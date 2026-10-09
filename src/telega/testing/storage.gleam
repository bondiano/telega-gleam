//// The contract every `KeyValueStorage` backend has to meet, as one function
//// a backend's test suite calls.
////
//// ```gleam
//// import telega/testing/storage as storage_contract
////
//// pub fn satisfies_the_storage_contract_test() {
////   storage_contract.check(my_backend, prefix: "contract:")
//// }
//// ```
////
//// `check` panics with the clause that failed. It only touches keys starting
//// with `prefix` and deletes them again, so it is safe against a shared
//// database as long as the prefix is this suite's own.

import gleam/list
import gleam/option.{None, Some}
import gleam/string

import telega/storage.{type KeyValueStorage}

/// Exercise `kv`: get on a missing key, set/get/overwrite/delete, a literal
/// `scan` prefix (no `_`, `%`, `*` or `?` wildcards), and TTL expiry.
pub fn check(kv: KeyValueStorage(error), prefix prefix: String) -> Nil {
  let key = fn(name) { prefix <> name }
  let keys = [
    "a",
    "my_flow:a",
    "myXflow:b",
    "my%flow:c",
    "my*flow:d",
    "gone",
    "live",
  ]
  list.each(keys, fn(name) {
    let _ = kv.delete(key(name))
  })

  expect(kv.get(key("a")) == Ok(None), "get on a missing key is Ok(None)")
  expect(kv.set(key("a"), "1") == Ok(Nil), "set succeeds")
  expect(kv.get(key("a")) == Ok(Some("1")), "get returns what was set")
  expect(kv.set(key("a"), "2") == Ok(Nil), "set overwrites")
  expect(kv.get(key("a")) == Ok(Some("2")), "get returns the newer value")
  expect(kv.delete(key("a")) == Ok(Nil), "delete succeeds")
  expect(kv.get(key("a")) == Ok(None), "get after delete is Ok(None)")
  expect(kv.delete(key("a")) == Ok(Nil), "delete of a missing key succeeds")

  let _ = kv.set(key("my_flow:a"), "1")
  let _ = kv.set(key("myXflow:b"), "2")
  let _ = kv.set(key("my%flow:c"), "3")
  let _ = kv.set(key("my*flow:d"), "4")
  expect(
    sorted(kv.scan(key("my_flow:"))) == Ok([key("my_flow:a")]),
    "scan treats `_` in the prefix literally",
  )
  expect(
    sorted(kv.scan(key("my%flow:"))) == Ok([key("my%flow:c")]),
    "scan treats `%` in the prefix literally",
  )
  expect(
    sorted(kv.scan(key("my*flow:"))) == Ok([key("my*flow:d")]),
    "scan treats `*` in the prefix literally",
  )
  expect(
    sorted(kv.scan(key("my")))
      == Ok(
      [key("my%flow:c"), key("my*flow:d"), key("my_flow:a"), key("myXflow:b")]
      |> list.sort(string.compare),
    ),
    "scan returns every key under the prefix",
  )

  expect(
    kv.set_with_ttl(key("gone"), "v", -1) == Ok(Nil),
    "set_with_ttl succeeds",
  )
  expect(kv.get(key("gone")) == Ok(None), "an expired key reads as missing")
  expect(
    sorted(kv.scan(key("gone"))) == Ok([]),
    "an expired key is not scanned",
  )
  expect(
    kv.set_with_ttl(key("live"), "v", 60_000) == Ok(Nil),
    "set_with_ttl succeeds",
  )
  expect(
    kv.get(key("live")) == Ok(Some("v")),
    "a key with time left reads back",
  )

  list.each(keys, fn(name) {
    let _ = kv.delete(key(name))
  })
}

fn sorted(scanned: Result(List(String), error)) -> Result(List(String), error) {
  case scanned {
    Ok(keys) -> Ok(list.sort(keys, string.compare))
    Error(e) -> Error(e)
  }
}

fn expect(ok: Bool, what: String) -> Nil {
  case ok {
    True -> Nil
    False -> panic as { "storage contract: " <> what }
  }
}
