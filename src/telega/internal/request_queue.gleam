//// Rate-limited request queue.
////
//// The queue actor decides *when* a request may run; it never runs one itself.
//// Each admitted request gets its own process, so a slow HTTP call cannot block
//// the actor's mailbox, cannot serialise the other requests, and cannot make
//// `overall_limit` unreachable. Workers are monitored, so a crashed one frees
//// its concurrency slot instead of leaking it.

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Pid, type Subject}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import telega/internal/utils

import telega/error.{type TelegaError}
import telega/telemetry

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
    /// Base retry delay in milliseconds; each further attempt doubles it
    retry_delay: Int,
    /// Maximum retries
    max_retries: Int,
    /// Per-chat pacing. Rules for individual chats are created as requests for
    /// them arrive and dropped again once the chat goes quiet, so a bot serving
    /// many chats does not carry a rule per chat it has ever answered.
    per_chat: Option(PerChatLimits),
  )
}

/// Telegram's per-chat limits, told apart by the sign of the `chat_id`:
/// groups, supergroups and channels have negative ids.
pub type PerChatLimits {
  PerChatLimits(
    private_rate: Int,
    private_window_ms: Int,
    group_rate: Int,
    group_window_ms: Int,
  )
}

/// 1 request per second per private chat, 20 per minute per group.
pub fn default_per_chat_limits() -> PerChatLimits {
  PerChatLimits(
    private_rate: 1,
    private_window_ms: 1000,
    group_rate: 20,
    group_window_ms: 60_000,
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
    per_chat: Some(default_per_chat_limits()),
  )
}

/// Rule id prefix for the per-chat rules created on demand.
const chat_rule_prefix = "chat:"

/// How long a per-chat rule with an empty queue is kept before it is dropped.
/// Long enough that a chat being answered steadily keeps its window, short
/// enough that a burst of one-off chats does not accumulate.
const chat_rule_idle_ms = 60_000

/// The rule a request for `chat_id` is paced by, created on demand.
///
/// It carries the `default` rule's priority, because a per-chat rule is an
/// extra bound on the lane `fetch` already uses — not a lane of its own. Giving
/// it a priority of its own would quietly move every ordinary reply out of
/// whatever tier the bot put `default` in.
fn chat_rule(limits: PerChatLimits, chat_id: Int, priority: Int) -> Rule {
  let #(rate, limit) = case chat_id < 0 {
    True -> #(limits.group_rate, limits.group_window_ms)
    False -> #(limits.private_rate, limits.private_window_ms)
  }
  Rule(id: chat_rule_prefix <> int.to_string(chat_id), rate:, limit:, priority:)
}

/// The priority ordinary replies ride at: the `default` rule's, when the bot
/// configured one.
fn default_priority(config: QueueConfig) -> Int {
  case list.find(config.rules, fn(rule) { rule.id == "default" }) {
    Ok(rule) -> rule.priority
    Error(Nil) -> 5
  }
}

/// How often the queue re-checks its rule windows. Exactly one such timer is
/// alive at a time — admitting a request nudges the queue directly instead of
/// arming another one.
const tick_interval = 100

/// Upper bound on the exponential retry backoff.
const max_retry_delay = 30_000

fn queue_unavailable() -> TelegaError {
  error.FetchError("Request queue is not available")
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

/// A request currently being executed by its own worker process.
type InFlight {
  InFlight(
    rule_id: String,
    worker: Pid,
    monitor: process.Monitor,
    reply_to: Subject(Result(Response(String), TelegaError)),
  )
}

type Message {
  Execute(request: QueuedRequest)
  /// Admit whatever the rules allow right now. Does not arm a timer.
  ProcessQueue
  /// Timer-driven variant of `ProcessQueue`; the only message that re-arms the
  /// timer, which keeps exactly one tick chain alive.
  Tick
  RequestCompleted(id: String)
  RequestFailed(request: QueuedRequest, error: TelegaError)
  RetryRequest(request: QueuedRequest)
  WorkerDown(down: process.Down)
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
    /// Created on demand for one chat, so it may be dropped again when that
    /// chat goes quiet. Configured rules never are.
    dynamic: Bool,
    /// When this rule last admitted or queued a request; only read for dynamic
    /// rules, to decide when to drop them.
    last_used: Int,
  )
}

type State {
  State(
    config: QueueConfig,
    /// Rule states by rule ID
    rule_states: Dict(String, RuleState),
    /// When each of the requests admitted inside the last overall window was
    /// let through. The ceiling Telegram enforces is any second, not the one a
    /// counter happens to be resetting on, so this is a log rather than a
    /// count: a fixed window admits its whole rate in the tail of one and again
    /// in the head of the next. It is also what makes the reserve below worth
    /// having — slots come back one at a time as they age out, instead of the
    /// budget reopening all at once for whoever is queued at that instant.
    overall_admissions: List(Int),
    /// The best (lowest) priority any configured rule has. The lane that holds
    /// it is the one the reserve is kept for.
    top_priority: Int,
    /// How much of the overall rate no lower-priority rule may spend. Derived
    /// once from the config; `0` when every rule shares one priority, because
    /// then there is no lane to keep it for.
    reserve: Int,
    /// Requests being executed right now, by request ID
    in_flight: Dict(String, InFlight),
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
            RuleState(
              rule:,
              window_count: 0,
              window_start: 0,
              queue: [],
              dynamic: False,
              last_used: 0,
            ),
          )
        })

      let top_priority = top_priority_of(config)

      let initial_state =
        State(
          config: config,
          rule_states: rule_states,
          overall_admissions: [],
          top_priority:,
          reserve: reserve_of(config, top_priority),
          in_flight: dict.new(),
          self: self,
        )

      process.send_after(self, tick_interval, Tick)

      let selector =
        process.new_selector()
        |> process.select(self)
        |> process.select_monitors(WorkerDown)

      actor.initialised(initial_state)
      |> actor.selecting(selector)
      |> actor.returning(self)
      |> Ok
    })
    |> actor.on_message(handle_message)
    |> actor.start
    |> result.map_error(fn(_) { actor.InitTimeout }),
  )

  Ok(RequestQueue(started.data))
}

/// Execute a request with specified rule.
///
/// Blocks until the request finishes. The queue actor is monitored, so a queue
/// that is gone (or dies mid-request) surfaces as an error rather than leaving
/// the caller waiting forever.
pub fn execute_with_rule(
  queue: RequestQueue,
  request_id: String,
  rule_id: String,
  execute: fn() -> Result(Response(String), TelegaError),
) -> Result(Response(String), TelegaError) {
  case process.subject_owner(queue.actor) {
    Error(Nil) -> Error(queue_unavailable())
    Ok(queue_pid) -> {
      let reply_subject = process.new_subject()
      let monitor = process.monitor(queue_pid)
      let selector =
        process.new_selector()
        |> process.select(reply_subject)
        |> process.select_specific_monitor(monitor, fn(_down) {
          Error(queue_unavailable())
        })

      process.send(
        queue.actor,
        Execute(QueuedRequest(
          id: request_id,
          rule_id: rule_id,
          execute: execute,
          reply_to: reply_subject,
          retry_count: 0,
        )),
      )

      let result = process.selector_receive_forever(selector)
      process.demonitor_process(monitor)
      result
    }
  }
}

/// Execute a request with default rule
pub fn execute(
  queue: RequestQueue,
  execute: fn() -> Result(Response(String), TelegaError),
) -> Result(Response(String), TelegaError) {
  execute_with_rule(queue, utils.random_string(32), "default", execute)
}

/// Execute a request paced by the chat it is addressed to, when the queue was
/// configured with per-chat limits and the chat is known.
///
/// Without either, this is `execute`: the global rules still apply, because a
/// per-chat rule is an extra bound on top of them, not a way around them.
pub fn execute_for_chat(
  queue: RequestQueue,
  chat_id: Option(Int),
  run: fn() -> Result(Response(String), TelegaError),
) -> Result(Response(String), TelegaError) {
  case chat_id {
    None -> execute(queue, run)
    Some(chat_id) ->
      execute_with_rule(
        queue,
        utils.random_string(32),
        chat_rule_prefix <> int.to_string(chat_id),
        run,
      )
  }
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

fn handle_message(
  state: State,
  message: Message,
) -> actor.Next(State, Message) {
  case message {
    Execute(request) -> {
      let new_state = add_to_queue(state, request)

      process.send(new_state.self, ProcessQueue)
      actor.continue(new_state)
    }

    ProcessQueue -> actor.continue(process_all_queues(state))

    Tick -> {
      let new_state =
        process_all_queues(state)
        |> prune_chat_rules(utils.current_time_ms())

      process.send_after(state.self, tick_interval, Tick)
      actor.continue(new_state)
    }

    RequestCompleted(id) -> {
      let new_state = release_slot(state, id)

      process.send(new_state.self, ProcessQueue)
      actor.continue(new_state)
    }

    RequestFailed(request, error) -> {
      let new_state = release_slot(state, request.id)

      case request.retry_count < state.config.max_retries {
        True -> {
          let retry_request =
            QueuedRequest(..request, retry_count: request.retry_count + 1)
          process.send_after(
            state.self,
            retry_delay_for(state.config.retry_delay, request.retry_count),
            RetryRequest(retry_request),
          )
          actor.continue(new_state)
        }
        False -> {
          process.send(request.reply_to, Error(error))
          process.send(new_state.self, ProcessQueue)
          actor.continue(new_state)
        }
      }
    }

    RetryRequest(request) -> {
      let new_state = add_to_queue(state, request)
      process.send(new_state.self, ProcessQueue)
      actor.continue(new_state)
    }

    // A worker died without reporting back (its `execute` crashed). Free the
    // slot it holds and fail its caller — nothing else would answer it.
    WorkerDown(process.ProcessDown(pid:, ..)) -> {
      let orphans =
        dict.filter(state.in_flight, fn(_id, in_flight) {
          in_flight.worker == pid
        })

      dict.each(orphans, fn(_id, in_flight) {
        process.send(
          in_flight.reply_to,
          Error(error.FetchError("Request worker exited unexpectedly")),
        )
      })

      let new_state =
        State(
          ..state,
          in_flight: dict.drop(state.in_flight, dict.keys(orphans)),
        )
      process.send(new_state.self, ProcessQueue)
      actor.continue(new_state)
    }
    WorkerDown(process.PortDown(..)) -> actor.continue(state)

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

/// Exponential backoff: `base`, `2 × base`, `4 × base`, … capped so a long
/// outage cannot park a request for minutes.
fn retry_delay_for(base: Int, attempt: Int) -> Int {
  int.min(base * int.bitwise_shift_left(1, attempt), max_retry_delay)
}

fn release_slot(state: State, id: String) -> State {
  case dict.get(state.in_flight, id) {
    Ok(in_flight) -> {
      process.demonitor_process(in_flight.monitor)
      State(..state, in_flight: dict.delete(state.in_flight, id))
    }
    Error(Nil) -> state
  }
}

fn emit_queue_depth(rule: Rule, depth: Int) {
  telemetry.execute(["telega", "request_queue", "depth"], [#("depth", depth)], [
    #("rule_id", telemetry.StringValue(rule.id)),
    #("priority", telemetry.IntValue(rule.priority)),
  ])
}

fn add_to_queue(state: State, request: QueuedRequest) -> State {
  let reject = fn() {
    process.send(request.reply_to, Error(error.FetchError("Invalid rule ID")))
    state
  }

  case resolve_rule(state, request.rule_id) {
    Error(Nil) -> reject()
    Ok(#(state, rule_id)) ->
      case dict.get(state.rule_states, rule_id) {
        Error(Nil) -> reject()
        Ok(rule_state) -> {
          let request = QueuedRequest(..request, rule_id:)
          let new_queue = list.append(rule_state.queue, [request])
          let new_rule_state =
            RuleState(
              ..rule_state,
              queue: new_queue,
              last_used: utils.current_time_ms(),
            )

          emit_queue_depth(rule_state.rule, list.length(new_queue))
          State(
            ..state,
            rule_states: dict.insert(state.rule_states, rule_id, new_rule_state),
          )
        }
      }
  }
}

/// Find the rule a request should be paced by, creating a per-chat rule the
/// first time that chat is seen and falling back to `default` for a rule id
/// nothing knows about.
fn resolve_rule(
  state: State,
  rule_id: String,
) -> Result(#(State, String), Nil) {
  case dict.has_key(state.rule_states, rule_id) {
    True -> Ok(#(state, rule_id))
    False ->
      case chat_id_of_rule(rule_id), state.config.per_chat {
        Ok(chat_id), Some(limits) -> {
          let rule = chat_rule(limits, chat_id, default_priority(state.config))
          let now = utils.current_time_ms()
          let rule_states =
            dict.insert(
              state.rule_states,
              rule_id,
              RuleState(
                rule:,
                window_count: 0,
                window_start: now,
                queue: [],
                dynamic: True,
                last_used: now,
              ),
            )
          Ok(#(State(..state, rule_states:), rule_id))
        }
        _, _ ->
          case dict.has_key(state.rule_states, "default") {
            True -> Ok(#(state, "default"))
            False -> Error(Nil)
          }
      }
  }
}

fn chat_id_of_rule(rule_id: String) -> Result(Int, Nil) {
  case string.split_once(rule_id, chat_rule_prefix) {
    Ok(#("", chat_id)) -> int.parse(chat_id)
    _ -> Error(Nil)
  }
}

/// Drop per-chat rules that have nothing queued and have not been used for a
/// while, so a bot that answers many chats does not grow a rule per chat.
fn prune_chat_rules(state: State, now: Int) -> State {
  let rule_states =
    dict.filter(state.rule_states, fn(_id, rule_state) {
      !rule_state.dynamic
      || rule_state.queue != []
      || now - rule_state.last_used < chat_rule_idle_ms
    })
  State(..state, rule_states:)
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
    let #(rule_id, _) = rule_entry
    process_rule_queue(state, rule_id, now)
  })
}

/// Admit as many of a rule's queued requests as its budget allows, not just one
/// per tick.
fn process_rule_queue(state: State, rule_id: String, now: Int) -> State {
  case dict.get(state.rule_states, rule_id) {
    Error(Nil) -> state
    Ok(rule_state) ->
      case rule_state.queue {
        [] -> state
        [request, ..rest] ->
          case can_process(state, rule_state, now) {
            False -> state
            True -> {
              let worker = execute_request(request, state.self)

              emit_queue_depth(rule_state.rule, list.length(rest))
              let new_rule_state =
                RuleState(
                  ..rule_state,
                  queue: rest,
                  window_count: rule_state.window_count + 1,
                  last_used: now,
                )
              let in_flight =
                dict.insert(
                  state.in_flight,
                  request.id,
                  InFlight(
                    rule_id:,
                    worker:,
                    monitor: process.monitor(worker),
                    reply_to: request.reply_to,
                  ),
                )

              State(
                ..state,
                rule_states: dict.insert(
                  state.rule_states,
                  rule_id,
                  new_rule_state,
                ),
                in_flight:,
                overall_admissions: [now, ..state.overall_admissions],
              )
              |> process_rule_queue(rule_id, now)
            }
          }
      }
  }
}

/// The bot-wide ceiling is expressed per second, and it is that second the
/// admission log is pruned against.
const overall_window_ms = 1000

/// How much of the overall rate is held back for the best-priority lane, as a
/// fraction: a fifth of it, and never less than one request.
const reserve_divisor = 5

fn top_priority_of(config: QueueConfig) -> Int {
  case config.rules {
    [] -> 0
    [first, ..rest] ->
      list.fold(rest, first.priority, fn(best, rule) {
        int.min(best, rule.priority)
      })
  }
}

/// Priority decides who goes FIRST among the requests queued right now — which
/// is worth nothing to a lane that is empty at the moment the budget opens and
/// arrives a beat later to find it spent. A bulk sender pacing itself at the
/// overall rate does exactly that, every window, and starves the interactive
/// lane for a full window at a time while the sort dutifully puts it first.
///
/// So a slice of the overall rate is not for sale: rules outside the
/// best-priority lane may spend the budget only down to the reserve, and what
/// is left is there for whoever is being answered right now. It costs the bulk
/// lane a fifth of its throughput while it is saturating the bot, and nothing
/// at all otherwise.
fn reserve_of(config: QueueConfig, top_priority: Int) -> Int {
  let has_lower_lane =
    list.any(config.rules, fn(rule) { rule.priority > top_priority })

  case config.overall_rate, has_lower_lane {
    Some(rate), True -> int.max(1, rate / reserve_divisor)
    _, _ -> 0
  }
}

/// The share of `limit` this rule may spend. Never below one, so a reserve
/// wider than the rate slows the lower lanes down instead of stopping them.
fn budget_for(limit: Int, reserve: Int, rule: Rule, top_priority: Int) -> Int {
  case rule.priority <= top_priority {
    True -> limit
    False -> int.max(1, limit - reserve)
  }
}

fn can_process(state: State, rule_state: RuleState, _now: Int) -> Bool {
  let rule_ok = rule_state.window_count < rule_state.rule.rate

  let overall_ok = case state.config.overall_rate {
    Some(limit) ->
      list.length(state.overall_admissions)
      < budget_for(limit, state.reserve, rule_state.rule, state.top_priority)
    None -> True
  }

  let concurrent_ok = case state.config.overall_limit {
    Some(limit) -> dict.size(state.in_flight) < limit
    None -> True
  }

  rule_ok && overall_ok && concurrent_ok
}

fn reset_windows(state: State, now: Int) -> State {
  let state =
    State(
      ..state,
      overall_admissions: list.filter(state.overall_admissions, fn(at) {
        now - at < overall_window_ms
      }),
    )

  let new_rule_states =
    dict.map_values(state.rule_states, fn(_, rule_state) {
      case now - rule_state.window_start > rule_state.rule.limit {
        True -> RuleState(..rule_state, window_count: 0, window_start: now)
        False -> rule_state
      }
    })

  State(..state, rule_states: new_rule_states)
}

/// Run the request in its own process. The actor stays free to admit further
/// requests (up to `overall_limit`) and to answer status queries while this one
/// is in flight.
fn execute_request(request: QueuedRequest, self: Subject(Message)) -> Pid {
  process.spawn_unlinked(fn() {
    case request.execute() {
      Ok(value) -> {
        process.send(request.reply_to, Ok(value))
        process.send(self, RequestCompleted(request.id))
      }
      Error(error) -> process.send(self, RequestFailed(request, error))
    }
  })
}
