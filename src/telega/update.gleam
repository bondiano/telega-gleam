import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import telega/error
import telega/model/decoder.{update_decoder}
import telega/model/types.{
  type Audio, type BusinessConnection, type BusinessMessagesDeleted,
  type CallbackQuery, type ChatBoostRemoved, type ChatJoinRequest,
  type ChatMemberUpdated, type ChosenInlineResult, type InlineQuery,
  type Message, type MessageEntity, type MessageReactionCountUpdated,
  type MessageReactionUpdated, type PaidMediaPurchased, type PhotoSize,
  type Poll, type PollAnswer, type PreCheckoutQuery, type ShippingQuery,
  type Update as ModelUpdate, type Video, type Voice, type WebAppData,
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
  case
    raw_update.callback_query,
    raw_update.channel_post,
    raw_update.edited_message,
    raw_update.business_connection,
    raw_update.business_message,
    raw_update.edited_business_message,
    raw_update.deleted_business_messages,
    raw_update.message_reaction,
    raw_update.message_reaction_count,
    raw_update.inline_query,
    raw_update.chosen_inline_result,
    raw_update.shipping_query,
    raw_update.pre_checkout_query,
    raw_update.purchased_paid_media,
    raw_update.poll,
    raw_update.poll_answer,
    raw_update.my_chat_member,
    raw_update.chat_member,
    raw_update.chat_join_request,
    raw_update.removed_chat_boost,
    raw_update.message
  {
    Some(callback_query),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_callback_query_update(raw_update, callback_query)
    _,
      Some(channel_post),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_channel_post_update(raw_update, channel_post)
    _,
      _,
      Some(edited_message),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_edited_message_update(raw_update, edited_message)
    _,
      _,
      _,
      Some(business_connection),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_business_connection_update(raw_update, business_connection)
    _,
      _,
      _,
      _,
      Some(business_message),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_business_message_update(raw_update, business_message)
    _,
      _,
      _,
      _,
      _,
      Some(edited_business_message),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_edited_business_message_update(raw_update, edited_business_message)
    _,
      _,
      _,
      _,
      _,
      _,
      Some(deleted_business_messages),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    ->
      new_deleted_business_message_update(raw_update, deleted_business_messages)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(message_reaction),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_message_reaction_update(raw_update, message_reaction)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(message_reaction_count),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_message_reaction_count_update(raw_update, message_reaction_count)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(inline_query),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_inline_query_update(raw_update, inline_query)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(chosen_inline_result),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_chosen_inline_result_update(raw_update, chosen_inline_result)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(shipping_query),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_shipping_query_update(raw_update, shipping_query)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(pre_checkout_query),
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_pre_checkout_query_update(raw_update, pre_checkout_query)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(purchased_paid_media),
      _,
      _,
      _,
      _,
      _,
      _,
      _
    -> new_paid_media_purchase_update(raw_update, purchased_paid_media)
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, Some(poll), _, _, _, _, _, _ ->
      new_poll_update(raw_update, poll)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(poll_answer),
      _,
      _,
      _,
      _,
      _
    -> new_poll_answer_update(raw_update, poll_answer)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(my_chat_member),
      _,
      _,
      _,
      _
    -> new_my_chat_member_update(raw_update, my_chat_member)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(chat_member),
      _,
      _,
      _
    -> new_chat_member_update(raw_update, chat_member)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(chat_join_request),
      _,
      _
    -> new_chat_join_request_update(raw_update, chat_join_request)
    _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      _,
      Some(removed_chat_boost),
      _
    -> new_removed_chat_boost_update(raw_update, removed_chat_boost)
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, Some(message) ->
      decode_message_update(raw_update, message)
    _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, None ->
      panic as { "Unknown update: " <> string.inspect(raw_update) }
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
    from_id: case message.from {
      Some(user) -> user.id
      None -> message.chat.id
    },
    chat_id: message.chat.id,
  )
}

fn new_command_update(raw: ModelUpdate, message: Message, text: String) {
  CommandUpdate(
    raw:,
    message:,
    from_id: case message.from {
      Some(user) -> user.id
      None -> message.chat.id
    },
    chat_id: message.chat.id,
    command: extract_command(text),
  )
}

fn new_photo_update(raw: ModelUpdate, message: Message, photos: List(PhotoSize)) {
  PhotoUpdate(
    raw:,
    photos:,
    message:,
    from_id: case message.from {
      Some(user) -> user.id
      None -> message.chat.id
    },
    chat_id: message.chat.id,
  )
}

fn new_video_update(raw: ModelUpdate, message: Message, video: Video) {
  VideoUpdate(
    raw:,
    video:,
    message:,
    from_id: case message.from {
      Some(user) -> user.id
      None -> message.chat.id
    },
    chat_id: message.chat.id,
  )
}

fn new_audio_update(raw: ModelUpdate, message: Message, audio: Audio) {
  AudioUpdate(
    raw:,
    audio:,
    message:,
    from_id: case message.from {
      Some(user) -> user.id
      None -> message.chat.id
    },
    chat_id: message.chat.id,
  )
}

fn new_voice_update(raw: ModelUpdate, message: Message, voice: Voice) {
  VoiceUpdate(
    raw:,
    voice:,
    message:,
    from_id: case message.from {
      Some(user) -> user.id
      None -> message.chat.id
    },
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
    from_id: case message.from {
      Some(user) -> user.id
      None -> message.chat.id
    },
    chat_id: message.chat.id,
  )
}

fn new_channel_post_update(raw: ModelUpdate, channel_post: Message) {
  ChannelPostUpdate(
    raw:,
    post: channel_post,
    from_id: case channel_post.from {
      Some(user) -> user.id
      None -> channel_post.chat.id
    },
    chat_id: channel_post.chat.id,
  )
}

fn new_message_update(raw: ModelUpdate, message: Message) {
  MessageUpdate(
    raw:,
    message:,
    from_id: case message.from {
      Some(user) -> user.id
      None -> message.chat.id
    },
    chat_id: message.chat.id,
  )
}

fn new_edited_message_update(raw: ModelUpdate, edited_message: Message) {
  EditedMessageUpdate(
    raw:,
    message: edited_message,
    from_id: case edited_message.from {
      Some(user) -> user.id
      None -> edited_message.chat.id
    },
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
    from_id: case message_reaction.user {
      Some(user) -> user.id
      None -> message_reaction.chat.id
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
  PollUpdate(
    raw:,
    poll:,
    // TODO: Polls don't have a direct from_id, we should use the user id from the poll_answer
    from_id: 0,
    // TODO: Polls don't have a direct chat_id, we should use the chat id from the poll_answer
    chat_id: 0,
  )
}

fn new_poll_answer_update(raw: ModelUpdate, poll_answer: PollAnswer) {
  PollAnswerUpdate(
    raw:,
    poll_answer:,
    from_id: case poll_answer.user {
      Some(user) -> user.id
      // TODO: check this case
      None -> 0
    },
    chat_id: case poll_answer.voter_chat {
      Some(chat) -> chat.id
      // TODO: check this case
      None -> 0
    },
  )
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
