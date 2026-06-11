//// Test database helper for integration tests.
////
//// Uses an in-memory SQLite database, so these tests run without any external
//// service — unlike the previous PostgreSQL setup.

import gleam/option.{type Option, None, Some}
import sqlight

import restaurant_booking/database

/// Open an in-memory SQLite database with the full schema and seed data.
pub fn try_connect_and_setup() -> Option(sqlight.Connection) {
  case sqlight.open(":memory:") {
    Ok(db) ->
      case database.migrate(db) {
        Ok(_) -> Some(db)
        Error(_) -> None
      }
    Error(_) -> None
  }
}

/// Remove all per-test data, keeping the schema and seeded tables.
pub fn cleanup(db: sqlight.Connection) -> Nil {
  let _ =
    sqlight.exec(
      "DELETE FROM bookings; DELETE FROM users; DELETE FROM telega_storage;",
      db,
    )
  Nil
}
