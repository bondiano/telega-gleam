import gleam/erlang/atom
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}

import telega/error

type EtsTable

pub opaque type Registry(message) {
  Registry(table: EtsTable)
}

pub fn start() -> Result(Registry(message), error.TelegaError) {
  let table =
    ets_new(atom.create("telega_registry"), [
      atom.create("set"),
      atom.create("public"),
    ])
  Ok(Registry(table:))
}

pub fn stop(registry: Registry(message)) -> Bool {
  ets_delete_table(registry.table)
}

pub fn register(
  registry: Registry(message),
  key key: String,
  subject subject: Subject(message),
) -> Bool {
  ets_insert(registry.table, #(key, subject))
}

pub fn unregister(registry: Registry(message), key key: String) -> Bool {
  ets_delete(registry.table, key)
}

pub fn get(
  registry: Registry(message),
  key key: String,
) -> Option(Subject(message)) {
  case ets_lookup(registry.table, key) {
    [] -> option.None
    [#(_, subject), ..] -> option.Some(subject)
  }
}

@external(erlang, "ets", "new")
fn ets_new(name: atom.Atom, options: List(atom.Atom)) -> EtsTable

@external(erlang, "ets", "insert")
fn ets_insert(table: EtsTable, tuple: #(String, Subject(message))) -> Bool

@external(erlang, "ets", "lookup")
fn ets_lookup(table: EtsTable, key: String) -> List(#(String, Subject(message)))

@external(erlang, "ets", "delete")
fn ets_delete(table: EtsTable, key: String) -> Bool

@external(erlang, "ets", "delete")
fn ets_delete_table(table: EtsTable) -> Bool
