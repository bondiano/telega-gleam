//// Shared state that is **not** the session: data keyed by chat, by user, or
//// by nothing at all.
////
//// A session belongs to one chat instance — one `{chat_id}:{from_id}` pair by
//// default — and is loaded once when that instance starts. That is exactly
//// wrong for state several instances share: a group counter every member
//// bumps, a chat-wide language, a global feature flag. Cached per instance it
//// would go stale the moment another member wrote it.
////
//// So a `Store` is not cached. Every read goes to the backend and every write
//// goes straight back, which is what makes concurrent readers correct. In
//// exchange each access costs a storage round-trip, so put per-user state
//// that only its own handlers touch in the session, and reach for a store for
//// the things the session cannot express.
////
//// ```gleam
//// // One counter per chat, shared by everyone in it.
//// let counters =
////   store.chat_data(
////     storage: ets_storage,
////     encode: json.int,
////     decode: decode.int,
////     default: fn() { 0 },
////   )
////
//// fn handle_message(ctx, _msg) {
////   use total <- result.try(
////     store.update(ctx, counters, fn(n) { n + 1 })
////     |> result.map_error(StorageError),
////   )
////   reply.with_text(ctx, "messages here: " <> int.to_string(total))
//// }
//// ```
////
//// Stores are plain values: build one at startup, put it in `dependencies`
//// (or a module constant) and hand it to whichever handlers need it. Nothing
//// needs to be registered on the builder.
////
//// **Read-modify-write is not atomic.** `update` reads, applies your function
//// and writes; two chat instances doing that at the same time can lose one of
//// the increments. Where that matters, key the *session* by chat instead
//// (`telega.with_session_key(bot.chat_session_key)`) so every member's update
//// is serialized through one process, and keep stores for state that is
//// written rarely or by one writer.

import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/bot.{type Context}
import telega/internal/log
import telega/storage.{type KeyValueStorage}
import telega/telemetry
import telega/update.{type Update}

/// A typed view of one key-space in a `KeyValueStorage`.
///
/// Built by [`chat_data`](#chat_data), [`user_data`](#user_data),
/// [`global_data`](#global_data) or [`custom`](#custom), and read through
/// [`get`](#get) / [`set`](#set) / [`update`](#update) / [`delete`](#delete).
pub opaque type Store(value, error) {
  Store(
    key_of: fn(Update) -> String,
    encode: fn(value) -> json.Json,
    decoder: decode.Decoder(value),
    default: fn() -> value,
    storage: KeyValueStorage(error),
    ttl_ms: Option(Int),
  )
}

const data_prefix = "data:"

/// One value per chat, keyed `data:chat:{chat_id}` — the group's own state,
/// shared by every member.
pub fn chat_data(
  storage storage: KeyValueStorage(error),
  encode encode: fn(value) -> json.Json,
  decode decoder: decode.Decoder(value),
  default default: fn() -> value,
) -> Store(value, error) {
  custom(
    key: bot.chat_session_key,
    storage:,
    encode:,
    decode: decoder,
    default:,
  )
}

/// One value per user, keyed `data:user:{from_id}` — state that follows the
/// user from chat to chat.
///
/// Updates that carry no user (a poll update, a channel post) key as
/// `user:-1`; see `docs/session-serialization.md`.
pub fn user_data(
  storage storage: KeyValueStorage(error),
  encode encode: fn(value) -> json.Json,
  decode decoder: decode.Decoder(value),
  default default: fn() -> value,
) -> Store(value, error) {
  custom(
    key: bot.user_session_key,
    storage:,
    encode:,
    decode: decoder,
    default:,
  )
}

/// One value for the whole bot, keyed `data:global:{name}` — a feature flag, a
/// counter of everything, the id of the current broadcast.
pub fn global_data(
  name name: String,
  storage storage: KeyValueStorage(error),
  encode encode: fn(value) -> json.Json,
  decode decoder: decode.Decoder(value),
  default default: fn() -> value,
) -> Store(value, error) {
  custom(
    key: fn(_) { "global:" <> name },
    storage:,
    encode:,
    decode: decoder,
    default:,
  )
}

/// A store keyed by anything the update can answer — a forum topic, a business
/// connection, the chat's owner.
pub fn custom(
  key key_of: fn(Update) -> String,
  storage storage: KeyValueStorage(error),
  encode encode: fn(value) -> json.Json,
  decode decoder: decode.Decoder(value),
  default default: fn() -> value,
) -> Store(value, error) {
  Store(key_of:, encode:, decoder:, default:, storage:, ttl_ms: None)
}

/// Expire written values after `ttl_ms` milliseconds.
///
/// Every write renews the entry, so this is "how long the value may sit
/// untouched before the backend drops it". Once it is gone a read simply
/// returns the store's default.
pub fn with_ttl(
  store: Store(value, error),
  ttl_ms: Int,
) -> Store(value, error) {
  Store(..store, ttl_ms: Some(ttl_ms))
}

/// The key this store uses for the update in `ctx`.
pub fn key(
  ctx: Context(session, error_, dependencies),
  store: Store(value, error),
) -> String {
  store.key_of(ctx.update)
}

/// Read the value for this update's key, or the store's default when nothing
/// is stored yet.
///
/// A stored value that will not decode is reported (error log plus
/// `telega.storage.decode_error` telemetry) and read as absent, the same rule
/// sessions follow — the next write overwrites it.
pub fn get(
  ctx: Context(session, error_, dependencies),
  store: Store(value, error),
) -> Result(value, error) {
  get_at(store, key(ctx, store))
}

/// Read the value stored at an explicit key.
///
/// The escape hatch for code with no `Context` to derive one from — a job, a
/// migration, an admin command reading another chat's data. The key is the one
/// [`key`](#key) would have produced, without the `data:` prefix.
pub fn get_at(store: Store(value, error), key: String) -> Result(value, error) {
  use raw <- result.try(store.storage.get(data_prefix <> key))
  case raw {
    None -> Ok(store.default())
    Some(raw) ->
      case json.parse(raw, store.decoder) {
        Ok(value) -> Ok(value)
        Error(err) -> {
          report_decode_error(key, err)
          Ok(store.default())
        }
      }
  }
}

/// Write the value for this update's key.
pub fn set(
  ctx: Context(session, error_, dependencies),
  store: Store(value, error),
  value: value,
) -> Result(Nil, error) {
  set_at(store, key(ctx, store), value)
}

/// Write the value at an explicit key. See [`get_at`](#get_at).
pub fn set_at(
  store: Store(value, error),
  key: String,
  value: value,
) -> Result(Nil, error) {
  let payload = store.encode(value) |> json.to_string
  case store.ttl_ms {
    None -> store.storage.set(data_prefix <> key, payload)
    Some(ttl) -> store.storage.set_with_ttl(data_prefix <> key, payload, ttl)
  }
}

/// Read, apply `change`, write back, and return the written value.
///
/// Not atomic: two instances updating the same key at the same time can lose
/// one of the changes (see the module docs).
pub fn update(
  ctx: Context(session, error_, dependencies),
  store: Store(value, error),
  change: fn(value) -> value,
) -> Result(value, error) {
  update_at(store, key(ctx, store), change)
}

/// Read-modify-write at an explicit key. See [`get_at`](#get_at).
pub fn update_at(
  store: Store(value, error),
  key: String,
  change: fn(value) -> value,
) -> Result(value, error) {
  use current <- result.try(get_at(store, key))
  let next = change(current)
  use _ <- result.try(set_at(store, key, next))
  Ok(next)
}

/// Forget the value for this update's key. A later read returns the default.
pub fn delete(
  ctx: Context(session, error_, dependencies),
  store: Store(value, error),
) -> Result(Nil, error) {
  delete_at(store, key(ctx, store))
}

/// Forget the value at an explicit key. See [`get_at`](#get_at).
pub fn delete_at(
  store: Store(value, error),
  key: String,
) -> Result(Nil, error) {
  store.storage.delete(data_prefix <> key)
}

fn report_decode_error(key: String, err: json.DecodeError) -> Nil {
  log.error(
    "[store] failed to decode the value stored at '"
    <> key
    <> "' — reading the default instead: "
    <> string.inspect(err),
  )
  telemetry.execute(["telega", "storage", "decode_error"], [#("count", 1)], [
    #("kind", telemetry.StringValue("store")),
    #("key", telemetry.StringValue(key)),
  ])
}
