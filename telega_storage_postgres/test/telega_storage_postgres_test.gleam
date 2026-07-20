import gleam/erlang/process
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import pog

import telega/storage
import telega_storage_postgres as postgres

/// persistent_term key under which the single shared pool state is memoized.
const pool_key = "telega_pg_test_shared_pool"

pub fn main() {
  // Start ONE shared pool before any test runs. Previously every `try_kv()`
  // call spun up a fresh `pool_size(1)` pool via `process.new_name` and never
  // shut it down, so concurrent tests accumulated connections until Postgres'
  // connection limit rejected them (ConnectionUnavailable). Memoizing a single
  // pool in persistent_term means every test shares the same connections.
  let _ = shared_kv()
  gleeunit.main()
}

/// Memoized state of the shared pool. `NotStarted` is the persistent_term
/// default, so the first reader triggers `start_shared`.
type PoolState {
  NotStarted
  Started(pog.Connection)
  Unavailable
}

@external(erlang, "persistent_term", "get")
fn pt_get(key key: String, default default: a) -> a

@external(erlang, "persistent_term", "put")
fn pt_put(key key: String, value value: a) -> Nil

/// Return a KV storage backed by the shared Postgres pool, starting it once on
/// first use. Returns `Error` when no database is reachable so the suite is a
/// no-op in CI without a DB.
fn shared_kv() -> Result(storage.KeyValueStorage(pog.QueryError), Nil) {
  case pt_get(key: pool_key, default: NotStarted) {
    Started(conn) -> Ok(postgres.new(conn))
    Unavailable -> Error(Nil)
    NotStarted -> start_shared()
  }
}

fn start_shared() -> Result(storage.KeyValueStorage(pog.QueryError), Nil) {
  let name = process.new_name("telega_pg_test_shared")
  let config =
    pog.default_config(name)
    |> pog.host("localhost")
    |> pog.database("telega_test")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(10)

  let state = case pog.start(config) {
    Ok(_) -> {
      let conn = pog.named_connection(name)
      case postgres.migrate(conn) {
        Ok(_) -> Started(conn)
        Error(_) -> Unavailable
      }
    }
    Error(_) -> Unavailable
  }
  pt_put(key: pool_key, value: state)

  case state {
    Started(conn) -> Ok(postgres.new(conn))
    _ -> Error(Nil)
  }
}

pub fn set_get_delete_test() {
  case shared_kv() {
    Error(_) -> Nil
    Ok(kv) -> {
      let assert Ok(Nil) = kv.delete("pg:a")
      kv.get("pg:a") |> should.equal(Ok(None))

      let assert Ok(Nil) = kv.set("pg:a", "1")
      kv.get("pg:a") |> should.equal(Ok(Some("1")))

      let assert Ok(Nil) = kv.set("pg:a", "2")
      kv.get("pg:a") |> should.equal(Ok(Some("2")))

      let assert Ok(Nil) = kv.delete("pg:a")
      kv.get("pg:a") |> should.equal(Ok(None))
    }
  }
}

pub fn ttl_and_scan_test() {
  case shared_kv() {
    Error(_) -> Nil
    Ok(kv) -> {
      let assert Ok(Nil) = kv.delete("pg:scan:x")
      let assert Ok(Nil) = kv.delete("pg:scan:y")

      let assert Ok(Nil) = kv.set("pg:scan:x", "1")
      let assert Ok(Nil) = kv.set_with_ttl("pg:scan:y", "2", -1)

      // The expired key must not be returned by scan.
      let assert Ok(keys) = kv.scan("pg:scan:")
      keys |> should.equal(["pg:scan:x"])

      let assert Ok(Nil) = kv.delete("pg:scan:x")
      Nil
    }
  }
}
