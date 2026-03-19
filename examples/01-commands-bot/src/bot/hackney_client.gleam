import gleam/hackney
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/result
import gleam/string

import telega/client
import telega/error.{type TelegaError}

/// Create a new Telegram client that uses hackney as the HTTP backend.
pub fn new(token token: String) -> client.TelegramClient {
  client.new(token)
  |> client.set_fetch_client(fetch_hackney_adapter)
}

fn fetch_hackney_adapter(
  req: Request(String),
) -> Result(Response(String), TelegaError) {
  hackney.send(req)
  |> result.map_error(fn(err) { error.FetchError(string.inspect(err)) })
}
