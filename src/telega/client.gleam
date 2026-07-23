//// Module provides a simple interface to the Telegram Bot API.
//// If you want to use `telega` as a Telegram client, you can use only this module.
////
//// Use an adapter package like `telega_httpc` or `telega_hackney` to create a client,
//// or provide your own `FetchClient` function.
////
//// ```gleam
//// import telega/client
//// import telega/api
////
//// fn main() {
////   ...
////   let response = client.new(token, my_fetch_adapter) |> api.send_message(client, send_message_parameters)
////   ...
//// }
//// ```

import gleam/bit_array
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/internal/utils

import telega/error.{type TelegaError}
import telega/format.{type ParseMode}
import telega/internal/request_queue.{type RequestQueue}
import telega/telemetry

const default_retry_delay = 1000

const telegram_url = "https://api.telegram.org/bot"

const default_retry_count = 3

pub type FetchClient =
  fn(Request(String)) -> Result(Response(String), TelegaError)

pub type FetchBitsClient =
  fn(Request(BitArray)) -> Result(Response(BitArray), TelegaError)

/// Middleware around a single API call: it receives the outgoing request and
/// a `next` continuation. It can modify the request before calling `next`,
/// short-circuit the chain by returning a result without calling `next`,
/// or inspect/transform the result after `next` returns.
///
/// Transformers run inside the `telega.api_call` telemetry span,
/// so their latency is included in the span duration.
///
/// ```gleam
/// let log_calls = fn(request, next) {
///   io.println("calling " <> client.request_method(request))
///   next(request)
/// }
/// let client = client.new(token:, fetch_client:) |> client.use_transformer(log_calls)
/// ```
pub type ApiRequestTransformer =
  fn(
    TelegramApiRequest,
    fn(TelegramApiRequest) -> Result(Response(String), TelegaError),
  ) -> Result(Response(String), TelegaError)

pub opaque type TelegramClient {
  TelegramClient(
    /// The Telegram Bot API token.
    token: String,
    /// The maximum number of times to retry sending a API message. Default is 3.
    max_retry_attempts: Int,
    /// The Telegram Bot API URL. Default is "https://api.telegram.org".
    /// This is useful for running [a local server](https://core.telegram.org/bots/api#using-a-local-bot-api-server).
    tg_api_url: String,
    /// The HTTP client to use.
    fetch_client: FetchClient,
    /// Optional HTTP client for binary downloads.
    fetch_bits_client: Option(FetchBitsClient),
    /// Request queue for rate limiting
    request_queue: Option(RequestQueue),
    /// Middleware chain applied around every API call. First added is outermost.
    transformers: List(ApiRequestTransformer),
    /// Default parse mode used by `telega/reply` text helpers when no explicit one is set.
    default_parse_mode: Option(ParseMode),
  )
}

/// Create a new Telegram client with the given fetch client adapter.
pub fn new(
  token token: String,
  fetch_client fetch_client: FetchClient,
) -> TelegramClient {
  TelegramClient(
    token:,
    max_retry_attempts: default_retry_count,
    tg_api_url: telegram_url,
    fetch_client:,
    fetch_bits_client: None,
    request_queue: None,
    transformers: [],
    default_parse_mode: None,
  )
}

/// Add a transformer to the client's middleware chain.
/// Transformers run in the order they were added: the first added
/// is the outermost (sees the request first, the result last).
pub fn use_transformer(
  client client: TelegramClient,
  transformer transformer: ApiRequestTransformer,
) -> TelegramClient {
  TelegramClient(
    ..client,
    transformers: list.append(client.transformers, [transformer]),
  )
}

/// Set the default parse mode for `telega/reply` text helpers
/// (`with_text`, `with_markup`, `edit_text`, ...). Explicit helpers like
/// `with_html` and parameters with a parse mode already set are not affected.
pub fn set_default_parse_mode(
  client client: TelegramClient,
  parse_mode parse_mode: ParseMode,
) -> TelegramClient {
  TelegramClient(..client, default_parse_mode: Some(parse_mode))
}

/// Get the default parse mode as an API string (e.g. `Some("HTML")`),
/// or `None` if no default is configured.
pub fn default_parse_mode_string(
  client client: TelegramClient,
) -> Option(String) {
  option.map(client.default_parse_mode, format.parse_mode_to_string)
}

/// Create a new Telegram client with default request queue configuration.
///
/// This is a convenience function that creates a client with sensible
/// default rate limiting settings for the Telegram Bot API.
pub fn new_with_queue(
  token token: String,
  fetch_client fetch_client: FetchClient,
) -> Result(TelegramClient, error.TelegaError) {
  new(token:, fetch_client:)
  |> set_request_queue(default_request_queue_config())
}

/// Send a request to the Telegram Bot API.
///
/// It uses `default` rule for rate limiting (if request [queue](#set_request_queue) is enabled).
pub fn fetch(
  request api_request: TelegramApiRequest,
  client client: TelegramClient,
) -> Result(Response(String), TelegaError) {
  use <- fetch_with_telemetry(api_request.method)
  use api_request <- apply_transformers(client.transformers, api_request)

  let method = api_request.method
  use api_request <- result.try(api_to_request(api_request))
  case client.request_queue {
    Some(queue) ->
      request_queue.execute(queue, fn() { send_request(client, api_request) })

    None ->
      send_with_retry(client, method, api_request, client.max_retry_attempts)
  }
}

/// Send a `multipart/form-data` POST (a `BitArray` body) to `method`, routed
/// through the SAME request queue and 429-retry path as JSON calls, using the
/// configured `FetchBitsClient`. This is how raw file uploads (e.g. sending a
/// photo by bytes) honor the one-queue rate-limit invariant — there is no
/// second HTTP client. Errors if no `FetchBitsClient` is configured.
pub fn fetch_multipart(
  client client: TelegramClient,
  method method: String,
  content_type content_type: String,
  body body: BitArray,
) -> Result(Response(String), TelegaError) {
  use <- fetch_with_telemetry(method)
  use fetch_bits <- result.try(case client.fetch_bits_client {
    Some(f) -> Ok(f)
    None ->
      Error(error.FetchError(
        "No FetchBitsClient configured for multipart upload. Use "
        <> "client.set_fetch_bits_client or an adapter like telega_httpc.",
      ))
  })

  use req <- result.try(
    request.to(build_url(client, method))
    |> result.map_error(fn(_: Nil) { error.ApiToRequestConvertError }),
  )
  let bits_req =
    req
    |> request.set_body(body)
    |> request.set_method(Post)
    |> request.set_header("content-type", content_type)

  // The upload BODY is binary, but Telegram's RESPONSE is always JSON text, so
  // decode it back to a `Response(String)` at the boundary — that lets the send
  // share the exact queue and 429-retry path as every JSON call.
  let send = fn() { fetch_bits(bits_req) |> stringify_response }

  case client.request_queue {
    Some(queue) -> request_queue.execute(queue, send)
    None ->
      send_bits_with_retry(client, method, send, client.max_retry_attempts)
  }
}

fn stringify_response(
  response: Result(Response(BitArray), TelegaError),
) -> Result(Response(String), TelegaError) {
  use response <- result.try(response)
  bit_array.to_string(response.body)
  |> result.replace_error(error.FetchError(
    "upload response body was not valid UTF-8",
  ))
  |> result.map(response.set_body(response, _))
}

fn send_bits_with_retry(
  client: TelegramClient,
  method: String,
  send: fn() -> Result(Response(String), TelegaError),
  retries: Int,
) -> Result(Response(String), TelegaError) {
  let response = send()

  case retries {
    0 -> response
    _ ->
      case response {
        Ok(response) ->
          case response.status {
            429 -> {
              let retry_delay = retry_delay_from_response(response)
              emit_api_retry(
                method,
                client.max_retry_attempts - retries + 1,
                retry_delay,
              )
              process.sleep(retry_delay)
              send_bits_with_retry(client, method, send, retries - 1)
            }
            _ -> Ok(response)
          }
        Error(_) -> {
          emit_api_retry(
            method,
            client.max_retry_attempts - retries + 1,
            default_retry_delay,
          )
          process.sleep(default_retry_delay)
          send_bits_with_retry(client, method, send, retries - 1)
        }
      }
  }
}

fn apply_transformers(
  transformers: List(ApiRequestTransformer),
  request: TelegramApiRequest,
  terminal: fn(TelegramApiRequest) -> Result(Response(String), TelegaError),
) -> Result(Response(String), TelegaError) {
  case transformers {
    [] -> terminal(request)
    [transformer, ..rest] ->
      transformer(request, fn(request) {
        apply_transformers(rest, request, terminal)
      })
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

/// Set the binary HTTP client for file downloads.
pub fn set_fetch_bits_client(
  client client: TelegramClient,
  fetch_bits_client fetch_bits_client: FetchBitsClient,
) -> TelegramClient {
  TelegramClient(..client, fetch_bits_client: Some(fetch_bits_client))
}

/// Get the binary HTTP client, if configured.
pub fn get_fetch_bits_client(
  client client: TelegramClient,
) -> Option(FetchBitsClient) {
  client.fetch_bits_client
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

/// Get the bot token from the client
pub fn get_token(client: TelegramClient) -> String {
  client.token
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
  use <- fetch_with_telemetry(api_request.method)
  use api_request <- apply_transformers(client.transformers, api_request)

  let method = api_request.method
  use api_request <- result.try(api_to_request(api_request))
  let request_id = utils.random_string(32)

  case client.request_queue {
    Some(queue) ->
      request_queue.execute_with_rule(queue, request_id, rule_id, fn() {
        send_request(client, api_request)
      })

    None ->
      send_with_retry(client, method, api_request, client.max_retry_attempts)
  }
}

fn send_request(
  client: TelegramClient,
  api_request: Request(String),
) -> Result(Response(String), TelegaError) {
  client.fetch_client(api_request)
}

/// Wraps a request execution in `telega.api_call` start/stop/exception events.
fn fetch_with_telemetry(
  method: String,
  run: fn() -> Result(Response(String), TelegaError),
) -> Result(Response(String), TelegaError) {
  let metadata = [#("method", telemetry.StringValue(method))]
  let started_at = telemetry.monotonic_time()
  telemetry.execute(
    ["telega", "api_call", "start"],
    [#("system_time", telemetry.system_time())],
    metadata,
  )

  let result = run()

  let duration = telemetry.monotonic_time() - started_at
  case result {
    Ok(response) ->
      telemetry.execute(
        ["telega", "api_call", "stop"],
        [#("duration", duration)],
        [#("status", telemetry.IntValue(response.status)), ..metadata],
      )
    Error(error) ->
      telemetry.execute(
        ["telega", "api_call", "exception"],
        [#("duration", duration)],
        [#("error", telemetry.StringValue(string.inspect(error))), ..metadata],
      )
  }

  result
}

fn emit_api_retry(method: String, attempt: Int, retry_delay: Int) {
  telemetry.execute(
    ["telega", "api_call", "retry"],
    [#("retry_after", retry_delay)],
    [
      #("method", telemetry.StringValue(method)),
      #("attempt", telemetry.IntValue(attempt)),
    ],
  )
}

/// Extract the delay in milliseconds from a 429 response's
/// `parameters.retry_after` (seconds), falling back to the default delay.
fn retry_delay_from_response(response: Response(String)) -> Int {
  json.parse(
    response.body,
    decode.at(["parameters", "retry_after"], decode.int),
  )
  |> result.map(fn(retry_after) { retry_after * 1000 })
  |> result.unwrap(default_retry_delay)
}

fn send_with_retry(
  client: TelegramClient,
  method: String,
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
              let retry_delay = retry_delay_from_response(response)
              emit_api_retry(
                method,
                client.max_retry_attempts - retries + 1,
                retry_delay,
              )
              process.sleep(retry_delay)
              send_with_retry(client, method, api_request, retries - 1)
            }
            _ -> Ok(response)
          }
        }
        Error(_) -> {
          emit_api_retry(
            method,
            client.max_retry_attempts - retries + 1,
            default_retry_delay,
          )
          process.sleep(default_retry_delay)
          send_with_retry(client, method, api_request, retries - 1)
        }
      }
    }
  }
}

fn api_to_request(api_request) {
  case api_request {
    TelegramApiGetRequest(url:, query:, ..) -> {
      request.to(url)
      |> result.map(fn(req) {
        req
        |> request.set_method(Get)
        |> set_query(query)
      })
    }
    TelegramApiPostRequest(url:, body:, ..) -> {
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
  TelegramApiPostRequest(url: String, body: String, method: String)
  TelegramApiGetRequest(
    url: String,
    query: Option(List(#(String, String))),
    method: String,
  )
}

/// Get the Telegram API method name of a request (e.g. "sendMessage").
pub fn request_method(request request: TelegramApiRequest) -> String {
  request.method
}

/// Get the JSON body of a request. Returns `None` for GET requests.
pub fn request_body(request request: TelegramApiRequest) -> Option(String) {
  case request {
    TelegramApiPostRequest(body:, ..) -> Some(body)
    TelegramApiGetRequest(..) -> None
  }
}

/// Transform the JSON body of a POST request. GET requests are returned unchanged.
pub fn map_request_body(
  request request: TelegramApiRequest,
  mapper mapper: fn(String) -> String,
) -> TelegramApiRequest {
  case request {
    TelegramApiPostRequest(url:, body:, method:) ->
      TelegramApiPostRequest(url:, body: mapper(body), method:)
    TelegramApiGetRequest(..) -> request
  }
}

pub fn new_post_request(
  client client: TelegramClient,
  path path: String,
  body body: String,
) -> TelegramApiRequest {
  TelegramApiPostRequest(url: build_url(client, path), body:, method: path)
}

pub fn new_get_request(
  client client: TelegramClient,
  path path: String,
  query query: Option(List(#(String, String))),
) -> TelegramApiRequest {
  TelegramApiGetRequest(url: build_url(client, path), query:, method: path)
}

fn build_url(client client: TelegramClient, path path: String) {
  client.tg_api_url <> client.token <> "/" <> path
}
