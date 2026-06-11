import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import telega/error
import telega/internal/log
import telega/model/decoder.{update_decoder}
import telega/model/types.{
  type Audio, type BusinessConnection, type BusinessMessagesDeleted,
  type CallbackQuery, type ChatBoostRemoved, type ChatJoinRequest,
  type ChatMemberUpdated, type ChosenInlineResult, type InlineQuery,
  type ManagedBotUpdated, type Message, type MessageEntity,
  type MessageReactionCountUpdated, type MessageReactionUpdated,
  type PaidMediaPurchased, type PhotoSize, type Poll, type PollAnswer,
  type PreCheckoutQuery, type ShippingQuery, type Update as ModelUpdate,
  type Video, type Voice, type WebAppData,
  InaccessibleMessageMaybeInaccessibleMessage, MessageMaybeInaccessibleMessage,
}

/// Messages represent the data that the bot receives from the Telegram API.
pub type Update {
  TextUpdate(
    from_id: Int,
    chat_id: Int,
    text: String,
    message: Message,
    raw: ModelUpdate,
  )
  CommandUpdate(
    from_id: Int,
    chat_id: Int,
    command: Command,
    message: Message,
    raw: ModelUpdate,
  )
  PhotoUpdate(
    from_id: Int,
    chat_id: Int,
    photos: List(PhotoSize),
    message: Message,
    raw: ModelUpdate,
  )
  VideoUpdate(
    from_id: Int,
    chat_id: Int,
    video: Video,
    message: Message,
    raw: ModelUpdate,
  )
  AudioUpdate(
    from_id: Int,
    chat_id: Int,
    audio: Audio,
    message: Message,
    raw: ModelUpdate,
  )
  VoiceUpdate(
    from_id: Int,
    chat_id: Int,
    voice: Voice,
    message: Message,
    raw: ModelUpdate,
  )
  MediaGroupUpdate(
    from_id: Int,
    chat_id: Int,
    media_group_id: String,
    messages: List(Message),
    raw: ModelUpdate,
  )
  WebAppUpdate(
    from_id: Int,
    chat_id: Int,
    web_app_data: WebAppData,
    message: Message,
    raw: ModelUpdate,
  )
  MessageUpdate(from_id: Int, chat_id: Int, message: Message, raw: ModelUpdate)
  ChannelPostUpdate(from_id: Int, chat_id: Int, post: Message, raw: ModelUpdate)
  EditedMessageUpdate(
    from_id: Int,
    chat_id: Int,
    message: Message,
    raw: ModelUpdate,
  )
  EditedChannelPostUpdate(
    from_id: Int,
    chat_id: Int,
    post: Message,
    raw: ModelUpdate,
  )
  BusinessConnectionUpdate(
    from_id: Int,
    chat_id: Int,
    business_connection: BusinessConnection,
    raw: ModelUpdate,
  )
  BusinessMessageUpdate(
    from_id: Int,
    chat_id: Int,
    message: Message,
    raw: ModelUpdate,
  )
  EditedBusinessMessageUpdate(
    from_id: Int,
    chat_id: Int,
    message: Message,
    raw: ModelUpdate,
  )
  DeletedBusinessMessageUpdate(
    from_id: Int,
    chat_id: Int,
    business_messages_deleted: BusinessMessagesDeleted,
    raw: ModelUpdate,
  )
  MessageReactionUpdate(
    from_id: Int,
    chat_id: Int,
    message_reaction_updated: MessageReactionUpdated,
    raw: ModelUpdate,
  )
  MessageReactionCountUpdate(
    from_id: Int,
    chat_id: Int,
    message_reaction_count_updated: MessageReactionCountUpdated,
    raw: ModelUpdate,
  )
  InlineQueryUpdate(
    from_id: Int,
    chat_id: Int,
    inline_query: InlineQuery,
    raw: ModelUpdate,
  )
  ChosenInlineResultUpdate(
    from_id: Int,
    chat_id: Int,
    chosen_inline_result: ChosenInlineResult,
    raw: ModelUpdate,
  )
  CallbackQueryUpdate(
    from_id: Int,
    chat_id: Int,
    query: CallbackQuery,
    raw: ModelUpdate,
  )
  ShippingQueryUpdate(
    from_id: Int,
    chat_id: Int,
    shipping_query: ShippingQuery,
    raw: ModelUpdate,
  )
  PreCheckoutQueryUpdate(
    from_id: Int,
    chat_id: Int,
    pre_checkout_query: PreCheckoutQuery,
    raw: ModelUpdate,
  )
  PaidMediaPurchaseUpdate(
    from_id: Int,
    chat_id: Int,
    paid_media_purchased: PaidMediaPurchased,
    raw: ModelUpdate,
  )
  PollUpdate(from_id: Int, chat_id: Int, poll: Poll, raw: ModelUpdate)
  PollAnswerUpdate(
    from_id: Int,
    chat_id: Int,
    poll_answer: PollAnswer,
    raw: ModelUpdate,
  )
  MyChatMemberUpdate(
    from_id: Int,
    chat_id: Int,
    chat_member_updated: ChatMemberUpdated,
    raw: ModelUpdate,
  )
  ChatMemberUpdate(
    from_id: Int,
    chat_id: Int,
    chat_member_updated: ChatMemberUpdated,
    raw: ModelUpdate,
  )
  ChatJoinRequestUpdate(
    from_id: Int,
    chat_id: Int,
    chat_join_request: ChatJoinRequest,
    raw: ModelUpdate,
  )
  RemovedChatBoost(
    from_id: Int,
    chat_id: Int,
    removed_chat_boost: ChatBoostRemoved,
    raw: ModelUpdate,
  )
  ManagedBotUpdate(
    from_id: Int,
    chat_id: Int,
    managed_bot: ManagedBotUpdated,
    raw: ModelUpdate,
  )
  /// New guest message from Bot API 10.0. The bot can use `message.guest_query_id`
  /// and `api.answer_guest_query` to send a message in response.
  GuestMessageUpdate(
    from_id: Int,
    chat_id: Int,
    message: Message,
    raw: ModelUpdate,
  )
}

pub type Command {
  /// Represents a command message.
  Command(
    /// Whole command message
    text: String,
    /// Command name without the leading slash
    command: String,
    /// The command arguments, if any.
    payload: Option(String),
  )
}

pub fn decode_raw(json: Dynamic) -> Result(ModelUpdate, error.TelegaError) {
  decode.run(json, update_decoder())
  |> result.map_error(fn(e) {
    error.DecodeUpdateError(
      "Cannot decode update: "
      <> string.inspect(json)
      <> " "
      <> string.inspect(e),
    )
  })
}

/// Decode a update from the Telegram API to `Update` instance.
pub fn raw_to_update(raw_update: ModelUpdate) -> Update {
  case raw_update {
    _ if raw_update.callback_query != None -> {
      let assert Some(callback_query) = raw_update.callback_query
      new_callback_query_update(raw_update, callback_query)
    }
    _ if raw_update.channel_post != None -> {
      let assert Some(channel_post) = raw_update.channel_post
      new_channel_post_update(raw_update, channel_post)
    }
    _ if raw_update.edited_message != None -> {
      let assert Some(edited_message) = raw_update.edited_message
      new_edited_message_update(raw_update, edited_message)
    }
    _ if raw_update.business_connection != None -> {
      let assert Some(business_connection) = raw_update.business_connection
      new_business_connection_update(raw_update, business_connection)
    }
    _ if raw_update.business_message != None -> {
      let assert Some(business_message) = raw_update.business_message
      new_business_message_update(raw_update, business_message)
    }
    _ if raw_update.edited_business_message != None -> {
      let assert Some(edited_business_message) =
        raw_update.edited_business_message
      new_edited_business_message_update(raw_update, edited_business_message)
    }
    _ if raw_update.deleted_business_messages != None -> {
      let assert Some(deleted_business_messages) =
        raw_update.deleted_business_messages
      new_deleted_business_message_update(raw_update, deleted_business_messages)
    }
    _ if raw_update.message_reaction != None -> {
      let assert Some(message_reaction) = raw_update.message_reaction
      new_message_reaction_update(raw_update, message_reaction)
    }
    _ if raw_update.message_reaction_count != None -> {
      let assert Some(message_reaction_count) =
        raw_update.message_reaction_count
      new_message_reaction_count_update(raw_update, message_reaction_count)
    }
    _ if raw_update.inline_query != None -> {
      let assert Some(inline_query) = raw_update.inline_query
      new_inline_query_update(raw_update, inline_query)
    }
    _ if raw_update.chosen_inline_result != None -> {
      let assert Some(chosen_inline_result) = raw_update.chosen_inline_result
      new_chosen_inline_result_update(raw_update, chosen_inline_result)
    }
    _ if raw_update.shipping_query != None -> {
      let assert Some(shipping_query) = raw_update.shipping_query
      new_shipping_query_update(raw_update, shipping_query)
    }
    _ if raw_update.pre_checkout_query != None -> {
      let assert Some(pre_checkout_query) = raw_update.pre_checkout_query
      new_pre_checkout_query_update(raw_update, pre_checkout_query)
    }
    _ if raw_update.purchased_paid_media != None -> {
      let assert Some(purchased_paid_media) = raw_update.purchased_paid_media
      new_paid_media_purchase_update(raw_update, purchased_paid_media)
    }
    _ if raw_update.poll != None -> {
      let assert Some(poll) = raw_update.poll
      new_poll_update(raw_update, poll)
    }
    _ if raw_update.poll_answer != None -> {
      let assert Some(poll_answer) = raw_update.poll_answer
      new_poll_answer_update(raw_update, poll_answer)
    }
    _ if raw_update.my_chat_member != None -> {
      let assert Some(my_chat_member) = raw_update.my_chat_member
      new_my_chat_member_update(raw_update, my_chat_member)
    }
    _ if raw_update.chat_member != None -> {
      let assert Some(chat_member) = raw_update.chat_member
      new_chat_member_update(raw_update, chat_member)
    }
    _ if raw_update.chat_join_request != None -> {
      let assert Some(chat_join_request) = raw_update.chat_join_request
      new_chat_join_request_update(raw_update, chat_join_request)
    }
    _ if raw_update.removed_chat_boost != None -> {
      let assert Some(removed_chat_boost) = raw_update.removed_chat_boost
      new_removed_chat_boost_update(raw_update, removed_chat_boost)
    }
    _ if raw_update.managed_bot != None -> {
      let assert Some(managed_bot) = raw_update.managed_bot
      new_managed_bot_update(raw_update, managed_bot)
    }
    _ if raw_update.guest_message != None -> {
      let assert Some(guest_message) = raw_update.guest_message
      new_guest_message_update(raw_update, guest_message)
    }
    _ if raw_update.message != None -> {
      let assert Some(message) = raw_update.message
      decode_message_update(raw_update, message)
    }
    _ -> panic as { "Unknown update: " <> string.inspect(raw_update) }
  }
}

fn decode_message_update(raw_update: ModelUpdate, message: Message) -> Update {
  case
    message.photo,
    message.video,
    message.audio,
    message.voice,
    message.web_app_data,
    message.text
  {
    Some(photos), _, _, _, _, _ -> new_photo_update(raw_update, message, photos)
    _, Some(video), _, _, _, _ -> new_video_update(raw_update, message, video)
    _, _, Some(audio), _, _, _ -> new_audio_update(raw_update, message, audio)
    _, _, _, Some(voice), _, _ -> new_voice_update(raw_update, message, voice)
    _, _, _, _, Some(web_app_data), _ ->
      new_web_app_data_update(raw_update, message, web_app_data)
    _, _, _, _, _, Some(text) -> decode_text_message(raw_update, message, text)
    _, _, _, _, _, None -> new_message_update(raw_update, message)
  }
}

fn decode_text_message(
  raw_update: ModelUpdate,
  message: Message,
  text: String,
) -> Update {
  case is_command_update(text, raw_update) {
    True -> new_command_update(raw_update, message, text)
    False -> new_text_update(raw_update, message, text)
  }
}

pub fn to_string(update: Update) -> String {
  case update {
    CommandUpdate(command:, from_id:, ..) ->
      "command \"" <> command.command <> "\" from " <> int.to_string(from_id)
    TextUpdate(text:, from_id:, ..) ->
      "text \"" <> text <> "\" from " <> int.to_string(from_id)
    MessageUpdate(message:, from_id:, ..) ->
      "message "
      <> int.to_string(message.message_id)
      <> " from "
      <> int.to_string(from_id)
    PhotoUpdate(from_id:, ..) -> "photo from " <> int.to_string(from_id)
    VideoUpdate(video:, from_id:, ..) ->
      "video " <> video.file_id <> " from " <> int.to_string(from_id)
    AudioUpdate(audio:, from_id:, ..) ->
      "audio " <> audio.file_id <> " from " <> int.to_string(from_id)
    VoiceUpdate(voice:, from_id:, ..) ->
      "voice " <> voice.file_id <> " from " <> int.to_string(from_id)
    MediaGroupUpdate(media_group_id:, from_id:, messages:, ..) ->
      "media group "
      <> media_group_id
      <> " with "
      <> int.to_string(list.length(messages))
      <> " items from "
      <> int.to_string(from_id)
    WebAppUpdate(web_app_data:, from_id:, ..) ->
      "web app " <> web_app_data.data <> " from " <> int.to_string(from_id)
    CallbackQueryUpdate(query:, from_id:, ..) ->
      "callback query "
      <> option.unwrap(query.data, "no data")
      <> " from "
      <> int.to_string(from_id)
    ChannelPostUpdate(post:, from_id:, ..) ->
      "channel post "
      <> int.to_string(post.message_id)
      <> " from "
      <> int.to_string(from_id)
    EditedMessageUpdate(message:, from_id:, ..) ->
      "edited message "
      <> int.to_string(message.message_id)
      <> " from "
      <> int.to_string(from_id)
    EditedChannelPostUpdate(post:, from_id:, ..) ->
      "edited channel post "
      <> int.to_string(post.message_id)
      <> " from "
      <> int.to_string(from_id)
    BusinessConnectionUpdate(business_connection:, from_id:, ..) ->
      "business connection "
      <> business_connection.id
      <> " from "
      <> int.to_string(from_id)
    BusinessMessageUpdate(message:, from_id:, ..) ->
      "business message "
      <> int.to_string(message.message_id)
      <> " from "
      <> int.to_string(from_id)
    ChatJoinRequestUpdate(chat_join_request:, from_id:, ..) ->
      "chat join request "
      <> int.to_string(chat_join_request.chat.id)
      <> " from "
      <> int.to_string(from_id)
    ChatMemberUpdate(chat_member_updated:, from_id:, ..) ->
      "chat member update "
      <> int.to_string(chat_member_updated.chat.id)
      <> " from "
      <> int.to_string(from_id)
    ChosenInlineResultUpdate(chosen_inline_result:, from_id:, ..) ->
      "chosen inline result "
      <> chosen_inline_result.result_id
      <> " from "
      <> int.to_string(from_id)
    DeletedBusinessMessageUpdate(business_messages_deleted:, from_id:, ..) ->
      "deleted business message "
      <> int.to_string(business_messages_deleted.chat.id)
      <> " from "
      <> int.to_string(from_id)
    EditedBusinessMessageUpdate(message:, from_id:, ..) ->
      "edited business message "
      <> int.to_string(message.message_id)
      <> " from "
      <> int.to_string(from_id)
    InlineQueryUpdate(inline_query:, from_id:, ..) ->
      "inline query " <> inline_query.id <> " from " <> int.to_string(from_id)
    MessageReactionCountUpdate(message_reaction_count_updated:, from_id:, ..) ->
      "message reaction count update "
      <> int.to_string(message_reaction_count_updated.chat.id)
      <> " from "
      <> int.to_string(from_id)
    MessageReactionUpdate(message_reaction_updated:, from_id:, ..) ->
      "message reaction update "
      <> int.to_string(message_reaction_updated.chat.id)
      <> " from "
      <> int.to_string(from_id)
    MyChatMemberUpdate(chat_member_updated:, from_id:, ..) ->
      "my chat member update "
      <> int.to_string(chat_member_updated.chat.id)
      <> " from "
      <> int.to_string(from_id)
    PaidMediaPurchaseUpdate(from_id:, ..) ->
      "paid media purchase from " <> int.to_string(from_id)
    PollAnswerUpdate(poll_answer:, from_id:, ..) ->
      "poll answer "
      <> poll_answer.poll_id
      <> " from "
      <> int.to_string(from_id)
    PollUpdate(poll:, from_id:, ..) ->
      "poll " <> poll.id <> " from " <> int.to_string(from_id)
    PreCheckoutQueryUpdate(pre_checkout_query:, from_id:, ..) ->
      "pre checkout query "
      <> pre_checkout_query.id
      <> " from "
      <> int.to_string(from_id)
    RemovedChatBoost(removed_chat_boost:, from_id:, ..) ->
      "removed chat boost "
      <> int.to_string(removed_chat_boost.chat.id)
      <> " from "
      <> int.to_string(from_id)
    ShippingQueryUpdate(shipping_query:, from_id:, ..) ->
      "shipping query "
      <> shipping_query.id
      <> " from "
      <> int.to_string(from_id)
    ManagedBotUpdate(managed_bot:, from_id:, ..) ->
      "managed bot "
      <> int.to_string(managed_bot.bot.id)
      <> " from "
      <> int.to_string(from_id)
    GuestMessageUpdate(message:, from_id:, ..) ->
      "guest message "
      <> int.to_string(message.message_id)
      <> " from "
      <> int.to_string(from_id)
  }
}

/// Returns a short snake_case tag for the update variant,
/// e.g. `"text"`, `"command"`, `"callback_query"`.
/// Used as the `update_type` metadata in telemetry events.
pub fn type_to_string(update: Update) -> String {
  case update {
    TextUpdate(..) -> "text"
    CommandUpdate(..) -> "command"
    PhotoUpdate(..) -> "photo"
    VideoUpdate(..) -> "video"
    AudioUpdate(..) -> "audio"
    VoiceUpdate(..) -> "voice"
    MediaGroupUpdate(..) -> "media_group"
    WebAppUpdate(..) -> "web_app"
    MessageUpdate(..) -> "message"
    ChannelPostUpdate(..) -> "channel_post"
    EditedMessageUpdate(..) -> "edited_message"
    EditedChannelPostUpdate(..) -> "edited_channel_post"
    BusinessConnectionUpdate(..) -> "business_connection"
    BusinessMessageUpdate(..) -> "business_message"
    EditedBusinessMessageUpdate(..) -> "edited_business_message"
    DeletedBusinessMessageUpdate(..) -> "deleted_business_message"
    MessageReactionUpdate(..) -> "message_reaction"
    MessageReactionCountUpdate(..) -> "message_reaction_count"
    InlineQueryUpdate(..) -> "inline_query"
    ChosenInlineResultUpdate(..) -> "chosen_inline_result"
    CallbackQueryUpdate(..) -> "callback_query"
    ShippingQueryUpdate(..) -> "shipping_query"
    PreCheckoutQueryUpdate(..) -> "pre_checkout_query"
    PaidMediaPurchaseUpdate(..) -> "paid_media_purchase"
    PollUpdate(..) -> "poll"
    PollAnswerUpdate(..) -> "poll_answer"
    MyChatMemberUpdate(..) -> "my_chat_member"
    ChatMemberUpdate(..) -> "chat_member"
    ChatJoinRequestUpdate(..) -> "chat_join_request"
    RemovedChatBoost(..) -> "removed_chat_boost"
    ManagedBotUpdate(..) -> "managed_bot"
    GuestMessageUpdate(..) -> "guest_message"
  }
}

// When we receive update with `callback_query` field
fn new_callback_query_update(raw: ModelUpdate, callback_query: CallbackQuery) {
  CallbackQueryUpdate(
    raw:,
    from_id: callback_query.from.id,
    chat_id: case callback_query.message {
      Some(message) ->
        case message {
          MessageMaybeInaccessibleMessage(message) -> message.chat.id
          InaccessibleMessageMaybeInaccessibleMessage(inaccessible) ->
            inaccessible.chat.id
        }
      None -> callback_query.from.id
    },
    query: callback_query,
  )
}

fn new_text_update(raw: ModelUpdate, message: Message, text: String) {
  TextUpdate(
    raw:,
    text:,
    message:,
    from_id: get_sender_id(message),
    chat_id: message.chat.id,
  )
}

fn new_command_update(raw: ModelUpdate, message: Message, text: String) {
  CommandUpdate(
    raw:,
    message:,
    from_id: get_sender_id(message),
    chat_id: message.chat.id,
    command: extract_command(text),
  )
}

fn new_photo_update(
  raw: ModelUpdate,
  message: Message,
  photos: List(PhotoSize),
) {
  PhotoUpdate(
    raw:,
    photos:,
    message:,
    from_id: get_sender_id(message),
    chat_id: message.chat.id,
  )
}

fn new_video_update(raw: ModelUpdate, message: Message, video: Video) {
  VideoUpdate(
    raw:,
    video:,
    message:,
    from_id: get_sender_id(message),
    chat_id: message.chat.id,
  )
}

fn new_audio_update(raw: ModelUpdate, message: Message, audio: Audio) {
  AudioUpdate(
    raw:,
    audio:,
    message:,
    from_id: get_sender_id(message),
    chat_id: message.chat.id,
  )
}

fn new_voice_update(raw: ModelUpdate, message: Message, voice: Voice) {
  VoiceUpdate(
    raw:,
    voice:,
    message:,
    from_id: get_sender_id(message),
    chat_id: message.chat.id,
  )
}

fn new_web_app_data_update(
  raw: ModelUpdate,
  message: Message,
  web_app_data: WebAppData,
) {
  WebAppUpdate(
    raw:,
    web_app_data:,
    message:,
    from_id: get_sender_id(message),
    chat_id: message.chat.id,
  )
}

fn new_channel_post_update(raw: ModelUpdate, channel_post: Message) {
  ChannelPostUpdate(
    raw:,
    post: channel_post,
    from_id: get_sender_id(channel_post),
    chat_id: channel_post.chat.id,
  )
}

fn new_message_update(raw: ModelUpdate, message: Message) {
  MessageUpdate(
    raw:,
    message:,
    from_id: get_sender_id(message),
    chat_id: message.chat.id,
  )
}

fn new_edited_message_update(raw: ModelUpdate, edited_message: Message) {
  EditedMessageUpdate(
    raw:,
    message: edited_message,
    from_id: get_sender_id(edited_message),
    chat_id: edited_message.chat.id,
  )
}

fn new_business_connection_update(
  raw: ModelUpdate,
  business_connection: BusinessConnection,
) {
  BusinessConnectionUpdate(
    raw:,
    business_connection:,
    from_id: business_connection.user.id,
    chat_id: business_connection.user_chat_id,
  )
}

fn new_business_message_update(raw: ModelUpdate, business_message: Message) {
  BusinessMessageUpdate(
    raw:,
    message: business_message,
    from_id: case business_message.from {
      Some(user) -> user.id
      None -> business_message.chat.id
    },
    chat_id: business_message.chat.id,
  )
}

fn get_sender_id(message: Message) {
  case message.from, message.sender_chat {
    _, Some(sender_chat) -> sender_chat.id
    Some(user), _ -> user.id
    _, _ -> message.chat.id
  }
}

fn is_command_entity(entity: MessageEntity) {
  entity.type_ == "bot_command" && entity.offset == 0
}

fn is_command_update(text: String, raw_update: ModelUpdate) -> Bool {
  use <- bool.guard(!string.starts_with(text, "/"), False)

  case raw_update.message {
    Some(message) ->
      case message.entities {
        Some(entities) -> list.any(entities, is_command_entity)
        None -> False
      }
    None -> False
  }
}

fn extract_command(text: String) -> Command {
  case string.split(text, " ") {
    [command, ..payload] ->
      Command(
        text:,
        command: string.drop_start(command, 1),
        payload: payload
          |> string.join(" ")
          |> Some,
      )
    [] -> Command(text:, command: "", payload: None)
  }
}

fn new_edited_business_message_update(
  raw: ModelUpdate,
  edited_business_message: Message,
) {
  EditedBusinessMessageUpdate(
    raw:,
    message: edited_business_message,
    from_id: case edited_business_message.from {
      Some(user) -> user.id
      None -> edited_business_message.chat.id
    },
    chat_id: edited_business_message.chat.id,
  )
}

fn new_deleted_business_message_update(
  raw: ModelUpdate,
  deleted_business_messages: BusinessMessagesDeleted,
) {
  DeletedBusinessMessageUpdate(
    raw:,
    business_messages_deleted: deleted_business_messages,
    from_id: deleted_business_messages.chat.id,
    chat_id: deleted_business_messages.chat.id,
  )
}

fn new_message_reaction_update(
  raw: ModelUpdate,
  message_reaction: MessageReactionUpdated,
) {
  MessageReactionUpdate(
    raw:,
    message_reaction_updated: message_reaction,
    from_id: case message_reaction.user, message_reaction.actor_chat {
      _, Some(actor_chat) -> actor_chat.id
      Some(user), _ -> user.id
      _, _ -> message_reaction.chat.id
    },
    chat_id: message_reaction.chat.id,
  )
}

fn new_message_reaction_count_update(
  raw: ModelUpdate,
  message_reaction_count: MessageReactionCountUpdated,
) {
  MessageReactionCountUpdate(
    raw:,
    message_reaction_count_updated: message_reaction_count,
    from_id: message_reaction_count.chat.id,
    chat_id: message_reaction_count.chat.id,
  )
}

fn new_inline_query_update(raw: ModelUpdate, inline_query: InlineQuery) {
  InlineQueryUpdate(
    raw:,
    inline_query:,
    from_id: inline_query.from.id,
    chat_id: inline_query.from.id,
  )
}

fn new_chosen_inline_result_update(
  raw: ModelUpdate,
  chosen_inline_result: ChosenInlineResult,
) {
  ChosenInlineResultUpdate(
    raw:,
    chosen_inline_result:,
    from_id: chosen_inline_result.from.id,
    chat_id: chosen_inline_result.from.id,
  )
}

fn new_shipping_query_update(raw: ModelUpdate, shipping_query: ShippingQuery) {
  ShippingQueryUpdate(
    raw:,
    shipping_query:,
    from_id: shipping_query.from.id,
    chat_id: shipping_query.from.id,
  )
}

fn new_pre_checkout_query_update(
  raw: ModelUpdate,
  pre_checkout_query: PreCheckoutQuery,
) {
  PreCheckoutQueryUpdate(
    raw:,
    pre_checkout_query:,
    from_id: pre_checkout_query.from.id,
    chat_id: pre_checkout_query.from.id,
  )
}

fn new_paid_media_purchase_update(
  raw: ModelUpdate,
  paid_media_purchased: PaidMediaPurchased,
) {
  PaidMediaPurchaseUpdate(
    raw:,
    paid_media_purchased:,
    from_id: paid_media_purchased.from.id,
    chat_id: paid_media_purchased.from.id,
  )
}

fn new_poll_update(raw: ModelUpdate, poll: Poll) {
  // Poll objects don't contain chat_id or from_id information.
  // Poll updates are sent only for polls created by the bot itself.
  // We use -1 to indicate a system update without specific user/chat context.
  PollUpdate(raw:, poll:, from_id: -1, chat_id: -1)
}

fn new_poll_answer_update(raw: ModelUpdate, poll_answer: PollAnswer) {
  // According to Telegram Bot API, either 'user' or 'voter_chat' is always present.
  // The fallback to 0 should theoretically never happen, but we keep it for safety.
  let from_id = case poll_answer.user {
    Some(user) -> user.id
    None -> {
      log.warning(
        "PollAnswer received with neither user nor voter_chat. Poll ID: "
        <> poll_answer.poll_id,
      )
      0
    }
  }

  let chat_id = case poll_answer.voter_chat {
    Some(chat) -> chat.id
    None ->
      case poll_answer.user {
        Some(user) -> user.id
        None -> {
          log.warning(
            "PollAnswer received with neither user nor voter_chat. Poll ID: "
            <> poll_answer.poll_id,
          )
          0
        }
      }
  }

  PollAnswerUpdate(raw:, poll_answer:, from_id:, chat_id:)
}

fn new_my_chat_member_update(
  raw: ModelUpdate,
  my_chat_member: ChatMemberUpdated,
) {
  MyChatMemberUpdate(
    raw:,
    chat_member_updated: my_chat_member,
    from_id: my_chat_member.from.id,
    chat_id: my_chat_member.chat.id,
  )
}

fn new_chat_member_update(raw: ModelUpdate, chat_member: ChatMemberUpdated) {
  ChatMemberUpdate(
    raw:,
    chat_member_updated: chat_member,
    from_id: chat_member.from.id,
    chat_id: chat_member.chat.id,
  )
}

fn new_chat_join_request_update(
  raw: ModelUpdate,
  chat_join_request: ChatJoinRequest,
) {
  ChatJoinRequestUpdate(
    raw:,
    chat_join_request:,
    from_id: chat_join_request.from.id,
    chat_id: chat_join_request.chat.id,
  )
}

fn new_removed_chat_boost_update(
  raw: ModelUpdate,
  removed_chat_boost: ChatBoostRemoved,
) {
  RemovedChatBoost(
    raw:,
    removed_chat_boost:,
    from_id: removed_chat_boost.chat.id,
    chat_id: removed_chat_boost.chat.id,
  )
}

fn new_managed_bot_update(raw: ModelUpdate, managed_bot: ManagedBotUpdated) {
  ManagedBotUpdate(
    raw:,
    managed_bot:,
    from_id: managed_bot.user.id,
    chat_id: managed_bot.user.id,
  )
}

fn new_guest_message_update(raw: ModelUpdate, guest_message: Message) {
  GuestMessageUpdate(
    raw:,
    message: guest_message,
    from_id: get_sender_id(guest_message),
    chat_id: guest_message.chat.id,
  )
}
