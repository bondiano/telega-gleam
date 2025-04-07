import gleam/dynamic
import gleam/int
import gleam/json
import gleam/string

pub type TelegaError {
  TelegramApiError(error_code: Int, description: String)

  JsonDecodeError(error: json.DecodeError)
  FetchError(error: dynamic.Dynamic)
  ApiToRequestConvertError

  SetWebhookError
  NoSessionSettingsError
  RegistryStartError(reason: String)
  BotStartError(reason: String)

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
