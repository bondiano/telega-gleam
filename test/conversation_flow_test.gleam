import gleam/dict
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import telega/conversation/flow

pub fn main() {
  gleeunit.main()
}

pub fn new_flow_test() {
  let test_flow = flow.new("test_flow", "start")

  should.equal(test_flow.name, "test_flow")
  should.equal(test_flow.initial_step, "start")
  should.equal(dict.size(test_flow.steps), 0)
  should.equal(test_flow.on_complete, None)
  should.equal(test_flow.on_cancel, None)
}

pub fn add_step_test() {
  let test_flow =
    flow.new("test_flow", "start")
    |> flow.add_step("start", fn(ctx, _state) { Ok(#(ctx, flow.Next("step2"))) })
    |> flow.add_step("step2", fn(ctx, state) {
      Ok(#(ctx, flow.Complete(state.data)))
    })

  should.equal(dict.size(test_flow.steps), 2)
  should.be_ok(dict.get(test_flow.steps, "start"))
  should.be_ok(dict.get(test_flow.steps, "step2"))
}

pub fn flow_state_test() {
  let initial_state =
    flow.FlowState(current_step: "start", data: dict.new(), history: [])

  let state_with_data =
    initial_state
    |> flow.store_data("name", "Alice")
    |> flow.store_data("age", "25")

  should.equal(flow.get_data(state_with_data, "name"), Some("Alice"))
  should.equal(flow.get_data(state_with_data, "age"), Some("25"))
  should.equal(flow.get_data(state_with_data, "unknown"), None)

  should.equal(state_with_data.current_step, "start")
  should.equal(state_with_data.history, [])
}

pub fn on_complete_test() {
  let test_flow =
    flow.new("test_flow", "start")
    |> flow.on_complete(fn(ctx, _data) { Ok(ctx) })

  should.be_some(test_flow.on_complete)
}

pub fn on_cancel_test() {
  let test_flow =
    flow.new("test_flow", "start")
    |> flow.on_cancel(fn(ctx) { Ok(ctx) })

  should.be_some(test_flow.on_cancel)
}
