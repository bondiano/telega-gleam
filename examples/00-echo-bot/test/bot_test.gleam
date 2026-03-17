import gleeunit

import bot

import telega/testing/conversation

pub fn main() {
  gleeunit.main()
}

pub fn echo_text_test() {
  conversation.conversation_test()
  |> conversation.send("Hello world")
  |> conversation.expect_reply("Hello world")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn echo_multiple_messages_test() {
  conversation.conversation_test()
  |> conversation.send("First")
  |> conversation.expect_reply("First")
  |> conversation.send("Second")
  |> conversation.expect_reply("Second")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn start_command_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Command: /start")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn help_command_test() {
  conversation.conversation_test()
  |> conversation.send("/help")
  |> conversation.expect_reply_containing("Command: /help")
  |> conversation.run(bot.build_router(), fn() { Nil })
}
