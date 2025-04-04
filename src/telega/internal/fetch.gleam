import gleam/dynamic
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/httpc
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import telega/internal/log

const default_retry_delay = 1000

type FetchClient =
  fn(Request(String)) -> Result(Response(String), String)

pub type TelegramFetchConfig {
  TelegramFetchConfig(
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

pub fn new_config(
  token token,
  max_retry_attempts max_retry_attempts,
  tg_api_url tg_api_url,
) -> TelegramFetchConfig {
  TelegramFetchConfig(
    token:,
    fetch_client: fetch_httpc_adapter,
    max_retry_attempts:,
    tg_api_url:,
  )
}

fn fetch_httpc_adapter(req: Request(String)) -> Result(Response(String), String) {
  httpc.send(req)
  |> result.map_error(fn(error) {
    "Failed to send request: " <> string.inspect(error)
  })
}

pub type TelegramApiRequest {
  TelegramApiPostRequest(
    url: String,
    body: String,
    query: Option(List(#(String, String))),
  )
  TelegramApiGetRequest(url: String, query: Option(List(#(String, String))))
}

pub fn new_post_request(
  config config,
  path path: String,
  body body: String,
  query query: Option(List(#(String, String))),
) {
  TelegramApiPostRequest(url: build_url(config, path), body:, query:)
}

pub fn new_get_request(
  config config,
  path path: String,
  query query: Option(List(#(String, String))),
) {
  TelegramApiGetRequest(url: build_url(config, path), query:)
}

// TODO: add rate limit handling
pub fn fetch(api_request: TelegramApiRequest, config: TelegramFetchConfig) {
  use api_request <- result.try(api_to_request(api_request))

  send_with_retry(config.fetch_client, api_request, config.max_retry_attempts)
  |> result.map_error(fn(error) {
    decode.run(error, decode.string)
    |> result.unwrap("Failed to send request")
  })
}

fn send_with_retry(
  fetch_client: FetchClient,
  api_request: Request(String),
  retries: Int,
) {
  let response = fetch_client(api_request)

  case retries {
    0 -> result.map_error(response, dynamic.from)
    _ -> {
      case response {
        Ok(response) -> {
          case response.status {
            429 -> {
              log.warn("Telegram API throttling, HTTP 429 'Too Many Requests'")
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

fn api_to_request(
  api_request: TelegramApiRequest,
) -> Result(Request(String), String) {
  case api_request {
    TelegramApiGetRequest(url: url, query: query) -> {
      request.to(url)
      |> result.map(request.set_method(_, Get))
      |> result.map(set_query(_, query))
    }
    TelegramApiPostRequest(url: url, query: query, body: body) -> {
      request.to(url)
      |> result.map(request.set_body(_, body))
      |> result.map(request.set_method(_, Post))
      |> result.map(request.set_header(_, "Content-Type", "application/json"))
      |> result.map(set_query(_, query))
    }
  }
  |> result.map_error(fn(error) {
    "Failed to convert API request to HTTP request: " <> string.inspect(error)
  })
}

fn set_query(
  api_request: Request(String),
  query: Option(List(#(String, String))),
) -> Request(String) {
  case query {
    None -> api_request
    Some(query) -> {
      request.set_query(api_request, query)
    }
  }
}

fn build_url(config: TelegramFetchConfig, path: String) -> String {
  config.tg_api_url <> config.token <> "/" <> path
}
