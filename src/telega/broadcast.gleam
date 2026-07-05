//// Mass messaging with pacing, result classification and reports —
//// the answer to "how do I send a message to all my users?" without
//// tripping over Telegram's rate limits or losing track of who
//// actually got the message.
////
//// A broadcast sends to a list (or a stream) of chat ids sequentially,
//// paced below Telegram's limit, and classifies every result:
////
//// - `sent` — delivered, with the value returned by the send function
//// - `blocked` — HTTP 403: the user blocked the bot, was deactivated,
////   or kicked the bot
//// - `failed` — everything else after retries
////
//// ```gleam
//// import telega/broadcast
////
//// let assert Ok(report) =
////   broadcast.send_text(client:, chat_ids:, text: "Big news!")
////   |> broadcast.run
////
//// // 403s are users who blocked the bot — stop sending to them
//// mark_as_dead(report.blocked)
//// ```
////
//// ## Telegram's limits
////
//// Telegram allows bots roughly **30 messages per second** across all
//// chats (and ~20 messages per minute into the same group). Exceeding
//// it earns HTTP 429 responses and, if you keep pushing, longer and
//// longer cooldowns.
////
//// The broadcast default is **25 messages per 1000 ms** — a deliberate
//// safety margin. Tune it with `with_rate`:
////
//// ```gleam
//// broadcast.send_text(client:, chat_ids:, text:)
//// |> broadcast.with_rate(rate: 20, window_ms: 1000)
//// |> broadcast.run
//// ```
////
//// If the client also has a request queue configured
//// (`client.new_with_queue` / `client.set_request_queue`), broadcast
//// calls go through it too, so the effective rate is the **min** of the
//// two limits. The broadcast's own pacing exists so that mass sends are
//// throttled even on clients without a queue — and so a broadcast never
//// starves interactive traffic by monopolizing the queue's default rule.
////
//// On 429: the client itself retries honoring `parameters.retry_after`.
//// A 429 that still reaches the broadcast means Telegram is pushing back
//// hard — the broadcast pauses for one full window and retries that
//// chat id **once**, then reports it as `failed`.
////
//// ## Custom payloads
////
//// `send_text` is a convenience over `api.send_message`. For anything
//// else — photos, invoices, per-user personalization — pass your own
//// send function:
////
//// ```gleam
//// let send_promo = fn(client, chat_id) {
////   api.send_photo(client, parameters: promo_photo_for(chat_id))
//// }
////
//// let assert Ok(report) =
////   broadcast.new(client:, chat_ids:, send: send_promo)
////   |> broadcast.run
//// ```
////
//// The function's success value ends up in `report.sent`, so you can
//// keep the returned `Message` for later edits or deletion.
////
//// Sends are sequential by design: one send at a time, inside the
//// broadcast actor. Concurrency would break pacing.
////
//// ## Streaming recipients from a database
////
//// For large audiences, don't load every chat id into memory — stream
//// them in chunks. The broadcast pulls the next chunk when the current
//// one is exhausted; return `None` (or an empty chunk) to signal the
//// end:
////
//// ```gleam
//// let next_page = fn() {
////   case load_subscriber_page(db) {
////     [] -> None
////     chat_ids -> Some(chat_ids)
////   }
//// }
////
//// let assert Ok(report) =
////   broadcast.new_from_iterator(client:, next_chunk: next_page, send: send_promo)
////   |> broadcast.run
//// ```
////
//// With an iterator source, `BroadcastProgress.total` is `None` — the
//// size is unknown upfront.
////
//// ## Background broadcasts: progress and cancellation
////
//// `run` is fine for scripts. In a bot you usually want to start the
//// broadcast, answer the admin immediately, and check on it later:
////
//// ```gleam
//// let assert Ok(handle) =
////   broadcast.send_text(client:, chat_ids:, text:)
////   |> broadcast.start
////
//// // From any process, at any time:
//// let progress = broadcast.progress(handle)
//// broadcast.cancel(handle)
//// let assert Ok(report) = broadcast.await(handle, timeout: 60_000)
//// ```
////
//// For live progress messages ("Sending… 250/1000"), register a
//// callback with `with_on_progress`. It runs inside the broadcast actor
//// after every processed chat id — keep it cheap, a slow callback slows
//// the whole broadcast down.
////
//// ## Blocked-user hygiene
////
//// A 403 (`Forbidden: bot was blocked by the user` and friends) is
//// permanent until the user comes back on their own. Every broadcast to
//// a dead chat id wastes your rate budget, so treat `report.blocked` as
//// a to-do list: mark those chat ids as inactive in your storage,
//// exclude them from future broadcasts, and re-activate a user when
//// they message the bot again (`/start`).
////
//// `failed` is different — those are transient errors (network,
//// server-side 5xx, a 429 that survived retries). Keep those ids and
//// retry them in a later broadcast.

import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string

import telega/api
import telega/client.{type TelegramClient}
import telega/error.{type TelegaError}
import telega/internal/utils
import telega/model/types.{type Message, SendMessageParameters}

/// Default pacing: 25 sends per 1000 ms — a safety margin below
/// Telegram's ~30 messages per second bot-wide limit.
const default_rate = 25

const default_window_ms = 1000

/// A configured broadcast, ready to `start` or `run`.
pub opaque type Broadcast(a) {
  Broadcast(
    client: TelegramClient,
    source: Source,
    send: fn(TelegramClient, Int) -> Result(a, TelegaError),
    rate: Int,
    window_ms: Int,
    on_progress: Option(fn(BroadcastProgress) -> Nil),
  )
}

type Source {
  ChatIdList(chat_ids: List(Int))
  ChunkIterator(next_chunk: fn() -> Option(List(Int)), buffer: List(Int))
}

/// Snapshot of a running (or finished) broadcast.
pub type BroadcastProgress {
  BroadcastProgress(
    /// Total number of recipients. `None` for iterator sources —
    /// the size is not known upfront.
    total: Option(Int),
    /// Number of processed chat ids: `sent + blocked + failed`.
    done: Int,
    sent: Int,
    blocked: Int,
    failed: Int,
  )
}

/// Final report of a broadcast, in recipient order.
pub type BroadcastReport(a) {
  BroadcastReport(
    /// Successfully delivered, with the send function's return value.
    sent: List(#(Int, a)),
    /// HTTP 403: bot blocked / kicked / user deactivated.
    blocked: List(Int),
    /// Everything else after retries.
    failed: List(#(Int, TelegaError)),
    duration_ms: Int,
    /// `True` if the broadcast was stopped via `cancel`;
    /// remaining recipients were not contacted.
    cancelled: Bool,
  )
}

/// Handle to a started broadcast, safe to share between processes.
pub opaque type BroadcastHandle(a) {
  BroadcastHandle(actor: Subject(Msg(a)))
}

/// Create a broadcast for a known list of chat ids.
///
/// The send function is called once per chat id (twice on a 429 that
/// survived the client's retries) inside the broadcast actor.
pub fn new(
  client client: TelegramClient,
  chat_ids chat_ids: List(Int),
  send send: fn(TelegramClient, Int) -> Result(a, TelegaError),
) -> Broadcast(a) {
  Broadcast(
    client:,
    source: ChatIdList(chat_ids),
    send:,
    rate: default_rate,
    window_ms: default_window_ms,
    on_progress: None,
  )
}

/// Create a broadcast that pulls chat ids in chunks — for streaming
/// millions of recipients from a database without loading them all
/// into memory.
///
/// The next chunk is requested (inside the broadcast actor) when the
/// current one is exhausted. Return `None` — or an empty chunk — to
/// signal the end of the stream.
pub fn new_from_iterator(
  client client: TelegramClient,
  next_chunk next_chunk: fn() -> Option(List(Int)),
  send send: fn(TelegramClient, Int) -> Result(a, TelegaError),
) -> Broadcast(a) {
  Broadcast(
    client:,
    source: ChunkIterator(next_chunk:, buffer: []),
    send:,
    rate: default_rate,
    window_ms: default_window_ms,
    on_progress: None,
  )
}

/// Convenience broadcast sending the same text to every chat id
/// via `sendMessage`.
pub fn send_text(
  client client: TelegramClient,
  chat_ids chat_ids: List(Int),
  text text: String,
) -> Broadcast(Message) {
  new(client:, chat_ids:, send: fn(client, chat_id) {
    api.send_message(
      client,
      parameters: SendMessageParameters(
        text:,
        chat_id: types.Int(chat_id),
        business_connection_id: None,
        message_thread_id: None,
        parse_mode: None,
        entities: None,
        link_preview_options: None,
        disable_notification: None,
        protect_content: None,
        message_effect_id: None,
        allow_paid_broadcast: None,
        reply_parameters: None,
        reply_markup: None,
      ),
    )
  })
}

/// Set the pacing: at most `rate` sends per `window_ms` milliseconds.
/// Default is 25 per 1000 ms. Values below 1 are clamped to 1.
pub fn with_rate(
  broadcast broadcast: Broadcast(a),
  rate rate: Int,
  window_ms window_ms: Int,
) -> Broadcast(a) {
  Broadcast(
    ..broadcast,
    rate: int.max(rate, 1),
    window_ms: int.max(window_ms, 1),
  )
}

/// Set a progress callback, called from the broadcast actor after every
/// processed chat id. Keep it cheap — a slow callback slows the broadcast.
pub fn with_on_progress(
  broadcast broadcast: Broadcast(a),
  on_progress on_progress: fn(BroadcastProgress) -> Nil,
) -> Broadcast(a) {
  Broadcast(..broadcast, on_progress: Some(on_progress))
}

/// Start the broadcast in a background actor and return a handle.
pub fn start(
  broadcast broadcast: Broadcast(a),
) -> Result(BroadcastHandle(a), TelegaError) {
  let Broadcast(client:, source:, send:, rate:, window_ms:, on_progress:) =
    broadcast

  let total = case source {
    ChatIdList(chat_ids) -> Some(list.length(chat_ids))
    ChunkIterator(..) -> None
  }

  actor.new_with_initialiser(1000, fn(self) {
    let now = utils.current_time_ms()
    let initial_state =
      State(
        client:,
        source:,
        send:,
        rate:,
        window_ms:,
        on_progress:,
        total:,
        retry_chat: None,
        sent: [],
        blocked: [],
        failed: [],
        window_start: now,
        window_count: 0,
        started_at: now,
        awaiters: [],
        report: None,
        self:,
      )

    process.send(self, SendNext)

    actor.initialised(initial_state)
    |> actor.returning(self)
    |> Ok
  })
  |> actor.on_message(handle_message)
  |> actor.start
  |> result.map(fn(started) { BroadcastHandle(started.data) })
  |> result.map_error(fn(reason) {
    error.ActorError("Failed to start broadcast: " <> string.inspect(reason))
  })
}

/// Wait for the broadcast to finish and return the report.
/// Returns an error if it does not finish within `timeout` milliseconds
/// (the broadcast itself keeps running).
pub fn await(
  handle handle: BroadcastHandle(a),
  timeout timeout: Int,
) -> Result(BroadcastReport(a), TelegaError) {
  let reply_subject = process.new_subject()
  process.send(handle.actor, Await(reply_subject))

  process.receive(reply_subject, timeout)
  |> result.map_error(fn(_) { error.ActorError("Broadcast await timed out") })
}

/// Stop the broadcast. Recipients not yet contacted stay untouched,
/// the report is finalized with `cancelled: True`. Cancelling a finished
/// broadcast is a no-op.
pub fn cancel(handle handle: BroadcastHandle(a)) -> Nil {
  process.send(handle.actor, Cancel)
}

/// Get a progress snapshot of the broadcast.
pub fn progress(handle handle: BroadcastHandle(a)) -> BroadcastProgress {
  let reply_subject = process.new_subject()
  process.send(handle.actor, GetProgress(reply_subject))

  case process.receive(reply_subject, 1000) {
    Ok(progress) -> progress
    Error(_) ->
      BroadcastProgress(total: None, done: 0, sent: 0, blocked: 0, failed: 0)
  }
}

/// Run the broadcast to completion: `start` + `await` forever.
/// Convenient for scripts and one-off jobs.
pub fn run(
  broadcast broadcast: Broadcast(a),
) -> Result(BroadcastReport(a), TelegaError) {
  use handle <- result.try(start(broadcast))

  let reply_subject = process.new_subject()
  process.send(handle.actor, Await(reply_subject))

  Ok(process.receive_forever(reply_subject))
}

type Msg(a) {
  SendNext
  Cancel
  GetProgress(reply_to: Subject(BroadcastProgress))
  Await(reply_to: Subject(BroadcastReport(a)))
}

type State(a) {
  State(
    client: TelegramClient,
    source: Source,
    send: fn(TelegramClient, Int) -> Result(a, TelegaError),
    rate: Int,
    window_ms: Int,
    on_progress: Option(fn(BroadcastProgress) -> Nil),
    total: Option(Int),
    /// Chat id that got a 429 and waits for its single retry.
    retry_chat: Option(Int),
    /// Accumulated in reverse order, reversed in the final report.
    sent: List(#(Int, a)),
    blocked: List(Int),
    failed: List(#(Int, TelegaError)),
    window_start: Int,
    window_count: Int,
    started_at: Int,
    awaiters: List(Subject(BroadcastReport(a))),
    report: Option(BroadcastReport(a)),
    self: Subject(Msg(a)),
  )
}

fn handle_message(
  state: State(a),
  message: Msg(a),
) -> actor.Next(State(a), Msg(a)) {
  case message {
    SendNext -> handle_send_next(state)

    Cancel ->
      case state.report {
        Some(_) -> actor.continue(state)
        None -> finish(state, cancelled: True)
      }

    GetProgress(reply_to) -> {
      process.send(reply_to, progress_of(state))
      actor.continue(state)
    }

    Await(reply_to) ->
      case state.report {
        Some(report) -> {
          process.send(reply_to, report)
          actor.continue(state)
        }
        None ->
          actor.continue(State(..state, awaiters: [reply_to, ..state.awaiters]))
      }
  }
}

fn handle_send_next(state: State(a)) -> actor.Next(State(a), Msg(a)) {
  case state.report {
    Some(_) -> actor.continue(state)
    None -> {
      let now = utils.current_time_ms()
      let state = case now - state.window_start >= state.window_ms {
        True -> State(..state, window_start: now, window_count: 0)
        False -> state
      }

      case state.window_count >= state.rate {
        // Window budget exhausted — wake up when the window rolls over
        True -> {
          let wait = state.window_start + state.window_ms - now
          process.send_after(state.self, int.max(wait, 1), SendNext)
          actor.continue(state)
        }
        False ->
          case next_chat_id(state) {
            #(None, state) -> finish(state, cancelled: False)
            #(Some(chat_id), state) -> send_to_chat(state, chat_id)
          }
      }
    }
  }
}

fn next_chat_id(state: State(a)) -> #(Option(Int), State(a)) {
  case state.retry_chat {
    Some(chat_id) -> #(Some(chat_id), state)
    None -> {
      let #(chat_id, source) = pull(state.source)
      #(chat_id, State(..state, source:))
    }
  }
}

fn pull(source: Source) -> #(Option(Int), Source) {
  case source {
    ChatIdList([]) -> #(None, source)
    ChatIdList([chat_id, ..rest]) -> #(Some(chat_id), ChatIdList(rest))
    ChunkIterator(next_chunk:, buffer: [chat_id, ..rest]) -> #(
      Some(chat_id),
      ChunkIterator(next_chunk:, buffer: rest),
    )
    ChunkIterator(next_chunk:, buffer: []) ->
      case next_chunk() {
        Some([chat_id, ..rest]) -> #(
          Some(chat_id),
          ChunkIterator(next_chunk:, buffer: rest),
        )
        Some([]) | None -> #(None, source)
      }
  }
}

fn send_to_chat(state: State(a), chat_id: Int) -> actor.Next(State(a), Msg(a)) {
  let is_retry = state.retry_chat == Some(chat_id)
  let state =
    State(..state, retry_chat: None, window_count: state.window_count + 1)

  case state.send(state.client, chat_id) {
    Ok(value) -> record(State(..state, sent: [#(chat_id, value), ..state.sent]))

    Error(error.TelegramApiError(403, _)) ->
      record(State(..state, blocked: [chat_id, ..state.blocked]))

    Error(error.TelegramApiError(429, description)) ->
      case is_retry {
        // A 429 that survived the client's own retries: pause for a full
        // window and retry this chat id once
        False -> {
          let state = State(..state, retry_chat: Some(chat_id))
          process.send_after(state.self, state.window_ms, SendNext)
          actor.continue(state)
        }
        True ->
          record(
            State(..state, failed: [
              #(chat_id, error.TelegramApiError(429, description)),
              ..state.failed
            ]),
          )
      }

    Error(reason) ->
      record(State(..state, failed: [#(chat_id, reason), ..state.failed]))
  }
}

fn record(state: State(a)) -> actor.Next(State(a), Msg(a)) {
  case state.on_progress {
    Some(on_progress) -> on_progress(progress_of(state))
    None -> Nil
  }

  process.send(state.self, SendNext)
  actor.continue(state)
}

fn finish(
  state: State(a),
  cancelled cancelled: Bool,
) -> actor.Next(State(a), Msg(a)) {
  let report =
    BroadcastReport(
      sent: list.reverse(state.sent),
      blocked: list.reverse(state.blocked),
      failed: list.reverse(state.failed),
      duration_ms: utils.current_time_ms() - state.started_at,
      cancelled:,
    )

  list.each(state.awaiters, process.send(_, report))
  actor.continue(State(..state, report: Some(report), awaiters: []))
}

fn progress_of(state: State(a)) -> BroadcastProgress {
  let sent = list.length(state.sent)
  let blocked = list.length(state.blocked)
  let failed = list.length(state.failed)

  BroadcastProgress(
    total: state.total,
    done: sent + blocked + failed,
    sent:,
    blocked:,
    failed:,
  )
}
