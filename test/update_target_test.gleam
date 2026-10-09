//// Where a reply to an update belongs: the forum topic, business connection
//// and direct-messages topic of the message it answers.

import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

import telega/model/types
import telega/testing/factory
import telega/update

pub fn main() {
  gleeunit.main()
}

fn message_in(chat_type: String) -> types.Message {
  factory.message_with(
    text: "hi",
    from: factory.user(),
    chat: factory.chat_with(id: -100_500, type_: chat_type),
  )
}

fn as_update(message: types.Message) -> update.Update {
  factory.message_update_with(message:, from_id: 1, chat_id: -100_500)
}

pub fn a_topic_message_names_its_topic_test() {
  let message =
    types.Message(
      ..message_in("supergroup"),
      message_thread_id: Some(42),
      is_topic_message: Some(True),
    )

  update.message_thread_id(as_update(message)) |> should.equal(Some(42))
}

pub fn a_reply_chain_in_a_plain_supergroup_is_not_a_topic_test() {
  // Telegram sets `message_thread_id` on any reply in a supergroup; only
  // `is_topic_message` tells a topic from a reply chain.
  let message =
    types.Message(..message_in("supergroup"), message_thread_id: Some(42))

  update.message_thread_id(as_update(message)) |> should.equal(None)
}

pub fn a_callback_query_answers_for_the_message_under_the_button_test() {
  let message =
    types.Message(
      ..message_in("supergroup"),
      message_thread_id: Some(7),
      is_topic_message: Some(True),
      business_connection_id: Some("biz"),
    )
  let query =
    types.CallbackQuery(
      id: "q",
      from: factory.user(),
      message: Some(types.MessageMaybeInaccessibleMessage(message)),
      inline_message_id: None,
      chat_instance: "ci",
      data: Some("press"),
      game_short_name: None,
    )
  let upd =
    update.CallbackQueryUpdate(
      query:,
      from_id: 1,
      chat_id: -100_500,
      raw: factory.raw_update(message:),
    )

  update.message_thread_id(upd) |> should.equal(Some(7))
  update.business_connection_id(upd) |> should.equal(Some("biz"))
}

pub fn a_business_message_names_its_connection_test() {
  let message =
    types.Message(..message_in("private"), business_connection_id: Some("biz"))

  update.business_connection_id(as_update(message)) |> should.equal(Some("biz"))
  update.message_thread_id(as_update(message)) |> should.equal(None)
}

pub fn a_direct_messages_topic_names_its_topic_test() {
  let message =
    types.Message(
      ..message_in("private"),
      direct_messages_topic: Some(types.DirectMessagesTopic(
        topic_id: 99,
        user: None,
      )),
    )

  update.direct_messages_topic_id(as_update(message)) |> should.equal(Some(99))
}

pub fn an_update_without_a_message_has_no_target_test() {
  let upd = factory.inline_query_update(query: "q")

  update.message_thread_id(upd) |> should.equal(None)
  update.business_connection_id(upd) |> should.equal(None)
  update.direct_messages_topic_id(upd) |> should.equal(None)
}
