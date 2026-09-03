//// The names Telegram accepts in `allowed_updates` are a spec fact, so they
//// are generated (`telega/internal/update_info`) from the same `Update` type
//// that drives `update.raw_to_update`. What is left to test is the direction
//// codegen cannot check: that the hand-written route → update-kind mapping in
//// `router` only ever answers with names that table knows. A typo there
//// narrows a bot to nothing, and a test that compares the derived list against
//// a hand-written expectation repeats the typo instead of catching it.

import gleam/list
import gleeunit/should

import telega/bot.{type Context}
import telega/error.{type TelegaError}
import telega/internal/update_info
import telega/router

type Ctx =
  Context(Nil, TelegaError, Nil)

fn ok_handler(ctx: Ctx, _payload) -> Result(Ctx, TelegaError) {
  Ok(ctx)
}

fn ok_album(ctx: Ctx, _id: String, _messages) -> Result(Ctx, TelegaError) {
  Ok(ctx)
}

pub fn the_table_covers_the_whole_spec_test() {
  update_info.bot_api_version |> should.equal("Bot API 10.3")
  update_info.update_kind_count |> should.equal(27)
  update_info.update_fields()
  |> list.length
  |> should.equal(update_info.update_kind_count)
}

pub fn the_update_id_is_not_an_update_kind_test() {
  update_info.is_update_field("update_id") |> should.be_false
  update_info.is_update_field("mesage") |> should.be_false
  update_info.is_update_field("") |> should.be_false
}

pub fn every_listed_field_is_a_known_field_test() {
  update_info.update_fields()
  |> list.all(update_info.is_update_field)
  |> should.be_true
}

pub fn each_field_carries_the_type_the_spec_gives_it_test() {
  update_info.update_field_type("message") |> should.equal(Ok("Message"))
  update_info.update_field_type("purchased_paid_media")
  |> should.equal(Ok("PaidMediaPurchased"))
  update_info.update_field_type("removed_chat_boost")
  |> should.equal(Ok("ChatBoostRemoved"))
  update_info.update_field_type("update_id") |> should.be_error
}

/// One router carrying every route kind that maps to an `allowed_updates`
/// name, so the whole mapping is exercised at once.
pub fn every_derived_name_is_a_spec_update_kind_test() {
  router.new("every-kind")
  |> router.on_any_text(ok_handler)
  |> router.on_photo(ok_handler)
  |> router.on_video(ok_handler)
  |> router.on_voice(ok_handler)
  |> router.on_audio(ok_handler)
  |> router.on_media_group(ok_album)
  |> router.on_web_app_data(ok_handler)
  |> router.on_edited_message(ok_handler)
  |> router.on_channel_post(ok_handler)
  |> router.on_edited_channel_post(ok_handler)
  |> router.on_business_message(ok_handler)
  |> router.on_inline_query(ok_handler)
  |> router.on_chosen_inline_result(ok_handler)
  |> router.on_shipping_query(ok_handler)
  |> router.on_pre_checkout_query(ok_handler)
  |> router.on_paid_media_purchase(ok_handler)
  |> router.on_poll(ok_handler)
  |> router.on_poll_answer(ok_handler)
  |> router.on_reaction(ok_handler)
  |> router.on_reaction_emoji("👍", ok_handler)
  |> router.on_paid_reaction(ok_handler)
  |> router.on_reaction_added(ok_handler)
  |> router.on_reaction_removed(ok_handler)
  |> router.on_reaction_count(ok_handler)
  |> router.on_chat_member_updated(ok_handler)
  |> router.on_my_chat_member_updated(ok_handler)
  |> router.on_chat_join_request(ok_handler)
  |> router.on_chat_boost(ok_handler)
  |> router.on_removed_chat_boost(ok_handler)
  |> router.allowed_updates
  |> list.each(fn(name) {
    case update_info.is_update_field(name) {
      True -> Nil
      False ->
        panic as { "router derived an unknown allowed_updates name: " <> name }
    }
  })
}
