//// Type-safe, persistent flow system for building multi-step conversational interactions.
////
//// ## Core Concepts
////
//// - **Flow** - State machine for multi-step conversations with compile-time validated transitions
//// - **FlowRegistry** - Central container managing all flows, supporting triggers and manual calls
//// - **Storage** - Pluggable persistence (database, memory, Redis) with automatic state recovery
////
//// ## Quick Start
////
//// ```gleam
//// // 1. Define flow steps
//// pub type OnboardingStep {
////   Welcome
////   CollectName
////   CollectEmail
////   Complete
//// }
////
//// // 2. Build flow with handlers
//// let onboarding_flow =
////   flow.new("onboarding", storage, step_to_string, string_to_step)
////   |> flow.add_step(Welcome, welcome_handler)
////   |> flow.add_step(CollectName, name_handler)
////   |> flow.add_step(CollectEmail, email_handler)
////   |> flow.add_step(Complete, complete_handler)
////   |> flow.build(initial: Welcome)
////
//// // 3. Register and apply to router
//// let flow_registry =
////   flow.new_registry()
////   |> flow.register(flow.OnCommand("/start"), onboarding_flow)
////
//// router |> flow.apply_to_router(flow_registry)
//// ```
////
//// ## Advanced Usage
////
//// ```gleam
//// // Call flow from any handler
//// fn my_handler(ctx, _data) {
////   let initial_data = dict.from_list([#("product_id", "123")])
////   flow.call_flow(ctx, flow_registry, "checkout", initial_data)
//// }
////
//// // Conditional transitions
//// |> flow.add_conditional(
////   from: CollectAge,
////   condition: fn(instance) {
////     case flow.get_data(instance, "age") {
////       Some(age) -> int.parse(age) |> result.unwrap(0) >= 18
////       None -> False
////     }
////   },
////   true: AdultFlow,
////   false: MinorFlow
//// )
////
//// // Parallel step execution
//// |> flow.add_parallel_steps(
////   trigger_step: StartVerification,
////   parallel_steps: [EmailVerify, PhoneVerify, DocumentVerify],
////   join_at: VerificationComplete
//// )
//// ```

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/internal/utils
import telega/reply

import telega/bot.{type Context}
import telega/keyboard
import telega/router
import telega/update

/// Flow state representing current step and data
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
pub type FlowStackFrame {
  FlowStackFrame(
    flow_name: String,
    return_step: String,
    saved_data: Dict(String, String),
  )
}

/// State for parallel step execution
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
pub type FlowEnterHook(session, error) =
  fn(Context(session, error), FlowInstance) ->
    Result(#(Context(session, error), FlowInstance), error)

/// Hook called when leaving a flow to enter a subflow
pub type FlowLeaveHook(session, error) =
  fn(Context(session, error), FlowInstance) ->
    Result(#(Context(session, error), FlowInstance), error)

/// Hook called when completely exiting the flow (cancel or complete)
pub type FlowExitHook(session, error) =
  fn(Context(session, error), FlowInstance) ->
    Result(Context(session, error), error)

pub opaque type FlowBuilder(step_type, session, error) {
  FlowBuilder(
    flow_name: String,
    steps: Dict(String, StepConfig(step_type, session, error)),
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
    global_middlewares: List(StepMiddleware(step_type, session, error)),
    conditionals: List(ConditionalTransition(step_type)),
    parallel_configs: List(ParallelConfig(step_type)),
    subflows: List(SubflowConfig(step_type, session, error)),
    // Flow lifecycle hooks
    on_flow_enter: Option(FlowEnterHook(session, error)),
    on_flow_leave: Option(FlowLeaveHook(session, error)),
    on_flow_exit: Option(FlowExitHook(session, error)),
  )
}

pub opaque type Flow(step_type, session, error) {
  Flow(
    name: String,
    steps: Dict(String, StepConfig(step_type, session, error)),
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
    global_middlewares: List(StepMiddleware(step_type, session, error)),
    conditionals: List(ConditionalTransition(step_type)),
    parallel_configs: List(ParallelConfig(step_type)),
    subflows: List(SubflowConfig(step_type, session, error)),
    // Flow lifecycle hooks
    on_flow_enter: Option(FlowEnterHook(session, error)),
    on_flow_leave: Option(FlowLeaveHook(session, error)),
    on_flow_exit: Option(FlowExitHook(session, error)),
  )
}

/// Flow registry for centralized flow management
pub opaque type FlowRegistry(session, error) {
  FlowRegistry(
    flows: List(
      #(FlowTrigger, Flow(Dynamic, session, error), Dict(String, String)),
    ),
    flow_map: Dict(String, Flow(Dynamic, session, error)),
  )
}

pub type StepHandler(step_type, session, error) =
  fn(Context(session, error), FlowInstance) ->
    StepResult(step_type, session, error)

pub type StepMiddleware(step_type, session, error) =
  fn(
    Context(session, error),
    FlowInstance,
    fn() -> StepResult(step_type, session, error),
  ) ->
    StepResult(step_type, session, error)

/// Hook called when entering a step (before the handler)
pub type StepEnterHook(session, error) =
  fn(Context(session, error), FlowInstance) ->
    Result(#(Context(session, error), FlowInstance), error)

/// Hook called when leaving a step (after the handler, before transition)
pub type StepLeaveHook(session, error) =
  fn(Context(session, error), FlowInstance) ->
    Result(#(Context(session, error), FlowInstance), error)

pub type StepConfig(step_type, session, error) {
  StepConfig(
    handler: StepHandler(step_type, session, error),
    middlewares: List(StepMiddleware(step_type, session, error)),
    on_enter: Option(StepEnterHook(session, error)),
    on_leave: Option(StepLeaveHook(session, error)),
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
pub type SubflowConfig(step_type, session, error) {
  SubflowConfig(
    trigger_step: String,
    flow: Flow(Dynamic, session, error),
    return_step: step_type,
    map_args: fn(FlowInstance) -> Dict(String, String),
    map_result: fn(Dict(String, String), FlowInstance) -> FlowInstance,
  )
}

/// Result type for flow steps
pub type StepResult(step_type, session, error) =
  Result(#(Context(session, error), FlowAction(step_type), FlowInstance), error)

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
///
/// ## Example
///
/// ```gleam
/// flow.new("checkout", storage, step_to_string, string_to_step)
/// |> flow.add_step_with_hooks(
///     Payment,
///     handler: payment_handler,
///     on_enter: Some(fn(ctx, instance) {
///       // Log payment step entry
///       use _ <- result.try(reply.with_text(ctx, "Entering payment..."))
///       Ok(#(ctx, instance))
///     }),
///     on_leave: Some(fn(ctx, instance) {
///       // Cleanup or log
///       Ok(#(ctx, instance))
///     }),
///   )
/// ```
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
  condition: fn(FlowInstance) -> Bool,
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
  conditions: List(#(fn(FlowInstance) -> Bool, step_type)),
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
///
/// This is the recommended way to add parallel steps to a flow.
/// When the flow reaches `from` step, it will execute all `steps` in parallel,
/// and automatically transition to `join` step when all parallel steps complete.
///
/// ## Example
///
/// ```gleam
/// flow.new("kyc_verification", storage, to_string, from_string)
/// |> flow.add_step(Start, start_handler)
/// |> flow.add_step(EmailVerify, email_handler)
/// |> flow.add_step(PhoneVerify, phone_handler)
/// |> flow.add_step(DocumentVerify, document_handler)
/// |> flow.parallel(
///     from: Start,
///     steps: [EmailVerify, PhoneVerify, DocumentVerify],
///     join: AllComplete,
///   )
/// |> flow.add_step(AllComplete, complete_handler)
/// |> flow.build(initial: Start)
/// ```
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
///
/// ## Example
///
/// ```gleam
/// let address_flow =
///   flow.new("address", storage, step_to_string, string_to_step)
///   |> flow.add_step(Street, street_handler)
///   |> flow.build(initial: Street)
///
/// let checkout_flow =
///   flow.new("checkout", storage, step_to_string, string_to_step)
///   |> flow.add_step(Cart, cart_handler)
///   |> flow.add_subflow(
///       trigger_step: CollectAddress,
///       subflow: address_flow,
///       return_to: Payment,
///       map_args: fn(instance) { instance.state.data },
///       map_result: fn(result, instance) {
///         FlowInstance(..instance, state: FlowState(
///           ..instance.state,
///           data: dict.merge(instance.state.data, result)
///         ))
///       },
///     )
///   |> flow.build(initial: Cart)
/// ```
pub fn add_subflow(
  builder: FlowBuilder(step_type, session, error),
  trigger_step: step_type,
  subflow subflow: Flow(Dynamic, session, error),
  return_to return_to: step_type,
  map_args map_args: fn(FlowInstance) -> Dict(String, String),
  map_result map_result: fn(Dict(String, String), FlowInstance) -> FlowInstance,
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

/// Inline subflow step type (uses strings internally)
pub type InlineStep {
  InlineStep(name: String)
}

/// Add an inline subflow defined within the parent flow
///
/// This creates a subflow inline without needing to define a separate flow.
/// Steps are identified by string names.
///
/// ## Example
///
/// ```gleam
/// let checkout_flow =
///   flow.new("checkout", storage, step_to_string, string_to_step)
///   |> flow.add_step(Cart, cart_handler)
///   |> flow.with_inline_subflow(
///       name: "address_collection",
///       trigger: CollectAddress,
///       return_to: Payment,
///       initial: "street",
///       steps: [
///         #("street", fn(ctx, instance) {
///           // Ask for street
///           flow.wait(ctx, instance, "street_input")
///         }),
///         #("city", fn(ctx, instance) {
///           // Ask for city
///           flow.wait(ctx, instance, "city_input")
///         }),
///         #("done", fn(ctx, instance) {
///           flow.return_from_subflow(ctx, instance, instance.state.data)
///         }),
///       ],
///     )
///   |> flow.add_step(Payment, payment_handler)
///   |> flow.build(initial: Cart)
/// ```
pub fn with_inline_subflow(
  builder: FlowBuilder(step_type, session, error),
  name name: String,
  trigger trigger: step_type,
  return_to return_to: step_type,
  initial initial: String,
  steps steps: List(
    #(
      String,
      fn(Context(session, error), FlowInstance) ->
        StepResult(InlineStep, session, error),
    ),
  ),
) -> FlowBuilder(step_type, session, error) {
  // Create the inline flow with string-based steps
  let inline_flow_name = builder.flow_name <> "::" <> name
  let inline_storage = builder.storage

  let inline_builder =
    new(
      inline_flow_name,
      inline_storage,
      inline_step_to_string,
      string_to_inline_step,
    )

  // Add all steps
  let inline_builder =
    list.fold(steps, inline_builder, fn(b, step_tuple) {
      let #(step_name, handler) = step_tuple
      add_step(b, InlineStep(step_name), handler)
    })

  // Build the inline flow
  let inline_flow = build(inline_builder, initial: InlineStep(initial))

  // Coerce to Dynamic and add as subflow
  let coerced_flow: Flow(Dynamic, session, error) = unsafe_coerce(inline_flow)

  add_subflow(
    builder,
    trigger,
    coerced_flow,
    return_to,
    fn(instance) { instance.state.data },
    fn(result, instance) {
      FlowInstance(
        ..instance,
        state: FlowState(
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
      fn(Context(session, error), FlowInstance) ->
        StepResult(InlineStep, session, error),
    ),
  ),
  map_args map_args: fn(FlowInstance) -> Dict(String, String),
  map_result map_result: fn(Dict(String, String), FlowInstance) -> FlowInstance,
) -> FlowBuilder(step_type, session, error) {
  // Create the inline flow with string-based steps
  let inline_flow_name = builder.flow_name <> "::" <> name
  let inline_storage = builder.storage

  let inline_builder =
    new(
      inline_flow_name,
      inline_storage,
      inline_step_to_string,
      string_to_inline_step,
    )

  // Add all steps
  let inline_builder =
    list.fold(steps, inline_builder, fn(b, step_tuple) {
      let #(step_name, handler) = step_tuple
      add_step(b, InlineStep(step_name), handler)
    })

  // Build the inline flow
  let inline_flow = build(inline_builder, initial: InlineStep(initial))

  // Coerce to Dynamic and add as subflow
  let coerced_flow: Flow(Dynamic, session, error) = unsafe_coerce(inline_flow)

  add_subflow(builder, trigger, coerced_flow, return_to, map_args, map_result)
}

fn inline_step_to_string(step: InlineStep) -> String {
  step.name
}

fn string_to_inline_step(s: String) -> Result(InlineStep, Nil) {
  Ok(InlineStep(s))
}

/// Navigate to next inline step by name
pub fn inline_next(
  ctx: Context(session, error),
  instance: FlowInstance,
  step_name step_name: String,
) -> StepResult(InlineStep, session, error) {
  Ok(#(ctx, Next(InlineStep(step_name)), instance))
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

/// Set flow enter hook
///
/// Called when the flow is first started or resumed from a parent flow.
///
/// ## Example
///
/// ```gleam
/// flow.new("checkout", storage, step_to_string, string_to_step)
/// |> flow.set_on_flow_enter(fn(ctx, instance) {
///   use ctx <- result.try(
///     reply.with_text(ctx, "Welcome to checkout!")
///     |> result.map_error(fn(e) { e })
///   )
///   Ok(#(ctx, instance))
/// })
/// ```
pub fn set_on_flow_enter(
  builder: FlowBuilder(step_type, session, error),
  hook: FlowEnterHook(session, error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, on_flow_enter: Some(hook))
}

/// Set flow leave hook
///
/// Called when transitioning to a subflow.
///
/// ## Example
///
/// ```gleam
/// flow.new("checkout", storage, step_to_string, string_to_step)
/// |> flow.set_on_flow_leave(fn(ctx, instance) {
///   // Save state before entering subflow
///   Ok(#(ctx, instance))
/// })
/// ```
pub fn set_on_flow_leave(
  builder: FlowBuilder(step_type, session, error),
  hook: FlowLeaveHook(session, error),
) -> FlowBuilder(step_type, session, error) {
  FlowBuilder(..builder, on_flow_leave: Some(hook))
}

/// Set flow exit hook
///
/// Called when the flow completes or is cancelled.
///
/// ## Example
///
/// ```gleam
/// flow.new("checkout", storage, step_to_string, string_to_step)
/// |> flow.set_on_flow_exit(fn(ctx, instance) {
///   use _ <- result.try(
///     reply.with_text(ctx, "Checkout complete!")
///     |> result.map_error(fn(e) { e })
///   )
///   Ok(ctx)
/// })
/// ```
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
  )
}

/// Next navigation
pub fn next(
  ctx: Context(session, error),
  instance: FlowInstance,
  step step: step_type,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Next(step), instance))
}

/// Next navigation with string step (for dynamic navigation)
pub fn unsafe_next(
  ctx: Context(session, error),
  instance: FlowInstance,
  step step: String,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, NextString(step), instance))
}

/// Type-safe goto navigation (clears step data)
pub fn goto(
  ctx: Context(session, error),
  instance: FlowInstance,
  step step: step_type,
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
  token token: String,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Wait(token), instance))
}

/// Wait for callback
pub fn wait_callback(
  ctx: Context(session, error),
  instance: FlowInstance,
  token token: String,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, WaitCallback(token <> "_" <> instance.id), instance))
}

/// Exit with result
pub fn exit(
  ctx: Context(session, error),
  instance: FlowInstance,
  result result: Option(Dict(String, String)),
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Exit(result), instance))
}

/// Enter a subflow by name
///
/// This pushes the current flow state onto the stack and starts the subflow.
/// When the subflow completes with `return_from_subflow`, execution returns
/// to the parent flow at the step specified in `add_subflow`.
///
/// ## Example
/// ```gleam
/// fn my_handler(ctx, instance) {
///   // Enter address collection subflow
///   flow.enter_subflow(ctx, instance, "address_collection", dict.new())
/// }
/// ```
pub fn enter_subflow(
  ctx: Context(session, error),
  instance: FlowInstance,
  subflow_name subflow_name: String,
  data data: Dict(String, String),
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, EnterSubflow(subflow_name, data), instance))
}

/// Return from a subflow with result data
///
/// This pops the parent flow from the stack and merges the result data
/// into the parent's state, then continues at the return step.
///
/// ## Example
/// ```gleam
/// fn final_step_handler(ctx, instance) {
///   let result = dict.from_list([
///     #("street", flow.get_data(instance, "street") |> option.unwrap("")),
///     #("city", flow.get_data(instance, "city") |> option.unwrap("")),
///   ])
///   flow.return_from_subflow(ctx, instance, result)
/// }
/// ```
pub fn return_from_subflow(
  ctx: Context(session, error),
  instance: FlowInstance,
  result result: Dict(String, String),
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, ReturnFromSubflow(result), instance))
}

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
          user_id:,
          chat_id:,
          state: FlowState(
            current_step: initial_step_name,
            data: initial_data,
            history: [initial_step_name],
            flow_stack: [],
            parallel_state: None,
          ),
          step_data: dict.new(),
          wait_token: None,
          created_at: utils.current_time_ms(),
          updated_at: utils.current_time_ms(),
        )

      case flow.storage.save(new_instance) {
        Ok(_) -> {
          // Call on_flow_enter hook for new flows
          case run_flow_enter_hook(flow.on_flow_enter, ctx, new_instance) {
            Ok(#(ctx_after_enter, instance_after_enter)) ->
              execute_step(flow, ctx_after_enter, instance_after_enter)
            Error(err) -> handle_error(flow, ctx, new_instance, Some(err))
          }
        }
        Error(err) -> handle_error(flow, ctx, new_instance, Some(err))
      }
    }
    Error(err) -> {
      let dummy_instance =
        FlowInstance(
          id: flow_id,
          flow_name: flow.name,
          user_id:,
          chat_id:,
          state: FlowState(
            current_step: "",
            data: dict.new(),
            history: [],
            flow_stack: [],
            parallel_state: None,
          ),
          step_data: dict.new(),
          wait_token: None,
          created_at: 0,
          updated_at: 0,
        )
      handle_error(flow, ctx, dummy_instance, Some(err))
    }
  }
}

fn resume_with_token(
  flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  token token: String,
  data data: Option(Dict(String, String)),
) -> Result(Context(session, error), error) {
  case find_instance_by_token(flow.storage, token) {
    Ok(Some(instance)) -> {
      let updated_instance = case data {
        Some(d) ->
          FlowInstance(
            ..instance,
            step_data: dict.merge(instance.step_data, d),
            wait_token: None,
          )
        None -> FlowInstance(..instance, wait_token: None)
      }
      execute_step(flow, ctx, updated_instance)
    }
    _ -> Ok(ctx)
  }
}

/// Get current step
pub fn get_current_step(
  flow: Flow(step_type, session, error),
  instance: FlowInstance,
) -> Result(step_type, Nil) {
  flow.string_to_step(instance.state.current_step)
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
pub fn get_step_data(instance: FlowInstance, key key: String) -> Option(String) {
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

pub fn is_callback_passed(
  instance: FlowInstance,
  key key: String,
  callback_id callback_id: String,
) -> Option(Bool) {
  case get_step_data(instance, key) {
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

/// Update instance data and continue to next step
pub fn next_with_data(
  ctx: Context(session, error),
  instance: FlowInstance,
  step step: step_type,
  key key: String,
  value value: String,
) -> StepResult(step_type, session, error) {
  let updated_instance = store_data(instance, key, value)
  next(ctx, updated_instance, step)
}

fn find_instance_by_token(
  storage: FlowStorage(error),
  token token: String,
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
  // Check for conditional transitions first
  case check_conditionals(flow, instance) {
    Some(next_step) -> {
      let updated_instance =
        FlowInstance(
          ..instance,
          state: FlowState(..instance.state, current_step: next_step, history: [
            instance.state.current_step,
            ..instance.state.history
          ]),
          updated_at: utils.current_time_ms(),
        )
      case flow.storage.save(updated_instance) {
        Ok(_) -> execute_step(flow, ctx, updated_instance)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }
    None -> {
      // Check for parallel execution trigger
      case check_parallel_trigger(flow, instance) {
        Some(config) -> start_parallel_execution(flow, ctx, instance, config)
        None -> {
          // Check for subflow trigger
          case check_subflow_trigger(flow, instance) {
            Some(subflow_config) ->
              start_subflow_execution(flow, ctx, instance, subflow_config)
            None -> {
              // Normal step execution with middleware
              case dict.get(flow.steps, instance.state.current_step) {
                Ok(config) -> {
                  // Call on_enter hook if present
                  case run_enter_hook(config.on_enter, ctx, instance) {
                    Ok(#(ctx_after_enter, instance_after_enter)) -> {
                      let handler_fn = fn() {
                        config.handler(ctx_after_enter, instance_after_enter)
                      }
                      let result =
                        apply_middlewares(
                          ctx_after_enter,
                          instance_after_enter,
                          handler_fn,
                          list.append(
                            flow.global_middlewares,
                            config.middlewares,
                          ),
                        )
                      case result {
                        Ok(#(new_ctx, action, new_instance)) ->
                          process_action_with_leave_hook(
                            flow,
                            new_ctx,
                            action,
                            new_instance,
                            config.on_leave,
                          )
                        Error(err) ->
                          handle_error(flow, ctx, instance, Some(err))
                      }
                    }
                    Error(err) -> handle_error(flow, ctx, instance, Some(err))
                  }
                }
                Error(_) -> handle_error(flow, ctx, instance, None)
              }
            }
          }
        }
      }
    }
  }
}

/// Run the enter hook if present
fn run_enter_hook(
  hook: Option(StepEnterHook(session, error)),
  ctx: Context(session, error),
  instance: FlowInstance,
) -> Result(#(Context(session, error), FlowInstance), error) {
  case hook {
    Some(enter_fn) -> enter_fn(ctx, instance)
    None -> Ok(#(ctx, instance))
  }
}

/// Run the leave hook if present
fn run_leave_hook(
  hook: Option(StepLeaveHook(session, error)),
  ctx: Context(session, error),
  instance: FlowInstance,
) -> Result(#(Context(session, error), FlowInstance), error) {
  case hook {
    Some(leave_fn) -> leave_fn(ctx, instance)
    None -> Ok(#(ctx, instance))
  }
}

/// Run the flow enter hook if present
fn run_flow_enter_hook(
  hook: Option(FlowEnterHook(session, error)),
  ctx: Context(session, error),
  instance: FlowInstance,
) -> Result(#(Context(session, error), FlowInstance), error) {
  case hook {
    Some(enter_fn) -> enter_fn(ctx, instance)
    None -> Ok(#(ctx, instance))
  }
}

/// Run the flow leave hook if present
fn run_flow_leave_hook(
  hook: Option(FlowLeaveHook(session, error)),
  ctx: Context(session, error),
  instance: FlowInstance,
) -> Result(#(Context(session, error), FlowInstance), error) {
  case hook {
    Some(leave_fn) -> leave_fn(ctx, instance)
    None -> Ok(#(ctx, instance))
  }
}

/// Run the flow exit hook if present
fn run_flow_exit_hook(
  hook: Option(FlowExitHook(session, error)),
  ctx: Context(session, error),
  instance: FlowInstance,
) -> Result(Context(session, error), error) {
  case hook {
    Some(exit_fn) -> exit_fn(ctx, instance)
    None -> Ok(ctx)
  }
}

/// Process action with leave hook support
fn process_action_with_leave_hook(
  flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  action: FlowAction(step_type),
  instance: FlowInstance,
  leave_hook: Option(StepLeaveHook(session, error)),
) -> Result(Context(session, error), error) {
  // For Wait actions, don't run leave hook (we're not actually leaving)
  case action {
    Wait(_) | WaitCallback(_) -> process_action(flow, ctx, action, instance)
    _ -> {
      // Run leave hook before processing the action
      case run_leave_hook(leave_hook, ctx, instance) {
        Ok(#(ctx_after_leave, instance_after_leave)) ->
          process_action(flow, ctx_after_leave, action, instance_after_leave)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }
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
          updated_at: utils.current_time_ms(),
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
          updated_at: utils.current_time_ms(),
        )

      case flow.storage.save(updated_instance) {
        Ok(_) -> execute_step(flow, ctx, updated_instance)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    ReturnFromSubflow(result) -> {
      case instance.state.flow_stack {
        [frame, ..rest_stack] -> {
          let updated_instance =
            FlowInstance(
              ..instance,
              state: FlowState(
                ..instance.state,
                current_step: frame.return_step,
                data: dict.merge(instance.state.data, result),
                flow_stack: rest_stack,
              ),
              updated_at: utils.current_time_ms(),
            )
          case flow.storage.save(updated_instance) {
            Ok(_) -> execute_step(flow, ctx, updated_instance)
            Error(err) -> handle_error(flow, ctx, instance, Some(err))
          }
        }
        [] -> Ok(ctx)
      }
    }

    StartParallel(steps, join_at) -> {
      let step_names = list.map(steps, flow.step_to_string)
      let join_step_name = flow.step_to_string(join_at)
      let parallel_state =
        ParallelState(
          pending_steps: step_names,
          completed_steps: [],
          results: dict.new(),
          join_step: join_step_name,
        )
      let updated_instance =
        FlowInstance(
          ..instance,
          state: FlowState(
            ..instance.state,
            parallel_state: Some(parallel_state),
          ),
          updated_at: utils.current_time_ms(),
        )
      case flow.storage.save(updated_instance) {
        Ok(_) -> {
          // Execute first parallel step
          case step_names {
            [first, ..] -> {
              let step_instance =
                FlowInstance(
                  ..updated_instance,
                  state: FlowState(
                    ..updated_instance.state,
                    current_step: first,
                  ),
                )
              execute_step(flow, ctx, step_instance)
            }
            [] -> Ok(ctx)
          }
        }
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    CompleteParallelStep(step, result) -> {
      case instance.state.parallel_state {
        Some(parallel_state) -> {
          let step_name = flow.step_to_string(step)
          let updated_parallel =
            ParallelState(
              ..parallel_state,
              pending_steps: list.filter(parallel_state.pending_steps, fn(s) {
                s != step_name
              }),
              completed_steps: [step_name, ..parallel_state.completed_steps],
              results: dict.insert(parallel_state.results, step_name, result),
            )

          case updated_parallel.pending_steps {
            [] -> {
              // All parallel steps completed, move to join step
              let updated_instance =
                FlowInstance(
                  ..instance,
                  state: FlowState(
                    ..instance.state,
                    current_step: updated_parallel.join_step,
                    parallel_state: None,
                    data: merge_parallel_results(
                      instance.state.data,
                      updated_parallel.results,
                    ),
                  ),
                  updated_at: utils.current_time_ms(),
                )
              case flow.storage.save(updated_instance) {
                Ok(_) -> execute_step(flow, ctx, updated_instance)
                Error(err) -> handle_error(flow, ctx, instance, Some(err))
              }
            }
            [next, ..] -> {
              // Execute next parallel step
              let updated_instance =
                FlowInstance(
                  ..instance,
                  state: FlowState(
                    ..instance.state,
                    current_step: next,
                    parallel_state: Some(updated_parallel),
                  ),
                  updated_at: utils.current_time_ms(),
                )
              case flow.storage.save(updated_instance) {
                Ok(_) -> execute_step(flow, ctx, updated_instance)
                Error(err) -> handle_error(flow, ctx, instance, Some(err))
              }
            }
          }
        }
        None -> Ok(ctx)
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
            flow_stack: [],
            parallel_state: None,
          ),
          step_data: dict.new(),
          updated_at: utils.current_time_ms(),
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
              updated_at: utils.current_time_ms(),
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
      let completed_instance =
        FlowInstance(..instance, state: FlowState(..instance.state, data: data))
      // Run on_complete handler first
      case flow.on_complete {
        Some(handler) -> {
          case handler(ctx, completed_instance) {
            Ok(new_ctx) -> {
              // Then run flow exit hook
              case
                run_flow_exit_hook(
                  flow.on_flow_exit,
                  new_ctx,
                  completed_instance,
                )
              {
                Ok(final_ctx) -> {
                  let _ = flow.storage.delete(instance.id)
                  Ok(final_ctx)
                }
                Error(err) -> handle_error(flow, ctx, instance, Some(err))
              }
            }
            Error(err) -> handle_error(flow, ctx, instance, Some(err))
          }
        }
        None -> {
          // Just run flow exit hook
          case run_flow_exit_hook(flow.on_flow_exit, ctx, completed_instance) {
            Ok(final_ctx) -> {
              let _ = flow.storage.delete(instance.id)
              Ok(final_ctx)
            }
            Error(err) -> handle_error(flow, ctx, instance, Some(err))
          }
        }
      }
    }

    Cancel -> {
      // Run flow exit hook before canceling
      case run_flow_exit_hook(flow.on_flow_exit, ctx, instance) {
        Ok(final_ctx) -> {
          let _ = flow.storage.delete(instance.id)
          Ok(final_ctx)
        }
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    Wait(token) -> {
      let updated_instance =
        FlowInstance(
          ..instance,
          wait_token: Some(token),
          updated_at: utils.current_time_ms(),
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
          updated_at: utils.current_time_ms(),
        )

      case flow.storage.save(updated_instance) {
        Ok(_) -> Ok(ctx)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    Exit(_) -> {
      let _ = flow.storage.delete(instance.id)
      Ok(ctx)
    }

    EnterSubflow(subflow_name, data) -> {
      // Find the subflow config by name
      case
        list.find(flow.subflows, fn(config) { config.flow.name == subflow_name })
      {
        Ok(subflow_config) -> {
          // Create stack frame for the parent flow
          let return_step = flow.step_to_string(subflow_config.return_step)
          let stack_frame =
            FlowStackFrame(
              flow_name: flow.name,
              return_step: return_step,
              saved_data: instance.state.data,
            )

          // Get subflow initial step
          let subflow_initial_step =
            subflow_config.flow.step_to_string(subflow_config.flow.initial_step)

          // Update instance with stack frame and switch to subflow
          let updated_instance =
            FlowInstance(
              ..instance,
              flow_name: subflow_config.flow.name,
              state: FlowState(
                current_step: subflow_initial_step,
                data: dict.merge(instance.state.data, data),
                history: [subflow_initial_step],
                flow_stack: [stack_frame, ..instance.state.flow_stack],
                parallel_state: None,
              ),
              step_data: dict.new(),
              updated_at: utils.current_time_ms(),
            )

          case flow.storage.save(updated_instance) {
            Ok(_) ->
              execute_subflow_step(
                subflow_config.flow,
                ctx,
                updated_instance,
                subflow_config,
              )
            Error(err) -> handle_error(flow, ctx, instance, Some(err))
          }
        }
        Error(_) -> {
          // Subflow not found, continue without error
          Ok(ctx)
        }
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

/// Create in-memory storage (for testing)
pub fn create_memory_storage() -> FlowStorage(error) {
  FlowStorage(
    save: fn(_instance) { Ok(Nil) },
    load: fn(_id) { Ok(None) },
    delete: fn(_id) { Ok(Nil) },
    list_by_user: fn(_user_id, _chat_id) { Ok([]) },
  )
}

/// Helper to create a string_to_step function for a list of steps
fn create_string_to_step(
  steps: List(#(String, step_type)),
) -> fn(String) -> Result(step_type, Nil) {
  let step_dict = dict.from_list(steps)
  fn(name) { dict.get(step_dict, name) }
}

/// Generate a unique wait token
fn generate_wait_token(instance: FlowInstance) -> String {
  instance.id <> "_" <> int.to_string(utils.current_time_ms())
}

/// Create a text input step
pub fn text_step(
  prompt: String,
  data_key: String,
  next_step: step_type,
) -> StepHandler(step_type, session, error) {
  fn(ctx: Context(session, error), instance: FlowInstance) {
    case get_step_data(instance, "user_input") {
      Some(value) -> {
        let instance =
          instance
          |> store_data(data_key, value)
          |> clear_step_data_key("user_input")
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

/// Call a registered flow from any handler
///
/// ## Parameters
/// - `ctx`: Current context
/// - `registry`: The flow registry containing the flow
/// - `flow_name`: Name of the flow to call
/// - `initial_data`: Initial data to pass to the flow
///
/// ## Example
/// ```gleam
/// fn my_handler(ctx, registry, _data) {
///   let initial_data = dict.from_list([
///     #("user_name", "John"),
///     #("product_id", "123")
///   ])
///   flow.call_flow(ctx, registry, "checkout", initial_data)
/// }
/// ```
pub fn call_flow(
  ctx ctx: Context(session, error),
  registry registry: FlowRegistry(session, error),
  name flow_name: String,
  initial initial_data: Dict(String, String),
) -> Result(Context(session, error), error) {
  case dict.get(registry.flow_map, flow_name) {
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
  flow flow: Flow(step_type, session, error),
  initial initial_data: Dict(String, String),
  ctx ctx: Context(session, error),
) -> Result(Context(session, error), error) {
  let #(from_id, chat_id) = extract_ids_from_context(ctx)
  start_or_resume(flow, ctx, from_id, chat_id, initial_data)
}

/// Create a router handler that starts a flow
pub fn to_handler(
  flow flow: Flow(step_type, session, error),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _command) { start(flow, dict.new(), ctx) }
}

/// Create a router handler that starts a flow with initial data (internal)
fn to_handler_with_data(
  flow flow: Flow(step_type, session, error),
  initial initial_data: Dict(String, String),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _update) { start(flow, initial_data, ctx) }
}

/// Create a router handler for resuming flows from callback queries (internal)
fn resume_handler(
  flow flow: Flow(step_type, session, error),
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

// Type coercion for dynamic flows
// This is unsafe but necessary for the flow registry to work with different step types
@external(erlang, "erlang", "term_to_binary")
fn to_binary(value: a) -> BitArray

@external(erlang, "erlang", "binary_to_term")
fn from_binary(binary: BitArray) -> b

fn unsafe_coerce(value: value_type) -> result_type {
  value |> to_binary |> from_binary
}

/// Create a new empty flow registry
pub fn new_registry() -> FlowRegistry(session, error) {
  FlowRegistry(flows: [], flow_map: dict.new())
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
    flow_map: dict.insert(registry.flow_map, flow.name, coerced_flow),
  )
}

/// Register a flow without a trigger (for calling from handlers)
pub fn register_callable(
  registry: FlowRegistry(session, error),
  flow: Flow(step_type, session, error),
) -> FlowRegistry(session, error) {
  let coerced_flow = unsafe_coerce(flow)
  FlowRegistry(
    flows: registry.flows,
    flow_map: dict.insert(registry.flow_map, flow.name, coerced_flow),
  )
}

/// Apply all registered flows to a router
pub fn apply_to_router(
  router: router.Router(session, error),
  registry: FlowRegistry(session, error),
) -> router.Router(session, error) {
  let router_with_flows =
    list.fold(registry.flows, router, fn(router, flow_entry) {
      let #(trigger, flow, initial_data) = flow_entry
      add_flow_route(router, trigger, flow, initial_data)
    })

  // If we have any flows, add auto-resume handlers
  case dict.size(registry.flow_map) {
    0 -> router_with_flows
    _ ->
      router_with_flows
      |> router.on_any_text(auto_resume_handler(registry))
      |> router.on_callback(
        router.Prefix(""),
        auto_resume_callback_handler(registry),
      )
  }
}

/// Add a flow route to router
fn add_flow_route(
  router: router.Router(session, error),
  trigger: FlowTrigger,
  flow: Flow(Dynamic, session, error),
  initial_data initial_data: Dict(String, String),
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
fn auto_resume_handler(
  registry: FlowRegistry(session, error),
) -> fn(Context(session, error), String) ->
  Result(Context(session, error), error) {
  fn(ctx: Context(session, error), text: String) {
    let #(user_id, chat_id) = extract_ids_from_context(ctx)
    let flows = dict.values(registry.flow_map)

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
fn auto_resume_callback_handler(
  registry: FlowRegistry(session, error),
) -> fn(Context(session, error), String, String) ->
  Result(Context(session, error), error) {
  fn(ctx: Context(session, error), _callback_id: String, data: String) {
    let #(user_id, chat_id) = extract_ids_from_context(ctx)
    let flows = dict.values(registry.flow_map)

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

/// Apply middleware chain to handler
fn apply_middlewares(
  ctx: Context(session, error),
  instance: FlowInstance,
  handler: fn() -> StepResult(step_type, session, error),
  middlewares: List(StepMiddleware(step_type, session, error)),
) -> StepResult(step_type, session, error) {
  case middlewares {
    [] -> handler()
    [middleware, ..rest] -> {
      middleware(ctx, instance, fn() {
        apply_middlewares(ctx, instance, handler, rest)
      })
    }
  }
}

/// Check for conditional transitions
fn check_conditionals(
  flow: Flow(step_type, session, error),
  instance: FlowInstance,
) -> Option(String) {
  list.fold(flow.conditionals, None, fn(acc, conditional) {
    case acc {
      Some(_) -> acc
      None -> {
        case conditional.from == instance.state.current_step {
          True -> {
            list.fold(conditional.conditions, None, fn(inner_acc, cond) {
              case inner_acc {
                Some(_) -> inner_acc
                None -> {
                  let #(check_fn, step) = cond
                  case check_fn(instance) {
                    True -> Some(flow.step_to_string(step))
                    False -> None
                  }
                }
              }
            })
            |> option.or(Some(flow.step_to_string(conditional.default)))
          }
          False -> None
        }
      }
    }
  })
}

/// Check if current step triggers parallel execution
fn check_parallel_trigger(
  flow: Flow(step_type, session, error),
  instance: FlowInstance,
) -> Option(ParallelConfig(step_type)) {
  list.find(flow.parallel_configs, fn(config) {
    config.trigger_step == instance.state.current_step
  })
  |> option.from_result()
}

/// Check if current step triggers a subflow
fn check_subflow_trigger(
  flow: Flow(step_type, session, error),
  instance: FlowInstance,
) -> Option(SubflowConfig(step_type, session, error)) {
  list.find(flow.subflows, fn(config) {
    config.trigger_step == instance.state.current_step
  })
  |> option.from_result()
}

/// Start subflow execution
fn start_subflow_execution(
  parent_flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  config: SubflowConfig(step_type, session, error),
) -> Result(Context(session, error), error) {
  // Run flow leave hook on parent flow before entering subflow
  case run_flow_leave_hook(parent_flow.on_flow_leave, ctx, instance) {
    Ok(#(ctx_after_leave, instance_after_leave)) -> {
      // Create stack frame for the parent flow
      let return_step = parent_flow.step_to_string(config.return_step)
      let stack_frame =
        FlowStackFrame(
          flow_name: parent_flow.name,
          return_step: return_step,
          saved_data: instance_after_leave.state.data,
        )

      // Map arguments for the subflow
      let subflow_data = config.map_args(instance_after_leave)

      // Get subflow initial step
      let subflow_initial_step =
        config.flow.step_to_string(config.flow.initial_step)

      // Update instance with stack frame and switch to subflow
      let updated_instance =
        FlowInstance(
          ..instance_after_leave,
          flow_name: config.flow.name,
          state: FlowState(
            current_step: subflow_initial_step,
            data: subflow_data,
            history: [subflow_initial_step],
            flow_stack: [stack_frame, ..instance_after_leave.state.flow_stack],
            parallel_state: None,
          ),
          step_data: dict.new(),
          updated_at: utils.current_time_ms(),
        )

      case parent_flow.storage.save(updated_instance) {
        Ok(_) ->
          execute_subflow_step(
            config.flow,
            ctx_after_leave,
            updated_instance,
            config,
          )
        Error(err) -> handle_error(parent_flow, ctx, instance, Some(err))
      }
    }
    Error(err) -> handle_error(parent_flow, ctx, instance, Some(err))
  }
}

/// Execute a step within a subflow context
fn execute_subflow_step(
  flow: Flow(Dynamic, session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  config: SubflowConfig(step_type, session, error),
) -> Result(Context(session, error), error) {
  case dict.get(flow.steps, instance.state.current_step) {
    Ok(step_config) -> {
      let handler_fn = fn() { step_config.handler(ctx, instance) }
      let result =
        apply_middlewares(
          ctx,
          instance,
          handler_fn,
          list.append(flow.global_middlewares, step_config.middlewares),
        )
      case result {
        Ok(#(new_ctx, action, new_instance)) ->
          process_subflow_action(flow, new_ctx, action, new_instance, config)
        Error(err) ->
          handle_subflow_error(flow, ctx, instance, Some(err), config)
      }
    }
    Error(_) -> handle_subflow_error(flow, ctx, instance, None, config)
  }
}

/// Process action within a subflow
fn process_subflow_action(
  flow: Flow(Dynamic, session, error),
  ctx: Context(session, error),
  action: FlowAction(Dynamic),
  instance: FlowInstance,
  config: SubflowConfig(step_type, session, error),
) -> Result(Context(session, error), error) {
  case action {
    // Handle subflow completion - return to parent
    Complete(data) | Exit(Some(data)) -> {
      return_to_parent_flow(ctx, instance, data, config)
    }

    Exit(None) -> {
      return_to_parent_flow(ctx, instance, instance.state.data, config)
    }

    ReturnFromSubflow(result) -> {
      return_to_parent_flow(ctx, instance, result, config)
    }

    // Cancel propagates up - cancel both subflow and parent
    Cancel -> {
      let _ = flow.storage.delete(instance.id)
      Ok(ctx)
    }

    // Navigation within subflow
    Next(step) -> {
      let step_name = flow.step_to_string(step)
      let updated_instance =
        FlowInstance(
          ..instance,
          state: FlowState(..instance.state, current_step: step_name, history: [
            instance.state.current_step,
            ..instance.state.history
          ]),
          updated_at: utils.current_time_ms(),
        )
      case flow.storage.save(updated_instance) {
        Ok(_) -> execute_subflow_step(flow, ctx, updated_instance, config)
        Error(err) ->
          handle_subflow_error(flow, ctx, instance, Some(err), config)
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
          updated_at: utils.current_time_ms(),
        )
      case flow.storage.save(updated_instance) {
        Ok(_) -> execute_subflow_step(flow, ctx, updated_instance, config)
        Error(err) ->
          handle_subflow_error(flow, ctx, instance, Some(err), config)
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
            flow_stack: instance.state.flow_stack,
            parallel_state: None,
          ),
          step_data: dict.new(),
          updated_at: utils.current_time_ms(),
        )
      case flow.storage.save(updated_instance) {
        Ok(_) -> execute_subflow_step(flow, ctx, updated_instance, config)
        Error(err) ->
          handle_subflow_error(flow, ctx, instance, Some(err), config)
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
              updated_at: utils.current_time_ms(),
            )
          case flow.storage.save(updated_instance) {
            Ok(_) -> execute_subflow_step(flow, ctx, updated_instance, config)
            Error(err) ->
              handle_subflow_error(flow, ctx, instance, Some(err), config)
          }
        }
        [] -> Ok(ctx)
      }
    }

    Wait(token) -> {
      let updated_instance =
        FlowInstance(
          ..instance,
          wait_token: Some(token),
          updated_at: utils.current_time_ms(),
        )
      case flow.storage.save(updated_instance) {
        Ok(_) -> Ok(ctx)
        Error(err) ->
          handle_subflow_error(flow, ctx, instance, Some(err), config)
      }
    }

    WaitCallback(token) -> {
      let updated_instance =
        FlowInstance(
          ..instance,
          wait_token: Some(token),
          updated_at: utils.current_time_ms(),
        )
      case flow.storage.save(updated_instance) {
        Ok(_) -> Ok(ctx)
        Error(err) ->
          handle_subflow_error(flow, ctx, instance, Some(err), config)
      }
    }

    // These shouldn't happen in a simple subflow but handle gracefully
    StartParallel(_, _) | CompleteParallelStep(_, _) | EnterSubflow(_, _) -> {
      Ok(ctx)
    }
  }
}

/// Return from subflow to parent flow
fn return_to_parent_flow(
  ctx: Context(session, error),
  instance: FlowInstance,
  result: Dict(String, String),
  config: SubflowConfig(step_type, session, error),
) -> Result(Context(session, error), error) {
  case instance.state.flow_stack {
    [frame, ..rest_stack] -> {
      // Apply result mapping
      let temp_instance =
        FlowInstance(
          ..instance,
          state: FlowState(..instance.state, data: frame.saved_data),
        )
      let mapped_instance = config.map_result(result, temp_instance)

      // Restore parent flow state
      let updated_instance =
        FlowInstance(
          ..mapped_instance,
          flow_name: frame.flow_name,
          state: FlowState(
            ..mapped_instance.state,
            current_step: frame.return_step,
            history: [frame.return_step, ..mapped_instance.state.history],
            flow_stack: rest_stack,
          ),
          step_data: dict.new(),
          updated_at: utils.current_time_ms(),
        )

      case config.flow.storage.save(updated_instance) {
        Ok(_) -> Ok(ctx)
        Error(_) -> Ok(ctx)
      }
    }
    [] -> Ok(ctx)
  }
}

/// Handle error within a subflow
fn handle_subflow_error(
  flow: Flow(Dynamic, session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  error: Option(error),
  _config: SubflowConfig(step_type, session, error),
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

/// Start parallel execution
fn start_parallel_execution(
  flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  config config: ParallelConfig(step_type),
) -> Result(Context(session, error), error) {
  let pending_steps = list.map(config.parallel_steps, flow.step_to_string)
  let join_step = flow.step_to_string(config.join_step)
  let parallel_state =
    ParallelState(
      join_step:,
      pending_steps:,
      completed_steps: [],
      results: dict.new(),
    )
  let updated_instance =
    FlowInstance(
      ..instance,
      state: FlowState(..instance.state, parallel_state: Some(parallel_state)),
      updated_at: utils.current_time_ms(),
    )
  case flow.storage.save(updated_instance) {
    Ok(_) -> {
      // Execute first parallel step
      case pending_steps {
        [current_step, ..] -> {
          let step_instance =
            FlowInstance(
              ..updated_instance,
              state: FlowState(..updated_instance.state, current_step:),
            )
          execute_step(flow, ctx, step_instance)
        }
        [] -> Ok(ctx)
      }
    }
    Error(err) -> handle_error(flow, ctx, instance, Some(err))
  }
}

/// Merge results from parallel execution
fn merge_parallel_results(
  base_data: Dict(String, String),
  parallel_results: Dict(String, Dict(String, String)),
) -> Dict(String, String) {
  dict.fold(parallel_results, base_data, fn(acc, step_name, step_results) {
    dict.fold(step_results, acc, fn(inner_acc, key, value) {
      dict.insert(inner_acc, step_name <> "." <> key, value)
    })
  })
}

/// Compose flows sequentially
pub fn compose_sequential(
  name: String,
  flows: List(Flow(Dynamic, session, error)),
  storage: FlowStorage(error),
) -> Flow(ComposedStep, session, error) {
  // Create a composed flow that executes flows in sequence
  let builder =
    new(name, storage, composed_step_to_string, string_to_composed_step)

  // Add steps for each flow transition
  let builder =
    list.index_fold(flows, builder, fn(builder, flow, index) {
      let step = ComposedFlowStep(index)
      add_step(builder, step, create_composed_handler(flow, flows, index))
    })

  build(builder, initial: ComposedFlowStep(0))
}

/// Compose flows with conditional selection
pub fn compose_conditional(
  name: String,
  condition: fn(FlowInstance) -> String,
  flows: Dict(String, Flow(Dynamic, session, error)),
  storage: FlowStorage(error),
) -> Flow(ComposedStep, session, error) {
  let builder =
    new(name, storage, composed_step_to_string, string_to_composed_step)

  // Add initial selection step
  let builder =
    add_step(builder, ComposedSelectFlow, fn(ctx, instance) {
      let flow_name = condition(instance)
      case dict.get(flows, flow_name) {
        Ok(flow) -> {
          // Start the selected flow
          let #(user_id, chat_id) = extract_ids_from_context(ctx)
          start_or_resume(flow, ctx, user_id, chat_id, instance.state.data)
          |> result.map(fn(new_ctx) {
            #(new_ctx, Complete(instance.state.data), instance)
          })
        }
        Error(_) -> Ok(#(ctx, Cancel, instance))
      }
    })

  build(builder, initial: ComposedSelectFlow)
}

/// Compose flows for parallel execution
pub fn compose_parallel(
  name: String,
  flows: List(Flow(Dynamic, session, error)),
  merge_results: fn(List(Dict(String, String))) -> Dict(String, String),
  storage: FlowStorage(error),
) -> Flow(ComposedStep, session, error) {
  let builder =
    new(name, storage, composed_step_to_string, string_to_composed_step)

  let parallel_steps =
    list.index_map(flows, fn(_, index) { ComposedParallelFlow(index) })

  let builder =
    add_step(builder, ComposedStartParallel, fn(ctx, instance) {
      Ok(#(ctx, StartParallel(parallel_steps, ComposedMergeResults), instance))
    })

  let builder =
    list.index_fold(flows, builder, fn(builder, flow, index) {
      let step = ComposedParallelFlow(index)
      add_step(builder, step, fn(ctx, instance) {
        let #(user_id, chat_id) = extract_ids_from_context(ctx)
        start_or_resume(flow, ctx, user_id, chat_id, instance.state.data)
        |> result.map(fn(new_ctx) {
          #(new_ctx, CompleteParallelStep(step, instance.state.data), instance)
        })
      })
    })

  let builder =
    add_step(builder, ComposedMergeResults, fn(ctx, instance) {
      case instance.state.parallel_state {
        Some(state) -> {
          let results = dict.values(state.results)
          let merged = merge_results(results)
          let updated_instance =
            FlowInstance(
              ..instance,
              state: FlowState(..instance.state, data: merged),
            )
          Ok(#(ctx, Complete(merged), updated_instance))
        }
        None -> Ok(#(ctx, Complete(instance.state.data), instance))
      }
    })

  let builder =
    add_parallel_steps(
      builder,
      ComposedStartParallel,
      parallel_steps,
      ComposedMergeResults,
    )

  build(builder, initial: ComposedStartParallel)
}

pub type ComposedStep {
  ComposedFlowStep(Int)
  ComposedSelectFlow
  ComposedStartParallel
  ComposedParallelFlow(Int)
  ComposedMergeResults
}

fn composed_step_to_string(step: ComposedStep) -> String {
  case step {
    ComposedFlowStep(n) -> "flow_" <> int.to_string(n)
    ComposedSelectFlow -> "select_flow"
    ComposedStartParallel -> "start_parallel"
    ComposedParallelFlow(n) -> "parallel_" <> int.to_string(n)
    ComposedMergeResults -> "merge_results"
  }
}

fn string_to_composed_step(string: String) -> Result(ComposedStep, Nil) {
  case string {
    "select_flow" -> Ok(ComposedSelectFlow)
    "start_parallel" -> Ok(ComposedStartParallel)
    "merge_results" -> Ok(ComposedMergeResults)
    _ -> {
      case string.starts_with(string, "flow_") {
        True -> {
          string.drop_start(string, 5)
          |> int.parse
          |> result.map(ComposedFlowStep)
          |> result.replace_error(Nil)
        }
        False -> {
          case string.starts_with(string, "parallel_") {
            True -> {
              string.drop_start(string, 9)
              |> int.parse
              |> result.map(ComposedParallelFlow)
              |> result.replace_error(Nil)
            }
            False -> Error(Nil)
          }
        }
      }
    }
  }
}

fn create_composed_handler(
  flow: Flow(Dynamic, session, error),
  all_flows: List(Flow(Dynamic, session, error)),
  index: Int,
) -> StepHandler(ComposedStep, session, error) {
  fn(ctx: Context(session, error), instance: FlowInstance) {
    let #(user_id, chat_id) = extract_ids_from_context(ctx)
    start_or_resume(flow, ctx, user_id, chat_id, instance.state.data)
    |> result.map(fn(new_ctx) {
      case list.drop(all_flows, index + 1) {
        [_, ..] -> #(new_ctx, Next(ComposedFlowStep(index + 1)), instance)
        [] -> #(new_ctx, Complete(instance.state.data), instance)
      }
    })
  }
}

pub fn validation_middleware(
  validator: fn(FlowInstance) -> Result(Nil, String),
) -> StepMiddleware(step_type, session, error) {
  fn(ctx, instance, next) {
    case validator(instance) {
      Ok(_) -> next()
      Error(msg) -> {
        case reply.with_text(ctx, "Validation failed: " <> msg) {
          Ok(_) -> Ok(#(ctx, Back, instance))
          Error(_) -> Ok(#(ctx, Cancel, instance))
        }
      }
    }
  }
}
