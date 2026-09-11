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

/// `language_code` and `scope` are fields of the setMyCommands REQUEST. Put
/// inside a command object instead, Telegram drops them — and then every
/// localized call overwrites the default menu, so the last language published
/// is the one everybody sees. Nothing about that is visible from a substring
/// search, so these tests assert the whole body.
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

  // The default-language menu carries no language at all — it is the menu for
  // everyone the next call does not name — and the Russian one carries its
  // own, beside `commands` rather than inside one.
  set_my_commands_bodies(drain(calls))
  |> should.equal([
    "{\"commands\":[{\"command\":\"help\",\"description\":\"Show help\"},"
      <> "{\"command\":\"start\",\"description\":\"Start the bot\"}]}",
    "{\"commands\":[{\"command\":\"help\",\"description\":\"Показать справку\"},"
      <> "{\"command\":\"start\",\"description\":\"Запустить бота\"}],"
      <> "\"language_code\":\"ru\"}",
  ])

  stop(bot)
}

pub fn command_scopes_split_the_private_menu_from_the_group_one_test() {
  let #(client, calls) = mock.routed_client(start_routes())

  let assert Ok(bot) =
    new_builder(client)
    |> telega.with_command_scopes([
      #(telega.PrivateChats, ["start", "help"]),
      #(telega.GroupChats, ["help"]),
    ])
    |> telega.start()

  // Three menus: the default one keeps the whole catalog (it is what an
  // unpublished scope falls back to), then one per scope, each carrying its
  // own scope object and only the commands that belong in it.
  // …and the scoped ones read in the order the CALLER listed them, which is the
  // order a person reads the menu in — the router's own order is whatever the
  // routes happened to be registered as.
  set_my_commands_bodies(drain(calls))
  |> should.equal([
    "{\"commands\":[{\"command\":\"help\",\"description\":\"Show help\"},"
      <> "{\"command\":\"start\",\"description\":\"Start the bot\"}]}",
    "{\"commands\":[{\"command\":\"start\",\"description\":\"Start the bot\"},"
      <> "{\"command\":\"help\",\"description\":\"Show help\"}],"
      <> "\"scope\":{\"type\":\"all_private_chats\"}}",
    "{\"commands\":[{\"command\":\"help\",\"description\":\"Show help\"}],"
      <> "\"scope\":{\"type\":\"all_group_chats\"}}",
  ])

  stop(bot)
}

pub fn a_scope_is_published_in_every_locale_too_test() {
  let #(client, calls) = mock.routed_client(start_routes())

  let assert Ok(bot) =
    new_builder(client)
    |> telega.with_command_translations(
      locales: ["ru"],
      translate: fn(command, _locale) {
        case command {
          "help" -> Some("Показать справку")
          _ -> None
        }
      },
    )
    |> telega.with_command_scopes([#(telega.GroupChats, ["help"])])
    |> telega.start()

  // A scoped menu is a menu: it gets the same per-locale treatment, with both
  // fields side by side. A localized call that forgot its scope would land on
  // the default menu and quietly replace it.
  set_my_commands_bodies(drain(calls))
  |> list.filter(string.contains(_, "all_group_chats"))
  |> should.equal([
    "{\"commands\":[{\"command\":\"help\",\"description\":\"Show help\"}],"
      <> "\"scope\":{\"type\":\"all_group_chats\"}}",
    "{\"commands\":[{\"command\":\"help\",\"description\":\"Показать справку\"}],"
      <> "\"scope\":{\"type\":\"all_group_chats\"},\"language_code\":\"ru\"}",
  ])

  stop(bot)
}

pub fn a_command_no_route_describes_is_dropped_from_its_scope_test() {
  let #(client, calls) = mock.routed_client(start_routes())

  // `hunt` is a typo, a renamed command, or one registered without a
  // description — either way the router has no words for it, and publishing it
  // would offer the player a menu entry nothing answers.
  let assert Ok(bot) =
    new_builder(client)
    |> telega.with_command_scopes([#(telega.GroupChats, ["hunt", "help"])])
    |> telega.start()

  set_my_commands_bodies(drain(calls))
  |> list.filter(string.contains(_, "all_group_chats"))
  |> should.equal([
    "{\"commands\":[{\"command\":\"help\",\"description\":\"Show help\"}],"
    <> "\"scope\":{\"type\":\"all_group_chats\"}}",
  ])

  stop(bot)
}

/// The body of every `setMyCommands` call, in the order they were made.
fn set_my_commands_bodies(calls: List(ApiCall)) -> List(String) {
  calls
  |> list.filter(fn(call) {
    let ApiCall(request:) = call
    string.contains(request.path, "setMyCommands")
  })
  |> list.map(fn(call) {
    let ApiCall(request:) = call
    request.body
  })
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
