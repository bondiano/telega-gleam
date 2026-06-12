//// Production observability via `telega/telemetry`.
////
//// Telega emits telemetry events at every key point of the update lifecycle
//// (see the `telega/telemetry` module docs for the full event reference).
//// This module attaches a single handler that turns the most useful ones
//// into log lines:
////
//// - slow updates (handler took longer than the threshold)
//// - handler errors (`telega.update.exception`)
//// - Telegram API rate-limit retries (`telega.api_call.retry`)
//// - flow steps, timeouts and cancellations
//// - the example's own database spans (`restaurant_booking.db.*`,
////   emitted with `telemetry.span` in `handlers.gleam`)
////
//// The same events can feed Prometheus / OpenTelemetry exporters instead of
//// logs — the handler is the only thing to swap.

import gleam/int
import gleam/list

import telega/telemetry

import restaurant_booking/util

const handler_id = "restaurant-booking-observability"

const slow_update_threshold_ms = 1000

/// Attach the telemetry handler. Call once at startup, before the bot is
/// initialized. Handlers run synchronously in the emitting process, so they
/// only log — anything heavier should be forwarded to a separate process.
pub fn attach() -> Nil {
  telemetry.attach_many(
    id: handler_id,
    events: [
      ["telega", "update", "stop"],
      ["telega", "update", "exception"],
      ["telega", "api_call", "retry"],
      ["telega", "flow", "step"],
      ["telega", "flow", "timeout"],
      ["telega", "flow", "cancel"],
      ["restaurant_booking", "db", "stop"],
      ["restaurant_booking", "db", "exception"],
    ],
    handler: handle_event,
  )
}

/// Detach the handler (useful in tests).
pub fn detach() -> Nil {
  telemetry.detach(handler_id)
}

fn handle_event(
  event: List(String),
  measurements: List(#(String, Int)),
  metadata: List(#(String, telemetry.Value)),
) -> Nil {
  case event {
    ["telega", "update", "stop"] -> {
      let ms = duration_ms(measurements)
      case ms > slow_update_threshold_ms {
        True ->
          util.log_warning(
            "Slow update: "
            <> metadata_string(metadata, "update_type")
            <> " took "
            <> int.to_string(ms)
            <> "ms",
          )
        False -> Nil
      }
    }

    ["telega", "update", "exception"] ->
      util.log_error(
        "Update failed: "
        <> metadata_string(metadata, "update_type")
        <> " after "
        <> int.to_string(duration_ms(measurements))
        <> "ms: "
        <> metadata_string(metadata, "error"),
      )

    ["telega", "api_call", "retry"] ->
      util.log_warning(
        "Telegram API rate limited: retrying "
        <> metadata_string(metadata, "method"),
      )

    ["telega", "flow", "step"] ->
      util.log_debug(
        "Flow "
        <> metadata_string(metadata, "flow_name")
        <> " step "
        <> metadata_string(metadata, "step")
        <> " took "
        <> int.to_string(duration_ms(measurements))
        <> "ms",
      )

    ["telega", "flow", "timeout"] ->
      util.log_warning(
        "Flow "
        <> metadata_string(metadata, "flow_name")
        <> " timed out at step "
        <> metadata_string(metadata, "step"),
      )

    ["telega", "flow", "cancel"] ->
      util.log(
        "Flow "
        <> metadata_string(metadata, "flow_name")
        <> " cancelled at step "
        <> metadata_string(metadata, "step"),
      )

    ["restaurant_booking", "db", "stop"] ->
      util.log_debug(
        "DB query "
        <> metadata_string(metadata, "query")
        <> " took "
        <> int.to_string(duration_ms(measurements))
        <> "ms",
      )

    ["restaurant_booking", "db", "exception"] ->
      util.log_error(
        "DB query "
        <> metadata_string(metadata, "query")
        <> " failed: "
        <> metadata_string(metadata, "error"),
      )

    _ -> Nil
  }
}

fn duration_ms(measurements: List(#(String, Int))) -> Int {
  case list.key_find(measurements, "duration") {
    Ok(duration) -> telemetry.native_to_millisecond(duration)
    Error(_) -> 0
  }
}

fn metadata_string(
  metadata: List(#(String, telemetry.Value)),
  key: String,
) -> String {
  case list.key_find(metadata, key) {
    Ok(telemetry.StringValue(value)) -> value
    Ok(telemetry.IntValue(value)) -> int.to_string(value)
    Ok(telemetry.FloatValue(_)) | Ok(telemetry.BoolValue(_)) | Error(_) ->
      "unknown"
  }
}
