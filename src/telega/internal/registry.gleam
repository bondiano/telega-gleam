import gleam/dict.{type Dict}
import gleam/erlang/process.{
  type Pid, type ProcessMonitor, type Selector, type Subject,
}
import gleam/function
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/result
import gleam/string

import telega/error

pub opaque type Actor(message) {
  Actor(pid: Pid, monitor: ProcessMonitor, self: Subject(message))
}

/// Registry itself is an actor storing a list of actors (eg. per-chat bot state instances).
pub opaque type Registry(message) {
  Registry(
    self: Subject(RegistryMessage(message)),
    selector: Selector(RegistryMessage(message)),
    actors: Dict(String, Actor(message)),
  )
}

pub opaque type RegistryMessage(message) {
  Register(key: String, pid: Pid, self: Subject(message))
  Get(reply_with: Subject(Option(Subject(message))), key: String)
  ActorExit(key: String, process_down: process.ProcessDown)
  Unregister(key: String)
  Shutdown
}

pub type RegistrySubject(message) =
  Subject(RegistryMessage(message))

const bot_actor_init_timeout = 100

/// Starts a new registry.
pub fn start() {
  actor.start_spec(actor.Spec(
    init: fn() {
      let self = process.new_subject()
      let selector =
        process.new_selector() |> process.selecting(self, function.identity)
      let registry = Registry(self:, selector:, actors: dict.new())

      actor.Ready(registry, selector)
    },
    loop:,
    init_timeout: bot_actor_init_timeout,
  ))
  |> result.map_error(fn(error) {
    error.RegistryStartError(string.inspect(error))
  })
}

pub fn stop(in actor: RegistrySubject(message)) {
  actor.send(actor, Shutdown)
}

pub fn register(
  in actor: RegistrySubject(message),
  key key: String,
  subject subject: Subject(message),
) {
  let pid = process.subject_owner(subject)
  actor.send(actor, Register(key, pid, subject))
  subject
}

pub fn unregister(in actor: RegistrySubject(message), key key: String) {
  actor.send(actor, Unregister(key))
}

const try_get_timeout = 10

pub fn get(
  in actor: RegistrySubject(message),
  key key: String,
) -> Option(Subject(message)) {
  actor.call(actor, Get(_, key), try_get_timeout)
}

fn loop(message: RegistryMessage(message), self: Registry(message)) {
  case message {
    Get(reply_with, key) -> {
      dict.get(self.actors, key)
      |> result.map(fn(actor) { actor.self })
      |> option.from_result
      |> actor.send(reply_with, _)

      actor.continue(self)
    }

    Register(key, pid, process_subject) -> {
      let next_registry = handle_register(self, key, pid, process_subject)
      next_registry
      |> actor.continue()
      |> actor.with_selector(next_registry.selector)
    }

    ActorExit(key, process_down) -> {
      let next_registry = remove(self, key, option.Some(process_down.pid))

      next_registry
      |> actor.continue()
      |> actor.with_selector(next_registry.selector)
    }

    Unregister(key) -> {
      let next_registry = remove(self, key, option.None)

      next_registry
      |> actor.continue()
      |> actor.with_selector(next_registry.selector)
    }

    Shutdown -> actor.Stop(process.Normal)
  }
}

fn handle_register(
  self: Registry(message),
  key: String,
  pid: Pid,
  process_subject: Subject(message),
) -> Registry(message) {
  let registry = remove(self, key, option.None)

  let monitor = process.monitor_process(pid)
  let selector =
    self.selector
    |> process.selecting_process_down(monitor, ActorExit(key:, process_down: _))

  let actor = Actor(pid:, monitor:, self: process_subject)
  let actors = dict.insert(registry.actors, for: key, insert: actor)

  Registry(..registry, actors:, selector:)
}

/// Demonitors and removes the specified actor, then rebuilds our selector.
///
/// - when_pid: Specify `Some(pid)` to prevent a potential race condition from
///   removing a newly registered actor instead of the one it replaced.
///   Specifying `None` will always remove the actor.
///
/// Takes an implementation from [singularity](https://hex.pm/packages/singularity)
fn remove(self: Registry(message), key: String, when_pid: Option(Pid)) {
  let rm = fn(actor: Actor(message)) {
    process.demonitor_process(actor.monitor)
    let actors = dict.delete(self.actors, key)
    let selector = build_selector(self.self, self.actors)

    Registry(..self, actors:, selector:)
  }

  case dict.get(self.actors, key) {
    Ok(Actor(pid: pid, monitor: _, self: _) as actor)
      if when_pid == option.Some(pid)
    -> rm(actor)
    Ok(actor) if when_pid == option.None -> rm(actor)
    Ok(_) -> self
    Error(Nil) -> self
  }
}

fn build_selector(
  self: Subject(RegistryMessage(message)),
  actors: Dict(String, Actor(message)),
) -> Selector(RegistryMessage(message)) {
  let base_selector =
    process.new_selector()
    |> process.selecting(self, fn(msg) { msg })

  dict.fold(over: actors, from: base_selector, with: fn(selector, key, actor) {
    process.selecting_process_down(selector, actor.monitor, ActorExit(
      key:,
      process_down: _,
    ))
  })
}
