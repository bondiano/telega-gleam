//// Regression tests for update decoding robustness (C3).
////
//// A single malformed or not-yet-known update must never take the poller down:
//// unknown update kinds decode to `UnknownUpdate`, unknown union variants
//// produce a decode error instead of a panic, and `getUpdates` keeps the
//// updates it *can* read (with the offsets of the ones it cannot).

import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleeunit/should

import gleam/http/response

import telega/api
import telega/client
import telega/model/decoder
import telega/model/types
import telega/testing/factory
import telega/update as update_module

fn empty_raw_update(update_id update_id: Int) -> types.Update {
  types.Update(
    ..factory.raw_update_with(message: factory.message(text: "x"), update_id:),
    message: None,
  )
}

// C3 — unknown / not-yet-supported update kinds -----------------------------

pub fn c3_unknown_update_does_not_panic_test() {
  empty_raw_update(update_id: 1)
  |> update_module.raw_to_update
  |> update_module.type_to_string
  |> should.equal("unknown")
}

pub fn c3_edited_channel_post_is_decoded_test() {
  let post = factory.message(text: "edited post")
  types.Update(
    ..empty_raw_update(update_id: 2),
    edited_channel_post: Some(post),
  )
  |> update_module.raw_to_update
  |> update_module.type_to_string
  |> should.equal("edited_channel_post")
}

pub fn c3_chat_boost_is_decoded_test() {
  let boost =
    types.ChatBoostUpdated(
      chat: factory.chat(),
      boost: types.ChatBoost(
        boost_id: "boost-1",
        add_date: 1,
        expiration_date: 2,
        source: types.ChatBoostSourcePremiumChatBoostSource(
          types.ChatBoostSourcePremium(source: "premium", user: factory.user()),
        ),
      ),
    )

  types.Update(..empty_raw_update(update_id: 3), chat_boost: Some(boost))
  |> update_module.raw_to_update
  |> update_module.type_to_string
  |> should.equal("chat_boost")
}

// C3 — decoders must fail, not panic ----------------------------------------

pub fn c3_unknown_union_variant_is_a_decode_error_test() {
  json.parse(
    "{\"type\": \"brand_new_reaction\"}",
    decoder.reaction_type_decoder(),
  )
  |> should.be_error
}

pub fn c3_integer_coordinates_decode_test() {
  let assert Ok(location) =
    json.parse(
      "{\"latitude\": 51, \"longitude\": 0}",
      decoder.location_decoder(),
    )

  location.latitude |> should.equal(51.0)
  location.longitude |> should.equal(0.0)
}

pub fn c3_inaccessible_message_is_reachable_test() {
  let body =
    "{\"chat\": {\"id\": 1, \"type\": \"private\"}, \"message_id\": 7, \"date\": 0}"

  let assert Ok(decoded) =
    json.parse(body, decoder.maybe_inaccessible_message_decoder())

  case decoded {
    types.InaccessibleMessageMaybeInaccessibleMessage(inaccessible) ->
      inaccessible.message_id |> should.equal(7)
    types.MessageMaybeInaccessibleMessage(_) -> should.fail()
  }
}

// C3 — one broken update must not drop the whole batch ----------------------

pub fn c3_get_updates_keeps_readable_updates_test() {
  let body =
    "{\"ok\": true, \"result\": ["
    <> "{\"update_id\": 10, \"message\": {\"message_id\": 1, \"date\": 1, \"chat\": {\"id\": 5, \"type\": \"private\"}, \"text\": \"hi\"}},"
    <> "{\"update_id\": 11, \"message\": {\"nonsense\": true}},"
    <> "{\"update_id\": 12, \"message\": {\"message_id\": 2, \"date\": 1, \"chat\": {\"id\": 5, \"type\": \"private\"}, \"text\": \"bye\"}}"
    <> "]}"

  let test_client =
    client.new(token: "test_token", fetch_client: fn(_req) {
      Ok(response.new(200) |> response.set_body(body))
    })

  let assert Ok(updates) =
    api.get_updates(client: test_client, parameters: None)

  updates
  |> list.map(fn(update: types.Update) { update.update_id })
  |> should.equal([10, 11, 12])
}
