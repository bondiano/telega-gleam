//// PostgreSQL storage adapter for Telega.
////
//// Implements `telega/storage.KeyValueStorage` on top of a single Postgres
//// table with a `text` value column, suitable for production bots. TTL is
//// stored as an epoch-millisecond `expires_at` column and enforced lazily on
//// access (`get`/`scan`), so no background job is required.

import gleam/dynamic/decode
import gleam/erlang/atom
import gleam/option.{type Option, None, Some}
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
    delete: fn(key) { do_delete(conn, table, key) },
    scan: fn(prefix) { do_scan(conn, table, prefix) },
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

fn do_scan(
  conn: pog.Connection,
  table: String,
  prefix: String,
) -> Result(List(String), pog.QueryError) {
  let sql =
    "SELECT key FROM "
    <> table
    <> " WHERE key LIKE $1 AND (expires_at IS NULL OR expires_at > $2)"
  let query =
    sql
    |> pog.query
    |> pog.parameter(pog.text(prefix <> "%"))
    |> pog.parameter(pog.int(now_ms()))
    |> pog.returning(decode.at([0], decode.string))
  case pog.execute(query, conn) {
    Ok(pog.Returned(rows:, ..)) -> Ok(rows)
    Error(err) -> Error(err)
  }
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
