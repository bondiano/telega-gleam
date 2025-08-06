//// Module provides a simple interface to the Telegram Bot API and uses `httpc` as a default HTTP client.
//// If you want to use `telega` as a Telegram client, you can use only this module.
////
//// ```gleam
//// import telega/client
//// import telega/api
////
//// fn main() {
////   ...
////   let response = client.new(token) |> api.send_message(client, send_message_parameters)
////   ...
//// }
//// ```

import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/httpc
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/internal/utils

import telega/error.{type TelegaError}
import telega/internal/request_queue.{type RequestQueue}

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
    /// Request queue for rate limiting
    request_queue: Option(RequestQueue),
  )
}

/// Create a new Telegram client. It uses `httpc` as a default HTTP client.
pub fn new(token token: String) -> TelegramClient {
  TelegramClient(
    token:,
    max_retry_attempts: default_retry_count,
    tg_api_url: telegram_url,
    fetch_client: fetch_httpc_adapter,
    request_queue: None,
  )
}

/// Create a new Telegram client with default request queue configuration
///
/// This is a convenience function that creates a client with sensible
/// default rate limiting settings for the Telegram Bot API.
pub fn new_with_queue(
  token token: String,
) -> Result(TelegramClient, error.TelegaError) {
  new(token)
  |> set_request_queue(default_request_queue_config())
}

/// Send a request to the Telegram Bot API.
///
/// It uses `default` rule for rate limiting (if request [queue](#set_request_queue) is enabled).
pub fn fetch(
  request api_request: TelegramApiRequest,
  client client: TelegramClient,
) -> Result(Response(String), TelegaError) {
  use api_request <- result.try(api_to_request(api_request))

  case client.request_queue {
    Some(queue) ->
      request_queue.execute(queue, fn() { send_request(client, api_request) })

    None -> send_with_retry(client, api_request, client.max_retry_attempts)
  }
}

/// Set the HTTP client to use.
pub fn set_fetch_client(
  client client: TelegramClient,
  fetch_client fetch_client: fn(Request(String)) ->
    Result(Response(String), TelegaError),
) -> TelegramClient {
  TelegramClient(..client, fetch_client:)
}

/// Set the maximum number of times to retry sending a API message.
pub fn set_max_retry_attempts(
  client client: TelegramClient,
  max_retry_attempts max_retry_attempts: Int,
) -> TelegramClient {
  TelegramClient(..client, max_retry_attempts:)
}

/// Set the Telegram Bot API URL.
pub fn set_tg_api_url(
  client client: TelegramClient,
  tg_api_url tg_api_url: String,
) -> TelegramClient {
  TelegramClient(..client, tg_api_url:)
}

pub type RequestQueueConfig {
  RequestQueueConfig(
    rules: List(RequestQueueRule),
    /// Overall rate limit (requests per second)
    overall_rate: Option(Int),
    /// Overall concurrent request limit
    overall_limit: Option(Int),
    /// Default retry delay in milliseconds
    retry_delay: Int,
    /// Maximum retries
    max_retries: Int,
  )
}

pub type RequestQueueRule {
  RequestQueueRule(
    /// Rule identifier
    id: String,
    /// Maximum requests per time window
    rate: Int,
    /// Time window in milliseconds
    limit: Int,
    /// Priority (lower number = higher priority)
    priority: Int,
  )
}

pub fn default_request_queue_config() -> RequestQueueConfig {
  let default_config = request_queue.default_config()

  let rules =
    list.map(default_config.rules, fn(rule) {
      RequestQueueRule(
        id: rule.id,
        rate: rule.rate,
        limit: rule.limit,
        priority: rule.priority,
      )
    })

  RequestQueueConfig(
    rules:,
    overall_rate: default_config.overall_rate,
    overall_limit: default_config.overall_limit,
    retry_delay: default_config.retry_delay,
    max_retries: default_config.max_retries,
  )
}

/// Enable request queue with custom configuration for rate limiting
///
/// The request queue helps prevent hitting Telegram's rate limits by:
/// - Queuing requests when limits are reached
/// - Automatically retrying failed requests with exponential backoff
/// - Supporting different rate limits for different types of requests
///
/// ## Example
///
/// ```gleam
/// import telega/client
///
/// let config = client.RequestQueueConfig(
///   rules: [
///     // Default rule for most requests
///     client.RequestQueueRule(
///       id: "default",
///       rate: 30,        // 30 requests
///       limit: 1000,     // per 1 second
///       priority: 5,
///     ),
///     // Slower rate for sending messages
///     client.RequestQueueRule(
///       id: "send_message",
///       rate: 1,         // 1 request
///       limit: 1000,     // per 1 second
///       priority: 10,
///     ),
///     // Higher priority for important requests
///     client.RequestQueueRule(
///       id: "important",
///       rate: 5,
///       limit: 1000,
///       priority: 1,     // Lower number = higher priority
///     ),
///   ],
///   overall_rate: Some(30),    // Global limit across all rules
///   overall_limit: Some(100),  // Max concurrent requests
///   retry_delay: 1000,         // Retry after 1 second
///   max_retries: 3,
/// )
///
/// let assert Ok(client) =
///   client.new(token)
///   |> client.set_request_queue(config)
///
/// // Use specific rule for rate-limited operations
/// client.fetch_with_rule(request, client, "send_message")
///
/// // Check queue status
/// let queue_length = client.get_queue_length(client)
/// let is_busy = client.is_queue_overheated(client)
/// ```
pub fn set_request_queue(
  client client: TelegramClient,
  config config: RequestQueueConfig,
) -> Result(TelegramClient, error.TelegaError) {
  case client.request_queue {
    Some(queue) -> request_queue.shutdown(queue)
    None -> Nil
  }

  use queue <- result.try(
    request_queue.start(request_queue.QueueConfig(
      rules: list.map(config.rules, fn(rule) {
        request_queue.Rule(
          id: rule.id,
          rate: rule.rate,
          limit: rule.limit,
          priority: rule.priority,
        )
      }),
      overall_rate: config.overall_rate,
      overall_limit: config.overall_limit,
      retry_delay: config.retry_delay,
      max_retries: config.max_retries,
    ))
    |> result.map_error(fn(_) {
      error.FetchError("Failed to start request queue")
    }),
  )

  Ok(TelegramClient(..client, request_queue: Some(queue)))
}

/// Shutdown the client and its request queue
///
/// Only recommended if request queue is enabled.
pub fn shutdown(client client: TelegramClient) -> Nil {
  case client.request_queue {
    Some(queue) -> request_queue.shutdown(queue)
    None -> Nil
  }
}

/// Get the total number of requests waiting in the queue
///
/// Returns 0 if no queue is configured
pub fn get_queue_length(client client: TelegramClient) -> Int {
  case client.request_queue {
    Some(queue) -> request_queue.total_length(queue)
    None -> 0
  }
}

/// Check if the queue is overheated (any rule is at its rate limit)
///
/// Returns False if no queue is configured
pub fn is_queue_overheated(client client: TelegramClient) -> Bool {
  case client.request_queue {
    Some(queue) -> request_queue.is_overheated(queue)
    None -> False
  }
}

pub fn fetch_with_rule(
  request api_request: TelegramApiRequest,
  client client: TelegramClient,
  rule_id rule_id: String,
) -> Result(Response(String), TelegaError) {
  use api_request <- result.try(api_to_request(api_request))
  let request_id = utils.random_string(32)

  case client.request_queue {
    Some(queue) ->
      request_queue.execute_with_rule(queue, request_id, rule_id, fn() {
        send_request(client, api_request)
      })

    None -> send_with_retry(client, api_request, client.max_retry_attempts)
  }
}

fn send_request(
  client: TelegramClient,
  api_request: Request(String),
) -> Result(Response(String), TelegaError) {
  client.fetch_client(api_request)
}

fn send_with_retry(
  client: TelegramClient,
  api_request: Request(String),
  retries: Int,
) -> Result(Response(String), TelegaError) {
  let response = client.fetch_client(api_request)

  case retries {
    0 -> response
    _ -> {
      case response {
        Ok(response) -> {
          case response.status {
            429 -> {
              // Rate limited, wait and retry
              process.sleep(default_retry_delay)
              send_with_retry(client, api_request, retries - 1)
            }
            _ -> Ok(response)
          }
        }
        Error(_) -> {
          process.sleep(default_retry_delay)
          send_with_retry(client, api_request, retries - 1)
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

fn fetch_httpc_adapter(
  req: Request(String),
) -> Result(Response(String), TelegaError) {
  httpc.send(req)
  |> result.map_error(fn(error) { error.FetchError(string.inspect(error)) })
}

fn build_url(client client: TelegramClient, path path: String) {
  client.tg_api_url <> client.token <> "/" <> path
}
