/// If you want to use telega only as a Telegram client, you can use this module.
/// ```gleam
/// import telega/client
/// import telega/api
///
/// fn main() {
///   ...
///   let response = client.new(token) |> api.send_message(client, send_message_parameters)
///   ...
/// }
/// ```
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import telega/error.{type TelegaError}

const default_retry_delay = 1000

const telegram_url = "https://api.telegram.org/bot"

const default_retry_count = 3

type FetchClient =
  fn(Request(String)) -> Result(Response(String), TelegaError)

pub opaque type TelegramClient {
  TelegramClient(
    /// The Telegram Bot API token.
    token: String,
    /// The maximum number of times to retry sending a API message. Default is 3.
    max_retry_attempts: Int,
    /// The Telegram Bot API URL. Default is "https://api.telegram.org".
    /// This is useful for running [a local server](https://core.telegram.org/bots/api#using-a-local-bot-api-server).
    tg_api_url: String,
    /// The HTTP client to use. Default is `httpc`.
    fetch_client: FetchClient,
  )
}

/// Create a new Telegram client. It uses `httpc` as a default HTTP client.
pub fn new(token token: String) -> TelegramClient {
  TelegramClient(
    token:,
    max_retry_attempts: default_retry_count,
    tg_api_url: telegram_url,
    fetch_client: fetch_httpc_adapter,
  )
}

/// Set the HTTP client to use.
pub fn set_fetch_client(
  client client: TelegramClient,
  fetch_client fetch_client: fn(Request(String)) ->
    Result(Response(String), TelegaError),
) -> TelegramClient {
  TelegramClient(..client, fetch_client:)
}

pub fn set_max_retry_attempts(
  client client: TelegramClient,
  max_retry_attempts max_retry_attempts: Int,
) -> TelegramClient {
  TelegramClient(..client, max_retry_attempts:)
}

pub fn set_tg_api_url(
  client client: TelegramClient,
  tg_api_url tg_api_url: String,
) -> TelegramClient {
  TelegramClient(..client, tg_api_url:)
}

fn fetch_httpc_adapter(
  req: Request(String),
) -> Result(Response(String), TelegaError) {
  httpc.send(req)
  |> result.map_error(fn(error) { error.FetchError(string.inspect(error)) })
}

// TODO: add rate limit handling
pub fn fetch(
  request api_request: TelegramApiRequest,
  client client: TelegramClient,
) -> Result(Response(String), TelegaError) {
  use api_request <- result.try(api_to_request(api_request))

  send_with_retry(client.fetch_client, api_request, client.max_retry_attempts)
}

fn send_with_retry(
  fetch_client: FetchClient,
  api_request: Request(String),
  retries: Int,
) -> Result(Response(String), TelegaError) {
  let response = fetch_client(api_request)

  case retries {
    0 -> response
    _ -> {
      case response {
        Ok(response) -> {
          case response.status {
            429 -> {
              // TODO: remake it with smart request balancer
              // https://github.com/energizer91/smart-request-balancer/tree/master - for reference
              process.sleep(default_retry_delay)
              send_with_retry(fetch_client, api_request, retries - 1)
            }
            _ -> Ok(response)
          }
        }
        Error(_) -> {
          process.sleep(default_retry_delay)
          send_with_retry(fetch_client, api_request, retries - 1)
        }
      }
    }
  }
}

fn api_to_request(api_request) {
  case api_request {
    TelegramApiGetRequest(url: url, query: query) -> {
      request.to(url)
      |> result.map(fn(req) {
        req
        |> request.set_method(Get)
        |> set_query(query)
      })
    }
    TelegramApiPostRequest(url: url, body: body) -> {
      request.to(url)
      |> result.map(fn(req) {
        req
        |> request.set_body(body)
        |> request.set_method(Post)
        |> request.set_header("Content-Type", "application/json")
      })
    }
  }
  |> result.map_error(fn(_: Nil) { error.ApiToRequestConvertError })
}

fn set_query(api_request, query) {
  case query {
    None -> api_request
    Some(query) -> request.set_query(api_request, query)
  }
}

pub fn get_api_url(client client: TelegramClient) -> String {
  client.tg_api_url
}

pub opaque type TelegramApiRequest {
  TelegramApiPostRequest(url: String, body: String)
  TelegramApiGetRequest(url: String, query: Option(List(#(String, String))))
}

pub fn new_post_request(
  client client: TelegramClient,
  path path: String,
  body body: String,
) -> TelegramApiRequest {
  TelegramApiPostRequest(url: build_url(client, path), body:)
}

pub fn new_get_request(
  client client: TelegramClient,
  path path: String,
  query query: Option(List(#(String, String))),
) -> TelegramApiRequest {
  TelegramApiGetRequest(url: build_url(client, path), query:)
}

fn build_url(client client: TelegramClient, path path: String) {
  client.tg_api_url <> client.token <> "/" <> path
}
