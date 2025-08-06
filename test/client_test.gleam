import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/option.{None}
import gleeunit
import gleeunit/should

import telega/client
import telega/error

pub fn main() {
  gleeunit.main()
}

pub fn new_client_test() {
  let token = "test-token"
  let client = client.new(token)

  client.get_api_url(client)
  |> should.equal("https://api.telegram.org/bot")
}

pub fn set_tg_api_url_test() {
  let client =
    client.new("token")
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
    client.new("test-token")
    |> client.set_fetch_client(mock_success_fetch_client)

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
    client.new("test-token")
    |> client.set_fetch_client(mock_rate_limit_fetch_client)
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
    client.new("test-token")
    |> client.set_fetch_client(mock_error_fetch_client)
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
    client.new("test-token")
    |> client.set_fetch_client(counting_fetch_client)

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
    client.new("test-token")
    |> client.set_fetch_client(adaptive_fetch_client)
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
    client.new("test-token")
    |> client.set_fetch_client(failing_then_success_client)
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
