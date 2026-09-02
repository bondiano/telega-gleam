import gleam/erlang/atom
import gleam/http/request
import gleeunit
import gleeunit/should
import telega/client
import telega_hackney

pub fn main() {
  gleeunit.main()
}

pub fn new_creates_client_test() {
  let client = telega_hackney.new("test-token")
  client.get_api_url(client)
  |> should.equal("https://api.telegram.org/bot")
}

// M11 — the response timeout must outlast a long poll -----------------------

/// Telega long-polls `getUpdates` with a 30-second timeout by default.
/// hackney's own `recv_timeout` default is 5 seconds, so every empty poll
/// used to end in a timeout and the bot silently polled every 5 seconds.
const polling_timeout_ms = 30_000

pub fn default_timeout_outlasts_a_long_poll_test() {
  { telega_hackney.default_timeout_ms > polling_timeout_ms } |> should.be_true
}

pub fn a_short_timeout_bounds_the_call_test() {
  let started = now_ms()
  // Nothing is listening on port 1, and nothing ever will be.
  let assert Ok(req) = request.to("http://127.0.0.1:1/")

  telega_hackney.fetch_adapter_with_timeout(timeout_ms: 200)(req)
  |> should.be_error

  { now_ms() - started < 5000 } |> should.be_true
}

@external(erlang, "erlang", "monotonic_time")
fn monotonic_time(unit: atom.Atom) -> Int

fn now_ms() -> Int {
  monotonic_time(atom.create("millisecond"))
}
