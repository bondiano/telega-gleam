import gleam/list
import gleam/option.{None}
import gleeunit
import gleeunit/should
import telega/model/types.{type Update, Update}
import telega/polling

pub fn main() {
  gleeunit.main()
}

fn create_test_update(id: Int) -> Update {
  Update(
    update_id: id,
    message: None,
    edited_message: None,
    channel_post: None,
    edited_channel_post: None,
    business_connection: None,
    business_message: None,
    edited_business_message: None,
    deleted_business_messages: None,
    message_reaction: None,
    message_reaction_count: None,
    inline_query: None,
    chosen_inline_result: None,
    callback_query: None,
    shipping_query: None,
    pre_checkout_query: None,
    purchased_paid_media: None,
    poll: None,
    poll_answer: None,
    my_chat_member: None,
    chat_member: None,
    chat_join_request: None,
    chat_boost: None,
    removed_chat_boost: None,
  )
}

pub fn calculate_new_offset_empty_list_test() {
  polling.calculate_new_offset([], 100)
  |> should.equal(100)
}

pub fn calculate_new_offset_single_update_test() {
  let updates = [create_test_update(101)]

  polling.calculate_new_offset(updates, 100)
  |> should.equal(102)
}

pub fn calculate_new_offset_multiple_updates_test() {
  let updates = [
    create_test_update(101),
    create_test_update(102),
    create_test_update(103),
  ]

  polling.calculate_new_offset(updates, 100)
  |> should.equal(104)
}

pub fn calculate_new_offset_preserves_current_when_empty_test() {
  polling.calculate_new_offset([], 42)
  |> should.equal(42)

  polling.calculate_new_offset([], 0)
  |> should.equal(0)

  polling.calculate_new_offset([], 999)
  |> should.equal(999)
}

pub fn offset_progression_test() {
  let offset1 = polling.calculate_new_offset([], 0)
  should.equal(offset1, 0)

  let offset2 = polling.calculate_new_offset([create_test_update(1)], offset1)
  should.equal(offset2, 2)

  let updates =
    list.range(10, 15)
    |> list.map(create_test_update)
  let offset3 = polling.calculate_new_offset(updates, offset2)
  should.equal(offset3, 16)

  let offset4 = polling.calculate_new_offset([], offset3)
  should.equal(offset4, 16)
}
