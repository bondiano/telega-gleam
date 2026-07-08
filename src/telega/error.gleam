import gleam/int
import gleam/json
import gleam/otp/actor
import gleam/string

import telega/model/types.{type Update}

pub type TelegaError {
  /// Returned by Bot API if server returns `ok: false`, indicating that your API request was invalid and failed
  TelegramApiError(error_code: Int, description: String)
  /// Returned if the Bot API server could not be reached or the request failed
  FetchError(error: String)
  /// Returned if the JSON response from the Bot API could not be decoded
  JsonDecodeError(error: json.DecodeError)

  /// Returned if the bot failed to call `handle_update`
  BotHandleUpdateError(reason: String)

  /// Returned if the bot failed to convert API request to HTTP request
  ApiToRequestConvertError
  SetWebhookError
  NoSessionSettingsError

  // Start errors
  RegistryStartError(reason: String)
  BotStartError(reason: actor.StartError)
  ChatInstanceStartError(reason: actor.StartError)

  FileNotFoundError

  DecodeUpdateError(reason: String)

  /// Occurs when the update is not handled by any handler
  UnknownUpdateError(update: Update)

  /// General actor error (e.g., from polling)
  ActorError(reason: String)

  RouterError(reason: String)

  // Supervision errors
  SupervisorStartError(reason: actor.StartError)
  ShutdownError(reason: String)
}

pub fn to_string(error: TelegaError) -> String {
  case error {
    TelegramApiError(error_code, description) ->
      "Telegram API error: " <> int.to_string(error_code) <> " " <> description
    JsonDecodeError(error) -> "Decode JSON error: " <> string.inspect(error)
    ApiToRequestConvertError -> "Failed to convert API request to HTTP request"
    FetchError(error) -> "Failed to send request: " <> string.inspect(error)
    SetWebhookError -> "Failed to set webhook"
    NoSessionSettingsError -> "Session settings not initialized"
    RegistryStartError(reason) -> "Failed to start registry: " <> reason
    BotStartError(reason) -> "Failed to start bot: " <> string.inspect(reason)
    ChatInstanceStartError(reason) ->
      "Failed to start chat instance: " <> string.inspect(reason)
    FileNotFoundError -> "File not found"
    DecodeUpdateError(reason) -> "Failed to decode update: " <> reason
    BotHandleUpdateError(reason) -> "Failed to handle update: " <> reason
    UnknownUpdateError(update) -> "Unknown update: " <> string.inspect(update)
    ActorError(reason) -> "Actor error: " <> reason
    RouterError(reason) -> "Router error: " <> reason
    SupervisorStartError(reason) ->
      "Failed to start supervisor: " <> string.inspect(reason)
    ShutdownError(reason) -> "Shutdown error: " <> reason
  }
}

/// The edit was a no-op: new content equals the current one. Safe to treat
/// as success.
///
/// The Bot API has no structured error codes, so a case-insensitive substring
/// match on the 400 description is the only way to classify this error.
pub fn is_message_not_modified(error error: TelegaError) -> Bool {
  is_400_with(error, "message is not modified")
}

/// The message to edit no longer exists (deleted by the user or too old).
///
/// The Bot API has no structured error codes, so a case-insensitive substring
/// match on the 400 description is the only way to classify this error.
pub fn is_message_not_found(error error: TelegaError) -> Bool {
  is_400_with(error, "message to edit not found")
}

/// The message exists but cannot be edited (e.g. not sent by the bot).
///
/// The Bot API has no structured error codes, so a case-insensitive substring
/// match on the 400 description is the only way to classify this error.
pub fn is_message_cant_be_edited(error error: TelegaError) -> Bool {
  is_400_with(error, "message can't be edited")
}

fn is_400_with(error: TelegaError, needle: String) -> Bool {
  case error {
    TelegramApiError(error_code: 400, description:) ->
      string.contains(string.lowercase(description), needle)
    _ -> False
  }
}

/// Helper to replace `result.try` for api call and error mapping.
pub fn try(
  result: Result(a, TelegaError),
  to to_error: fn(TelegaError) -> e,
  fun fun: fn(a) -> Result(b, e),
) -> Result(b, e) {
  case result {
    Ok(x) -> fun(x)
    Error(e) -> Error(to_error(e))
  }
}
