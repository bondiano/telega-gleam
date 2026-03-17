//// Core execution engine, hooks, middleware application, and conditionals.

import gleam/dict
import gleam/dynamic
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import telega/bot.{type Context}
import telega/flow/instance
import telega/flow/types.{
  type Flow, type FlowAction, type FlowEnterHook, type FlowExitHook,
  type FlowInstance, type FlowLeaveHook, type FlowStorage, type ParallelConfig,
  type StepEnterHook, type StepLeaveHook, type StepMiddleware, type StepResult,
  type SubflowConfig, Back, Cancel, Complete, CompleteParallelStep, EnterSubflow,
  Exit, FlowInstance, FlowStackFrame, FlowState, GoTo, Next, NextString,
  ParallelState, ReturnFromSubflow, StartParallel, Wait, WaitCallback,
  WaitCallbackWithTimeout, WaitWithTimeout,
}
import telega/internal/utils

/// Start or resume a flow for a given user/chat
@internal
pub fn start_or_resume(
  flow flow: Flow(step_type, session, error),
  ctx ctx: Context(session, error),
  user_id user_id: Int,
  chat_id chat_id: Int,
  initial_data initial_data: dict.Dict(String, String),
) -> Result(Context(session, error), error) {
  let flow_id =
    flow.name <> "_" <> int.to_string(chat_id) <> "_" <> int.to_string(user_id)

  case flow.storage.load(flow_id) {
    Ok(Some(existing_instance)) ->
      case instance.is_expired(existing_instance, flow.ttl_ms) {
        True -> {
          let _ = flow.storage.delete(existing_instance.id)
          let initial_step_name = flow.step_to_string(flow.initial_step)
          let new_instance =
            instance.new_instance_with_data(
              id: flow_id,
              flow_name: flow.name,
              user_id:,
              chat_id:,
              current_step: initial_step_name,
              data: initial_data,
            )
          case flow.storage.save(new_instance) {
            Ok(_) -> {
              case run_flow_enter_hook(flow.on_flow_enter, ctx, new_instance) {
                Ok(#(ctx_after_enter, instance_after_enter)) ->
                  execute_step(flow, ctx_after_enter, instance_after_enter)
                Error(err) -> handle_error(flow, ctx, new_instance, Some(err))
              }
            }
            Error(err) -> handle_error(flow, ctx, new_instance, Some(err))
          }
        }
        False -> execute_step(flow, ctx, existing_instance)
      }
    Ok(None) -> {
      let initial_step_name = flow.step_to_string(flow.initial_step)
      let new_instance =
        instance.new_instance_with_data(
          id: flow_id,
          flow_name: flow.name,
          user_id:,
          chat_id:,
          current_step: initial_step_name,
          data: initial_data,
        )

      case flow.storage.save(new_instance) {
        Ok(_) -> {
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
        instance.new_instance(
          id: flow_id,
          flow_name: flow.name,
          user_id:,
          chat_id:,
          current_step: "",
        )
      handle_error(flow, ctx, dummy_instance, Some(err))
    }
  }
}

/// Resume a flow with a wait token
@internal
pub fn resume_with_token(
  flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  token token: String,
  data data: Option(dict.Dict(String, String)),
) -> Result(Context(session, error), error) {
  case find_instance_by_token(flow.storage, token) {
    Ok(Some(instance)) -> resume_with_instance(flow, ctx, instance, data)
    _ -> Ok(ctx)
  }
}

/// Resume a flow with an existing instance
@internal
pub fn resume_with_instance(
  flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  data data: Option(dict.Dict(String, String)),
) -> Result(Context(session, error), error) {
  let updated_instance = case data {
    Some(d) ->
      FlowInstance(
        ..instance,
        step_data: dict.merge(instance.step_data, d),
        wait_token: None,
        wait_timeout_at: None,
      )
    None -> FlowInstance(..instance, wait_token: None, wait_timeout_at: None)
  }
  execute_step(flow, ctx, updated_instance)
}

/// Execute the current step of a flow
@internal
pub fn execute_step(
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

/// Handle an error in a flow
@internal
pub fn handle_error(
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

/// Extract user and chat IDs from context
@internal
pub fn extract_ids_from_context(ctx: Context(session, error)) -> #(Int, Int) {
  #(ctx.update.from_id, ctx.update.chat_id)
}

/// Apply middleware chain to handler
@internal
pub fn apply_middlewares(
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

/// Generate a unique wait token
@internal
pub fn generate_wait_token(instance: FlowInstance) -> String {
  instance.id <> ":" <> int.to_string(utils.current_time_ms())
}

/// Process action with leave hook support
fn process_action_with_leave_hook(
  flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  action: FlowAction(step_type),
  instance: FlowInstance,
  leave_hook: Option(StepLeaveHook(session, error)),
) -> Result(Context(session, error), error) {
  case action {
    Wait | WaitCallback | WaitWithTimeout(_) | WaitCallbackWithTimeout(_) ->
      process_action(flow, ctx, action, instance)
    _ -> {
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
          step_data: dict.delete(instance.step_data, "__wait_result"),
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
          step_data: dict.delete(instance.step_data, "__wait_result"),
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
              step_data: dict.delete(instance.step_data, "__wait_result"),
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
      case flow.on_complete {
        Some(handler) -> {
          case handler(ctx, completed_instance) {
            Ok(new_ctx) -> {
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
      case run_flow_exit_hook(flow.on_flow_exit, ctx, instance) {
        Ok(final_ctx) -> {
          let _ = flow.storage.delete(instance.id)
          Ok(final_ctx)
        }
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    Wait | WaitCallback -> {
      let token = generate_wait_token(instance)
      let updated_instance =
        FlowInstance(
          ..instance,
          wait_token: Some(token),
          wait_timeout_at: None,
          updated_at: utils.current_time_ms(),
        )

      case flow.storage.save(updated_instance) {
        Ok(_) -> Ok(ctx)
        Error(err) -> handle_error(flow, ctx, instance, Some(err))
      }
    }

    WaitWithTimeout(timeout_ms) | WaitCallbackWithTimeout(timeout_ms) -> {
      let token = generate_wait_token(instance)
      let wait_timeout_at = utils.current_time_ms() + timeout_ms
      let updated_instance =
        FlowInstance(
          ..instance,
          wait_token: Some(token),
          wait_timeout_at: Some(wait_timeout_at),
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
      case
        list.find(flow.subflows, fn(config) { config.flow.name == subflow_name })
      {
        Ok(subflow_config) -> {
          let return_step = flow.step_to_string(subflow_config.return_step)
          let stack_frame =
            FlowStackFrame(
              flow_name: flow.name,
              return_step: return_step,
              saved_data: instance.state.data,
            )

          let subflow_initial_step =
            subflow_config.flow.step_to_string(subflow_config.flow.initial_step)

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
          Ok(ctx)
        }
      }
    }
  }
}

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

fn check_parallel_trigger(
  flow: Flow(step_type, session, error),
  instance: FlowInstance,
) -> Option(ParallelConfig(step_type)) {
  list.find(flow.parallel_configs, fn(config) {
    config.trigger_step == instance.state.current_step
  })
  |> option.from_result()
}

fn check_subflow_trigger(
  flow: Flow(step_type, session, error),
  instance: FlowInstance,
) -> Option(SubflowConfig(step_type, session, error)) {
  list.find(flow.subflows, fn(config) {
    config.trigger_step == instance.state.current_step
  })
  |> option.from_result()
}

fn start_subflow_execution(
  parent_flow: Flow(step_type, session, error),
  ctx: Context(session, error),
  instance: FlowInstance,
  config: SubflowConfig(step_type, session, error),
) -> Result(Context(session, error), error) {
  case run_flow_leave_hook(parent_flow.on_flow_leave, ctx, instance) {
    Ok(#(ctx_after_leave, instance_after_leave)) -> {
      let return_step = parent_flow.step_to_string(config.return_step)
      let stack_frame =
        FlowStackFrame(
          flow_name: parent_flow.name,
          return_step: return_step,
          saved_data: instance_after_leave.state.data,
        )

      let subflow_data = config.map_args(instance_after_leave)

      let subflow_initial_step =
        config.flow.step_to_string(config.flow.initial_step)

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

fn merge_parallel_results(
  base_data: dict.Dict(String, String),
  parallel_results: dict.Dict(String, dict.Dict(String, String)),
) -> dict.Dict(String, String) {
  dict.fold(parallel_results, base_data, fn(acc, step_name, step_results) {
    dict.fold(step_results, acc, fn(inner_acc, key, value) {
      dict.insert(inner_acc, step_name <> "." <> key, value)
    })
  })
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

// Forward declaration for subflow - the actual implementation uses
// execute_subflow_step from the subflow module, but since engine needs it
// for the EnterSubflow action, we include the subflow execution here.

/// Execute a step within a subflow context
@internal
pub fn execute_subflow_step(
  flow: Flow(dynamic.Dynamic, session, error),
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

fn process_subflow_action(
  flow: Flow(dynamic.Dynamic, session, error),
  ctx: Context(session, error),
  action: FlowAction(dynamic.Dynamic),
  instance: FlowInstance,
  config: SubflowConfig(step_type, session, error),
) -> Result(Context(session, error), error) {
  case action {
    Complete(data) | Exit(Some(data)) -> {
      return_to_parent_flow(ctx, instance, data, config)
    }

    Exit(None) -> {
      return_to_parent_flow(ctx, instance, instance.state.data, config)
    }

    ReturnFromSubflow(result) -> {
      return_to_parent_flow(ctx, instance, result, config)
    }

    Cancel -> {
      let _ = flow.storage.delete(instance.id)
      Ok(ctx)
    }

    Next(step) -> {
      let step_name = flow.step_to_string(step)
      let updated_instance =
        FlowInstance(
          ..instance,
          state: FlowState(..instance.state, current_step: step_name, history: [
            instance.state.current_step,
            ..instance.state.history
          ]),
          step_data: dict.delete(instance.step_data, "__wait_result"),
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
          step_data: dict.delete(instance.step_data, "__wait_result"),
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
              step_data: dict.delete(instance.step_data, "__wait_result"),
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

    Wait | WaitCallback -> {
      let token = generate_wait_token(instance)
      let updated_instance =
        FlowInstance(
          ..instance,
          wait_token: Some(token),
          wait_timeout_at: None,
          updated_at: utils.current_time_ms(),
        )
      case flow.storage.save(updated_instance) {
        Ok(_) -> Ok(ctx)
        Error(err) ->
          handle_subflow_error(flow, ctx, instance, Some(err), config)
      }
    }

    WaitWithTimeout(timeout_ms) | WaitCallbackWithTimeout(timeout_ms) -> {
      let token = generate_wait_token(instance)
      let wait_timeout_at = utils.current_time_ms() + timeout_ms
      let updated_instance =
        FlowInstance(
          ..instance,
          wait_token: Some(token),
          wait_timeout_at: Some(wait_timeout_at),
          updated_at: utils.current_time_ms(),
        )
      case flow.storage.save(updated_instance) {
        Ok(_) -> Ok(ctx)
        Error(err) ->
          handle_subflow_error(flow, ctx, instance, Some(err), config)
      }
    }

    StartParallel(_, _) | CompleteParallelStep(_, _) | EnterSubflow(_, _) -> {
      Ok(ctx)
    }
  }
}

fn return_to_parent_flow(
  ctx: Context(session, error),
  instance: FlowInstance,
  result: dict.Dict(String, String),
  config: SubflowConfig(step_type, session, error),
) -> Result(Context(session, error), error) {
  case instance.state.flow_stack {
    [frame, ..rest_stack] -> {
      let temp_instance =
        FlowInstance(
          ..instance,
          state: FlowState(..instance.state, data: frame.saved_data),
        )
      let mapped_instance = config.map_result(result, temp_instance)

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

fn handle_subflow_error(
  flow: Flow(dynamic.Dynamic, session, error),
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
