//// Router v3: the `Router`/`RouterTree` split, typed callback routes, the
//// dedicated routes for update kinds that used to need `on_custom`, and the
//// content filters.

import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleam/option.{None, Some}
import gleam/result
import gleeunit/should

import telega/bot.{type Context, Context}
import telega/error.{type TelegaError}
import telega/keyboard
import telega/model/types
import telega/router
import telega/testing/context as test_context
import telega/testing/factory
import telega/update.{type Update}

type Ctx =
  Context(String, TelegaError, Nil)

fn make_ctx(session: String) -> Ctx {
  test_context.context(session:)
}

fn mark(tag: String) {
  fn(ctx: Ctx, _payload) { Ok(Context(..ctx, session: tag)) }
}

fn mark_update(tag: String) {
  fn(ctx: Ctx, _upd: Update) { Ok(Context(..ctx, session: tag)) }
}

fn session_of(result: Result(Ctx, TelegaError)) -> String {
  result |> should.be_ok |> fn(ctx: Ctx) { ctx.session }
}

fn command_update(command: String) -> Update {
  update.CommandUpdate(
    from_id: 123,
    chat_id: 456,
    command: update.Command(command:, payload: None, text: "/" <> command),
    message: factory.message(text: "/" <> command),
    raw: factory.raw_update(message: factory.message(text: "/" <> command)),
  )
}

// Typed callback routes -------------------------------------------------------

pub fn on_callback_data_hands_the_decoded_payload_to_the_handler_test() {
  let page = keyboard.int_callback_data("page")

  let r =
    router.new("test")
    |> router.on_callback_data(page, fn(ctx: Ctx, _query, page_number: Int) {
      Ok(Context(..ctx, session: "page:" <> int_to_string(page_number)))
    })

  let payload = keyboard.pack_callback(callback_data: page, data: 7).payload

  router.handle(r, make_ctx("initial"), factory.callback_query_update(payload))
  |> session_of
  |> should.equal("page:7")
}

pub fn on_callback_data_ignores_another_factorys_payload_test() {
  let page = keyboard.int_callback_data("page")
  let other = keyboard.string_callback_data("other")

  let r =
    router.new("test")
    |> router.on_callback_data(page, mark_callback("page"))
    |> router.on_callback_data(other, mark_callback("other"))

  let payload = keyboard.pack_callback(callback_data: other, data: "x").payload

  router.handle(r, make_ctx("initial"), factory.callback_query_update(payload))
  |> session_of
  |> should.equal("other")
}

pub fn on_callback_data_drops_a_payload_that_does_not_decode_test() {
  let page = keyboard.int_callback_data("page")

  let r =
    router.new("test")
    |> router.on_callback_data(page, mark_callback("routed"))

  // Right factory id, but "abc" is not an Int — the handler must not run on a
  // stand-in value.
  router.handle(
    r,
    make_ctx("initial"),
    factory.callback_query_update("page:abc"),
  )
  |> session_of
  |> should.equal("initial")
}

fn mark_callback(tag: String) {
  fn(ctx: Ctx, _query: types.CallbackQuery, _data) {
    Ok(Context(..ctx, session: tag))
  }
}

fn int_to_string(n: Int) -> String {
  case n {
    7 -> "7"
    _ -> "?"
  }
}

// Dedicated routes ------------------------------------------------------------

pub fn on_edited_message_routes_an_edit_test() {
  let message = factory.message(text: "fixed")
  let r = router.new("test") |> router.on_edited_message(mark("edited"))

  router.handle(
    r,
    make_ctx("initial"),
    update.EditedMessageUpdate(
      from_id: 1,
      chat_id: 2,
      message:,
      raw: factory.raw_update(message:),
    ),
  )
  |> session_of
  |> should.equal("edited")
}

pub fn on_channel_post_routes_a_post_test() {
  let post = factory.message(text: "news")
  let r = router.new("test") |> router.on_channel_post(mark("post"))

  router.handle(
    r,
    make_ctx("initial"),
    update.ChannelPostUpdate(
      from_id: 1,
      chat_id: 2,
      post:,
      raw: factory.raw_update(message: post),
    ),
  )
  |> session_of
  |> should.equal("post")
}

pub fn on_edited_channel_post_routes_an_edit_test() {
  let post = factory.message(text: "news v2")
  let r = router.new("test") |> router.on_edited_channel_post(mark("edited"))

  router.handle(
    r,
    make_ctx("initial"),
    update.EditedChannelPostUpdate(
      from_id: 1,
      chat_id: 2,
      post:,
      raw: factory.raw_update(message: post),
    ),
  )
  |> session_of
  |> should.equal("edited")
}

pub fn on_business_message_routes_a_business_chat_message_test() {
  let message = factory.message(text: "hello from a client")
  let r = router.new("test") |> router.on_business_message(mark("business"))

  router.handle(
    r,
    make_ctx("initial"),
    update.BusinessMessageUpdate(
      from_id: 1,
      chat_id: 2,
      message:,
      raw: factory.raw_update(message:),
    ),
  )
  |> session_of
  |> should.equal("business")
}

pub fn on_web_app_data_routes_mini_app_data_test() {
  let message = factory.message(text: "")
  let r = router.new("test") |> router.on_web_app_data(mark("web_app"))

  router.handle(
    r,
    make_ctx("initial"),
    update.WebAppUpdate(
      from_id: 1,
      chat_id: 2,
      web_app_data: types.WebAppData(data: "{}", button_text: "Open"),
      message:,
      raw: factory.raw_update(message:),
    ),
  )
  |> session_of
  |> should.equal("web_app")
}

pub fn on_chat_boost_routes_a_boost_test() {
  let r = router.new("test") |> router.on_chat_boost(mark("boost"))

  router.handle(r, make_ctx("initial"), chat_boost_update())
  |> session_of
  |> should.equal("boost")
}

pub fn on_removed_chat_boost_routes_a_removal_test() {
  let r = router.new("test") |> router.on_removed_chat_boost(mark("removed"))

  router.handle(
    r,
    make_ctx("initial"),
    update.RemovedChatBoost(
      from_id: 1,
      chat_id: 2,
      removed_chat_boost: types.ChatBoostRemoved(
        chat: factory.chat(),
        boost_id: "b1",
        remove_date: 0,
        source: boost_source(),
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    ),
  )
  |> session_of
  |> should.equal("removed")
}

pub fn on_paid_media_purchase_routes_a_purchase_test() {
  let r = router.new("test") |> router.on_paid_media_purchase(mark("purchase"))

  router.handle(
    r,
    make_ctx("initial"),
    update.PaidMediaPurchaseUpdate(
      from_id: 1,
      chat_id: 2,
      paid_media_purchased: types.PaidMediaPurchased(
        from: factory.user(),
        paid_media_payload: "sku-1",
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    ),
  )
  |> session_of
  |> should.equal("purchase")
}

pub fn on_unknown_update_routes_an_uninterpretable_update_test() {
  let r = router.new("test") |> router.on_unknown_update(mark_update("unknown"))

  router.handle(
    r,
    make_ctx("initial"),
    update.UnknownUpdate(
      from_id: 1,
      chat_id: 2,
      raw: factory.raw_update(message: factory.message(text: "")),
    ),
  )
  |> session_of
  |> should.equal("unknown")
}

fn boost_source() -> types.ChatBoostSource {
  types.ChatBoostSourcePremiumChatBoostSource(types.ChatBoostSourcePremium(
    source: "premium",
    user: factory.user(),
  ))
}

fn chat_boost_update() -> Update {
  update.ChatBoostUpdate(
    from_id: 1,
    chat_id: 2,
    chat_boost: types.ChatBoostUpdated(
      chat: factory.chat(),
      boost: types.ChatBoost(
        boost_id: "b1",
        add_date: 0,
        expiration_date: 0,
        source: boost_source(),
      ),
    ),
    raw: factory.raw_update(message: factory.message(text: "")),
  )
}

pub fn dedicated_routes_widen_allowed_updates_test() {
  router.new("test")
  |> router.on_edited_message(mark("e"))
  |> router.on_channel_post(mark("c"))
  |> router.on_chat_boost(mark("b"))
  |> router.on_paid_media_purchase(mark("p"))
  |> router.allowed_updates
  |> should.equal([
    "callback_query", "channel_post", "chat_boost", "edited_message",
    "purchased_paid_media",
  ])
}

pub fn on_unknown_update_turns_off_narrowing_test() {
  // A kind the library does not know can never be in a derived set, so the
  // router must not narrow at all.
  router.new("test")
  |> router.on_command("start", fn(ctx: Ctx, _cmd) { Ok(ctx) })
  |> router.on_unknown_update(mark_update("unknown"))
  |> router.allowed_updates
  |> should.equal([])
}

// M9 — a narrowed set always admits callback queries --------------------------

pub fn derived_set_always_allows_callback_query_test() {
  // A bot whose router registers only commands but whose handler parks on
  // `bot.wait_callback` used to derive ["message"] and then wait forever.
  router.new("test")
  |> router.on_command("start", fn(ctx: Ctx, _cmd) { Ok(ctx) })
  |> router.allowed_updates
  |> should.equal(["callback_query", "message"])
}

// Content filters -------------------------------------------------------------

fn text_update_with_message(message: types.Message) -> Update {
  update.TextUpdate(
    from_id: 1,
    chat_id: 2,
    text: message.text |> option.unwrap(""),
    message:,
    raw: factory.raw_update(message:),
  )
}

fn filtered_router(
  filter: router.Filter,
) -> router.Router(String, TelegaError, Nil) {
  router.new("test")
  |> router.on_filtered(filter, mark_update("matched"))
}

fn check(filter: router.Filter, message: types.Message) -> String {
  router.handle(
    filtered_router(filter),
    make_ctx("initial"),
    text_update_with_message(message),
  )
  |> session_of
}

pub fn is_forwarded_matches_a_forward_test() {
  let plain = factory.message(text: "hi")
  let forwarded =
    types.Message(
      ..plain,
      forward_origin: Some(
        types.MessageOriginUserMessageOrigin(types.MessageOriginUser(
          type_: "user",
          date: 0,
          sender_user: factory.user(),
        )),
      ),
    )

  check(router.is_forwarded(), forwarded) |> should.equal("matched")
  check(router.is_forwarded(), plain) |> should.equal("initial")
}

pub fn is_reply_matches_a_reply_test() {
  let plain = factory.message(text: "hi")
  let reply = types.Message(..plain, reply_to_message: Some(plain))

  check(router.is_reply(), reply) |> should.equal("matched")
  check(router.is_reply(), plain) |> should.equal("initial")
}

pub fn in_topic_matches_one_thread_test() {
  let plain = factory.message(text: "hi")
  let in_thread = types.Message(..plain, message_thread_id: Some(42))

  check(router.in_topic(42), in_thread) |> should.equal("matched")
  check(router.in_topic(7), in_thread) |> should.equal("initial")
  check(router.in_topic(42), plain) |> should.equal("initial")
}

pub fn has_entity_reads_text_and_caption_entities_test() {
  let plain = factory.message(text: "look")
  let url_entity =
    types.MessageEntity(
      type_: "url",
      offset: 0,
      length: 4,
      url: None,
      user: None,
      language: None,
      custom_emoji_id: None,
      unix_time: None,
      date_time_format: None,
    )

  let with_text_entity = types.Message(..plain, entities: Some([url_entity]))
  let with_caption_entity =
    types.Message(..plain, caption_entities: Some([url_entity]))

  check(router.has_entity("url"), with_text_entity) |> should.equal("matched")
  check(router.has_entity("url"), with_caption_entity)
  |> should.equal("matched")
  check(router.has_entity("mention"), with_text_entity)
  |> should.equal("initial")
  check(router.has_entity("url"), plain) |> should.equal("initial")
}

pub fn via_bot_matches_an_inline_bot_message_test() {
  let plain = factory.message(text: "hi")
  let via =
    types.Message(
      ..plain,
      via_bot: Some(factory.user_with(id: 99, first_name: "B")),
    )

  check(router.via_bot(), via) |> should.equal("matched")
  check(router.via_bot_id(99), via) |> should.equal("matched")
  check(router.via_bot_id(1), via) |> should.equal("initial")
  check(router.via_bot(), plain) |> should.equal("initial")
}

pub fn is_automatic_forward_matches_a_linked_channel_post_test() {
  let plain = factory.message(text: "hi")
  let forwarded = types.Message(..plain, is_automatic_forward: Some(True))

  check(router.is_automatic_forward(), forwarded) |> should.equal("matched")
  check(router.is_automatic_forward(), plain) |> should.equal("initial")
}

pub fn has_media_spoiler_matches_a_covered_media_test() {
  let plain = factory.message(text: "hi")
  let spoiler = types.Message(..plain, has_media_spoiler: Some(True))

  check(router.has_media_spoiler(), spoiler) |> should.equal("matched")
  check(router.has_media_spoiler(), plain) |> should.equal("initial")
}

pub fn content_filters_decline_updates_without_a_message_test() {
  // A callback query has no message of its own here, so every message-reading
  // filter must decline rather than guess.
  router.handle(
    filtered_router(router.is_reply()),
    make_ctx("initial"),
    factory.callback_query_update("noop"),
  )
  |> session_of
  |> should.equal("initial")
}

// RouterTree ------------------------------------------------------------------

fn ping_router(tag: String) -> router.Router(String, TelegaError, Nil) {
  router.new(tag)
  |> router.on_command("ping", fn(ctx: Ctx, _cmd) {
    Ok(Context(..ctx, session: tag))
  })
}

pub fn branch_picks_the_first_matching_filter_test() {
  let tree =
    router.tree()
    |> router.branch(router.is_private_chat(), ping_router("private"))
    |> router.branch(router.is_group_chat(), ping_router("group"))

  let private = command_update("ping")
  router.handle_tree(tree, make_ctx("initial"), private)
  |> session_of
  |> should.equal("private")

  let group_message =
    types.Message(
      ..factory.message(text: "/ping"),
      chat: factory.chat_with(id: -100, type_: "supergroup"),
    )
  let group =
    update.CommandUpdate(
      from_id: 1,
      chat_id: -100,
      command: update.Command(command: "ping", payload: None, text: "/ping"),
      message: group_message,
      raw: factory.raw_update(message: group_message),
    )
  router.handle_tree(tree, make_ctx("initial"), group)
  |> session_of
  |> should.equal("group")
}

pub fn branch_whose_filter_matches_but_has_no_route_falls_through_test() {
  let tree =
    router.tree()
    // Matches the update but has nothing registered for it.
    |> router.branch(router.is_private_chat(), router.new("empty"))
    |> router.append(ping_router("open"))

  router.handle_tree(tree, make_ctx("initial"), command_update("ping"))
  |> session_of
  |> should.equal("open")
}

pub fn tree_fallback_catches_what_no_branch_claimed_test() {
  let tree =
    router.tree()
    |> router.append(ping_router("branch"))
    |> router.tree_fallback(mark_update("fallback"))

  router.handle_tree(tree, make_ctx("initial"), command_update("nope"))
  |> session_of
  |> should.equal("fallback")
}

pub fn with_catch_handler_on_tree_leaves_an_existing_one_alone_test() {
  let failing =
    router.new("failing")
    |> router.on_command("boom", fn(_ctx: Ctx, _cmd) {
      Error(error.ActorError("boom"))
    })

  let tree =
    router.tree()
    |> router.append(
      failing
      |> router.with_catch_handler(fn(_err) { Ok(make_ctx("own_catch")) }),
    )
    |> router.append(
      router.new("other")
      |> router.on_command("bang", fn(_ctx: Ctx, _cmd) {
        Error(error.ActorError("bang"))
      }),
    )
    |> router.with_catch_handler_on_tree(fn(_err) { Ok(make_ctx("tree_catch")) })

  router.handle_tree(tree, make_ctx("initial"), command_update("boom"))
  |> session_of
  |> should.equal("own_catch")

  router.handle_tree(tree, make_ctx("initial"), command_update("bang"))
  |> session_of
  |> should.equal("tree_catch")
}

pub fn tree_registered_commands_unions_the_branches_test() {
  let tree =
    router.compose(
      router.new("admin")
        |> router.on_command_with_description(
          "ban",
          "Ban a user",
          fn(ctx: Ctx, _cmd) { Ok(ctx) },
        ),
      router.new("user")
        |> router.on_command_with_description(
          "start",
          "Start",
          fn(ctx: Ctx, _cmd) { Ok(ctx) },
        ),
    )

  router.tree_registered_commands(tree)
  |> should.equal([#("ban", "Ban a user"), #("start", "Start")])
}

pub fn one_wildcard_branch_gives_up_narrowing_for_the_tree_test() {
  let tree =
    router.compose(
      router.new("a") |> router.on_inline_query(mark("inline")),
      router.new("b") |> router.fallback(mark_update("anything")),
    )

  router.tree_allowed_updates(tree) |> should.equal([])
}

pub fn tree_name_joins_the_branch_names_test() {
  router.compose(ping_router("a"), ping_router("b"))
  |> router.tree_name
  |> should.equal("a+b")
}

// Pre-router annotations ------------------------------------------------------

pub fn annotation_reads_what_a_pre_handler_attached_test() {
  let ctx =
    Context(
      ..make_ctx("initial"),
      annotations: dict.from_list([
        #("locale", dynamic.string("ru")),
        #("attempt", dynamic.int(3)),
      ]),
    )

  bot.annotation(ctx, "locale", decode.string) |> should.equal(Ok("ru"))
  bot.annotation(ctx, "attempt", decode.int) |> should.equal(Ok(3))
}

pub fn annotation_fails_on_a_missing_key_or_wrong_type_test() {
  let ctx =
    Context(
      ..make_ctx("initial"),
      annotations: dict.from_list([#("locale", dynamic.string("ru"))]),
    )

  bot.annotation(ctx, "missing", decode.string) |> should.equal(Error(Nil))
  bot.annotation(ctx, "locale", decode.int) |> should.equal(Error(Nil))

  // Which makes `result.unwrap` the idiomatic read.
  bot.annotation(ctx, "missing", decode.string)
  |> result.unwrap("en")
  |> should.equal("en")
}

pub fn a_router_with_only_callback_routes_still_narrows_test() {
  // Callbacks live in a dict, not in `routes` — reading only the routes made
  // this router look empty, which reads as "do not restrict".
  router.new("test")
  |> router.on_callback(router.Exact("ok"), fn(ctx: Ctx, _id, _data) { Ok(ctx) })
  |> router.allowed_updates
  |> should.equal(["callback_query"])
}

pub fn an_empty_branch_does_not_stop_the_tree_from_narrowing_test() {
  // An empty router handles nothing; it is not a wildcard.
  router.tree()
  |> router.append(router.new("empty"))
  |> router.append(router.new("inline") |> router.on_inline_query(mark("i")))
  |> router.tree_allowed_updates
  |> should.equal(["callback_query", "inline_query"])
}
