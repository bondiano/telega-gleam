import gleam/erlang/process.{type Subject}
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import gleeunit
import gleeunit/should

import telega/broadcast
import telega/client
import telega/error

pub fn main() {
  gleeunit.main()
}

fn mock_client() {
  client.new(token: "test-token", fetch_client: mock_fetch_client)
}

fn mock_fetch_client(
  _req: request.Request(String),
) -> Result(response.Response(String), error.TelegaError) {
  Ok(response.Response(
    status: 200,
    headers: [],
    body: "{\"ok\": true, \"result\": {}}",
  ))
}

fn range(from from: Int, to to: Int) -> List(Int) {
  case from > to {
    True -> []
    False -> [from, ..range(from: from + 1, to:)]
  }
}

fn collect(subject: Subject(a), acc: List(a)) -> List(a) {
  case process.receive(subject, 10) {
    Ok(value) -> collect(subject, [value, ..acc])
    Error(_) -> list.reverse(acc)
  }
}

/// Stateful helpers for send functions: closures can't mutate, so state
/// lives in a tiny call-based actor.
type CounterMsg {
  Bump(reply_to: Subject(Int))
}

fn start_counter() -> fn() -> Int {
  let assert Ok(started) =
    actor.new(0)
    |> actor.on_message(fn(count, message) {
      let Bump(reply_to) = message
      process.send(reply_to, count + 1)
      actor.continue(count + 1)
    })
    |> actor.start

  fn() { process.call(started.data, 1000, Bump) }
}

type ChunkMsg {
  NextChunk(reply_to: Subject(option.Option(List(Int))))
}

fn start_chunk_source(
  chunks: List(List(Int)),
) -> fn() -> option.Option(List(Int)) {
  let assert Ok(started) =
    actor.new(chunks)
    |> actor.on_message(fn(chunks, message) {
      let NextChunk(reply_to) = message
      case chunks {
        [] -> {
          process.send(reply_to, None)
          actor.continue([])
        }
        [chunk, ..rest] -> {
          process.send(reply_to, Some(chunk))
          actor.continue(rest)
        }
      }
    })
    |> actor.start

  fn() { process.call(started.data, 1000, NextChunk) }
}

pub fn classification_test() {
  let send = fn(_client, chat_id) {
    case chat_id % 3 {
      0 -> Ok(chat_id * 10)
      1 ->
        Error(error.TelegramApiError(
          403,
          "Forbidden: bot was blocked by the user",
        ))
      _ -> Error(error.TelegramApiError(500, "Internal Server Error"))
    }
  }

  let assert Ok(report) =
    broadcast.new(client: mock_client(), chat_ids: [3, 1, 2, 6, 4, 5], send:)
    |> broadcast.run

  report.sent |> should.equal([#(3, 30), #(6, 60)])
  report.blocked |> should.equal([1, 4])
  report.failed |> list.map(fn(failure) { failure.0 }) |> should.equal([2, 5])
  report.cancelled |> should.be_false()
}

pub fn send_called_once_per_chat_test() {
  let calls = process.new_subject()
  let chat_ids = [1, 2, 3, 4, 5]

  let assert Ok(report) =
    broadcast.new(client: mock_client(), chat_ids:, send: fn(_client, chat_id) {
      process.send(calls, chat_id)
      Ok(Nil)
    })
    |> broadcast.run

  list.length(report.sent) |> should.equal(5)
  collect(calls, []) |> should.equal(chat_ids)
}

pub fn cancel_test() {
  let chat_ids = range(from: 1, to: 50)

  let assert Ok(handle) =
    broadcast.new(client: mock_client(), chat_ids:, send: fn(_client, _chat_id) {
      process.sleep(10)
      Ok(Nil)
    })
    |> broadcast.start

  process.sleep(50)
  broadcast.cancel(handle)

  let assert Ok(report) = broadcast.await(handle, timeout: 1000)
  report.cancelled |> should.be_true()

  let done =
    list.length(report.sent)
    + list.length(report.blocked)
    + list.length(report.failed)
  should.be_true(done > 0)
  should.be_true(done < 50)
}

pub fn progress_monotonic_test() {
  let progresses = process.new_subject()
  let total = 10

  let assert Ok(report) =
    broadcast.new(
      client: mock_client(),
      chat_ids: range(from: 1, to: total),
      send: fn(_client, _chat_id) { Ok(Nil) },
    )
    |> broadcast.with_on_progress(fn(progress) {
      process.send(progresses, progress)
    })
    |> broadcast.run

  let samples = collect(progresses, [])
  samples
  |> list.map(fn(progress) { progress.done })
  |> should.equal(range(from: 1, to: total))
  list.each(samples, fn(progress) { progress.total |> should.equal(Some(10)) })
  list.length(report.sent) |> should.equal(total)
}

pub fn pacing_test() {
  let assert Ok(report) =
    broadcast.new(
      client: mock_client(),
      chat_ids: [1, 2, 3, 4, 5],
      send: fn(_client, _chat_id) { Ok(Nil) },
    )
    |> broadcast.with_rate(rate: 2, window_ms: 100)
    |> broadcast.run

  list.length(report.sent) |> should.equal(5)
  // 5 sends at 2 per 100ms need at least two full window rollovers
  should.be_true(report.duration_ms >= 180)
}

pub fn iterator_source_test() {
  let next_chunk = start_chunk_source([[1, 2], [3], [4, 5, 6]])
  let progresses = process.new_subject()

  let assert Ok(report) =
    broadcast.new_from_iterator(
      client: mock_client(),
      next_chunk:,
      send: fn(_client, chat_id) { Ok(chat_id) },
    )
    |> broadcast.with_on_progress(fn(progress) {
      process.send(progresses, progress)
    })
    |> broadcast.run

  report.sent
  |> should.equal([#(1, 1), #(2, 2), #(3, 3), #(4, 4), #(5, 5), #(6, 6)])
  list.each(collect(progresses, []), fn(progress) {
    progress.total |> should.equal(None)
  })
}

pub fn retry_429_then_success_test() {
  let attempt = start_counter()

  let assert Ok(report) =
    broadcast.new(
      client: mock_client(),
      chat_ids: [1],
      send: fn(_client, _chat_id) {
        case attempt() {
          1 -> Error(error.TelegramApiError(429, "Too Many Requests"))
          _ -> Ok(Nil)
        }
      },
    )
    |> broadcast.with_rate(rate: 25, window_ms: 50)
    |> broadcast.run

  report.sent |> should.equal([#(1, Nil)])
  report.failed |> should.equal([])
}

pub fn retry_429_exhausted_test() {
  let attempt = start_counter()

  let assert Ok(report) =
    broadcast.new(
      client: mock_client(),
      chat_ids: [1, 2],
      send: fn(_client, chat_id) {
        case chat_id {
          1 -> {
            let _ = attempt()
            Error(error.TelegramApiError(429, "Too Many Requests"))
          }
          _ -> Ok(Nil)
        }
      },
    )
    |> broadcast.with_rate(rate: 25, window_ms: 50)
    |> broadcast.run

  report.sent |> should.equal([#(2, Nil)])
  // one initial attempt + exactly one retry
  attempt() |> should.equal(3)
  let assert [#(1, error.TelegramApiError(429, _))] = report.failed
}

pub fn empty_list_test() {
  let assert Ok(report) =
    broadcast.new(
      client: mock_client(),
      chat_ids: [],
      send: fn(_client, _chat_id) { Ok(Nil) },
    )
    |> broadcast.run

  report.sent |> should.equal([])
  report.blocked |> should.equal([])
  report.failed |> should.equal([])
  report.cancelled |> should.be_false()
}
