//// Shared type definitions for the flow system.
////
//// This module contains all types used across flow submodules.

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/option.{type Option}
import telega/bot.{type Context}
import telega/router

/// Flow state representing current step and data
@internal
pub type FlowState {
  FlowState(
    // Internal string representation for storage
    current_step: String,
    data: Dict(String, String),
    history: List(String),
    // Stack for nested flows
    flow_stack: List(FlowStackFrame),
    // Parallel execution state
    parallel_state: Option(ParallelState),
  )
}

/// Stack frame for nested flow calls
@internal
pub type FlowStackFrame {
  FlowStackFrame(
    flow_name: String,
    return_step: String,
    saved_data: Dict(String, String),
  )
}

/// State for parallel step execution
@internal
pub type ParallelState {
  ParallelState(
    pending_steps: List(String),
    completed_steps: List(String),
    results: Dict(String, Dict(String, String)),
    join_step: String,
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
    // Step-local data (cleared on step transitions)
    step_data: Dict(String, String),
    // Token for external resume
    wait_token: Option(String),
    // Timestamp when current wait expires
    wait_timeout_at: Option(Int),
    created_at: Int,
    updated_at: Int,
  )
}

/// Result of waiting for user input or callback
pub type WaitResult {
  /// Text message from user
  TextInput(value: String)
  /// Yes/No callback button press
  BoolCallback(value: Bool)
  /// Other callback data (non-boolean)
  DataCallback(value: String)
  /// Photo message (list of file_ids for different sizes)
  PhotoInput(file_ids: List(String))
  /// Video message
  VideoInput(file_id: String)
  /// Voice message
  VoiceInput(file_id: String)
  /// Audio message
  AudioInput(file_id: String)
  /// Location message
  LocationInput(latitude: Float, longitude: Float)
  /// Command message
  CommandInput(command: String, payload: String)
  /// No input yet (first visit to step)
  Pending
}

/// Flat representation of a FlowInstance for database serialization
pub type FlowInstanceRow {
  FlowInstanceRow(
    id: String,
    flow_name: String,
    user_id: Int,
    chat_id: Int,
    current_step: String,
    data: Dict(String, String),
    step_data: Dict(String, String),
    wait_token: Option(String),
    wait_timeout_at: Option(Int),
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

/// Hook called when entering a flow (from trigger or from parent flow)
pub type FlowEnterHook(session, error, dependencies) =
  fn(Context(session, error, dependencies), FlowInstance) ->
    Result(#(Context(session, error, dependencies), FlowInstance), error)

/// Hook called when leaving a flow to enter a subflow
pub type FlowLeaveHook(session, error, dependencies) =
  fn(Context(session, error, dependencies), FlowInstance) ->
    Result(#(Context(session, error, dependencies), FlowInstance), error)

/// Hook called when completely exiting the flow (cancel or complete)
pub type FlowExitHook(session, error, dependencies) =
  fn(Context(session, error, dependencies), FlowInstance) ->
    Result(Context(session, error, dependencies), error)

pub type StepHandler(step_type, session, error, dependencies) =
  fn(Context(session, error, dependencies), FlowInstance) ->
    StepResult(step_type, session, error, dependencies)

pub type StepMiddleware(step_type, session, error, dependencies) =
  fn(
    Context(session, error, dependencies),
    FlowInstance,
    fn() -> StepResult(step_type, session, error, dependencies),
  ) -> StepResult(step_type, session, error, dependencies)

/// Hook called when entering a step (before the handler)
pub type StepEnterHook(session, error, dependencies) =
  fn(Context(session, error, dependencies), FlowInstance) ->
    Result(#(Context(session, error, dependencies), FlowInstance), error)

/// Hook called when leaving a step (after the handler, before transition)
pub type StepLeaveHook(session, error, dependencies) =
  fn(Context(session, error, dependencies), FlowInstance) ->
    Result(#(Context(session, error, dependencies), FlowInstance), error)

pub type StepConfig(step_type, session, error, dependencies) {
  StepConfig(
    handler: StepHandler(step_type, session, error, dependencies),
    middlewares: List(StepMiddleware(step_type, session, error, dependencies)),
    on_enter: Option(StepEnterHook(session, error, dependencies)),
    on_leave: Option(StepLeaveHook(session, error, dependencies)),
  )
}

pub type ConditionalTransition(step_type) {
  ConditionalTransition(
    from: String,
    conditions: List(#(fn(FlowInstance) -> Bool, step_type)),
    default: step_type,
  )
}

pub type ParallelConfig(step_type) {
  ParallelConfig(
    trigger_step: String,
    parallel_steps: List(step_type),
    join_step: step_type,
  )
}

/// Sub-flow configuration
pub type SubflowConfig(step_type, session, error, dependencies) {
  SubflowConfig(
    trigger_step: String,
    flow: Flow(Dynamic, session, error, dependencies),
    return_step: step_type,
    map_args: fn(FlowInstance) -> Dict(String, String),
    map_result: fn(Dict(String, String), FlowInstance) -> FlowInstance,
  )
}

/// Result type for flow steps
pub type StepResult(step_type, session, error, dependencies) =
  Result(
    #(
      Context(session, error, dependencies),
      FlowAction(step_type),
      FlowInstance,
    ),
    error,
  )

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
  Wait
  /// Wait for callback query
  WaitCallback
  /// Wait for user input with timeout
  WaitWithTimeout(timeout_ms: Int)
  /// Wait for callback query with timeout
  WaitCallbackWithTimeout(timeout_ms: Int)
  /// Jump to any step (clears step data)
  GoTo(step_type)
  /// Exit flow with result
  Exit(Option(Dict(String, String)))
  /// Return from subflow
  ReturnFromSubflow(result: Dict(String, String))
  /// Start parallel execution
  StartParallel(steps: List(step_type), join_at: step_type)
  /// Complete a parallel step
  CompleteParallelStep(step: step_type, result: Dict(String, String))
  /// Enter a subflow (pushes current state to stack)
  EnterSubflow(subflow_name: String, data: Dict(String, String))
}

/// Built flow ready for execution
pub type Flow(step_type, session, error, dependencies) {
  Flow(
    name: String,
    steps: Dict(String, StepConfig(step_type, session, error, dependencies)),
    initial_step: step_type,
    step_to_string: fn(step_type) -> String,
    string_to_step: fn(String) -> Result(step_type, Nil),
    storage: FlowStorage(error),
    on_complete: Option(
      fn(Context(session, error, dependencies), FlowInstance) ->
        Result(Context(session, error, dependencies), error),
    ),
    on_error: Option(
      fn(Context(session, error, dependencies), FlowInstance, Option(error)) ->
        Result(Context(session, error, dependencies), error),
    ),
    global_middlewares: List(
      StepMiddleware(step_type, session, error, dependencies),
    ),
    conditionals: List(ConditionalTransition(step_type)),
    parallel_configs: List(ParallelConfig(step_type)),
    subflows: List(SubflowConfig(step_type, session, error, dependencies)),
    // Flow lifecycle hooks
    on_flow_enter: Option(FlowEnterHook(session, error, dependencies)),
    on_flow_leave: Option(FlowLeaveHook(session, error, dependencies)),
    on_flow_exit: Option(FlowExitHook(session, error, dependencies)),
    // Timeout configuration
    ttl_ms: Option(Int),
    on_timeout: Option(FlowExitHook(session, error, dependencies)),
  )
}

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

/// Inline subflow step type (uses strings internally)
pub type InlineStep {
  InlineStep(name: String)
}

/// Composed step type for flow composition
pub type ComposedStep {
  ComposedFlowStep(Int)
  ComposedSelectFlow
  ComposedStartParallel
  ComposedParallelFlow(Int)
  ComposedMergeResults
}
