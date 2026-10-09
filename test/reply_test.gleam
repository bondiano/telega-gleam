//// Regression tests for the chat a `reply.*` call targets.
////
//// `Context.key` is the session key — `"{chat_id}:{from_id}"` (see
//// `bot.build_session_key`) — not a chat id. Sending it as `chat_id` only ever
//// worked because the Bot API parses a string chat_id with the lenient
//// `td::to_integer`, which stops at the first non-digit; the strict paths on
//// the server (the per-chat flood fast path) silently skipped telega's calls.
//// Replies must carry the numeric chat id of the update instead.

import gleam/bit_array
import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot
import telega/chat_action
import telega/client
import telega/error
import telega/model/types
import telega/reply
import telega/testing/context as testing_context
import telega/testing/factory
import telega/testing/mock
import telega/update

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
  testing_context.with_client(ctx, tg_client)
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

pub fn with_photo_bytes_targets_numeric_chat_id_test() {
  let captured = process.new_subject()
  let bits_client = fn(req: request.Request(BitArray)) {
    process.send(captured, req)
    Ok(response.Response(
      status: 200,
      headers: [],
      body: bit_array.from_string(mock.message_response()),
    ))
  }
  let tg_client =
    client.new(token: "test_token", fetch_client: fn(_) {
      panic as "the bytes upload must not use the JSON client"
    })
    |> client.set_fetch_bits_client(bits_client)

  let _ =
    reply.with_photo_bytes(
      ctx: context_with(tg_client),
      bytes: bit_array.from_string("PNGDATA"),
      filename: "cat.png",
      content_type: "image/png",
      caption: None,
    )

  let assert Ok(req) = process.receive(captured, 100)
  let assert Ok(body) = bit_array.to_string(req.body)

  string.contains(body, "-100500") |> should.be_true
  string.contains(body, "-100500:888") |> should.be_false
}

pub fn with_file_link_uses_the_bot_token_test() {
  let file_response =
    "{\"ok\":true,\"result\":{\"file_id\":\"f\",\"file_unique_id\":\"u\",\"file_path\":\"photos/x.jpg\"}}"
  let #(tg_client, _calls) =
    mock.client_with(handler: fn(_req) {
      Ok(response.new(200) |> response.set_body(file_response))
    })

  let assert Ok(link) = reply.with_file_link(context_with(tg_client), "f")

  link
  |> should.equal("https://api.telegram.org/file/bottest_token/photos/x.jpg")
}

// Where in the chat a reply lands ---------------------------------------------
//
// A forum topic, a business chat and a channel's direct messages all need
// an id beside `chat_id`, or the reply goes to General / is rejected.

fn context_for(
  tg_client: client.TelegramClient,
  message: types.Message,
) -> bot.Context(Nil, error.TelegaError, Nil) {
  let ctx =
    testing_context.context_with_all(
      session: Nil,
      update: factory.message_update_with(message:, from_id: user_id, chat_id:),
      key: "-100500:888",
      bot_info: factory.bot_user(),
      dependencies: Nil,
    )
  testing_context.with_client(ctx, tg_client)
}

fn supergroup_message() -> types.Message {
  factory.message_with(
    text: "hi",
    from: factory.user_with(id: user_id, first_name: "Ada"),
    chat: factory.chat_with(id: chat_id, type_: "supergroup"),
  )
}

fn topic_message() -> types.Message {
  types.Message(
    ..supergroup_message(),
    message_thread_id: Some(42),
    is_topic_message: Some(True),
  )
}

pub fn a_reply_in_a_forum_topic_stays_in_the_topic_test() {
  let #(tg_client, calls) = mock.message_client()

  let _ = reply.with_text(context_for(tg_client, topic_message()), "hello")

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendMessage",
      body_contains: "\"message_thread_id\":42",
    )
  Nil
}

pub fn a_reply_to_a_reply_chain_names_no_topic_test() {
  // Not a topic: Telegram sets `message_thread_id` on any supergroup reply,
  // and a send carrying it to a chat without topics is rejected.
  let #(tg_client, calls) = mock.message_client()
  let message =
    types.Message(..supergroup_message(), message_thread_id: Some(42))

  let _ = reply.with_text(context_for(tg_client, message), "hello")

  let call =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendMessage",
      body_contains: "\"text\":\"hello\"",
    )
  string.contains(call.request.body, "message_thread_id") |> should.be_false
}

pub fn a_reply_to_a_business_message_carries_the_connection_test() {
  let #(tg_client, calls) = mock.message_client()
  let message =
    types.Message(..supergroup_message(), business_connection_id: Some("biz"))

  let _ = reply.with_html(context_for(tg_client, message), "<b>hi</b>")

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendMessage",
      body_contains: "\"business_connection_id\":\"biz\"",
    )
  Nil
}

pub fn an_edit_under_a_business_button_carries_the_connection_test() {
  let #(tg_client, calls) = mock.message_client()
  let message =
    types.Message(..supergroup_message(), business_connection_id: Some("biz"))
  let query =
    types.CallbackQuery(
      id: "q",
      from: factory.user_with(id: user_id, first_name: "Ada"),
      message: Some(types.MessageMaybeInaccessibleMessage(message)),
      inline_message_id: None,
      chat_instance: "ci",
      data: Some("press"),
      game_short_name: None,
    )
  let ctx =
    testing_context.context_with_all(
      session: Nil,
      update: update.CallbackQueryUpdate(
        query:,
        from_id: user_id,
        chat_id:,
        raw: factory.raw_update(message:),
      ),
      key: "-100500:888",
      bot_info: factory.bot_user(),
      dependencies: Nil,
    )
    |> testing_context.with_client(tg_client)

  let _ = reply.edit_callback_message(ctx, "done")

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "editMessageText",
      body_contains: "\"business_connection_id\":\"biz\"",
    )
  Nil
}

pub fn a_chat_action_in_a_forum_topic_targets_the_topic_test() {
  let #(tg_client, calls) = mock.client()

  let _ =
    chat_action.with_action_every(
      ctx: context_for(tg_client, topic_message()),
      action: chat_action.Typing,
      interval: 60_000,
      run: fn() { Nil },
    )

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendChatAction",
      body_contains: "\"message_thread_id\":42",
    )
  Nil
}

pub fn a_reply_in_a_direct_messages_chat_names_its_topic_test() {
  let #(tg_client, calls) = mock.message_client()
  let message =
    types.Message(
      ..supergroup_message(),
      direct_messages_topic: Some(types.DirectMessagesTopic(
        topic_id: 99,
        user: None,
      )),
    )

  let _ = reply.with_poll(context_for(tg_client, message), "q?", ["a", "b"])
  let _ = reply.with_text(context_for(tg_client, message), "hello")

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendMessage",
      body_contains: "\"direct_messages_topic_id\":99",
    )
  Nil
}
