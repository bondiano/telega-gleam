//// Unified key-value storage contract shared by sessions and flows.
////
//// `KeyValueStorage` is the single low-level contract that every backend
//// implements (ETS in core; Postgres/SQLite/Redis as separate packages).
//// Values are opaque `String`s — callers serialize to/from JSON themselves.
////
//// The two bridges below derive the higher-level `SessionSettings` and
//// `FlowStorage` contracts from a single `KeyValueStorage`, so a bot only
//// needs to wire up one backend for both sessions and flows.

import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import telega/bot.{type SessionSettings, SessionSettings}
import telega/flow/instance
import telega/flow/types.{type FlowInstance, type FlowStorage, FlowStorage}

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
/// falls back to `default` instead of crashing on a corrupt or migrated value.
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
            Error(_) -> Ok(None)
          }
      }
    },
    default_session: default,
  )
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
  FlowStorage(
    save: fn(inst: FlowInstance) {
      storage.set(flow_prefix <> inst.id, instance.to_json_string(inst))
    },
    load: fn(id) {
      use maybe <- result.try(storage.get(flow_prefix <> id))
      case maybe {
        None -> Ok(None)
        Some(raw) ->
          case instance.from_json_string(raw) {
            Ok(inst) -> Ok(Some(inst))
            Error(_) -> Ok(None)
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
              Error(_) -> Ok(acc)
            }
        }
      })
    },
  )
}
