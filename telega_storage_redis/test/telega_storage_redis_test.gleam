import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/static_supervisor as supervisor
import gleeunit
import gleeunit/should
import valkyrie

import telega/storage
import telega_storage_redis as redis

pub fn main() {
  gleeunit.main()
}

/// Try to connect to a local Redis for integration tests. Returns `Error` when
/// no server is reachable so the suite is a no-op in CI without Redis.
fn try_kv() -> Result(storage.KeyValueStorage(valkyrie.Error), Nil) {
  let pool_name = process.new_name("telega_redis_test")
  let spec =
    valkyrie.default_config()
    |> valkyrie.supervised_pool(size: 1, name: Some(pool_name), timeout: 1000)

  case
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(spec)
    |> supervisor.start
  {
    Ok(_) -> {
      let kv = redis.new(valkyrie.named_connection(pool_name))
      case kv.get("__telega_probe__") {
        Ok(_) -> Ok(kv)
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
      let assert Ok(Nil) = kv.delete("redis:a")
      kv.get("redis:a") |> should.equal(Ok(None))

      let assert Ok(Nil) = kv.set("redis:a", "1")
      kv.get("redis:a") |> should.equal(Ok(Some("1")))

      let assert Ok(Nil) = kv.delete("redis:a")
      kv.get("redis:a") |> should.equal(Ok(None))
    }
  }
}

pub fn scan_test() {
  case try_kv() {
    Error(_) -> Nil
    Ok(kv) -> {
      let assert Ok(Nil) = kv.set("redis:scan:x", "1")
      let assert Ok(Nil) = kv.set("redis:scan:y", "2")

      let assert Ok(keys) = kv.scan("redis:scan:")
      list.length(keys) |> should.equal(2)

      let assert Ok(Nil) = kv.delete("redis:scan:x")
      let assert Ok(Nil) = kv.delete("redis:scan:y")
      Nil
    }
  }
}
