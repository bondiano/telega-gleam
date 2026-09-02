//// Regression tests for the reliability audit (C1–C5).
////
//// Each test reproduces a concrete failure mode that used to hang, lose, or
//// silently mis-route updates. They are deliberately written against the
//// public/`@internal` surface so they keep working as the internals change.

import gleam/erlang/process
import gleam/option.{None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleeunit/should

import telega/bot
import telega/internal/registry
import telega/testing/context
import telega/testing/factory
import telega/update as update_module

pub type Sess {
  Sess(counter: Int)
}

pub type Err {
  Err(message: String)
}

/// Session key the default factory updates resolve to (`chat_id:from_id`).
const default_key = "123456789:987654321"

fn start_test_factory() {
  let assert Ok(started) =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.start
  started.data
}

fn start_bot(
  name name: String,
  router router: fn(bot.Context(Sess, Err, Nil), update_module.Update) ->
    Result(bot.Context(Sess, Err, Nil), Err),
  catch_handler catch_handler: bot.CatchHandler(Sess, Err, Nil),
) {
  let assert Ok(reg) = registry.start(name)
  let assert Ok(started) =
    bot.start(
      registry: reg,
      config: context.config(),
      bot_info: factory.bot_user(),
      router_handler: router,
      pre_handlers: [],
      session_settings: context.session_settings_with(
        default: fn() { Sess(0) },
        initial: Sess(0),
      ),
      catch_handler:,
      dependencies: Nil,
      chat_factory: start_test_factory(),
      name: None,
    )
  #(started.data, reg)
}

/// Dispatch an update the way the poller does, but bounded: the caller runs in
/// a throwaway process so a dispatch that never answers times out here instead
/// of wedging the test suite.
fn dispatch(
  bot_subject: bot.BotSubject,
  update: update_module.Update,
  timeout: Int,
) -> Result(Bool, Nil) {
  let reply = process.new_subject()
  let _ =
    process.spawn_unlinked(fn() {
      process.send(reply, bot.handle_update(bot_subject, update))
    })
  process.receive(reply, timeout)
}

// C1 — a handler that dies must not wedge the caller forever ----------------

pub fn c1_panicking_handler_answers_the_caller_test() {
  let #(bot_subject, _reg) =
    start_bot(
      name: "c1_panic",
      router: fn(_ctx, _update) { panic as "handler exploded" },
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "hi"), 2000)
  |> should.equal(Ok(False))
}

pub fn c1_failing_catch_handler_answers_the_caller_test() {
  let #(bot_subject, _reg) =
    start_bot(
      name: "c1_catch_fail",
      router: fn(_ctx, _update) { Error(Err("boom")) },
      catch_handler: fn(_ctx, e) { Error(e) },
    )

  dispatch(bot_subject, factory.text_update(text: "hi"), 2000)
  |> should.equal(Ok(False))
}

pub fn c1_failing_persist_answers_the_caller_test() {
  let assert Ok(reg) = registry.start("c1_persist_fail")
  let assert Ok(started) =
    bot.start(
      registry: reg,
      config: context.config(),
      bot_info: factory.bot_user(),
      router_handler: fn(ctx, _update) { Ok(ctx) },
      pre_handlers: [],
      session_settings: bot.SessionSettings(
        persist_session: fn(_key, _session) { Error(Err("storage down")) },
        get_session: fn(_key) { Ok(Some(Sess(0))) },
        default_session: fn() { Sess(0) },
      ),
      catch_handler: fn(_ctx, e) { Error(e) },
      dependencies: Nil,
      chat_factory: start_test_factory(),
      name: None,
    )

  dispatch(started.data, factory.text_update(text: "hi"), 2000)
  |> should.equal(Ok(False))
}
