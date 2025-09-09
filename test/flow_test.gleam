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

pub fn scene_data_operations_test() {
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
      scene_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  let instance1 = flow.store_scene_data(instance, "key1", "value1")
  flow.get_scene_data(instance1, "key1") |> should.equal(Some("value1"))

  let instance2 = flow.store_scene_data(instance1, "key2", "value2")
  flow.get_scene_data(instance2, "key1") |> should.equal(Some("value1"))
  flow.get_scene_data(instance2, "key2") |> should.equal(Some("value2"))

  let instance3 = flow.clear_scene_data_key(instance2, "key1")
  flow.get_scene_data(instance3, "key1") |> should.equal(None)
  flow.get_scene_data(instance3, "key2") |> should.equal(Some("value2"))

  let instance4 = flow.clear_scene_data(instance3)
  flow.get_scene_data(instance4, "key2") |> should.equal(None)
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
      scene_data: dict.new(),
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
      scene_data: dict.new(),
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
      scene_data: dict.new(),
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
      scene_data: dict.new(),
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
      scene_data: dict.new(),
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
      scene_data: dict.new(),
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
