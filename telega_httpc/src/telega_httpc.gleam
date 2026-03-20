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

/// Create a new Telegram client using httpc as the HTTP backend.
///
/// This sets up both `FetchClient` (for JSON API calls) and
/// `FetchBitsClient` (for binary file downloads).
pub fn new(token token: String) -> client.TelegramClient {
  client.new(token:, fetch_client: fetch_adapter)
  |> client.set_fetch_bits_client(fetch_bits_adapter)
}

/// Create a new Telegram client with httpc and default request queue.
pub fn new_with_queue(
  token token: String,
) -> Result(client.TelegramClient, TelegaError) {
  client.new_with_queue(token:, fetch_client: fetch_adapter)
  |> result.map(client.set_fetch_bits_client(_, fetch_bits_adapter))
}

/// The httpc fetch adapter for JSON API requests.
///
/// Exposed so you can use it with `client.set_fetch_client` if needed.
pub fn fetch_adapter(
  req: Request(String),
) -> Result(Response(String), TelegaError) {
  httpc.send(req)
  |> result.map_error(fn(err) { error.FetchError(string.inspect(err)) })
}

/// The httpc fetch adapter for binary file downloads.
///
/// Exposed so you can use it with `client.set_fetch_bits_client` if needed.
pub fn fetch_bits_adapter(
  req: Request(BitArray),
) -> Result(Response(BitArray), TelegaError) {
  httpc.send_bits(req)
  |> result.map_error(fn(err) { error.FetchError(string.inspect(err)) })
}
