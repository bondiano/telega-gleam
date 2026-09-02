//// M3 — the error model must carry what Telegram actually said.
////
//// `parameters.retry_after` and `parameters.migrate_to_chat_id` are the two
//// fields callers have to act on, and "this chat is gone" needs to be as
//// classifiable as the 400 edit errors are.

import gleam/http/response
import gleam/option.{None, Some}
import gleeunit/should

import telega/api
import telega/client
import telega/error
import telega/model/types

fn client_answering(status: Int, body: String) -> client.TelegramClient {
  client.new(token: "test-token", fetch_client: fn(_req) {
    Ok(response.Response(status:, headers: [], body:))
  })
  |> client.set_max_retry_attempts(0)
}

pub fn api_error_carries_response_parameters_test() {
  let client =
    client_answering(
      429,
      "{\"ok\": false, \"error_code\": 429, \"description\": \"Too Many Requests\", \"parameters\": {\"retry_after\": 17}}",
    )

  let assert Error(err) = api.get_me(client)

  err
  |> should.equal(error.TelegramApiError(
    error_code: 429,
    description: "Too Many Requests",
    parameters: Some(types.ResponseParameters(
      migrate_to_chat_id: None,
      retry_after: Some(17),
    )),
  ))

  error.retry_after(err) |> should.equal(Some(17))
}

pub fn api_error_carries_migrate_to_chat_id_test() {
  let client =
    client_answering(
      400,
      "{\"ok\": false, \"error_code\": 400, \"description\": \"Bad Request: group chat was upgraded to a supergroup chat\", \"parameters\": {\"migrate_to_chat_id\": -1001234567890}}",
    )

  let assert Error(err) = api.get_me(client)

  error.migrate_to_chat_id(err) |> should.equal(Some(-1_001_234_567_890))
  error.retry_after(err) |> should.equal(None)
}

pub fn api_error_without_parameters_test() {
  let client =
    client_answering(
      400,
      "{\"ok\": false, \"error_code\": 400, \"description\": \"Bad Request: chat not found\"}",
    )

  let assert Error(err) = api.get_me(client)

  error.retry_after(err) |> should.equal(None)
  error.migrate_to_chat_id(err) |> should.equal(None)
}

pub fn unreachable_chat_classifiers_test() {
  let blocked =
    error.TelegramApiError(403, "Forbidden: bot was blocked by the user", None)
  let deactivated =
    error.TelegramApiError(403, "Forbidden: user is deactivated", None)
  let not_found =
    error.TelegramApiError(400, "Bad Request: chat not found", None)
  let flood = error.TelegramApiError(429, "Too Many Requests", None)

  error.is_bot_blocked(blocked) |> should.be_true()
  error.is_bot_blocked(deactivated) |> should.be_false()

  error.is_chat_unreachable(blocked) |> should.be_true()
  error.is_chat_unreachable(deactivated) |> should.be_true()
  error.is_chat_unreachable(not_found) |> should.be_true()
  error.is_chat_unreachable(flood) |> should.be_false()
}
