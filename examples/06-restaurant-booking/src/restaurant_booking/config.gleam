import dot_env
import envoy
import gleam/int
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
  InvalidPortNumber(String)
}

pub fn load() -> Result(Config, String) {
  dot_env.load_default()

  case load_bot_token() {
    Ok(bot_token) -> {
      let db_config = load_database_config()
      let restaurant_name = load_restaurant_name()

      Ok(Config(bot_token:, database: db_config, restaurant_name:))
    }
    Error(MissingBotToken) ->
      Error("BOT_TOKEN environment variable is required")
    Error(InvalidPortNumber(port)) -> Error("Invalid port number: " <> port)
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
    host: envoy.get("PGHOST")
      |> result.unwrap(constants.default_host),
    port: load_port(),
    database: envoy.get("PGDATABASE")
      |> result.unwrap(constants.default_database),
    user: envoy.get("PGUSER")
      |> result.unwrap(constants.default_user),
    password: envoy.get("PGPASSWORD")
      |> result.unwrap(constants.default_password),
    pool_size: load_pool_size(),
  )
}

fn load_port() -> Int {
  envoy.get("PGPORT")
  |> result.try(int.parse)
  |> result.unwrap(constants.default_port)
}

fn load_pool_size() -> Int {
  envoy.get("DB_POOL_SIZE")
  |> result.try(int.parse)
  |> result.map(fn(size) {
    case size >= constants.min_pool_size && size <= constants.max_pool_size {
      True -> size
      False -> constants.default_pool_size
    }
  })
  |> result.unwrap(constants.default_pool_size)
}

fn load_restaurant_name() -> String {
  envoy.get("RESTAURANT_NAME")
  |> result.unwrap(constants.default_restaurant_name)
}
