import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/result

pub type StorageMessage(value) {
  Get(reply_with: Subject(Option(value)), key: String)
  Set(key: String, value: value)
}

pub type StorageSubject(value) =
  Subject(StorageMessage(value))

pub fn start() -> Result(StorageSubject(value), actor.StartError) {
  let initial_state = dict.new()

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start
  |> result.map(fn(started) { started.data })
}

pub fn get(in actor: StorageSubject(value), key key: String) -> Option(value) {
  process.call_forever(actor, Get(_, key))
}

pub fn set(
  in actor: StorageSubject(value),
  key key: String,
  value value: value,
) -> Nil {
  process.send(actor, Set(key, value))
}

fn handle_message(state, message) {
  case message {
    Get(reply_with, key) -> {
      let value =
        dict.get(state, key)
        |> option.from_result

      process.send(reply_with, value)
      actor.continue(state)
    }
    Set(key, value) -> {
      dict.insert(state, key, value)
      |> actor.continue
    }
  }
}
