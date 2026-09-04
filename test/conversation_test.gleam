import gleam/erlang/process
import gleam/option.{None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleam/result
import gleeunit/should

import telega
import telega/bot
import telega/internal/config
import telega/internal/registry
import telega/model/types
import telega/router
import telega/testing/context
import telega/testing/factory
import telega/testing/mock
import telega/update

pub type TestSession {
  TestSession(name: String)
}

pub type TestError {
  TestError(message: String)
}

fn handlers_to_router_handler(
  handlers: List(bot.Handler(TestSession, TestError, Nil)),
) -> fn(bot.Context(TestSession, TestError, Nil), update.Update) ->
  Result(bot.Context(TestSession, TestError, Nil), TestError) {
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
  router_handler: fn(bot.Context(TestSession, TestError, Nil), update.Update) ->
    Result(bot.Context(TestSession, TestError, Nil), TestError),
  session_settings: bot.SessionSettings(TestSession, TestError),
) -> bot.BotSubject {
  build_test_bot_with_config(context.config(), router_handler, session_settings)
}

fn build_test_bot_with_config(
  config: config.Config,
  router_handler: fn(bot.Context(TestSession, TestError, Nil), update.Update) ->
    Result(bot.Context(TestSession, TestError, Nil), TestError),
  session_settings: bot.SessionSettings(TestSession, TestError),
) -> bot.BotSubject {
  let assert Ok(registry) = registry.start("conv_test")
  let bot_info = factory.bot_user()
  let catch_handler = context.catch_handler()
  let chat_factory = start_test_factory()

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
      chat_settings: bot.ChatSettings(
        ..bot.default_chat_settings(),
        idle_timeout: None,
        init_timeout: 5000,
        media_group_timeout: option.None,
      ),
      dead_letters: None,
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

  // `/setname` only arms the wait, and `/getname` only reads: neither changed
  // the session, so under the default `PersistOnChange` neither is written
  // back. The only write is the one the continuation actually made.
  let assert Ok(#("persist", _key, session)) =
    process.receive(session_storage, 3000)
  let TestSession(name:) = session
  name |> should.equal("Alice")

  process.receive(session_storage, 200) |> should.be_error

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

  // `/setname` left the session as it found it, so the only write is the one
  // `handle_else` made.
  case process.receive(session_storage, 3000) {
    Ok(#("persist", _key, session)) -> {
      let TestSession(name:) = session
      name |> should.equal("cancelled")
    }
    Ok(_other) -> panic as "Got unexpected message format for the persist call"
    Error(_timeout) ->
      panic as "No persist call - handle_else was never triggered"
  }
}

/// `wait_filtered` lets one continuation wait for several update types at once
/// via the router's `or`/`and` combinators. Here we wait for text OR photo: a
/// non-matching voice update keeps the chat waiting, and the following photo
/// resolves the continuation with the raw update for type discrimination.
pub fn wait_filtered_or_combinator_test() {
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
    bot.HandleCommand("waitmedia", fn(ctx, _command) {
      telega.wait_filtered(
        ctx:,
        filter: router.or2(router.is_text(), router.has_photo()),
        or: None,
        timeout: Some(5000),
        continue: fn(ctx, upd) {
          let marker = case upd {
            update.TextUpdate(text:, ..) -> "text:" <> text
            update.PhotoUpdate(..) -> "photo"
            _ -> "other"
          }
          bot.next_session(ctx, TestSession(name: marker))
        },
      )
    }),
  ]

  let bot_subject =
    build_test_bot(handlers_to_router_handler(handlers), session_settings)

  bot.handle_update(bot_subject, factory.command_update(command: "waitmedia"))
  |> should.be_true

  // Voice does not match text|photo -> reported unhandled (there is no `or:`
  // handler), and the continuation stays armed.
  bot.handle_update(bot_subject, factory.voice_update())
  |> should.be_false

  // Photo matches -> continuation fires with the raw PhotoUpdate.
  bot.handle_update(bot_subject, factory.photo_update())
  |> should.be_true

  // Drain persists until we see the photo marker (proves the photo branch ran).
  let resolved = drain_until_marker(session_storage, "photo")
  resolved |> should.be_true
}

fn drain_until_marker(
  storage: process.Subject(#(String, String, TestSession)),
  marker: String,
) -> Bool {
  case process.receive(storage, 1000) {
    Ok(#("persist", _key, TestSession(name:))) if name == marker -> True
    Ok(_other) -> drain_until_marker(storage, marker)
    Error(_timeout) -> False
  }
}

pub fn wait_choice_sends_prompt_text_test() {
  let #(api_client, calls) = mock.message_client()

  let handlers = [
    bot.HandleCommand("pick", fn(ctx, _command) {
      use ctx, colour <- telega.wait_choice(
        ctx:,
        text: "Pick a colour",
        options: [#("Red", "red"), #("Blue", "blue")],
        or: None,
        timeout: Some(5000),
      )
      bot.next_session(ctx, TestSession(name: colour))
    }),
  ]

  let session_settings =
    context.session_settings(default: fn() { TestSession(name: "") })
  let bot_subject =
    build_test_bot_with_config(
      context.config_with_client(api_client),
      handlers_to_router_handler(handlers),
      session_settings,
    )

  bot.handle_update(bot_subject, factory.command_update(command: "pick"))
  |> should.be_true

  mock.assert_called_with_body(
    from: calls,
    path_contains: "sendMessage",
    body_contains: "Pick a colour",
  )
  Nil
}

// M9 — a command must not be swallowed by a bare `wait_*` --------------------

pub fn command_reaches_the_router_during_a_bare_wait_test() {
  let seen = process.new_subject()

  let handlers = [
    bot.HandleCommand("setname", fn(ctx, _command) {
      bot.wait_handler(
        ctx:,
        handler: bot.HandleText(fn(ctx, name) {
          process.send(seen, "name:" <> name)
          Ok(ctx)
        }),
        // No `or:` handler at all — the case the audit calls out.
        handle_else: None,
        timeout: None,
      )
    }),
    bot.HandleCommand("cancel", fn(ctx, _command) {
      process.send(seen, "cancelled")
      bot.cancel_conversation_in(ctx)
      Ok(ctx)
    }),
  ]

  let session_settings =
    context.session_settings(default: fn() { TestSession(name: "") })
  let bot_subject =
    build_test_bot(handlers_to_router_handler(handlers), session_settings)

  bot.handle_update(bot_subject, factory.command_update(command: "setname"))
  |> should.be_true

  // `/cancel` is a registered command: it belongs to the router, not to the
  // floor.
  bot.handle_update(bot_subject, factory.command_update(command: "cancel"))
  |> should.be_true
  process.receive(seen, 200) |> should.equal(Ok("cancelled"))

  // And the conversation really is over — the next text is not the name.
  bot.handle_update(bot_subject, factory.text_update(text: "John"))
  process.receive(seen, 200) |> should.equal(Error(Nil))
}

pub fn non_command_updates_still_wait_test() {
  let seen = process.new_subject()

  let handlers = [
    bot.HandleCommand("setname", fn(ctx, _command) {
      bot.wait_handler(
        ctx:,
        handler: bot.HandleText(fn(ctx, name) {
          process.send(seen, "name:" <> name)
          Ok(ctx)
        }),
        handle_else: None,
        timeout: None,
      )
    }),
    bot.HandleAll(fn(ctx, _upd) {
      process.send(seen, "router_fallback")
      Ok(ctx)
    }),
  ]

  let session_settings =
    context.session_settings(default: fn() { TestSession(name: "") })
  let bot_subject =
    build_test_bot(handlers_to_router_handler(handlers), session_settings)

  bot.handle_update(bot_subject, factory.command_update(command: "setname"))
  |> should.be_true

  // A photo does not match `HandleText`, and it is not a command: the wait
  // stays armed and the router (whose `HandleAll` would have claimed it) is
  // not consulted.
  bot.handle_update(bot_subject, factory.photo_update())
  process.receive(seen, 200) |> should.equal(Error(Nil))

  // The text the conversation was actually waiting for still lands.
  bot.handle_update(bot_subject, factory.text_update(text: "John"))
  process.receive(seen, 500) |> should.equal(Ok("name:John"))
}

// A payment query must not be swallowed either -------------------------------
//
// Telegram fails the payment if the bot does not answer a pre-checkout query
// within 10 seconds, and in a private chat the query lands on the same chat
// instance as the messages (its `chat_id` is the user's own id). A
// conversation waiting for the successful-payment message would otherwise eat
// the very query that has to be answered for that message to ever exist.

const payer_id = 555

fn pre_checkout_update() -> update.Update {
  update.PreCheckoutQueryUpdate(
    from_id: payer_id,
    chat_id: payer_id,
    pre_checkout_query: types.PreCheckoutQuery(
      id: "pcq1",
      from: factory.user_with(id: payer_id, first_name: "Payer"),
      currency: "XTR",
      total_amount: 50,
      invoice_payload: "order:1",
      shipping_option_id: None,
      order_info: None,
    ),
    raw: factory.raw_update(message: factory.message(text: "")),
  )
}

pub fn pre_checkout_query_reaches_the_router_during_a_wait_test() {
  let seen = process.new_subject()

  let handlers = [
    bot.HandleCommand("buy", fn(ctx, _command) {
      bot.wait_handler(
        ctx:,
        // What `payments.wait_successful_payment` parks on.
        handler: bot.HandleMessage(fn(ctx, _message) {
          process.send(seen, "paid")
          Ok(ctx)
        }),
        handle_else: None,
        timeout: None,
      )
    }),
    bot.HandleAll(fn(ctx, upd) {
      case upd {
        update.PreCheckoutQueryUpdate(..) -> process.send(seen, "pre_checkout")
        _ -> Nil
      }
      Ok(ctx)
    }),
  ]

  let session_settings =
    context.session_settings(default: fn() { TestSession(name: "") })
  let bot_subject =
    build_test_bot(handlers_to_router_handler(handlers), session_settings)

  bot.handle_update(
    bot_subject,
    factory.command_update_with(
      command: "buy",
      payload: None,
      from_id: payer_id,
      chat_id: payer_id,
    ),
  )
  |> should.be_true

  // Same session key as the command, so it reaches the waiting instance — and
  // must be handed to the router rather than swallowed.
  bot.handle_update(bot_subject, pre_checkout_update())
  process.receive(seen, 500) |> should.equal(Ok("pre_checkout"))

  // The wait is still armed: the payment message that follows is the
  // conversation's, not the router's.
  bot.handle_update(
    bot_subject,
    factory.message_update_with(
      message: factory.message(text: "receipt"),
      from_id: payer_id,
      chat_id: payer_id,
    ),
  )
  process.receive(seen, 500) |> should.equal(Ok("paid"))
}
