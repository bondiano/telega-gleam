//// A webhook bot with the four things a webhook needs in production that long
//// polling gives you for free:
////
////   1. a health endpoint a load balancer can probe (`handle_health`),
////   2. deduplication of the updates Telegram redelivers (`telega/idempotency`),
////   3. an overload cap, so a bot that is behind says `503` instead of piling
////      up work (`with_max_in_flight`),
////   4. a graceful drain on SIGTERM, so a deploy finishes what it started
////      (`with_signal_handlers` + `with_drain_timeout`).
////
//// Everything else is an ordinary bot.

import envoy
import gleam/erlang/process
import gleam/int
import gleam/option.{Some}
import gleam/result
import mist
import wisp
import wisp/wisp_mist

import telega
import telega/error as telega_error
import telega/idempotency
import telega/reply
import telega/router
import telega/storage
import telega/storage/ets
import telega_httpc
import telega_wisp

/// Telegram gives up redelivering an update long before this; an hour of ids
/// is a comfortable window that costs a few kilobytes.
const dedup_ttl_ms = 3_600_000

/// A crashed chat instance's update is kept for a week so it can be replayed.
const dead_letter_retention_ms = 604_800_000

/// Updates in flight above which the webhook endpoint answers `503` and
/// Telegram backs off. Pick it from what your bot can actually keep up with.
const max_in_flight = 500

/// How long `shutdown` waits for in-flight updates on SIGTERM.
const drain_timeout_ms = 10_000

// --- Handlers ---------------------------------------------------------------

fn start_handler(ctx, _command) {
  use ctx <- telega.log_context(ctx, "start")
  reply.text(ctx, "Hi! I run behind a webhook. Try /ping, or send me any text.")
}

fn ping_handler(ctx, _command) {
  use ctx <- telega.log_context(ctx, "ping")
  reply.text(ctx, "pong")
}

fn echo_handler(ctx, text) {
  use ctx <- telega.log_context(ctx, "echo")
  reply.text(ctx, text)
}

pub fn build_router() -> router.Router(Nil, telega_error.TelegaError, Nil) {
  router.new("webhook_bot")
  |> router.on_command_with_description(
    "start",
    "Show the welcome message",
    start_handler,
  )
  |> router.on_command_with_description(
    "ping",
    "Check the bot is up",
    ping_handler,
  )
  |> router.on_any_text(echo_handler)
}

// --- HTTP -------------------------------------------------------------------

/// Order matters: the health probe must be answered even while the bot is
/// draining, and the webhook path must be claimed before your own routes.
fn handle_request(bot, req) {
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use <- telega_wisp.handle_health(
    telega: bot,
    req:,
    path: telega_wisp.default_health_path,
  )
  use <- telega_wisp.handle_bot(telega: bot, req:)

  wisp.not_found()
}

// --- Wiring -----------------------------------------------------------------

fn build_bot() {
  let assert Ok(token) = envoy.get("BOT_TOKEN")
  let assert Ok(url) = envoy.get("SERVER_URL")
  let webhook_path = envoy.get("WEBHOOK_PATH") |> result.unwrap("webhook")
  let secret_token = envoy.get("BOT_SECRET_TOKEN") |> option.from_result

  // One in-memory store for both concerns. It is per-node and dies with the
  // VM: fine for a single instance, but run several and you want a shared
  // backend (`telega_storage_redis`, `telega_storage_postgres`) so a
  // redelivery that lands on another node is still recognised as a duplicate.
  let assert Ok(store) = ets.new(name: "webhook_bot_store")

  telega.new(telega_httpc.new(token))
  |> telega.webhook(url:, path: webhook_path, secret_token:)
  // Runs in the bot actor before routing: an update_id seen in the last hour
  // never reaches a handler twice.
  |> telega.use_pre_handler(idempotency.deduplicate(
    storage: store,
    ttl_ms: dedup_ttl_ms,
  ))
  |> telega.router(build_router())
  |> telega.with_auto_commands()
  |> telega.with_auto_allowed_updates()
  |> telega.with_max_in_flight(max_in_flight)
  |> telega.with_dead_letters(storage.dead_letters_from_storage(
    storage: store,
    retention_ms: Some(dead_letter_retention_ms),
  ))
  |> telega.with_drain_timeout(drain_timeout_ms)
  // SIGTERM (what fly.io/Kubernetes send on a deploy) drains and exits.
  |> telega.with_signal_handlers()
  |> telega.start()
}

pub fn main() {
  wisp.configure_logger()

  let assert Ok(bot) = build_bot()
  let port = envoy.get("PORT") |> result.try(int.parse) |> result.unwrap(8000)

  let assert Ok(_) =
    wisp_mist.handler(handle_request(bot, _), wisp.random_string(64))
    |> mist.new
    |> mist.port(port)
    |> mist.start

  wisp.log_info(
    "listening on :"
    <> int.to_string(port)
    <> " — health at /"
    <> telega_wisp.default_health_path,
  )

  process.sleep_forever()
}
