import gleam/erlang/process
import gleeunit
import gleeunit/should

import telega/bot.{type Context, Context}
import telega/error.{type TelegaError}
import telega/router
import telega/testing/context as test_context
import telega/testing/factory

pub fn main() {
  gleeunit.main()
}

fn make_router(limit limit: Int, window_ms window_ms: Int) {
  router.new("rate_limit_test")
  |> router.use_middleware(
    router.with_rate_limit(
      limit:,
      window_ms:,
      on_limit: fn(ctx: Context(String, TelegaError, Nil)) {
        Ok(Context(..ctx, session: "limited"))
      },
    ),
  )
  |> router.on_any_text(fn(ctx: Context(String, TelegaError, Nil), _text) {
    Ok(Context(..ctx, session: "handled"))
  })
}

fn handle_text_from(r, from_id from_id: Int, chat_id chat_id: Int) -> String {
  let upd = factory.text_update_with(text: "hi", from_id:, chat_id:)
  router.handle(
    r,
    test_context.context_with(session: "initial", update: upd),
    upd,
  )
  |> should.be_ok()
  |> fn(ctx: Context(String, TelegaError, Nil)) { ctx.session }
}

pub fn rate_limit_blocks_after_limit_test() {
  let r = make_router(limit: 2, window_ms: 60_000)

  handle_text_from(r, from_id: 1, chat_id: 1)
  |> should.equal("handled")
  handle_text_from(r, from_id: 1, chat_id: 1)
  |> should.equal("handled")
  handle_text_from(r, from_id: 1, chat_id: 1)
  |> should.equal("limited")
}

pub fn rate_limit_is_per_user_test() {
  let r = make_router(limit: 1, window_ms: 60_000)

  handle_text_from(r, from_id: 1, chat_id: 10)
  |> should.equal("handled")
  handle_text_from(r, from_id: 1, chat_id: 10)
  |> should.equal("limited")

  // Same chat, different user — independent counter
  handle_text_from(r, from_id: 2, chat_id: 10)
  |> should.equal("handled")
  // Same user, different chat — independent counter
  handle_text_from(r, from_id: 1, chat_id: 11)
  |> should.equal("handled")
}

pub fn rate_limit_window_resets_test() {
  let r = make_router(limit: 1, window_ms: 50)

  handle_text_from(r, from_id: 5, chat_id: 5)
  |> should.equal("handled")
  handle_text_from(r, from_id: 5, chat_id: 5)
  |> should.equal("limited")

  process.sleep(80)

  handle_text_from(r, from_id: 5, chat_id: 5)
  |> should.equal("handled")
}

pub fn rate_limit_invokes_handler_exactly_once_test() {
  // Regression: an eager `bool.guard` used to run the handler twice
  // for every update with user context.
  let r =
    router.new("rate_limit_once_test")
    |> router.use_middleware(
      router.with_rate_limit(
        limit: 10,
        window_ms: 60_000,
        on_limit: fn(ctx: Context(String, TelegaError, Nil)) { Ok(ctx) },
      ),
    )
    |> router.on_any_text(fn(ctx: Context(String, TelegaError, Nil), _text) {
      Ok(Context(..ctx, session: ctx.session <> "+"))
    })

  let upd = factory.text_update_with(text: "hi", from_id: 7, chat_id: 7)
  router.handle(r, test_context.context_with(session: "", update: upd), upd)
  |> should.be_ok()
  |> fn(ctx: Context(String, TelegaError, Nil)) { ctx.session }
  |> should.equal("+")
}

pub fn rate_limit_skips_updates_without_user_test() {
  let r = make_router(limit: 1, window_ms: 60_000)

  // Updates without user context (from_id: -1, e.g. poll updates) bypass the limiter
  handle_text_from(r, from_id: -1, chat_id: -1)
  |> should.equal("handled")
  handle_text_from(r, from_id: -1, chat_id: -1)
  |> should.equal("handled")
}
