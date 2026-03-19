//// Pure control functions that construct `FlowAction` values.

import gleam/dict.{type Dict}
import gleam/option.{type Option}
import telega/bot.{type Context}
import telega/flow/types.{
  type FlowInstance, type StepResult, Back, Cancel, Complete, EnterSubflow, Exit,
  GoTo, Next, NextString, ReturnFromSubflow, Wait, WaitCallback,
  WaitCallbackWithTimeout, WaitWithTimeout,
}
import telega/reply

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
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, Wait, instance))
}

/// Wait for callback
pub fn wait_callback(
  ctx: Context(session, error),
  instance: FlowInstance,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, WaitCallback, instance))
}

/// Wait for user input with timeout
pub fn wait_with_timeout(
  ctx: Context(session, error),
  instance: FlowInstance,
  timeout_ms timeout_ms: Int,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, WaitWithTimeout(timeout_ms), instance))
}

/// Wait for callback with timeout
pub fn wait_callback_with_timeout(
  ctx: Context(session, error),
  instance: FlowInstance,
  timeout_ms timeout_ms: Int,
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, WaitCallbackWithTimeout(timeout_ms), instance))
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
pub fn return_from_subflow(
  ctx: Context(session, error),
  instance: FlowInstance,
  result result: Dict(String, String),
) -> StepResult(step_type, session, error) {
  Ok(#(ctx, ReturnFromSubflow(result), instance))
}

/// Try a result, cancelling the flow on error.
///
/// Designed for `use` syntax to flatten nested error handling in flow steps:
///
/// ```gleam
/// use _ <- action.try(ctx, instance, reply.with_text(ctx, "Hello!"))
/// use data <- action.try(ctx, instance, fetch_data())
/// action.complete(ctx, instance)
/// ```
pub fn try(
  ctx: Context(session, error),
  instance: FlowInstance,
  result: Result(a, any_error),
  continue: fn(a) -> StepResult(step_type, session, error),
) -> StepResult(step_type, session, error) {
  case result {
    Ok(value) -> continue(value)
    Error(_) -> cancel(ctx, instance)
  }
}

/// Try a result, sending an error message and cancelling the flow on error.
///
/// The `to_message` function converts the error into a user-facing message
/// that is sent via `reply.with_text` before cancelling.
///
/// ```gleam
/// use data <- action.try_with_message(ctx, instance,
///   extract_data(instance),
///   fn(err) { "❌ Error: " <> err },
/// )
/// action.complete(ctx, instance)
/// ```
pub fn try_with_message(
  ctx: Context(session, error),
  instance: FlowInstance,
  result: Result(a, err),
  to_message: fn(err) -> String,
  continue: fn(a) -> StepResult(step_type, session, error),
) -> StepResult(step_type, session, error) {
  case result {
    Ok(value) -> continue(value)
    Error(err) -> {
      let _ = reply.with_text(ctx, to_message(err))
      cancel(ctx, instance)
    }
  }
}
