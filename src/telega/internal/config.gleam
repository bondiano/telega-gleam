import gleam/option.{type Option}

import telega/client.{type TelegramClient}
import telega/internal/utils

pub type Config {
  Config(
    server_url: String,
    webhook_path: String,
    /// String to compare with X-Telegram-Bot-Api-Secret-Token
    secret_token: String,
    api_client: TelegramClient,
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
    option.lazy_unwrap(secret_token, fn() { utils.random_string(64) })

  Config(
    server_url:,
    webhook_path:,
    secret_token:,
    api_client: client.new(token),
  )
}
