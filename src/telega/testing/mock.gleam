//// Mock client and assertion utilities for testing bot API interactions.
////
//// ```gleam
//// import telega/testing/mock
////
//// let #(client, calls) = mock.client()
//// // ... use client in your bot setup ...
//// mock.assert_call_count(from: calls, expected: 1)
//// ```

import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response
import gleam/json
import gleam/list
import gleam/string

import telega/client
import telega/error.{type TelegaError}
import telega/model/encoder
import telega/testing/factory

/// Represents a recorded API call.
pub type ApiCall {
  ApiCall(request: Request(String))
}

type FetchClient =
  fn(Request(String)) -> Result(response.Response(String), TelegaError)

/// Returns a JSON string representing a valid `{"ok":true,"result":{...message...}}` response.
/// Useful for building custom mock clients that need to return valid Message responses.
pub fn message_response() -> String {
  let message_json = encoder.encode_message(factory.message(text: ""))
  "{\"ok\":true,\"result\":" <> json.to_string(message_json) <> "}"
}

/// Creates a mock Telegram client that records all API calls
/// and returns 200 OK with an empty successful response.
/// Note: This response will NOT decode as a valid Message.
/// Use `message_client()` if your handlers call reply functions.
pub fn client() -> #(client.TelegramClient, Subject(ApiCall)) {
  let calls = process.new_subject()
  let fetch_client: FetchClient = fn(req) {
    process.send(calls, ApiCall(request: req))
    Ok(response.new(200) |> response.set_body("{\"ok\":true,\"result\":{}}"))
  }
  let telegram_client =
    client.new(token: "test_token")
    |> client.set_fetch_client(fetch_client)
  #(telegram_client, calls)
}

/// Creates a mock Telegram client that records all API calls
/// and returns 200 OK with a valid Message response.
/// Use this when your handlers call `reply.with_text` or other reply functions.
pub fn message_client() -> #(client.TelegramClient, Subject(ApiCall)) {
  let response_body = message_response()
  let calls = process.new_subject()
  let fetch_client: FetchClient = fn(req) {
    process.send(calls, ApiCall(request: req))
    Ok(response.new(200) |> response.set_body(response_body))
  }
  let telegram_client =
    client.new(token: "test_token")
    |> client.set_fetch_client(fetch_client)
  #(telegram_client, calls)
}

/// Creates a mock client with a custom response handler.
pub fn client_with(
  handler handler: FetchClient,
) -> #(client.TelegramClient, Subject(ApiCall)) {
  let calls = process.new_subject()
  let fetch_client: FetchClient = fn(req) {
    process.send(calls, ApiCall(request: req))
    handler(req)
  }
  let telegram_client =
    client.new(token: "test_token")
    |> client.set_fetch_client(fetch_client)
  #(telegram_client, calls)
}

/// Drains all recorded API calls from the subject.
pub fn get_calls(from subject: Subject(ApiCall)) -> List(ApiCall) {
  drain_calls(subject, [])
}

fn drain_calls(subject: Subject(ApiCall), acc: List(ApiCall)) -> List(ApiCall) {
  case process.receive(subject, 0) {
    Ok(call) -> drain_calls(subject, [call, ..acc])
    Error(_) -> list.reverse(acc)
  }
}

/// Asserts the number of recorded API calls equals the expected count.
pub fn assert_call_count(
  from subject: Subject(ApiCall),
  expected expected: Int,
) -> List(ApiCall) {
  let calls = get_calls(from: subject)
  let count = list.length(calls)
  case count == expected {
    True -> calls
    False ->
      panic as {
        "Expected "
        <> string.inspect(expected)
        <> " API calls, got "
        <> string.inspect(count)
      }
  }
}

/// Asserts no API calls were recorded.
pub fn assert_no_calls(from subject: Subject(ApiCall)) -> Nil {
  let calls = get_calls(from: subject)
  case list.is_empty(calls) {
    True -> Nil
    False ->
      panic as {
        "Expected no API calls, got " <> string.inspect(list.length(calls))
      }
  }
}

/// Asserts at least one API call was made to a path containing the given string.
pub fn assert_called_with_path(
  from subject: Subject(ApiCall),
  path_contains path_contains: String,
) -> ApiCall {
  let calls = get_calls(from: subject)
  case
    list.find(calls, fn(call) {
      string.contains(call.request.path, path_contains)
    })
  {
    Ok(call) -> call
    Error(_) ->
      panic as {
        "No API call found with path containing '"
        <> path_contains
        <> "'. Calls: "
        <> string.inspect(calls)
      }
  }
}
