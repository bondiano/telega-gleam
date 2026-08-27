//// Ephemeral messages (Bot API 10.3): group-chat messages visible to a single
//// user, addressed through `ephemeral_message_parameters` of the send methods.

import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot
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

fn context_with(
  tg_client: client.TelegramClient,
  update: update.Update,
) -> bot.Context(Nil, error.TelegaError, Nil) {
  let ctx = testing_context.context_with(session: Nil, update:)
  bot.Context(..ctx, config: testing_context.config_with_client(tg_client))
}

pub fn ephemeral_parameters_from_text_update_test() {
  let ctx =
    testing_context.context_with(
      session: Nil,
      update: factory.text_update_with(
        text: "hi",
        from_id: 777,
        chat_id: -100_500,
      ),
    )

  reply.ephemeral_parameters(ctx)
  |> should.equal(types.EphemeralMessageParameters(
    receiver_user_id: 777,
    callback_query_id: None,
    replace_callback_query_message: None,
  ))
}

pub fn ephemeral_parameters_wire_callback_query_id_test() {
  let ctx =
    testing_context.context_with(
      session: Nil,
      update: factory.callback_query_update_with(
        data: "press",
        from_id: 777,
        chat_id: -100_500,
      ),
    )

  reply.ephemeral_parameters(ctx).callback_query_id
  |> should.equal(Some("test_callback_query"))
}

pub fn with_ephemeral_text_sends_receiver_test() {
  let #(tg_client, calls) = mock.message_client()
  let update =
    factory.callback_query_update_with(
      data: "press",
      from_id: 777,
      chat_id: -100_500,
    )

  let _ = reply.with_ephemeral_text(context_with(tg_client, update), "only you")

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendMessage",
      body_contains: "\"ephemeral_message_parameters\":{\"receiver_user_id\":777,\"callback_query_id\":\"test_callback_query\"}",
    )
  Nil
}

pub fn with_ephemeral_takes_explicit_parameters_test() {
  let #(tg_client, calls) = mock.message_client()
  let update = factory.text_update_with(text: "hi", from_id: 1, chat_id: 2)
  let parameters =
    types.EphemeralMessageParameters(
      ..types.new_ephemeral_message_parameters(receiver_user_id: 42),
      replace_callback_query_message: Some(True),
    )

  let _ =
    reply.with_ephemeral(
      ctx: context_with(tg_client, update),
      text: "only you",
      parameters:,
    )

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendMessage",
      body_contains: "\"receiver_user_id\":42,\"replace_callback_query_message\":true",
    )
  Nil
}

/// A plain send must not carry the field at all — `json_object_filter_nulls`
/// drops it, so existing bots keep their exact request bodies.
pub fn plain_send_has_no_ephemeral_field_test() {
  let #(tg_client, calls) = mock.message_client()
  let update = factory.text_update_with(text: "hi", from_id: 1, chat_id: 2)

  let _ = reply.with_text(context_with(tg_client, update), "hello")

  let assert [call] = mock.get_calls(from: calls)
  call.request.body
  |> string.contains("ephemeral_message_parameters")
  |> should.be_false
}
