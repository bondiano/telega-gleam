//// Pure control functions that construct `FlowAction` values.

import gleam/dict.{type Dict}
import gleam/option.{type Option}
import telega/bot.{type Context}
import telega/flow/types.{
  type FlowInstance, type StepResult, Back, Cancel, Complete, EnterSubflow, Exit,
  GoTo, Next, NextString, ReturnFromSubflow, Wait, WaitCallback,
  WaitCallbackWithTimeout, WaitWithTimeout,
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
