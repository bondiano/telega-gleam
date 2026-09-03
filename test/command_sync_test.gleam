//// End-to-end tests for command and `allowed_updates` auto-synchronization.
////
//// Uses webhook `init` (no background polling loop) with a routed mock client,
//// so the `setWebhook` + `setMyCommands` calls made on start are deterministic
//// and inspectable.

import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should

import telega
import telega/bot.{type Context}
import telega/error.{type TelegaError}
import telega/model/encoder
import telega/router
import telega/testing/factory
import telega/testing/mock.{type ApiCall, ApiCall}

fn ok_1(
  ctx: Context(Nil, TelegaError, Nil),
  _x: a,
) -> Result(Context(Nil, TelegaError, Nil), TelegaError) {
  Ok(ctx)
}

fn start_routes() {
  [
    mock.route_with_response(
      "getMe",
      mock.ok_response(encoder.encode_user(factory.bot_user())),
    ),
    mock.route_with_response("setWebhook", mock.bool_response()),
    mock.route_with_response("setMyCommands", mock.bool_response()),
  ]
}

fn build_router() {
  router.new("commands")
  |> router.on_command_with_description("start", "Start the bot", ok_1)
  |> router.on_command_with_description("help", "Show help", ok_1)
  |> router.on_inline_query(ok_1)
}

fn new_builder(client) {
  telega.new(client)
  |> telega.webhook(
    url: "https://example.com",
    path: "/hook",
    secret_token: None,
  )
  |> telega.router(build_router())
}

/// `mock.get_calls` drains the subject, so collect once and query the snapshot.
fn seen(calls: List(ApiCall), path: String, body: String) -> Bool {
  list.any(calls, fn(call) {
    let ApiCall(request:) = call
    string.contains(request.path, path) && string.contains(request.body, body)
  })
}

fn drain(calls: Subject(ApiCall)) -> List(ApiCall) {
  mock.get_calls(from: calls)
}

/// `telega.shutdown` sends an abnormal exit to the root supervisor, which is
/// linked to this test process. Unlink first so tearing the tree down does not
/// take the test with it.
fn stop(bot: telega.Telega(Nil, TelegaError, Nil)) -> Nil {
  process.unlink(telega.get_supervisor_pid(bot))
  telega.shutdown(bot)
}

pub fn auto_commands_published_on_start_test() {
  let #(client, calls) = mock.routed_client(start_routes())

  let assert Ok(bot) =
    new_builder(client)
    |> telega.with_auto_commands()
    |> telega.start()

  let calls = drain(calls)
  // Both described commands are published via setMyCommands.
  seen(calls, "setMyCommands", "Start the bot") |> should.be_true
  seen(calls, "setMyCommands", "Show help") |> should.be_true

  stop(bot)
}

pub fn auto_commands_localized_per_language_test() {
  let #(client, calls) = mock.routed_client(start_routes())

  let translate = fn(command, locale) {
    case command, locale {
      "start", "ru" -> Some("Запустить бота")
      "help", "ru" -> Some("Показать справку")
      _, _ -> None
    }
  }

  let assert Ok(bot) =
    new_builder(client)
    |> telega.with_command_translations(locales: ["ru"], translate:)
    |> telega.start()

  let calls = drain(calls)
  // Default-language menu...
  seen(calls, "setMyCommands", "Start the bot") |> should.be_true
  // ...plus a localized variant carrying the language_code.
  seen(calls, "setMyCommands", "Запустить бота") |> should.be_true
  seen(calls, "setMyCommands", "\"language_code\":\"ru\"") |> should.be_true

  stop(bot)
}

pub fn auto_allowed_updates_passed_to_set_webhook_test() {
  let #(client, calls) = mock.routed_client(start_routes())

  let assert Ok(bot) =
    new_builder(client)
    |> telega.with_auto_allowed_updates()
    |> telega.start()

  let calls = drain(calls)
  // Router handles commands (message) and inline queries only.
  seen(calls, "setWebhook", "inline_query") |> should.be_true
  seen(calls, "setWebhook", "message") |> should.be_true

  stop(bot)
}

pub fn no_commands_published_without_opt_in_test() {
  let #(client, calls) = mock.routed_client(start_routes())

  let assert Ok(bot) =
    new_builder(client)
    |> telega.start()

  let calls = drain(calls)
  // setWebhook + getMe happen, but no setMyCommands without with_auto_commands.
  seen(calls, "setMyCommands", "") |> should.be_false

  stop(bot)
}

// M9 — derivation only sees the router ---------------------------------------

pub fn extra_allowed_updates_are_added_to_the_derived_set_test() {
  let #(client, calls) = mock.routed_client(start_routes())

  // The router registers no callback route, but a conversation in it uses
  // `wait_callback`. Without this, Telegram never sends `callback_query` and
  // the wait hangs forever.
  let assert Ok(bot) =
    new_builder(client)
    |> telega.with_auto_allowed_updates()
    |> telega.with_extra_allowed_updates(["callback_query"])
    |> telega.start()

  let calls = drain(calls)
  seen(calls, "setWebhook", "callback_query") |> should.be_true
  seen(calls, "setWebhook", "inline_query") |> should.be_true

  stop(bot)
}

pub fn extra_allowed_updates_do_not_narrow_a_wildcard_router_test() {
  let #(client, calls) = mock.routed_client(start_routes())

  // A router with a fallback handles anything, so derivation deliberately
  // returns "do not restrict". Extras must not turn that into a narrow list.
  let assert Ok(bot) =
    new_builder(client)
    |> telega.router(
      router.new("wildcard")
      |> router.fallback(fn(ctx, _upd) { Ok(ctx) }),
    )
    |> telega.with_auto_allowed_updates()
    |> telega.with_extra_allowed_updates(["callback_query"])
    |> telega.start()

  let calls = drain(calls)
  seen(calls, "setWebhook", "allowed_updates") |> should.be_false

  stop(bot)
}
