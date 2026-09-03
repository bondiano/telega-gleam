//// Regression tests for the reliability audit (C1–C5, H2, H3).
////
//// Each test reproduces a concrete failure mode that used to hang, lose, or
//// silently mis-route updates. They are deliberately written against the
//// public/`@internal` surface so they keep working as the internals change.

import gleam/erlang/atom
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleam/regexp
import gleeunit/should

import telega
import telega/bot
import telega/internal/registry
import telega/testing/context
import telega/testing/factory
import telega/update as update_module

pub type Sess {
  Sess(counter: Int)
}

pub type Err {
  Err(message: String)
}

/// Session key the default factory updates resolve to (`chat_id:from_id`).
const default_key = "123456789:987654321"

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
  catch_handler catch_handler: bot.CatchHandler(Sess, Err, Nil),
) {
  start_bot_with_idle_timeout(
    name:,
    router:,
    catch_handler:,
    idle_timeout: None,
  )
}

fn start_bot_with_idle_timeout(
  name name: String,
  router router: fn(bot.Context(Sess, Err, Nil), update_module.Update) ->
    Result(bot.Context(Sess, Err, Nil), Err),
  catch_handler catch_handler: bot.CatchHandler(Sess, Err, Nil),
  idle_timeout idle_timeout: Option(Int),
) {
  start_bot_with_sessions(
    name:,
    router:,
    catch_handler:,
    idle_timeout:,
    session_settings: context.session_settings_with(
      default: fn() { Sess(0) },
      initial: Sess(0),
    ),
  )
}

fn start_bot_with_sessions(
  name name: String,
  router router: fn(bot.Context(Sess, Err, Nil), update_module.Update) ->
    Result(bot.Context(Sess, Err, Nil), Err),
  catch_handler catch_handler: bot.CatchHandler(Sess, Err, Nil),
  idle_timeout idle_timeout: Option(Int),
  session_settings session_settings: bot.SessionSettings(Sess, Err),
) {
  let assert Ok(reg) = registry.start(name)
  let assert Ok(started) =
    bot.start(
      registry: reg,
      config: context.config(),
      bot_info: factory.bot_user(),
      router_handler: router,
      pre_handlers: [],
      session_settings:,
      catch_handler:,
      dependencies: Nil,
      chat_factory: start_test_factory(),
      chat_settings: bot.ChatSettings(
        ..bot.default_chat_settings(),
        idle_timeout: idle_timeout,
        init_timeout: 5000,
        media_group_timeout: option.None,
      ),
      name: None,
    )
  #(started.data, reg)
}

/// Pid of the chat instance currently registered under `default_key`.
fn instance_pid(reg) -> Result(process.Pid, Nil) {
  case registry.get(reg, key: default_key) {
    Some(subject) -> process.subject_owner(subject)
    None -> Error(Nil)
  }
}

/// Dispatch an update the way the poller does, but bounded: the caller runs in
/// a throwaway process so a dispatch that never answers times out here instead
/// of wedging the test suite.
fn dispatch(
  bot_subject: bot.BotSubject,
  update: update_module.Update,
  timeout: Int,
) -> Result(Bool, Nil) {
  let reply = process.new_subject()
  let _ =
    process.spawn_unlinked(fn() {
      process.send(reply, bot.handle_update(bot_subject, update))
    })
  process.receive(reply, timeout)
}

// C1 — a handler that dies must not wedge the caller forever ----------------

pub fn c1_panicking_handler_answers_the_caller_test() {
  let #(bot_subject, _reg) =
    start_bot(
      name: "c1_panic",
      router: fn(_ctx, _update) { panic as "handler exploded" },
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "hi"), 2000)
  |> should.equal(Ok(False))
}

pub fn c1_failing_catch_handler_answers_the_caller_test() {
  let #(bot_subject, _reg) =
    start_bot(
      name: "c1_catch_fail",
      router: fn(_ctx, _update) { Error(Err("boom")) },
      catch_handler: fn(_ctx, e) { Error(e) },
    )

  dispatch(bot_subject, factory.text_update(text: "hi"), 2000)
  |> should.equal(Ok(False))
}

pub fn c1_failing_persist_answers_the_caller_test() {
  let assert Ok(reg) = registry.start("c1_persist_fail")
  let assert Ok(started) =
    bot.start(
      registry: reg,
      config: context.config(),
      bot_info: factory.bot_user(),
      // The handler has to actually change the session, or there would be
      // nothing to write and no storage error to answer for.
      router_handler: fn(ctx, _update) { bot.next_session(ctx, Sess(1)) },
      pre_handlers: [],
      session_settings: bot.SessionSettings(
        persist_session: fn(_key, _session) { Error(Err("storage down")) },
        get_session: fn(_key) { Ok(Some(Sess(0))) },
        default_session: fn() { Sess(0) },
      ),
      catch_handler: fn(_ctx, e) { Error(e) },
      dependencies: Nil,
      chat_factory: start_test_factory(),
      chat_settings: bot.ChatSettings(
        ..bot.default_chat_settings(),
        idle_timeout: None,
        init_timeout: 5000,
        media_group_timeout: option.None,
      ),
      name: None,
    )

  dispatch(started.data, factory.text_update(text: "hi"), 2000)
  |> should.equal(Ok(False))
}

// C2 — a stopped chat instance must not poison the registry -----------------

pub fn c2_stopped_chat_instance_is_unregistered_test() {
  let #(bot_subject, reg) =
    start_bot(
      name: "c2_registry",
      router: fn(ctx, update) {
        case update {
          update_module.TextUpdate(text: "fail", ..) -> Error(Err("boom"))
          _ -> Ok(ctx)
        }
      },
      catch_handler: fn(_ctx, e) { Error(e) },
    )

  dispatch(bot_subject, factory.text_update(text: "fail"), 2000)
  |> should.equal(Ok(False))

  process.sleep(100)
  registry.get(reg, key: default_key)
  |> should.equal(None)

  // The user must still be served after their instance was torn down.
  dispatch(bot_subject, factory.text_update(text: "ok"), 2000)
  |> should.equal(Ok(True))
}

// C4 — `wait_*` filters must actually filter --------------------------------

fn wait_router(
  events: process.Subject(String),
  handler: bot.Handler(Sess, Err, Nil),
) {
  fn(ctx: bot.Context(Sess, Err, Nil), update) {
    case update {
      update_module.TextUpdate(text: "start", ..) ->
        bot.wait_handler(
          ctx:,
          handler:,
          handle_else: Some(
            bot.HandleAll(fn(ctx, _update) {
              process.send(events, "else")
              Ok(ctx)
            }),
          ),
          timeout: None,
        )
      _ -> Ok(ctx)
    }
  }
}

pub fn c4_wait_command_ignores_other_commands_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "c4_command",
      router: wait_router(
        events,
        bot.HandleCommand("confirm", fn(ctx, _command) {
          process.send(events, "confirm")
          Ok(ctx)
        }),
      ),
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let _ = dispatch(bot_subject, factory.command_update(command: "cancel"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("else"))
}

pub fn c4_wait_command_still_matches_its_command_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "c4_command_match",
      router: wait_router(
        events,
        bot.HandleCommand("confirm", fn(ctx, _command) {
          process.send(events, "confirm")
          Ok(ctx)
        }),
      ),
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let _ =
    dispatch(bot_subject, factory.command_update(command: "confirm"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("confirm"))
}

pub fn c4_wait_hears_ignores_non_matching_text_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "c4_hears",
      router: wait_router(
        events,
        bot.HandleHears(bot.HearText("yes"), fn(ctx, _text) {
          process.send(events, "hears")
          Ok(ctx)
        }),
      ),
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let _ = dispatch(bot_subject, factory.text_update(text: "no"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("else"))
}

pub fn c4_wait_callback_query_ignores_non_matching_data_test() {
  let assert Ok(re) = regexp.from_string("^accept$")
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "c4_callback",
      router: wait_router(
        events,
        bot.HandleCallbackQuery(
          bot.CallbackQueryFilter(re:),
          fn(ctx, _data, _id) {
            process.send(events, "callback")
            Ok(ctx)
          },
        ),
      ),
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let _ =
    dispatch(bot_subject, factory.callback_query_update(data: "decline"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("else"))
}

pub fn c4_wait_for_runs_the_fallback_on_a_filter_miss_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "c4_wait_for",
      router: fn(ctx: bot.Context(Sess, Err, Nil), update) {
        case update {
          update_module.TextUpdate(text: "start", ..) ->
            telega.wait_for(
              ctx:,
              filter: fn(update) {
                case update {
                  update_module.PhotoUpdate(..) -> True
                  _ -> False
                }
              },
              or: Some(
                bot.HandleAll(fn(ctx, _update) {
                  process.send(events, "else")
                  Ok(ctx)
                }),
              ),
              timeout: None,
              continue: fn(ctx, _update) {
                process.send(events, "photo")
                Ok(ctx)
              },
            )
          _ -> Ok(ctx)
        }
      },
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let _ = dispatch(bot_subject, factory.text_update(text: "not a photo"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("else"))

  // Still waiting: the matching update resumes the conversation.
  let _ = dispatch(bot_subject, factory.photo_update(), 2000)
  process.receive(events, 1000)
  |> should.equal(Ok("photo"))
}

// H2 — chat instances must not accumulate forever ---------------------------

pub fn h2_idle_chat_instance_is_stopped_and_unregistered_test() {
  let #(bot_subject, reg) =
    start_bot_with_idle_timeout(
      name: "h2_idle_stop",
      router: fn(ctx, _update) { Ok(ctx) },
      catch_handler: context.catch_handler(),
      idle_timeout: Some(150),
    )

  dispatch(bot_subject, factory.text_update(text: "hi"), 2000)
  |> should.equal(Ok(True))

  let assert Ok(pid) = instance_pid(reg)
  process.is_alive(pid) |> should.equal(True)

  process.sleep(600)

  // The idle instance is gone: no process, no registry entry.
  process.is_alive(pid) |> should.equal(False)
  registry.get(reg, key: default_key) |> should.equal(None)

  // The next update from the same user is served by a fresh instance.
  dispatch(bot_subject, factory.text_update(text: "hi again"), 2000)
  |> should.equal(Ok(True))

  let assert Ok(new_pid) = instance_pid(reg)
  { new_pid == pid } |> should.equal(False)
}

pub fn h2_many_users_leave_no_instances_behind_test() {
  let #(bot_subject, reg) =
    start_bot_with_idle_timeout(
      name: "h2_idle_many",
      router: fn(ctx, _update) { Ok(ctx) },
      catch_handler: context.catch_handler(),
      idle_timeout: Some(150),
    )

  let user_ids =
    list.map(list.repeat(0, 40), fn(_) { 0 })
    |> list.index_map(fn(_, i) { i + 1 })
  let pids =
    list.map(user_ids, fn(id) {
      dispatch(
        bot_subject,
        factory.text_update_with(text: "hi", from_id: id, chat_id: id),
        2000,
      )
      |> should.equal(Ok(True))

      let key = int.to_string(id) <> ":" <> int.to_string(id)
      let assert Some(subject) = registry.get(reg, key:)
      let assert Ok(pid) = process.subject_owner(subject)
      pid
    })

  process.sleep(600)

  // Every per-user process is reclaimed, not just the last one.
  list.filter(pids, process.is_alive)
  |> should.equal([])
  list.filter(user_ids, fn(id) {
    let key = int.to_string(id) <> ":" <> int.to_string(id)
    registry.get(reg, key:) != None
  })
  |> should.equal([])
}

pub fn h2_active_chat_instance_survives_the_idle_timeout_test() {
  let #(bot_subject, reg) =
    start_bot_with_idle_timeout(
      name: "h2_idle_active",
      router: fn(ctx, _update) { Ok(ctx) },
      catch_handler: context.catch_handler(),
      idle_timeout: Some(400),
    )

  dispatch(bot_subject, factory.text_update(text: "hi"), 2000)
  |> should.equal(Ok(True))
  let assert Ok(pid) = instance_pid(reg)

  // Keep talking to the bot for longer than the idle timeout.
  list.each([1, 2, 3, 4, 5], fn(_) {
    process.sleep(150)
    dispatch(bot_subject, factory.text_update(text: "still here"), 2000)
    |> should.equal(Ok(True))
  })

  instance_pid(reg) |> should.equal(Ok(pid))
}

pub fn h2_slow_handler_is_not_evicted_mid_update_test() {
  let #(bot_subject, _reg) =
    start_bot_with_idle_timeout(
      name: "h2_idle_slow_handler",
      router: fn(ctx, _update) {
        process.sleep(300)
        Ok(ctx)
      },
      catch_handler: context.catch_handler(),
      idle_timeout: Some(100),
    )

  // The handler outlives the idle timeout — the update must still be answered.
  dispatch(bot_subject, factory.text_update(text: "slow"), 2000)
  |> should.equal(Ok(True))
}

pub fn h2_cancel_conversation_clears_the_continuation_not_the_registry_test() {
  let events = process.new_subject()
  let #(bot_subject, reg) =
    start_bot(
      name: "h2_cancel",
      router: fn(ctx: bot.Context(Sess, Err, Nil), update) {
        case update {
          update_module.TextUpdate(text: "start", ..) ->
            bot.wait_handler(
              ctx:,
              handler: bot.HandleAll(fn(ctx, _update) {
                process.send(events, "continuation")
                Ok(ctx)
              }),
              handle_else: None,
              timeout: None,
            )
          _ -> {
            process.send(events, "router")
            Ok(ctx)
          }
        }
      },
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let assert Ok(pid) = instance_pid(reg)

  bot.cancel_conversation_for(bot_subject:, key: default_key)
  process.sleep(100)

  // The instance is still the same live, registered process...
  process.is_alive(pid) |> should.equal(True)
  instance_pid(reg) |> should.equal(Ok(pid))

  // ...and the update goes back through the router, not the continuation.
  dispatch(bot_subject, factory.text_update(text: "after cancel"), 2000)
  |> should.equal(Ok(True))
  process.receive(events, 1000)
  |> should.equal(Ok("router"))
}

// H3 — `wait_*` timeouts are milliseconds, as documented --------------------

fn timed_wait_router(events: process.Subject(String), timeout: Option(Int)) {
  fn(ctx: bot.Context(Sess, Err, Nil), update) {
    case update {
      update_module.TextUpdate(text: "start", ..) ->
        bot.wait_handler(
          ctx:,
          handler: bot.HandleAll(fn(ctx, _update) {
            process.send(events, "continuation")
            Ok(ctx)
          }),
          handle_else: None,
          timeout:,
        )
      _ -> {
        process.send(events, "router")
        Ok(ctx)
      }
    }
  }
}

pub fn h3_wait_timeout_expires_after_the_given_milliseconds_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "h3_timeout_ms",
      router: timed_wait_router(events, Some(150)),
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))

  // 150 *milliseconds*, not 150 seconds.
  process.sleep(400)
  let _ = dispatch(bot_subject, factory.text_update(text: "too late"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("router"))
}

pub fn h3_wait_timeout_still_running_resumes_the_conversation_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "h3_timeout_alive",
      router: timed_wait_router(events, Some(5000)),
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))

  process.sleep(100)
  let _ = dispatch(bot_subject, factory.text_update(text: "in time"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("continuation"))
}

// H12 — session loading lives in the instance, and a failed spawn is survivable

pub fn slow_session_load_does_not_fail_the_spawn_test() {
  let session_settings =
    bot.SessionSettings(
      persist_session: fn(_key, session) { Ok(session) },
      get_session: fn(_key) {
        // Far longer than the old hard-coded 10 ms initialisation timeout.
        process.sleep(200)
        Ok(Some(Sess(7)))
      },
      default_session: fn() { Sess(0) },
    )

  let seen = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot_with_sessions(
      name: "h12_slow_session",
      router: fn(ctx, _update) {
        process.send(seen, ctx.session)
        Ok(ctx)
      },
      catch_handler: context.catch_handler(),
      idle_timeout: None,
      session_settings:,
    )

  dispatch(bot_subject, factory.text_update(text: "hi"), 3000)
  |> should.equal(Ok(True))

  process.receive(seen, 1000) |> should.equal(Ok(Sess(7)))
}

pub fn failed_spawn_keeps_the_bot_and_the_factory_alive_test() {
  let poisoned_key = "1:1"
  let session_settings =
    bot.SessionSettings(
      persist_session: fn(_key, session) { Ok(session) },
      get_session: fn(key) {
        case key == poisoned_key {
          True -> panic as "storage exploded"
          False -> Ok(Some(Sess(0)))
        }
      },
      default_session: fn() { Sess(0) },
    )

  let #(bot_subject, _reg) =
    start_bot_with_sessions(
      name: "h12_failed_spawn",
      router: fn(ctx, _update) { Ok(ctx) },
      catch_handler: context.catch_handler(),
      idle_timeout: None,
      session_settings:,
    )

  // The instance for this chat cannot start; the caller is answered `False`
  // rather than being left waiting.
  dispatch(
    bot_subject,
    factory.text_update_with(text: "boom", from_id: 1, chat_id: 1),
    3000,
  )
  |> should.equal(Ok(False))

  // Neither the bot actor nor the chat factory went down with it.
  dispatch(bot_subject, factory.text_update(text: "hi"), 3000)
  |> should.equal(Ok(True))
}

// M1 — a session that could not be read must not be replaced by the default ---

pub fn m1_unreadable_session_is_not_overwritten_test() {
  let persisted = process.new_subject()
  let session_settings =
    bot.SessionSettings(
      persist_session: fn(_key, session) {
        process.send(persisted, session)
        Ok(session)
      },
      get_session: fn(_key) { Error(Err("storage down")) },
      default_session: fn() { Sess(0) },
    )

  let #(bot_subject, reg) =
    start_bot_with_sessions(
      name: "m1_unreadable_session",
      router: fn(ctx, _update) { bot.next_session(ctx, Sess(99)) },
      catch_handler: context.catch_handler(),
      idle_timeout: None,
      session_settings:,
    )

  // Nothing could handle the update, and the caller is told so.
  dispatch(bot_subject, factory.text_update(text: "hi"), 3000)
  |> should.equal(Ok(False))

  // The handler never ran, so the user's real session was never overwritten
  // with a fresh default.
  process.receive(persisted, 200)
  |> should.equal(Error(Nil))

  // No half-started instance is left behind in the registry.
  process.sleep(100)
  registry.get(reg, key: default_key)
  |> should.equal(None)
}

// L1 — draining must not wait out the timeout it was given --------------------

pub fn drain_returns_as_soon_as_nothing_is_in_flight_test() {
  let #(bot_subject, _reg) =
    start_bot(
      name: "l1_drain_idle",
      router: fn(ctx, _update) { Ok(ctx) },
      catch_handler: context.catch_handler(),
    )

  let started = now_ms()
  bot.drain(bot_subject:, timeout: 5000) |> should.equal(0)
  { now_ms() - started < 1000 } |> should.be_true
}

pub fn a_crashed_handler_still_frees_its_in_flight_slot_test() {
  let #(bot_subject, _reg) =
    start_bot(
      name: "l1_drain_crash",
      router: fn(_ctx, _update) { panic as "handler exploded" },
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "boom"), 2000)
  |> should.equal(Ok(False))

  // The instance died mid-update. If its slot were not released, the drain
  // would sit here until the timeout.
  let started = now_ms()
  bot.drain(bot_subject:, timeout: 5000) |> should.equal(0)
  { now_ms() - started < 1000 } |> should.be_true
}

@external(erlang, "erlang", "monotonic_time")
fn monotonic_time(unit: atom.Atom) -> Int

fn now_ms() -> Int {
  monotonic_time(atom.create("millisecond"))
}
