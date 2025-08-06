import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import telega/internal/utils

import telega/error.{type TelegaError}

pub opaque type RequestQueue {
  RequestQueue(actor: Subject(Message))
}

/// Rule configuration for request handling
pub type Rule {
  Rule(
    /// Rule identifier
    id: String,
    /// Maximum requests per time window
    rate: Int,
    /// Time window in milliseconds
    limit: Int,
    /// Priority (lower number = higher priority)
    priority: Int,
  )
}

/// Queue configuration
pub type QueueConfig {
  QueueConfig(
    /// List of rules
    rules: List(Rule),
    /// Overall rate limit (requests per second)
    overall_rate: Option(Int),
    /// Overall concurrent request limit
    overall_limit: Option(Int),
    /// Default retry delay in milliseconds
    retry_delay: Int,
    /// Maximum retries
    max_retries: Int,
  )
}

/// Default configuration for Telegram API
pub fn default_config() -> QueueConfig {
  QueueConfig(
    rules: [Rule(id: "default", rate: 30, limit: 1000, priority: 5)],
    overall_rate: Some(30),
    overall_limit: Some(100),
    retry_delay: 1000,
    max_retries: 3,
  )
}

/// A queued request
type QueuedRequest {
  QueuedRequest(
    /// Unique request ID
    id: String,
    /// Rule ID to use
    rule_id: String,
    /// Function to execute
    execute: fn() -> Result(Response(String), TelegaError),
    /// Reply channel
    reply_to: Subject(Result(Response(String), TelegaError)),
    /// Current retry count
    retry_count: Int,
  )
}

type Message {
  Execute(request: QueuedRequest)
  ProcessQueue
  RequestCompleted(id: String, rule_id: String)
  RequestFailed(request: QueuedRequest, error: TelegaError, should_retry: Bool)
  RetryRequest(request: QueuedRequest)
  GetTotalLength(reply_to: Subject(Int))
  IsOverheated(reply_to: Subject(Bool))
  Shutdown
}

type RuleState {
  RuleState(
    rule: Rule,
    /// Current count in window
    window_count: Int,
    /// Timestamp of window start
    window_start: Int,
    /// Queue of pending requests for this rule
    queue: List(QueuedRequest),
  )
}

type State {
  State(
    config: QueueConfig,
    /// Rule states by rule ID
    rule_states: Dict(String, RuleState),
    /// Overall request count
    overall_count: Int,
    /// Overall window start
    overall_window_start: Int,
    /// Currently processing requests
    in_flight: Dict(String, String),
    // request_id -> rule_id
    /// Self reference
    self: Subject(Message),
  )
}

/// Start a new request queue
pub fn start(config: QueueConfig) -> Result(RequestQueue, actor.StartError) {
  use started <- result.try(
    actor.new_with_initialiser(1000, fn(self) {
      let rule_states =
        list.fold(config.rules, dict.new(), fn(acc, rule) {
          dict.insert(
            acc,
            rule.id,
            RuleState(rule: rule, window_count: 0, window_start: 0, queue: []),
          )
        })

      let initial_state =
        State(
          config: config,
          rule_states: rule_states,
          overall_count: 0,
          overall_window_start: 0,
          in_flight: dict.new(),
          self: self,
        )

      process.send_after(self, 100, ProcessQueue)

      actor.initialised(initial_state)
      |> actor.returning(self)
      |> Ok
    })
    |> actor.on_message(handle_message)
    |> actor.start
    |> result.map_error(fn(_) { actor.InitTimeout }),
  )

  Ok(RequestQueue(started.data))
}

/// Execute a request with specified rule
pub fn execute_with_rule(
  queue: RequestQueue,
  request_id: String,
  rule_id: String,
  execute: fn() -> Result(Response(String), TelegaError),
) -> Result(Response(String), TelegaError) {
  let reply_subject = process.new_subject()

  let request =
    QueuedRequest(
      id: request_id,
      rule_id: rule_id,
      execute: execute,
      reply_to: reply_subject,
      retry_count: 0,
    )

  process.send(queue.actor, Execute(request))

  process.receive_forever(reply_subject)
}

/// Execute a request with default rule
pub fn execute(
  queue: RequestQueue,
  execute: fn() -> Result(Response(String), TelegaError),
) -> Result(Response(String), TelegaError) {
  execute_with_rule(queue, utils.random_string(32), "default", execute)
}

/// Shutdown the queue
pub fn shutdown(queue: RequestQueue) -> Nil {
  process.send(queue.actor, Shutdown)
}

/// Get the total number of queued requests across all rules
pub fn total_length(queue: RequestQueue) -> Int {
  let reply_subject = process.new_subject()
  process.send(queue.actor, GetTotalLength(reply_subject))

  case process.receive(reply_subject, 1000) {
    Ok(length) -> length
    Error(_) -> 0
  }
}

/// Check if any rule is currently at its rate limit
pub fn is_overheated(queue: RequestQueue) -> Bool {
  let reply_subject = process.new_subject()
  process.send(queue.actor, IsOverheated(reply_subject))

  case process.receive(reply_subject, 1000) {
    Ok(overheated) -> overheated
    Error(_) -> False
  }
}

fn handle_message(state: State, message: Message) -> actor.Next(State, Message) {
  case message {
    Execute(request) -> {
      let new_state = add_to_queue(state, request)

      process.send(new_state.self, ProcessQueue)
      actor.continue(new_state)
    }

    ProcessQueue -> {
      let new_state = process_all_queues(state)

      process.send_after(state.self, 100, ProcessQueue)
      actor.continue(new_state)
    }

    RequestCompleted(id, _rule_id) -> {
      let new_in_flight = dict.delete(state.in_flight, id)
      let new_state = State(..state, in_flight: new_in_flight)

      process.send(new_state.self, ProcessQueue)
      actor.continue(new_state)
    }

    RequestFailed(request, error, should_retry) -> {
      let new_in_flight = dict.delete(state.in_flight, request.id)
      let mut_state = State(..state, in_flight: new_in_flight)

      case should_retry {
        True -> {
          // Schedule retry after delay
          let retry_request =
            QueuedRequest(..request, retry_count: request.retry_count + 1)
          process.send_after(
            state.self,
            state.config.retry_delay,
            RetryRequest(retry_request),
          )
          actor.continue(mut_state)
        }
        False -> {
          // Send error to caller
          process.send(request.reply_to, Error(error))
          actor.continue(mut_state)
        }
      }
    }

    RetryRequest(request) -> {
      // Add request back to queue for retry
      let new_state = add_to_queue(state, request)
      process.send(new_state.self, ProcessQueue)
      actor.continue(new_state)
    }

    GetTotalLength(reply_to) -> {
      let total =
        dict.fold(state.rule_states, 0, fn(acc, _, rule_state) {
          acc + list.length(rule_state.queue)
        })
      process.send(reply_to, total)
      actor.continue(state)
    }

    IsOverheated(reply_to) -> {
      let overheated =
        dict.to_list(state.rule_states)
        |> list.any(fn(pair) {
          let #(_, rule_state) = pair
          rule_state.window_count >= rule_state.rule.rate
        })
      process.send(reply_to, overheated)
      actor.continue(state)
    }

    Shutdown -> {
      actor.stop()
    }
  }
}

fn add_to_queue(state: State, request: QueuedRequest) -> State {
  case dict.get(state.rule_states, request.rule_id) {
    Ok(rule_state) -> {
      let new_queue = list.append(rule_state.queue, [request])
      let new_rule_state = RuleState(..rule_state, queue: new_queue)
      let new_rule_states =
        dict.insert(state.rule_states, request.rule_id, new_rule_state)

      State(..state, rule_states: new_rule_states)
    }
    Error(_) -> {
      case dict.get(state.rule_states, "default") {
        Ok(rule_state) -> {
          let updated_request = QueuedRequest(..request, rule_id: "default")
          let new_queue = list.append(rule_state.queue, [updated_request])
          let new_rule_state = RuleState(..rule_state, queue: new_queue)
          let new_rule_states =
            dict.insert(state.rule_states, "default", new_rule_state)

          State(..state, rule_states: new_rule_states)
        }
        Error(_) -> {
          process.send(
            request.reply_to,
            Error(error.FetchError("Invalid rule ID")),
          )
          state
        }
      }
    }
  }
}

fn process_all_queues(state: State) -> State {
  let now = utils.current_time_ms()

  let state = reset_windows(state, now)

  let sorted_rules =
    dict.to_list(state.rule_states)
    |> list.sort(fn(a, b) {
      let #(_, rule_state_a) = a
      let #(_, rule_state_b) = b
      int.compare(rule_state_a.rule.priority, rule_state_b.rule.priority)
    })

  list.fold(sorted_rules, state, fn(state, rule_entry) {
    let #(rule_id, rule_state) = rule_entry
    process_rule_queue(state, rule_id, rule_state, now)
  })
}

fn process_rule_queue(
  state: State,
  rule_id: String,
  rule_state: RuleState,
  now: Int,
) -> State {
  case rule_state.queue {
    [] -> state
    [request, ..rest] -> {
      case can_process(state, rule_state, now) {
        True -> {
          execute_request(request, state.self, state.config.max_retries)

          let new_rule_state =
            RuleState(
              ..rule_state,
              queue: rest,
              window_count: rule_state.window_count + 1,
            )
          let new_rule_states =
            dict.insert(state.rule_states, rule_id, new_rule_state)
          let new_in_flight = dict.insert(state.in_flight, request.id, rule_id)

          State(
            ..state,
            rule_states: new_rule_states,
            in_flight: new_in_flight,
            overall_count: state.overall_count + 1,
          )
        }
        False -> state
      }
    }
  }
}

fn can_process(state: State, rule_state: RuleState, _now: Int) -> Bool {
  let rule_ok = rule_state.window_count < rule_state.rule.rate

  let overall_ok = case state.config.overall_rate {
    Some(limit) -> state.overall_count < limit
    None -> True
  }

  let concurrent_ok = case state.config.overall_limit {
    Some(limit) -> dict.size(state.in_flight) < limit
    None -> True
  }

  rule_ok && overall_ok && concurrent_ok
}

fn reset_windows(state: State, now: Int) -> State {
  let state = case now - state.overall_window_start > 1000 {
    True -> State(..state, overall_count: 0, overall_window_start: now)
    False -> state
  }

  let new_rule_states =
    dict.map_values(state.rule_states, fn(_, rule_state) {
      case now - rule_state.window_start > rule_state.rule.limit {
        True -> RuleState(..rule_state, window_count: 0, window_start: now)
        False -> rule_state
      }
    })

  State(..state, rule_states: new_rule_states)
}

fn execute_request(
  request: QueuedRequest,
  self: Subject(Message),
  max_retries: Int,
) {
  let result = request.execute()

  case result {
    Ok(value) -> {
      process.send(self, RequestCompleted(request.id, request.rule_id))
      process.send(request.reply_to, Ok(value))
    }
    Error(error) -> {
      let should_retry = request.retry_count < max_retries

      case should_retry {
        True -> {
          process.send(self, RequestFailed(request, error, True))
        }
        False -> {
          process.send(self, RequestCompleted(request.id, request.rule_id))
          process.send(request.reply_to, Error(error))
        }
      }
    }
  }

  Nil
}
