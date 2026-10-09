//// `router.with_timeout`: a handler that does not come back in time is
//// killed and answered for, and one that does is none the wiser.

import gleam/erlang/process
import gleeunit
import gleeunit/should

import telega/bot.{type Context}
import telega/error.{type TelegaError}
import telega/router
import telega/scope
import telega/testing/context as test_context
import telega/testing/factory

pub fn main() {
  gleeunit.main()
}

const marker: scope.Key(String) = scope.Key("timeout_test/marker")

fn make_router(
  ms: Int,
  body: fn(Context(String, TelegaError, Nil)) ->
    Result(Context(String, TelegaError, Nil), TelegaError),
) {
  router.new("timeout_test")
  |> router.use_middleware(
    router.with_timeout(ms:, on_timeout: fn(ctx) {
      bot.next_session(ctx, "timed out")
    }),
  )
  |> router.on_any_text(fn(ctx, _text) { body(ctx) })
}

fn handle(r) -> Context(String, TelegaError, Nil) {
  let upd = factory.text_update_with(text: "hi", from_id: 1, chat_id: 1)
  router.handle(
    r,
    test_context.context_with(session: "initial", update: upd),
    upd,
  )
  |> should.be_ok()
}

pub fn a_handler_within_the_deadline_passes_through_test() {
  let ctx =
    handle(make_router(1000, fn(ctx) { bot.next_session(ctx, "handled") }))

  ctx.session |> should.equal("handled")
}

pub fn a_hung_handler_is_cut_off_and_on_timeout_answers_test() {
  let ctx =
    handle(
      make_router(50, fn(ctx) {
        process.sleep(5000)
        bot.next_session(ctx, "handled")
      }),
    )

  ctx.session |> should.equal("timed out")
}

pub fn the_update_scope_travels_with_the_handler_both_ways_test() {
  let upd = factory.text_update_with(text: "hi", from_id: 1, chat_id: 1)
  let ctx = test_context.context_with(session: "initial", update: upd)
  // Put there before the handler, as a pre-handler or an outer middleware
  // would.
  scope.put(ctx.scope, marker, "from outside")

  let r =
    make_router(1000, fn(ctx) {
      let assert Ok("from outside") = scope.get(ctx.scope, marker)
      scope.put(ctx.scope, marker, "from inside")
      Ok(ctx)
    })
  let assert Ok(ctx) = router.handle(r, ctx, upd)

  // ...and what the handler left is readable after it, as
  // `reply.answer_callback_once` relies on.
  scope.get(ctx.scope, marker) |> should.equal(Ok("from inside"))
}
