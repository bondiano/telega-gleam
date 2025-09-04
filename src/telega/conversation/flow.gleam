//// # Flow Module
////
//// In-memory, multi-step conversational flows with navigation.
//// Maintains state and history within a single bot session.
////
//// ## When to Use
////
//// - Multi-step forms or wizards
//// - Flows with navigation (back/forward)
//// - Data collection across steps
//// - Conditional branching logic
////
//// ## Key Features
////
//// - **Stateful**: Maintains data and navigation history
//// - **In-memory**: State exists only during bot runtime
//// - **Navigable**: Supports Next, Back, Jump actions
//// - **Composable**: Build complex flows from simple steps
////
//// ## Example
////
//// ```gleam
//// // Define a registration flow
//// let registration_flow =
////   flow.new("registration", "welcome")
////   |> flow.add_step("welcome", welcome_handler)
////   |> flow.add_step("name", name_handler)
////   |> flow.add_step("email", email_handler)
////   |> flow.on_complete(save_registration)
////   |> flow.on_cancel(cleanup)
////
//// // Step handler
//// fn name_handler(ctx, state) {
////   case reply.with_text(ctx, "What's your name?") {
////     Ok(_) -> Ok(#(ctx, flow.Next("email")))
////     Error(_) -> Ok(#(ctx, flow.Cancel))
////   }
//// }
////
//// // Start flow
//// use ctx <- flow.start(registration_flow, ctx)
//// ```
////
//// ## Flow Actions
////
//// - `Next(step)`: Move to next step
//// - `Back`: Return to previous step
//// - `Jump(step)`: Jump to any step
//// - `Complete(data)`: Finish with data
//// - `Cancel`: Exit flow
////
//// ## Comparison
////
//// - Use `dialog` for simple, immediate interactions
//// - Use `flow` for in-memory multi-step processes
//// - Use `persistent_flow` when state must survive restarts

import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import telega/bot.{type Context}
import telega/update

/// Flow state representing current step and data
pub type FlowState {
  FlowState(
    current_step: String,
    data: Dict(String, String),
    history: List(String),
  )
}

/// Step handler function type
pub type StepHandler(session, error) =
  fn(Context(session, error), FlowState) ->
    Result(#(Context(session, error), FlowAction), error)

/// Action to take after step execution
pub type FlowAction {
  Next(step: String)
  Back
  Jump(step: String)
  Complete(result: Dict(String, String))
  Cancel
}

/// Flow definition with steps and transitions
pub type Flow(session, error) {
  Flow(
    name: String,
    steps: Dict(String, StepHandler(session, error)),
    initial_step: String,
    on_complete: Option(
      fn(Context(session, error), Dict(String, String)) ->
        Result(Context(session, error), error),
    ),
    on_cancel: Option(
      fn(Context(session, error)) -> Result(Context(session, error), error),
    ),
  )
}

/// Create a new flow
pub fn new(name: String, initial_step: String) -> Flow(session, error) {
  Flow(
    name: name,
    steps: dict.new(),
    initial_step: initial_step,
    on_complete: None,
    on_cancel: None,
  )
}

/// Add a step to the flow
pub fn add_step(
  flow: Flow(session, error),
  step_name: String,
  handler: StepHandler(session, error),
) -> Flow(session, error) {
  Flow(..flow, steps: dict.insert(flow.steps, step_name, handler))
}

/// Set completion handler
pub fn on_complete(
  flow: Flow(session, error),
  handler: fn(Context(session, error), Dict(String, String)) ->
    Result(Context(session, error), error),
) -> Flow(session, error) {
  Flow(..flow, on_complete: Some(handler))
}

/// Set cancellation handler
pub fn on_cancel(
  flow: Flow(session, error),
  handler: fn(Context(session, error)) -> Result(Context(session, error), error),
) -> Flow(session, error) {
  Flow(..flow, on_cancel: Some(handler))
}

/// Start flow execution
pub fn start(
  flow: Flow(session, error),
  ctx: Context(session, error),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let initial_state =
    FlowState(current_step: flow.initial_step, data: dict.new(), history: [])

  execute_step(flow, ctx, initial_state, continue)
}

/// Start flow execution with initial data
pub fn start_with_data(
  flow: Flow(session, error),
  ctx: Context(session, error),
  initial_data: Dict(String, String),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let initial_state =
    FlowState(current_step: flow.initial_step, data: initial_data, history: [])

  execute_step(flow, ctx, initial_state, continue)
}

/// Resume flow execution from a specific state
pub fn resume_from_state(
  flow: Flow(session, error),
  ctx: Context(session, error),
  state: FlowState,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  execute_step(flow, ctx, state, continue)
}

/// Execute current step
fn execute_step(
  flow: Flow(session, error),
  ctx: Context(session, error),
  state: FlowState,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case dict.get(flow.steps, state.current_step) {
    Ok(handler) -> {
      case handler(ctx, state) {
        Ok(#(new_ctx, action)) -> {
          handle_action(flow, new_ctx, state, action, continue)
        }
        Error(err) -> Error(err)
      }
    }
    Error(_) -> {
      // Step not found, cancel flow
      case flow.on_cancel {
        Some(cancel_handler) -> cancel_handler(ctx)
        None -> continue(ctx)
      }
    }
  }
}

/// Handle flow action
fn handle_action(
  flow: Flow(session, error),
  ctx: Context(session, error),
  state: FlowState,
  action: FlowAction,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case action {
    Next(step) -> {
      let new_state =
        FlowState(..state, current_step: step, history: [
          state.current_step,
          ..state.history
        ])
      execute_step(flow, ctx, new_state, continue)
    }

    Back -> {
      case state.history {
        [previous, ..rest] -> {
          let new_state =
            FlowState(..state, current_step: previous, history: rest)
          execute_step(flow, ctx, new_state, continue)
        }
        [] -> {
          // No history, stay on current step
          execute_step(flow, ctx, state, continue)
        }
      }
    }

    Jump(step) -> {
      let new_state =
        FlowState(..state, current_step: step, history: [
          state.current_step,
          ..state.history
        ])
      execute_step(flow, ctx, new_state, continue)
    }

    Complete(result) -> {
      case flow.on_complete {
        Some(complete_handler) -> complete_handler(ctx, result)
        None -> continue(ctx)
      }
    }

    Cancel -> {
      case flow.on_cancel {
        Some(cancel_handler) -> cancel_handler(ctx)
        None -> continue(ctx)
      }
    }
  }
}

/// Helper to store data in flow state
pub fn store_data(state: FlowState, key: String, value: String) -> FlowState {
  FlowState(..state, data: dict.insert(state.data, key, value))
}

/// Helper to get data from flow state
pub fn get_data(state: FlowState, key: String) -> Option(String) {
  case dict.get(state.data, key) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

/// Serialize flow state to JSON string for embedding in callback data
pub fn serialize_state(state: FlowState) -> String {
  let data_list =
    state.data
    |> dict.to_list
    |> list.map(fn(pair) {
      let #(key, value) = pair
      json.object([#("key", json.string(key)), #("value", json.string(value))])
    })

  let state_json =
    json.object([
      #("current_step", json.string(state.current_step)),
      #("data", json.array(data_list, fn(x) { x })),
      #("history", json.array(state.history, json.string)),
    ])

  json.to_string(state_json)
}

/// Deserialize flow state from JSON string
pub fn deserialize_state(encoded_state: String) -> Result(FlowState, String) {
  case string.trim(encoded_state) {
    "" -> Error("Empty state string")
    state_str -> {
      let decoder = {
        use current_step <- decode.field("current_step", decode.string)
        use data <- decode.field(
          "data",
          decode.dict(decode.string, decode.string),
        )
        use history <- decode.field("history", decode.list(decode.string))
        decode.success(FlowState(current_step:, data:, history:))
      }

      case json.parse(state_str, decoder) {
        Ok(state) -> Ok(state)
        Error(err) ->
          Error("Failed to parse flow state: " <> string.inspect(err))
      }
    }
  }
}

/// Create a router handler that starts a flow
///
/// ## Example
///
/// ```gleam
/// let onboarding_flow = flow.new("onboarding")
///   |> flow.add_step("welcome", welcome_step)
///   |> flow.add_step("collect_name", name_step)
///   |> flow.add_step("collect_email", email_step)
///
/// router.new("my_bot")
///   |> router.on_command("start", flow.to_handler(onboarding_flow))
/// ```
pub fn to_handler(
  flow: Flow(session, error),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _command) { start(flow, ctx, Ok) }
}

/// Create a router handler that starts a flow with initial data
///
/// ## Example
///
/// ```gleam
/// router.new("my_bot")
///   |> router.on_command("quiz", flow.to_handler_with_data(
///     quiz_flow,
///     dict.from_list([#("difficulty", "easy")])
///   ))
/// ```
pub fn to_handler_with_data(
  flow: Flow(session, error),
  initial_data: Dict(String, String),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _command) { start_with_data(flow, ctx, initial_data, Ok) }
}

/// Create a router handler for resuming flows
///
/// ## Example
///
/// ```gleam
/// router.new("my_bot")
///   |> router.on_callback(Prefix("flow:"), flow.resume_handler(my_flow))
/// ```
pub fn resume_handler(
  flow: Flow(session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, update) {
    case update {
      update.CallbackQueryUpdate(query:, ..) -> {
        // Extract flow state from callback data
        // Expected format: "flow:encoded_state" or "resume:encoded_state"
        let data = option.unwrap(query.data, "")

        case string.split(data, ":") {
          [_prefix, encoded_state, ..] -> {
            // Try to decode the flow state
            case deserialize_state(encoded_state) {
              Ok(state) -> {
                // Resume flow from the decoded state
                resume_from_state(flow, ctx, state, Ok)
              }
              Error(_) -> {
                // If decoding fails, start fresh flow
                start(flow, ctx, Ok)
              }
            }
          }
          [encoded_state] -> {
            // No prefix, treat entire data as encoded state
            case deserialize_state(encoded_state) {
              Ok(state) -> resume_from_state(flow, ctx, state, Ok)
              Error(_) -> start(flow, ctx, Ok)
            }
          }
          [] -> {
            // No callback data, start fresh
            start(flow, ctx, Ok)
          }
        }
      }
      _ -> {
        // Not a callback query, ignore
        Ok(ctx)
      }
    }
  }
}
