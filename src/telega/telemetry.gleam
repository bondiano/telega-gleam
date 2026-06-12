//// Telemetry events for production observability.
////
//// Telega emits [`telemetry`](https://hexdocs.pm/telemetry/) events at every
//// key point of the update lifecycle, so standard BEAM exporters (PromEx,
//// `opentelemetry_telemetry`, custom handlers) work out of the box.
//// Emitting an event with no attached handlers is nearly free (a single ETS
//// lookup), so instrumentation costs nothing until you attach a handler.
////
//// ## Event reference
////
//// | Event | Measurements | Metadata |
//// |---|---|---|
//// | `telega.update.start` | `system_time` | `update_type`, `chat_id`, `from_id` |
//// | `telega.update.stop` | `duration` | `update_type`, `chat_id`, `from_id` |
//// | `telega.update.exception` | `duration` | `error`, `update_type`, `chat_id`, `from_id` |
//// | `telega.api_call.start` | `system_time` | `method` |
//// | `telega.api_call.stop` | `duration` | `method`, `status` |
//// | `telega.api_call.exception` | `duration` | `method`, `error` |
//// | `telega.api_call.retry` | `retry_after` (ms) | `method`, `attempt` |
//// | `telega.request_queue.depth` | `depth` | `rule_id`, `priority` |
//// | `telega.rate_limit.hit` | `count` | `update_type`, `chat_id`, `from_id` |
//// | `telega.chat_instance.spawn` | `count` | `chat_id`, `from_id` |
//// | `telega.chat_instance.terminate` | `count` | `key`, `reason` |
//// | `telega.flow.step` | `duration` | `flow_name`, `step` |
//// | `telega.flow.timeout` | `count` | `flow_name`, `step` |
//// | `telega.flow.cancel` | `count` | `flow_name`, `step` |
////
//// - Update and API call events follow the **span convention**
////   (`start`/`stop`/`exception` with a monotonic `duration`), the same
////   pattern used by Phoenix and Ecto.
//// - `duration` and `system_time` are in **native time units** — convert
////   with `native_to_millisecond`.
//// - `telega.update.exception` fires when a handler returns `Error(...)`,
////   before your `catch_handler` runs.
//// - `telega.chat_instance.terminate` fires only for abnormal stops;
////   `reason` tells you which.
//// - `telega.rate_limit.hit` fires for every update rejected by
////   `router.with_rate_limit`.
////
//// ## Attaching a handler
////
//// `attach_many` subscribes one handler (identified by a unique id) to a
//// list of events. The handler receives the event name, measurements, and
//// metadata as lists of pairs:
////
//// ```gleam
//// import gleam/int
//// import gleam/io
//// import gleam/list
//// import telega/telemetry
////
//// pub fn attach_slow_update_logger() {
////   telemetry.attach_many(
////     id: "my-bot-slow-updates",
////     events: [["telega", "update", "stop"]],
////     handler: fn(_event, measurements, metadata) {
////       let assert Ok(duration) = list.key_find(measurements, "duration")
////       let ms = telemetry.native_to_millisecond(duration)
////
////       case ms > 1000 {
////         True -> {
////           let update_type = case list.key_find(metadata, "update_type") {
////             Ok(telemetry.StringValue(t)) -> t
////             _ -> "unknown"
////           }
////           io.println(
////             "slow update: " <> update_type <> " took " <> int.to_string(ms) <> "ms",
////           )
////         }
////         False -> Nil
////       }
////     },
////   )
//// }
//// ```
////
//// Call it once at startup, before `telega.init_for_polling()` /
//// `telega.init()`. Detach with `telemetry.detach("my-bot-slow-updates")`.
////
//// **Handlers run synchronously in the process that emitted the event.**
//// Keep them fast, never call the Telegram API from a handler, and offload
//// anything heavy to another process (see below). A handler that crashes is
//// automatically detached by telemetry.
////
//// ## Forwarding events to a process
////
//// To get events out of the hot path, forward them to a subject and consume
//// them from your own process (an actor, a metrics aggregator, a test
//// assertion):
////
//// ```gleam
//// import gleam/erlang/process
//// import telega/telemetry
////
//// pub type Event {
////   Event(
////     name: List(String),
////     measurements: List(#(String, Int)),
////     metadata: List(#(String, telemetry.Value)),
////   )
//// }
////
//// pub fn attach_forwarder(
////   id id: String,
////   events events: List(List(String)),
//// ) -> process.Subject(Event) {
////   let subject = process.new_subject()
////   telemetry.attach_many(id:, events:, handler: fn(name, measurements, metadata) {
////     process.send(subject, Event(name:, measurements:, metadata:))
////   })
////   subject
//// }
//// ```
////
//// This is also the easiest way to assert on telemetry in tests:
////
//// ```gleam
//// pub fn api_call_emits_stop_test() {
////   let subject =
////     attach_forwarder(id: "test-api-call", events: [
////       ["telega", "api_call", "stop"],
////     ])
////
////   // ... call the bot / client ...
////
////   let assert Ok(Event(name:, ..)) = process.receive(subject, 100)
////   assert name == ["telega", "api_call", "stop"]
////
////   telemetry.detach("test-api-call")
//// }
//// ```
////
//// ## Exporters
////
//// Because events follow the standard telemetry span convention, any BEAM
//// exporter can consume them — attach it to the event names from the table
//// above:
////
//// - **Prometheus**: the [`prometheus`](https://hex.pm/packages/prometheus)
////   Erlang package — register counters/histograms at startup and update
////   them from an `attach_many` handler (convert durations with
////   `native_to_millisecond`).
//// - **Elixir releases**: [`telemetry_metrics`](https://hexdocs.pm/telemetry_metrics/) +
////   [`telemetry_metrics_prometheus`](https://hexdocs.pm/telemetry_metrics_prometheus/),
////   or a custom [PromEx](https://hexdocs.pm/prom_ex/) plugin — declare
////   metrics like `counter("telega.update.stop.duration")`.
//// - **OpenTelemetry**: [`opentelemetry_telemetry`](https://hexdocs.pm/opentelemetry_telemetry/)
////   bridges the `start`/`stop`/`exception` spans into traces.

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/atom.{type Atom}
import gleam/list
import gleam/string

/// Metadata value attached to an event.
pub type Value {
  StringValue(String)
  IntValue(Int)
  FloatValue(Float)
  BoolValue(Bool)
}

/// Handler invoked for each event: event name, measurements, metadata.
pub type EventHandler =
  fn(List(String), List(#(String, Int)), List(#(String, Value))) -> Nil

@external(erlang, "telemetry", "execute")
fn telemetry_execute(
  event: List(Atom),
  measurements: Dict(Atom, Int),
  metadata: Dict(Atom, Dynamic),
) -> Dynamic

@external(erlang, "telemetry", "attach_many")
fn telemetry_attach_many(
  id: String,
  events: List(List(Atom)),
  function: fn(List(Atom), Dict(Atom, Int), Dict(Atom, Dynamic), Nil) -> Nil,
  config: Nil,
) -> Dynamic

@external(erlang, "telemetry", "detach")
fn telemetry_detach(id: String) -> Dynamic

/// Emit a telemetry event.
///
/// ```gleam
/// telemetry.execute(["telega", "update", "start"], [#("system_time", now)], [
///   #("update_type", telemetry.StringValue("text")),
/// ])
/// ```
pub fn execute(
  event event: List(String),
  measurements measurements: List(#(String, Int)),
  metadata metadata: List(#(String, Value)),
) -> Nil {
  let _ =
    telemetry_execute(
      list.map(event, atom.create),
      measurements
        |> list.map(fn(pair) { #(atom.create(pair.0), pair.1) })
        |> dict.from_list,
      metadata
        |> list.map(fn(pair) {
          #(atom.create(pair.0), value_to_dynamic(pair.1))
        })
        |> dict.from_list,
    )
  Nil
}

/// Attach a handler to several events. The `id` must be unique.
///
/// The handler runs synchronously in the process that emitted the event —
/// keep it fast and never call the Telegram API from it. A handler that
/// crashes is detached by telemetry.
pub fn attach_many(
  id id: String,
  events events: List(List(String)),
  handler handler: EventHandler,
) -> Nil {
  let _ =
    telemetry_attach_many(
      id,
      list.map(events, fn(event) { list.map(event, atom.create) }),
      fn(event, measurements, metadata, _config) {
        handler(
          list.map(event, atom.to_string),
          measurements
            |> dict.to_list
            |> list.map(fn(pair) { #(atom.to_string(pair.0), pair.1) }),
          metadata
            |> dict.to_list
            |> list.map(fn(pair) {
              #(atom.to_string(pair.0), dynamic_to_value(pair.1))
            }),
        )
      },
      Nil,
    )
  Nil
}

/// Detach a previously attached handler by its id.
pub fn detach(id id: String) -> Nil {
  let _ = telemetry_detach(id)
  Nil
}

/// Current monotonic time in native units. Use for measuring durations.
@external(erlang, "erlang", "monotonic_time")
pub fn monotonic_time() -> Int

/// Current system time in native units.
@external(erlang, "erlang", "system_time")
pub fn system_time() -> Int

@external(erlang, "erlang", "convert_time_unit")
fn convert_time_unit(time: Int, from: Atom, to: Atom) -> Int

/// Convert a native time unit value (e.g. a `duration` measurement) to milliseconds.
pub fn native_to_millisecond(time time: Int) -> Int {
  convert_time_unit(time, atom.create("native"), atom.create("millisecond"))
}

fn value_to_dynamic(value: Value) -> Dynamic {
  case value {
    StringValue(string) -> dynamic.string(string)
    IntValue(int) -> dynamic.int(int)
    FloatValue(float) -> dynamic.float(float)
    BoolValue(bool) -> dynamic.bool(bool)
  }
}

fn dynamic_to_value(value: Dynamic) -> Value {
  let decoder =
    decode.one_of(decode.map(decode.string, StringValue), or: [
      decode.map(decode.bool, BoolValue),
      decode.map(decode.int, IntValue),
      decode.map(decode.float, FloatValue),
    ])
  case decode.run(value, decoder) {
    Ok(value) -> value
    Error(_) -> StringValue(string.inspect(value))
  }
}

/// Wrap a `Result`-returning function in a `start`/`stop`/`exception` span,
/// following the Phoenix/Ecto span convention:
///
/// - `event + [start]` with `system_time` before the function runs
/// - `event + [stop]` with monotonic `duration` on `Ok`
/// - `event + [exception]` with `duration` and inspected `error` metadata on `Error`
pub fn span(
  event event: List(String),
  metadata metadata: List(#(String, Value)),
  run run: fn() -> Result(a, e),
) -> Result(a, e) {
  let started_at = monotonic_time()
  execute(
    list.append(event, ["start"]),
    [#("system_time", system_time())],
    metadata,
  )

  let result = run()

  let duration = monotonic_time() - started_at
  case result {
    Ok(_) ->
      execute(list.append(event, ["stop"]), [#("duration", duration)], metadata)
    Error(error) ->
      execute(list.append(event, ["exception"]), [#("duration", duration)], [
        #("error", StringValue(string.inspect(error))),
        ..metadata
      ])
  }

  result
}
