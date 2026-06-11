import gleam/erlang/process
import gleam/http/response
import gleam/list
import gleam/option.{None}
import gleeunit
import gleeunit/should

import telega/client
import telega/error
import telega/telemetry

pub fn main() {
  gleeunit.main()
}

type Event {
  Event(
    name: List(String),
    measurements: List(#(String, Int)),
    metadata: List(#(String, telemetry.Value)),
  )
}

fn attach_forwarder(
  id id: String,
  events events: List(List(String)),
) -> process.Subject(Event) {
  let subject = process.new_subject()
  telemetry.attach_many(id:, events:, handler: fn(name, measurements, metadata) {
    process.send(subject, Event(name:, measurements:, metadata:))
  })
  subject
}

fn receive_event(subject: process.Subject(Event)) -> Event {
  let assert Ok(event) = process.receive(subject, 100)
  event
}

pub fn execute_roundtrip_test() {
  let subject =
    attach_forwarder(id: "execute-roundtrip", events: [["test", "event"]])

  telemetry.execute(["test", "event"], [#("count", 42)], [
    #("name", telemetry.StringValue("hello")),
    #("size", telemetry.IntValue(7)),
    #("enabled", telemetry.BoolValue(True)),
  ])

  let event = receive_event(subject)
  event.name |> should.equal(["test", "event"])

  list.key_find(event.measurements, "count") |> should.equal(Ok(42))
  list.key_find(event.metadata, "name")
  |> should.equal(Ok(telemetry.StringValue("hello")))
  list.key_find(event.metadata, "size")
  |> should.equal(Ok(telemetry.IntValue(7)))
  list.key_find(event.metadata, "enabled")
  |> should.equal(Ok(telemetry.BoolValue(True)))

  telemetry.detach("execute-roundtrip")
}

pub fn span_ok_emits_start_and_stop_test() {
  let subject =
    attach_forwarder(id: "span-ok", events: [
      ["test", "span", "start"],
      ["test", "span", "stop"],
      ["test", "span", "exception"],
    ])

  let result =
    telemetry.span(
      event: ["test", "span"],
      metadata: [#("step", telemetry.StringValue("one"))],
      run: fn() { Ok(1) },
    )
  result |> should.equal(Ok(1))

  let started = receive_event(subject)
  started.name |> should.equal(["test", "span", "start"])
  list.key_find(started.measurements, "system_time") |> should.be_ok

  let stopped = receive_event(subject)
  stopped.name |> should.equal(["test", "span", "stop"])
  let assert Ok(duration) = list.key_find(stopped.measurements, "duration")
  { duration >= 0 } |> should.be_true
  list.key_find(stopped.metadata, "step")
  |> should.equal(Ok(telemetry.StringValue("one")))

  telemetry.detach("span-ok")
}

pub fn span_error_emits_exception_test() {
  let subject =
    attach_forwarder(id: "span-error", events: [
      ["test", "span2", "start"],
      ["test", "span2", "stop"],
      ["test", "span2", "exception"],
    ])

  let result =
    telemetry.span(event: ["test", "span2"], metadata: [], run: fn() {
      Error("boom")
    })
  result |> should.equal(Error("boom"))

  let started = receive_event(subject)
  started.name |> should.equal(["test", "span2", "start"])

  let failed = receive_event(subject)
  failed.name |> should.equal(["test", "span2", "exception"])
  list.key_find(failed.metadata, "error")
  |> should.equal(Ok(telemetry.StringValue("\"boom\"")))

  telemetry.detach("span-error")
}

pub fn api_call_emits_start_and_stop_test() {
  let subject =
    attach_forwarder(id: "api-call", events: [
      ["telega", "api_call", "start"],
      ["telega", "api_call", "stop"],
    ])

  let client =
    client.new(token: "test-token", fetch_client: fn(_req) {
      Ok(response.Response(status: 200, headers: [], body: "{\"ok\": true}"))
    })
  let request = client.new_get_request(client, "getMe", None)
  let assert Ok(_) = client.fetch(request, client)

  let started = receive_event(subject)
  started.name |> should.equal(["telega", "api_call", "start"])
  list.key_find(started.metadata, "method")
  |> should.equal(Ok(telemetry.StringValue("getMe")))

  let stopped = receive_event(subject)
  stopped.name |> should.equal(["telega", "api_call", "stop"])
  list.key_find(stopped.metadata, "status")
  |> should.equal(Ok(telemetry.IntValue(200)))
  list.key_find(stopped.measurements, "duration") |> should.be_ok

  telemetry.detach("api-call")
}

pub fn api_call_emits_retry_on_rate_limit_test() {
  let subject =
    attach_forwarder(id: "api-retry", events: [["telega", "api_call", "retry"]])

  let client =
    client.new(token: "test-token", fetch_client: fn(_req) {
      Ok(response.Response(
        status: 429,
        headers: [],
        body: "{\"ok\": false, \"error_code\": 429}",
      ))
    })
    |> client.set_max_retry_attempts(1)
  let request = client.new_get_request(client, "getMe", None)
  let assert Ok(_) = client.fetch(request, client)

  let retried = receive_event(subject)
  retried.name |> should.equal(["telega", "api_call", "retry"])
  list.key_find(retried.metadata, "method")
  |> should.equal(Ok(telemetry.StringValue("getMe")))
  list.key_find(retried.metadata, "attempt")
  |> should.equal(Ok(telemetry.IntValue(1)))
  list.key_find(retried.measurements, "retry_after") |> should.be_ok

  telemetry.detach("api-retry")
}

pub fn api_call_emits_exception_on_error_test() {
  let subject =
    attach_forwarder(id: "api-exception", events: [
      ["telega", "api_call", "exception"],
    ])

  let client =
    client.new(token: "test-token", fetch_client: fn(_req) {
      Error(error.FetchError("network down"))
    })
    |> client.set_max_retry_attempts(0)
  let request = client.new_get_request(client, "getMe", None)
  let assert Error(_) = client.fetch(request, client)

  let failed = receive_event(subject)
  failed.name |> should.equal(["telega", "api_call", "exception"])
  list.key_find(failed.metadata, "method")
  |> should.equal(Ok(telemetry.StringValue("getMe")))
  list.key_find(failed.measurements, "duration") |> should.be_ok

  telemetry.detach("api-exception")
}

pub fn detach_stops_delivery_test() {
  let subject =
    attach_forwarder(id: "detach-test", events: [["test", "detach"]])

  telemetry.execute(["test", "detach"], [#("count", 1)], [])
  let _ = receive_event(subject)

  telemetry.detach("detach-test")
  telemetry.execute(["test", "detach"], [#("count", 2)], [])

  process.receive(subject, 50) |> should.be_error
}
