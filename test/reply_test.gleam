//// Regression tests for the chat a `reply.*` call targets.
////
//// `Context.key` is the session key — `"{chat_id}:{from_id}"` (see
//// `bot.build_session_key`) — not a chat id. Sending it as `chat_id` only ever
//// worked because the Bot API parses a string chat_id with the lenient
//// `td::to_integer`, which stops at the first non-digit; the strict paths on
//// the server (the per-chat flood fast path) silently skipped telega's calls.
//// Replies must carry the numeric chat id of the update instead.

import gleam/string
import gleeunit
import gleeunit/should

import telega/bot
import telega/chat_action
import telega/client
import telega/error
import telega/reply
import telega/testing/context as testing_context
import telega/testing/factory
import telega/testing/mock

pub fn main() {
  gleeunit.main()
}

const chat_id = -100_500

const user_id = 888

fn context_with(
  tg_client: client.TelegramClient,
) -> bot.Context(Nil, error.TelegaError, Nil) {
  let ctx =
    testing_context.context_with_all(
      session: Nil,
      update: factory.text_update_with(text: "hi", from_id: user_id, chat_id:),
      // A composite session key, exactly as the bot actor builds it.
      key: "-100500:888",
      bot_info: factory.bot_user(),
      dependencies: Nil,
    )
  bot.Context(..ctx, config: testing_context.config_with_client(tg_client))
}

pub fn with_text_targets_numeric_chat_id_test() {
  let #(tg_client, calls) = mock.message_client()

  let _ = reply.with_text(context_with(tg_client), "hello")

  let call =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendMessage",
      body_contains: "\"chat_id\":-100500",
    )

  call.request.body
  |> string.contains("-100500:888")
  |> should.be_false
}

pub fn chat_action_targets_numeric_chat_id_test() {
  let #(tg_client, calls) = mock.client()

  let _ =
    chat_action.with_action_every(
      ctx: context_with(tg_client),
      action: chat_action.Typing,
      interval: 60_000,
      run: fn() { Nil },
    )

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendChatAction",
      body_contains: "\"chat_id\":-100500",
    )
  Nil
}
