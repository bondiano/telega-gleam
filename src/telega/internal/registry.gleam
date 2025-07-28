import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/result
import gleam/string

import telega/error

/// Registry itself is an actor storing a list of actors (eg. per-chat bot state instances).
pub opaque type Registry(message) {
  Registry(actors: Dict(String, Subject(message)))
}

pub opaque type RegistryMessage(message) {
  Register(
    reply_with: Subject(Subject(message)),
    key: String,
    self: Subject(message),
  )
  Get(reply_with: Subject(Option(Subject(message))), key: String)
  Unregister(key: String)
  Shutdown
}

pub type RegistrySubject(message) =
  Subject(RegistryMessage(message))

/// Starts a new registry.
pub fn start() -> Result(Subject(RegistryMessage(message)), error.TelegaError) {
  let initial_state = Registry(actors: dict.new())

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start
  |> result.map(fn(started) { started.data })
  |> result.map_error(fn(error) {
    error.RegistryStartError(string.inspect(error))
  })
}

pub fn stop(in actor: RegistrySubject(message)) -> Nil {
  actor.send(actor, Shutdown)
}

const register_timeout = 3

pub fn register(
  in actor: RegistrySubject(message),
  key key: String,
  subject subject: Subject(message),
) -> Subject(message) {
  actor.call(actor, register_timeout, Register(_, key, subject))
}

pub fn unregister(in actor: RegistrySubject(message), key key: String) -> Nil {
  actor.send(actor, Unregister(key))
}

const try_get_timeout = 10

pub fn get(
  in actor: RegistrySubject(message),
  key key: String,
) -> Option(Subject(message)) {
  process.call(actor, try_get_timeout, Get(_, key))
}

fn handle_message(self: Registry(message), message: RegistryMessage(message)) {
  case message {
    Get(reply_with, key) -> {
      dict.get(self.actors, key)
      |> option.from_result
      |> process.send(reply_with, _)

      actor.continue(self)
    }

    Register(reply_with, key, subject) -> {
      let actors = dict.insert(self.actors, key, subject)
      process.send(reply_with, subject)

      actor.continue(Registry(actors:))
    }

    Unregister(key) -> {
      let actors = dict.delete(self.actors, key)
      actor.continue(Registry(actors:))
    }

    Shutdown -> actor.stop()
  }
}
