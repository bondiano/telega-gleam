import envoy
import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import logging
import pog
import restaurant_booking/sql
import telega/flow
import telega/keyboard

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

/// Parse JSON data back to dict using gleam/json
fn parse_json_to_dict(json_str: String) -> dict.Dict(String, String) {
  case string.trim(json_str) {
    "{}" -> dict.new()
    "" -> dict.new()
    _ -> {
      case json.parse(json_str, decode.dict(decode.string, decode.string)) {
        Ok(parsed_dict) -> parsed_dict
        Error(_) -> dict.new()
      }
    }
  }
}

fn db_row_to_flow_instance(row: sql.LoadFlowInstanceRow) -> flow.FlowInstance {
  let state_data = parse_json_to_dict(option.unwrap(row.state_data, "{}"))
  let scene_data = parse_json_to_dict(option.unwrap(row.scene_data, "{}"))

  flow.FlowInstance(
    id: row.id,
    flow_name: row.flow_name,
    user_id: row.user_id,
    chat_id: row.chat_id,
    state: flow.FlowState(
      current_step: row.current_step,
      data: state_data,
      history: [],
      flow_stack: [],
      parallel_state: None,
    ),
    scene_data: scene_data,
    wait_token: row.wait_token,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

/// Convert list database rows to FlowInstance list
fn db_rows_to_flow_instances(
  rows: List(sql.ListUserInstancesRow),
) -> List(flow.FlowInstance) {
  rows
  |> list.map(fn(row) {
    let state_data = parse_json_to_dict(option.unwrap(row.state_data, "{}"))
    let scene_data = parse_json_to_dict(option.unwrap(row.scene_data, "{}"))

    flow.FlowInstance(
      id: row.id,
      flow_name: row.flow_name,
      user_id: row.user_id,
      chat_id: row.chat_id,
      state: flow.FlowState(
        current_step: row.current_step,
        data: state_data,
        history: [],
        flow_stack: [],
        parallel_state: None,
      ),
      scene_data: scene_data,
      wait_token: row.wait_token,
      created_at: row.created_at,
      updated_at: row.updated_at,
    )
  })
}

/// Create real database storage for flow persistence
pub fn create_database_storage(db: pog.Connection) -> flow.FlowStorage(String) {
  flow.FlowStorage(
    save: fn(instance) {
      // Convert flow state data to JSON
      let state_data_json =
        json.object(
          instance.state.data
          |> dict.to_list
          |> list.map(fn(pair) { #(pair.0, json.string(pair.1)) }),
        )

      // Convert scene data to JSON (if exists)
      let scene_data_json = case dict.size(instance.scene_data) {
        0 -> json.null()
        _ ->
          json.object(
            instance.scene_data
            |> dict.to_list
            |> list.map(fn(pair) { #(pair.0, json.string(pair.1)) }),
          )
      }

      case
        sql.save_flow_instance(
          db,
          instance.id,
          instance.flow_name,
          instance.user_id,
          instance.chat_id,
          instance.state.current_step,
          state_data_json,
          scene_data_json,
          option.unwrap(instance.wait_token, ""),
        )
      {
        Ok(_) -> Ok(Nil)
        Error(err) ->
          Error("Failed to save flow instance: " <> string.inspect(err))
      }
    },
    load: fn(id) {
      case sql.load_flow_instance(db, id) {
        Ok(pog.Returned(count: _, rows: [row])) ->
          Ok(Some(db_row_to_flow_instance(row)))
        Ok(pog.Returned(count: _, rows: [])) -> Ok(None)
        Ok(pog.Returned(count: _, rows: [first_row, ..])) ->
          Ok(Some(db_row_to_flow_instance(first_row)))
        Error(err) ->
          Error("Failed to load flow instance: " <> string.inspect(err))
      }
    },
    delete: fn(id) {
      case sql.delete_flow_instance(db, id) {
        Ok(_) -> Ok(Nil)
        Error(err) ->
          Error("Failed to delete flow instance: " <> string.inspect(err))
      }
    },
    list_by_user: fn(user_id, chat_id) {
      case sql.list_user_instances(db, user_id, chat_id) {
        Ok(pog.Returned(count: _, rows: rows)) ->
          Ok(db_rows_to_flow_instances(rows))
        Error(err) ->
          Error("Failed to list user flow instances: " <> string.inspect(err))
      }
    },
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
    keyboard.inline_button("✅ Yes", keyboard.pack_callback(callback_data, True))

  let assert Ok(no_button) =
    keyboard.inline_button("❌ No", keyboard.pack_callback(callback_data, False))

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

/// Create a new FlowInstance with minimal required fields
/// Other fields will be set to sensible defaults
pub fn create_flow_instance(
  id: String,
  flow_name: String, 
  user_id: Int,
  chat_id: Int,
  current_step: String,
) -> flow.FlowInstance {
  flow.FlowInstance(
    id: id,
    flow_name: flow_name,
    user_id: user_id,
    chat_id: chat_id,
    state: flow.FlowState(
      current_step: current_step,
      data: dict.new(),
      history: [current_step],
      flow_stack: [],
      parallel_state: None,
    ),
    scene_data: dict.new(),
    wait_token: None,
    created_at: unix_timestamp(),
    updated_at: unix_timestamp(),
  )
}

/// Create a FlowInstance with initial data
pub fn create_flow_instance_with_data(
  id: String,
  flow_name: String,
  user_id: Int,
  chat_id: Int,
  current_step: String,
  initial_data: dict.Dict(String, String),
) -> flow.FlowInstance {
  flow.FlowInstance(
    id: id,
    flow_name: flow_name,
    user_id: user_id,
    chat_id: chat_id,
    state: flow.FlowState(
      current_step: current_step,
      data: initial_data,
      history: [current_step],
      flow_stack: [],
      parallel_state: None,
    ),
    scene_data: dict.new(),
    wait_token: None,
    created_at: unix_timestamp(),
    updated_at: unix_timestamp(),
  )
}

/// Create a FlowInstance with both initial data and scene data
pub fn create_full_flow_instance(
  id: String,
  flow_name: String,
  user_id: Int,
  chat_id: Int,
  current_step: String,
  initial_data: dict.Dict(String, String),
  scene_data: dict.Dict(String, String),
  wait_token: option.Option(String),
) -> flow.FlowInstance {
  flow.FlowInstance(
    id: id,
    flow_name: flow_name,
    user_id: user_id,
    chat_id: chat_id,
    state: flow.FlowState(
      current_step: current_step,
      data: initial_data,
      history: [current_step],
      flow_stack: [],
      parallel_state: None,
    ),
    scene_data: scene_data,
    wait_token: wait_token,
    created_at: unix_timestamp(),
    updated_at: unix_timestamp(),
  )
}

/// Generate a flow instance ID based on user, chat, and flow name
pub fn generate_flow_id(user_id: Int, chat_id: Int, flow_name: String) -> String {
  flow_name <> "_" <> int.to_string(chat_id) <> "_" <> int.to_string(user_id)
}

/// Get current unix timestamp
fn unix_timestamp() -> Int {
  // Simple timestamp - in real implementation you might want to use proper time functions
  int.random(1_000_000_000) + 1_640_000_000
}
