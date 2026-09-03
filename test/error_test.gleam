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

// classify
//
// The Bot API has no error codes beyond the HTTP status: everything else is
// English prose. These pin down the reading, so a caller can `case` instead of
// spelling substrings of its own.

fn api_error(code: Int, description: String) -> error.TelegaError {
  error.TelegramApiError(error_code: code, description:, parameters: None)
}

pub fn classify_reads_403_descriptions_test() {
  api_error(403, "Forbidden: bot was blocked by the user")
  |> error.classify
  |> should.equal(error.BotBlocked)

  api_error(403, "Forbidden: user is deactivated")
  |> error.classify
  |> should.equal(error.UserDeactivated)

  api_error(403, "Forbidden: bot was kicked from the supergroup chat")
  |> error.classify
  |> should.equal(error.BotKicked)

  api_error(403, "Forbidden: bot is not a member of the channel chat")
  |> error.classify
  |> should.equal(error.BotKicked)

  // A 403 this module cannot read more precisely stays a plain `Forbidden`
  // rather than being guessed into one of the specific kinds.
  api_error(403, "Forbidden: something new Telegram invented")
  |> error.classify
  |> should.equal(error.Forbidden)
}

pub fn classify_reads_400_descriptions_test() {
  api_error(400, "Bad Request: chat not found")
  |> error.classify
  |> should.equal(error.ChatNotFound)

  api_error(400, "Bad Request: message is not modified")
  |> error.classify
  |> should.equal(error.MessageNotModified)

  api_error(400, "Bad Request: message to edit not found")
  |> error.classify
  |> should.equal(error.MessageNotFound)

  api_error(400, "Bad Request: message can't be edited")
  |> error.classify
  |> should.equal(error.MessageCantBeEdited)

  api_error(400, "Bad Request: message is too long")
  |> error.classify
  |> should.equal(error.MessageTooLong)

  api_error(400, "Bad Request: CHAT_WRITE_FORBIDDEN")
  |> error.classify
  |> should.equal(error.ChatWriteForbidden)

  api_error(400, "Bad Request: wrong file identifier")
  |> error.classify
  |> should.equal(error.BadRequest)
}

pub fn classify_needs_both_status_and_description_test() {
  // The words alone do not decide it: a 400 that mentions blocking is not a
  // blocked user.
  api_error(400, "Bad Request: bot was blocked by the user")
  |> error.classify
  |> should.equal(error.BadRequest)
}

pub fn classify_reads_response_parameters_test() {
  error.TelegramApiError(
    error_code: 429,
    description: "Too Many Requests: retry later",
    parameters: Some(types.ResponseParameters(
      migrate_to_chat_id: None,
      retry_after: Some(17),
    )),
  )
  |> error.classify
  |> should.equal(error.TooManyRequests(retry_after: 17))

  // A 429 without parameters is still a flood wait; Telegram just did not say
  // for how long.
  api_error(429, "Too Many Requests")
  |> error.classify
  |> should.equal(error.TooManyRequests(retry_after: 0))

  error.TelegramApiError(
    error_code: 400,
    description: "Bad Request: group chat was upgraded to a supergroup chat",
    parameters: Some(types.ResponseParameters(
      migrate_to_chat_id: Some(-1_001_234_567_890),
      retry_after: None,
    )),
  )
  |> error.classify
  |> should.equal(error.ChatMigrated(new_chat_id: -1_001_234_567_890))
}

pub fn classify_reads_status_alone_test() {
  api_error(401, "Unauthorized")
  |> error.classify
  |> should.equal(error.Unauthorized)

  api_error(500, "Internal Server Error")
  |> error.classify
  |> should.equal(error.ServerError)

  api_error(502, "Bad Gateway")
  |> error.classify
  |> should.equal(error.ServerError)
}

pub fn classify_non_api_errors_as_other_test() {
  // A transport failure carries no Telegram status to read.
  error.FetchError("connection refused")
  |> error.classify
  |> should.equal(error.Other)
}

pub fn predicates_agree_with_classify_test() {
  let blocked = api_error(403, "Forbidden: bot was blocked by the user")
  let write_forbidden =
    api_error(400, "Bad Request: have no rights to send a message")
  let flood = api_error(429, "Too Many Requests")

  error.is_bot_blocked(blocked) |> should.be_true
  error.is_chat_unreachable(blocked) |> should.be_true
  // A chat the bot may not write in is as undeliverable as a blocked one:
  // retrying the same call never helps.
  error.is_chat_unreachable(write_forbidden) |> should.be_true
  error.is_chat_unreachable(flood) |> should.be_false
  error.is_message_too_long(api_error(400, "Bad Request: message is too long"))
  |> should.be_true
}
