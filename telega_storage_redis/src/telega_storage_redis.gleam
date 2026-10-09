//// Redis/Valkey storage adapter for Telega.
////
//// Implements `telega/storage.KeyValueStorage` on top of a Valkyrie connection
//// pool. TTL is handled natively by the server (`SET PX`), so expired keys are
//// removed automatically — no lazy cleanup needed. `scan` uses cursor-based
//// `SCAN` over a key prefix, which is safe for production unlike `KEYS`.

import gleam/list
import gleam/option.{None, Some}
import gleam/string
import telega/storage.{type KeyValueStorage, KeyValueStorage}
import valkyrie

const default_timeout = 5000

const scan_count = 100

/// Build a `KeyValueStorage` from a Valkyrie connection (default 5s timeout).
///
/// The caller owns the connection pool (typically started under a supervisor);
/// see the valkyrie docs for setup.
pub fn new(conn: valkyrie.Connection) -> KeyValueStorage(valkyrie.Error) {
  new_with_timeout(conn, default_timeout)
}

/// Like `new`, but with a custom per-command timeout in milliseconds.
pub fn new_with_timeout(
  conn: valkyrie.Connection,
  timeout: Int,
) -> KeyValueStorage(valkyrie.Error) {
  KeyValueStorage(
    get: fn(key) {
      case valkyrie.get(conn, key, timeout) {
        Ok(value) -> Ok(Some(value))
        Error(valkyrie.NotFound) -> Ok(None)
        Error(err) -> Error(err)
      }
    },
    set: fn(key, value) {
      case valkyrie.set(conn, key, value, None, timeout) {
        Ok(_) -> Ok(Nil)
        Error(err) -> Error(err)
      }
    },
    set_with_ttl: fn(key, value, ttl_ms) {
      case ttl_ms <= 0 {
        // Already expired: the key must read as missing right away, which a
        // 1 ms expiry does not guarantee.
        True ->
          case valkyrie.del(conn, [key], timeout) {
            Ok(_) -> Ok(Nil)
            Error(err) -> Error(err)
          }
        // One `SET ... PX`: a `SET` followed by `EXPIRE` leaves a key that
        // never expires if the second call fails.
        False -> {
          let options =
            valkyrie.SetOptions(
              ..valkyrie.default_set_options(),
              expiry_option: Some(valkyrie.ExpiryMilliseconds(ttl_ms)),
            )
          case valkyrie.set(conn, key, value, Some(options), timeout) {
            Ok(_) -> Ok(Nil)
            Error(err) -> Error(err)
          }
        }
      }
    },
    delete: fn(key) {
      case valkyrie.del(conn, [key], timeout) {
        Ok(_) -> Ok(Nil)
        Error(err) -> Error(err)
      }
    },
    scan: fn(prefix) {
      scan_all(conn, escape_glob(prefix) <> "*", 0, [], timeout)
    },
  )
}

fn scan_all(
  conn: valkyrie.Connection,
  pattern: String,
  cursor: Int,
  acc: List(String),
  timeout: Int,
) -> Result(List(String), valkyrie.Error) {
  case valkyrie.scan(conn, cursor, Some(pattern), scan_count, None, timeout) {
    Ok(#(keys, next_cursor)) -> {
      let acc = list.append(acc, keys)
      case next_cursor {
        0 -> Ok(acc)
        _ -> scan_all(conn, pattern, next_cursor, acc, timeout)
      }
    }
    Error(err) -> Error(err)
  }
}

/// `SCAN MATCH` is a glob; `*`, `?`, `[` and `\\` in a prefix must match
/// literally.
fn escape_glob(prefix: String) -> String {
  prefix
  |> string.replace("\\", "\\\\")
  |> string.replace("*", "\\*")
  |> string.replace("?", "\\?")
  |> string.replace("[", "\\[")
}
