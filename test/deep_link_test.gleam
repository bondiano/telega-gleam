import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/deep_link.{
  InvalidPayloadCharacters, MissingBotUsername, PayloadTooLong,
}
import telega/model/types.{User}
import telega/update.{Command}

pub fn main() {
  gleeunit.main()
}

fn bot_user(username username) {
  User(
    id: 42,
    is_bot: True,
    first_name: "Telega",
    last_name: None,
    username:,
    language_code: None,
    is_premium: None,
    added_to_attachment_menu: None,
    can_join_groups: None,
    can_read_all_group_messages: None,
    supports_guest_queries: None,
    supports_inline_queries: None,
    can_connect_to_business: None,
    has_main_web_app: None,
    has_topics_enabled: None,
    allows_users_to_create_topics: None,
    can_manage_bots: None,
    supports_join_request_queries: None,
  )
}

// Link formats

pub fn start_link_test() {
  deep_link.start_link(username: "my_bot", payload: "ref-42")
  |> should.equal(Ok("https://t.me/my_bot?start=ref-42"))
}

pub fn start_link_strips_at_sign_test() {
  deep_link.start_link(username: "@my_bot", payload: "abc")
  |> should.equal(Ok("https://t.me/my_bot?start=abc"))
}

pub fn start_link_empty_username_test() {
  deep_link.start_link(username: "", payload: "abc")
  |> should.equal(Error(MissingBotUsername))
}

pub fn start_group_link_test() {
  deep_link.start_group_link(username: "my_bot", payload: "team_1")
  |> should.equal(Ok("https://t.me/my_bot?startgroup=team_1"))
}

pub fn start_app_link_with_payload_test() {
  deep_link.start_app_link(
    username: "my_bot",
    app_name: "shop",
    payload: Some("promo"),
  )
  |> should.equal(Ok("https://t.me/my_bot/shop?startapp=promo"))
}

pub fn start_app_link_without_payload_test() {
  deep_link.start_app_link(username: "my_bot", app_name: "shop", payload: None)
  |> should.equal(Ok("https://t.me/my_bot/shop"))
}

pub fn start_link_for_bot_test() {
  deep_link.start_link_for_bot(
    bot_info: bot_user(username: Some("my_bot")),
    payload: "abc123",
  )
  |> should.equal(Ok("https://t.me/my_bot?start=abc123"))
}

pub fn start_link_for_bot_without_username_test() {
  deep_link.start_link_for_bot(bot_info: bot_user(username: None), payload: "x")
  |> should.equal(Error(MissingBotUsername))
}

pub fn start_group_link_for_bot_test() {
  deep_link.start_group_link_for_bot(
    bot_info: bot_user(username: Some("my_bot")),
    payload: "team_1",
  )
  |> should.equal(Ok("https://t.me/my_bot?startgroup=team_1"))
}

pub fn start_app_link_for_bot_test() {
  deep_link.start_app_link_for_bot(
    bot_info: bot_user(username: Some("my_bot")),
    app_name: "shop",
    payload: Some("promo"),
  )
  |> should.equal(Ok("https://t.me/my_bot/shop?startapp=promo"))

  deep_link.start_app_link_for_bot(
    bot_info: bot_user(username: None),
    app_name: "shop",
    payload: None,
  )
  |> should.equal(Error(MissingBotUsername))
}

// Encoded link helpers

pub fn encoded_start_link_test() {
  let assert Ok(link) =
    deep_link.encoded_start_link(username: "my_bot", data: "ref:42")

  let assert "https://t.me/my_bot?start=" <> payload = link
  deep_link.decode_payload(payload:)
  |> should.equal(Ok("ref:42"))
}

pub fn encoded_start_group_link_test() {
  let assert Ok(link) =
    deep_link.encoded_start_group_link(username: "my_bot", data: "team:7")

  let assert "https://t.me/my_bot?startgroup=" <> payload = link
  deep_link.decode_payload(payload:)
  |> should.equal(Ok("team:7"))
}

pub fn encoded_start_link_for_bot_roundtrip_test() {
  let bot_info = bot_user(username: Some("my_bot"))
  let assert Ok(link) =
    deep_link.encoded_start_link_for_bot(bot_info:, data: "ref:42 юзер")

  // The payload a user's client will send back in `/start <payload>`
  let assert "https://t.me/my_bot?start=" <> payload = link
  Command(text: "/start " <> payload, command: "start", payload: Some(payload))
  |> deep_link.decoded_payload_from_command
  |> should.equal(Ok(Some("ref:42 юзер")))
}

pub fn encoded_start_group_link_for_bot_test() {
  let assert Ok(link) =
    deep_link.encoded_start_group_link_for_bot(
      bot_info: bot_user(username: Some("my_bot")),
      data: "team:7",
    )

  let assert "https://t.me/my_bot?startgroup=" <> payload = link
  deep_link.decode_payload(payload:)
  |> should.equal(Ok("team:7"))
}

pub fn encoded_start_link_for_bot_too_long_test() {
  deep_link.encoded_start_link_for_bot(
    bot_info: bot_user(username: Some("my_bot")),
    data: string.repeat("a", 49),
  )
  |> should.equal(Error(PayloadTooLong(actual: 49)))
}

// Payload validation

pub fn validate_payload_ok_test() {
  deep_link.validate_payload(payload: "AZaz09_-")
  |> should.equal(Ok("AZaz09_-"))
}

pub fn validate_payload_max_length_test() {
  let payload = string.repeat("a", 64)
  deep_link.validate_payload(payload:)
  |> should.equal(Ok(payload))
}

pub fn validate_payload_too_long_test() {
  deep_link.validate_payload(payload: string.repeat("a", 65))
  |> should.equal(Error(PayloadTooLong(actual: 65)))
}

pub fn validate_payload_empty_test() {
  deep_link.validate_payload(payload: "")
  |> should.equal(Error(InvalidPayloadCharacters(payload: "")))
}

pub fn validate_payload_invalid_characters_test() {
  deep_link.validate_payload(payload: "ref:42")
  |> should.equal(Error(InvalidPayloadCharacters(payload: "ref:42")))

  deep_link.validate_payload(payload: "приве")
  |> should.equal(Error(InvalidPayloadCharacters(payload: "приве")))
}

pub fn start_link_rejects_invalid_payload_test() {
  deep_link.start_link(username: "my_bot", payload: "a b")
  |> should.equal(Error(InvalidPayloadCharacters(payload: "a b")))
}

// Encode / decode

pub fn encode_decode_roundtrip_test() {
  let assert Ok(payload) = deep_link.encode_payload(data: "ref:42 юзер")
  deep_link.validate_payload(payload:)
  |> should.equal(Ok(payload))

  deep_link.decode_payload(payload:)
  |> should.equal(Ok("ref:42 юзер"))
}

pub fn encode_payload_48_bytes_test() {
  let data = string.repeat("a", 48)
  let assert Ok(payload) = deep_link.encode_payload(data:)
  string.length(payload) |> should.equal(64)

  deep_link.decode_payload(payload:)
  |> should.equal(Ok(data))
}

pub fn encode_payload_49_bytes_test() {
  deep_link.encode_payload(data: string.repeat("a", 49))
  |> should.equal(Error(PayloadTooLong(actual: 49)))
}

pub fn encode_payload_counts_bytes_not_graphemes_test() {
  // 25 cyrillic characters = 50 bytes in UTF-8
  deep_link.encode_payload(data: string.repeat("ю", 25))
  |> should.equal(Error(PayloadTooLong(actual: 50)))
}

pub fn encode_payload_empty_test() {
  deep_link.encode_payload(data: "")
  |> should.equal(Error(InvalidPayloadCharacters(payload: "")))
}

pub fn decode_payload_invalid_base64_test() {
  deep_link.decode_payload(payload: "@@@")
  |> should.equal(Error(InvalidPayloadCharacters(payload: "@@@")))
}

// Command helpers

pub fn payload_from_command_some_test() {
  Command(text: "/start abc123", command: "start", payload: Some("abc123"))
  |> deep_link.payload_from_command
  |> should.equal(Some("abc123"))
}

pub fn payload_from_command_none_test() {
  Command(text: "/start", command: "start", payload: None)
  |> deep_link.payload_from_command
  |> should.equal(None)

  // A bare `/start` is parsed with an empty payload — treated as no payload
  Command(text: "/start", command: "start", payload: Some(""))
  |> deep_link.payload_from_command
  |> should.equal(None)
}

pub fn decoded_payload_from_command_test() {
  let assert Ok(payload) = deep_link.encode_payload(data: "user:99")

  Command(text: "/start " <> payload, command: "start", payload: Some(payload))
  |> deep_link.decoded_payload_from_command
  |> should.equal(Ok(Some("user:99")))

  Command(text: "/start", command: "start", payload: None)
  |> deep_link.decoded_payload_from_command
  |> should.equal(Ok(None))
}
