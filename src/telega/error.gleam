import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/json
import gleam/string

pub type TelegaError {
  TelegramApiError(error_code: Int, description: String)

  JsonDecodeError(error: json.DecodeError)
  FetchError(error: Dynamic)
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
