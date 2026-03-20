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
////     telega.new_for_polling(client)
////     |> telega.with_router(router)
////     |> telega.init_for_polling_nil_session()
//// }
//// ```

import gleam/bytes_tree
import gleam/hackney
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/result
import gleam/string

import telega/client
import telega/error.{type TelegaError}

/// Create a new Telegram client using hackney as the HTTP backend.
///
/// This sets up both `FetchClient` (for JSON API calls) and
/// `FetchBitsClient` (for binary file downloads).
pub fn new(token token: String) -> client.TelegramClient {
  client.new(token:, fetch_client: fetch_adapter)
  |> client.set_fetch_bits_client(fetch_bits_adapter)
}

/// The hackney fetch adapter for JSON API requests.
///
/// Exposed so you can use it with `client.set_fetch_client` if needed.
pub fn fetch_adapter(
  req: Request(String),
) -> Result(Response(String), TelegaError) {
  hackney.send(req)
  |> result.map_error(fn(err) { error.FetchError(string.inspect(err)) })
}

/// The hackney fetch adapter for binary file downloads.
///
/// Exposed so you can use it with `client.set_fetch_bits_client` if needed.
pub fn fetch_bits_adapter(
  req: Request(BitArray),
) -> Result(Response(BitArray), TelegaError) {
  req
  |> request.map(bytes_tree.from_bit_array)
  |> hackney.send_bits
  |> result.map_error(fn(err) { error.FetchError(string.inspect(err)) })
}
