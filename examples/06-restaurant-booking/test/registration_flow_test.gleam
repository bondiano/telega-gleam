//// Tests for the restaurant registration flow.
////
//// The bot injects its SQLite connection and i18n catalog through `dependencies`, so
//// the router is `Router(Nil, String, Dependencies)`. The `telega/testing` conversation
//// runner fixes `dependencies` to `Nil` and therefore can't drive a `dependencies`-typed
//// router, so these tests exercise the flow's pure validators and the flow
//// construction directly. Handler-level behavior that reads `ctx.dependencies` is
//// covered with `context.context_with_dependencies`.

import gleam/erlang/process
import gleam/option.{None, Some}
import sqlight

import telega/bot as telega_bot
import telega/testing/context
import telega/testing/factory
import telega/testing/mock

import restaurant_booking/bot
import restaurant_booking/config
import restaurant_booking/constants
import restaurant_booking/database
import restaurant_booking/dependencies.{type Dependencies, Dependencies}
import restaurant_booking/flows/registration
import restaurant_booking/handlers
import restaurant_booking/i18n

import test_db

fn test_config() -> config.Config {
  config.Config(
    bot_token: "test_token",
    database: database.ConnectionConfig(path: ":memory:"),
    restaurant_name: constants.default_restaurant_name,
  )
}

fn run_with_db(test_fn: fn(sqlight.Connection) -> Nil) -> Nil {
  case test_db.try_connect_and_setup() {
    None -> Nil
    Some(db) -> {
      test_fn(db)
      test_db.cleanup(db)
    }
  }
}

/// The router (with `Dependencies`) builds successfully from a db connection.
pub fn build_router_test() {
  use db <- run_with_db

  // Smoke test: building the `Router(Nil, String, Dependencies)` must not panic.
  let _ = bot.build_router(test_config(), db)
  Nil
}

/// `my_bookings` reads the db from `ctx.dependencies`; with no registered user it asks
/// the user to register (and the reply is sent through a mock client).
pub fn my_bookings_without_registration_test() {
  use db <- run_with_db

  let #(client, _calls) = mock.message_client()
  let ctx =
    dependencies_context(Dependencies(db:, catalog: i18n.catalog()), client)

  // No user registered for this chat — the handler completes without error.
  let assert Ok(_) =
    handlers.my_bookings(ctx, factory.command(command: "my_bookings"))
  Nil
}

/// Build a `Context` with injected `dependencies` and a working mock client so replies
/// decode to a valid `Message`.
fn dependencies_context(
  d: Dependencies,
  client,
) -> telega_bot.Context(Nil, String, Dependencies) {
  telega_bot.Context(
    key: "test_chat:123",
    update: factory.command_update(command: "my_bookings"),
    config: context.config_with_client(client),
    session: Nil,
    dependencies: d,
    chat_subject: process.new_subject(),
    start_time: None,
    log_prefix: None,
    bot_info: factory.bot_user(),
  )
}

// Validators ----------------------------------------------------------------

pub fn validate_name_test() {
  let assert Ok("Alice Johnson") = registration.validate_name("Alice Johnson")
  let assert Error("error.name_too_short") = registration.validate_name("A")
}

pub fn validate_phone_test() {
  let assert Ok(_) = registration.validate_phone("+1-555-123-4567")
  let assert Error("error.invalid_phone") = registration.validate_phone("123")
}

pub fn validate_email_test() {
  let assert Ok(_) = registration.validate_email("user@example.com")
  let assert Error("error.invalid_email") =
    registration.validate_email("not-an-email")
}
