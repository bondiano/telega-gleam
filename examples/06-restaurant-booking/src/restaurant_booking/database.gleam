import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/option.{None, Some}
import gleam/string
import pog
import restaurant_booking/constants

pub type ConnectionConfig {
  ConnectionConfig(
    host: String,
    port: Int,
    database: String,
    user: String,
    password: String,
    pool_size: Int,
  )
}

pub fn default_config() -> ConnectionConfig {
  ConnectionConfig(
    host: constants.default_host,
    port: constants.default_port,
    database: constants.default_database,
    user: constants.default_user,
    password: constants.default_password,
    pool_size: constants.default_pool_size,
  )
}

pub fn connect(cfg: ConnectionConfig) -> Result(pog.Connection, String) {
  let pool_name = process.new_name(constants.pool_name_prefix)

  let pog_config =
    pog.default_config(pool_name)
    |> pog.database(cfg.database)
    |> pog.user(cfg.user)
    |> pog.password(case cfg.password {
      "" -> None
      pwd -> Some(pwd)
    })
    |> pog.host(cfg.host)
    |> pog.port(cfg.port)
    |> pog.pool_size(cfg.pool_size)

  case pog.start(pog_config) {
    Ok(_) -> {
      let db = pog.named_connection(pool_name)
      io.println(
        "✅ Connected to PostgreSQL database: "
        <> cfg.database
        <> " at "
        <> cfg.host
        <> ":"
        <> int.to_string(cfg.port),
      )
      case verify_tables(db) {
        Ok(_) -> Ok(db)
        Error(err) -> Error(err)
      }
    }
    Error(err) -> {
      io.println("❌ Database connection failed: " <> string.inspect(err))
      Error("Failed to connect to database: " <> string.inspect(err))
    }
  }
}

fn verify_tables(db: pog.Connection) -> Result(Nil, String) {
  let test_sql = "SELECT COUNT(*) FROM users LIMIT 1"
  case pog.query(test_sql) |> pog.execute(db) {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error("Database tables not ready: " <> string.inspect(err))
  }
}

pub fn connection_url(cfg: ConnectionConfig) -> String {
  let password_part = case cfg.password {
    "" -> ""
    pwd -> ":" <> pwd
  }

  string.concat([
    "postgres://",
    cfg.user,
    password_part,
    "@",
    cfg.host,
    ":",
    int.to_string(cfg.port),
    "/",
    cfg.database,
  ])
}
