//// Tests for the webhook reply optimization: the claim protocol between a
//// handler's API call and the webhook HTTP process
//// (`telega/webhook_reply` + `telega.handle_update_webhook`).

import gleam/erlang/process
import gleam/list
import gleam/option.{None}
import gleam/string
import gleeunit
import gleeunit/should

import telega
import telega/api
import telega/bot.{type Context}
import telega/client
import telega/error.{type TelegaError}
import telega/model/encoder
import telega/model/types
import telega/router
import telega/testing/factory
import telega/testing/mock.{type ApiCall, ApiCall}
import telega/webhook_reply

pub fn main() {
  gleeunit.main()
}

fn answer_params(id: String) -> types.AnswerCallbackQueryParameters {
  types.new_answer_callback_query_parameters(id)
}

fn send_message_params(
  chat_id chat_id: Int,
  text text: String,
) -> types.SendMessageParameters {
  types.SendMessageParameters(
    business_connection_id: None,
    chat_id: types.Int(chat_id),
    message_thread_id: None,
    text:,
    parse_mode: None,
    entities: None,
    link_preview_options: None,
    disable_notification: None,
    protect_content: None,
    allow_paid_broadcast: None,
    message_effect_id: None,
    reply_parameters: None,
    reply_markup: None,
  )
}

/// A client whose calls go through the webhook-reply transformer bound to a
/// fresh envelope owned by the test process.
fn enveloped_client(
  routes routes: List(mock.MockRoute),
) -> #(client.TelegramClient, process.Subject(ApiCall), webhook_reply.Envelope) {
  let #(base_client, calls) = mock.routed_client(routes:)
  let envelope: webhook_reply.Envelope = process.new_subject()
  let client =
    client.use_transformer(base_client, webhook_reply.transformer(envelope:))
  #(client, calls, envelope)
}

fn bool_routes() -> List(mock.MockRoute) {
  [
    mock.route_with_response("answerCallbackQuery", mock.bool_response()),
    mock.route_with_response("setMyCommands", mock.bool_response()),
  ]
}

// --- Transformer-level tests -------------------------------------------------

pub fn granted_claim_skips_http_test() {
  let #(client, calls, envelope) = enveloped_client(routes: bool_routes())

  let results = process.new_subject()
  process.spawn(fn() {
    process.send(
      results,
      api.answer_callback_query(client, answer_params("cb-1")),
    )
  })

  // The handler process claims the call; grant it.
  let assert Ok(webhook_reply.Claim(reply:, granted:)) =
    process.receive(envelope, 1000)
  process.send(granted, True)

  reply.method |> should.equal("answerCallbackQuery")
  string.contains(reply.params_json, "cb-1") |> should.be_true

  // The claimed call resolved to a synthetic `true` without touching HTTP.
  let assert Ok(Ok(True)) = process.receive(results, 1000)
  mock.assert_no_calls(from: calls)
}

pub fn second_call_goes_over_http_test() {
  let #(client, calls, envelope) = enveloped_client(routes: bool_routes())

  let results = process.new_subject()
  process.spawn(fn() {
    let first = api.answer_callback_query(client, answer_params("first"))
    let second = api.answer_callback_query(client, answer_params("second"))
    process.send(results, #(first, second))
  })

  let assert Ok(webhook_reply.Claim(granted:, ..)) =
    process.receive(envelope, 1000)
  process.send(granted, True)

  let assert Ok(#(Ok(True), Ok(True))) = process.receive(results, 1000)

  // Only the second call reached HTTP: one claim attempt per update.
  let calls = mock.assert_call_count(from: calls, expected: 1)
  let assert [ApiCall(request:)] = calls
  string.contains(request.body, "second") |> should.be_true
}

pub fn unanswered_claim_falls_back_to_http_test() {
  // Envelope exists but nobody grants — as when the webhook HTTP process
  // already timed out and returned an empty 200.
  let #(client, calls, _envelope) = enveloped_client(routes: bool_routes())

  api.answer_callback_query(client, answer_params("cb-timeout"))
  |> should.equal(Ok(True))

  mock.assert_called_with_path(
    from: calls,
    path_contains: "answerCallbackQuery",
  )
}

pub fn non_allowlisted_method_is_not_claimed_test() {
  let #(client, calls, envelope) = enveloped_client(routes: bool_routes())

  api.set_my_commands(
    client:,
    commands: [
      types.BotCommand(
        command: "start",
        description: "Start",
        is_ephemeral: None,
      ),
    ],
    parameters: None,
  )
  |> should.equal(Ok(True))

  // Straight to HTTP, no claim was attempted.
  process.receive(envelope, 0) |> should.be_error
  mock.assert_called_with_path(from: calls, path_contains: "setMyCommands")
}

pub fn send_message_stub_decodes_test() {
  let #(client, calls, envelope) = enveloped_client(routes: [])

  let results = process.new_subject()
  process.spawn(fn() {
    process.send(
      results,
      api.send_message(client, send_message_params(chat_id: 42, text: "hi")),
    )
  })

  let assert Ok(webhook_reply.Claim(reply:, granted:)) =
    process.receive(envelope, 1000)
  process.send(granted, True)
  reply.method |> should.equal("sendMessage")

  // The synthetic Message carries the documented fake fields.
  let assert Ok(Ok(message)) = process.receive(results, 1000)
  message.message_id |> should.equal(-1)
  message.date |> should.equal(0)
  message.chat.id |> should.equal(42)
  mock.assert_no_calls(from: calls)
}

pub fn without_claim_suppresses_claiming_test() {
  let #(client, calls, envelope) = enveloped_client(routes: bool_routes())

  let results = process.new_subject()
  process.spawn(fn() {
    // Inside without_claim: no claim is attempted, the call goes over HTTP.
    let inside =
      webhook_reply.without_claim(fn() {
        api.answer_callback_query(client, answer_params("quiet"))
      })
    // Outside: claiming works again (the suppressed call did not consume the
    // one claim attempt per update).
    let outside = api.answer_callback_query(client, answer_params("loud"))
    process.send(results, #(inside, outside))
  })

  // The first (and only) Claim on the envelope is the outside call.
  let assert Ok(webhook_reply.Claim(reply:, granted:)) =
    process.receive(envelope, 1000)
  string.contains(reply.params_json, "loud") |> should.be_true
  process.send(granted, True)

  let assert Ok(#(Ok(True), Ok(True))) = process.receive(results, 1000)

  // Only the suppressed call reached HTTP.
  let calls = mock.assert_call_count(from: calls, expected: 1)
  let assert [ApiCall(request:)] = calls
  string.contains(request.body, "quiet") |> should.be_true
}

pub fn to_response_body_splices_method_test() {
  webhook_reply.WebhookReply(
    method: "answerCallbackQuery",
    params_json: "{\"callback_query_id\":\"1\"}",
  )
  |> webhook_reply.to_response_body
  |> should.equal(
    "{\"method\":\"answerCallbackQuery\",\"callback_query_id\":\"1\"}",
  )

  webhook_reply.WebhookReply(method: "sendChatAction", params_json: "{}")
  |> webhook_reply.to_response_body
  |> should.equal("{\"method\":\"sendChatAction\"}")
}

// --- End-to-end tests via telega.handle_update_webhook -----------------------

fn start_routes() -> List(mock.MockRoute) {
  [
    mock.route_with_response(
      "getMe",
      mock.ok_response(encoder.encode_user(factory.bot_user())),
    ),
    mock.route_with_response("setWebhook", mock.bool_response()),
    mock.route_with_response("answerCallbackQuery", mock.bool_response()),
  ]
}

fn start_webhook_bot(
  handler handler: fn(Context(Nil, TelegaError, Nil), String) ->
    Result(Context(Nil, TelegaError, Nil), TelegaError),
) -> #(telega.Telega(Nil, TelegaError, Nil), process.Subject(ApiCall)) {
  let #(client, calls) = mock.routed_client(routes: start_routes())

  let assert Ok(bot) =
    telega.new(
      api_client: client,
      url: "https://example.com",
      webhook_path: "/hook",
      secret_token: None,
    )
    |> telega.with_router(
      router.new("webhook_reply") |> router.on_any_text(handler),
    )
    |> telega.with_nil_session()
    |> telega.init()

  // Drop the setWebhook/getMe calls made on start.
  let _ = mock.get_calls(from: calls)
  #(bot, calls)
}

fn stop(bot: telega.Telega(Nil, TelegaError, Nil)) -> Nil {
  process.unlink(telega.get_supervisor_pid(bot))
  telega.shutdown(bot)
}

fn seen(calls: List(ApiCall), path: String) -> Bool {
  list.any(calls, fn(call) {
    let ApiCall(request:) = call
    string.contains(request.path, path)
  })
}

pub fn webhook_reply_answers_in_response_body_test() {
  let #(bot, calls) =
    start_webhook_bot(handler: fn(ctx, _text) {
      let assert Ok(True) =
        api.answer_callback_query(ctx.config.api_client, answer_params("e2e"))
      Ok(ctx)
    })

  let raw = factory.raw_update(message: factory.message(text: "hello"))
  let assert telega.JsonResponse(body:) =
    telega.handle_update_webhook(telega: bot, update: raw, timeout: 5000)

  string.contains(body, "\"method\":\"answerCallbackQuery\"")
  |> should.be_true
  string.contains(body, "e2e") |> should.be_true

  // The answered call never went over HTTP.
  seen(mock.get_calls(from: calls), "answerCallbackQuery")
  |> should.be_false

  stop(bot)
}

pub fn handler_without_claim_returns_empty_test() {
  let #(bot, _calls) = start_webhook_bot(handler: fn(ctx, _text) { Ok(ctx) })

  let raw = factory.raw_update(message: factory.message(text: "hello"))
  telega.handle_update_webhook(telega: bot, update: raw, timeout: 5000)
  |> should.equal(telega.EmptyResponse)

  stop(bot)
}

pub fn slow_handler_times_out_and_falls_back_to_http_test() {
  let #(bot, calls) =
    start_webhook_bot(handler: fn(ctx, _text) {
      process.sleep(300)
      let assert Ok(True) =
        api.answer_callback_query(ctx.config.api_client, answer_params("late"))
      Ok(ctx)
    })

  let raw = factory.raw_update(message: factory.message(text: "hello"))
  // The HTTP process gives up before the handler claims anything...
  telega.handle_update_webhook(telega: bot, update: raw, timeout: 100)
  |> should.equal(telega.EmptyResponse)

  // ...so the late call falls back to a regular HTTP request
  // (300ms handler sleep + 100ms unanswered claim window).
  process.sleep(700)
  seen(mock.get_calls(from: calls), "answerCallbackQuery")
  |> should.be_true

  stop(bot)
}
