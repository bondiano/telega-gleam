import envoy
import gleam/result

import restaurant_booking/constants
import restaurant_booking/database

pub type Config {
  Config(
    bot_token: String,
    database: database.ConnectionConfig,
    restaurant_name: String,
  )
}

pub type ConfigError {
  MissingBotToken
}

pub fn load() -> Result(Config, String) {
  case load_bot_token() {
    Ok(bot_token) ->
      Ok(Config(
        bot_token:,
        database: load_database_config(),
        restaurant_name: load_restaurant_name(),
      ))
    Error(MissingBotToken) ->
      Error("BOT_TOKEN environment variable is required")
  }
}

fn load_bot_token() -> Result(String, ConfigError) {
  case envoy.get("BOT_TOKEN") {
    Ok(token) -> Ok(token)
    Error(_) -> Error(MissingBotToken)
  }
}

fn load_database_config() -> database.ConnectionConfig {
  database.ConnectionConfig(
    path: envoy.get("DATABASE_PATH")
    |> result.unwrap(constants.default_database_path),
  )
}

fn load_restaurant_name() -> String {
  envoy.get("RESTAURANT_NAME")
  |> result.unwrap(constants.default_restaurant_name)
}
