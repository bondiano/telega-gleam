import gleam/dynamic
import gleam/erlang/atom.{type Atom}
import gleam/list
import gleam/option.{type Option}

import telega/error

type EtsTable

pub opaque type FlowEtsStorage {
  FlowEtsStorage(table: EtsTable)
}

pub fn start() -> Result(FlowEtsStorage, error.TelegaError) {
  let name = atom.create("telega_flow_storage")
  let table = case is_undefined(ets_whereis_raw(name)) {
    True ->
      ets_new(name, [
        atom.create("set"),
        atom.create("public"),
        atom.create("named_table"),
      ])
    False -> coerce(ets_whereis_raw(name))
  }
  Ok(FlowEtsStorage(table:))
}

pub fn save(storage: FlowEtsStorage, key: String, value: value) -> Nil {
  ets_insert(storage.table, #(key, value))
  Nil
}

pub fn load(storage: FlowEtsStorage, key: String) -> Option(value) {
  case ets_lookup(storage.table, key) {
    [] -> option.None
    [#(_, value), ..] -> option.Some(value)
  }
}

pub fn delete(storage: FlowEtsStorage, key: String) -> Nil {
  ets_delete(storage.table, key)
  Nil
}

/// Add an instance ID to the secondary index for a user+chat key.
pub fn add_to_index(
  storage: FlowEtsStorage,
  index_key: String,
  instance_id: String,
) -> Nil {
  let existing = case ets_lookup(storage.table, index_key) {
    [] -> []
    [#(_, ids), ..] -> ids
  }
  case list.contains(existing, instance_id) {
    True -> Nil
    False -> {
      ets_insert_list(storage.table, #(index_key, [instance_id, ..existing]))
      Nil
    }
  }
}

/// Remove an instance ID from the secondary index for a user+chat key.
pub fn remove_from_index(
  storage: FlowEtsStorage,
  index_key: String,
  instance_id: String,
) -> Nil {
  case ets_lookup(storage.table, index_key) {
    [] -> Nil
    [#(_, ids), ..] -> {
      let updated = list.filter(ids, fn(id) { id != instance_id })
      case updated {
        [] -> {
          ets_delete(storage.table, index_key)
          Nil
        }
        _ -> {
          ets_insert_list(storage.table, #(index_key, updated))
          Nil
        }
      }
    }
  }
}

/// Get all instance IDs from the secondary index for a user+chat key.
pub fn lookup_index(storage: FlowEtsStorage, index_key: String) -> List(String) {
  case ets_lookup(storage.table, index_key) {
    [] -> []
    [#(_, ids), ..] -> ids
  }
}

@external(erlang, "ets", "whereis")
fn ets_whereis_raw(name: Atom) -> dynamic.Dynamic

fn is_undefined(value: dynamic.Dynamic) -> Bool {
  case atom.get("undefined") {
    Ok(undefined) -> value == atom.to_dynamic(undefined)
    Error(_) -> False
  }
}

@external(erlang, "gleam_stdlib", "identity")
fn coerce(value: dynamic.Dynamic) -> EtsTable

@external(erlang, "ets", "new")
fn ets_new(name: Atom, options: List(Atom)) -> EtsTable

@external(erlang, "ets", "insert")
fn ets_insert(table: EtsTable, tuple: #(String, value)) -> Bool

@external(erlang, "ets", "insert")
fn ets_insert_list(table: EtsTable, tuple: #(String, List(String))) -> Bool

@external(erlang, "ets", "lookup")
fn ets_lookup(table: EtsTable, key: String) -> List(#(String, value))

@external(erlang, "ets", "delete")
fn ets_delete(table: EtsTable, key: String) -> Bool
