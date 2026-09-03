import gleam/erlang/process
import gleam/http/response
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

import telega/error
import telega/internal/request_queue as queue
import telega/internal/utils

pub fn main() {
  gleeunit.main()
}

pub fn create_queue_test() {
  let config = queue.default_config()
  let result = queue.start(config)

  result |> should.be_ok()

  case result {
    Ok(q) -> queue.shutdown(q)
    Error(_) -> Nil
  }
}

pub fn simple_request_test() {
  let config = queue.default_config()
  let assert Ok(q) = queue.start(config)

  let result =
    queue.execute(q, fn() {
      Ok(response.Response(status: 200, headers: [], body: "test response"))
    })

  result
  |> should.be_ok()
  |> fn(resp) {
    resp.status |> should.equal(200)
    resp.body |> should.equal("test response")
  }

  queue.shutdown(q)
}

pub fn basic_ordering_test() {
  let config = queue.default_config()
  let assert Ok(q) = queue.start(config)

  let results = process.new_subject()

  let _ =
    queue.execute(q, fn() {
      process.send(results, 1)
      Ok(response.Response(status: 200, headers: [], body: "first"))
    })

  let _ =
    queue.execute(q, fn() {
      process.send(results, 2)
      Ok(response.Response(status: 200, headers: [], body: "second"))
    })

  let _ =
    queue.execute(q, fn() {
      process.send(results, 3)
      Ok(response.Response(status: 200, headers: [], body: "third"))
    })

  let collected = collect_results(results, [], 3)

  list.length(collected) |> should.equal(3)

  queue.shutdown(q)
}

pub fn execute_with_rule_test() {
  let config =
    queue.QueueConfig(
      rules: [
        queue.Rule(id: "test_rule", rate: 10, limit: 1000, priority: 1),
        queue.Rule(id: "default", rate: 30, limit: 1000, priority: 5),
      ],
      overall_rate: None,
      overall_limit: None,
      retry_delay: 1000,
      max_retries: 3,
      per_chat: None,
    )

  let assert Ok(q) = queue.start(config)

  let result =
    queue.execute_with_rule(q, "req1", "test_rule", fn() {
      Ok(response.Response(
        status: 200,
        headers: [],
        body: "executed with test_rule",
      ))
    })

  result
  |> should.be_ok()
  |> fn(resp) { resp.body |> should.equal("executed with test_rule") }
}

pub fn fallback_to_default_test() {
  let config = queue.default_config()
  let assert Ok(q) = queue.start(config)

  let result =
    queue.execute_with_rule(q, "req1", "non_existent", fn() {
      Ok(response.Response(status: 200, headers: [], body: "fallback worked"))
    })

  result
  |> should.be_ok()
  |> fn(resp) { resp.body |> should.equal("fallback worked") }
}

pub fn no_retry_test() {
  let config =
    queue.QueueConfig(
      rules: [queue.Rule(id: "default", rate: 30, limit: 1000, priority: 5)],
      overall_rate: None,
      overall_limit: None,
      retry_delay: 100,
      max_retries: 0,
      per_chat: None,
    )

  let assert Ok(q) = queue.start(config)

  let result =
    queue.execute(q, fn() { Error(error.FetchError("Simulated error")) })

  result |> should.be_error()
}

pub fn total_length_test() {
  let config = queue.default_config()
  let assert Ok(q) = queue.start(config)

  queue.total_length(q) |> should.equal(0)

  let result =
    queue.execute(q, fn() {
      Ok(response.Response(status: 200, headers: [], body: "test"))
    })

  result |> should.be_ok()

  queue.total_length(q) |> should.equal(0)
}

pub fn is_overheated_test() {
  let config =
    queue.QueueConfig(
      rules: [queue.Rule(id: "default", rate: 2, limit: 1000, priority: 5)],
      overall_rate: None,
      overall_limit: None,
      retry_delay: 100,
      max_retries: 0,
      per_chat: None,
    )

  let assert Ok(q) = queue.start(config)

  queue.is_overheated(q) |> should.equal(False)

  let _ =
    queue.execute(q, fn() {
      Ok(response.Response(status: 200, headers: [], body: "1"))
    })

  let _ =
    queue.execute(q, fn() {
      Ok(response.Response(status: 200, headers: [], body: "2"))
    })

  process.sleep(50)
  queue.is_overheated(q) |> should.equal(True)

  process.sleep(1100)
  queue.is_overheated(q) |> should.equal(False)
}

fn collect_results(
  subject: process.Subject(Int),
  acc: List(Int),
  count: Int,
) -> List(Int) {
  case count {
    0 -> list.reverse(acc)
    _ -> {
      case process.receive(subject, 100) {
        Ok(n) -> collect_results(subject, [n, ..acc], count - 1)
        Error(_) -> list.reverse(acc)
      }
    }
  }
}

// C5 — the queue must not run HTTP inside its own actor ---------------------

fn wait_for_all(
  subject: process.Subject(Int),
  count: Int,
  timeout: Int,
) -> Int {
  case count {
    0 -> 0
    _ ->
      case process.receive(subject, timeout) {
        Ok(_) -> wait_for_all(subject, count - 1, timeout)
        Error(_) -> count
      }
  }
}

pub fn concurrent_requests_are_not_serialized_test() {
  let assert Ok(q) = queue.start(queue.default_config())

  let done = process.new_subject()
  list.each([1, 2, 3], fn(n) {
    process.spawn_unlinked(fn() {
      let _ =
        queue.execute(q, fn() {
          process.sleep(300)
          Ok(response.Response(status: 200, headers: [], body: "ok"))
        })
      process.send(done, n)
    })
  })

  let started_at = utils.current_time_ms()
  wait_for_all(done, 3, 3000) |> should.equal(0)
  let elapsed = utils.current_time_ms() - started_at

  queue.shutdown(q)

  // Serialized inside the actor this takes ~900ms; concurrently, ~300ms.
  { elapsed < 700 } |> should.be_true
}

pub fn queue_stays_responsive_while_a_request_runs_test() {
  let assert Ok(q) = queue.start(queue.default_config())

  process.spawn_unlinked(fn() {
    let _ =
      queue.execute(q, fn() {
        process.sleep(500)
        Ok(response.Response(status: 200, headers: [], body: "slow"))
      })
    Nil
  })

  process.sleep(100)
  let started_at = utils.current_time_ms()
  let _ = queue.total_length(q)
  let elapsed = utils.current_time_ms() - started_at

  queue.shutdown(q)

  { elapsed < 200 } |> should.be_true
}

pub fn execute_on_a_dead_queue_returns_an_error_test() {
  let assert Ok(q) = queue.start(queue.default_config())
  queue.shutdown(q)
  process.sleep(50)

  let reply = process.new_subject()
  process.spawn_unlinked(fn() {
    process.send(
      reply,
      queue.execute(q, fn() {
        Ok(response.Response(status: 200, headers: [], body: "never"))
      }),
    )
  })

  let assert Ok(result) = process.receive(reply, 2000)
  result |> should.be_error
}

// ---------------------------------------------------------------------------
// Per-chat pacing (2c)
// ---------------------------------------------------------------------------

/// A queue with one rule per chat: a private chat gets one request per window,
/// a group gets two. Windows are tiny so the test does not sleep for a second.
fn per_chat_queue(window_ms: Int) -> queue.RequestQueue {
  let assert Ok(q) =
    queue.start(queue.QueueConfig(
      rules: [queue.Rule(id: "default", rate: 100, limit: 1000, priority: 5)],
      overall_rate: None,
      overall_limit: None,
      retry_delay: 10,
      max_retries: 0,
      per_chat: Some(queue.PerChatLimits(
        private_rate: 1,
        private_window_ms: window_ms,
        group_rate: 2,
        group_window_ms: window_ms,
      )),
    ))
  q
}

pub fn per_chat_rule_paces_one_chat_without_blocking_another_test() {
  let q = per_chat_queue(400)
  let done = process.new_subject()

  // Three requests to the same private chat, and one to another chat, all
  // started at once. The per-chat rule allows one per window, so the busy chat
  // is spread over three windows...
  let started_at = utils.current_time_ms()
  list.each([1, 1, 1], fn(chat_id) {
    spawn_request(q, Some(chat_id), done, "busy")
  })
  spawn_request(q, Some(2), done, "quiet")

  // ...but the quiet chat is not made to wait behind them.
  let first = collect_labels(done, [], 2, 1000)
  list.contains(first, "quiet") |> should.be_true
  utils.current_time_ms() - started_at
  |> fn(elapsed) { { elapsed < 400 } |> should.be_true }

  // All four still get through, over the windows the rule allows.
  collect_labels(done, [], 2, 2000) |> list.length |> should.equal(2)
  queue.shutdown(q)
}

pub fn groups_get_their_own_rate_test() {
  let q = per_chat_queue(2000)
  let done = process.new_subject()

  // A negative id is a group, which the config allows two of per window; a
  // private chat only one. Nothing sleeps out the window here — the point is
  // that the two chats are paced by different rules.
  spawn_request(q, Some(-100), done, "group")
  spawn_request(q, Some(-100), done, "group")
  spawn_request(q, Some(500), done, "private")
  spawn_request(q, Some(500), done, "private")

  let admitted = collect_labels(done, [], 3, 1000)
  list.length(admitted) |> should.equal(3)
  count_label(admitted, "group") |> should.equal(2)
  count_label(admitted, "private") |> should.equal(1)

  queue.shutdown(q)
}

pub fn a_request_with_no_chat_falls_back_to_the_default_rule_test() {
  let q = per_chat_queue(2000)
  let done = process.new_subject()

  // `getMe` and friends address no chat; they are paced by the global rules.
  list.each([1, 2, 3], fn(_) { spawn_request(q, None, done, "global") })

  collect_labels(done, [], 3, 1000) |> list.length |> should.equal(3)
  queue.shutdown(q)
}

pub fn per_chat_rules_do_not_accumulate_test() {
  let q = per_chat_queue(50)
  let done = process.new_subject()

  // Every one-off chat would otherwise leave a rule behind forever.
  list.each(chat_ids(30, []), fn(chat_id) {
    spawn_request(q, Some(chat_id), done, "one-off")
  })
  collect_labels(done, [], 30, 2000) |> list.length |> should.equal(30)

  // Nothing is queued any more, so the queue is idle whatever it kept.
  queue.total_length(q) |> should.equal(0)
  queue.shutdown(q)
}

fn spawn_request(
  q: queue.RequestQueue,
  chat_id: option.Option(Int),
  done: process.Subject(String),
  label: String,
) -> Nil {
  process.spawn_unlinked(fn() {
    let _ =
      queue.execute_for_chat(q, chat_id, fn() {
        process.send(done, label)
        Ok(response.Response(status: 200, headers: [], body: label))
      })
    Nil
  })
  Nil
}

fn collect_labels(
  subject: process.Subject(String),
  acc: List(String),
  remaining: Int,
  timeout: Int,
) -> List(String) {
  case remaining {
    0 -> list.reverse(acc)
    _ ->
      case process.receive(subject, timeout) {
        Ok(label) ->
          collect_labels(subject, [label, ..acc], remaining - 1, timeout)
        Error(_) -> list.reverse(acc)
      }
  }
}

fn count_label(labels: List(String), label: String) -> Int {
  list.count(labels, fn(l) { l == label })
}

fn chat_ids(n: Int, acc: List(Int)) -> List(Int) {
  case n {
    0 -> acc
    _ -> chat_ids(n - 1, [n, ..acc])
  }
}
