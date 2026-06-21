import gleam/erlang/atom.{type Atom}
import gleam/erlang/process
import gleeunit/should

import telega/internal/signal

// gen_event:notify/2 lets us deliver a synthetic signal event to the
// erl_signal_server without raising a real OS signal.
@external(erlang, "gen_event", "notify")
fn notify(manager: Atom, event: Atom) -> Atom

pub fn signal_handler_invokes_callback_test() {
  let subject = process.new_subject()
  signal.install(fn(sig) { process.send(subject, sig) })

  notify(atom.create("erl_signal_server"), atom.create("sigterm"))

  let assert Ok(received) = process.receive(subject, 1000)
  received
  |> should.equal(atom.create("sigterm"))
}
