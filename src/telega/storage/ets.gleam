//// ETS-backed `KeyValueStorage` with lazy TTL expiration.
////
//// Values live in a public, named ETS table for the lifetime of the VM but do
//// NOT survive a VM restart. TTL is enforced lazily: an expired entry is only
//// removed when it is next accessed via `get` or `scan`. For persistence
//// across restarts use a database-backed package (Postgres/SQLite/Redis).

import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom.{type Atom}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/string
import telega/error.{type TelegaError}
import telega/internal/utils
import telega/storage.{type KeyValueStorage, KeyValueStorage}

type EtsTable

/// Create an ETS-backed `KeyValueStorage`.
///
/// `name` is the ETS table name; reusing the same name returns a handle to the
/// existing table. The error type stays generic because none of the operations
/// can fail, so the result composes with flows/sessions of any error type.
pub fn new(name name: String) -> Result(KeyValueStorage(error), TelegaError) {
  let table = start_table(atom.create(name))
  Ok(
    KeyValueStorage(
      get: fn(key) { Ok(do_get(table, key)) },
      set: fn(key, value) {
        ets_insert(table, #(key, value, 0))
        Ok(Nil)
      },
      set_with_ttl: fn(key, value, ttl_ms) {
        ets_insert(table, #(key, value, utils.current_time_ms() + ttl_ms))
        Ok(Nil)
      },
      compare_and_set: fn(key, expected, value, ttl_ms) {
        let now = utils.current_time_ms()
        let expires_at = case ttl_ms {
          None -> 0
          Some(ms) -> now + ms
        }
        Ok(ets_compare_and_set(table, key, expected, value, expires_at, now))
      },
      delete: fn(key) {
        ets_delete(table, key)
        Ok(Nil)
      },
      scan: fn(prefix, cursor, limit) {
        let page = do_scan(table, prefix, cursor, limit)
        Ok(#(page, storage.next_cursor(page, limit)))
      },
    ),
  )
}

fn start_table(name: Atom) -> EtsTable {
  case is_undefined(ets_whereis_raw(name)) {
    True ->
      ets_new(name, [
        atom.create("set"),
        atom.create("public"),
        atom.create("named_table"),
      ])
    False -> coerce(ets_whereis_raw(name))
  }
}

/// An `expires_at` of `0` means "never expires".
fn is_live(expires_at: Int) -> Bool {
  expires_at == 0 || utils.current_time_ms() < expires_at
}

fn do_get(table: EtsTable, key: String) -> Option(String) {
  case ets_lookup(table, key) {
    [] -> None
    [#(_, value, expires_at), ..] ->
      case is_live(expires_at) {
        True -> Some(value)
        False -> {
          ets_delete(table, key)
          None
        }
      }
  }
}

/// The live keys under `prefix` in key order, `limit` of them past `after`.
/// A `set` table has no order, so every page is a pass over the table —
/// fine for the in-memory sizes ETS holds.
fn do_scan(
  table: EtsTable,
  prefix: String,
  after: Option(String),
  limit: Int,
) -> List(String) {
  ets_tab2list(table)
  |> list.filter_map(fn(entry) {
    let #(key, _value, expires_at) = entry
    case
      string.starts_with(key, prefix)
      && is_live(expires_at)
      && is_after(key, after)
    {
      True -> Ok(key)
      False -> Error(Nil)
    }
  })
  |> list.sort(string.compare)
  |> list.take(limit)
}

fn is_after(key: String, cursor: Option(String)) -> Bool {
  case cursor {
    None -> True
    Some(cursor) -> string.compare(key, cursor) == order.Gt
  }
}

@external(erlang, "ets", "whereis")
fn ets_whereis_raw(name: Atom) -> Dynamic

fn is_undefined(value: Dynamic) -> Bool {
  case atom.get("undefined") {
    Ok(undefined) -> value == atom.to_dynamic(undefined)
    Error(_) -> False
  }
}

@external(erlang, "gleam_stdlib", "identity")
fn coerce(value: Dynamic) -> EtsTable

@external(erlang, "ets", "new")
fn ets_new(name: Atom, options: List(Atom)) -> EtsTable

@external(erlang, "ets", "insert")
fn ets_insert(table: EtsTable, tuple: #(String, String, Int)) -> Bool

@external(erlang, "ets", "lookup")
fn ets_lookup(table: EtsTable, key: String) -> List(#(String, String, Int))

@external(erlang, "ets", "delete")
fn ets_delete(table: EtsTable, key: String) -> Bool

@external(erlang, "ets", "tab2list")
fn ets_tab2list(table: EtsTable) -> List(#(String, String, Int))

@external(erlang, "telega_ets_ffi", "compare_and_set")
fn ets_compare_and_set(
  table: EtsTable,
  key: String,
  expected: Option(String),
  value: String,
  expires_at: Int,
  now: Int,
) -> Bool
