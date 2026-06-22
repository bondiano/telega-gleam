import gleam/option.{None}
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

/// Router with a single filtered route that marks the session `"matched"` when
/// the filter passes. Unmatched updates fall through unchanged (`"initial"`).
fn filtered_router(filter: router.Filter) {
  router.new("filters_test")
  |> router.on_filtered(filter, fn(ctx: Context(String, TelegaError, Nil), _u) {
    Ok(Context(..ctx, session: "matched"))
  })
}

fn run(r, update) -> String {
  router.handle(
    r,
    test_context.context_with(session: "initial", update:),
    update,
  )
  |> should.be_ok()
  |> fn(ctx: Context(String, TelegaError, Nil)) { ctx.session }
}

fn text(from_id from_id: Int, chat_id chat_id: Int) {
  factory.text_update_with(text: "hi", from_id:, chat_id:)
}

pub fn from_chats_whitelists_test() {
  let r = filtered_router(router.from_chats([10, 20]))

  run(r, text(from_id: 1, chat_id: 10)) |> should.equal("matched")
  run(r, text(from_id: 1, chat_id: 20)) |> should.equal("matched")
  // A chat outside the whitelist is left untouched.
  run(r, text(from_id: 1, chat_id: 30)) |> should.equal("initial")
}

pub fn not_inverts_a_filter_test() {
  // `not(from_chats(...))` is a blacklist.
  let r = filtered_router(router.not(router.from_chats([10])))

  run(r, text(from_id: 1, chat_id: 10)) |> should.equal("initial")
  run(r, text(from_id: 1, chat_id: 11)) |> should.equal("matched")
}

pub fn and_requires_all_test() {
  let r = filtered_router(router.and([router.is_text(), router.from_user(1)]))

  // Text from the allowed user matches.
  run(r, text(from_id: 1, chat_id: 5)) |> should.equal("matched")
  // Text from another user fails the `from_user` arm.
  run(r, text(from_id: 2, chat_id: 5)) |> should.equal("initial")
  // A command from user 1 fails the `is_text` arm.
  run(
    r,
    factory.command_update_with(
      command: "go",
      payload: None,
      from_id: 1,
      chat_id: 5,
    ),
  )
  |> should.equal("initial")
}

pub fn or_requires_any_test() {
  let r = filtered_router(router.or([router.from_user(1), router.from_user(2)]))

  run(r, text(from_id: 1, chat_id: 5)) |> should.equal("matched")
  run(r, text(from_id: 2, chat_id: 5)) |> should.equal("matched")
  run(r, text(from_id: 3, chat_id: 5)) |> should.equal("initial")
}

pub fn nested_algebra_test() {
  // (is_text AND from_chats([10, 20])) but NOT from_user(99)
  let r =
    filtered_router(
      router.and([
        router.is_text(),
        router.from_chats([10, 20]),
        router.not(router.from_user(99)),
      ]),
    )

  run(r, text(from_id: 1, chat_id: 10)) |> should.equal("matched")
  // Right chat but blacklisted user.
  run(r, text(from_id: 99, chat_id: 10)) |> should.equal("initial")
  // Allowed user but wrong chat.
  run(r, text(from_id: 1, chat_id: 30)) |> should.equal("initial")
}
