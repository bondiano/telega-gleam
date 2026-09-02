//// Long polling implementation for Telegram Bot API.
////
//// This module provides long polling as an alternative to webhooks for receiving updates.
//// A polling worker actor continuously fetches updates from Telegram and dispatches them
//// to the bot's message handlers.
////
//// ## Supervised mode (recommended)
////
//// When using `telega.init_for_polling()`, the polling worker is automatically started
//// inside the supervision tree as a `Permanent` child. No manual setup is needed:
////
//// ```gleam
//// let assert Ok(_bot) =
////   telega.new_for_polling(token: "BOT_TOKEN")
////   |> telega.with_router(router)
////   |> telega.init_for_polling_nil_session()
////
//// process.sleep_forever()
//// ```
////
//// Use `telega.with_polling_config()` on the builder to customize timeout, limit,
//// and poll interval before calling `init_for_polling()`.
////
//// ## Manual mode
////
//// For advanced use cases (custom offsets, separate lifecycle management),
//// start polling manually:
////
//// ```gleam
//// let assert Ok(poller) =
////   polling.start_polling_default(
////     client: telega.get_api_config(bot),
////     bot: telega.get_bot_subject_internal(bot),
////   )
//// ```
////
//// ## Concurrency and backpressure
////
//// Updates are dispatched to the bot without waiting for their handlers to
//// finish, so a slow handler in one chat never holds up another chat or the
//// next `getUpdates`. Ordering is preserved: the poller sends updates in the
//// order Telegram returned them, and each chat has a single actor, so updates
//// of the *same* chat are still handled one after another.
////
//// To keep a burst from piling up without bound, the worker stops fetching
//// once `limit` updates are in flight and resumes as soon as one settles —
//// i.e. at most one `getUpdates` batch is being handled at a time. Tune it
//// with `telega.with_polling_config(limit:)`.
////
//// ## Error handling
////
//// The polling worker uses exponential backoff for transient errors (network issues,
//// rate limits, server errors). Critical errors (invalid token, bot deleted, or
//// 10+ consecutive failures) stop polling and invoke the optional `on_stop` callback.

import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/supervision
import gleam/result
import gleam/string

import telega/api
import telega/bot.{type BotSubject}
import telega/client.{type TelegramClient}
import telega/error.{type TelegaError, FetchError}
import telega/internal/log
import telega/model/types.{type Update, GetUpdatesParameters}
import telega/update as update_module

/// Threshold for logging persistent timeout issues
const persistent_timeout_threshold = 10

/// Internal configuration for the polling system
type PollingConfig {
  PollingConfig(
    client: TelegramClient,
    bot: BotSubject,
    timeout: Int,
    limit: Int,
    allowed_updates: List(String),
    poll_interval: Int,
    on_stop: Option(fn(TelegaError) -> Nil),
  )
}

/// Opaque type representing a running poller instance
pub opaque type Poller {
  Poller(
    worker: Subject(PollingMessage),
    config: PollingConfig,
    status: PollerStatus,
  )
}

/// Status of the poller
pub type PollerStatus {
  Starting
  Running
  Stopped
  Failed(String)
}

/// Internal function to create default polling configuration
fn create_config(
  client: TelegramClient,
  bot: BotSubject,
  timeout: Int,
  limit: Int,
  allowed_updates: List(String),
  poll_interval: Int,
  on_stop: Option(fn(TelegaError) -> Nil),
) -> PollingConfig {
  PollingConfig(
    client:,
    bot:,
    timeout:,
    limit:,
    allowed_updates:,
    poll_interval:,
    on_stop:,
  )
}

/// Messages for the polling worker actor
pub type PollingMessage {
  StartPolling(offset: Option(Int))
  StopPolling
  PollNext(offset: Int)
  InjectUpdates(updates: List(Update), offset: Int)
  SetSelf(subject: Subject(PollingMessage))
  HandleError(error: TelegaError, offset: Int)
  /// One dispatched update has settled (handled, failed, or its chat instance
  /// died), freeing an in-flight slot. Produced from the bot's answers.
  UpdateSettled
  /// Backstop for a pause that never got its slots back: resume intake anyway.
  CapacityTimeout(offset: Int, epoch: Int)
}

/// State for the polling worker
type PollingState {
  PollingState(
    config: PollingConfig,
    offset: Option(Int),
    is_running: Bool,
    self: Option(Subject(PollingMessage)),
    consecutive_errors: Int,
    // Subject the bot answers on once a dispatched update settles. Selected
    // into the actor's own message type as `UpdateSettled`.
    ack: Subject(Bool),
    // Updates dispatched to the bot that have not settled yet.
    in_flight: Int,
    // Offset to poll from once capacity frees up, when intake is paused.
    paused: Option(Int),
    // Bumped on every pause so a stale `CapacityTimeout` is ignored.
    pause_epoch: Int,
  )
}

/// How many updates the poller keeps in flight before it stops fetching more.
///
/// Bounded by the batch size, so at most one `getUpdates` batch is being
/// handled at a time — tune it with `telega.with_polling_config(limit:)`.
fn max_in_flight(config: PollingConfig) -> Int {
  int.max(1, config.limit)
}

fn init_state(
  config: PollingConfig,
  self: Subject(PollingMessage),
  ack: Subject(Bool),
) -> PollingState {
  PollingState(
    config:,
    offset: None,
    is_running: False,
    self: Some(self),
    consecutive_errors: 0,
    ack:,
    in_flight: 0,
    paused: None,
    pause_epoch: 0,
  )
}

fn polling_selector(
  self: Subject(PollingMessage),
  ack: Subject(Bool),
) -> process.Selector(PollingMessage) {
  process.new_selector()
  |> process.select(self)
  |> process.select_map(ack, fn(_settled) { UpdateSettled })
}

fn send_self(state: PollingState, message: PollingMessage) -> Nil {
  case state.self {
    Some(self) -> process.send(self, message)
    None -> log.error("No self reference available for polling")
  }
}

/// Start the polling worker actor
fn start_polling_worker(
  config: PollingConfig,
) -> Result(Subject(PollingMessage), actor.StartError) {
  use started <- result.try(
    actor.new_with_initialiser(worker_init_timeout, fn(self) {
      let ack = process.new_subject()
      init_state(config, self, ack)
      |> actor.initialised
      |> actor.selecting(polling_selector(self, ack))
      |> actor.returning(self)
      |> Ok
    })
    |> actor.on_message(handle_polling_message)
    |> actor.start(),
  )

  Ok(started.data)
}

const worker_init_timeout = 1000

/// Create a `ChildSpecification` for running polling inside a supervision tree.
/// The polling worker will automatically delete the webhook and start polling.
pub fn supervised(
  client client: TelegramClient,
  bot bot: BotSubject,
  timeout timeout: Int,
  limit limit: Int,
  allowed_updates allowed_updates: List(String),
  poll_interval poll_interval: Int,
  on_stop on_stop: Option(fn(TelegaError) -> Nil),
  name name: process.Name(PollingMessage),
) -> supervision.ChildSpecification(Subject(PollingMessage)) {
  supervision.worker(fn() {
    let config =
      create_config(
        client,
        bot,
        timeout,
        limit,
        allowed_updates,
        poll_interval,
        on_stop,
      )
    use _ <- result.try(
      api.delete_webhook(config.client)
      |> result.map_error(fn(err) { actor.InitFailed(error.to_string(err)) }),
    )

    use started <- result.try(
      actor.new_with_initialiser(worker_init_timeout, fn(self) {
        let ack = process.new_subject()
        init_state(config, self, ack)
        |> actor.initialised
        |> actor.selecting(polling_selector(self, ack))
        |> actor.returning(self)
        |> Ok
      })
      |> actor.on_message(handle_polling_message)
      |> actor.named(name)
      |> actor.start(),
    )

    process.send(started.data, StartPolling(None))
    Ok(started)
  })
  |> supervision.restart(supervision.Permanent)
}

/// Stop a supervised polling worker by its subject.
///
/// Sends `StopPolling`, which makes the worker stop fetching new updates after
/// its current batch. Used by graceful shutdown to halt intake before draining.
pub fn stop_worker(worker worker: Subject(PollingMessage)) -> Nil {
  process.send(worker, StopPolling)
}

/// Handle messages in the polling worker
fn handle_polling_message(
  state: PollingState,
  message: PollingMessage,
) -> actor.Next(PollingState, PollingMessage) {
  case message {
    SetSelf(subject) -> {
      actor.continue(PollingState(..state, self: Some(subject)))
    }

    StartPolling(offset) -> {
      let new_state = PollingState(..state, offset:, is_running: True)

      case state.self {
        Some(self) -> {
          process.send(self, PollNext(option.unwrap(offset, 0)))
        }
        None -> {
          log.error("No self reference available for polling")
        }
      }

      actor.continue(new_state)
    }

    StopPolling -> {
      actor.continue(PollingState(..state, is_running: False))
    }

    PollNext(offset) -> {
      case state.is_running {
        False -> actor.continue(state)
        True ->
          case state.in_flight >= max_in_flight(state.config) {
            True -> pause_for_capacity(state, offset)
            False -> poll_now(state, offset)
          }
      }
    }

    UpdateSettled -> {
      let in_flight = int.max(0, state.in_flight - 1)
      let state = PollingState(..state, in_flight:)
      let capacity = max_in_flight(state.config)
      case state.paused {
        Some(offset) if in_flight < capacity -> {
          let state = PollingState(..state, paused: None)
          send_self(state, PollNext(offset))
          actor.continue(state)
        }
        _ -> actor.continue(state)
      }
    }

    CapacityTimeout(offset:, epoch:) -> {
      let stale = state.pause_epoch != epoch
      case state.paused {
        Some(_) if !stale -> {
          log.warning(
            "Polling stalled: "
            <> string.inspect(state.in_flight)
            <> " dispatched update(s) never settled — resuming intake",
          )
          let state = PollingState(..state, paused: None, in_flight: 0)
          send_self(state, PollNext(offset))
          actor.continue(state)
        }
        _ -> actor.continue(state)
      }
    }

    InjectUpdates(updates, offset) -> {
      let dispatched = dispatch_updates(state, updates)
      let new_offset = calculate_new_offset(updates, offset)
      actor.continue(
        PollingState(
          ..state,
          offset: Some(new_offset),
          in_flight: state.in_flight + dispatched,
        ),
      )
    }

    HandleError(error, offset) -> {
      let new_consecutive_errors = state.consecutive_errors + 1

      // Error handling strategy:
      // - Critical errors (auth, not found, etc.) stop polling immediately
      // - Network/temporary errors retry with exponential backoff
      // - After 10 consecutive errors of any type, stop polling
      let should_stop = case error {
        // API errors with specific codes that indicate critical issues
        error.TelegramApiError(401, _) -> True
        // Unauthorized - invalid token
        error.TelegramApiError(404, _) -> True

        // Not found - bot deleted
        // Too many consecutive errors of any type
        _ if new_consecutive_errors >= 10 -> True

        // Network and temporary errors are recoverable
        error.FetchError(_) -> False
        error.TelegramApiError(429, _) -> False
        // Rate limit
        error.TelegramApiError(500, _) -> False
        // Server error
        error.TelegramApiError(502, _) -> False
        // Bad gateway
        error.TelegramApiError(503, _) -> False
        // Service unavailable
        error.JsonDecodeError(_) -> False

        // Might be temporary API issue
        // Other errors are considered critical
        _ -> True
      }

      case should_stop {
        True -> {
          log.error(
            "Critical polling error (consecutive: "
            <> string.inspect(new_consecutive_errors)
            <> "): "
            <> error.to_string(error)
            <> " - stopping polling",
          )
          case state.config.on_stop {
            Some(callback) -> callback(error)
            None -> Nil
          }
          actor.stop()
        }
        False -> {
          // Only log non-timeout errors or persistent timeout issues
          // Timeouts are normal for long polling when there are no updates
          let is_timeout = case error {
            FetchError(msg) ->
              string.contains(msg, "ResponseTimeout")
              || string.contains(msg, "Timeout")
            _ -> False
          }

          case is_timeout {
            True -> {
              // Timeouts are expected in long polling - only log if persistent
              case new_consecutive_errors > persistent_timeout_threshold {
                True ->
                  log.warning(
                    "Persistent timeout issues detected (count: "
                    <> string.inspect(new_consecutive_errors)
                    <> ")",
                  )
                False -> Nil
              }
            }
            False -> {
              // Log actual errors (not timeouts)
              log.error(
                "Polling error (consecutive: "
                <> string.inspect(new_consecutive_errors)
                <> "): "
                <> error.to_string(error)
                <> " - retrying",
              )
            }
          }

          // Exponential backoff for retries
          let delay = case new_consecutive_errors {
            n if n <= 3 -> 1000
            // 1 second for first 3 errors
            n if n <= 6 -> 5000
            // 5 seconds for next 3 errors
            _ -> 10_000
            // 10 seconds for remaining errors
          }

          case state.self {
            Some(self) -> {
              process.send_after(self, delay, PollNext(offset))
              Nil
            }
            None -> Nil
          }

          actor.continue(
            PollingState(..state, consecutive_errors: new_consecutive_errors),
          )
        }
      }
    }
  }
}

/// Stop fetching until dispatched updates settle. Schedules a one-shot backstop
/// so a handler that never answers cannot silence the poller for good.
fn pause_for_capacity(
  state: PollingState,
  offset: Int,
) -> actor.Next(PollingState, PollingMessage) {
  case state.paused {
    Some(_) -> actor.continue(state)
    None -> {
      let epoch = state.pause_epoch + 1
      let state =
        PollingState(..state, paused: Some(offset), pause_epoch: epoch)
      case state.self {
        Some(self) -> {
          process.send_after(
            self,
            bot.update_dispatch_timeout,
            CapacityTimeout(offset:, epoch:),
          )
          Nil
        }
        None -> Nil
      }
      actor.continue(state)
    }
  }
}

fn poll_now(
  state: PollingState,
  offset: Int,
) -> actor.Next(PollingState, PollingMessage) {
  case poll_updates(state, offset) {
    Ok(#(new_offset, dispatched)) -> {
      schedule_next_poll(state, new_offset)
      actor.continue(
        PollingState(
          ..state,
          offset: Some(new_offset),
          consecutive_errors: 0,
          in_flight: state.in_flight + dispatched,
        ),
      )
    }
    Error(error) -> {
      send_self(state, HandleError(error, offset))
      actor.continue(state)
    }
  }
}

/// Poll for updates and dispatch them. Returns the next offset and how many
/// updates were dispatched (and are therefore in flight).
fn poll_updates(
  state: PollingState,
  offset: Int,
) -> Result(#(Int, Int), TelegaError) {
  let parameters =
    GetUpdatesParameters(
      offset: Some(offset),
      limit: Some(state.config.limit),
      timeout: Some(state.config.timeout),
      allowed_updates: case state.config.allowed_updates {
        [] -> None
        updates -> Some(updates)
      },
    )

  use updates <- result.try(api.get_updates(
    state.config.client,
    Some(parameters),
  ))

  let dispatched = dispatch_updates(state, updates)

  Ok(#(calculate_new_offset(updates, offset), dispatched))
}

/// Hand every update to the bot without waiting for it to be handled, so a slow
/// handler in one chat cannot hold up other chats or the next `getUpdates`.
/// Sends stay in poller order, so updates of the same chat keep their order.
fn dispatch_updates(state: PollingState, updates: List(Update)) -> Int {
  list.each(updates, fn(update) {
    process_update(state.config.bot, state.ack, update)
  })
  list.length(updates)
}

/// Calculate the next offset based on received updates
pub fn calculate_new_offset(updates: List(Update), current_offset: Int) -> Int {
  case updates {
    [] -> current_offset
    _ -> {
      case list.last(updates) {
        Ok(update) -> update.update_id + 1
        Error(_) -> current_offset
      }
    }
  }
}

/// Convert a raw update and dispatch it to the bot. The bot answers `ack` once
/// the update settles, which is what keeps the in-flight count honest.
fn process_update(
  bot_subject: BotSubject,
  ack: Subject(Bool),
  update: Update,
) -> Nil {
  bot.dispatch_update(
    bot_subject:,
    update: update_module.raw_to_update(update),
    reply_with: ack,
  )
}

/// Schedule the next poll
fn schedule_next_poll(state: PollingState, offset: Int) -> Nil {
  let delay = case state.config.timeout {
    0 -> state.config.poll_interval
    _ -> 10
  }

  case state.self {
    Some(self) -> {
      process.send_after(self, delay, PollNext(offset))
      Nil
    }
    None -> Nil
  }
}

/// Internal function to start polling with given configuration and offset
fn start_polling_internal(
  config: PollingConfig,
  offset: Option(Int),
) -> Result(Poller, TelegaError) {
  use _ <- result.try(api.delete_webhook(config.client))

  use worker <- result.try(
    start_polling_worker(config)
    |> result.map_error(fn(err) {
      error.ActorError(
        "Failed to start polling worker: " <> string.inspect(err),
      )
    }),
  )

  process.send(worker, StartPolling(offset))

  Ok(Poller(worker: worker, config: config, status: Starting))
}

/// Start polling with the given client and bot subject.
pub fn start_polling(
  client client: TelegramClient,
  bot bot: BotSubject,
  timeout timeout: Int,
  limit limit: Int,
  allowed_updates allowed_updates: List(String),
  poll_interval poll_interval: Int,
) -> Result(Poller, TelegaError) {
  let config =
    create_config(
      client,
      bot,
      timeout,
      limit,
      allowed_updates,
      poll_interval,
      None,
    )

  start_polling_internal(config, None)
}

/// Start polling with default configuration.
pub fn start_polling_default(
  client client: TelegramClient,
  bot bot: BotSubject,
) -> Result(Poller, TelegaError) {
  start_polling(
    client:,
    bot:,
    timeout: 30,
    limit: 100,
    allowed_updates: [],
    poll_interval: 1000,
  )
}

/// Start polling with a custom offset.
pub fn start_polling_with_offset(
  client client: TelegramClient,
  bot bot: BotSubject,
  offset offset: Int,
  timeout timeout: Int,
  limit limit: Int,
  allowed_updates allowed_updates: List(String),
  poll_interval poll_interval: Int,
) -> Result(Poller, TelegaError) {
  let config =
    create_config(
      client,
      bot,
      timeout,
      limit,
      allowed_updates,
      poll_interval,
      None,
    )

  start_polling_internal(config, Some(offset))
}

/// Start polling with a notification callback for when polling stops due to errors.
/// The callback will be invoked with the error that caused polling to stop.
pub fn start_polling_with_notify(
  client client: TelegramClient,
  bot bot: BotSubject,
  timeout timeout: Int,
  limit limit: Int,
  allowed_updates allowed_updates: List(String),
  poll_interval poll_interval: Int,
  on_stop on_stop: fn(TelegaError) -> Nil,
) -> Result(Poller, TelegaError) {
  let config =
    create_config(
      client,
      bot,
      timeout,
      limit,
      allowed_updates,
      poll_interval,
      Some(on_stop),
    )

  start_polling_internal(config, None)
}

/// Stop polling
pub fn stop(poller: Poller) -> Nil {
  process.send(poller.worker, StopPolling)
}

/// Get the current status of the poller
pub fn get_status(poller: Poller) -> PollerStatus {
  poller.status
}

/// Get the polling configuration metadata
pub fn get_config_info(poller: Poller) -> #(Int, Int, List(String), Int) {
  #(
    poller.config.timeout,
    poller.config.limit,
    poller.config.allowed_updates,
    poller.config.poll_interval,
  )
}

/// Check if poller is running
pub fn is_running(poller: Poller) -> Bool {
  case poller.status {
    Running -> True
    _ -> False
  }
}

/// Wait for the poller to finish
/// This function blocks indefinitely until the polling worker stops
pub fn wait_finish(poller: Poller) -> Nil {
  case process.subject_owner(poller.worker) {
    Ok(pid) -> {
      let monitor = process.monitor(pid)
      let selector =
        process.new_selector()
        |> process.select_specific_monitor(monitor, fn(_down_msg) { Nil })

      process.selector_receive_forever(selector)
    }
    Error(_) -> {
      process.sleep_forever()
    }
  }
}
