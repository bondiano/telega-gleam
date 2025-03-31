import gleam/erlang/process
import gleam/option.{Some}
import gleam/otp/actor
import gleeunit/should

import telega/internal/registry

type Msg

pub fn simple_actor_test() {
  let assert Ok(simple_registry) = registry.start()

  let assert Ok(actor_a) =
    actor.start(Nil, fn(_msg: Msg, state) { actor.continue(state) })
  let assert Ok(actor_b) =
    actor.start(Nil, fn(_msg: Msg, state) { actor.continue(state) })

  registry.register(in: simple_registry, key: "actor_a", subject: actor_a)
  registry.register(in: simple_registry, key: "actor_b", subject: actor_b)

  let assert Some(got_a) = registry.get(in: simple_registry, key: "actor_a")
  let assert Some(got_b) = registry.get(in: simple_registry, key: "actor_b")

  got_a
  |> should.equal(actor_a)
  got_b
  |> should.equal(actor_b)
}

type MsgEcho {
  MsgEcho(process.Subject(String), String)
}

pub fn still_work_after_crash_test() {
  let assert Ok(simple_registry) = registry.start()

  let assert Ok(actor_a) =
    actor.start(Nil, fn(msg: MsgEcho, state) {
      case msg {
        MsgEcho(subj, "crash") -> {
          actor.send(subj, "ok")
          actor.Stop(process.Abnormal("Ohh, no, it crashed"))
        }
        MsgEcho(subj, echo_) -> {
          actor.send(subj, echo_)
          actor.continue(state)
        }
      }
    })
  let assert Ok(actor_b) =
    actor.start(Nil, fn(msg: MsgEcho, state) {
      case msg {
        MsgEcho(subj, echo_) -> {
          actor.send(subj, echo_)
          actor.continue(state)
        }
      }
    })

  registry.register(in: simple_registry, key: "actor_a", subject: actor_a)
  registry.register(in: simple_registry, key: "actor_b", subject: actor_b)

  let assert Some(got_a) = registry.get(in: simple_registry, key: "actor_a")
  let assert Some(got_b) = registry.get(in: simple_registry, key: "actor_b")

  process.call(got_a, MsgEcho(_, "crash"), 100)
  process.subject_owner(got_a)
  |> process.is_alive
  |> should.equal(False)

  process.call(got_b, MsgEcho(_, "ok"), 100) |> should.equal("ok")
}
