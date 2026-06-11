import gleam/erlang/process
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import pog

import telega/storage
import telega_storage_postgres as postgres

pub fn main() {
  gleeunit.main()
}

/// Try to connect to a local Postgres for integration tests. Returns `Error`
/// when no database is reachable so the suite is a no-op in CI without a DB.
fn try_kv() -> Result(storage.KeyValueStorage(pog.QueryError), Nil) {
  let name = process.new_name("telega_pg_test")
  let config =
    pog.default_config(name)
    |> pog.host("localhost")
    |> pog.database("telega_test")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.pool_size(1)

  case pog.start(config) {
    Ok(_) -> {
      let conn = pog.named_connection(name)
      case postgres.migrate(conn) {
        Ok(_) -> Ok(postgres.new(conn))
        Error(_) -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}

pub fn set_get_delete_test() {
  case try_kv() {
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
  case try_kv() {
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
