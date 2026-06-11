import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import sqlight

import telega/flow/instance
import telega/flow/types.{FlowInstance, FlowStackFrame, FlowState, ParallelState}
import telega/storage
import telega_storage_sqlite as sqlite

pub fn main() {
  gleeunit.main()
}

fn with_kv(f: fn(storage.KeyValueStorage(sqlight.Error)) -> a) -> a {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(Nil) = sqlite.migrate(conn)
  f(sqlite.new(conn))
}

pub fn set_get_delete_test() {
  use kv <- with_kv()

  kv.get("missing") |> should.equal(Ok(None))

  let assert Ok(Nil) = kv.set("a", "1")
  kv.get("a") |> should.equal(Ok(Some("1")))

  let assert Ok(Nil) = kv.set("a", "2")
  kv.get("a") |> should.equal(Ok(Some("2")))

  let assert Ok(Nil) = kv.delete("a")
  kv.get("a") |> should.equal(Ok(None))
}

pub fn scan_by_prefix_test() {
  use kv <- with_kv()
  let assert Ok(Nil) = kv.set("flow:x", "1")
  let assert Ok(Nil) = kv.set("flow:y", "2")
  let assert Ok(Nil) = kv.set("session:z", "3")

  let assert Ok(keys) = kv.scan("flow:")
  keys |> list.sort(by: string.compare) |> should.equal(["flow:x", "flow:y"])
}

pub fn ttl_lazy_expiration_test() {
  use kv <- with_kv()

  let assert Ok(Nil) = kv.set_with_ttl("gone", "v", -1)
  kv.get("gone") |> should.equal(Ok(None))
  kv.scan("") |> should.equal(Ok([]))

  let assert Ok(Nil) = kv.set_with_ttl("live", "v", 60_000)
  kv.get("live") |> should.equal(Ok(Some("v")))
}

pub fn session_bridge_round_trip_test() {
  use kv <- with_kv()
  let settings =
    storage.session_settings_from_storage(
      storage: kv,
      encode: json.int,
      decode: decode.int,
      default: fn() { 0 },
    )

  settings.get_session("42:7") |> should.equal(Ok(None))
  let assert Ok(7) = settings.persist_session("42:7", 7)
  settings.get_session("42:7") |> should.equal(Ok(Some(7)))
}

fn sample_instance() -> types.FlowInstance {
  FlowInstance(
    id: "booking_20_10",
    flow_name: "booking",
    user_id: 10,
    chat_id: 20,
    state: FlowState(
      current_step: "confirm",
      data: dict.from_list([#("name", "Ada")]),
      history: ["start", "confirm"],
      flow_stack: [
        FlowStackFrame(
          flow_name: "parent",
          return_step: "after",
          saved_data: dict.from_list([#("k", "v")]),
        ),
      ],
      parallel_state: Some(ParallelState(
        pending_steps: ["a"],
        completed_steps: ["b"],
        results: dict.from_list([#("b", dict.from_list([#("ok", "1")]))]),
        join_step: "join",
      )),
    ),
    step_data: dict.from_list([#("tmp", "x")]),
    wait_token: Some("tok"),
    wait_timeout_at: Some(123),
    created_at: 1000,
    updated_at: 2000,
  )
}

pub fn flow_bridge_persists_full_instance_test() {
  use kv <- with_kv()
  let flow_storage = storage.flow_storage_from_storage(kv)
  let inst = sample_instance()

  let assert Ok(Nil) = flow_storage.save(inst)
  flow_storage.load(inst.id) |> should.equal(Ok(Some(inst)))

  let assert Ok(found) = flow_storage.list_by_user(10, 20)
  found |> should.equal([inst])

  let assert Ok(Nil) = flow_storage.delete(inst.id)
  flow_storage.load(inst.id) |> should.equal(Ok(None))
}

pub fn instance_json_round_trip_test() {
  let original = sample_instance()
  let assert Ok(restored) =
    original |> instance.to_json_string |> instance.from_json_string
  restored |> should.equal(original)
}
