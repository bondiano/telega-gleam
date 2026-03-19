//// Utilities for testing individual handlers in isolation and
//// setting up full bot instances with minimal boilerplate.
////
//// ```gleam
//// import telega/testing/handler
//// import telega/testing/factory
//// import telega/testing/mock
////
//// // Test a single handler without a router
//// pub fn my_handler_test() {
////   let #(ctx, calls) = handler.test_handler(
////     session: MySession(count: 0),
////     update: factory.text_update(text: "hello"),
////     handler: fn(ctx, _update) { reply.with_text(ctx, "hi") |> result.map(fn(_) { ctx }) },
////   )
////   mock.assert_call_count(from: calls, expected: 1)
//// }
////
//// // Test with a full bot (router + actors)
//// pub fn my_bot_test() {
////   handler.with_test_bot(
////     router: build_router(),
////     session: fn() { MySession(count: 0) },
////     handler: fn(bot_subject, calls) {
////       let update = factory.command_update("start")
////       bot.handle_update(bot_subject:, update:)
////       mock.assert_call_count(from: calls, expected: 1)
////     },
////   )
//// }
//// ```

import gleam/erlang/process.{type Subject}
import gleam/option.{None}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision

import telega/bot
import telega/internal/registry
import telega/router
import telega/testing/context as test_context
import telega/testing/factory
import telega/testing/mock
import telega/update

/// Runs a handler function in isolation with a mock client.
/// Returns the resulting context and the recorded API calls subject.
///
/// Use this to test a single handler without involving the router or actor system.
pub fn test_handler(
  session session: session,
  update update: update.Update,
  handler handler: fn(bot.Context(session, error), update.Update) ->
    Result(bot.Context(session, error), error),
) -> #(Result(bot.Context(session, error), error), Subject(mock.ApiCall)) {
  let #(client, calls) = mock.message_client()
  let config = test_context.config_with_client(client)
  let ctx =
    bot.Context(
      key: "test_chat:123",
      update:,
      config:,
      session:,
      chat_subject: process.new_subject(),
      start_time: None,
      log_prefix: None,
      bot_info: factory.bot_user(),
    )
  let result = handler(ctx, update)
  #(result, calls)
}

/// Starts a full bot with router, registry, and actors using a mock client.
/// Calls `handler` with the bot subject and API calls subject, then cleans up.
///
/// Use this to test end-to-end update handling with minimal boilerplate.
pub fn with_test_bot(
  router router: router.Router(session, error),
  session default_session: fn() -> session,
  handler handler: fn(bot.BotSubject, Subject(mock.ApiCall)) -> Nil,
) -> Nil {
  with_test_bot_advanced(
    router_handler: fn(ctx, update) { router.handle(router, ctx, update) },
    session_settings: test_context.session_settings(default: default_session),
    handler:,
  )
}

/// Lower-level variant with custom router handler and session settings.
pub fn with_test_bot_advanced(
  router_handler router_handler: fn(bot.Context(session, error), update.Update) ->
    Result(bot.Context(session, error), error),
  session_settings session_settings: bot.SessionSettings(session, error),
  handler handler: fn(bot.BotSubject, Subject(mock.ApiCall)) -> Nil,
) -> Nil {
  let #(client, calls) = mock.message_client()
  let config = test_context.config_with_client(client)

  let assert Ok(reg) = registry.start("test_handler")
  let assert Ok(chat_factory_started) =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.start

  let assert Ok(started) =
    bot.start(
      registry: reg,
      config:,
      bot_info: factory.bot_user(),
      router_handler:,
      session_settings:,
      catch_handler: fn(_ctx, _err) { Ok(Nil) },
      chat_factory: chat_factory_started.data,
      name: None,
    )

  handler(started.data, calls)

  let _ = registry.stop(reg)
  Nil
}
