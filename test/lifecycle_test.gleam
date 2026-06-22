import gleam/erlang/process
import gleam/option.{Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleeunit/should

import telega/bot
import telega/internal/registry
import telega/testing/context
import telega/testing/factory

pub type TestSession {
  TestSession(counter: Int)
}

pub type TestError {
  TestError(message: String)
}

fn start_test_factory() {
  let assert Ok(started) =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.start
  started.data
}

fn start_named_bot(
  registry_name: String,
  router_handler: fn(bot.Context(TestSession, TestError, Nil), _) ->
    Result(bot.Context(TestSession, TestError, Nil), TestError),
) -> bot.BotSubject {
  let assert Ok(registry) = registry.start(registry_name)
  let config = context.config()
  let bot_info = factory.bot_user()
  let session_settings =
    context.session_settings_with(
      default: fn() { TestSession(counter: 0) },
      initial: TestSession(counter: 0),
    )
  let catch_handler = context.catch_handler()
  let chat_factory = start_test_factory()
  let name = process.new_name("lifecycle_bot")

  let assert Ok(started) =
    bot.start(
      registry:,
      config:,
      bot_info:,
      router_handler:,
      pre_handlers: [],
      session_settings:,
      catch_handler:,
      dependencies: Nil,
      chat_factory:,
      name: Some(name),
    )

  started.data
}

pub fn drain_with_no_in_flight_returns_zero_test() {
  let bot_subject =
    start_named_bot("drain_no_in_flight_test", fn(ctx, _update) { Ok(ctx) })

  bot.drain(bot_subject, 1000)
  |> should.equal(0)
}

pub fn drain_sets_draining_and_rejects_updates_test() {
  let bot_subject =
    start_named_bot("drain_rejects_test", fn(ctx, _update) { Ok(ctx) })

  bot.is_draining(bot_subject)
  |> should.be_false

  let _ = bot.drain(bot_subject, 1000)

  bot.is_draining(bot_subject)
  |> should.be_true

  // New updates are rejected (not handled) while draining.
  bot.handle_update(bot_subject, factory.text_update(text: "after drain"))
  |> should.be_false
}

pub fn drain_waits_for_in_flight_test() {
  let bot_subject =
    start_named_bot("drain_waits_test", fn(ctx, _update) {
      // Simulate a slow handler so the update is in-flight during drain.
      process.sleep(200)
      Ok(ctx)
    })

  // Dispatch an update from another process — it blocks until handled.
  process.spawn(fn() {
    let _ = bot.handle_update(bot_subject, factory.text_update(text: "slow"))
    Nil
  })

  // Give the bot time to spawn the chat instance and start handling.
  process.sleep(100)

  // Drain should wait for the in-flight update and report it as drained.
  bot.drain(bot_subject, 3000)
  |> should.equal(1)
}
