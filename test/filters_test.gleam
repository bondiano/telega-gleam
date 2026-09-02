import gleam/option.{None}
import gleeunit
import gleeunit/should

import telega/bot.{type Context, Context}
import telega/error.{type TelegaError}
import telega/router
import telega/testing/context as test_context
import telega/testing/factory
import telega/update

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

// M8 — filters must answer for every update kind, not just the seven ---------

fn message_update(
  from_id from_id: Int,
  chat_id chat_id: Int,
  type_ type_: String,
) {
  let from = factory.user_with(id: from_id, first_name: "U")
  let chat = factory.chat_with(id: chat_id, type_:)
  factory.message_update_with(
    message: factory.message_with(text: "", from:, chat:),
    from_id:,
    chat_id:,
  )
}

pub fn from_user_matches_every_update_with_a_sender_test() {
  let r = filtered_router(router.from_user(7))

  // A plain message (a location, a contact, a sticker — anything that is not
  // one of the handful of media variants) has a sender just the same.
  run(r, message_update(from_id: 7, chat_id: 5, type_: "private"))
  |> should.equal("matched")
  run(r, message_update(from_id: 8, chat_id: 5, type_: "private"))
  |> should.equal("initial")
}

pub fn private_and_group_filters_use_the_chat_type_test() {
  let private = filtered_router(router.is_private_chat())
  let group = filtered_router(router.is_group_chat())

  run(private, message_update(from_id: 1, chat_id: 5, type_: "private"))
  |> should.equal("matched")
  run(private, message_update(from_id: 1, chat_id: -5, type_: "supergroup"))
  |> should.equal("initial")

  run(group, message_update(from_id: 1, chat_id: -5, type_: "supergroup"))
  |> should.equal("matched")
  run(group, message_update(from_id: 1, chat_id: -5, type_: "group"))
  |> should.equal("matched")
  run(group, message_update(from_id: 1, chat_id: 5, type_: "private"))
  |> should.equal("initial")
}

pub fn chatless_updates_are_neither_private_nor_group_test() {
  let private = filtered_router(router.is_private_chat())
  let group = filtered_router(router.is_group_chat())

  // An inline query has a positive "chat id" but happens in no chat at all,
  // and an unrecognised update is keyed with -1 — neither is a chat of any
  // kind, so neither filter should claim it.
  let inline = factory.inline_query_update(query: "cats")
  let unknown =
    update.UnknownUpdate(
      from_id: -1,
      chat_id: -1,
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  run(private, inline) |> should.equal("initial")
  run(group, inline) |> should.equal("initial")
  run(private, unknown) |> should.equal("initial")
  run(group, unknown) |> should.equal("initial")
}
