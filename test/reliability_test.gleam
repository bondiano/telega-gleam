//// Regression tests for the reliability audit (C1–C5).
////
//// Each test reproduces a concrete failure mode that used to hang, lose, or
//// silently mis-route updates. They are deliberately written against the
//// public/`@internal` surface so they keep working as the internals change.

import gleam/erlang/process
import gleam/option.{None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleam/regexp
import gleeunit/should

import telega
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

// C2 — a stopped chat instance must not poison the registry -----------------

pub fn c2_stopped_chat_instance_is_unregistered_test() {
  let #(bot_subject, reg) =
    start_bot(
      name: "c2_registry",
      router: fn(ctx, update) {
        case update {
          update_module.TextUpdate(text: "fail", ..) -> Error(Err("boom"))
          _ -> Ok(ctx)
        }
      },
      catch_handler: fn(_ctx, e) { Error(e) },
    )

  dispatch(bot_subject, factory.text_update(text: "fail"), 2000)
  |> should.equal(Ok(False))

  process.sleep(100)
  registry.get(reg, key: default_key)
  |> should.equal(None)

  // The user must still be served after their instance was torn down.
  dispatch(bot_subject, factory.text_update(text: "ok"), 2000)
  |> should.equal(Ok(True))
}

// C4 — `wait_*` filters must actually filter --------------------------------

fn wait_router(
  events: process.Subject(String),
  handler: bot.Handler(Sess, Err, Nil),
) {
  fn(ctx: bot.Context(Sess, Err, Nil), update) {
    case update {
      update_module.TextUpdate(text: "start", ..) ->
        bot.wait_handler(
          ctx:,
          handler:,
          handle_else: Some(
            bot.HandleAll(fn(ctx, _update) {
              process.send(events, "else")
              Ok(ctx)
            }),
          ),
          timeout: None,
        )
      _ -> Ok(ctx)
    }
  }
}

pub fn c4_wait_command_ignores_other_commands_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "c4_command",
      router: wait_router(
        events,
        bot.HandleCommand("confirm", fn(ctx, _command) {
          process.send(events, "confirm")
          Ok(ctx)
        }),
      ),
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let _ = dispatch(bot_subject, factory.command_update(command: "cancel"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("else"))
}

pub fn c4_wait_command_still_matches_its_command_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "c4_command_match",
      router: wait_router(
        events,
        bot.HandleCommand("confirm", fn(ctx, _command) {
          process.send(events, "confirm")
          Ok(ctx)
        }),
      ),
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let _ =
    dispatch(bot_subject, factory.command_update(command: "confirm"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("confirm"))
}

pub fn c4_wait_hears_ignores_non_matching_text_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "c4_hears",
      router: wait_router(
        events,
        bot.HandleHears(bot.HearText("yes"), fn(ctx, _text) {
          process.send(events, "hears")
          Ok(ctx)
        }),
      ),
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let _ = dispatch(bot_subject, factory.text_update(text: "no"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("else"))
}

pub fn c4_wait_callback_query_ignores_non_matching_data_test() {
  let assert Ok(re) = regexp.from_string("^accept$")
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "c4_callback",
      router: wait_router(
        events,
        bot.HandleCallbackQuery(
          bot.CallbackQueryFilter(re:),
          fn(ctx, _data, _id) {
            process.send(events, "callback")
            Ok(ctx)
          },
        ),
      ),
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let _ =
    dispatch(bot_subject, factory.callback_query_update(data: "decline"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("else"))
}

pub fn c4_wait_for_runs_the_fallback_on_a_filter_miss_test() {
  let events = process.new_subject()
  let #(bot_subject, _reg) =
    start_bot(
      name: "c4_wait_for",
      router: fn(ctx: bot.Context(Sess, Err, Nil), update) {
        case update {
          update_module.TextUpdate(text: "start", ..) ->
            telega.wait_for(
              ctx:,
              filter: fn(update) {
                case update {
                  update_module.PhotoUpdate(..) -> True
                  _ -> False
                }
              },
              or: Some(
                bot.HandleAll(fn(ctx, _update) {
                  process.send(events, "else")
                  Ok(ctx)
                }),
              ),
              timeout: None,
              continue: fn(ctx, _update) {
                process.send(events, "photo")
                Ok(ctx)
              },
            )
          _ -> Ok(ctx)
        }
      },
      catch_handler: context.catch_handler(),
    )

  dispatch(bot_subject, factory.text_update(text: "start"), 2000)
  |> should.equal(Ok(True))
  let _ = dispatch(bot_subject, factory.text_update(text: "not a photo"), 2000)

  process.receive(events, 1000)
  |> should.equal(Ok("else"))

  // Still waiting: the matching update resumes the conversation.
  let _ = dispatch(bot_subject, factory.photo_update(), 2000)
  process.receive(events, 1000)
  |> should.equal(Ok("photo"))
}
