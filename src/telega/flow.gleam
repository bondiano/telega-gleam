//// # Flow Module
////
//// Type-safe, persistent flow system for building multi-step conversational interactions.
////
//// ## Core Concepts
////
//// **Flow** - A state machine representing a multi-step conversation with defined transitions
//// between steps. Each flow is isolated per user and persists across bot restarts.
////
//// **FlowRegistry** - Central container for managing all flows in your bot. Flows are
//// registered once and can be triggered by commands, callbacks, or called programmatically.
////
//// **Type Safety** - All step transitions are validated at compile-time using ADTs.
//// Invalid transitions are compilation errors, not runtime failures.
////
//// **Storage** - Pluggable persistence layer supporting any backend (database, memory, Redis).
//// Flow state automatically persists and resumes after interruptions.
////
//// ## Architecture
////
//// ```
//// FlowRegistry
////   ├── Triggered Flows (commands, callbacks, text patterns)
////   └── Global Flows (callable from any handler)
////         ↓
////      Router Integration
////         ↓
////      Auto-resume Handlers
//// ```
////
//// ## Quick Start
////
//// ```gleam
//// // 1. Define your flow steps as an ADT
//// pub type OnboardingStep {
////   Welcome
////   CollectName
////   CollectEmail
////   Complete
//// }
////
//// // 2. Create the flow with step handlers
//// let onboarding_flow =
////   flow.new("onboarding", storage, step_to_string, string_to_step)
////   |> flow.add_step(Welcome, welcome_handler)
////   |> flow.add_step(CollectName, name_handler)
////   |> flow.add_step(CollectEmail, email_handler)
////   |> flow.add_step(Complete, complete_handler)
////   |> flow.build(initial: Welcome)
////
//// // 3. Register flows in a registry
//// let flow_registry =
////   flow.new_registry()
////   |> flow.register(flow.OnCommand("/start"), onboarding_flow)
////
//// // 4. Apply to router
//// router
//// |> flow.apply_to_router(flow_registry)
//// ```
////
//// ## Flow Registry API
////
//// Use the FlowRegistry to centrally manage all flows in your bot:
////
//// ```gleam
//// let flow_registry =
////   flow.new_registry()
////   |> flow.register(flow.OnCommand("/start"), start_flow)
////   |> flow.register(flow.OnCommand("/checkout"), checkout_flow)
////   |> flow.register_global(background_flow)  // For calling from handlers
////
//// let router =
////   router.new("MyBot")
////   |> router.on_command("/help", help_handler)
////   |> flow.apply_to_router(flow_registry, _)
//// ```
////
//// Once registered, flows can be called from any handler:
////
//// ```gleam
//// // Call from any handler
//// fn my_handler(ctx, _data) {
////   let initial_data = dict.from_list([
////     #("product_id", "123"),
////     #("quantity", "2")
////   ])
////   flow.call_flow(ctx, "checkout", initial_data)
//// }
////
//// // Or call from within another flow step
//// fn some_step_handler(ctx, instance) {
////   let args = dict.from_list([#("reason", "upgrade")])
////   flow.call(ctx, instance, "subscription_flow", args)
//// }
////
//// // Register a flow without router trigger (manual invocation only)
//// flow.register_global(helper_flow)
//// ```

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/reply

import telega/bot.{type Context}
import telega/keyboard
import telega/router
import telega/update

// ============================================================================
// Core Types
// ============================================================================

/// Flow state representing current step and data
pub type FlowState {
  FlowState(
    // Internal string representation for storage
    current_step: String,
    data: Dict(String, String),
    history: List(String),
  )
}

/// Persistent flow instance with unique ID
pub type FlowInstance {
  FlowInstance(
    id: String,
    flow_name: String,
    user_id: Int,
    chat_id: Int,
    state: FlowState,
    // Scene-local data
    scene_data: Dict(String, String),
    // Token for external resume
    wait_token: Option(String),
    created_at: Int,
    updated_at: Int,
  )
}

/// Storage interface for persistent flows
pub type FlowStorage(error) {
  FlowStorage(
    save: fn(FlowInstance) -> Result(Nil, error),
    load: fn(String) -> Result(Option(FlowInstance), error),
    delete: fn(String) -> Result(Nil, error),
    list_by_user: fn(Int, Int) -> Result(List(FlowInstance), error),
  )
}

// ============================================================================
// Type-Safe Flow Types
// ============================================================================

/// Type-safe flow builder that ensures compile-time step validation
pub opaque type FlowBuilder(step_type, session, error) {
  FlowBuilder(
    flow_name: String,
    steps: Dict(String, StepHandler(step_type, session, error)),
    step_to_string: fn(step_type) -> String,
    string_to_step: fn(String) -> Result(step_type, Nil),
    storage: FlowStorage(error),
    on_complete: Option(
      fn(Context(session, error), FlowInstance) ->
        Result(Context(session, error), error),
    ),
    on_error: Option(
      fn(Context(session, error), FlowInstance, Option(error)) ->
        Result(Context(session, error), error),
    ),
  )
}

/// Type-safe flow
pub opaque type Flow(step_type, session, error) {
  Flow(
    name: String,
    steps: Dict(String, StepHandler(step_type, session, error)),
    initial_step: step_type,
    step_to_string: fn(step_type) -> String,
    string_to_step: fn(String) -> Result(step_type, Nil),
    storage: FlowStorage(error),
    on_complete: Option(
      fn(Context(session, error), FlowInstance) ->
        Result(Context(session, error), error),
    ),
    on_error: Option(
      fn(Context(session, error), FlowInstance, Option(error)) ->
        Result(Context(session, error), error),
    ),
  )
}

/// Flow registry for centralized flow management
pub opaque type FlowRegistry(session, error) {
  FlowRegistry(
    flows: List(
      #(FlowTrigger, Flow(Dynamic, session, error), Dict(String, String)),
    ),
    global_flows: List(Flow(Dynamic, session, error)),
  )
}

/// Step handler function type
pub type StepHandler(step_type, session, error) =
  fn(Context(session, error), FlowInstance) ->
    StepResult(step_type, session, error)

/// Result type for flow steps
pub type StepResult(step_type, session, error) =
  Result(#(Context(session, error), FlowAction(step_type), FlowInstance), error)

/// Type-safe flow actions
pub type FlowAction(step_type) {
  /// Move to the next step
  Next(step_type)
  /// Move to next step by string name (for dynamic navigation)
  NextString(String)
  /// Go back to previous step
  Back
  /// Complete the flow with data
  Complete(Dict(String, String))
  /// Cancel the flow
  Cancel
  /// Wait for user input
  Wait(String)
  /// Wait for callback query
  WaitCallback(String)
  /// Jump to any step (clears scene data)
  GoTo(step_type)
  /// Exit flow with result
  Exit(Option(Dict(String, String)))
  /// Call another flow
  Call(flow_name: String, args: Dict(String, String))
}

// ============================================================================
// Builder Functions
// ============================================================================

/// Create a new flow builder
pub fn new(
  flow_name: String,
  storage: FlowStorage(error),
  step_to_string: fn(step_type) -> String,
  string_to_step: fn(String) -> Result(step_type, Nil),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(
    flow_name: flow_name,
    steps: dict.new(),
    step_to_string: step_to_string,
    string_to_step: string_to_step,
    storage: storage,
    on_complete: None,
    on_error: None,
  )
}

/// Create a flow builder with default string conversion (uses string.inspect)
pub fn new_with_default_converters(
  flow_name: String,
  storage: FlowStorage(error),
  steps: List(#(String, step_type)),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(
    flow_name: flow_name,
    steps: dict.new(),
    step_to_string: step_to_string_default,
    string_to_step: create_string_to_step(steps),
    storage: storage,
    on_complete: None,
    on_error: None,
  )
}

/// Add a typed step to the flow
pub fn add_step(
  builder: FlowBuilder(step_type, session, error),
  step: step_type,
  handler: StepHandler(step_type, session, error),
) -> FlowBuilder(step_type, session, error) {
  let step_name = builder.step_to_string(step)
  FlowBuilder(..builder, steps: dict.insert(builder.steps, step_name, handler))
}

/// Set completion handler
pub fn on_complete(
  builder: FlowBuilder(step_type, session, error),
  handler: fn(Context(session, error), FlowInstance) ->
    Result(Context(session, error), error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, on_complete: Some(handler))
}

/// Set error handler
pub fn on_error(
  builder: FlowBuilder(step_type, session, error),
  handler: fn(Context(session, error), FlowInstance, Option(error)) ->
    Result(Context(session, error), error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, on_error: Some(handler))
}

/// Build the flow
pub fn build(
  builder: FlowBuilder(step_type, session, error),
  initial initial_step: step_type,
) -> Flow(step_type, session, error) {
  Flow(
    name: builder.flow_name,
    steps: builder.steps,
    initial_step: initial_step,
    step_to_string: builder.step_to_string,
    string_to_step: builder.string_to_step,
    storage: builder.storage,
    on_complete: builder.on_complete,
    on_error: builder.on_error,
  )
}

// ============================================================================
// Navigation Helpers
// ============================================================================

/// Type-safe next navigation
pub fn next(
  ctx: Context(session, error),
  instance: FlowInstance,
  step: step_type,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Next(step), instance))
}

/// Next navigation with string step (for dynamic navigation)
pub fn unsafe_next(
  ctx: Context(session, error),
  instance: FlowInstance,
  step: String,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, NextString(step), instance))
}

/// Type-safe goto navigation (clears scene data)
pub fn goto(
  ctx: Context(session, error),
  instance: FlowInstance,
  step: step_type,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, GoTo(step), instance))
}

/// Go back to previous step
pub fn back(
  ctx: Context(session, error),
  instance: FlowInstance,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Back, instance))
}

/// Complete the flow
pub fn complete(
  ctx: Context(session, error),
  instance: FlowInstance,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Complete(instance.state.data), instance))
}

/// Cancel the flow
pub fn cancel(
  ctx: Context(session, error),
  instance: FlowInstance,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Cancel, instance))
}

/// Wait for user input
pub fn wait(
  ctx: Context(session, error),
  instance: FlowInstance,
  token: String,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Wait(token), instance))
}

/// Wait for callback
pub fn wait_callback(
  ctx: Context(session, error),
  instance: FlowInstance,
  token: String,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, WaitCallback(token <> "_" <> instance.id), instance))
}

/// Exit with result
pub fn exit(
  ctx: Context(session, error),
  instance: FlowInstance,
  result: Option(Dict(String, String)),
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Exit(result), instance))
}

/// Call another flow from within a step handler
pub fn call(
  ctx: Context(session, error),
  instance: FlowInstance,
  flow_name: String,
  args: Dict(String, String),
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Call(flow_name, args), instance))
}

// ============================================================================
// Flow Control
// ============================================================================

/// Start or resume a flow (internal)
fn start_or_resume(
  flow flow: Flow(step_type, session, error),
  ctx ctx: Context(session, error),
  user_id user_id: Int,
  chat_id chat_id: Int,
  initial_data initial_data: Dict(String, String),
) -> Result(Context(session, error), error) {
  let flow_id = generate_flow_id(user_id, chat_id, flow.name)

  case flow.storage.load(flow_id) {
    Ok(Some(instance)) -> execute_step(flow, ctx, instance)
    Ok(None) -> {
      let initial_step_name = flow.step_to_string(flow.initial_step)
      let new_instance =
        FlowInstance(
          id: flow_id,
          flow_name: flow.name,
          user_id: user_id,
          chat_id: chat_id,
          state: FlowState(
            current_step: initial_step_name,
            data: initial_data,
            history: [initial_step_name],
          ),
          scene_data: dict.new(),
          wait_token: None,
          created_at: unix_timestamp(),
          updated_at: unix_timestamp(),
        )

      case flow.storage.save(new_instance) {
        Ok(_) -> execute_step(flow, ctx, new_instance)
        Error(err) -> handle_error(flow, ctx, new_instance, Some(err))
      }
    }
    Error(err) -> {
      let dummy_instance =
        FlowInstance(
          id: flow_id,
          flow_name: flow.name,
          user_id: user_id,
          chat_id: chat_id,
          state: FlowState(current_step: "", data: dict.new(), history: []),
          scene_data: dict.new(),
          wait_token: None,
          created_at: 0,
          updated_at: 0,
        )
      handle_error(flow, ctx, dummy_instance, Some(err))
    }
  }
}

/// Resume flow with external token (internal)
fn resume_with_token(
  flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  token: String,
  data: Option(Dict(String, String)),
) -> Result(Context(session, error), error) {
  case find_instance_by_token(flow.storage, token) {
    Ok(Some(instance)) -> {
      let updated_instance = case data {
        Some(d) ->
          FlowInstance(
            ..instance,
            scene_data: dict.merge(instance.scene_data, d),
            wait_token: None,
          )
        None -> FlowInstance(..instance, wait_token: None)
      }
      execute_step(flow, ctx, updated_instance)
    }
    _ -> Ok(ctx)
  }
}

/// Get current step as typed value
pub fn get_current_step(
  flow: Flow(step_type, session, error),
  instance: FlowInstance,
) -> Result(step_type, Nil) {
  flow.string_to_step(instance.state.current_step)
}

// ============================================================================
// Scene Data Management
// ============================================================================

/// Store scene data
pub fn store_scene_data(
  instance: FlowInstance,
  key: String,
  value: String,
) -> FlowInstance {
  FlowInstance(
    ..instance,
    scene_data: dict.insert(instance.scene_data, key, value),
  )
}

/// Get scene data
pub fn get_scene_data(instance: FlowInstance, key: String) -> Option(String) {
  dict.get(instance.scene_data, key)
  |> result.map(Some)
  |> result.unwrap(None)
}

/// Clear all scene data
pub fn clear_scene_data(instance: FlowInstance) -> FlowInstance {
  FlowInstance(..instance, scene_data: dict.new())
}

/// Clear specific scene data key
pub fn clear_scene_data_key(instance: FlowInstance, key: String) -> FlowInstance {
  FlowInstance(..instance, scene_data: dict.delete(instance.scene_data, key))
}

/// Get callback bool from scene data
pub fn get_callback_bool(
  instance: FlowInstance,
  key: String,
  callback_id: String,
) -> Option(Bool) {
  case get_scene_data(instance, key) {
    Some(data) -> {
      let callback_data = keyboard.bool_callback_data(callback_id)
      case keyboard.unpack_callback(data, callback_data) {
        Ok(callback) -> Some(callback.data)
        Error(_) -> None
      }
    }
    None -> None
  }
}

// ============================================================================
// Instance Data Management
// ============================================================================

/// Store data in the flow instance
pub fn store_data(
  instance: FlowInstance,
  key: String,
  value: String,
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
pub fn get_data(instance: FlowInstance, key: String) -> Option(String) {
  dict.get(instance.state.data, key)
  |> result.map(Some)
  |> result.unwrap(None)
}

// ============================================================================
// Helper Navigation Functions
// ============================================================================

/// Update instance data and continue to next step
pub fn next_with_data(
  ctx: Context(session, error),
  instance: FlowInstance,
  step: step_type,
  key: String,
  value: String,
) -> StepResult(step_type, session, error) {
  let updated_instance = store_data(instance, key, value)
  next(ctx, updated_instance, step)
}

// ============================================================================
// Internal Functions
// ============================================================================

/// Helper to find instance by wait token
fn find_instance_by_token(
  storage: FlowStorage(error),
  token: String,
) -> Result(Option(FlowInstance), error) {
  case string.split(token, ":") {
    [instance_id, ..] -> storage.load(instance_id)
    _ -> Ok(None)
  }
}

fn execute_step(
  flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
) -> Result(Context(session, error), error) {
  case dict.get(flow.steps, instance.state.current_step) {
    Ok(handler) -> {
      case handler(ctx, instance) {
        Ok(#(new_ctx, action, new_instance)) ->
          process_action(flow, new_ctx, action, new_instance)

        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }
    Error(_) -> handle_error(flow, ctx, instance, None)
  }
}

fn process_action(
  flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  action: FlowAction(step_type),
  instance: FlowInstance,
) -> Result(Context(session, error), error) {
  case action {
    Next(step) -> {
      let step_name = flow.step_to_string(step)
      let updated_instance =
        FlowInstance(
          ..instance,
          state: FlowState(..instance.state, current_step: step_name, history: [
            instance.state.current_step,
            ..instance.state.history
          ]),
          updated_at: unix_timestamp(),
        )

      case flow.storage.save(updated_instance) {
        Ok(_) -> execute_step(flow, ctx, updated_instance)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    NextString(step_name) -> {
      let updated_instance =
        FlowInstance(
          ..instance,
          state: FlowState(..instance.state, current_step: step_name, history: [
            instance.state.current_step,
            ..instance.state.history
          ]),
          updated_at: unix_timestamp(),
        )

      case flow.storage.save(updated_instance) {
        Ok(_) -> execute_step(flow, ctx, updated_instance)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    GoTo(step) -> {
      let step_name = flow.step_to_string(step)
      let updated_instance =
        FlowInstance(
          ..instance,
          state: FlowState(
            current_step: step_name,
            data: instance.state.data,
            history: [step_name],
          ),
          scene_data: dict.new(),
          updated_at: unix_timestamp(),
        )

      case flow.storage.save(updated_instance) {
        Ok(_) -> execute_step(flow, ctx, updated_instance)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    Back -> {
      case instance.state.history {
        [previous_step, ..rest] -> {
          let updated_instance =
            FlowInstance(
              ..instance,
              state: FlowState(
                ..instance.state,
                current_step: previous_step,
                history: rest,
              ),
              updated_at: unix_timestamp(),
            )

          case flow.storage.save(updated_instance) {
            Ok(_) -> execute_step(flow, ctx, updated_instance)
            Error(err) -> handle_error(flow, ctx, instance, Some(err))
          }
        }
        [] -> Ok(ctx)
      }
    }

    Complete(data) -> {
      case flow.on_complete {
        Some(handler) -> {
          let completed_instance =
            FlowInstance(
              ..instance,
              state: FlowState(..instance.state, data: data),
            )
          case handler(ctx, completed_instance) {
            Ok(new_ctx) -> {
              let _ = flow.storage.delete(instance.id)
              Ok(new_ctx)
            }
            Error(err) -> handle_error(flow, ctx, instance, Some(err))
          }
        }
        None -> {
          let _ = flow.storage.delete(instance.id)
          Ok(ctx)
        }
      }
    }

    Cancel -> {
      let _ = flow.storage.delete(instance.id)
      Ok(ctx)
    }

    Wait(token) -> {
      let updated_instance =
        FlowInstance(
          ..instance,
          wait_token: Some(token),
          updated_at: unix_timestamp(),
        )

      case flow.storage.save(updated_instance) {
        Ok(_) -> Ok(ctx)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    WaitCallback(token) -> {
      let updated_instance =
        FlowInstance(
          ..instance,
          wait_token: Some(token),
          updated_at: unix_timestamp(),
        )

      case flow.storage.save(updated_instance) {
        Ok(_) -> Ok(ctx)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    Exit(result) -> {
      let _ = flow.storage.delete(instance.id)
      case result {
        Some(_data) -> Ok(ctx)
        None -> Ok(ctx)
      }
    }

    Call(flow_name, args) -> {
      let updated_instance =
        FlowInstance(..instance, updated_at: unix_timestamp())

      case flow.storage.save(updated_instance) {
        Ok(_) -> call_flow(ctx, flow_name, args)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }
  }
}

fn handle_error(
  flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  error: Option(error),
) -> Result(Context(session, error), error) {
  case flow.on_error {
    Some(handler) -> {
      case handler(ctx, instance, error) {
        Ok(new_ctx) -> Ok(new_ctx)
        Error(_) -> Ok(ctx)
      }
    }
    None -> Ok(ctx)
  }
}

fn generate_flow_id(user_id: Int, chat_id: Int, flow_name: String) -> String {
  flow_name <> "_" <> int.to_string(chat_id) <> "_" <> int.to_string(user_id)
}

// ============================================================================
// Storage Implementations
// ============================================================================

/// Create in-memory storage (for testing)
pub fn create_memory_storage() -> FlowStorage(error) {
  // Note: This is a simplified version. Real implementation would use an actor
  FlowStorage(
    save: fn(_instance) { Ok(Nil) },
    load: fn(_id) { Ok(None) },
    delete: fn(_id) { Ok(Nil) },
    list_by_user: fn(_user_id, _chat_id) { Ok([]) },
  )
}

// ============================================================================
// Convenience Functions
// ============================================================================

/// Convert a step type to string using the type's string representation
fn step_to_string_default(step: a) -> String {
  string.inspect(step)
}

/// Helper to create a string_to_step function for a list of steps
fn create_string_to_step(
  steps: List(#(String, step_type)),
) -> fn(String) -> Result(step_type, Nil) {
  let step_dict = dict.from_list(steps)
  fn(name) { dict.get(step_dict, name) }
}

/// Generate a unique wait token (internal)
fn generate_wait_token(instance: FlowInstance) -> String {
  instance.id <> "_" <> int.to_string(unix_timestamp())
}

// ============================================================================
// Step Helper Functions
// ============================================================================

/// Create a text input step
pub fn text_step(
  prompt: String,
  data_key: String,
  next_step: step_type,
) -> StepHandler(step_type, session, error) {
  fn(ctx: Context(session, error), instance: FlowInstance) {
    // Check if we have user input from the auto-resume handler
    case get_scene_data(instance, "user_input") {
      Some(value) -> {
        // Store the value with the correct key and clear user_input
        let instance =
          instance
          |> store_data(data_key, value)
          |> clear_scene_data_key("user_input")
        Ok(#(ctx, Next(next_step), instance))
      }
      None -> {
        case reply.with_text(ctx, prompt) {
          Ok(_) -> {
            let token = generate_wait_token(instance)
            Ok(#(ctx, Wait(token), instance))
          }
          Error(_) -> Ok(#(ctx, Cancel, instance))
        }
      }
    }
  }
}

/// Create a message display step
pub fn message_step(
  message_fn: fn(FlowInstance) -> String,
  next_step: Option(step_type),
) -> StepHandler(step_type, session, error) {
  fn(ctx: Context(session, error), instance: FlowInstance) {
    let message = message_fn(instance)
    case reply.with_text(ctx, message) {
      Ok(_) -> {
        case next_step {
          Some(step) -> Ok(#(ctx, Next(step), instance))
          None -> Ok(#(ctx, Complete(instance.state.data), instance))
        }
      }
      Error(_) -> Ok(#(ctx, Cancel, instance))
    }
  }
}

// ============================================================================
// Convenience Functions for Handler Creation
// ============================================================================

/// Create a router handler for resuming flows from callback queries
pub fn create_resume_handler(
  flow: Flow(step_type, session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  resume_handler(flow)
}

/// Create a router handler for resuming flows from callback queries with keyboard parsing
pub fn create_resume_handler_with_keyboard(
  flow: Flow(step_type, session, error),
  callback_data: keyboard.KeyboardCallbackData(String),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  resume_handler_with_keyboard(flow, callback_data)
}

/// Create a text handler for resuming flows
pub fn create_text_handler(
  flow: Flow(step_type, session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, update) {
    case update {
      update.TextUpdate(text:, from_id:, chat_id:, ..) -> {
        case flow.storage.list_by_user(from_id, chat_id) {
          Ok([instance, ..]) if instance.wait_token != None -> {
            // Resume flow with text input
            let data = dict.from_list([#("user_input", text)])
            resume_with_token(
              flow,
              ctx,
              option.unwrap(instance.wait_token, ""),
              Some(data),
            )
          }
          _ -> Ok(ctx)
        }
      }
      _ -> Ok(ctx)
    }
  }
}

// ============================================================================
// Router Integration Functions
// ============================================================================

/// Trigger type for flow registration
pub type FlowTrigger {
  OnCommand(command: String)
  OnText(pattern: router.Pattern)
  OnCallback(pattern: router.Pattern)
  OnFiltered(filter: router.Filter)
  OnPhoto
  OnVideo
  OnAudio
  OnVoice
  OnAnyText
}

/// Call a globally registered flow from any handler
///
/// ## Parameters
/// - `ctx`: Current context
/// - `flow_name`: Name of the flow to call
/// - `initial_data`: Initial data to pass to the flow
///
/// ## Example
/// ```gleam
/// fn my_handler(ctx, _data) {
///   let initial_data = dict.from_list([
///     #("user_name", "John"),
///     #("product_id", "123")
///   ])
///   flow.call_flow(ctx, "checkout", initial_data)
/// }
/// ```
pub fn call_flow(
  ctx: Context(session, error),
  flow_name: String,
  initial_data: Dict(String, String),
) -> Result(Context(session, error), error) {
  let flows = get_flows()

  let result =
    list.find(flows, fn(f) {
      let flow: Flow(Dynamic, session, error) = f
      flow.name == flow_name
    })

  case result {
    Ok(found_flow) -> start(found_flow, initial_data, ctx)
    Error(_) -> Ok(ctx)
  }
}

/// Extract user and chat IDs from context
fn extract_ids_from_context(ctx: Context(session, error)) -> #(Int, Int) {
  #(ctx.update.from_id, ctx.update.chat_id)
}

/// Start a flow with optional initial data
fn start(
  flow: Flow(step_type, session, error),
  initial_data: Dict(String, String),
  ctx: Context(session, error),
) -> Result(Context(session, error), error) {
  let #(from_id, chat_id) = extract_ids_from_context(ctx)
  start_or_resume(flow, ctx, from_id, chat_id, initial_data)
}

/// Create a router handler that starts a flow
pub fn to_handler(
  flow: Flow(step_type, session, error),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _command) { start(flow, dict.new(), ctx) }
}

/// Create a router handler that starts a flow with initial data (internal)
fn to_handler_with_data(
  flow: Flow(step_type, session, error),
  initial_data: Dict(String, String),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _update) { start(flow, initial_data, ctx) }
}

/// Create a router handler for resuming flows from callback queries (internal)
fn resume_handler(
  flow: Flow(step_type, session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, update) {
    case update {
      update.CallbackQueryUpdate(query:, ..) -> {
        let data = option.unwrap(query.data, "")
        let token = case string.split(data, ":") {
          [_prefix, token, ..] -> token
          _ -> data
        }
        resume_with_token(flow, ctx, token, None)
      }
      _ -> Ok(ctx)
    }
  }
}

/// Create a router handler for resuming flows from callback queries with keyboard parsing (internal)
fn resume_handler_with_keyboard(
  flow: Flow(step_type, session, error),
  callback_data: keyboard.KeyboardCallbackData(String),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, update) {
    case update {
      update.CallbackQueryUpdate(query:, ..) -> {
        let data = option.unwrap(query.data, "")
        case keyboard.unpack_callback(data, callback_data) {
          Ok(callback) -> resume_with_token(flow, ctx, callback.data, None)

          // Fallback to simple parsing if keyboard parsing fails
          Error(_) -> {
            let token = case string.split(data, ":") {
              [_prefix, token, ..] -> token
              _ -> data
            }
            resume_with_token(flow, ctx, token, None)
          }
        }
      }
      _ -> Ok(ctx)
    }
  }
}

// Global flow registry - using FFI to store flows in ETS table
@external(erlang, "telega_ffi", "put_flows")
fn put_flows(flows: List(Flow(Dynamic, session, error))) -> Nil

@external(erlang, "telega_ffi", "get_flows")
fn get_flows() -> List(Flow(Dynamic, session, error))

@external(erlang, "telega_ffi", "unsafe_coerce")
fn unsafe_coerce(value: a) -> b

/// Create a new empty flow registry
pub fn new_registry() -> FlowRegistry(session, error) {
  FlowRegistry(flows: [], global_flows: [])
}

/// Add a flow to the registry with a trigger
pub fn register(
  registry: FlowRegistry(session, error),
  trigger: FlowTrigger,
  flow: Flow(step_type, session, error),
) -> FlowRegistry(session, error) {
  register_with_data(registry, trigger, flow, dict.new())
}

/// Add a flow to the registry with a trigger and initial data
pub fn register_with_data(
  registry: FlowRegistry(session, error),
  trigger: FlowTrigger,
  flow: Flow(step_type, session, error),
  initial_data: Dict(String, String),
) -> FlowRegistry(session, error) {
  let coerced_flow = unsafe_coerce(flow)
  FlowRegistry(
    flows: list.append(registry.flows, [#(trigger, coerced_flow, initial_data)]),
    global_flows: list.append(registry.global_flows, [coerced_flow]),
  )
}

/// Register a flow globally without a trigger (for calling from handlers)
pub fn register_global(
  registry: FlowRegistry(session, error),
  flow: Flow(step_type, session, error),
) -> FlowRegistry(session, error) {
  let coerced_flow = unsafe_coerce(flow)
  FlowRegistry(
    flows: registry.flows,
    global_flows: list.append(registry.global_flows, [coerced_flow]),
  )
}

/// Apply all registered flows to a router
pub fn apply_to_router(
  router: router.Router(session, error),
  registry: FlowRegistry(session, error),
) -> router.Router(session, error) {
  put_flows(registry.global_flows)

  let router_with_flows =
    list.fold(registry.flows, router, fn(router, flow_entry) {
      let #(trigger, flow, initial_data) = flow_entry
      add_flow_route(router, trigger, flow, initial_data)
    })

  case list.length(registry.global_flows) {
    0 -> router_with_flows
    _ ->
      router_with_flows
      |> router.on_any_text(auto_resume_handler())
      |> router.on_callback(router.Prefix(""), auto_resume_callback_handler())
  }
}

/// Internal: Add a flow route to router
fn add_flow_route(
  router: router.Router(session, error),
  trigger: FlowTrigger,
  flow: Flow(Dynamic, session, error),
  initial_data: Dict(String, String),
) -> router.Router(session, error) {
  case trigger {
    OnCommand(command) ->
      router.on_command(
        router,
        command,
        to_handler_with_data(flow, initial_data),
      )
    OnText(pattern) ->
      router.on_text(router, pattern, fn(ctx, _text) {
        start(flow, initial_data, ctx)
      })
    OnCallback(pattern) ->
      router.on_callback(router, pattern, fn(ctx, _id, _data) {
        start(flow, initial_data, ctx)
      })
    OnFiltered(filter) ->
      router.on_filtered(router, filter, fn(ctx, _update) {
        start(flow, initial_data, ctx)
      })
    OnPhoto ->
      router.on_photo(router, fn(ctx, _photos) {
        start(flow, initial_data, ctx)
      })
    OnVideo ->
      router.on_video(router, fn(ctx, _video) { start(flow, initial_data, ctx) })
    OnAudio ->
      router.on_audio(router, fn(ctx, _audio) { start(flow, initial_data, ctx) })
    OnVoice ->
      router.on_voice(router, fn(ctx, _voice) { start(flow, initial_data, ctx) })
    OnAnyText ->
      router.on_any_text(router, fn(ctx, _text) {
        start(flow, initial_data, ctx)
      })
  }
}

/// Auto-resume handler for text messages
fn auto_resume_handler() -> fn(Context(session, error), String) ->
  Result(Context(session, error), error) {
  let flows = get_flows()

  fn(ctx: Context(session, error), text: String) {
    let #(user_id, chat_id) = extract_ids_from_context(ctx)
    // Try each flow until we find one that's waiting for input
    let result =
      list.fold(flows, None, fn(acc, flow) {
        case acc {
          Some(_) -> acc
          None -> {
            let flow_id = generate_flow_id(user_id, chat_id, flow.name)
            case flow.storage.load(flow_id) {
              Ok(Some(instance)) if instance.wait_token != None -> {
                let data = dict.from_list([#("user_input", text)])

                resume_with_token(
                  flow,
                  ctx,
                  option.unwrap(instance.wait_token, ""),
                  Some(data),
                )
                |> Some
              }
              _ -> None
            }
          }
        }
      })

    case result {
      Some(res) -> res
      None -> Ok(ctx)
    }
  }
}

/// Auto-resume handler for callback queries (internal)
fn auto_resume_callback_handler() -> fn(Context(session, error), String, String) ->
  Result(Context(session, error), error) {
  let flows = get_flows()

  fn(ctx: Context(session, error), _callback_id: String, data: String) {
    let #(user_id, chat_id) = extract_ids_from_context(ctx)
    let result =
      list.fold(flows, None, fn(acc, flow) {
        case acc {
          Some(_) -> acc
          None -> {
            let flow_id = generate_flow_id(user_id, chat_id, flow.name)
            case flow.storage.load(flow_id) {
              Ok(Some(instance)) if instance.wait_token != None -> {
                let callback_data = dict.from_list([#("callback_data", data)])
                resume_with_token(
                  flow,
                  ctx,
                  option.unwrap(instance.wait_token, ""),
                  Some(callback_data),
                )
                |> Some
              }
              _ -> None
            }
          }
        }
      })

    case result {
      Some(res) -> res
      None -> Ok(ctx)
    }
  }
}

// ============================================================================
// External Functions
// ============================================================================

@external(erlang, "os", "system_time")
fn system_time() -> Int

fn unix_timestamp() -> Int {
  system_time() / 1_000_000_000
}
