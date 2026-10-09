//// SQLite storage adapter for Telega.
////
//// Implements `telega/storage.KeyValueStorage` on top of a single SQLite
//// table, giving small bots single-file persistence that survives restarts.
//// TTL is stored as an epoch-millisecond `expires_at` column and enforced
//// lazily on access (`get`/`scan`), matching the core ETS backend.

import gleam/dynamic/decode
import gleam/erlang/atom
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import sqlight
import telega/storage.{type KeyValueStorage, KeyValueStorage}

/// Build a `KeyValueStorage` backed by the given SQLite connection.
///
/// Uses the default table name `telega_storage`. Call `migrate` once at startup
/// to create the table.
pub fn new(conn: sqlight.Connection) -> KeyValueStorage(sqlight.Error) {
  new_with_table(conn, default_table)
}

/// Like `new`, but with a custom table name.
pub fn new_with_table(
  conn: sqlight.Connection,
  table: String,
) -> KeyValueStorage(sqlight.Error) {
  KeyValueStorage(
    get: fn(key) { do_get(conn, table, key) },
    set: fn(key, value) { do_set(conn, table, key, value, None) },
    set_with_ttl: fn(key, value, ttl_ms) {
      do_set(conn, table, key, value, Some(now_ms() + ttl_ms))
    },
    compare_and_set: fn(key, expected, value, ttl_ms) {
      do_compare_and_set(conn, table, key, expected, value, ttl_ms)
    },
    delete: fn(key) { do_delete(conn, table, key) },
    scan: fn(prefix, cursor, limit) {
      do_scan(conn, table, prefix, cursor, limit)
    },
  )
}

const default_table = "telega_storage"

/// Create the storage table if it does not exist. Run once at startup.
pub fn migrate(conn: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  migrate_table(conn, default_table)
}

/// Create a custom-named storage table if it does not exist.
pub fn migrate_table(
  conn: sqlight.Connection,
  table: String,
) -> Result(Nil, sqlight.Error) {
  sqlight.exec(
    "CREATE TABLE IF NOT EXISTS "
      <> table
      <> " (key TEXT PRIMARY KEY, value TEXT NOT NULL, expires_at INTEGER)",
    conn,
  )
}

fn do_get(
  conn: sqlight.Connection,
  table: String,
  key: String,
) -> Result(Option(String), sqlight.Error) {
  let decoder = {
    use value <- decode.field(0, decode.string)
    use expires_at <- decode.field(1, decode.optional(decode.int))
    decode.success(#(value, expires_at))
  }
  let sql =
    "SELECT value, expires_at FROM " <> table <> " WHERE key = ? LIMIT 1"
  case
    sqlight.query(sql, on: conn, with: [sqlight.text(key)], expecting: decoder)
  {
    Ok([#(value, expires_at), ..]) ->
      case is_live(expires_at) {
        True -> Ok(Some(value))
        False -> {
          // Lazily drop the expired row, then report it as absent.
          case do_delete(conn, table, key) {
            Ok(_) -> Ok(None)
            Error(err) -> Error(err)
          }
        }
      }
    Ok([]) -> Ok(None)
    Error(err) -> Error(err)
  }
}

fn do_set(
  conn: sqlight.Connection,
  table: String,
  key: String,
  value: String,
  expires_at: Option(Int),
) -> Result(Nil, sqlight.Error) {
  let sql =
    "INSERT INTO "
    <> table
    <> " (key, value, expires_at) VALUES (?, ?, ?)"
    <> " ON CONFLICT(key) DO UPDATE SET value = excluded.value,"
    <> " expires_at = excluded.expires_at"
  let args = [
    sqlight.text(key),
    sqlight.text(value),
    sqlight.nullable(sqlight.int, expires_at),
  ]
  case sqlight.query(sql, on: conn, with: args, expecting: decode.dynamic) {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(err)
  }
}

fn do_delete(
  conn: sqlight.Connection,
  table: String,
  key: String,
) -> Result(Nil, sqlight.Error) {
  let sql = "DELETE FROM " <> table <> " WHERE key = ?"
  case
    sqlight.query(
      sql,
      on: conn,
      with: [sqlight.text(key)],
      expecting: decode.dynamic,
    )
  {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(err)
  }
}

/// One atomic statement each way: an `UPDATE` guarded by the expected value
/// (and liveness), or an upsert that only replaces an expired row. SQLite's
/// `RETURNING` says whether a row was written.
fn do_compare_and_set(
  conn: sqlight.Connection,
  table: String,
  key: String,
  expected: Option(String),
  value: String,
  ttl_ms: Option(Int),
) -> Result(Bool, sqlight.Error) {
  let now = now_ms()
  let expires_at =
    sqlight.nullable(sqlight.int, option.map(ttl_ms, int.add(now, _)))
  let #(sql, args) = case expected {
    Some(current) -> #(
      "UPDATE "
        <> table
        <> " SET value = ?, expires_at = ? WHERE key = ? AND value = ?"
        <> " AND (expires_at IS NULL OR expires_at > ?) RETURNING key",
      [
        sqlight.text(value),
        expires_at,
        sqlight.text(key),
        sqlight.text(current),
        sqlight.int(now),
      ],
    )
    None -> #(
      "INSERT INTO "
        <> table
        <> " (key, value, expires_at) VALUES (?, ?, ?)"
        <> " ON CONFLICT(key) DO UPDATE SET value = excluded.value,"
        <> " expires_at = excluded.expires_at WHERE "
        <> table
        <> ".expires_at IS NOT NULL AND "
        <> table
        <> ".expires_at <= ? RETURNING key",
      [sqlight.text(key), sqlight.text(value), expires_at, sqlight.int(now)],
    )
  }
  sqlight.query(
    sql,
    on: conn,
    with: args,
    expecting: decode.at([0], decode.string),
  )
  |> result.map(fn(written) { written != [] })
}

fn do_scan(
  conn: sqlight.Connection,
  table: String,
  prefix: String,
  cursor: Option(String),
  limit: Int,
) -> Result(#(List(String), Option(String)), sqlight.Error) {
  let #(after_sql, after_args) = case cursor {
    None -> #("", [])
    Some(last) -> #(" AND key > ?", [sqlight.text(last)])
  }
  let sql =
    "SELECT key FROM "
    <> table
    <> " WHERE key LIKE ? ESCAPE '\\' AND (expires_at IS NULL OR expires_at > ?)"
    <> after_sql
    <> " ORDER BY key LIMIT ?"
  let args =
    list.flatten([
      [sqlight.text(escape_like(prefix) <> "%"), sqlight.int(now_ms())],
      after_args,
      [sqlight.int(limit)],
    ])
  sqlight.query(
    sql,
    on: conn,
    with: args,
    expecting: decode.at([0], decode.string),
  )
  |> result.map(fn(page) { #(page, storage.next_cursor(page, limit)) })
}

/// `_` and `%` are wildcards in `LIKE`; a prefix such as `my_flow:` must
/// match literally.
fn escape_like(prefix: String) -> String {
  prefix
  |> string.replace("\\", "\\\\")
  |> string.replace("%", "\\%")
  |> string.replace("_", "\\_")
}

/// An absent (`None`) `expires_at` means "never expires".
fn is_live(expires_at: Option(Int)) -> Bool {
  case expires_at {
    None -> True
    Some(at) -> now_ms() < at
  }
}

fn now_ms() -> Int {
  os_system_time(atom.create("millisecond"))
}

@external(erlang, "os", "system_time")
fn os_system_time(unit: atom.Atom) -> Int
