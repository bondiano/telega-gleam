//// Integration tests for the conversation bot flows.
//// Tests actual multi-message conversation flows using the conversation DSL,
//// with_test_bot helper, and API call assertions.

import bot

import telega/bot as telega_bot
import telega/testing/conversation
import telega/testing/factory
import telega/testing/handler
import telega/testing/mock

import session.{NameBotSession}

fn default_session() -> session.NameBotSession {
  NameBotSession(name: "Unknown")
}

pub fn start_command_replies_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Name bot")
  |> conversation.run(bot.build_router(), default_session)
}

pub fn set_name_conversation_flow_test() {
  conversation.conversation_test()
  |> conversation.send("/set_name")
  |> conversation.expect_reply("What's your name?")
  |> conversation.send("Alice")
  |> conversation.expect_reply("Your name is: Alice set!")
  |> conversation.run(bot.build_router(), default_session)
}

pub fn set_name_then_get_name_test() {
  conversation.conversation_test()
  |> conversation.send("/set_name")
  |> conversation.expect_reply("What's your name?")
  |> conversation.send("Bob")
  |> conversation.expect_reply("Your name is: Bob set!")
  |> conversation.send("/get_name")
  |> conversation.expect_reply("Your name is: Bob")
  |> conversation.run(bot.build_router(), default_session)
}

pub fn with_test_bot_start_command_test() {
  handler.with_test_bot(
    router: bot.build_router(),
    session: default_session,
    handler: fn(bot_subject, calls) {
      let update = factory.command_update("start")
      telega_bot.handle_update(bot_subject:, update:)
      let _ =
        mock.assert_called_with_body(
          from: calls,
          path_contains: "sendMessage",
          body_contains: "Name bot",
        )
      Nil
    },
  )
}

// --- Isolated handler test ---

pub fn start_handler_isolated_test() {
  let update = factory.command_update("start")
  let #(result, calls) =
    handler.test_handler(
      session: default_session(),
      update:,
      handler: fn(ctx, _update) {
        bot.start_command_handler(ctx, factory.command(command: "start"))
      },
    )

  let assert Ok(_ctx) = result
  // Use assert_called_with_body which also verifies at least one call was made
  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendMessage",
      body_contains: "Name bot",
    )
  Nil
}

// --- API call body assertion test ---

pub fn set_name_api_call_body_test() {
  conversation.conversation_test()
  |> conversation.send("/set_name")
  |> conversation.expect_api_call(
    path_contains: "sendMessage",
    body_contains: "What's your name?",
  )
  |> conversation.send("Charlie")
  |> conversation.expect_api_call(
    path_contains: "sendMessage",
    body_contains: "Charlie",
  )
  |> conversation.run(bot.build_router(), default_session)
}
