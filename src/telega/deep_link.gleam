//// Deep-linking helpers: build `t.me` links that open the bot with a
//// `/start` payload and read that payload back in the command handler.
////
//// Telegram restricts start payloads to `A-Za-z0-9_-`, at most 64
//// characters. To carry arbitrary data (user ids, referral codes with
//// separators, unicode), pair `encode_payload`/`decode_payload` — they wrap
//// the data in URL-safe base64, which fits the allowed alphabet.
////
//// ```gleam
//// // Somewhere a link is generated:
//// let assert Ok(link) = deep_link.encoded_start_link_for_bot(ctx.bot_info, "ref:42")
//// // -> "https://t.me/my_bot?start=cmVmOjQy"
////
//// // In the /start handler:
//// fn start_handler(ctx, command: update.Command) {
////   case deep_link.decoded_payload_from_command(command) {
////     Ok(Some(data)) -> reply.with_text(ctx, "Referred by: " <> data)
////     _ -> reply.with_text(ctx, "Hello!")
////   }
//// }
//// ```

import gleam/bit_array
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import telega/model/types.{type User}
import telega/update

/// Telegram allows at most 64 characters in a start payload.
pub const max_payload_length = 64

/// Raw data longer than 48 bytes does not fit into 64 characters once
/// base64-encoded.
pub const max_data_length = 48

pub type DeepLinkError {
  /// Payload (or data passed to `encode_payload`) exceeds the Telegram
  /// limit; `actual` is the offending length.
  PayloadTooLong(actual: Int)
  /// Payload is empty or contains characters outside `A-Za-z0-9_-`,
  /// or cannot be decoded back from base64.
  InvalidPayloadCharacters(payload: String)
  /// The bot has no username, so no `t.me` link can be built.
  MissingBotUsername
}

/// Checks that a payload matches the Telegram deep-linking rules:
/// 1 to 64 characters from `A-Za-z0-9_-`. Returns the payload unchanged.
pub fn validate_payload(
  payload payload: String,
) -> Result(String, DeepLinkError) {
  let length = string.length(payload)
  case length {
    0 -> Error(InvalidPayloadCharacters(payload:))
    _ if length > max_payload_length -> Error(PayloadTooLong(actual: length))
    _ ->
      case
        payload
        |> string.to_utf_codepoints
        |> list.all(is_allowed_codepoint)
      {
        True -> Ok(payload)
        False -> Error(InvalidPayloadCharacters(payload:))
      }
  }
}

/// Encodes arbitrary data into a payload that fits the Telegram alphabet
/// (URL-safe base64 without padding). Data must be at most 48 bytes,
/// otherwise the encoded payload would not fit into 64 characters.
pub fn encode_payload(data data: String) -> Result(String, DeepLinkError) {
  let bytes = bit_array.from_string(data)
  let size = bit_array.byte_size(bytes)
  case size {
    0 -> Error(InvalidPayloadCharacters(payload: data))
    _ if size > max_data_length -> Error(PayloadTooLong(actual: size))
    _ -> Ok(bit_array.base64_url_encode(bytes, False))
  }
}

/// Decodes a payload produced by `encode_payload` back to the original data.
pub fn decode_payload(
  payload payload: String,
) -> Result(String, DeepLinkError) {
  payload
  |> bit_array.base64_url_decode
  |> result.try(bit_array.to_string)
  |> result.replace_error(InvalidPayloadCharacters(payload:))
}

/// Builds `https://t.me/<username>?start=<payload>` — opens a private chat
/// with the bot and suggests pressing Start; the payload arrives in the
/// `/start` command. A leading `@` in the username is ignored.
pub fn start_link(
  username username: String,
  payload payload: String,
) -> Result(String, DeepLinkError) {
  use username <- result.try(normalize_username(username))
  use payload <- result.try(validate_payload(payload))
  Ok("https://t.me/" <> username <> "?start=" <> payload)
}

/// Builds `https://t.me/<username>?startgroup=<payload>` — prompts the user
/// to pick a group to add the bot to; the payload arrives in `/start`.
pub fn start_group_link(
  username username: String,
  payload payload: String,
) -> Result(String, DeepLinkError) {
  use username <- result.try(normalize_username(username))
  use payload <- result.try(validate_payload(payload))
  Ok("https://t.me/" <> username <> "?startgroup=" <> payload)
}

/// Builds `https://t.me/<username>/<app_name>?startapp=<payload>` — opens a
/// Mini App directly. Without a payload the `startapp` parameter is omitted.
pub fn start_app_link(
  username username: String,
  app_name app_name: String,
  payload payload: Option(String),
) -> Result(String, DeepLinkError) {
  use username <- result.try(normalize_username(username))
  let base = "https://t.me/" <> username <> "/" <> app_name
  case payload {
    None -> Ok(base)
    Some(payload) -> {
      use payload <- result.try(validate_payload(payload))
      Ok(base <> "?startapp=" <> payload)
    }
  }
}

/// Like `start_link`, but encodes arbitrary data with `encode_payload`
/// first — one call instead of encode + link.
pub fn encoded_start_link(
  username username: String,
  data data: String,
) -> Result(String, DeepLinkError) {
  use payload <- result.try(encode_payload(data))
  start_link(username:, payload:)
}

/// Like `start_group_link`, but encodes arbitrary data with
/// `encode_payload` first.
pub fn encoded_start_group_link(
  username username: String,
  data data: String,
) -> Result(String, DeepLinkError) {
  use payload <- result.try(encode_payload(data))
  start_group_link(username:, payload:)
}

/// Like `start_link`, but takes the bot's `User` (e.g. `ctx.bot_info`) and
/// fails with `MissingBotUsername` when the bot has no username.
pub fn start_link_for_bot(
  bot_info bot_info: User,
  payload payload: String,
) -> Result(String, DeepLinkError) {
  use username <- result.try(bot_username(bot_info))
  start_link(username:, payload:)
}

/// Like `start_group_link`, but takes the bot's `User` (e.g. `ctx.bot_info`).
pub fn start_group_link_for_bot(
  bot_info bot_info: User,
  payload payload: String,
) -> Result(String, DeepLinkError) {
  use username <- result.try(bot_username(bot_info))
  start_group_link(username:, payload:)
}

/// Like `start_app_link`, but takes the bot's `User` (e.g. `ctx.bot_info`).
pub fn start_app_link_for_bot(
  bot_info bot_info: User,
  app_name app_name: String,
  payload payload: Option(String),
) -> Result(String, DeepLinkError) {
  use username <- result.try(bot_username(bot_info))
  start_app_link(username:, app_name:, payload:)
}

/// Encodes arbitrary data and builds a start link for the bot — the closest
/// analog of aiogram's `create_start_link(bot, data, encode=True)`:
///
/// ```gleam
/// let assert Ok(link) = deep_link.encoded_start_link_for_bot(ctx.bot_info, "ref:42")
/// ```
pub fn encoded_start_link_for_bot(
  bot_info bot_info: User,
  data data: String,
) -> Result(String, DeepLinkError) {
  use payload <- result.try(encode_payload(data))
  start_link_for_bot(bot_info:, payload:)
}

/// Encodes arbitrary data and builds a group start link for the bot.
pub fn encoded_start_group_link_for_bot(
  bot_info bot_info: User,
  data data: String,
) -> Result(String, DeepLinkError) {
  use payload <- result.try(encode_payload(data))
  start_group_link_for_bot(bot_info:, payload:)
}

/// Extracts the raw `/start` payload from a command, normalizing the empty
/// payload of a bare `/start` to `None`.
pub fn payload_from_command(command command: update.Command) -> Option(String) {
  case command.payload {
    Some("") | None -> None
    Some(payload) -> Some(payload)
  }
}

/// Extracts and base64-decodes the payload of a command produced by an
/// `encode_payload`-built link. `Ok(None)` means there was no payload.
pub fn decoded_payload_from_command(
  command command: update.Command,
) -> Result(Option(String), DeepLinkError) {
  case payload_from_command(command) {
    None -> Ok(None)
    Some(payload) -> decode_payload(payload) |> result.map(Some)
  }
}

fn bot_username(bot_info: User) -> Result(String, DeepLinkError) {
  case bot_info.username {
    Some(username) -> Ok(username)
    None -> Error(MissingBotUsername)
  }
}

fn normalize_username(username: String) -> Result(String, DeepLinkError) {
  let username = case username {
    "@" <> rest -> rest
    _ -> username
  }
  case username {
    "" -> Error(MissingBotUsername)
    _ -> Ok(username)
  }
}

fn is_allowed_codepoint(codepoint: UtfCodepoint) -> Bool {
  let code = string.utf_codepoint_to_int(codepoint)
  { code >= 0x41 && code <= 0x5A }
  || { code >= 0x61 && code <= 0x7A }
  || { code >= 0x30 && code <= 0x39 }
  || code == 0x5F
  || code == 0x2D
}
