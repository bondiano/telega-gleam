//// Work the bot does later: a reminder in an hour, a nightly digest, a
//// retry after the rate limit clears.
////
//// Two kinds of job, and the difference is what happens when the bot
//// restarts:
////
//// - **In-memory** (`run_after`, `run_every`) — a closure and a BEAM timer.
////   Cheap, cancellable, and gone the moment the VM stops. Good for the
////   periodic chores of a running bot: refreshing a cache, sweeping a table.
//// - **Persisted** (`persisted`, `persisted_every`) — a named handler, a
////   chat, a payload and a due time written to a `KeyValueStorage`. The
////   scheduler re-reads them at start, so a reminder still fires after a
////   deploy. Anything a *user* is waiting for belongs here.
////
//// ```gleam
//// import telega/jobs
////
//// let assert Ok(scheduler) =
////   jobs.new(bot)
////   |> jobs.with_storage(storage)
////   |> jobs.with_handler("reminder", fn(ctx, payload) {
////     let text = decode.run(payload, decode.at(["text"], decode.string))
////     let _ = reply.with_text(ctx, result.unwrap(text, "⏰"))
////     Nil
////   })
////   |> jobs.start()
////
//// // ...from a handler, an hour from now:
//// jobs.persisted(
////   scheduler,
////   id: "reminder:" <> int.to_string(ctx.update.chat_id),
////   handler: "reminder",
////   chat_id: ctx.update.chat_id,
////   user_id: ctx.update.from_id,
////   at: timestamp.add(timestamp.system_time(), duration.hours(1)),
////   payload: json.object([#("text", json.string("stand up"))]),
//// )
//// ```
////
//// A persisted job runs against a [`telega.background_context`](../telega.html#background_context):
//// the session is loaded, `dependencies` are injected, and everything a
//// handler can do — reply, edit, `dialog.refresh` — works. What does not is
//// `wait_*`: there is no chat instance to suspend.
////
//// ## Ids, and what they cost
////
//// A persisted job's `id` is its identity in storage. Scheduling twice with
//// the same id replaces the first — which is what you want for
//// "remind me at 9", and not what you want for a queue of independent
//// reminders. Include whatever makes them distinct (`"digest:" <> chat`,
//// `"reminder:" <> chat <> ":" <> nonce`). `cancel` takes the same id.
////
//// ## Guarantees
////
//// At-most-once, not exactly-once. A job whose handler crashes mid-run is
//// not retried — it has already been taken out of storage. A job whose
//// *context* cannot be built (an unreadable session) is retried a few times
//// and then dropped with an error log, since retrying forever would be a
//// louder failure than losing the job. A job whose handler name is not
//// registered stays in storage untouched, so the deploy that adds the
//// handler picks it up at start.
////
//// Every run emits `["telega", "job", "run"]`; a failure to run one emits
//// `["telega", "job", "error"]`.

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/process.{type Name, type Subject}
import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/result
import gleam/string
import gleam/time/timestamp.{type Timestamp}
import telega.{type Telega}
import telega/bot.{type Context}
import telega/client.{type TelegramClient}
import telega/error.{type TelegaError}
import telega/internal/log
import telega/internal/utils
import telega/storage.{type KeyValueStorage, KeyValueStorage}
import telega/telemetry

/// A running scheduler. Hand it to handlers through `dependencies`, or name it
/// with [`with_name`](#with_name) and rebuild the handle with
/// [`from_name`](#from_name).
pub opaque type Scheduler(session, error, dependencies) {
  Scheduler(subject: Subject(Message(session, error, dependencies)))
}

/// The scheduler actor's protocol. Opaque — every message has a function that
/// sends it; the type is public only so it can be named.
pub opaque type Message(session, error, dependencies) {
  Fire(id: String)
  AddMemory(job: MemoryJob, delay_ms: Int)
  AddPersisted(record: JobRecord)
  CancelJob(id: String)
  Pending(reply: Subject(List(String)))
}

/// What a persisted job runs: the update-less context for its chat and the
/// payload it was scheduled with, still undecoded.
pub type JobHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), Dynamic) -> Nil

type MemoryJob {
  MemoryJob(id: String, run: fn(TelegramClient) -> Nil, every: Option(Int))
}

type JobRecord {
  JobRecord(
    id: String,
    handler: String,
    chat_id: Int,
    user_id: Int,
    /// Unix time in milliseconds.
    run_at: Int,
    /// The payload exactly as it was scheduled, still JSON.
    payload: String,
    repeat_ms: Option(Int),
    /// How many times building this job's context has failed.
    attempts: Int,
  )
}

/// Scheduler configuration, built by [`new`](#new) and started by
/// [`start`](#start).
pub opaque type Builder(session, error, dependencies) {
  Builder(
    telega: Telega(session, error, dependencies),
    storage: Option(KeyValueStorage(String)),
    handlers: Dict(String, JobHandler(session, error, dependencies)),
    name: Option(Name(Message(session, error, dependencies))),
  )
}

type State(session, error, dependencies) {
  State(
    self: Subject(Message(session, error, dependencies)),
    telega: Telega(session, error, dependencies),
    storage: Option(KeyValueStorage(String)),
    handlers: Dict(String, JobHandler(session, error, dependencies)),
    timers: Dict(String, process.Timer),
    memory: Dict(String, MemoryJob),
    persisted: Dict(String, JobRecord),
  )
}

const job_prefix = "job:"

/// How many times a job whose context cannot be built is put back before it is
/// given up on.
pub const max_job_attempts = 5

/// How long a job waits before its context is tried again.
pub const job_retry_delay_ms = 60_000

/// Start configuring a scheduler for a started bot.
pub fn new(
  telega telega: Telega(session, error, dependencies),
) -> Builder(session, error, dependencies) {
  Builder(telega:, storage: None, handlers: dict.new(), name: None)
}

/// Give the scheduler somewhere to keep persisted jobs.
///
/// Without it `persisted` has nowhere to write and logs an error instead; the
/// in-memory jobs work either way. Use the same backend the sessions and flows
/// use — jobs live under their own `job:` namespace.
pub fn with_storage(
  builder builder: Builder(session, error, dependencies),
  storage storage: KeyValueStorage(storage_error),
) -> Builder(session, error, dependencies) {
  Builder(..builder, storage: Some(erase_storage(storage)))
}

/// Register what a persisted job named `name` does.
///
/// The name is what is written to storage in place of the closure, so it has
/// to mean the same thing across deploys. Registering the same name twice
/// keeps the last one.
pub fn with_handler(
  builder builder: Builder(session, error, dependencies),
  name name: String,
  run run: JobHandler(session, error, dependencies),
) -> Builder(session, error, dependencies) {
  Builder(..builder, handlers: dict.insert(builder.handlers, name, run))
}

/// Register the scheduler actor under a process name, so handlers can reach it
/// with [`from_name`](#from_name) instead of being handed the value.
pub fn with_name(
  builder builder: Builder(session, error, dependencies),
  name name: Name(Message(session, error, dependencies)),
) -> Builder(session, error, dependencies) {
  Builder(..builder, name: Some(name))
}

/// A handle for a scheduler started under `name`.
///
/// Nothing checks that it is running — a send to a dead name is dropped, the
/// same as any named subject.
pub fn from_name(
  name: Name(Message(session, error, dependencies)),
) -> Scheduler(session, error, dependencies) {
  Scheduler(process.named_subject(name))
}

/// Start the scheduler.
///
/// Persisted jobs are read back from storage here: everything already due runs
/// straight away, the rest is armed for its due time.
pub fn start(
  builder builder: Builder(session, error, dependencies),
) -> Result(Scheduler(session, error, dependencies), TelegaError) {
  let started =
    actor.new_with_initialiser(start_timeout, fn(self) {
      let state =
        State(
          self:,
          telega: builder.telega,
          storage: builder.storage,
          handlers: builder.handlers,
          timers: dict.new(),
          memory: dict.new(),
          persisted: dict.new(),
        )

      actor.initialised(restore(state))
      |> actor.returning(self)
      |> Ok
    })
    |> actor.on_message(loop)

  let started = case builder.name {
    Some(name) -> actor.named(started, name)
    None -> started
  }

  actor.start(started)
  |> result.map(fn(started) { Scheduler(started.data) })
  |> result.map_error(fn(reason) {
    error.ActorError(
      "Failed to start the job scheduler: " <> string.inspect(reason),
    )
  })
}

const start_timeout = 5000

/// Run `job` once, `delay_ms` from now, and forget it if the bot restarts
/// first. Returns the id [`cancel`](#cancel) takes.
pub fn run_after(
  scheduler scheduler: Scheduler(session, error, dependencies),
  delay_ms delay_ms: Int,
  job job: fn(TelegramClient) -> Nil,
) -> String {
  let id = "mem:" <> utils.random_string(16)
  process.send(
    scheduler.subject,
    AddMemory(MemoryJob(id:, run: job, every: None), int.max(delay_ms, 0)),
  )
  id
}

/// Run `job` every `interval_ms`, starting one interval from now, until the
/// bot stops or [`cancel`](#cancel) is called with the returned id.
///
/// The next run is armed *after* the previous one is dispatched, so a job that
/// takes longer than its interval does not pile up.
pub fn run_every(
  scheduler scheduler: Scheduler(session, error, dependencies),
  interval_ms interval_ms: Int,
  job job: fn(TelegramClient) -> Nil,
) -> String {
  let interval = int.max(interval_ms, 1)
  let id = "mem:" <> utils.random_string(16)
  process.send(
    scheduler.subject,
    AddMemory(MemoryJob(id:, run: job, every: Some(interval)), interval),
  )
  id
}

/// Schedule a job that survives a restart: run `handler` for this chat at
/// `at`, with `payload`.
///
/// Scheduling an `id` that already exists replaces it. A time already in the
/// past runs as soon as the scheduler sees it.
pub fn persisted(
  scheduler scheduler: Scheduler(session, error, dependencies),
  id id: String,
  handler handler: String,
  chat_id chat_id: Int,
  user_id user_id: Int,
  at at: Timestamp,
  payload payload: Json,
) -> Nil {
  process.send(
    scheduler.subject,
    AddPersisted(JobRecord(
      id:,
      handler:,
      chat_id:,
      user_id:,
      run_at: to_unix_ms(at),
      payload: json.to_string(payload),
      repeat_ms: None,
      attempts: 0,
    )),
  )
}

/// Schedule a repeating job that survives a restart: run `handler` for this
/// chat every `interval_ms`, starting one interval from now.
///
/// Each run schedules the next one *and writes it* before it dispatches, so a
/// restart mid-run resumes the series rather than ending it.
pub fn persisted_every(
  scheduler scheduler: Scheduler(session, error, dependencies),
  id id: String,
  handler handler: String,
  chat_id chat_id: Int,
  user_id user_id: Int,
  interval_ms interval_ms: Int,
  payload payload: Json,
) -> Nil {
  let interval = int.max(interval_ms, 1)
  process.send(
    scheduler.subject,
    AddPersisted(JobRecord(
      id:,
      handler:,
      chat_id:,
      user_id:,
      run_at: utils.current_time_ms() + interval,
      payload: json.to_string(payload),
      repeat_ms: Some(interval),
      attempts: 0,
    )),
  )
}

/// Forget a job, in memory or in storage. Unknown ids are ignored.
pub fn cancel(
  scheduler scheduler: Scheduler(session, error, dependencies),
  id id: String,
) -> Nil {
  process.send(scheduler.subject, CancelJob(id))
}

/// The ids the scheduler is currently holding, in no particular order.
///
/// Mostly for tests and health endpoints. A scheduler that is gone, or does
/// not answer within `timeout` milliseconds, reports `Error(Nil)` rather than
/// taking the caller down with it.
pub fn pending(
  scheduler scheduler: Scheduler(session, error, dependencies),
  timeout timeout: Int,
) -> Result(List(String), Nil) {
  use pid <- result.try(process.subject_owner(scheduler.subject))
  let monitor = process.monitor(pid)
  let reply = process.new_subject()
  process.send(scheduler.subject, Pending(reply))

  let selector =
    process.new_selector()
    |> process.select_map(reply, Some)
    |> process.select_specific_monitor(monitor, fn(_down) { None })

  let ids = process.selector_receive(from: selector, within: timeout)
  process.demonitor_process(monitor)
  case ids {
    Ok(Some(ids)) -> Ok(ids)
    // The scheduler died, or did not answer in time.
    Ok(None) | Error(Nil) -> Error(Nil)
  }
}

// Actor ----------------------------------------------------------------------

fn loop(
  state: State(session, error, dependencies),
  message: Message(session, error, dependencies),
) -> actor.Next(
  State(session, error, dependencies),
  Message(session, error, dependencies),
) {
  case message {
    AddMemory(job, delay_ms) ->
      actor.continue(arm(
        State(..state, memory: dict.insert(state.memory, job.id, job)),
        job.id,
        delay_ms,
      ))

    AddPersisted(record) -> actor.continue(schedule_persisted(state, record))

    CancelJob(id) -> actor.continue(forget(state, id))

    Fire(id) -> actor.continue(fire(state, id))

    Pending(reply) -> {
      let ids = list.append(dict.keys(state.memory), dict.keys(state.persisted))
      process.send(reply, ids)
      actor.continue(state)
    }
  }
}

/// Write the job, then arm it. A crash between the two loses only the timer —
/// the next start reads the record back.
fn schedule_persisted(
  state: State(session, error, dependencies),
  record: JobRecord,
) -> State(session, error, dependencies) {
  case state.storage {
    None -> {
      log.error(
        "[jobs] cannot schedule the persisted job '"
        <> record.id
        <> "': the scheduler was started without storage",
      )
      state
    }
    Some(storage) -> {
      case storage.set(job_prefix <> record.id, encode_record(record)) {
        Ok(_) -> Nil
        Error(reason) ->
          log.error(
            "[jobs] failed to store the job '" <> record.id <> "': " <> reason,
          )
      }
      arm(
        State(
          ..state,
          persisted: dict.insert(state.persisted, record.id, record),
        ),
        record.id,
        record.run_at - utils.current_time_ms(),
      )
    }
  }
}

fn arm(
  state: State(session, error, dependencies),
  id: String,
  delay_ms: Int,
) -> State(session, error, dependencies) {
  let state = cancel_timer(state, id)
  let timer = process.send_after(state.self, int.max(delay_ms, 0), Fire(id))
  State(..state, timers: dict.insert(state.timers, id, timer))
}

fn cancel_timer(
  state: State(session, error, dependencies),
  id: String,
) -> State(session, error, dependencies) {
  case dict.get(state.timers, id) {
    Ok(timer) -> {
      let _ = process.cancel_timer(timer)
      State(..state, timers: dict.delete(state.timers, id))
    }
    Error(Nil) -> state
  }
}

fn forget(
  state: State(session, error, dependencies),
  id: String,
) -> State(session, error, dependencies) {
  let state = cancel_timer(state, id)
  let state =
    State(
      ..state,
      memory: dict.delete(state.memory, id),
      persisted: dict.delete(state.persisted, id),
    )
  drop_stored(state, id)
}

fn drop_stored(
  state: State(session, error, dependencies),
  id: String,
) -> State(session, error, dependencies) {
  case state.storage {
    None -> state
    Some(storage) -> {
      case storage.delete(job_prefix <> id) {
        Ok(_) -> Nil
        Error(reason) ->
          log.error(
            "[jobs] failed to delete the job '" <> id <> "': " <> reason,
          )
      }
      state
    }
  }
}

fn fire(
  state: State(session, error, dependencies),
  id: String,
) -> State(session, error, dependencies) {
  let state = State(..state, timers: dict.delete(state.timers, id))
  case dict.get(state.memory, id) {
    Ok(job) -> fire_memory(state, job)
    Error(Nil) ->
      case dict.get(state.persisted, id) {
        Ok(record) -> fire_persisted(state, record)
        // Cancelled between the timer firing and this message arriving.
        Error(Nil) -> state
      }
  }
}

fn fire_memory(
  state: State(session, error, dependencies),
  job: MemoryJob,
) -> State(session, error, dependencies) {
  let client = telega.get_api_config(state.telega)
  report_run(job.id, "memory")
  // Unlinked: a job that crashes must not take the scheduler with it.
  let _ = process.spawn_unlinked(fn() { job.run(client) })

  case job.every {
    None -> State(..state, memory: dict.delete(state.memory, job.id))
    Some(interval) -> arm(state, job.id, interval)
  }
}

fn fire_persisted(
  state: State(session, error, dependencies),
  record: JobRecord,
) -> State(session, error, dependencies) {
  case dict.get(state.handlers, record.handler) {
    // Left in storage on purpose: the deploy that registers this handler will
    // read it back at start. Dropping it would lose a user's reminder over a
    // typo.
    Error(Nil) -> {
      log.error(
        "[jobs] no handler named '"
        <> record.handler
        <> "' for job '"
        <> record.id
        <> "' — leaving it in storage",
      )
      report_error(record.id, "unknown_handler")
      State(..state, persisted: dict.delete(state.persisted, record.id))
    }

    Ok(handler) ->
      case
        telega.background_context(
          state.telega,
          chat_id: record.chat_id,
          user_id: record.user_id,
        )
      {
        Error(_) -> retry(state, record)

        Ok(ctx) -> {
          let payload =
            json.parse(record.payload, decode.dynamic)
            |> result.unwrap(dynamic.nil())
          report_run(record.id, record.handler)

          // The job is taken out of storage (or moved to its next run) before
          // it is dispatched: a handler that crashes is not retried, and a
          // restart mid-run does not run it twice.
          let state = case record.repeat_ms {
            None -> {
              let state = drop_stored(state, record.id)
              State(..state, persisted: dict.delete(state.persisted, record.id))
            }
            Some(interval) ->
              schedule_persisted(
                state,
                JobRecord(
                  ..record,
                  run_at: utils.current_time_ms() + interval,
                  attempts: 0,
                ),
              )
          }

          let _ = process.spawn_unlinked(fn() { handler(ctx, payload) })
          state
        }
      }
  }
}

/// The context could not be built — usually a session the backend would not
/// hand over. Put the job back for a few more tries, then give up loudly.
fn retry(
  state: State(session, error, dependencies),
  record: JobRecord,
) -> State(session, error, dependencies) {
  let attempts = record.attempts + 1
  case attempts >= max_job_attempts {
    True -> {
      log.error(
        "[jobs] giving up on job '"
        <> record.id
        <> "' after "
        <> int.to_string(attempts)
        <> " failed attempts to build its context",
      )
      report_error(record.id, "context_failed")
      forget(state, record.id)
    }
    False -> {
      log.warning(
        "[jobs] could not build the context for job '"
        <> record.id
        <> "', retrying in "
        <> int.to_string(job_retry_delay_ms)
        <> "ms",
      )
      schedule_persisted(
        state,
        JobRecord(
          ..record,
          attempts:,
          run_at: utils.current_time_ms() + job_retry_delay_ms,
        ),
      )
    }
  }
}

/// Read every stored job back and arm it. Anything already due is armed with
/// no delay, so a bot that was down over a reminder still sends it.
fn restore(
  state: State(session, error, dependencies),
) -> State(session, error, dependencies) {
  case state.storage {
    None -> state
    Some(storage) ->
      case storage.scan(job_prefix) {
        Error(reason) -> {
          log.error("[jobs] failed to read stored jobs: " <> reason)
          state
        }
        Ok(keys) ->
          list.fold(keys, state, fn(state, key) {
            case storage.get(key) {
              Ok(Some(raw)) ->
                case json.parse(raw, record_decoder()) {
                  Ok(record) ->
                    arm(
                      State(
                        ..state,
                        persisted: dict.insert(
                          state.persisted,
                          record.id,
                          record,
                        ),
                      ),
                      record.id,
                      record.run_at - utils.current_time_ms(),
                    )
                  Error(err) -> {
                    log.error(
                      "[jobs] failed to decode the stored job '"
                      <> key
                      <> "': "
                      <> string.inspect(err),
                    )
                    state
                  }
                }
              _ -> state
            }
          })
      }
  }
}

// Serialization --------------------------------------------------------------

fn encode_record(record: JobRecord) -> String {
  json.object([
    #("id", json.string(record.id)),
    #("handler", json.string(record.handler)),
    #("chat_id", json.int(record.chat_id)),
    #("user_id", json.int(record.user_id)),
    #("run_at", json.int(record.run_at)),
    #("payload", json.string(record.payload)),
    #("repeat_ms", case record.repeat_ms {
      None -> json.null()
      Some(ms) -> json.int(ms)
    }),
    #("attempts", json.int(record.attempts)),
  ])
  |> json.to_string
}

fn record_decoder() -> decode.Decoder(JobRecord) {
  use id <- decode.field("id", decode.string)
  use handler <- decode.field("handler", decode.string)
  use chat_id <- decode.field("chat_id", decode.int)
  use user_id <- decode.field("user_id", decode.int)
  use run_at <- decode.field("run_at", decode.int)
  use payload <- decode.field("payload", decode.string)
  use repeat_ms <- decode.optional_field(
    "repeat_ms",
    None,
    decode.optional(decode.int),
  )
  use attempts <- decode.optional_field("attempts", 0, decode.int)
  decode.success(JobRecord(
    id:,
    handler:,
    chat_id:,
    user_id:,
    run_at:,
    payload:,
    repeat_ms:,
    attempts:,
  ))
}

fn to_unix_ms(at: Timestamp) -> Int {
  let #(seconds, nanoseconds) = timestamp.to_unix_seconds_and_nanoseconds(at)
  seconds * 1000 + nanoseconds / 1_000_000
}

/// The scheduler only logs storage failures, so a backend's error type is
/// flattened here rather than infecting `Scheduler` with a fourth parameter.
fn erase_storage(storage: KeyValueStorage(e)) -> KeyValueStorage(String) {
  KeyValueStorage(
    get: fn(key) { storage.get(key) |> result.map_error(string.inspect) },
    set: fn(key, value) {
      storage.set(key, value) |> result.map_error(string.inspect)
    },
    set_with_ttl: fn(key, value, ttl) {
      storage.set_with_ttl(key, value, ttl) |> result.map_error(string.inspect)
    },
    delete: fn(key) { storage.delete(key) |> result.map_error(string.inspect) },
    scan: fn(prefix) {
      storage.scan(prefix) |> result.map_error(string.inspect)
    },
  )
}

fn report_run(id: String, handler: String) -> Nil {
  telemetry.execute(["telega", "job", "run"], [#("count", 1)], [
    #("id", telemetry.StringValue(id)),
    #("handler", telemetry.StringValue(handler)),
  ])
}

fn report_error(id: String, reason: String) -> Nil {
  telemetry.execute(["telega", "job", "error"], [#("count", 1)], [
    #("id", telemetry.StringValue(id)),
    #("reason", telemetry.StringValue(reason)),
  ])
}
