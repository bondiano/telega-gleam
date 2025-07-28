import gleam/erlang/process
import gleam/option.{Some}
import gleam/otp/actor
import gleeunit/should

import telega/internal/registry

type Msg

pub fn simple_actor_test() {
  let assert Ok(simple_registry) = registry.start()

  let assert Ok(started_a) =
    actor.new(Nil)
    |> actor.on_message(fn(_state, _msg: Msg) { actor.continue(Nil) })
    |> actor.start
  let assert Ok(started_b) =
    actor.new(Nil)
    |> actor.on_message(fn(_state, _msg: Msg) { actor.continue(Nil) })
    |> actor.start

  let actor_a = started_a.data
  let actor_b = started_b.data

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

  let assert Ok(started_a) =
    actor.new(Nil)
    |> actor.on_message(fn(_state, msg: MsgEcho) {
      case msg {
        MsgEcho(subj, "crash") -> {
          process.send(subj, "ok")
          actor.stop()
        }
        MsgEcho(subj, echo_) -> {
          process.send(subj, echo_)
          actor.continue(Nil)
        }
      }
    })
    |> actor.start
  let assert Ok(started_b) =
    actor.new(Nil)
    |> actor.on_message(fn(_state, msg: MsgEcho) {
      case msg {
        MsgEcho(subj, echo_) -> {
          process.send(subj, echo_)
          actor.continue(Nil)
        }
      }
    })
    |> actor.start

  let actor_a = started_a.data
  let actor_b = started_b.data

  registry.register(in: simple_registry, key: "actor_a", subject: actor_a)
  registry.register(in: simple_registry, key: "actor_b", subject: actor_b)

  let assert Some(got_a) = registry.get(in: simple_registry, key: "actor_a")
  let assert Some(got_b) = registry.get(in: simple_registry, key: "actor_b")

  process.call(got_a, 100, MsgEcho(_, "crash"))
  let assert Ok(pid) = process.subject_owner(got_a)
  pid
  |> process.is_alive
  |> should.equal(False)

  process.call(got_b, 100, MsgEcho(_, "ok")) |> should.equal("ok")
}
