//// Raw process-dictionary access.
////
//// This is the **only** module in the library that touches `erlang:put` —
//// everything else goes through [`telega/scope`](../scope.html), whose
//// `Scope` value namespaces these keys per update and knows how to drop them
//// all again.

import gleam/dynamic.{type Dynamic}

/// An integer unique to the running node. Used to give each `Scope` its own
/// key namespace, so a flag left by one update can never be read by the next.
@external(erlang, "erlang", "unique_integer")
pub fn unique_integer() -> Int

@external(erlang, "erlang", "put")
pub fn put(key: String, value: value) -> Dynamic

@external(erlang, "erlang", "get")
pub fn get(key: String) -> Dynamic

@external(erlang, "erlang", "erase")
pub fn erase(key: String) -> Dynamic
