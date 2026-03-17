//// Data factories for creating test instances of Telegram types.
////
//// All functions return deterministic default values, making tests
//// reproducible and easy to write. Use `_with` variants for customization.
////
//// ```gleam
//// import telega/testing/factory
////
//// let update = factory.text_update("Hello")
//// let cmd = factory.command_update("start")
//// ```

import gleam/option.{None, Some}

import telega/model/types
import telega/update

const default_bot_id = 1_000_000

const default_user_id = 987_654_321

const default_chat_id = 123_456_789

const default_date = 1_640_995_200

/// Creates a bot user with sensible defaults.
pub fn bot_user() -> types.User {
  types.User(
    id: default_bot_id,
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

/// Creates a regular (non-bot) user with sensible defaults.
pub fn user() -> types.User {
  types.User(
    id: default_user_id,
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
  )
}

/// Creates a user with custom id and first_name.
pub fn user_with(id id: Int, first_name first_name: String) -> types.User {
  types.User(..user(), id:, first_name:)
}

/// Creates a private chat with sensible defaults.
pub fn chat() -> types.Chat {
  types.Chat(
    id: default_chat_id,
    type_: "private",
    title: None,
    username: None,
    first_name: Some("TestUser"),
    last_name: None,
    is_forum: None,
    is_direct_messages: None,
  )
}

/// Creates a chat with custom id and type.
pub fn chat_with(id id: Int, type_ type_: String) -> types.Chat {
  types.Chat(..chat(), id:, type_:)
}

/// Creates a message with the given text, using default user and chat.
pub fn message(text text: String) -> types.Message {
  message_with(text:, from: user(), chat: chat())
}

/// Creates a message with custom text, from user, and chat.
pub fn message_with(
  text text: String,
  from from: types.User,
  chat chat: types.Chat,
) -> types.Message {
  types.Message(
    message_id: 1,
    message_thread_id: None,
    from: Some(from),
    sender_chat: None,
    direct_messages_topic: None,
    sender_boost_count: None,
    sender_business_bot: None,
    sender_tag: None,
    date: default_date,
    business_connection_id: None,
    chat:,
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

/// Creates a raw `types.Update` wrapping a message.
pub fn raw_update(message message: types.Message) -> types.Update {
  raw_update_with(message:, update_id: 1)
}

/// Creates a raw `types.Update` with custom update_id.
pub fn raw_update_with(
  message message: types.Message,
  update_id update_id: Int,
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

/// Creates a typed `TextUpdate` with default user/chat IDs.
pub fn text_update(text text: String) -> update.Update {
  text_update_with(text:, from_id: default_user_id, chat_id: default_chat_id)
}

/// Creates a typed `TextUpdate` with custom from_id and chat_id.
pub fn text_update_with(
  text text: String,
  from_id from_id: Int,
  chat_id chat_id: Int,
) -> update.Update {
  let from = user_with(id: from_id, first_name: "TestUser")
  let chat = chat_with(id: chat_id, type_: "private")
  let msg = message_with(text:, from:, chat:)
  update.TextUpdate(
    text:,
    message: msg,
    from_id:,
    chat_id:,
    raw: raw_update(message: msg),
  )
}

/// Creates a `Command` record.
pub fn command(command cmd: String) -> update.Command {
  command_with(command: cmd, payload: None)
}

/// Creates a `Command` record with a payload.
pub fn command_with(
  command cmd: String,
  payload payload: option.Option(String),
) -> update.Command {
  update.Command(command: cmd, payload:, text: "/" <> cmd)
}

/// Creates a typed `CommandUpdate` with default user/chat IDs.
pub fn command_update(command cmd: String) -> update.Update {
  command_update_with(
    command: cmd,
    payload: None,
    from_id: default_user_id,
    chat_id: default_chat_id,
  )
}

/// Creates a typed `CommandUpdate` with custom payload, from_id, and chat_id.
pub fn command_update_with(
  command cmd: String,
  payload payload: option.Option(String),
  from_id from_id: Int,
  chat_id chat_id: Int,
) -> update.Update {
  let from = user_with(id: from_id, first_name: "TestUser")
  let chat = chat_with(id: chat_id, type_: "private")
  let msg = message_with(text: "/" <> cmd, from:, chat:)
  let command = command_with(command: cmd, payload:)
  update.CommandUpdate(
    command:,
    message: msg,
    from_id:,
    chat_id:,
    raw: raw_update(message: msg),
  )
}

/// Creates a typed `CallbackQueryUpdate` with default user/chat IDs.
pub fn callback_query_update(data data: String) -> update.Update {
  callback_query_update_with(
    data:,
    from_id: default_user_id,
    chat_id: default_chat_id,
  )
}

/// Creates a typed `CallbackQueryUpdate` with custom from_id and chat_id.
pub fn callback_query_update_with(
  data data: String,
  from_id from_id: Int,
  chat_id chat_id: Int,
) -> update.Update {
  let from = user_with(id: from_id, first_name: "TestUser")
  let chat = chat_with(id: chat_id, type_: "private")
  let msg = message_with(text: "", from:, chat:)
  let query =
    types.CallbackQuery(
      id: "test_callback_query",
      from:,
      message: Some(types.MessageMaybeInaccessibleMessage(msg)),
      inline_message_id: None,
      chat_instance: "test_chat_instance",
      data: Some(data),
      game_short_name: None,
    )
  let raw =
    types.Update(
      ..raw_update(message: msg),
      message: None,
      callback_query: Some(query),
    )
  update.CallbackQueryUpdate(query:, from_id:, chat_id:, raw:)
}
