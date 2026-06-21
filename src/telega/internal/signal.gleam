//// OS signal handling for graceful shutdown.
////
//// Registers this module as a `gen_event` handler on the runtime's
//// `erl_signal_server`, so SIGTERM invokes a callback instead of immediately
//// stopping the VM. (SIGINT is reserved by BEAM for the interactive break
//// handler and cannot be managed via `os:set_signal`, so only SIGTERM — the
//// signal sent on rolling deploys — is handled.)
////
//// The `gen_event` callbacks are written directly in Gleam — no `.erl` file.
//// A Gleam module compiles to an Erlang module, and Gleam tuples/atoms compile
//// to the exact terms `gen_event` expects (`{ok, State}`, `{ok, Reply, State}`,
//// …), so the behaviour callbacks below are valid `gen_event` callbacks.

import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom.{type Atom}

/// Callback invoked with the received signal name (`sigterm`).
pub type SignalCallback =
  fn(Atom) -> Nil

/// Install a handler for SIGTERM.
///
/// The callback runs in the signal-server process; it is expected to perform a
/// graceful shutdown and then halt the VM.
pub fn install(callback callback: SignalCallback) -> Nil {
  set_signal(atom.create("sigterm"), atom.create("handle"))
  // Drop the default handler (which calls `init:stop/0` on SIGTERM) so our
  // callback controls shutdown timing instead of racing the VM teardown.
  let _ = delete_handler(signal_server(), atom.create("erl_signal_handler"), [])
  let _ = add_handler(signal_server(), this_module(), [callback])
  Nil
}

fn signal_server() -> Atom {
  atom.create("erl_signal_server")
}

/// This module's atom name, resolved at runtime (rename-safe) from one of its
/// own functions, so it can register itself as the `gen_event` handler module.
fn this_module() -> Atom {
  let #(_, module) = fun_info(init, atom.create("module"))
  module
}

// --- gen_event behaviour callbacks ---
// Invoked by the OTP `gen_event` manager, so they return the Erlang tuples it
// expects. The handler state is the user callback.

pub fn init(args: List(SignalCallback)) -> #(Atom, SignalCallback) {
  let assert [callback, ..] = args
  #(atom.create("ok"), callback)
}

pub fn handle_event(
  signal: Atom,
  callback: SignalCallback,
) -> #(Atom, SignalCallback) {
  callback(signal)
  #(atom.create("ok"), callback)
}

pub fn handle_call(
  _request: Dynamic,
  callback: SignalCallback,
) -> #(Atom, Atom, SignalCallback) {
  #(atom.create("ok"), atom.create("ok"), callback)
}

pub fn handle_info(
  _info: Dynamic,
  callback: SignalCallback,
) -> #(Atom, SignalCallback) {
  #(atom.create("ok"), callback)
}

pub fn terminate(_reason: Dynamic, _callback: SignalCallback) -> Atom {
  atom.create("ok")
}

pub fn code_change(
  _old_vsn: Dynamic,
  callback: SignalCallback,
  _extra: Dynamic,
) -> #(Atom, SignalCallback) {
  #(atom.create("ok"), callback)
}

@external(erlang, "os", "set_signal")
fn set_signal(signal: Atom, option: Atom) -> Atom

@external(erlang, "gen_event", "add_handler")
fn add_handler(
  manager: Atom,
  handler: Atom,
  args: List(SignalCallback),
) -> Dynamic

@external(erlang, "gen_event", "delete_handler")
fn delete_handler(manager: Atom, handler: Atom, args: List(a)) -> Dynamic

@external(erlang, "erlang", "fun_info")
fn fun_info(
  f: fn(List(SignalCallback)) -> #(Atom, SignalCallback),
  key: Atom,
) -> #(Atom, Atom)
