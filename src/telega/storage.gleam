//// Unified key-value storage contract shared by sessions and flows.
////
//// `KeyValueStorage` is the single low-level contract that every backend
//// implements (ETS in core; Postgres/SQLite/Redis as separate packages).
//// Values are opaque `String`s — callers serialize to/from JSON themselves.
////
//// The two bridges below derive the higher-level `SessionSettings` and
//// `FlowStorage` contracts from a single `KeyValueStorage`, so a bot only
//// needs to wire up one backend for both sessions and flows.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/bot.{type SessionSettings, SessionSettings}
import telega/dead_letter
import telega/flow/instance
import telega/flow/types.{type FlowInstance, type FlowStorage, FlowStorage}
import telega/internal/log
import telega/telemetry

/// Backend-agnostic key-value store.
///
/// - `get` returns `None` for a missing key.
/// - `set` stores a value with no expiration.
/// - `set_with_ttl` stores a value that expires after `ttl_ms` milliseconds.
///   Backends without native TTL emulate it with lazy expiration on access.
/// - `scan` returns every key beginning with the given prefix (live keys only).
pub type KeyValueStorage(error) {
  KeyValueStorage(
    get: fn(String) -> Result(Option(String), error),
    set: fn(String, String) -> Result(Nil, error),
    set_with_ttl: fn(String, String, Int) -> Result(Nil, error),
    delete: fn(String) -> Result(Nil, error),
    scan: fn(String) -> Result(List(String), error),
  )
}

const session_prefix = "session:"

const flow_prefix = "flow:"

/// Derive `SessionSettings` from a `KeyValueStorage`.
///
/// Sessions are stored under the `session:` key namespace as JSON produced by
/// `encode`. A decode failure on load is treated as "no session" so the bot
/// falls back to `default` instead of crashing on a corrupt or migrated value —
/// but it is reported first (`telega.storage.decode_error` telemetry plus an
/// error log), because the next handler will persist that default over the
/// value that failed to decode.
pub fn session_settings_from_storage(
  storage storage: KeyValueStorage(error),
  encode encode: fn(session) -> json.Json,
  decode decoder: decode.Decoder(session),
  default default: fn() -> session,
) -> SessionSettings(session, error) {
  SessionSettings(
    persist_session: fn(key, session) {
      let payload = encode(session) |> json.to_string
      storage.set(session_prefix <> key, payload)
      |> result.map(fn(_) { session })
    },
    get_session: fn(key) {
      use maybe <- result.try(storage.get(session_prefix <> key))
      case maybe {
        None -> Ok(None)
        Some(raw) ->
          case json.parse(raw, decoder) {
            Ok(session) -> Ok(Some(session))
            Error(err) -> {
              report_decode_error("session", key, string.inspect(err))
              Ok(None)
            }
          }
      }
    },
    default_session: default,
  )
}

/// Derive `SessionSettings` that carry a schema version.
///
/// The stored value is wrapped in `{"v": <version>, "d": <encoded session>}`,
/// so a build that changes the shape of its session can still read what an
/// older build wrote. On load:
///
/// - the envelope's version matches → decode with `decode`;
/// - it does not → hand `migrate` the stored version and the raw payload;
/// - there is no envelope (the value was written by
///   [`session_settings_from_storage`](#session_settings_from_storage)) → the
///   version is `0` and `migrate` gets the whole value.
///
/// A `migrate` returning `Error(Nil)` is treated exactly like a value that
/// will not decode: reported, then read as "no session", so the caller falls
/// back to `default`.
///
/// ```gleam
/// storage.session_settings_from_storage_versioned(
///   storage:,
///   encode: encode_session,
///   decode: session_decoder(),
///   default: fn() { Session(name: "", locale: "en") },
///   version: 2,
///   migrate: fn(from, raw) {
///     case from {
///       // v1 had no `locale`.
///       1 -> decode.run(raw, v1_decoder()) |> result.replace_error(Nil)
///       _ -> Error(Nil)
///     }
///   },
/// )
/// ```
pub fn session_settings_from_storage_versioned(
  storage storage: KeyValueStorage(error),
  encode encode: fn(session) -> json.Json,
  decode decoder: decode.Decoder(session),
  default default: fn() -> session,
  version version: Int,
  migrate migrate: fn(Int, Dynamic) -> Result(session, Nil),
) -> SessionSettings(session, error) {
  SessionSettings(
    persist_session: fn(key, session) {
      let payload =
        json.object([#("v", json.int(version)), #("d", encode(session))])
        |> json.to_string
      storage.set(session_prefix <> key, payload)
      |> result.map(fn(_) { session })
    },
    get_session: fn(key) {
      use maybe <- result.try(storage.get(session_prefix <> key))
      case maybe {
        None -> Ok(None)
        Some(raw) ->
          case read_versioned(raw, decoder, version, migrate) {
            Ok(session) -> Ok(Some(session))
            Error(reason) -> {
              report_decode_error("session", key, reason)
              Ok(None)
            }
          }
      }
    },
    default_session: default,
  )
}

type Envelope {
  Envelope(version: Int, data: Dynamic)
}

fn envelope_decoder() -> decode.Decoder(Envelope) {
  use version <- decode.field("v", decode.int)
  use data <- decode.field("d", decode.dynamic)
  decode.success(Envelope(version:, data:))
}

fn read_versioned(
  raw: String,
  decoder: decode.Decoder(session),
  version: Int,
  migrate: fn(Int, Dynamic) -> Result(session, Nil),
) -> Result(session, String) {
  use value <- result.try(
    json.parse(raw, decode.dynamic)
    |> result.map_error(fn(err) { string.inspect(err) }),
  )
  let #(stored_version, payload) = case decode.run(value, envelope_decoder()) {
    Ok(Envelope(version:, data:)) -> #(version, data)
    // No envelope: written before this session was versioned.
    Error(_) -> #(0, value)
  }
  case stored_version == version {
    True ->
      decode.run(payload, decoder)
      |> result.map_error(fn(errs) { string.inspect(errs) })
    False ->
      migrate(stored_version, payload)
      |> result.replace_error(
        "no migration from schema version " <> int.to_string(stored_version),
      )
  }
}

/// Derive `FlowStorage` from a `KeyValueStorage`.
///
/// Flow instances are stored under the `flow:` key namespace as complete JSON
/// (see `instance.to_json`), so subflows and parallel state survive restarts.
/// `list_by_user` is served by `scan` over the namespace, replacing the
/// secondary index used by the legacy ETS-only implementation.
pub fn flow_storage_from_storage(
  storage storage: KeyValueStorage(error),
) -> FlowStorage(error) {
  do_flow_storage(storage, None)
}

/// Derive `FlowStorage` that lets the backend reclaim abandoned instances.
///
/// Every save renews the entry, so `retention_ms` is "how long an instance may
/// sit untouched before the backend drops it". Redis expires it natively; the
/// ETS and SQL backends expire lazily on access and skip expired keys in
/// `scan`. Without this, a flow a user walked away from stays in storage
/// forever — nothing sweeps it.
///
/// Pick a retention comfortably longer than the flow's `builder.with_ttl`:
/// once the entry is gone the instance simply looks absent, so `on_timeout`
/// will not fire for it and the user's next message starts a fresh flow.
pub fn flow_storage_from_storage_with_retention(
  storage storage: KeyValueStorage(error),
  retention_ms retention_ms: Int,
) -> FlowStorage(error) {
  do_flow_storage(storage, Some(retention_ms))
}

fn do_flow_storage(
  storage: KeyValueStorage(error),
  retention_ms: Option(Int),
) -> FlowStorage(error) {
  FlowStorage(
    save: fn(inst: FlowInstance) {
      let key = flow_prefix <> inst.id
      let payload = instance.to_json_string(inst)
      case retention_ms {
        Some(ttl) -> storage.set_with_ttl(key, payload, ttl)
        None -> storage.set(key, payload)
      }
    },
    load: fn(id) {
      use maybe <- result.try(storage.get(flow_prefix <> id))
      case maybe {
        None -> Ok(None)
        Some(raw) ->
          case instance.from_json_string(raw) {
            Ok(inst) -> Ok(Some(inst))
            Error(err) -> {
              report_decode_error("flow", id, string.inspect(err))
              Ok(None)
            }
          }
      }
    },
    delete: fn(id) { storage.delete(flow_prefix <> id) },
    list_by_user: fn(user_id, chat_id) {
      use keys <- result.try(storage.scan(flow_prefix))
      list.try_fold(keys, [], fn(acc, key) {
        use maybe <- result.try(storage.get(key))
        case maybe {
          None -> Ok(acc)
          Some(raw) ->
            case instance.from_json_string(raw) {
              Ok(inst) ->
                case inst.user_id == user_id && inst.chat_id == chat_id {
                  True -> Ok([inst, ..acc])
                  False -> Ok(acc)
                }
              Error(err) -> {
                report_decode_error("flow", key, string.inspect(err))
                Ok(acc)
              }
            }
        }
      })
    },
  )
}

/// A stored value that will not decode is not the same as a missing one: the
/// caller falls back to a default and then persists it *over* the value that
/// failed. Say so loudly — a schema change is the usual cause.
fn report_decode_error(kind: String, key: String, reason: String) -> Nil {
  log.error(
    "[storage] failed to decode stored "
    <> kind
    <> " '"
    <> key
    <> "' — falling back to the default, which will overwrite it: "
    <> reason,
  )
  telemetry.execute(["telega", "storage", "decode_error"], [#("count", 1)], [
    #("kind", telemetry.StringValue(kind)),
    #("key", telemetry.StringValue(key)),
  ])
}

/// Derive a [dead-letter queue](dead_letter.html) from a `KeyValueStorage`.
///
/// Letters live under the `dlq:` prefix, alongside sessions (`session:`) and
/// flows (`flow:`), so one backend covers all three. The backend's error type
/// is flattened to a `String` — a dead letter is written from the bot actor's
/// crash path, where nothing matches on it.
///
/// `retention_ms` bounds how long a letter is kept. `None` keeps letters until
/// they are replayed or dropped, which is what you want while debugging and
/// not what you want unattended: a bot crashing in a loop writes one entry per
/// distinct `update_id`.
///
/// ```gleam
/// telega.with_dead_letters(
///   builder,
///   storage.dead_letters_from_storage(storage, retention_ms: Some(604_800_000)),
/// )
/// ```
pub fn dead_letters_from_storage(
  storage storage: KeyValueStorage(error),
  retention_ms retention_ms: Option(Int),
) -> dead_letter.DeadLetters {
  dead_letter.new(
    put: fn(key, payload) {
      case retention_ms {
        Some(ttl) -> storage.set_with_ttl(key, payload, ttl)
        None -> storage.set(key, payload)
      }
      |> result.map_error(string.inspect)
    },
    keys: fn() {
      storage.scan(dead_letter.prefix) |> result.map_error(string.inspect)
    },
    read: fn(key) { storage.get(key) |> result.map_error(string.inspect) },
    drop: fn(key) { storage.delete(key) |> result.map_error(string.inspect) },
  )
}
