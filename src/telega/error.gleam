import gleam/dynamic
import gleam/int
import gleam/json
import gleam/string

pub type TelegaError {
  /// Returned by Bot API if server returns `ok: false`, indicating that your API request was invalid and failed
  TelegramApiError(error_code: Int, description: String)
  /// Returned if the Bot API server could not be reached or the request failed
  FetchError(error: dynamic.Dynamic)
  /// Returned if the JSON response from the Bot API could not be decoded
  JsonDecodeError(error: json.DecodeError)

  ApiToRequestConvertError
  SetWebhookError
  NoSessionSettingsError

  RegistryStartError(reason: String)
  BotStartError(reason: String)
  ChatInstanceStartError(reason: String)

  FileNotFoundError
}

pub fn to_string(error) {
  case error {
    TelegramApiError(error_code, description) ->
      "Telegram API error: " <> int.to_string(error_code) <> " " <> description
    JsonDecodeError(error) -> "Decode JSON error: " <> string.inspect(error)
    ApiToRequestConvertError -> "Failed to convert API request to HTTP request"
    FetchError(error) -> "Failed to send request: " <> string.inspect(error)
    SetWebhookError -> "Failed to set webhook"
    NoSessionSettingsError -> "Session settings not initialized"
    RegistryStartError(reason) -> "Failed to start registry: " <> reason
    BotStartError(reason) -> "Failed to start bot: " <> reason
    ChatInstanceStartError(reason) ->
      "Failed to start chat instance: " <> reason
    FileNotFoundError -> "File not found"
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
