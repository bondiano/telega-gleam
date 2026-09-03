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
import gleam/bool
import gleam/dynamic/decode
import gleam/erlang/atom.{type Atom}
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/result
import gleam/string
import logging
import telega/internal/utils

import telega/error.{type TelegaError}
import telega/format.{type ParseMode}
import telega/internal/ets_table.{type EtsTable}
import telega/internal/method_info
import telega/internal/request_queue.{type RequestQueue}
import telega/telemetry

const telegram_url = "https://api.telegram.org/bot"

// --- Retry policy -----------------------------------------------------------

/// When a failed attempt may be repeated.
pub type RetryOn {
  /// Never repeat — hand the failure back after the first attempt.
  Never
  /// Repeat only methods that create nothing, so a replay cannot duplicate a
  /// message, an invite link or a payment. The list comes from
  /// `telega/internal/method_info`, generated from the Bot API spec.
  OnlyIdempotent
  /// Repeat every method, duplicates included. Pick this only when the caller
  /// deduplicates on its own.
  Always
}

/// How the client repeats a call that did not go through.
///
/// A 429 is special: Telegram answers it *instead of* doing the work and says
/// exactly how long to wait, so it is always retried (up to `max_attempts`)
/// whatever `retry_on_*` says — but only if the wait fits in
/// `max_retry_after_ms`, because sleeping it off blocks the calling process.
pub type RetryPolicy {
  RetryPolicy(
    /// Total attempts, the first one included. `1` disables retrying.
    max_attempts: Int,
    /// Delay before the first retry; each further one doubles it.
    base_delay_ms: Int,
    /// Cap on the doubling.
    max_delay_ms: Int,
    /// Spread the delay over `[delay / 2, delay]` so a fleet of bots that hit
    /// the same outage does not come back in lockstep.
    jitter: Bool,
    /// Whether a 5xx may be repeated.
    retry_on_server_errors: RetryOn,
    /// Whether a transport failure (no response at all) may be repeated.
    retry_on_transport_errors: RetryOn,
    /// Longest 429 `retry_after` worth sleeping off inside the calling process.
    /// Beyond it the 429 response is returned to the caller.
    max_retry_after_ms: Int,
  )
}

/// Four attempts, one second apart and doubling, and only methods that create
/// nothing are repeated on a 5xx or a transport failure.
pub fn default_retry_policy() -> RetryPolicy {
  RetryPolicy(
    max_attempts: 4,
    base_delay_ms: 1000,
    max_delay_ms: 30_000,
    jitter: True,
    retry_on_server_errors: OnlyIdempotent,
    retry_on_transport_errors: OnlyIdempotent,
    max_retry_after_ms: 60_000,
  )
}

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
    /// How failed calls are repeated. See `RetryPolicy`.
    retry_policy: RetryPolicy,
    /// The Telegram Bot API URL. Default is "https://api.telegram.org".
    /// This is useful for running [a local server](https://core.telegram.org/bots/api#using-a-local-bot-api-server).
    tg_api_url: String,
    /// The HTTP client to use.
    fetch_client: FetchClient,
    /// Optional HTTP client for binary downloads.
    fetch_bits_client: Option(FetchBitsClient),
    /// Request queue for rate limiting
    request_queue: Option(RequestQueue),
    /// Whether the queue paces requests per chat, which is the only reason to
    /// pay for reading a `chat_id` off every outgoing request.
    per_chat_limits: Bool,
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
    retry_policy: default_retry_policy(),
    tg_api_url: telegram_url,
    fetch_client:,
    fetch_bits_client: None,
    request_queue: None,
    per_chat_limits: False,
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

/// A transformer that logs every API call at `level`: the method and request
/// body on the way out, the status and elapsed time on the way back, the
/// description on a failure.
///
/// ```gleam
/// let client =
///   client.new(token:, fetch_client:)
///   |> client.use_transformer(client.trace_transformer(logging.Debug))
/// ```
///
/// Add it first if you want it to time the whole chain, last to see the
/// request as it actually goes out. Bodies are truncated and anything shaped
/// like a bot token is replaced with `<token>` — a fetch error carries the
/// request URL, and the URL carries the token. Everything else in a body is
/// logged verbatim, so this is a debugging tool, not something to leave on in
/// production with user data flowing through it.
pub fn trace_transformer(
  level level: logging.LogLevel,
) -> ApiRequestTransformer {
  fn(api_request: TelegramApiRequest, next) {
    let method = request_method(api_request)
    let started_at = telemetry.monotonic_time()

    logging.log(level, "telega -> " <> method <> traced_body(api_request))
    let result = next(api_request)
    let took = elapsed_ms(started_at)

    case result {
      Ok(response.Response(status:, body:, ..)) ->
        logging.log(
          level,
          "telega <- "
            <> method
            <> " "
            <> int.to_string(status)
            <> " in "
            <> took
            <> traced_text(body),
        )
      Error(reason) ->
        logging.log(
          level,
          "telega <- "
            <> method
            <> " failed in "
            <> took
            <> ": "
            <> redact_tokens(error.to_string(reason)),
        )
    }

    result
  }
}

fn traced_body(api_request: TelegramApiRequest) -> String {
  case api_request {
    TelegramApiPostRequest(body:, ..) -> traced_text(body)
    TelegramApiGetRequest(query: Some(query), ..) ->
      traced_text(string.inspect(query))
    TelegramApiGetRequest(..) -> ""
    TelegramApiMultipartRequest(body:, ..) ->
      " <" <> int.to_string(bit_array.byte_size(body)) <> " bytes>"
  }
}

const trace_body_limit = 500

fn traced_text(text: String) -> String {
  let text = redact_tokens(text)
  case string.length(text) > trace_body_limit {
    True -> " " <> string.slice(text, 0, trace_body_limit) <> "…"
    False -> " " <> text
  }
}

fn elapsed_ms(started_at: Int) -> String {
  let elapsed = telemetry.monotonic_time() - started_at
  int.to_string(native_to_millisecond(elapsed)) <> "ms"
}

/// A trace has no client to ask for the token, so it matches the shape
/// Telegram tokens have: digits, a colon, then 30+ token characters.
fn redact_tokens(text: String) -> String {
  case regexp.from_string("[0-9]{5,}:[A-Za-z0-9_-]{30,}") {
    Ok(token) -> regexp.replace(each: token, in: text, with: "<token>")
    Error(_) -> text
  }
}

/// Answer `getMe` from a cache instead of the network after the first call.
///
/// `getMe` is asked once at startup by `telega` itself and then again by
/// anything that wants `bot_info`; the answer only changes when you rename the
/// bot. The cache lives in an ETS table of its own, so it survives whichever
/// process happened to make the first call — and it is never invalidated, so a
/// bot renamed through `setMyName` keeps reporting the old name until the node
/// restarts.
///
/// Only a successful response is cached; a failure is retried the next time.
pub fn cache_get_me(client client: TelegramClient) -> TelegramClient {
  let table = ets_table.create_owned()

  use_transformer(client, fn(api_request, next) {
    case request_method(api_request) {
      "getMe" ->
        case ets_lookup(table, get_me_key) {
          [#(_, status, body)] ->
            Ok(response.Response(status:, headers: [], body:))
          _ -> {
            let result = next(api_request)
            case result {
              Ok(response.Response(status: 200, body:, ..)) -> {
                ets_insert(table, #(get_me_key, 200, body))
                Nil
              }
              _ -> Nil
            }
            result
          }
        }
      _ -> next(api_request)
    }
  })
}

const get_me_key = "getMe"

@external(erlang, "ets", "insert")
fn ets_insert(table: EtsTable, tuple: #(String, Int, String)) -> Bool

@external(erlang, "ets", "lookup")
fn ets_lookup(table: EtsTable, key: String) -> List(#(String, Int, String))

@external(erlang, "erlang", "convert_time_unit")
fn convert_time_unit(time: Int, from: Atom, to: Atom) -> Int

fn native_to_millisecond(time: Int) -> Int {
  convert_time_unit(time, atom.create("native"), atom.create("millisecond"))
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

/// Create a client that paces itself by Telegram's documented limits.
///
/// That is 30 requests per second overall, 1 per second to any one private
/// chat and 20 per minute to any one group, supergroup or channel — see
/// `default_request_queue_config`. Requests over the limit wait in the queue
/// instead of coming back as a 429.
///
/// ```gleam
/// let assert Ok(api_client) =
///   client.new_with_default_limits(token:, fetch_client:)
/// ```
pub fn new_with_default_limits(
  token token: String,
  fetch_client fetch_client: FetchClient,
) -> Result(TelegramClient, error.TelegaError) {
  new(token:, fetch_client:)
  |> set_request_queue(default_request_queue_config())
}

/// Create a new Telegram client with default request queue configuration.
///
/// The older name for `new_with_default_limits`; the two are the same call.
pub fn new_with_queue(
  token token: String,
  fetch_client fetch_client: FetchClient,
) -> Result(TelegramClient, error.TelegaError) {
  new_with_default_limits(token:, fetch_client:)
}

/// Send a request to the Telegram Bot API.
///
/// With a request [queue](#set_request_queue) configured, the call is paced by
/// the rule for the chat it addresses when the queue has per-chat limits, and
/// by the `default` rule otherwise. `getUpdates` never goes through the queue.
pub fn fetch(
  request api_request: TelegramApiRequest,
  client client: TelegramClient,
) -> Result(Response(String), TelegaError) {
  use <- fetch_with_telemetry(api_request.method)
  use api_request <- apply_transformers(client.transformers, api_request)

  let method = api_request.method
  let chat_id = chat_id_of(client, api_request)
  use api_request <- result.try(api_to_request(api_request))
  // The queued path runs the *same* send-with-retry as the direct one, so a 429
  // honours `parameters.retry_after` whether or not a queue is configured.
  let send = fn() { send_with_retry(client, method, api_request) }
  case queue_for(client, method) {
    Some(queue) -> request_queue.execute_for_chat(queue, chat_id, send)
    None -> send()
  }
}

/// The queue a call to `method` goes through, if any.
///
/// `getUpdates` never does. It is a long poll that holds its slot for the whole
/// polling timeout (30 s by default) while Telegram rate-limits nothing about
/// it, so queueing it would spend a concurrency slot the bot needs for its
/// replies. Only the polling worker calls it, one call at a time, so it needs
/// no pacing of its own.
fn queue_for(client: TelegramClient, method: String) -> Option(RequestQueue) {
  case method {
    "getUpdates" -> None
    _ -> client.request_queue
  }
}

/// The `chat_id` a request is addressed to, when the queue paces per chat.
///
/// Read straight off the outgoing request — the JSON body for a POST, the query
/// string for a GET — so no call site has to thread it through. A `@username`
/// chat has no numeric id and is paced by the global rules only, and so is a
/// raw upload, whose body is binary rather than JSON.
fn chat_id_of(
  client: TelegramClient,
  api_request: TelegramApiRequest,
) -> Option(Int) {
  use <- bool.guard(when: !client.per_chat_limits, return: None)

  case api_request {
    TelegramApiPostRequest(body:, ..) ->
      json.parse(body, decode.at(["chat_id"], decode.int))
      |> option.from_result
    TelegramApiGetRequest(query: Some(query), ..) ->
      list.key_find(query, "chat_id")
      |> result.try(int.parse)
      |> option.from_result
    TelegramApiGetRequest(..) | TelegramApiMultipartRequest(..) -> None
  }
}

/// Send a `multipart/form-data` POST (a `BitArray` body) to `method`, routed
/// through the SAME transformer chain, request queue and 429-retry path as
/// JSON calls, using the configured `FetchBitsClient`. This is how raw file
/// uploads (e.g. sending a photo by bytes) honor the one-queue rate-limit
/// invariant — there is no second HTTP client. Errors if no `FetchBitsClient`
/// is configured.
pub fn fetch_multipart(
  client client: TelegramClient,
  method method: String,
  content_type content_type: String,
  body body: BitArray,
) -> Result(Response(String), TelegaError) {
  use <- fetch_with_telemetry(method)
  use api_request <- apply_transformers(
    client.transformers,
    TelegramApiMultipartRequest(
      url: build_url(client, method),
      body:,
      method:,
      content_type:,
    ),
  )

  use fetch_bits <- result.try(case client.fetch_bits_client {
    Some(f) -> Ok(f)
    None ->
      Error(error.FetchError(
        "No FetchBitsClient configured for multipart upload. Use "
        <> "client.set_fetch_bits_client or an adapter like telega_httpc.",
      ))
  })

  // A transformer may hand back a different request kind; the bits client has
  // no binary body to send then, so refuse instead of panicking.
  use #(url, body, method, content_type) <- result.try(case api_request {
    TelegramApiMultipartRequest(url:, body:, method:, content_type:) ->
      Ok(#(url, body, method, content_type))
    TelegramApiPostRequest(..) | TelegramApiGetRequest(..) ->
      Error(error.FetchError(
        "A transformer replaced the multipart upload for "
        <> method
        <> " with a non-multipart request; uploads must stay multipart.",
      ))
  })

  use req <- result.try(
    request.to(url)
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

  let send_with_retries = fn() { do_send_with_retry(client, method, send, 1) }
  case queue_for(client, method) {
    Some(queue) ->
      request_queue.execute_for_chat(
        queue,
        chat_id_of(client, api_request),
        send_with_retries,
      )
    None -> send_with_retries()
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

/// Replace the whole retry policy.
///
/// ```gleam
/// client.new(token:, fetch_client:)
/// |> client.set_retry_policy(
///   client.RetryPolicy(
///     ..client.default_retry_policy(),
///     max_attempts: 6,
///     base_delay_ms: 250,
///     retry_on_transport_errors: client.Always,
///   ),
/// )
/// ```
pub fn set_retry_policy(
  client client: TelegramClient,
  retry_policy retry_policy: RetryPolicy,
) -> TelegramClient {
  TelegramClient(..client, retry_policy:)
}

/// The retry policy this client uses.
pub fn get_retry_policy(client client: TelegramClient) -> RetryPolicy {
  client.retry_policy
}

/// Set the maximum number of *retries* after the first attempt.
///
/// A shorthand for `RetryPolicy.max_attempts`, which counts the first attempt
/// too: `set_max_retry_attempts(0)` means one attempt and no retry.
pub fn set_max_retry_attempts(
  client client: TelegramClient,
  max_retry_attempts max_retry_attempts: Int,
) -> TelegramClient {
  TelegramClient(
    ..client,
    retry_policy: RetryPolicy(
      ..client.retry_policy,
      max_attempts: int.max(max_retry_attempts + 1, 1),
    ),
  )
}

/// Set the longest 429 `retry_after` the client will wait out.
///
/// Telegram can ask for minutes; sleeping that off blocks the process that made
/// the call (a chat instance, the broadcast actor). Beyond this the 429
/// response is returned to the caller instead. Default is 60_000 ms.
///
/// A shorthand for `RetryPolicy.max_retry_after_ms`.
pub fn set_max_retry_delay(
  client client: TelegramClient,
  max_retry_delay max_retry_delay: Int,
) -> TelegramClient {
  TelegramClient(
    ..client,
    retry_policy: RetryPolicy(
      ..client.retry_policy,
      max_retry_after_ms: max_retry_delay,
    ),
  )
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

/// Replaces every occurrence of the bot token in `text` with `<token>`.
///
/// Telegram puts the token in the URL of every request, so any message built
/// from a URL — an error, a log line, a link shown to a user — leaks it unless
/// it goes through this function first.
pub fn redact_token(
  client client: TelegramClient,
  text text: String,
) -> String {
  case client.token {
    "" -> text
    token -> string.replace(text, each: token, with: "<token>")
  }
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
    /// Per-chat pacing on top of the global rules. `None` paces by the global
    /// rules only, which is what a bot busy in one chat will notice first.
    per_chat: Option(PerChatLimits),
  )
}

/// Telegram's per-chat limits, which the global rate does not cover: a bot may
/// send 30 messages a second overall but only about one a second to the same
/// private chat, and about 20 a minute to the same group.
///
/// The queue tells the two apart by the sign of the `chat_id` — Telegram gives
/// groups, supergroups and channels negative ids.
pub type PerChatLimits {
  PerChatLimits(
    /// Requests allowed per `private_window_ms` to one private chat.
    private_rate: Int,
    private_window_ms: Int,
    /// Requests allowed per `group_window_ms` to one group/supergroup/channel.
    group_rate: Int,
    group_window_ms: Int,
  )
}

/// 1 request per second per private chat, 20 per minute per group.
pub fn default_per_chat_limits() -> PerChatLimits {
  let limits = request_queue.default_per_chat_limits()
  PerChatLimits(
    private_rate: limits.private_rate,
    private_window_ms: limits.private_window_ms,
    group_rate: limits.group_rate,
    group_window_ms: limits.group_window_ms,
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
    per_chat: option.map(default_config.per_chat, fn(limits) {
      PerChatLimits(
        private_rate: limits.private_rate,
        private_window_ms: limits.private_window_ms,
        group_rate: limits.group_rate,
        group_window_ms: limits.group_window_ms,
      )
    }),
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
/// // Start from the defaults and change what you need, so a new field in a
/// // later version does not turn into a compile error here.
/// let config = client.RequestQueueConfig(
///   ..client.default_request_queue_config(),
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
///   // 1/s per private chat, 20/min per group; `None` to pace by the global
///   // rules only.
///   per_chat: Some(client.default_per_chat_limits()),
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
      per_chat: option.map(config.per_chat, fn(limits) {
        request_queue.PerChatLimits(
          private_rate: limits.private_rate,
          private_window_ms: limits.private_window_ms,
          group_rate: limits.group_rate,
          group_window_ms: limits.group_window_ms,
        )
      }),
    ))
    |> result.map_error(fn(_) {
      error.FetchError("Failed to start request queue")
    }),
  )

  Ok(
    TelegramClient(
      ..client,
      request_queue: Some(queue),
      per_chat_limits: config.per_chat != None,
    ),
  )
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

  let send = fn() { send_with_retry(client, method, api_request) }
  case client.request_queue {
    Some(queue) ->
      request_queue.execute_with_rule(queue, request_id, rule_id, send)
    None -> send()
  }
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
/// `parameters.retry_after` (seconds), falling back to the policy's base delay.
fn retry_delay_from_response(
  policy: RetryPolicy,
  response: Response(String),
) -> Int {
  json.parse(
    response.body,
    decode.at(["parameters", "retry_after"], decode.int),
  )
  |> result.map(fn(retry_after) { retry_after * 1000 })
  |> result.unwrap(policy.base_delay_ms)
}

/// Exponential backoff for the `attempt`-th failed try (1-based), capped by
/// `max_delay_ms` and optionally spread over the lower half of the window.
fn backoff_delay(policy: RetryPolicy, attempt: Int) -> Int {
  let doublings = int.min(int.max(attempt - 1, 0), 30)
  let delay =
    int.min(
      policy.base_delay_ms * int.bitwise_shift_left(1, doublings),
      policy.max_delay_ms,
    )
  case policy.jitter && delay > 1 {
    False -> delay
    True -> {
      let half = delay / 2
      half + int.random(delay - half + 1)
    }
  }
}

/// Whether a failure of this kind, for this method, may be repeated.
fn may_retry(on: RetryOn, method: String) -> Bool {
  case on {
    Never -> False
    Always -> True
    OnlyIdempotent -> method_info.is_idempotent(method)
  }
}

fn send_with_retry(
  client: TelegramClient,
  method: String,
  api_request: Request(String),
) -> Result(Response(String), TelegaError) {
  do_send_with_retry(
    client,
    method,
    fn() { client.fetch_client(api_request) },
    1,
  )
}

fn do_send_with_retry(
  client: TelegramClient,
  method: String,
  send: fn() -> Result(Response(String), TelegaError),
  attempt: Int,
) -> Result(Response(String), TelegaError) {
  let policy = client.retry_policy
  let response = send()

  use <- bool.guard(when: attempt >= policy.max_attempts, return: response)

  let again = fn(delay) {
    emit_api_retry(method, attempt, delay)
    process.sleep(delay)
    do_send_with_retry(client, method, send, attempt + 1)
  }
  let retry_if_allowed = fn(on, give_up) {
    case may_retry(on, method) {
      True -> again(backoff_delay(policy, attempt))
      False -> give_up
    }
  }

  case response {
    Ok(res) ->
      case res.status {
        429 -> {
          let retry_delay = retry_delay_from_response(policy, res)
          case retry_delay > policy.max_retry_after_ms {
            // Sleeping this off would block the calling process for minutes;
            // hand the 429 back and let the caller decide.
            True -> Ok(res)
            False -> again(retry_delay)
          }
        }
        status if status >= 500 ->
          retry_if_allowed(policy.retry_on_server_errors, Ok(res))
        _ -> Ok(res)
      }
    Error(e) -> retry_if_allowed(policy.retry_on_transport_errors, Error(e))
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
    // Uploads never reach here — `fetch_multipart` owns that path because the
    // body is a `BitArray` and needs the bits client.
    TelegramApiMultipartRequest(..) -> Error(Nil)
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
  /// A raw file upload. The body is binary, so `request_body` and
  /// `map_request_body` do not apply — everything else a transformer does
  /// (inspecting the method, short-circuiting, post-processing the result)
  /// works the same.
  TelegramApiMultipartRequest(
    url: String,
    body: BitArray,
    method: String,
    content_type: String,
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
    TelegramApiGetRequest(..) | TelegramApiMultipartRequest(..) -> None
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
    TelegramApiGetRequest(..) | TelegramApiMultipartRequest(..) -> request
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
