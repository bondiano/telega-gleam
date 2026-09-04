import gleeunit

import telega/testing/conversation

import bot

pub fn main() {
  gleeunit.main()
}

pub fn start_command_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("webhook")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn ping_command_test() {
  conversation.conversation_test()
  |> conversation.send("/ping")
  |> conversation.expect_reply_containing("pong")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn echoes_text_test() {
  conversation.conversation_test()
  |> conversation.send("hello there")
  |> conversation.expect_reply_containing("hello there")
  |> conversation.run(bot.build_router(), fn() { Nil })
}
