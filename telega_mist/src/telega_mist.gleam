import gleam/bytes_tree
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json

import mist.{type Connection, type ResponseData}

import telega.{type Telega}
import telega/update
import telega/webhook

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

  case update.decode_raw(json) {
    Ok(message) -> {
      // Telegram waits for the response before sending the next update, so
      // the update is handled in its own process and answered right away.
      process.spawn(fn() {
        telega.handle_update(telega, message)
        Nil
      })
      empty_response(200)
    }
    Error(_) -> empty_response(400)
  }
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
pub const default_health_path = webhook.default_health_path

/// Answer a health probe on `path` (no leading slash), and let every other
/// request through to `next`. See `telega/webhook.health_probe` for what is
/// answered and why.
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
  case
    webhook.health_probe(telega, req.method, request.path_segments(req), path)
  {
    Ok(#(status, body)) -> json_response_with_status(body, status)
    Error(Nil) -> handler()
  }
}

/// The gate shared by the `handle_bot*` handlers (`telega/webhook.admit`):
/// other paths go to `next`, a wrong secret is `401`, an unhealthy bot `503`,
/// and only then is the body read and parsed as JSON (`400` on failure).
fn accept_bot_request(
  telega: Telega(session, error, dependencies),
  req: Request(Connection),
  max_body_limit: Int,
  next: fn() -> Response(ResponseData),
  run: fn(Dynamic) -> Response(ResponseData),
) -> Response(ResponseData) {
  case
    webhook.admit(
      telega,
      request.path_segments(req),
      request.get_header(req, webhook.secret_header),
    )
  {
    webhook.NotWebhook -> next()
    webhook.Rejected(status) -> empty_response(status)
    webhook.Admitted ->
      case mist.read_body(req, max_body_limit) {
        Ok(req) ->
          case json.parse_bits(req.body, decode.dynamic) {
            Ok(json) -> run(json)
            Error(_) -> empty_response(400)
          }
        Error(_) -> empty_response(400)
      }
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
