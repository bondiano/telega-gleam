//// Driven against a mock client — no token, no network, no model.

import gleeunit

import telega/testing/conversation

import bot

pub fn main() {
  gleeunit.main()
}

pub fn start_command_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("token by token")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn prompt_opens_with_a_placeholder_test() {
  conversation.conversation_test()
  |> conversation.send("why is the sky blue?")
  // The user hears back immediately; the answer then fills this same message
  // in through `editMessageText`.
  |> conversation.expect_reply_containing("Thinking")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn echo_sends_text_verbatim_test() {
  conversation.conversation_test()
  |> conversation.send("/echo *not markdown*")
  // With entities nothing is escaped, so the asterisks survive the round trip.
  |> conversation.expect_reply_containing("*not markdown*")
  |> conversation.run(bot.build_router(), fn() { Nil })
}
