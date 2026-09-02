//// httpc adapter for the Telega Telegram Bot Library.
////
//// Provides a `TelegramClient` that uses `gleam_httpc` as the HTTP backend.
////
//// ```gleam
//// import telega
//// import telega_httpc
////
//// pub fn main() {
////   let client = telega_httpc.new("BOT_TOKEN")
////   let assert Ok(_bot) =
////     telega.new_for_polling(client)
////     |> telega.with_router(router)
////     |> telega.init_for_polling_nil_session()
//// }
//// ```

import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/result
import gleam/string

import telega/client
import telega/error.{type TelegaError}

/// How long a single HTTP call may take, in milliseconds.
///
/// It has to outlast a long poll: Telega asks `getUpdates` to hold the
/// connection open for 30 seconds by default, and httpc's own 30-second
/// default races that — the response and the timeout arrive together. 60
/// seconds leaves the poll room to answer.
pub const default_timeout_ms = 60_000

/// Create a new Telegram client using httpc as the HTTP backend.
///
/// This sets up both `FetchClient` (for JSON API calls) and
/// `FetchBitsClient` (for binary file downloads).
pub fn new(token token: String) -> client.TelegramClient {
  new_with_timeout(token:, timeout_ms: default_timeout_ms)
}

/// `new` with an explicit per-call HTTP timeout (milliseconds).
///
/// Raise it above `default_timeout_ms` if you long-poll with a
/// `telega.set_polling_timeout` longer than ~55 seconds; lower it only for
/// bots that never poll.
pub fn new_with_timeout(
  token token: String,
  timeout_ms timeout_ms: Int,
) -> client.TelegramClient {
  client.new(token:, fetch_client: fetch_adapter_with_timeout(timeout_ms:))
  |> client.set_fetch_bits_client(fetch_bits_adapter_with_timeout(timeout_ms:))
}

/// Create a new Telegram client with httpc and default request queue.
pub fn new_with_queue(
  token token: String,
) -> Result(client.TelegramClient, TelegaError) {
  client.new_with_queue(
    token:,
    fetch_client: fetch_adapter_with_timeout(timeout_ms: default_timeout_ms),
  )
  |> result.map(client.set_fetch_bits_client(
    _,
    fetch_bits_adapter_with_timeout(timeout_ms: default_timeout_ms),
  ))
}

/// The httpc fetch adapter for JSON API requests.
///
/// Exposed so you can use it with `client.set_fetch_client` if needed.
pub fn fetch_adapter(
  req: Request(String),
) -> Result(Response(String), TelegaError) {
  fetch_adapter_with_timeout(timeout_ms: default_timeout_ms)(req)
}

/// `fetch_adapter` with an explicit timeout in milliseconds.
pub fn fetch_adapter_with_timeout(
  timeout_ms timeout_ms: Int,
) -> fn(Request(String)) -> Result(Response(String), TelegaError) {
  let config = configuration(timeout_ms)
  fn(req) {
    httpc.dispatch(config, req)
    |> result.map_error(fn(err) { error.FetchError(string.inspect(err)) })
  }
}

/// The httpc fetch adapter for binary file downloads.
///
/// Exposed so you can use it with `client.set_fetch_bits_client` if needed.
pub fn fetch_bits_adapter(
  req: Request(BitArray),
) -> Result(Response(BitArray), TelegaError) {
  fetch_bits_adapter_with_timeout(timeout_ms: default_timeout_ms)(req)
}

/// `fetch_bits_adapter` with an explicit timeout in milliseconds.
pub fn fetch_bits_adapter_with_timeout(
  timeout_ms timeout_ms: Int,
) -> fn(Request(BitArray)) -> Result(Response(BitArray), TelegaError) {
  let config = configuration(timeout_ms)
  fn(req) {
    httpc.dispatch_bits(config, req)
    |> result.map_error(fn(err) { error.FetchError(string.inspect(err)) })
  }
}

fn configuration(timeout_ms: Int) -> httpc.Configuration {
  httpc.configure()
  |> httpc.timeout(timeout_ms)
}
