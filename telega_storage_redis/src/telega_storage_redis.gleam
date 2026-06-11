//// Redis/Valkey storage adapter for Telega.
////
//// Implements `telega/storage.KeyValueStorage` on top of a Valkyrie connection
//// pool. TTL is handled natively by the server (`EXPIRE`), so expired keys are
//// removed automatically — no lazy cleanup needed. `scan` uses cursor-based
//// `SCAN` over a key prefix, which is safe for production unlike `KEYS`.

import gleam/list
import gleam/option.{None, Some}
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
      case valkyrie.set(conn, key, value, None, timeout) {
        Ok(_) ->
          case
            valkyrie.expire(conn, key, ms_to_seconds(ttl_ms), None, timeout)
          {
            Ok(_) -> Ok(Nil)
            Error(err) -> Error(err)
          }
        Error(err) -> Error(err)
      }
    },
    delete: fn(key) {
      case valkyrie.del(conn, [key], timeout) {
        Ok(_) -> Ok(Nil)
        Error(err) -> Error(err)
      }
    },
    scan: fn(prefix) { scan_all(conn, prefix <> "*", 0, [], timeout) },
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

/// Redis `EXPIRE` works in whole seconds; round up so a sub-second TTL still
/// lives for at least one second. A non-positive TTL expires immediately.
fn ms_to_seconds(ttl_ms: Int) -> Int {
  case ttl_ms <= 0 {
    True -> 0
    False -> { ttl_ms + 999 } / 1000
  }
}
