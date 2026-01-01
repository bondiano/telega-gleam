import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleeunit/should

import telega/bot
import telega/internal/config
import telega/internal/registry
import telega/model/types
import telega/update

pub type TestSession {
  TestSession(name: String)
}

pub type TestError {
  TestError(message: String)
}

const test_user_id = 987_654_321

const test_chat_id = 123_456_789

const test_bot_id = 123_456_789

fn create_test_config() -> config.Config {
  config.new(
    token: "test_token",
    webhook_path: "test_webhook",
    secret_token: None,
    url: "https://test.example.com",
  )
}

fn create_test_user() -> types.User {
  types.User(
    id: test_bot_id,
    is_bot: True,
    first_name: "TestBot",
    last_name: None,
    username: Some("testbot"),
    language_code: None,
    is_premium: None,
    added_to_attachment_menu: None,
    can_join_groups: None,
    can_read_all_group_messages: None,
    supports_inline_queries: None,
    can_connect_to_business: None,
    has_main_web_app: None,
    has_topics_enabled: None,
  )
}

fn create_default_session_settings() -> bot.SessionSettings(
  TestSession,
  TestError,
) {
  bot.SessionSettings(
    persist_session: fn(_key, session) { Ok(session) },
    get_session: fn(_key) { Ok(None) },
    default_session: fn() { TestSession(name: "") },
  )
}

fn create_test_catch_handler() -> bot.CatchHandler(TestSession, TestError) {
  fn(_ctx, _error) { Ok(Nil) }
}

fn build_test_user() -> types.User {
  types.User(
    id: test_user_id,
    is_bot: False,
    first_name: "TestUser",
    last_name: None,
    username: Some("testuser"),
    language_code: None,
    is_premium: None,
    added_to_attachment_menu: None,
    can_join_groups: None,
    can_read_all_group_messages: None,
    supports_inline_queries: None,
    can_connect_to_business: None,
    has_main_web_app: None,
    has_topics_enabled: None,
  )
}

fn build_test_chat() -> types.Chat {
  types.Chat(
    id: test_chat_id,
    type_: Some("private"),
    title: None,
    username: None,
    first_name: Some("TestUser"),
    last_name: None,
    is_forum: None,
    is_direct_messages: None,
  )
}

fn build_minimal_message(text: String) -> types.Message {
  types.Message(
    message_id: 1,
    message_thread_id: None,
    from: Some(build_test_user()),
    sender_chat: None,
    direct_messages_topic: None,
    sender_boost_count: None,
    sender_business_bot: None,
    date: 1_640_995_200,
    business_connection_id: None,
    chat: build_test_chat(),
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
    text: Some(text),
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

fn build_minimal_raw_update(
  message: types.Message,
  update_id: Int,
) -> types.Update {
  types.Update(
    update_id:,
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
}

fn command_update(command: String) -> update.Update {
  let message = build_minimal_message("/" <> command)
  update.CommandUpdate(
    message:,
    from_id: test_user_id,
    chat_id: test_chat_id,
    command: update.Command(text: "/" <> command, command:, payload: None),
    raw: build_minimal_raw_update(message, 1),
  )
}

fn text_update(text: String) -> update.Update {
  let message = build_minimal_message(text)
  update.TextUpdate(
    text:,
    message:,
    from_id: test_user_id,
    chat_id: test_chat_id,
    raw: build_minimal_raw_update(message, 2),
  )
}

fn handlers_to_router_handler(
  handlers: List(bot.Handler(TestSession, TestError)),
) -> fn(bot.Context(TestSession, TestError), update.Update) ->
  Result(bot.Context(TestSession, TestError), TestError) {
  fn(ctx, upd) {
    // Find and execute the first matching handler
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

fn build_test_bot(
  router_handler: fn(bot.Context(TestSession, TestError), update.Update) ->
    Result(bot.Context(TestSession, TestError), TestError),
  session_settings: bot.SessionSettings(TestSession, TestError),
) -> bot.BotSubject {
  let assert Ok(registry) = registry.start()
  let config = create_test_config()
  let bot_info = create_test_user()
  let catch_handler = create_test_catch_handler()

  let assert Ok(bot_subject) =
    bot.start(
      registry:,
      config:,
      bot_info:,
      router_handler:,
      session_settings:,
      catch_handler:,
    )

  bot_subject
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

  let session_settings = create_default_session_settings()
  let bot_subject =
    build_test_bot(handlers_to_router_handler(handlers), session_settings)

  let result1 = bot.handle_update(bot_subject, command_update("setname"))
  result1 |> should.be_true

  let result2 = bot.handle_update(bot_subject, text_update("John Doe"))
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

  let result1 = bot.handle_update(bot_subject, command_update("setname"))
  result1 |> should.be_true

  let result2 = bot.handle_update(bot_subject, text_update("Alice"))
  result2 |> should.be_true

  let result3 = bot.handle_update(bot_subject, command_update("getname"))
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

  let session_settings = create_default_session_settings()
  let bot_subject =
    build_test_bot(handlers_to_router_handler(handlers), session_settings)

  let result1 = bot.handle_update(bot_subject, command_update("setname"))
  result1 |> should.be_true

  let result2 = bot.handle_update(bot_subject, text_update("Alice"))
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

  let result1 = bot.handle_update(bot_subject, command_update("setname"))
  result1 |> should.be_true

  let result2 = bot.handle_update(bot_subject, command_update("cancel"))
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
