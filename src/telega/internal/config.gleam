import gleam/int
import gleam/option.{type Option}
import telega/internal/fetch.{type TelegramFetchConfig, TelegramFetchConfig}

const telegram_url = "https://api.telegram.org/bot"

const default_retry_count = 3

pub type Config {
  Config(
    server_url: String,
    webhook_path: String,
    /// String to compare with X-Telegram-Bot-Api-Secret-Token
    secret_token: String,
    api: TelegramFetchConfig,
  )
}

/// Simplify the creation of a new config.
///
/// If `secret_token` is not provided, a random one will be generated.
pub fn new(
  token token: String,
  url server_url: String,
  webhook_path webhook_path: String,
  secret_token secret_token: Option(String),
) {
  let secret_token =
    option.lazy_unwrap(secret_token, fn() {
      int.random(10_000_000)
      |> int.to_string
    })

  Config(
    server_url:,
    webhook_path:,
    secret_token:,
    api: fetch.new_config(
      token:,
      max_retry_attempts: default_retry_count,
      tg_api_url: telegram_url,
    ),
  )
}
