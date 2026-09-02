//// ETS tables that outlive the process that asked for them.
////
//// An ETS table dies with its owner. A registry or cache created in a `main`
//// that spawns the bot and then returns — or worse, in a handler — leaves
//// every later lookup raising `badarg` inside a chat instance. The tables here
//// are held by a bare process that does nothing but hold one, and that exits
//// once the table is gone.

import gleam/erlang/atom.{type Atom}
import gleam/erlang/process

pub type EtsTable

/// How often the owner checks whether its table still exists.
const hold_interval_ms = 60_000

/// Create a public ETS table owned by a process of its own.
///
/// The table is anonymous: two calls give two independent tables, the way
/// creating one inline used to.
pub fn create_owned() -> EtsTable {
  let ready = process.new_subject()

  process.spawn_unlinked(fn() {
    let table =
      ets_new(atom.create("telega_owned_table"), [
        atom.create("set"),
        atom.create("public"),
      ])
    process.send(ready, table)
    hold(table)
  })

  let assert Ok(table) = process.receive(ready, 5000)
    as "ETS table owner failed to start"
  table
}

/// Holding the table is the whole job — until someone deletes it.
fn hold(table: EtsTable) -> Nil {
  process.sleep(hold_interval_ms)
  case is_alive(table) {
    True -> hold(table)
    False -> Nil
  }
}

@external(erlang, "ets", "new")
fn ets_new(name: Atom, options: List(Atom)) -> EtsTable

@external(erlang, "telega_ets_ffi", "is_alive")
fn is_alive(table: EtsTable) -> Bool
