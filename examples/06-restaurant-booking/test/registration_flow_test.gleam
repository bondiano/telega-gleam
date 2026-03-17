//// Integration tests for the restaurant registration flow.
//// Requires a running PostgreSQL instance with the test database.
//// Tests are skipped gracefully when the database is unavailable.

import gleam/option.{None, Some}

import test_db

import telega/testing/conversation

import restaurant_booking/bot
import restaurant_booking/config
import restaurant_booking/constants
import restaurant_booking/database

pub fn full_registration_flow_test() {
  case test_db.try_connect_and_setup() {
    None -> Nil
    Some(db) -> {
      let cfg =
        config.Config(
          bot_token: "test_token",
          database: database.default_config(),
          restaurant_name: constants.default_restaurant_name,
        )

      let test_router = bot.build_router(cfg, db)

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

      test_db.cleanup(db)
    }
  }
}
