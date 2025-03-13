import gleam/dynamic/decode
import gleam/option.{type Option}

// This file is auto-generated from the Telegram Bot API documentation.
// Do not edit it manually.

pub type IntOrString {
  Int(value: Int)
  Str(value: String)
}

fn int_or_string_decoder() -> decode.Decoder(IntOrString) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "int" -> {
      use value <- decode.field("value", decode.int)
      decode.success(Int(value:))
    }
    "str" -> {
      use value <- decode.field("value", decode.string)
      decode.success(Str(value:))
    }
    _ -> decode.failure(Int(0), "IntOrString")
  }
}

pub type FileOrString {
  FileV(value: File)
  StringV(string: String)
}

fn file_or_string_decoder() -> decode.Decoder(FileOrString) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "file_v" -> {
      use value <- decode.field("value", file_decoder())
      decode.success(FileV(value:))
    }
    "string" -> {
      use string <- decode.field("string", decode.string)
      decode.success(StringV(string:))
    }
    _ -> decode.failure(StringV(""), "FileOrString")
  }
}

pub type MaybeInaccessibleMessage {
  MessageMaybeInaccessibleMessage(Message)
  InaccessibleMessageMaybeInaccessibleMessage(InaccessibleMessage)
}

pub type MessageOrigin {
  MessageOriginUserMessageOrigin(MessageOriginUser)
  MessageOriginHiddenUserMessageOrigin(MessageOriginHiddenUser)
  MessageOriginChatMessageOrigin(MessageOriginChat)
  MessageOriginChannelMessageOrigin(MessageOriginChannel)
}

pub type PaidMedia {
  PaidMediaPreviewPaidMedia(PaidMediaPreview)
  PaidMediaPhotoPaidMedia(PaidMediaPhoto)
  PaidMediaVideoPaidMedia(PaidMediaVideo)
}

pub type BackgroundFill {
  BackgroundFillSolidBackgroundFill(BackgroundFillSolid)
  BackgroundFillGradientBackgroundFill(BackgroundFillGradient)
  BackgroundFillFreeformGradientBackgroundFill(BackgroundFillFreeformGradient)
}

pub type BackgroundType {
  BackgroundTypeFillBackgroundType(BackgroundTypeFill)
  BackgroundTypeWallpaperBackgroundType(BackgroundTypeWallpaper)
  BackgroundTypePatternBackgroundType(BackgroundTypePattern)
  BackgroundTypeChatThemeBackgroundType(BackgroundTypeChatTheme)
}

pub type ChatMember {
  ChatMemberOwnerChatMember(ChatMemberOwner)
  ChatMemberAdministratorChatMember(ChatMemberAdministrator)
  ChatMemberMemberChatMember(ChatMemberMember)
  ChatMemberRestrictedChatMember(ChatMemberRestricted)
  ChatMemberLeftChatMember(ChatMemberLeft)
  ChatMemberBannedChatMember(ChatMemberBanned)
}

pub type ReactionType {
  ReactionTypeEmojiReactionType(ReactionTypeEmoji)
  ReactionTypeCustomEmojiReactionType(ReactionTypeCustomEmoji)
  ReactionTypePaidReactionType(ReactionTypePaid)
}

pub type BotCommandScope {
  BotCommandScopeDefaultBotCommandScope(BotCommandScopeDefault)
  BotCommandScopeAllPrivateChatsBotCommandScope(BotCommandScopeAllPrivateChats)
  BotCommandScopeAllGroupChatsBotCommandScope(BotCommandScopeAllGroupChats)
  BotCommandScopeAllChatAdministratorsBotCommandScope(
    BotCommandScopeAllChatAdministrators,
  )
  BotCommandScopeChatBotCommandScope(BotCommandScopeChat)
  BotCommandScopeChatAdministratorsBotCommandScope(
    BotCommandScopeChatAdministrators,
  )
  BotCommandScopeChatMemberBotCommandScope(BotCommandScopeChatMember)
}

pub type MenuButton {
  MenuButtonCommandsMenuButton(MenuButtonCommands)
  MenuButtonWebAppMenuButton(MenuButtonWebApp)
  MenuButtonDefaultMenuButton(MenuButtonDefault)
}

pub type ChatBoostSource {
  ChatBoostSourcePremiumChatBoostSource(ChatBoostSourcePremium)
  ChatBoostSourceGiftCodeChatBoostSource(ChatBoostSourceGiftCode)
  ChatBoostSourceGiveawayChatBoostSource(ChatBoostSourceGiveaway)
}

pub type InputMedia {
  InputMediaAnimationInputMedia(InputMediaAnimation)
  InputMediaDocumentInputMedia(InputMediaDocument)
  InputMediaAudioInputMedia(InputMediaAudio)
  InputMediaPhotoInputMedia(InputMediaPhoto)
  InputMediaVideoInputMedia(InputMediaVideo)
}

pub type InputPaidMedia {
  InputPaidMediaPhotoInputPaidMedia(InputPaidMediaPhoto)
  InputPaidMediaVideoInputPaidMedia(InputPaidMediaVideo)
}

pub type InlineQueryResult {
  InlineQueryResultCachedAudioInlineQueryResult(InlineQueryResultCachedAudio)
  InlineQueryResultCachedDocumentInlineQueryResult(
    InlineQueryResultCachedDocument,
  )
  InlineQueryResultCachedGifInlineQueryResult(InlineQueryResultCachedGif)
  InlineQueryResultCachedMpeg4GifInlineQueryResult(
    InlineQueryResultCachedMpeg4Gif,
  )
  InlineQueryResultCachedPhotoInlineQueryResult(InlineQueryResultCachedPhoto)
  InlineQueryResultCachedStickerInlineQueryResult(
    InlineQueryResultCachedSticker,
  )
  InlineQueryResultCachedVideoInlineQueryResult(InlineQueryResultCachedVideo)
  InlineQueryResultCachedVoiceInlineQueryResult(InlineQueryResultCachedVoice)
  InlineQueryResultArticleInlineQueryResult(InlineQueryResultArticle)
  InlineQueryResultAudioInlineQueryResult(InlineQueryResultAudio)
  InlineQueryResultContactInlineQueryResult(InlineQueryResultContact)
  InlineQueryResultGameInlineQueryResult(InlineQueryResultGame)
  InlineQueryResultDocumentInlineQueryResult(InlineQueryResultDocument)
  InlineQueryResultGifInlineQueryResult(InlineQueryResultGif)
  InlineQueryResultLocationInlineQueryResult(InlineQueryResultLocation)
  InlineQueryResultMpeg4GifInlineQueryResult(InlineQueryResultMpeg4Gif)
  InlineQueryResultPhotoInlineQueryResult(InlineQueryResultPhoto)
  InlineQueryResultVenueInlineQueryResult(InlineQueryResultVenue)
  InlineQueryResultVideoInlineQueryResult(InlineQueryResultVideo)
  InlineQueryResultVoiceInlineQueryResult(InlineQueryResultVoice)
}

pub type InputMessageContent {
  InputTextMessageContentInputMessageContent(InputTextMessageContent)
  InputLocationMessageContentInputMessageContent(InputLocationMessageContent)
  InputVenueMessageContentInputMessageContent(InputVenueMessageContent)
  InputContactMessageContentInputMessageContent(InputContactMessageContent)
  InputInvoiceMessageContentInputMessageContent(InputInvoiceMessageContent)
}

pub type RevenueWithdrawalState {
  RevenueWithdrawalStatePendingRevenueWithdrawalState(
    RevenueWithdrawalStatePending,
  )
  RevenueWithdrawalStateSucceededRevenueWithdrawalState(
    RevenueWithdrawalStateSucceeded,
  )
  RevenueWithdrawalStateFailedRevenueWithdrawalState(
    RevenueWithdrawalStateFailed,
  )
}

pub type TransactionPartner {
  TransactionPartnerUserTransactionPartner(TransactionPartnerUser)
  TransactionPartnerChatTransactionPartner(TransactionPartnerChat)
  TransactionPartnerAffiliateProgramTransactionPartner(
    TransactionPartnerAffiliateProgram,
  )
  TransactionPartnerFragmentTransactionPartner(TransactionPartnerFragment)
  TransactionPartnerTelegramAdsTransactionPartner(TransactionPartnerTelegramAds)
  TransactionPartnerTelegramApiTransactionPartner(TransactionPartnerTelegramApi)
  TransactionPartnerOtherTransactionPartner(TransactionPartnerOther)
}

pub type PassportElementError {
  PassportElementErrorDataFieldPassportElementError(
    PassportElementErrorDataField,
  )
  PassportElementErrorFrontSidePassportElementError(
    PassportElementErrorFrontSide,
  )
  PassportElementErrorReverseSidePassportElementError(
    PassportElementErrorReverseSide,
  )
  PassportElementErrorSelfiePassportElementError(PassportElementErrorSelfie)
  PassportElementErrorFilePassportElementError(PassportElementErrorFile)
  PassportElementErrorFilesPassportElementError(PassportElementErrorFiles)
  PassportElementErrorTranslationFilePassportElementError(
    PassportElementErrorTranslationFile,
  )
  PassportElementErrorTranslationFilesPassportElementError(
    PassportElementErrorTranslationFiles,
  )
  PassportElementErrorUnspecifiedPassportElementError(
    PassportElementErrorUnspecified,
  )
}

/// **Official reference:** This object represents an incoming update.
/// At most one of the optional parameters can be present in any given update.
pub type Update {
  Update(
    /// The update's unique identifier. Update identifiers start from a certain positive number and increase sequentially. This identifier becomes especially handy if you're using webhooks, since it allows you to ignore repeated updates or to restore the correct update sequence, should they get out of order. If there are no new updates for at least a week, then identifier of the next update will be chosen randomly instead of sequentially.
    update_id: Int,
    /// Optional. New incoming message of any kind - text, photo, sticker, etc.
    message: Option(Message),
    /// Optional. New version of a message that is known to the bot and was edited. This update may at times be triggered by changes to message fields that are either unavailable or not actively used by your bot.
    edited_message: Option(Message),
    /// Optional. New incoming channel post of any kind - text, photo, sticker, etc.
    channel_post: Option(Message),
    /// Optional. New version of a channel post that is known to the bot and was edited. This update may at times be triggered by changes to message fields that are either unavailable or not actively used by your bot.
    edited_channel_post: Option(Message),
    /// Optional. The bot was connected to or disconnected from a business account, or a user edited an existing connection with the bot
    business_connection: Option(BusinessConnection),
    /// Optional. New message from a connected business account
    business_message: Option(Message),
    /// Optional. New version of a message from a connected business account
    edited_business_message: Option(Message),
    /// Optional. Messages were deleted from a connected business account
    deleted_business_messages: Option(BusinessMessagesDeleted),
    /// Optional. A reaction to a message was changed by a user. The bot must be an administrator in the chat and must explicitly specify "message_reaction" in the list of allowed_updates to receive these updates. The update isn't received for reactions set by bots.
    message_reaction: Option(MessageReactionUpdated),
    /// Optional. Reactions to a message with anonymous reactions were changed. The bot must be an administrator in the chat and must explicitly specify "message_reaction_count" in the list of allowed_updates to receive these updates. The updates are grouped and can be sent with delay up to a few minutes.
    message_reaction_count: Option(MessageReactionCountUpdated),
    /// Optional. New incoming inline query
    inline_query: Option(InlineQuery),
    /// Optional. The result of an inline query that was chosen by a user and sent to their chat partner. Please see our documentation on the feedback collecting for details on how to enable these updates for your bot.
    chosen_inline_result: Option(ChosenInlineResult),
    /// Optional. New incoming callback query
    callback_query: Option(CallbackQuery),
    /// Optional. New incoming shipping query. Only for invoices with flexible price
    shipping_query: Option(ShippingQuery),
    /// Optional. New incoming pre-checkout query. Contains full information about checkout
    pre_checkout_query: Option(PreCheckoutQuery),
    /// Optional. A user purchased paid media with a non-empty payload sent by the bot in a non-channel chat
    purchased_paid_media: Option(PaidMediaPurchased),
    /// Optional. New poll state. Bots receive only updates about manually stopped polls and polls, which are sent by the bot
    poll: Option(Poll),
    /// Optional. A user changed their answer in a non-anonymous poll. Bots receive new votes only in polls that were sent by the bot itself.
    poll_answer: Option(PollAnswer),
    /// Optional. The bot's chat member status was updated in a chat. For private chats, this update is received only when the bot is blocked or unblocked by the user.
    my_chat_member: Option(ChatMemberUpdated),
    /// Optional. A chat member's status was updated in a chat. The bot must be an administrator in the chat and must explicitly specify "chat_member" in the list of allowed_updates to receive these updates.
    chat_member: Option(ChatMemberUpdated),
    /// Optional. A request to join the chat has been sent. The bot must have the can_invite_users administrator right in the chat to receive these updates.
    chat_join_request: Option(ChatJoinRequest),
    /// Optional. A chat boost was added or changed. The bot must be an administrator in the chat to receive these updates.
    chat_boost: Option(ChatBoostUpdated),
    /// Optional. A boost was removed from a chat. The bot must be an administrator in the chat to receive these updates.
    removed_chat_boost: Option(ChatBoostRemoved),
  )
}

/// **Official reference:** Describes the current status of a webhook.
pub type WebhookInfo {
  WebhookInfo(
    /// Webhook URL, may be empty if webhook is not set up
    url: String,
    /// True, if a custom certificate was provided for webhook certificate checks
    has_custom_certificate: Bool,
    /// Number of updates awaiting delivery
    pending_update_count: Int,
    /// Optional. Currently used webhook IP address
    ip_address: Option(String),
    /// Optional. Unix time for the most recent error that happened when trying to deliver an update via webhook
    last_error_date: Option(Int),
    /// Optional. Error message in human-readable format for the most recent error that happened when trying to deliver an update via webhook
    last_error_message: Option(String),
    /// Optional. Unix time of the most recent error that happened when trying to synchronize available updates with Telegram datacenters
    last_synchronization_error_date: Option(Int),
    /// Optional. The maximum allowed number of simultaneous HTTPS connections to the webhook for update delivery
    max_connections: Option(Int),
    /// Optional. A list of update types the bot is subscribed to. Defaults to all update types except chat_member
    allowed_updates: Option(List(String)),
  )
}

/// **Official reference:** This object represents a Telegram user or bot.
pub type User {
  User(
    /// Unique identifier for this user or bot. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a 64-bit integer or double-precision float type are safe for storing this identifier.
    id: Int,
    /// True, if this user is a bot
    is_bot: Bool,
    /// User's or bot's first name
    first_name: String,
    /// Optional. User's or bot's last name
    last_name: Option(String),
    /// Optional. User's or bot's username
    username: Option(String),
    /// Optional. IETF language tag of the user's language
    language_code: Option(String),
    /// Optional. True, if this user is a Telegram Premium user
    is_premium: Option(Bool),
    /// Optional. True, if this user added the bot to the attachment menu
    added_to_attachment_menu: Option(Bool),
    /// Optional. True, if the bot can be invited to groups. Returned only in getMe.
    can_join_groups: Option(Bool),
    /// Optional. True, if privacy mode is disabled for the bot. Returned only in getMe.
    can_read_all_group_messages: Option(Bool),
    /// Optional. True, if the bot supports inline queries. Returned only in getMe.
    supports_inline_queries: Option(Bool),
    /// Optional. True, if the bot can be connected to a Telegram Business account to receive its messages. Returned only in getMe.
    can_connect_to_business: Option(Bool),
    /// Optional. True, if the bot has a main Web App. Returned only in getMe.
    has_main_web_app: Option(Bool),
  )
}

/// **Official reference:** This object represents a chat.
pub type Chat {
  Chat(
    /// Unique identifier for this chat. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this identifier.
    id: Int,
    /// Type of the chat, can be either “private”, “group”, “supergroup” or “channel”
    type_: String,
    /// Optional. Title, for supergroups, channels and group chats
    title: Option(String),
    /// Optional. Username, for private chats, supergroups and channels if available
    username: Option(String),
    /// Optional. First name of the other party in a private chat
    first_name: Option(String),
    /// Optional. Last name of the other party in a private chat
    last_name: Option(String),
    /// Optional. True, if the supergroup chat is a forum (has topics enabled)
    is_forum: Option(Bool),
  )
}

/// **Official reference:** This object contains full information about a chat.
pub type ChatFullInfo {
  ChatFullInfo(
    /// Unique identifier for this chat. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this identifier.
    id: Int,
    /// Type of the chat, can be either “private”, “group”, “supergroup” or “channel”
    type_: String,
    /// Optional. Title, for supergroups, channels and group chats
    title: Option(String),
    /// Optional. Username, for private chats, supergroups and channels if available
    username: Option(String),
    /// Optional. First name of the other party in a private chat
    first_name: Option(String),
    /// Optional. Last name of the other party in a private chat
    last_name: Option(String),
    /// Optional. True, if the supergroup chat is a forum (has topics enabled)
    is_forum: Option(Bool),
    /// Identifier of the accent color for the chat name and backgrounds of the chat photo, reply header, and link preview. See accent colors for more details.
    accent_color_id: Int,
    /// The maximum number of reactions that can be set on a message in the chat
    max_reaction_count: Int,
    /// Optional. Chat photo
    photo: Option(ChatPhoto),
    /// Optional. If non-empty, the list of all active chat usernames; for private chats, supergroups and channels
    active_usernames: Option(List(String)),
    /// Optional. For private chats, the date of birth of the user
    birthdate: Option(Birthdate),
    /// Optional. For private chats with business accounts, the intro of the business
    business_intro: Option(BusinessIntro),
    /// Optional. For private chats with business accounts, the location of the business
    business_location: Option(BusinessLocation),
    /// Optional. For private chats with business accounts, the opening hours of the business
    business_opening_hours: Option(BusinessOpeningHours),
    /// Optional. For private chats, the personal channel of the user
    personal_chat: Option(Chat),
    /// Optional. List of available reactions allowed in the chat. If omitted, then all emoji reactions are allowed.
    available_reactions: Option(List(ReactionType)),
    /// Optional. Custom emoji identifier of the emoji chosen by the chat for the reply header and link preview background
    background_custom_emoji_id: Option(String),
    /// Optional. Identifier of the accent color for the chat's profile background. See profile accent colors for more details.
    profile_accent_color_id: Option(Int),
    /// Optional. Custom emoji identifier of the emoji chosen by the chat for its profile background
    profile_background_custom_emoji_id: Option(String),
    /// Optional. Custom emoji identifier of the emoji status of the chat or the other party in a private chat
    emoji_status_custom_emoji_id: Option(String),
    /// Optional. Expiration date of the emoji status of the chat or the other party in a private chat, in Unix time, if any
    emoji_status_expiration_date: Option(Int),
    /// Optional. Bio of the other party in a private chat
    bio: Option(String),
    /// Optional. True, if privacy settings of the other party in the private chat allows to use tg://user?id=<user_id> links only in chats with the user
    has_private_forwards: Option(Bool),
    /// Optional. True, if the privacy settings of the other party restrict sending voice and video note messages in the private chat
    has_restricted_voice_and_video_messages: Option(Bool),
    /// Optional. True, if users need to join the supergroup before they can send messages
    join_to_send_messages: Option(Bool),
    /// Optional. True, if all users directly joining the supergroup without using an invite link need to be approved by supergroup administrators
    join_by_request: Option(Bool),
    /// Optional. Description, for groups, supergroups and channel chats
    description: Option(String),
    /// Optional. Primary invite link, for groups, supergroups and channel chats
    invite_link: Option(String),
    /// Optional. The most recent pinned message (by sending date)
    pinned_message: Option(Message),
    /// Optional. Default chat member permissions, for groups and supergroups
    permissions: Option(ChatPermissions),
    /// Optional. True, if gifts can be sent to the chat
    can_send_gift: Option(Bool),
    /// Optional. True, if paid media messages can be sent or forwarded to the channel chat. The field is available only for channel chats.
    can_send_paid_media: Option(Bool),
    /// Optional. For supergroups, the minimum allowed delay between consecutive messages sent by each unprivileged user; in seconds
    slow_mode_delay: Option(Int),
    /// Optional. For supergroups, the minimum number of boosts that a non-administrator user needs to add in order to ignore slow mode and chat permissions
    unrestrict_boost_count: Option(Int),
    /// Optional. The time after which all messages sent to the chat will be automatically deleted; in seconds
    message_auto_delete_time: Option(Int),
    /// Optional. True, if aggressive anti-spam checks are enabled in the supergroup. The field is only available to chat administrators.
    has_aggressive_anti_spam_enabled: Option(Bool),
    /// Optional. True, if non-administrators can only get the list of bots and administrators in the chat
    has_hidden_members: Option(Bool),
    /// Optional. True, if messages from the chat can't be forwarded to other chats
    has_protected_content: Option(Bool),
    /// Optional. True, if new chat members will have access to old messages; available only to chat administrators
    has_visible_history: Option(Bool),
    /// Optional. For supergroups, name of the group sticker set
    sticker_set_name: Option(String),
    /// Optional. True, if the bot can change the group sticker set
    can_set_sticker_set: Option(Bool),
    /// Optional. For supergroups, the name of the group's custom emoji sticker set. Custom emoji from this set can be used by all users and bots in the group.
    custom_emoji_sticker_set_name: Option(String),
    /// Optional. Unique identifier for the linked chat, i.e. the discussion group identifier for a channel and vice versa; for supergroups and channel chats. This identifier may be greater than 32 bits and some programming languages may have difficulty/silent defects in interpreting it. But it is smaller than 52 bits, so a signed 64 bit integer or double-precision float type are safe for storing this identifier.
    linked_chat_id: Option(Int),
    /// Optional. For supergroups, the location to which the supergroup is connected
    location: Option(ChatLocation),
  )
}

/// **Official reference:** This object represents a message.
pub type Message {
  Message(
    /// Unique message identifier inside this chat. In specific instances (e.g., message containing a video sent to a big chat), the server might automatically schedule a message instead of sending it immediately. In such cases, this field will be 0 and the relevant message will be unusable until it is actually sent
    message_id: Int,
    /// Optional. Unique identifier of a message thread to which the message belongs; for supergroups only
    message_thread_id: Option(Int),
    /// Optional. Sender of the message; may be empty for messages sent to channels. For backward compatibility, if the message was sent on behalf of a chat, the field contains a fake sender user in non-channel chats
    from: Option(User),
    /// Optional. Sender of the message when sent on behalf of a chat. For example, the supergroup itself for messages sent by its anonymous administrators or a linked channel for messages automatically forwarded to the channel's discussion group. For backward compatibility, if the message was sent on behalf of a chat, the field from contains a fake sender user in non-channel chats.
    sender_chat: Option(Chat),
    /// Optional. If the sender of the message boosted the chat, the number of boosts added by the user
    sender_boost_count: Option(Int),
    /// Optional. The bot that actually sent the message on behalf of the business account. Available only for outgoing messages sent on behalf of the connected business account.
    sender_business_bot: Option(User),
    /// Date the message was sent in Unix time. It is always a positive number, representing a valid date.
    date: Int,
    /// Optional. Unique identifier of the business connection from which the message was received. If non-empty, the message belongs to a chat of the corresponding business account that is independent from any potential bot chat which might share the same identifier.
    business_connection_id: Option(String),
    /// Chat the message belongs to
    chat: Chat,
    /// Optional. Information about the original message for forwarded messages
    forward_origin: Option(MessageOrigin),
    /// Optional. True, if the message is sent to a forum topic
    is_topic_message: Option(Bool),
    /// Optional. True, if the message is a channel post that was automatically forwarded to the connected discussion group
    is_automatic_forward: Option(Bool),
    /// Optional. For replies in the same chat and message thread, the original message. Note that the Message object in this field will not contain further reply_to_message fields even if it itself is a reply.
    reply_to_message: Option(Message),
    /// Optional. Information about the message that is being replied to, which may come from another chat or forum topic
    external_reply: Option(ExternalReplyInfo),
    /// Optional. For replies that quote part of the original message, the quoted part of the message
    quote: Option(TextQuote),
    /// Optional. For replies to a story, the original story
    reply_to_story: Option(Story),
    /// Optional. Bot through which the message was sent
    via_bot: Option(User),
    /// Optional. Date the message was last edited in Unix time
    edit_date: Option(Int),
    /// Optional. True, if the message can't be forwarded
    has_protected_content: Option(Bool),
    /// Optional. True, if the message was sent by an implicit action, for example, as an away or a greeting business message, or as a scheduled message
    is_from_offline: Option(Bool),
    /// Optional. The unique identifier of a media message group this message belongs to
    media_group_id: Option(String),
    /// Optional. Signature of the post author for messages in channels, or the custom title of an anonymous group administrator
    author_signature: Option(String),
    /// Optional. For text messages, the actual UTF-8 text of the message
    text: Option(String),
    /// Optional. For text messages, special entities like usernames, URLs, bot commands, etc. that appear in the text
    entities: Option(List(MessageEntity)),
    /// Optional. Options used for link preview generation for the message, if it is a text message and link preview options were changed
    link_preview_options: Option(LinkPreviewOptions),
    /// Optional. Unique identifier of the message effect added to the message
    effect_id: Option(String),
    /// Optional. Message is an animation, information about the animation. For backward compatibility, when this field is set, the document field will also be set
    animation: Option(Animation),
    /// Optional. Message is an audio file, information about the file
    audio: Option(Audio),
    /// Optional. Message is a general file, information about the file
    document: Option(Document),
    /// Optional. Message contains paid media; information about the paid media
    paid_media: Option(PaidMediaInfo),
    /// Optional. Message is a photo, available sizes of the photo
    photo: Option(List(PhotoSize)),
    /// Optional. Message is a sticker, information about the sticker
    sticker: Option(Sticker),
    /// Optional. Message is a forwarded story
    story: Option(Story),
    /// Optional. Message is a video, information about the video
    video: Option(Video),
    /// Optional. Message is a video note, information about the video message
    video_note: Option(VideoNote),
    /// Optional. Message is a voice message, information about the file
    voice: Option(Voice),
    /// Optional. Caption for the animation, audio, document, paid media, photo, video or voice
    caption: Option(String),
    /// Optional. For messages with a caption, special entities like usernames, URLs, bot commands, etc. that appear in the caption
    caption_entities: Option(List(MessageEntity)),
    /// Optional. True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. True, if the message media is covered by a spoiler animation
    has_media_spoiler: Option(Bool),
    /// Optional. Message is a shared contact, information about the contact
    contact: Option(Contact),
    /// Optional. Message is a dice with random value
    dice: Option(Dice),
    /// Optional. Message is a game, information about the game. More about games »
    game: Option(Game),
    /// Optional. Message is a native poll, information about the poll
    poll: Option(Poll),
    /// Optional. Message is a venue, information about the venue. For backward compatibility, when this field is set, the location field will also be set
    venue: Option(Venue),
    /// Optional. Message is a shared location, information about the location
    location: Option(Location),
    /// Optional. New members that were added to the group or supergroup and information about them (the bot itself may be one of these members)
    new_chat_members: Option(List(User)),
    /// Optional. A member was removed from the group, information about them (this member may be the bot itself)
    left_chat_member: Option(User),
    /// Optional. A chat title was changed to this value
    new_chat_title: Option(String),
    /// Optional. A chat photo was change to this value
    new_chat_photo: Option(List(PhotoSize)),
    /// Optional. Service message: the chat photo was deleted
    delete_chat_photo: Option(Bool),
    /// Optional. Service message: the group has been created
    group_chat_created: Option(Bool),
    /// Optional. Service message: the supergroup has been created. This field can't be received in a message coming through updates, because bot can't be a member of a supergroup when it is created. It can only be found in reply_to_message if someone replies to a very first message in a directly created supergroup.
    supergroup_chat_created: Option(Bool),
    /// Optional. Service message: the channel has been created. This field can't be received in a message coming through updates, because bot can't be a member of a channel when it is created. It can only be found in reply_to_message if someone replies to a very first message in a channel.
    channel_chat_created: Option(Bool),
    /// Optional. Service message: auto-delete timer settings changed in the chat
    message_auto_delete_timer_changed: Option(MessageAutoDeleteTimerChanged),
    /// Optional. The group has been migrated to a supergroup with the specified identifier. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this identifier.
    migrate_to_chat_id: Option(Int),
    /// Optional. The supergroup has been migrated from a group with the specified identifier. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this identifier.
    migrate_from_chat_id: Option(Int),
    /// Optional. Specified message was pinned. Note that the Message object in this field will not contain further reply_to_message fields even if it itself is a reply.
    pinned_message: Option(MaybeInaccessibleMessage),
    /// Optional. Message is an invoice for a payment, information about the invoice. More about payments »
    invoice: Option(Invoice),
    /// Optional. Message is a service message about a successful payment, information about the payment. More about payments »
    successful_payment: Option(SuccessfulPayment),
    /// Optional. Message is a service message about a refunded payment, information about the payment. More about payments »
    refunded_payment: Option(RefundedPayment),
    /// Optional. Service message: users were shared with the bot
    users_shared: Option(UsersShared),
    /// Optional. Service message: a chat was shared with the bot
    chat_shared: Option(ChatShared),
    /// Optional. The domain name of the website on which the user has logged in. More about Telegram Login »
    connected_website: Option(String),
    /// Optional. Service message: the user allowed the bot to write messages after adding it to the attachment or side menu, launching a Web App from a link, or accepting an explicit request from a Web App sent by the method requestWriteAccess
    write_access_allowed: Option(WriteAccessAllowed),
    /// Optional. Telegram Passport data
    passport_data: Option(PassportData),
    /// Optional. Service message. A user in the chat triggered another user's proximity alert while sharing Live Location.
    proximity_alert_triggered: Option(ProximityAlertTriggered),
    /// Optional. Service message: user boosted the chat
    boost_added: Option(ChatBoostAdded),
    /// Optional. Service message: chat background set
    chat_background_set: Option(ChatBackground),
    /// Optional. Service message: forum topic created
    forum_topic_created: Option(ForumTopicCreated),
    /// Optional. Service message: forum topic edited
    forum_topic_edited: Option(ForumTopicEdited),
    /// Optional. Service message: forum topic closed
    forum_topic_closed: Option(ForumTopicClosed),
    /// Optional. Service message: forum topic reopened
    forum_topic_reopened: Option(ForumTopicReopened),
    /// Optional. Service message: the 'General' forum topic hidden
    general_forum_topic_hidden: Option(GeneralForumTopicHidden),
    /// Optional. Service message: the 'General' forum topic unhidden
    general_forum_topic_unhidden: Option(GeneralForumTopicUnhidden),
    /// Optional. Service message: a scheduled giveaway was created
    giveaway_created: Option(GiveawayCreated),
    /// Optional. The message is a scheduled giveaway message
    giveaway: Option(Giveaway),
    /// Optional. A giveaway with public winners was completed
    giveaway_winners: Option(GiveawayWinners),
    /// Optional. Service message: a giveaway without public winners was completed
    giveaway_completed: Option(GiveawayCompleted),
    /// Optional. Service message: video chat scheduled
    video_chat_scheduled: Option(VideoChatScheduled),
    /// Optional. Service message: video chat started
    video_chat_started: Option(VideoChatStarted),
    /// Optional. Service message: video chat ended
    video_chat_ended: Option(VideoChatEnded),
    /// Optional. Service message: new participants invited to a video chat
    video_chat_participants_invited: Option(VideoChatParticipantsInvited),
    /// Optional. Service message: data sent by a Web App
    web_app_data: Option(WebAppData),
    /// Optional. Inline keyboard attached to the message. login_url buttons are represented as ordinary url buttons.
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

/// **Official reference:** This object represents a unique message identifier.
pub type MessageId {
  MessageId(
    /// Unique message identifier. In specific instances (e.g., message containing a video sent to a big chat), the server might automatically schedule a message instead of sending it immediately. In such cases, this field will be 0 and the relevant message will be unusable until it is actually sent
    message_id: Int,
  )
}

/// **Official reference:** This object describes a message that was deleted or is otherwise inaccessible to the bot.
pub type InaccessibleMessage {
  InaccessibleMessage(
    /// Chat the message belonged to
    chat: Chat,
    /// Unique message identifier inside the chat
    message_id: Int,
    /// Always 0. The field can be used to differentiate regular and inaccessible messages.
    date: Int,
  )
}

/// **Official reference:** This object represents one special entity in a text message. For example, hashtags, usernames, URLs, etc.
pub type MessageEntity {
  MessageEntity(
    /// Type of the entity. Currently, can be “mention” (@username), “hashtag” (#hashtag or #hashtag@chatusername), “cashtag” ($USD or $USD@chatusername), “bot_command” (/start@jobs_bot), “url” (https://telegram.org), “email” (do-not-reply@telegram.org), “phone_number” (+1-212-555-0123), “bold” (bold text), “italic” (italic text), “underline” (underlined text), “strikethrough” (strikethrough text), “spoiler” (spoiler message), “blockquote” (block quotation), “expandable_blockquote” (collapsed-by-default block quotation), “code” (monowidth string), “pre” (monowidth block), “text_link” (for clickable text URLs), “text_mention” (for users without usernames), “custom_emoji” (for inline custom emoji stickers)
    type_: String,
    /// Offset in UTF-16 code units to the start of the entity
    offset: Int,
    /// Length of the entity in UTF-16 code units
    length: Int,
    /// Optional. For “text_link” only, URL that will be opened after user taps on the text
    url: Option(String),
    /// Optional. For “text_mention” only, the mentioned user
    user: Option(User),
    /// Optional. For “pre” only, the programming language of the entity text
    language: Option(String),
    /// Optional. For “custom_emoji” only, unique identifier of the custom emoji. Use getCustomEmojiStickers to get full information about the sticker
    custom_emoji_id: Option(String),
  )
}

/// **Official reference:** This object contains information about the quoted part of a message that is replied to by the given message.
pub type TextQuote {
  TextQuote(
    /// Text of the quoted part of a message that is replied to by the given message
    text: String,
    /// Optional. Special entities that appear in the quote. Currently, only bold, italic, underline, strikethrough, spoiler, and custom_emoji entities are kept in quotes.
    entities: Option(List(MessageEntity)),
    /// Approximate quote position in the original message in UTF-16 code units as specified by the sender
    position: Int,
    /// Optional. True, if the quote was chosen manually by the message sender. Otherwise, the quote was added automatically by the server.
    is_manual: Option(Bool),
  )
}

/// **Official reference:** This object contains information about a message that is being replied to, which may come from another chat or forum topic.
pub type ExternalReplyInfo {
  ExternalReplyInfo(
    /// Origin of the message replied to by the given message
    origin: MessageOrigin,
    /// Optional. Chat the original message belongs to. Available only if the chat is a supergroup or a channel.
    chat: Option(Chat),
    /// Optional. Unique message identifier inside the original chat. Available only if the original chat is a supergroup or a channel.
    message_id: Option(Int),
    /// Optional. Options used for link preview generation for the original message, if it is a text message
    link_preview_options: Option(LinkPreviewOptions),
    /// Optional. Message is an animation, information about the animation
    animation: Option(Animation),
    /// Optional. Message is an audio file, information about the file
    audio: Option(Audio),
    /// Optional. Message is a general file, information about the file
    document: Option(Document),
    /// Optional. Message contains paid media; information about the paid media
    paid_media: Option(PaidMediaInfo),
    /// Optional. Message is a photo, available sizes of the photo
    photo: Option(List(PhotoSize)),
    /// Optional. Message is a sticker, information about the sticker
    sticker: Option(Sticker),
    /// Optional. Message is a forwarded story
    story: Option(Story),
    /// Optional. Message is a video, information about the video
    video: Option(Video),
    /// Optional. Message is a video note, information about the video message
    video_note: Option(VideoNote),
    /// Optional. Message is a voice message, information about the file
    voice: Option(Voice),
    /// Optional. True, if the message media is covered by a spoiler animation
    has_media_spoiler: Option(Bool),
    /// Optional. Message is a shared contact, information about the contact
    contact: Option(Contact),
    /// Optional. Message is a dice with random value
    dice: Option(Dice),
    /// Optional. Message is a game, information about the game. More about games »
    game: Option(Game),
    /// Optional. Message is a scheduled giveaway, information about the giveaway
    giveaway: Option(Giveaway),
    /// Optional. A giveaway with public winners was completed
    giveaway_winners: Option(GiveawayWinners),
    /// Optional. Message is an invoice for a payment, information about the invoice. More about payments »
    invoice: Option(Invoice),
    /// Optional. Message is a shared location, information about the location
    location: Option(Location),
    /// Optional. Message is a native poll, information about the poll
    poll: Option(Poll),
    /// Optional. Message is a venue, information about the venue
    venue: Option(Venue),
  )
}

/// **Official reference:** Describes reply parameters for the message that is being sent.
pub type ReplyParameters {
  ReplyParameters(
    /// Identifier of the message that will be replied to in the current chat, or in the chat chat_id if it is specified
    message_id: Int,
    /// Optional. If the message to be replied to is from a different chat, unique identifier for the chat or username of the channel (in the format @channelusername). Not supported for messages sent on behalf of a business account.
    chat_id: Option(IntOrString),
    /// Optional. Pass True if the message should be sent even if the specified message to be replied to is not found. Always False for replies in another chat or forum topic. Always True for messages sent on behalf of a business account.
    allow_sending_without_reply: Option(Bool),
    /// Optional. Quoted part of the message to be replied to; 0-1024 characters after entities parsing. The quote must be an exact substring of the message to be replied to, including bold, italic, underline, strikethrough, spoiler, and custom_emoji entities. The message will fail to send if the quote isn't found in the original message.
    quote: Option(String),
    /// Optional. Mode for parsing entities in the quote. See formatting options for more details.
    quote_parse_mode: Option(String),
    /// Optional. A JSON-serialized list of special entities that appear in the quote. It can be specified instead of quote_parse_mode.
    quote_entities: Option(List(MessageEntity)),
    /// Optional. Position of the quote in the original message in UTF-16 code units
    quote_position: Option(Int),
  )
}

/// **Official reference:** The message was originally sent by a known user.
pub type MessageOriginUser {
  MessageOriginUser(
    /// Type of the message origin, always “user”
    type_: String,
    /// Date the message was sent originally in Unix time
    date: Int,
    /// User that sent the message originally
    sender_user: User,
  )
}

/// **Official reference:** The message was originally sent by an unknown user.
pub type MessageOriginHiddenUser {
  MessageOriginHiddenUser(
    /// Type of the message origin, always “hidden_user”
    type_: String,
    /// Date the message was sent originally in Unix time
    date: Int,
    /// Name of the user that sent the message originally
    sender_user_name: String,
  )
}

/// **Official reference:** The message was originally sent on behalf of a chat to a group chat.
pub type MessageOriginChat {
  MessageOriginChat(
    /// Type of the message origin, always “chat”
    type_: String,
    /// Date the message was sent originally in Unix time
    date: Int,
    /// Chat that sent the message originally
    sender_chat: Chat,
    /// Optional. For messages originally sent by an anonymous chat administrator, original message author signature
    author_signature: Option(String),
  )
}

/// **Official reference:** The message was originally sent to a channel chat.
pub type MessageOriginChannel {
  MessageOriginChannel(
    /// Type of the message origin, always “channel”
    type_: String,
    /// Date the message was sent originally in Unix time
    date: Int,
    /// Channel chat to which the message was originally sent
    chat: Chat,
    /// Unique message identifier inside the chat
    message_id: Int,
    /// Optional. Signature of the original post author
    author_signature: Option(String),
  )
}

/// **Official reference:** This object represents one size of a photo or a file / sticker thumbnail.
pub type PhotoSize {
  PhotoSize(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// Photo width
    width: Int,
    /// Photo height
    height: Int,
    /// Optional. File size in bytes
    file_size: Option(Int),
  )
}

/// **Official reference:** This object represents an animation file (GIF or H.264/MPEG-4 AVC video without sound).
pub type Animation {
  Animation(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// Video width as defined by the sender
    width: Int,
    /// Video height as defined by the sender
    height: Int,
    /// Duration of the video in seconds as defined by the sender
    duration: Int,
    /// Optional. Animation thumbnail as defined by the sender
    thumbnail: Option(PhotoSize),
    /// Optional. Original animation filename as defined by the sender
    file_name: Option(String),
    /// Optional. MIME type of the file as defined by the sender
    mime_type: Option(String),
    /// Optional. File size in bytes. It can be bigger than 2^31 and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this value.
    file_size: Option(Int),
  )
}

/// **Official reference:** This object represents an audio file to be treated as music by the Telegram clients.
pub type Audio {
  Audio(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// Duration of the audio in seconds as defined by the sender
    duration: Int,
    /// Optional. Performer of the audio as defined by the sender or by audio tags
    performer: Option(String),
    /// Optional. Title of the audio as defined by the sender or by audio tags
    title: Option(String),
    /// Optional. Original filename as defined by the sender
    file_name: Option(String),
    /// Optional. MIME type of the file as defined by the sender
    mime_type: Option(String),
    /// Optional. File size in bytes. It can be bigger than 2^31 and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this value.
    file_size: Option(Int),
    /// Optional. Thumbnail of the album cover to which the music file belongs
    thumbnail: Option(PhotoSize),
  )
}

/// **Official reference:** This object represents a general file (as opposed to photos, voice messages and audio files).
pub type Document {
  Document(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// Optional. Document thumbnail as defined by the sender
    thumbnail: Option(PhotoSize),
    /// Optional. Original filename as defined by the sender
    file_name: Option(String),
    /// Optional. MIME type of the file as defined by the sender
    mime_type: Option(String),
    /// Optional. File size in bytes. It can be bigger than 2^31 and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this value.
    file_size: Option(Int),
  )
}

/// **Official reference:** This object represents a story.
pub type Story {
  Story(
    /// Chat that posted the story
    chat: Chat,
    /// Unique identifier for the story in the chat
    id: Int,
  )
}

/// **Official reference:** This object represents a video file.
pub type Video {
  Video(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// Video width as defined by the sender
    width: Int,
    /// Video height as defined by the sender
    height: Int,
    /// Duration of the video in seconds as defined by the sender
    duration: Int,
    /// Optional. Video thumbnail
    thumbnail: Option(PhotoSize),
    /// Optional. Available sizes of the cover of the video in the message
    cover: Option(List(PhotoSize)),
    /// Optional. Timestamp in seconds from which the video will play in the message
    start_timestamp: Option(Int),
    /// Optional. Original filename as defined by the sender
    file_name: Option(String),
    /// Optional. MIME type of the file as defined by the sender
    mime_type: Option(String),
    /// Optional. File size in bytes. It can be bigger than 2^31 and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this value.
    file_size: Option(Int),
  )
}

/// **Official reference:** This object represents a video message (available in Telegram apps as of v.4.0).
pub type VideoNote {
  VideoNote(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// Video width and height (diameter of the video message) as defined by the sender
    length: Int,
    /// Duration of the video in seconds as defined by the sender
    duration: Int,
    /// Optional. Video thumbnail
    thumbnail: Option(PhotoSize),
    /// Optional. File size in bytes
    file_size: Option(Int),
  )
}

/// **Official reference:** This object represents a voice note.
pub type Voice {
  Voice(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// Duration of the audio in seconds as defined by the sender
    duration: Int,
    /// Optional. MIME type of the file as defined by the sender
    mime_type: Option(String),
    /// Optional. File size in bytes. It can be bigger than 2^31 and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this value.
    file_size: Option(Int),
  )
}

/// **Official reference:** Describes the paid media added to a message.
pub type PaidMediaInfo {
  PaidMediaInfo(
    /// The number of Telegram Stars that must be paid to buy access to the media
    star_count: Int,
    /// Information about the paid media
    paid_media: List(PaidMedia),
  )
}

/// **Official reference:** The paid media isn't available before the payment.
pub type PaidMediaPreview {
  PaidMediaPreview(
    /// Type of the paid media, always “preview”
    type_: String,
    /// Optional. Media width as defined by the sender
    width: Option(Int),
    /// Optional. Media height as defined by the sender
    height: Option(Int),
    /// Optional. Duration of the media in seconds as defined by the sender
    duration: Option(Int),
  )
}

/// **Official reference:** The paid media is a photo.
pub type PaidMediaPhoto {
  PaidMediaPhoto(
    /// Type of the paid media, always “photo”
    type_: String,
    /// The photo
    photo: List(PhotoSize),
  )
}

/// **Official reference:** The paid media is a video.
pub type PaidMediaVideo {
  PaidMediaVideo(
    /// Type of the paid media, always “video”
    type_: String,
    /// The video
    video: Video,
  )
}

/// **Official reference:** This object represents a phone contact.
pub type Contact {
  Contact(
    /// Contact's phone number
    phone_number: String,
    /// Contact's first name
    first_name: String,
    /// Optional. Contact's last name
    last_name: Option(String),
    /// Optional. Contact's user identifier in Telegram. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a 64-bit integer or double-precision float type are safe for storing this identifier.
    user_id: Option(Int),
    /// Optional. Additional data about the contact in the form of a vCard
    vcard: Option(String),
  )
}

/// **Official reference:** This object represents an animated emoji that displays a random value.
pub type Dice {
  Dice(
    /// Emoji on which the dice throw animation is based
    emoji: String,
    /// Value of the dice, 1-6 for “”, “” and “” base emoji, 1-5 for “” and “” base emoji, 1-64 for “” base emoji
    value: Int,
  )
}

/// **Official reference:** This object contains information about one answer option in a poll.
pub type PollOption {
  PollOption(
    /// Option text, 1-100 characters
    text: String,
    /// Optional. Special entities that appear in the option text. Currently, only custom emoji entities are allowed in poll option texts
    text_entities: Option(List(MessageEntity)),
    /// Number of users that voted for this option
    voter_count: Int,
  )
}

/// **Official reference:** This object contains information about one answer option in a poll to be sent.
pub type InputPollOption {
  InputPollOption(
    /// Option text, 1-100 characters
    text: String,
    /// Optional. Mode for parsing entities in the text. See formatting options for more details. Currently, only custom emoji entities are allowed
    text_parse_mode: Option(String),
    /// Optional. A JSON-serialized list of special entities that appear in the poll option text. It can be specified instead of text_parse_mode
    text_entities: Option(List(MessageEntity)),
  )
}

/// **Official reference:** This object represents an answer of a user in a non-anonymous poll.
pub type PollAnswer {
  PollAnswer(
    /// Unique poll identifier
    poll_id: String,
    /// Optional. The chat that changed the answer to the poll, if the voter is anonymous
    voter_chat: Option(Chat),
    /// Optional. The user that changed the answer to the poll, if the voter isn't anonymous
    user: Option(User),
    /// 0-based identifiers of chosen answer options. May be empty if the vote was retracted.
    option_ids: List(Int),
  )
}

/// **Official reference:** This object contains information about a poll.
pub type Poll {
  Poll(
    /// Unique poll identifier
    id: String,
    /// Poll question, 1-300 characters
    question: String,
    /// Optional. Special entities that appear in the question. Currently, only custom emoji entities are allowed in poll questions
    question_entities: Option(List(MessageEntity)),
    /// List of poll options
    options: List(PollOption),
    /// Total number of users that voted in the poll
    total_voter_count: Int,
    /// True, if the poll is closed
    is_closed: Bool,
    /// True, if the poll is anonymous
    is_anonymous: Bool,
    /// Poll type, currently can be “regular” or “quiz”
    type_: String,
    /// True, if the poll allows multiple answers
    allows_multiple_answers: Bool,
    /// Optional. 0-based identifier of the correct answer option. Available only for polls in the quiz mode, which are closed, or was sent (not forwarded) by the bot or to the private chat with the bot.
    correct_option_id: Option(Int),
    /// Optional. Text that is shown when a user chooses an incorrect answer or taps on the lamp icon in a quiz-style poll, 0-200 characters
    explanation: Option(String),
    /// Optional. Special entities like usernames, URLs, bot commands, etc. that appear in the explanation
    explanation_entities: Option(List(MessageEntity)),
    /// Optional. Amount of time in seconds the poll will be active after creation
    open_period: Option(Int),
    /// Optional. Point in time (Unix timestamp) when the poll will be automatically closed
    close_date: Option(Int),
  )
}

/// **Official reference:** This object represents a point on the map.
pub type Location {
  Location(
    /// Latitude as defined by the sender
    latitude: Float,
    /// Longitude as defined by the sender
    longitude: Float,
    /// Optional. The radius of uncertainty for the location, measured in meters; 0-1500
    horizontal_accuracy: Option(Float),
    /// Optional. Time relative to the message sending date, during which the location can be updated; in seconds. For active live locations only.
    live_period: Option(Int),
    /// Optional. The direction in which user is moving, in degrees; 1-360. For active live locations only.
    heading: Option(Int),
    /// Optional. The maximum distance for proximity alerts about approaching another chat member, in meters. For sent live locations only.
    proximity_alert_radius: Option(Int),
  )
}

/// **Official reference:** This object represents a venue.
pub type Venue {
  Venue(
    /// Venue location. Can't be a live location
    location: Location,
    /// Name of the venue
    title: String,
    /// Address of the venue
    address: String,
    /// Optional. Foursquare identifier of the venue
    foursquare_id: Option(String),
    /// Optional. Foursquare type of the venue. (For example, “arts_entertainment/default”, “arts_entertainment/aquarium” or “food/icecream”.)
    foursquare_type: Option(String),
    /// Optional. Google Places identifier of the venue
    google_place_id: Option(String),
    /// Optional. Google Places type of the venue. (See supported types.)
    google_place_type: Option(String),
  )
}

/// **Official reference:** Describes data sent from a Web App to the bot.
pub type WebAppData {
  WebAppData(
    /// The data. Be aware that a bad client can send arbitrary data in this field.
    data: String,
    /// Text of the web_app keyboard button from which the Web App was opened. Be aware that a bad client can send arbitrary data in this field.
    button_text: String,
  )
}

/// **Official reference:** This object represents the content of a service message, sent whenever a user in the chat triggers a proximity alert set by another user.
pub type ProximityAlertTriggered {
  ProximityAlertTriggered(
    /// User that triggered the alert
    traveler: User,
    /// User that set the alert
    watcher: User,
    /// The distance between the users
    distance: Int,
  )
}

/// **Official reference:** This object represents a service message about a change in auto-delete timer settings.
pub type MessageAutoDeleteTimerChanged {
  MessageAutoDeleteTimerChanged(
    /// New auto-delete time for messages in the chat; in seconds
    message_auto_delete_time: Int,
  )
}

/// **Official reference:** This object represents a service message about a user boosting a chat.
pub type ChatBoostAdded {
  ChatBoostAdded(
    /// Number of boosts added by the user
    boost_count: Int,
  )
}

/// **Official reference:** The background is filled using the selected color.
pub type BackgroundFillSolid {
  BackgroundFillSolid(
    /// Type of the background fill, always “solid”
    type_: String,
    /// The color of the background fill in the RGB24 format
    color: Int,
  )
}

/// **Official reference:** The background is a gradient fill.
pub type BackgroundFillGradient {
  BackgroundFillGradient(
    /// Type of the background fill, always “gradient”
    type_: String,
    /// Top color of the gradient in the RGB24 format
    top_color: Int,
    /// Bottom color of the gradient in the RGB24 format
    bottom_color: Int,
    /// Clockwise rotation angle of the background fill in degrees; 0-359
    rotation_angle: Int,
  )
}

/// **Official reference:** The background is a freeform gradient that rotates after every message in the chat.
pub type BackgroundFillFreeformGradient {
  BackgroundFillFreeformGradient(
    /// Type of the background fill, always “freeform_gradient”
    type_: String,
    /// A list of the 3 or 4 base colors that are used to generate the freeform gradient in the RGB24 format
    colors: List(Int),
  )
}

/// **Official reference:** The background is automatically filled based on the selected colors.
pub type BackgroundTypeFill {
  BackgroundTypeFill(
    /// Type of the background, always “fill”
    type_: String,
    /// The background fill
    fill: BackgroundFill,
    /// Dimming of the background in dark themes, as a percentage; 0-100
    dark_theme_dimming: Int,
  )
}

/// **Official reference:** The background is a wallpaper in the JPEG format.
pub type BackgroundTypeWallpaper {
  BackgroundTypeWallpaper(
    /// Type of the background, always “wallpaper”
    type_: String,
    /// Document with the wallpaper
    document: Document,
    /// Dimming of the background in dark themes, as a percentage; 0-100
    dark_theme_dimming: Int,
    /// Optional. True, if the wallpaper is downscaled to fit in a 450x450 square and then box-blurred with radius 12
    is_blurred: Option(Bool),
    /// Optional. True, if the background moves slightly when the device is tilted
    is_moving: Option(Bool),
  )
}

/// **Official reference:** The background is a .PNG or .TGV (gzipped subset of SVG with MIME type “application/x-tgwallpattern”) pattern to be combined with the background fill chosen by the user.
pub type BackgroundTypePattern {
  BackgroundTypePattern(
    /// Type of the background, always “pattern”
    type_: String,
    /// Document with the pattern
    document: Document,
    /// The background fill that is combined with the pattern
    fill: BackgroundFill,
    /// Intensity of the pattern when it is shown above the filled background; 0-100
    intensity: Int,
    /// Optional. True, if the background fill must be applied only to the pattern itself. All other pixels are black in this case. For dark themes only
    is_inverted: Option(Bool),
    /// Optional. True, if the background moves slightly when the device is tilted
    is_moving: Option(Bool),
  )
}

/// **Official reference:** The background is taken directly from a built-in chat theme.
pub type BackgroundTypeChatTheme {
  BackgroundTypeChatTheme(
    /// Type of the background, always “chat_theme”
    type_: String,
    /// Name of the chat theme, which is usually an emoji
    theme_name: String,
  )
}

/// **Official reference:** This object represents a chat background.
pub type ChatBackground {
  ChatBackground(
    /// Type of the background
    type_: BackgroundType,
  )
}

/// **Official reference:** This object represents a service message about a new forum topic created in the chat.
pub type ForumTopicCreated {
  ForumTopicCreated(
    /// Name of the topic
    name: String,
    /// Color of the topic icon in RGB format
    icon_color: Int,
    /// Optional. Unique identifier of the custom emoji shown as the topic icon
    icon_custom_emoji_id: Option(String),
  )
}

pub type ForumTopicClosed {
  ForumTopicClosed
}

/// **Official reference:** This object represents a service message about an edited forum topic.
pub type ForumTopicEdited {
  ForumTopicEdited(
    /// Optional. New name of the topic, if it was edited
    name: Option(String),
    /// Optional. New identifier of the custom emoji shown as the topic icon, if it was edited; an empty string if the icon was removed
    icon_custom_emoji_id: Option(String),
  )
}

pub type ForumTopicReopened {
  ForumTopicReopened
}

pub type GeneralForumTopicHidden {
  GeneralForumTopicHidden
}

pub type GeneralForumTopicUnhidden {
  GeneralForumTopicUnhidden
}

/// **Official reference:** This object contains information about a user that was shared with the bot using a KeyboardButtonRequestUsers button.
pub type SharedUser {
  SharedUser(
    /// Identifier of the shared user. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so 64-bit integers or double-precision float types are safe for storing these identifiers. The bot may not have access to the user and could be unable to use this identifier, unless the user is already known to the bot by some other means.
    user_id: Int,
    /// Optional. First name of the user, if the name was requested by the bot
    first_name: Option(String),
    /// Optional. Last name of the user, if the name was requested by the bot
    last_name: Option(String),
    /// Optional. Username of the user, if the username was requested by the bot
    username: Option(String),
    /// Optional. Available sizes of the chat photo, if the photo was requested by the bot
    photo: Option(List(PhotoSize)),
  )
}

/// **Official reference:** This object contains information about the users whose identifiers were shared with the bot using a KeyboardButtonRequestUsers button.
pub type UsersShared {
  UsersShared(
    /// Identifier of the request
    request_id: Int,
    /// Information about users shared with the bot.
    users: List(SharedUser),
  )
}

/// **Official reference:** This object contains information about a chat that was shared with the bot using a KeyboardButtonRequestChat button.
pub type ChatShared {
  ChatShared(
    /// Identifier of the request
    request_id: Int,
    /// Identifier of the shared chat. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a 64-bit integer or double-precision float type are safe for storing this identifier. The bot may not have access to the chat and could be unable to use this identifier, unless the chat is already known to the bot by some other means.
    chat_id: Int,
    /// Optional. Title of the chat, if the title was requested by the bot.
    title: Option(String),
    /// Optional. Username of the chat, if the username was requested by the bot and available.
    username: Option(String),
    /// Optional. Available sizes of the chat photo, if the photo was requested by the bot
    photo: Option(List(PhotoSize)),
  )
}

/// **Official reference:** This object represents a service message about a user allowing a bot to write messages after adding it to the attachment menu, launching a Web App from a link, or accepting an explicit request from a Web App sent by the method requestWriteAccess.
pub type WriteAccessAllowed {
  WriteAccessAllowed(
    /// Optional. True, if the access was granted after the user accepted an explicit request from a Web App sent by the method requestWriteAccess
    from_request: Option(Bool),
    /// Optional. Name of the Web App, if the access was granted when the Web App was launched from a link
    web_app_name: Option(String),
    /// Optional. True, if the access was granted when the bot was added to the attachment or side menu
    from_attachment_menu: Option(Bool),
  )
}

/// **Official reference:** This object represents a service message about a video chat scheduled in the chat.
pub type VideoChatScheduled {
  VideoChatScheduled(
    /// Point in time (Unix timestamp) when the video chat is supposed to be started by a chat administrator
    start_date: Int,
  )
}

pub type VideoChatStarted {
  VideoChatStarted
}

/// **Official reference:** This object represents a service message about a video chat ended in the chat.
pub type VideoChatEnded {
  VideoChatEnded(
    /// Video chat duration in seconds
    duration: Int,
  )
}

/// **Official reference:** This object represents a service message about new members invited to a video chat.
pub type VideoChatParticipantsInvited {
  VideoChatParticipantsInvited(
    /// New members that were invited to the video chat
    users: List(User),
  )
}

/// **Official reference:** This object represents a service message about the creation of a scheduled giveaway.
pub type GiveawayCreated {
  GiveawayCreated(
    /// Optional. The number of Telegram Stars to be split between giveaway winners; for Telegram Star giveaways only
    prize_star_count: Option(Int),
  )
}

/// **Official reference:** This object represents a message about a scheduled giveaway.
pub type Giveaway {
  Giveaway(
    /// The list of chats which the user must join to participate in the giveaway
    chats: List(Chat),
    /// Point in time (Unix timestamp) when winners of the giveaway will be selected
    winners_selection_date: Int,
    /// The number of users which are supposed to be selected as winners of the giveaway
    winner_count: Int,
    /// Optional. True, if only users who join the chats after the giveaway started should be eligible to win
    only_new_members: Option(Bool),
    /// Optional. True, if the list of giveaway winners will be visible to everyone
    has_public_winners: Option(Bool),
    /// Optional. Description of additional giveaway prize
    prize_description: Option(String),
    /// Optional. A list of two-letter ISO 3166-1 alpha-2 country codes indicating the countries from which eligible users for the giveaway must come. If empty, then all users can participate in the giveaway. Users with a phone number that was bought on Fragment can always participate in giveaways.
    country_codes: Option(List(String)),
    /// Optional. The number of Telegram Stars to be split between giveaway winners; for Telegram Star giveaways only
    prize_star_count: Option(Int),
    /// Optional. The number of months the Telegram Premium subscription won from the giveaway will be active for; for Telegram Premium giveaways only
    premium_subscription_month_count: Option(Int),
  )
}

/// **Official reference:** This object represents a message about the completion of a giveaway with public winners.
pub type GiveawayWinners {
  GiveawayWinners(
    /// The chat that created the giveaway
    chat: Chat,
    /// Identifier of the message with the giveaway in the chat
    giveaway_message_id: Int,
    /// Point in time (Unix timestamp) when winners of the giveaway were selected
    winners_selection_date: Int,
    /// Total number of winners in the giveaway
    winner_count: Int,
    /// List of up to 100 winners of the giveaway
    winners: List(User),
    /// Optional. The number of other chats the user had to join in order to be eligible for the giveaway
    additional_chat_count: Option(Int),
    /// Optional. The number of Telegram Stars that were split between giveaway winners; for Telegram Star giveaways only
    prize_star_count: Option(Int),
    /// Optional. The number of months the Telegram Premium subscription won from the giveaway will be active for; for Telegram Premium giveaways only
    premium_subscription_month_count: Option(Int),
    /// Optional. Number of undistributed prizes
    unclaimed_prize_count: Option(Int),
    /// Optional. True, if only users who had joined the chats after the giveaway started were eligible to win
    only_new_members: Option(Bool),
    /// Optional. True, if the giveaway was canceled because the payment for it was refunded
    was_refunded: Option(Bool),
    /// Optional. Description of additional giveaway prize
    prize_description: Option(String),
  )
}

/// **Official reference:** This object represents a service message about the completion of a giveaway without public winners.
pub type GiveawayCompleted {
  GiveawayCompleted(
    /// Number of winners in the giveaway
    winner_count: Int,
    /// Optional. Number of undistributed prizes
    unclaimed_prize_count: Option(Int),
    /// Optional. Message with the giveaway that was completed, if it wasn't deleted
    giveaway_message: Option(Message),
    /// Optional. True, if the giveaway is a Telegram Star giveaway. Otherwise, currently, the giveaway is a Telegram Premium giveaway.
    is_star_giveaway: Option(Bool),
  )
}

/// **Official reference:** Describes the options used for link preview generation.
pub type LinkPreviewOptions {
  LinkPreviewOptions(
    /// Optional. True, if the link preview is disabled
    is_disabled: Option(Bool),
    /// Optional. URL to use for the link preview. If empty, then the first URL found in the message text will be used
    url: Option(String),
    /// Optional. True, if the media in the link preview is supposed to be shrunk; ignored if the URL isn't explicitly specified or media size change isn't supported for the preview
    prefer_small_media: Option(Bool),
    /// Optional. True, if the media in the link preview is supposed to be enlarged; ignored if the URL isn't explicitly specified or media size change isn't supported for the preview
    prefer_large_media: Option(Bool),
    /// Optional. True, if the link preview must be shown above the message text; otherwise, the link preview will be shown below the message text
    show_above_text: Option(Bool),
  )
}

/// **Official reference:** This object represent a user's profile pictures.
pub type UserProfilePhotos {
  UserProfilePhotos(
    /// Total number of profile pictures the target user has
    total_count: Int,
    /// Requested profile pictures (in up to 4 sizes each)
    photos: List(List(PhotoSize)),
  )
}

/// **Official reference:** This object represents a file ready to be downloaded. The file can be downloaded via the link https://api.telegram.org/file/bot<token>/<file_path>. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile.
pub type File {
  File(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// Optional. File size in bytes. It can be bigger than 2^31 and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this value.
    file_size: Option(Int),
    /// Optional. File path. Use https://api.telegram.org/file/bot<token>/<file_path> to get the file.
    file_path: Option(String),
  )
}

/// **Official reference:** Describes a Web App.
pub type WebAppInfo {
  WebAppInfo(
    /// An HTTPS URL of a Web App to be opened with additional data as specified in Initializing Web Apps
    url: String,
  )
}

/// **Official reference:** This object represents a custom keyboard with reply options (see Introduction to bots for details and examples). Not supported in channels and for messages sent on behalf of a Telegram Business account.
pub type ReplyKeyboardMarkup {
  ReplyKeyboardMarkup(
    /// Array of button rows, each represented by an Array of KeyboardButton objects
    keyboard: List(List(KeyboardButton)),
    /// Optional. Requests clients to always show the keyboard when the regular keyboard is hidden. Defaults to false, in which case the custom keyboard can be hidden and opened with a keyboard icon.
    is_persistent: Option(Bool),
    /// Optional. Requests clients to resize the keyboard vertically for optimal fit (e.g., make the keyboard smaller if there are just two rows of buttons). Defaults to false, in which case the custom keyboard is always of the same height as the app's standard keyboard.
    resize_keyboard: Option(Bool),
    /// Optional. Requests clients to hide the keyboard as soon as it's been used. The keyboard will still be available, but clients will automatically display the usual letter-keyboard in the chat - the user can press a special button in the input field to see the custom keyboard again. Defaults to false.
    one_time_keyboard: Option(Bool),
    /// Optional. The placeholder to be shown in the input field when the keyboard is active; 1-64 characters
    input_field_placeholder: Option(String),
    /// Optional. Use this parameter if you want to show the keyboard to specific users only. Targets: 1) users that are @mentioned in the text of the Message object; 2) if the bot's message is a reply to a message in the same chat and forum topic, sender of the original message.
    ///
    /// Example: A user requests to change the bot's language, bot replies to the request with a keyboard to select the new language. Other users in the group don't see the keyboard.
    selective: Option(Bool),
  )
}

/// **Official reference:** This object represents one button of the reply keyboard. At most one of the optional fields must be used to specify type of the button. For simple text buttons, String can be used instead of this object to specify the button text.
pub type KeyboardButton {
  KeyboardButton(
    /// Text of the button. If none of the optional fields are used, it will be sent as a message when the button is pressed
    text: String,
    /// Optional. If specified, pressing the button will open a list of suitable users. Identifiers of selected users will be sent to the bot in a “users_shared” service message. Available in private chats only.
    request_users: Option(KeyboardButtonRequestUsers),
    /// Optional. If specified, pressing the button will open a list of suitable chats. Tapping on a chat will send its identifier to the bot in a “chat_shared” service message. Available in private chats only.
    request_chat: Option(KeyboardButtonRequestChat),
    /// Optional. If True, the user's phone number will be sent as a contact when the button is pressed. Available in private chats only.
    request_contact: Option(Bool),
    /// Optional. If True, the user's current location will be sent when the button is pressed. Available in private chats only.
    request_location: Option(Bool),
    /// Optional. If specified, the user will be asked to create a poll and send it to the bot when the button is pressed. Available in private chats only.
    request_poll: Option(KeyboardButtonPollType),
    /// Optional. If specified, the described Web App will be launched when the button is pressed. The Web App will be able to send a “web_app_data” service message. Available in private chats only.
    web_app: Option(WebAppInfo),
  )
}

/// **Official reference:** This object defines the criteria used to request suitable users. Information about the selected users will be shared with the bot when the corresponding button is pressed. More about requesting users »
pub type KeyboardButtonRequestUsers {
  KeyboardButtonRequestUsers(
    /// Signed 32-bit identifier of the request that will be received back in the UsersShared object. Must be unique within the message
    request_id: Int,
    /// Optional. Pass True to request bots, pass False to request regular users. If not specified, no additional restrictions are applied.
    user_is_bot: Option(Bool),
    /// Optional. Pass True to request premium users, pass False to request non-premium users. If not specified, no additional restrictions are applied.
    user_is_premium: Option(Bool),
    /// Optional. The maximum number of users to be selected; 1-10. Defaults to 1.
    max_quantity: Option(Int),
    /// Optional. Pass True to request the users' first and last names
    request_name: Option(Bool),
    /// Optional. Pass True to request the users' usernames
    request_username: Option(Bool),
    /// Optional. Pass True to request the users' photos
    request_photo: Option(Bool),
  )
}

/// **Official reference:** This object defines the criteria used to request a suitable chat. Information about the selected chat will be shared with the bot when the corresponding button is pressed. The bot will be granted requested rights in the chat if appropriate. More about requesting chats ».
pub type KeyboardButtonRequestChat {
  KeyboardButtonRequestChat(
    /// Signed 32-bit identifier of the request, which will be received back in the ChatShared object. Must be unique within the message
    request_id: Int,
    /// Pass True to request a channel chat, pass False to request a group or a supergroup chat.
    chat_is_channel: Bool,
    /// Optional. Pass True to request a forum supergroup, pass False to request a non-forum chat. If not specified, no additional restrictions are applied.
    chat_is_forum: Option(Bool),
    /// Optional. Pass True to request a supergroup or a channel with a username, pass False to request a chat without a username. If not specified, no additional restrictions are applied.
    chat_has_username: Option(Bool),
    /// Optional. Pass True to request a chat owned by the user. Otherwise, no additional restrictions are applied.
    chat_is_created: Option(Bool),
    /// Optional. A JSON-serialized object listing the required administrator rights of the user in the chat. The rights must be a superset of bot_administrator_rights. If not specified, no additional restrictions are applied.
    user_administrator_rights: Option(ChatAdministratorRights),
    /// Optional. A JSON-serialized object listing the required administrator rights of the bot in the chat. The rights must be a subset of user_administrator_rights. If not specified, no additional restrictions are applied.
    bot_administrator_rights: Option(ChatAdministratorRights),
    /// Optional. Pass True to request a chat with the bot as a member. Otherwise, no additional restrictions are applied.
    bot_is_member: Option(Bool),
    /// Optional. Pass True to request the chat's title
    request_title: Option(Bool),
    /// Optional. Pass True to request the chat's username
    request_username: Option(Bool),
    /// Optional. Pass True to request the chat's photo
    request_photo: Option(Bool),
  )
}

/// **Official reference:** This object represents type of a poll, which is allowed to be created and sent when the corresponding button is pressed.
pub type KeyboardButtonPollType {
  KeyboardButtonPollType(
    /// Optional. If quiz is passed, the user will be allowed to create only polls in the quiz mode. If regular is passed, only regular polls will be allowed. Otherwise, the user will be allowed to create a poll of any type.
    type_: Option(String),
  )
}

/// **Official reference:** Upon receiving a message with this object, Telegram clients will remove the current custom keyboard and display the default letter-keyboard. By default, custom keyboards are displayed until a new keyboard is sent by a bot. An exception is made for one-time keyboards that are hidden immediately after the user presses a button (see ReplyKeyboardMarkup). Not supported in channels and for messages sent on behalf of a Telegram Business account.
pub type ReplyKeyboardRemove {
  ReplyKeyboardRemove(
    /// Requests clients to remove the custom keyboard (user will not be able to summon this keyboard; if you want to hide the keyboard from sight but keep it accessible, use one_time_keyboard in ReplyKeyboardMarkup)
    remove_keyboard: Bool,
    /// Optional. Use this parameter if you want to remove the keyboard for specific users only. Targets: 1) users that are @mentioned in the text of the Message object; 2) if the bot's message is a reply to a message in the same chat and forum topic, sender of the original message.
    ///
    /// Example: A user votes in a poll, bot returns confirmation message in reply to the vote and removes the keyboard for that user, while still showing the keyboard with poll options to users who haven't voted yet.
    selective: Option(Bool),
  )
}

/// **Official reference:** This object represents an inline keyboard that appears right next to the message it belongs to.
pub type InlineKeyboardMarkup {
  InlineKeyboardMarkup(
    /// Array of button rows, each represented by an Array of InlineKeyboardButton objects
    inline_keyboard: List(List(InlineKeyboardButton)),
  )
}

/// **Official reference:** This object represents one button of an inline keyboard. Exactly one of the optional fields must be used to specify type of the button.
pub type InlineKeyboardButton {
  InlineKeyboardButton(
    /// Label text on the button
    text: String,
    /// Optional. HTTP or tg:// URL to be opened when the button is pressed. Links tg://user?id=<user_id> can be used to mention a user by their identifier without using a username, if this is allowed by their privacy settings.
    url: Option(String),
    /// Optional. Data to be sent in a callback query to the bot when the button is pressed, 1-64 bytes
    callback_data: Option(String),
    /// Optional. Description of the Web App that will be launched when the user presses the button. The Web App will be able to send an arbitrary message on behalf of the user using the method answerWebAppQuery. Available only in private chats between a user and the bot. Not supported for messages sent on behalf of a Telegram Business account.
    web_app: Option(WebAppInfo),
    /// Optional. An HTTPS URL used to automatically authorize the user. Can be used as a replacement for the Telegram Login Widget.
    login_url: Option(LoginUrl),
    /// Optional. If set, pressing the button will prompt the user to select one of their chats, open that chat and insert the bot's username and the specified inline query in the input field. May be empty, in which case just the bot's username will be inserted. Not supported for messages sent on behalf of a Telegram Business account.
    switch_inline_query: Option(String),
    /// Optional. If set, pressing the button will insert the bot's username and the specified inline query in the current chat's input field. May be empty, in which case only the bot's username will be inserted.
    ///
    /// This offers a quick way for the user to open your bot in inline mode in the same chat - good for selecting something from multiple options. Not supported in channels and for messages sent on behalf of a Telegram Business account.
    switch_inline_query_current_chat: Option(String),
    /// Optional. If set, pressing the button will prompt the user to select one of their chats of the specified type, open that chat and insert the bot's username and the specified inline query in the input field. Not supported for messages sent on behalf of a Telegram Business account.
    switch_inline_query_chosen_chat: Option(SwitchInlineQueryChosenChat),
    /// Optional. Description of the button that copies the specified text to the clipboard.
    copy_text: Option(CopyTextButton),
    /// Optional. Description of the game that will be launched when the user presses the button.
    ///
    /// NOTE: This type of button must always be the first button in the first row.
    callback_game: Option(CallbackGame),
    /// Optional. Specify True, to send a Pay button. Substrings “” and “XTR” in the buttons's text will be replaced with a Telegram Star icon.
    ///
    /// NOTE: This type of button must always be the first button in the first row and can only be used in invoice messages.
    pay: Option(Bool),
  )
}

/// **Official reference:** This object represents a parameter of the inline keyboard button used to automatically authorize a user. Serves as a great replacement for the Telegram Login Widget when the user is coming from Telegram. All the user needs to do is tap/click a button and confirm that they want to log in:
pub type LoginUrl {
  LoginUrl(
    /// An HTTPS URL to be opened with user authorization data added to the query string when the button is pressed. If the user refuses to provide authorization data, the original URL without information about the user will be opened. The data added is the same as described in Receiving authorization data.
    ///
    /// NOTE: You must always check the hash of the received data to verify the authentication and the integrity of the data as described in Checking authorization.
    url: String,
    /// Optional. New text of the button in forwarded messages.
    forward_text: Option(String),
    /// Optional. Username of a bot, which will be used for user authorization. See Setting up a bot for more details. If not specified, the current bot's username will be assumed. The url's domain must be the same as the domain linked with the bot. See Linking your domain to the bot for more details.
    bot_username: Option(String),
    /// Optional. Pass True to request the permission for your bot to send messages to the user.
    request_write_access: Option(Bool),
  )
}

/// **Official reference:** This object represents an inline button that switches the current user to inline mode in a chosen chat, with an optional default inline query.
pub type SwitchInlineQueryChosenChat {
  SwitchInlineQueryChosenChat(
    /// Optional. The default inline query to be inserted in the input field. If left empty, only the bot's username will be inserted
    query: Option(String),
    /// Optional. True, if private chats with users can be chosen
    allow_user_chats: Option(Bool),
    /// Optional. True, if private chats with bots can be chosen
    allow_bot_chats: Option(Bool),
    /// Optional. True, if group and supergroup chats can be chosen
    allow_group_chats: Option(Bool),
    /// Optional. True, if channel chats can be chosen
    allow_channel_chats: Option(Bool),
  )
}

/// **Official reference:** This object represents an inline keyboard button that copies specified text to the clipboard.
pub type CopyTextButton {
  CopyTextButton(
    /// The text to be copied to the clipboard; 1-256 characters
    text: String,
  )
}

/// **Official reference:** This object represents an incoming callback query from a callback button in an inline keyboard. If the button that originated the query was attached to a message sent by the bot, the field message will be present. If the button was attached to a message sent via the bot (in inline mode), the field inline_message_id will be present. Exactly one of the fields data or game_short_name will be present.
pub type CallbackQuery {
  CallbackQuery(
    /// Unique identifier for this query
    id: String,
    /// Sender
    from: User,
    /// Optional. Message sent by the bot with the callback button that originated the query
    message: Option(MaybeInaccessibleMessage),
    /// Optional. Identifier of the message sent via the bot in inline mode, that originated the query.
    inline_message_id: Option(String),
    /// Global identifier, uniquely corresponding to the chat to which the message with the callback button was sent. Useful for high scores in games.
    chat_instance: String,
    /// Optional. Data associated with the callback button. Be aware that the message originated the query can contain no callback buttons with this data.
    data: Option(String),
    /// Optional. Short name of a Game to be returned, serves as the unique identifier for the game
    game_short_name: Option(String),
  )
}

/// **Official reference:** Upon receiving a message with this object, Telegram clients will display a reply interface to the user (act as if the user has selected the bot's message and tapped 'Reply'). This can be extremely useful if you want to create user-friendly step-by-step interfaces without having to sacrifice privacy mode. Not supported in channels and for messages sent on behalf of a Telegram Business account.
pub type ForceReply {
  ForceReply(
    /// Shows reply interface to the user, as if they manually selected the bot's message and tapped 'Reply'
    force_reply: Bool,
    /// Optional. The placeholder to be shown in the input field when the reply is active; 1-64 characters
    input_field_placeholder: Option(String),
    /// Optional. Use this parameter if you want to force reply from specific users only. Targets: 1) users that are @mentioned in the text of the Message object; 2) if the bot's message is a reply to a message in the same chat and forum topic, sender of the original message.
    selective: Option(Bool),
  )
}

/// **Official reference:** This object represents a chat photo.
pub type ChatPhoto {
  ChatPhoto(
    /// File identifier of small (160x160) chat photo. This file_id can be used only for photo download and only for as long as the photo is not changed.
    small_file_id: String,
    /// Unique file identifier of small (160x160) chat photo, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    small_file_unique_id: String,
    /// File identifier of big (640x640) chat photo. This file_id can be used only for photo download and only for as long as the photo is not changed.
    big_file_id: String,
    /// Unique file identifier of big (640x640) chat photo, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    big_file_unique_id: String,
  )
}

/// **Official reference:** Represents an invite link for a chat.
pub type ChatInviteLink {
  ChatInviteLink(
    /// The invite link. If the link was created by another chat administrator, then the second part of the link will be replaced with “…”.
    invite_link: String,
    /// Creator of the link
    creator: User,
    /// True, if users joining the chat via the link need to be approved by chat administrators
    creates_join_request: Bool,
    /// True, if the link is primary
    is_primary: Bool,
    /// True, if the link is revoked
    is_revoked: Bool,
    /// Optional. Invite link name
    name: Option(String),
    /// Optional. Point in time (Unix timestamp) when the link will expire or has been expired
    expire_date: Option(Int),
    /// Optional. The maximum number of users that can be members of the chat simultaneously after joining the chat via this invite link; 1-99999
    member_limit: Option(Int),
    /// Optional. Number of pending join requests created using this link
    pending_join_request_count: Option(Int),
    /// Optional. The number of seconds the subscription will be active for before the next payment
    subscription_period: Option(Int),
    /// Optional. The amount of Telegram Stars a user must pay initially and after each subsequent subscription period to be a member of the chat using the link
    subscription_price: Option(Int),
  )
}

/// **Official reference:** Represents the rights of an administrator in a chat.
pub type ChatAdministratorRights {
  ChatAdministratorRights(
    /// True, if the user's presence in the chat is hidden
    is_anonymous: Bool,
    /// True, if the administrator can access the chat event log, get boost list, see hidden supergroup and channel members, report spam messages and ignore slow mode. Implied by any other administrator privilege.
    can_manage_chat: Bool,
    /// True, if the administrator can delete messages of other users
    can_delete_messages: Bool,
    /// True, if the administrator can manage video chats
    can_manage_video_chats: Bool,
    /// True, if the administrator can restrict, ban or unban chat members, or access supergroup statistics
    can_restrict_members: Bool,
    /// True, if the administrator can add new administrators with a subset of their own privileges or demote administrators that they have promoted, directly or indirectly (promoted by administrators that were appointed by the user)
    can_promote_members: Bool,
    /// True, if the user is allowed to change the chat title, photo and other settings
    can_change_info: Bool,
    /// True, if the user is allowed to invite new users to the chat
    can_invite_users: Bool,
    /// True, if the administrator can post stories to the chat
    can_post_stories: Bool,
    /// True, if the administrator can edit stories posted by other users, post stories to the chat page, pin chat stories, and access the chat's story archive
    can_edit_stories: Bool,
    /// True, if the administrator can delete stories posted by other users
    can_delete_stories: Bool,
    /// Optional. True, if the administrator can post messages in the channel, or access channel statistics; for channels only
    can_post_messages: Option(Bool),
    /// Optional. True, if the administrator can edit messages of other users and can pin messages; for channels only
    can_edit_messages: Option(Bool),
    /// Optional. True, if the user is allowed to pin messages; for groups and supergroups only
    can_pin_messages: Option(Bool),
    /// Optional. True, if the user is allowed to create, rename, close, and reopen forum topics; for supergroups only
    can_manage_topics: Option(Bool),
  )
}

/// **Official reference:** This object represents changes in the status of a chat member.
pub type ChatMemberUpdated {
  ChatMemberUpdated(
    /// Chat the user belongs to
    chat: Chat,
    /// Performer of the action, which resulted in the change
    from: User,
    /// Date the change was done in Unix time
    date: Int,
    /// Previous information about the chat member
    old_chat_member: ChatMember,
    /// New information about the chat member
    new_chat_member: ChatMember,
    /// Optional. Chat invite link, which was used by the user to join the chat; for joining by invite link events only.
    invite_link: Option(ChatInviteLink),
    /// Optional. True, if the user joined the chat after sending a direct join request without using an invite link and being approved by an administrator
    via_join_request: Option(Bool),
    /// Optional. True, if the user joined the chat via a chat folder invite link
    via_chat_folder_invite_link: Option(Bool),
  )
}

/// **Official reference:** Represents a chat member that owns the chat and has all administrator privileges.
pub type ChatMemberOwner {
  ChatMemberOwner(
    /// The member's status in the chat, always “creator”
    status: String,
    /// Information about the user
    user: User,
    /// True, if the user's presence in the chat is hidden
    is_anonymous: Bool,
    /// Optional. Custom title for this user
    custom_title: Option(String),
  )
}

/// **Official reference:** Represents a chat member that has some additional privileges.
pub type ChatMemberAdministrator {
  ChatMemberAdministrator(
    /// The member's status in the chat, always “administrator”
    status: String,
    /// Information about the user
    user: User,
    /// True, if the bot is allowed to edit administrator privileges of that user
    can_be_edited: Bool,
    /// True, if the user's presence in the chat is hidden
    is_anonymous: Bool,
    /// True, if the administrator can access the chat event log, get boost list, see hidden supergroup and channel members, report spam messages and ignore slow mode. Implied by any other administrator privilege.
    can_manage_chat: Bool,
    /// True, if the administrator can delete messages of other users
    can_delete_messages: Bool,
    /// True, if the administrator can manage video chats
    can_manage_video_chats: Bool,
    /// True, if the administrator can restrict, ban or unban chat members, or access supergroup statistics
    can_restrict_members: Bool,
    /// True, if the administrator can add new administrators with a subset of their own privileges or demote administrators that they have promoted, directly or indirectly (promoted by administrators that were appointed by the user)
    can_promote_members: Bool,
    /// True, if the user is allowed to change the chat title, photo and other settings
    can_change_info: Bool,
    /// True, if the user is allowed to invite new users to the chat
    can_invite_users: Bool,
    /// True, if the administrator can post stories to the chat
    can_post_stories: Bool,
    /// True, if the administrator can edit stories posted by other users, post stories to the chat page, pin chat stories, and access the chat's story archive
    can_edit_stories: Bool,
    /// True, if the administrator can delete stories posted by other users
    can_delete_stories: Bool,
    /// Optional. True, if the administrator can post messages in the channel, or access channel statistics; for channels only
    can_post_messages: Option(Bool),
    /// Optional. True, if the administrator can edit messages of other users and can pin messages; for channels only
    can_edit_messages: Option(Bool),
    /// Optional. True, if the user is allowed to pin messages; for groups and supergroups only
    can_pin_messages: Option(Bool),
    /// Optional. True, if the user is allowed to create, rename, close, and reopen forum topics; for supergroups only
    can_manage_topics: Option(Bool),
    /// Optional. Custom title for this user
    custom_title: Option(String),
  )
}

/// **Official reference:** Represents a chat member that has no additional privileges or restrictions.
pub type ChatMemberMember {
  ChatMemberMember(
    /// The member's status in the chat, always “member”
    status: String,
    /// Information about the user
    user: User,
    /// Optional. Date when the user's subscription will expire; Unix time
    until_date: Option(Int),
  )
}

/// **Official reference:** Represents a chat member that is under certain restrictions in the chat. Supergroups only.
pub type ChatMemberRestricted {
  ChatMemberRestricted(
    /// The member's status in the chat, always “restricted”
    status: String,
    /// Information about the user
    user: User,
    /// True, if the user is a member of the chat at the moment of the request
    is_member: Bool,
    /// True, if the user is allowed to send text messages, contacts, giveaways, giveaway winners, invoices, locations and venues
    can_send_messages: Bool,
    /// True, if the user is allowed to send audios
    can_send_audios: Bool,
    /// True, if the user is allowed to send documents
    can_send_documents: Bool,
    /// True, if the user is allowed to send photos
    can_send_photos: Bool,
    /// True, if the user is allowed to send videos
    can_send_videos: Bool,
    /// True, if the user is allowed to send video notes
    can_send_video_notes: Bool,
    /// True, if the user is allowed to send voice notes
    can_send_voice_notes: Bool,
    /// True, if the user is allowed to send polls
    can_send_polls: Bool,
    /// True, if the user is allowed to send animations, games, stickers and use inline bots
    can_send_other_messages: Bool,
    /// True, if the user is allowed to add web page previews to their messages
    can_add_web_page_previews: Bool,
    /// True, if the user is allowed to change the chat title, photo and other settings
    can_change_info: Bool,
    /// True, if the user is allowed to invite new users to the chat
    can_invite_users: Bool,
    /// True, if the user is allowed to pin messages
    can_pin_messages: Bool,
    /// True, if the user is allowed to create forum topics
    can_manage_topics: Bool,
    /// Date when restrictions will be lifted for this user; Unix time. If 0, then the user is restricted forever
    until_date: Int,
  )
}

/// **Official reference:** Represents a chat member that isn't currently a member of the chat, but may join it themselves.
pub type ChatMemberLeft {
  ChatMemberLeft(
    /// The member's status in the chat, always “left”
    status: String,
    /// Information about the user
    user: User,
  )
}

/// **Official reference:** Represents a chat member that was banned in the chat and can't return to the chat or view chat messages.
pub type ChatMemberBanned {
  ChatMemberBanned(
    /// The member's status in the chat, always “kicked”
    status: String,
    /// Information about the user
    user: User,
    /// Date when restrictions will be lifted for this user; Unix time. If 0, then the user is banned forever
    until_date: Int,
  )
}

/// **Official reference:** Represents a join request sent to a chat.
pub type ChatJoinRequest {
  ChatJoinRequest(
    /// Chat to which the request was sent
    chat: Chat,
    /// User that sent the join request
    from: User,
    /// Identifier of a private chat with the user who sent the join request. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a 64-bit integer or double-precision float type are safe for storing this identifier. The bot can use this identifier for 5 minutes to send messages until the join request is processed, assuming no other administrator contacted the user.
    user_chat_id: Int,
    /// Date the request was sent in Unix time
    date: Int,
    /// Optional. Bio of the user.
    bio: Option(String),
    /// Optional. Chat invite link that was used by the user to send the join request
    invite_link: Option(ChatInviteLink),
  )
}

/// **Official reference:** Describes actions that a non-administrator user is allowed to take in a chat.
pub type ChatPermissions {
  ChatPermissions(
    /// Optional. True, if the user is allowed to send text messages, contacts, giveaways, giveaway winners, invoices, locations and venues
    can_send_messages: Option(Bool),
    /// Optional. True, if the user is allowed to send audios
    can_send_audios: Option(Bool),
    /// Optional. True, if the user is allowed to send documents
    can_send_documents: Option(Bool),
    /// Optional. True, if the user is allowed to send photos
    can_send_photos: Option(Bool),
    /// Optional. True, if the user is allowed to send videos
    can_send_videos: Option(Bool),
    /// Optional. True, if the user is allowed to send video notes
    can_send_video_notes: Option(Bool),
    /// Optional. True, if the user is allowed to send voice notes
    can_send_voice_notes: Option(Bool),
    /// Optional. True, if the user is allowed to send polls
    can_send_polls: Option(Bool),
    /// Optional. True, if the user is allowed to send animations, games, stickers and use inline bots
    can_send_other_messages: Option(Bool),
    /// Optional. True, if the user is allowed to add web page previews to their messages
    can_add_web_page_previews: Option(Bool),
    /// Optional. True, if the user is allowed to change the chat title, photo and other settings. Ignored in public supergroups
    can_change_info: Option(Bool),
    /// Optional. True, if the user is allowed to invite new users to the chat
    can_invite_users: Option(Bool),
    /// Optional. True, if the user is allowed to pin messages. Ignored in public supergroups
    can_pin_messages: Option(Bool),
    /// Optional. True, if the user is allowed to create forum topics. If omitted defaults to the value of can_pin_messages
    can_manage_topics: Option(Bool),
  )
}

/// **Official reference:** Describes the birthdate of a user.
pub type Birthdate {
  Birthdate(
    /// Day of the user's birth; 1-31
    day: Int,
    /// Month of the user's birth; 1-12
    month: Int,
    /// Optional. Year of the user's birth
    year: Option(Int),
  )
}

/// **Official reference:** Contains information about the start page settings of a Telegram Business account.
pub type BusinessIntro {
  BusinessIntro(
    /// Optional. Title text of the business intro
    title: Option(String),
    /// Optional. Message text of the business intro
    message: Option(String),
    /// Optional. Sticker of the business intro
    sticker: Option(Sticker),
  )
}

/// **Official reference:** Contains information about the location of a Telegram Business account.
pub type BusinessLocation {
  BusinessLocation(
    /// Address of the business
    address: String,
    /// Optional. Location of the business
    location: Option(Location),
  )
}

/// **Official reference:** Describes an interval of time during which a business is open.
pub type BusinessOpeningHoursInterval {
  BusinessOpeningHoursInterval(
    /// The minute's sequence number in a week, starting on Monday, marking the start of the time interval during which the business is open; 0 - 7 * 24 * 60
    opening_minute: Int,
    /// The minute's sequence number in a week, starting on Monday, marking the end of the time interval during which the business is open; 0 - 8 * 24 * 60
    closing_minute: Int,
  )
}

/// **Official reference:** Describes the opening hours of a business.
pub type BusinessOpeningHours {
  BusinessOpeningHours(
    /// Unique name of the time zone for which the opening hours are defined
    time_zone_name: String,
    /// List of time intervals describing business opening hours
    opening_hours: List(BusinessOpeningHoursInterval),
  )
}

/// **Official reference:** Represents a location to which a chat is connected.
pub type ChatLocation {
  ChatLocation(
    /// The location to which the supergroup is connected. Can't be a live location.
    location: Location,
    /// Location address; 1-64 characters, as defined by the chat owner
    address: String,
  )
}

/// **Official reference:** The reaction is based on an emoji.
pub type ReactionTypeEmoji {
  ReactionTypeEmoji(
    /// Type of the reaction, always “emoji”
    type_: String,
    /// Reaction emoji. Currently, it can be one of "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""
    emoji: String,
  )
}

/// **Official reference:** The reaction is based on a custom emoji.
pub type ReactionTypeCustomEmoji {
  ReactionTypeCustomEmoji(
    /// Type of the reaction, always “custom_emoji”
    type_: String,
    /// Custom emoji identifier
    custom_emoji_id: String,
  )
}

/// **Official reference:** The reaction is paid.
pub type ReactionTypePaid {
  ReactionTypePaid(
    /// Type of the reaction, always “paid”
    type_: String,
  )
}

/// **Official reference:** Represents a reaction added to a message along with the number of times it was added.
pub type ReactionCount {
  ReactionCount(
    /// Type of the reaction
    type_: ReactionType,
    /// Number of times the reaction was added
    total_count: Int,
  )
}

/// **Official reference:** This object represents a change of a reaction on a message performed by a user.
pub type MessageReactionUpdated {
  MessageReactionUpdated(
    /// The chat containing the message the user reacted to
    chat: Chat,
    /// Unique identifier of the message inside the chat
    message_id: Int,
    /// Optional. The user that changed the reaction, if the user isn't anonymous
    user: Option(User),
    /// Optional. The chat on behalf of which the reaction was changed, if the user is anonymous
    actor_chat: Option(Chat),
    /// Date of the change in Unix time
    date: Int,
    /// Previous list of reaction types that were set by the user
    old_reaction: List(ReactionType),
    /// New list of reaction types that have been set by the user
    new_reaction: List(ReactionType),
  )
}

/// **Official reference:** This object represents reaction changes on a message with anonymous reactions.
pub type MessageReactionCountUpdated {
  MessageReactionCountUpdated(
    /// The chat containing the message
    chat: Chat,
    /// Unique message identifier inside the chat
    message_id: Int,
    /// Date of the change in Unix time
    date: Int,
    /// List of reactions that are present on the message
    reactions: List(ReactionCount),
  )
}

/// **Official reference:** This object represents a forum topic.
pub type ForumTopic {
  ForumTopic(
    /// Unique identifier of the forum topic
    message_thread_id: Int,
    /// Name of the topic
    name: String,
    /// Color of the topic icon in RGB format
    icon_color: Int,
    /// Optional. Unique identifier of the custom emoji shown as the topic icon
    icon_custom_emoji_id: Option(String),
  )
}

/// **Official reference:** This object represents a bot command.
pub type BotCommand {
  BotCommand(
    /// Text of the command; 1-32 characters. Can contain only lowercase English letters, digits and underscores.
    command: String,
    /// Description of the command; 1-256 characters.
    description: String,
  )
}

/// **Official reference:** Represents the default scope of bot commands. Default commands are used if no commands with a narrower scope are specified for the user.
pub type BotCommandScopeDefault {
  BotCommandScopeDefault(
    /// Scope type, must be default
    type_: String,
  )
}

/// **Official reference:** Represents the scope of bot commands, covering all private chats.
pub type BotCommandScopeAllPrivateChats {
  BotCommandScopeAllPrivateChats(
    /// Scope type, must be all_private_chats
    type_: String,
  )
}

/// **Official reference:** Represents the scope of bot commands, covering all group and supergroup chats.
pub type BotCommandScopeAllGroupChats {
  BotCommandScopeAllGroupChats(
    /// Scope type, must be all_group_chats
    type_: String,
  )
}

/// **Official reference:** Represents the scope of bot commands, covering all group and supergroup chat administrators.
pub type BotCommandScopeAllChatAdministrators {
  BotCommandScopeAllChatAdministrators(
    /// Scope type, must be all_chat_administrators
    type_: String,
  )
}

/// **Official reference:** Represents the scope of bot commands, covering a specific chat.
pub type BotCommandScopeChat {
  BotCommandScopeChat(
    /// Scope type, must be chat
    type_: String,
    /// Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
    chat_id: IntOrString,
  )
}

/// **Official reference:** Represents the scope of bot commands, covering all administrators of a specific group or supergroup chat.
pub type BotCommandScopeChatAdministrators {
  BotCommandScopeChatAdministrators(
    /// Scope type, must be chat_administrators
    type_: String,
    /// Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
    chat_id: IntOrString,
  )
}

/// **Official reference:** Represents the scope of bot commands, covering a specific member of a group or supergroup chat.
pub type BotCommandScopeChatMember {
  BotCommandScopeChatMember(
    /// Scope type, must be chat_member
    type_: String,
    /// Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
  )
}

/// **Official reference:** This object represents the bot's name.
pub type BotName {
  BotName(
    /// The bot's name
    name: String,
  )
}

/// **Official reference:** This object represents the bot's description.
pub type BotDescription {
  BotDescription(
    /// The bot's description
    description: String,
  )
}

/// **Official reference:** This object represents the bot's short description.
pub type BotShortDescription {
  BotShortDescription(
    /// The bot's short description
    short_description: String,
  )
}

/// **Official reference:** Represents a menu button, which opens the bot's list of commands.
pub type MenuButtonCommands {
  MenuButtonCommands(
    /// Type of the button, must be commands
    type_: String,
  )
}

/// **Official reference:** Represents a menu button, which launches a Web App.
pub type MenuButtonWebApp {
  MenuButtonWebApp(
    /// Type of the button, must be web_app
    type_: String,
    /// Text on the button
    text: String,
    /// Description of the Web App that will be launched when the user presses the button. The Web App will be able to send an arbitrary message on behalf of the user using the method answerWebAppQuery. Alternatively, a t.me link to a Web App of the bot can be specified in the object instead of the Web App's URL, in which case the Web App will be opened as if the user pressed the link.
    web_app: WebAppInfo,
  )
}

/// **Official reference:** Describes that no specific value for the menu button was set.
pub type MenuButtonDefault {
  MenuButtonDefault(
    /// Type of the button, must be default
    type_: String,
  )
}

/// **Official reference:** The boost was obtained by subscribing to Telegram Premium or by gifting a Telegram Premium subscription to another user.
pub type ChatBoostSourcePremium {
  ChatBoostSourcePremium(
    /// Source of the boost, always “premium”
    source: String,
    /// User that boosted the chat
    user: User,
  )
}

/// **Official reference:** The boost was obtained by the creation of Telegram Premium gift codes to boost a chat. Each such code boosts the chat 4 times for the duration of the corresponding Telegram Premium subscription.
pub type ChatBoostSourceGiftCode {
  ChatBoostSourceGiftCode(
    /// Source of the boost, always “gift_code”
    source: String,
    /// User for which the gift code was created
    user: User,
  )
}

/// **Official reference:** The boost was obtained by the creation of a Telegram Premium or a Telegram Star giveaway. This boosts the chat 4 times for the duration of the corresponding Telegram Premium subscription for Telegram Premium giveaways and prize_star_count / 500 times for one year for Telegram Star giveaways.
pub type ChatBoostSourceGiveaway {
  ChatBoostSourceGiveaway(
    /// Source of the boost, always “giveaway”
    source: String,
    /// Identifier of a message in the chat with the giveaway; the message could have been deleted already. May be 0 if the message isn't sent yet.
    giveaway_message_id: Int,
    /// Optional. User that won the prize in the giveaway if any; for Telegram Premium giveaways only
    user: Option(User),
    /// Optional. The number of Telegram Stars to be split between giveaway winners; for Telegram Star giveaways only
    prize_star_count: Option(Int),
    /// Optional. True, if the giveaway was completed, but there was no user to win the prize
    is_unclaimed: Option(Bool),
  )
}

/// **Official reference:** This object contains information about a chat boost.
pub type ChatBoost {
  ChatBoost(
    /// Unique identifier of the boost
    boost_id: String,
    /// Point in time (Unix timestamp) when the chat was boosted
    add_date: Int,
    /// Point in time (Unix timestamp) when the boost will automatically expire, unless the booster's Telegram Premium subscription is prolonged
    expiration_date: Int,
    /// Source of the added boost
    source: ChatBoostSource,
  )
}

/// **Official reference:** This object represents a boost added to a chat or changed.
pub type ChatBoostUpdated {
  ChatBoostUpdated(
    /// Chat which was boosted
    chat: Chat,
    /// Information about the chat boost
    boost: ChatBoost,
  )
}

/// **Official reference:** This object represents a boost removed from a chat.
pub type ChatBoostRemoved {
  ChatBoostRemoved(
    /// Chat which was boosted
    chat: Chat,
    /// Unique identifier of the boost
    boost_id: String,
    /// Point in time (Unix timestamp) when the boost was removed
    remove_date: Int,
    /// Source of the removed boost
    source: ChatBoostSource,
  )
}

/// **Official reference:** This object represents a list of boosts added to a chat by a user.
pub type UserChatBoosts {
  UserChatBoosts(
    /// The list of boosts added to the chat by the user
    boosts: List(ChatBoost),
  )
}

/// **Official reference:** Describes the connection of the bot with a business account.
pub type BusinessConnection {
  BusinessConnection(
    /// Unique identifier of the business connection
    id: String,
    /// Business account user that created the business connection
    user: User,
    /// Identifier of a private chat with the user who created the business connection. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a 64-bit integer or double-precision float type are safe for storing this identifier.
    user_chat_id: Int,
    /// Date the connection was established in Unix time
    date: Int,
    /// True, if the bot can act on behalf of the business account in chats that were active in the last 24 hours
    can_reply: Bool,
    /// True, if the connection is active
    is_enabled: Bool,
  )
}

/// **Official reference:** This object is received when messages are deleted from a connected business account.
pub type BusinessMessagesDeleted {
  BusinessMessagesDeleted(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Information about a chat in the business account. The bot may not have access to the chat or the corresponding user.
    chat: Chat,
    /// The list of identifiers of deleted messages in the chat of the business account
    message_ids: List(Int),
  )
}

/// **Official reference:** Describes why a request was unsuccessful.
pub type ResponseParameters {
  ResponseParameters(
    /// Optional. The group has been migrated to a supergroup with the specified identifier. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a signed 64-bit integer or double-precision float type are safe for storing this identifier.
    migrate_to_chat_id: Option(Int),
    /// Optional. In case of exceeding flood control, the number of seconds left to wait before the request can be repeated
    retry_after: Option(Int),
  )
}

/// **Official reference:** Represents a photo to be sent.
pub type InputMediaPhoto {
  InputMediaPhoto(
    /// Type of the result, must be photo
    type_: String,
    /// File to send. Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass “attach://<file_attach_name>” to upload a new one using multipart/form-data under <file_attach_name> name. More information on Sending Files »
    media: String,
    /// Optional. Caption of the photo to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the photo caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Pass True if the photo needs to be covered with a spoiler animation
    has_spoiler: Option(Bool),
  )
}

/// **Official reference:** Represents a video to be sent.
pub type InputMediaVideo {
  InputMediaVideo(
    /// Type of the result, must be video
    type_: String,
    /// File to send. Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass “attach://<file_attach_name>” to upload a new one using multipart/form-data under <file_attach_name> name. More information on Sending Files »
    media: String,
    /// Optional. Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. More information on Sending Files »
    thumbnail: Option(String),
    /// Optional. Cover for the video in the message. Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass “attach://<file_attach_name>” to upload a new one using multipart/form-data under <file_attach_name> name. More information on Sending Files »
    cover: Option(String),
    /// Optional. Start timestamp for the video in the message
    start_timestamp: Option(Int),
    /// Optional. Caption of the video to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the video caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Video width
    width: Option(Int),
    /// Optional. Video height
    height: Option(Int),
    /// Optional. Video duration in seconds
    duration: Option(Int),
    /// Optional. Pass True if the uploaded video is suitable for streaming
    supports_streaming: Option(Bool),
    /// Optional. Pass True if the video needs to be covered with a spoiler animation
    has_spoiler: Option(Bool),
  )
}

/// **Official reference:** Represents an animation file (GIF or H.264/MPEG-4 AVC video without sound) to be sent.
pub type InputMediaAnimation {
  InputMediaAnimation(
    /// Type of the result, must be animation
    type_: String,
    /// File to send. Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass “attach://<file_attach_name>” to upload a new one using multipart/form-data under <file_attach_name> name. More information on Sending Files »
    media: String,
    /// Optional. Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. More information on Sending Files »
    thumbnail: Option(String),
    /// Optional. Caption of the animation to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the animation caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Animation width
    width: Option(Int),
    /// Optional. Animation height
    height: Option(Int),
    /// Optional. Animation duration in seconds
    duration: Option(Int),
    /// Optional. Pass True if the animation needs to be covered with a spoiler animation
    has_spoiler: Option(Bool),
  )
}

/// **Official reference:** Represents an audio file to be treated as music to be sent.
pub type InputMediaAudio {
  InputMediaAudio(
    /// Type of the result, must be audio
    type_: String,
    /// File to send. Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass “attach://<file_attach_name>” to upload a new one using multipart/form-data under <file_attach_name> name. More information on Sending Files »
    media: String,
    /// Optional. Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. More information on Sending Files »
    thumbnail: Option(String),
    /// Optional. Caption of the audio to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the audio caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Duration of the audio in seconds
    duration: Option(Int),
    /// Optional. Performer of the audio
    performer: Option(String),
    /// Optional. Title of the audio
    title: Option(String),
  )
}

/// **Official reference:** Represents a general file to be sent.
pub type InputMediaDocument {
  InputMediaDocument(
    /// Type of the result, must be document
    type_: String,
    /// File to send. Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass “attach://<file_attach_name>” to upload a new one using multipart/form-data under <file_attach_name> name. More information on Sending Files »
    media: String,
    /// Optional. Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. More information on Sending Files »
    thumbnail: Option(String),
    /// Optional. Caption of the document to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the document caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Disables automatic server-side content type detection for files uploaded using multipart/form-data. Always True, if the document is sent as part of an album.
    disable_content_type_detection: Option(Bool),
  )
}

/// **Official reference:** The paid media to send is a photo.
pub type InputPaidMediaPhoto {
  InputPaidMediaPhoto(
    /// Type of the media, must be photo
    type_: String,
    /// File to send. Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass “attach://<file_attach_name>” to upload a new one using multipart/form-data under <file_attach_name> name. More information on Sending Files »
    media: String,
  )
}

/// **Official reference:** The paid media to send is a video.
pub type InputPaidMediaVideo {
  InputPaidMediaVideo(
    /// Type of the media, must be video
    type_: String,
    /// File to send. Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass “attach://<file_attach_name>” to upload a new one using multipart/form-data under <file_attach_name> name. More information on Sending Files »
    media: String,
    /// Optional. Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. More information on Sending Files »
    thumbnail: Option(String),
    /// Optional. Cover for the video in the message. Pass a file_id to send a file that exists on the Telegram servers (recommended), pass an HTTP URL for Telegram to get a file from the Internet, or pass “attach://<file_attach_name>” to upload a new one using multipart/form-data under <file_attach_name> name. More information on Sending Files »
    cover: Option(String),
    /// Optional. Start timestamp for the video in the message
    start_timestamp: Option(Int),
    /// Optional. Video width
    width: Option(Int),
    /// Optional. Video height
    height: Option(Int),
    /// Optional. Video duration in seconds
    duration: Option(Int),
    /// Optional. Pass True if the uploaded video is suitable for streaming
    supports_streaming: Option(Bool),
  )
}

/// **Official reference:** This object represents a sticker.
pub type Sticker {
  Sticker(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// Type of the sticker, currently one of “regular”, “mask”, “custom_emoji”. The type of the sticker is independent from its format, which is determined by the fields is_animated and is_video.
    type_: String,
    /// Sticker width
    width: Int,
    /// Sticker height
    height: Int,
    /// True, if the sticker is animated
    is_animated: Bool,
    /// True, if the sticker is a video sticker
    is_video: Bool,
    /// Optional. Sticker thumbnail in the .WEBP or .JPG format
    thumbnail: Option(PhotoSize),
    /// Optional. Emoji associated with the sticker
    emoji: Option(String),
    /// Optional. Name of the sticker set to which the sticker belongs
    set_name: Option(String),
    /// Optional. For premium regular stickers, premium animation for the sticker
    premium_animation: Option(File),
    /// Optional. For mask stickers, the position where the mask should be placed
    mask_position: Option(MaskPosition),
    /// Optional. For custom emoji stickers, unique identifier of the custom emoji
    custom_emoji_id: Option(String),
    /// Optional. True, if the sticker must be repainted to a text color in messages, the color of the Telegram Premium badge in emoji status, white color on chat photos, or another appropriate color in other places
    needs_repainting: Option(Bool),
    /// Optional. File size in bytes
    file_size: Option(Int),
  )
}

/// **Official reference:** This object represents a sticker set.
pub type StickerSet {
  StickerSet(
    /// Sticker set name
    name: String,
    /// Sticker set title
    title: String,
    /// Type of stickers in the set, currently one of “regular”, “mask”, “custom_emoji”
    sticker_type: String,
    /// List of all set stickers
    stickers: List(Sticker),
    /// Optional. Sticker set thumbnail in the .WEBP, .TGS, or .WEBM format
    thumbnail: Option(PhotoSize),
  )
}

/// **Official reference:** This object describes the position on faces where a mask should be placed by default.
pub type MaskPosition {
  MaskPosition(
    /// The part of the face relative to which the mask should be placed. One of “forehead”, “eyes”, “mouth”, or “chin”.
    point: String,
    /// Shift by X-axis measured in widths of the mask scaled to the face size, from left to right. For example, choosing -1.0 will place mask just to the left of the default mask position.
    x_shift: Float,
    /// Shift by Y-axis measured in heights of the mask scaled to the face size, from top to bottom. For example, 1.0 will place the mask just below the default mask position.
    y_shift: Float,
    /// Mask scaling coefficient. For example, 2.0 means double size.
    scale: Float,
  )
}

/// **Official reference:** This object describes a sticker to be added to a sticker set.
pub type InputSticker {
  InputSticker(
    /// The added sticker. Pass a file_id as a String to send a file that already exists on the Telegram servers, pass an HTTP URL as a String for Telegram to get a file from the Internet, upload a new one using multipart/form-data, or pass “attach://<file_attach_name>” to upload a new one using multipart/form-data under <file_attach_name> name. Animated and video stickers can't be uploaded via HTTP URL. More information on Sending Files »
    sticker: FileOrString,
    /// Format of the added sticker, must be one of “static” for a .WEBP or .PNG image, “animated” for a .TGS animation, “video” for a .WEBM video
    format: String,
    /// List of 1-20 emoji associated with the sticker
    emoji_list: List(String),
    /// Optional. Position where the mask should be placed on faces. For “mask” stickers only.
    mask_position: Option(MaskPosition),
    /// Optional. List of 0-20 search keywords for the sticker with total length of up to 64 characters. For “regular” and “custom_emoji” stickers only.
    keywords: Option(List(String)),
  )
}

/// **Official reference:** This object represents a gift that can be sent by the bot.
pub type Gift {
  Gift(
    /// Unique identifier of the gift
    id: String,
    /// The sticker that represents the gift
    sticker: Sticker,
    /// The number of Telegram Stars that must be paid to send the sticker
    star_count: Int,
    /// Optional. The number of Telegram Stars that must be paid to upgrade the gift to a unique one
    upgrade_star_count: Option(Int),
    /// Optional. The total number of the gifts of this type that can be sent; for limited gifts only
    total_count: Option(Int),
    /// Optional. The number of remaining gifts of this type that can be sent; for limited gifts only
    remaining_count: Option(Int),
  )
}

/// **Official reference:** This object represent a list of gifts.
pub type Gifts {
  Gifts(
    /// The list of gifts
    gifts: List(Gift),
  )
}

/// **Official reference:** This object represents an incoming inline query. When the user sends an empty query, your bot could return some default or trending results.
pub type InlineQuery {
  InlineQuery(
    /// Unique identifier for this query
    id: String,
    /// Sender
    from: User,
    /// Text of the query (up to 256 characters)
    query: String,
    /// Offset of the results to be returned, can be controlled by the bot
    offset: String,
    /// Optional. Type of the chat from which the inline query was sent. Can be either “sender” for a private chat with the inline query sender, “private”, “group”, “supergroup”, or “channel”. The chat type should be always known for requests sent from official clients and most third-party clients, unless the request was sent from a secret chat
    chat_type: Option(String),
    /// Optional. Sender location, only for bots that request user location
    location: Option(Location),
  )
}

/// **Official reference:** This object represents a button to be shown above inline query results. You must use exactly one of the optional fields.
pub type InlineQueryResultsButton {
  InlineQueryResultsButton(
    /// Label text on the button
    text: String,
    /// Optional. Description of the Web App that will be launched when the user presses the button. The Web App will be able to switch back to the inline mode using the method switchInlineQuery inside the Web App.
    web_app: Option(WebAppInfo),
    /// Optional. Deep-linking parameter for the /start message sent to the bot when a user presses the button. 1-64 characters, only A-Z, a-z, 0-9, _ and - are allowed.
    ///
    /// Example: An inline bot that sends YouTube videos can ask the user to connect the bot to their YouTube account to adapt search results accordingly. To do this, it displays a 'Connect your YouTube account' button above the results, or even before showing any. The user presses the button, switches to a private chat with the bot and, in doing so, passes a start parameter that instructs the bot to return an OAuth link. Once done, the bot can offer a switch_inline button so that the user can easily return to the chat where they wanted to use the bot's inline capabilities.
    start_parameter: Option(String),
  )
}

/// **Official reference:** Represents a link to an article or web page.
pub type InlineQueryResultArticle {
  InlineQueryResultArticle(
    /// Type of the result, must be article
    type_: String,
    /// Unique identifier for this result, 1-64 Bytes
    id: String,
    /// Title of the result
    title: String,
    /// Content of the message to be sent
    input_message_content: InputMessageContent,
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. URL of the result
    url: Option(String),
    /// Optional. Short description of the result
    description: Option(String),
    /// Optional. Url of the thumbnail for the result
    thumbnail_url: Option(String),
    /// Optional. Thumbnail width
    thumbnail_width: Option(Int),
    /// Optional. Thumbnail height
    thumbnail_height: Option(Int),
  )
}

/// **Official reference:** Represents a link to a photo. By default, this photo will be sent by the user with optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the photo.
pub type InlineQueryResultPhoto {
  InlineQueryResultPhoto(
    /// Type of the result, must be photo
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid URL of the photo. Photo must be in JPEG format. Photo size must not exceed 5MB
    photo_url: String,
    /// URL of the thumbnail for the photo
    thumbnail_url: String,
    /// Optional. Width of the photo
    photo_width: Option(Int),
    /// Optional. Height of the photo
    photo_height: Option(Int),
    /// Optional. Title for the result
    title: Option(String),
    /// Optional. Short description of the result
    description: Option(String),
    /// Optional. Caption of the photo to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the photo caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the photo
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to an animated GIF file. By default, this animated GIF file will be sent by the user with optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the animation.
pub type InlineQueryResultGif {
  InlineQueryResultGif(
    /// Type of the result, must be gif
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid URL for the GIF file
    gif_url: String,
    /// Optional. Width of the GIF
    gif_width: Option(Int),
    /// Optional. Height of the GIF
    gif_height: Option(Int),
    /// Optional. Duration of the GIF in seconds
    gif_duration: Option(Int),
    /// URL of the static (JPEG or GIF) or animated (MPEG4) thumbnail for the result
    thumbnail_url: String,
    /// Optional. MIME type of the thumbnail, must be one of “image/jpeg”, “image/gif”, or “video/mp4”. Defaults to “image/jpeg”
    thumbnail_mime_type: Option(String),
    /// Optional. Title for the result
    title: Option(String),
    /// Optional. Caption of the GIF file to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the GIF animation
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to a video animation (H.264/MPEG-4 AVC video without sound). By default, this animated MPEG-4 file will be sent by the user with optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the animation.
pub type InlineQueryResultMpeg4Gif {
  InlineQueryResultMpeg4Gif(
    /// Type of the result, must be mpeg4_gif
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid URL for the MPEG4 file
    mpeg4_url: String,
    /// Optional. Video width
    mpeg4_width: Option(Int),
    /// Optional. Video height
    mpeg4_height: Option(Int),
    /// Optional. Video duration in seconds
    mpeg4_duration: Option(Int),
    /// URL of the static (JPEG or GIF) or animated (MPEG4) thumbnail for the result
    thumbnail_url: String,
    /// Optional. MIME type of the thumbnail, must be one of “image/jpeg”, “image/gif”, or “video/mp4”. Defaults to “image/jpeg”
    thumbnail_mime_type: Option(String),
    /// Optional. Title for the result
    title: Option(String),
    /// Optional. Caption of the MPEG-4 file to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the video animation
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to a page containing an embedded video player or a video file. By default, this video file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the video.
pub type InlineQueryResultVideo {
  InlineQueryResultVideo(
    /// Type of the result, must be video
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid URL for the embedded video player or video file
    video_url: String,
    /// MIME type of the content of the video URL, “text/html” or “video/mp4”
    mime_type: String,
    /// URL of the thumbnail (JPEG only) for the video
    thumbnail_url: String,
    /// Title for the result
    title: String,
    /// Optional. Caption of the video to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the video caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Video width
    video_width: Option(Int),
    /// Optional. Video height
    video_height: Option(Int),
    /// Optional. Video duration in seconds
    video_duration: Option(Int),
    /// Optional. Short description of the result
    description: Option(String),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the video. This field is required if InlineQueryResultVideo is used to send an HTML-page as a result (e.g., a YouTube video).
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to an MP3 audio file. By default, this audio file will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the audio.
pub type InlineQueryResultAudio {
  InlineQueryResultAudio(
    /// Type of the result, must be audio
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid URL for the audio file
    audio_url: String,
    /// Title
    title: String,
    /// Optional. Caption, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the audio caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Performer
    performer: Option(String),
    /// Optional. Audio duration in seconds
    audio_duration: Option(Int),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the audio
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to a voice recording in an .OGG container encoded with OPUS. By default, this voice recording will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the the voice message.
pub type InlineQueryResultVoice {
  InlineQueryResultVoice(
    /// Type of the result, must be voice
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid URL for the voice recording
    voice_url: String,
    /// Recording title
    title: String,
    /// Optional. Caption, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the voice message caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Recording duration in seconds
    voice_duration: Option(Int),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the voice recording
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to a file. By default, this file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the file. Currently, only .PDF and .ZIP files can be sent using this method.
pub type InlineQueryResultDocument {
  InlineQueryResultDocument(
    /// Type of the result, must be document
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// Title for the result
    title: String,
    /// Optional. Caption of the document to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the document caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// A valid URL for the file
    document_url: String,
    /// MIME type of the content of the file, either “application/pdf” or “application/zip”
    mime_type: String,
    /// Optional. Short description of the result
    description: Option(String),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the file
    input_message_content: Option(InputMessageContent),
    /// Optional. URL of the thumbnail (JPEG only) for the file
    thumbnail_url: Option(String),
    /// Optional. Thumbnail width
    thumbnail_width: Option(Int),
    /// Optional. Thumbnail height
    thumbnail_height: Option(Int),
  )
}

/// **Official reference:** Represents a location on a map. By default, the location will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the location.
pub type InlineQueryResultLocation {
  InlineQueryResultLocation(
    /// Type of the result, must be location
    type_: String,
    /// Unique identifier for this result, 1-64 Bytes
    id: String,
    /// Location latitude in degrees
    latitude: Float,
    /// Location longitude in degrees
    longitude: Float,
    /// Location title
    title: String,
    /// Optional. The radius of uncertainty for the location, measured in meters; 0-1500
    horizontal_accuracy: Option(Float),
    /// Optional. Period in seconds during which the location can be updated, should be between 60 and 86400, or 0x7FFFFFFF for live locations that can be edited indefinitely.
    live_period: Option(Int),
    /// Optional. For live locations, a direction in which the user is moving, in degrees. Must be between 1 and 360 if specified.
    heading: Option(Int),
    /// Optional. For live locations, a maximum distance for proximity alerts about approaching another chat member, in meters. Must be between 1 and 100000 if specified.
    proximity_alert_radius: Option(Int),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the location
    input_message_content: Option(InputMessageContent),
    /// Optional. Url of the thumbnail for the result
    thumbnail_url: Option(String),
    /// Optional. Thumbnail width
    thumbnail_width: Option(Int),
    /// Optional. Thumbnail height
    thumbnail_height: Option(Int),
  )
}

/// **Official reference:** Represents a venue. By default, the venue will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the venue.
pub type InlineQueryResultVenue {
  InlineQueryResultVenue(
    /// Type of the result, must be venue
    type_: String,
    /// Unique identifier for this result, 1-64 Bytes
    id: String,
    /// Latitude of the venue location in degrees
    latitude: Float,
    /// Longitude of the venue location in degrees
    longitude: Float,
    /// Title of the venue
    title: String,
    /// Address of the venue
    address: String,
    /// Optional. Foursquare identifier of the venue if known
    foursquare_id: Option(String),
    /// Optional. Foursquare type of the venue, if known. (For example, “arts_entertainment/default”, “arts_entertainment/aquarium” or “food/icecream”.)
    foursquare_type: Option(String),
    /// Optional. Google Places identifier of the venue
    google_place_id: Option(String),
    /// Optional. Google Places type of the venue. (See supported types.)
    google_place_type: Option(String),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the venue
    input_message_content: Option(InputMessageContent),
    /// Optional. Url of the thumbnail for the result
    thumbnail_url: Option(String),
    /// Optional. Thumbnail width
    thumbnail_width: Option(Int),
    /// Optional. Thumbnail height
    thumbnail_height: Option(Int),
  )
}

/// **Official reference:** Represents a contact with a phone number. By default, this contact will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the contact.
pub type InlineQueryResultContact {
  InlineQueryResultContact(
    /// Type of the result, must be contact
    type_: String,
    /// Unique identifier for this result, 1-64 Bytes
    id: String,
    /// Contact's phone number
    phone_number: String,
    /// Contact's first name
    first_name: String,
    /// Optional. Contact's last name
    last_name: Option(String),
    /// Optional. Additional data about the contact in the form of a vCard, 0-2048 bytes
    vcard: Option(String),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the contact
    input_message_content: Option(InputMessageContent),
    /// Optional. Url of the thumbnail for the result
    thumbnail_url: Option(String),
    /// Optional. Thumbnail width
    thumbnail_width: Option(Int),
    /// Optional. Thumbnail height
    thumbnail_height: Option(Int),
  )
}

/// **Official reference:** Represents a Game.
pub type InlineQueryResultGame {
  InlineQueryResultGame(
    /// Type of the result, must be game
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// Short name of the game
    game_short_name: String,
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

/// **Official reference:** Represents a link to a photo stored on the Telegram servers. By default, this photo will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the photo.
pub type InlineQueryResultCachedPhoto {
  InlineQueryResultCachedPhoto(
    /// Type of the result, must be photo
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid file identifier of the photo
    photo_file_id: String,
    /// Optional. Title for the result
    title: Option(String),
    /// Optional. Short description of the result
    description: Option(String),
    /// Optional. Caption of the photo to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the photo caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the photo
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to an animated GIF file stored on the Telegram servers. By default, this animated GIF file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with specified content instead of the animation.
pub type InlineQueryResultCachedGif {
  InlineQueryResultCachedGif(
    /// Type of the result, must be gif
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid file identifier for the GIF file
    gif_file_id: String,
    /// Optional. Title for the result
    title: Option(String),
    /// Optional. Caption of the GIF file to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the GIF animation
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to a video animation (H.264/MPEG-4 AVC video without sound) stored on the Telegram servers. By default, this animated MPEG-4 file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the animation.
pub type InlineQueryResultCachedMpeg4Gif {
  InlineQueryResultCachedMpeg4Gif(
    /// Type of the result, must be mpeg4_gif
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid file identifier for the MPEG4 file
    mpeg4_file_id: String,
    /// Optional. Title for the result
    title: Option(String),
    /// Optional. Caption of the MPEG-4 file to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the video animation
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to a sticker stored on the Telegram servers. By default, this sticker will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the sticker.
pub type InlineQueryResultCachedSticker {
  InlineQueryResultCachedSticker(
    /// Type of the result, must be sticker
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid file identifier of the sticker
    sticker_file_id: String,
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the sticker
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to a file stored on the Telegram servers. By default, this file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the file.
pub type InlineQueryResultCachedDocument {
  InlineQueryResultCachedDocument(
    /// Type of the result, must be document
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// Title for the result
    title: String,
    /// A valid file identifier for the file
    document_file_id: String,
    /// Optional. Short description of the result
    description: Option(String),
    /// Optional. Caption of the document to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the document caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the file
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to a video file stored on the Telegram servers. By default, this video file will be sent by the user with an optional caption. Alternatively, you can use input_message_content to send a message with the specified content instead of the video.
pub type InlineQueryResultCachedVideo {
  InlineQueryResultCachedVideo(
    /// Type of the result, must be video
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid file identifier for the video file
    video_file_id: String,
    /// Title for the result
    title: String,
    /// Optional. Short description of the result
    description: Option(String),
    /// Optional. Caption of the video to be sent, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the video caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Pass True, if the caption must be shown above the message media
    show_caption_above_media: Option(Bool),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the video
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to a voice message stored on the Telegram servers. By default, this voice message will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the voice message.
pub type InlineQueryResultCachedVoice {
  InlineQueryResultCachedVoice(
    /// Type of the result, must be voice
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid file identifier for the voice message
    voice_file_id: String,
    /// Voice message title
    title: String,
    /// Optional. Caption, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the voice message caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the voice message
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents a link to an MP3 audio file stored on the Telegram servers. By default, this audio file will be sent by the user. Alternatively, you can use input_message_content to send a message with the specified content instead of the audio.
pub type InlineQueryResultCachedAudio {
  InlineQueryResultCachedAudio(
    /// Type of the result, must be audio
    type_: String,
    /// Unique identifier for this result, 1-64 bytes
    id: String,
    /// A valid file identifier for the audio file
    audio_file_id: String,
    /// Optional. Caption, 0-1024 characters after entities parsing
    caption: Option(String),
    /// Optional. Mode for parsing entities in the audio caption. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Optional. Inline keyboard attached to the message
    reply_markup: Option(InlineKeyboardMarkup),
    /// Optional. Content of the message to be sent instead of the audio
    input_message_content: Option(InputMessageContent),
  )
}

/// **Official reference:** Represents the content of a text message to be sent as the result of an inline query.
pub type InputTextMessageContent {
  InputTextMessageContent(
    /// Text of the message to be sent, 1-4096 characters
    message_text: String,
    /// Optional. Mode for parsing entities in the message text. See formatting options for more details.
    parse_mode: Option(String),
    /// Optional. List of special entities that appear in message text, which can be specified instead of parse_mode
    entities: Option(List(MessageEntity)),
    /// Optional. Link preview generation options for the message
    link_preview_options: Option(LinkPreviewOptions),
  )
}

/// **Official reference:** Represents the content of a location message to be sent as the result of an inline query.
pub type InputLocationMessageContent {
  InputLocationMessageContent(
    /// Latitude of the location in degrees
    latitude: Float,
    /// Longitude of the location in degrees
    longitude: Float,
    /// Optional. The radius of uncertainty for the location, measured in meters; 0-1500
    horizontal_accuracy: Option(Float),
    /// Optional. Period in seconds during which the location can be updated, should be between 60 and 86400, or 0x7FFFFFFF for live locations that can be edited indefinitely.
    live_period: Option(Int),
    /// Optional. For live locations, a direction in which the user is moving, in degrees. Must be between 1 and 360 if specified.
    heading: Option(Int),
    /// Optional. For live locations, a maximum distance for proximity alerts about approaching another chat member, in meters. Must be between 1 and 100000 if specified.
    proximity_alert_radius: Option(Int),
  )
}

/// **Official reference:** Represents the content of a venue message to be sent as the result of an inline query.
pub type InputVenueMessageContent {
  InputVenueMessageContent(
    /// Latitude of the venue in degrees
    latitude: Float,
    /// Longitude of the venue in degrees
    longitude: Float,
    /// Name of the venue
    title: String,
    /// Address of the venue
    address: String,
    /// Optional. Foursquare identifier of the venue, if known
    foursquare_id: Option(String),
    /// Optional. Foursquare type of the venue, if known. (For example, “arts_entertainment/default”, “arts_entertainment/aquarium” or “food/icecream”.)
    foursquare_type: Option(String),
    /// Optional. Google Places identifier of the venue
    google_place_id: Option(String),
    /// Optional. Google Places type of the venue. (See supported types.)
    google_place_type: Option(String),
  )
}

/// **Official reference:** Represents the content of a contact message to be sent as the result of an inline query.
pub type InputContactMessageContent {
  InputContactMessageContent(
    /// Contact's phone number
    phone_number: String,
    /// Contact's first name
    first_name: String,
    /// Optional. Contact's last name
    last_name: Option(String),
    /// Optional. Additional data about the contact in the form of a vCard, 0-2048 bytes
    vcard: Option(String),
  )
}

/// **Official reference:** Represents the content of an invoice message to be sent as the result of an inline query.
pub type InputInvoiceMessageContent {
  InputInvoiceMessageContent(
    /// Product name, 1-32 characters
    title: String,
    /// Product description, 1-255 characters
    description: String,
    /// Bot-defined invoice payload, 1-128 bytes. This will not be displayed to the user, use it for your internal processes.
    payload: String,
    /// Optional. Payment provider token, obtained via @BotFather. Pass an empty string for payments in Telegram Stars.
    provider_token: Option(String),
    /// Three-letter ISO 4217 currency code, see more on currencies. Pass “XTR” for payments in Telegram Stars.
    currency: String,
    /// Price breakdown, a JSON-serialized list of components (e.g. product price, tax, discount, delivery cost, delivery tax, bonus, etc.). Must contain exactly one item for payments in Telegram Stars.
    prices: List(LabeledPrice),
    /// Optional. The maximum accepted amount for tips in the smallest units of the currency (integer, not float/double). For example, for a maximum tip of US$ 1.45 pass max_tip_amount = 145. See the exp parameter in currencies.json, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies). Defaults to 0. Not supported for payments in Telegram Stars.
    max_tip_amount: Option(Int),
    /// Optional. A JSON-serialized array of suggested amounts of tip in the smallest units of the currency (integer, not float/double). At most 4 suggested tip amounts can be specified. The suggested tip amounts must be positive, passed in a strictly increased order and must not exceed max_tip_amount.
    suggested_tip_amounts: Option(List(Int)),
    /// Optional. A JSON-serialized object for data about the invoice, which will be shared with the payment provider. A detailed description of the required fields should be provided by the payment provider.
    provider_data: Option(String),
    /// Optional. URL of the product photo for the invoice. Can be a photo of the goods or a marketing image for a service.
    photo_url: Option(String),
    /// Optional. Photo size in bytes
    photo_size: Option(Int),
    /// Optional. Photo width
    photo_width: Option(Int),
    /// Optional. Photo height
    photo_height: Option(Int),
    /// Optional. Pass True if you require the user's full name to complete the order. Ignored for payments in Telegram Stars.
    need_name: Option(Bool),
    /// Optional. Pass True if you require the user's phone number to complete the order. Ignored for payments in Telegram Stars.
    need_phone_number: Option(Bool),
    /// Optional. Pass True if you require the user's email address to complete the order. Ignored for payments in Telegram Stars.
    need_email: Option(Bool),
    /// Optional. Pass True if you require the user's shipping address to complete the order. Ignored for payments in Telegram Stars.
    need_shipping_address: Option(Bool),
    /// Optional. Pass True if the user's phone number should be sent to the provider. Ignored for payments in Telegram Stars.
    send_phone_number_to_provider: Option(Bool),
    /// Optional. Pass True if the user's email address should be sent to the provider. Ignored for payments in Telegram Stars.
    send_email_to_provider: Option(Bool),
    /// Optional. Pass True if the final price depends on the shipping method. Ignored for payments in Telegram Stars.
    is_flexible: Option(Bool),
  )
}

/// **Official reference:** Represents a result of an inline query that was chosen by the user and sent to their chat partner.
pub type ChosenInlineResult {
  ChosenInlineResult(
    /// The unique identifier for the result that was chosen
    result_id: String,
    /// The user that chose the result
    from: User,
    /// Optional. Sender location, only for bots that require user location
    location: Option(Location),
    /// Optional. Identifier of the sent inline message. Available only if there is an inline keyboard attached to the message. Will be also received in callback queries and can be used to edit the message.
    inline_message_id: Option(String),
    /// The query that was used to obtain the result
    query: String,
  )
}

/// **Official reference:** Describes an inline message sent by a Web App on behalf of a user.
pub type SentWebAppMessage {
  SentWebAppMessage(
    /// Optional. Identifier of the sent inline message. Available only if there is an inline keyboard attached to the message.
    inline_message_id: Option(String),
  )
}

/// **Official reference:** Describes an inline message to be sent by a user of a Mini App.
pub type PreparedInlineMessage {
  PreparedInlineMessage(
    /// Unique identifier of the prepared message
    id: String,
    /// Expiration date of the prepared message, in Unix time. Expired prepared messages can no longer be used
    expiration_date: Int,
  )
}

/// **Official reference:** This object represents a portion of the price for goods or services.
pub type LabeledPrice {
  LabeledPrice(
    /// Portion label
    label: String,
    /// Price of the product in the smallest units of the currency (integer, not float/double). For example, for a price of US$ 1.45 pass amount = 145. See the exp parameter in currencies.json, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).
    amount: Int,
  )
}

/// **Official reference:** This object contains basic information about an invoice.
pub type Invoice {
  Invoice(
    /// Product name
    title: String,
    /// Product description
    description: String,
    /// Unique bot deep-linking parameter that can be used to generate this invoice
    start_parameter: String,
    /// Three-letter ISO 4217 currency code, or “XTR” for payments in Telegram Stars
    currency: String,
    /// Total price in the smallest units of the currency (integer, not float/double). For example, for a price of US$ 1.45 pass amount = 145. See the exp parameter in currencies.json, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).
    total_amount: Int,
  )
}

/// **Official reference:** This object represents a shipping address.
pub type ShippingAddress {
  ShippingAddress(
    /// Two-letter ISO 3166-1 alpha-2 country code
    country_code: String,
    /// State, if applicable
    state: String,
    /// City
    city: String,
    /// First line for the address
    street_line1: String,
    /// Second line for the address
    street_line2: String,
    /// Address post code
    post_code: String,
  )
}

/// **Official reference:** This object represents information about an order.
pub type OrderInfo {
  OrderInfo(
    /// Optional. User name
    name: Option(String),
    /// Optional. User's phone number
    phone_number: Option(String),
    /// Optional. User email
    email: Option(String),
    /// Optional. User shipping address
    shipping_address: Option(ShippingAddress),
  )
}

/// **Official reference:** This object represents one shipping option.
pub type ShippingOption {
  ShippingOption(
    /// Shipping option identifier
    id: String,
    /// Option title
    title: String,
    /// List of price portions
    prices: List(LabeledPrice),
  )
}

/// **Official reference:** This object contains basic information about a successful payment. Note that if the buyer initiates a chargeback with the relevant payment provider following this transaction, the funds may be debited from your balance. This is outside of Telegram's control.
pub type SuccessfulPayment {
  SuccessfulPayment(
    /// Three-letter ISO 4217 currency code, or “XTR” for payments in Telegram Stars
    currency: String,
    /// Total price in the smallest units of the currency (integer, not float/double). For example, for a price of US$ 1.45 pass amount = 145. See the exp parameter in currencies.json, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).
    total_amount: Int,
    /// Bot-specified invoice payload
    invoice_payload: String,
    /// Optional. Expiration date of the subscription, in Unix time; for recurring payments only
    subscription_expiration_date: Option(Int),
    /// Optional. True, if the payment is a recurring payment for a subscription
    is_recurring: Option(Bool),
    /// Optional. True, if the payment is the first payment for a subscription
    is_first_recurring: Option(Bool),
    /// Optional. Identifier of the shipping option chosen by the user
    shipping_option_id: Option(String),
    /// Optional. Order information provided by the user
    order_info: Option(OrderInfo),
    /// Telegram payment identifier
    telegram_payment_charge_id: String,
    /// Provider payment identifier
    provider_payment_charge_id: String,
  )
}

/// **Official reference:** This object contains basic information about a refunded payment.
pub type RefundedPayment {
  RefundedPayment(
    /// Three-letter ISO 4217 currency code, or “XTR” for payments in Telegram Stars. Currently, always “XTR”
    currency: String,
    /// Total refunded price in the smallest units of the currency (integer, not float/double). For example, for a price of US$ 1.45, total_amount = 145. See the exp parameter in currencies.json, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).
    total_amount: Int,
    /// Bot-specified invoice payload
    invoice_payload: String,
    /// Telegram payment identifier
    telegram_payment_charge_id: String,
    /// Optional. Provider payment identifier
    provider_payment_charge_id: Option(String),
  )
}

/// **Official reference:** This object contains information about an incoming shipping query.
pub type ShippingQuery {
  ShippingQuery(
    /// Unique query identifier
    id: String,
    /// User who sent the query
    from: User,
    /// Bot-specified invoice payload
    invoice_payload: String,
    /// User specified shipping address
    shipping_address: ShippingAddress,
  )
}

/// **Official reference:** This object contains information about an incoming pre-checkout query.
pub type PreCheckoutQuery {
  PreCheckoutQuery(
    /// Unique query identifier
    id: String,
    /// User who sent the query
    from: User,
    /// Three-letter ISO 4217 currency code, or “XTR” for payments in Telegram Stars
    currency: String,
    /// Total price in the smallest units of the currency (integer, not float/double). For example, for a price of US$ 1.45 pass amount = 145. See the exp parameter in currencies.json, it shows the number of digits past the decimal point for each currency (2 for the majority of currencies).
    total_amount: Int,
    /// Bot-specified invoice payload
    invoice_payload: String,
    /// Optional. Identifier of the shipping option chosen by the user
    shipping_option_id: Option(String),
    /// Optional. Order information provided by the user
    order_info: Option(OrderInfo),
  )
}

/// **Official reference:** This object contains information about a paid media purchase.
pub type PaidMediaPurchased {
  PaidMediaPurchased(
    /// User who purchased the media
    from: User,
    /// Bot-specified paid media payload
    paid_media_payload: String,
  )
}

/// **Official reference:** The withdrawal is in progress.
pub type RevenueWithdrawalStatePending {
  RevenueWithdrawalStatePending(
    /// Type of the state, always “pending”
    type_: String,
  )
}

/// **Official reference:** The withdrawal succeeded.
pub type RevenueWithdrawalStateSucceeded {
  RevenueWithdrawalStateSucceeded(
    /// Type of the state, always “succeeded”
    type_: String,
    /// Date the withdrawal was completed in Unix time
    date: Int,
    /// An HTTPS URL that can be used to see transaction details
    url: String,
  )
}

/// **Official reference:** The withdrawal failed and the transaction was refunded.
pub type RevenueWithdrawalStateFailed {
  RevenueWithdrawalStateFailed(
    /// Type of the state, always “failed”
    type_: String,
  )
}

/// **Official reference:** Contains information about the affiliate that received a commission via this transaction.
pub type AffiliateInfo {
  AffiliateInfo(
    /// Optional. The bot or the user that received an affiliate commission if it was received by a bot or a user
    affiliate_user: Option(User),
    /// Optional. The chat that received an affiliate commission if it was received by a chat
    affiliate_chat: Option(Chat),
    /// The number of Telegram Stars received by the affiliate for each 1000 Telegram Stars received by the bot from referred users
    commission_per_mille: Int,
    /// Integer amount of Telegram Stars received by the affiliate from the transaction, rounded to 0; can be negative for refunds
    amount: Int,
    /// Optional. The number of 1/1000000000 shares of Telegram Stars received by the affiliate; from -999999999 to 999999999; can be negative for refunds
    nanostar_amount: Option(Int),
  )
}

/// **Official reference:** Describes a transaction with a user.
pub type TransactionPartnerUser {
  TransactionPartnerUser(
    /// Type of the transaction partner, always “user”
    type_: String,
    /// Information about the user
    user: User,
    /// Optional. Information about the affiliate that received a commission via this transaction
    affiliate: Option(AffiliateInfo),
    /// Optional. Bot-specified invoice payload
    invoice_payload: Option(String),
    /// Optional. The duration of the paid subscription
    subscription_period: Option(Int),
    /// Optional. Information about the paid media bought by the user
    paid_media: Option(List(PaidMedia)),
    /// Optional. Bot-specified paid media payload
    paid_media_payload: Option(String),
    /// Optional. The gift sent to the user by the bot
    gift: Option(Gift),
  )
}

/// **Official reference:** Describes a transaction with a chat.
pub type TransactionPartnerChat {
  TransactionPartnerChat(
    /// Type of the transaction partner, always “chat”
    type_: String,
    /// Information about the chat
    chat: Chat,
    /// Optional. The gift sent to the chat by the bot
    gift: Option(Gift),
  )
}

/// **Official reference:** Describes the affiliate program that issued the affiliate commission received via this transaction.
pub type TransactionPartnerAffiliateProgram {
  TransactionPartnerAffiliateProgram(
    /// Type of the transaction partner, always “affiliate_program”
    type_: String,
    /// Optional. Information about the bot that sponsored the affiliate program
    sponsor_user: Option(User),
    /// The number of Telegram Stars received by the bot for each 1000 Telegram Stars received by the affiliate program sponsor from referred users
    commission_per_mille: Int,
  )
}

/// **Official reference:** Describes a withdrawal transaction with Fragment.
pub type TransactionPartnerFragment {
  TransactionPartnerFragment(
    /// Type of the transaction partner, always “fragment”
    type_: String,
    /// Optional. State of the transaction if the transaction is outgoing
    withdrawal_state: Option(RevenueWithdrawalState),
  )
}

/// **Official reference:** Describes a withdrawal transaction to the Telegram Ads platform.
pub type TransactionPartnerTelegramAds {
  TransactionPartnerTelegramAds(
    /// Type of the transaction partner, always “telegram_ads”
    type_: String,
  )
}

/// **Official reference:** Describes a transaction with payment for paid broadcasting.
pub type TransactionPartnerTelegramApi {
  TransactionPartnerTelegramApi(
    /// Type of the transaction partner, always “telegram_api”
    type_: String,
    /// The number of successful requests that exceeded regular limits and were therefore billed
    request_count: Int,
  )
}

/// **Official reference:** Describes a transaction with an unknown source or recipient.
pub type TransactionPartnerOther {
  TransactionPartnerOther(
    /// Type of the transaction partner, always “other”
    type_: String,
  )
}

/// **Official reference:** Describes a Telegram Star transaction. Note that if the buyer initiates a chargeback with the payment provider from whom they acquired Stars (e.g., Apple, Google) following this transaction, the refunded Stars will be deducted from the bot's balance. This is outside of Telegram's control.
pub type StarTransaction {
  StarTransaction(
    /// Unique identifier of the transaction. Coincides with the identifier of the original transaction for refund transactions. Coincides with SuccessfulPayment.telegram_payment_charge_id for successful incoming payments from users.
    id: String,
    /// Integer amount of Telegram Stars transferred by the transaction
    amount: Int,
    /// Optional. The number of 1/1000000000 shares of Telegram Stars transferred by the transaction; from 0 to 999999999
    nanostar_amount: Option(Int),
    /// Date the transaction was created in Unix time
    date: Int,
    /// Optional. Source of an incoming transaction (e.g., a user purchasing goods or services, Fragment refunding a failed withdrawal). Only for incoming transactions
    source: Option(TransactionPartner),
    /// Optional. Receiver of an outgoing transaction (e.g., a user for a purchase refund, Fragment for a withdrawal). Only for outgoing transactions
    receiver: Option(TransactionPartner),
  )
}

/// **Official reference:** Contains a list of Telegram Star transactions.
pub type StarTransactions {
  StarTransactions(
    /// The list of transactions
    transactions: List(StarTransaction),
  )
}

/// **Official reference:** Describes Telegram Passport data shared with the bot by the user.
pub type PassportData {
  PassportData(
    /// Array with information about documents and other Telegram Passport elements that was shared with the bot
    data: List(EncryptedPassportElement),
    /// Encrypted credentials required to decrypt the data
    credentials: EncryptedCredentials,
  )
}

/// **Official reference:** This object represents a file uploaded to Telegram Passport. Currently all Telegram Passport files are in JPEG format when decrypted and don't exceed 10MB.
pub type PassportFile {
  PassportFile(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// File size in bytes
    file_size: Int,
    /// Unix time when the file was uploaded
    file_date: Int,
  )
}

/// **Official reference:** Describes documents or other Telegram Passport elements shared with the bot by the user.
pub type EncryptedPassportElement {
  EncryptedPassportElement(
    /// Element type. One of “personal_details”, “passport”, “driver_license”, “identity_card”, “internal_passport”, “address”, “utility_bill”, “bank_statement”, “rental_agreement”, “passport_registration”, “temporary_registration”, “phone_number”, “email”.
    type_: String,
    /// Optional. Base64-encoded encrypted Telegram Passport element data provided by the user; available only for “personal_details”, “passport”, “driver_license”, “identity_card”, “internal_passport” and “address” types. Can be decrypted and verified using the accompanying EncryptedCredentials.
    data: Option(String),
    /// Optional. User's verified phone number; available only for “phone_number” type
    phone_number: Option(String),
    /// Optional. User's verified email address; available only for “email” type
    email: Option(String),
    /// Optional. Array of encrypted files with documents provided by the user; available only for “utility_bill”, “bank_statement”, “rental_agreement”, “passport_registration” and “temporary_registration” types. Files can be decrypted and verified using the accompanying EncryptedCredentials.
    files: Option(List(PassportFile)),
    /// Optional. Encrypted file with the front side of the document, provided by the user; available only for “passport”, “driver_license”, “identity_card” and “internal_passport”. The file can be decrypted and verified using the accompanying EncryptedCredentials.
    front_side: Option(PassportFile),
    /// Optional. Encrypted file with the reverse side of the document, provided by the user; available only for “driver_license” and “identity_card”. The file can be decrypted and verified using the accompanying EncryptedCredentials.
    reverse_side: Option(PassportFile),
    /// Optional. Encrypted file with the selfie of the user holding a document, provided by the user; available if requested for “passport”, “driver_license”, “identity_card” and “internal_passport”. The file can be decrypted and verified using the accompanying EncryptedCredentials.
    selfie: Option(PassportFile),
    /// Optional. Array of encrypted files with translated versions of documents provided by the user; available if requested for “passport”, “driver_license”, “identity_card”, “internal_passport”, “utility_bill”, “bank_statement”, “rental_agreement”, “passport_registration” and “temporary_registration” types. Files can be decrypted and verified using the accompanying EncryptedCredentials.
    translation: Option(List(PassportFile)),
    /// Base64-encoded element hash for using in PassportElementErrorUnspecified
    hash: String,
  )
}

/// **Official reference:** Describes data required for decrypting and authenticating EncryptedPassportElement. See the Telegram Passport Documentation for a complete description of the data decryption and authentication processes.
pub type EncryptedCredentials {
  EncryptedCredentials(
    /// Base64-encoded encrypted JSON-serialized data with unique user's payload, data hashes and secrets required for EncryptedPassportElement decryption and authentication
    data: String,
    /// Base64-encoded data hash for data authentication
    hash: String,
    /// Base64-encoded secret, encrypted with the bot's public RSA key, required for data decryption
    secret: String,
  )
}

/// **Official reference:** Represents an issue in one of the data fields that was provided by the user. The error is considered resolved when the field's value changes.
pub type PassportElementErrorDataField {
  PassportElementErrorDataField(
    /// Error source, must be data
    source: String,
    /// The section of the user's Telegram Passport which has the error, one of “personal_details”, “passport”, “driver_license”, “identity_card”, “internal_passport”, “address”
    type_: String,
    /// Name of the data field which has the error
    field_name: String,
    /// Base64-encoded data hash
    data_hash: String,
    /// Error message
    message: String,
  )
}

/// **Official reference:** Represents an issue with the front side of a document. The error is considered resolved when the file with the front side of the document changes.
pub type PassportElementErrorFrontSide {
  PassportElementErrorFrontSide(
    /// Error source, must be front_side
    source: String,
    /// The section of the user's Telegram Passport which has the issue, one of “passport”, “driver_license”, “identity_card”, “internal_passport”
    type_: String,
    /// Base64-encoded hash of the file with the front side of the document
    file_hash: String,
    /// Error message
    message: String,
  )
}

/// **Official reference:** Represents an issue with the reverse side of a document. The error is considered resolved when the file with reverse side of the document changes.
pub type PassportElementErrorReverseSide {
  PassportElementErrorReverseSide(
    /// Error source, must be reverse_side
    source: String,
    /// The section of the user's Telegram Passport which has the issue, one of “driver_license”, “identity_card”
    type_: String,
    /// Base64-encoded hash of the file with the reverse side of the document
    file_hash: String,
    /// Error message
    message: String,
  )
}

/// **Official reference:** Represents an issue with the selfie with a document. The error is considered resolved when the file with the selfie changes.
pub type PassportElementErrorSelfie {
  PassportElementErrorSelfie(
    /// Error source, must be selfie
    source: String,
    /// The section of the user's Telegram Passport which has the issue, one of “passport”, “driver_license”, “identity_card”, “internal_passport”
    type_: String,
    /// Base64-encoded hash of the file with the selfie
    file_hash: String,
    /// Error message
    message: String,
  )
}

/// **Official reference:** Represents an issue with a document scan. The error is considered resolved when the file with the document scan changes.
pub type PassportElementErrorFile {
  PassportElementErrorFile(
    /// Error source, must be file
    source: String,
    /// The section of the user's Telegram Passport which has the issue, one of “utility_bill”, “bank_statement”, “rental_agreement”, “passport_registration”, “temporary_registration”
    type_: String,
    /// Base64-encoded file hash
    file_hash: String,
    /// Error message
    message: String,
  )
}

/// **Official reference:** Represents an issue with a list of scans. The error is considered resolved when the list of files containing the scans changes.
pub type PassportElementErrorFiles {
  PassportElementErrorFiles(
    /// Error source, must be files
    source: String,
    /// The section of the user's Telegram Passport which has the issue, one of “utility_bill”, “bank_statement”, “rental_agreement”, “passport_registration”, “temporary_registration”
    type_: String,
    /// List of base64-encoded file hashes
    file_hashes: List(String),
    /// Error message
    message: String,
  )
}

/// **Official reference:** Represents an issue with one of the files that constitute the translation of a document. The error is considered resolved when the file changes.
pub type PassportElementErrorTranslationFile {
  PassportElementErrorTranslationFile(
    /// Error source, must be translation_file
    source: String,
    /// Type of element of the user's Telegram Passport which has the issue, one of “passport”, “driver_license”, “identity_card”, “internal_passport”, “utility_bill”, “bank_statement”, “rental_agreement”, “passport_registration”, “temporary_registration”
    type_: String,
    /// Base64-encoded file hash
    file_hash: String,
    /// Error message
    message: String,
  )
}

/// **Official reference:** Represents an issue with the translated version of a document. The error is considered resolved when a file with the document translation change.
pub type PassportElementErrorTranslationFiles {
  PassportElementErrorTranslationFiles(
    /// Error source, must be translation_files
    source: String,
    /// Type of element of the user's Telegram Passport which has the issue, one of “passport”, “driver_license”, “identity_card”, “internal_passport”, “utility_bill”, “bank_statement”, “rental_agreement”, “passport_registration”, “temporary_registration”
    type_: String,
    /// List of base64-encoded file hashes
    file_hashes: List(String),
    /// Error message
    message: String,
  )
}

/// **Official reference:** Represents an issue in an unspecified place. The error is considered resolved when new data is added.
pub type PassportElementErrorUnspecified {
  PassportElementErrorUnspecified(
    /// Error source, must be unspecified
    source: String,
    /// Type of element of the user's Telegram Passport which has the issue
    type_: String,
    /// Base64-encoded element hash
    element_hash: String,
    /// Error message
    message: String,
  )
}

/// **Official reference:** This object represents a game. Use BotFather to create and edit games, their short names will act as unique identifiers.
pub type Game {
  Game(
    /// Title of the game
    title: String,
    /// Description of the game
    description: String,
    /// Photo that will be displayed in the game message in chats.
    photo: List(PhotoSize),
    /// Optional. Brief description of the game or high scores included in the game message. Can be automatically edited to include current high scores for the game when the bot calls setGameScore, or manually edited using editMessageText. 0-4096 characters.
    text: Option(String),
    /// Optional. Special entities that appear in text, such as usernames, URLs, bot commands, etc.
    text_entities: Option(List(MessageEntity)),
    /// Optional. Animation that will be displayed in the game message in chats. Upload via BotFather
    animation: Option(Animation),
  )
}

/// **Official reference:** A placeholder, currently holds no information. Use BotFather to set up your game.
pub type CallbackGame {
  CallbackGame(
    /// User identifier
    user_id: Int,
    /// New score, must be non-negative
    score: Int,
    /// Pass True if the high score is allowed to decrease. This can be useful when fixing mistakes or banning cheaters
    force: Option(Bool),
    /// Pass True if the game message should not be automatically edited to include the current scoreboard
    disable_edit_message: Option(Bool),
    /// Required if inline_message_id is not specified. Unique identifier for the target chat
    chat_id: Option(Int),
    /// Required if inline_message_id is not specified. Identifier of the sent message
    message_id: Option(Int),
    /// Required if chat_id and message_id are not specified. Identifier of the inline message
    inline_message_id: Option(String),
  )
}

/// **Official reference:** This object represents one row of the high scores table for a game.
pub type GameHighScore {
  GameHighScore(
    /// Position in high score table for the game
    position: Int,
    /// User
    user: User,
    /// Score
    score: Int,
  )
}

pub fn update_decoder() -> decode.Decoder(Update) {
  use update_id <- decode.field("update_id", decode.int)
  use message <- decode.field("message", decode.optional(message_decoder()))
  use edited_message <- decode.field(
    "edited_message",
    decode.optional(message_decoder()),
  )
  use channel_post <- decode.field(
    "channel_post",
    decode.optional(message_decoder()),
  )
  use edited_channel_post <- decode.field(
    "edited_channel_post",
    decode.optional(message_decoder()),
  )
  use business_connection <- decode.field(
    "business_connection",
    decode.optional(business_connection_decoder()),
  )
  use business_message <- decode.field(
    "business_message",
    decode.optional(message_decoder()),
  )
  use edited_business_message <- decode.field(
    "edited_business_message",
    decode.optional(message_decoder()),
  )
  use deleted_business_messages <- decode.field(
    "deleted_business_messages",
    decode.optional(business_messages_deleted_decoder()),
  )
  use message_reaction <- decode.field(
    "message_reaction",
    decode.optional(message_reaction_updated_decoder()),
  )
  use message_reaction_count <- decode.field(
    "message_reaction_count",
    decode.optional(message_reaction_count_updated_decoder()),
  )
  use inline_query <- decode.field(
    "inline_query",
    decode.optional(inline_query_decoder()),
  )
  use chosen_inline_result <- decode.field(
    "chosen_inline_result",
    decode.optional(chosen_inline_result_decoder()),
  )
  use callback_query <- decode.field(
    "callback_query",
    decode.optional(callback_query_decoder()),
  )
  use shipping_query <- decode.field(
    "shipping_query",
    decode.optional(shipping_query_decoder()),
  )
  use pre_checkout_query <- decode.field(
    "pre_checkout_query",
    decode.optional(pre_checkout_query_decoder()),
  )
  use purchased_paid_media <- decode.field(
    "purchased_paid_media",
    decode.optional(paid_media_purchased_decoder()),
  )
  use poll <- decode.field("poll", decode.optional(poll_decoder()))
  use poll_answer <- decode.field(
    "poll_answer",
    decode.optional(poll_answer_decoder()),
  )
  use my_chat_member <- decode.field(
    "my_chat_member",
    decode.optional(chat_member_updated_decoder()),
  )
  use chat_member <- decode.field(
    "chat_member",
    decode.optional(chat_member_updated_decoder()),
  )
  use chat_join_request <- decode.field(
    "chat_join_request",
    decode.optional(chat_join_request_decoder()),
  )
  use chat_boost <- decode.field(
    "chat_boost",
    decode.optional(chat_boost_updated_decoder()),
  )
  use removed_chat_boost <- decode.field(
    "removed_chat_boost",
    decode.optional(chat_boost_removed_decoder()),
  )
  decode.success(Update(
    update_id: update_id,
    message: message,
    edited_message: edited_message,
    channel_post: channel_post,
    edited_channel_post: edited_channel_post,
    business_connection: business_connection,
    business_message: business_message,
    edited_business_message: edited_business_message,
    deleted_business_messages: deleted_business_messages,
    message_reaction: message_reaction,
    message_reaction_count: message_reaction_count,
    inline_query: inline_query,
    chosen_inline_result: chosen_inline_result,
    callback_query: callback_query,
    shipping_query: shipping_query,
    pre_checkout_query: pre_checkout_query,
    purchased_paid_media: purchased_paid_media,
    poll: poll,
    poll_answer: poll_answer,
    my_chat_member: my_chat_member,
    chat_member: chat_member,
    chat_join_request: chat_join_request,
    chat_boost: chat_boost,
    removed_chat_boost: removed_chat_boost,
  ))
}

pub fn webhook_info_decoder() -> decode.Decoder(WebhookInfo) {
  use url <- decode.field("url", decode.string)
  use has_custom_certificate <- decode.field(
    "has_custom_certificate",
    decode.bool,
  )
  use pending_update_count <- decode.field("pending_update_count", decode.int)
  use ip_address <- decode.field("ip_address", decode.optional(decode.string))
  use last_error_date <- decode.field(
    "last_error_date",
    decode.optional(decode.int),
  )
  use last_error_message <- decode.field(
    "last_error_message",
    decode.optional(decode.string),
  )
  use last_synchronization_error_date <- decode.field(
    "last_synchronization_error_date",
    decode.optional(decode.int),
  )
  use max_connections <- decode.field(
    "max_connections",
    decode.optional(decode.int),
  )
  use allowed_updates <- decode.field(
    "allowed_updates",
    decode.optional(decode.list(decode.string)),
  )
  decode.success(WebhookInfo(
    url: url,
    has_custom_certificate: has_custom_certificate,
    pending_update_count: pending_update_count,
    ip_address: ip_address,
    last_error_date: last_error_date,
    last_error_message: last_error_message,
    last_synchronization_error_date: last_synchronization_error_date,
    max_connections: max_connections,
    allowed_updates: allowed_updates,
  ))
}

pub fn user_decoder() -> decode.Decoder(User) {
  use id <- decode.field("id", decode.int)
  use is_bot <- decode.field("is_bot", decode.bool)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.optional(decode.string))
  use username <- decode.field("username", decode.optional(decode.string))
  use language_code <- decode.field(
    "language_code",
    decode.optional(decode.string),
  )
  use is_premium <- decode.field("is_premium", decode.optional(decode.bool))
  use added_to_attachment_menu <- decode.field(
    "added_to_attachment_menu",
    decode.optional(decode.bool),
  )
  use can_join_groups <- decode.field(
    "can_join_groups",
    decode.optional(decode.bool),
  )
  use can_read_all_group_messages <- decode.field(
    "can_read_all_group_messages",
    decode.optional(decode.bool),
  )
  use supports_inline_queries <- decode.field(
    "supports_inline_queries",
    decode.optional(decode.bool),
  )
  use can_connect_to_business <- decode.field(
    "can_connect_to_business",
    decode.optional(decode.bool),
  )
  use has_main_web_app <- decode.field(
    "has_main_web_app",
    decode.optional(decode.bool),
  )
  decode.success(User(
    id: id,
    is_bot: is_bot,
    first_name: first_name,
    last_name: last_name,
    username: username,
    language_code: language_code,
    is_premium: is_premium,
    added_to_attachment_menu: added_to_attachment_menu,
    can_join_groups: can_join_groups,
    can_read_all_group_messages: can_read_all_group_messages,
    supports_inline_queries: supports_inline_queries,
    can_connect_to_business: can_connect_to_business,
    has_main_web_app: has_main_web_app,
  ))
}

pub fn chat_decoder() -> decode.Decoder(Chat) {
  use id <- decode.field("id", decode.int)
  use type_ <- decode.field("type_", decode.string)
  use title <- decode.field("title", decode.optional(decode.string))
  use username <- decode.field("username", decode.optional(decode.string))
  use first_name <- decode.field("first_name", decode.optional(decode.string))
  use last_name <- decode.field("last_name", decode.optional(decode.string))
  use is_forum <- decode.field("is_forum", decode.optional(decode.bool))
  decode.success(Chat(
    id: id,
    type_: type_,
    title: title,
    username: username,
    first_name: first_name,
    last_name: last_name,
    is_forum: is_forum,
  ))
}

pub fn chat_full_info_decoder() -> decode.Decoder(ChatFullInfo) {
  use id <- decode.field("id", decode.int)
  use type_ <- decode.field("type_", decode.string)
  use title <- decode.field("title", decode.optional(decode.string))
  use username <- decode.field("username", decode.optional(decode.string))
  use first_name <- decode.field("first_name", decode.optional(decode.string))
  use last_name <- decode.field("last_name", decode.optional(decode.string))
  use is_forum <- decode.field("is_forum", decode.optional(decode.bool))
  use accent_color_id <- decode.field("accent_color_id", decode.int)
  use max_reaction_count <- decode.field("max_reaction_count", decode.int)
  use photo <- decode.field("photo", decode.optional(chat_photo_decoder()))
  use active_usernames <- decode.field(
    "active_usernames",
    decode.optional(decode.list(decode.string)),
  )
  use birthdate <- decode.field(
    "birthdate",
    decode.optional(birthdate_decoder()),
  )
  use business_intro <- decode.field(
    "business_intro",
    decode.optional(business_intro_decoder()),
  )
  use business_location <- decode.field(
    "business_location",
    decode.optional(business_location_decoder()),
  )
  use business_opening_hours <- decode.field(
    "business_opening_hours",
    decode.optional(business_opening_hours_decoder()),
  )
  use personal_chat <- decode.field(
    "personal_chat",
    decode.optional(chat_decoder()),
  )
  use available_reactions <- decode.field(
    "available_reactions",
    decode.optional(decode.list(reaction_type_decoder())),
  )
  use background_custom_emoji_id <- decode.field(
    "background_custom_emoji_id",
    decode.optional(decode.string),
  )
  use profile_accent_color_id <- decode.field(
    "profile_accent_color_id",
    decode.optional(decode.int),
  )
  use profile_background_custom_emoji_id <- decode.field(
    "profile_background_custom_emoji_id",
    decode.optional(decode.string),
  )
  use emoji_status_custom_emoji_id <- decode.field(
    "emoji_status_custom_emoji_id",
    decode.optional(decode.string),
  )
  use emoji_status_expiration_date <- decode.field(
    "emoji_status_expiration_date",
    decode.optional(decode.int),
  )
  use bio <- decode.field("bio", decode.optional(decode.string))
  use has_private_forwards <- decode.field(
    "has_private_forwards",
    decode.optional(decode.bool),
  )
  use has_restricted_voice_and_video_messages <- decode.field(
    "has_restricted_voice_and_video_messages",
    decode.optional(decode.bool),
  )
  use join_to_send_messages <- decode.field(
    "join_to_send_messages",
    decode.optional(decode.bool),
  )
  use join_by_request <- decode.field(
    "join_by_request",
    decode.optional(decode.bool),
  )
  use description <- decode.field("description", decode.optional(decode.string))
  use invite_link <- decode.field("invite_link", decode.optional(decode.string))
  use pinned_message <- decode.field(
    "pinned_message",
    decode.optional(message_decoder()),
  )
  use permissions <- decode.field(
    "permissions",
    decode.optional(chat_permissions_decoder()),
  )
  use can_send_gift <- decode.field(
    "can_send_gift",
    decode.optional(decode.bool),
  )
  use can_send_paid_media <- decode.field(
    "can_send_paid_media",
    decode.optional(decode.bool),
  )
  use slow_mode_delay <- decode.field(
    "slow_mode_delay",
    decode.optional(decode.int),
  )
  use unrestrict_boost_count <- decode.field(
    "unrestrict_boost_count",
    decode.optional(decode.int),
  )
  use message_auto_delete_time <- decode.field(
    "message_auto_delete_time",
    decode.optional(decode.int),
  )
  use has_aggressive_anti_spam_enabled <- decode.field(
    "has_aggressive_anti_spam_enabled",
    decode.optional(decode.bool),
  )
  use has_hidden_members <- decode.field(
    "has_hidden_members",
    decode.optional(decode.bool),
  )
  use has_protected_content <- decode.field(
    "has_protected_content",
    decode.optional(decode.bool),
  )
  use has_visible_history <- decode.field(
    "has_visible_history",
    decode.optional(decode.bool),
  )
  use sticker_set_name <- decode.field(
    "sticker_set_name",
    decode.optional(decode.string),
  )
  use can_set_sticker_set <- decode.field(
    "can_set_sticker_set",
    decode.optional(decode.bool),
  )
  use custom_emoji_sticker_set_name <- decode.field(
    "custom_emoji_sticker_set_name",
    decode.optional(decode.string),
  )
  use linked_chat_id <- decode.field(
    "linked_chat_id",
    decode.optional(decode.int),
  )
  use location <- decode.field(
    "location",
    decode.optional(chat_location_decoder()),
  )
  decode.success(ChatFullInfo(
    id: id,
    type_: type_,
    title: title,
    username: username,
    first_name: first_name,
    last_name: last_name,
    is_forum: is_forum,
    accent_color_id: accent_color_id,
    max_reaction_count: max_reaction_count,
    photo: photo,
    active_usernames: active_usernames,
    birthdate: birthdate,
    business_intro: business_intro,
    business_location: business_location,
    business_opening_hours: business_opening_hours,
    personal_chat: personal_chat,
    available_reactions: available_reactions,
    background_custom_emoji_id: background_custom_emoji_id,
    profile_accent_color_id: profile_accent_color_id,
    profile_background_custom_emoji_id: profile_background_custom_emoji_id,
    emoji_status_custom_emoji_id: emoji_status_custom_emoji_id,
    emoji_status_expiration_date: emoji_status_expiration_date,
    bio: bio,
    has_private_forwards: has_private_forwards,
    has_restricted_voice_and_video_messages: has_restricted_voice_and_video_messages,
    join_to_send_messages: join_to_send_messages,
    join_by_request: join_by_request,
    description: description,
    invite_link: invite_link,
    pinned_message: pinned_message,
    permissions: permissions,
    can_send_gift: can_send_gift,
    can_send_paid_media: can_send_paid_media,
    slow_mode_delay: slow_mode_delay,
    unrestrict_boost_count: unrestrict_boost_count,
    message_auto_delete_time: message_auto_delete_time,
    has_aggressive_anti_spam_enabled: has_aggressive_anti_spam_enabled,
    has_hidden_members: has_hidden_members,
    has_protected_content: has_protected_content,
    has_visible_history: has_visible_history,
    sticker_set_name: sticker_set_name,
    can_set_sticker_set: can_set_sticker_set,
    custom_emoji_sticker_set_name: custom_emoji_sticker_set_name,
    linked_chat_id: linked_chat_id,
    location: location,
  ))
}

pub fn message_decoder() -> decode.Decoder(Message) {
  use message_id <- decode.field("message_id", decode.int)
  use message_thread_id <- decode.field(
    "message_thread_id",
    decode.optional(decode.int),
  )
  use from <- decode.field("from", decode.optional(user_decoder()))
  use sender_chat <- decode.field(
    "sender_chat",
    decode.optional(chat_decoder()),
  )
  use sender_boost_count <- decode.field(
    "sender_boost_count",
    decode.optional(decode.int),
  )
  use sender_business_bot <- decode.field(
    "sender_business_bot",
    decode.optional(user_decoder()),
  )
  use date <- decode.field("date", decode.int)
  use business_connection_id <- decode.field(
    "business_connection_id",
    decode.optional(decode.string),
  )
  use chat <- decode.field("chat", chat_decoder())
  use forward_origin <- decode.field(
    "forward_origin",
    decode.optional(message_origin_decoder()),
  )
  use is_topic_message <- decode.field(
    "is_topic_message",
    decode.optional(decode.bool),
  )
  use is_automatic_forward <- decode.field(
    "is_automatic_forward",
    decode.optional(decode.bool),
  )
  use reply_to_message <- decode.field(
    "reply_to_message",
    decode.optional(message_decoder()),
  )
  use external_reply <- decode.field(
    "external_reply",
    decode.optional(external_reply_info_decoder()),
  )
  use quote <- decode.field("quote", decode.optional(text_quote_decoder()))
  use reply_to_story <- decode.field(
    "reply_to_story",
    decode.optional(story_decoder()),
  )
  use via_bot <- decode.field("via_bot", decode.optional(user_decoder()))
  use edit_date <- decode.field("edit_date", decode.optional(decode.int))
  use has_protected_content <- decode.field(
    "has_protected_content",
    decode.optional(decode.bool),
  )
  use is_from_offline <- decode.field(
    "is_from_offline",
    decode.optional(decode.bool),
  )
  use media_group_id <- decode.field(
    "media_group_id",
    decode.optional(decode.string),
  )
  use author_signature <- decode.field(
    "author_signature",
    decode.optional(decode.string),
  )
  use text <- decode.field("text", decode.optional(decode.string))
  use entities <- decode.field(
    "entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use link_preview_options <- decode.field(
    "link_preview_options",
    decode.optional(link_preview_options_decoder()),
  )
  use effect_id <- decode.field("effect_id", decode.optional(decode.string))
  use animation <- decode.field(
    "animation",
    decode.optional(animation_decoder()),
  )
  use audio <- decode.field("audio", decode.optional(audio_decoder()))
  use document <- decode.field("document", decode.optional(document_decoder()))
  use paid_media <- decode.field(
    "paid_media",
    decode.optional(paid_media_info_decoder()),
  )
  use photo <- decode.field(
    "photo",
    decode.optional(decode.list(photo_size_decoder())),
  )
  use sticker <- decode.field("sticker", decode.optional(sticker_decoder()))
  use story <- decode.field("story", decode.optional(story_decoder()))
  use video <- decode.field("video", decode.optional(video_decoder()))
  use video_note <- decode.field(
    "video_note",
    decode.optional(video_note_decoder()),
  )
  use voice <- decode.field("voice", decode.optional(voice_decoder()))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use has_media_spoiler <- decode.field(
    "has_media_spoiler",
    decode.optional(decode.bool),
  )
  use contact <- decode.field("contact", decode.optional(contact_decoder()))
  use dice <- decode.field("dice", decode.optional(dice_decoder()))
  use game <- decode.field("game", decode.optional(game_decoder()))
  use poll <- decode.field("poll", decode.optional(poll_decoder()))
  use venue <- decode.field("venue", decode.optional(venue_decoder()))
  use location <- decode.field("location", decode.optional(location_decoder()))
  use new_chat_members <- decode.field(
    "new_chat_members",
    decode.optional(decode.list(user_decoder())),
  )
  use left_chat_member <- decode.field(
    "left_chat_member",
    decode.optional(user_decoder()),
  )
  use new_chat_title <- decode.field(
    "new_chat_title",
    decode.optional(decode.string),
  )
  use new_chat_photo <- decode.field(
    "new_chat_photo",
    decode.optional(decode.list(photo_size_decoder())),
  )
  use delete_chat_photo <- decode.field(
    "delete_chat_photo",
    decode.optional(decode.bool),
  )
  use group_chat_created <- decode.field(
    "group_chat_created",
    decode.optional(decode.bool),
  )
  use supergroup_chat_created <- decode.field(
    "supergroup_chat_created",
    decode.optional(decode.bool),
  )
  use channel_chat_created <- decode.field(
    "channel_chat_created",
    decode.optional(decode.bool),
  )
  use message_auto_delete_timer_changed <- decode.field(
    "message_auto_delete_timer_changed",
    decode.optional(message_auto_delete_timer_changed_decoder()),
  )
  use migrate_to_chat_id <- decode.field(
    "migrate_to_chat_id",
    decode.optional(decode.int),
  )
  use migrate_from_chat_id <- decode.field(
    "migrate_from_chat_id",
    decode.optional(decode.int),
  )
  use pinned_message <- decode.field(
    "pinned_message",
    decode.optional(maybe_inaccessible_message_decoder()),
  )
  use invoice <- decode.field("invoice", decode.optional(invoice_decoder()))
  use successful_payment <- decode.field(
    "successful_payment",
    decode.optional(successful_payment_decoder()),
  )
  use refunded_payment <- decode.field(
    "refunded_payment",
    decode.optional(refunded_payment_decoder()),
  )
  use users_shared <- decode.field(
    "users_shared",
    decode.optional(users_shared_decoder()),
  )
  use chat_shared <- decode.field(
    "chat_shared",
    decode.optional(chat_shared_decoder()),
  )
  use connected_website <- decode.field(
    "connected_website",
    decode.optional(decode.string),
  )
  use write_access_allowed <- decode.field(
    "write_access_allowed",
    decode.optional(write_access_allowed_decoder()),
  )
  use passport_data <- decode.field(
    "passport_data",
    decode.optional(passport_data_decoder()),
  )
  use proximity_alert_triggered <- decode.field(
    "proximity_alert_triggered",
    decode.optional(proximity_alert_triggered_decoder()),
  )
  use boost_added <- decode.field(
    "boost_added",
    decode.optional(chat_boost_added_decoder()),
  )
  use chat_background_set <- decode.field(
    "chat_background_set",
    decode.optional(chat_background_decoder()),
  )
  use forum_topic_created <- decode.field(
    "forum_topic_created",
    decode.optional(forum_topic_created_decoder()),
  )
  use forum_topic_edited <- decode.field(
    "forum_topic_edited",
    decode.optional(forum_topic_edited_decoder()),
  )
  use forum_topic_closed <- decode.field(
    "forum_topic_closed",
    decode.optional(forum_topic_closed_decoder()),
  )
  use forum_topic_reopened <- decode.field(
    "forum_topic_reopened",
    decode.optional(forum_topic_reopened_decoder()),
  )
  use general_forum_topic_hidden <- decode.field(
    "general_forum_topic_hidden",
    decode.optional(general_forum_topic_hidden_decoder()),
  )
  use general_forum_topic_unhidden <- decode.field(
    "general_forum_topic_unhidden",
    decode.optional(general_forum_topic_unhidden_decoder()),
  )
  use giveaway_created <- decode.field(
    "giveaway_created",
    decode.optional(giveaway_created_decoder()),
  )
  use giveaway <- decode.field("giveaway", decode.optional(giveaway_decoder()))
  use giveaway_winners <- decode.field(
    "giveaway_winners",
    decode.optional(giveaway_winners_decoder()),
  )
  use giveaway_completed <- decode.field(
    "giveaway_completed",
    decode.optional(giveaway_completed_decoder()),
  )
  use video_chat_scheduled <- decode.field(
    "video_chat_scheduled",
    decode.optional(video_chat_scheduled_decoder()),
  )
  use video_chat_started <- decode.field(
    "video_chat_started",
    decode.optional(video_chat_started_decoder()),
  )
  use video_chat_ended <- decode.field(
    "video_chat_ended",
    decode.optional(video_chat_ended_decoder()),
  )
  use video_chat_participants_invited <- decode.field(
    "video_chat_participants_invited",
    decode.optional(video_chat_participants_invited_decoder()),
  )
  use web_app_data <- decode.field(
    "web_app_data",
    decode.optional(web_app_data_decoder()),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  decode.success(Message(
    message_id: message_id,
    message_thread_id: message_thread_id,
    from: from,
    sender_chat: sender_chat,
    sender_boost_count: sender_boost_count,
    sender_business_bot: sender_business_bot,
    date: date,
    business_connection_id: business_connection_id,
    chat: chat,
    forward_origin: forward_origin,
    is_topic_message: is_topic_message,
    is_automatic_forward: is_automatic_forward,
    reply_to_message: reply_to_message,
    external_reply: external_reply,
    quote: quote,
    reply_to_story: reply_to_story,
    via_bot: via_bot,
    edit_date: edit_date,
    has_protected_content: has_protected_content,
    is_from_offline: is_from_offline,
    media_group_id: media_group_id,
    author_signature: author_signature,
    text: text,
    entities: entities,
    link_preview_options: link_preview_options,
    effect_id: effect_id,
    animation: animation,
    audio: audio,
    document: document,
    paid_media: paid_media,
    photo: photo,
    sticker: sticker,
    story: story,
    video: video,
    video_note: video_note,
    voice: voice,
    caption: caption,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    has_media_spoiler: has_media_spoiler,
    contact: contact,
    dice: dice,
    game: game,
    poll: poll,
    venue: venue,
    location: location,
    new_chat_members: new_chat_members,
    left_chat_member: left_chat_member,
    new_chat_title: new_chat_title,
    new_chat_photo: new_chat_photo,
    delete_chat_photo: delete_chat_photo,
    group_chat_created: group_chat_created,
    supergroup_chat_created: supergroup_chat_created,
    channel_chat_created: channel_chat_created,
    message_auto_delete_timer_changed: message_auto_delete_timer_changed,
    migrate_to_chat_id: migrate_to_chat_id,
    migrate_from_chat_id: migrate_from_chat_id,
    pinned_message: pinned_message,
    invoice: invoice,
    successful_payment: successful_payment,
    refunded_payment: refunded_payment,
    users_shared: users_shared,
    chat_shared: chat_shared,
    connected_website: connected_website,
    write_access_allowed: write_access_allowed,
    passport_data: passport_data,
    proximity_alert_triggered: proximity_alert_triggered,
    boost_added: boost_added,
    chat_background_set: chat_background_set,
    forum_topic_created: forum_topic_created,
    forum_topic_edited: forum_topic_edited,
    forum_topic_closed: forum_topic_closed,
    forum_topic_reopened: forum_topic_reopened,
    general_forum_topic_hidden: general_forum_topic_hidden,
    general_forum_topic_unhidden: general_forum_topic_unhidden,
    giveaway_created: giveaway_created,
    giveaway: giveaway,
    giveaway_winners: giveaway_winners,
    giveaway_completed: giveaway_completed,
    video_chat_scheduled: video_chat_scheduled,
    video_chat_started: video_chat_started,
    video_chat_ended: video_chat_ended,
    video_chat_participants_invited: video_chat_participants_invited,
    web_app_data: web_app_data,
    reply_markup: reply_markup,
  ))
}

pub fn message_id_decoder() -> decode.Decoder(MessageId) {
  use message_id <- decode.field("message_id", decode.int)
  decode.success(MessageId(message_id: message_id))
}

pub fn inaccessible_message_decoder() -> decode.Decoder(InaccessibleMessage) {
  use chat <- decode.field("chat", chat_decoder())
  use message_id <- decode.field("message_id", decode.int)
  use date <- decode.field("date", decode.int)
  decode.success(InaccessibleMessage(
    chat: chat,
    message_id: message_id,
    date: date,
  ))
}

pub fn message_entity_decoder() -> decode.Decoder(MessageEntity) {
  use type_ <- decode.field("type_", decode.string)
  use offset <- decode.field("offset", decode.int)
  use length <- decode.field("length", decode.int)
  use url <- decode.field("url", decode.optional(decode.string))
  use user <- decode.field("user", decode.optional(user_decoder()))
  use language <- decode.field("language", decode.optional(decode.string))
  use custom_emoji_id <- decode.field(
    "custom_emoji_id",
    decode.optional(decode.string),
  )
  decode.success(MessageEntity(
    type_: type_,
    offset: offset,
    length: length,
    url: url,
    user: user,
    language: language,
    custom_emoji_id: custom_emoji_id,
  ))
}

pub fn text_quote_decoder() -> decode.Decoder(TextQuote) {
  use text <- decode.field("text", decode.string)
  use entities <- decode.field(
    "entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use position <- decode.field("position", decode.int)
  use is_manual <- decode.field("is_manual", decode.optional(decode.bool))
  decode.success(TextQuote(
    text: text,
    entities: entities,
    position: position,
    is_manual: is_manual,
  ))
}

pub fn external_reply_info_decoder() -> decode.Decoder(ExternalReplyInfo) {
  use origin <- decode.field("origin", message_origin_decoder())
  use chat <- decode.field("chat", decode.optional(chat_decoder()))
  use message_id <- decode.field("message_id", decode.optional(decode.int))
  use link_preview_options <- decode.field(
    "link_preview_options",
    decode.optional(link_preview_options_decoder()),
  )
  use animation <- decode.field(
    "animation",
    decode.optional(animation_decoder()),
  )
  use audio <- decode.field("audio", decode.optional(audio_decoder()))
  use document <- decode.field("document", decode.optional(document_decoder()))
  use paid_media <- decode.field(
    "paid_media",
    decode.optional(paid_media_info_decoder()),
  )
  use photo <- decode.field(
    "photo",
    decode.optional(decode.list(photo_size_decoder())),
  )
  use sticker <- decode.field("sticker", decode.optional(sticker_decoder()))
  use story <- decode.field("story", decode.optional(story_decoder()))
  use video <- decode.field("video", decode.optional(video_decoder()))
  use video_note <- decode.field(
    "video_note",
    decode.optional(video_note_decoder()),
  )
  use voice <- decode.field("voice", decode.optional(voice_decoder()))
  use has_media_spoiler <- decode.field(
    "has_media_spoiler",
    decode.optional(decode.bool),
  )
  use contact <- decode.field("contact", decode.optional(contact_decoder()))
  use dice <- decode.field("dice", decode.optional(dice_decoder()))
  use game <- decode.field("game", decode.optional(game_decoder()))
  use giveaway <- decode.field("giveaway", decode.optional(giveaway_decoder()))
  use giveaway_winners <- decode.field(
    "giveaway_winners",
    decode.optional(giveaway_winners_decoder()),
  )
  use invoice <- decode.field("invoice", decode.optional(invoice_decoder()))
  use location <- decode.field("location", decode.optional(location_decoder()))
  use poll <- decode.field("poll", decode.optional(poll_decoder()))
  use venue <- decode.field("venue", decode.optional(venue_decoder()))
  decode.success(ExternalReplyInfo(
    origin: origin,
    chat: chat,
    message_id: message_id,
    link_preview_options: link_preview_options,
    animation: animation,
    audio: audio,
    document: document,
    paid_media: paid_media,
    photo: photo,
    sticker: sticker,
    story: story,
    video: video,
    video_note: video_note,
    voice: voice,
    has_media_spoiler: has_media_spoiler,
    contact: contact,
    dice: dice,
    game: game,
    giveaway: giveaway,
    giveaway_winners: giveaway_winners,
    invoice: invoice,
    location: location,
    poll: poll,
    venue: venue,
  ))
}

pub fn reply_parameters_decoder() -> decode.Decoder(ReplyParameters) {
  use message_id <- decode.field("message_id", decode.int)
  use chat_id <- decode.field(
    "chat_id",
    decode.optional(int_or_string_decoder()),
  )
  use allow_sending_without_reply <- decode.field(
    "allow_sending_without_reply",
    decode.optional(decode.bool),
  )
  use quote <- decode.field("quote", decode.optional(decode.string))
  use quote_parse_mode <- decode.field(
    "quote_parse_mode",
    decode.optional(decode.string),
  )
  use quote_entities <- decode.field(
    "quote_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use quote_position <- decode.field(
    "quote_position",
    decode.optional(decode.int),
  )
  decode.success(ReplyParameters(
    message_id: message_id,
    chat_id: chat_id,
    allow_sending_without_reply: allow_sending_without_reply,
    quote: quote,
    quote_parse_mode: quote_parse_mode,
    quote_entities: quote_entities,
    quote_position: quote_position,
  ))
}

pub fn message_origin_user_decoder() -> decode.Decoder(MessageOriginUser) {
  use type_ <- decode.field("type_", decode.string)
  use date <- decode.field("date", decode.int)
  use sender_user <- decode.field("sender_user", user_decoder())
  decode.success(MessageOriginUser(
    type_: type_,
    date: date,
    sender_user: sender_user,
  ))
}

pub fn message_origin_hidden_user_decoder() -> decode.Decoder(
  MessageOriginHiddenUser,
) {
  use type_ <- decode.field("type_", decode.string)
  use date <- decode.field("date", decode.int)
  use sender_user_name <- decode.field("sender_user_name", decode.string)
  decode.success(MessageOriginHiddenUser(
    type_: type_,
    date: date,
    sender_user_name: sender_user_name,
  ))
}

pub fn message_origin_chat_decoder() -> decode.Decoder(MessageOriginChat) {
  use type_ <- decode.field("type_", decode.string)
  use date <- decode.field("date", decode.int)
  use sender_chat <- decode.field("sender_chat", chat_decoder())
  use author_signature <- decode.field(
    "author_signature",
    decode.optional(decode.string),
  )
  decode.success(MessageOriginChat(
    type_: type_,
    date: date,
    sender_chat: sender_chat,
    author_signature: author_signature,
  ))
}

pub fn message_origin_channel_decoder() -> decode.Decoder(MessageOriginChannel) {
  use type_ <- decode.field("type_", decode.string)
  use date <- decode.field("date", decode.int)
  use chat <- decode.field("chat", chat_decoder())
  use message_id <- decode.field("message_id", decode.int)
  use author_signature <- decode.field(
    "author_signature",
    decode.optional(decode.string),
  )
  decode.success(MessageOriginChannel(
    type_: type_,
    date: date,
    chat: chat,
    message_id: message_id,
    author_signature: author_signature,
  ))
}

pub fn photo_size_decoder() -> decode.Decoder(PhotoSize) {
  use file_id <- decode.field("file_id", decode.string)
  use file_unique_id <- decode.field("file_unique_id", decode.string)
  use width <- decode.field("width", decode.int)
  use height <- decode.field("height", decode.int)
  use file_size <- decode.field("file_size", decode.optional(decode.int))
  decode.success(PhotoSize(
    file_id: file_id,
    file_unique_id: file_unique_id,
    width: width,
    height: height,
    file_size: file_size,
  ))
}

pub fn animation_decoder() -> decode.Decoder(Animation) {
  use file_id <- decode.field("file_id", decode.string)
  use file_unique_id <- decode.field("file_unique_id", decode.string)
  use width <- decode.field("width", decode.int)
  use height <- decode.field("height", decode.int)
  use duration <- decode.field("duration", decode.int)
  use thumbnail <- decode.field(
    "thumbnail",
    decode.optional(photo_size_decoder()),
  )
  use file_name <- decode.field("file_name", decode.optional(decode.string))
  use mime_type <- decode.field("mime_type", decode.optional(decode.string))
  use file_size <- decode.field("file_size", decode.optional(decode.int))
  decode.success(Animation(
    file_id: file_id,
    file_unique_id: file_unique_id,
    width: width,
    height: height,
    duration: duration,
    thumbnail: thumbnail,
    file_name: file_name,
    mime_type: mime_type,
    file_size: file_size,
  ))
}

pub fn audio_decoder() -> decode.Decoder(Audio) {
  use file_id <- decode.field("file_id", decode.string)
  use file_unique_id <- decode.field("file_unique_id", decode.string)
  use duration <- decode.field("duration", decode.int)
  use performer <- decode.field("performer", decode.optional(decode.string))
  use title <- decode.field("title", decode.optional(decode.string))
  use file_name <- decode.field("file_name", decode.optional(decode.string))
  use mime_type <- decode.field("mime_type", decode.optional(decode.string))
  use file_size <- decode.field("file_size", decode.optional(decode.int))
  use thumbnail <- decode.field(
    "thumbnail",
    decode.optional(photo_size_decoder()),
  )
  decode.success(Audio(
    file_id: file_id,
    file_unique_id: file_unique_id,
    duration: duration,
    performer: performer,
    title: title,
    file_name: file_name,
    mime_type: mime_type,
    file_size: file_size,
    thumbnail: thumbnail,
  ))
}

pub fn document_decoder() -> decode.Decoder(Document) {
  use file_id <- decode.field("file_id", decode.string)
  use file_unique_id <- decode.field("file_unique_id", decode.string)
  use thumbnail <- decode.field(
    "thumbnail",
    decode.optional(photo_size_decoder()),
  )
  use file_name <- decode.field("file_name", decode.optional(decode.string))
  use mime_type <- decode.field("mime_type", decode.optional(decode.string))
  use file_size <- decode.field("file_size", decode.optional(decode.int))
  decode.success(Document(
    file_id: file_id,
    file_unique_id: file_unique_id,
    thumbnail: thumbnail,
    file_name: file_name,
    mime_type: mime_type,
    file_size: file_size,
  ))
}

pub fn story_decoder() -> decode.Decoder(Story) {
  use chat <- decode.field("chat", chat_decoder())
  use id <- decode.field("id", decode.int)
  decode.success(Story(chat: chat, id: id))
}

pub fn video_decoder() -> decode.Decoder(Video) {
  use file_id <- decode.field("file_id", decode.string)
  use file_unique_id <- decode.field("file_unique_id", decode.string)
  use width <- decode.field("width", decode.int)
  use height <- decode.field("height", decode.int)
  use duration <- decode.field("duration", decode.int)
  use thumbnail <- decode.field(
    "thumbnail",
    decode.optional(photo_size_decoder()),
  )
  use cover <- decode.field(
    "cover",
    decode.optional(decode.list(photo_size_decoder())),
  )
  use start_timestamp <- decode.field(
    "start_timestamp",
    decode.optional(decode.int),
  )
  use file_name <- decode.field("file_name", decode.optional(decode.string))
  use mime_type <- decode.field("mime_type", decode.optional(decode.string))
  use file_size <- decode.field("file_size", decode.optional(decode.int))
  decode.success(Video(
    file_id: file_id,
    file_unique_id: file_unique_id,
    width: width,
    height: height,
    duration: duration,
    thumbnail: thumbnail,
    cover: cover,
    start_timestamp: start_timestamp,
    file_name: file_name,
    mime_type: mime_type,
    file_size: file_size,
  ))
}

pub fn video_note_decoder() -> decode.Decoder(VideoNote) {
  use file_id <- decode.field("file_id", decode.string)
  use file_unique_id <- decode.field("file_unique_id", decode.string)
  use length <- decode.field("length", decode.int)
  use duration <- decode.field("duration", decode.int)
  use thumbnail <- decode.field(
    "thumbnail",
    decode.optional(photo_size_decoder()),
  )
  use file_size <- decode.field("file_size", decode.optional(decode.int))
  decode.success(VideoNote(
    file_id: file_id,
    file_unique_id: file_unique_id,
    length: length,
    duration: duration,
    thumbnail: thumbnail,
    file_size: file_size,
  ))
}

pub fn voice_decoder() -> decode.Decoder(Voice) {
  use file_id <- decode.field("file_id", decode.string)
  use file_unique_id <- decode.field("file_unique_id", decode.string)
  use duration <- decode.field("duration", decode.int)
  use mime_type <- decode.field("mime_type", decode.optional(decode.string))
  use file_size <- decode.field("file_size", decode.optional(decode.int))
  decode.success(Voice(
    file_id: file_id,
    file_unique_id: file_unique_id,
    duration: duration,
    mime_type: mime_type,
    file_size: file_size,
  ))
}

pub fn paid_media_info_decoder() -> decode.Decoder(PaidMediaInfo) {
  use star_count <- decode.field("star_count", decode.int)
  use paid_media <- decode.field(
    "paid_media",
    decode.list(paid_media_decoder()),
  )
  decode.success(PaidMediaInfo(star_count: star_count, paid_media: paid_media))
}

pub fn paid_media_preview_decoder() -> decode.Decoder(PaidMediaPreview) {
  use type_ <- decode.field("type_", decode.string)
  use width <- decode.field("width", decode.optional(decode.int))
  use height <- decode.field("height", decode.optional(decode.int))
  use duration <- decode.field("duration", decode.optional(decode.int))
  decode.success(PaidMediaPreview(
    type_: type_,
    width: width,
    height: height,
    duration: duration,
  ))
}

pub fn paid_media_photo_decoder() -> decode.Decoder(PaidMediaPhoto) {
  use type_ <- decode.field("type_", decode.string)
  use photo <- decode.field("photo", decode.list(photo_size_decoder()))
  decode.success(PaidMediaPhoto(type_: type_, photo: photo))
}

pub fn paid_media_video_decoder() -> decode.Decoder(PaidMediaVideo) {
  use type_ <- decode.field("type_", decode.string)
  use video <- decode.field("video", video_decoder())
  decode.success(PaidMediaVideo(type_: type_, video: video))
}

pub fn contact_decoder() -> decode.Decoder(Contact) {
  use phone_number <- decode.field("phone_number", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.optional(decode.string))
  use user_id <- decode.field("user_id", decode.optional(decode.int))
  use vcard <- decode.field("vcard", decode.optional(decode.string))
  decode.success(Contact(
    phone_number: phone_number,
    first_name: first_name,
    last_name: last_name,
    user_id: user_id,
    vcard: vcard,
  ))
}

pub fn dice_decoder() -> decode.Decoder(Dice) {
  use emoji <- decode.field("emoji", decode.string)
  use value <- decode.field("value", decode.int)
  decode.success(Dice(emoji: emoji, value: value))
}

pub fn poll_option_decoder() -> decode.Decoder(PollOption) {
  use text <- decode.field("text", decode.string)
  use text_entities <- decode.field(
    "text_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use voter_count <- decode.field("voter_count", decode.int)
  decode.success(PollOption(
    text: text,
    text_entities: text_entities,
    voter_count: voter_count,
  ))
}

pub fn input_poll_option_decoder() -> decode.Decoder(InputPollOption) {
  use text <- decode.field("text", decode.string)
  use text_parse_mode <- decode.field(
    "text_parse_mode",
    decode.optional(decode.string),
  )
  use text_entities <- decode.field(
    "text_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  decode.success(InputPollOption(
    text: text,
    text_parse_mode: text_parse_mode,
    text_entities: text_entities,
  ))
}

pub fn poll_answer_decoder() -> decode.Decoder(PollAnswer) {
  use poll_id <- decode.field("poll_id", decode.string)
  use voter_chat <- decode.field("voter_chat", decode.optional(chat_decoder()))
  use user <- decode.field("user", decode.optional(user_decoder()))
  use option_ids <- decode.field("option_ids", decode.list(decode.int))
  decode.success(PollAnswer(
    poll_id: poll_id,
    voter_chat: voter_chat,
    user: user,
    option_ids: option_ids,
  ))
}

pub fn poll_decoder() -> decode.Decoder(Poll) {
  use id <- decode.field("id", decode.string)
  use question <- decode.field("question", decode.string)
  use question_entities <- decode.field(
    "question_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use options <- decode.field("options", decode.list(poll_option_decoder()))
  use total_voter_count <- decode.field("total_voter_count", decode.int)
  use is_closed <- decode.field("is_closed", decode.bool)
  use is_anonymous <- decode.field("is_anonymous", decode.bool)
  use type_ <- decode.field("type_", decode.string)
  use allows_multiple_answers <- decode.field(
    "allows_multiple_answers",
    decode.bool,
  )
  use correct_option_id <- decode.field(
    "correct_option_id",
    decode.optional(decode.int),
  )
  use explanation <- decode.field("explanation", decode.optional(decode.string))
  use explanation_entities <- decode.field(
    "explanation_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use open_period <- decode.field("open_period", decode.optional(decode.int))
  use close_date <- decode.field("close_date", decode.optional(decode.int))
  decode.success(Poll(
    id: id,
    question: question,
    question_entities: question_entities,
    options: options,
    total_voter_count: total_voter_count,
    is_closed: is_closed,
    is_anonymous: is_anonymous,
    type_: type_,
    allows_multiple_answers: allows_multiple_answers,
    correct_option_id: correct_option_id,
    explanation: explanation,
    explanation_entities: explanation_entities,
    open_period: open_period,
    close_date: close_date,
  ))
}

pub fn location_decoder() -> decode.Decoder(Location) {
  use latitude <- decode.field("latitude", decode.float)
  use longitude <- decode.field("longitude", decode.float)
  use horizontal_accuracy <- decode.field(
    "horizontal_accuracy",
    decode.optional(decode.float),
  )
  use live_period <- decode.field("live_period", decode.optional(decode.int))
  use heading <- decode.field("heading", decode.optional(decode.int))
  use proximity_alert_radius <- decode.field(
    "proximity_alert_radius",
    decode.optional(decode.int),
  )
  decode.success(Location(
    latitude: latitude,
    longitude: longitude,
    horizontal_accuracy: horizontal_accuracy,
    live_period: live_period,
    heading: heading,
    proximity_alert_radius: proximity_alert_radius,
  ))
}

pub fn venue_decoder() -> decode.Decoder(Venue) {
  use location <- decode.field("location", location_decoder())
  use title <- decode.field("title", decode.string)
  use address <- decode.field("address", decode.string)
  use foursquare_id <- decode.field(
    "foursquare_id",
    decode.optional(decode.string),
  )
  use foursquare_type <- decode.field(
    "foursquare_type",
    decode.optional(decode.string),
  )
  use google_place_id <- decode.field(
    "google_place_id",
    decode.optional(decode.string),
  )
  use google_place_type <- decode.field(
    "google_place_type",
    decode.optional(decode.string),
  )
  decode.success(Venue(
    location: location,
    title: title,
    address: address,
    foursquare_id: foursquare_id,
    foursquare_type: foursquare_type,
    google_place_id: google_place_id,
    google_place_type: google_place_type,
  ))
}

pub fn web_app_data_decoder() -> decode.Decoder(WebAppData) {
  use data <- decode.field("data", decode.string)
  use button_text <- decode.field("button_text", decode.string)
  decode.success(WebAppData(data: data, button_text: button_text))
}

pub fn proximity_alert_triggered_decoder() -> decode.Decoder(
  ProximityAlertTriggered,
) {
  use traveler <- decode.field("traveler", user_decoder())
  use watcher <- decode.field("watcher", user_decoder())
  use distance <- decode.field("distance", decode.int)
  decode.success(ProximityAlertTriggered(
    traveler: traveler,
    watcher: watcher,
    distance: distance,
  ))
}

pub fn message_auto_delete_timer_changed_decoder() -> decode.Decoder(
  MessageAutoDeleteTimerChanged,
) {
  use message_auto_delete_time <- decode.field(
    "message_auto_delete_time",
    decode.int,
  )
  decode.success(MessageAutoDeleteTimerChanged(
    message_auto_delete_time: message_auto_delete_time,
  ))
}

pub fn chat_boost_added_decoder() -> decode.Decoder(ChatBoostAdded) {
  use boost_count <- decode.field("boost_count", decode.int)
  decode.success(ChatBoostAdded(boost_count: boost_count))
}

pub fn background_fill_solid_decoder() -> decode.Decoder(BackgroundFillSolid) {
  use type_ <- decode.field("type_", decode.string)
  use color <- decode.field("color", decode.int)
  decode.success(BackgroundFillSolid(type_: type_, color: color))
}

pub fn background_fill_gradient_decoder() -> decode.Decoder(
  BackgroundFillGradient,
) {
  use type_ <- decode.field("type_", decode.string)
  use top_color <- decode.field("top_color", decode.int)
  use bottom_color <- decode.field("bottom_color", decode.int)
  use rotation_angle <- decode.field("rotation_angle", decode.int)
  decode.success(BackgroundFillGradient(
    type_: type_,
    top_color: top_color,
    bottom_color: bottom_color,
    rotation_angle: rotation_angle,
  ))
}

pub fn background_fill_freeform_gradient_decoder() -> decode.Decoder(
  BackgroundFillFreeformGradient,
) {
  use type_ <- decode.field("type_", decode.string)
  use colors <- decode.field("colors", decode.list(decode.int))
  decode.success(BackgroundFillFreeformGradient(type_: type_, colors: colors))
}

pub fn background_type_fill_decoder() -> decode.Decoder(BackgroundTypeFill) {
  use type_ <- decode.field("type_", decode.string)
  use fill <- decode.field("fill", background_fill_decoder())
  use dark_theme_dimming <- decode.field("dark_theme_dimming", decode.int)
  decode.success(BackgroundTypeFill(
    type_: type_,
    fill: fill,
    dark_theme_dimming: dark_theme_dimming,
  ))
}

pub fn background_type_wallpaper_decoder() -> decode.Decoder(
  BackgroundTypeWallpaper,
) {
  use type_ <- decode.field("type_", decode.string)
  use document <- decode.field("document", document_decoder())
  use dark_theme_dimming <- decode.field("dark_theme_dimming", decode.int)
  use is_blurred <- decode.field("is_blurred", decode.optional(decode.bool))
  use is_moving <- decode.field("is_moving", decode.optional(decode.bool))
  decode.success(BackgroundTypeWallpaper(
    type_: type_,
    document: document,
    dark_theme_dimming: dark_theme_dimming,
    is_blurred: is_blurred,
    is_moving: is_moving,
  ))
}

pub fn background_type_pattern_decoder() -> decode.Decoder(
  BackgroundTypePattern,
) {
  use type_ <- decode.field("type_", decode.string)
  use document <- decode.field("document", document_decoder())
  use fill <- decode.field("fill", background_fill_decoder())
  use intensity <- decode.field("intensity", decode.int)
  use is_inverted <- decode.field("is_inverted", decode.optional(decode.bool))
  use is_moving <- decode.field("is_moving", decode.optional(decode.bool))
  decode.success(BackgroundTypePattern(
    type_: type_,
    document: document,
    fill: fill,
    intensity: intensity,
    is_inverted: is_inverted,
    is_moving: is_moving,
  ))
}

pub fn background_type_chat_theme_decoder() -> decode.Decoder(
  BackgroundTypeChatTheme,
) {
  use type_ <- decode.field("type_", decode.string)
  use theme_name <- decode.field("theme_name", decode.string)
  decode.success(BackgroundTypeChatTheme(type_: type_, theme_name: theme_name))
}

pub fn chat_background_decoder() -> decode.Decoder(ChatBackground) {
  use type_ <- decode.field("type_", background_type_decoder())
  decode.success(ChatBackground(type_: type_))
}

pub fn forum_topic_created_decoder() -> decode.Decoder(ForumTopicCreated) {
  use name <- decode.field("name", decode.string)
  use icon_color <- decode.field("icon_color", decode.int)
  use icon_custom_emoji_id <- decode.field(
    "icon_custom_emoji_id",
    decode.optional(decode.string),
  )
  decode.success(ForumTopicCreated(
    name: name,
    icon_color: icon_color,
    icon_custom_emoji_id: icon_custom_emoji_id,
  ))
}

pub fn forum_topic_closed_decoder() -> decode.Decoder(ForumTopicClosed) {
  decode.success(ForumTopicClosed)
}

pub fn forum_topic_edited_decoder() -> decode.Decoder(ForumTopicEdited) {
  use name <- decode.field("name", decode.optional(decode.string))
  use icon_custom_emoji_id <- decode.field(
    "icon_custom_emoji_id",
    decode.optional(decode.string),
  )
  decode.success(ForumTopicEdited(
    name: name,
    icon_custom_emoji_id: icon_custom_emoji_id,
  ))
}

pub fn forum_topic_reopened_decoder() -> decode.Decoder(ForumTopicReopened) {
  decode.success(ForumTopicReopened)
}

pub fn general_forum_topic_hidden_decoder() -> decode.Decoder(
  GeneralForumTopicHidden,
) {
  decode.success(GeneralForumTopicHidden)
}

pub fn general_forum_topic_unhidden_decoder() -> decode.Decoder(
  GeneralForumTopicUnhidden,
) {
  decode.success(GeneralForumTopicUnhidden)
}

pub fn shared_user_decoder() -> decode.Decoder(SharedUser) {
  use user_id <- decode.field("user_id", decode.int)
  use first_name <- decode.field("first_name", decode.optional(decode.string))
  use last_name <- decode.field("last_name", decode.optional(decode.string))
  use username <- decode.field("username", decode.optional(decode.string))
  use photo <- decode.field(
    "photo",
    decode.optional(decode.list(photo_size_decoder())),
  )
  decode.success(SharedUser(
    user_id: user_id,
    first_name: first_name,
    last_name: last_name,
    username: username,
    photo: photo,
  ))
}

pub fn users_shared_decoder() -> decode.Decoder(UsersShared) {
  use request_id <- decode.field("request_id", decode.int)
  use users <- decode.field("users", decode.list(shared_user_decoder()))
  decode.success(UsersShared(request_id: request_id, users: users))
}

pub fn chat_shared_decoder() -> decode.Decoder(ChatShared) {
  use request_id <- decode.field("request_id", decode.int)
  use chat_id <- decode.field("chat_id", decode.int)
  use title <- decode.field("title", decode.optional(decode.string))
  use username <- decode.field("username", decode.optional(decode.string))
  use photo <- decode.field(
    "photo",
    decode.optional(decode.list(photo_size_decoder())),
  )
  decode.success(ChatShared(
    request_id: request_id,
    chat_id: chat_id,
    title: title,
    username: username,
    photo: photo,
  ))
}

pub fn write_access_allowed_decoder() -> decode.Decoder(WriteAccessAllowed) {
  use from_request <- decode.field("from_request", decode.optional(decode.bool))
  use web_app_name <- decode.field(
    "web_app_name",
    decode.optional(decode.string),
  )
  use from_attachment_menu <- decode.field(
    "from_attachment_menu",
    decode.optional(decode.bool),
  )
  decode.success(WriteAccessAllowed(
    from_request: from_request,
    web_app_name: web_app_name,
    from_attachment_menu: from_attachment_menu,
  ))
}

pub fn video_chat_scheduled_decoder() -> decode.Decoder(VideoChatScheduled) {
  use start_date <- decode.field("start_date", decode.int)
  decode.success(VideoChatScheduled(start_date: start_date))
}

pub fn video_chat_started_decoder() -> decode.Decoder(VideoChatStarted) {
  decode.success(VideoChatStarted)
}

pub fn video_chat_ended_decoder() -> decode.Decoder(VideoChatEnded) {
  use duration <- decode.field("duration", decode.int)
  decode.success(VideoChatEnded(duration: duration))
}

pub fn video_chat_participants_invited_decoder() -> decode.Decoder(
  VideoChatParticipantsInvited,
) {
  use users <- decode.field("users", decode.list(user_decoder()))
  decode.success(VideoChatParticipantsInvited(users: users))
}

pub fn giveaway_created_decoder() -> decode.Decoder(GiveawayCreated) {
  use prize_star_count <- decode.field(
    "prize_star_count",
    decode.optional(decode.int),
  )
  decode.success(GiveawayCreated(prize_star_count: prize_star_count))
}

pub fn giveaway_decoder() -> decode.Decoder(Giveaway) {
  use chats <- decode.field("chats", decode.list(chat_decoder()))
  use winners_selection_date <- decode.field(
    "winners_selection_date",
    decode.int,
  )
  use winner_count <- decode.field("winner_count", decode.int)
  use only_new_members <- decode.field(
    "only_new_members",
    decode.optional(decode.bool),
  )
  use has_public_winners <- decode.field(
    "has_public_winners",
    decode.optional(decode.bool),
  )
  use prize_description <- decode.field(
    "prize_description",
    decode.optional(decode.string),
  )
  use country_codes <- decode.field(
    "country_codes",
    decode.optional(decode.list(decode.string)),
  )
  use prize_star_count <- decode.field(
    "prize_star_count",
    decode.optional(decode.int),
  )
  use premium_subscription_month_count <- decode.field(
    "premium_subscription_month_count",
    decode.optional(decode.int),
  )
  decode.success(Giveaway(
    chats: chats,
    winners_selection_date: winners_selection_date,
    winner_count: winner_count,
    only_new_members: only_new_members,
    has_public_winners: has_public_winners,
    prize_description: prize_description,
    country_codes: country_codes,
    prize_star_count: prize_star_count,
    premium_subscription_month_count: premium_subscription_month_count,
  ))
}

pub fn giveaway_winners_decoder() -> decode.Decoder(GiveawayWinners) {
  use chat <- decode.field("chat", chat_decoder())
  use giveaway_message_id <- decode.field("giveaway_message_id", decode.int)
  use winners_selection_date <- decode.field(
    "winners_selection_date",
    decode.int,
  )
  use winner_count <- decode.field("winner_count", decode.int)
  use winners <- decode.field("winners", decode.list(user_decoder()))
  use additional_chat_count <- decode.field(
    "additional_chat_count",
    decode.optional(decode.int),
  )
  use prize_star_count <- decode.field(
    "prize_star_count",
    decode.optional(decode.int),
  )
  use premium_subscription_month_count <- decode.field(
    "premium_subscription_month_count",
    decode.optional(decode.int),
  )
  use unclaimed_prize_count <- decode.field(
    "unclaimed_prize_count",
    decode.optional(decode.int),
  )
  use only_new_members <- decode.field(
    "only_new_members",
    decode.optional(decode.bool),
  )
  use was_refunded <- decode.field("was_refunded", decode.optional(decode.bool))
  use prize_description <- decode.field(
    "prize_description",
    decode.optional(decode.string),
  )
  decode.success(GiveawayWinners(
    chat: chat,
    giveaway_message_id: giveaway_message_id,
    winners_selection_date: winners_selection_date,
    winner_count: winner_count,
    winners: winners,
    additional_chat_count: additional_chat_count,
    prize_star_count: prize_star_count,
    premium_subscription_month_count: premium_subscription_month_count,
    unclaimed_prize_count: unclaimed_prize_count,
    only_new_members: only_new_members,
    was_refunded: was_refunded,
    prize_description: prize_description,
  ))
}

pub fn giveaway_completed_decoder() -> decode.Decoder(GiveawayCompleted) {
  use winner_count <- decode.field("winner_count", decode.int)
  use unclaimed_prize_count <- decode.field(
    "unclaimed_prize_count",
    decode.optional(decode.int),
  )
  use giveaway_message <- decode.field(
    "giveaway_message",
    decode.optional(message_decoder()),
  )
  use is_star_giveaway <- decode.field(
    "is_star_giveaway",
    decode.optional(decode.bool),
  )
  decode.success(GiveawayCompleted(
    winner_count: winner_count,
    unclaimed_prize_count: unclaimed_prize_count,
    giveaway_message: giveaway_message,
    is_star_giveaway: is_star_giveaway,
  ))
}

pub fn link_preview_options_decoder() -> decode.Decoder(LinkPreviewOptions) {
  use is_disabled <- decode.field("is_disabled", decode.optional(decode.bool))
  use url <- decode.field("url", decode.optional(decode.string))
  use prefer_small_media <- decode.field(
    "prefer_small_media",
    decode.optional(decode.bool),
  )
  use prefer_large_media <- decode.field(
    "prefer_large_media",
    decode.optional(decode.bool),
  )
  use show_above_text <- decode.field(
    "show_above_text",
    decode.optional(decode.bool),
  )
  decode.success(LinkPreviewOptions(
    is_disabled: is_disabled,
    url: url,
    prefer_small_media: prefer_small_media,
    prefer_large_media: prefer_large_media,
    show_above_text: show_above_text,
  ))
}

pub fn user_profile_photos_decoder() -> decode.Decoder(UserProfilePhotos) {
  use total_count <- decode.field("total_count", decode.int)
  use photos <- decode.field(
    "photos",
    decode.list(decode.list(photo_size_decoder())),
  )
  decode.success(UserProfilePhotos(total_count: total_count, photos: photos))
}

pub fn file_decoder() -> decode.Decoder(File) {
  use file_id <- decode.field("file_id", decode.string)
  use file_unique_id <- decode.field("file_unique_id", decode.string)
  use file_size <- decode.field("file_size", decode.optional(decode.int))
  use file_path <- decode.field("file_path", decode.optional(decode.string))
  decode.success(File(
    file_id: file_id,
    file_unique_id: file_unique_id,
    file_size: file_size,
    file_path: file_path,
  ))
}

pub fn web_app_info_decoder() -> decode.Decoder(WebAppInfo) {
  use url <- decode.field("url", decode.string)
  decode.success(WebAppInfo(url: url))
}

pub fn reply_keyboard_markup_decoder() -> decode.Decoder(ReplyKeyboardMarkup) {
  use keyboard <- decode.field(
    "keyboard",
    decode.list(decode.list(keyboard_button_decoder())),
  )
  use is_persistent <- decode.field(
    "is_persistent",
    decode.optional(decode.bool),
  )
  use resize_keyboard <- decode.field(
    "resize_keyboard",
    decode.optional(decode.bool),
  )
  use one_time_keyboard <- decode.field(
    "one_time_keyboard",
    decode.optional(decode.bool),
  )
  use input_field_placeholder <- decode.field(
    "input_field_placeholder",
    decode.optional(decode.string),
  )
  use selective <- decode.field("selective", decode.optional(decode.bool))
  decode.success(ReplyKeyboardMarkup(
    keyboard: keyboard,
    is_persistent: is_persistent,
    resize_keyboard: resize_keyboard,
    one_time_keyboard: one_time_keyboard,
    input_field_placeholder: input_field_placeholder,
    selective: selective,
  ))
}

pub fn keyboard_button_decoder() -> decode.Decoder(KeyboardButton) {
  use text <- decode.field("text", decode.string)
  use request_users <- decode.field(
    "request_users",
    decode.optional(keyboard_button_request_users_decoder()),
  )
  use request_chat <- decode.field(
    "request_chat",
    decode.optional(keyboard_button_request_chat_decoder()),
  )
  use request_contact <- decode.field(
    "request_contact",
    decode.optional(decode.bool),
  )
  use request_location <- decode.field(
    "request_location",
    decode.optional(decode.bool),
  )
  use request_poll <- decode.field(
    "request_poll",
    decode.optional(keyboard_button_poll_type_decoder()),
  )
  use web_app <- decode.field(
    "web_app",
    decode.optional(web_app_info_decoder()),
  )
  decode.success(KeyboardButton(
    text: text,
    request_users: request_users,
    request_chat: request_chat,
    request_contact: request_contact,
    request_location: request_location,
    request_poll: request_poll,
    web_app: web_app,
  ))
}

pub fn keyboard_button_request_users_decoder() -> decode.Decoder(
  KeyboardButtonRequestUsers,
) {
  use request_id <- decode.field("request_id", decode.int)
  use user_is_bot <- decode.field("user_is_bot", decode.optional(decode.bool))
  use user_is_premium <- decode.field(
    "user_is_premium",
    decode.optional(decode.bool),
  )
  use max_quantity <- decode.field("max_quantity", decode.optional(decode.int))
  use request_name <- decode.field("request_name", decode.optional(decode.bool))
  use request_username <- decode.field(
    "request_username",
    decode.optional(decode.bool),
  )
  use request_photo <- decode.field(
    "request_photo",
    decode.optional(decode.bool),
  )
  decode.success(KeyboardButtonRequestUsers(
    request_id: request_id,
    user_is_bot: user_is_bot,
    user_is_premium: user_is_premium,
    max_quantity: max_quantity,
    request_name: request_name,
    request_username: request_username,
    request_photo: request_photo,
  ))
}

pub fn keyboard_button_request_chat_decoder() -> decode.Decoder(
  KeyboardButtonRequestChat,
) {
  use request_id <- decode.field("request_id", decode.int)
  use chat_is_channel <- decode.field("chat_is_channel", decode.bool)
  use chat_is_forum <- decode.field(
    "chat_is_forum",
    decode.optional(decode.bool),
  )
  use chat_has_username <- decode.field(
    "chat_has_username",
    decode.optional(decode.bool),
  )
  use chat_is_created <- decode.field(
    "chat_is_created",
    decode.optional(decode.bool),
  )
  use user_administrator_rights <- decode.field(
    "user_administrator_rights",
    decode.optional(chat_administrator_rights_decoder()),
  )
  use bot_administrator_rights <- decode.field(
    "bot_administrator_rights",
    decode.optional(chat_administrator_rights_decoder()),
  )
  use bot_is_member <- decode.field(
    "bot_is_member",
    decode.optional(decode.bool),
  )
  use request_title <- decode.field(
    "request_title",
    decode.optional(decode.bool),
  )
  use request_username <- decode.field(
    "request_username",
    decode.optional(decode.bool),
  )
  use request_photo <- decode.field(
    "request_photo",
    decode.optional(decode.bool),
  )
  decode.success(KeyboardButtonRequestChat(
    request_id: request_id,
    chat_is_channel: chat_is_channel,
    chat_is_forum: chat_is_forum,
    chat_has_username: chat_has_username,
    chat_is_created: chat_is_created,
    user_administrator_rights: user_administrator_rights,
    bot_administrator_rights: bot_administrator_rights,
    bot_is_member: bot_is_member,
    request_title: request_title,
    request_username: request_username,
    request_photo: request_photo,
  ))
}

pub fn keyboard_button_poll_type_decoder() -> decode.Decoder(
  KeyboardButtonPollType,
) {
  use type_ <- decode.field("type_", decode.optional(decode.string))
  decode.success(KeyboardButtonPollType(type_: type_))
}

pub fn reply_keyboard_remove_decoder() -> decode.Decoder(ReplyKeyboardRemove) {
  use remove_keyboard <- decode.field("remove_keyboard", decode.bool)
  use selective <- decode.field("selective", decode.optional(decode.bool))
  decode.success(ReplyKeyboardRemove(
    remove_keyboard: remove_keyboard,
    selective: selective,
  ))
}

pub fn inline_keyboard_markup_decoder() -> decode.Decoder(InlineKeyboardMarkup) {
  use inline_keyboard <- decode.field(
    "inline_keyboard",
    decode.list(decode.list(inline_keyboard_button_decoder())),
  )
  decode.success(InlineKeyboardMarkup(inline_keyboard: inline_keyboard))
}

pub fn inline_keyboard_button_decoder() -> decode.Decoder(InlineKeyboardButton) {
  use text <- decode.field("text", decode.string)
  use url <- decode.field("url", decode.optional(decode.string))
  use callback_data <- decode.field(
    "callback_data",
    decode.optional(decode.string),
  )
  use web_app <- decode.field(
    "web_app",
    decode.optional(web_app_info_decoder()),
  )
  use login_url <- decode.field(
    "login_url",
    decode.optional(login_url_decoder()),
  )
  use switch_inline_query <- decode.field(
    "switch_inline_query",
    decode.optional(decode.string),
  )
  use switch_inline_query_current_chat <- decode.field(
    "switch_inline_query_current_chat",
    decode.optional(decode.string),
  )
  use switch_inline_query_chosen_chat <- decode.field(
    "switch_inline_query_chosen_chat",
    decode.optional(switch_inline_query_chosen_chat_decoder()),
  )
  use copy_text <- decode.field(
    "copy_text",
    decode.optional(copy_text_button_decoder()),
  )
  use callback_game <- decode.field(
    "callback_game",
    decode.optional(callback_game_decoder()),
  )
  use pay <- decode.field("pay", decode.optional(decode.bool))
  decode.success(InlineKeyboardButton(
    text: text,
    url: url,
    callback_data: callback_data,
    web_app: web_app,
    login_url: login_url,
    switch_inline_query: switch_inline_query,
    switch_inline_query_current_chat: switch_inline_query_current_chat,
    switch_inline_query_chosen_chat: switch_inline_query_chosen_chat,
    copy_text: copy_text,
    callback_game: callback_game,
    pay: pay,
  ))
}

pub fn login_url_decoder() -> decode.Decoder(LoginUrl) {
  use url <- decode.field("url", decode.string)
  use forward_text <- decode.field(
    "forward_text",
    decode.optional(decode.string),
  )
  use bot_username <- decode.field(
    "bot_username",
    decode.optional(decode.string),
  )
  use request_write_access <- decode.field(
    "request_write_access",
    decode.optional(decode.bool),
  )
  decode.success(LoginUrl(
    url: url,
    forward_text: forward_text,
    bot_username: bot_username,
    request_write_access: request_write_access,
  ))
}

pub fn switch_inline_query_chosen_chat_decoder() -> decode.Decoder(
  SwitchInlineQueryChosenChat,
) {
  use query <- decode.field("query", decode.optional(decode.string))
  use allow_user_chats <- decode.field(
    "allow_user_chats",
    decode.optional(decode.bool),
  )
  use allow_bot_chats <- decode.field(
    "allow_bot_chats",
    decode.optional(decode.bool),
  )
  use allow_group_chats <- decode.field(
    "allow_group_chats",
    decode.optional(decode.bool),
  )
  use allow_channel_chats <- decode.field(
    "allow_channel_chats",
    decode.optional(decode.bool),
  )
  decode.success(SwitchInlineQueryChosenChat(
    query: query,
    allow_user_chats: allow_user_chats,
    allow_bot_chats: allow_bot_chats,
    allow_group_chats: allow_group_chats,
    allow_channel_chats: allow_channel_chats,
  ))
}

pub fn copy_text_button_decoder() -> decode.Decoder(CopyTextButton) {
  use text <- decode.field("text", decode.string)
  decode.success(CopyTextButton(text: text))
}

pub fn callback_query_decoder() -> decode.Decoder(CallbackQuery) {
  use id <- decode.field("id", decode.string)
  use from <- decode.field("from", user_decoder())
  use message <- decode.field(
    "message",
    decode.optional(maybe_inaccessible_message_decoder()),
  )
  use inline_message_id <- decode.field(
    "inline_message_id",
    decode.optional(decode.string),
  )
  use chat_instance <- decode.field("chat_instance", decode.string)
  use data <- decode.field("data", decode.optional(decode.string))
  use game_short_name <- decode.field(
    "game_short_name",
    decode.optional(decode.string),
  )
  decode.success(CallbackQuery(
    id: id,
    from: from,
    message: message,
    inline_message_id: inline_message_id,
    chat_instance: chat_instance,
    data: data,
    game_short_name: game_short_name,
  ))
}

pub fn force_reply_decoder() -> decode.Decoder(ForceReply) {
  use force_reply <- decode.field("force_reply", decode.bool)
  use input_field_placeholder <- decode.field(
    "input_field_placeholder",
    decode.optional(decode.string),
  )
  use selective <- decode.field("selective", decode.optional(decode.bool))
  decode.success(ForceReply(
    force_reply: force_reply,
    input_field_placeholder: input_field_placeholder,
    selective: selective,
  ))
}

pub fn chat_photo_decoder() -> decode.Decoder(ChatPhoto) {
  use small_file_id <- decode.field("small_file_id", decode.string)
  use small_file_unique_id <- decode.field(
    "small_file_unique_id",
    decode.string,
  )
  use big_file_id <- decode.field("big_file_id", decode.string)
  use big_file_unique_id <- decode.field("big_file_unique_id", decode.string)
  decode.success(ChatPhoto(
    small_file_id: small_file_id,
    small_file_unique_id: small_file_unique_id,
    big_file_id: big_file_id,
    big_file_unique_id: big_file_unique_id,
  ))
}

pub fn chat_invite_link_decoder() -> decode.Decoder(ChatInviteLink) {
  use invite_link <- decode.field("invite_link", decode.string)
  use creator <- decode.field("creator", user_decoder())
  use creates_join_request <- decode.field("creates_join_request", decode.bool)
  use is_primary <- decode.field("is_primary", decode.bool)
  use is_revoked <- decode.field("is_revoked", decode.bool)
  use name <- decode.field("name", decode.optional(decode.string))
  use expire_date <- decode.field("expire_date", decode.optional(decode.int))
  use member_limit <- decode.field("member_limit", decode.optional(decode.int))
  use pending_join_request_count <- decode.field(
    "pending_join_request_count",
    decode.optional(decode.int),
  )
  use subscription_period <- decode.field(
    "subscription_period",
    decode.optional(decode.int),
  )
  use subscription_price <- decode.field(
    "subscription_price",
    decode.optional(decode.int),
  )
  decode.success(ChatInviteLink(
    invite_link: invite_link,
    creator: creator,
    creates_join_request: creates_join_request,
    is_primary: is_primary,
    is_revoked: is_revoked,
    name: name,
    expire_date: expire_date,
    member_limit: member_limit,
    pending_join_request_count: pending_join_request_count,
    subscription_period: subscription_period,
    subscription_price: subscription_price,
  ))
}

pub fn chat_administrator_rights_decoder() -> decode.Decoder(
  ChatAdministratorRights,
) {
  use is_anonymous <- decode.field("is_anonymous", decode.bool)
  use can_manage_chat <- decode.field("can_manage_chat", decode.bool)
  use can_delete_messages <- decode.field("can_delete_messages", decode.bool)
  use can_manage_video_chats <- decode.field(
    "can_manage_video_chats",
    decode.bool,
  )
  use can_restrict_members <- decode.field("can_restrict_members", decode.bool)
  use can_promote_members <- decode.field("can_promote_members", decode.bool)
  use can_change_info <- decode.field("can_change_info", decode.bool)
  use can_invite_users <- decode.field("can_invite_users", decode.bool)
  use can_post_stories <- decode.field("can_post_stories", decode.bool)
  use can_edit_stories <- decode.field("can_edit_stories", decode.bool)
  use can_delete_stories <- decode.field("can_delete_stories", decode.bool)
  use can_post_messages <- decode.field(
    "can_post_messages",
    decode.optional(decode.bool),
  )
  use can_edit_messages <- decode.field(
    "can_edit_messages",
    decode.optional(decode.bool),
  )
  use can_pin_messages <- decode.field(
    "can_pin_messages",
    decode.optional(decode.bool),
  )
  use can_manage_topics <- decode.field(
    "can_manage_topics",
    decode.optional(decode.bool),
  )
  decode.success(ChatAdministratorRights(
    is_anonymous: is_anonymous,
    can_manage_chat: can_manage_chat,
    can_delete_messages: can_delete_messages,
    can_manage_video_chats: can_manage_video_chats,
    can_restrict_members: can_restrict_members,
    can_promote_members: can_promote_members,
    can_change_info: can_change_info,
    can_invite_users: can_invite_users,
    can_post_stories: can_post_stories,
    can_edit_stories: can_edit_stories,
    can_delete_stories: can_delete_stories,
    can_post_messages: can_post_messages,
    can_edit_messages: can_edit_messages,
    can_pin_messages: can_pin_messages,
    can_manage_topics: can_manage_topics,
  ))
}

pub fn chat_member_updated_decoder() -> decode.Decoder(ChatMemberUpdated) {
  use chat <- decode.field("chat", chat_decoder())
  use from <- decode.field("from", user_decoder())
  use date <- decode.field("date", decode.int)
  use old_chat_member <- decode.field("old_chat_member", chat_member_decoder())
  use new_chat_member <- decode.field("new_chat_member", chat_member_decoder())
  use invite_link <- decode.field(
    "invite_link",
    decode.optional(chat_invite_link_decoder()),
  )
  use via_join_request <- decode.field(
    "via_join_request",
    decode.optional(decode.bool),
  )
  use via_chat_folder_invite_link <- decode.field(
    "via_chat_folder_invite_link",
    decode.optional(decode.bool),
  )
  decode.success(ChatMemberUpdated(
    chat: chat,
    from: from,
    date: date,
    old_chat_member: old_chat_member,
    new_chat_member: new_chat_member,
    invite_link: invite_link,
    via_join_request: via_join_request,
    via_chat_folder_invite_link: via_chat_folder_invite_link,
  ))
}

pub fn chat_member_owner_decoder() -> decode.Decoder(ChatMemberOwner) {
  use status <- decode.field("status", decode.string)
  use user <- decode.field("user", user_decoder())
  use is_anonymous <- decode.field("is_anonymous", decode.bool)
  use custom_title <- decode.field(
    "custom_title",
    decode.optional(decode.string),
  )
  decode.success(ChatMemberOwner(
    status: status,
    user: user,
    is_anonymous: is_anonymous,
    custom_title: custom_title,
  ))
}

pub fn chat_member_administrator_decoder() -> decode.Decoder(
  ChatMemberAdministrator,
) {
  use status <- decode.field("status", decode.string)
  use user <- decode.field("user", user_decoder())
  use can_be_edited <- decode.field("can_be_edited", decode.bool)
  use is_anonymous <- decode.field("is_anonymous", decode.bool)
  use can_manage_chat <- decode.field("can_manage_chat", decode.bool)
  use can_delete_messages <- decode.field("can_delete_messages", decode.bool)
  use can_manage_video_chats <- decode.field(
    "can_manage_video_chats",
    decode.bool,
  )
  use can_restrict_members <- decode.field("can_restrict_members", decode.bool)
  use can_promote_members <- decode.field("can_promote_members", decode.bool)
  use can_change_info <- decode.field("can_change_info", decode.bool)
  use can_invite_users <- decode.field("can_invite_users", decode.bool)
  use can_post_stories <- decode.field("can_post_stories", decode.bool)
  use can_edit_stories <- decode.field("can_edit_stories", decode.bool)
  use can_delete_stories <- decode.field("can_delete_stories", decode.bool)
  use can_post_messages <- decode.field(
    "can_post_messages",
    decode.optional(decode.bool),
  )
  use can_edit_messages <- decode.field(
    "can_edit_messages",
    decode.optional(decode.bool),
  )
  use can_pin_messages <- decode.field(
    "can_pin_messages",
    decode.optional(decode.bool),
  )
  use can_manage_topics <- decode.field(
    "can_manage_topics",
    decode.optional(decode.bool),
  )
  use custom_title <- decode.field(
    "custom_title",
    decode.optional(decode.string),
  )
  decode.success(ChatMemberAdministrator(
    status: status,
    user: user,
    can_be_edited: can_be_edited,
    is_anonymous: is_anonymous,
    can_manage_chat: can_manage_chat,
    can_delete_messages: can_delete_messages,
    can_manage_video_chats: can_manage_video_chats,
    can_restrict_members: can_restrict_members,
    can_promote_members: can_promote_members,
    can_change_info: can_change_info,
    can_invite_users: can_invite_users,
    can_post_stories: can_post_stories,
    can_edit_stories: can_edit_stories,
    can_delete_stories: can_delete_stories,
    can_post_messages: can_post_messages,
    can_edit_messages: can_edit_messages,
    can_pin_messages: can_pin_messages,
    can_manage_topics: can_manage_topics,
    custom_title: custom_title,
  ))
}

pub fn chat_member_member_decoder() -> decode.Decoder(ChatMemberMember) {
  use status <- decode.field("status", decode.string)
  use user <- decode.field("user", user_decoder())
  use until_date <- decode.field("until_date", decode.optional(decode.int))
  decode.success(ChatMemberMember(
    status: status,
    user: user,
    until_date: until_date,
  ))
}

pub fn chat_member_restricted_decoder() -> decode.Decoder(ChatMemberRestricted) {
  use status <- decode.field("status", decode.string)
  use user <- decode.field("user", user_decoder())
  use is_member <- decode.field("is_member", decode.bool)
  use can_send_messages <- decode.field("can_send_messages", decode.bool)
  use can_send_audios <- decode.field("can_send_audios", decode.bool)
  use can_send_documents <- decode.field("can_send_documents", decode.bool)
  use can_send_photos <- decode.field("can_send_photos", decode.bool)
  use can_send_videos <- decode.field("can_send_videos", decode.bool)
  use can_send_video_notes <- decode.field("can_send_video_notes", decode.bool)
  use can_send_voice_notes <- decode.field("can_send_voice_notes", decode.bool)
  use can_send_polls <- decode.field("can_send_polls", decode.bool)
  use can_send_other_messages <- decode.field(
    "can_send_other_messages",
    decode.bool,
  )
  use can_add_web_page_previews <- decode.field(
    "can_add_web_page_previews",
    decode.bool,
  )
  use can_change_info <- decode.field("can_change_info", decode.bool)
  use can_invite_users <- decode.field("can_invite_users", decode.bool)
  use can_pin_messages <- decode.field("can_pin_messages", decode.bool)
  use can_manage_topics <- decode.field("can_manage_topics", decode.bool)
  use until_date <- decode.field("until_date", decode.int)
  decode.success(ChatMemberRestricted(
    status: status,
    user: user,
    is_member: is_member,
    can_send_messages: can_send_messages,
    can_send_audios: can_send_audios,
    can_send_documents: can_send_documents,
    can_send_photos: can_send_photos,
    can_send_videos: can_send_videos,
    can_send_video_notes: can_send_video_notes,
    can_send_voice_notes: can_send_voice_notes,
    can_send_polls: can_send_polls,
    can_send_other_messages: can_send_other_messages,
    can_add_web_page_previews: can_add_web_page_previews,
    can_change_info: can_change_info,
    can_invite_users: can_invite_users,
    can_pin_messages: can_pin_messages,
    can_manage_topics: can_manage_topics,
    until_date: until_date,
  ))
}

pub fn chat_member_left_decoder() -> decode.Decoder(ChatMemberLeft) {
  use status <- decode.field("status", decode.string)
  use user <- decode.field("user", user_decoder())
  decode.success(ChatMemberLeft(status: status, user: user))
}

pub fn chat_member_banned_decoder() -> decode.Decoder(ChatMemberBanned) {
  use status <- decode.field("status", decode.string)
  use user <- decode.field("user", user_decoder())
  use until_date <- decode.field("until_date", decode.int)
  decode.success(ChatMemberBanned(
    status: status,
    user: user,
    until_date: until_date,
  ))
}

pub fn chat_join_request_decoder() -> decode.Decoder(ChatJoinRequest) {
  use chat <- decode.field("chat", chat_decoder())
  use from <- decode.field("from", user_decoder())
  use user_chat_id <- decode.field("user_chat_id", decode.int)
  use date <- decode.field("date", decode.int)
  use bio <- decode.field("bio", decode.optional(decode.string))
  use invite_link <- decode.field(
    "invite_link",
    decode.optional(chat_invite_link_decoder()),
  )
  decode.success(ChatJoinRequest(
    chat: chat,
    from: from,
    user_chat_id: user_chat_id,
    date: date,
    bio: bio,
    invite_link: invite_link,
  ))
}

pub fn chat_permissions_decoder() -> decode.Decoder(ChatPermissions) {
  use can_send_messages <- decode.field(
    "can_send_messages",
    decode.optional(decode.bool),
  )
  use can_send_audios <- decode.field(
    "can_send_audios",
    decode.optional(decode.bool),
  )
  use can_send_documents <- decode.field(
    "can_send_documents",
    decode.optional(decode.bool),
  )
  use can_send_photos <- decode.field(
    "can_send_photos",
    decode.optional(decode.bool),
  )
  use can_send_videos <- decode.field(
    "can_send_videos",
    decode.optional(decode.bool),
  )
  use can_send_video_notes <- decode.field(
    "can_send_video_notes",
    decode.optional(decode.bool),
  )
  use can_send_voice_notes <- decode.field(
    "can_send_voice_notes",
    decode.optional(decode.bool),
  )
  use can_send_polls <- decode.field(
    "can_send_polls",
    decode.optional(decode.bool),
  )
  use can_send_other_messages <- decode.field(
    "can_send_other_messages",
    decode.optional(decode.bool),
  )
  use can_add_web_page_previews <- decode.field(
    "can_add_web_page_previews",
    decode.optional(decode.bool),
  )
  use can_change_info <- decode.field(
    "can_change_info",
    decode.optional(decode.bool),
  )
  use can_invite_users <- decode.field(
    "can_invite_users",
    decode.optional(decode.bool),
  )
  use can_pin_messages <- decode.field(
    "can_pin_messages",
    decode.optional(decode.bool),
  )
  use can_manage_topics <- decode.field(
    "can_manage_topics",
    decode.optional(decode.bool),
  )
  decode.success(ChatPermissions(
    can_send_messages: can_send_messages,
    can_send_audios: can_send_audios,
    can_send_documents: can_send_documents,
    can_send_photos: can_send_photos,
    can_send_videos: can_send_videos,
    can_send_video_notes: can_send_video_notes,
    can_send_voice_notes: can_send_voice_notes,
    can_send_polls: can_send_polls,
    can_send_other_messages: can_send_other_messages,
    can_add_web_page_previews: can_add_web_page_previews,
    can_change_info: can_change_info,
    can_invite_users: can_invite_users,
    can_pin_messages: can_pin_messages,
    can_manage_topics: can_manage_topics,
  ))
}

pub fn birthdate_decoder() -> decode.Decoder(Birthdate) {
  use day <- decode.field("day", decode.int)
  use month <- decode.field("month", decode.int)
  use year <- decode.field("year", decode.optional(decode.int))
  decode.success(Birthdate(day: day, month: month, year: year))
}

pub fn business_intro_decoder() -> decode.Decoder(BusinessIntro) {
  use title <- decode.field("title", decode.optional(decode.string))
  use message <- decode.field("message", decode.optional(decode.string))
  use sticker <- decode.field("sticker", decode.optional(sticker_decoder()))
  decode.success(BusinessIntro(title: title, message: message, sticker: sticker))
}

pub fn business_location_decoder() -> decode.Decoder(BusinessLocation) {
  use address <- decode.field("address", decode.string)
  use location <- decode.field("location", decode.optional(location_decoder()))
  decode.success(BusinessLocation(address: address, location: location))
}

pub fn business_opening_hours_interval_decoder() -> decode.Decoder(
  BusinessOpeningHoursInterval,
) {
  use opening_minute <- decode.field("opening_minute", decode.int)
  use closing_minute <- decode.field("closing_minute", decode.int)
  decode.success(BusinessOpeningHoursInterval(
    opening_minute: opening_minute,
    closing_minute: closing_minute,
  ))
}

pub fn business_opening_hours_decoder() -> decode.Decoder(BusinessOpeningHours) {
  use time_zone_name <- decode.field("time_zone_name", decode.string)
  use opening_hours <- decode.field(
    "opening_hours",
    decode.list(business_opening_hours_interval_decoder()),
  )
  decode.success(BusinessOpeningHours(
    time_zone_name: time_zone_name,
    opening_hours: opening_hours,
  ))
}

pub fn chat_location_decoder() -> decode.Decoder(ChatLocation) {
  use location <- decode.field("location", location_decoder())
  use address <- decode.field("address", decode.string)
  decode.success(ChatLocation(location: location, address: address))
}

pub fn reaction_type_emoji_decoder() -> decode.Decoder(ReactionTypeEmoji) {
  use type_ <- decode.field("type_", decode.string)
  use emoji <- decode.field("emoji", decode.string)
  decode.success(ReactionTypeEmoji(type_: type_, emoji: emoji))
}

pub fn reaction_type_custom_emoji_decoder() -> decode.Decoder(
  ReactionTypeCustomEmoji,
) {
  use type_ <- decode.field("type_", decode.string)
  use custom_emoji_id <- decode.field("custom_emoji_id", decode.string)
  decode.success(ReactionTypeCustomEmoji(
    type_: type_,
    custom_emoji_id: custom_emoji_id,
  ))
}

pub fn reaction_type_paid_decoder() -> decode.Decoder(ReactionTypePaid) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(ReactionTypePaid(type_: type_))
}

pub fn reaction_count_decoder() -> decode.Decoder(ReactionCount) {
  use type_ <- decode.field("type_", reaction_type_decoder())
  use total_count <- decode.field("total_count", decode.int)
  decode.success(ReactionCount(type_: type_, total_count: total_count))
}

pub fn message_reaction_updated_decoder() -> decode.Decoder(
  MessageReactionUpdated,
) {
  use chat <- decode.field("chat", chat_decoder())
  use message_id <- decode.field("message_id", decode.int)
  use user <- decode.field("user", decode.optional(user_decoder()))
  use actor_chat <- decode.field("actor_chat", decode.optional(chat_decoder()))
  use date <- decode.field("date", decode.int)
  use old_reaction <- decode.field(
    "old_reaction",
    decode.list(reaction_type_decoder()),
  )
  use new_reaction <- decode.field(
    "new_reaction",
    decode.list(reaction_type_decoder()),
  )
  decode.success(MessageReactionUpdated(
    chat: chat,
    message_id: message_id,
    user: user,
    actor_chat: actor_chat,
    date: date,
    old_reaction: old_reaction,
    new_reaction: new_reaction,
  ))
}

pub fn message_reaction_count_updated_decoder() -> decode.Decoder(
  MessageReactionCountUpdated,
) {
  use chat <- decode.field("chat", chat_decoder())
  use message_id <- decode.field("message_id", decode.int)
  use date <- decode.field("date", decode.int)
  use reactions <- decode.field(
    "reactions",
    decode.list(reaction_count_decoder()),
  )
  decode.success(MessageReactionCountUpdated(
    chat: chat,
    message_id: message_id,
    date: date,
    reactions: reactions,
  ))
}

pub fn forum_topic_decoder() -> decode.Decoder(ForumTopic) {
  use message_thread_id <- decode.field("message_thread_id", decode.int)
  use name <- decode.field("name", decode.string)
  use icon_color <- decode.field("icon_color", decode.int)
  use icon_custom_emoji_id <- decode.field(
    "icon_custom_emoji_id",
    decode.optional(decode.string),
  )
  decode.success(ForumTopic(
    message_thread_id: message_thread_id,
    name: name,
    icon_color: icon_color,
    icon_custom_emoji_id: icon_custom_emoji_id,
  ))
}

pub fn bot_command_decoder() -> decode.Decoder(BotCommand) {
  use command <- decode.field("command", decode.string)
  use description <- decode.field("description", decode.string)
  decode.success(BotCommand(command: command, description: description))
}

pub fn bot_command_scope_default_decoder() -> decode.Decoder(
  BotCommandScopeDefault,
) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(BotCommandScopeDefault(type_: type_))
}

pub fn bot_command_scope_all_private_chats_decoder() -> decode.Decoder(
  BotCommandScopeAllPrivateChats,
) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(BotCommandScopeAllPrivateChats(type_: type_))
}

pub fn bot_command_scope_all_group_chats_decoder() -> decode.Decoder(
  BotCommandScopeAllGroupChats,
) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(BotCommandScopeAllGroupChats(type_: type_))
}

pub fn bot_command_scope_all_chat_administrators_decoder() -> decode.Decoder(
  BotCommandScopeAllChatAdministrators,
) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(BotCommandScopeAllChatAdministrators(type_: type_))
}

pub fn bot_command_scope_chat_decoder() -> decode.Decoder(BotCommandScopeChat) {
  use type_ <- decode.field("type_", decode.string)
  use chat_id <- decode.field("chat_id", int_or_string_decoder())
  decode.success(BotCommandScopeChat(type_: type_, chat_id: chat_id))
}

pub fn bot_command_scope_chat_administrators_decoder() -> decode.Decoder(
  BotCommandScopeChatAdministrators,
) {
  use type_ <- decode.field("type_", decode.string)
  use chat_id <- decode.field("chat_id", int_or_string_decoder())
  decode.success(BotCommandScopeChatAdministrators(
    type_: type_,
    chat_id: chat_id,
  ))
}

pub fn bot_command_scope_chat_member_decoder() -> decode.Decoder(
  BotCommandScopeChatMember,
) {
  use type_ <- decode.field("type_", decode.string)
  use chat_id <- decode.field("chat_id", int_or_string_decoder())
  use user_id <- decode.field("user_id", decode.int)
  decode.success(BotCommandScopeChatMember(
    type_: type_,
    chat_id: chat_id,
    user_id: user_id,
  ))
}

pub fn bot_name_decoder() -> decode.Decoder(BotName) {
  use name <- decode.field("name", decode.string)
  decode.success(BotName(name: name))
}

pub fn bot_description_decoder() -> decode.Decoder(BotDescription) {
  use description <- decode.field("description", decode.string)
  decode.success(BotDescription(description: description))
}

pub fn bot_short_description_decoder() -> decode.Decoder(BotShortDescription) {
  use short_description <- decode.field("short_description", decode.string)
  decode.success(BotShortDescription(short_description: short_description))
}

pub fn menu_button_commands_decoder() -> decode.Decoder(MenuButtonCommands) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(MenuButtonCommands(type_: type_))
}

pub fn menu_button_web_app_decoder() -> decode.Decoder(MenuButtonWebApp) {
  use type_ <- decode.field("type_", decode.string)
  use text <- decode.field("text", decode.string)
  use web_app <- decode.field("web_app", web_app_info_decoder())
  decode.success(MenuButtonWebApp(type_: type_, text: text, web_app: web_app))
}

pub fn menu_button_default_decoder() -> decode.Decoder(MenuButtonDefault) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(MenuButtonDefault(type_: type_))
}

pub fn chat_boost_source_premium_decoder() -> decode.Decoder(
  ChatBoostSourcePremium,
) {
  use source <- decode.field("source", decode.string)
  use user <- decode.field("user", user_decoder())
  decode.success(ChatBoostSourcePremium(source: source, user: user))
}

pub fn chat_boost_source_gift_code_decoder() -> decode.Decoder(
  ChatBoostSourceGiftCode,
) {
  use source <- decode.field("source", decode.string)
  use user <- decode.field("user", user_decoder())
  decode.success(ChatBoostSourceGiftCode(source: source, user: user))
}

pub fn chat_boost_source_giveaway_decoder() -> decode.Decoder(
  ChatBoostSourceGiveaway,
) {
  use source <- decode.field("source", decode.string)
  use giveaway_message_id <- decode.field("giveaway_message_id", decode.int)
  use user <- decode.field("user", decode.optional(user_decoder()))
  use prize_star_count <- decode.field(
    "prize_star_count",
    decode.optional(decode.int),
  )
  use is_unclaimed <- decode.field("is_unclaimed", decode.optional(decode.bool))
  decode.success(ChatBoostSourceGiveaway(
    source: source,
    giveaway_message_id: giveaway_message_id,
    user: user,
    prize_star_count: prize_star_count,
    is_unclaimed: is_unclaimed,
  ))
}

pub fn chat_boost_decoder() -> decode.Decoder(ChatBoost) {
  use boost_id <- decode.field("boost_id", decode.string)
  use add_date <- decode.field("add_date", decode.int)
  use expiration_date <- decode.field("expiration_date", decode.int)
  use source <- decode.field("source", chat_boost_source_decoder())
  decode.success(ChatBoost(
    boost_id: boost_id,
    add_date: add_date,
    expiration_date: expiration_date,
    source: source,
  ))
}

pub fn chat_boost_updated_decoder() -> decode.Decoder(ChatBoostUpdated) {
  use chat <- decode.field("chat", chat_decoder())
  use boost <- decode.field("boost", chat_boost_decoder())
  decode.success(ChatBoostUpdated(chat: chat, boost: boost))
}

pub fn chat_boost_removed_decoder() -> decode.Decoder(ChatBoostRemoved) {
  use chat <- decode.field("chat", chat_decoder())
  use boost_id <- decode.field("boost_id", decode.string)
  use remove_date <- decode.field("remove_date", decode.int)
  use source <- decode.field("source", chat_boost_source_decoder())
  decode.success(ChatBoostRemoved(
    chat: chat,
    boost_id: boost_id,
    remove_date: remove_date,
    source: source,
  ))
}

pub fn user_chat_boosts_decoder() -> decode.Decoder(UserChatBoosts) {
  use boosts <- decode.field("boosts", decode.list(chat_boost_decoder()))
  decode.success(UserChatBoosts(boosts: boosts))
}

pub fn business_connection_decoder() -> decode.Decoder(BusinessConnection) {
  use id <- decode.field("id", decode.string)
  use user <- decode.field("user", user_decoder())
  use user_chat_id <- decode.field("user_chat_id", decode.int)
  use date <- decode.field("date", decode.int)
  use can_reply <- decode.field("can_reply", decode.bool)
  use is_enabled <- decode.field("is_enabled", decode.bool)
  decode.success(BusinessConnection(
    id: id,
    user: user,
    user_chat_id: user_chat_id,
    date: date,
    can_reply: can_reply,
    is_enabled: is_enabled,
  ))
}

pub fn business_messages_deleted_decoder() -> decode.Decoder(
  BusinessMessagesDeleted,
) {
  use business_connection_id <- decode.field(
    "business_connection_id",
    decode.string,
  )
  use chat <- decode.field("chat", chat_decoder())
  use message_ids <- decode.field("message_ids", decode.list(decode.int))
  decode.success(BusinessMessagesDeleted(
    business_connection_id: business_connection_id,
    chat: chat,
    message_ids: message_ids,
  ))
}

pub fn response_parameters_decoder() -> decode.Decoder(ResponseParameters) {
  use migrate_to_chat_id <- decode.field(
    "migrate_to_chat_id",
    decode.optional(decode.int),
  )
  use retry_after <- decode.field("retry_after", decode.optional(decode.int))
  decode.success(ResponseParameters(
    migrate_to_chat_id: migrate_to_chat_id,
    retry_after: retry_after,
  ))
}

pub fn input_media_photo_decoder() -> decode.Decoder(InputMediaPhoto) {
  use type_ <- decode.field("type_", decode.string)
  use media <- decode.field("media", decode.string)
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use has_spoiler <- decode.field("has_spoiler", decode.optional(decode.bool))
  decode.success(InputMediaPhoto(
    type_: type_,
    media: media,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    has_spoiler: has_spoiler,
  ))
}

pub fn input_media_video_decoder() -> decode.Decoder(InputMediaVideo) {
  use type_ <- decode.field("type_", decode.string)
  use media <- decode.field("media", decode.string)
  use thumbnail <- decode.field("thumbnail", decode.optional(decode.string))
  use cover <- decode.field("cover", decode.optional(decode.string))
  use start_timestamp <- decode.field(
    "start_timestamp",
    decode.optional(decode.int),
  )
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use width <- decode.field("width", decode.optional(decode.int))
  use height <- decode.field("height", decode.optional(decode.int))
  use duration <- decode.field("duration", decode.optional(decode.int))
  use supports_streaming <- decode.field(
    "supports_streaming",
    decode.optional(decode.bool),
  )
  use has_spoiler <- decode.field("has_spoiler", decode.optional(decode.bool))
  decode.success(InputMediaVideo(
    type_: type_,
    media: media,
    thumbnail: thumbnail,
    cover: cover,
    start_timestamp: start_timestamp,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    width: width,
    height: height,
    duration: duration,
    supports_streaming: supports_streaming,
    has_spoiler: has_spoiler,
  ))
}

pub fn input_media_animation_decoder() -> decode.Decoder(InputMediaAnimation) {
  use type_ <- decode.field("type_", decode.string)
  use media <- decode.field("media", decode.string)
  use thumbnail <- decode.field("thumbnail", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use width <- decode.field("width", decode.optional(decode.int))
  use height <- decode.field("height", decode.optional(decode.int))
  use duration <- decode.field("duration", decode.optional(decode.int))
  use has_spoiler <- decode.field("has_spoiler", decode.optional(decode.bool))
  decode.success(InputMediaAnimation(
    type_: type_,
    media: media,
    thumbnail: thumbnail,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    width: width,
    height: height,
    duration: duration,
    has_spoiler: has_spoiler,
  ))
}

pub fn input_media_audio_decoder() -> decode.Decoder(InputMediaAudio) {
  use type_ <- decode.field("type_", decode.string)
  use media <- decode.field("media", decode.string)
  use thumbnail <- decode.field("thumbnail", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use duration <- decode.field("duration", decode.optional(decode.int))
  use performer <- decode.field("performer", decode.optional(decode.string))
  use title <- decode.field("title", decode.optional(decode.string))
  decode.success(InputMediaAudio(
    type_: type_,
    media: media,
    thumbnail: thumbnail,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    duration: duration,
    performer: performer,
    title: title,
  ))
}

pub fn input_media_document_decoder() -> decode.Decoder(InputMediaDocument) {
  use type_ <- decode.field("type_", decode.string)
  use media <- decode.field("media", decode.string)
  use thumbnail <- decode.field("thumbnail", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use disable_content_type_detection <- decode.field(
    "disable_content_type_detection",
    decode.optional(decode.bool),
  )
  decode.success(InputMediaDocument(
    type_: type_,
    media: media,
    thumbnail: thumbnail,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    disable_content_type_detection: disable_content_type_detection,
  ))
}

pub fn input_paid_media_photo_decoder() -> decode.Decoder(InputPaidMediaPhoto) {
  use type_ <- decode.field("type_", decode.string)
  use media <- decode.field("media", decode.string)
  decode.success(InputPaidMediaPhoto(type_: type_, media: media))
}

pub fn input_paid_media_video_decoder() -> decode.Decoder(InputPaidMediaVideo) {
  use type_ <- decode.field("type_", decode.string)
  use media <- decode.field("media", decode.string)
  use thumbnail <- decode.field("thumbnail", decode.optional(decode.string))
  use cover <- decode.field("cover", decode.optional(decode.string))
  use start_timestamp <- decode.field(
    "start_timestamp",
    decode.optional(decode.int),
  )
  use width <- decode.field("width", decode.optional(decode.int))
  use height <- decode.field("height", decode.optional(decode.int))
  use duration <- decode.field("duration", decode.optional(decode.int))
  use supports_streaming <- decode.field(
    "supports_streaming",
    decode.optional(decode.bool),
  )
  decode.success(InputPaidMediaVideo(
    type_: type_,
    media: media,
    thumbnail: thumbnail,
    cover: cover,
    start_timestamp: start_timestamp,
    width: width,
    height: height,
    duration: duration,
    supports_streaming: supports_streaming,
  ))
}

pub fn sticker_decoder() -> decode.Decoder(Sticker) {
  use file_id <- decode.field("file_id", decode.string)
  use file_unique_id <- decode.field("file_unique_id", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use width <- decode.field("width", decode.int)
  use height <- decode.field("height", decode.int)
  use is_animated <- decode.field("is_animated", decode.bool)
  use is_video <- decode.field("is_video", decode.bool)
  use thumbnail <- decode.field(
    "thumbnail",
    decode.optional(photo_size_decoder()),
  )
  use emoji <- decode.field("emoji", decode.optional(decode.string))
  use set_name <- decode.field("set_name", decode.optional(decode.string))
  use premium_animation <- decode.field(
    "premium_animation",
    decode.optional(file_decoder()),
  )
  use mask_position <- decode.field(
    "mask_position",
    decode.optional(mask_position_decoder()),
  )
  use custom_emoji_id <- decode.field(
    "custom_emoji_id",
    decode.optional(decode.string),
  )
  use needs_repainting <- decode.field(
    "needs_repainting",
    decode.optional(decode.bool),
  )
  use file_size <- decode.field("file_size", decode.optional(decode.int))
  decode.success(Sticker(
    file_id: file_id,
    file_unique_id: file_unique_id,
    type_: type_,
    width: width,
    height: height,
    is_animated: is_animated,
    is_video: is_video,
    thumbnail: thumbnail,
    emoji: emoji,
    set_name: set_name,
    premium_animation: premium_animation,
    mask_position: mask_position,
    custom_emoji_id: custom_emoji_id,
    needs_repainting: needs_repainting,
    file_size: file_size,
  ))
}

pub fn sticker_set_decoder() -> decode.Decoder(StickerSet) {
  use name <- decode.field("name", decode.string)
  use title <- decode.field("title", decode.string)
  use sticker_type <- decode.field("sticker_type", decode.string)
  use stickers <- decode.field("stickers", decode.list(sticker_decoder()))
  use thumbnail <- decode.field(
    "thumbnail",
    decode.optional(photo_size_decoder()),
  )
  decode.success(StickerSet(
    name: name,
    title: title,
    sticker_type: sticker_type,
    stickers: stickers,
    thumbnail: thumbnail,
  ))
}

pub fn mask_position_decoder() -> decode.Decoder(MaskPosition) {
  use point <- decode.field("point", decode.string)
  use x_shift <- decode.field("x_shift", decode.float)
  use y_shift <- decode.field("y_shift", decode.float)
  use scale <- decode.field("scale", decode.float)
  decode.success(MaskPosition(
    point: point,
    x_shift: x_shift,
    y_shift: y_shift,
    scale: scale,
  ))
}

pub fn input_sticker_decoder() -> decode.Decoder(InputSticker) {
  use sticker <- decode.field("sticker", file_or_string_decoder())
  use format <- decode.field("format", decode.string)
  use emoji_list <- decode.field("emoji_list", decode.list(decode.string))
  use mask_position <- decode.field(
    "mask_position",
    decode.optional(mask_position_decoder()),
  )
  use keywords <- decode.field(
    "keywords",
    decode.optional(decode.list(decode.string)),
  )
  decode.success(InputSticker(
    sticker: sticker,
    format: format,
    emoji_list: emoji_list,
    mask_position: mask_position,
    keywords: keywords,
  ))
}

pub fn gift_decoder() -> decode.Decoder(Gift) {
  use id <- decode.field("id", decode.string)
  use sticker <- decode.field("sticker", sticker_decoder())
  use star_count <- decode.field("star_count", decode.int)
  use upgrade_star_count <- decode.field(
    "upgrade_star_count",
    decode.optional(decode.int),
  )
  use total_count <- decode.field("total_count", decode.optional(decode.int))
  use remaining_count <- decode.field(
    "remaining_count",
    decode.optional(decode.int),
  )
  decode.success(Gift(
    id: id,
    sticker: sticker,
    star_count: star_count,
    upgrade_star_count: upgrade_star_count,
    total_count: total_count,
    remaining_count: remaining_count,
  ))
}

pub fn gifts_decoder() -> decode.Decoder(Gifts) {
  use gifts <- decode.field("gifts", decode.list(gift_decoder()))
  decode.success(Gifts(gifts: gifts))
}

pub fn inline_query_decoder() -> decode.Decoder(InlineQuery) {
  use id <- decode.field("id", decode.string)
  use from <- decode.field("from", user_decoder())
  use query <- decode.field("query", decode.string)
  use offset <- decode.field("offset", decode.string)
  use chat_type <- decode.field("chat_type", decode.optional(decode.string))
  use location <- decode.field("location", decode.optional(location_decoder()))
  decode.success(InlineQuery(
    id: id,
    from: from,
    query: query,
    offset: offset,
    chat_type: chat_type,
    location: location,
  ))
}

pub fn inline_query_results_button_decoder() -> decode.Decoder(
  InlineQueryResultsButton,
) {
  use text <- decode.field("text", decode.string)
  use web_app <- decode.field(
    "web_app",
    decode.optional(web_app_info_decoder()),
  )
  use start_parameter <- decode.field(
    "start_parameter",
    decode.optional(decode.string),
  )
  decode.success(InlineQueryResultsButton(
    text: text,
    web_app: web_app,
    start_parameter: start_parameter,
  ))
}

pub fn inline_query_result_article_decoder() -> decode.Decoder(
  InlineQueryResultArticle,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use input_message_content <- decode.field(
    "input_message_content",
    input_message_content_decoder(),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use url <- decode.field("url", decode.optional(decode.string))
  use description <- decode.field("description", decode.optional(decode.string))
  use thumbnail_url <- decode.field(
    "thumbnail_url",
    decode.optional(decode.string),
  )
  use thumbnail_width <- decode.field(
    "thumbnail_width",
    decode.optional(decode.int),
  )
  use thumbnail_height <- decode.field(
    "thumbnail_height",
    decode.optional(decode.int),
  )
  decode.success(InlineQueryResultArticle(
    type_: type_,
    id: id,
    title: title,
    input_message_content: input_message_content,
    reply_markup: reply_markup,
    url: url,
    description: description,
    thumbnail_url: thumbnail_url,
    thumbnail_width: thumbnail_width,
    thumbnail_height: thumbnail_height,
  ))
}

pub fn inline_query_result_photo_decoder() -> decode.Decoder(
  InlineQueryResultPhoto,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use photo_url <- decode.field("photo_url", decode.string)
  use thumbnail_url <- decode.field("thumbnail_url", decode.string)
  use photo_width <- decode.field("photo_width", decode.optional(decode.int))
  use photo_height <- decode.field("photo_height", decode.optional(decode.int))
  use title <- decode.field("title", decode.optional(decode.string))
  use description <- decode.field("description", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultPhoto(
    type_: type_,
    id: id,
    photo_url: photo_url,
    thumbnail_url: thumbnail_url,
    photo_width: photo_width,
    photo_height: photo_height,
    title: title,
    description: description,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_gif_decoder() -> decode.Decoder(InlineQueryResultGif) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use gif_url <- decode.field("gif_url", decode.string)
  use gif_width <- decode.field("gif_width", decode.optional(decode.int))
  use gif_height <- decode.field("gif_height", decode.optional(decode.int))
  use gif_duration <- decode.field("gif_duration", decode.optional(decode.int))
  use thumbnail_url <- decode.field("thumbnail_url", decode.string)
  use thumbnail_mime_type <- decode.field(
    "thumbnail_mime_type",
    decode.optional(decode.string),
  )
  use title <- decode.field("title", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultGif(
    type_: type_,
    id: id,
    gif_url: gif_url,
    gif_width: gif_width,
    gif_height: gif_height,
    gif_duration: gif_duration,
    thumbnail_url: thumbnail_url,
    thumbnail_mime_type: thumbnail_mime_type,
    title: title,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_mpeg4_gif_decoder() -> decode.Decoder(
  InlineQueryResultMpeg4Gif,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use mpeg4_url <- decode.field("mpeg4_url", decode.string)
  use mpeg4_width <- decode.field("mpeg4_width", decode.optional(decode.int))
  use mpeg4_height <- decode.field("mpeg4_height", decode.optional(decode.int))
  use mpeg4_duration <- decode.field(
    "mpeg4_duration",
    decode.optional(decode.int),
  )
  use thumbnail_url <- decode.field("thumbnail_url", decode.string)
  use thumbnail_mime_type <- decode.field(
    "thumbnail_mime_type",
    decode.optional(decode.string),
  )
  use title <- decode.field("title", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultMpeg4Gif(
    type_: type_,
    id: id,
    mpeg4_url: mpeg4_url,
    mpeg4_width: mpeg4_width,
    mpeg4_height: mpeg4_height,
    mpeg4_duration: mpeg4_duration,
    thumbnail_url: thumbnail_url,
    thumbnail_mime_type: thumbnail_mime_type,
    title: title,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_video_decoder() -> decode.Decoder(
  InlineQueryResultVideo,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use video_url <- decode.field("video_url", decode.string)
  use mime_type <- decode.field("mime_type", decode.string)
  use thumbnail_url <- decode.field("thumbnail_url", decode.string)
  use title <- decode.field("title", decode.string)
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use video_width <- decode.field("video_width", decode.optional(decode.int))
  use video_height <- decode.field("video_height", decode.optional(decode.int))
  use video_duration <- decode.field(
    "video_duration",
    decode.optional(decode.int),
  )
  use description <- decode.field("description", decode.optional(decode.string))
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultVideo(
    type_: type_,
    id: id,
    video_url: video_url,
    mime_type: mime_type,
    thumbnail_url: thumbnail_url,
    title: title,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    video_width: video_width,
    video_height: video_height,
    video_duration: video_duration,
    description: description,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_audio_decoder() -> decode.Decoder(
  InlineQueryResultAudio,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use audio_url <- decode.field("audio_url", decode.string)
  use title <- decode.field("title", decode.string)
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use performer <- decode.field("performer", decode.optional(decode.string))
  use audio_duration <- decode.field(
    "audio_duration",
    decode.optional(decode.int),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultAudio(
    type_: type_,
    id: id,
    audio_url: audio_url,
    title: title,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    performer: performer,
    audio_duration: audio_duration,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_voice_decoder() -> decode.Decoder(
  InlineQueryResultVoice,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use voice_url <- decode.field("voice_url", decode.string)
  use title <- decode.field("title", decode.string)
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use voice_duration <- decode.field(
    "voice_duration",
    decode.optional(decode.int),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultVoice(
    type_: type_,
    id: id,
    voice_url: voice_url,
    title: title,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    voice_duration: voice_duration,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_document_decoder() -> decode.Decoder(
  InlineQueryResultDocument,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use document_url <- decode.field("document_url", decode.string)
  use mime_type <- decode.field("mime_type", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  use thumbnail_url <- decode.field(
    "thumbnail_url",
    decode.optional(decode.string),
  )
  use thumbnail_width <- decode.field(
    "thumbnail_width",
    decode.optional(decode.int),
  )
  use thumbnail_height <- decode.field(
    "thumbnail_height",
    decode.optional(decode.int),
  )
  decode.success(InlineQueryResultDocument(
    type_: type_,
    id: id,
    title: title,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    document_url: document_url,
    mime_type: mime_type,
    description: description,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
    thumbnail_url: thumbnail_url,
    thumbnail_width: thumbnail_width,
    thumbnail_height: thumbnail_height,
  ))
}

pub fn inline_query_result_location_decoder() -> decode.Decoder(
  InlineQueryResultLocation,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use latitude <- decode.field("latitude", decode.float)
  use longitude <- decode.field("longitude", decode.float)
  use title <- decode.field("title", decode.string)
  use horizontal_accuracy <- decode.field(
    "horizontal_accuracy",
    decode.optional(decode.float),
  )
  use live_period <- decode.field("live_period", decode.optional(decode.int))
  use heading <- decode.field("heading", decode.optional(decode.int))
  use proximity_alert_radius <- decode.field(
    "proximity_alert_radius",
    decode.optional(decode.int),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  use thumbnail_url <- decode.field(
    "thumbnail_url",
    decode.optional(decode.string),
  )
  use thumbnail_width <- decode.field(
    "thumbnail_width",
    decode.optional(decode.int),
  )
  use thumbnail_height <- decode.field(
    "thumbnail_height",
    decode.optional(decode.int),
  )
  decode.success(InlineQueryResultLocation(
    type_: type_,
    id: id,
    latitude: latitude,
    longitude: longitude,
    title: title,
    horizontal_accuracy: horizontal_accuracy,
    live_period: live_period,
    heading: heading,
    proximity_alert_radius: proximity_alert_radius,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
    thumbnail_url: thumbnail_url,
    thumbnail_width: thumbnail_width,
    thumbnail_height: thumbnail_height,
  ))
}

pub fn inline_query_result_venue_decoder() -> decode.Decoder(
  InlineQueryResultVenue,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use latitude <- decode.field("latitude", decode.float)
  use longitude <- decode.field("longitude", decode.float)
  use title <- decode.field("title", decode.string)
  use address <- decode.field("address", decode.string)
  use foursquare_id <- decode.field(
    "foursquare_id",
    decode.optional(decode.string),
  )
  use foursquare_type <- decode.field(
    "foursquare_type",
    decode.optional(decode.string),
  )
  use google_place_id <- decode.field(
    "google_place_id",
    decode.optional(decode.string),
  )
  use google_place_type <- decode.field(
    "google_place_type",
    decode.optional(decode.string),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  use thumbnail_url <- decode.field(
    "thumbnail_url",
    decode.optional(decode.string),
  )
  use thumbnail_width <- decode.field(
    "thumbnail_width",
    decode.optional(decode.int),
  )
  use thumbnail_height <- decode.field(
    "thumbnail_height",
    decode.optional(decode.int),
  )
  decode.success(InlineQueryResultVenue(
    type_: type_,
    id: id,
    latitude: latitude,
    longitude: longitude,
    title: title,
    address: address,
    foursquare_id: foursquare_id,
    foursquare_type: foursquare_type,
    google_place_id: google_place_id,
    google_place_type: google_place_type,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
    thumbnail_url: thumbnail_url,
    thumbnail_width: thumbnail_width,
    thumbnail_height: thumbnail_height,
  ))
}

pub fn inline_query_result_contact_decoder() -> decode.Decoder(
  InlineQueryResultContact,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use phone_number <- decode.field("phone_number", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.optional(decode.string))
  use vcard <- decode.field("vcard", decode.optional(decode.string))
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  use thumbnail_url <- decode.field(
    "thumbnail_url",
    decode.optional(decode.string),
  )
  use thumbnail_width <- decode.field(
    "thumbnail_width",
    decode.optional(decode.int),
  )
  use thumbnail_height <- decode.field(
    "thumbnail_height",
    decode.optional(decode.int),
  )
  decode.success(InlineQueryResultContact(
    type_: type_,
    id: id,
    phone_number: phone_number,
    first_name: first_name,
    last_name: last_name,
    vcard: vcard,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
    thumbnail_url: thumbnail_url,
    thumbnail_width: thumbnail_width,
    thumbnail_height: thumbnail_height,
  ))
}

pub fn inline_query_result_game_decoder() -> decode.Decoder(
  InlineQueryResultGame,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use game_short_name <- decode.field("game_short_name", decode.string)
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  decode.success(InlineQueryResultGame(
    type_: type_,
    id: id,
    game_short_name: game_short_name,
    reply_markup: reply_markup,
  ))
}

pub fn inline_query_result_cached_photo_decoder() -> decode.Decoder(
  InlineQueryResultCachedPhoto,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use photo_file_id <- decode.field("photo_file_id", decode.string)
  use title <- decode.field("title", decode.optional(decode.string))
  use description <- decode.field("description", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultCachedPhoto(
    type_: type_,
    id: id,
    photo_file_id: photo_file_id,
    title: title,
    description: description,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_cached_gif_decoder() -> decode.Decoder(
  InlineQueryResultCachedGif,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use gif_file_id <- decode.field("gif_file_id", decode.string)
  use title <- decode.field("title", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultCachedGif(
    type_: type_,
    id: id,
    gif_file_id: gif_file_id,
    title: title,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_cached_mpeg4_gif_decoder() -> decode.Decoder(
  InlineQueryResultCachedMpeg4Gif,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use mpeg4_file_id <- decode.field("mpeg4_file_id", decode.string)
  use title <- decode.field("title", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultCachedMpeg4Gif(
    type_: type_,
    id: id,
    mpeg4_file_id: mpeg4_file_id,
    title: title,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_cached_sticker_decoder() -> decode.Decoder(
  InlineQueryResultCachedSticker,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use sticker_file_id <- decode.field("sticker_file_id", decode.string)
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultCachedSticker(
    type_: type_,
    id: id,
    sticker_file_id: sticker_file_id,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_cached_document_decoder() -> decode.Decoder(
  InlineQueryResultCachedDocument,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use document_file_id <- decode.field("document_file_id", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultCachedDocument(
    type_: type_,
    id: id,
    title: title,
    document_file_id: document_file_id,
    description: description,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_cached_video_decoder() -> decode.Decoder(
  InlineQueryResultCachedVideo,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use video_file_id <- decode.field("video_file_id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.field(
    "show_caption_above_media",
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultCachedVideo(
    type_: type_,
    id: id,
    video_file_id: video_file_id,
    title: title,
    description: description,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    show_caption_above_media: show_caption_above_media,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_cached_voice_decoder() -> decode.Decoder(
  InlineQueryResultCachedVoice,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use voice_file_id <- decode.field("voice_file_id", decode.string)
  use title <- decode.field("title", decode.string)
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultCachedVoice(
    type_: type_,
    id: id,
    voice_file_id: voice_file_id,
    title: title,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn inline_query_result_cached_audio_decoder() -> decode.Decoder(
  InlineQueryResultCachedAudio,
) {
  use type_ <- decode.field("type_", decode.string)
  use id <- decode.field("id", decode.string)
  use audio_file_id <- decode.field("audio_file_id", decode.string)
  use caption <- decode.field("caption", decode.optional(decode.string))
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use caption_entities <- decode.field(
    "caption_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use reply_markup <- decode.field(
    "reply_markup",
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.field(
    "input_message_content",
    decode.optional(input_message_content_decoder()),
  )
  decode.success(InlineQueryResultCachedAudio(
    type_: type_,
    id: id,
    audio_file_id: audio_file_id,
    caption: caption,
    parse_mode: parse_mode,
    caption_entities: caption_entities,
    reply_markup: reply_markup,
    input_message_content: input_message_content,
  ))
}

pub fn input_text_message_content_decoder() -> decode.Decoder(
  InputTextMessageContent,
) {
  use message_text <- decode.field("message_text", decode.string)
  use parse_mode <- decode.field("parse_mode", decode.optional(decode.string))
  use entities <- decode.field(
    "entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use link_preview_options <- decode.field(
    "link_preview_options",
    decode.optional(link_preview_options_decoder()),
  )
  decode.success(InputTextMessageContent(
    message_text: message_text,
    parse_mode: parse_mode,
    entities: entities,
    link_preview_options: link_preview_options,
  ))
}

pub fn input_location_message_content_decoder() -> decode.Decoder(
  InputLocationMessageContent,
) {
  use latitude <- decode.field("latitude", decode.float)
  use longitude <- decode.field("longitude", decode.float)
  use horizontal_accuracy <- decode.field(
    "horizontal_accuracy",
    decode.optional(decode.float),
  )
  use live_period <- decode.field("live_period", decode.optional(decode.int))
  use heading <- decode.field("heading", decode.optional(decode.int))
  use proximity_alert_radius <- decode.field(
    "proximity_alert_radius",
    decode.optional(decode.int),
  )
  decode.success(InputLocationMessageContent(
    latitude: latitude,
    longitude: longitude,
    horizontal_accuracy: horizontal_accuracy,
    live_period: live_period,
    heading: heading,
    proximity_alert_radius: proximity_alert_radius,
  ))
}

pub fn input_venue_message_content_decoder() -> decode.Decoder(
  InputVenueMessageContent,
) {
  use latitude <- decode.field("latitude", decode.float)
  use longitude <- decode.field("longitude", decode.float)
  use title <- decode.field("title", decode.string)
  use address <- decode.field("address", decode.string)
  use foursquare_id <- decode.field(
    "foursquare_id",
    decode.optional(decode.string),
  )
  use foursquare_type <- decode.field(
    "foursquare_type",
    decode.optional(decode.string),
  )
  use google_place_id <- decode.field(
    "google_place_id",
    decode.optional(decode.string),
  )
  use google_place_type <- decode.field(
    "google_place_type",
    decode.optional(decode.string),
  )
  decode.success(InputVenueMessageContent(
    latitude: latitude,
    longitude: longitude,
    title: title,
    address: address,
    foursquare_id: foursquare_id,
    foursquare_type: foursquare_type,
    google_place_id: google_place_id,
    google_place_type: google_place_type,
  ))
}

pub fn input_contact_message_content_decoder() -> decode.Decoder(
  InputContactMessageContent,
) {
  use phone_number <- decode.field("phone_number", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.optional(decode.string))
  use vcard <- decode.field("vcard", decode.optional(decode.string))
  decode.success(InputContactMessageContent(
    phone_number: phone_number,
    first_name: first_name,
    last_name: last_name,
    vcard: vcard,
  ))
}

pub fn input_invoice_message_content_decoder() -> decode.Decoder(
  InputInvoiceMessageContent,
) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use payload <- decode.field("payload", decode.string)
  use provider_token <- decode.field(
    "provider_token",
    decode.optional(decode.string),
  )
  use currency <- decode.field("currency", decode.string)
  use prices <- decode.field("prices", decode.list(labeled_price_decoder()))
  use max_tip_amount <- decode.field(
    "max_tip_amount",
    decode.optional(decode.int),
  )
  use suggested_tip_amounts <- decode.field(
    "suggested_tip_amounts",
    decode.optional(decode.list(decode.int)),
  )
  use provider_data <- decode.field(
    "provider_data",
    decode.optional(decode.string),
  )
  use photo_url <- decode.field("photo_url", decode.optional(decode.string))
  use photo_size <- decode.field("photo_size", decode.optional(decode.int))
  use photo_width <- decode.field("photo_width", decode.optional(decode.int))
  use photo_height <- decode.field("photo_height", decode.optional(decode.int))
  use need_name <- decode.field("need_name", decode.optional(decode.bool))
  use need_phone_number <- decode.field(
    "need_phone_number",
    decode.optional(decode.bool),
  )
  use need_email <- decode.field("need_email", decode.optional(decode.bool))
  use need_shipping_address <- decode.field(
    "need_shipping_address",
    decode.optional(decode.bool),
  )
  use send_phone_number_to_provider <- decode.field(
    "send_phone_number_to_provider",
    decode.optional(decode.bool),
  )
  use send_email_to_provider <- decode.field(
    "send_email_to_provider",
    decode.optional(decode.bool),
  )
  use is_flexible <- decode.field("is_flexible", decode.optional(decode.bool))
  decode.success(InputInvoiceMessageContent(
    title: title,
    description: description,
    payload: payload,
    provider_token: provider_token,
    currency: currency,
    prices: prices,
    max_tip_amount: max_tip_amount,
    suggested_tip_amounts: suggested_tip_amounts,
    provider_data: provider_data,
    photo_url: photo_url,
    photo_size: photo_size,
    photo_width: photo_width,
    photo_height: photo_height,
    need_name: need_name,
    need_phone_number: need_phone_number,
    need_email: need_email,
    need_shipping_address: need_shipping_address,
    send_phone_number_to_provider: send_phone_number_to_provider,
    send_email_to_provider: send_email_to_provider,
    is_flexible: is_flexible,
  ))
}

pub fn chosen_inline_result_decoder() -> decode.Decoder(ChosenInlineResult) {
  use result_id <- decode.field("result_id", decode.string)
  use from <- decode.field("from", user_decoder())
  use location <- decode.field("location", decode.optional(location_decoder()))
  use inline_message_id <- decode.field(
    "inline_message_id",
    decode.optional(decode.string),
  )
  use query <- decode.field("query", decode.string)
  decode.success(ChosenInlineResult(
    result_id: result_id,
    from: from,
    location: location,
    inline_message_id: inline_message_id,
    query: query,
  ))
}

pub fn sent_web_app_message_decoder() -> decode.Decoder(SentWebAppMessage) {
  use inline_message_id <- decode.field(
    "inline_message_id",
    decode.optional(decode.string),
  )
  decode.success(SentWebAppMessage(inline_message_id: inline_message_id))
}

pub fn prepared_inline_message_decoder() -> decode.Decoder(
  PreparedInlineMessage,
) {
  use id <- decode.field("id", decode.string)
  use expiration_date <- decode.field("expiration_date", decode.int)
  decode.success(PreparedInlineMessage(id: id, expiration_date: expiration_date))
}

pub fn labeled_price_decoder() -> decode.Decoder(LabeledPrice) {
  use label <- decode.field("label", decode.string)
  use amount <- decode.field("amount", decode.int)
  decode.success(LabeledPrice(label: label, amount: amount))
}

pub fn invoice_decoder() -> decode.Decoder(Invoice) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use start_parameter <- decode.field("start_parameter", decode.string)
  use currency <- decode.field("currency", decode.string)
  use total_amount <- decode.field("total_amount", decode.int)
  decode.success(Invoice(
    title: title,
    description: description,
    start_parameter: start_parameter,
    currency: currency,
    total_amount: total_amount,
  ))
}

pub fn shipping_address_decoder() -> decode.Decoder(ShippingAddress) {
  use country_code <- decode.field("country_code", decode.string)
  use state <- decode.field("state", decode.string)
  use city <- decode.field("city", decode.string)
  use street_line1 <- decode.field("street_line1", decode.string)
  use street_line2 <- decode.field("street_line2", decode.string)
  use post_code <- decode.field("post_code", decode.string)
  decode.success(ShippingAddress(
    country_code: country_code,
    state: state,
    city: city,
    street_line1: street_line1,
    street_line2: street_line2,
    post_code: post_code,
  ))
}

pub fn order_info_decoder() -> decode.Decoder(OrderInfo) {
  use name <- decode.field("name", decode.optional(decode.string))
  use phone_number <- decode.field(
    "phone_number",
    decode.optional(decode.string),
  )
  use email <- decode.field("email", decode.optional(decode.string))
  use shipping_address <- decode.field(
    "shipping_address",
    decode.optional(shipping_address_decoder()),
  )
  decode.success(OrderInfo(
    name: name,
    phone_number: phone_number,
    email: email,
    shipping_address: shipping_address,
  ))
}

pub fn shipping_option_decoder() -> decode.Decoder(ShippingOption) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use prices <- decode.field("prices", decode.list(labeled_price_decoder()))
  decode.success(ShippingOption(id: id, title: title, prices: prices))
}

pub fn successful_payment_decoder() -> decode.Decoder(SuccessfulPayment) {
  use currency <- decode.field("currency", decode.string)
  use total_amount <- decode.field("total_amount", decode.int)
  use invoice_payload <- decode.field("invoice_payload", decode.string)
  use subscription_expiration_date <- decode.field(
    "subscription_expiration_date",
    decode.optional(decode.int),
  )
  use is_recurring <- decode.field("is_recurring", decode.optional(decode.bool))
  use is_first_recurring <- decode.field(
    "is_first_recurring",
    decode.optional(decode.bool),
  )
  use shipping_option_id <- decode.field(
    "shipping_option_id",
    decode.optional(decode.string),
  )
  use order_info <- decode.field(
    "order_info",
    decode.optional(order_info_decoder()),
  )
  use telegram_payment_charge_id <- decode.field(
    "telegram_payment_charge_id",
    decode.string,
  )
  use provider_payment_charge_id <- decode.field(
    "provider_payment_charge_id",
    decode.string,
  )
  decode.success(SuccessfulPayment(
    currency: currency,
    total_amount: total_amount,
    invoice_payload: invoice_payload,
    subscription_expiration_date: subscription_expiration_date,
    is_recurring: is_recurring,
    is_first_recurring: is_first_recurring,
    shipping_option_id: shipping_option_id,
    order_info: order_info,
    telegram_payment_charge_id: telegram_payment_charge_id,
    provider_payment_charge_id: provider_payment_charge_id,
  ))
}

pub fn refunded_payment_decoder() -> decode.Decoder(RefundedPayment) {
  use currency <- decode.field("currency", decode.string)
  use total_amount <- decode.field("total_amount", decode.int)
  use invoice_payload <- decode.field("invoice_payload", decode.string)
  use telegram_payment_charge_id <- decode.field(
    "telegram_payment_charge_id",
    decode.string,
  )
  use provider_payment_charge_id <- decode.field(
    "provider_payment_charge_id",
    decode.optional(decode.string),
  )
  decode.success(RefundedPayment(
    currency: currency,
    total_amount: total_amount,
    invoice_payload: invoice_payload,
    telegram_payment_charge_id: telegram_payment_charge_id,
    provider_payment_charge_id: provider_payment_charge_id,
  ))
}

pub fn shipping_query_decoder() -> decode.Decoder(ShippingQuery) {
  use id <- decode.field("id", decode.string)
  use from <- decode.field("from", user_decoder())
  use invoice_payload <- decode.field("invoice_payload", decode.string)
  use shipping_address <- decode.field(
    "shipping_address",
    shipping_address_decoder(),
  )
  decode.success(ShippingQuery(
    id: id,
    from: from,
    invoice_payload: invoice_payload,
    shipping_address: shipping_address,
  ))
}

pub fn pre_checkout_query_decoder() -> decode.Decoder(PreCheckoutQuery) {
  use id <- decode.field("id", decode.string)
  use from <- decode.field("from", user_decoder())
  use currency <- decode.field("currency", decode.string)
  use total_amount <- decode.field("total_amount", decode.int)
  use invoice_payload <- decode.field("invoice_payload", decode.string)
  use shipping_option_id <- decode.field(
    "shipping_option_id",
    decode.optional(decode.string),
  )
  use order_info <- decode.field(
    "order_info",
    decode.optional(order_info_decoder()),
  )
  decode.success(PreCheckoutQuery(
    id: id,
    from: from,
    currency: currency,
    total_amount: total_amount,
    invoice_payload: invoice_payload,
    shipping_option_id: shipping_option_id,
    order_info: order_info,
  ))
}

pub fn paid_media_purchased_decoder() -> decode.Decoder(PaidMediaPurchased) {
  use from <- decode.field("from", user_decoder())
  use paid_media_payload <- decode.field("paid_media_payload", decode.string)
  decode.success(PaidMediaPurchased(
    from: from,
    paid_media_payload: paid_media_payload,
  ))
}

pub fn revenue_withdrawal_state_pending_decoder() -> decode.Decoder(
  RevenueWithdrawalStatePending,
) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(RevenueWithdrawalStatePending(type_: type_))
}

pub fn revenue_withdrawal_state_succeeded_decoder() -> decode.Decoder(
  RevenueWithdrawalStateSucceeded,
) {
  use type_ <- decode.field("type_", decode.string)
  use date <- decode.field("date", decode.int)
  use url <- decode.field("url", decode.string)
  decode.success(RevenueWithdrawalStateSucceeded(
    type_: type_,
    date: date,
    url: url,
  ))
}

pub fn revenue_withdrawal_state_failed_decoder() -> decode.Decoder(
  RevenueWithdrawalStateFailed,
) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(RevenueWithdrawalStateFailed(type_: type_))
}

pub fn affiliate_info_decoder() -> decode.Decoder(AffiliateInfo) {
  use affiliate_user <- decode.field(
    "affiliate_user",
    decode.optional(user_decoder()),
  )
  use affiliate_chat <- decode.field(
    "affiliate_chat",
    decode.optional(chat_decoder()),
  )
  use commission_per_mille <- decode.field("commission_per_mille", decode.int)
  use amount <- decode.field("amount", decode.int)
  use nanostar_amount <- decode.field(
    "nanostar_amount",
    decode.optional(decode.int),
  )
  decode.success(AffiliateInfo(
    affiliate_user: affiliate_user,
    affiliate_chat: affiliate_chat,
    commission_per_mille: commission_per_mille,
    amount: amount,
    nanostar_amount: nanostar_amount,
  ))
}

pub fn transaction_partner_user_decoder() -> decode.Decoder(
  TransactionPartnerUser,
) {
  use type_ <- decode.field("type_", decode.string)
  use user <- decode.field("user", user_decoder())
  use affiliate <- decode.field(
    "affiliate",
    decode.optional(affiliate_info_decoder()),
  )
  use invoice_payload <- decode.field(
    "invoice_payload",
    decode.optional(decode.string),
  )
  use subscription_period <- decode.field(
    "subscription_period",
    decode.optional(decode.int),
  )
  use paid_media <- decode.field(
    "paid_media",
    decode.optional(decode.list(paid_media_decoder())),
  )
  use paid_media_payload <- decode.field(
    "paid_media_payload",
    decode.optional(decode.string),
  )
  use gift <- decode.field("gift", decode.optional(gift_decoder()))
  decode.success(TransactionPartnerUser(
    type_: type_,
    user: user,
    affiliate: affiliate,
    invoice_payload: invoice_payload,
    subscription_period: subscription_period,
    paid_media: paid_media,
    paid_media_payload: paid_media_payload,
    gift: gift,
  ))
}

pub fn transaction_partner_chat_decoder() -> decode.Decoder(
  TransactionPartnerChat,
) {
  use type_ <- decode.field("type_", decode.string)
  use chat <- decode.field("chat", chat_decoder())
  use gift <- decode.field("gift", decode.optional(gift_decoder()))
  decode.success(TransactionPartnerChat(type_: type_, chat: chat, gift: gift))
}

pub fn transaction_partner_affiliate_program_decoder() -> decode.Decoder(
  TransactionPartnerAffiliateProgram,
) {
  use type_ <- decode.field("type_", decode.string)
  use sponsor_user <- decode.field(
    "sponsor_user",
    decode.optional(user_decoder()),
  )
  use commission_per_mille <- decode.field("commission_per_mille", decode.int)
  decode.success(TransactionPartnerAffiliateProgram(
    type_: type_,
    sponsor_user: sponsor_user,
    commission_per_mille: commission_per_mille,
  ))
}

pub fn transaction_partner_fragment_decoder() -> decode.Decoder(
  TransactionPartnerFragment,
) {
  use type_ <- decode.field("type_", decode.string)
  use withdrawal_state <- decode.field(
    "withdrawal_state",
    decode.optional(revenue_withdrawal_state_decoder()),
  )
  decode.success(TransactionPartnerFragment(
    type_: type_,
    withdrawal_state: withdrawal_state,
  ))
}

pub fn transaction_partner_telegram_ads_decoder() -> decode.Decoder(
  TransactionPartnerTelegramAds,
) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(TransactionPartnerTelegramAds(type_: type_))
}

pub fn transaction_partner_telegram_api_decoder() -> decode.Decoder(
  TransactionPartnerTelegramApi,
) {
  use type_ <- decode.field("type_", decode.string)
  use request_count <- decode.field("request_count", decode.int)
  decode.success(TransactionPartnerTelegramApi(
    type_: type_,
    request_count: request_count,
  ))
}

pub fn transaction_partner_other_decoder() -> decode.Decoder(
  TransactionPartnerOther,
) {
  use type_ <- decode.field("type_", decode.string)
  decode.success(TransactionPartnerOther(type_: type_))
}

pub fn star_transaction_decoder() -> decode.Decoder(StarTransaction) {
  use id <- decode.field("id", decode.string)
  use amount <- decode.field("amount", decode.int)
  use nanostar_amount <- decode.field(
    "nanostar_amount",
    decode.optional(decode.int),
  )
  use date <- decode.field("date", decode.int)
  use source <- decode.field(
    "source",
    decode.optional(transaction_partner_decoder()),
  )
  use receiver <- decode.field(
    "receiver",
    decode.optional(transaction_partner_decoder()),
  )
  decode.success(StarTransaction(
    id: id,
    amount: amount,
    nanostar_amount: nanostar_amount,
    date: date,
    source: source,
    receiver: receiver,
  ))
}

pub fn star_transactions_decoder() -> decode.Decoder(StarTransactions) {
  use transactions <- decode.field(
    "transactions",
    decode.list(star_transaction_decoder()),
  )
  decode.success(StarTransactions(transactions: transactions))
}

pub fn passport_data_decoder() -> decode.Decoder(PassportData) {
  use data <- decode.field(
    "data",
    decode.list(encrypted_passport_element_decoder()),
  )
  use credentials <- decode.field(
    "credentials",
    encrypted_credentials_decoder(),
  )
  decode.success(PassportData(data: data, credentials: credentials))
}

pub fn passport_file_decoder() -> decode.Decoder(PassportFile) {
  use file_id <- decode.field("file_id", decode.string)
  use file_unique_id <- decode.field("file_unique_id", decode.string)
  use file_size <- decode.field("file_size", decode.int)
  use file_date <- decode.field("file_date", decode.int)
  decode.success(PassportFile(
    file_id: file_id,
    file_unique_id: file_unique_id,
    file_size: file_size,
    file_date: file_date,
  ))
}

pub fn encrypted_passport_element_decoder() -> decode.Decoder(
  EncryptedPassportElement,
) {
  use type_ <- decode.field("type_", decode.string)
  use data <- decode.field("data", decode.optional(decode.string))
  use phone_number <- decode.field(
    "phone_number",
    decode.optional(decode.string),
  )
  use email <- decode.field("email", decode.optional(decode.string))
  use files <- decode.field(
    "files",
    decode.optional(decode.list(passport_file_decoder())),
  )
  use front_side <- decode.field(
    "front_side",
    decode.optional(passport_file_decoder()),
  )
  use reverse_side <- decode.field(
    "reverse_side",
    decode.optional(passport_file_decoder()),
  )
  use selfie <- decode.field("selfie", decode.optional(passport_file_decoder()))
  use translation <- decode.field(
    "translation",
    decode.optional(decode.list(passport_file_decoder())),
  )
  use hash <- decode.field("hash", decode.string)
  decode.success(EncryptedPassportElement(
    type_: type_,
    data: data,
    phone_number: phone_number,
    email: email,
    files: files,
    front_side: front_side,
    reverse_side: reverse_side,
    selfie: selfie,
    translation: translation,
    hash: hash,
  ))
}

pub fn encrypted_credentials_decoder() -> decode.Decoder(EncryptedCredentials) {
  use data <- decode.field("data", decode.string)
  use hash <- decode.field("hash", decode.string)
  use secret <- decode.field("secret", decode.string)
  decode.success(EncryptedCredentials(data: data, hash: hash, secret: secret))
}

pub fn passport_element_error_data_field_decoder() -> decode.Decoder(
  PassportElementErrorDataField,
) {
  use source <- decode.field("source", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use field_name <- decode.field("field_name", decode.string)
  use data_hash <- decode.field("data_hash", decode.string)
  use message <- decode.field("message", decode.string)
  decode.success(PassportElementErrorDataField(
    source: source,
    type_: type_,
    field_name: field_name,
    data_hash: data_hash,
    message: message,
  ))
}

pub fn passport_element_error_front_side_decoder() -> decode.Decoder(
  PassportElementErrorFrontSide,
) {
  use source <- decode.field("source", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use file_hash <- decode.field("file_hash", decode.string)
  use message <- decode.field("message", decode.string)
  decode.success(PassportElementErrorFrontSide(
    source: source,
    type_: type_,
    file_hash: file_hash,
    message: message,
  ))
}

pub fn passport_element_error_reverse_side_decoder() -> decode.Decoder(
  PassportElementErrorReverseSide,
) {
  use source <- decode.field("source", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use file_hash <- decode.field("file_hash", decode.string)
  use message <- decode.field("message", decode.string)
  decode.success(PassportElementErrorReverseSide(
    source: source,
    type_: type_,
    file_hash: file_hash,
    message: message,
  ))
}

pub fn passport_element_error_selfie_decoder() -> decode.Decoder(
  PassportElementErrorSelfie,
) {
  use source <- decode.field("source", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use file_hash <- decode.field("file_hash", decode.string)
  use message <- decode.field("message", decode.string)
  decode.success(PassportElementErrorSelfie(
    source: source,
    type_: type_,
    file_hash: file_hash,
    message: message,
  ))
}

pub fn passport_element_error_file_decoder() -> decode.Decoder(
  PassportElementErrorFile,
) {
  use source <- decode.field("source", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use file_hash <- decode.field("file_hash", decode.string)
  use message <- decode.field("message", decode.string)
  decode.success(PassportElementErrorFile(
    source: source,
    type_: type_,
    file_hash: file_hash,
    message: message,
  ))
}

pub fn passport_element_error_files_decoder() -> decode.Decoder(
  PassportElementErrorFiles,
) {
  use source <- decode.field("source", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use file_hashes <- decode.field("file_hashes", decode.list(decode.string))
  use message <- decode.field("message", decode.string)
  decode.success(PassportElementErrorFiles(
    source: source,
    type_: type_,
    file_hashes: file_hashes,
    message: message,
  ))
}

pub fn passport_element_error_translation_file_decoder() -> decode.Decoder(
  PassportElementErrorTranslationFile,
) {
  use source <- decode.field("source", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use file_hash <- decode.field("file_hash", decode.string)
  use message <- decode.field("message", decode.string)
  decode.success(PassportElementErrorTranslationFile(
    source: source,
    type_: type_,
    file_hash: file_hash,
    message: message,
  ))
}

pub fn passport_element_error_translation_files_decoder() -> decode.Decoder(
  PassportElementErrorTranslationFiles,
) {
  use source <- decode.field("source", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use file_hashes <- decode.field("file_hashes", decode.list(decode.string))
  use message <- decode.field("message", decode.string)
  decode.success(PassportElementErrorTranslationFiles(
    source: source,
    type_: type_,
    file_hashes: file_hashes,
    message: message,
  ))
}

pub fn passport_element_error_unspecified_decoder() -> decode.Decoder(
  PassportElementErrorUnspecified,
) {
  use source <- decode.field("source", decode.string)
  use type_ <- decode.field("type_", decode.string)
  use element_hash <- decode.field("element_hash", decode.string)
  use message <- decode.field("message", decode.string)
  decode.success(PassportElementErrorUnspecified(
    source: source,
    type_: type_,
    element_hash: element_hash,
    message: message,
  ))
}

pub fn game_decoder() -> decode.Decoder(Game) {
  use title <- decode.field("title", decode.string)
  use description <- decode.field("description", decode.string)
  use photo <- decode.field("photo", decode.list(photo_size_decoder()))
  use text <- decode.field("text", decode.optional(decode.string))
  use text_entities <- decode.field(
    "text_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use animation <- decode.field(
    "animation",
    decode.optional(animation_decoder()),
  )
  decode.success(Game(
    title: title,
    description: description,
    photo: photo,
    text: text,
    text_entities: text_entities,
    animation: animation,
  ))
}

pub fn callback_game_decoder() -> decode.Decoder(CallbackGame) {
  use user_id <- decode.field("user_id", decode.int)
  use score <- decode.field("score", decode.int)
  use force <- decode.field("force", decode.optional(decode.bool))
  use disable_edit_message <- decode.field(
    "disable_edit_message",
    decode.optional(decode.bool),
  )
  use chat_id <- decode.field("chat_id", decode.optional(decode.int))
  use message_id <- decode.field("message_id", decode.optional(decode.int))
  use inline_message_id <- decode.field(
    "inline_message_id",
    decode.optional(decode.string),
  )
  decode.success(CallbackGame(
    user_id: user_id,
    score: score,
    force: force,
    disable_edit_message: disable_edit_message,
    chat_id: chat_id,
    message_id: message_id,
    inline_message_id: inline_message_id,
  ))
}

pub fn game_high_score_decoder() -> decode.Decoder(GameHighScore) {
  use position <- decode.field("position", decode.int)
  use user <- decode.field("user", user_decoder())
  use score <- decode.field("score", decode.int)
  decode.success(GameHighScore(position: position, user: user, score: score))
}

pub fn maybe_inaccessible_message_decoder() -> decode.Decoder(
  MaybeInaccessibleMessage,
) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "message" -> {
      use value <- decode.field("value", message_decoder())
      decode.success(MessageMaybeInaccessibleMessage(value))
    }
    "inaccessible_message" -> {
      use value <- decode.field("value", inaccessible_message_decoder())
      decode.success(InaccessibleMessageMaybeInaccessibleMessage(value))
    }
    _ -> panic as "Invalid variant for MaybeInaccessibleMessage"
  }
}

pub fn message_origin_decoder() -> decode.Decoder(MessageOrigin) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "message_origin_user" -> {
      use value <- decode.field("value", message_origin_user_decoder())
      decode.success(MessageOriginUserMessageOrigin(value))
    }
    "message_origin_hidden_user" -> {
      use value <- decode.field("value", message_origin_hidden_user_decoder())
      decode.success(MessageOriginHiddenUserMessageOrigin(value))
    }
    "message_origin_chat" -> {
      use value <- decode.field("value", message_origin_chat_decoder())
      decode.success(MessageOriginChatMessageOrigin(value))
    }
    "message_origin_channel" -> {
      use value <- decode.field("value", message_origin_channel_decoder())
      decode.success(MessageOriginChannelMessageOrigin(value))
    }
    _ -> panic as "Invalid variant for MessageOrigin"
  }
}

pub fn paid_media_decoder() -> decode.Decoder(PaidMedia) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "paid_media_preview" -> {
      use value <- decode.field("value", paid_media_preview_decoder())
      decode.success(PaidMediaPreviewPaidMedia(value))
    }
    "paid_media_photo" -> {
      use value <- decode.field("value", paid_media_photo_decoder())
      decode.success(PaidMediaPhotoPaidMedia(value))
    }
    "paid_media_video" -> {
      use value <- decode.field("value", paid_media_video_decoder())
      decode.success(PaidMediaVideoPaidMedia(value))
    }
    _ -> panic as "Invalid variant for PaidMedia"
  }
}

pub fn background_fill_decoder() -> decode.Decoder(BackgroundFill) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "background_fill_solid" -> {
      use value <- decode.field("value", background_fill_solid_decoder())
      decode.success(BackgroundFillSolidBackgroundFill(value))
    }
    "background_fill_gradient" -> {
      use value <- decode.field("value", background_fill_gradient_decoder())
      decode.success(BackgroundFillGradientBackgroundFill(value))
    }
    "background_fill_freeform_gradient" -> {
      use value <- decode.field(
        "value",
        background_fill_freeform_gradient_decoder(),
      )
      decode.success(BackgroundFillFreeformGradientBackgroundFill(value))
    }
    _ -> panic as "Invalid variant for BackgroundFill"
  }
}

pub fn background_type_decoder() -> decode.Decoder(BackgroundType) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "background_type_fill" -> {
      use value <- decode.field("value", background_type_fill_decoder())
      decode.success(BackgroundTypeFillBackgroundType(value))
    }
    "background_type_wallpaper" -> {
      use value <- decode.field("value", background_type_wallpaper_decoder())
      decode.success(BackgroundTypeWallpaperBackgroundType(value))
    }
    "background_type_pattern" -> {
      use value <- decode.field("value", background_type_pattern_decoder())
      decode.success(BackgroundTypePatternBackgroundType(value))
    }
    "background_type_chat_theme" -> {
      use value <- decode.field("value", background_type_chat_theme_decoder())
      decode.success(BackgroundTypeChatThemeBackgroundType(value))
    }
    _ -> panic as "Invalid variant for BackgroundType"
  }
}

pub fn chat_member_decoder() -> decode.Decoder(ChatMember) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "chat_member_owner" -> {
      use value <- decode.field("value", chat_member_owner_decoder())
      decode.success(ChatMemberOwnerChatMember(value))
    }
    "chat_member_administrator" -> {
      use value <- decode.field("value", chat_member_administrator_decoder())
      decode.success(ChatMemberAdministratorChatMember(value))
    }
    "chat_member_member" -> {
      use value <- decode.field("value", chat_member_member_decoder())
      decode.success(ChatMemberMemberChatMember(value))
    }
    "chat_member_restricted" -> {
      use value <- decode.field("value", chat_member_restricted_decoder())
      decode.success(ChatMemberRestrictedChatMember(value))
    }
    "chat_member_left" -> {
      use value <- decode.field("value", chat_member_left_decoder())
      decode.success(ChatMemberLeftChatMember(value))
    }
    "chat_member_banned" -> {
      use value <- decode.field("value", chat_member_banned_decoder())
      decode.success(ChatMemberBannedChatMember(value))
    }
    _ -> panic as "Invalid variant for ChatMember"
  }
}

pub fn reaction_type_decoder() -> decode.Decoder(ReactionType) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "reaction_type_emoji" -> {
      use value <- decode.field("value", reaction_type_emoji_decoder())
      decode.success(ReactionTypeEmojiReactionType(value))
    }
    "reaction_type_custom_emoji" -> {
      use value <- decode.field("value", reaction_type_custom_emoji_decoder())
      decode.success(ReactionTypeCustomEmojiReactionType(value))
    }
    "reaction_type_paid" -> {
      use value <- decode.field("value", reaction_type_paid_decoder())
      decode.success(ReactionTypePaidReactionType(value))
    }
    _ -> panic as "Invalid variant for ReactionType"
  }
}

pub fn bot_command_scope_decoder() -> decode.Decoder(BotCommandScope) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "bot_command_scope_default" -> {
      use value <- decode.field("value", bot_command_scope_default_decoder())
      decode.success(BotCommandScopeDefaultBotCommandScope(value))
    }
    "bot_command_scope_all_private_chats" -> {
      use value <- decode.field(
        "value",
        bot_command_scope_all_private_chats_decoder(),
      )
      decode.success(BotCommandScopeAllPrivateChatsBotCommandScope(value))
    }
    "bot_command_scope_all_group_chats" -> {
      use value <- decode.field(
        "value",
        bot_command_scope_all_group_chats_decoder(),
      )
      decode.success(BotCommandScopeAllGroupChatsBotCommandScope(value))
    }
    "bot_command_scope_all_chat_administrators" -> {
      use value <- decode.field(
        "value",
        bot_command_scope_all_chat_administrators_decoder(),
      )
      decode.success(BotCommandScopeAllChatAdministratorsBotCommandScope(value))
    }
    "bot_command_scope_chat" -> {
      use value <- decode.field("value", bot_command_scope_chat_decoder())
      decode.success(BotCommandScopeChatBotCommandScope(value))
    }
    "bot_command_scope_chat_administrators" -> {
      use value <- decode.field(
        "value",
        bot_command_scope_chat_administrators_decoder(),
      )
      decode.success(BotCommandScopeChatAdministratorsBotCommandScope(value))
    }
    "bot_command_scope_chat_member" -> {
      use value <- decode.field(
        "value",
        bot_command_scope_chat_member_decoder(),
      )
      decode.success(BotCommandScopeChatMemberBotCommandScope(value))
    }
    _ -> panic as "Invalid variant for BotCommandScope"
  }
}

pub fn menu_button_decoder() -> decode.Decoder(MenuButton) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "menu_button_commands" -> {
      use value <- decode.field("value", menu_button_commands_decoder())
      decode.success(MenuButtonCommandsMenuButton(value))
    }
    "menu_button_web_app" -> {
      use value <- decode.field("value", menu_button_web_app_decoder())
      decode.success(MenuButtonWebAppMenuButton(value))
    }
    "menu_button_default" -> {
      use value <- decode.field("value", menu_button_default_decoder())
      decode.success(MenuButtonDefaultMenuButton(value))
    }
    _ -> panic as "Invalid variant for MenuButton"
  }
}

pub fn chat_boost_source_decoder() -> decode.Decoder(ChatBoostSource) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "chat_boost_source_premium" -> {
      use value <- decode.field("value", chat_boost_source_premium_decoder())
      decode.success(ChatBoostSourcePremiumChatBoostSource(value))
    }
    "chat_boost_source_gift_code" -> {
      use value <- decode.field("value", chat_boost_source_gift_code_decoder())
      decode.success(ChatBoostSourceGiftCodeChatBoostSource(value))
    }
    "chat_boost_source_giveaway" -> {
      use value <- decode.field("value", chat_boost_source_giveaway_decoder())
      decode.success(ChatBoostSourceGiveawayChatBoostSource(value))
    }
    _ -> panic as "Invalid variant for ChatBoostSource"
  }
}

pub fn input_media_decoder() -> decode.Decoder(InputMedia) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "input_media_animation" -> {
      use value <- decode.field("value", input_media_animation_decoder())
      decode.success(InputMediaAnimationInputMedia(value))
    }
    "input_media_document" -> {
      use value <- decode.field("value", input_media_document_decoder())
      decode.success(InputMediaDocumentInputMedia(value))
    }
    "input_media_audio" -> {
      use value <- decode.field("value", input_media_audio_decoder())
      decode.success(InputMediaAudioInputMedia(value))
    }
    "input_media_photo" -> {
      use value <- decode.field("value", input_media_photo_decoder())
      decode.success(InputMediaPhotoInputMedia(value))
    }
    "input_media_video" -> {
      use value <- decode.field("value", input_media_video_decoder())
      decode.success(InputMediaVideoInputMedia(value))
    }
    _ -> panic as "Invalid variant for InputMedia"
  }
}

pub fn input_paid_media_decoder() -> decode.Decoder(InputPaidMedia) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "input_paid_media_photo" -> {
      use value <- decode.field("value", input_paid_media_photo_decoder())
      decode.success(InputPaidMediaPhotoInputPaidMedia(value))
    }
    "input_paid_media_video" -> {
      use value <- decode.field("value", input_paid_media_video_decoder())
      decode.success(InputPaidMediaVideoInputPaidMedia(value))
    }
    _ -> panic as "Invalid variant for InputPaidMedia"
  }
}

pub fn inline_query_result_decoder() -> decode.Decoder(InlineQueryResult) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "inline_query_result_cached_audio" -> {
      use value <- decode.field(
        "value",
        inline_query_result_cached_audio_decoder(),
      )
      decode.success(InlineQueryResultCachedAudioInlineQueryResult(value))
    }
    "inline_query_result_cached_document" -> {
      use value <- decode.field(
        "value",
        inline_query_result_cached_document_decoder(),
      )
      decode.success(InlineQueryResultCachedDocumentInlineQueryResult(value))
    }
    "inline_query_result_cached_gif" -> {
      use value <- decode.field(
        "value",
        inline_query_result_cached_gif_decoder(),
      )
      decode.success(InlineQueryResultCachedGifInlineQueryResult(value))
    }
    "inline_query_result_cached_mpeg4_gif" -> {
      use value <- decode.field(
        "value",
        inline_query_result_cached_mpeg4_gif_decoder(),
      )
      decode.success(InlineQueryResultCachedMpeg4GifInlineQueryResult(value))
    }
    "inline_query_result_cached_photo" -> {
      use value <- decode.field(
        "value",
        inline_query_result_cached_photo_decoder(),
      )
      decode.success(InlineQueryResultCachedPhotoInlineQueryResult(value))
    }
    "inline_query_result_cached_sticker" -> {
      use value <- decode.field(
        "value",
        inline_query_result_cached_sticker_decoder(),
      )
      decode.success(InlineQueryResultCachedStickerInlineQueryResult(value))
    }
    "inline_query_result_cached_video" -> {
      use value <- decode.field(
        "value",
        inline_query_result_cached_video_decoder(),
      )
      decode.success(InlineQueryResultCachedVideoInlineQueryResult(value))
    }
    "inline_query_result_cached_voice" -> {
      use value <- decode.field(
        "value",
        inline_query_result_cached_voice_decoder(),
      )
      decode.success(InlineQueryResultCachedVoiceInlineQueryResult(value))
    }
    "inline_query_result_article" -> {
      use value <- decode.field("value", inline_query_result_article_decoder())
      decode.success(InlineQueryResultArticleInlineQueryResult(value))
    }
    "inline_query_result_audio" -> {
      use value <- decode.field("value", inline_query_result_audio_decoder())
      decode.success(InlineQueryResultAudioInlineQueryResult(value))
    }
    "inline_query_result_contact" -> {
      use value <- decode.field("value", inline_query_result_contact_decoder())
      decode.success(InlineQueryResultContactInlineQueryResult(value))
    }
    "inline_query_result_game" -> {
      use value <- decode.field("value", inline_query_result_game_decoder())
      decode.success(InlineQueryResultGameInlineQueryResult(value))
    }
    "inline_query_result_document" -> {
      use value <- decode.field("value", inline_query_result_document_decoder())
      decode.success(InlineQueryResultDocumentInlineQueryResult(value))
    }
    "inline_query_result_gif" -> {
      use value <- decode.field("value", inline_query_result_gif_decoder())
      decode.success(InlineQueryResultGifInlineQueryResult(value))
    }
    "inline_query_result_location" -> {
      use value <- decode.field("value", inline_query_result_location_decoder())
      decode.success(InlineQueryResultLocationInlineQueryResult(value))
    }
    "inline_query_result_mpeg4_gif" -> {
      use value <- decode.field(
        "value",
        inline_query_result_mpeg4_gif_decoder(),
      )
      decode.success(InlineQueryResultMpeg4GifInlineQueryResult(value))
    }
    "inline_query_result_photo" -> {
      use value <- decode.field("value", inline_query_result_photo_decoder())
      decode.success(InlineQueryResultPhotoInlineQueryResult(value))
    }
    "inline_query_result_venue" -> {
      use value <- decode.field("value", inline_query_result_venue_decoder())
      decode.success(InlineQueryResultVenueInlineQueryResult(value))
    }
    "inline_query_result_video" -> {
      use value <- decode.field("value", inline_query_result_video_decoder())
      decode.success(InlineQueryResultVideoInlineQueryResult(value))
    }
    "inline_query_result_voice" -> {
      use value <- decode.field("value", inline_query_result_voice_decoder())
      decode.success(InlineQueryResultVoiceInlineQueryResult(value))
    }
    _ -> panic as "Invalid variant for InlineQueryResult"
  }
}

pub fn input_message_content_decoder() -> decode.Decoder(InputMessageContent) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "input_text_message_content" -> {
      use value <- decode.field("value", input_text_message_content_decoder())
      decode.success(InputTextMessageContentInputMessageContent(value))
    }
    "input_location_message_content" -> {
      use value <- decode.field(
        "value",
        input_location_message_content_decoder(),
      )
      decode.success(InputLocationMessageContentInputMessageContent(value))
    }
    "input_venue_message_content" -> {
      use value <- decode.field("value", input_venue_message_content_decoder())
      decode.success(InputVenueMessageContentInputMessageContent(value))
    }
    "input_contact_message_content" -> {
      use value <- decode.field(
        "value",
        input_contact_message_content_decoder(),
      )
      decode.success(InputContactMessageContentInputMessageContent(value))
    }
    "input_invoice_message_content" -> {
      use value <- decode.field(
        "value",
        input_invoice_message_content_decoder(),
      )
      decode.success(InputInvoiceMessageContentInputMessageContent(value))
    }
    _ -> panic as "Invalid variant for InputMessageContent"
  }
}

pub fn revenue_withdrawal_state_decoder() -> decode.Decoder(
  RevenueWithdrawalState,
) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "revenue_withdrawal_state_pending" -> {
      use value <- decode.field(
        "value",
        revenue_withdrawal_state_pending_decoder(),
      )
      decode.success(RevenueWithdrawalStatePendingRevenueWithdrawalState(value))
    }
    "revenue_withdrawal_state_succeeded" -> {
      use value <- decode.field(
        "value",
        revenue_withdrawal_state_succeeded_decoder(),
      )
      decode.success(RevenueWithdrawalStateSucceededRevenueWithdrawalState(
        value,
      ))
    }
    "revenue_withdrawal_state_failed" -> {
      use value <- decode.field(
        "value",
        revenue_withdrawal_state_failed_decoder(),
      )
      decode.success(RevenueWithdrawalStateFailedRevenueWithdrawalState(value))
    }
    _ -> panic as "Invalid variant for RevenueWithdrawalState"
  }
}

pub fn transaction_partner_decoder() -> decode.Decoder(TransactionPartner) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "transaction_partner_user" -> {
      use value <- decode.field("value", transaction_partner_user_decoder())
      decode.success(TransactionPartnerUserTransactionPartner(value))
    }
    "transaction_partner_chat" -> {
      use value <- decode.field("value", transaction_partner_chat_decoder())
      decode.success(TransactionPartnerChatTransactionPartner(value))
    }
    "transaction_partner_affiliate_program" -> {
      use value <- decode.field(
        "value",
        transaction_partner_affiliate_program_decoder(),
      )
      decode.success(TransactionPartnerAffiliateProgramTransactionPartner(value))
    }
    "transaction_partner_fragment" -> {
      use value <- decode.field("value", transaction_partner_fragment_decoder())
      decode.success(TransactionPartnerFragmentTransactionPartner(value))
    }
    "transaction_partner_telegram_ads" -> {
      use value <- decode.field(
        "value",
        transaction_partner_telegram_ads_decoder(),
      )
      decode.success(TransactionPartnerTelegramAdsTransactionPartner(value))
    }
    "transaction_partner_telegram_api" -> {
      use value <- decode.field(
        "value",
        transaction_partner_telegram_api_decoder(),
      )
      decode.success(TransactionPartnerTelegramApiTransactionPartner(value))
    }
    "transaction_partner_other" -> {
      use value <- decode.field("value", transaction_partner_other_decoder())
      decode.success(TransactionPartnerOtherTransactionPartner(value))
    }
    _ -> panic as "Invalid variant for TransactionPartner"
  }
}

pub fn passport_element_error_decoder() -> decode.Decoder(PassportElementError) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "passport_element_error_data_field" -> {
      use value <- decode.field(
        "value",
        passport_element_error_data_field_decoder(),
      )
      decode.success(PassportElementErrorDataFieldPassportElementError(value))
    }
    "passport_element_error_front_side" -> {
      use value <- decode.field(
        "value",
        passport_element_error_front_side_decoder(),
      )
      decode.success(PassportElementErrorFrontSidePassportElementError(value))
    }
    "passport_element_error_reverse_side" -> {
      use value <- decode.field(
        "value",
        passport_element_error_reverse_side_decoder(),
      )
      decode.success(PassportElementErrorReverseSidePassportElementError(value))
    }
    "passport_element_error_selfie" -> {
      use value <- decode.field(
        "value",
        passport_element_error_selfie_decoder(),
      )
      decode.success(PassportElementErrorSelfiePassportElementError(value))
    }
    "passport_element_error_file" -> {
      use value <- decode.field("value", passport_element_error_file_decoder())
      decode.success(PassportElementErrorFilePassportElementError(value))
    }
    "passport_element_error_files" -> {
      use value <- decode.field("value", passport_element_error_files_decoder())
      decode.success(PassportElementErrorFilesPassportElementError(value))
    }
    "passport_element_error_translation_file" -> {
      use value <- decode.field(
        "value",
        passport_element_error_translation_file_decoder(),
      )
      decode.success(PassportElementErrorTranslationFilePassportElementError(
        value,
      ))
    }
    "passport_element_error_translation_files" -> {
      use value <- decode.field(
        "value",
        passport_element_error_translation_files_decoder(),
      )
      decode.success(PassportElementErrorTranslationFilesPassportElementError(
        value,
      ))
    }
    "passport_element_error_unspecified" -> {
      use value <- decode.field(
        "value",
        passport_element_error_unspecified_decoder(),
      )
      decode.success(PassportElementErrorUnspecifiedPassportElementError(value))
    }
    _ -> panic as "Invalid variant for PassportElementError"
  }
}
