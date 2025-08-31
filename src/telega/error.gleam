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
