//// ETS-backed fixed-window counter used by `router.with_rate_limit`.
////
//// Each limiter owns an unnamed public ETS table, so several limiters never
//// share state. Entries are `#(key, count, window_started_at_ms)`. Updates for
//// the same key are processed sequentially by the owning chat instance actor,
//// so plain lookup-then-insert is race-free per key.

import gleam/erlang/atom

import telega/internal/utils

type EtsTable

pub opaque type RateLimiter {
  RateLimiter(table: EtsTable, limit: Int, window_ms: Int)
}

/// Create a limiter allowing `limit` hits per `window_ms` window.
///
/// The ETS table is owned by the calling process — create the limiter from a
/// long-lived process (bot setup), not from a handler.
pub fn new(limit limit: Int, window_ms window_ms: Int) -> RateLimiter {
  let table =
    ets_new(atom.create("telega_rate_limiter"), [
      atom.create("set"),
      atom.create("public"),
    ])
  RateLimiter(table:, limit:, window_ms:)
}

/// Register a hit for `key`. Returns `True` if the hit is within the limit.
pub fn hit(limiter limiter: RateLimiter, key key: String) -> Bool {
  let RateLimiter(table:, limit:, window_ms:) = limiter
  let now = utils.current_time_ms()

  case ets_lookup(table, key) {
    [#(_, count, window_started_at), ..]
      if now - window_started_at < window_ms
    ->
      case count < limit {
        True -> {
          ets_insert(table, #(key, count + 1, window_started_at))
          True
        }
        False -> False
      }
    _ -> {
      ets_insert(table, #(key, 1, now))
      True
    }
  }
}

@external(erlang, "ets", "new")
fn ets_new(name: atom.Atom, options: List(atom.Atom)) -> EtsTable

@external(erlang, "ets", "insert")
fn ets_insert(table: EtsTable, tuple: #(String, Int, Int)) -> Bool

@external(erlang, "ets", "lookup")
fn ets_lookup(table: EtsTable, key: String) -> List(#(String, Int, Int))
