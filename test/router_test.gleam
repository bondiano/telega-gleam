import bot_test.{create_test_user}
import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import telega/bot.{type Context, Context}
import telega/client
import telega/error.{type TelegaError}
import telega/internal/config
import telega/model/types
import telega/router
import telega/update.{type Update}

pub fn main() {
  gleeunit.main()
}

fn test_message() -> types.Message {
  types.Message(
    message_id: 1,
    message_thread_id: None,
    from: Some(types.User(
      id: 123,
      is_bot: False,
      first_name: "Test",
      last_name: None,
      username: None,
      language_code: None,
      is_premium: None,
      added_to_attachment_menu: None,
      can_join_groups: None,
      can_read_all_group_messages: None,
      supports_inline_queries: None,
      can_connect_to_business: None,
      has_main_web_app: None,
      has_topics_enabled: None,
      allows_users_to_create_topics: None,
    )),
    sender_chat: None,
    direct_messages_topic: None,
    sender_boost_count: None,
    sender_business_bot: None,
    date: 1_234_567_890,
    business_connection_id: None,
    chat: types.Chat(
      id: 456,
      type_: Some("private"),
      title: None,
      username: None,
      first_name: Some("Test"),
      last_name: Some("User"),
      is_forum: None,
      is_direct_messages: None,
    ),
    forward_origin: None,
    is_topic_message: None,
    is_automatic_forward: None,
    reply_to_message: None,
    external_reply: None,
    quote: None,
    reply_to_story: None,
    reply_to_checklist_task_id: None,
    via_bot: None,
    edit_date: None,
    has_protected_content: None,
    is_from_offline: None,
    is_paid_post: None,
    media_group_id: None,
    author_signature: None,
    text: Some("/start"),
    entities: None,
    link_preview_options: None,
    effect_id: None,
    suggested_post_info: None,
    animation: None,
    audio: None,
    document: None,
    paid_media: None,
    photo: None,
    sticker: None,
    story: None,
    video: None,
    video_note: None,
    voice: None,
    caption: None,
    caption_entities: None,
    show_caption_above_media: None,
    has_media_spoiler: None,
    contact: None,
    dice: None,
    game: None,
    poll: None,
    venue: None,
    location: None,
    new_chat_members: None,
    left_chat_member: None,
    new_chat_title: None,
    new_chat_photo: None,
    delete_chat_photo: None,
    group_chat_created: None,
    supergroup_chat_created: None,
    channel_chat_created: None,
    message_auto_delete_timer_changed: None,
    migrate_to_chat_id: None,
    migrate_from_chat_id: None,
    pinned_message: None,
    invoice: None,
    successful_payment: None,
    refunded_payment: None,
    users_shared: None,
    chat_shared: None,
    connected_website: None,
    write_access_allowed: None,
    passport_data: None,
    proximity_alert_triggered: None,
    boost_added: None,
    chat_background_set: None,
    chat_owner_left: None,
    chat_owner_changed: None,
    forum_topic_created: None,
    forum_topic_edited: None,
    forum_topic_closed: None,
    forum_topic_reopened: None,
    general_forum_topic_hidden: None,
    general_forum_topic_unhidden: None,
    giveaway_created: None,
    giveaway: None,
    giveaway_winners: None,
    giveaway_completed: None,
    video_chat_scheduled: None,
    video_chat_started: None,
    video_chat_ended: None,
    video_chat_participants_invited: None,
    web_app_data: None,
    reply_markup: None,
    checklist: None,
    checklist_tasks_added: None,
    checklist_tasks_done: None,
    direct_message_price_changed: None,
    gift: None,
    paid_message_price_changed: None,
    paid_star_count: None,
    unique_gift: None,
    gift_upgrade_sent: None,
    suggested_post_approved: None,
    suggested_post_approval_failed: None,
    suggested_post_declined: None,
    suggested_post_paid: None,
    suggested_post_refunded: None,
  )
}

fn test_update() -> types.Update {
  types.Update(
    update_id: 1,
    message: Some(test_message()),
    edited_message: None,
    channel_post: None,
    edited_channel_post: None,
    business_connection: None,
    business_message: None,
    edited_business_message: None,
    deleted_business_messages: None,
    message_reaction: None,
    message_reaction_count: None,
    inline_query: None,
    chosen_inline_result: None,
    callback_query: None,
    shipping_query: None,
    pre_checkout_query: None,
    purchased_paid_media: None,
    poll: None,
    poll_answer: None,
    my_chat_member: None,
    chat_member: None,
    chat_join_request: None,
    chat_boost: None,
    removed_chat_boost: None,
  )
}

fn test_context(session: String) -> Context(String, TelegaError) {
  let subject = process.new_subject()
  Context(
    session: session,
    config: config.Config(
      server_url: "https://api.telegram.org",
      webhook_path: "/webhook",
      secret_token: "test_token",
      api_client: client.new(token: "test_token"),
    ),
    chat_subject: subject,
    key: "test_key",
    log_prefix: Some("test"),
    start_time: None,
    update: update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "test", payload: None, text: "/test"),
      message: test_message(),
      raw: test_update(),
    ),
    bot_info: create_test_user(),
  )
}

pub fn command_routing_integration_test() {
  let start_handler = fn(ctx: Context(String, TelegaError), cmd: update.Command) {
    case cmd.command {
      "start" -> Ok(Context(..ctx, session: "start_called"))
      _ -> Ok(ctx)
    }
  }

  let help_handler = fn(ctx: Context(String, TelegaError), cmd: update.Command) {
    case cmd.command {
      "help" -> Ok(Context(..ctx, session: "help_called"))
      _ -> Ok(ctx)
    }
  }

  let r =
    router.new("test")
    |> router.on_command("start", start_handler)
    |> router.on_command("help", help_handler)

  let start_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "start", payload: None, text: "/start"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  let result = router.handle(r, ctx, start_update)

  result
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("start_called")

  let help_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "help", payload: None, text: "/help"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  let result2 = router.handle(r, ctx2, help_update)

  result2
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("help_called")

  let unknown_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(
        command: "unknown",
        payload: None,
        text: "/unknown",
      ),
      message: test_message(),
      raw: test_update(),
    )

  let ctx3 = test_context("initial")
  let result3 = router.handle(r, ctx3, unknown_update)

  result3
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial")
}

pub fn decode_command_with_args_test() {
  // Build a message with text "/help foo bar" and a bot_command entity for "/help"
  let base = test_message()
  let text = "/help foo bar"
  let entity =
    types.MessageEntity(
      type_: "bot_command",
      offset: 0,
      length: 5,
      // length of "/help"
      url: None,
      user: None,
      language: None,
      custom_emoji_id: None,
    )

  let message =
    types.Message(..base, text: Some(text), entities: Some([entity]))

  let raw =
    types.Update(
      update_id: 1,
      message: Some(message),
      edited_message: None,
      channel_post: None,
      edited_channel_post: None,
      business_connection: None,
      business_message: None,
      edited_business_message: None,
      deleted_business_messages: None,
      message_reaction: None,
      message_reaction_count: None,
      inline_query: None,
      chosen_inline_result: None,
      callback_query: None,
      shipping_query: None,
      pre_checkout_query: None,
      purchased_paid_media: None,
      poll: None,
      poll_answer: None,
      my_chat_member: None,
      chat_member: None,
      chat_join_request: None,
      chat_boost: None,
      removed_chat_boost: None,
    )

  let upd = update.raw_to_update(raw)

  case upd {
    update.CommandUpdate(command: cmd, ..) -> {
      cmd.command |> should.equal("help")
      cmd.payload |> should.equal(Some("foo bar"))
    }
    _ -> should.fail()
  }
}

pub fn router_command_with_args_test() {
  let handler = fn(ctx: Context(String, TelegaError), cmd: update.Command) {
    Ok(Context(..ctx, session: option.unwrap(cmd.payload, "no_payload")))
  }

  let r =
    router.new("test")
    |> router.on_command("help", handler)

  // Build same update as above
  let base = test_message()
  let text = "/help payload here"
  let entity =
    types.MessageEntity(
      type_: "bot_command",
      offset: 0,
      length: 5,
      url: None,
      user: None,
      language: None,
      custom_emoji_id: None,
    )

  let message =
    types.Message(..base, text: Some(text), entities: Some([entity]))

  let raw =
    types.Update(
      update_id: 1,
      message: Some(message),
      edited_message: None,
      channel_post: None,
      edited_channel_post: None,
      business_connection: None,
      business_message: None,
      edited_business_message: None,
      deleted_business_messages: None,
      message_reaction: None,
      message_reaction_count: None,
      inline_query: None,
      chosen_inline_result: None,
      callback_query: None,
      shipping_query: None,
      pre_checkout_query: None,
      purchased_paid_media: None,
      poll: None,
      poll_answer: None,
      my_chat_member: None,
      chat_member: None,
      chat_join_request: None,
      chat_boost: None,
      removed_chat_boost: None,
    )

  let upd = update.raw_to_update(raw)
  let ctx = test_context("initial")
  let result = router.handle(r, ctx, upd)

  result
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("payload here")
}

pub fn router_command_with_matching_suffix_test() {
  router_command_with_suffix_test("/help@testbot", "help@testbot")
  router_command_with_suffix_test("/start@testbot", "start@testbot")
}

pub fn router_command_with_non_matching_suffix_test() {
  router_command_with_suffix_test("/help@someotherbot", "initial")
  router_command_with_suffix_test("/start@", "initial")
}

fn router_command_with_suffix_test(text: String, session_val: String) {
  let handler = fn(ctx: Context(String, TelegaError), cmd: update.Command) {
    Ok(Context(..ctx, session: cmd.command))
  }

  let r =
    router.new("test")
    |> router.on_commands(["help", "start"], handler)

  // Build same update as above
  let base = test_message()
  let entity =
    types.MessageEntity(
      type_: "bot_command",
      offset: 0,
      length: text |> string.length,
      url: None,
      user: None,
      language: None,
      custom_emoji_id: None,
    )

  let message =
    types.Message(..base, text: Some(text), entities: Some([entity]))

  let raw =
    types.Update(
      update_id: 1,
      message: Some(message),
      edited_message: None,
      channel_post: None,
      edited_channel_post: None,
      business_connection: None,
      business_message: None,
      edited_business_message: None,
      deleted_business_messages: None,
      message_reaction: None,
      message_reaction_count: None,
      inline_query: None,
      chosen_inline_result: None,
      callback_query: None,
      shipping_query: None,
      pre_checkout_query: None,
      purchased_paid_media: None,
      poll: None,
      poll_answer: None,
      my_chat_member: None,
      chat_member: None,
      chat_join_request: None,
      chat_boost: None,
      removed_chat_boost: None,
    )

  let upd = update.raw_to_update(raw)
  let ctx = test_context("initial")
  let result = router.handle(r, ctx, upd)

  result
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal(session_val)
}

pub fn text_pattern_matching_integration_test() {
  let exact_handler = fn(ctx: Context(String, TelegaError), _text: String) {
    Ok(Context(..ctx, session: "exact_matched"))
  }

  let prefix_handler = fn(ctx: Context(String, TelegaError), _text: String) {
    Ok(Context(..ctx, session: "prefix_matched"))
  }

  let r =
    router.new("test")
    |> router.on_text(router.Exact("hello"), exact_handler)
    |> router.on_text(router.Prefix("search:"), prefix_handler)

  let exact_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "hello",
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, exact_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("exact_matched")

  let prefix_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "search:gleam tutorials",
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(r, ctx2, prefix_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("prefix_matched")
}

pub fn middleware_integration_test() {
  let handler = fn(ctx: Context(String, TelegaError), _cmd: update.Command) {
    Ok(Context(..ctx, session: ctx.session <> "_handler"))
  }

  let counting_middleware = fn(handler) {
    fn(ctx: Context(String, TelegaError), update: Update) {
      let modified_ctx = Context(..ctx, session: ctx.session <> "_pre")
      case handler(modified_ctx, update) {
        Ok(result_ctx) ->
          Ok(Context(..result_ctx, session: result_ctx.session <> "_post"))
        Error(err) -> Error(err)
      }
    }
  }

  let r =
    router.new("test")
    |> router.use_middleware(counting_middleware)
    |> router.on_command("test", handler)

  let cmd_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "test", payload: None, text: "/test"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, cmd_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial_pre_handler_post")
}

pub fn fallback_integration_test() {
  let command_handler = fn(
    ctx: Context(String, TelegaError),
    _cmd: update.Command,
  ) {
    Ok(Context(..ctx, session: "command_handled"))
  }

  let fallback_handler = fn(ctx: Context(String, TelegaError), _update: Update) {
    Ok(Context(..ctx, session: "fallback_handled"))
  }

  let r =
    router.new("test")
    |> router.on_command("start", command_handler)
    |> router.fallback(fallback_handler)

  let command_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "start", payload: None, text: "/start"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, command_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("command_handled")

  let text_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "random text",
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(r, ctx2, text_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("fallback_handled")
}

pub fn filter_middleware_integration_test() {
  let handler = fn(ctx: Context(String, TelegaError), _update: Update) {
    Ok(Context(..ctx, session: "handler_called"))
  }

  let user_filter = fn(update: Update) -> Bool {
    case update {
      update.TextUpdate(from_id: id, ..) -> id == 123
      update.CommandUpdate(from_id: id, ..) -> id == 123
      _ -> False
    }
  }

  // Use on_custom with the filter to properly check updates
  let r =
    router.new("test")
    |> router.on_custom(
      fn(update) {
        case update {
          update.TextUpdate(..) -> user_filter(update)
          _ -> False
        }
      },
      handler,
    )

  let allowed_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "hello",
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, allowed_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("handler_called")

  let blocked_update =
    update.TextUpdate(
      from_id: 999,
      chat_id: 456,
      text: "hello",
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(r, ctx2, blocked_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial")
}

pub fn custom_matcher_integration_test() {
  let custom_handler = fn(ctx: Context(String, TelegaError), _update: Update) {
    Ok(Context(..ctx, session: "custom_matched"))
  }

  let contains_number = fn(update: Update) -> Bool {
    case update {
      update.TextUpdate(text: text, ..) -> {
        text
        |> string.to_graphemes
        |> list.any(fn(char) {
          char == "0"
          || char == "1"
          || char == "2"
          || char == "3"
          || char == "4"
          || char == "5"
          || char == "6"
          || char == "7"
          || char == "8"
          || char == "9"
        })
      }
      _ -> False
    }
  }

  let r =
    router.new("test")
    |> router.on_custom(contains_number, custom_handler)

  let with_number =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "I have 5 apples",
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, with_number)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("custom_matched")

  let without_number =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "No numbers here",
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(r, ctx2, without_number)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial")
}

pub fn router_composition_integration_test() {
  let handler1 = fn(ctx: Context(String, TelegaError), _cmd: update.Command) {
    Ok(Context(..ctx, session: "router1"))
  }

  let handler2 = fn(ctx: Context(String, TelegaError), _cmd: update.Command) {
    Ok(Context(..ctx, session: "router2"))
  }

  let router1 =
    router.new("r1")
    |> router.on_command("start", handler1)

  let router2 =
    router.new("r2")
    |> router.on_command("help", handler2)

  let composed = router.compose(router1, router2)

  let start_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "start", payload: None, text: "/start"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  composed
  |> router.handle(ctx, start_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router1")

  let help_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "help", payload: None, text: "/help"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  composed
  |> router.handle(ctx2, help_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router2")
}

pub fn media_handlers_integration_test() {
  let photo_handler = fn(
    ctx: Context(String, TelegaError),
    _photos: List(types.PhotoSize),
  ) {
    Ok(Context(..ctx, session: "photo"))
  }

  let video_handler = fn(ctx: Context(String, TelegaError), _video: types.Video) {
    Ok(Context(..ctx, session: "video"))
  }

  let r =
    router.new("test")
    |> router.on_photo(photo_handler)
    |> router.on_video(video_handler)

  let photo_update =
    update.PhotoUpdate(
      from_id: 123,
      chat_id: 456,
      photos: [],
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, photo_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("photo")

  let video_update =
    update.VideoUpdate(
      from_id: 123,
      chat_id: 456,
      video: types.Video(
        file_id: "test_video",
        file_unique_id: "unique_video",
        width: 1920,
        height: 1080,
        duration: 60,
        thumbnail: None,
        cover: None,
        file_name: None,
        mime_type: None,
        file_size: None,
        start_timestamp: None,
        qualities: None,
      ),
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(r, ctx2, video_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("video")
}

pub fn recovery_middleware_integration_test() {
  let failing_handler = fn(
    _ctx: Context(String, TelegaError),
    _cmd: update.Command,
  ) {
    Error(error.ActorError("expected error"))
  }

  let recover = fn(err) {
    case err {
      error.ActorError("expected error") -> Ok(test_context("recovered"))
      _ -> Error(err)
    }
  }

  let r =
    router.new("test")
    |> router.on_command("fail", fn(ctx, cmd) {
      let _ = failing_handler(ctx, cmd)
      // We know this always fails, so just recover
      recover(error.ActorError("expected error"))
    })

  let cmd_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "fail", payload: None, text: "/fail"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, cmd_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("recovered")
}

pub fn compose_basic_test() {
  // First router handles /start command
  let router1 =
    router.new("router1")
    |> router.on_command("start", fn(ctx, _cmd) {
      Ok(Context(..ctx, session: "router1_start"))
    })
    |> router.on_text(router.Prefix("hello"), fn(ctx, _text) {
      Ok(Context(..ctx, session: "router1_hello"))
    })

  // Second router handles /help command
  let router2 =
    router.new("router2")
    |> router.on_command("help", fn(ctx, _cmd) {
      Ok(Context(..ctx, session: "router2_help"))
    })
    |> router.on_text(router.Prefix("world"), fn(ctx, _text) {
      Ok(Context(..ctx, session: "router2_world"))
    })

  let combined = router.compose(router1, router2)

  // Test that router1's command works
  let start_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "start", payload: None, text: "/start"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(combined, ctx, start_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router1_start")

  // Test that router2's command works
  let help_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "help", payload: None, text: "/help"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(combined, ctx2, help_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router2_help")
}

pub fn compose_priority_test() {
  // Both routers handle same command - first should win
  let router1 =
    router.new("router1")
    |> router.on_command("test", fn(ctx, _cmd) {
      Ok(Context(..ctx, session: "router1_wins"))
    })

  let router2 =
    router.new("router2")
    |> router.on_command("test", fn(ctx, _cmd) {
      Ok(Context(..ctx, session: "router2_should_not_run"))
    })

  let combined = router.compose(router1, router2)

  let test_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "test", payload: None, text: "/test"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(combined, ctx, test_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router1_wins")
}

pub fn compose_fallback_test() {
  // First router has no handler, second router's fallback should handle
  let router1 =
    router.new("router1")
    |> router.on_command("start", fn(ctx, _cmd) {
      Ok(Context(..ctx, session: "router1_start"))
    })

  let router2 =
    router.new("router2")
    |> router.fallback(fn(ctx, _) {
      Ok(Context(..ctx, session: "router2_fallback"))
    })

  let combined = router.compose(router1, router2)

  // Test unhandled text update
  let msg = test_message()
  let text_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "random text",
      message: types.Message(..msg, text: Some("random text")),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(combined, ctx, text_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router2_fallback")
}

pub fn compose_catch_handler_test() {
  // Test that catch handlers work correctly in composed routers
  let router1 =
    router.new("router1")
    |> router.on_command("fail1", fn(_ctx, _cmd) {
      Error(error.ActorError("error1"))
    })
    |> router.with_catch_handler(fn(err) {
      case err {
        error.ActorError("error1") -> Ok(test_context("caught_by_router1"))
        _ -> Error(err)
      }
    })

  let router2 =
    router.new("router2")
    |> router.on_command("fail2", fn(_ctx, _cmd) {
      Error(error.ActorError("error2"))
    })
    |> router.with_catch_handler(fn(err) {
      case err {
        error.ActorError("error2") -> Ok(test_context("caught_by_router2"))
        _ -> Error(err)
      }
    })

  let combined = router.compose(router1, router2)

  // Test that router1's catch handler catches its error
  let fail1_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "fail1", payload: None, text: "/fail1"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(combined, ctx1, fail1_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("caught_by_router1")

  // Test that router2's catch handler catches its error
  let fail2_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "fail2", payload: None, text: "/fail2"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(combined, ctx2, fail2_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("caught_by_router2")
}

pub fn nested_compose_test() {
  // Test that compose works with already composed routers
  // Note: Due to how compose works, nested composition will delegate
  // to the second router when the first (composed) router can't handle
  let router1 =
    router.new("router1")
    |> router.on_command("cmd1", fn(_ctx, _cmd) {
      Ok(test_context("handled_by_router1"))
    })

  let router2 =
    router.new("router2")
    |> router.on_command("cmd2", fn(_ctx, _cmd) {
      Ok(test_context("handled_by_router2"))
    })

  let router3 =
    router.new("router3")
    |> router.on_command("cmd3", fn(_ctx, _cmd) {
      Ok(test_context("handled_by_router3"))
    })

  // Compose router1 and router2, then compose with router3
  let composed_1_2 = router.compose(router1, router2)
  let nested_composed = router.compose(composed_1_2, router3)

  // Test cmd3 (should be handled by router3 as composed_1_2 can't handle it)
  let cmd3_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd3", payload: None, text: "/cmd3"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx3 = test_context("initial")
  router.handle(nested_composed, ctx3, cmd3_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("handled_by_router3")
}

pub fn deeply_nested_compose_test() {
  // Test deeply nested composition with middleware
  let router1 =
    router.new("router1")
    |> router.use_middleware(fn(handler) {
      fn(ctx: bot.Context(String, error.TelegaError), update) {
        handler(test_context(ctx.session <> "_mw1"), update)
      }
    })
    |> router.on_command("cmd1", fn(ctx, _) {
      Ok(test_context(ctx.session <> "_r1"))
    })

  let router2 =
    router.new("router2")
    |> router.use_middleware(fn(handler) {
      fn(ctx: bot.Context(String, error.TelegaError), update) {
        handler(test_context(ctx.session <> "_mw2"), update)
      }
    })
    |> router.on_command("cmd2", fn(ctx, _) {
      Ok(test_context(ctx.session <> "_r2"))
    })

  let router3 =
    router.new("router3")
    |> router.use_middleware(fn(handler) {
      fn(ctx: bot.Context(String, error.TelegaError), update) {
        handler(test_context(ctx.session <> "_mw3"), update)
      }
    })
    |> router.on_command("cmd3", fn(ctx, _) {
      Ok(test_context(ctx.session <> "_r3"))
    })

  let router4 =
    router.new("router4")
    |> router.use_middleware(fn(handler) {
      fn(ctx: bot.Context(String, error.TelegaError), update) {
        handler(test_context(ctx.session <> "_mw4"), update)
      }
    })
    |> router.on_command("cmd4", fn(ctx, _) {
      Ok(test_context(ctx.session <> "_r4"))
    })

  // Create nested composition: ((r1 + r2) + (r3 + r4))
  let composed_1_2 = router.compose(router1, router2)
  let composed_3_4 = router.compose(router3, router4)
  let final_composed = router.compose(composed_1_2, composed_3_4)

  // Test cmd1 - should get middleware from router1 only
  let cmd1_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd1", payload: None, text: "/cmd1"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx1 = test_context("init")
  router.handle(final_composed, ctx1, cmd1_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("init_mw1_r1")

  // Test cmd3 - should get middleware from router3 only
  let cmd3_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd3", payload: None, text: "/cmd3"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx3 = test_context("init")
  router.handle(final_composed, ctx3, cmd3_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("init_mw3_r3")
}

pub fn nested_compose_with_fallback_test() {
  // Test nested compose with fallback handlers
  let router1 =
    router.new("router1")
    |> router.on_command("cmd1", fn(_ctx, _cmd) {
      Ok(test_context("handled_by_router1"))
    })

  let router2 =
    router.new("router2")
    |> router.on_command("cmd2", fn(_ctx, _cmd) {
      Ok(test_context("handled_by_router2"))
    })
    |> router.fallback(fn(_ctx, _) { Ok(test_context("fallback_router2")) })

  let router3 =
    router.new("router3")
    |> router.on_command("cmd3", fn(_ctx, _cmd) {
      Ok(test_context("handled_by_router3"))
    })
    |> router.fallback(fn(_ctx, _) { Ok(test_context("fallback_router3")) })

  // Compose router1 and router2, then compose with router3
  let composed_1_2 = router.compose(router1, router2)
  let nested_composed = router.compose(composed_1_2, router3)

  // Test unknown command - should be handled by router2's fallback (first fallback in chain)
  let unknown_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(
        command: "unknown",
        payload: None,
        text: "/unknown",
      ),
      message: test_message(),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(nested_composed, ctx, unknown_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("fallback_router2")
}

pub fn merge_with_composed_router_test() {
  // Test merge behavior with ComposedRouter
  let router1 =
    router.new("router1")
    |> router.on_command("cmd1", fn(_ctx, _cmd) {
      Ok(test_context("router1_cmd1"))
    })

  let router2 =
    router.new("router2")
    |> router.on_command("cmd2", fn(_ctx, _cmd) {
      Ok(test_context("router2_cmd2"))
    })

  let router3 =
    router.new("router3")
    |> router.on_command("cmd3", fn(_ctx, _cmd) {
      Ok(test_context("router3_cmd3"))
    })

  // Create composed router
  let composed_1_2 = router.compose(router1, router2)

  // Test: merge ComposedRouter with regular Router
  let merged = router.merge(composed_1_2, router3)

  // All commands should be available in merged router
  let cmd1_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd1", payload: None, text: "/cmd1"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(merged, ctx1, cmd1_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router1_cmd1")

  let cmd2_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd2", payload: None, text: "/cmd2"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(merged, ctx2, cmd2_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router2_cmd2")

  let cmd3_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd3", payload: None, text: "/cmd3"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx3 = test_context("initial")
  router.handle(merged, ctx3, cmd3_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router3_cmd3")
}

pub fn merge_composed_with_composed_test() {
  // Test merge with two ComposedRouters
  let router1 =
    router.new("router1")
    |> router.on_command("cmd1", fn(_ctx, _cmd) {
      Ok(test_context("router1_cmd1"))
    })

  let router2 =
    router.new("router2")
    |> router.on_command("cmd2", fn(_ctx, _cmd) {
      Ok(test_context("router2_cmd2"))
    })

  let router3 =
    router.new("router3")
    |> router.on_command("cmd3", fn(_ctx, _cmd) {
      Ok(test_context("router3_cmd3"))
    })

  let router4 =
    router.new("router4")
    |> router.on_command("cmd4", fn(_ctx, _cmd) {
      Ok(test_context("router4_cmd4"))
    })

  // Create two composed routers
  let composed_1_2 = router.compose(router1, router2)
  let composed_3_4 = router.compose(router3, router4)

  // Merge them
  let merged = router.merge(composed_1_2, composed_3_4)

  // All commands should be available
  let cmd1_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd1", payload: None, text: "/cmd1"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(merged, ctx1, cmd1_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router1_cmd1")

  let cmd4_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd4", payload: None, text: "/cmd4"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx4 = test_context("initial")
  router.handle(merged, ctx4, cmd4_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router4_cmd4")
}

pub fn simple_filter_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(router.is_text(), fn(_ctx, _) {
      Ok(test_context("text_matched"))
    })
    |> router.on_filtered(router.is_command(), fn(_ctx, _) {
      Ok(test_context("command_matched"))
    })

  let text_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hello",
      message: test_message(),
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(test_router, ctx1, text_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("text_matched")

  let cmd_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "start", payload: None, text: "/start"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(test_router, ctx2, cmd_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("command_matched")
}

pub fn filter_composition_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(router.is_text(), fn(_ctx, _) {
      Ok(test_context("any_text"))
    })
    |> router.on_filtered(
      router.and2(router.is_text(), router.text_starts_with("Hello")),
      fn(_ctx, _) { Ok(test_context("hello_matched")) },
    )

  let hello_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hello World",
      message: test_message(),
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(test_router, ctx1, hello_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("hello_matched")

  let other_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Goodbye",
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(test_router, ctx2, other_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("any_text")
}

pub fn filter_or_logic_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(
      router.or2(router.text_equals("help"), router.command_equals("help")),
      fn(_ctx, _) { Ok(test_context("help_matched")) },
    )

  let text_help =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "help",
      message: test_message(),
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(test_router, ctx1, text_help)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("help_matched")

  let cmd_help =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "help", payload: None, text: "/help"),
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(test_router, ctx2, cmd_help)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("help_matched")
}

pub fn filter_not_logic_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(
      router.and2(router.is_text(), router.not(router.text_starts_with("/"))),
      fn(_ctx, _) { Ok(test_context("not_command")) },
    )

  let text_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hello",
      message: test_message(),
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(test_router, ctx1, text_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("not_command")

  let cmd_like =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "/start",
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(test_router, ctx2, cmd_like)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial")
}

pub fn filter_user_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(router.from_user(123), fn(_ctx, _) {
      Ok(test_context("user_123"))
    })
    |> router.on_filtered(router.from_users([456, 789]), fn(_ctx, _) {
      Ok(test_context("special_users"))
    })

  let user123_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hello",
      message: test_message(),
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(test_router, ctx1, user123_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("user_123")

  let user456_update =
    update.TextUpdate(
      from_id: 456,
      chat_id: 999,
      text: "Hello",
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(test_router, ctx2, user456_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("special_users")
}

pub fn filter_chat_type_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(router.is_private_chat(), fn(_ctx, _) {
      Ok(test_context("private_chat"))
    })
    |> router.on_filtered(router.is_group_chat(), fn(_ctx, _) {
      Ok(test_context("group_chat"))
    })

  let private_msg =
    types.Message(
      ..test_message(),
      chat: types.Chat(
        id: 456,
        type_: Some("private"),
        title: None,
        username: None,
        first_name: Some("Test"),
        last_name: Some("User"),
        is_forum: None,
        is_direct_messages: None,
      ),
    )

  let private_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hello",
      message: private_msg,
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(test_router, ctx1, private_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("private_chat")

  let group_msg =
    types.Message(
      ..test_message(),
      chat: types.Chat(
        id: 789,
        type_: Some("group"),
        title: Some("Test Group"),
        username: None,
        first_name: None,
        last_name: None,
        is_forum: None,
        is_direct_messages: None,
      ),
    )

  let group_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 789,
      text: "Hello",
      message: group_msg,
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(test_router, ctx2, group_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("group_chat")
}

pub fn custom_filter_test() {
  let is_long_text =
    router.filter("long_text", fn(upd) {
      case upd {
        update.TextUpdate(text:, ..) -> string.length(text) > 10
        _ -> False
      }
    })

  let test_router =
    router.new("filter_test")
    |> router.on_filtered(router.is_text(), fn(_ctx, _) {
      Ok(test_context("short_text"))
    })
    |> router.on_filtered(is_long_text, fn(_ctx, _) {
      Ok(test_context("long_text"))
    })

  // Test long text
  let long_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "This is a very long text message",
      message: test_message(),
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(test_router, ctx1, long_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("long_text")

  let short_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hi",
      message: test_message(),
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(test_router, ctx2, short_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("short_text")
}

pub fn complex_filter_composition_test() {
  let admin_ids = [100, 200, 300]

  let test_router =
    router.new("filter_test")
    |> router.on_filtered(
      router.and([
        router.is_text(),
        router.from_users(admin_ids),
        router.text_starts_with("!"),
        router.is_group_chat(),
      ]),
      fn(_ctx, _) { Ok(test_context("admin_group_command")) },
    )

  let group_msg =
    types.Message(
      ..test_message(),
      chat: types.Chat(
        id: 789,
        type_: Some("group"),
        title: Some("Test Group"),
        username: None,
        first_name: None,
        last_name: None,
        is_forum: None,
        is_direct_messages: None,
      ),
    )

  let admin_update =
    update.TextUpdate(
      from_id: 200,
      chat_id: 789,
      text: "!ban user123",
      message: group_msg,
      raw: test_update(),
    )

  let ctx1 = test_context("initial")
  router.handle(test_router, ctx1, admin_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("admin_group_command")

  let non_admin_update =
    update.TextUpdate(
      from_id: 999,
      chat_id: 789,
      text: "!ban user123",
      message: group_msg,
      raw: test_update(),
    )

  let ctx2 = test_context("initial")
  router.handle(test_router, ctx2, non_admin_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial")
}

pub fn inline_query_handler_test() {
  let handler = fn(ctx: Context(String, TelegaError), query: types.InlineQuery) {
    Ok(Context(..ctx, session: "inline_query:" <> query.query))
  }

  let r =
    router.new("test")
    |> router.on_inline_query(handler)

  let inline_query_update =
    update.InlineQueryUpdate(
      from_id: 123,
      chat_id: 123,
      inline_query: types.InlineQuery(
        id: "query123",
        from: types.User(
          id: 123,
          is_bot: False,
          first_name: "Test",
          last_name: None,
          username: None,
          language_code: None,
          is_premium: None,
          added_to_attachment_menu: None,
          can_join_groups: None,
          can_read_all_group_messages: None,
          supports_inline_queries: None,
          can_connect_to_business: None,
          has_main_web_app: None,
          has_topics_enabled: None,
          allows_users_to_create_topics: None,
        ),
        query: "search text",
        offset: "0",
        chat_type: None,
        location: None,
      ),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, inline_query_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("inline_query:search text")
}

pub fn chosen_inline_result_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    result: types.ChosenInlineResult,
  ) {
    Ok(Context(..ctx, session: "chosen:" <> result.result_id))
  }

  let r =
    router.new("test")
    |> router.on_chosen_inline_result(handler)

  let chosen_result_update =
    update.ChosenInlineResultUpdate(
      from_id: 123,
      chat_id: 123,
      chosen_inline_result: types.ChosenInlineResult(
        result_id: "result456",
        from: types.User(
          id: 123,
          is_bot: False,
          first_name: "Test",
          last_name: None,
          username: None,
          language_code: None,
          is_premium: None,
          added_to_attachment_menu: None,
          can_join_groups: None,
          can_read_all_group_messages: None,
          supports_inline_queries: None,
          can_connect_to_business: None,
          has_main_web_app: None,
          has_topics_enabled: None,
          allows_users_to_create_topics: None,
        ),
        location: None,
        inline_message_id: None,
        query: "test query",
      ),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, chosen_result_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("chosen:result456")
}

pub fn poll_handler_test() {
  let handler = fn(ctx: Context(String, TelegaError), poll: types.Poll) {
    Ok(Context(..ctx, session: "poll:" <> poll.question))
  }

  let r =
    router.new("test")
    |> router.on_poll(handler)

  let poll_update =
    update.PollUpdate(
      from_id: -1,
      chat_id: -1,
      poll: types.Poll(
        id: "poll123",
        question: "Do you like Gleam?",
        question_entities: None,
        options: [
          types.PollOption(text: "Yes", text_entities: None, voter_count: 10),
          types.PollOption(text: "No", text_entities: None, voter_count: 2),
        ],
        total_voter_count: 12,
        is_closed: False,
        is_anonymous: True,
        type_: "regular",
        allows_multiple_answers: False,
        correct_option_id: None,
        explanation: None,
        explanation_entities: None,
        open_period: None,
        close_date: None,
      ),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, poll_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("poll:Do you like Gleam?")
}

pub fn poll_answer_handler_test() {
  let handler = fn(ctx: Context(String, TelegaError), answer: types.PollAnswer) {
    Ok(Context(..ctx, session: "poll_answer:" <> answer.poll_id))
  }

  let r =
    router.new("test")
    |> router.on_poll_answer(handler)

  let poll_answer_update =
    update.PollAnswerUpdate(
      from_id: 123,
      chat_id: 123,
      poll_answer: types.PollAnswer(
        poll_id: "poll123",
        voter_chat: None,
        user: Some(types.User(
          id: 123,
          is_bot: False,
          first_name: "Test",
          last_name: None,
          username: None,
          language_code: None,
          is_premium: None,
          added_to_attachment_menu: None,
          can_join_groups: None,
          can_read_all_group_messages: None,
          supports_inline_queries: None,
          can_connect_to_business: None,
          has_main_web_app: None,
          has_topics_enabled: None,
          allows_users_to_create_topics: None,
        )),
        option_ids: [0],
      ),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, poll_answer_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("poll_answer:poll123")
}

pub fn shipping_query_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    query: types.ShippingQuery,
  ) {
    Ok(Context(..ctx, session: "shipping:" <> query.id))
  }

  let r =
    router.new("test")
    |> router.on_shipping_query(handler)

  let shipping_query_update =
    update.ShippingQueryUpdate(
      from_id: 123,
      chat_id: 123,
      shipping_query: types.ShippingQuery(
        id: "shipping123",
        from: types.User(
          id: 123,
          is_bot: False,
          first_name: "Test",
          last_name: None,
          username: None,
          language_code: None,
          is_premium: None,
          added_to_attachment_menu: None,
          can_join_groups: None,
          can_read_all_group_messages: None,
          supports_inline_queries: None,
          can_connect_to_business: None,
          has_main_web_app: None,
          has_topics_enabled: None,
          allows_users_to_create_topics: None,
        ),
        invoice_payload: "test_payload",
        shipping_address: types.ShippingAddress(
          country_code: "US",
          state: "CA",
          city: "San Francisco",
          street_line1: "123 Main St",
          street_line2: "",
          post_code: "94102",
        ),
      ),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, shipping_query_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("shipping:shipping123")
}

pub fn pre_checkout_query_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    query: types.PreCheckoutQuery,
  ) {
    Ok(Context(..ctx, session: "checkout:" <> query.id))
  }

  let r =
    router.new("test")
    |> router.on_pre_checkout_query(handler)

  let pre_checkout_query_update =
    update.PreCheckoutQueryUpdate(
      from_id: 123,
      chat_id: 123,
      pre_checkout_query: types.PreCheckoutQuery(
        id: "checkout123",
        from: types.User(
          id: 123,
          is_bot: False,
          first_name: "Test",
          last_name: None,
          username: None,
          language_code: None,
          is_premium: None,
          added_to_attachment_menu: None,
          can_join_groups: None,
          can_read_all_group_messages: None,
          supports_inline_queries: None,
          can_connect_to_business: None,
          has_main_web_app: None,
          has_topics_enabled: None,
          allows_users_to_create_topics: None,
        ),
        currency: "USD",
        total_amount: 1000,
        invoice_payload: "test_payload",
        shipping_option_id: None,
        order_info: None,
      ),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, pre_checkout_query_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("checkout:checkout123")
}

pub fn message_reaction_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    reaction: types.MessageReactionUpdated,
  ) {
    Ok(Context(..ctx, session: "reaction:" <> string.inspect(reaction.chat.id)))
  }

  let r =
    router.new("test")
    |> router.on_reaction(handler)

  let reaction_update =
    update.MessageReactionUpdate(
      from_id: 123,
      chat_id: 456,
      message_reaction_updated: types.MessageReactionUpdated(
        chat: types.Chat(
          id: 456,
          type_: Some("private"),
          title: None,
          username: None,
          first_name: Some("Test"),
          last_name: None,
          is_forum: None,
          is_direct_messages: None,
        ),
        message_id: 789,
        user: Some(types.User(
          id: 123,
          is_bot: False,
          first_name: "Test",
          last_name: None,
          username: None,
          language_code: None,
          is_premium: None,
          added_to_attachment_menu: None,
          can_join_groups: None,
          can_read_all_group_messages: None,
          supports_inline_queries: None,
          can_connect_to_business: None,
          has_main_web_app: None,
          has_topics_enabled: None,
          allows_users_to_create_topics: None,
        )),
        actor_chat: None,
        date: 1_234_567_890,
        old_reaction: [],
        new_reaction: [],
      ),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, reaction_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("reaction:456")
}

pub fn chat_member_updated_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    member: types.ChatMemberUpdated,
  ) {
    Ok(
      Context(
        ..ctx,
        session: "member_updated:" <> string.inspect(member.chat.id),
      ),
    )
  }

  let r =
    router.new("test")
    |> router.on_chat_member_updated(handler)

  let member_updated_update =
    update.ChatMemberUpdate(
      from_id: 123,
      chat_id: 456,
      chat_member_updated: types.ChatMemberUpdated(
        chat: types.Chat(
          id: 456,
          type_: Some("group"),
          title: Some("Test Group"),
          username: None,
          first_name: None,
          last_name: None,
          is_forum: None,
          is_direct_messages: None,
        ),
        from: types.User(
          id: 123,
          is_bot: False,
          first_name: "Admin",
          last_name: None,
          username: None,
          language_code: None,
          is_premium: None,
          added_to_attachment_menu: None,
          can_join_groups: None,
          can_read_all_group_messages: None,
          supports_inline_queries: None,
          can_connect_to_business: None,
          has_main_web_app: None,
          has_topics_enabled: None,
          allows_users_to_create_topics: None,
        ),
        date: 1_234_567_890,
        old_chat_member: types.ChatMemberMemberChatMember(
          types.ChatMemberMember(
            status: "member",
            user: types.User(
              id: 789,
              is_bot: False,
              first_name: "Member",
              last_name: None,
              username: None,
              language_code: None,
              is_premium: None,
              added_to_attachment_menu: None,
              can_join_groups: None,
              can_read_all_group_messages: None,
              supports_inline_queries: None,
              can_connect_to_business: None,
              has_main_web_app: None,
              has_topics_enabled: None,
              allows_users_to_create_topics: None,
            ),
            until_date: None,
          ),
        ),
        new_chat_member: types.ChatMemberMemberChatMember(
          types.ChatMemberMember(
            status: "member",
            user: types.User(
              id: 789,
              is_bot: False,
              first_name: "Member",
              last_name: None,
              username: None,
              language_code: None,
              is_premium: None,
              added_to_attachment_menu: None,
              can_join_groups: None,
              can_read_all_group_messages: None,
              supports_inline_queries: None,
              can_connect_to_business: None,
              has_main_web_app: None,
              has_topics_enabled: None,
              allows_users_to_create_topics: None,
            ),
            until_date: None,
          ),
        ),
        invite_link: None,
        via_join_request: None,
        via_chat_folder_invite_link: None,
      ),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, member_updated_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("member_updated:456")
}

pub fn chat_join_request_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    request: types.ChatJoinRequest,
  ) {
    Ok(Context(..ctx, session: "join_request:" <> request.from.first_name))
  }

  let r =
    router.new("test")
    |> router.on_chat_join_request(handler)

  let join_request_update =
    update.ChatJoinRequestUpdate(
      from_id: 123,
      chat_id: 456,
      chat_join_request: types.ChatJoinRequest(
        chat: types.Chat(
          id: 456,
          type_: Some("group"),
          title: Some("Private Group"),
          username: None,
          first_name: None,
          last_name: None,
          is_forum: None,
          is_direct_messages: None,
        ),
        from: types.User(
          id: 123,
          is_bot: False,
          first_name: "NewUser",
          last_name: None,
          username: Some("newuser"),
          language_code: None,
          is_premium: None,
          added_to_attachment_menu: None,
          can_join_groups: None,
          can_read_all_group_messages: None,
          supports_inline_queries: None,
          can_connect_to_business: None,
          has_main_web_app: None,
          has_topics_enabled: None,
          allows_users_to_create_topics: None,
        ),
        user_chat_id: 123,
        date: 1_234_567_890,
        bio: None,
        invite_link: None,
      ),
      raw: test_update(),
    )

  let ctx = test_context("initial")
  router.handle(r, ctx, join_request_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("join_request:NewUser")
}
