//// What every webhook adapter checks before an update reaches the bot.
////
//// `telega_wisp` and `telega_mist` are thin: they read the request and answer
//// it. The decisions — is this the bot's path, does the secret match, is the
//// bot in a state to take an update, is this a health probe — live here, so
//// an adapter for another server is a few lines over `admit` and
//// `health_probe`, and all adapters reject and report alike.

import gleam/http
import gleam/result
import gleam/string

import telega.{type Telega}

/// The header Telegram sends the `secret_token` of `setWebhook` in.
pub const secret_header = "x-telegram-bot-api-secret-token"

/// The path `health_probe` answers on when an adapter picks the default.
pub const default_health_path = "healthz"

/// Whether a request on the bot's webhook path may be processed.
pub type Admission {
  /// Not the bot's webhook path: the adapter's other routes get the request.
  NotWebhook
  /// The bot's path, but not to be processed: answer `status` and nothing
  /// else. `401` when the secret token is wrong; `503` when the bot is
  /// draining, over its `with_max_in_flight` cap or not answering, so
  /// Telegram redelivers the update after the deploy or the spike instead of
  /// it being lost.
  Rejected(status: Int)
  /// Read the body, decode the update and hand it to the bot.
  Admitted
}

/// Decide what to do with a request, from its path segments and the value of
/// [`secret_header`](#secret_header) (`Error(Nil)` when absent).
///
/// The checks run in this order, so a request that is not ours costs nothing
/// and a wrong secret is turned away before the body is read.
pub fn admit(
  telega telega: Telega(session, error, dependencies),
  path_segments path_segments: List(String),
  secret_token secret_token: Result(String, Nil),
) -> Admission {
  case telega.is_webhook_path(telega, string.join(path_segments, "/")) {
    False -> NotWebhook
    True ->
      case
        telega.is_secret_token_valid(telega, result.unwrap(secret_token, ""))
      {
        False -> Rejected(401)
        True ->
          case telega.is_healthy(telega.health(telega)) {
            False -> Rejected(503)
            True -> Admitted
          }
      }
  }
}

/// `Ok(#(status, json))` when the request is a health probe — a `GET` on
/// `path` (leading and trailing slashes ignored) — and `Error(Nil)` for any
/// other request.
///
/// The status is `200` while the bot actor is alive, accepting updates and
/// below the cap set by `telega.with_max_in_flight`, `503` otherwise; the body
/// is `telega.health_to_json`. That is what a load balancer, a Kubernetes
/// readiness probe or a fly.io health check wants: a deploy drains out of
/// rotation instead of black-holing updates.
pub fn health_probe(
  telega telega: Telega(session, error, dependencies),
  method method: http.Method,
  path_segments path_segments: List(String),
  path path: String,
) -> Result(#(Int, String), Nil) {
  case method == http.Get && path_segments == segments(path) {
    False -> Error(Nil)
    True -> {
      let health = telega.health(telega)
      Ok(#(telega.health_status_code(health), telega.health_to_json(health)))
    }
  }
}

fn segments(path: String) -> List(String) {
  path
  |> string.trim
  |> string.split("/")
  |> list_drop_empty
}

fn list_drop_empty(segments: List(String)) -> List(String) {
  case segments {
    [] -> []
    ["", ..rest] -> list_drop_empty(rest)
    [segment, ..rest] -> [segment, ..list_drop_empty(rest)]
  }
}
