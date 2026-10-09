import gleam/dynamic
import gleam/erlang/process
import gleam/http/request

import wisp.{type Request as WispRequest, type Response as WispResponse}

import telega.{type Telega}
import telega/update
import telega/webhook

/// A middleware function to handle incoming requests from the Telegram API.
/// Handles a request to the bot webhook endpoint, decodes the incoming message,
/// validates the secret token, and passes the message to the bot for processing.
///
/// ```gleam
/// import wisp.{type Request, type Response}
/// import telega.{type Bot}
/// import telega_wisp
///
/// fn handle_request(bot: Bot, req: Request) -> Response {
///   use <- telega_wisp.handle_bot(req, bot)
///   // ...
/// }
/// ```
pub fn handle_bot(
  telega telega: Telega(session, error, dependencies),
  req req: WispRequest,
  next handler: fn() -> WispResponse,
) -> WispResponse {
  use json <- accept_bot_request(telega, req, handler)

  case update.decode_raw(json) {
    Ok(message) -> {
      // Telegram waits for the response before sending the next update, so
      // the update is handled in its own process and answered right away.
      process.spawn(fn() {
        telega.handle_update(telega, message)
        Nil
      })
      wisp.ok()
    }
    Error(_) -> wisp.response(400)
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
  req req: WispRequest,
  timeout timeout: Int,
  next handler: fn() -> WispResponse,
) -> WispResponse {
  use json <- accept_bot_request(telega, req, handler)

  case update.decode_raw(json) {
    Ok(message) ->
      case telega.handle_update_webhook(telega, message, timeout) {
        telega.JsonResponse(body:) -> wisp.json_response(body, 200)
        telega.EmptyResponse -> wisp.ok()
      }
    Error(_) -> wisp.response(400)
  }
}

/// The path `handle_health` answers on by default.
pub const default_health_path = webhook.default_health_path

/// Answer a health probe on `path` (no leading slash), and let every other
/// request through to `next`. See `telega/webhook.health_probe` for what is
/// answered and why.
///
/// ```gleam
/// fn handle_request(bot: Telega(s, e, d), req: Request) -> Response {
///   use <- telega_wisp.handle_health(telega: bot, req:, path: telega_wisp.default_health_path)
///   use <- telega_wisp.handle_bot(telega: bot, req:)
///   // ... your own routes
/// }
/// ```
pub fn handle_health(
  telega telega: Telega(session, error, dependencies),
  req req: WispRequest,
  path path: String,
  next handler: fn() -> WispResponse,
) -> WispResponse {
  case webhook.health_probe(telega, req.method, wisp.path_segments(req), path) {
    Ok(#(status, body)) -> wisp.json_response(body, status)
    Error(Nil) -> handler()
  }
}

/// The gate shared by `handle_bot` and `handle_bot_with_reply`
/// (`telega/webhook.admit`): other paths go to `next`, a wrong secret is `401`,
/// an unhealthy bot `503`, and only then is the JSON body read.
fn accept_bot_request(
  telega: Telega(session, error, dependencies),
  req: WispRequest,
  next: fn() -> WispResponse,
  run: fn(dynamic.Dynamic) -> WispResponse,
) -> WispResponse {
  case
    webhook.admit(
      telega,
      wisp.path_segments(req),
      request.get_header(req, webhook.secret_header),
    )
  {
    webhook.NotWebhook -> next()
    webhook.Rejected(status) -> wisp.response(status)
    webhook.Admitted -> {
      use json <- wisp.require_json(req)
      run(json)
    }
  }
}
