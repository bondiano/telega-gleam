//// Keeps a chat action indicator ("typing…", "sending photo…") alive while
//// a long-running handler executes.
////
//// Telegram clears a chat action after ~5 seconds, so a single
//// `api.send_chat_action` call is not enough for slow handlers. `with_action`
//// re-sends the action every ~4 seconds until the wrapped function returns:
////
//// ```gleam
//// import telega/chat_action
////
//// fn handler(ctx, _) {
////   use <- chat_action.with_action(ctx, chat_action.Typing)
////   // ... long-running work: LLM call, file processing, etc.
////   reply.with_text(ctx, "Done!")
//// }
//// ```
////
//// The repeating sender runs in an unlinked worker process that monitors the
//// caller: it stops when the wrapped function returns *or* when the calling
//// process dies, so no processes are leaked even if the handler crashes.

import gleam/erlang/process
import gleam/int
import gleam/option.{None}

import telega/api
import telega/bot.{type Context}
import telega/model/types.{SendChatActionParameters, Str}

/// Chat action to broadcast, mirrors [`ChatAction`](https://core.telegram.org/bots/api#sendchataction).
pub type Action {
  Typing
  UploadPhoto
  RecordVideo
  UploadVideo
  RecordVoice
  UploadVoice
  UploadDocument
  ChooseSticker
  FindLocation
  RecordVideoNote
  UploadVideoNote
}

type WorkerMessage {
  StopWorker
}

const default_interval = 4000

/// Sends `action` immediately and then re-sends it every ~4 seconds while
/// `run` executes. Returns the result of `run`.
///
/// ```gleam
/// use <- chat_action.with_action(ctx, chat_action.Typing)
/// slow_work(ctx)
/// ```
pub fn with_action(
  ctx ctx: Context(session, error, dependencies),
  action action: Action,
  run run: fn() -> a,
) -> a {
  with_action_every(ctx:, action:, interval: default_interval, run:)
}

/// Same as `with_action` but with a custom re-send interval in milliseconds.
/// Useful for tests and for long uploads where a different cadence is needed.
pub fn with_action_every(
  ctx ctx: Context(session, error, dependencies),
  action action: Action,
  interval interval: Int,
  run run: fn() -> a,
) -> a {
  let client = ctx.config.api_client
  let parameters =
    SendChatActionParameters(
      chat_id: Str(ctx.key),
      business_connection_id: None,
      message_thread_id: None,
      action: to_model_action(action),
    )
  let _ = api.send_chat_action(client:, parameters:)

  let interval = int.max(interval, 1)
  let caller = process.self()
  let handshake = process.new_subject()

  process.spawn_unlinked(fn() {
    let stop = process.new_subject()
    process.send(handshake, stop)
    let monitor = process.monitor(caller)
    let selector =
      process.new_selector()
      |> process.select(stop)
      |> process.select_specific_monitor(monitor, fn(_down) { StopWorker })
    worker_loop(client, parameters, interval, selector)
  })

  let stop = process.receive(handshake, 1000)
  let result = run()
  case stop {
    Ok(stop) -> process.send(stop, StopWorker)
    Error(Nil) -> Nil
  }
  result
}

fn worker_loop(
  client,
  parameters,
  interval: Int,
  selector: process.Selector(WorkerMessage),
) -> Nil {
  case process.selector_receive(from: selector, within: interval) {
    Ok(StopWorker) -> Nil
    Error(Nil) -> {
      let _ = api.send_chat_action(client:, parameters:)
      worker_loop(client, parameters, interval, selector)
    }
  }
}

fn to_model_action(action: Action) -> types.ChatAction {
  case action {
    Typing -> types.Typing
    UploadPhoto -> types.UploadPhoto
    RecordVideo -> types.RecordVideo
    UploadVideo -> types.UploadVideo
    RecordVoice -> types.RecordVoice
    UploadVoice -> types.UploadVoice
    UploadDocument -> types.UploadDocument
    ChooseSticker -> types.ChooseSticker
    FindLocation -> types.FindLocation
    RecordVideoNote -> types.RecordVideoNote
    UploadVideoNote -> types.UploadVideoNote
  }
}
