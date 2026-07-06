import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/erlang/process
import gleam/http/request
import gleam/result
import gleam/string
import telega/error

import wisp.{type Request as WispRequest, type Response as WispResponse}

import telega.{type Telega}
import telega/update

const secret_header = "x-telegram-bot-api-secret-token"

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

  // Telegram will wait response from the server, before sending the next update
  // So we need to handle it in a separate process and return response immediately.
  process.spawn(fn() {
    case update.decode_raw(json) {
      Ok(message) -> {
        telega.handle_update(telega, message)
        Nil
      }
      Error(e) -> panic as { "Failed to decode update" <> error.to_string(e) }
    }
  })

  wisp.ok()
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

/// Common webhook gate shared by `handle_bot` and `handle_bot_with_reply`:
/// non-webhook paths go to `next`, then the JSON body is required, the secret
/// token validated (401), and updates are rejected with 503 while the bot is
/// draining (graceful shutdown) so Telegram retries them after the deploy
/// instead of losing them.
fn accept_bot_request(
  telega: Telega(session, error, dependencies),
  req: WispRequest,
  next: fn() -> WispResponse,
  run: fn(Dynamic) -> WispResponse,
) -> WispResponse {
  use <- bool.lazy_guard(!is_bot_request(telega, req), next)
  use json <- wisp.require_json(req)
  use <- bool.lazy_guard(!is_secret_token_valid(telega, req), fn() {
    wisp.response(401)
  })
  use <- bool.lazy_guard(telega.is_draining(telega), fn() { wisp.response(503) })

  run(json)
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
  req: WispRequest,
) -> Bool {
  let path = wisp.path_segments(req) |> string.join("/")
  telega.is_webhook_path(telega, path)
}
