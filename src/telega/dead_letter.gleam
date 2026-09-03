//// Updates that crashed the chat instance handling them.
////
//// A handler that panics takes its chat instance down with it. The bot actor
//// already notices (it monitors every instance it dispatched to) and answers
//// the poller or the webhook for the update the instance never finished — but
//// the update itself is gone, and with it any chance of finding out what the
//// bot was asked to do.
////
//// A dead-letter queue keeps it. Give the bot a `KeyValueStorage` with
//// [`telega.with_dead_letters`](telega.html#with_dead_letters) and every
//// update whose instance crashed is written under the `dlq:` prefix as the
//// raw JSON Telegram sent, together with the reason. Read them back with
//// [`telega.dead_letters`](telega.html#dead_letters), re-dispatch them with
//// [`telega.replay_dead_letters`](telega.html#replay_dead_letters) once the
//// bug is fixed, and drop them with [`telega.drop_dead_letter`].
////
//// ```gleam
//// let storage = storage.new(...)
////
//// telega.new(api_client)
//// |> telega.router(router)
//// |> telega.with_dead_letters(storage.dead_letters_from_storage(storage, ttl: None))
//// |> telega.start()
//// ```
////
//// Writing is **fire-and-forget in a spawned process**: the bot actor is the
//// only dispatcher a bot has, and a wedged storage backend must not be able
//// to stop it. A write that fails is logged and the letter is lost — the
//// queue is a debugging aid, not a durable inbox.
////
//// Entries are keyed by `update_id`, so a replayed update that crashes again
//// overwrites its own entry instead of growing the queue.

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/order
import gleam/result
import gleam/string

import telega/model/decoder
import telega/model/encoder
import telega/model/types.{type Update as RawUpdate}

/// The key prefix every dead letter is stored under.
pub const prefix = "dlq:"

/// A place to put updates that crashed, and to read them back from.
///
/// Built from a `KeyValueStorage` with
/// [`storage.dead_letters_from_storage`](storage.html#dead_letters_from_storage);
/// the backend's own error type is flattened to a `String` here, because the
/// bot that holds one is already generic over three type parameters and the
/// queue is never on a path where the error is matched on.
pub opaque type DeadLetters {
  DeadLetters(
    put: fn(String, String) -> Result(Nil, String),
    keys: fn() -> Result(List(String), String),
    read: fn(String) -> Result(Option(String), String),
    drop: fn(String) -> Result(Nil, String),
  )
}

/// One stored update, as read back from the queue.
pub type DeadLetter {
  DeadLetter(
    /// Storage key, e.g. `"dlq:123456"`. Pass it to `drop_dead_letter`.
    key: String,
    /// The update, ready to be handed back to `telega.handle_update`.
    update: RawUpdate,
    /// Why the instance went down, as the BEAM reported it.
    reason: String,
  )
}

/// Build a queue out of four storage primitives. Backends live in
/// `telega/storage`; this is the seam a custom one plugs into.
pub fn new(
  put put: fn(String, String) -> Result(Nil, String),
  keys keys: fn() -> Result(List(String), String),
  read read: fn(String) -> Result(Option(String), String),
  drop drop: fn(String) -> Result(Nil, String),
) -> DeadLetters {
  DeadLetters(put:, keys:, read:, drop:)
}

/// The key an update is stored under.
pub fn key_for(update: RawUpdate) -> String {
  prefix <> int.to_string(update.update_id)
}

/// Store one update. Called by the bot actor when a chat instance goes down
/// with work still in flight.
pub fn record(
  letters letters: DeadLetters,
  update update: RawUpdate,
  reason reason: String,
) -> Result(Nil, String) {
  let payload =
    json.object([
      #("reason", json.string(reason)),
      #("update", encoder.encode_update(update)),
    ])
    |> json.to_string

  letters.put(key_for(update), payload)
}

/// Every stored letter, oldest `update_id` first.
///
/// A payload that will not decode is reported in the `Error` list rather than
/// silently skipped — a queue that quietly drops what it cannot read is worse
/// than no queue.
pub fn list(
  letters letters: DeadLetters,
) -> Result(#(List(DeadLetter), List(String)), String) {
  use keys <- result.try(letters.keys())

  let #(found, failed) =
    keys
    |> list.sort(compare_keys)
    |> list.fold(#([], []), fn(acc, key) {
      let #(found, failed) = acc
      case read(letters, key) {
        Ok(letter) -> #([letter, ..found], failed)
        Error(reason) -> #(found, [key <> ": " <> reason, ..failed])
      }
    })

  Ok(#(list.reverse(found), list.reverse(failed)))
}

/// Read one letter back by its storage key.
pub fn read(
  letters letters: DeadLetters,
  key key: String,
) -> Result(DeadLetter, String) {
  use stored <- result.try(letters.read(key))
  use raw <- result.try(option.to_result(stored, "not found"))
  use decoded <- result.try(
    json.parse(raw, envelope_decoder())
    |> result.map_error(string.inspect),
  )
  let #(reason, update) = decoded
  Ok(DeadLetter(key:, update:, reason:))
}

/// Forget one letter.
pub fn drop(
  letters letters: DeadLetters,
  key key: String,
) -> Result(Nil, String) {
  letters.drop(key)
}

fn envelope_decoder() -> decode.Decoder(#(String, RawUpdate)) {
  use reason <- decode.field("reason", decode.string)
  use update <- decode.field("update", decoder.update_decoder())
  decode.success(#(reason, update))
}

/// Sort by the numeric `update_id` rather than by the key's text, so `dlq:9`
/// comes before `dlq:10` — replay order is the order Telegram sent them in.
fn compare_keys(left: String, right: String) -> order.Order {
  int.compare(key_id(left), key_id(right))
}

fn key_id(key: String) -> Int {
  key
  |> string.drop_start(string.length(prefix))
  |> int.parse
  |> result.unwrap(0)
}
