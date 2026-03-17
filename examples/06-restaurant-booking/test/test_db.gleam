//// Test database helper for integration tests.
//// Uses a separate test database to avoid conflicts with development.

import gleam/erlang/process
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import pog

import restaurant_booking/constants

const test_database = "restaurant_booking_test"

/// Attempts to connect to the test database.
/// Returns Ok(connection) on success, Error(reason) if DB is unavailable.
/// Verifies connectivity with a simple query before returning.
pub fn try_connect() -> Result(pog.Connection, String) {
  let pool_name = process.new_name(constants.pool_name_prefix <> "_test")

  let pog_config =
    pog.default_config(pool_name)
    |> pog.database(test_database)
    |> pog.user(constants.default_user)
    |> pog.password(None)
    |> pog.host(constants.default_host)
    |> pog.port(constants.default_port)
    |> pog.pool_size(2)
    |> pog.queue_target(500)
    |> pog.queue_interval(1000)

  case pog.start(pog_config) {
    Ok(_) -> {
      let db = pog.named_connection(pool_name)
      // Verify actual connectivity with a simple query
      case pog.query("SELECT 1") |> pog.execute(db) {
        Ok(_) -> Ok(db)
        Error(err) ->
          Error("Test database not reachable: " <> string.inspect(err))
      }
    }
    Error(err) ->
      Error("Failed to start test database pool: " <> string.inspect(err))
  }
}

/// Sets up the test database schema.
pub fn setup(db: pog.Connection) -> Nil {
  let statements = [
    "CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      telegram_id BIGINT UNIQUE NOT NULL,
      chat_id BIGINT NOT NULL,
      name VARCHAR(255) NOT NULL,
      phone VARCHAR(20) NOT NULL,
      email VARCHAR(255),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )",
    "CREATE TABLE IF NOT EXISTS restaurant_tables (
      id SERIAL PRIMARY KEY,
      table_number INT UNIQUE NOT NULL,
      capacity INT NOT NULL,
      location VARCHAR(50),
      is_available BOOLEAN DEFAULT true
    )",
    "CREATE TABLE IF NOT EXISTS bookings (
      id SERIAL PRIMARY KEY,
      user_id INT REFERENCES users(id),
      table_id INT REFERENCES restaurant_tables(id),
      booking_date DATE NOT NULL,
      booking_time TIME NOT NULL,
      guests INT NOT NULL,
      special_requests TEXT,
      status VARCHAR(20) DEFAULT 'pending',
      confirmation_code VARCHAR(10) UNIQUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(table_id, booking_date, booking_time)
    )",
    "CREATE TABLE IF NOT EXISTS flow_instances (
      id VARCHAR(255) PRIMARY KEY,
      flow_name VARCHAR(100) NOT NULL,
      user_id BIGINT NOT NULL,
      chat_id BIGINT NOT NULL,
      current_step VARCHAR(100) NOT NULL,
      state_data JSONB,
      scene_data JSONB,
      wait_token VARCHAR(255),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )",
    "CREATE INDEX IF NOT EXISTS idx_flow_user ON flow_instances (user_id, chat_id)",
    "CREATE INDEX IF NOT EXISTS idx_flow_token ON flow_instances (wait_token)",
    "INSERT INTO restaurant_tables (table_number, capacity, location) VALUES
      (1, 2, 'window'), (2, 2, 'window'), (3, 4, 'center'),
      (4, 4, 'center'), (5, 6, 'center'), (6, 2, 'terrace'),
      (7, 4, 'terrace'), (8, 8, 'terrace')
    ON CONFLICT (table_number) DO NOTHING",
  ]

  list.each(statements, fn(sql) {
    case pog.query(sql) |> pog.execute(db) {
      Ok(_) -> Nil
      Error(err) -> {
        io.println("Schema setup note: " <> string.inspect(err))
        Nil
      }
    }
  })
}

/// Truncates all data tables, preserving the schema and restaurant_tables seed data.
pub fn cleanup(db: pog.Connection) -> Nil {
  let tables = ["flow_instances", "bookings", "users"]
  list.each(tables, fn(table) {
    let sql = "TRUNCATE TABLE " <> table <> " RESTART IDENTITY CASCADE"
    case pog.query(sql) |> pog.execute(db) {
      Ok(_) -> Nil
      Error(err) -> {
        io.println("Cleanup warning: " <> string.inspect(err))
        Nil
      }
    }
  })
}

/// Attempts to connect, set up schema, and clean data.
/// Returns Some(connection) if DB is available, None if not.
pub fn try_connect_and_setup() -> option.Option(pog.Connection) {
  case try_connect() {
    Ok(db) -> {
      setup(db)
      cleanup(db)
      Some(db)
    }
    Error(reason) -> {
      io.println("Skipping DB test: " <> reason)
      None
    }
  }
}
