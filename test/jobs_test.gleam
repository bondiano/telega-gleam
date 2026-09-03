//// Phase 6d: work the bot does later — in-memory timers, and jobs that
//// survive the process that scheduled them.

import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/time/duration
import gleam/time/timestamp
import gleeunit/should

import telega
import telega/bot
import telega/error.{type TelegaError}
import telega/jobs
import telega/model/encoder
import telega/router
import telega/storage/ets
import telega/testing/factory
import telega/testing/mock

fn start_bot() -> telega.Telega(Nil, TelegaError, Nil) {
  let #(client, _calls) =
    mock.routed_client([
      mock.route_with_response(
        "getMe",
        mock.ok_response(encoder.encode_user(factory.bot_user())),
      ),
      mock.route_with_response("deleteWebhook", mock.bool_response()),
      mock.route_with_response("getUpdates", "{\"ok\":true,\"result\":[]}"),
      mock.route_with_response("sendMessage", mock.message_response()),
    ])

  let assert Ok(bot) =
    telega.new(client)
    |> telega.router(router.new("jobs"))
    |> telega.start()
  bot
}

/// `telega.shutdown` sends an abnormal exit to the root supervisor, which is
/// linked to this test process. Unlink first so tearing the tree down does not
/// take the test with it.
fn stop(bot: telega.Telega(Nil, TelegaError, Nil)) -> Nil {
  process.unlink(telega.get_supervisor_pid(bot))
  telega.shutdown(bot)
}

// --- in-memory jobs ---------------------------------------------------------

pub fn a_delayed_job_runs_once_test() {
  let bot = start_bot()
  let ran = process.new_subject()
  let assert Ok(scheduler) = jobs.new(bot) |> jobs.start()

  jobs.run_after(scheduler, delay_ms: 10, job: fn(_client) {
    process.send(ran, "once")
  })

  process.receive(ran, 1000) |> should.equal(Ok("once"))
  process.receive(ran, 100) |> should.be_error

  stop(bot)
}

pub fn a_repeating_job_keeps_running_until_it_is_cancelled_test() {
  let bot = start_bot()
  let ran = process.new_subject()
  let assert Ok(scheduler) = jobs.new(bot) |> jobs.start()

  let id =
    jobs.run_every(scheduler, interval_ms: 10, job: fn(_client) {
      process.send(ran, "tick")
    })

  process.receive(ran, 1000) |> should.equal(Ok("tick"))
  process.receive(ran, 1000) |> should.equal(Ok("tick"))

  jobs.cancel(scheduler, id)
  // Drain whatever was already in flight when the cancel landed.
  let _ = process.receive(ran, 50)
  process.receive(ran, 200) |> should.be_error

  stop(bot)
}

pub fn a_cancelled_delayed_job_never_runs_test() {
  let bot = start_bot()
  let ran = process.new_subject()
  let assert Ok(scheduler) = jobs.new(bot) |> jobs.start()

  let id =
    jobs.run_after(scheduler, delay_ms: 300, job: fn(_client) {
      process.send(ran, "should not happen")
    })
  jobs.cancel(scheduler, id)

  process.receive(ran, 500) |> should.be_error

  stop(bot)
}

// --- persisted jobs ---------------------------------------------------------

fn reminder_handler(ran: process.Subject(#(Int, String))) {
  fn(ctx: bot.Context(Nil, TelegaError, Nil), payload) {
    let text =
      decode.run(payload, decode.at(["text"], decode.string))
      |> result.unwrap("")
    process.send(ran, #(ctx.update.chat_id, text))
  }
}

pub fn a_persisted_job_runs_with_its_payload_and_chat_test() {
  let bot = start_bot()
  let ran = process.new_subject()
  let assert Ok(kv) = ets.new("jobs_persisted_run")

  let assert Ok(scheduler) =
    jobs.new(bot)
    |> jobs.with_storage(kv)
    |> jobs.with_handler("reminder", reminder_handler(ran))
    |> jobs.start()

  jobs.persisted(
    scheduler,
    id: "reminder:42",
    handler: "reminder",
    chat_id: 42,
    user_id: 7,
    at: timestamp.add(timestamp.system_time(), duration.milliseconds(10)),
    payload: json.object([#("text", json.string("stand up"))]),
  )

  process.receive(ran, 2000) |> should.equal(Ok(#(42, "stand up")))

  // A one-shot job is taken out of storage before it is dispatched.
  kv.get("job:reminder:42") |> should.equal(Ok(None))

  stop(bot)
}

pub fn a_job_whose_handler_is_not_registered_stays_in_storage_test() {
  let bot = start_bot()
  let assert Ok(kv) = ets.new("jobs_unknown_handler")

  let assert Ok(scheduler) =
    jobs.new(bot) |> jobs.with_storage(kv) |> jobs.start()

  jobs.persisted(
    scheduler,
    id: "reminder:1",
    handler: "not_registered_yet",
    chat_id: 1,
    user_id: 1,
    at: timestamp.system_time(),
    payload: json.object([]),
  )

  // Give the scheduler time to fire it and decide what to do.
  sleep(200)
  let assert Ok(option.Some(_)) = kv.get("job:reminder:1")

  stop(bot)
}

pub fn a_stored_job_is_picked_up_by_the_next_scheduler_test() {
  let bot = start_bot()
  let ran = process.new_subject()
  let assert Ok(kv) = ets.new("jobs_restart")

  // The deploy that scheduled it did not know the handler: the job is left in
  // storage rather than dropped.
  let assert Ok(first) = jobs.new(bot) |> jobs.with_storage(kv) |> jobs.start()
  jobs.persisted(
    first,
    id: "reminder:9",
    handler: "reminder",
    chat_id: 9,
    user_id: 9,
    at: timestamp.system_time(),
    payload: json.object([#("text", json.string("after restart"))]),
  )
  sleep(200)

  // The next one knows it, reads it back at start, and runs it — overdue, so
  // immediately.
  let assert Ok(_second) =
    jobs.new(bot)
    |> jobs.with_storage(kv)
    |> jobs.with_handler("reminder", reminder_handler(ran))
    |> jobs.start()

  process.receive(ran, 2000) |> should.equal(Ok(#(9, "after restart")))

  stop(bot)
}

pub fn a_repeating_persisted_job_reschedules_itself_test() {
  let bot = start_bot()
  let ran = process.new_subject()
  let assert Ok(kv) = ets.new("jobs_persisted_every")

  let assert Ok(scheduler) =
    jobs.new(bot)
    |> jobs.with_storage(kv)
    |> jobs.with_handler("digest", reminder_handler(ran))
    |> jobs.start()

  jobs.persisted_every(
    scheduler,
    id: "digest:5",
    handler: "digest",
    chat_id: 5,
    user_id: 5,
    interval_ms: 20,
    payload: json.object([#("text", json.string("digest"))]),
  )

  process.receive(ran, 2000) |> should.equal(Ok(#(5, "digest")))
  process.receive(ran, 2000) |> should.equal(Ok(#(5, "digest")))

  // Still on the books, with its next run written down.
  let assert Ok(option.Some(_)) = kv.get("job:digest:5")

  jobs.cancel(scheduler, "digest:5")
  sleep(100)
  kv.get("job:digest:5") |> should.equal(Ok(None))

  stop(bot)
}

pub fn pending_lists_what_the_scheduler_is_holding_test() {
  let bot = start_bot()
  let assert Ok(kv) = ets.new("jobs_pending")

  let assert Ok(scheduler) =
    jobs.new(bot)
    |> jobs.with_storage(kv)
    |> jobs.with_handler("later", fn(_ctx, _payload) { Nil })
    |> jobs.start()

  jobs.persisted(
    scheduler,
    id: "later:1",
    handler: "later",
    chat_id: 1,
    user_id: 1,
    at: timestamp.add(timestamp.system_time(), duration.hours(1)),
    payload: json.object([]),
  )
  let memory_id =
    jobs.run_after(scheduler, delay_ms: 60_000, job: fn(_client) { Nil })

  let assert Ok(ids) = jobs.pending(scheduler, timeout: 1000)
  ids |> list.contains("later:1") |> should.be_true
  ids |> list.contains(memory_id) |> should.be_true

  jobs.cancel(scheduler, "later:1")
  let assert Ok(ids) = jobs.pending(scheduler, timeout: 1000)
  ids |> list.contains("later:1") |> should.be_false

  stop(bot)
}

@external(erlang, "timer", "sleep")
fn sleep(milliseconds: Int) -> anything
