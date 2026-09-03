//// hackney adapter for the Telega Telegram Bot Library.
////
//// Provides a `TelegramClient` that uses `gleam_hackney` as the HTTP backend.
////
//// ```gleam
//// import telega
//// import telega_hackney
////
//// pub fn main() {
////   let client = telega_hackney.new("BOT_TOKEN")
////   let assert Ok(_bot) =
////     telega.new(client)
////     |> telega.router(router)
////     |> telega.start()
//// }
//// ```

import gleam/bit_array
import gleam/bytes_tree.{type BytesTree}
import gleam/dynamic.{type Dynamic}
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/list
import gleam/result
import gleam/string
import gleam/uri

import telega/client
import telega/error.{type TelegaError}

/// How long hackney may wait for the response body, in milliseconds.
///
/// hackney's own default is **5 seconds**, which is shorter than the
/// 30-second long poll Telega opens by default: every empty `getUpdates` ended
/// in a timeout, the poller retried, and the bot quietly degraded to polling
/// every 5 seconds. 60 seconds leaves the poll room to answer.
pub const default_timeout_ms = 60_000

/// How long hackney may wait to establish the connection, in milliseconds.
pub const default_connect_timeout_ms = 10_000

/// Create a new Telegram client using hackney as the HTTP backend.
///
/// This sets up both `FetchClient` (for JSON API calls) and
/// `FetchBitsClient` (for binary file downloads).
pub fn new(token token: String) -> client.TelegramClient {
  new_with_timeout(token:, timeout_ms: default_timeout_ms)
}

/// `new` with an explicit response timeout (milliseconds).
///
/// Raise it above `default_timeout_ms` if you long-poll with a
/// a `polling.PollingSettings(timeout:)` longer than ~55 seconds.
pub fn new_with_timeout(
  token token: String,
  timeout_ms timeout_ms: Int,
) -> client.TelegramClient {
  client.new(token:, fetch_client: fetch_adapter_with_timeout(timeout_ms:))
  |> client.set_fetch_bits_client(fetch_bits_adapter_with_timeout(timeout_ms:))
}

/// The hackney fetch adapter for JSON API requests.
///
/// Exposed so you can use it with `client.set_fetch_client` if needed.
pub fn fetch_adapter(
  req: Request(String),
) -> Result(Response(String), TelegaError) {
  fetch_adapter_with_timeout(timeout_ms: default_timeout_ms)(req)
}

/// `fetch_adapter` with an explicit response timeout in milliseconds.
pub fn fetch_adapter_with_timeout(
  timeout_ms timeout_ms: Int,
) -> fn(Request(String)) -> Result(Response(String), TelegaError) {
  let send = fetch_bits_adapter_with_timeout(timeout_ms:)
  fn(req: Request(String)) {
    use response <- result.try(send(request.map(req, bit_array.from_string)))
    bit_array.to_string(response.body)
    |> result.replace_error(error.FetchError(
      "response body was not valid UTF-8",
    ))
    |> result.map(response.set_body(response, _))
  }
}

/// The hackney fetch adapter for binary file downloads.
///
/// Exposed so you can use it with `client.set_fetch_bits_client` if needed.
pub fn fetch_bits_adapter(
  req: Request(BitArray),
) -> Result(Response(BitArray), TelegaError) {
  fetch_bits_adapter_with_timeout(timeout_ms: default_timeout_ms)(req)
}

/// `fetch_bits_adapter` with an explicit response timeout in milliseconds.
pub fn fetch_bits_adapter_with_timeout(
  timeout_ms timeout_ms: Int,
) -> fn(Request(BitArray)) -> Result(Response(BitArray), TelegaError) {
  fn(req: Request(BitArray)) {
    let url =
      req
      |> request.to_uri
      |> uri.to_string

    ffi_send(
      http.method_to_string(req.method),
      url,
      req.headers,
      bytes_tree.from_bit_array(req.body),
      default_connect_timeout_ms,
      timeout_ms,
    )
    |> result.map(fn(response: Response(BitArray)) {
      Response(
        ..response,
        headers: list.map(response.headers, normalise_header),
      )
    })
    |> result.map_error(fn(err) { error.FetchError(string.inspect(err)) })
  }
}

fn normalise_header(header: http.Header) -> http.Header {
  #(string.lowercase(header.0), header.1)
}

@external(erlang, "telega_hackney_ffi", "send")
fn ffi_send(
  method: String,
  url: String,
  headers: List(http.Header),
  body: BytesTree,
  connect_timeout: Int,
  recv_timeout: Int,
) -> Result(Response(BitArray), Dynamic)
