//// Integration tests for the conversation bot flows.
//// Tests actual multi-message conversation flows using the conversation DSL.

import bot

import telega/testing/conversation

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
