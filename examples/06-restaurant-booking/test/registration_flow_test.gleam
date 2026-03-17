//// Integration tests for the restaurant registration flow.
//// Requires a running PostgreSQL instance with the test database.
//// Tests are skipped gracefully when the database is unavailable.
////
//// Demonstrates: conversation DSL, expect_keyboard, expect_reply_with_keyboard,
//// expect_api_call, with_test_bot, and routed_client.

import gleam/option.{None, Some}
import pog

import test_db

import telega/bot as telega_bot
import telega/testing/conversation
import telega/testing/factory
import telega/testing/handler
import telega/testing/mock

import restaurant_booking/bot
import restaurant_booking/config
import restaurant_booking/constants
import restaurant_booking/database

fn with_db(test_fn: fn(pog.Connection) -> Nil) -> Nil {
  case test_db.try_connect_and_setup() {
    None -> Nil
    Some(db) -> {
      test_fn(db)
      test_db.cleanup(db)
    }
  }
}

fn test_config() -> config.Config {
  config.Config(
    bot_token: "test_token",
    database: database.default_config(),
    restaurant_name: constants.default_restaurant_name,
  )
}

pub fn full_registration_flow_test() {
  use db <- with_db

  let test_router = bot.build_router(test_config(), db)

  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Welcome")
  |> conversation.expect_reply_containing("full name")
  |> conversation.send("Alice Johnson")
  |> conversation.expect_reply_containing("phone number")
  |> conversation.send("+1-555-123-4567")
  |> conversation.expect_reply_containing("Email")
  |> conversation.send("skip")
  |> conversation.expect_reply_containing("confirm your registration")
  |> conversation.send_callback("reg_confirm:true")
  |> conversation.expect_reply_containing("Registration successful")
  |> conversation.run(test_router, fn() { Nil })
}

/// Tests that the confirmation step sends a keyboard with Yes/No buttons.
pub fn registration_confirmation_keyboard_test() {
  use db <- with_db

  let test_router = bot.build_router(test_config(), db)

  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Welcome")
  |> conversation.expect_reply_containing("full name")
  |> conversation.send("Alice Johnson")
  |> conversation.expect_reply_containing("phone number")
  |> conversation.send("+1-555-123-4567")
  |> conversation.expect_reply_containing("Email")
  |> conversation.send("skip")
  |> conversation.expect_reply_with_keyboard(
    containing: "confirm your registration",
    buttons: ["Yes", "No"],
  )
  |> conversation.send_callback("reg_confirm:true")
  |> conversation.expect_reply_containing("Registration successful")
  |> conversation.run(test_router, fn() { Nil })
}

/// Tests using with_test_bot to verify API calls directly.
pub fn with_test_bot_start_command_test() {
  use db <- with_db

  let test_router = bot.build_router(test_config(), db)

  handler.with_test_bot(
    router: test_router,
    session: fn() { Nil },
    handler: fn(bot_subject, calls) {
      let update = factory.command_update("start")
      telega_bot.handle_update(bot_subject:, update:)

      // Verify welcome message was sent
      let _ =
        mock.assert_called_with_body(
          from: calls,
          path_contains: "sendMessage",
          body_contains: "Welcome",
        )
      Nil
    },
  )
}

/// Tests registration flow with a routed mock client.
/// answerCallbackQuery gets a correct boolean response instead of a Message JSON.
pub fn registration_with_routed_client_test() {
  use db <- with_db

  let test_router = bot.build_router(test_config(), db)
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "answerCallbackQuery",
        response: mock.bool_response(),
      ),
    ])

  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Welcome")
  |> conversation.expect_reply_containing("full name")
  |> conversation.send("Alice Johnson")
  |> conversation.expect_reply_containing("phone number")
  |> conversation.send("+1-555-123-4567")
  |> conversation.expect_reply_containing("Email")
  |> conversation.send("skip")
  |> conversation.expect_reply_containing("confirm your registration")
  |> conversation.send_callback("reg_confirm:true")
  |> conversation.expect_reply_containing("Registration successful")
  |> conversation.run_with_mock(test_router, fn() { Nil }, client, calls)
}

/// Tests validation: invalid phone number should prompt retry.
pub fn registration_invalid_phone_test() {
  use db <- with_db

  let test_router = bot.build_router(test_config(), db)

  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Welcome")
  |> conversation.expect_reply_containing("full name")
  |> conversation.send("Alice Johnson")
  |> conversation.expect_reply_containing("phone number")
  |> conversation.send("123")
  |> conversation.expect_reply_containing("digits")
  |> conversation.send("+1-555-123-4567")
  |> conversation.expect_reply_containing("Email")
  |> conversation.run(test_router, fn() { Nil })
}
