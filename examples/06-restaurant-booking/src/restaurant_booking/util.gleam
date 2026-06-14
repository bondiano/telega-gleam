import envoy
import gleam/int
import gleam/result
import gleam/string
import logging
import sqlight

import telega/flow/types
import telega/keyboard
import telega/storage
import telega_storage_sqlite as sqlite

import restaurant_booking/i18n

/// Log an info message
pub fn log(message: String) -> Nil {
  logging.log(logging.Info, message)
}

/// Log an error message
pub fn log_error(message: String) -> Nil {
  logging.log(logging.Error, message)
}

/// Log a debug message
pub fn log_debug(message: String) -> Nil {
  logging.log(logging.Debug, message)
}

/// Log a warning message
pub fn log_warning(message: String) -> Nil {
  logging.log(logging.Warning, message)
}

/// Build flow storage from the SQLite key-value adapter.
///
/// No hand-written storage code: `telega_storage_sqlite` implements the
/// `KeyValueStorage` contract, and `storage.flow_storage_from_storage` derives
/// the `FlowStorage` from it. We only adapt the error type to `String` to match
/// the example's flow error type.
pub fn create_database_storage(
  db: sqlight.Connection,
) -> types.FlowStorage(String) {
  sqlite.new(db)
  |> with_string_errors
  |> storage.flow_storage_from_storage
}

fn with_string_errors(
  kv: storage.KeyValueStorage(e),
) -> storage.KeyValueStorage(String) {
  storage.KeyValueStorage(
    get: fn(key) { kv.get(key) |> result.map_error(string.inspect) },
    set: fn(key, value) {
      kv.set(key, value) |> result.map_error(string.inspect)
    },
    set_with_ttl: fn(key, value, ttl) {
      kv.set_with_ttl(key, value, ttl) |> result.map_error(string.inspect)
    },
    delete: fn(key) { kv.delete(key) |> result.map_error(string.inspect) },
    scan: fn(prefix) { kv.scan(prefix) |> result.map_error(string.inspect) },
  )
}

/// Get restaurant name from environment
pub fn get_restaurant_name() -> String {
  envoy.get("RESTAURANT_NAME")
  |> result.unwrap("Bella Vista Restaurant")
}

/// Create a confirmation keyboard with Yes/No buttons
pub fn yes_no_keyboard(id: String) -> keyboard.InlineKeyboard {
  let callback_data = keyboard.bool_callback_data(id)

  let assert Ok(yes_button) =
    keyboard.inline_button(
      i18n.tr("common.yes", []),
      keyboard.pack_callback(callback_data, True),
    )

  let assert Ok(no_button) =
    keyboard.inline_button(
      i18n.tr("common.no", []),
      keyboard.pack_callback(callback_data, False),
    )

  keyboard.new_inline([[yes_button, no_button]])
}

/// Generate a confirmation code
pub fn generate_confirmation_code() -> String {
  "RES" <> string.pad_start(int.to_string(int.random(99_999)), to: 5, with: "0")
}

/// Get table location based on table number
pub fn get_table_location(table_num: Int) -> String {
  case table_num {
    n if n <= 5 -> "window side"
    n if n <= 10 -> "terrace view"
    _ -> "main dining area"
  }
}

/// Get table number based on guest count
pub fn get_table_for_guests(guests: Int) -> Int {
  case guests {
    // Small tables 1-5
    n if n <= 2 -> int.random(5) + 1
    // Medium tables 6-10
    n if n <= 4 -> int.random(5) + 6
    // Large tables 11-13
    _ -> int.random(3) + 11
  }
}
