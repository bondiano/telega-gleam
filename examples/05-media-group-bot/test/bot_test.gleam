import gleam/json
import gleeunit

import bot

import telega/model/encoder
import telega/testing/conversation
import telega/testing/factory
import telega/testing/mock

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
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "sendMediaGroup",
        response: mock.ok_response(
          result: json.preprocessed_array([
            encoder.encode_message(factory.message(text: "")),
          ]),
        ),
      ),
    ])

  conversation.conversation_test()
  |> conversation.send("https://example.com/photo.jpg")
  |> conversation.expect_api_call(
    path_contains: "sendMediaGroup",
    body_contains: "example.com",
  )
  |> conversation.run_with_mock(bot.build_router(), fn() { Nil }, client, calls)
}

pub fn photo_download_failure_test() {
  conversation.conversation_test()
  |> conversation.send_photo()
  |> conversation.expect_reply_containing("Failed to save photo")
  |> conversation.run(bot.build_router(), fn() { Nil })
}
