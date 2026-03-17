//// Composition API for combining flows.

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string
import telega/bot.{type Context}
import telega/flow/builder
import telega/flow/engine
import telega/flow/types.{
  type ComposedStep, type Flow, type FlowInstance, type FlowStorage,
  type StepHandler, type StepMiddleware, Back, Cancel, Complete,
  CompleteParallelStep, ComposedFlowStep, ComposedMergeResults,
  ComposedParallelFlow, ComposedSelectFlow, ComposedStartParallel, FlowInstance,
  FlowState, StartParallel,
}
import telega/reply

/// Compose flows sequentially
pub fn compose_sequential(
  name: String,
  flows: List(Flow(Dynamic, session, error)),
  storage: FlowStorage(error),
) -> Flow(ComposedStep, session, error) {
  let flow_builder =
    builder.new(name, storage, composed_step_to_string, string_to_composed_step)

  let flow_builder =
    list.index_fold(flows, flow_builder, fn(b, flow, index) {
      let step = ComposedFlowStep(index)
      builder.add_step(b, step, create_composed_handler(flow, flows, index))
    })

  builder.build(flow_builder, initial: ComposedFlowStep(0))
}

/// Compose flows with conditional selection
pub fn compose_conditional(
  name: String,
  condition: fn(FlowInstance) -> String,
  flows: Dict(String, Flow(Dynamic, session, error)),
  storage: FlowStorage(error),
) -> Flow(ComposedStep, session, error) {
  let flow_builder =
    builder.new(name, storage, composed_step_to_string, string_to_composed_step)

  let flow_builder =
    builder.add_step(flow_builder, ComposedSelectFlow, fn(ctx, instance) {
      let flow_name = condition(instance)
      case dict.get(flows, flow_name) {
        Ok(flow) -> {
          let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
          engine.start_or_resume(
            flow,
            ctx,
            user_id,
            chat_id,
            instance.state.data,
          )
          |> result.map(fn(new_ctx) {
            #(new_ctx, Complete(instance.state.data), instance)
          })
        }
        Error(_) -> Ok(#(ctx, Cancel, instance))
      }
    })

  builder.build(flow_builder, initial: ComposedSelectFlow)
}

/// Compose flows for parallel execution
pub fn compose_parallel(
  name: String,
  flows: List(Flow(Dynamic, session, error)),
  merge_results: fn(List(Dict(String, String))) -> Dict(String, String),
  storage: FlowStorage(error),
) -> Flow(ComposedStep, session, error) {
  let flow_builder =
    builder.new(name, storage, composed_step_to_string, string_to_composed_step)

  let parallel_steps =
    list.index_map(flows, fn(_, index) { ComposedParallelFlow(index) })

  let flow_builder =
    builder.add_step(flow_builder, ComposedStartParallel, fn(ctx, instance) {
      Ok(#(ctx, StartParallel(parallel_steps, ComposedMergeResults), instance))
    })

  let flow_builder =
    list.index_fold(flows, flow_builder, fn(b, flow, index) {
      let step = ComposedParallelFlow(index)
      builder.add_step(b, step, fn(ctx, instance) {
        let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
        engine.start_or_resume(flow, ctx, user_id, chat_id, instance.state.data)
        |> result.map(fn(new_ctx) {
          #(new_ctx, CompleteParallelStep(step, instance.state.data), instance)
        })
      })
    })

  let flow_builder =
    builder.add_step(flow_builder, ComposedMergeResults, fn(ctx, instance) {
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
        option.None -> Ok(#(ctx, Complete(instance.state.data), instance))
      }
    })

  let flow_builder =
    builder.add_parallel_steps(
      flow_builder,
      ComposedStartParallel,
      parallel_steps,
      ComposedMergeResults,
    )

  builder.build(flow_builder, initial: ComposedStartParallel)
}

/// Validation middleware
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

fn composed_step_to_string(step: ComposedStep) -> String {
  case step {
    ComposedFlowStep(n) -> "flow_" <> int.to_string(n)
    ComposedSelectFlow -> "select_flow"
    ComposedStartParallel -> "start_parallel"
    ComposedParallelFlow(n) -> "parallel_" <> int.to_string(n)
    ComposedMergeResults -> "merge_results"
  }
}

fn string_to_composed_step(s: String) -> Result(ComposedStep, Nil) {
  case s {
    "select_flow" -> Ok(ComposedSelectFlow)
    "start_parallel" -> Ok(ComposedStartParallel)
    "merge_results" -> Ok(ComposedMergeResults)
    _ -> {
      case string.starts_with(s, "flow_") {
        True -> {
          string.drop_start(s, 5)
          |> int.parse
          |> result.map(ComposedFlowStep)
          |> result.replace_error(Nil)
        }
        False -> {
          case string.starts_with(s, "parallel_") {
            True -> {
              string.drop_start(s, 9)
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
    let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
    engine.start_or_resume(flow, ctx, user_id, chat_id, instance.state.data)
    |> result.map(fn(new_ctx) {
      case list.drop(all_flows, index + 1) {
        [_, ..] -> #(new_ctx, types.Next(ComposedFlowStep(index + 1)), instance)
        [] -> #(new_ctx, Complete(instance.state.data), instance)
      }
    })
  }
}
