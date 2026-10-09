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
import gleam/option.{type Option, None, Some}
import gleam/string

import telega/storage.{type KeyValueStorage}

/// Exercise `kv`: get on a missing key, set/get/overwrite/delete, a literal
/// `scan` prefix (no `_`, `%`, `*` or `?` wildcards) that pages to
/// completion, TTL expiry, and `compare_and_set` against an absent, a
/// present, a differing and an expired value.
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
    "cas",
    "page:1",
    "page:2",
    "page:3",
    "page:4",
    "page:5",
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
    sorted(storage.scan_all(kv, key("my_flow:"))) == Ok([key("my_flow:a")]),
    "scan treats `_` in the prefix literally",
  )
  expect(
    sorted(storage.scan_all(kv, key("my%flow:"))) == Ok([key("my%flow:c")]),
    "scan treats `%` in the prefix literally",
  )
  expect(
    sorted(storage.scan_all(kv, key("my*flow:"))) == Ok([key("my*flow:d")]),
    "scan treats `*` in the prefix literally",
  )
  expect(
    sorted(storage.scan_all(kv, key("my")))
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
    sorted(storage.scan_all(kv, key("gone"))) == Ok([]),
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

  expect(
    kv.compare_and_set(key("cas"), None, "1", None) == Ok(True),
    "compare_and_set writes an absent key",
  )
  expect(kv.get(key("cas")) == Ok(Some("1")), "the written value reads back")
  expect(
    kv.compare_and_set(key("cas"), None, "2", None) == Ok(False),
    "compare_and_set expecting an absent key refuses a present one",
  )
  expect(
    kv.compare_and_set(key("cas"), Some("0"), "2", None) == Ok(False),
    "compare_and_set refuses a value other than the expected one",
  )
  expect(
    kv.get(key("cas")) == Ok(Some("1")),
    "a refused compare_and_set leaves the value alone",
  )
  expect(
    kv.compare_and_set(key("cas"), Some("1"), "2", None) == Ok(True),
    "compare_and_set replaces the expected value",
  )
  expect(kv.get(key("cas")) == Ok(Some("2")), "the replacement reads back")
  expect(
    kv.compare_and_set(key("cas"), Some("2"), "3", Some(-1)) == Ok(True),
    "compare_and_set with a ttl succeeds",
  )
  expect(
    kv.get(key("cas")) == Ok(None),
    "a compare_and_set that already expired reads as missing",
  )
  expect(
    kv.compare_and_set(key("cas"), None, "4", Some(60_000)) == Ok(True),
    "compare_and_set treats an expired key as absent",
  )
  expect(
    kv.get(key("cas")) == Ok(Some("4")),
    "the value written over an expired one reads back",
  )

  let pages = ["page:1", "page:2", "page:3", "page:4", "page:5"]
  list.each(pages, fn(name) {
    let _ = kv.set(key(name), "p")
  })
  expect(
    sorted(scan_pages(kv, key("page:"), None, [])) == Ok(list.map(pages, key)),
    "scan pages through every key under the prefix",
  )
  expect(
    sorted(storage.scan_all(kv, key("page:"))) == Ok(list.map(pages, key)),
    "scan_all returns every key under the prefix",
  )

  list.each(keys, fn(name) {
    let _ = kv.delete(key(name))
  })
}

/// Two keys at a time, until the backend says there are no more.
fn scan_pages(
  kv: KeyValueStorage(error),
  prefix: String,
  cursor: Option(String),
  acc: List(String),
) -> Result(List(String), error) {
  case kv.scan(prefix, cursor, 2) {
    Ok(#(keys, None)) -> Ok(list.append(acc, keys))
    Ok(#(keys, next)) -> scan_pages(kv, prefix, next, list.append(acc, keys))
    Error(e) -> Error(e)
  }
}

fn sorted(scanned: Result(List(String), error)) -> Result(List(String), error) {
  case scanned {
    Ok(keys) -> Ok(list.sort(list.unique(keys), string.compare))
    Error(e) -> Error(e)
  }
}

fn expect(ok: Bool, what: String) -> Nil {
  case ok {
    True -> Nil
    False -> panic as { "storage contract: " <> what }
  }
}
