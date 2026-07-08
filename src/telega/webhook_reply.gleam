//// Webhook reply optimization: answer an update by embedding a bot API call
//// into the webhook HTTP response body instead of making a separate HTTP
//// request to Telegram.
////
//// Telegram allows the webhook HTTP response to carry one API call as JSON
//// (`{"method": "sendMessage", ...}`) — it is executed as if it were a normal
//// request, saving one HTTP round-trip and not counting against the request
//// quota. This module implements the claim protocol between a handler's API
//// call and the webhook HTTP process that is still holding the connection.
////
//// > ⚠️ Telegram does **not** return the result of an embedded call. A claimed
//// > call resolves to a synthetic stub: `True` for boolean methods, and for
//// > `sendMessage` a fake `Message` with `message_id: -1` and `date: 0`. If
//// > your handler needs the real `message_id`, do not use webhook reply for
//// > that call.
////
//// This is opt-in: adapters expose it as `handle_bot_with_reply`, built on
//// `telega.handle_update_webhook`. Regular `handle_bot` behavior is unchanged.
////
//// ## Usage
////
//// ```gleam
//// import telega_wisp
////
//// fn handle_request(bot, req) {
////   use <- telega_wisp.handle_bot_with_reply(bot, req, timeout: 5000)
////   // other routes...
//// }
//// ```
////
//// `telega_mist.handle_bot_with_reply` works the same way. For a custom
//// adapter, call `telega.handle_update_webhook(telega:, update:, timeout:)`
//// and map the result yourself:
////
//// ```gleam
//// case telega.handle_update_webhook(telega:, update:, timeout: 5000) {
////   // Answer 200 with this JSON body, Content-Type: application/json.
////   telega.JsonResponse(body:) -> todo
////   // Answer an empty 200.
////   telega.EmptyResponse -> todo
//// }
//// ```
////
//// With `handle_bot_with_reply`, a bot answering a callback button makes
//// **zero** outgoing HTTP calls for that update.
////
//// ## Eligible methods
////
//// Only the first eligible **POST** call per update is claimed:
////
//// - `answerCallbackQuery`, `deleteMessage`, `setMessageReaction`,
////   `sendChatAction` — boolean methods, the stub is honest;
//// - `sendMessage` — with the documented fake `Message` above (the chat id is
////   copied from your request when numeric, `-1` otherwise).
////
//// Everything else — GET requests included — always goes over HTTP. If a
//// handler needs the real `message_id` (to edit or reply to the message
//// later), that call must go over regular HTTP — do not use webhook reply
//// for it.
////
//// ## Latency semantics
////
//// Unlike `handle_bot`, the request process **waits** — up to `timeout` ms —
//// for the handler to either claim a call or finish. Telegram serializes
//// updates per webhook connection slot, so pick a `timeout` well below
//// Telegram's own webhook timeout; 5000 ms is a sensible default. When the
//// timeout fires the adapter answers an empty `200 OK`, the handler keeps
//// running in the background, and all of its API calls go over regular HTTP.
////
//// ## Claim protocol
////
//// - `telega.handle_update_webhook` creates a per-update `Envelope` and
////   dispatches the update, then waits on the envelope and on handler
////   completion, whichever comes first.
//// - The chat instance wraps that update's API client with `transformer`,
////   which serializes the *first* eligible call into a `Claim` and waits for
////   a grant for at most 100 ms.
//// - First-wins, race-free: only an HTTP process that is still waiting grants
////   a claim. If it already answered (or timed out), the grant wait expires
////   and the call falls back to a regular HTTP request. At most one claim is
////   attempted per update, so the 100 ms window is paid at most once, and
////   only when the HTTP process is already gone.
//// - On a grant, `handle_update_webhook` splices `"method"` into the request
////   params and returns `JsonResponse`.
////
//// The claimed call resolves inside your handler *immediately* on grant —
//// the handler does not wait for Telegram to execute it.
////
//// ## Testing
////
//// Use a routed mock and assert on the response body — see
//// `test/webhook_reply_test.gleam` for full examples:
////
//// ```gleam
//// let assert telega.JsonResponse(body:) =
////   telega.handle_update_webhook(telega: bot, update: raw, timeout: 5000)
//// string.contains(body, "\"method\":\"answerCallbackQuery\"")
//// ```

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/process.{type Subject}
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import gleam/option.{Some}
import gleam/result
import gleam/string

import telega/client

/// How long (ms) a claiming API call waits for the webhook HTTP process to
/// grant the claim before falling back to a regular HTTP request.
const claim_timeout = 100

/// An API call claimed for delivery in the webhook HTTP response body.
pub type WebhookReply {
  WebhookReply(method: String, params_json: String)
}

/// Message sent by a handler's API call to the webhook HTTP process holding
/// the connection. The sender waits on `granted`; only a still-waiting HTTP
/// process replies `True`. If it already responded or timed out, the wait
/// expires and the call goes over regular HTTP.
pub type EnvelopeMessage {
  Claim(reply: WebhookReply, granted: Subject(Bool))
}

/// Per-update channel owned by the webhook HTTP process.
pub type Envelope =
  Subject(EnvelopeMessage)

/// Build the API-call transformer that implements the handler side of the
/// claim protocol for one update. Installed automatically by the chat
/// instance when the update was dispatched with an envelope — not meant to be
/// added manually.
pub fn transformer(
  envelope envelope: Envelope,
) -> client.ApiRequestTransformer {
  // One claim attempt per update: the first eligible call flips the flag,
  // every later call skips straight to HTTP without waiting.
  let claimed = atomics_new(1, [])

  fn(request, next) {
    let method = client.request_method(request)
    case
      is_claimable(method) && !claim_suppressed(),
      client.request_body(request)
    {
      True, Some(params_json) ->
        case atomics_add_get(claimed, 1, 1) {
          1 -> {
            let granted = process.new_subject()
            process.send(
              envelope,
              Claim(reply: WebhookReply(method:, params_json:), granted:),
            )
            case process.receive(granted, claim_timeout) {
              Ok(True) -> Ok(synthetic_response(method, params_json))
              _ -> next(request)
            }
          }
          _ -> next(request)
        }
      _, _ -> next(request)
    }
  }
}

// Claim suppression ----------------------------------------------------------
//
// A claimed call resolves to a synthetic stub — `sendMessage` in particular
// yields a fake `message_id: -1`. Callers that need the real result (the
// dialog engine tracks the sent message's id to edit it later) opt their
// calls out via `without_claim`. The transformer runs in the calling process,
// so a process-dictionary flag is race-free.

const suppress_key = "__telega_webhook_reply_suppress"

/// Run `work` with webhook-reply claiming disabled for the calling process.
/// Use around API calls whose real result you need — a claimed call would
/// resolve to a synthetic stub instead (see the module doc).
pub fn without_claim(work work: fn() -> a) -> a {
  let _ = pdict_put(suppress_key, "1")
  let result = work()
  let _ = pdict_erase(suppress_key)
  result
}

fn claim_suppressed() -> Bool {
  pdict_get(suppress_key)
  |> decode.run(decode.string)
  |> result.is_ok
}

@external(erlang, "erlang", "put")
fn pdict_put(key: String, value: String) -> Dynamic

@external(erlang, "erlang", "get")
fn pdict_get(key: String) -> Dynamic

@external(erlang, "erlang", "erase")
fn pdict_erase(key: String) -> Dynamic

/// Whether a method may be answered in the webhook response body.
/// Only methods whose synthetic result is honest (`True` for boolean methods)
/// or explicitly documented as fake (`sendMessage`) are eligible.
fn is_claimable(method: String) -> Bool {
  case method {
    "answerCallbackQuery"
    | "deleteMessage"
    | "setMessageReaction"
    | "sendChatAction"
    | "sendMessage" -> True
    _ -> False
  }
}

/// Render a granted claim as the webhook HTTP response body:
/// the request params with `"method"` spliced in front.
pub fn to_response_body(reply reply: WebhookReply) -> String {
  let method_field = "{\"method\":\"" <> reply.method <> "\""
  case reply.params_json {
    "{}" -> method_field <> "}"
    params ->
      case string.starts_with(params, "{") {
        True -> method_field <> "," <> string.drop_start(params, 1)
        False -> method_field <> "}"
      }
  }
}

/// The response a claimed call resolves to locally. Telegram never returns
/// the result of an embedded call, so boolean methods get an honest `true`
/// and `sendMessage` gets the documented fake `Message`.
fn synthetic_response(method: String, params_json: String) -> Response(String) {
  let result = case method {
    "sendMessage" -> stub_message_json(params_json)
    _ -> "true"
  }
  response.new(200)
  |> response.set_body("{\"ok\":true,\"result\":" <> result <> "}")
}

/// Minimal `Message` JSON that satisfies `message_decoder()`. The fake fields
/// are intentional and documented: `message_id: -1`, `date: 0`. The chat id is
/// copied from the request params when it is numeric, `-1` otherwise.
fn stub_message_json(params_json: String) -> String {
  let chat_id =
    json.parse(params_json, decode.at(["chat_id"], decode.int))
    |> result.unwrap(-1)

  "{\"message_id\":-1,\"date\":0,\"chat\":{\"id\":"
  <> int.to_string(chat_id)
  <> ",\"type\":\"private\"}}"
}

type AtomicsRef

@external(erlang, "atomics", "new")
fn atomics_new(size: Int, options: List(options)) -> AtomicsRef

@external(erlang, "atomics", "add_get")
fn atomics_add_get(ref: AtomicsRef, index: Int, increment: Int) -> Int
