//// Instance CRUD, accessors, factories, WaitResult, and serialization.

import gleam/bool
import gleam/dict
import gleam/dynamic/decode.{type Decoder}
import gleam/float
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/bot.{type Context}
import telega/flow/types.{
  type Flow, type FlowInstance, type FlowStackFrame, type FlowState,
  type ParallelState, type StepResult, type WaitResult, AudioInput, BoolCallback,
  CommandInput, DataCallback, FlowInstance, FlowStackFrame, FlowState,
  LocationInput, Next, ParallelState, Pending, PhotoInput, TextInput, VideoInput,
  VoiceInput,
}
import telega/internal/utils

/// Create a new FlowInstance with minimal required fields
pub fn new_instance(
  id id: String,
  flow_name flow_name: String,
  user_id user_id: Int,
  chat_id chat_id: Int,
  current_step current_step: String,
) -> FlowInstance {
  FlowInstance(
    id:,
    flow_name:,
    user_id:,
    chat_id:,
    state: FlowState(
      current_step:,
      data: dict.new(),
      history: [current_step],
      flow_stack: [],
      parallel_state: None,
    ),
    step_data: dict.new(),
    wait_token: None,
    wait_timeout_at: None,
    created_at: utils.current_time_ms(),
    updated_at: utils.current_time_ms(),
  )
}

/// Create a new FlowInstance with initial data
pub fn new_instance_with_data(
  id id: String,
  flow_name flow_name: String,
  user_id user_id: Int,
  chat_id chat_id: Int,
  current_step current_step: String,
  data data: dict.Dict(String, String),
) -> FlowInstance {
  FlowInstance(
    id:,
    flow_name:,
    user_id:,
    chat_id:,
    state: FlowState(
      current_step:,
      data:,
      history: [current_step],
      flow_stack: [],
      parallel_state: None,
    ),
    step_data: dict.new(),
    wait_token: None,
    wait_timeout_at: None,
    created_at: utils.current_time_ms(),
    updated_at: utils.current_time_ms(),
  )
}

/// Get the instance ID
pub fn instance_id(instance: FlowInstance) -> String {
  instance.id
}

/// Get the flow name
pub fn instance_flow_name(instance: FlowInstance) -> String {
  instance.flow_name
}

/// Get the user ID
pub fn instance_user_id(instance: FlowInstance) -> Int {
  instance.user_id
}

/// Get the chat ID
pub fn instance_chat_id(instance: FlowInstance) -> Int {
  instance.chat_id
}

/// Get the current step name
pub fn instance_current_step(instance: FlowInstance) -> String {
  instance.state.current_step
}

/// Get the wait token
pub fn instance_wait_token(instance: FlowInstance) -> Option(String) {
  instance.wait_token
}

/// Get the created_at timestamp
pub fn instance_created_at(instance: FlowInstance) -> Int {
  instance.created_at
}

/// Get the updated_at timestamp
pub fn instance_updated_at(instance: FlowInstance) -> Int {
  instance.updated_at
}

/// Store step data
pub fn store_step_data(
  instance: FlowInstance,
  key key: String,
  value value: String,
) -> FlowInstance {
  FlowInstance(
    ..instance,
    step_data: dict.insert(instance.step_data, key, value),
  )
}

/// Get step data
pub fn get_step_data(
  instance: FlowInstance,
  key key: String,
) -> Option(String) {
  dict.get(instance.step_data, key)
  |> option.from_result()
}

/// Clear all step data
pub fn clear_step_data(instance: FlowInstance) -> FlowInstance {
  FlowInstance(..instance, step_data: dict.new())
}

/// Clear specific step data key
pub fn clear_step_data_key(
  instance: FlowInstance,
  key key: String,
) -> FlowInstance {
  FlowInstance(..instance, step_data: dict.delete(instance.step_data, key))
}

/// Store data in the flow instance
pub fn store_data(
  instance: FlowInstance,
  key key: String,
  value value: String,
) -> FlowInstance {
  FlowInstance(
    ..instance,
    state: FlowState(
      ..instance.state,
      data: dict.insert(instance.state.data, key, value),
    ),
  )
}

/// Get data from the flow instance
pub fn get_data(instance: FlowInstance, key key: String) -> Option(String) {
  dict.get(instance.state.data, key)
  |> result.map(Some)
  |> result.unwrap(None)
}

/// Step-data key under which auto-resume handlers store the encoded wait
/// result. Owned here so the literal exists in exactly one module.
@internal
pub const wait_result_key = "__wait_result"

/// Get the result of waiting for user input or callback
pub fn get_wait_result(instance: FlowInstance) -> WaitResult {
  case get_step_data(instance, wait_result_key) {
    None -> Pending
    Some(raw) -> parse_wait_result(raw)
  }
}

/// Drop a consumed wait result so a later re-execution of the same step sees
/// `Pending` instead of re-processing the old event.
@internal
pub fn clear_wait_result(instance: FlowInstance) -> FlowInstance {
  clear_step_data_key(instance, wait_result_key)
}

// JSON serialization ---------------------------------------------------------
//
// These encode the *complete* instance — including
// `history`, `flow_stack`, and `parallel_state` — so any key-value backend can
// persist and restore subflows and parallel execution across restarts.

fn encode_string_dict(d: dict.Dict(String, String)) -> Json {
  json.object(list.map(dict.to_list(d), fn(kv) { #(kv.0, json.string(kv.1)) }))
}

fn string_dict_decoder() -> Decoder(dict.Dict(String, String)) {
  decode.dict(decode.string, decode.string)
}

fn encode_nested_dict(d: dict.Dict(String, dict.Dict(String, String))) -> Json {
  json.object(
    list.map(dict.to_list(d), fn(kv) { #(kv.0, encode_string_dict(kv.1)) }),
  )
}

fn nested_dict_decoder() -> Decoder(
  dict.Dict(String, dict.Dict(String, String)),
) {
  decode.dict(decode.string, string_dict_decoder())
}

fn encode_parallel_state(ps: ParallelState) -> Json {
  json.object([
    #("pending_steps", json.array(ps.pending_steps, json.string)),
    #("completed_steps", json.array(ps.completed_steps, json.string)),
    #("results", encode_nested_dict(ps.results)),
    #("join_step", json.string(ps.join_step)),
  ])
}

fn parallel_state_decoder() -> Decoder(ParallelState) {
  use pending_steps <- decode.field("pending_steps", decode.list(decode.string))
  use completed_steps <- decode.field(
    "completed_steps",
    decode.list(decode.string),
  )
  use results <- decode.field("results", nested_dict_decoder())
  use join_step <- decode.field("join_step", decode.string)
  decode.success(ParallelState(
    pending_steps:,
    completed_steps:,
    results:,
    join_step:,
  ))
}

fn encode_stack_frame(frame: FlowStackFrame) -> Json {
  json.object([
    #("flow_name", json.string(frame.flow_name)),
    #("return_step", json.string(frame.return_step)),
    #("saved_data", encode_string_dict(frame.saved_data)),
  ])
}

fn stack_frame_decoder() -> Decoder(FlowStackFrame) {
  use flow_name <- decode.field("flow_name", decode.string)
  use return_step <- decode.field("return_step", decode.string)
  use saved_data <- decode.field("saved_data", string_dict_decoder())
  decode.success(FlowStackFrame(flow_name:, return_step:, saved_data:))
}

fn encode_state(state: FlowState) -> Json {
  json.object([
    #("current_step", json.string(state.current_step)),
    #("data", encode_string_dict(state.data)),
    #("history", json.array(state.history, json.string)),
    #("flow_stack", json.array(state.flow_stack, encode_stack_frame)),
    #(
      "parallel_state",
      json.nullable(state.parallel_state, encode_parallel_state),
    ),
  ])
}

fn state_decoder() -> Decoder(FlowState) {
  use current_step <- decode.field("current_step", decode.string)
  use data <- decode.field("data", string_dict_decoder())
  use history <- decode.field("history", decode.list(decode.string))
  use flow_stack <- decode.field(
    "flow_stack",
    decode.list(stack_frame_decoder()),
  )
  use parallel_state <- decode.field(
    "parallel_state",
    decode.optional(parallel_state_decoder()),
  )
  decode.success(FlowState(
    current_step:,
    data:,
    history:,
    flow_stack:,
    parallel_state:,
  ))
}

/// Version of the persisted `FlowInstance` shape.
///
/// Bump it whenever a change makes an older blob no longer safe to read as-is.
/// A blob written by a *newer* build fails to decode rather than being read
/// partially — see `instance_decoder`.
pub const schema_version = 1

/// Encode a complete `FlowInstance` to JSON.
pub fn to_json(instance: FlowInstance) -> Json {
  json.object([
    #("schema_version", json.int(schema_version)),
    #("id", json.string(instance.id)),
    #("flow_name", json.string(instance.flow_name)),
    #("user_id", json.int(instance.user_id)),
    #("chat_id", json.int(instance.chat_id)),
    #("state", encode_state(instance.state)),
    #("step_data", encode_string_dict(instance.step_data)),
    #("wait_token", json.nullable(instance.wait_token, json.string)),
    #("wait_timeout_at", json.nullable(instance.wait_timeout_at, json.int)),
    #("created_at", json.int(instance.created_at)),
    #("updated_at", json.int(instance.updated_at)),
  ])
}

/// Decoder for a complete `FlowInstance`.
///
/// A blob without `schema_version` predates the field and is schema 1. A blob
/// from a newer build fails: reading it with this build's decoder would yield a
/// half-populated instance that the next save would write back over the user's
/// real state.
pub fn instance_decoder() -> Decoder(FlowInstance) {
  use version <- decode.optional_field("schema_version", 1, decode.int)
  use <- bool.lazy_guard(when: version > schema_version, return: fn() {
    decode.failure(
      new_instance(
        id: "",
        flow_name: "",
        user_id: 0,
        chat_id: 0,
        current_step: "",
      ),
      "FlowInstance schema v" <> int.to_string(schema_version) <> " or older",
    )
  })
  use id <- decode.field("id", decode.string)
  use flow_name <- decode.field("flow_name", decode.string)
  use user_id <- decode.field("user_id", decode.int)
  use chat_id <- decode.field("chat_id", decode.int)
  use state <- decode.field("state", state_decoder())
  use step_data <- decode.field("step_data", string_dict_decoder())
  use wait_token <- decode.field("wait_token", decode.optional(decode.string))
  use wait_timeout_at <- decode.field(
    "wait_timeout_at",
    decode.optional(decode.int),
  )
  use created_at <- decode.field("created_at", decode.int)
  use updated_at <- decode.field("updated_at", decode.int)
  decode.success(FlowInstance(
    id:,
    flow_name:,
    user_id:,
    chat_id:,
    state:,
    step_data:,
    wait_token:,
    wait_timeout_at:,
    created_at:,
    updated_at:,
  ))
}

/// Serialize a `FlowInstance` to a JSON string (for string-based storage).
pub fn to_json_string(instance: FlowInstance) -> String {
  instance |> to_json |> json.to_string
}

/// Deserialize a `FlowInstance` from a JSON string.
pub fn from_json_string(raw: String) -> Result(FlowInstance, json.DecodeError) {
  json.parse(raw, instance_decoder())
}

/// Check if an instance is expired based on TTL or wait timeout
pub fn is_expired(instance: FlowInstance, ttl_ms: option.Option(Int)) -> Bool {
  let now = utils.current_time_ms()
  let ttl_expired = case ttl_ms {
    Some(ttl) -> now - instance.created_at > ttl
    None -> False
  }
  let wait_expired = case instance.wait_timeout_at {
    Some(timeout_at) -> now > timeout_at
    None -> False
  }
  ttl_expired || wait_expired
}

/// Update instance data and continue to next step
pub fn next_with_data(
  ctx: Context(session, error, dependencies),
  instance: FlowInstance,
  step step: step_type,
  key key: String,
  value value: String,
) -> StepResult(step_type, session, error, dependencies) {
  let updated_instance = store_data(instance, key, value)
  Ok(#(ctx, Next(step), updated_instance))
}

/// Get current step as typed value
pub fn get_current_step(
  flow: Flow(step_type, session, error, dependencies),
  instance: FlowInstance,
) -> Result(step_type, Nil) {
  flow.string_to_step(instance.state.current_step)
}

/// Encode text wait result
@internal
pub fn encode_text_wait_result(text: String) -> String {
  "text:" <> text
}

/// Encode callback wait result.
///
/// A payload shaped `"{id}:true"` / `"{id}:false"` is a yes/no button. The id
/// travels with it — dropping it (as this used to) left a step unable to tell
/// `confirm:true` from `subscribe:true`.
@internal
pub fn encode_callback_wait_result(data: String) -> String {
  case string.split(data, ":") {
    [id, "true"] -> "bool:" <> id <> ":true"
    [id, "false"] -> "bool:" <> id <> ":false"
    _ -> "data:" <> data
  }
}

/// Exposed for tests: the encoding above and this parser are one pair.
@internal
pub fn parse_wait_result_for_test(raw: String) -> WaitResult {
  parse_wait_result(raw)
}

fn parse_wait_result(raw: String) -> WaitResult {
  case raw {
    "bool:" <> rest -> parse_bool_result(rest)
    "photo:" <> rest -> PhotoInput(file_ids: string.split(rest, ","))
    "video:" <> rest -> VideoInput(file_id: rest)
    "voice:" <> rest -> VoiceInput(file_id: rest)
    "audio:" <> rest -> AudioInput(file_id: rest)
    "location:" <> rest -> parse_location_result(rest)
    "command:" <> rest -> parse_command_result(rest)
    "text:" <> rest -> TextInput(value: rest)
    "data:" <> rest -> DataCallback(value: rest)
    other -> DataCallback(value: other)
  }
}

fn parse_bool_result(raw: String) -> WaitResult {
  case string.split_once(raw, ":") {
    Ok(#(id, "true")) -> BoolCallback(id:, value: True)
    Ok(#(id, "false")) -> BoolCallback(id:, value: False)
    // Instances persisted before the id was carried say just "true"/"false".
    Error(Nil) if raw == "true" -> BoolCallback(id: "", value: True)
    Error(Nil) if raw == "false" -> BoolCallback(id: "", value: False)
    _ -> DataCallback(value: "bool:" <> raw)
  }
}

fn parse_location_result(raw: String) -> WaitResult {
  case string.split(raw, ",") {
    [lat_str, lng_str] ->
      case float.parse(lat_str), float.parse(lng_str) {
        Ok(lat), Ok(lng) -> LocationInput(latitude: lat, longitude: lng)
        _, _ -> DataCallback(value: "location:" <> raw)
      }
    _ -> DataCallback(value: "location:" <> raw)
  }
}

fn parse_command_result(raw: String) -> WaitResult {
  case string.split_once(raw, ":") {
    Ok(#(cmd, payload)) -> CommandInput(command: cmd, payload:)
    Error(_) -> CommandInput(command: raw, payload: "")
  }
}
