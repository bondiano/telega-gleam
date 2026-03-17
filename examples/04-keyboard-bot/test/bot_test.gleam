import gleeunit

import bot

import session.{English, LanguageBotSession}

import telega/testing/conversation
import telega/testing/mock

pub fn main() {
  gleeunit.main()
}

fn default_session() -> session.LanguageBotSession {
  LanguageBotSession(language: English)
}

pub fn start_command_english_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Hello!")
  |> conversation.run(bot.build_router(), default_session)
}

pub fn lang_keyboard_choose_russian_test() {
  conversation.conversation_test()
  |> conversation.send("/lang")
  |> conversation.expect_keyboard(buttons: ["Russian", "English"])
  |> conversation.send_callback("0")
  |> conversation.expect_reply_containing("Язык изменен")
  |> conversation.run(bot.build_router(), default_session)
}

pub fn lang_inline_keyboard_test() {
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "answerCallbackQuery",
        response: mock.bool_response(),
      ),
    ])

  conversation.conversation_test()
  |> conversation.send("/lang_inline")
  |> conversation.expect_reply_containing("Choose your language")
  |> conversation.send_callback("language:russian")
  |> conversation.expect_reply_containing("Язык изменен")
  |> conversation.run_with_mock(
    bot.build_router(),
    default_session,
    client,
    calls,
  )
}
