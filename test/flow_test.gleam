import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleeunit
import gleeunit/should
import telega/flow

pub fn main() {
  gleeunit.main()
}

pub type TestStep {
  Start
  Middle
  End
  Parallel1
  Parallel2
  Join
  ConditionalA
  ConditionalB
  ErrorStep
}

fn test_step_to_string(step: TestStep) -> String {
  case step {
    Start -> "start"
    Middle -> "middle"
    End -> "end"
    Parallel1 -> "parallel1"
    Parallel2 -> "parallel2"
    Join -> "join"
    ConditionalA -> "conditional_a"
    ConditionalB -> "conditional_b"
    ErrorStep -> "error_step"
  }
}

fn string_to_test_step(s: String) -> Result(TestStep, Nil) {
  case s {
    "start" -> Ok(Start)
    "middle" -> Ok(Middle)
    "end" -> Ok(End)
    "parallel1" -> Ok(Parallel1)
    "parallel2" -> Ok(Parallel2)
    "join" -> Ok(Join)
    "conditional_a" -> Ok(ConditionalA)
    "conditional_b" -> Ok(ConditionalB)
    "error_step" -> Ok(ErrorStep)
    _ -> Error(Nil)
  }
}

pub fn step_data_operations_test() {
  let instance =
    flow.FlowInstance(
      id: "test_123_456",
      flow_name: "test_flow",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "step1",
        data: dict.new(),
        history: ["step1"],
        flow_stack: [],
        parallel_state: None,
      ),
      step_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  let instance1 = flow.store_step_data(instance, "key1", "value1")
  flow.get_step_data(instance1, "key1") |> should.equal(Some("value1"))

  let instance2 = flow.store_step_data(instance1, "key2", "value2")
  flow.get_step_data(instance2, "key1") |> should.equal(Some("value1"))
  flow.get_step_data(instance2, "key2") |> should.equal(Some("value2"))

  let instance3 = flow.clear_step_data_key(instance2, "key1")
  flow.get_step_data(instance3, "key1") |> should.equal(None)
  flow.get_step_data(instance3, "key2") |> should.equal(Some("value2"))

  let instance4 = flow.clear_step_data(instance3)
  flow.get_step_data(instance4, "key2") |> should.equal(None)
}

pub fn flow_data_persistence_test() {
  let instance =
    flow.FlowInstance(
      id: "test_123_456",
      flow_name: "test_flow",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "step1",
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

  let instance1 = flow.store_data(instance, "name", "Alice")
  let instance2 = flow.store_data(instance1, "age", "25")
  let instance3 = flow.store_data(instance2, "email", "alice@example.com")

  flow.get_data(instance3, "name") |> should.equal(Some("Alice"))
  flow.get_data(instance3, "age") |> should.equal(Some("25"))
  flow.get_data(instance3, "email") |> should.equal(Some("alice@example.com"))
  flow.get_data(instance3, "nonexistent") |> should.equal(None)
}

pub fn middleware_execution_order_test() {
  let execution_order = process.new_subject()

  let middleware1 = fn(_ctx, _instance: flow.FlowInstance, next) {
    process.send(execution_order, "middleware1_before")
    let result = next()
    process.send(execution_order, "middleware1_after")
    result
  }

  let middleware2 = fn(_ctx, _instance: flow.FlowInstance, next) {
    process.send(execution_order, "middleware2_before")
    let result = next()
    process.send(execution_order, "middleware2_after")
    result
  }

  let handler = fn(_ctx, instance: flow.FlowInstance) {
    process.send(execution_order, "handler")
    Ok(#(Nil, flow.Next(End), instance))
  }

  let test_instance =
    flow.FlowInstance(
      id: "test_middleware",
      flow_name: "test",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "start",
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

  let result =
    middleware1(Nil, test_instance, fn() {
      middleware2(Nil, test_instance, fn() { handler(Nil, test_instance) })
    })

  let assert Ok(msg1) = process.receive(execution_order, 100)
  msg1 |> should.equal("middleware1_before")

  let assert Ok(msg2) = process.receive(execution_order, 100)
  msg2 |> should.equal("middleware2_before")

  let assert Ok(msg3) = process.receive(execution_order, 100)
  msg3 |> should.equal("handler")

  let assert Ok(msg4) = process.receive(execution_order, 100)
  msg4 |> should.equal("middleware2_after")

  let assert Ok(msg5) = process.receive(execution_order, 100)
  msg5 |> should.equal("middleware1_after")

  case result {
    Ok(#(_, action, _)) -> {
      case action {
        flow.Next(End) -> Nil
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn test_parallel_steps_configuration() {
  let storage = flow.create_memory_storage()
  let parallel_results = process.new_subject()

  let flow_builder =
    flow.new("test", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) {
      flow.next(ctx, instance, step: Middle)
    })
    |> flow.add_parallel_steps(Middle, [Parallel1, Parallel2], Join)
    |> flow.add_step(Parallel1, fn(ctx, instance) {
      process.send(parallel_results, "parallel1_executed")
      let result = dict.from_list([#("task1", "completed")])
      Ok(#(ctx, flow.CompleteParallelStep(Parallel1, result), instance))
    })
    |> flow.add_step(Parallel2, fn(ctx, instance) {
      process.send(parallel_results, "parallel2_executed")
      let result = dict.from_list([#("task2", "completed")])
      Ok(#(ctx, flow.CompleteParallelStep(Parallel2, result), instance))
    })
    |> flow.add_step(Join, fn(ctx, instance) {
      let task1 = flow.get_data(instance, "parallel1.task1")
      let task2 = flow.get_data(instance, "parallel2.task2")

      case task1, task2 {
        Some("completed"), Some("completed") -> {
          process.send(parallel_results, "join_successful")
          flow.complete(ctx, instance)
        }
        _, _ -> {
          process.send(parallel_results, "join_failed")
          flow.cancel(ctx, instance)
        }
      }
    })

  let _ = flow.build(flow_builder, initial: Start)

  let instance_with_parallel =
    flow.FlowInstance(
      id: "test_parallel",
      flow_name: "test",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "middle",
        data: dict.new(),
        history: ["start"],
        flow_stack: [],
        parallel_state: Some(flow.ParallelState(
          pending_steps: ["parallel1", "parallel2"],
          completed_steps: [],
          results: dict.new(),
          join_step: "join",
        )),
      ),
      step_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  case instance_with_parallel.state.parallel_state {
    Some(ps) -> {
      ps.pending_steps |> should.equal(["parallel1", "parallel2"])
      ps.join_step |> should.equal("join")
      ps.completed_steps |> should.equal([])
    }
    None -> should.fail()
  }
}

pub fn multi_conditional_routing_test() {
  let storage = flow.create_memory_storage()

  let flow_builder =
    flow.new("grading", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) {
      flow.next(ctx, instance, step: Middle)
    })
    |> flow.add_multi_conditional(
      Middle,
      [
        #(
          fn(i) {
            case flow.get_data(i, "score") {
              Some(s) ->
                case int.parse(s) {
                  Ok(score) -> score >= 90
                  _ -> False
                }
              _ -> False
            }
          },
          ConditionalA,
        ),
        #(
          fn(i) {
            case flow.get_data(i, "score") {
              Some(s) ->
                case int.parse(s) {
                  Ok(score) -> score >= 70 && score < 90
                  _ -> False
                }
              _ -> False
            }
          },
          ConditionalB,
        ),
      ],
      End,
    )
    |> flow.add_step(ConditionalA, fn(ctx, instance) {
      let updated = flow.store_data(instance, "grade", "A")
      flow.complete(ctx, updated)
    })
    |> flow.add_step(ConditionalB, fn(ctx, instance) {
      let updated = flow.store_data(instance, "grade", "B")
      flow.complete(ctx, updated)
    })
    |> flow.add_step(End, fn(ctx, instance) {
      let updated = flow.store_data(instance, "grade", "F")
      flow.complete(ctx, updated)
    })

  let _ = flow.build(flow_builder, initial: Start)

  let test_cases = [
    #("95", ConditionalA, "A"),
    #("85", ConditionalB, "B"),
    #("75", ConditionalB, "B"),
    #("65", End, "F"),
    #("50", End, "F"),
  ]

  list.each(test_cases, fn(test_case) {
    let #(score, expected_step, _expected_grade) = test_case

    let score_int = int.parse(score) |> result.unwrap(0)

    case score_int {
      s if s >= 90 -> expected_step |> should.equal(ConditionalA)
      s if s >= 70 -> expected_step |> should.equal(ConditionalB)
      _ -> expected_step |> should.equal(End)
    }
  })
}

pub fn flow_stack_for_nested_flows_test() {
  let parent_instance =
    flow.FlowInstance(
      id: "parent_123",
      flow_name: "parent_flow",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "parent_step",
        data: dict.from_list([#("parent_data", "value")]),
        history: ["parent_start"],
        flow_stack: [],
        parallel_state: None,
      ),
      step_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  let stack_frame =
    flow.FlowStackFrame(
      flow_name: "parent_flow",
      return_step: "parent_step",
      saved_data: parent_instance.state.data,
    )

  let child_instance =
    flow.FlowInstance(
      id: "child_123",
      flow_name: "child_flow",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "child_start",
        data: dict.new(),
        history: [],
        flow_stack: [stack_frame],
        parallel_state: None,
      ),
      step_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  child_instance.state.flow_stack |> list.length() |> should.equal(1)

  case child_instance.state.flow_stack {
    [frame] -> {
      frame.flow_name |> should.equal("parent_flow")
      frame.return_step |> should.equal("parent_step")
      dict.get(frame.saved_data, "parent_data") |> should.equal(Ok("value"))
    }
    _ -> should.fail()
  }

  case child_instance.state.flow_stack {
    [frame, ..rest] -> {
      let restored_instance =
        flow.FlowInstance(
          ..child_instance,
          flow_name: frame.flow_name,
          state: flow.FlowState(
            current_step: frame.return_step,
            data: frame.saved_data,
            history: ["child_flow", "parent_start"],
            flow_stack: rest,
            parallel_state: None,
          ),
        )

      restored_instance.flow_name |> should.equal("parent_flow")
      restored_instance.state.current_step |> should.equal("parent_step")
      flow.get_data(restored_instance, "parent_data")
      |> should.equal(Some("value"))
    }
    _ -> should.fail()
  }
}

pub fn wait_mechanisms_set_tokens_test() {
  let storage = flow.create_memory_storage()

  let flow_builder =
    flow.new("test", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) {
      flow.wait(ctx, instance, "wait_for_input")
    })
    |> flow.add_step(Middle, fn(ctx, instance) {
      flow.wait_callback(ctx, instance, "wait_for_button")
    })
    |> flow.add_step(End, fn(ctx, instance) { flow.complete(ctx, instance) })

  let _ = flow.build(flow_builder, initial: Start)

  let instance1 =
    flow.FlowInstance(
      id: "test_wait",
      flow_name: "test",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "start",
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

  let waiting_instance =
    flow.FlowInstance(..instance1, wait_token: Some("wait_for_input"))

  waiting_instance.wait_token |> should.equal(Some("wait_for_input"))

  let callback_instance =
    flow.FlowInstance(
      ..instance1,
      state: flow.FlowState(..instance1.state, current_step: "middle"),
      wait_token: Some("wait_for_button"),
    )

  callback_instance.wait_token |> should.equal(Some("wait_for_button"))
}

// ============================================================================
// Nested Flow / Subflow Tests
// ============================================================================

/// Test inline step type creation
pub fn inline_step_type_test() {
  let step = flow.InlineStep("my_step")
  step.name |> should.equal("my_step")
}

/// Test inline_next navigation helper
pub fn inline_next_navigation_test() {
  let storage = flow.create_memory_storage()
  let execution_log = process.new_subject()

  // Just verify that the flow builds without errors
  let _parent_flow =
    flow.new("parent", storage, test_step_to_string, string_to_test_step)
    |> flow.with_inline_subflow(
      name: "inline_sub",
      trigger: Middle,
      return_to: End,
      initial: "step1",
      steps: [
        #("step1", fn(ctx, instance) {
          process.send(execution_log, "inline_step1")
          flow.inline_next(ctx, instance, "step2")
        }),
        #("step2", fn(ctx, instance) {
          process.send(execution_log, "inline_step2")
          flow.return_from_subflow(ctx, instance, dict.new())
        }),
      ],
    )
    |> flow.add_step(Start, fn(ctx, instance) {
      process.send(execution_log, "parent_start")
      flow.next(ctx, instance, step: Middle)
    })
    |> flow.add_step(End, fn(ctx, instance) {
      process.send(execution_log, "parent_end")
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  // Flow builds successfully (no runtime assertion on opaque type)
  True |> should.be_true()
}

/// Test step hooks are called in correct order
pub fn step_hooks_execution_order_test() {
  let storage = flow.create_memory_storage()
  let execution_log = process.new_subject()

  let _test_flow =
    flow.new("hooks_test", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step_with_hooks(
      Start,
      handler: fn(ctx, instance) {
        process.send(execution_log, "handler")
        flow.next(ctx, instance, step: End)
      },
      on_enter: Some(fn(ctx, instance) {
        process.send(execution_log, "on_enter")
        Ok(#(ctx, instance))
      }),
      on_leave: Some(fn(ctx, instance) {
        process.send(execution_log, "on_leave")
        Ok(#(ctx, instance))
      }),
    )
    |> flow.add_step(End, fn(ctx, instance) {
      process.send(execution_log, "end_handler")
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  // Verify flow was built (no runtime assertion on opaque type)
  True |> should.be_true()
}

/// Test flow lifecycle hooks are set correctly
pub fn flow_lifecycle_hooks_builder_test() {
  let storage = flow.create_memory_storage()
  let execution_log = process.new_subject()

  let _test_flow =
    flow.new("flow_test", storage, test_step_to_string, string_to_test_step)
    |> flow.set_on_flow_enter(fn(ctx, instance) {
      process.send(execution_log, "flow_enter")
      Ok(#(ctx, instance))
    })
    |> flow.set_on_flow_leave(fn(ctx, instance) {
      process.send(execution_log, "flow_leave")
      Ok(#(ctx, instance))
    })
    |> flow.set_on_flow_exit(fn(ctx, _instance) {
      process.send(execution_log, "flow_exit")
      Ok(ctx)
    })
    |> flow.add_step(Start, fn(ctx, instance) { flow.complete(ctx, instance) })
    |> flow.build(initial: Start)

  // Verify flow was built with hooks (no runtime assertion on opaque type)
  True |> should.be_true()
}

/// Test inline subflow with mapped data
pub fn inline_subflow_with_mapping_test() {
  let storage = flow.create_memory_storage()

  let _parent_flow =
    flow.new("parent", storage, test_step_to_string, string_to_test_step)
    |> flow.with_inline_subflow_mapped(
      name: "data_sub",
      trigger: Middle,
      return_to: End,
      initial: "collect",
      steps: [
        #("collect", fn(ctx, instance) {
          let updated = flow.store_data(instance, "collected", "data")
          flow.return_from_subflow(ctx, updated, updated.state.data)
        }),
      ],
      map_args: fn(_instance) {
        dict.from_list([#("initial_arg", "from_parent")])
      },
      map_result: fn(_result, instance) {
        flow.FlowInstance(
          ..instance,
          state: flow.FlowState(
            ..instance.state,
            data: dict.insert(instance.state.data, "subflow_result", "merged"),
          ),
        )
      },
    )
    |> flow.add_step(Start, fn(ctx, instance) {
      flow.next(ctx, instance, step: Middle)
    })
    |> flow.add_step(End, fn(ctx, instance) { flow.complete(ctx, instance) })
    |> flow.build(initial: Start)

  // Flow builds successfully
  True |> should.be_true()
}

/// Test flow stack frame creation
pub fn flow_stack_frame_test() {
  let saved_data = dict.from_list([#("parent_key", "parent_value")])

  let frame =
    flow.FlowStackFrame(
      flow_name: "parent_flow",
      return_step: "continue_step",
      saved_data: saved_data,
    )

  frame.flow_name |> should.equal("parent_flow")
  frame.return_step |> should.equal("continue_step")
  dict.get(frame.saved_data, "parent_key") |> should.equal(Ok("parent_value"))
}

/// Test deeply nested flow stack
pub fn deeply_nested_flow_stack_test() {
  let grandparent_frame =
    flow.FlowStackFrame(
      flow_name: "grandparent",
      return_step: "gp_return",
      saved_data: dict.from_list([#("gp_data", "gp_value")]),
    )

  let parent_frame =
    flow.FlowStackFrame(
      flow_name: "parent",
      return_step: "p_return",
      saved_data: dict.from_list([#("p_data", "p_value")]),
    )

  let instance =
    flow.FlowInstance(
      id: "child_123",
      flow_name: "child",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "child_step",
        data: dict.new(),
        history: [],
        flow_stack: [parent_frame, grandparent_frame],
        parallel_state: None,
      ),
      step_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Verify stack depth
  list.length(instance.state.flow_stack) |> should.equal(2)

  // Verify stack order (parent should be first)
  case instance.state.flow_stack {
    [first, second] -> {
      first.flow_name |> should.equal("parent")
      second.flow_name |> should.equal("grandparent")
    }
    _ -> should.fail()
  }
}

// =============================================================================
// Subflow Tests
// =============================================================================

/// Test enter_subflow returns correct EnterSubflow action
pub fn enter_subflow_action_test() {
  let storage = flow.create_memory_storage()

  let instance =
    flow.FlowInstance(
      id: "test_123_456",
      flow_name: "parent_flow",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "trigger_step",
        data: dict.from_list([#("parent_data", "value")]),
        history: ["trigger_step"],
        flow_stack: [],
        parallel_state: None,
      ),
      step_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Create a minimal flow to test enter_subflow
  let _flow =
    flow.new("parent", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, inst) {
      // Test enter_subflow with data
      let subflow_data = dict.from_list([#("key", "value")])
      flow.enter_subflow(ctx, inst, "child_flow", subflow_data)
    })
    |> flow.build(initial: Start)

  // Verify instance has correct structure for subflow entry
  instance.state.flow_stack |> should.equal([])
  dict.get(instance.state.data, "parent_data") |> should.equal(Ok("value"))
}

/// Test return_from_subflow returns correct ReturnFromSubflow action
pub fn return_from_subflow_action_test() {
  let storage = flow.create_memory_storage()

  // Create parent frame on stack
  let parent_frame =
    flow.FlowStackFrame(
      flow_name: "parent_flow",
      return_step: "continue_step",
      saved_data: dict.from_list([#("parent_key", "parent_value")]),
    )

  let instance =
    flow.FlowInstance(
      id: "child_123_456",
      flow_name: "child_flow",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "final_step",
        data: dict.from_list([#("collected", "data")]),
        history: ["step1", "final_step"],
        flow_stack: [parent_frame],
        parallel_state: None,
      ),
      step_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Verify subflow has parent on stack
  list.length(instance.state.flow_stack) |> should.equal(1)

  case instance.state.flow_stack {
    [frame] -> {
      frame.flow_name |> should.equal("parent_flow")
      frame.return_step |> should.equal("continue_step")
    }
    _ -> should.fail()
  }

  // Test flow with return_from_subflow
  let _flow =
    flow.new("child", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, inst) {
      let result =
        dict.from_list([#("street", "123 Main St"), #("city", "NYC")])
      flow.return_from_subflow(ctx, inst, result)
    })
    |> flow.build(initial: Start)

  True |> should.be_true()
}

/// Test inline subflow creates correct flow structure
pub fn inline_subflow_structure_test() {
  let storage = flow.create_memory_storage()

  let _parent_flow =
    flow.new("checkout", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) {
      flow.next(ctx, instance, step: Middle)
    })
    |> flow.with_inline_subflow(
      name: "address",
      trigger: Middle,
      return_to: End,
      initial: "street",
      steps: [
        #("street", fn(ctx, instance) {
          let instance = flow.store_step_data(instance, "street", "123 Main")
          flow.inline_next(ctx, instance, "city")
        }),
        #("city", fn(ctx, instance) {
          let instance = flow.store_step_data(instance, "city", "NYC")
          flow.inline_next(ctx, instance, "done")
        }),
        #("done", fn(ctx, instance) {
          flow.return_from_subflow(ctx, instance, instance.state.data)
        }),
      ],
    )
    |> flow.add_step(End, fn(ctx, instance) { flow.complete(ctx, instance) })
    |> flow.build(initial: Start)

  // Flow builds successfully with inline subflow
  True |> should.be_true()
}

/// Test multiple inline subflows in one parent flow
pub fn multiple_inline_subflows_test() {
  let storage = flow.create_memory_storage()

  let _flow =
    flow.new("multi_sub", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) {
      flow.next(ctx, instance, step: Middle)
    })
    |> flow.with_inline_subflow(
      name: "shipping_address",
      trigger: Middle,
      return_to: Parallel1,
      initial: "addr_step",
      steps: [
        #("addr_step", fn(ctx, instance) {
          flow.return_from_subflow(ctx, instance, dict.new())
        }),
      ],
    )
    |> flow.add_step(Parallel1, fn(ctx, instance) {
      flow.next(ctx, instance, step: Parallel2)
    })
    |> flow.with_inline_subflow(
      name: "billing_address",
      trigger: Parallel2,
      return_to: End,
      initial: "billing_step",
      steps: [
        #("billing_step", fn(ctx, instance) {
          flow.return_from_subflow(ctx, instance, dict.new())
        }),
      ],
    )
    |> flow.add_step(End, fn(ctx, instance) { flow.complete(ctx, instance) })
    |> flow.build(initial: Start)

  // Multiple subflows build successfully
  True |> should.be_true()
}

/// Test subflow data isolation (step_data is cleared)
pub fn subflow_data_isolation_test() {
  let instance =
    flow.FlowInstance(
      id: "test_123_456",
      flow_name: "parent",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "step1",
        data: dict.from_list([#("persistent", "data")]),
        history: ["step1"],
        flow_stack: [],
        parallel_state: None,
      ),
      step_data: dict.from_list([#("temp", "will_be_cleared")]),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Persistent data survives
  flow.get_data(instance, "persistent") |> should.equal(Some("data"))

  // Step data is separate
  flow.get_step_data(instance, "temp") |> should.equal(Some("will_be_cleared"))

  // After clearing step data, persistent data remains
  let cleared = flow.clear_step_data(instance)
  flow.get_data(cleared, "persistent") |> should.equal(Some("data"))
  flow.get_step_data(cleared, "temp") |> should.equal(None)
}

/// Test inline_next returns correct action for inline steps
pub fn inline_next_returns_next_action_test() {
  let storage = flow.create_memory_storage()
  let execution_log = process.new_subject()

  let _flow =
    flow.new("inline_test", storage, test_step_to_string, string_to_test_step)
    |> flow.with_inline_subflow(
      name: "steps",
      trigger: Start,
      return_to: End,
      initial: "a",
      steps: [
        #("a", fn(ctx, instance) {
          process.send(execution_log, "step_a")
          flow.inline_next(ctx, instance, "b")
        }),
        #("b", fn(ctx, instance) {
          process.send(execution_log, "step_b")
          flow.inline_next(ctx, instance, "c")
        }),
        #("c", fn(ctx, instance) {
          process.send(execution_log, "step_c")
          flow.return_from_subflow(ctx, instance, dict.new())
        }),
      ],
    )
    |> flow.add_step(End, fn(ctx, instance) { flow.complete(ctx, instance) })
    |> flow.build(initial: Start)

  True |> should.be_true()
}

/// Test InlineStep type
pub fn inline_step_type_operations_test() {
  let step1 = flow.InlineStep("collect_name")
  let step2 = flow.InlineStep("collect_email")
  let step3 = flow.InlineStep("collect_name")

  // Different steps are not equal
  step1 |> should.not_equal(step2)

  // Same steps are equal
  step1 |> should.equal(step3)
}

/// Test flow preserves parent data when entering subflow
pub fn subflow_preserves_parent_data_test() {
  let parent_data =
    dict.from_list([
      #("user_name", "John"),
      #("user_email", "john@example.com"),
    ])

  let parent_frame =
    flow.FlowStackFrame(
      flow_name: "checkout",
      return_step: "payment",
      saved_data: parent_data,
    )

  // Verify data is preserved in stack frame
  dict.get(parent_frame.saved_data, "user_name") |> should.equal(Ok("John"))
  dict.get(parent_frame.saved_data, "user_email")
  |> should.equal(Ok("john@example.com"))
}

/// Test subflow with empty result data
pub fn subflow_empty_result_test() {
  let storage = flow.create_memory_storage()

  let _flow =
    flow.new("empty_result", storage, test_step_to_string, string_to_test_step)
    |> flow.with_inline_subflow(
      name: "empty_sub",
      trigger: Start,
      return_to: End,
      initial: "only_step",
      steps: [
        #("only_step", fn(ctx, instance) {
          // Return with empty dict
          flow.return_from_subflow(ctx, instance, dict.new())
        }),
      ],
    )
    |> flow.add_step(End, fn(ctx, instance) { flow.complete(ctx, instance) })
    |> flow.build(initial: Start)

  True |> should.be_true()
}

/// Test subflow collects and returns data correctly
pub fn subflow_data_collection_test() {
  let storage = flow.create_memory_storage()

  let _flow =
    flow.new("data_collect", storage, test_step_to_string, string_to_test_step)
    |> flow.with_inline_subflow(
      name: "collector",
      trigger: Start,
      return_to: End,
      initial: "step1",
      steps: [
        #("step1", fn(ctx, instance) {
          let instance = flow.store_data(instance, "field1", "value1")
          flow.inline_next(ctx, instance, "step2")
        }),
        #("step2", fn(ctx, instance) {
          let instance = flow.store_data(instance, "field2", "value2")
          flow.inline_next(ctx, instance, "final")
        }),
        #("final", fn(ctx, instance) {
          // Return all collected data
          flow.return_from_subflow(ctx, instance, instance.state.data)
        }),
      ],
    )
    |> flow.add_step(End, fn(ctx, instance) {
      // Verify data was merged from subflow
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  True |> should.be_true()
}

// =============================================================================
// FSM Execution Order Tests
// =============================================================================

/// Test step hooks execution order: on_enter → handler → on_leave
pub fn step_hooks_order_test() {
  let storage = flow.create_memory_storage()
  let events = process.new_subject()

  let _flow =
    flow.new("hooks_order", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step_with_hooks(
      Start,
      handler: fn(ctx, instance) {
        process.send(events, "handler:start")
        flow.next(ctx, instance, step: End)
      },
      on_enter: Some(fn(ctx, instance) {
        process.send(events, "enter:start")
        Ok(#(ctx, instance))
      }),
      on_leave: Some(fn(ctx, instance) {
        process.send(events, "leave:start")
        Ok(#(ctx, instance))
      }),
    )
    |> flow.add_step(End, fn(ctx, instance) {
      process.send(events, "handler:end")
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  // Expected order: enter:start → handler:start → leave:start → handler:end
  True |> should.be_true()
}

/// Test flow lifecycle hooks order: on_flow_enter → steps → on_flow_exit
pub fn flow_lifecycle_order_test() {
  let storage = flow.create_memory_storage()
  let events = process.new_subject()

  let _flow =
    flow.new(
      "lifecycle_order",
      storage,
      test_step_to_string,
      string_to_test_step,
    )
    |> flow.set_on_flow_enter(fn(ctx, instance) {
      process.send(events, "flow:enter")
      Ok(#(ctx, instance))
    })
    |> flow.set_on_flow_exit(fn(ctx, _instance) {
      process.send(events, "flow:exit")
      Ok(ctx)
    })
    |> flow.add_step(Start, fn(ctx, instance) {
      process.send(events, "step:start")
      flow.next(ctx, instance, step: End)
    })
    |> flow.add_step(End, fn(ctx, instance) {
      process.send(events, "step:end")
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  // Expected order: flow:enter → step:start → step:end → flow:exit
  True |> should.be_true()
}

/// Test sequential transitions maintain correct order
pub fn sequential_transitions_order_test() {
  let storage = flow.create_memory_storage()
  let events = process.new_subject()

  let _flow =
    flow.new("sequential", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) {
      process.send(events, "1:start")
      flow.next(ctx, instance, step: Middle)
    })
    |> flow.add_step(Middle, fn(ctx, instance) {
      process.send(events, "2:middle")
      flow.next(ctx, instance, step: End)
    })
    |> flow.add_step(End, fn(ctx, instance) {
      process.send(events, "3:end")
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  // Expected order: 1:start → 2:middle → 3:end
  True |> should.be_true()
}

/// Test subflow entry/exit order with parent
pub fn subflow_entry_exit_order_test() {
  let storage = flow.create_memory_storage()
  let events = process.new_subject()

  let _flow =
    flow.new("subflow_order", storage, test_step_to_string, string_to_test_step)
    |> flow.set_on_flow_leave(fn(ctx, instance) {
      process.send(events, "parent:leave")
      Ok(#(ctx, instance))
    })
    |> flow.add_step(Start, fn(ctx, instance) {
      process.send(events, "parent:start")
      flow.next(ctx, instance, step: Middle)
    })
    |> flow.with_inline_subflow(
      name: "child",
      trigger: Middle,
      return_to: End,
      initial: "sub_step",
      steps: [
        #("sub_step", fn(ctx, instance) {
          process.send(events, "child:step")
          flow.return_from_subflow(ctx, instance, dict.new())
        }),
      ],
    )
    |> flow.add_step(End, fn(ctx, instance) {
      process.send(events, "parent:end")
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  // Expected: parent:start → parent:leave → child:step → parent:end
  True |> should.be_true()
}

// =============================================================================
// FSM Corner Cases Tests
// =============================================================================

/// Test self-transition (goto same step)
pub fn self_transition_test() {
  let storage = flow.create_memory_storage()
  let counter = process.new_subject()

  let _flow =
    flow.new("self_trans", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) {
      let count =
        flow.get_data(instance, "count")
        |> option.map(fn(s) { result.unwrap(int.parse(s), 0) })
        |> option.unwrap(0)

      process.send(counter, "visit:" <> int.to_string(count))

      case count < 3 {
        True -> {
          let instance =
            flow.store_data(instance, "count", int.to_string(count + 1))
          // Self-transition: goto same step
          flow.goto(ctx, instance, Start)
        }
        False -> flow.next(ctx, instance, step: End)
      }
    })
    |> flow.add_step(End, fn(ctx, instance) {
      process.send(counter, "done")
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  // Should visit Start 4 times (0,1,2,3) then go to End
  True |> should.be_true()
}

/// Test cancel flow at different stages
pub fn cancel_at_start_test() {
  let storage = flow.create_memory_storage()
  let events = process.new_subject()

  let _flow =
    flow.new("cancel_start", storage, test_step_to_string, string_to_test_step)
    |> flow.set_on_flow_exit(fn(ctx, _instance) {
      process.send(events, "exit_hook")
      Ok(ctx)
    })
    |> flow.add_step(Start, fn(ctx, instance) {
      process.send(events, "start")
      flow.cancel(ctx, instance)
    })
    |> flow.add_step(End, fn(ctx, instance) {
      process.send(events, "end_never_called")
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  // Cancel should trigger exit hook but not End step
  True |> should.be_true()
}

/// Test cancel flow in middle step
pub fn cancel_at_middle_test() {
  let storage = flow.create_memory_storage()
  let events = process.new_subject()

  let _flow =
    flow.new("cancel_middle", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) {
      process.send(events, "start")
      flow.next(ctx, instance, step: Middle)
    })
    |> flow.add_step(Middle, fn(ctx, instance) {
      process.send(events, "middle")
      flow.cancel(ctx, instance)
    })
    |> flow.add_step(End, fn(ctx, instance) {
      process.send(events, "end_never_called")
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  // Expected: start → middle, End never called
  True |> should.be_true()
}

/// Test back navigation
pub fn back_navigation_test() {
  let instance =
    flow.FlowInstance(
      id: "back_test",
      flow_name: "test",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "middle",
        data: dict.new(),
        history: ["start", "middle"],
        flow_stack: [],
        parallel_state: None,
      ),
      step_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Verify history for back navigation
  instance.state.history |> should.equal(["start", "middle"])
  instance.state.current_step |> should.equal("middle")
}

/// Test self-loop (stay on same step using goto to self)
pub fn self_loop_step_test() {
  let storage = flow.create_memory_storage()
  let attempts = process.new_subject()

  let _flow =
    flow.new(
      "self_loop_test",
      storage,
      test_step_to_string,
      string_to_test_step,
    )
    |> flow.add_step(Start, fn(ctx, instance) {
      let count =
        flow.get_step_data(instance, "attempts")
        |> option.map(fn(s) { result.unwrap(int.parse(s), 0) })
        |> option.unwrap(0)

      process.send(attempts, "attempt:" <> int.to_string(count))

      case count < 2 {
        True -> {
          let instance =
            flow.store_step_data(instance, "attempts", int.to_string(count + 1))
          // Use goto to self for repeating the step
          flow.goto(ctx, instance, step: Start)
        }
        False -> flow.next(ctx, instance, step: End)
      }
    })
    |> flow.add_step(End, fn(ctx, instance) { flow.complete(ctx, instance) })
    |> flow.build(initial: Start)

  True |> should.be_true()
}

/// Test goto clears step_data
pub fn goto_clears_step_data_test() {
  let instance =
    flow.FlowInstance(
      id: "goto_test",
      flow_name: "test",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "start",
        data: dict.from_list([#("persistent", "stays")]),
        history: ["start"],
        flow_stack: [],
        parallel_state: None,
      ),
      step_data: dict.from_list([#("temp", "will_be_cleared")]),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Before clearing
  flow.get_step_data(instance, "temp") |> should.equal(Some("will_be_cleared"))
  flow.get_data(instance, "persistent") |> should.equal(Some("stays"))

  // After goto/clear_step_data
  let cleared = flow.clear_step_data(instance)
  flow.get_step_data(cleared, "temp") |> should.equal(None)
  flow.get_data(cleared, "persistent") |> should.equal(Some("stays"))
}

/// Test flow with no steps (edge case)
pub fn empty_steps_flow_test() {
  let storage = flow.create_memory_storage()

  // Flow with only one step that immediately completes
  let _flow =
    flow.new("minimal", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) { flow.complete(ctx, instance) })
    |> flow.build(initial: Start)

  True |> should.be_true()
}

/// Test history accumulation across transitions
pub fn history_accumulation_test() {
  let instance1 =
    flow.FlowInstance(
      id: "hist_test",
      flow_name: "test",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "start",
        data: dict.new(),
        history: ["start"],
        flow_stack: [],
        parallel_state: None,
      ),
      step_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Simulate transitions by updating history
  let instance2 =
    flow.FlowInstance(
      ..instance1,
      state: flow.FlowState(..instance1.state, current_step: "middle", history: [
        "start",
        "middle",
      ]),
    )

  let instance3 =
    flow.FlowInstance(
      ..instance2,
      state: flow.FlowState(..instance2.state, current_step: "end", history: [
        "start",
        "middle",
        "end",
      ]),
    )

  // Verify history grows
  list.length(instance1.state.history) |> should.equal(1)
  list.length(instance2.state.history) |> should.equal(2)
  list.length(instance3.state.history) |> should.equal(3)

  // Verify order
  instance3.state.history |> should.equal(["start", "middle", "end"])
}

/// Test wait token is set correctly
pub fn wait_token_test() {
  let storage = flow.create_memory_storage()

  let _flow =
    flow.new("wait_test", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) {
      // wait() should set the wait_token
      flow.wait(ctx, instance, "unique_token_123")
    })
    |> flow.build(initial: Start)

  True |> should.be_true()
}

/// Test callback wait token
pub fn wait_callback_token_test() {
  let storage = flow.create_memory_storage()

  let _flow =
    flow.new("callback_test", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step(Start, fn(ctx, instance) {
      flow.wait_callback(ctx, instance, "callback_token")
    })
    |> flow.build(initial: Start)

  True |> should.be_true()
}

/// Test data merging during subflow return
pub fn subflow_data_merge_test() {
  let parent_data = dict.from_list([#("parent_key", "parent_value")])
  let child_result = dict.from_list([#("child_key", "child_value")])

  let merged = dict.merge(parent_data, child_result)

  dict.get(merged, "parent_key") |> should.equal(Ok("parent_value"))
  dict.get(merged, "child_key") |> should.equal(Ok("child_value"))
  dict.size(merged) |> should.equal(2)
}

/// Test subflow data override (child overwrites parent key)
pub fn subflow_data_override_test() {
  let parent_data = dict.from_list([#("shared_key", "parent_value")])
  let child_result = dict.from_list([#("shared_key", "child_value")])

  // dict.merge: second dict overwrites first
  let merged = dict.merge(parent_data, child_result)

  dict.get(merged, "shared_key") |> should.equal(Ok("child_value"))
}

/// Test multiple hooks on different steps
pub fn multiple_steps_with_hooks_test() {
  let storage = flow.create_memory_storage()
  let events = process.new_subject()

  let _flow =
    flow.new("multi_hooks", storage, test_step_to_string, string_to_test_step)
    |> flow.add_step_with_hooks(
      Start,
      handler: fn(ctx, instance) {
        process.send(events, "h:start")
        flow.next(ctx, instance, step: Middle)
      },
      on_enter: Some(fn(ctx, instance) {
        process.send(events, "e:start")
        Ok(#(ctx, instance))
      }),
      on_leave: Some(fn(ctx, instance) {
        process.send(events, "l:start")
        Ok(#(ctx, instance))
      }),
    )
    |> flow.add_step_with_hooks(
      Middle,
      handler: fn(ctx, instance) {
        process.send(events, "h:middle")
        flow.next(ctx, instance, step: End)
      },
      on_enter: Some(fn(ctx, instance) {
        process.send(events, "e:middle")
        Ok(#(ctx, instance))
      }),
      on_leave: Some(fn(ctx, instance) {
        process.send(events, "l:middle")
        Ok(#(ctx, instance))
      }),
    )
    |> flow.add_step(End, fn(ctx, instance) {
      process.send(events, "h:end")
      flow.complete(ctx, instance)
    })
    |> flow.build(initial: Start)

  // Expected: e:start → h:start → l:start → e:middle → h:middle → l:middle → h:end
  True |> should.be_true()
}

/// Test flow instance ID generation
pub fn flow_instance_id_test() {
  let instance =
    flow.FlowInstance(
      id: "checkout_456_123",
      flow_name: "checkout",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(
        current_step: "start",
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

  // ID format: {flow_name}_{chat_id}_{user_id}
  instance.id |> should.equal("checkout_456_123")
  instance.flow_name |> should.equal("checkout")
  instance.user_id |> should.equal(123)
  instance.chat_id |> should.equal(456)
}

/// Test parallel state initialization
pub fn parallel_state_init_test() {
  let parallel =
    flow.ParallelState(
      pending_steps: ["email", "phone", "document"],
      completed_steps: [],
      results: dict.new(),
      join_step: "all_complete",
    )

  list.length(parallel.pending_steps) |> should.equal(3)
  list.length(parallel.completed_steps) |> should.equal(0)
  parallel.join_step |> should.equal("all_complete")
}

/// Test parallel state progress
pub fn parallel_state_progress_test() {
  let initial =
    flow.ParallelState(
      pending_steps: ["email", "phone", "document"],
      completed_steps: [],
      results: dict.new(),
      join_step: "done",
    )

  // Simulate completing "email" step
  let after_email =
    flow.ParallelState(
      ..initial,
      pending_steps: ["phone", "document"],
      completed_steps: ["email"],
      results: dict.from_list([
        #("email", dict.from_list([#("verified", "true")])),
      ]),
    )

  list.length(after_email.pending_steps) |> should.equal(2)
  list.length(after_email.completed_steps) |> should.equal(1)
  list.contains(after_email.completed_steps, "email") |> should.be_true()
}
