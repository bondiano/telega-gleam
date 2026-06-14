//// End-to-end test for the `/language` command: switching the language
//// persists the choice and changes the language of subsequent replies.
//// Backed by an in-memory SQLite database.

import gleam/option.{None, Some}
import sqlight

import telega/testing/conversation

import restaurant_booking/bot
import restaurant_booking/config
import restaurant_booking/constants
import restaurant_booking/database

import test_db

fn with_db(test_fn: fn(sqlight.Connection) -> Nil) -> Nil {
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
    database: database.ConnectionConfig(path: ":memory:"),
    restaurant_name: constants.default_restaurant_name,
  )
}

/// `/language` offers a picker; choosing Russian switches all later replies to
/// Russian (here verified through `/help`).
pub fn switch_language_to_russian_test() {
  use db <- with_db

  let test_router = bot.build_router(test_config(), db)

  conversation.conversation_test()
  // Default locale is English (the test updates carry no language_code).
  |> conversation.send("/language")
  |> conversation.expect_reply_with_keyboard(
    containing: "Choose your language",
    buttons: ["English", "Русский"],
  )
  // Pick Russian → confirmation comes back in Russian.
  |> conversation.send_callback("lang:ru")
  |> conversation.expect_reply_containing("переключён на русский")
  // Subsequent commands are now Russian too.
  |> conversation.send("/help")
  |> conversation.expect_reply_containing("Доступные команды")
  |> conversation.run(test_router, fn() { Nil })
}

/// Help is English by default (no stored override, no Telegram language_code).
pub fn help_is_english_by_default_test() {
  use db <- with_db

  let test_router = bot.build_router(test_config(), db)

  conversation.conversation_test()
  |> conversation.send("/help")
  |> conversation.expect_reply_containing("Available commands")
  |> conversation.run(test_router, fn() { Nil })
}
