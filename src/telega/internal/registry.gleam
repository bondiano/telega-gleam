import gleam/erlang/atom
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}

import telega/error

type EtsTable

pub opaque type Registry(message) {
  Registry(table: EtsTable)
}

pub fn start(name: String) -> Result(Registry(message), error.TelegaError) {
  let table =
    ets_new(atom.create("telega_registry_" <> name), [
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

/// Remove `key`, but only while it still points at `pid`.
///
/// Used when a chat instance dies: by the time the owner notices, a supervisor
/// restart may already have re-registered a *live* instance under the same key,
/// and that fresh registration must survive the cleanup.
pub fn unregister_owned_by(
  registry: Registry(message),
  key key: String,
  pid pid: process.Pid,
) -> Bool {
  case get(registry, key:) {
    option.Some(subject) ->
      case process.subject_owner(subject) {
        Ok(owner) if owner == pid -> ets_delete(registry.table, key)
        _ -> False
      }
    option.None -> False
  }
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
