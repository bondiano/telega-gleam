//// The throughput criteria phase 2 is measured against.
////
//// These are load tests, not micro-benchmarks: they assert the two properties
//// the design is supposed to give — that slow handlers in different chats run
//// at the same time, and that idle chats give their processes back — with
//// bounds loose enough to survive a busy CI machine and tight enough to fail
//// if either property is lost.

import gleam/erlang/atom
import gleam/erlang/charlist
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleam/result
import gleeunit/should

import telega/bot
import telega/internal/registry
import telega/internal/utils
import telega/testing/context
import telega/testing/factory
import telega/update as update_module

pub type Sess {
  Sess(counter: Int)
}

pub type Err {
  Err(message: String)
}

/// Chats in the concurrency run. Every one gets its own instance, and every
/// instance sleeps for `handler_delay` — so the run takes about as long as one
/// handler if they truly overlap, and 200 times longer if they do not.
const concurrent_chats = 1000

const handler_delay = 200

/// The dispatch itself has to finish well inside the time one handler takes;
/// a tenfold margin leaves room for a loaded CI machine without letting a
/// serialised run through (that would take 200 seconds).
const concurrency_budget = 2000

/// Chats in the eviction run, unless `TELEGA_LOAD_CHATS` says otherwise.
///
/// The roadmap's criterion is a hundred thousand, which this test passes
/// (`task test:load`) — but it holds 100 000 live instances at once, which is
/// about 2.8 GB, more than a shared CI runner should be asked for on every
/// push. The default is a twentieth of that; the mechanism it exercises — one
/// idle tick per instance, eviction routed through the bot actor — is the same
/// at either size.
const default_evictable_chats = 20_000

/// Long enough that no instance starts asking to be evicted while the bot is
/// still working through the backlog of first updates — every such request is
/// another message into the one mailbox that is creating the instances.
const evictable_idle_timeout = 2000

fn evictable_chats() -> Int {
  charlist.to_string(getenv(
    charlist.from_string("TELEGA_LOAD_CHATS"),
    charlist.from_string(""),
  ))
  |> int.parse
  |> result.unwrap(default_evictable_chats)
}

fn start_test_factory() {
  let assert Ok(started) =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.start
  started.data
}

fn start_bot(
  name name: String,
  router router: fn(bot.Context(Sess, Err, Nil), update_module.Update) ->
    Result(bot.Context(Sess, Err, Nil), Err),
  settings settings: bot.ChatSettings,
) {
  let assert Ok(reg) = registry.start(name)
  let assert Ok(started) =
    bot.start(
      registry: reg,
      config: context.config(),
      bot_info: factory.bot_user(),
      router_handler: router,
      pre_handlers: [],
      session_settings: context.session_settings_with(
        default: fn() { Sess(0) },
        initial: Sess(0),
      ),
      catch_handler: context.catch_handler(),
      dependencies: Nil,
      chat_factory: start_test_factory(),
      chat_settings: settings,
      dead_letters: None,
      name: None,
    )
  #(started.data, reg)
}

/// An update from `chat_id`, sent by a user with the same id, so every chat
/// resolves to its own `{chat_id}:{from_id}` instance.
fn chat_update(chat_id: Int) -> update_module.Update {
  factory.raw_update_with(
    message: factory.message_with(
      text: "hi",
      from: factory.user_with(id: chat_id, first_name: "U"),
      chat: factory.chat_with(id: chat_id, type_: "private"),
    ),
    update_id: chat_id,
  )
  |> update_module.raw_to_update
}

// ---------------------------------------------------------------------------
// A thousand slow chats finish in about the time one of them takes
// ---------------------------------------------------------------------------

pub fn slow_handlers_in_different_chats_run_at_the_same_time_test() {
  let done = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "load_concurrency",
      router: fn(ctx, _update) {
        process.sleep(handler_delay)
        Ok(ctx)
      },
      settings: bot.ChatSettings(
        ..bot.default_chat_settings(),
        idle_timeout: None,
        hibernate_after: None,
        init_timeout: 30_000,
      ),
    )

  let started_at = utils.current_time_ms()
  list.each(chat_ids(concurrent_chats, []), fn(chat_id) {
    bot.dispatch_update(
      bot_subject:,
      update: chat_update(chat_id),
      reply_with: done,
    )
  })

  // Every update is answered — the ack protocol has no gaps under load either.
  collect_acks(done, concurrent_chats, 30_000) |> should.equal(concurrent_chats)

  let elapsed = utils.current_time_ms() - started_at
  case elapsed < concurrency_budget {
    True -> Nil
    False ->
      panic as {
        int.to_string(concurrent_chats)
        <> " chats × "
        <> int.to_string(handler_delay)
        <> "ms took "
        <> int.to_string(elapsed)
        <> "ms — handlers are being serialised"
      }
  }
}

// ---------------------------------------------------------------------------
// Idle chats give their processes back
// ---------------------------------------------------------------------------

pub fn idle_instances_are_reclaimed_test() {
  let chats = evictable_chats()
  let done = process.new_subject()
  let baseline = process_count()
  let #(bot_subject, reg) =
    start_bot(
      name: "load_eviction",
      router: fn(ctx, _update) { Ok(ctx) },
      settings: bot.ChatSettings(
        ..bot.default_chat_settings(),
        idle_timeout: Some(evictable_idle_timeout),
        hibernate_after: None,
        init_timeout: 30_000,
      ),
    )

  list.each(chat_ids(chats, []), fn(chat_id) {
    bot.dispatch_update(
      bot_subject:,
      update: chat_update(chat_id),
      reply_with: done,
    )
  })
  collect_acks(done, chats, 60_000) |> should.equal(chats)

  // One process per chat while they are all being served...
  let at_peak = process_count()
  { at_peak - baseline >= chats } |> should.be_true

  // ...and back to roughly the baseline once they have all gone quiet: the
  // instance asks the bot to evict it, the bot deregisters the key first, and
  // the next update from that chat starts a fresh instance from storage.
  wait_until_empty(reg, chats, 60_000)
  let after_idle = process_count()
  case after_idle - baseline < 1000 {
    True -> Nil
    False ->
      panic as {
        int.to_string(chats)
        <> " idle chats left "
        <> int.to_string(after_idle - baseline)
        <> " processes behind"
      }
  }
}

/// Poll until every chat instance has deregistered itself, or give up.
fn wait_until_empty(reg, total: Int, budget: Int) -> Nil {
  case registered(reg, total) {
    0 -> Nil
    remaining ->
      case budget <= 0 {
        True ->
          panic as {
            int.to_string(remaining) <> " chat instances were never evicted"
          }
        False -> {
          process.sleep(100)
          wait_until_empty(reg, total, budget - 100)
        }
      }
  }
}

fn registered(reg, total: Int) -> Int {
  list.count(chat_ids(total, []), fn(chat_id) {
    let key = int.to_string(chat_id) <> ":" <> int.to_string(chat_id)
    registry.get(reg, key:) != None
  })
}

fn collect_acks(
  done: process.Subject(Bool),
  remaining: Int,
  timeout: Int,
) -> Int {
  do_collect_acks(done, remaining, timeout, 0)
}

fn do_collect_acks(
  done: process.Subject(Bool),
  remaining: Int,
  timeout: Int,
  acc: Int,
) -> Int {
  case remaining {
    0 -> acc
    _ ->
      case process.receive(done, timeout) {
        Ok(_) -> do_collect_acks(done, remaining - 1, timeout, acc + 1)
        Error(_) -> acc
      }
  }
}

fn chat_ids(n: Int, acc: List(Int)) -> List(Int) {
  case n {
    0 -> acc
    _ -> chat_ids(n - 1, [n, ..acc])
  }
}

/// How many processes the whole VM is running. The test only ever reads the
/// difference from a baseline it takes first, so other tests' processes cancel
/// out.
fn process_count() -> Int {
  system_info(atom.create("process_count"))
}

@external(erlang, "erlang", "system_info")
fn system_info(key: atom.Atom) -> Int

@external(erlang, "os", "getenv")
fn getenv(
  name: charlist.Charlist,
  default: charlist.Charlist,
) -> charlist.Charlist
