import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleeunit
import gleeunit/should
import telega/bot
import telega/flow/action
import telega/flow/builder
import telega/flow/engine
import telega/flow/instance
import telega/flow/registry
import telega/flow/storage
import telega/flow/types
import telega/testing/context
import telega/testing/factory
import telega/testing/mock

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

// ============================================================================
// Instance CRUD & Data Operations
// ============================================================================

pub fn step_data_operations_test() {
  let instance =
    instance.new_instance(
      id: "test_123_456",
      flow_name: "test_flow",
      user_id: 123,
      chat_id: 456,
      current_step: "step1",
    )

  let instance1 = instance.store_step_data(instance, "key1", "value1")
  instance.get_step_data(instance1, "key1") |> should.equal(Some("value1"))

  let instance2 = instance.store_step_data(instance1, "key2", "value2")
  instance.get_step_data(instance2, "key1") |> should.equal(Some("value1"))
  instance.get_step_data(instance2, "key2") |> should.equal(Some("value2"))

  let instance3 = instance.clear_step_data_key(instance2, "key1")
  instance.get_step_data(instance3, "key1") |> should.equal(None)
  instance.get_step_data(instance3, "key2") |> should.equal(Some("value2"))

  let instance4 = instance.clear_step_data(instance3)
  instance.get_step_data(instance4, "key2") |> should.equal(None)
}

pub fn flow_data_persistence_test() {
  let instance =
    instance.new_instance(
      id: "test_123_456",
      flow_name: "test_flow",
      user_id: 123,
      chat_id: 456,
      current_step: "step1",
    )

  let instance1 = instance.store_data(instance, "name", "Alice")
  let instance2 = instance.store_data(instance1, "age", "25")
  let instance3 = instance.store_data(instance2, "email", "alice@example.com")

  instance.get_data(instance3, "name") |> should.equal(Some("Alice"))
  instance.get_data(instance3, "age") |> should.equal(Some("25"))
  instance.get_data(instance3, "email")
  |> should.equal(Some("alice@example.com"))
  instance.get_data(instance3, "nonexistent") |> should.equal(None)
}

pub fn flow_instance_id_test() {
  let instance =
    instance.new_instance(
      id: "checkout_456_123",
      flow_name: "checkout",
      user_id: 123,
      chat_id: 456,
      current_step: "start",
    )

  instance.instance_id(instance) |> should.equal("checkout_456_123")
  instance.instance_flow_name(instance) |> should.equal("checkout")
  instance.instance_user_id(instance) |> should.equal(123)
  instance.instance_chat_id(instance) |> should.equal(456)
}

pub fn instance_to_row_round_trip_test() {
  let instance =
    instance.new_instance_with_data(
      id: "roundtrip_test",
      flow_name: "my_flow",
      user_id: 42,
      chat_id: 99,
      current_step: "middle",
      data: dict.from_list([#("key1", "val1"), #("key2", "val2")]),
    )

  let row = instance.instance_to_row(instance)
  let restored = instance.instance_from_row(row)

  instance.instance_id(restored) |> should.equal("roundtrip_test")
  instance.instance_flow_name(restored) |> should.equal("my_flow")
  instance.instance_user_id(restored) |> should.equal(42)
  instance.instance_chat_id(restored) |> should.equal(99)
  instance.instance_current_step(restored) |> should.equal("middle")
  instance.get_data(restored, "key1") |> should.equal(Some("val1"))
  instance.get_data(restored, "key2") |> should.equal(Some("val2"))
}

pub fn generate_id_test() {
  storage.generate_id(123, 456, "test") |> should.equal("test_456_123")
}

pub fn subflow_data_isolation_test() {
  let instance =
    instance.new_instance_with_data(
      id: "test_123_456",
      flow_name: "parent",
      user_id: 123,
      chat_id: 456,
      current_step: "step1",
      data: dict.from_list([#("persistent", "data")]),
    )

  let instance = instance.store_step_data(instance, "temp", "will_be_cleared")

  instance.get_data(instance, "persistent") |> should.equal(Some("data"))
  instance.get_step_data(instance, "temp")
  |> should.equal(Some("will_be_cleared"))

  let cleared = instance.clear_step_data(instance)
  instance.get_data(cleared, "persistent") |> should.equal(Some("data"))
  instance.get_step_data(cleared, "temp") |> should.equal(None)
}

// ============================================================================
// WaitResult parsing
// ============================================================================

pub fn get_wait_result_pending_test() {
  let instance =
    instance.new_instance(
      id: "wait_pending",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  instance.get_wait_result(instance) |> should.equal(types.Pending)
}

pub fn get_wait_result_text_test() {
  let instance =
    instance.new_instance(
      id: "wait_text",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "text:hello")

  instance.get_wait_result(instance)
  |> should.equal(types.TextInput(value: "hello"))
}

pub fn get_wait_result_bool_test() {
  let instance =
    instance.new_instance(
      id: "wait_bool",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "bool:true")

  instance.get_wait_result(instance)
  |> should.equal(types.BoolCallback(value: True))
}

pub fn get_wait_result_bool_false_test() {
  let instance =
    instance.new_instance(
      id: "wait_bool_f",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "bool:false")

  instance.get_wait_result(instance)
  |> should.equal(types.BoolCallback(value: False))
}

pub fn get_wait_result_data_test() {
  let instance =
    instance.new_instance(
      id: "wait_data",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "data:some_value")

  instance.get_wait_result(instance)
  |> should.equal(types.DataCallback(value: "some_value"))
}

pub fn get_wait_result_photo_test() {
  let instance =
    instance.new_instance(
      id: "photo_test",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(
      instance,
      "__wait_result",
      "photo:file1,file2,file3",
    )

  instance.get_wait_result(instance)
  |> should.equal(types.PhotoInput(file_ids: ["file1", "file2", "file3"]))
}

pub fn get_wait_result_video_test() {
  let instance =
    instance.new_instance(
      id: "video_test",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "video:abc123")

  instance.get_wait_result(instance)
  |> should.equal(types.VideoInput(file_id: "abc123"))
}

pub fn get_wait_result_voice_test() {
  let instance =
    instance.new_instance(
      id: "voice_test",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "voice:voice_file_1")

  instance.get_wait_result(instance)
  |> should.equal(types.VoiceInput(file_id: "voice_file_1"))
}

pub fn get_wait_result_audio_test() {
  let instance =
    instance.new_instance(
      id: "audio_test",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "audio:audio_file_1")

  instance.get_wait_result(instance)
  |> should.equal(types.AudioInput(file_id: "audio_file_1"))
}

pub fn get_wait_result_location_test() {
  let instance =
    instance.new_instance(
      id: "loc_test",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "location:55.75,37.62")

  instance.get_wait_result(instance)
  |> should.equal(types.LocationInput(latitude: 55.75, longitude: 37.62))
}

pub fn get_wait_result_location_invalid_test() {
  let instance =
    instance.new_instance(
      id: "loc_bad",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "location:not_a_number")

  instance.get_wait_result(instance)
  |> should.equal(types.DataCallback(value: "location:not_a_number"))
}

pub fn get_wait_result_command_test() {
  let instance =
    instance.new_instance(
      id: "cmd_test",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(
      instance,
      "__wait_result",
      "command:start:some arg",
    )

  instance.get_wait_result(instance)
  |> should.equal(types.CommandInput(command: "start", payload: "some arg"))
}

pub fn get_wait_result_command_no_payload_test() {
  let instance =
    instance.new_instance(
      id: "cmd_test2",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "command:help")

  instance.get_wait_result(instance)
  |> should.equal(types.CommandInput(command: "help", payload: ""))
}

pub fn get_wait_result_unknown_format_test() {
  let instance =
    instance.new_instance(
      id: "unknown_test",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )
  let instance =
    instance.store_step_data(instance, "__wait_result", "random_stuff")

  instance.get_wait_result(instance)
  |> should.equal(types.DataCallback(value: "random_stuff"))
}

// ============================================================================
// Middleware execution
// ============================================================================

pub fn middleware_execution_order_test() {
  let execution_order = process.new_subject()

  let middleware1 = fn(_ctx, _instance: types.FlowInstance, next) {
    process.send(execution_order, "middleware1_before")
    let result = next()
    process.send(execution_order, "middleware1_after")
    result
  }

  let middleware2 = fn(_ctx, _instance: types.FlowInstance, next) {
    process.send(execution_order, "middleware2_before")
    let result = next()
    process.send(execution_order, "middleware2_after")
    result
  }

  let handler = fn(_ctx, inst: types.FlowInstance) {
    process.send(execution_order, "handler")
    Ok(#(Nil, types.Next(End), inst))
  }

  let test_instance =
    instance.new_instance(
      id: "test_middleware",
      flow_name: "test",
      user_id: 123,
      chat_id: 456,
      current_step: "start",
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
        types.Next(End) -> Nil
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

// ============================================================================
// Engine: sequential flow execution with ETS storage
// ============================================================================

pub fn engine_sequential_flow_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("seq_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      process.send(events, "start")
      let inst = instance.store_data(inst, "step", "visited_start")
      action.next(ctx, inst, step: Middle)
    })
    |> builder.add_step(Middle, fn(ctx, inst) {
      process.send(events, "middle")
      instance.get_data(inst, "step") |> should.equal(Some("visited_start"))
      let inst = instance.store_data(inst, "step", "visited_middle")
      action.next(ctx, inst, step: End)
    })
    |> builder.add_step(End, fn(ctx, inst) {
      process.send(events, "end")
      instance.get_data(inst, "step") |> should.equal(Some("visited_middle"))
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _calls) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "hi", from_id: 10, chat_id: 20),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 10,
      chat_id: 20,
      initial_data: dict.new(),
    )

  // Verify execution order
  let assert Ok("start") = process.receive(events, 100)
  let assert Ok("middle") = process.receive(events, 100)
  let assert Ok("end") = process.receive(events, 100)

  // Instance should be deleted after Complete
  let flow_id = storage.generate_id(10, 20, "seq_test")
  let assert Ok(None) = ets.load(flow_id)
}

pub fn engine_data_flows_through_steps_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let collected = process.new_subject()

  let flow =
    builder.new("data_flow", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      let inst = instance.store_data(inst, "name", "Alice")
      action.next(ctx, inst, step: Middle)
    })
    |> builder.add_step(Middle, fn(ctx, inst) {
      let inst = instance.store_data(inst, "age", "30")
      action.next(ctx, inst, step: End)
    })
    |> builder.add_step(End, fn(ctx, inst) {
      let name = instance.get_data(inst, "name")
      let age = instance.get_data(inst, "age")
      process.send(collected, #(name, age))
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok(#(Some("Alice"), Some("30"))) = process.receive(collected, 100)
}

// ============================================================================
// Engine: Wait & Resume
// ============================================================================

pub fn engine_wait_and_resume_with_text_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("wait_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      case instance.get_wait_result(inst) {
        types.Pending -> {
          process.send(events, "waiting")
          action.wait(ctx, inst)
        }
        types.TextInput(value:) -> {
          process.send(events, "got:" <> value)
          let inst = instance.store_data(inst, "answer", value)
          action.next(ctx, inst, step: End)
        }
        _ -> action.cancel(ctx, inst)
      }
    })
    |> builder.add_step(End, fn(ctx, inst) {
      let answer = instance.get_data(inst, "answer")
      process.send(events, "end:" <> option.unwrap(answer, "none"))
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 50, chat_id: 60),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  // First call: should wait
  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 50,
      chat_id: 60,
      initial_data: dict.new(),
    )

  let assert Ok("waiting") = process.receive(events, 100)

  // Verify instance is saved with wait_token
  let flow_id = storage.generate_id(50, 60, "wait_test")
  let assert Ok(Some(saved_instance)) = ets.load(flow_id)
  saved_instance.wait_token |> option.is_some() |> should.be_true()

  // Resume with text input
  let resume_data =
    dict.from_list([
      #("user_input", "hello world"),
      #("__wait_result", "text:hello world"),
    ])
  let assert Ok(_) =
    engine.resume_with_instance(flow, ctx, saved_instance, Some(resume_data))

  let assert Ok("got:hello world") = process.receive(events, 100)
  let assert Ok("end:hello world") = process.receive(events, 100)

  // Instance should be cleaned up
  let assert Ok(None) = ets.load(flow_id)
}

pub fn engine_wait_callback_and_resume_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("cb_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      case instance.get_wait_result(inst) {
        types.Pending -> {
          process.send(events, "waiting_callback")
          action.wait_callback(ctx, inst)
        }
        types.BoolCallback(value: True) -> {
          process.send(events, "confirmed")
          action.next(ctx, inst, step: End)
        }
        types.BoolCallback(value: False) -> {
          process.send(events, "declined")
          action.cancel(ctx, inst)
        }
        _ -> action.cancel(ctx, inst)
      }
    })
    |> builder.add_step(End, fn(ctx, inst) {
      process.send(events, "completed")
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 70, chat_id: 80),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 70,
      chat_id: 80,
      initial_data: dict.new(),
    )
  let assert Ok("waiting_callback") = process.receive(events, 100)

  let flow_id = storage.generate_id(70, 80, "cb_test")
  let assert Ok(Some(inst)) = ets.load(flow_id)

  // Resume with bool:true callback
  let data = dict.from_list([#("__wait_result", "bool:true")])
  let assert Ok(_) = engine.resume_with_instance(flow, ctx, inst, Some(data))

  let assert Ok("confirmed") = process.receive(events, 100)
  let assert Ok("completed") = process.receive(events, 100)
}

// ============================================================================
// Engine: Wait with timeout
// ============================================================================

pub fn engine_wait_with_timeout_sets_deadline_test() {
  let assert Ok(ets) = storage.create_ets_storage()

  let flow =
    builder.new("timeout_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      action.wait_with_timeout(ctx, inst, timeout_ms: 5000)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let flow_id = storage.generate_id(1, 2, "timeout_test")
  let assert Ok(Some(inst)) = ets.load(flow_id)

  inst.wait_token |> option.is_some() |> should.be_true()
  inst.wait_timeout_at |> option.is_some() |> should.be_true()
}

pub fn engine_wait_callback_with_timeout_test() {
  let assert Ok(ets) = storage.create_ets_storage()

  let flow =
    builder.new("cb_timeout", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      action.wait_callback_with_timeout(ctx, inst, timeout_ms: 10_000)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 3, chat_id: 4),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 3,
      chat_id: 4,
      initial_data: dict.new(),
    )

  let flow_id = storage.generate_id(3, 4, "cb_timeout")
  let assert Ok(Some(inst)) = ets.load(flow_id)

  inst.wait_token |> option.is_some() |> should.be_true()
  inst.wait_timeout_at |> option.is_some() |> should.be_true()
}

// ============================================================================
// Engine: Cancel flow
// ============================================================================

pub fn engine_cancel_deletes_instance_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("cancel_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      process.send(events, "start")
      action.cancel(ctx, inst)
    })
    |> builder.add_step(End, fn(ctx, inst) {
      process.send(events, "end_never")
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("start") = process.receive(events, 100)
  // End handler should NOT be called
  process.receive(events, 50) |> should.be_error()

  // Instance should be cleaned up
  let flow_id = storage.generate_id(1, 2, "cancel_test")
  let assert Ok(None) = ets.load(flow_id)
}

pub fn engine_cancel_triggers_exit_hook_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("cancel_hook", ets, test_step_to_string, string_to_test_step)
    |> builder.set_on_flow_exit(fn(ctx, _inst) {
      process.send(events, "exit_hook")
      Ok(ctx)
    })
    |> builder.add_step(Start, fn(ctx, inst) {
      process.send(events, "start")
      action.cancel(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("start") = process.receive(events, 100)
  let assert Ok("exit_hook") = process.receive(events, 100)
}

// ============================================================================
// Engine: GoTo (clears step data, resets flow_stack)
// ============================================================================

pub fn engine_goto_clears_step_data_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("goto_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      // Store step data, then goto Middle
      let inst = instance.store_step_data(inst, "temp", "should_clear")
      action.goto(ctx, inst, step: Middle)
    })
    |> builder.add_step(Middle, fn(ctx, inst) {
      // step_data should be cleared by GoTo
      let temp = instance.get_step_data(inst, "temp")
      process.send(events, "temp:" <> option.unwrap(temp, "cleared"))
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("temp:cleared") = process.receive(events, 100)
}

// ============================================================================
// Engine: Back navigation
// ============================================================================

pub fn engine_back_returns_to_previous_step_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let visit_count = process.new_subject()

  let flow =
    builder.new("back_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      let visits =
        instance.get_data(inst, "start_visits")
        |> option.map(fn(s) { result.unwrap(int.parse(s), 0) })
        |> option.unwrap(0)
      let inst =
        instance.store_data(inst, "start_visits", int.to_string(visits + 1))
      process.send(visit_count, "start:" <> int.to_string(visits + 1))
      action.next(ctx, inst, step: Middle)
    })
    |> builder.add_step(Middle, fn(ctx, inst) {
      let visits =
        instance.get_data(inst, "start_visits")
        |> option.unwrap("0")
      case visits {
        "1" -> {
          process.send(visit_count, "back_from_middle")
          action.back(ctx, inst)
        }
        _ -> {
          process.send(visit_count, "complete")
          action.complete(ctx, inst)
        }
      }
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  // start(1) -> middle -> back -> start(2) -> middle -> complete
  let assert Ok("start:1") = process.receive(visit_count, 100)
  let assert Ok("back_from_middle") = process.receive(visit_count, 100)
  let assert Ok("start:2") = process.receive(visit_count, 100)
  let assert Ok("complete") = process.receive(visit_count, 100)
}

// ============================================================================
// Engine: Conditional routing via engine
// ============================================================================

pub fn engine_conditional_routing_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("cond_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      // This step is never actually executed due to conditional redirect
      process.send(events, "start_handler")
      action.complete(ctx, inst)
    })
    |> builder.add_conditional(
      Start,
      fn(inst) {
        case instance.get_data(inst, "score") {
          Some("high") -> True
          _ -> False
        }
      },
      true: ConditionalA,
      false: ConditionalB,
    )
    |> builder.add_step(ConditionalA, fn(ctx, inst) {
      process.send(events, "conditional_a")
      action.complete(ctx, inst)
    })
    |> builder.add_step(ConditionalB, fn(ctx, inst) {
      process.send(events, "conditional_b")
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  // With "high" score -> ConditionalA
  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.from_list([#("score", "high")]),
    )

  let assert Ok("conditional_a") = process.receive(events, 100)
}

pub fn engine_conditional_default_branch_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("cond_def", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      process.send(events, "start")
      action.complete(ctx, inst)
    })
    |> builder.add_conditional(
      Start,
      fn(inst) {
        case instance.get_data(inst, "score") {
          Some("high") -> True
          _ -> False
        }
      },
      true: ConditionalA,
      false: ConditionalB,
    )
    |> builder.add_step(ConditionalA, fn(ctx, inst) {
      process.send(events, "a")
      action.complete(ctx, inst)
    })
    |> builder.add_step(ConditionalB, fn(ctx, inst) {
      process.send(events, "b")
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 5, chat_id: 6),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  // With "low" score -> default branch (ConditionalB)
  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 5,
      chat_id: 6,
      initial_data: dict.from_list([#("score", "low")]),
    )

  let assert Ok("b") = process.receive(events, 100)
}

pub fn engine_multi_conditional_routing_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("multi_cond", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      process.send(events, "start")
      action.complete(ctx, inst)
    })
    |> builder.add_multi_conditional(
      Start,
      [
        #(
          fn(i) {
            case instance.get_data(i, "score") {
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
            case instance.get_data(i, "score") {
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
    |> builder.add_step(ConditionalA, fn(ctx, inst) {
      process.send(events, "grade_a")
      action.complete(ctx, inst)
    })
    |> builder.add_step(ConditionalB, fn(ctx, inst) {
      process.send(events, "grade_b")
      action.complete(ctx, inst)
    })
    |> builder.add_step(End, fn(ctx, inst) {
      process.send(events, "grade_f")
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()

  // Score 95 -> A
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 10, chat_id: 20),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))
  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 10,
      chat_id: 20,
      initial_data: dict.from_list([#("score", "95")]),
    )
  let assert Ok("grade_a") = process.receive(events, 100)

  // Score 80 -> B
  let ctx2 =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 11, chat_id: 21),
    )
  let ctx2 = bot.Context(..ctx2, config: context.config_with_client(client))
  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx2,
      user_id: 11,
      chat_id: 21,
      initial_data: dict.from_list([#("score", "80")]),
    )
  let assert Ok("grade_b") = process.receive(events, 100)

  // Score 50 -> default (End/F)
  let ctx3 =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 12, chat_id: 22),
    )
  let ctx3 = bot.Context(..ctx3, config: context.config_with_client(client))
  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx3,
      user_id: 12,
      chat_id: 22,
      initial_data: dict.from_list([#("score", "50")]),
    )
  let assert Ok("grade_f") = process.receive(events, 100)
}

// ============================================================================
// Engine: Parallel steps
// ============================================================================

pub fn engine_parallel_steps_execute_and_join_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("par_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      process.send(events, "trigger")
      action.next(ctx, inst, step: Middle)
    })
    |> builder.parallel(from: Middle, steps: [Parallel1, Parallel2], join: Join)
    |> builder.add_step(Parallel1, fn(ctx, inst) {
      process.send(events, "parallel1")
      let result = dict.from_list([#("task1", "done")])
      Ok(#(ctx, types.CompleteParallelStep(Parallel1, result), inst))
    })
    |> builder.add_step(Parallel2, fn(ctx, inst) {
      process.send(events, "parallel2")
      let result = dict.from_list([#("task2", "done")])
      Ok(#(ctx, types.CompleteParallelStep(Parallel2, result), inst))
    })
    |> builder.add_step(Join, fn(ctx, inst) {
      // Parallel results are merged with prefix: "step_name.key"
      let task1 = instance.get_data(inst, "parallel1.task1")
      let task2 = instance.get_data(inst, "parallel2.task2")
      process.send(
        events,
        "join:" <> option.unwrap(task1, "?") <> "," <> option.unwrap(task2, "?"),
      )
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("trigger") = process.receive(events, 100)
  let assert Ok("parallel1") = process.receive(events, 100)
  let assert Ok("parallel2") = process.receive(events, 100)
  let assert Ok("join:done,done") = process.receive(events, 100)
}

// ============================================================================
// Engine: Step hooks (on_enter, on_leave)
// ============================================================================

pub fn engine_step_hooks_execution_order_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("hooks_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step_with_hooks(
      Start,
      handler: fn(ctx, inst) {
        process.send(events, "handler:start")
        action.next(ctx, inst, step: End)
      },
      on_enter: Some(fn(ctx, inst) {
        process.send(events, "enter:start")
        Ok(#(ctx, inst))
      }),
      on_leave: Some(fn(ctx, inst) {
        process.send(events, "leave:start")
        Ok(#(ctx, inst))
      }),
    )
    |> builder.add_step(End, fn(ctx, inst) {
      process.send(events, "handler:end")
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  // Expected: enter -> handler -> leave -> next step handler
  let assert Ok("enter:start") = process.receive(events, 100)
  let assert Ok("handler:start") = process.receive(events, 100)
  let assert Ok("leave:start") = process.receive(events, 100)
  let assert Ok("handler:end") = process.receive(events, 100)
}

pub fn engine_step_hooks_skip_leave_on_wait_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("wait_hook", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step_with_hooks(
      Start,
      handler: fn(ctx, inst) {
        process.send(events, "handler")
        action.wait(ctx, inst)
      },
      on_enter: Some(fn(ctx, inst) {
        process.send(events, "enter")
        Ok(#(ctx, inst))
      }),
      on_leave: Some(fn(ctx, inst) {
        process.send(events, "leave_should_not_run")
        Ok(#(ctx, inst))
      }),
    )
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("enter") = process.receive(events, 100)
  let assert Ok("handler") = process.receive(events, 100)
  // Leave hook should NOT fire when waiting
  process.receive(events, 50) |> should.be_error()
}

// ============================================================================
// Engine: Flow lifecycle hooks (on_flow_enter, on_flow_leave, on_flow_exit)
// ============================================================================

pub fn engine_flow_lifecycle_hooks_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("lifecycle", ets, test_step_to_string, string_to_test_step)
    |> builder.set_on_flow_enter(fn(ctx, inst) {
      process.send(events, "flow_enter")
      Ok(#(ctx, inst))
    })
    |> builder.set_on_flow_exit(fn(ctx, _inst) {
      process.send(events, "flow_exit")
      Ok(ctx)
    })
    |> builder.add_step(Start, fn(ctx, inst) {
      process.send(events, "step")
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("flow_enter") = process.receive(events, 100)
  let assert Ok("step") = process.receive(events, 100)
  let assert Ok("flow_exit") = process.receive(events, 100)
}

pub fn engine_on_complete_handler_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("complete_h", ets, test_step_to_string, string_to_test_step)
    |> builder.on_complete(fn(ctx, inst) {
      let name = instance.get_data(inst, "name")
      process.send(events, "complete:" <> option.unwrap(name, "?"))
      Ok(ctx)
    })
    |> builder.add_step(Start, fn(ctx, inst) {
      let inst = instance.store_data(inst, "name", "Bob")
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("complete:Bob") = process.receive(events, 100)
}

// ============================================================================
// Engine: Global middleware
// ============================================================================

pub fn engine_global_middleware_applies_to_all_steps_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("global_mw", ets, test_step_to_string, string_to_test_step)
    |> builder.add_global_middleware(fn(_ctx, _inst, next) {
      process.send(events, "mw_before")
      let result = next()
      process.send(events, "mw_after")
      result
    })
    |> builder.add_step(Start, fn(ctx, inst) {
      process.send(events, "start")
      action.next(ctx, inst, step: End)
    })
    |> builder.add_step(End, fn(ctx, inst) {
      process.send(events, "end")
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  // Middleware wraps Start step
  let assert Ok("mw_before") = process.receive(events, 100)
  let assert Ok("start") = process.receive(events, 100)
  let assert Ok("mw_after") = process.receive(events, 100)
  // Middleware wraps End step
  let assert Ok("mw_before") = process.receive(events, 100)
  let assert Ok("end") = process.receive(events, 100)
  let assert Ok("mw_after") = process.receive(events, 100)
}

// ============================================================================
// Engine: Inline subflows
// ============================================================================

pub fn engine_inline_subflow_execution_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("subflow_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      process.send(events, "parent:start")
      action.next(ctx, inst, step: Middle)
    })
    |> builder.with_inline_subflow(
      name: "child",
      trigger: Middle,
      return_to: End,
      initial: "sub_a",
      steps: [
        #("sub_a", fn(ctx, inst) {
          process.send(events, "child:sub_a")
          let inst = instance.store_data(inst, "sub_data", "collected")
          builder.inline_next(ctx, inst, "sub_b")
        }),
        #("sub_b", fn(ctx, inst) {
          process.send(events, "child:sub_b")
          action.return_from_subflow(ctx, inst, dict.new())
        }),
      ],
    )
    |> builder.add_step(End, fn(ctx, inst) {
      process.send(events, "parent:end")
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("parent:start") = process.receive(events, 100)
  let assert Ok("child:sub_a") = process.receive(events, 100)
  let assert Ok("child:sub_b") = process.receive(events, 100)
  // After subflow returns, parent continues at End
  // (return_to_parent_flow saves and returns Ok(ctx), End is reached on next resume)
}

pub fn engine_inline_subflow_with_mapping_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("mapped_sub", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      let inst = instance.store_data(inst, "parent_val", "hello")
      action.next(ctx, inst, step: Middle)
    })
    |> builder.with_inline_subflow_mapped(
      name: "mapped",
      trigger: Middle,
      return_to: End,
      initial: "collect",
      steps: [
        #("collect", fn(ctx, inst) {
          let parent_val = instance.get_data(inst, "mapped_arg")
          process.send(events, "arg:" <> option.unwrap(parent_val, "none"))
          action.return_from_subflow(
            ctx,
            inst,
            dict.from_list([#("result_key", "result_val")]),
          )
        }),
      ],
      map_args: fn(inst) {
        dict.from_list([
          #(
            "mapped_arg",
            option.unwrap(instance.get_data(inst, "parent_val"), ""),
          ),
        ])
      },
      map_result: fn(result, inst) {
        case dict.get(result, "result_key") {
          Ok(val) -> instance.store_data(inst, "merged_result", val)
          _ -> inst
        }
      },
    )
    |> builder.add_step(End, fn(ctx, inst) {
      let merged = instance.get_data(inst, "merged_result")
      process.send(events, "merged:" <> option.unwrap(merged, "none"))
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("arg:hello") = process.receive(events, 100)
}

// ============================================================================
// Engine: Self-transition (goto same step)
// ============================================================================

pub fn engine_self_transition_with_goto_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("self_goto", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      let count =
        instance.get_data(inst, "count")
        |> option.map(fn(s) { result.unwrap(int.parse(s), 0) })
        |> option.unwrap(0)
      process.send(events, "visit:" <> int.to_string(count))

      case count < 3 {
        True -> {
          let inst =
            instance.store_data(inst, "count", int.to_string(count + 1))
          action.goto(ctx, inst, step: Start)
        }
        False -> action.complete(ctx, inst)
      }
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("visit:0") = process.receive(events, 100)
  let assert Ok("visit:1") = process.receive(events, 100)
  let assert Ok("visit:2") = process.receive(events, 100)
  let assert Ok("visit:3") = process.receive(events, 100)
}

// ============================================================================
// Engine: Resume existing instance (not expired)
// ============================================================================

pub fn engine_resume_existing_instance_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("resume_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      case instance.get_wait_result(inst) {
        types.Pending -> {
          process.send(events, "first_visit")
          action.wait(ctx, inst)
        }
        types.TextInput(value:) -> {
          process.send(events, "resumed:" <> value)
          action.complete(ctx, inst)
        }
        _ -> action.cancel(ctx, inst)
      }
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  // First call: wait
  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )
  let assert Ok("first_visit") = process.receive(events, 100)

  // Second call with same user/chat: should resume the existing instance (still waiting)
  // Since instance exists and is not expired, start_or_resume calls execute_step
  let flow_id = storage.generate_id(1, 2, "resume_test")
  let assert Ok(Some(inst)) = ets.load(flow_id)
  inst.wait_token |> option.is_some() |> should.be_true()
}

// ============================================================================
// Engine: Exit action
// ============================================================================

pub fn engine_exit_deletes_instance_test() {
  let assert Ok(ets) = storage.create_ets_storage()

  let flow =
    builder.new("exit_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      action.exit(ctx, inst, result: Some(dict.from_list([#("k", "v")])))
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let flow_id = storage.generate_id(1, 2, "exit_test")
  let assert Ok(None) = ets.load(flow_id)
}

// ============================================================================
// Engine: Initial data is passed to flow
// ============================================================================

pub fn engine_initial_data_available_in_first_step_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("init_data", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      let source = instance.get_data(inst, "source")
      process.send(events, "source:" <> option.unwrap(source, "none"))
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.from_list([#("source", "command")]),
    )

  let assert Ok("source:command") = process.receive(events, 100)
}

// ============================================================================
// Engine: on_error handler
// ============================================================================

pub fn engine_missing_step_triggers_error_handler_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("err_test", ets, test_step_to_string, string_to_test_step)
    |> builder.on_error(fn(ctx, _inst, _err) {
      process.send(events, "error_handled")
      Ok(ctx)
    })
    |> builder.add_step(Start, fn(ctx, inst) {
      // Navigate to a step that doesn't have a handler registered
      action.unsafe_next(ctx, inst, step: "nonexistent")
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  let assert Ok("error_handled") = process.receive(events, 100)
}

// ============================================================================
// Engine: TTL expiration
// ============================================================================

pub fn engine_ttl_expired_instance_is_recreated_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("ttl_test", ets, test_step_to_string, string_to_test_step)
    |> builder.with_ttl(ms: 1)
    // 1ms TTL — will expire almost instantly
    |> builder.add_step(Start, fn(ctx, inst) {
      case instance.get_wait_result(inst) {
        types.Pending -> {
          process.send(events, "pending")
          action.wait(ctx, inst)
        }
        _ -> {
          process.send(events, "resumed")
          action.complete(ctx, inst)
        }
      }
    })
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  // First: create instance
  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )
  let assert Ok("pending") = process.receive(events, 100)

  // Sleep to ensure TTL expires
  process.sleep(5)

  // Second call: old instance expired -> new instance created -> Pending again
  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )
  let assert Ok("pending") = process.receive(events, 100)
}

// ============================================================================
// Instance: is_expired
// ============================================================================

pub fn instance_not_expired_without_ttl_test() {
  let inst =
    instance.new_instance(
      id: "test",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  instance.is_expired(inst, None) |> should.be_false()
}

pub fn instance_expired_by_wait_timeout_test() {
  let inst =
    types.FlowInstance(
      ..instance.new_instance(
        id: "test",
        flow_name: "test",
        user_id: 1,
        chat_id: 2,
        current_step: "start",
      ),
      wait_timeout_at: Some(1),
      // expired long ago
    )

  instance.is_expired(inst, None) |> should.be_true()
}

// ============================================================================
// Instance: next_with_data helper
// ============================================================================

pub fn instance_next_with_data_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "test",
      flow_name: "test",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_ctx, action, updated)) =
    instance.next_with_data(ctx, inst, step: End, key: "name", value: "Alice")

  case action {
    types.Next(End) -> Nil
    _ -> should.fail()
  }
  instance.get_data(updated, "name") |> should.equal(Some("Alice"))
}

// ============================================================================
// Instance: get_current_step
// ============================================================================

pub fn instance_get_current_step_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let flow =
    builder.new("step_test", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) { action.complete(ctx, inst) })
    |> builder.build(initial: Start)

  let inst =
    instance.new_instance(
      id: "test",
      flow_name: "step_test",
      user_id: 1,
      chat_id: 2,
      current_step: "middle",
    )

  instance.get_current_step(flow, inst) |> should.equal(Ok(Middle))
}

pub fn instance_get_current_step_invalid_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let flow =
    builder.new("step_test2", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) { action.complete(ctx, inst) })
    |> builder.build(initial: Start)

  let inst =
    instance.new_instance(
      id: "test",
      flow_name: "step_test2",
      user_id: 1,
      chat_id: 2,
      current_step: "unknown_step",
    )

  instance.get_current_step(flow, inst) |> should.equal(Error(Nil))
}

// ============================================================================
// Instance: encode_callback_wait_result
// ============================================================================

pub fn encode_callback_bool_true_test() {
  instance.encode_callback_wait_result("some_id:true")
  |> should.equal("bool:true")
}

pub fn encode_callback_bool_false_test() {
  instance.encode_callback_wait_result("some_id:false")
  |> should.equal("bool:false")
}

pub fn encode_callback_data_test() {
  instance.encode_callback_wait_result("some_random_data")
  |> should.equal("data:some_random_data")
}

// ============================================================================
// ETS Storage Tests
// ============================================================================

fn make_test_instance(
  id: String,
  user_id: Int,
  chat_id: Int,
) -> types.FlowInstance {
  instance.new_instance(
    id:,
    flow_name: "test_flow",
    user_id:,
    chat_id:,
    current_step: "start",
  )
}

pub fn ets_storage_save_and_load_test() {
  let assert Ok(storage) = storage.create_ets_storage()
  let instance = make_test_instance("ets_test_1", 100, 200)

  let assert Ok(Nil) = storage.save(instance)
  let assert Ok(Some(loaded)) = storage.load("ets_test_1")

  instance.instance_id(loaded) |> should.equal("ets_test_1")
  instance.instance_user_id(loaded) |> should.equal(100)
  instance.instance_chat_id(loaded) |> should.equal(200)
  instance.instance_flow_name(loaded) |> should.equal("test_flow")
}

pub fn ets_storage_load_nonexistent_test() {
  let assert Ok(storage) = storage.create_ets_storage()

  let assert Ok(None) = storage.load("nonexistent_id")
}

pub fn ets_storage_delete_test() {
  let assert Ok(storage) = storage.create_ets_storage()
  let instance = make_test_instance("ets_delete_1", 101, 201)

  let assert Ok(Nil) = storage.save(instance)
  let assert Ok(Some(_)) = storage.load("ets_delete_1")

  let assert Ok(Nil) = storage.delete("ets_delete_1")
  let assert Ok(None) = storage.load("ets_delete_1")
}

pub fn ets_storage_overwrite_test() {
  let assert Ok(storage) = storage.create_ets_storage()
  let instance1 = make_test_instance("ets_overwrite_1", 102, 202)
  let instance2 =
    instance1
    |> instance.store_data(key: "key", value: "value")

  let assert Ok(Nil) = storage.save(instance1)
  let assert Ok(Nil) = storage.save(instance2)
  let assert Ok(Some(loaded)) = storage.load("ets_overwrite_1")

  instance.get_data(loaded, "key") |> should.equal(Some("value"))
}

pub fn ets_storage_list_by_user_test() {
  let assert Ok(storage) = storage.create_ets_storage()

  let instance_a = make_test_instance("ets_list_a", 200, 300)
  let instance_b = make_test_instance("ets_list_b", 200, 300)
  let instance_c = make_test_instance("ets_list_c", 201, 300)
  let instance_d = make_test_instance("ets_list_d", 200, 301)

  let assert Ok(Nil) = storage.save(instance_a)
  let assert Ok(Nil) = storage.save(instance_b)
  let assert Ok(Nil) = storage.save(instance_c)
  let assert Ok(Nil) = storage.save(instance_d)

  let assert Ok(results) = storage.list_by_user(200, 300)
  list.length(results) |> should.equal(2)

  let ids = list.map(results, instance.instance_id)
  list.contains(ids, "ets_list_a") |> should.be_true()
  list.contains(ids, "ets_list_b") |> should.be_true()
}

pub fn ets_storage_list_by_user_empty_test() {
  let assert Ok(storage) = storage.create_ets_storage()

  let assert Ok(results) = storage.list_by_user(999, 999)
  results |> should.equal([])
}

pub fn ets_storage_delete_removes_from_user_index_test() {
  let assert Ok(storage) = storage.create_ets_storage()

  let inst = make_test_instance("ets_idx_del", 500, 600)
  let assert Ok(Nil) = storage.save(inst)

  let assert Ok(results_before) = storage.list_by_user(500, 600)
  list.length(results_before) |> should.equal(1)

  let assert Ok(Nil) = storage.delete("ets_idx_del")

  let assert Ok(results_after) = storage.list_by_user(500, 600)
  results_after |> should.equal([])
}

// ============================================================================
// Registry: cancel_user_flows, cancel_flow_instance
// ============================================================================

pub fn registry_cancel_user_flows_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let flow =
    builder.new("cancel_reg", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) { action.wait(ctx, inst) })
    |> builder.build(initial: Start)

  let reg =
    registry.new_registry()
    |> registry.register(types.OnCommand("start"), flow)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 100, chat_id: 200),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  // Start the flow to create an instance
  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 100,
      chat_id: 200,
      initial_data: dict.new(),
    )

  // Verify instance exists
  let flow_id = storage.generate_id(100, 200, "cancel_reg")
  let assert Ok(Some(_)) = ets.load(flow_id)

  // Cancel all user flows
  let assert Ok(cancelled) =
    registry.cancel_user_flows(reg, user_id: 100, chat_id: 200)
  list.length(cancelled) |> should.equal(1)

  // Verify instance is gone
  let assert Ok(None) = ets.load(flow_id)
}

pub fn registry_cancel_flow_instance_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let flow =
    builder.new("cancel_inst", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) { action.wait(ctx, inst) })
    |> builder.build(initial: Start)

  let reg =
    registry.new_registry()
    |> registry.register(types.OnCommand("test"), flow)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 10, chat_id: 20),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 10,
      chat_id: 20,
      initial_data: dict.new(),
    )

  let flow_id = storage.generate_id(10, 20, "cancel_inst")

  // Cancel by ID
  let assert Ok(True) = registry.cancel_flow_instance(reg, flow_id:)

  let assert Ok(None) = ets.load(flow_id)

  // Cancel non-existent returns False
  let assert Ok(False) =
    registry.cancel_flow_instance(reg, flow_id: "nonexistent")
}

// ============================================================================
// Registry: register_callable + call_flow
// ============================================================================

pub fn registry_call_flow_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("callable", ets, test_step_to_string, string_to_test_step)
    |> builder.add_step(Start, fn(ctx, inst) {
      let src = instance.get_data(inst, "src")
      process.send(events, "called:" <> option.unwrap(src, "none"))
      action.complete(ctx, inst)
    })
    |> builder.build(initial: Start)

  let reg =
    registry.new_registry()
    |> registry.register_callable(flow)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    registry.call_flow(
      ctx:,
      registry: reg,
      name: "callable",
      initial: dict.from_list([#("src", "handler")]),
    )

  let assert Ok("called:handler") = process.receive(events, 100)
}

pub fn registry_call_flow_nonexistent_test() {
  let reg = registry.new_registry()

  let ctx = context.context(session: Nil)

  let assert Ok(_) =
    registry.call_flow(
      ctx:,
      registry: reg,
      name: "nonexistent",
      initial: dict.new(),
    )
  // Should not error, just return Ok(ctx)
}

// ============================================================================
// InlineStep type
// ============================================================================

pub fn inline_step_type_equality_test() {
  let step1 = types.InlineStep("collect_name")
  let step2 = types.InlineStep("collect_email")
  let step3 = types.InlineStep("collect_name")

  step1 |> should.not_equal(step2)
  step1 |> should.equal(step3)
}

// ============================================================================
// Action module: pure return values
// ============================================================================

pub fn action_next_returns_correct_action_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_, action, _)) = action.next(ctx, inst, step: Middle)
  case action {
    types.Next(Middle) -> Nil
    _ -> should.fail()
  }
}

pub fn action_goto_returns_correct_action_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_, action, _)) = action.goto(ctx, inst, step: End)
  case action {
    types.GoTo(End) -> Nil
    _ -> should.fail()
  }
}

pub fn action_back_returns_correct_action_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_, action, _)) = action.back(ctx, inst)
  case action {
    types.Back -> Nil
    _ -> should.fail()
  }
}

pub fn action_complete_includes_instance_data_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance_with_data(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
      data: dict.from_list([#("key", "val")]),
    )

  let assert Ok(#(_, action, _)) = action.complete(ctx, inst)
  case action {
    types.Complete(data) -> {
      dict.get(data, "key") |> should.equal(Ok("val"))
    }
    _ -> should.fail()
  }
}

pub fn action_cancel_returns_correct_action_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_, action, _)) = action.cancel(ctx, inst)
  case action {
    types.Cancel -> Nil
    _ -> should.fail()
  }
}

pub fn action_wait_returns_correct_action_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_, action, _)) = action.wait(ctx, inst)
  case action {
    types.Wait -> Nil
    _ -> should.fail()
  }
}

pub fn action_wait_callback_returns_correct_action_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_, action, _)) = action.wait_callback(ctx, inst)
  case action {
    types.WaitCallback -> Nil
    _ -> should.fail()
  }
}

pub fn action_wait_with_timeout_returns_correct_action_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_, action, _)) =
    action.wait_with_timeout(ctx, inst, timeout_ms: 5000)
  case action {
    types.WaitWithTimeout(5000) -> Nil
    _ -> should.fail()
  }
}

pub fn action_wait_callback_with_timeout_returns_correct_action_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_, action, _)) =
    action.wait_callback_with_timeout(ctx, inst, timeout_ms: 3000)
  case action {
    types.WaitCallbackWithTimeout(3000) -> Nil
    _ -> should.fail()
  }
}

pub fn action_enter_subflow_returns_correct_action_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let data = dict.from_list([#("key", "val")])
  let assert Ok(#(_, action, _)) =
    action.enter_subflow(ctx, inst, subflow_name: "child", data:)
  case action {
    types.EnterSubflow("child", d) -> {
      dict.get(d, "key") |> should.equal(Ok("val"))
    }
    _ -> should.fail()
  }
}

pub fn action_return_from_subflow_returns_correct_action_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let result = dict.from_list([#("result", "data")])
  let assert Ok(#(_, action, _)) =
    action.return_from_subflow(ctx, inst, result:)
  case action {
    types.ReturnFromSubflow(r) -> {
      dict.get(r, "result") |> should.equal(Ok("data"))
    }
    _ -> should.fail()
  }
}

pub fn action_exit_with_result_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_, action, _)) =
    action.exit(ctx, inst, result: Some(dict.from_list([#("k", "v")])))
  case action {
    types.Exit(Some(d)) -> dict.get(d, "k") |> should.equal(Ok("v"))
    _ -> should.fail()
  }
}

pub fn action_exit_without_result_test() {
  let ctx = context.context(session: Nil)
  let inst =
    instance.new_instance(
      id: "t",
      flow_name: "t",
      user_id: 1,
      chat_id: 2,
      current_step: "start",
    )

  let assert Ok(#(_, action, _)) = action.exit(ctx, inst, result: None)
  case action {
    types.Exit(None) -> Nil
    _ -> should.fail()
  }
}

// ============================================================================
// Builder: with_ttl, on_timeout
// ============================================================================

pub fn builder_with_ttl_builds_flow_test() {
  let assert Ok(ets) = storage.create_ets_storage()

  let flow =
    builder.new("ttl_build", ets, test_step_to_string, string_to_test_step)
    |> builder.with_ttl(ms: 60_000)
    |> builder.on_timeout(fn(ctx, _inst) { Ok(ctx) })
    |> builder.add_step(Start, fn(ctx, inst) { action.complete(ctx, inst) })
    |> builder.build(initial: Start)

  flow.ttl_ms |> should.equal(Some(60_000))
  flow.on_timeout |> option.is_some() |> should.be_true()
}

// ============================================================================
// Engine: step-level middleware combined with global
// ============================================================================

pub fn engine_step_middleware_combined_with_global_test() {
  let assert Ok(ets) = storage.create_ets_storage()
  let events = process.new_subject()

  let flow =
    builder.new("combo_mw", ets, test_step_to_string, string_to_test_step)
    |> builder.add_global_middleware(fn(_ctx, _inst, next) {
      process.send(events, "global")
      next()
    })
    |> builder.add_step_with_middleware(
      Start,
      [
        fn(_ctx, _inst, next) {
          process.send(events, "step_mw")
          next()
        },
      ],
      fn(ctx, inst) {
        process.send(events, "handler")
        action.complete(ctx, inst)
      },
    )
    |> builder.build(initial: Start)

  let #(client, _) = mock.message_client()
  let ctx =
    context.context_with(
      session: Nil,
      update: factory.text_update_with(text: "", from_id: 1, chat_id: 2),
    )
  let ctx = bot.Context(..ctx, config: context.config_with_client(client))

  let assert Ok(_) =
    engine.start_or_resume(
      flow,
      ctx,
      user_id: 1,
      chat_id: 2,
      initial_data: dict.new(),
    )

  // Global middleware runs first, then step-level, then handler
  let assert Ok("global") = process.receive(events, 100)
  let assert Ok("step_mw") = process.receive(events, 100)
  let assert Ok("handler") = process.receive(events, 100)
}

// ============================================================================
// Noop storage
// ============================================================================

pub fn noop_storage_operations_test() {
  let noop = storage.create_noop_storage()
  let inst = make_test_instance("noop_test", 1, 2)

  let assert Ok(Nil) = noop.save(inst)
  let assert Ok(None) = noop.load("noop_test")
  let assert Ok(Nil) = noop.delete("noop_test")
  let assert Ok([]) = noop.list_by_user(1, 2)
}
