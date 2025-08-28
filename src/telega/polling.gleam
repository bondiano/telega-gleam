//// Long polling implementation for Telegram Bot API.
////
//// This module provides an alternative to webhooks for receiving updates.
//// The polling system uses a worker actor that continuously fetches updates
//// from Telegram and dispatches them to the bot's message handlers.

import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string

import telega
import telega/api
import telega/bot.{type BotSubject}
import telega/client.{type TelegramClient}
import telega/error.{type TelegaError}
import telega/internal/log
import telega/model/types.{type Update, GetUpdatesParameters}
import telega/update as update_module

/// Internal configuration for the polling system
type PollingConfig {
  PollingConfig(
    client: TelegramClient,
    bot: BotSubject,
    timeout: Int,
    limit: Int,
    allowed_updates: List(String),
    poll_interval: Int,
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
) -> PollingConfig {
  PollingConfig(
    client:,
    bot:,
    timeout:,
    limit:,
    allowed_updates:,
    poll_interval:,
  )
}

/// Messages for the polling worker actor
pub type PollingMessage {
  StartPolling(offset: Option(Int))
  StopPolling
  PollNext(offset: Int)
  InjectUpdates(updates: List(Update), offset: Int)
  SetSelf(subject: Subject(PollingMessage))
}

/// State for the polling worker
type PollingState {
  PollingState(
    config: PollingConfig,
    offset: Option(Int),
    is_running: Bool,
    self: Option(Subject(PollingMessage)),
  )
}

/// Start the polling worker actor
fn start_polling_worker(
  config: PollingConfig,
) -> Result(Subject(PollingMessage), actor.StartError) {
  let initial_state =
    PollingState(config:, offset: None, is_running: False, self: None)

  use started <- result.try(
    actor.new(initial_state)
    |> actor.on_message(handle_polling_message)
    |> actor.start(),
  )

  process.send(started.data, SetSelf(started.data))

  Ok(started.data)
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
      let offset_str = case offset {
        Some(o) -> int.to_string(o)
        None -> "none"
      }
      log.info("Starting polling with offset: " <> offset_str)

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
      log.info("Stopping polling")
      actor.continue(PollingState(..state, is_running: False))
    }

    PollNext(offset) -> {
      case state.is_running {
        False -> actor.continue(state)
        True -> {
          case poll_updates(state, offset) {
            Ok(new_offset) -> {
              schedule_next_poll(state, new_offset)
              actor.continue(PollingState(..state, offset: Some(new_offset)))
            }
            Error(_error) -> {
              log.error("Polling error occurred")
              schedule_next_poll(state, offset)
              actor.continue(state)
            }
          }
        }
      }
    }

    InjectUpdates(updates, offset) -> {
      list.each(updates, fn(update) { process_update(state.config.bot, update) })
      let new_offset = calculate_new_offset(updates, offset)
      actor.continue(PollingState(..state, offset: Some(new_offset)))
    }
  }
}

/// Poll for updates and process them
fn poll_updates(state: PollingState, offset: Int) -> Result(Int, TelegaError) {
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

  list.each(updates, fn(update) { process_update(state.config.bot, update) })

  Ok(calculate_new_offset(updates, offset))
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

/// Process a single update by converting and sending to bot
/// Handles errors gracefully to prevent polling from stopping
fn process_update(bot_subject: BotSubject, update: Update) -> Nil {
  let decoded_update = update_module.raw_to_update(update)
  bot.handle_update(bot_subject, decoded_update)
  Nil
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
    None -> {
      log.error("Cannot schedule next poll: no self reference")
    }
  }
}

/// Start polling with a Telega bot instance
pub fn init_polling(
  telega: telega.Telega(session, error),
  timeout timeout: Int,
  limit limit: Int,
  allowed_updates allowed_updates: List(String),
  poll_interval poll_interval: Int,
) -> Result(Poller, TelegaError) {
  let config =
    create_config(
      telega.get_client_internal(telega),
      telega.get_bot_subject_internal(telega),
      timeout,
      limit,
      allowed_updates,
      poll_interval,
    )

  use worker <- result.try(
    start_polling_worker(config)
    |> result.map_error(fn(err) {
      error.ActorError(
        "Failed to start polling worker: " <> string.inspect(err),
      )
    }),
  )

  process.send(worker, StartPolling(None))

  Ok(Poller(worker: worker, config: config, status: Starting))
}

/// Start polling with default configuration
pub fn init_polling_default(
  telega: telega.Telega(session, error),
) -> Result(Poller, TelegaError) {
  init_polling(
    telega,
    timeout: 30,
    limit: 100,
    allowed_updates: [],
    poll_interval: 1000,
  )
}

/// Start polling with a custom offset
pub fn init_polling_with_offset(
  telega: telega.Telega(session, error),
  token: String,
  offset: Int,
  timeout timeout: Int,
  limit limit: Int,
  allowed_updates allowed_updates: List(String),
  poll_interval poll_interval: Int,
) -> Result(Poller, TelegaError) {
  let config =
    create_config(
      client.new(token),
      telega.get_bot_subject_internal(telega),
      timeout,
      limit,
      allowed_updates,
      poll_interval,
    )

  use worker <- result.try(
    start_polling_worker(config)
    |> result.map_error(fn(err) {
      error.ActorError(
        "Failed to start polling worker: " <> string.inspect(err),
      )
    }),
  )

  process.send(worker, StartPolling(Some(offset)))

  Ok(Poller(worker: worker, config: config, status: Starting))
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
