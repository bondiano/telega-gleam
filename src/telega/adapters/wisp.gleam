import gleam/bool
import gleam/erlang/process
import gleam/http/request
import gleam/http/response.{Response as HttpResponse}
import gleam/result

import wisp.{
  type Request as WispRequest, type Response as WispResponse,
  Empty as WispEmptyBody,
}

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
/// import telega/adapters/wisp as telega_wisp
///
/// fn handle_request(bot: Bot, req: Request) -> Response {
///   use <- telega_wisp.handle_bot(req, bot)
///   // ...
/// }
/// ```
pub fn handle_bot(
  telega telega: Telega(session, error),
  req req: WispRequest,
  next handler: fn() -> WispResponse,
) -> WispResponse {
  use <- bool.lazy_guard(!is_bot_request(telega, req), handler)
  use json <- wisp.require_json(req)
  use <- bool.lazy_guard(!is_secret_token_valid(telega, req), fn() {
    HttpResponse(401, [], WispEmptyBody)
  })

  // Telegram will wait response from the server, before sending the next update
  // So we need to handle it in a separate process and return response immediately.
  process.spawn(fn() {
    let assert Ok(message) = update.decode_raw(json)
    telega.handle_update(telega, message)
  })

  wisp.ok()
}

fn is_secret_token_valid(telega: Telega(session, error), req) -> Bool {
  let secret_header_value =
    request.get_header(req, secret_header)
    |> result.unwrap("")

  telega.is_secret_token_valid(telega, secret_header_value)
}

fn is_bot_request(telega: Telega(session, error), req) -> Bool {
  case wisp.path_segments(req) {
    [segment] -> telega.is_webhook_path(telega, segment)
    _ -> False
  }
}
