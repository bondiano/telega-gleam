import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

import telega/model/decoder

pub fn main() {
  gleeunit.main()
}

// Regression test for https://github.com/bondiano/telega-gleam/issues/42
// /getMe responses omit Option fields entirely (rather than sending null),
// so the decoder must use optional_field, not field+optional.
pub fn user_decoder_omitted_optional_fields_test() {
  let body =
    "{
      \"id\": 5453349465,
      \"is_bot\": true,
      \"first_name\": \"test bot\",
      \"username\": \"testalpacabot\",
      \"can_join_groups\": true,
      \"can_read_all_group_messages\": true,
      \"supports_inline_queries\": false,
      \"can_connect_to_business\": false,
      \"has_main_web_app\": false,
      \"has_topics_enabled\": false,
      \"allows_users_to_create_topics\": false,
      \"can_manage_bots\": false
    }"

  let assert Ok(user) = json.parse(body, decoder.user_decoder())

  user.id |> should.equal(5_453_349_465)
  user.is_bot |> should.equal(True)
  user.first_name |> should.equal("test bot")
  user.username |> should.equal(Some("testalpacabot"))
  user.last_name |> should.equal(None)
  user.language_code |> should.equal(None)
  user.is_premium |> should.equal(None)
  user.added_to_attachment_menu |> should.equal(None)
}

pub fn user_decoder_null_optional_fields_test() {
  let body =
    "{
      \"id\": 1,
      \"is_bot\": false,
      \"first_name\": \"Alice\",
      \"last_name\": null,
      \"language_code\": null
    }"

  let assert Ok(user) = json.parse(body, decoder.user_decoder())

  user.first_name |> should.equal("Alice")
  user.last_name |> should.equal(None)
  user.language_code |> should.equal(None)
}

pub fn user_decoder_present_optional_fields_test() {
  let body =
    "{
      \"id\": 1,
      \"is_bot\": false,
      \"first_name\": \"Alice\",
      \"last_name\": \"Smith\",
      \"language_code\": \"en\",
      \"is_premium\": true
    }"

  let assert Ok(user) = json.parse(body, decoder.user_decoder())

  user.last_name |> should.equal(Some("Smith"))
  user.language_code |> should.equal(Some("en"))
  user.is_premium |> should.equal(Some(True))
}

// Regression: Telegram sends "type" but the Gleam field is named `type_`
// (reserved word). The decoder must read the JSON key "type", not "type_".
pub fn chat_decoder_type_field_test() {
  let body =
    "{
      \"id\": 123,
      \"type\": \"private\",
      \"first_name\": \"Alice\"
    }"

  let assert Ok(chat) = json.parse(body, decoder.chat_decoder())

  chat.id |> should.equal(123)
  chat.type_ |> should.equal("private")
  chat.first_name |> should.equal(Some("Alice"))
}

pub fn message_decoder_with_entities_test() {
  let body =
    "{
      \"message_id\": 1,
      \"date\": 1700000000,
      \"chat\": {\"id\": 42, \"type\": \"private\", \"first_name\": \"Alice\"},
      \"text\": \"/start\",
      \"entities\": [{\"type\": \"bot_command\", \"offset\": 0, \"length\": 6}]
    }"

  let assert Ok(message) = json.parse(body, decoder.message_decoder())

  message.message_id |> should.equal(1)
  message.text |> should.equal(Some("/start"))
  case message.entities {
    Some([entity]) -> entity.type_ |> should.equal("bot_command")
    _ -> panic as "expected exactly one entity"
  }
}
