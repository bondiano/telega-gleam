//// Redis/Valkey storage adapter for Telega.
////
//// Implements `telega/storage.KeyValueStorage` on top of a Valkyrie connection
//// pool. TTL is handled natively by the server (`SET PX`), so expired keys are
//// removed automatically — no lazy cleanup needed. `scan` is Redis's own
//// cursor-based `SCAN` over a key prefix, which is safe for production unlike
//// `KEYS`, and `compare_and_set` is one Lua script, so the check and the
//// write run as one command.

import gleam/int
import gleam/option.{None, Some}
import gleam/string
import telega/storage.{type KeyValueStorage, KeyValueStorage}
import valkyrie
import valkyrie/resp

const default_timeout = 5000

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
    compare_and_set: fn(key, expected, value, ttl_ms) {
      // One EVAL: the server runs the script without interleaving commands.
      let #(absent, current) = case expected {
        None -> #("1", "")
        Some(current) -> #("0", current)
      }
      let px = case ttl_ms {
        None -> ""
        Some(ms) -> int.to_string(ms)
      }
      case
        valkyrie.custom(
          conn,
          ["EVAL", compare_and_set_script, "1", key, absent, current, value, px],
          timeout,
        )
      {
        Ok([resp.Integer(1)]) -> Ok(True)
        Ok(_) -> Ok(False)
        Error(err) -> Error(err)
      }
    },
    delete: fn(key) {
      case valkyrie.del(conn, [key], timeout) {
        Ok(_) -> Ok(Nil)
        Error(err) -> Error(err)
      }
    },
    scan: fn(prefix, cursor, limit) {
      let cursor =
        cursor
        |> option.then(fn(c) { int.parse(c) |> option.from_result })
        |> option.unwrap(0)
      let pattern = Some(escape_glob(prefix) <> "*")
      case valkyrie.scan(conn, cursor, pattern, limit, None, timeout) {
        Ok(#(keys, 0)) -> Ok(#(keys, None))
        Ok(#(keys, next)) -> Ok(#(keys, Some(int.to_string(next))))
        Error(err) -> Error(err)
      }
    },
  )
}

/// KEYS[1] the key; ARGV: "1" when the key is expected absent, else the
/// expected value; the new value; the ttl in ms, "" for none. A ttl of zero
/// or less is a write that has already expired, so the key is deleted.
const compare_and_set_script =
  "
local current = redis.call('GET', KEYS[1])
if ARGV[1] == '1' then
  if current then return 0 end
elseif current ~= ARGV[2] then
  return 0
end
if ARGV[4] == '' then
  redis.call('SET', KEYS[1], ARGV[3])
elseif tonumber(ARGV[4]) <= 0 then
  redis.call('DEL', KEYS[1])
else
  redis.call('SET', KEYS[1], ARGV[3], 'PX', ARGV[4])
end
return 1
"

/// `SCAN MATCH` is a glob; `*`, `?`, `[` and `\\` in a prefix must match
/// literally.
fn escape_glob(prefix: String) -> String {
  prefix
  |> string.replace("\\", "\\\\")
  |> string.replace("*", "\\*")
  |> string.replace("?", "\\?")
  |> string.replace("[", "\\[")
}
