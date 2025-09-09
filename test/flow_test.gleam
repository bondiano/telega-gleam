import gleam/dict
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import telega/flow

pub fn main() {
  gleeunit.main()
}

pub fn test_scene_data_preserved_on_navigation() {
  // Create initial instance with scene data
  let instance =
    flow.FlowInstance(
      id: "test_123_456",
      flow_name: "test_flow",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(current_step: "step1", data: dict.new(), history: [
        "step1",
      ]),
      scene_data: dict.from_list([
        #("step1_data", "value1"),
      ]),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Verify initial scene data
  flow.get_scene_data(instance, "step1_data")
  |> should.equal(Some("value1"))

  // Store additional scene data
  let instance2 = flow.store_scene_data(instance, "step2_data", "value2")

  // Both scene data should be available
  flow.get_scene_data(instance2, "step1_data")
  |> should.equal(Some("value1"))

  flow.get_scene_data(instance2, "step2_data")
  |> should.equal(Some("value2"))
}

pub fn test_goto_clears_scene_data() {
  // Create instance with scene data
  let instance =
    flow.FlowInstance(
      id: "test_123_456",
      flow_name: "test_flow",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(current_step: "step2", data: dict.new(), history: [
        "step2",
        "step1",
      ]),
      scene_data: dict.from_list([
        #("step1_data", "value1"),
        #("step2_data", "value2"),
      ]),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Clear scene data for GoTo navigation
  let cleared_instance = flow.clear_scene_data(instance)

  // Scene data should be cleared
  flow.get_scene_data(cleared_instance, "step1_data")
  |> should.equal(None)

  flow.get_scene_data(cleared_instance, "step2_data")
  |> should.equal(None)
}

pub fn test_store_and_get_flow_data() {
  let instance =
    flow.FlowInstance(
      id: "test_123_456",
      flow_name: "test_flow",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(current_step: "step1", data: dict.new(), history: [
        "step1",
      ]),
      scene_data: dict.new(),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Store data in flow state
  let instance2 = flow.store_data(instance, "name", "John")
  let instance3 = flow.store_data(instance2, "email", "john@example.com")

  // Retrieve data
  flow.get_data(instance3, "name")
  |> should.equal(Some("John"))

  flow.get_data(instance3, "email")
  |> should.equal(Some("john@example.com"))

  flow.get_data(instance3, "nonexistent")
  |> should.equal(None)
}

pub fn test_clear_scene_data_key() {
  let instance =
    flow.FlowInstance(
      id: "test_123_456",
      flow_name: "test_flow",
      user_id: 123,
      chat_id: 456,
      state: flow.FlowState(current_step: "step1", data: dict.new(), history: [
        "step1",
      ]),
      scene_data: dict.from_list([
        #("key1", "value1"),
        #("key2", "value2"),
        #("key3", "value3"),
      ]),
      wait_token: None,
      created_at: 0,
      updated_at: 0,
    )

  // Clear specific key
  let instance2 = flow.clear_scene_data_key(instance, "key2")

  // key2 should be gone, others should remain
  flow.get_scene_data(instance2, "key1")
  |> should.equal(Some("value1"))

  flow.get_scene_data(instance2, "key2")
  |> should.equal(None)

  flow.get_scene_data(instance2, "key3")
  |> should.equal(Some("value3"))
}
