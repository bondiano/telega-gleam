//// PostgreSQL storage adapter for Telega.
////
//// Implements `telega/storage.KeyValueStorage` on top of a single Postgres
//// table with a `text` value column, suitable for production bots. TTL is
//// stored as an epoch-millisecond `expires_at` column and enforced lazily on
//// access (`get`/`scan`), so no background job is required.

import gleam/dynamic/decode
import gleam/erlang/atom
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import pog
import telega/storage.{type KeyValueStorage, KeyValueStorage}

/// Build a `KeyValueStorage` backed by the given pog connection.
///
/// Uses the default table name `telega_storage`. Call `migrate` once at startup
/// to create the table.
pub fn new(conn: pog.Connection) -> KeyValueStorage(pog.QueryError) {
  new_with_table(conn, default_table)
}

/// Like `new`, but with a custom table name.
pub fn new_with_table(
  conn: pog.Connection,
  table: String,
) -> KeyValueStorage(pog.QueryError) {
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
pub fn migrate(conn: pog.Connection) -> Result(Nil, pog.QueryError) {
  migrate_table(conn, default_table)
}

/// Create a custom-named storage table if it does not exist.
pub fn migrate_table(
  conn: pog.Connection,
  table: String,
) -> Result(Nil, pog.QueryError) {
  let sql =
    "CREATE TABLE IF NOT EXISTS "
    <> table
    <> " (key TEXT PRIMARY KEY, value TEXT NOT NULL, expires_at BIGINT)"
  case sql |> pog.query |> pog.execute(conn) {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(err)
  }
}

fn do_get(
  conn: pog.Connection,
  table: String,
  key: String,
) -> Result(Option(String), pog.QueryError) {
  let decoder = {
    use value <- decode.field(0, decode.string)
    use expires_at <- decode.field(1, decode.optional(decode.int))
    decode.success(#(value, expires_at))
  }
  let sql =
    "SELECT value, expires_at FROM " <> table <> " WHERE key = $1 LIMIT 1"
  let query =
    sql
    |> pog.query
    |> pog.parameter(pog.text(key))
    |> pog.returning(decoder)
  case pog.execute(query, conn) {
    Ok(pog.Returned(rows: [#(value, expires_at), ..], ..)) ->
      case is_live(expires_at) {
        True -> Ok(Some(value))
        False ->
          case do_delete(conn, table, key) {
            Ok(_) -> Ok(None)
            Error(err) -> Error(err)
          }
      }
    Ok(pog.Returned(rows: [], ..)) -> Ok(None)
    Error(err) -> Error(err)
  }
}

fn do_set(
  conn: pog.Connection,
  table: String,
  key: String,
  value: String,
  expires_at: Option(Int),
) -> Result(Nil, pog.QueryError) {
  let sql =
    "INSERT INTO "
    <> table
    <> " (key, value, expires_at) VALUES ($1, $2, $3)"
    <> " ON CONFLICT (key) DO UPDATE SET value = $2, expires_at = $3"
  let query =
    sql
    |> pog.query
    |> pog.parameter(pog.text(key))
    |> pog.parameter(pog.text(value))
    |> pog.parameter(pog.nullable(pog.int, expires_at))
  case pog.execute(query, conn) {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(err)
  }
}

fn do_delete(
  conn: pog.Connection,
  table: String,
  key: String,
) -> Result(Nil, pog.QueryError) {
  let query =
    { "DELETE FROM " <> table <> " WHERE key = $1" }
    |> pog.query
    |> pog.parameter(pog.text(key))
  case pog.execute(query, conn) {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(err)
  }
}

/// One atomic statement each way: an `UPDATE` guarded by the expected value
/// (and liveness), or an upsert that only replaces an expired row.
/// `RETURNING` says whether a row was written.
fn do_compare_and_set(
  conn: pog.Connection,
  table: String,
  key: String,
  expected: Option(String),
  value: String,
  ttl_ms: Option(Int),
) -> Result(Bool, pog.QueryError) {
  let now = now_ms()
  let expires_at = pog.nullable(pog.int, option.map(ttl_ms, int.add(now, _)))
  let query = case expected {
    Some(current) ->
      {
        "UPDATE "
        <> table
        <> " SET value = $1, expires_at = $2 WHERE key = $3 AND value = $4"
        <> " AND (expires_at IS NULL OR expires_at > $5) RETURNING key"
      }
      |> pog.query
      |> pog.parameter(pog.text(value))
      |> pog.parameter(expires_at)
      |> pog.parameter(pog.text(key))
      |> pog.parameter(pog.text(current))
      |> pog.parameter(pog.int(now))
    None ->
      {
        "INSERT INTO "
        <> table
        <> " (key, value, expires_at) VALUES ($1, $2, $3)"
        <> " ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value,"
        <> " expires_at = EXCLUDED.expires_at WHERE "
        <> table
        <> ".expires_at IS NOT NULL AND "
        <> table
        <> ".expires_at <= $4 RETURNING key"
      }
      |> pog.query
      |> pog.parameter(pog.text(key))
      |> pog.parameter(pog.text(value))
      |> pog.parameter(expires_at)
      |> pog.parameter(pog.int(now))
  }
  case pog.execute(pog.returning(query, decode.at([0], decode.string)), conn) {
    Ok(pog.Returned(rows:, ..)) -> Ok(rows != [])
    Error(err) -> Error(err)
  }
}

fn do_scan(
  conn: pog.Connection,
  table: String,
  prefix: String,
  cursor: Option(String),
  limit: Int,
) -> Result(#(List(String), Option(String)), pog.QueryError) {
  let #(after_sql, after_args) = case cursor {
    None -> #("", [])
    Some(last) -> #(" AND key > $4", [pog.text(last)])
  }
  let sql =
    "SELECT key FROM "
    <> table
    <> " WHERE key LIKE $1 ESCAPE '\\' AND (expires_at IS NULL OR expires_at > $2)"
    <> after_sql
    <> " ORDER BY key LIMIT $3"
  let query =
    list.fold(
      over: list.flatten([
        [
          pog.text(escape_like(prefix) <> "%"),
          pog.int(now_ms()),
          pog.int(limit),
        ],
        after_args,
      ]),
      from: pog.query(sql),
      with: pog.parameter,
    )
    |> pog.returning(decode.at([0], decode.string))
  case pog.execute(query, conn) {
    Ok(pog.Returned(rows:, ..)) -> Ok(#(rows, storage.next_cursor(rows, limit)))
    Error(err) -> Error(err)
  }
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
