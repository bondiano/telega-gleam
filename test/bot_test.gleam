import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should

import telega/bot
import telega/internal/config
import telega/internal/registry
import telega/model/types
import telega/update

pub type TestSession {
  TestSession(counter: Int)
}

pub type TestError {
  TestError(message: String)
}

fn create_test_config() -> config.Config {
  config.new(
    token: "test_token",
    webhook_path: "test_webhook",
    secret_token: None,
    url: "https://test.example.com",
  )
}

pub fn create_test_user() -> types.User {
  types.User(
    id: 123_456_789,
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
    allows_users_to_create_topics: None,
  )
}

fn create_test_session_settings() -> bot.SessionSettings(TestSession, TestError) {
  bot.SessionSettings(
    persist_session: fn(_key, session) { Ok(session) },
    get_session: fn(_key) { Ok(Some(TestSession(counter: 0))) },
    default_session: fn() { TestSession(counter: 0) },
  )
}

fn create_test_catch_handler() -> bot.CatchHandler(TestSession, TestError) {
  fn(_ctx, _error) { Ok(Nil) }
}

fn create_test_update() -> update.Update {
  let message =
    types.Message(
      message_id: 1,
      message_thread_id: None,
      from: Some(types.User(
        id: 987_654_321,
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
        allows_users_to_create_topics: None,
      )),
      sender_chat: None,
      direct_messages_topic: None,
      sender_boost_count: None,
      sender_business_bot: None,
      date: 1_640_995_200,
      business_connection_id: None,
      chat: types.Chat(
        id: 123_456_789,
        type_: Some("private"),
        title: None,
        username: None,
        first_name: Some("TestUser"),
        last_name: None,
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
      text: Some("Hello"),
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

  update.TextUpdate(
    message:,
    from_id: 987_654_321,
    chat_id: 123_456_789,
    text: "Hello",
    raw: types.Update(
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
    ),
  )
}

pub fn bot_start_test() {
  let assert Ok(registry) = registry.start()
  let config = create_test_config()
  let bot_info = create_test_user()
  let router_handler = fn(ctx, _update) { Ok(ctx) }
  let session_settings = create_test_session_settings()
  let catch_handler = create_test_catch_handler()

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
  let config = create_test_config()
  let bot_info = create_test_user()
  let router_handler = fn(ctx, _update) { Ok(ctx) }
  let session_settings = create_test_session_settings()
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

  let test_update = create_test_update()
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
  let config = create_test_config()
  let test_update = create_test_update()
  let chat_subject = process.new_subject()

  let ctx =
    bot.Context(
      key: "test_chat:123",
      update: test_update,
      config:,
      session: TestSession(counter: 5),
      chat_subject:,
      start_time: None,
      log_prefix: None,
      bot_info: create_test_user(),
    )

  let new_session = TestSession(counter: 10)
  let assert Ok(updated_ctx) = bot.next_session(ctx, new_session)

  updated_ctx.session.counter |> should.equal(10)
  updated_ctx.key |> should.equal("test_chat:123")
}

pub fn get_session_test() {
  let session_settings = create_test_session_settings()
  let test_update = create_test_update()

  let result = bot.get_session(session_settings, test_update)

  result |> should.be_ok
  let assert Ok(Some(session)) = result
  session.counter |> should.equal(0)
}

pub fn handler_types_test() {
  let _test_ctx =
    bot.Context(
      key: "test",
      update: create_test_update(),
      config: create_test_config(),
      session: TestSession(counter: 0),
      chat_subject: process.new_subject(),
      start_time: None,
      log_prefix: None,
      bot_info: create_test_user(),
    )

  let handle_all = bot.HandleAll(fn(ctx, _update) { Ok(ctx) })

  let handle_text = bot.HandleText(fn(ctx, _text) { Ok(ctx) })

  let handle_command = bot.HandleCommand("start", fn(ctx, _command) { Ok(ctx) })

  [handle_all, handle_text, handle_command]
  |> list.length
  |> should.equal(3)
}

pub fn wait_handler_test() {
  let ctx =
    bot.Context(
      key: "test",
      update: create_test_update(),
      config: create_test_config(),
      session: TestSession(counter: 0),
      chat_subject: process.new_subject(),
      start_time: None,
      log_prefix: None,
      bot_info: create_test_user(),
    )

  let handler = bot.HandleText(fn(ctx, _text) { Ok(ctx) })
  let result =
    bot.wait_handler(ctx:, handler:, handle_else: None, timeout: Some(1000))

  should.be_ok(result)
}
