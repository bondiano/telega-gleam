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

/// Wraps a `Json` value into `{"ok":true,"result":...}` Telegram API response format.
pub fn ok_response(result result: json.Json) -> String {
  json.to_string(json.object([#("ok", json.bool(True)), #("result", result)]))
}

/// Returns a `{"ok":true,"result":true}` response string.
/// Use for endpoints that return a boolean (e.g. `answerCallbackQuery`, `deleteMessage`).
pub fn bool_response() -> String {
  ok_response(result: json.bool(True))
}

/// Returns a JSON string representing a valid `{"ok":true,"result":{...message...}}` response.
/// Useful for building custom mock clients that need to return valid Message responses.
pub fn message_response() -> String {
  ok_response(result: encoder.encode_message(factory.message(text: "")))
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

// ---------------------------------------------------------------------------
// Routed mock client (MSW-like pattern)
// ---------------------------------------------------------------------------

/// A route that matches API requests by path and returns a custom response.
pub type MockRoute {
  MockRoute(
    path_contains: String,
    handler: fn(Request(String)) ->
      Result(response.Response(String), TelegaError),
  )
}

/// Creates a route that matches requests whose path contains `path_contains`
/// and delegates to the given handler function.
pub fn route(
  path_contains path_contains: String,
  handler handler: fn(Request(String)) ->
    Result(response.Response(String), TelegaError),
) -> MockRoute {
  MockRoute(path_contains:, handler:)
}

/// Creates a route that matches requests whose path contains `path_contains`
/// and returns a 200 OK with the given body string.
pub fn route_with_body(
  path_contains path_contains: String,
  body body: String,
) -> MockRoute {
  MockRoute(path_contains:, handler: fn(_req) {
    Ok(response.new(200) |> response.set_body(body))
  })
}

/// Creates a route that matches requests whose path contains `path_contains`
/// and returns a 200 OK with the given response string (from `ok_response`, `bool_response`, etc.).
/// Prefer this over `route_with_body` for type-safe response building.
pub fn route_with_response(
  path_contains path_contains: String,
  response response_body: String,
) -> MockRoute {
  MockRoute(path_contains:, handler: fn(_req) {
    Ok(response.new(200) |> response.set_body(response_body))
  })
}

/// Creates a mock client that routes requests through a list of `MockRoute`s.
/// Routes are checked in order; first match wins. Unmatched requests fall back
/// to a default `message_response()`.
pub fn routed_client(
  routes routes: List(MockRoute),
) -> #(client.TelegramClient, Subject(ApiCall)) {
  let default_body = message_response()
  let calls = process.new_subject()
  let fetch_client: FetchClient = fn(req) {
    process.send(calls, ApiCall(request: req))
    case find_matching_route(routes, req) {
      Ok(matched_route) -> matched_route.handler(req)
      Error(_) -> Ok(response.new(200) |> response.set_body(default_body))
    }
  }
  let telegram_client =
    client.new(token: "test_token")
    |> client.set_fetch_client(fetch_client)
  #(telegram_client, calls)
}

fn find_matching_route(
  routes: List(MockRoute),
  req: Request(String),
) -> Result(MockRoute, Nil) {
  list.find(routes, fn(r) { string.contains(req.path, r.path_contains) })
}

// ---------------------------------------------------------------------------
// Stateful mock client
// ---------------------------------------------------------------------------

/// Creates a mock client that passes a 0-based call counter to the handler.
/// Useful for returning different responses based on call order.
pub fn stateful_client(
  handler handler: fn(Request(String), Int) ->
    Result(response.Response(String), TelegaError),
) -> #(client.TelegramClient, Subject(ApiCall)) {
  let calls = process.new_subject()
  let counter = process.new_subject()
  process.send(counter, 0)
  let fetch_client: FetchClient = fn(req) {
    let assert Ok(n) = process.receive(counter, 1000)
    process.send(counter, n + 1)
    process.send(calls, ApiCall(request: req))
    handler(req, n)
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

/// Asserts at least one API call was made to a path containing `path_contains`
/// and whose request body contains `body_contains`.
pub fn assert_called_with_body(
  from subject: Subject(ApiCall),
  path_contains path_contains: String,
  body_contains body_contains: String,
) -> ApiCall {
  let calls = get_calls(from: subject)
  case
    list.find(calls, fn(call) {
      string.contains(call.request.path, path_contains)
      && string.contains(call.request.body, body_contains)
    })
  {
    Ok(call) -> call
    Error(_) ->
      panic as {
        "No API call found with path containing '"
        <> path_contains
        <> "' and body containing '"
        <> body_contains
        <> "'. Calls: "
        <> string.inspect(calls)
      }
  }
}
