import gleeunit

import bot

import telega/testing/conversation

pub fn main() {
  gleeunit.main()
}

pub fn start_command_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("dice bot")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn dice_command_sends_dice_test() {
  conversation.conversation_test()
  |> conversation.send("/dice")
  |> conversation.expect_api_call(
    path_contains: "sendDice",
    body_contains: "chat_id",
  )
  |> conversation.run(bot.build_router(), fn() { Nil })
}
