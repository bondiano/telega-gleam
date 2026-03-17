import gleam/dynamic
import gleam/erlang/atom.{type Atom}
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

pub fn list_all(storage: FlowEtsStorage) -> List(#(String, value)) {
  ets_tab2list(storage.table)
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

@external(erlang, "ets", "lookup")
fn ets_lookup(table: EtsTable, key: String) -> List(#(String, value))

@external(erlang, "ets", "delete")
fn ets_delete(table: EtsTable, key: String) -> Bool

@external(erlang, "ets", "tab2list")
fn ets_tab2list(table: EtsTable) -> List(#(String, value))
