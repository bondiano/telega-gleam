//// Phase 6a–6c: what an update is keyed by, what happens when the session
//// cannot be read, and whether a failed write is retried.

import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleam/result
import gleam/string
import gleeunit/should

import telega/bot
import telega/internal/registry
import telega/storage
import telega/storage/ets
import telega/testing/context
import telega/testing/factory
import telega/update as update_module

pub type Sess {
  Sess(counter: Int)
}

pub type Err {
  Err(message: String)
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

/// A backend that reports every key it is asked to read or write.
fn recording_sessions(
  events: process.Subject(#(String, String)),
) -> bot.SessionSettings(Sess, Err) {
  bot.SessionSettings(
    persist_session: fn(key, session) {
      process.send(events, #("write", key))
      Ok(session)
    },
    get_session: fn(key) {
      process.send(events, #("read", key))
      Ok(Some(Sess(0)))
    },
    default_session: fn() { Sess(0) },
  )
}

// --- 6a: what an update is keyed by ----------------------------------------

pub fn the_default_key_is_chat_and_user_test() {
  bot.default_session_key(factory.text_update_with(
    text: "hi",
    from_id: 7,
    chat_id: -100,
  ))
  |> should.equal("-100:7")
}

pub fn a_chat_key_ignores_who_sent_the_update_test() {
  let one =
    factory.text_update_with(text: "hi", from_id: 7, chat_id: -100)
    |> bot.chat_session_key
  let other =
    factory.text_update_with(text: "hi", from_id: 8, chat_id: -100)
    |> bot.chat_session_key

  one |> should.equal("chat:-100")
  one |> should.equal(other)
}

pub fn a_user_key_ignores_which_chat_the_update_is_in_test() {
  factory.text_update_with(text: "hi", from_id: 7, chat_id: -100)
  |> bot.user_session_key
  |> should.equal("user:7")
}

pub fn two_members_of_a_chat_share_one_session_under_a_chat_key_test() {
  let events = process.new_subject()
  let #(bot_subject, reg) =
    start_bot(
      name: "scope_chat_key",
      router: fn(ctx, _update) { bot.next_session(ctx, Sess(1)) },
      session_settings: recording_sessions(events),
      settings: bot.ChatSettings(
        ..bot.default_chat_settings(),
        idle_timeout: None,
        hibernate_after: None,
        session_key: bot.chat_session_key,
      ),
    )

  bot.handle_update(
    bot_subject,
    factory.text_update_with(text: "one", from_id: 7, chat_id: -100),
  )
  |> should.be_true
  bot.handle_update(
    bot_subject,
    factory.text_update_with(text: "two", from_id: 8, chat_id: -100),
  )
  |> should.be_true

  // One instance, one key: the second member's update reused the first
  // member's chat instance, so the session was read exactly once.
  drain(events, [])
  |> list.filter(fn(event) { event.0 == "read" })
  |> should.equal([#("read", "chat:-100")])

  registry.get(reg, key: "chat:-100") |> option.is_some |> should.be_true
  registry.get(reg, key: "-100:7") |> should.equal(None)
}

pub fn the_default_key_gives_each_member_their_own_session_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "scope_default_key",
      router: fn(ctx, _update) { Ok(ctx) },
      session_settings: recording_sessions(events),
      settings: bot.ChatSettings(
        ..bot.default_chat_settings(),
        idle_timeout: None,
        hibernate_after: None,
      ),
    )

  bot.handle_update(
    bot_subject,
    factory.text_update_with(text: "one", from_id: 7, chat_id: -100),
  )
  |> should.be_true
  bot.handle_update(
    bot_subject,
    factory.text_update_with(text: "two", from_id: 8, chat_id: -100),
  )
  |> should.be_true

  drain(events, [])
  |> list.filter(fn(event) { event.0 == "read" })
  |> list.map(fn(event) { event.1 })
  |> list.sort(string.compare)
  |> should.equal(["-100:7", "-100:8"])
}

// --- 6b: an unreadable session ---------------------------------------------

fn failing_sessions(
  writes: process.Subject(Sess),
) -> bot.SessionSettings(Sess, Err) {
  bot.SessionSettings(
    persist_session: fn(_key, session) {
      process.send(writes, session)
      Ok(session)
    },
    get_session: fn(_key) { Error(Err("backend down")) },
    default_session: fn() { Sess(0) },
  )
}

fn load_error_settings(policy: bot.SessionLoadError) -> bot.ChatSettings {
  bot.ChatSettings(
    ..bot.default_chat_settings(),
    idle_timeout: None,
    hibernate_after: None,
    on_load_error: policy,
  )
}

pub fn fail_update_is_the_default_for_an_unreadable_session_test() {
  bot.default_chat_settings().on_load_error |> should.equal(bot.FailUpdate)
}

pub fn an_unreadable_session_fails_the_update_test() {
  let writes = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "scope_load_fail",
      router: fn(ctx, _update) { bot.next_session(ctx, Sess(1)) },
      session_settings: failing_sessions(writes),
      settings: load_error_settings(bot.FailUpdate),
    )

  bot.handle_update(bot_subject, factory.text_update(text: "hi"))
  |> should.be_false

  // Nothing was written: the whole point is not to overwrite the session that
  // could not be read.
  process.receive(writes, 200) |> should.be_error
}

pub fn use_default_serves_the_update_and_writes_test() {
  let writes = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "scope_load_default",
      router: fn(ctx, _update) { bot.next_session(ctx, Sess(1)) },
      session_settings: failing_sessions(writes),
      settings: load_error_settings(bot.UseDefault),
    )

  bot.handle_update(bot_subject, factory.text_update(text: "hi"))
  |> should.be_true

  process.receive(writes, 1000) |> should.equal(Ok(Sess(1)))
}

pub fn read_only_serves_the_update_and_writes_nothing_test() {
  let writes = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "scope_load_read_only",
      router: fn(ctx, _update) { bot.next_session(ctx, Sess(1)) },
      session_settings: failing_sessions(writes),
      settings: load_error_settings(bot.ReadOnly),
    )

  // The handler ran — the update is answered — but the stored session, which
  // this instance never managed to read, is left alone.
  bot.handle_update(bot_subject, factory.text_update(text: "hi"))
  |> should.be_true

  process.receive(writes, 200) |> should.be_error
}

// --- 6b: a failed write is retried on the next update ------------------------

/// Fails the first write, accepts the rest, and reports every attempt.
///
/// The "have I failed yet" flag lives in ETS rather than in a subject: the
/// writes happen in the chat instance's process, which cannot receive from a
/// subject the test process owns.
fn flaky_sessions(
  attempts: process.Subject(Sess),
  flag: storage.KeyValueStorage(e),
) -> bot.SessionSettings(Sess, Err) {
  bot.SessionSettings(
    persist_session: fn(_key, session) {
      process.send(attempts, session)
      case flag.get("failed_once") {
        Ok(None) -> {
          let _ = flag.set("failed_once", "yes")
          Error(Err("write failed"))
        }
        _ -> Ok(session)
      }
    },
    get_session: fn(_key) { Ok(Some(Sess(0))) },
    default_session: fn() { Sess(0) },
  )
}

pub fn a_failed_write_is_retried_on_the_next_update_test() {
  let attempts = process.new_subject()
  let assert Ok(flag) = ets.new("scope_dirty_flag")

  let #(bot_subject, _reg) =
    start_bot(
      name: "scope_dirty_retry",
      // The second update returns the same session the first one stored, so
      // without the dirty flag `PersistOnChange` would skip the retry.
      router: fn(ctx, _update) { bot.next_session(ctx, Sess(1)) },
      session_settings: flaky_sessions(attempts, flag),
      settings: bot.ChatSettings(
        ..bot.default_chat_settings(),
        idle_timeout: None,
        hibernate_after: None,
      ),
    )

  bot.handle_update(bot_subject, factory.text_update(text: "one"))
  |> should.be_false
  process.receive(attempts, 1000) |> should.equal(Ok(Sess(1)))

  bot.handle_update(bot_subject, factory.text_update(text: "two"))
  |> should.be_true
  process.receive(attempts, 1000) |> should.equal(Ok(Sess(1)))
}

// --- 6c: versioned sessions -------------------------------------------------

type Versioned {
  Versioned(name: String, locale: String)
}

fn encode_versioned(value: Versioned) -> json.Json {
  json.object([
    #("name", json.string(value.name)),
    #("locale", json.string(value.locale)),
  ])
}

fn versioned_decoder() -> decode.Decoder(Versioned) {
  use name <- decode.field("name", decode.string)
  use locale <- decode.field("locale", decode.string)
  decode.success(Versioned(name:, locale:))
}

/// v1 had no `locale`.
fn v1_decoder() -> decode.Decoder(Versioned) {
  use name <- decode.field("name", decode.string)
  decode.success(Versioned(name:, locale: "en"))
}

fn versioned_settings(kv) {
  storage.session_settings_from_storage_versioned(
    storage: kv,
    encode: encode_versioned,
    decode: versioned_decoder(),
    default: fn() { Versioned(name: "", locale: "en") },
    version: 2,
    migrate: fn(from, raw) {
      case from {
        0 | 1 -> decode.run(raw, v1_decoder()) |> result.replace_error(Nil)
        _ -> Error(Nil)
      }
    },
  )
}

pub fn a_versioned_session_round_trips_test() {
  let assert Ok(kv) = ets.new("scope_versioned_round_trip")
  let settings = versioned_settings(kv)

  let assert Ok(_) =
    settings.persist_session("k", Versioned(name: "Ada", locale: "uk"))

  settings.get_session("k")
  |> should.equal(Ok(Some(Versioned(name: "Ada", locale: "uk"))))

  // The envelope, not the bare value, is what is on disk.
  kv.get("session:k")
  |> should.equal(
    Ok(Some("{\"v\":2,\"d\":{\"name\":\"Ada\",\"locale\":\"uk\"}}")),
  )
}

pub fn an_older_schema_version_is_migrated_test() {
  let assert Ok(kv) = ets.new("scope_versioned_migrate")
  let assert Ok(Nil) = kv.set("session:k", "{\"v\":1,\"d\":{\"name\":\"Ada\"}}")

  versioned_settings(kv).get_session("k")
  |> should.equal(Ok(Some(Versioned(name: "Ada", locale: "en"))))
}

pub fn an_unversioned_value_is_migrated_as_version_zero_test() {
  let assert Ok(kv) = ets.new("scope_versioned_legacy")
  // Written by `session_settings_from_storage`, before this bot versioned its
  // sessions: no envelope at all.
  let assert Ok(Nil) = kv.set("session:k", "{\"name\":\"Ada\"}")

  versioned_settings(kv).get_session("k")
  |> should.equal(Ok(Some(Versioned(name: "Ada", locale: "en"))))
}

pub fn a_version_with_no_migration_reads_as_absent_test() {
  let assert Ok(kv) = ets.new("scope_versioned_future")
  // Written by a newer deploy: reading it half-populated would be worse than
  // starting over from the default.
  let assert Ok(Nil) = kv.set("session:k", "{\"v\":9,\"d\":{\"name\":\"Ada\"}}")

  versioned_settings(kv).get_session("k") |> should.equal(Ok(None))
}

// ---------------------------------------------------------------------------

fn drain(subject: process.Subject(a), acc: List(a)) -> List(a) {
  case process.receive(subject, 300) {
    Ok(event) -> drain(subject, [event, ..acc])
    Error(Nil) -> list.reverse(acc)
  }
}
