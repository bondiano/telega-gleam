import gleeunit

import bot

import telega/testing/conversation

pub fn main() {
  gleeunit.main()
}

pub fn help_command_test() {
  conversation.conversation_test()
  |> conversation.send("/help")
  |> conversation.expect_reply_containing("Image URL Bot")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn start_command_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Image URL Bot")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn text_without_urls_test() {
  conversation.conversation_test()
  |> conversation.send("just some text")
  |> conversation.expect_reply_containing("No URLs found")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn text_with_single_url_test() {
  conversation.conversation_test()
  |> conversation.send("https://example.com/photo.jpg")
  |> conversation.expect_reply_containing("Processing")
  |> conversation.run(bot.build_router(), fn() { Nil })
}

pub fn photo_download_failure_test() {
  conversation.conversation_test()
  |> conversation.send_photo()
  |> conversation.expect_reply_containing("Failed to save photo")
  |> conversation.run(bot.build_router(), fn() { Nil })
}
