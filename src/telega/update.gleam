import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import telega/error
import telega/model.{
  type Audio, type BusinessConnection, type BusinessMessagesDeleted,
  type CallbackQuery, type ChatBoostRemoved, type ChatJoinRequest,
  type ChatMemberUpdated, type ChosenInlineResult, type InlineQuery,
  type Message, type MessageEntity, type MessageReactionCountUpdated,
  type MessageReactionUpdated, type PaidMediaPurchased, type PhotoSize,
  type Poll, type PollAnswer, type PreCheckoutQuery, type ShippingQuery,
  type Update as ModelUpdate, type Video, type Voice,
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

pub fn decode_raw(json: Dynamic) {
  decode.run(json, model.update_decoder())
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
pub fn raw_to_update(raw_update: ModelUpdate) {
  use <- try_decode_callback_query(raw_update)
  use <- try_decode_channel_post(raw_update)
  use <- try_decode_edited_message(raw_update)
  use <- try_decode_business_connection(raw_update)
  use <- try_decode_business_message(raw_update)
  use <- try_decode_edited_business_message(raw_update)
  use <- try_decode_deleted_business_message(raw_update)
  use <- try_decode_message_reaction(raw_update)
  use <- try_decode_message_reaction_count(raw_update)
  use <- try_decode_inline_query(raw_update)
  use <- try_decode_chosen_inline_result(raw_update)
  use <- try_decode_shipping_query(raw_update)
  use <- try_decode_pre_checkout_query(raw_update)
  use <- try_decode_paid_media_purchase(raw_update)
  use <- try_decode_poll(raw_update)
  use <- try_decode_poll_answer(raw_update)
  use <- try_decode_my_chat_member(raw_update)
  use <- try_decode_chat_member(raw_update)
  use <- try_decode_chat_join_request(raw_update)
  use <- try_decode_removed_chat_boost(raw_update)

  use <- try_decode_photo_message(raw_update)
  use <- try_decode_video_message(raw_update)
  use <- try_decode_audio_message(raw_update)
  use <- try_decode_voice_message(raw_update)

  // Message is the most common update type, so we decode it last
  use <- try_decode_message(raw_update)

  panic as { "Unknown update: " <> string.inspect(raw_update) }
}

pub fn to_string(update: Update) {
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

fn try_decode_channel_post(raw: ModelUpdate, on_none) {
  case raw.channel_post {
    Some(channel_post) -> new_channel_post_update(raw, channel_post)
    None -> on_none()
  }
}

fn try_decode_callback_query(raw: ModelUpdate, on_none) {
  case raw.callback_query {
    Some(callback_query) -> new_callback_query_update(raw, callback_query)
    None -> on_none()
  }
}

// When we receive update with message field
fn try_decode_message(raw: ModelUpdate, on_none) {
  case raw.message {
    Some(message) ->
      case message.text {
        Some(text) -> try_decode_text_message(raw, message, text)
        None -> new_message_update(raw, message)
      }
    None -> on_none()
  }
}

fn try_decode_text_message(raw, message, text) {
  case is_command_update(text, raw) {
    True -> new_command_update(raw, message, text)
    False -> new_text_update(raw, message, text)
  }
}

fn try_decode_photo_message(raw: ModelUpdate, on_none) {
  case raw.message {
    Some(message) ->
      case message.photo {
        Some(photos) -> new_photo_update(raw, message, photos)
        None -> on_none()
      }
    None -> on_none()
  }
}

fn try_decode_video_message(raw: ModelUpdate, on_none) {
  case raw.message {
    Some(message) ->
      case message.video {
        Some(video) -> new_video_update(raw, message, video)
        None -> on_none()
      }
    None -> on_none()
  }
}

fn try_decode_audio_message(raw: ModelUpdate, on_none) {
  case raw.message {
    Some(message) ->
      case message.audio {
        Some(audio) -> new_audio_update(raw, message, audio)
        None -> on_none()
      }
    None -> on_none()
  }
}

fn try_decode_voice_message(raw: ModelUpdate, on_none) {
  case raw.message {
    Some(message) ->
      case message.voice {
        Some(voice) -> new_voice_update(raw, message, voice)
        None -> on_none()
      }
    None -> on_none()
  }
}

fn try_decode_edited_message(raw: ModelUpdate, on_none) {
  case raw.edited_message {
    Some(edited_message) -> new_edited_message_update(raw, edited_message)
    None -> on_none()
  }
}

fn try_decode_business_connection(raw: ModelUpdate, on_none) {
  case raw.business_connection {
    Some(business_connection) ->
      new_business_connection_update(raw, business_connection)
    None -> on_none()
  }
}

fn try_decode_business_message(raw: ModelUpdate, on_none) {
  case raw.business_message {
    Some(business_message) -> new_business_message_update(raw, business_message)
    None -> on_none()
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
          model.MessageMaybeInaccessibleMessage(message) -> message.chat.id
          model.InaccessibleMessageMaybeInaccessibleMessage(message) ->
            message.chat.id
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

fn is_command_entity(text, entity: MessageEntity) {
  entity.type_ == "bot_command"
  && entity.offset == 0
  && entity.length == string.length(text)
}

fn is_command_update(text: String, raw_update: ModelUpdate) -> Bool {
  use <- bool.guard(!string.starts_with(text, "/"), False)

  case raw_update.message {
    Some(message) ->
      case message.entities {
        Some(entities) -> list.any(entities, is_command_entity(text, _))
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

fn try_decode_edited_business_message(raw: ModelUpdate, on_none) {
  case raw.edited_business_message {
    Some(edited_business_message) ->
      new_edited_business_message_update(raw, edited_business_message)
    None -> on_none()
  }
}

fn try_decode_deleted_business_message(raw: ModelUpdate, on_none) {
  case raw.deleted_business_messages {
    Some(deleted_business_messages) ->
      new_deleted_business_message_update(raw, deleted_business_messages)
    None -> on_none()
  }
}

fn try_decode_message_reaction(raw: ModelUpdate, on_none) {
  case raw.message_reaction {
    Some(message_reaction) -> new_message_reaction_update(raw, message_reaction)
    None -> on_none()
  }
}

fn try_decode_message_reaction_count(raw: ModelUpdate, on_none) {
  case raw.message_reaction_count {
    Some(message_reaction_count) ->
      new_message_reaction_count_update(raw, message_reaction_count)
    None -> on_none()
  }
}

fn try_decode_inline_query(raw: ModelUpdate, on_none) {
  case raw.inline_query {
    Some(inline_query) -> new_inline_query_update(raw, inline_query)
    None -> on_none()
  }
}

fn try_decode_chosen_inline_result(raw: ModelUpdate, on_none) {
  case raw.chosen_inline_result {
    Some(chosen_inline_result) ->
      new_chosen_inline_result_update(raw, chosen_inline_result)
    None -> on_none()
  }
}

fn try_decode_shipping_query(raw: ModelUpdate, on_none) {
  case raw.shipping_query {
    Some(shipping_query) -> new_shipping_query_update(raw, shipping_query)
    None -> on_none()
  }
}

fn try_decode_pre_checkout_query(raw: ModelUpdate, on_none) {
  case raw.pre_checkout_query {
    Some(pre_checkout_query) ->
      new_pre_checkout_query_update(raw, pre_checkout_query)
    None -> on_none()
  }
}

fn try_decode_paid_media_purchase(raw: ModelUpdate, on_none) {
  case raw.purchased_paid_media {
    Some(purchased_paid_media) ->
      new_paid_media_purchase_update(raw, purchased_paid_media)
    None -> on_none()
  }
}

fn try_decode_poll(raw: ModelUpdate, on_none) {
  case raw.poll {
    Some(poll) -> new_poll_update(raw, poll)
    None -> on_none()
  }
}

fn try_decode_poll_answer(raw: ModelUpdate, on_none) {
  case raw.poll_answer {
    Some(poll_answer) -> new_poll_answer_update(raw, poll_answer)
    None -> on_none()
  }
}

fn try_decode_my_chat_member(raw: ModelUpdate, on_none) {
  case raw.my_chat_member {
    Some(my_chat_member) -> new_my_chat_member_update(raw, my_chat_member)
    None -> on_none()
  }
}

fn try_decode_chat_member(raw: ModelUpdate, on_none) {
  case raw.chat_member {
    Some(chat_member) -> new_chat_member_update(raw, chat_member)
    None -> on_none()
  }
}

fn try_decode_chat_join_request(raw: ModelUpdate, on_none) {
  case raw.chat_join_request {
    Some(chat_join_request) ->
      new_chat_join_request_update(raw, chat_join_request)
    None -> on_none()
  }
}

fn try_decode_removed_chat_boost(raw: ModelUpdate, on_none) {
  case raw.removed_chat_boost {
    Some(removed_chat_boost) ->
      new_removed_chat_boost_update(raw, removed_chat_boost)
    None -> on_none()
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
    from_id: 0,
    // TODO: Polls don't have a direct from_id, we should use the user id from the poll_answer
    chat_id: 0,
    // TODO: Polls don't have a direct chat_id, we should use the chat id from the poll_answer
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
