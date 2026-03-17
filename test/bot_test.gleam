import gleam/list
import gleam/option.{None, Some}
import gleam/string
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

pub fn bot_start_test() {
  let assert Ok(registry) = registry.start()
  let config = context.config()
  let bot_info = factory.bot_user()
  let router_handler = fn(ctx, _update) { Ok(ctx) }
  let session_settings =
    context.session_settings_with(
      default: fn() { TestSession(counter: 0) },
      initial: TestSession(counter: 0),
    )
  let catch_handler = context.catch_handler()

  let result =
    bot.start(
      registry:,
      config:,
      bot_info:,
      router_handler:,
      session_settings:,
      catch_handler:,
    )

  result
  |> should.be_ok
}

pub fn bot_handle_update_test() {
  let assert Ok(registry) = registry.start()
  let config = context.config()
  let bot_info = factory.bot_user()
  let router_handler = fn(ctx, _update) { Ok(ctx) }
  let session_settings =
    context.session_settings_with(
      default: fn() { TestSession(counter: 0) },
      initial: TestSession(counter: 0),
    )
  let catch_handler = context.catch_handler()

  let assert Ok(bot_subject) =
    bot.start(
      registry:,
      config:,
      bot_info:,
      router_handler:,
      session_settings:,
      catch_handler:,
    )

  let test_update = factory.text_update(text: "Hello")
  let result = bot.handle_update(bot_subject, test_update)

  result |> should.be_true
}

pub fn session_settings_test() {
  let session_settings =
    bot.SessionSettings(
      persist_session: fn(key, session) {
        { key |> string.length > 0 } |> should.be_true
        Ok(session)
      },
      get_session: fn(key) {
        { key |> string.length > 0 } |> should.be_true
        Ok(Some(TestSession(counter: 42)))
      },
      default_session: fn() { TestSession(counter: 0) },
    )

  let default = session_settings.default_session()
  default.counter |> should.equal(0)

  let assert Ok(Some(retrieved)) = session_settings.get_session("test_key")
  retrieved.counter |> should.equal(42)

  let assert Ok(persisted) =
    session_settings.persist_session("test_key", TestSession(counter: 100))
  persisted.counter |> should.equal(100)
}

pub fn context_next_session_test() {
  let assert Ok(_registry) = registry.start()

  let ctx: bot.Context(TestSession, TestError) =
    context.context_with(
      session: TestSession(counter: 5),
      update: factory.text_update(text: "Hello"),
    )

  let new_session = TestSession(counter: 10)
  let assert Ok(updated_ctx) = bot.next_session(ctx, new_session)

  updated_ctx.session.counter |> should.equal(10)
  updated_ctx.key |> should.equal("test_chat:123")
}

pub fn get_session_test() {
  let session_settings: bot.SessionSettings(TestSession, TestError) =
    context.session_settings_with(
      default: fn() { TestSession(counter: 0) },
      initial: TestSession(counter: 0),
    )
  let test_update = factory.text_update(text: "Hello")

  let result = bot.get_session(session_settings, test_update)

  result |> should.be_ok
  let assert Ok(Some(session)) = result
  session.counter |> should.equal(0)
}

pub fn handler_types_test() {
  let _test_ctx: bot.Context(TestSession, TestError) =
    context.context(session: TestSession(counter: 0))

  let handle_all = bot.HandleAll(fn(ctx, _update) { Ok(ctx) })

  let handle_text = bot.HandleText(fn(ctx, _text) { Ok(ctx) })

  let handle_command = bot.HandleCommand("start", fn(ctx, _command) { Ok(ctx) })

  [handle_all, handle_text, handle_command]
  |> list.length
  |> should.equal(3)
}

pub fn wait_handler_test() {
  let ctx: bot.Context(TestSession, TestError) =
    context.context(session: TestSession(counter: 0))

  let handler = bot.HandleText(fn(ctx, _text) { Ok(ctx) })
  let result =
    bot.wait_handler(ctx:, handler:, handle_else: None, timeout: Some(1000))

  should.be_ok(result)
}
