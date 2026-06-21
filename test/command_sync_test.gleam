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
  ctx: Context(Nil, TelegaError),
  _x: a,
) -> Result(Context(Nil, TelegaError), TelegaError) {
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
  telega.new(
    api_client: client,
    url: "https://example.com",
    webhook_path: "/hook",
    secret_token: None,
  )
  |> telega.with_router(build_router())
  |> telega.with_nil_session()
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
fn stop(bot: telega.Telega(Nil, TelegaError)) -> Nil {
  process.unlink(telega.get_supervisor_pid(bot))
  telega.shutdown(bot)
}

pub fn auto_commands_published_on_start_test() {
  let #(client, calls) = mock.routed_client(start_routes())

  let assert Ok(bot) =
    new_builder(client)
    |> telega.with_auto_commands()
    |> telega.init()

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
    |> telega.init()

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
    |> telega.init()

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
    |> telega.init()

  let calls = drain(calls)
  // setWebhook + getMe happen, but no setMyCommands without with_auto_commands.
  seen(calls, "setMyCommands", "") |> should.be_false

  stop(bot)
}
