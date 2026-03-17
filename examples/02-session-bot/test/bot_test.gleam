import gleeunit

import bot

import session.{NameBotSession, WaitName}

import telega/testing/conversation

pub fn main() {
  gleeunit.main()
}

fn default_session() -> session.NameBotSession {
  NameBotSession(name: "Unknown", state: WaitName)
}

pub fn start_command_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Name bot")
  |> conversation.run(bot.build_router(), default_session)
}

pub fn set_name_flow_test() {
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

pub fn get_name_default_test() {
  conversation.conversation_test()
  |> conversation.send("/get_name")
  |> conversation.expect_reply("Your name is: Unknown")
  |> conversation.run(bot.build_router(), default_session)
}

pub fn text_ignored_before_set_name_test() {
  conversation.conversation_test()
  |> conversation.send("random text")
  |> conversation.send("/get_name")
  |> conversation.expect_reply("Your name is: Unknown")
  |> conversation.run(bot.build_router(), default_session)
}
