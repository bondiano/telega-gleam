//// FlowBuilder and all builder functions for constructing flows.

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import telega/bot.{type Context}
import telega/flow/types.{
  type ConditionalTransition, type Flow, type FlowEnterHook, type FlowExitHook,
  type FlowLeaveHook, type FlowStorage, type InlineStep, type ParallelConfig,
  type StepConfig, type StepEnterHook, type StepHandler, type StepLeaveHook,
  type StepMiddleware, type StepResult, type SubflowConfig,
  ConditionalTransition, Flow, InlineStep, ParallelConfig, StepConfig,
  SubflowConfig,
}

pub opaque type FlowBuilder(step_type, session, error) {
  FlowBuilder(
    flow_name: String,
    steps: Dict(String, StepConfig(step_type, session, error)),
    step_to_string: fn(step_type) -> String,
    string_to_step: fn(String) -> Result(step_type, Nil),
    storage: FlowStorage(error),
    on_complete: Option(
      fn(Context(session, error), types.FlowInstance) ->
        Result(Context(session, error), error),
    ),
    on_error: Option(
      fn(Context(session, error), types.FlowInstance, Option(error)) ->
        Result(Context(session, error), error),
    ),
    global_middlewares: List(StepMiddleware(step_type, session, error)),
    conditionals: List(ConditionalTransition(step_type)),
    parallel_configs: List(ParallelConfig(step_type)),
    subflows: List(SubflowConfig(step_type, session, error)),
    on_flow_enter: Option(FlowEnterHook(session, error)),
    on_flow_leave: Option(FlowLeaveHook(session, error)),
    on_flow_exit: Option(FlowExitHook(session, error)),
    ttl_ms: Option(Int),
    on_timeout: Option(types.FlowExitHook(session, error)),
  )
}

/// Create a new flow builder
pub fn new(
  flow_name: String,
  storage: FlowStorage(error),
  step_to_string: fn(step_type) -> String,
  string_to_step: fn(String) -> Result(step_type, Nil),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(
    flow_name:,
    steps: dict.new(),
    step_to_string:,
    string_to_step:,
    storage:,
    on_complete: None,
    on_error: None,
    global_middlewares: [],
    conditionals: [],
    parallel_configs: [],
    subflows: [],
    on_flow_enter: None,
    on_flow_leave: None,
    on_flow_exit: None,
    ttl_ms: None,
    on_timeout: None,
  )
}

/// Create a flow builder with default string conversion (uses string.inspect)
pub fn new_with_default_converters(
  flow_name: String,
  storage: FlowStorage(error),
  steps: List(#(String, step_type)),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(
    flow_name:,
    storage:,
    steps: dict.new(),
    step_to_string: string.inspect,
    string_to_step: create_string_to_step(steps),
    on_complete: None,
    on_error: None,
    global_middlewares: [],
    conditionals: [],
    parallel_configs: [],
    subflows: [],
    on_flow_enter: None,
    on_flow_leave: None,
    on_flow_exit: None,
    ttl_ms: None,
    on_timeout: None,
  )
}

/// Add a step to the flow
pub fn add_step(
  builder: FlowBuilder(step_type, session, error),
  step: step_type,
  handler: StepHandler(step_type, session, error),
) -> FlowBuilder(step_type, session, error) {
  let step_name = builder.step_to_string(step)
  let config =
    StepConfig(handler:, middlewares: [], on_enter: None, on_leave: None)
  FlowBuilder(..builder, steps: dict.insert(builder.steps, step_name, config))
}

/// Add a step with middleware
pub fn add_step_with_middleware(
  builder: FlowBuilder(step_type, session, error),
  step: step_type,
  middlewares: List(StepMiddleware(step_type, session, error)),
  handler: StepHandler(step_type, session, error),
) -> FlowBuilder(step_type, session, error) {
  let step_name = builder.step_to_string(step)
  let config =
    StepConfig(handler:, middlewares:, on_enter: None, on_leave: None)
  FlowBuilder(..builder, steps: dict.insert(builder.steps, step_name, config))
}

/// Add a step with lifecycle hooks
pub fn add_step_with_hooks(
  builder: FlowBuilder(step_type, session, error),
  step: step_type,
  handler handler: StepHandler(step_type, session, error),
  on_enter on_enter: Option(StepEnterHook(session, error)),
  on_leave on_leave: Option(StepLeaveHook(session, error)),
) -> FlowBuilder(step_type, session, error) {
  let step_name = builder.step_to_string(step)
  let config = StepConfig(handler:, middlewares: [], on_enter:, on_leave:)
  FlowBuilder(..builder, steps: dict.insert(builder.steps, step_name, config))
}

/// Add a step with hooks and middleware
pub fn add_step_with_hooks_and_middleware(
  builder: FlowBuilder(step_type, session, error),
  step: step_type,
  handler handler: StepHandler(step_type, session, error),
  middlewares middlewares: List(StepMiddleware(step_type, session, error)),
  on_enter on_enter: Option(StepEnterHook(session, error)),
  on_leave on_leave: Option(StepLeaveHook(session, error)),
) -> FlowBuilder(step_type, session, error) {
  let step_name = builder.step_to_string(step)
  let config = StepConfig(handler:, middlewares:, on_enter:, on_leave:)
  FlowBuilder(..builder, steps: dict.insert(builder.steps, step_name, config))
}

/// Add global middleware that applies to all steps
pub fn add_global_middleware(
  builder: FlowBuilder(step_type, session, error),
  middleware: StepMiddleware(step_type, session, error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(
    ..builder,
    global_middlewares: list.append(builder.global_middlewares, [middleware]),
  )
}

/// Add conditional transition
pub fn add_conditional(
  builder: FlowBuilder(step_type, session, error),
  from: step_type,
  condition: fn(types.FlowInstance) -> Bool,
  true on_true: step_type,
  false on_false: step_type,
) -> FlowBuilder(step_type, session, error) {
  let from_str = builder.step_to_string(from)
  let conditional =
    ConditionalTransition(
      from: from_str,
      conditions: [#(condition, on_true)],
      default: on_false,
    )
  FlowBuilder(
    ..builder,
    conditionals: list.append(builder.conditionals, [conditional]),
  )
}

/// Add multi-way conditional
pub fn add_multi_conditional(
  builder: FlowBuilder(step_type, session, error),
  from: step_type,
  conditions: List(#(fn(types.FlowInstance) -> Bool, step_type)),
  default: step_type,
) -> FlowBuilder(step_type, session, error) {
  let from_str = builder.step_to_string(from)
  let conditional = ConditionalTransition(from: from_str, conditions:, default:)
  FlowBuilder(
    ..builder,
    conditionals: list.append(builder.conditionals, [conditional]),
  )
}

/// Add parallel step execution (simplified API).
pub fn parallel(
  builder: FlowBuilder(step_type, session, error),
  from from: step_type,
  steps steps: List(step_type),
  join join: step_type,
) -> FlowBuilder(step_type, session, error) {
  add_parallel_steps(builder, from, steps, join)
}

/// Add parallel step execution.
///
/// @deprecated Use `parallel()` instead for cleaner API.
pub fn add_parallel_steps(
  builder: FlowBuilder(step_type, session, error),
  trigger_step: step_type,
  parallel_steps: List(step_type),
  join_at: step_type,
) -> FlowBuilder(step_type, session, error) {
  let trigger_str = builder.step_to_string(trigger_step)
  let config =
    ParallelConfig(
      trigger_step: trigger_str,
      parallel_steps:,
      join_step: join_at,
    )
  FlowBuilder(
    ..builder,
    parallel_configs: list.append(builder.parallel_configs, [config]),
  )
}

/// Add sub-flow
pub fn add_subflow(
  builder: FlowBuilder(step_type, session, error),
  trigger_step: step_type,
  subflow subflow: Flow(Dynamic, session, error),
  return_to return_to: step_type,
  map_args map_args: fn(types.FlowInstance) -> Dict(String, String),
  map_result map_result: fn(Dict(String, String), types.FlowInstance) ->
    types.FlowInstance,
) -> FlowBuilder(step_type, session, error) {
  let trigger_str = builder.step_to_string(trigger_step)
  let config =
    SubflowConfig(
      trigger_step: trigger_str,
      flow: subflow,
      return_step: return_to,
      map_args:,
      map_result:,
    )
  FlowBuilder(..builder, subflows: list.append(builder.subflows, [config]))
}

/// Add an inline subflow defined within the parent flow
pub fn with_inline_subflow(
  builder: FlowBuilder(step_type, session, error),
  name name: String,
  trigger trigger: step_type,
  return_to return_to: step_type,
  initial initial: String,
  steps steps: List(
    #(
      String,
      fn(Context(session, error), types.FlowInstance) ->
        StepResult(InlineStep, session, error),
    ),
  ),
) -> FlowBuilder(step_type, session, error) {
  let inline_flow_name = builder.flow_name <> "::" <> name
  let inline_storage = builder.storage

  let inline_builder =
    new(
      inline_flow_name,
      inline_storage,
      inline_step_to_string,
      string_to_inline_step,
    )

  let inline_builder =
    list.fold(steps, inline_builder, fn(b, step_tuple) {
      let #(step_name, handler) = step_tuple
      add_step(b, InlineStep(step_name), handler)
    })

  let inline_flow = build(inline_builder, initial: InlineStep(initial))
  let coerced_flow: Flow(Dynamic, session, error) = unsafe_coerce(inline_flow)

  add_subflow(
    builder,
    trigger,
    coerced_flow,
    return_to,
    fn(instance) { instance.state.data },
    fn(result, instance) {
      types.FlowInstance(
        ..instance,
        state: types.FlowState(
          ..instance.state,
          data: dict.merge(instance.state.data, result),
        ),
      )
    },
  )
}

/// Add an inline subflow with custom argument and result mapping
pub fn with_inline_subflow_mapped(
  builder: FlowBuilder(step_type, session, error),
  name name: String,
  trigger trigger: step_type,
  return_to return_to: step_type,
  initial initial: String,
  steps steps: List(
    #(
      String,
      fn(Context(session, error), types.FlowInstance) ->
        StepResult(InlineStep, session, error),
    ),
  ),
  map_args map_args: fn(types.FlowInstance) -> Dict(String, String),
  map_result map_result: fn(Dict(String, String), types.FlowInstance) ->
    types.FlowInstance,
) -> FlowBuilder(step_type, session, error) {
  let inline_flow_name = builder.flow_name <> "::" <> name
  let inline_storage = builder.storage

  let inline_builder =
    new(
      inline_flow_name,
      inline_storage,
      inline_step_to_string,
      string_to_inline_step,
    )

  let inline_builder =
    list.fold(steps, inline_builder, fn(b, step_tuple) {
      let #(step_name, handler) = step_tuple
      add_step(b, InlineStep(step_name), handler)
    })

  let inline_flow = build(inline_builder, initial: InlineStep(initial))
  let coerced_flow: Flow(Dynamic, session, error) = unsafe_coerce(inline_flow)

  add_subflow(builder, trigger, coerced_flow, return_to, map_args, map_result)
}

/// Navigate to next inline step by name
pub fn inline_next(
  ctx: Context(session, error),
  instance: types.FlowInstance,
  step_name step_name: String,
) -> StepResult(InlineStep, session, error) {
  Ok(#(ctx, types.Next(InlineStep(step_name)), instance))
}

/// Set completion handler
pub fn on_complete(
  builder: FlowBuilder(step_type, session, error),
  handler: fn(Context(session, error), types.FlowInstance) ->
    Result(Context(session, error), error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, on_complete: Some(handler))
}

/// Set error handler
pub fn on_error(
  builder: FlowBuilder(step_type, session, error),
  handler: fn(Context(session, error), types.FlowInstance, Option(error)) ->
    Result(Context(session, error), error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, on_error: Some(handler))
}

/// Set flow enter hook
pub fn set_on_flow_enter(
  builder: FlowBuilder(step_type, session, error),
  hook: FlowEnterHook(session, error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, on_flow_enter: Some(hook))
}

/// Set flow leave hook
pub fn set_on_flow_leave(
  builder: FlowBuilder(step_type, session, error),
  hook: FlowLeaveHook(session, error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, on_flow_leave: Some(hook))
}

/// Set flow-level TTL (maximum lifetime in milliseconds)
pub fn with_ttl(
  builder: FlowBuilder(step_type, session, error),
  ms ms: Int,
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, ttl_ms: Some(ms))
}

/// Set timeout hook (called when flow or wait expires via lazy check)
pub fn on_timeout(
  builder: FlowBuilder(step_type, session, error),
  handler: types.FlowExitHook(session, error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, on_timeout: Some(handler))
}

/// Set flow exit hook
pub fn set_on_flow_exit(
  builder: FlowBuilder(step_type, session, error),
  hook: FlowExitHook(session, error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, on_flow_exit: Some(hook))
}

/// Build the flow
pub fn build(
  builder: FlowBuilder(step_type, session, error),
  initial initial_step: step_type,
) -> Flow(step_type, session, error) {
  Flow(
    initial_step:,
    name: builder.flow_name,
    steps: builder.steps,
    step_to_string: builder.step_to_string,
    string_to_step: builder.string_to_step,
    storage: builder.storage,
    on_complete: builder.on_complete,
    on_error: builder.on_error,
    global_middlewares: builder.global_middlewares,
    conditionals: builder.conditionals,
    parallel_configs: builder.parallel_configs,
    subflows: builder.subflows,
    on_flow_enter: builder.on_flow_enter,
    on_flow_leave: builder.on_flow_leave,
    on_flow_exit: builder.on_flow_exit,
    ttl_ms: builder.ttl_ms,
    on_timeout: builder.on_timeout,
  )
}

fn inline_step_to_string(step: InlineStep) -> String {
  step.name
}

fn string_to_inline_step(s: String) -> Result(InlineStep, Nil) {
  Ok(InlineStep(s))
}

/// Helper to create a string_to_step function for a list of steps
fn create_string_to_step(
  steps: List(#(String, step_type)),
) -> fn(String) -> Result(step_type, Nil) {
  let step_dict = dict.from_list(steps)
  fn(name) { dict.get(step_dict, name) }
}

import telega/internal/coerce

fn unsafe_coerce(value: value_type) -> result_type {
  coerce.unsafe_coerce(value)
}
