import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot
import telega/client
import telega/error
import telega/format
import telega/reply
import telega/telemetry
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

// ---------------------------------------------------------------------------
// C5 — the request queue must share the 429 retry path
// ---------------------------------------------------------------------------

type CounterMessage {
  NextCount(reply: process.Subject(Int))
}

/// A call counter that works from any process, unlike a bare `Subject`
/// mailbox — queued requests run in their own process.
fn start_counter() -> process.Subject(CounterMessage) {
  let assert Ok(started) =
    actor.new(0)
    |> actor.on_message(fn(count, message) {
      let NextCount(reply:) = message
      process.send(reply, count + 1)
      actor.continue(count + 1)
    })
    |> actor.start
  started.data
}

pub fn queued_request_retries_on_429_test() {
  let counter = start_counter()

  let rate_limited_then_success_client = fn(_req: request.Request(String)) {
    case process.call(counter, 1000, NextCount) {
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

  let assert Ok(tg_client) =
    client.new(
      token: "test-token",
      fetch_client: rate_limited_then_success_client,
    )
    |> client.set_max_retry_attempts(3)
    |> client.set_request_queue(client.default_request_queue_config())

  let request = client.new_get_request(tg_client, "getMe", None)

  let assert Ok(response) = client.fetch(request, tg_client)
  response.status |> should.equal(200)

  client.shutdown(tg_client)
}

// ---------------------------------------------------------------------------
// M2 — retries must not duplicate non-idempotent calls
// ---------------------------------------------------------------------------

/// The default policy sleeps a second between attempts; these tests only care
/// about how many attempts there are, so they wait a millisecond instead.
fn fast_retries(
  client: client.TelegramClient,
  attempts: Int,
) -> client.TelegramClient {
  client
  |> client.set_retry_policy(
    client.RetryPolicy(
      ..client.default_retry_policy(),
      max_attempts: attempts,
      base_delay_ms: 1,
      jitter: False,
    ),
  )
}

/// A fetch client that counts its calls and always fails the way `how` says.
fn counting_fetch_client(
  calls: process.Subject(Int),
  how: fn() -> Result(response.Response(String), error.TelegaError),
) {
  fn(_req: request.Request(String)) {
    process.send(calls, 1)
    how()
  }
}

pub fn transport_error_is_not_retried_for_send_message_test() {
  let calls = process.new_subject()
  let client =
    client.new(
      token: "test-token",
      fetch_client: counting_fetch_client(calls, fn() {
        Error(error.FetchError("connection closed"))
      }),
    )
    |> fast_retries(4)

  client.new_post_request(client, "sendMessage", "{}")
  |> client.fetch(client)
  |> should.be_error()

  // Replaying a `sendMessage` whose response was merely lost would post the
  // message twice.
  count_messages(calls, 0) |> should.equal(1)
}

pub fn transport_error_is_retried_for_idempotent_method_test() {
  let calls = process.new_subject()
  let client =
    client.new(
      token: "test-token",
      fetch_client: counting_fetch_client(calls, fn() {
        Error(error.FetchError("connection closed"))
      }),
    )
    |> fast_retries(3)

  client.new_post_request(client, "deleteMessage", "{}")
  |> client.fetch(client)
  |> should.be_error()

  count_messages(calls, 0) |> should.equal(3)
}

pub fn server_error_is_retried_for_idempotent_method_test() {
  let calls = process.new_subject()
  let client =
    client.new(
      token: "test-token",
      fetch_client: counting_fetch_client(calls, fn() {
        Ok(response.Response(status: 502, headers: [], body: "bad gateway"))
      }),
    )
    |> fast_retries(3)

  client.new_get_request(client, "getMe", None)
  |> client.fetch(client)
  |> should.be_ok()

  count_messages(calls, 0) |> should.equal(3)
}

pub fn server_error_is_not_retried_for_send_message_test() {
  let calls = process.new_subject()
  let client =
    client.new(
      token: "test-token",
      fetch_client: counting_fetch_client(calls, fn() {
        Ok(response.Response(status: 502, headers: [], body: "bad gateway"))
      }),
    )
    |> fast_retries(4)

  client.new_post_request(client, "sendMessage", "{}")
  |> client.fetch(client)
  |> should.be_ok()

  count_messages(calls, 0) |> should.equal(1)
}

pub fn long_retry_after_is_not_slept_off_test() {
  let calls = process.new_subject()
  let client =
    client.new(
      token: "test-token",
      fetch_client: counting_fetch_client(calls, fn() {
        Ok(response.Response(
          status: 429,
          headers: [],
          body: "{\"ok\": false, \"error_code\": 429, \"parameters\": {\"retry_after\": 3600}}",
        ))
      }),
    )
    |> fast_retries(4)
    |> client.set_max_retry_delay(50)

  // An hour-long `process.sleep` would block the calling chat instance, so the
  // 429 comes back to the caller instead.
  client.new_post_request(client, "sendMessage", "{}")
  |> client.fetch(client)
  |> should.be_ok()
  |> fn(r: response.Response(String)) { r.status |> should.equal(429) }

  count_messages(calls, 0) |> should.equal(1)
}

// ---------------------------------------------------------------------------
// Retry policy as configuration (2d)
// ---------------------------------------------------------------------------

pub fn retry_on_transport_errors_never_test() {
  let calls = process.new_subject()
  let client =
    client.new(
      token: "test-token",
      fetch_client: counting_fetch_client(calls, fn() {
        Error(error.FetchError("connection closed"))
      }),
    )
    |> fast_retries(5)
    |> client.set_retry_policy(
      client.RetryPolicy(
        ..client.get_retry_policy(client.new(
          token: "",
          fetch_client: mock_success_fetch_client,
        )),
        max_attempts: 5,
        base_delay_ms: 1,
        jitter: False,
        retry_on_transport_errors: client.Never,
      ),
    )

  // `deleteMessage` is idempotent, so only the policy stops the retrying.
  client.new_post_request(client, "deleteMessage", "{}")
  |> client.fetch(client)
  |> should.be_error()

  count_messages(calls, 0) |> should.equal(1)
}

pub fn retry_on_transport_errors_always_replays_a_send_test() {
  let calls = process.new_subject()
  let client =
    client.new(
      token: "test-token",
      fetch_client: counting_fetch_client(calls, fn() {
        Error(error.FetchError("connection closed"))
      }),
    )
    |> client.set_retry_policy(
      client.RetryPolicy(
        ..client.default_retry_policy(),
        max_attempts: 3,
        base_delay_ms: 1,
        jitter: False,
        retry_on_transport_errors: client.Always,
      ),
    )

  // A caller that deduplicates on its own can ask for this; the default would
  // hand `sendMessage` back after the first failure.
  client.new_post_request(client, "sendMessage", "{}")
  |> client.fetch(client)
  |> should.be_error()

  count_messages(calls, 0) |> should.equal(3)
}

pub fn retry_on_server_errors_is_configured_separately_test() {
  let calls = process.new_subject()
  let client =
    client.new(
      token: "test-token",
      fetch_client: counting_fetch_client(calls, fn() {
        Ok(response.Response(status: 503, headers: [], body: "unavailable"))
      }),
    )
    |> client.set_retry_policy(
      client.RetryPolicy(
        ..client.default_retry_policy(),
        max_attempts: 4,
        base_delay_ms: 1,
        jitter: False,
        retry_on_server_errors: client.Never,
        retry_on_transport_errors: client.Always,
      ),
    )

  client.new_get_request(client, "getMe", None)
  |> client.fetch(client)
  |> should.be_ok()

  count_messages(calls, 0) |> should.equal(1)
}

pub fn max_attempts_counts_the_first_attempt_test() {
  let calls = process.new_subject()
  let client =
    client.new(
      token: "test-token",
      fetch_client: counting_fetch_client(calls, fn() {
        Error(error.FetchError("connection closed"))
      }),
    )
    |> fast_retries(1)

  client.new_get_request(client, "getMe", None)
  |> client.fetch(client)
  |> should.be_error()

  count_messages(calls, 0) |> should.equal(1)
}

pub fn set_max_retry_attempts_is_a_shorthand_for_max_attempts_test() {
  let client =
    client.new(token: "t", fetch_client: mock_success_fetch_client)
    |> client.set_max_retry_attempts(0)

  // Zero *retries* is one attempt.
  client.get_retry_policy(client).max_attempts |> should.equal(1)

  let client = client |> client.set_max_retry_attempts(3)
  client.get_retry_policy(client).max_attempts |> should.equal(4)
}

pub fn backoff_grows_and_is_capped_test() {
  let delays = process.new_subject()
  let started = telemetry_start(delays)

  let client =
    client.new(token: "test-token", fetch_client: fn(_req) {
      Ok(response.Response(status: 502, headers: [], body: "bad gateway"))
    })
    |> client.set_retry_policy(
      client.RetryPolicy(
        ..client.default_retry_policy(),
        max_attempts: 5,
        base_delay_ms: 2,
        max_delay_ms: 8,
        jitter: False,
      ),
    )

  client.new_get_request(client, "getMe", None)
  |> client.fetch(client)
  |> should.be_ok()

  // 2, 4, 8, then capped at 8 rather than 16.
  drain_ints(delays, []) |> should.equal([2, 4, 8, 8])
  telemetry.detach(started)
}

pub fn jitter_keeps_the_delay_in_the_upper_half_of_the_window_test() {
  let delays = process.new_subject()
  let started = telemetry_start(delays)

  let client =
    client.new(token: "test-token", fetch_client: fn(_req) {
      Ok(response.Response(status: 502, headers: [], body: "bad gateway"))
    })
    |> client.set_retry_policy(
      client.RetryPolicy(
        ..client.default_retry_policy(),
        max_attempts: 6,
        base_delay_ms: 8,
        max_delay_ms: 8,
        jitter: True,
      ),
    )

  client.new_get_request(client, "getMe", None)
  |> client.fetch(client)
  |> should.be_ok()

  // Every delay lands in [4, 8]; a fleet coming back from the same outage
  // spreads over the window instead of hitting the API in lockstep.
  let observed = drain_ints(delays, [])
  list.length(observed) |> should.equal(5)
  list.all(observed, fn(d) { d >= 4 && d <= 8 }) |> should.be_true
  telemetry.detach(started)
}

/// Listen for the delay the client reports on each `telega.api_call.retry`.
fn telemetry_start(into: process.Subject(Int)) -> String {
  let id = "client-retry-" <> int.to_string(int.random(1_000_000))
  telemetry.attach_many(
    id: id,
    events: [["telega", "api_call", "retry"]],
    handler: fn(_event, measurements, _metadata) {
      case list.key_find(measurements, "retry_after") {
        Ok(delay) -> process.send(into, delay)
        Error(Nil) -> Nil
      }
    },
  )
  id
}

fn drain_ints(subject: process.Subject(Int), acc: List(Int)) -> List(Int) {
  case process.receive(subject, 0) {
    Ok(value) -> drain_ints(subject, [value, ..acc])
    Error(_) -> list.reverse(acc)
  }
}

// ---------------------------------------------------------------------------
// getUpdates has its own lane (2c)
// ---------------------------------------------------------------------------

pub fn get_updates_does_not_go_through_the_queue_test() {
  let calls = process.new_subject()
  let assert Ok(tg_client) =
    client.new(
      token: "test-token",
      fetch_client: counting_fetch_client(calls, fn() {
        Ok(response.Response(status: 200, headers: [], body: "{\"ok\": true}"))
      }),
    )
    |> client.set_request_queue(
      // A queue that admits nothing: anything routed through it would block
      // until the call times out.
      client.RequestQueueConfig(
        ..client.default_request_queue_config(),
        rules: [
          client.RequestQueueRule(
            id: "default",
            rate: 0,
            limit: 60_000,
            priority: 5,
          ),
        ],
        per_chat: None,
      ),
    )

  // A long poll must never wait behind the bot's own replies, nor spend one of
  // the queue's concurrency slots for the whole polling timeout.
  client.new_get_request(tg_client, "getUpdates", None)
  |> client.fetch(tg_client)
  |> should.be_ok()

  count_messages(calls, 0) |> should.equal(1)
  client.shutdown(tg_client)
}
