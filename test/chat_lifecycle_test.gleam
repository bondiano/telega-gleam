//// Phase 2b: what a chat instance costs while it is alive and how it is
//// reclaimed — session writes it can skip, the heap it gives back when the
//// chat goes quiet, and the eviction that is now on by default.

import gleam/erlang/process
import gleam/http/response
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleeunit/should

import telega
import telega/bot
import telega/client
import telega/internal/registry
import telega/telemetry
import telega/testing/context
import telega/testing/factory
import telega/update as update_module

pub type Sess {
  Sess(counter: Int)
}

pub type Err {
  Err(message: String)
}

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
  session_settings session_settings: bot.SessionSettings(Sess, Err),
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
      session_settings:,
      catch_handler: context.catch_handler(),
      dependencies: Nil,
      chat_factory: start_test_factory(),
      chat_settings: settings,
      dead_letters: None,
      name: None,
    )
  #(started.data, reg)
}

/// A session backend that reports every write it is asked to make.
fn recording_sessions(
  writes: process.Subject(Sess),
) -> bot.SessionSettings(Sess, Err) {
  bot.SessionSettings(
    persist_session: fn(_key, session) {
      process.send(writes, session)
      Ok(session)
    },
    get_session: fn(_key) { Ok(Some(Sess(0))) },
    default_session: fn() { Sess(0) },
  )
}

fn test_settings(
  idle_timeout idle_timeout: Option(Int),
  hibernate_after hibernate_after: Option(Int),
  persistence persistence: bot.SessionPersistence,
) -> bot.ChatSettings {
  bot.ChatSettings(
    ..bot.default_chat_settings(),
    idle_timeout:,
    init_timeout: 5000,
    media_group_timeout: None,
    hibernate_after:,
    session_persistence: persistence,
  )
}

// ---------------------------------------------------------------------------
// Dirty-check: an unchanged session is not written back
// ---------------------------------------------------------------------------

pub fn a_handler_that_only_reads_writes_nothing_test() {
  let writes = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "lifecycle_read_only",
      router: fn(ctx, _update) { Ok(ctx) },
      session_settings: recording_sessions(writes),
      settings: test_settings(
        idle_timeout: None,
        hibernate_after: None,
        persistence: bot.PersistOnChange,
      ),
    )

  bot.handle_update(bot_subject, factory.text_update(text: "hi"))
  |> should.be_true

  // Storage already holds exactly this value; writing it back would be a round
  // trip that changes nothing.
  process.receive(writes, 200) |> should.be_error
}

pub fn a_handler_that_changes_the_session_still_writes_test() {
  let writes = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "lifecycle_dirty",
      router: fn(ctx, _update) { bot.next_session(ctx, Sess(1)) },
      session_settings: recording_sessions(writes),
      settings: test_settings(
        idle_timeout: None,
        hibernate_after: None,
        persistence: bot.PersistOnChange,
      ),
    )

  bot.handle_update(bot_subject, factory.text_update(text: "hi"))
  |> should.be_true

  process.receive(writes, 1000) |> should.equal(Ok(Sess(1)))
}

/// The skip is per update, not once and for all: a chat that goes quiet after
/// changing its session has already had that change stored.
pub fn only_the_updates_that_changed_something_are_written_test() {
  let writes = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "lifecycle_mixed",
      router: fn(ctx, update) {
        case update {
          update_module.TextUpdate(text: "bump", ..) ->
            bot.next_session(ctx, Sess(ctx.session.counter + 1))
          _ -> Ok(ctx)
        }
      },
      session_settings: recording_sessions(writes),
      settings: test_settings(
        idle_timeout: None,
        hibernate_after: None,
        persistence: bot.PersistOnChange,
      ),
    )

  list.each(["read", "bump", "read", "bump", "read"], fn(text) {
    bot.handle_update(bot_subject, factory.text_update(text:))
    |> should.be_true
  })

  drain_sessions(writes, []) |> should.equal([Sess(1), Sess(2)])
}

pub fn persist_always_writes_every_update_test() {
  let writes = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "lifecycle_always",
      router: fn(ctx, _update) { Ok(ctx) },
      session_settings: recording_sessions(writes),
      settings: test_settings(
        idle_timeout: None,
        hibernate_after: None,
        persistence: bot.PersistAlways,
      ),
    )

  // A backend whose write refreshes a TTL or a "last seen" column needs the
  // round trip even when the value has not moved.
  list.each([1, 2, 3], fn(_) {
    bot.handle_update(bot_subject, factory.text_update(text: "hi"))
    |> should.be_true
  })

  drain_sessions(writes, []) |> list.length |> should.equal(3)
}

// ---------------------------------------------------------------------------
// Hibernation: the heap comes back when the chat goes quiet
// ---------------------------------------------------------------------------

pub fn an_idle_instance_compacts_its_heap_once_test() {
  let events = process.new_subject()
  let id = "hibernate-" <> int.to_string(int.random(1_000_000))
  telemetry.attach_many(
    id:,
    events: [["telega", "chat_instance", "hibernate"]],
    handler: fn(_event, _measurements, metadata) {
      case list.key_find(metadata, "key") {
        Ok(telemetry.StringValue(key)) -> process.send(events, key)
        _ -> Nil
      }
    },
  )

  let #(bot_subject, _reg) =
    start_bot(
      name: "lifecycle_hibernate",
      router: fn(ctx, _update) { Ok(ctx) },
      session_settings: context.session_settings_with(
        default: fn() { Sess(0) },
        initial: Sess(0),
      ),
      settings: test_settings(
        idle_timeout: None,
        hibernate_after: Some(50),
        persistence: bot.PersistOnChange,
      ),
    )

  bot.handle_update(bot_subject, factory.text_update(text: "hi"))
  |> should.be_true

  process.receive(events, 2000) |> should.equal(Ok(default_key))
  // One collection per quiet spell, not one per idle tick.
  process.receive(events, 300) |> should.be_error

  telemetry.detach(id)
}

pub fn traffic_rearms_the_compaction_test() {
  let events = process.new_subject()
  let id = "hibernate-rearm-" <> int.to_string(int.random(1_000_000))
  telemetry.attach_many(
    id:,
    events: [["telega", "chat_instance", "hibernate"]],
    handler: fn(_event, _measurements, _metadata) { process.send(events, Nil) },
  )

  let #(bot_subject, _reg) =
    start_bot(
      name: "lifecycle_hibernate_rearm",
      router: fn(ctx, _update) { Ok(ctx) },
      session_settings: context.session_settings_with(
        default: fn() { Sess(0) },
        initial: Sess(0),
      ),
      settings: test_settings(
        idle_timeout: None,
        hibernate_after: Some(50),
        persistence: bot.PersistOnChange,
      ),
    )

  bot.handle_update(bot_subject, factory.text_update(text: "hi"))
  |> should.be_true
  process.receive(events, 2000) |> should.be_ok

  // The chat comes back: the heap it grows now is worth collecting again.
  bot.handle_update(bot_subject, factory.text_update(text: "again"))
  |> should.be_true
  process.receive(events, 2000) |> should.be_ok

  telemetry.detach(id)
}

// ---------------------------------------------------------------------------
// Eviction is on by default
// ---------------------------------------------------------------------------

pub fn default_chat_settings_evict_and_compact_test() {
  let defaults = bot.default_chat_settings()

  // H2 is only closed for everyone if the default closes it: an instance per
  // user, kept forever, is how a busy bot runs out of processes.
  defaults.idle_timeout |> should.equal(Some(bot.default_chat_idle_timeout))
  defaults.hibernate_after |> should.equal(Some(bot.default_hibernate_after))
  defaults.session_persistence |> should.equal(bot.PersistOnChange)
  bot.default_chat_idle_timeout |> should.equal(1000 * 60 * 30)
}

/// The builder resolves to the same defaults, and `without_chat_idle_timeout`
/// is the way back to instances that live as long as the bot.
pub fn the_builder_can_turn_eviction_off_test() {
  let api_client =
    client.new(token: "test_token", fetch_client: fn(_req) {
      Ok(response.new(200) |> response.set_body("{\"ok\":true}"))
    })
  let builder = telega.new(api_client)

  telega.chat_settings(builder).idle_timeout
  |> should.equal(Some(bot.default_chat_idle_timeout))
  telega.chat_settings(telega.with_chat_idle_timeout(builder, 1234)).idle_timeout
  |> should.equal(Some(1234))
  telega.chat_settings(telega.without_chat_idle_timeout(builder)).idle_timeout
  |> should.equal(None)
  telega.chat_settings(telega.without_chat_idle_timeout(builder)).hibernate_after
  |> should.equal(Some(bot.default_hibernate_after))
  telega.chat_settings(telega.without_chat_hibernation(builder)).hibernate_after
  |> should.equal(None)
  telega.chat_settings(telega.with_session_persistence(
    builder,
    bot.PersistAlways,
  )).session_persistence
  |> should.equal(bot.PersistAlways)
}

fn drain_sessions(
  subject: process.Subject(Sess),
  acc: List(Sess),
) -> List(Sess) {
  case process.receive(subject, 200) {
    Ok(session) -> drain_sessions(subject, [session, ..acc])
    Error(_) -> list.reverse(acc)
  }
}
