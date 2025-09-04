import gleam/dict
import gleam/option.{None}
import gleeunit
import gleeunit/should
import telega/conversation/flow
import telega/conversation/persistent_flow as pflow

pub fn main() {
  gleeunit.main()
}

// Test persistent flow creation
pub fn new_persistent_flow_test() {
  let storage = pflow.memory_storage()
  let test_flow = pflow.new("persistent_test", "start", storage)

  should.equal(test_flow.name, "persistent_test")
  should.equal(test_flow.initial_step, "start")
  should.equal(dict.size(test_flow.steps), 0)
  should.equal(test_flow.on_complete, None)
  should.equal(test_flow.on_error, None)
}

// Test adding steps to persistent flow
pub fn add_step_test() {
  let storage = pflow.memory_storage()
  let test_flow =
    pflow.new("test_flow", "start", storage)
    |> pflow.add_step("start", fn(ctx, instance) {
      Ok(#(ctx, pflow.StandardAction(flow.Next("step2")), instance))
    })
    |> pflow.add_step("step2", fn(ctx, instance) {
      Ok(#(
        ctx,
        pflow.StandardAction(flow.Complete(instance.state.data)),
        instance,
      ))
    })

  should.equal(dict.size(test_flow.steps), 2)
  should.be_ok(dict.get(test_flow.steps, "start"))
  should.be_ok(dict.get(test_flow.steps, "step2"))
}

// Test flow instance creation
pub fn flow_instance_test() {
  let state =
    flow.FlowState(
      current_step: "welcome",
      data: dict.from_list([#("name", "Alice")]),
      history: ["start"],
    )

  let instance =
    pflow.FlowInstance(
      id: "123:456:test",
      flow_name: "test_flow",
      user_id: 456,
      chat_id: 123,
      state: state,
      scene_data: dict.new(),
      wait_token: None,
      created_at: 1000,
      updated_at: 2000,
    )

  should.equal(instance.id, "123:456:test")
  should.equal(instance.flow_name, "test_flow")
  should.equal(instance.user_id, 456)
  should.equal(instance.chat_id, 123)
  should.equal(instance.state.current_step, "welcome")
  should.equal(dict.size(instance.state.data), 1)
  should.equal(instance.state.history, ["start"])
  should.equal(instance.created_at, 1000)
  should.equal(instance.updated_at, 2000)
}

// Test flow handlers
pub fn on_complete_test() {
  let storage = pflow.memory_storage()
  let test_flow =
    pflow.new("test_flow", "start", storage)
    |> pflow.on_complete(fn(ctx, _instance) { Ok(ctx) })

  should.be_some(test_flow.on_complete)
}

pub fn on_error_test() {
  let storage = pflow.memory_storage()
  let test_flow =
    pflow.new("test_flow", "start", storage)
    |> pflow.on_error(fn(ctx, _instance, _error) { Ok(ctx) })

  should.be_some(test_flow.on_error)
}

// Test memory storage
pub fn memory_storage_test() {
  let storage = pflow.memory_storage()

  // Test save
  let instance = create_test_instance()
  should.be_ok(storage.save(instance))

  // Test load (always returns None for memory storage stub)
  case storage.load("test_id") {
    Ok(None) -> should.be_true(True)
    _ -> should.fail()
  }

  // Test delete
  should.be_ok(storage.delete("test_id"))

  // Test list_by_user
  case storage.list_by_user(123, 456) {
    Ok(list) -> should.equal(list, [])
    Error(_) -> should.fail()
  }
}

// Helper function to create test instance
fn create_test_instance() -> pflow.FlowInstance {
  pflow.FlowInstance(
    id: "test_id",
    flow_name: "test_flow",
    user_id: 123,
    chat_id: 456,
    state: flow.FlowState(current_step: "start", data: dict.new(), history: []),
    scene_data: dict.new(),
    wait_token: None,
    created_at: 1000,
    updated_at: 1000,
  )
}
