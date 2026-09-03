import gleam/bool
import gleam/bytes_tree
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/result
import gleam/string

import mist.{type Connection, type ResponseData}

import telega.{type Telega}
import telega/error
import telega/update

const secret_header = "x-telegram-bot-api-secret-token"

/// Default maximum size in bytes for the incoming webhook request body.
///
/// Telegram updates are small, so 4MB is plenty while keeping a sane upper
/// bound. Use `handle_bot_with_limit` to override it.
pub const default_max_body_limit = 4_000_000

/// A handler to process incoming requests from the Telegram API directly on top
/// of [mist](https://hexdocs.pm/mist/), without wisp — for minimalistic
/// deployments.
///
/// It checks the webhook path, validates the secret token, decodes the incoming
/// update, and dispatches it to the bot in a separate process so the `200 OK`
/// response is returned immediately (Telegram waits for the response before
/// sending the next update).
///
/// ```gleam
/// import gleam/http/request.{type Request}
/// import gleam/http/response.{type Response}
/// import mist.{type Connection, type ResponseData}
/// import telega.{type Telega}
/// import telega_mist
///
/// fn handle_request(
///   req: Request(Connection),
///   bot: Telega(session, error, dependencies),
/// ) -> Response(ResponseData) {
///   use <- telega_mist.handle_bot(telega: bot, req:)
///
///   // Your other routes here...
///   response.new(404) |> response.set_body(mist.Bytes(bytes_tree.new()))
/// }
/// ```
pub fn handle_bot(
  telega telega: Telega(session, error, dependencies),
  req req: Request(Connection),
  next handler: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  handle_bot_with_limit(
    telega:,
    req:,
    max_body_limit: default_max_body_limit,
    next: handler,
  )
}

/// Same as `handle_bot`, but lets you set the maximum request body size in bytes.
pub fn handle_bot_with_limit(
  telega telega: Telega(session, error, dependencies),
  req req: Request(Connection),
  max_body_limit max_body_limit: Int,
  next handler: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  use json <- accept_bot_request(telega, req, max_body_limit, handler)

  // Telegram waits for a response before sending the next update, so we
  // handle it in a separate process and return the response immediately.
  process.spawn(fn() {
    case update.decode_raw(json) {
      Ok(message) -> {
        telega.handle_update(telega, message)
        Nil
      }
      Error(e) -> panic as { "Failed to decode update" <> error.to_string(e) }
    }
  })

  empty_response(200)
}

/// Like `handle_bot`, but lets the handler answer the update directly in the
/// webhook HTTP response body ([webhook reply](https://core.telegram.org/bots/api#making-requests-when-getting-updates)),
/// saving one HTTP round-trip for the first eligible API call.
///
/// Unlike `handle_bot`, the request process waits up to `timeout` ms for the
/// handler to either claim a reply or finish; after the timeout it answers an
/// empty `200 OK` and the handler keeps running in the background. Pick a
/// `timeout` safely below Telegram's webhook timeout — e.g. 5000 ms.
///
/// > ⚠️ A claimed call resolves to a synthetic stub inside the handler (`True`
/// > for boolean methods, a fake `Message` for `sendMessage`).
/// > Full guide in telega's `telega/webhook_reply` module docs.
pub fn handle_bot_with_reply(
  telega telega: Telega(session, error, dependencies),
  req req: Request(Connection),
  timeout timeout: Int,
  next handler: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  handle_bot_with_reply_and_limit(
    telega:,
    req:,
    timeout:,
    max_body_limit: default_max_body_limit,
    next: handler,
  )
}

/// Same as `handle_bot_with_reply`, but lets you set the maximum request body
/// size in bytes.
pub fn handle_bot_with_reply_and_limit(
  telega telega: Telega(session, error, dependencies),
  req req: Request(Connection),
  timeout timeout: Int,
  max_body_limit max_body_limit: Int,
  next handler: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  use json <- accept_bot_request(telega, req, max_body_limit, handler)

  case update.decode_raw(json) {
    Ok(message) ->
      case telega.handle_update_webhook(telega, message, timeout) {
        telega.JsonResponse(body:) -> json_response(body)
        telega.EmptyResponse -> empty_response(200)
      }
    Error(_) -> empty_response(400)
  }
}

/// The path `handle_health` answers on by default.
pub const default_health_path = "healthz"

/// Answer a health probe on `path` (no leading slash), and let every other
/// request through to `next`.
///
/// `GET /healthz` answers `200` with
/// `{"status":"healthy","in_flight":3,"chat_instances":41}` while the bot
/// actor is alive, accepting updates, and below the cap set by
/// `telega.with_max_in_flight`; `503` with the same shape (`draining`,
/// `overloaded`, `unavailable`) otherwise. That is what a load balancer, a
/// Kubernetes readiness probe or a fly.io health check wants: a deploy drains
/// out of rotation instead of black-holing updates.
///
/// ```gleam
/// fn handle_request(req: Request(Connection), bot: Telega(s, e, d)) {
///   use <- telega_mist.handle_health(telega: bot, req:, path: telega_mist.default_health_path)
///   use <- telega_mist.handle_bot(telega: bot, req:)
///   response.new(404) |> response.set_body(mist.Bytes(bytes_tree.new()))
/// }
/// ```
pub fn handle_health(
  telega telega: Telega(session, error, dependencies),
  req req: Request(Connection),
  path path: String,
  next handler: fn() -> Response(ResponseData),
) -> Response(ResponseData) {
  use <- bool.lazy_guard(!is_health_request(req, path), handler)

  let health = telega.health(telega)
  json_response_with_status(
    telega.health_to_json(health),
    telega.health_status_code(health),
  )
}

fn is_health_request(req: Request(Connection), path: String) -> Bool {
  req.method == http.Get
  && request.path_segments(req) == string.split(normalize_path(path), "/")
}

fn normalize_path(path: String) -> String {
  path |> string.trim |> trim_slashes
}

fn trim_slashes(path: String) -> String {
  case string.starts_with(path, "/") {
    True -> trim_slashes(string.drop_start(path, 1))
    False ->
      case string.ends_with(path, "/") {
        True -> trim_slashes(string.drop_end(path, 1))
        False -> path
      }
  }
}

/// Common webhook gate shared by `handle_bot*` handlers: non-webhook paths go
/// to `next`, then the secret token is validated (401), updates are rejected
/// with 503 unless the bot is healthy — draining (graceful shutdown), over the
/// `with_max_in_flight` cap, or not answering at all — so Telegram retries
/// them after the deploy or the spike instead of them being lost, and finally
/// the body is read and parsed as JSON (400 on failure).
fn accept_bot_request(
  telega: Telega(session, error, dependencies),
  req: Request(Connection),
  max_body_limit: Int,
  next: fn() -> Response(ResponseData),
  run: fn(Dynamic) -> Response(ResponseData),
) -> Response(ResponseData) {
  use <- bool.lazy_guard(!is_bot_request(telega, req), next)
  use <- bool.lazy_guard(!is_secret_token_valid(telega, req), fn() {
    empty_response(401)
  })
  use <- bool.lazy_guard(!telega.is_healthy(telega.health(telega)), fn() {
    empty_response(503)
  })

  case mist.read_body(req, max_body_limit) {
    Ok(req) ->
      case json.parse_bits(req.body, decode.dynamic) {
        Ok(json) -> run(json)
        Error(_) -> empty_response(400)
      }
    Error(_) -> empty_response(400)
  }
}

fn empty_response(status: Int) -> Response(ResponseData) {
  response.new(status)
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}

fn json_response(body: String) -> Response(ResponseData) {
  json_response_with_status(body, 200)
}

fn json_response_with_status(
  body: String,
  status: Int,
) -> Response(ResponseData) {
  response.new(status)
  |> response.set_header("content-type", "application/json")
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}

fn is_secret_token_valid(
  telega: Telega(session, error, dependencies),
  req,
) -> Bool {
  let secret_header_value =
    request.get_header(req, secret_header)
    |> result.unwrap("")

  telega.is_secret_token_valid(telega, secret_header_value)
}

fn is_bot_request(
  telega: Telega(session, error, dependencies),
  req: Request(Connection),
) -> Bool {
  let path = request.path_segments(req) |> string.join("/")
  telega.is_webhook_path(telega, path)
}
