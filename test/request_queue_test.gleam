import gleam/erlang/process
import gleam/http/response
import gleam/list
import gleam/option.{None}
import gleeunit
import gleeunit/should

import telega/error
import telega/internal/request_queue as queue

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
