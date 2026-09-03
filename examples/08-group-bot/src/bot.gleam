//// A group bot whose state is not all the same shape.
////
//// Three scopes, three storage keys, one SQLite file:
////
//// - the **session** is per user per chat (`"{chat_id}:{from_id}"`) — how many
////   messages *you* have sent here;
//// - a **chat store** is per chat (`data:chat:{chat_id}`) — how many messages
////   everyone has sent here, which no single member's session could hold;
//// - a **global store** is per bot (`data:global:messages`) — the total.
////
//// And `/remind 1 stand up` schedules a **persisted job**: kill the bot,
//// start it again, and the reminder still arrives.

import envoy
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/int
import gleam/json
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp
import sqlight

import telega
import telega/bot.{type Context}
import telega/error.{type TelegaError}
import telega/jobs
import telega/reply
import telega/router
import telega/storage.{type KeyValueStorage}
import telega/store.{type Store}
import telega/update.{type Command}
import telega_httpc
import telega_storage_sqlite as sqlite

/// What this user has done in this chat. One row per `{chat_id}:{from_id}`.
pub type Session {
  Session(sent: Int)
}

pub type BotContext =
  Context(Session, TelegaError, Nil)

/// Everything the handlers need that is not in the update: the two stores and
/// the name the job scheduler is registered under.
pub type Deps {
  Deps(
    chat_total: Store(Int, TelegaError),
    grand_total: Store(Int, TelegaError),
    scheduler: process.Name(jobs.Message(Session, TelegaError, Deps)),
  )
}

pub type Ctx =
  Context(Session, TelegaError, Deps)

// --- handlers ---------------------------------------------------------------

fn count_message(ctx: Ctx, _text: String) -> Result(Ctx, TelegaError) {
  let Deps(chat_total:, grand_total:, ..) = ctx.dependencies

  // The chat's counter is shared by every member, so it cannot live in a
  // session — each member has their own.
  use _ <- result.try(store.update(ctx, chat_total, fn(n) { n + 1 }))
  use _ <- result.try(store.update(ctx, grand_total, fn(n) { n + 1 }))

  bot.next_session(ctx, Session(sent: ctx.session.sent + 1))
}

fn stats(ctx: Ctx, _command: Command) -> Result(Ctx, TelegaError) {
  let Deps(chat_total:, grand_total:, ..) = ctx.dependencies
  use here <- result.try(store.get(ctx, chat_total))
  use everywhere <- result.try(store.get(ctx, grand_total))

  reply.text(
    ctx,
    "you: "
      <> int.to_string(ctx.session.sent)
      <> "\nthis chat: "
      <> int.to_string(here)
      <> "\neverywhere: "
      <> int.to_string(everywhere),
  )
}

/// `/remind 5 water the plants`
fn remind(ctx: Ctx, command: Command) -> Result(Ctx, TelegaError) {
  case parse_reminder(command) {
    Error(Nil) -> reply.text(ctx, "usage: /remind <minutes> <what>")
    Ok(#(minutes, text)) -> {
      let scheduler = jobs.from_name(ctx.dependencies.scheduler)
      jobs.persisted(
        scheduler,
        // One pending reminder per user per chat; scheduling another replaces
        // it. Add a nonce here to allow several.
        id: "reminder:" <> ctx.key,
        handler: "reminder",
        chat_id: ctx.update.chat_id,
        user_id: ctx.update.from_id,
        at: timestamp.add(
          timestamp.system_time(),
          duration.milliseconds(minutes * 60_000),
        ),
        payload: json.object([#("text", json.string(text))]),
      )
      reply.text(ctx, "ok, in " <> int.to_string(minutes) <> " min")
    }
  }
}

fn parse_reminder(command: Command) -> Result(#(Int, String), Nil) {
  case string.split(string.trim(command.text), " ") {
    [_command, minutes, ..rest] -> {
      use minutes <- result.try(int.parse(minutes))
      use <- guard(minutes > 0)
      Ok(#(minutes, string.join(rest, " ")))
    }
    _ -> Error(Nil)
  }
}

fn guard(condition: Bool, continue: fn() -> Result(a, Nil)) -> Result(a, Nil) {
  case condition {
    True -> continue()
    False -> Error(Nil)
  }
}

/// What a stored reminder does when its time comes. It runs on a
/// `telega.background_context`, so replying works exactly as in a handler —
/// there is just no update that triggered it.
fn deliver_reminder(ctx: Ctx, payload) -> Nil {
  let text =
    decode.run(payload, decode.at(["text"], decode.string))
    |> result.unwrap("⏰")

  let _ = reply.text(ctx, "⏰ " <> text)
  Nil
}

pub fn build_router() -> router.Router(Session, TelegaError, Deps) {
  router.new("group_bot")
  |> router.on_command_with_description(
    "stats",
    "Messages here, and everywhere",
    stats,
  )
  |> router.on_command_with_description(
    "remind",
    "Remind me later: /remind <minutes> <what>",
    remind,
  )
  |> router.on_any_text(count_message)
}

// --- storage ----------------------------------------------------------------

fn encode_session(session: Session) -> json.Json {
  json.object([#("sent", json.int(session.sent))])
}

fn session_decoder() -> decode.Decoder(Session) {
  use sent <- decode.field("sent", decode.int)
  decode.success(Session(sent:))
}

/// Versioned from the start: the day `Session` grows a field, bump `version`
/// and read the old shape in `migrate` instead of resetting everyone to zero.
fn session_settings(kv: KeyValueStorage(TelegaError)) {
  storage.session_settings_from_storage_versioned(
    storage: kv,
    encode: encode_session,
    decode: session_decoder(),
    default: fn() { Session(sent: 0) },
    version: 1,
    migrate: fn(_from, raw) {
      // Version 0 is what an unversioned build wrote: the same shape, no
      // envelope around it.
      decode.run(raw, session_decoder()) |> result.replace_error(Nil)
    },
  )
}

fn counter(kv: KeyValueStorage(TelegaError)) {
  store.chat_data(
    storage: kv,
    encode: json.int,
    decode: decode.int,
    default: fn() { 0 },
  )
}

/// The SQLite adapter reports `sqlight.Error`; the bot's error type is
/// `TelegaError`, so the two are bridged once, here.
fn as_telega_errors(
  kv: KeyValueStorage(sqlight.Error),
) -> KeyValueStorage(TelegaError) {
  let wrap = fn(err) { error.ActorError(string.inspect(err)) }
  storage.KeyValueStorage(
    get: fn(key) { kv.get(key) |> result.map_error(wrap) },
    set: fn(key, value) { kv.set(key, value) |> result.map_error(wrap) },
    set_with_ttl: fn(key, value, ttl) {
      kv.set_with_ttl(key, value, ttl) |> result.map_error(wrap)
    },
    delete: fn(key) { kv.delete(key) |> result.map_error(wrap) },
    scan: fn(prefix) { kv.scan(prefix) |> result.map_error(wrap) },
  )
}

// --- wiring -----------------------------------------------------------------

pub fn main() {
  let assert Ok(token) = envoy.get("BOT_TOKEN")
  let assert Ok(db) = sqlight.open("group_bot.db")
  let assert Ok(Nil) = sqlite.migrate(db)
  let kv = sqlite.new(db) |> as_telega_errors

  // The scheduler is started *after* the bot (it needs the running instance),
  // but handlers need to reach it — so it is registered under a name they can
  // resolve.
  let scheduler_name = process.new_name("group_bot_jobs")

  let dependencies =
    Deps(
      chat_total: counter(kv),
      grand_total: store.global_data(
        name: "messages",
        storage: kv,
        encode: json.int,
        decode: decode.int,
        default: fn() { 0 },
      ),
      scheduler: scheduler_name,
    )

  let assert Ok(bot) =
    telega.new_for_polling_with_dependencies(
      api_client: telega_httpc.new(token),
      dependencies:,
    )
    |> telega.with_router(build_router())
    |> telega.with_session_settings(session_settings(kv))
    // A database that is briefly unreadable should not take the bot with it:
    // handlers keep answering, and nothing overwrites the stored session.
    |> telega.with_session_load_error(bot.ReadOnly)
    |> telega.with_auto_commands()
    |> telega.init_for_polling()

  let assert Ok(_scheduler) =
    jobs.new(bot)
    |> jobs.with_name(scheduler_name)
    |> jobs.with_storage(kv)
    |> jobs.with_handler("reminder", deliver_reminder)
    // A chore with no user waiting on it: in memory is enough.
    |> jobs.with_handler("noop", fn(_ctx, _payload) { Nil })
    |> jobs.start()

  process.sleep_forever()
}
