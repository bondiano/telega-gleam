import gleam/erlang/process
import gleam/option.{None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleam/result
import gleeunit/should

import telega/bot
import telega/internal/registry
import telega/testing/context
import telega/testing/factory
import telega/update

pub type TestSession {
  TestSession(name: String)
}

pub type TestError {
  TestError(message: String)
}

fn handlers_to_router_handler(
  handlers: List(bot.Handler(TestSession, TestError)),
) -> fn(bot.Context(TestSession, TestError), update.Update) ->
  Result(bot.Context(TestSession, TestError), TestError) {
  fn(ctx, upd) {
    list.find_map(handlers, fn(handler) {
      case handler, upd {
        bot.HandleCommand(command:, handler:),
          update.CommandUpdate(command: cmd, ..)
          if cmd.command == command
        -> Ok(handler(ctx, cmd))
        bot.HandleText(handler:), update.TextUpdate(text:, ..) ->
          Ok(handler(ctx, text))
        bot.HandleAll(handler:), _ -> Ok(handler(ctx, upd))
        _, _ -> Error(Nil)
      }
    })
    |> result.unwrap(Ok(ctx))
  }
}

import gleam/list

fn start_test_factory() {
  let assert Ok(started) =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.start
  started.data
}

fn build_test_bot(
  router_handler: fn(bot.Context(TestSession, TestError), update.Update) ->
    Result(bot.Context(TestSession, TestError), TestError),
  session_settings: bot.SessionSettings(TestSession, TestError),
) -> bot.BotSubject {
  let assert Ok(registry) = registry.start("conv_test")
  let config = context.config()
  let bot_info = factory.bot_user()
  let catch_handler = context.catch_handler()
  let chat_factory = start_test_factory()

  let assert Ok(started) =
    bot.start(
      registry:,
      config:,
      bot_info:,
      router_handler:,
      session_settings:,
      catch_handler:,
      chat_factory:,
      name: None,
    )

  started.data
}

pub fn basic_conversation_flow_test() {
  let handlers = [
    bot.HandleCommand("setname", fn(ctx, _command) {
      bot.wait_handler(
        ctx: ctx,
        handler: bot.HandleText(fn(ctx, name) {
          bot.next_session(ctx, TestSession(name:))
        }),
        handle_else: None,
        timeout: Some(5000),
      )
    }),
  ]

  let session_settings =
    context.session_settings(default: fn() { TestSession(name: "") })
  let bot_subject =
    build_test_bot(handlers_to_router_handler(handlers), session_settings)

  let result1 =
    bot.handle_update(bot_subject, factory.command_update(command: "setname"))
  result1 |> should.be_true

  let result2 =
    bot.handle_update(bot_subject, factory.text_update(text: "John Doe"))
  result2 |> should.be_true
}

pub fn conversation_with_session_persistence_test() {
  let session_storage = process.new_subject()
  let name_storage = process.new_subject()

  let session_settings =
    bot.SessionSettings(
      persist_session: fn(key, session) {
        process.send(session_storage, #("persist", key, session))
        Ok(session)
      },
      get_session: fn(_key) { Ok(None) },
      default_session: fn() { TestSession(name: "default") },
    )

  let handlers = [
    bot.HandleCommand("setname", fn(ctx, _command) {
      let TestSession(name: current_name) = ctx.session
      current_name |> should.equal("default")

      bot.wait_handler(
        ctx:,
        handler: bot.HandleText(fn(ctx, name) {
          bot.next_session(ctx, TestSession(name:))
        }),
        handle_else: None,
        timeout: Some(5000),
      )
    }),
    bot.HandleCommand("getname", fn(ctx, _command) {
      let TestSession(name: current_name) = ctx.session
      process.send(name_storage, current_name)
      Ok(ctx)
    }),
  ]

  let bot_subject =
    build_test_bot(handlers_to_router_handler(handlers), session_settings)

  let result1 =
    bot.handle_update(bot_subject, factory.command_update(command: "setname"))
  result1 |> should.be_true

  let result2 =
    bot.handle_update(bot_subject, factory.text_update(text: "Alice"))
  result2 |> should.be_true

  let result3 =
    bot.handle_update(bot_subject, factory.command_update(command: "getname"))
  result3 |> should.be_true

  let assert Ok(#("persist", _key1, first_session)) =
    process.receive(session_storage, 3000)
  let TestSession(name: first_name) = first_session
  first_name |> should.equal("default")

  case process.receive(session_storage, 1000) {
    Ok(#("persist", _key2, second_session)) -> {
      let TestSession(name: second_name) = second_session
      second_name |> should.equal("Alice")
    }
    Ok(_other) ->
      panic as "Got unexpected message format for second persist call"
    Error(_timeout) ->
      panic as "No second persist call - continuation was never triggered"
  }

  let assert Ok(current_name) = process.receive(name_storage, 1000)
  current_name |> should.equal("Alice")
}

pub fn conversation_timeout_test() {
  let handlers = [
    bot.HandleCommand("setname", fn(ctx, _command) {
      bot.wait_handler(
        ctx:,
        handler: bot.HandleText(fn(ctx, name) {
          bot.next_session(ctx, TestSession(name:))
        }),
        handle_else: None,
        timeout: Some(100),
      )
    }),
  ]

  let session_settings =
    context.session_settings(default: fn() { TestSession(name: "") })
  let bot_subject =
    build_test_bot(handlers_to_router_handler(handlers), session_settings)

  let result1 =
    bot.handle_update(bot_subject, factory.command_update(command: "setname"))
  result1 |> should.be_true

  let result2 =
    bot.handle_update(bot_subject, factory.text_update(text: "Alice"))
  result2 |> should.be_true
}

pub fn conversation_with_handle_else_test() {
  let session_storage = process.new_subject()

  let session_settings =
    bot.SessionSettings(
      persist_session: fn(key, session) {
        process.send(session_storage, #("persist", key, session))
        Ok(session)
      },
      get_session: fn(_key) { Ok(None) },
      default_session: fn() { TestSession(name: "default") },
    )

  let handlers = [
    bot.HandleCommand("setname", fn(ctx, _command) {
      bot.wait_handler(
        ctx: ctx,
        handler: bot.HandleText(fn(ctx, name) {
          bot.next_session(ctx, TestSession(name:))
        }),
        handle_else: Some(
          bot.HandleCommand("cancel", fn(ctx, _) {
            bot.next_session(ctx, TestSession(name: "cancelled"))
          }),
        ),
        timeout: Some(5000),
      )
    }),
  ]

  let bot_subject =
    build_test_bot(handlers_to_router_handler(handlers), session_settings)

  let result1 =
    bot.handle_update(bot_subject, factory.command_update(command: "setname"))
  result1 |> should.be_true

  let result2 =
    bot.handle_update(bot_subject, factory.command_update(command: "cancel"))
  result2 |> should.be_true

  let assert Ok(#("persist", _key1, first_session)) =
    process.receive(session_storage, 3000)
  let TestSession(name: first_name) = first_session
  first_name |> should.equal("default")

  case process.receive(session_storage, 1000) {
    Ok(#("persist", _key2, second_session)) -> {
      let TestSession(name: second_name) = second_session
      second_name |> should.equal("cancelled")
    }
    Ok(_other) ->
      panic as "Got unexpected message format for second persist call"
    Error(_timeout) ->
      panic as "No second persist call - handle_else was never triggered"
  }
}
