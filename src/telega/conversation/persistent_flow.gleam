//// # Persistent Flow Module
////
//// Provides persistent, resumable conversational flows that survive bot restarts.
//// Extends the flow module with external storage capabilities and advanced flow control.
////
//// ## When to Use
////
//// - Flows that must survive bot restarts
//// - Long-running processes (hours/days)
//// - Multi-user concurrent flows
//// - Flows requiring audit trails
//// - External process integration
//// - Complex navigation patterns
////
//// ## Key Features
////
//// - **Persistent**: State saved to external storage
//// - **Resumable**: Users continue after interruptions
//// - **Multi-user**: Independent flow instances per user
//// - **Storage-agnostic**: Pluggable storage backends
//// - **Wait/Resume**: Pause flows and resume via tokens
//// - **Scene Data**: Isolated data storage per scene
//// - **Advanced Navigation**: Goto, Call, Exit actions
////
//// ## Flow Actions
////
//// - `StandardAction(flow.FlowAction)`: Standard flow navigation
//// - `Wait(token)`: Pause flow with resumption token
//// - `Goto(label)`: Jump directly to any step
//// - `Call(flow_name, args)`: Call another flow with arguments
//// - `Exit(result)`: Exit flow with optional result data
////
//// ## Example
////
//// ```gleam
//// // Create persistent flow with storage
//// let approval_flow =
////   persistent_flow.new("approval", "submit", storage)
////   |> persistent_flow.add_step("submit", submit_step)
////   |> persistent_flow.add_step("wait_approval", fn(ctx, instance) {
////     let token = persistent_flow.generate_wait_token(instance)
////     // Send token to external system
////     send_to_approval_system(token)
////     Ok(#(ctx, Wait(token), instance))
////   })
////   |> persistent_flow.add_step("approved", approved_step)
////   |> persistent_flow.add_step("rejected", rejected_step)
////   |> persistent_flow.on_complete(save_result)
////
//// // Start or resume for user
//// use ctx <- persistent_flow.start_or_resume(
////   approval_flow,
////   ctx,
////   user_id: 12345,
////   chat_id: 67890,
//// )
////
//// // Later, resume with external token
//// use ctx <- persistent_flow.resume_with_token(
////   approval_flow,
////   ctx,
////   token,
////   Some(dict.from_list([#("status", "approved")])),
//// )
//// ```
////
//// ## Scene Data
////
//// Scene data provides isolated storage for flow steps:
////
//// ```gleam
//// fn collect_info_step(ctx, instance) {
////   // Store data locally to this scene
////   let instance = persistent_flow.store_scene_data(
////     instance,
////     "temp_input",
////     user_input,
////   )
////
////   // Retrieve scene data
////   case persistent_flow.get_scene_data(instance, "temp_input") {
////     Some(value) -> process_input(value)
////     None -> ask_for_input()
////   }
////
////   // Clear when moving to new scene
////   let instance = persistent_flow.clear_scene_data(instance)
////   Ok(#(ctx, Goto("next_scene"), instance))
//// }
//// ```
////
//// ## Comparison
////
//// - Use `dialog` for simple, immediate interactions
//// - Use `flow` for in-memory multi-step processes
//// - Use `persistent_flow` when state must persist across restarts or integrate with external systems

import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/timestamp

import telega/bot.{type Context}
import telega/conversation/flow
import telega/keyboard
import telega/reply
import telega/update

const return_to_key = "__return_to"

const return_flow_key = "__return_flow"

const caller_id_key = "__caller_id"

const caller_flow_key = "__caller_flow"

const error_step = "error"

/// Persistent flow instance with unique ID
pub type FlowInstance {
  FlowInstance(
    id: String,
    flow_name: String,
    user_id: Int,
    chat_id: Int,
    state: flow.FlowState,
    scene_data: Dict(String, String),
    // Scene-local data
    wait_token: Option(String),
    // Token for external resume
    created_at: Int,
    updated_at: Int,
  )
}

/// Storage interface for persistent flows
pub type FlowStorage {
  FlowStorage(
    save: fn(FlowInstance) -> Result(Nil, String),
    load: fn(String) -> Result(Option(FlowInstance), String),
    delete: fn(String) -> Result(Nil, String),
    list_by_user: fn(Int, Int) -> Result(List(FlowInstance), String),
  )
}

/// Flow registry for managing multiple flows
pub type FlowRegistry(session, error) {
  FlowRegistry(flows: Dict(String, PersistentFlow(session, error)))
}

/// Persistent flow definition
pub type PersistentFlow(session, error) {
  PersistentFlow(
    name: String,
    steps: Dict(String, PersistentStepHandler(session, error)),
    initial_step: String,
    storage: FlowStorage,
    registry: Option(FlowRegistry(session, error)),
    on_complete: Option(
      fn(Context(session, error), FlowInstance) ->
        Result(Context(session, error), error),
    ),
    on_error: Option(
      fn(Context(session, error), FlowInstance, String) ->
        Result(Context(session, error), error),
    ),
  )
}

/// Extended flow actions for persistent flows
pub type PersistentFlowAction {
  StandardAction(flow.FlowAction)
  Wait(token: String)
  // Wait for external resume
  Goto(label: String)
  // Jump to labeled step
  Call(flow_name: String, args: Dict(String, String))
  // Call another flow
  Exit(result: Option(Dict(String, String)))
  // Exit with optional result
}

/// Persistent step handler with state persistence
pub type PersistentStepHandler(session, error) =
  fn(Context(session, error), FlowInstance) ->
    Result(
      #(Context(session, error), PersistentFlowAction, FlowInstance),
      error,
    )

/// Create a new flow registry
pub fn new_registry() -> FlowRegistry(session, error) {
  FlowRegistry(flows: dict.new())
}

/// Add a flow to the registry
pub fn register_flow(
  registry: FlowRegistry(session, error),
  flow: PersistentFlow(session, error),
) -> FlowRegistry(session, error) {
  FlowRegistry(flows: dict.insert(registry.flows, flow.name, flow))
}

/// Create a new persistent flow
pub fn new(
  name: String,
  initial_step: String,
  storage: FlowStorage,
) -> PersistentFlow(session, error) {
  PersistentFlow(
    name: name,
    steps: dict.new(),
    initial_step: initial_step,
    storage: storage,
    registry: None,
    on_complete: None,
    on_error: None,
  )
}

/// Set the flow registry for a flow
pub fn with_registry(
  flow: PersistentFlow(session, error),
  registry: FlowRegistry(session, error),
) -> PersistentFlow(session, error) {
  PersistentFlow(..flow, registry: Some(registry))
}

/// Add a step to the persistent flow
pub fn add_step(
  flow: PersistentFlow(session, error),
  step_name: String,
  handler: PersistentStepHandler(session, error),
) -> PersistentFlow(session, error) {
  PersistentFlow(..flow, steps: dict.insert(flow.steps, step_name, handler))
}

/// Set completion handler
pub fn on_complete(
  flow: PersistentFlow(session, error),
  handler: fn(Context(session, error), FlowInstance) ->
    Result(Context(session, error), error),
) -> PersistentFlow(session, error) {
  PersistentFlow(..flow, on_complete: Some(handler))
}

/// Set error handler
pub fn on_error(
  flow: PersistentFlow(session, error),
  handler: fn(Context(session, error), FlowInstance, String) ->
    Result(Context(session, error), error),
) -> PersistentFlow(session, error) {
  PersistentFlow(..flow, on_error: Some(handler))
}

/// Start or resume a persistent flow
pub fn start_or_resume(
  flow: PersistentFlow(session, error),
  ctx: Context(session, error),
  user_id: Int,
  chat_id: Int,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let flow_id = generate_flow_id(user_id, chat_id, flow.name)

  case flow.storage.load(flow_id) {
    Ok(Some(instance)) -> execute_step(flow, ctx, instance, continue)
    Ok(None) -> {
      start_new_instance(flow, ctx, flow_id, user_id, chat_id, continue)
    }
    Error(err) -> {
      case flow.on_error {
        Some(handler) -> {
          let dummy_instance =
            create_dummy_instance(flow_id, flow.name, user_id, chat_id)
          handler(ctx, dummy_instance, err)
        }
        None -> continue(ctx)
      }
    }
  }
}

/// Start a new flow instance
fn start_new_instance(
  flow: PersistentFlow(session, error),
  ctx: Context(session, error),
  flow_id: String,
  user_id: Int,
  chat_id: Int,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let now = current_timestamp()

  let instance =
    FlowInstance(
      id: flow_id,
      flow_name: flow.name,
      user_id: user_id,
      chat_id: chat_id,
      state: flow.FlowState(
        current_step: flow.initial_step,
        data: dict.new(),
        history: [],
      ),
      scene_data: dict.new(),
      wait_token: None,
      created_at: now,
      updated_at: now,
    )

  // Save initial state
  case flow.storage.save(instance) {
    Ok(_) -> execute_step(flow, ctx, instance, continue)
    Error(err) -> {
      case flow.on_error {
        Some(handler) -> handler(ctx, instance, err)
        None -> continue(ctx)
      }
    }
  }
}

/// Execute current step
fn execute_step(
  flow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case dict.get(flow.steps, instance.state.current_step) {
    Ok(handler) -> {
      case handler(ctx, instance) {
        Ok(#(new_ctx, action, updated_instance)) -> {
          // Save updated state
          let final_instance =
            FlowInstance(..updated_instance, updated_at: current_timestamp())

          case flow.storage.save(final_instance) {
            Ok(_) ->
              handle_action(flow, new_ctx, final_instance, action, continue)
            Error(err) -> {
              case flow.on_error {
                Some(error_handler) ->
                  error_handler(new_ctx, final_instance, err)
                None -> continue(new_ctx)
              }
            }
          }
        }
        Error(err) -> Error(err)
      }
    }
    Error(_) -> {
      // Step not found
      case flow.on_error {
        Some(handler) ->
          handler(
            ctx,
            instance,
            "Step not found: " <> instance.state.current_step,
          )
        None -> continue(ctx)
      }
    }
  }
}

/// Handle flow action
fn handle_action(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  action: PersistentFlowAction,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case action {
    StandardAction(flow_action) ->
      handle_standard_action(pflow, ctx, instance, flow_action, continue)

    Wait(token) -> handle_wait_action(pflow, ctx, instance, token, continue)

    Goto(label) -> handle_goto_action(pflow, ctx, instance, label, continue)

    Call(flow_name, args) ->
      handle_call_action(pflow, ctx, instance, flow_name, args, continue)

    Exit(result) -> handle_exit_action(pflow, ctx, instance, result, continue)
  }
}

/// Handle wait action
fn handle_wait_action(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  token: String,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let updated_instance = FlowInstance(..instance, wait_token: Some(token))
  save_and_continue(pflow, ctx, updated_instance, continue)
}

/// Handle goto action
fn handle_goto_action(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  label: String,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let updated_instance =
    FlowInstance(
      ..instance,
      state: flow.FlowState(..instance.state, current_step: label, history: [
        instance.state.current_step,
        ..instance.state.history
      ]),
    )
  execute_step(pflow, ctx, updated_instance, continue)
}

/// Save instance and continue or handle error
fn save_and_continue(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case pflow.storage.save(instance) {
    Ok(_) -> continue(ctx)
    Error(err) -> handle_error(pflow, ctx, instance, err, continue)
  }
}

/// Handle error with optional error handler
fn handle_error(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  err: String,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case pflow.on_error {
    Some(handler) -> handler(ctx, instance, err)
    None -> continue(ctx)
  }
}

/// Handle call action - call another flow
fn handle_call_action(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  flow_name: String,
  args: Dict(String, String),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case pflow.registry {
    Some(registry) ->
      execute_call_with_registry(
        pflow,
        ctx,
        instance,
        flow_name,
        args,
        registry,
        continue,
      )
    None -> {
      let error_msg =
        "No flow registry configured for flow '" <> pflow.name <> "'"
      handle_error(pflow, ctx, instance, error_msg, continue)
    }
  }
}

/// Execute call action with registry
fn execute_call_with_registry(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  flow_name: String,
  args: Dict(String, String),
  registry: FlowRegistry(session, error),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case dict.get(registry.flows, flow_name) {
    Ok(called_flow) -> {
      let caller_instance = prepare_caller_instance(instance, pflow.name)

      case pflow.storage.save(caller_instance) {
        Ok(_) -> {
          let new_instance =
            create_called_flow_instance(
              instance,
              flow_name,
              called_flow.initial_step,
              args,
              pflow.name,
            )

          case called_flow.storage.save(new_instance) {
            Ok(_) -> execute_step(called_flow, ctx, new_instance, continue)
            Error(err) -> handle_error(pflow, ctx, new_instance, err, continue)
          }
        }
        Error(err) -> handle_error(pflow, ctx, caller_instance, err, continue)
      }
    }
    Error(_) -> {
      let error_msg = "Flow '" <> flow_name <> "' not found in registry"
      handle_error(pflow, ctx, instance, error_msg, continue)
    }
  }
}

/// Prepare caller instance with return context
fn prepare_caller_instance(
  instance: FlowInstance,
  flow_name: String,
) -> FlowInstance {
  FlowInstance(
    ..instance,
    state: flow.FlowState(
      ..instance.state,
      data: dict.insert(instance.state.data, return_to_key, instance.id)
        |> dict.insert(return_flow_key, flow_name),
    ),
  )
}

/// Create new instance for called flow
fn create_called_flow_instance(
  caller: FlowInstance,
  flow_name: String,
  initial_step: String,
  args: Dict(String, String),
  caller_flow_name: String,
) -> FlowInstance {
  let flow_id = generate_flow_id(caller.user_id, caller.chat_id, flow_name)
  let now = current_timestamp()

  FlowInstance(
    id: flow_id,
    flow_name: flow_name,
    user_id: caller.user_id,
    chat_id: caller.chat_id,
    state: flow.FlowState(
      current_step: initial_step,
      data: dict.insert(args, caller_id_key, caller.id)
        |> dict.insert(caller_flow_key, caller_flow_name),
      history: [],
    ),
    scene_data: dict.new(),
    wait_token: None,
    created_at: now,
    updated_at: now,
  )
}

/// Handle exit action
fn handle_exit_action(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  result: Option(Dict(String, String)),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let caller_id =
    dict.get(instance.state.data, caller_id_key) |> result.unwrap("")
  let caller_flow_name =
    dict.get(instance.state.data, caller_flow_key) |> result.unwrap("")

  // Delete current instance
  let _ = pflow.storage.delete(instance.id)

  case has_caller(caller_id, caller_flow_name) {
    True ->
      return_to_caller(
        pflow,
        ctx,
        instance,
        caller_id,
        caller_flow_name,
        result,
        continue,
      )
    False -> complete_flow(pflow, ctx, instance, result, continue)
  }
}

/// Check if flow has a caller
fn has_caller(caller_id: String, caller_flow_name: String) -> Bool {
  caller_id != "" && caller_flow_name != ""
}

/// Complete flow normally
fn complete_flow(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  result: Option(Dict(String, String)),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case result {
    Some(data) -> {
      let final_instance =
        FlowInstance(
          ..instance,
          state: flow.FlowState(
            ..instance.state,
            data: dict.merge(instance.state.data, data),
          ),
        )
      invoke_completion_handler(pflow, ctx, final_instance, continue)
    }
    None -> invoke_completion_handler(pflow, ctx, instance, continue)
  }
}

/// Return to caller flow
fn return_to_caller(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  caller_id: String,
  caller_flow_name: String,
  result: Option(Dict(String, String)),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case pflow.registry {
    Some(registry) -> {
      case dict.get(registry.flows, caller_flow_name) {
        Ok(caller_flow) ->
          resume_caller_flow(
            caller_flow,
            ctx,
            instance,
            caller_id,
            result,
            pflow,
            continue,
          )
        Error(_) -> complete_flow(pflow, ctx, instance, result, continue)
      }
    }
    None -> complete_flow(pflow, ctx, instance, result, continue)
  }
}

/// Resume caller flow execution
fn resume_caller_flow(
  caller_flow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  caller_id: String,
  result: Option(Dict(String, String)),
  pflow: PersistentFlow(session, error),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case caller_flow.storage.load(caller_id) {
    Ok(Some(caller_instance)) -> {
      let updated_caller = update_caller_with_result(caller_instance, result)
      execute_step(caller_flow, ctx, updated_caller, continue)
    }
    _ -> complete_flow(pflow, ctx, instance, result, continue)
  }
}

/// Update caller instance with result data
fn update_caller_with_result(
  caller_instance: FlowInstance,
  result: Option(Dict(String, String)),
) -> FlowInstance {
  case result {
    Some(data) ->
      FlowInstance(
        ..caller_instance,
        state: flow.FlowState(
          ..caller_instance.state,
          data: dict.merge(caller_instance.state.data, data),
        ),
        scene_data: dict.new(),
      )
    None -> FlowInstance(..caller_instance, scene_data: dict.new())
  }
}

/// Invoke completion handler if exists
fn invoke_completion_handler(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case pflow.on_complete {
    Some(handler) -> handler(ctx, instance)
    None -> continue(ctx)
  }
}

/// Handle standard flow actions
fn handle_standard_action(
  pflow: PersistentFlow(session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  action: flow.FlowAction,
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case action {
    flow.Next(step) -> {
      let updated_instance =
        FlowInstance(
          ..instance,
          state: flow.FlowState(..instance.state, current_step: step, history: [
            instance.state.current_step,
            ..instance.state.history
          ]),
        )
      execute_step(pflow, ctx, updated_instance, continue)
    }

    flow.Back -> {
      case instance.state.history {
        [previous, ..rest] -> {
          let updated_instance =
            FlowInstance(
              ..instance,
              state: flow.FlowState(
                ..instance.state,
                current_step: previous,
                history: rest,
              ),
            )
          execute_step(pflow, ctx, updated_instance, continue)
        }
        [] -> execute_step(pflow, ctx, instance, continue)
      }
    }

    flow.Jump(step) -> {
      let updated_instance =
        FlowInstance(
          ..instance,
          state: flow.FlowState(..instance.state, current_step: step, history: [
            instance.state.current_step,
            ..instance.state.history
          ]),
        )
      execute_step(pflow, ctx, updated_instance, continue)
    }

    flow.Complete(data) -> {
      // Delete completed flow
      let _ = pflow.storage.delete(instance.id)
      // Update instance data with completion data
      let final_instance =
        FlowInstance(..instance, state: flow.FlowState(..instance.state, data:))
      case pflow.on_complete {
        Some(handler) -> handler(ctx, final_instance)
        None -> continue(ctx)
      }
    }

    flow.Cancel -> {
      // Delete cancelled flow
      let _ = pflow.storage.delete(instance.id)
      continue(ctx)
    }
  }
}

/// Generate unique flow ID
fn generate_flow_id(user_id: Int, chat_id: Int, flow_name: String) -> String {
  int.to_string(chat_id) <> ":" <> int.to_string(user_id) <> ":" <> flow_name
}

/// Create dummy instance for error handling
fn create_dummy_instance(
  flow_id: String,
  flow_name: String,
  user_id: Int,
  chat_id: Int,
) -> FlowInstance {
  FlowInstance(
    id: flow_id,
    flow_name: flow_name,
    user_id: user_id,
    chat_id: chat_id,
    state: flow.FlowState(
      current_step: error_step,
      data: dict.new(),
      history: [],
    ),
    scene_data: dict.new(),
    wait_token: None,
    created_at: 0,
    updated_at: 0,
  )
}

/// Get current timestamp in Unix seconds
fn current_timestamp() -> Int {
  let ts = timestamp.system_time()
  // Convert to Unix seconds (as Int)
  let seconds = timestamp.to_unix_seconds(ts)
  // Round to nearest integer if needed
  case seconds {
    s if s <. 0.0 -> 0
    s -> {
      let rounded = s +. 0.5
      case rounded >=. 2_147_483_647.0 {
        True -> 2_147_483_647
        // Max Int32
        False -> {
          // Convert float to int by truncating
          let str = float.to_string(rounded)
          case string.split(str, ".") {
            [int_part, ..] -> int.parse(int_part) |> result.unwrap(0)
            _ -> 0
          }
        }
      }
    }
  }
}

/// Extract user_id and chat_id from Context.update
fn extract_ids_from_context(ctx: Context(session, error)) -> #(Int, Int) {
  #(ctx.update.from_id, ctx.update.chat_id)
}

/// Generate unique wait token
pub fn generate_wait_token(instance: FlowInstance) -> String {
  instance.id <> ":" <> int.to_string(current_timestamp())
}

/// Store scene-local data
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

/// Get scene-local data
pub fn get_scene_data(instance: FlowInstance, key: String) -> Option(String) {
  case dict.get(instance.scene_data, key) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}

/// Clear scene data (useful when entering new scene)
pub fn clear_scene_data(instance: FlowInstance) -> FlowInstance {
  FlowInstance(..instance, scene_data: dict.new())
}

/// Resume flow with external token
pub fn resume_with_token(
  flow: PersistentFlow(session, error),
  ctx: Context(session, error),
  token: String,
  data: Option(Dict(String, String)),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  case find_instance_by_token(flow.storage, token) {
    Ok(Some(instance)) -> {
      let updated_instance = case data {
        Some(d) ->
          FlowInstance(
            ..instance,
            state: flow.FlowState(
              ..instance.state,
              data: dict.merge(instance.state.data, d),
            ),
            wait_token: None,
          )
        None -> FlowInstance(..instance, wait_token: None)
      }
      execute_step(flow, ctx, updated_instance, continue)
    }
    _ -> continue(ctx)
  }
}

/// Helper to find instance by wait token
fn find_instance_by_token(
  storage: FlowStorage,
  token: String,
) -> Result(Option(FlowInstance), String) {
  // Token format: "instance_id:timestamp"
  case string.split(token, ":") {
    [instance_id, ..] -> storage.load(instance_id)
    _ -> Ok(None)
  }
}

/// Memory storage implementation for testing
///
/// This is a no-op storage that doesn't actually persist anything.
/// Useful for unit tests where storage behavior isn't important.
pub fn memory_storage() -> FlowStorage {
  FlowStorage(
    save: fn(_instance) { Ok(Nil) },
    load: fn(_id) { Ok(None) },
    delete: fn(_id) { Ok(Nil) },
    list_by_user: fn(_user_id, _chat_id) { Ok([]) },
  )
}

/// Common step: Text input with persistence
///
/// This step sends a prompt to the user and waits for their text response.
/// The response will be stored in the flow state under the specified data_key.
/// After receiving the text, the flow continues to the next_step.
pub fn text_step(
  prompt: String,
  data_key: String,
  next_step: String,
) -> PersistentStepHandler(session, error) {
  fn(ctx, instance) {
    case reply.with_text(ctx, prompt) {
      Ok(_) -> {
        // Generate a unique token for this wait state
        let token = generate_wait_token(instance)

        // Store the data key and next step so we know where to save input
        // and where to go next when the flow resumes
        let updated_instance =
          instance
          |> store_scene_data("text_data_key", data_key)
          |> store_scene_data("text_next_step", next_step)

        // Wait for text input - the flow will be paused here
        // and resumed when text is received
        Ok(#(ctx, Wait(token), updated_instance))
      }
      Error(_) -> Ok(#(ctx, StandardAction(flow.Cancel), instance))
    }
  }
}

/// Common step: Message display
pub fn message_step(
  message_fn: fn(FlowInstance) -> String,
  next_step: Option(String),
) -> PersistentStepHandler(session, error) {
  fn(ctx, instance) {
    let message = message_fn(instance)
    case reply.with_text(ctx, message) {
      Ok(_) -> {
        case next_step {
          Some(step) -> Ok(#(ctx, StandardAction(flow.Next(step)), instance))
          None ->
            Ok(#(
              ctx,
              StandardAction(flow.Complete(instance.state.data)),
              instance,
            ))
        }
      }
      Error(_) -> Ok(#(ctx, StandardAction(flow.Cancel), instance))
    }
  }
}

/// Start a flow for a user
pub fn start(
  flow: PersistentFlow(session, error),
  ctx: Context(session, error),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let #(from_id, chat_id) = extract_ids_from_context(ctx)
  start_or_resume(flow, ctx, from_id, chat_id, continue)
}

/// Start a flow with initial data
pub fn start_with_data(
  flow: PersistentFlow(session, error),
  ctx: Context(session, error),
  initial_data: Dict(String, String),
  continue: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let #(from_id, chat_id) = extract_ids_from_context(ctx)
  let flow_id = generate_flow_id(from_id, chat_id, flow.name)
  let now = current_timestamp()

  let instance =
    FlowInstance(
      id: flow_id,
      flow_name: flow.name,
      user_id: from_id,
      chat_id: chat_id,
      state: flow.FlowState(
        current_step: flow.initial_step,
        data: initial_data,
        history: [],
      ),
      scene_data: dict.new(),
      wait_token: None,
      created_at: now,
      updated_at: now,
    )

  // Save initial state
  case flow.storage.save(instance) {
    Ok(_) -> execute_step(flow, ctx, instance, continue)
    Error(err) -> {
      case flow.on_error {
        Some(handler) -> handler(ctx, instance, err)
        None -> continue(ctx)
      }
    }
  }
}

/// Create a router handler that starts a persistent flow
///
/// ## Example
///
/// ```gleam
/// let registration_flow = persistent_flow.new("registration", "welcome", storage)
///   |> persistent_flow.add_step("welcome", welcome_step)
///   |> persistent_flow.add_step("name", collect_name_step)
///
/// router.new("my_bot")
///   |> router.on_command("register", persistent_flow.to_handler(registration_flow))
/// ```
pub fn to_handler(
  flow: PersistentFlow(session, error),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _command) { start(flow, ctx, fn(ctx) { Ok(ctx) }) }
}

/// Create a router handler that starts a flow with initial data
///
/// ## Example
///
/// ```gleam
/// router.new("my_bot")
///   |> router.on_command("book", persistent_flow.to_handler_with_data(
///     booking_flow,
///     dict.from_list([#("source", "command")])
///   ))
/// ```
pub fn to_handler_with_data(
  flow: PersistentFlow(session, error),
  initial_data: Dict(String, String),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _update) {
    start_with_data(flow, ctx, initial_data, fn(ctx) { Ok(ctx) })
  }
}

/// Create a router handler for resuming flows from callback queries
///
/// ## Example
///
/// ```gleam
/// router.new("my_bot")
///   |> router.on_callback(Prefix("resume:"), persistent_flow.resume_handler(flow))
/// ```
pub fn resume_handler(
  flow: PersistentFlow(session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, update) {
    case update {
      update.CallbackQueryUpdate(query:, ..) -> {
        // Extract token from callback data (e.g., "resume:token123")
        let data = option.unwrap(query.data, "")
        let token = case string.split(data, ":") {
          [_prefix, token, ..] -> token
          _ -> data
        }

        resume_with_token(flow, ctx, token, None, fn(ctx) { Ok(ctx) })
      }
      _ -> Ok(ctx)
    }
  }
}

/// Create a router handler for resuming flows from callback queries with keyboard parsing
///
/// ## Example
///
/// ```gleam
/// let callback_data = keyboard.string_callback_data("flow_resume")
/// router.new("my_bot")
///   |> router.on_callback(Prefix("flow_resume:"),
///      persistent_flow.resume_handler_with_keyboard(flow, callback_data))
/// ```
pub fn resume_handler_with_keyboard(
  flow: PersistentFlow(session, error),
  callback_data: keyboard.KeyboardCallbackData(String),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, update) {
    case update {
      update.CallbackQueryUpdate(query:, ..) -> {
        let data = option.unwrap(query.data, "")
        // Use keyboard module to properly parse the callback
        case keyboard.unpack_callback(data, callback_data) {
          Ok(callback) -> {
            // The token is stored in the callback data
            resume_with_token(flow, ctx, callback.data, None, fn(ctx) {
              Ok(ctx)
            })
          }
          Error(_) -> {
            // Fallback to simple parsing if keyboard parsing fails
            let token = case string.split(data, ":") {
              [_prefix, token, ..] -> token
              _ -> data
            }
            resume_with_token(flow, ctx, token, None, fn(ctx) { Ok(ctx) })
          }
        }
      }
      _ -> Ok(ctx)
    }
  }
}

///
/// ```gleam
/// router.new("my_bot")
///   |> router.on_any_text(persistent_flow.text_handler(flow))
/// ```
pub fn text_handler(
  flow: PersistentFlow(session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, update) {
    case update {
      update.TextUpdate(text:, from_id:, chat_id:, ..) -> {
        // Check if user has an active flow waiting for input
        let user_id = from_id
        let chat_id = chat_id

        case flow.storage.list_by_user(user_id, chat_id) {
          Ok([instance, ..]) if instance.wait_token != None -> {
            // Resume flow with text input
            let data = dict.from_list([#("user_input", text)])
            resume_with_token(
              flow,
              ctx,
              option.unwrap(instance.wait_token, ""),
              Some(data),
              fn(ctx) { Ok(ctx) },
            )
          }
          _ -> {
            // No active flow, let other handlers process
            Ok(ctx)
          }
        }
      }
      _ -> Ok(ctx)
    }
  }
}
