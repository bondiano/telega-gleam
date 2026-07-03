import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot
import telega/client
import telega/error
import telega/format
import telega/reply
import telega/testing/context as testing_context
import telega/testing/mock

pub fn main() {
  gleeunit.main()
}

pub fn new_client_test() {
  let token = "test-token"
  let client = client.new(token:, fetch_client: mock_success_fetch_client)

  client.get_api_url(client)
  |> should.equal("https://api.telegram.org/bot")
}

pub fn set_tg_api_url_test() {
  let client =
    client.new(token: "token", fetch_client: mock_success_fetch_client)
    |> client.set_tg_api_url("https://custom.api.url/bot")

  client.get_api_url(client)
  |> should.equal("https://custom.api.url/bot")
}

fn mock_success_fetch_client(
  _req: request.Request(String),
) -> Result(response.Response(String), error.TelegaError) {
  Ok(response.Response(
    status: 200,
    headers: [],
    body: "{\"ok\": true, \"result\": {}}",
  ))
}

fn mock_rate_limit_fetch_client(
  _req: request.Request(String),
) -> Result(response.Response(String), error.TelegaError) {
  Ok(response.Response(
    status: 429,
    headers: [],
    body: "{\"ok\": false, \"error_code\": 429, \"description\": \"Too Many Requests\", \"parameters\": {\"retry_after\": 5}}",
  ))
}

fn mock_error_fetch_client(
  _req: request.Request(String),
) -> Result(response.Response(String), error.TelegaError) {
  Error(error.FetchError("Network error"))
}

pub fn fetch_with_success_test() {
  let client =
    client.new(token: "test-token", fetch_client: mock_success_fetch_client)

  let request = client.new_get_request(client, "getMe", None)

  let result = client.fetch(request, client)

  result
  |> should.be_ok()
  |> fn(response) {
    response.status
    |> should.equal(200)
  }
}

pub fn fetch_with_rate_limit_test() {
  let client =
    client.new(token: "test-token", fetch_client: mock_rate_limit_fetch_client)
    |> client.set_max_retry_attempts(1)

  let request = client.new_get_request(client, "getMe", None)

  let result = client.fetch(request, client)

  result
  |> should.be_ok()
  |> fn(response) {
    response.status
    |> should.equal(429)
  }
}

pub fn fetch_with_network_error_test() {
  let client =
    client.new(token: "test-token", fetch_client: mock_error_fetch_client)
    |> client.set_max_retry_attempts(2)

  let request = client.new_get_request(client, "getMe", None)

  let result = client.fetch(request, client)

  result
  |> should.be_error()
}

pub fn rate_limiting_behavior_test() {
  let request_count = process.new_subject()

  let counting_fetch_client = fn(_req: request.Request(String)) {
    process.send(request_count, 1)
    Ok(response.Response(status: 200, headers: [], body: "{\"ok\": true}"))
  }

  let client =
    client.new(token: "test-token", fetch_client: counting_fetch_client)

  let request = client.new_get_request(client, "getMe", None)

  let _ = client.fetch(request, client)
  let _ = client.fetch(request, client)
  let _ = client.fetch(request, client)

  let count = count_messages(request_count, 0)
  count |> should.equal(3)
}

pub fn adaptive_rate_limiting_test() {
  let state = process.new_subject()
  process.send(state, 0)

  let adaptive_fetch_client = fn(_req: request.Request(String)) {
    let count = case process.receive(state, 10) {
      Ok(n) -> n + 1
      Error(_) -> 1
    }
    process.send(state, count)

    case count {
      2 -> {
        Ok(response.Response(
          status: 429,
          headers: [],
          body: "{\"ok\": false, \"error_code\": 429}",
        ))
      }
      _ -> {
        Ok(response.Response(status: 200, headers: [], body: "{\"ok\": true}"))
      }
    }
  }

  let client =
    client.new(token: "test-token", fetch_client: adaptive_fetch_client)
    |> client.set_max_retry_attempts(0)

  let request = client.new_get_request(client, "getMe", None)

  let result1 = client.fetch(request, client)
  result1
  |> should.be_ok()
  |> fn(r) { r.status |> should.equal(200) }

  let result2 = client.fetch(request, client)
  result2
  |> should.be_ok()
  |> fn(r) { r.status |> should.equal(429) }
}

pub fn retry_on_error_test() {
  let state = process.new_subject()
  process.send(state, 0)

  let failing_then_success_client = fn(_req: request.Request(String)) {
    let count = case process.receive(state, 10) {
      Ok(n) -> n + 1
      Error(_) -> 1
    }
    process.send(state, count)

    case count {
      c if c <= 2 -> {
        Error(error.FetchError("Network error"))
      }
      _ -> {
        Ok(response.Response(status: 200, headers: [], body: "{\"ok\": true}"))
      }
    }
  }

  let client =
    client.new(token: "test-token", fetch_client: failing_then_success_client)
    |> client.set_max_retry_attempts(3)

  let request = client.new_get_request(client, "getMe", None)

  let result = client.fetch(request, client)
  result |> should.be_ok()
}

fn count_messages(subject: process.Subject(Int), acc: Int) -> Int {
  case process.receive(subject, 0) {
    Ok(_) -> count_messages(subject, acc + 1)
    Error(_) -> acc
  }
}

// ---------------------------------------------------------------------------
// Transformers
// ---------------------------------------------------------------------------

pub fn transformer_order_test() {
  let bodies = process.new_subject()
  let capture_fetch_client = fn(req: request.Request(String)) {
    process.send(bodies, req.body)
    Ok(response.Response(status: 200, headers: [], body: "{\"ok\":true}"))
  }

  let tg_client =
    client.new(token: "test-token", fetch_client: capture_fetch_client)
    |> client.use_transformer(fn(req, next) {
      next(client.map_request_body(req, fn(body) { body <> ":first" }))
    })
    |> client.use_transformer(fn(req, next) {
      next(client.map_request_body(req, fn(body) { body <> ":second" }))
    })

  let request = client.new_post_request(tg_client, "sendMessage", "{}")
  let assert Ok(_) = client.fetch(request, tg_client)

  let assert Ok(body) = process.receive(bodies, 100)
  body |> should.equal("{}:first:second")
}

pub fn transformer_short_circuit_test() {
  let calls = process.new_subject()
  let counting_fetch_client = fn(_req: request.Request(String)) {
    process.send(calls, 1)
    Ok(response.Response(status: 200, headers: [], body: "{\"ok\":true}"))
  }

  let tg_client =
    client.new(token: "test-token", fetch_client: counting_fetch_client)
    |> client.use_transformer(fn(_req, _next) {
      Ok(response.Response(status: 200, headers: [], body: "short-circuited"))
    })

  let request = client.new_post_request(tg_client, "sendMessage", "{}")
  let assert Ok(response) = client.fetch(request, tg_client)

  response.body |> should.equal("short-circuited")
  count_messages(calls, 0) |> should.equal(0)
}

pub fn request_accessors_test() {
  let tg_client =
    client.new(token: "test-token", fetch_client: mock_success_fetch_client)

  let post = client.new_post_request(tg_client, "sendMessage", "{\"a\":1}")
  client.request_method(post) |> should.equal("sendMessage")
  client.request_body(post) |> should.equal(Some("{\"a\":1}"))

  let mapped = client.map_request_body(post, fn(body) { body <> "!" })
  client.request_body(mapped) |> should.equal(Some("{\"a\":1}!"))

  let get = client.new_get_request(tg_client, "getMe", None)
  client.request_method(get) |> should.equal("getMe")
  client.request_body(get) |> should.equal(None)
  client.map_request_body(get, fn(body) { body <> "!" })
  |> client.request_body()
  |> should.equal(None)
}

// ---------------------------------------------------------------------------
// 429 retry_after
// ---------------------------------------------------------------------------

pub fn retry_after_from_response_test() {
  let state = process.new_subject()
  process.send(state, 0)

  let rate_limited_then_success_client = fn(_req: request.Request(String)) {
    let count = case process.receive(state, 10) {
      Ok(n) -> n + 1
      Error(_) -> 1
    }
    process.send(state, count)

    case count {
      1 ->
        Ok(response.Response(
          status: 429,
          headers: [],
          body: "{\"ok\": false, \"error_code\": 429, \"parameters\": {\"retry_after\": 0}}",
        ))
      _ ->
        Ok(response.Response(status: 200, headers: [], body: "{\"ok\": true}"))
    }
  }

  let tg_client =
    client.new(
      token: "test-token",
      fetch_client: rate_limited_then_success_client,
    )
    |> client.set_max_retry_attempts(3)

  let request = client.new_get_request(tg_client, "getMe", None)

  // retry_after: 0 means the retry happens without the default 1s sleep
  let assert Ok(response) = client.fetch(request, tg_client)
  response.status |> should.equal(200)
}

// ---------------------------------------------------------------------------
// Default parse_mode
// ---------------------------------------------------------------------------

fn context_with_client(
  tg_client: client.TelegramClient,
) -> bot.Context(Nil, error.TelegaError, Nil) {
  let ctx = testing_context.context(session: Nil)
  bot.Context(..ctx, config: testing_context.config_with_client(tg_client))
}

pub fn default_parse_mode_applied_test() {
  let #(tg_client, calls) = mock.message_client()
  let tg_client = client.set_default_parse_mode(tg_client, format.HTML)

  let _ = reply.with_text(context_with_client(tg_client), "hello")

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendMessage",
      body_contains: "\"parse_mode\":\"HTML\"",
    )
  Nil
}

pub fn no_default_parse_mode_test() {
  let #(tg_client, calls) = mock.message_client()

  let _ = reply.with_text(context_with_client(tg_client), "hello")

  let assert [call] = mock.get_calls(from: calls)
  string.contains(call.request.body, "parse_mode")
  |> should.be_false()
}
