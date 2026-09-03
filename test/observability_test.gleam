import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleeunit/should

import telega
import telega/bot
import telega/dead_letter
import telega/internal/log
import telega/internal/registry
import telega/router
import telega/storage
import telega/storage/ets
import telega/telemetry
import telega/testing/context as test_context
import telega/testing/factory
import telega/testing/handler as test_handler
import telega/testing/mock
import telega/update as update_module

// Telemetry plumbing ----------------------------------------------------------

type Event {
  Event(
    name: List(String),
    measurements: List(#(String, Int)),
    metadata: List(#(String, telemetry.Value)),
  )
}

fn attach_forwarder(
  id id: String,
  events events: List(List(String)),
) -> Subject(Event) {
  let subject = process.new_subject()
  telemetry.attach_many(id:, events:, handler: fn(name, measurements, metadata) {
    process.send(subject, Event(name:, measurements:, metadata:))
  })
  subject
}

fn string_metadata(event: Event, key: String) -> Result(String, Nil) {
  case list.key_find(event.metadata, key) {
    Ok(telemetry.StringValue(value)) -> Ok(value)
    _ -> Error(Nil)
  }
}

fn receive_stop(subject: Subject(Event)) -> Event {
  let assert Ok(event) = process.receive(subject, 500)
  event
}

// Route metadata --------------------------------------------------------------

fn dispatch(router: router.Router(Nil, e, Nil), update) -> Nil {
  use bot_subject, _calls <- test_handler.with_test_bot(router:, session: fn() {
    Nil
  })
  bot.handle_update(bot_subject:, update:) |> should.be_true
}

pub fn update_stop_carries_matched_command_route_test() {
  let subject =
    attach_forwarder(id: "obs-route-command", events: [
      ["telega", "update", "stop"],
    ])

  router.new("main")
  |> router.on_command("start", fn(ctx, _cmd) { Ok(ctx) })
  |> dispatch(factory.command_update(command: "/start"))

  let event = receive_stop(subject)
  string_metadata(event, "route") |> should.equal(Ok("command:/start"))
  string_metadata(event, "router") |> should.equal(Ok("main"))

  telemetry.detach("obs-route-command")
}

pub fn update_stop_carries_text_route_test() {
  let subject =
    attach_forwarder(id: "obs-route-text", events: [
      ["telega", "update", "stop"],
    ])

  router.new("texts")
  |> router.on_text(router.Exact("hi"), fn(ctx, _text) { Ok(ctx) })
  |> dispatch(factory.text_update(text: "hi"))

  let event = receive_stop(subject)
  string_metadata(event, "route") |> should.equal(Ok("text:exact:hi"))

  telemetry.detach("obs-route-text")
}

pub fn update_stop_reports_unmatched_route_test() {
  let subject =
    attach_forwarder(id: "obs-route-none", events: [
      ["telega", "update", "stop"],
    ])

  router.new("empty")
  |> dispatch(factory.text_update(text: "nothing matches this"))

  let event = receive_stop(subject)
  string_metadata(event, "route") |> should.equal(Ok("unmatched"))

  telemetry.detach("obs-route-none")
}

pub fn update_stop_reports_fallback_route_test() {
  let subject =
    attach_forwarder(id: "obs-route-fallback", events: [
      ["telega", "update", "stop"],
    ])

  router.new("catchall")
  |> router.fallback(fn(ctx, _update) { Ok(ctx) })
  |> dispatch(factory.text_update(text: "anything"))

  let event = receive_stop(subject)
  string_metadata(event, "route") |> should.equal(Ok("fallback"))

  telemetry.detach("obs-route-fallback")
}

pub fn tree_branch_is_named_in_metadata_test() {
  let subject =
    attach_forwarder(id: "obs-route-branch", events: [
      ["telega", "update", "stop"],
    ])

  let private =
    router.new("private")
    |> router.on_command("start", fn(ctx, _cmd) { Ok(ctx) })
  let tree = router.tree() |> router.branch(router.is_private_chat(), private)

  use bot_subject, _calls <- test_handler.with_test_bot_advanced(
    router_handler: fn(ctx, update) { router.handle_tree(tree, ctx, update) },
    session_settings: test_context.session_settings(default: fn() { Nil }),
  )
  bot.handle_update(bot_subject:, update: factory.command_update("/start"))
  |> should.be_true

  let event = receive_stop(subject)
  string_metadata(event, "router") |> should.equal(Ok("private"))
  string_metadata(event, "route") |> should.equal(Ok("command:/start"))

  telemetry.detach("obs-route-branch")
}

pub fn matched_route_is_readable_from_a_handler_test() {
  let seen = process.new_subject()
  let router =
    router.new("main")
    |> router.on_command("ping", fn(ctx, _cmd) {
      process.send(seen, #(
        router.matched_route(ctx),
        router.matched_router(ctx),
      ))
      Ok(ctx)
    })

  let ctx = test_context.context(session: Nil)
  let assert Ok(_) =
    router.handle(router, ctx, factory.command_update(command: "/ping"))

  process.receive(seen, 100)
  |> should.equal(Ok(#(Some("command:/ping"), Some("main"))))
}

pub fn matched_route_is_empty_outside_routing_test() {
  let ctx = test_context.context(session: Nil)
  router.matched_route(ctx) |> should.equal(None)
  router.matched_router(ctx) |> should.equal(None)
}

// Structured log metadata -----------------------------------------------------

@external(erlang, "logger", "get_process_metadata")
fn logger_process_metadata() -> dynamic_metadata

pub fn log_metadata_is_set_and_restored_test() {
  let before = logger_process_metadata()

  let inside =
    log.with_metadata(
      fields: [#("chat_id", "42"), #("update_id", "7")],
      run: fn() { logger_process_metadata() },
    )

  // Something was set while running…
  inside |> should.not_equal(before)
  // …and the process is back to how we found it afterwards.
  logger_process_metadata() |> should.equal(before)
}

// Health ----------------------------------------------------------------------

pub fn health_status_codes_test() {
  telega.Healthy(in_flight: 0, chat_instances: 0)
  |> telega.health_status_code
  |> should.equal(200)

  telega.Draining(in_flight: 1, chat_instances: 1)
  |> telega.health_status_code
  |> should.equal(503)

  telega.Overloaded(in_flight: 9, chat_instances: 3, max_in_flight: 9)
  |> telega.health_status_code
  |> should.equal(503)

  telega.Unavailable |> telega.health_status_code |> should.equal(503)
}

pub fn health_json_shapes_test() {
  telega.Healthy(in_flight: 2, chat_instances: 5)
  |> telega.health_to_json
  |> should.equal(
    "{\"status\":\"healthy\",\"in_flight\":2,\"chat_instances\":5}",
  )

  telega.Unavailable
  |> telega.health_to_json
  |> should.equal("{\"status\":\"unavailable\"}")
}

pub fn only_healthy_is_healthy_test() {
  telega.is_healthy(telega.Healthy(in_flight: 0, chat_instances: 0))
  |> should.be_true
  telega.is_healthy(telega.Draining(in_flight: 0, chat_instances: 0))
  |> should.be_false
  telega.is_healthy(telega.Unavailable) |> should.be_false
}

pub fn bot_reports_live_instance_count_test() {
  use bot_subject, _calls <- test_handler.with_test_bot(
    router: router.new("main")
      |> router.on_command("start", fn(ctx, _cmd) { Ok(ctx) }),
    session: fn() { Nil },
  )

  let assert Some(before) =
    bot.health(bot_subject:, timeout: bot.health_timeout)
  before.draining |> should.be_false
  before.in_flight |> should.equal(0)

  bot.handle_update(bot_subject:, update: factory.command_update("/start"))
  |> should.be_true

  let assert Some(after) = bot.health(bot_subject:, timeout: bot.health_timeout)
  after.chat_instances |> should.equal(1)
  // The update was answered before we asked, so nothing is in flight.
  after.in_flight |> should.equal(0)
}

pub fn draining_bot_reports_draining_test() {
  use bot_subject, _calls <- test_handler.with_test_bot(
    router: router.new("main"),
    session: fn() { Nil },
  )

  bot.drain(bot_subject:, timeout: 500) |> should.equal(0)

  let assert Some(health) =
    bot.health(bot_subject:, timeout: bot.health_timeout)
  health.draining |> should.be_true
  bot.is_draining(bot_subject:) |> should.be_true
}

pub fn dead_bot_reports_unavailable_test() {
  let subject: bot.BotSubject = process.new_subject()
  bot.health(bot_subject: subject, timeout: 50) |> should.equal(None)
}

// Dead letters ----------------------------------------------------------------

fn test_dead_letters(name: String) -> dead_letter.DeadLetters {
  let assert Ok(kv) = ets.new(name)
  storage.dead_letters_from_storage(kv, retention_ms: None)
}

pub fn dead_letter_round_trip_test() {
  let letters = test_dead_letters("dlq_round_trip")
  let raw = factory.raw_update(message: factory.message(text: "boom"))

  let assert Ok(Nil) =
    dead_letter.record(letters:, update: raw, reason: "badmatch")

  let assert Ok(#([stored], [])) = dead_letter.list(letters)
  stored.key |> should.equal(dead_letter.key_for(raw))
  stored.reason |> should.equal("badmatch")
  stored.update.update_id |> should.equal(raw.update_id)

  let assert Ok(Nil) = dead_letter.drop(letters:, key: stored.key)
  dead_letter.list(letters) |> should.equal(Ok(#([], [])))
}

pub fn dead_letters_are_ordered_by_update_id_test() {
  let letters = test_dead_letters("dlq_ordering")
  let message = factory.message(text: "x")

  list.each([9, 10, 2], fn(id) {
    let raw = factory.raw_update_with(message:, update_id: id)
    let assert Ok(Nil) = dead_letter.record(letters:, update: raw, reason: "e")
  })

  let assert Ok(#(stored, [])) = dead_letter.list(letters)
  stored
  |> list.map(fn(letter) { letter.update.update_id })
  |> should.equal([2, 9, 10])
}

pub fn crashing_handler_is_dead_lettered_test() {
  let letters = test_dead_letters("dlq_crash")
  let update = factory.command_update(command: "/boom")

  with_crashing_bot(Some(letters), fn(bot_subject) {
    dispatch_off_thread(bot_subject, update) |> should.equal(Ok(False))
  })

  // The write happens in a process the bot spawns, so give it a moment.
  let assert Ok(#([stored], [])) = eventually_one(letters, 20)
  stored.update.update_id
  |> should.equal(update_module.raw(update).update_id)
}

pub fn no_queue_means_nothing_is_stored_test() {
  let letters = test_dead_letters("dlq_absent")

  with_crashing_bot(None, fn(bot_subject) {
    dispatch_off_thread(bot_subject, factory.command_update("/boom"))
    |> should.equal(Ok(False))
  })

  // A bot built without `with_dead_letters` writes nowhere, so the queue we
  // did not give it stays empty.
  process.sleep(100)
  dead_letter.list(letters) |> should.equal(Ok(#([], [])))
}

/// Dispatch the way the poller does, but from a throwaway process: a handler
/// that panics must take its chat instance down, not the test.
fn dispatch_off_thread(
  bot_subject: bot.BotSubject,
  update: update_module.Update,
) -> Result(Bool, Nil) {
  let reply = process.new_subject()
  let _ =
    process.spawn_unlinked(fn() {
      process.send(reply, bot.handle_update(bot_subject:, update:))
    })
  process.receive(reply, 2000)
}

fn eventually_one(letters: dead_letter.DeadLetters, attempts: Int) {
  case dead_letter.list(letters) {
    Ok(#([_, ..], _)) as found -> found
    other ->
      case attempts {
        0 -> other
        _ -> {
          process.sleep(25)
          eventually_one(letters, attempts - 1)
        }
      }
  }
}

/// A bot whose router always panics.
///
/// The registry is deliberately **not** stopped afterwards: the factory
/// supervisor restarts the dead chat instance a moment after `run` returns,
/// and a restart into a deleted ETS table loops until the supervisor gives up
/// and takes the test process with it.
fn with_crashing_bot(
  letters: Option(dead_letter.DeadLetters),
  run: fn(bot.BotSubject) -> Nil,
) -> Nil {
  let #(client, _calls) = mock.message_client()
  let config = test_context.config_with_client(client)

  let assert Ok(reg) = registry.start("dlq_test")
  let assert Ok(chat_factory) =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.start

  let assert Ok(started) =
    bot.start(
      registry: reg,
      config:,
      bot_info: factory.bot_user(),
      router_handler: fn(_ctx, _update) { panic as "handler exploded" },
      pre_handlers: [],
      session_settings: test_context.session_settings(default: fn() { Nil }),
      catch_handler: fn(_ctx, _err) { Ok(Nil) },
      dependencies: Nil,
      chat_factory: chat_factory.data,
      chat_settings: bot.default_chat_settings(),
      dead_letters: letters,
      name: None,
    )

  run(started.data)
}
