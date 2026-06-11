# Observability

Telega emits [`telemetry`](https://hexdocs.pm/telemetry/) events at every key point of the update lifecycle. Subscribe to them with `telega/telemetry` — no FFI or extra dependencies needed.

Emitting an event with no attached handlers is nearly free (a single ETS lookup), so instrumentation costs nothing until you attach a handler.

## Event reference

| Event | Measurements | Metadata |
|---|---|---|
| `telega.update.start` | `system_time` | `update_type`, `chat_id`, `from_id` |
| `telega.update.stop` | `duration` | `update_type`, `chat_id`, `from_id` |
| `telega.update.exception` | `duration` | `error`, `update_type`, `chat_id`, `from_id` |
| `telega.api_call.start` | `system_time` | `method` |
| `telega.api_call.stop` | `duration` | `method`, `status` |
| `telega.api_call.exception` | `duration` | `method`, `error` |
| `telega.api_call.retry` | `retry_after` (ms) | `method`, `attempt` |
| `telega.request_queue.depth` | `depth` | `rule_id`, `priority` |
| `telega.chat_instance.spawn` | `count` | `chat_id`, `from_id` |
| `telega.chat_instance.terminate` | `count` | `key`, `reason` |
| `telega.flow.step` | `duration` | `flow_name`, `step` |
| `telega.flow.timeout` | `count` | `flow_name`, `step` |
| `telega.flow.cancel` | `count` | `flow_name`, `step` |

- Update and API call events follow the **span convention** (`start`/`stop`/`exception` with a monotonic `duration`), the same pattern used by Phoenix and Ecto.
- `duration` and `system_time` are in **native time units** — convert with `telemetry.native_to_millisecond`.
- `telega.update.exception` fires when a handler returns `Error(...)`, before your `catch_handler` runs.
- `telega.chat_instance.terminate` fires only for abnormal stops; `reason` tells you which.

## Attaching a handler

`telemetry.attach_many` subscribes one handler (identified by a unique id) to a list of events. The handler receives the event name, measurements, and metadata as lists of pairs:

```gleam
import gleam/int
import gleam/io
import gleam/list
import telega/telemetry

pub fn attach_slow_update_logger() {
  telemetry.attach_many(
    id: "my-bot-slow-updates",
    events: [["telega", "update", "stop"]],
    handler: fn(_event, measurements, metadata) {
      let assert Ok(duration) = list.key_find(measurements, "duration")
      let ms = telemetry.native_to_millisecond(duration)

      case ms > 1000 {
        True -> {
          let update_type = case list.key_find(metadata, "update_type") {
            Ok(telemetry.StringValue(t)) -> t
            _ -> "unknown"
          }
          io.println(
            "slow update: " <> update_type <> " took " <> int.to_string(ms) <> "ms",
          )
        }
        False -> Nil
      }
    },
  )
}
```

Call it once at startup, before `telega.init_for_polling()` / `telega.init()`. Detach with `telemetry.detach("my-bot-slow-updates")`.

**Handlers run synchronously in the process that emitted the event.** Keep them fast, never call the Telegram API from a handler, and offload anything heavy to another process (see below). A handler that crashes is automatically detached by telemetry.

## Forwarding events to a process

To get events out of the hot path, forward them to a subject and consume them from your own process (an actor, a metrics aggregator, a test assertion):

```gleam
import gleam/erlang/process
import telega/telemetry

pub type Event {
  Event(
    name: List(String),
    measurements: List(#(String, Int)),
    metadata: List(#(String, telemetry.Value)),
  )
}

pub fn attach_forwarder(
  id id: String,
  events events: List(List(String)),
) -> process.Subject(Event) {
  let subject = process.new_subject()
  telemetry.attach_many(id:, events:, handler: fn(name, measurements, metadata) {
    process.send(subject, Event(name:, measurements:, metadata:))
  })
  subject
}
```

This is also the easiest way to assert on telemetry in tests:

```gleam
pub fn api_call_emits_stop_test() {
  let subject =
    attach_forwarder(id: "test-api-call", events: [
      ["telega", "api_call", "stop"],
    ])

  // ... call the bot / client ...

  let assert Ok(Event(name:, ..)) = process.receive(subject, 100)
  assert name == ["telega", "api_call", "stop"]

  telemetry.detach("test-api-call")
}
```

## Exporters

Because events follow the standard telemetry span convention, any BEAM exporter can consume them — attach it to the event names from the table above:

- **Prometheus**: the [`prometheus`](https://hex.pm/packages/prometheus) Erlang package — register counters/histograms at startup and update them from an `attach_many` handler (convert durations with `native_to_millisecond`).
- **Elixir releases**: [`telemetry_metrics`](https://hexdocs.pm/telemetry_metrics/) + [`telemetry_metrics_prometheus`](https://hexdocs.pm/telemetry_metrics_prometheus/), or a custom [PromEx](https://hexdocs.pm/prom_ex/) plugin — declare metrics like `counter("telega.update.stop.duration")`.
- **OpenTelemetry**: [`opentelemetry_telemetry`](https://hexdocs.pm/opentelemetry_telemetry/) bridges the `start`/`stop`/`exception` spans into traces.
