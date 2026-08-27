import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

import telega/model/decoder
import telega/model/types
import telega/update

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

// Bot API 10.2: RichText is a recursive union mixing bare strings, arrays,
// and `type`-tagged records — decoded by the hand-written rich_text_decoder.
pub fn rich_text_decoder_recursive_test() {
  let body =
    "[\"Hello, \", {\"type\": \"bold\", \"text\": {\"type\": \"url\", \"text\": \"link\", \"url\": \"https://example.com\"}}]"

  let assert Ok(types.ListRichText([first, second])) =
    json.parse(body, decoder.rich_text_decoder())

  first |> should.equal(types.StringRichText("Hello, "))
  let assert types.RichTextBoldRichText(bold) = second
  let assert types.RichTextUrlRichText(url) = bold.text
  url.url |> should.equal("https://example.com")
  url.text |> should.equal(types.StringRichText("link"))
}

pub fn rich_message_decoder_test() {
  let body =
    "{\"blocks\": [{\"type\": \"paragraph\", \"text\": \"plain\"}], \"is_rtl\": true}"

  let assert Ok(rich_message) = json.parse(body, decoder.rich_message_decoder())

  rich_message.is_rtl |> should.equal(Some(True))
  let assert [types.RichBlockParagraphRichBlock(paragraph)] =
    rich_message.blocks
  paragraph.text |> should.equal(types.StringRichText("plain"))
}

// Bot API 10.3: a user stopping the generation of a message draft arrives as a
// top-level `stopped_message_generation` update.
pub fn message_generation_stopped_update_decoder_test() {
  let body =
    "{
      \"update_id\": 42,
      \"stopped_message_generation\": {
        \"chat\": {\"id\": 100, \"type\": \"private\"},
        \"draft_id\": 7
      }
    }"

  let assert Ok(raw) = json.parse(body, decoder.update_decoder())
  let assert Some(stopped) = raw.stopped_message_generation
  stopped.draft_id |> should.equal(7)
  stopped.chat.id |> should.equal(100)
  stopped.message_thread_id |> should.equal(None)

  let assert update.MessageGenerationStoppedUpdate(chat_id:, from_id:, ..) =
    update.raw_to_update(raw)
  chat_id |> should.equal(100)
  from_id |> should.equal(-1)
}

// Bot API 10.3: inline buttons can be disabled, and both markups can force a
// reply from the user.
pub fn disabled_inline_button_decoder_test() {
  let body =
    "{
      \"inline_keyboard\": [[{\"text\": \"Sold out\", \"disabled\": {}}]],
      \"force_reply\": true
    }"

  let assert Ok(markup) =
    json.parse(body, decoder.inline_keyboard_markup_decoder())
  markup.force_reply |> should.equal(Some(True))
  let assert [[button]] = markup.inline_keyboard
  button.disabled |> should.equal(Some(types.DisabledButton))
}
