import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/static_supervisor as supervisor
import gleeunit
import gleeunit/should
import valkyrie

import telega/storage
import telega_storage_redis as redis

/// persistent_term key under which the single shared pool state is memoized.
const pool_key = "telega_redis_test_shared_pool"

pub fn main() {
  // Start ONE shared pool before any test runs. Previously every `try_kv()`
  // call spun up a fresh `size: 1` supervised pool via `process.new_name` and
  // never shut it down, so concurrent tests accumulated connections. Memoizing
  // a single pool in persistent_term means every test shares the same
  // connections.
  let _ = shared_kv()
  gleeunit.main()
}

/// Memoized state of the shared pool. `NotStarted` is the persistent_term
/// default, so the first reader triggers `start_shared`.
type PoolState {
  NotStarted
  Started(valkyrie.Connection)
  Unavailable
}

@external(erlang, "persistent_term", "get")
fn pt_get(key key: String, default default: a) -> a

@external(erlang, "persistent_term", "put")
fn pt_put(key key: String, value value: a) -> Nil

/// Return a KV storage backed by the shared Redis pool, starting it once on
/// first use. Returns `Error` when no server is reachable so the suite is a
/// no-op in CI without Redis.
fn shared_kv() -> Result(storage.KeyValueStorage(valkyrie.Error), Nil) {
  case pt_get(key: pool_key, default: NotStarted) {
    Started(conn) -> Ok(redis.new(conn))
    Unavailable -> Error(Nil)
    NotStarted -> start_shared()
  }
}

fn start_shared() -> Result(storage.KeyValueStorage(valkyrie.Error), Nil) {
  let pool_name = process.new_name("telega_redis_test_shared")
  let spec =
    valkyrie.default_config()
    |> valkyrie.supervised_pool(size: 10, name: Some(pool_name), timeout: 1000)

  let state = case
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(spec)
    |> supervisor.start
  {
    Ok(_) -> {
      let conn = valkyrie.named_connection(pool_name)
      case redis.new(conn).get("__telega_probe__") {
        Ok(_) -> Started(conn)
        Error(_) -> Unavailable
      }
    }
    Error(_) -> Unavailable
  }
  pt_put(key: pool_key, value: state)

  case state {
    Started(conn) -> Ok(redis.new(conn))
    _ -> Error(Nil)
  }
}

pub fn set_get_delete_test() {
  case shared_kv() {
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
  case shared_kv() {
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
