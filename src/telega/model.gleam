/// This module contains all types from [Telegram Bot API](https://core.telegram.org/bots/api).
///
/// Most of types named in the same way as in the official documentation.
/// But some types are renamed to more verbose names for using from Gleam code (ex. `type` -> `type_`).
import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None}

// This file was mostly auto-generated from the Telegram Bot API documentation.
// But I have to edit it for API params and generic types as a lot of cases
// are not supported by the auto-generated code.

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
    /// Optional. New incoming [inline](https://core.telegram.org/bots/api#inline-mode) query
    inline_query: Option(InlineQuery),
    /// Optional. The result of an [inline](https://core.telegram.org/bots/api#inline-mode) query that was chosen by a user and sent to their chat partner. Please see our documentation on the [feedback collecting](https://core.telegram.org/bots/inline#collecting-feedback) for details on how to enable these updates for your bot.
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
    type_: Option(String),
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

/// **Official reference:** Represents the rights of a business bot.
pub type BusinessBotRights {
  BusinessBotRights(
    /// Optional. True, if the bot can send and edit messages in the private chats that had incoming messages in the last 24 hours
    can_reply: Option(Bool),
    /// Optional. True, if the bot can mark incoming private messages as read
    can_read_messages: Option(Bool),
    /// Optional. True, if the bot can delete messages sent by the bot
    can_delete_outgoing_messages: Option(Bool),
    /// Optional. True, if the bot can delete all private messages in managed chats
    can_delete_all_messages: Option(Bool),
    /// Optional. True, if the bot can edit the first and last name of the business account
    can_edit_name: Option(Bool),
    /// Optional. True, if the bot can edit the bio of the business account
    can_edit_bio: Option(Bool),
    /// Optional. True, if the bot can edit the profile photo of the business account
    can_edit_profile_photo: Option(Bool),
    /// Optional. True, if the bot can edit the username of the business account
    can_edit_username: Option(Bool),
    /// Optional. True, if the bot can change the privacy settings pertaining to gifts for the business account
    can_change_gift_settings: Option(Bool),
    /// Optional. True, if the bot can view gifts and the amount of Telegram Stars owned by the business account
    can_view_gifts_and_stars: Option(Bool),
    /// Optional. True, if the bot can convert regular gifts owned by the business account to Telegram Stars
    can_convert_gifts_to_stars: Option(Bool),
    /// Optional. True, if the bot can transfer and upgrade gifts owned by the business account
    can_transfer_and_upgrade_gifts: Option(Bool),
    /// Optional. True, if the bot can transfer Telegram Stars received by the business account to its own account, or use them to upgrade and transfer gifts
    can_transfer_stars: Option(Bool),
    /// Optional. True, if the bot can post, edit and delete stories on behalf of the business account
    can_manage_stories: Option(Bool),
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
    /// Optional. Rights of the business bot
    rights: Option(BusinessBotRights),
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
  use message <- decode.optional_field(
    "message",
    None,
    decode.optional(message_decoder()),
  )
  use edited_message <- decode.optional_field(
    "edited_message",
    None,
    decode.optional(message_decoder()),
  )
  use channel_post <- decode.optional_field(
    "channel_post",
    None,
    decode.optional(message_decoder()),
  )
  use edited_channel_post <- decode.optional_field(
    "edited_channel_post",
    None,
    decode.optional(message_decoder()),
  )
  use business_connection <- decode.optional_field(
    "business_connection",
    None,
    decode.optional(business_connection_decoder()),
  )
  use business_message <- decode.optional_field(
    "business_message",
    None,
    decode.optional(message_decoder()),
  )
  use edited_business_message <- decode.optional_field(
    "edited_business_message",
    None,
    decode.optional(message_decoder()),
  )
  use deleted_business_messages <- decode.optional_field(
    "deleted_business_messages",
    None,
    decode.optional(business_messages_deleted_decoder()),
  )
  use message_reaction <- decode.optional_field(
    "message_reaction",
    None,
    decode.optional(message_reaction_updated_decoder()),
  )
  use message_reaction_count <- decode.optional_field(
    "message_reaction_count",
    None,
    decode.optional(message_reaction_count_updated_decoder()),
  )
  use inline_query <- decode.optional_field(
    "inline_query",
    None,
    decode.optional(inline_query_decoder()),
  )
  use chosen_inline_result <- decode.optional_field(
    "chosen_inline_result",
    None,
    decode.optional(chosen_inline_result_decoder()),
  )
  use callback_query <- decode.optional_field(
    "callback_query",
    None,
    decode.optional(callback_query_decoder()),
  )
  use shipping_query <- decode.optional_field(
    "shipping_query",
    None,
    decode.optional(shipping_query_decoder()),
  )
  use pre_checkout_query <- decode.optional_field(
    "pre_checkout_query",
    None,
    decode.optional(pre_checkout_query_decoder()),
  )
  use purchased_paid_media <- decode.optional_field(
    "purchased_paid_media",
    None,
    decode.optional(paid_media_purchased_decoder()),
  )
  use poll <- decode.optional_field(
    "poll",
    None,
    decode.optional(poll_decoder()),
  )
  use poll_answer <- decode.optional_field(
    "poll_answer",
    None,
    decode.optional(poll_answer_decoder()),
  )
  use my_chat_member <- decode.optional_field(
    "my_chat_member",
    None,
    decode.optional(chat_member_updated_decoder()),
  )
  use chat_member <- decode.optional_field(
    "chat_member",
    None,
    decode.optional(chat_member_updated_decoder()),
  )
  use chat_join_request <- decode.optional_field(
    "chat_join_request",
    None,
    decode.optional(chat_join_request_decoder()),
  )
  use chat_boost <- decode.optional_field(
    "chat_boost",
    None,
    decode.optional(chat_boost_updated_decoder()),
  )
  use removed_chat_boost <- decode.optional_field(
    "removed_chat_boost",
    None,
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
  use ip_address <- decode.optional_field(
    "ip_address",
    None,
    decode.optional(decode.string),
  )
  use last_error_date <- decode.optional_field(
    "last_error_date",
    None,
    decode.optional(decode.int),
  )
  use last_error_message <- decode.optional_field(
    "last_error_message",
    None,
    decode.optional(decode.string),
  )
  use last_synchronization_error_date <- decode.optional_field(
    "last_synchronization_error_date",
    None,
    decode.optional(decode.int),
  )
  use max_connections <- decode.optional_field(
    "max_connections",
    None,
    decode.optional(decode.int),
  )
  use allowed_updates <- decode.optional_field(
    "allowed_updates",
    None,
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
  use last_name <- decode.optional_field(
    "last_name",
    None,
    decode.optional(decode.string),
  )
  use username <- decode.optional_field(
    "username",
    None,
    decode.optional(decode.string),
  )
  use language_code <- decode.optional_field(
    "language_code",
    None,
    decode.optional(decode.string),
  )
  use is_premium <- decode.optional_field(
    "is_premium",
    None,
    decode.optional(decode.bool),
  )
  use added_to_attachment_menu <- decode.optional_field(
    "added_to_attachment_menu",
    None,
    decode.optional(decode.bool),
  )
  use can_join_groups <- decode.optional_field(
    "can_join_groups",
    None,
    decode.optional(decode.bool),
  )
  use can_read_all_group_messages <- decode.optional_field(
    "can_read_all_group_messages",
    None,
    decode.optional(decode.bool),
  )
  use supports_inline_queries <- decode.optional_field(
    "supports_inline_queries",
    None,
    decode.optional(decode.bool),
  )
  use can_connect_to_business <- decode.optional_field(
    "can_connect_to_business",
    None,
    decode.optional(decode.bool),
  )
  use has_main_web_app <- decode.optional_field(
    "has_main_web_app",
    None,
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
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use username <- decode.optional_field(
    "username",
    None,
    decode.optional(decode.string),
  )
  use first_name <- decode.optional_field(
    "first_name",
    None,
    decode.optional(decode.string),
  )
  use last_name <- decode.optional_field(
    "last_name",
    None,
    decode.optional(decode.string),
  )
  use is_forum <- decode.optional_field(
    "is_forum",
    None,
    decode.optional(decode.bool),
  )
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
  use type_ <- decode.field("type", decode.string)
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use username <- decode.optional_field(
    "username",
    None,
    decode.optional(decode.string),
  )
  use first_name <- decode.optional_field(
    "first_name",
    None,
    decode.optional(decode.string),
  )
  use last_name <- decode.optional_field(
    "last_name",
    None,
    decode.optional(decode.string),
  )
  use is_forum <- decode.optional_field(
    "is_forum",
    None,
    decode.optional(decode.bool),
  )
  use accent_color_id <- decode.field("accent_color_id", decode.int)
  use max_reaction_count <- decode.field("max_reaction_count", decode.int)
  use photo <- decode.optional_field(
    "photo",
    None,
    decode.optional(chat_photo_decoder()),
  )
  use active_usernames <- decode.optional_field(
    "active_usernames",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use birthdate <- decode.optional_field(
    "birthdate",
    None,
    decode.optional(birthdate_decoder()),
  )
  use business_intro <- decode.optional_field(
    "business_intro",
    None,
    decode.optional(business_intro_decoder()),
  )
  use business_location <- decode.optional_field(
    "business_location",
    None,
    decode.optional(business_location_decoder()),
  )
  use business_opening_hours <- decode.optional_field(
    "business_opening_hours",
    None,
    decode.optional(business_opening_hours_decoder()),
  )
  use personal_chat <- decode.optional_field(
    "personal_chat",
    None,
    decode.optional(chat_decoder()),
  )
  use available_reactions <- decode.optional_field(
    "available_reactions",
    None,
    decode.optional(decode.list(reaction_type_decoder())),
  )
  use background_custom_emoji_id <- decode.optional_field(
    "background_custom_emoji_id",
    None,
    decode.optional(decode.string),
  )
  use profile_accent_color_id <- decode.optional_field(
    "profile_accent_color_id",
    None,
    decode.optional(decode.int),
  )
  use profile_background_custom_emoji_id <- decode.optional_field(
    "profile_background_custom_emoji_id",
    None,
    decode.optional(decode.string),
  )
  use emoji_status_custom_emoji_id <- decode.optional_field(
    "emoji_status_custom_emoji_id",
    None,
    decode.optional(decode.string),
  )
  use emoji_status_expiration_date <- decode.optional_field(
    "emoji_status_expiration_date",
    None,
    decode.optional(decode.int),
  )
  use bio <- decode.optional_field("bio", None, decode.optional(decode.string))
  use has_private_forwards <- decode.optional_field(
    "has_private_forwards",
    None,
    decode.optional(decode.bool),
  )
  use has_restricted_voice_and_video_messages <- decode.optional_field(
    "has_restricted_voice_and_video_messages",
    None,
    decode.optional(decode.bool),
  )
  use join_to_send_messages <- decode.optional_field(
    "join_to_send_messages",
    None,
    decode.optional(decode.bool),
  )
  use join_by_request <- decode.optional_field(
    "join_by_request",
    None,
    decode.optional(decode.bool),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use invite_link <- decode.optional_field(
    "invite_link",
    None,
    decode.optional(decode.string),
  )
  use pinned_message <- decode.optional_field(
    "pinned_message",
    None,
    decode.optional(message_decoder()),
  )
  use permissions <- decode.optional_field(
    "permissions",
    None,
    decode.optional(chat_permissions_decoder()),
  )
  use can_send_gift <- decode.optional_field(
    "can_send_gift",
    None,
    decode.optional(decode.bool),
  )
  use can_send_paid_media <- decode.optional_field(
    "can_send_paid_media",
    None,
    decode.optional(decode.bool),
  )
  use slow_mode_delay <- decode.optional_field(
    "slow_mode_delay",
    None,
    decode.optional(decode.int),
  )
  use unrestrict_boost_count <- decode.optional_field(
    "unrestrict_boost_count",
    None,
    decode.optional(decode.int),
  )
  use message_auto_delete_time <- decode.optional_field(
    "message_auto_delete_time",
    None,
    decode.optional(decode.int),
  )
  use has_aggressive_anti_spam_enabled <- decode.optional_field(
    "has_aggressive_anti_spam_enabled",
    None,
    decode.optional(decode.bool),
  )
  use has_hidden_members <- decode.optional_field(
    "has_hidden_members",
    None,
    decode.optional(decode.bool),
  )
  use has_protected_content <- decode.optional_field(
    "has_protected_content",
    None,
    decode.optional(decode.bool),
  )
  use has_visible_history <- decode.optional_field(
    "has_visible_history",
    None,
    decode.optional(decode.bool),
  )
  use sticker_set_name <- decode.optional_field(
    "sticker_set_name",
    None,
    decode.optional(decode.string),
  )
  use can_set_sticker_set <- decode.optional_field(
    "can_set_sticker_set",
    None,
    decode.optional(decode.bool),
  )
  use custom_emoji_sticker_set_name <- decode.optional_field(
    "custom_emoji_sticker_set_name",
    None,
    decode.optional(decode.string),
  )
  use linked_chat_id <- decode.optional_field(
    "linked_chat_id",
    None,
    decode.optional(decode.int),
  )
  use location <- decode.optional_field(
    "location",
    None,
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
  use message_thread_id <- decode.optional_field(
    "message_thread_id",
    None,
    decode.optional(decode.int),
  )
  use from <- decode.optional_field(
    "from",
    None,
    decode.optional(user_decoder()),
  )
  use sender_chat <- decode.optional_field(
    "sender_chat",
    None,
    decode.optional(chat_decoder()),
  )
  use sender_boost_count <- decode.optional_field(
    "sender_boost_count",
    None,
    decode.optional(decode.int),
  )
  use sender_business_bot <- decode.optional_field(
    "sender_business_bot",
    None,
    decode.optional(user_decoder()),
  )
  use date <- decode.field("date", decode.int)
  use business_connection_id <- decode.optional_field(
    "business_connection_id",
    None,
    decode.optional(decode.string),
  )
  use chat <- decode.field("chat", chat_decoder())
  use forward_origin <- decode.optional_field(
    "forward_origin",
    None,
    decode.optional(message_origin_decoder()),
  )
  use is_topic_message <- decode.optional_field(
    "is_topic_message",
    None,
    decode.optional(decode.bool),
  )
  use is_automatic_forward <- decode.optional_field(
    "is_automatic_forward",
    None,
    decode.optional(decode.bool),
  )
  use reply_to_message <- decode.optional_field(
    "reply_to_message",
    None,
    decode.optional(message_decoder()),
  )
  use external_reply <- decode.optional_field(
    "external_reply",
    None,
    decode.optional(external_reply_info_decoder()),
  )
  use quote <- decode.optional_field(
    "quote",
    None,
    decode.optional(text_quote_decoder()),
  )
  use reply_to_story <- decode.optional_field(
    "reply_to_story",
    None,
    decode.optional(story_decoder()),
  )
  use via_bot <- decode.optional_field(
    "via_bot",
    None,
    decode.optional(user_decoder()),
  )
  use edit_date <- decode.optional_field(
    "edit_date",
    None,
    decode.optional(decode.int),
  )
  use has_protected_content <- decode.optional_field(
    "has_protected_content",
    None,
    decode.optional(decode.bool),
  )
  use is_from_offline <- decode.optional_field(
    "is_from_offline",
    None,
    decode.optional(decode.bool),
  )
  use media_group_id <- decode.optional_field(
    "media_group_id",
    None,
    decode.optional(decode.string),
  )
  use author_signature <- decode.optional_field(
    "author_signature",
    None,
    decode.optional(decode.string),
  )
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(decode.string),
  )
  use entities <- decode.optional_field(
    "entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use link_preview_options <- decode.optional_field(
    "link_preview_options",
    None,
    decode.optional(link_preview_options_decoder()),
  )
  use effect_id <- decode.optional_field(
    "effect_id",
    None,
    decode.optional(decode.string),
  )
  use animation <- decode.optional_field(
    "animation",
    None,
    decode.optional(animation_decoder()),
  )
  use audio <- decode.optional_field(
    "audio",
    None,
    decode.optional(audio_decoder()),
  )
  use document <- decode.optional_field(
    "document",
    None,
    decode.optional(document_decoder()),
  )
  use paid_media <- decode.optional_field(
    "paid_media",
    None,
    decode.optional(paid_media_info_decoder()),
  )
  use photo <- decode.optional_field(
    "photo",
    None,
    decode.optional(decode.list(photo_size_decoder())),
  )
  use sticker <- decode.optional_field(
    "sticker",
    None,
    decode.optional(sticker_decoder()),
  )
  use story <- decode.optional_field(
    "story",
    None,
    decode.optional(story_decoder()),
  )
  use video <- decode.optional_field(
    "video",
    None,
    decode.optional(video_decoder()),
  )
  use video_note <- decode.optional_field(
    "video_note",
    None,
    decode.optional(video_note_decoder()),
  )
  use voice <- decode.optional_field(
    "voice",
    None,
    decode.optional(voice_decoder()),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use has_media_spoiler <- decode.optional_field(
    "has_media_spoiler",
    None,
    decode.optional(decode.bool),
  )
  use contact <- decode.optional_field(
    "contact",
    None,
    decode.optional(contact_decoder()),
  )
  use dice <- decode.optional_field(
    "dice",
    None,
    decode.optional(dice_decoder()),
  )
  use game <- decode.optional_field(
    "game",
    None,
    decode.optional(game_decoder()),
  )
  use poll <- decode.optional_field(
    "poll",
    None,
    decode.optional(poll_decoder()),
  )
  use venue <- decode.optional_field(
    "venue",
    None,
    decode.optional(venue_decoder()),
  )
  use location <- decode.optional_field(
    "location",
    None,
    decode.optional(location_decoder()),
  )
  use new_chat_members <- decode.optional_field(
    "new_chat_members",
    None,
    decode.optional(decode.list(user_decoder())),
  )
  use left_chat_member <- decode.optional_field(
    "left_chat_member",
    None,
    decode.optional(user_decoder()),
  )
  use new_chat_title <- decode.optional_field(
    "new_chat_title",
    None,
    decode.optional(decode.string),
  )
  use new_chat_photo <- decode.optional_field(
    "new_chat_photo",
    None,
    decode.optional(decode.list(photo_size_decoder())),
  )
  use delete_chat_photo <- decode.optional_field(
    "delete_chat_photo",
    None,
    decode.optional(decode.bool),
  )
  use group_chat_created <- decode.optional_field(
    "group_chat_created",
    None,
    decode.optional(decode.bool),
  )
  use supergroup_chat_created <- decode.optional_field(
    "supergroup_chat_created",
    None,
    decode.optional(decode.bool),
  )
  use channel_chat_created <- decode.optional_field(
    "channel_chat_created",
    None,
    decode.optional(decode.bool),
  )
  use message_auto_delete_timer_changed <- decode.optional_field(
    "message_auto_delete_timer_changed",
    None,
    decode.optional(message_auto_delete_timer_changed_decoder()),
  )
  use migrate_to_chat_id <- decode.optional_field(
    "migrate_to_chat_id",
    None,
    decode.optional(decode.int),
  )
  use migrate_from_chat_id <- decode.optional_field(
    "migrate_from_chat_id",
    None,
    decode.optional(decode.int),
  )
  use pinned_message <- decode.optional_field(
    "pinned_message",
    None,
    decode.optional(maybe_inaccessible_message_decoder()),
  )
  use invoice <- decode.optional_field(
    "invoice",
    None,
    decode.optional(invoice_decoder()),
  )
  use successful_payment <- decode.optional_field(
    "successful_payment",
    None,
    decode.optional(successful_payment_decoder()),
  )
  use refunded_payment <- decode.optional_field(
    "refunded_payment",
    None,
    decode.optional(refunded_payment_decoder()),
  )
  use users_shared <- decode.optional_field(
    "users_shared",
    None,
    decode.optional(users_shared_decoder()),
  )
  use chat_shared <- decode.optional_field(
    "chat_shared",
    None,
    decode.optional(chat_shared_decoder()),
  )
  use connected_website <- decode.optional_field(
    "connected_website",
    None,
    decode.optional(decode.string),
  )
  use write_access_allowed <- decode.optional_field(
    "write_access_allowed",
    None,
    decode.optional(write_access_allowed_decoder()),
  )
  use passport_data <- decode.optional_field(
    "passport_data",
    None,
    decode.optional(passport_data_decoder()),
  )
  use proximity_alert_triggered <- decode.optional_field(
    "proximity_alert_triggered",
    None,
    decode.optional(proximity_alert_triggered_decoder()),
  )
  use boost_added <- decode.optional_field(
    "boost_added",
    None,
    decode.optional(chat_boost_added_decoder()),
  )
  use chat_background_set <- decode.optional_field(
    "chat_background_set",
    None,
    decode.optional(chat_background_decoder()),
  )
  use forum_topic_created <- decode.optional_field(
    "forum_topic_created",
    None,
    decode.optional(forum_topic_created_decoder()),
  )
  use forum_topic_edited <- decode.optional_field(
    "forum_topic_edited",
    None,
    decode.optional(forum_topic_edited_decoder()),
  )
  use forum_topic_closed <- decode.optional_field(
    "forum_topic_closed",
    None,
    decode.optional(forum_topic_closed_decoder()),
  )
  use forum_topic_reopened <- decode.optional_field(
    "forum_topic_reopened",
    None,
    decode.optional(forum_topic_reopened_decoder()),
  )
  use general_forum_topic_hidden <- decode.optional_field(
    "general_forum_topic_hidden",
    None,
    decode.optional(general_forum_topic_hidden_decoder()),
  )
  use general_forum_topic_unhidden <- decode.optional_field(
    "general_forum_topic_unhidden",
    None,
    decode.optional(general_forum_topic_unhidden_decoder()),
  )
  use giveaway_created <- decode.optional_field(
    "giveaway_created",
    None,
    decode.optional(giveaway_created_decoder()),
  )
  use giveaway <- decode.optional_field(
    "giveaway",
    None,
    decode.optional(giveaway_decoder()),
  )
  use giveaway_winners <- decode.optional_field(
    "giveaway_winners",
    None,
    decode.optional(giveaway_winners_decoder()),
  )
  use giveaway_completed <- decode.optional_field(
    "giveaway_completed",
    None,
    decode.optional(giveaway_completed_decoder()),
  )
  use video_chat_scheduled <- decode.optional_field(
    "video_chat_scheduled",
    None,
    decode.optional(video_chat_scheduled_decoder()),
  )
  use video_chat_started <- decode.optional_field(
    "video_chat_started",
    None,
    decode.optional(video_chat_started_decoder()),
  )
  use video_chat_ended <- decode.optional_field(
    "video_chat_ended",
    None,
    decode.optional(video_chat_ended_decoder()),
  )
  use video_chat_participants_invited <- decode.optional_field(
    "video_chat_participants_invited",
    None,
    decode.optional(video_chat_participants_invited_decoder()),
  )
  use web_app_data <- decode.optional_field(
    "web_app_data",
    None,
    decode.optional(web_app_data_decoder()),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use offset <- decode.field("offset", decode.int)
  use length <- decode.field("length", decode.int)
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user_decoder()),
  )
  use language <- decode.optional_field(
    "language",
    None,
    decode.optional(decode.string),
  )
  use custom_emoji_id <- decode.optional_field(
    "custom_emoji_id",
    None,
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
  use entities <- decode.optional_field(
    "entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use position <- decode.field("position", decode.int)
  use is_manual <- decode.optional_field(
    "is_manual",
    None,
    decode.optional(decode.bool),
  )
  decode.success(TextQuote(
    text: text,
    entities: entities,
    position: position,
    is_manual: is_manual,
  ))
}

pub fn external_reply_info_decoder() -> decode.Decoder(ExternalReplyInfo) {
  use origin <- decode.field("origin", message_origin_decoder())
  use chat <- decode.optional_field(
    "chat",
    None,
    decode.optional(chat_decoder()),
  )
  use message_id <- decode.optional_field(
    "message_id",
    None,
    decode.optional(decode.int),
  )
  use link_preview_options <- decode.optional_field(
    "link_preview_options",
    None,
    decode.optional(link_preview_options_decoder()),
  )
  use animation <- decode.optional_field(
    "animation",
    None,
    decode.optional(animation_decoder()),
  )
  use audio <- decode.optional_field(
    "audio",
    None,
    decode.optional(audio_decoder()),
  )
  use document <- decode.optional_field(
    "document",
    None,
    decode.optional(document_decoder()),
  )
  use paid_media <- decode.optional_field(
    "paid_media",
    None,
    decode.optional(paid_media_info_decoder()),
  )
  use photo <- decode.optional_field(
    "photo",
    None,
    decode.optional(decode.list(photo_size_decoder())),
  )
  use sticker <- decode.optional_field(
    "sticker",
    None,
    decode.optional(sticker_decoder()),
  )
  use story <- decode.optional_field(
    "story",
    None,
    decode.optional(story_decoder()),
  )
  use video <- decode.optional_field(
    "video",
    None,
    decode.optional(video_decoder()),
  )
  use video_note <- decode.optional_field(
    "video_note",
    None,
    decode.optional(video_note_decoder()),
  )
  use voice <- decode.optional_field(
    "voice",
    None,
    decode.optional(voice_decoder()),
  )
  use has_media_spoiler <- decode.optional_field(
    "has_media_spoiler",
    None,
    decode.optional(decode.bool),
  )
  use contact <- decode.optional_field(
    "contact",
    None,
    decode.optional(contact_decoder()),
  )
  use dice <- decode.optional_field(
    "dice",
    None,
    decode.optional(dice_decoder()),
  )
  use game <- decode.optional_field(
    "game",
    None,
    decode.optional(game_decoder()),
  )
  use giveaway <- decode.optional_field(
    "giveaway",
    None,
    decode.optional(giveaway_decoder()),
  )
  use giveaway_winners <- decode.optional_field(
    "giveaway_winners",
    None,
    decode.optional(giveaway_winners_decoder()),
  )
  use invoice <- decode.optional_field(
    "invoice",
    None,
    decode.optional(invoice_decoder()),
  )
  use location <- decode.optional_field(
    "location",
    None,
    decode.optional(location_decoder()),
  )
  use poll <- decode.optional_field(
    "poll",
    None,
    decode.optional(poll_decoder()),
  )
  use venue <- decode.optional_field(
    "venue",
    None,
    decode.optional(venue_decoder()),
  )
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
  use chat_id <- decode.optional_field(
    "chat_id",
    None,
    decode.optional(int_or_string_decoder()),
  )
  use allow_sending_without_reply <- decode.optional_field(
    "allow_sending_without_reply",
    None,
    decode.optional(decode.bool),
  )
  use quote <- decode.optional_field(
    "quote",
    None,
    decode.optional(decode.string),
  )
  use quote_parse_mode <- decode.optional_field(
    "quote_parse_mode",
    None,
    decode.optional(decode.string),
  )
  use quote_entities <- decode.optional_field(
    "quote_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use quote_position <- decode.optional_field(
    "quote_position",
    None,
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
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
  use date <- decode.field("date", decode.int)
  use sender_user_name <- decode.field("sender_user_name", decode.string)
  decode.success(MessageOriginHiddenUser(
    type_: type_,
    date: date,
    sender_user_name: sender_user_name,
  ))
}

pub fn message_origin_chat_decoder() -> decode.Decoder(MessageOriginChat) {
  use type_ <- decode.field("type", decode.string)
  use date <- decode.field("date", decode.int)
  use sender_chat <- decode.field("sender_chat", chat_decoder())
  use author_signature <- decode.optional_field(
    "author_signature",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use date <- decode.field("date", decode.int)
  use chat <- decode.field("chat", chat_decoder())
  use message_id <- decode.field("message_id", decode.int)
  use author_signature <- decode.optional_field(
    "author_signature",
    None,
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
  use file_size <- decode.optional_field(
    "file_size",
    None,
    decode.optional(decode.int),
  )
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
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(photo_size_decoder()),
  )
  use file_name <- decode.optional_field(
    "file_name",
    None,
    decode.optional(decode.string),
  )
  use mime_type <- decode.optional_field(
    "mime_type",
    None,
    decode.optional(decode.string),
  )
  use file_size <- decode.optional_field(
    "file_size",
    None,
    decode.optional(decode.int),
  )
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
  use performer <- decode.optional_field(
    "performer",
    None,
    decode.optional(decode.string),
  )
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use file_name <- decode.optional_field(
    "file_name",
    None,
    decode.optional(decode.string),
  )
  use mime_type <- decode.optional_field(
    "mime_type",
    None,
    decode.optional(decode.string),
  )
  use file_size <- decode.optional_field(
    "file_size",
    None,
    decode.optional(decode.int),
  )
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
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
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(photo_size_decoder()),
  )
  use file_name <- decode.optional_field(
    "file_name",
    None,
    decode.optional(decode.string),
  )
  use mime_type <- decode.optional_field(
    "mime_type",
    None,
    decode.optional(decode.string),
  )
  use file_size <- decode.optional_field(
    "file_size",
    None,
    decode.optional(decode.int),
  )
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
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(photo_size_decoder()),
  )
  use cover <- decode.optional_field(
    "cover",
    None,
    decode.optional(decode.list(photo_size_decoder())),
  )
  use start_timestamp <- decode.optional_field(
    "start_timestamp",
    None,
    decode.optional(decode.int),
  )
  use file_name <- decode.optional_field(
    "file_name",
    None,
    decode.optional(decode.string),
  )
  use mime_type <- decode.optional_field(
    "mime_type",
    None,
    decode.optional(decode.string),
  )
  use file_size <- decode.optional_field(
    "file_size",
    None,
    decode.optional(decode.int),
  )
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
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(photo_size_decoder()),
  )
  use file_size <- decode.optional_field(
    "file_size",
    None,
    decode.optional(decode.int),
  )
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
  use mime_type <- decode.optional_field(
    "mime_type",
    None,
    decode.optional(decode.string),
  )
  use file_size <- decode.optional_field(
    "file_size",
    None,
    decode.optional(decode.int),
  )
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
  use type_ <- decode.field("type", decode.string)
  use width <- decode.optional_field("width", None, decode.optional(decode.int))
  use height <- decode.optional_field(
    "height",
    None,
    decode.optional(decode.int),
  )
  use duration <- decode.optional_field(
    "duration",
    None,
    decode.optional(decode.int),
  )
  decode.success(PaidMediaPreview(
    type_: type_,
    width: width,
    height: height,
    duration: duration,
  ))
}

pub fn paid_media_photo_decoder() -> decode.Decoder(PaidMediaPhoto) {
  use type_ <- decode.field("type", decode.string)
  use photo <- decode.field("photo", decode.list(photo_size_decoder()))
  decode.success(PaidMediaPhoto(type_: type_, photo: photo))
}

pub fn paid_media_video_decoder() -> decode.Decoder(PaidMediaVideo) {
  use type_ <- decode.field("type", decode.string)
  use video <- decode.field("video", video_decoder())
  decode.success(PaidMediaVideo(type_: type_, video: video))
}

pub fn contact_decoder() -> decode.Decoder(Contact) {
  use phone_number <- decode.field("phone_number", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.optional_field(
    "last_name",
    None,
    decode.optional(decode.string),
  )
  use user_id <- decode.optional_field(
    "user_id",
    None,
    decode.optional(decode.int),
  )
  use vcard <- decode.optional_field(
    "vcard",
    None,
    decode.optional(decode.string),
  )
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
  use text_entities <- decode.optional_field(
    "text_entities",
    None,
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
  use text_parse_mode <- decode.optional_field(
    "text_parse_mode",
    None,
    decode.optional(decode.string),
  )
  use text_entities <- decode.optional_field(
    "text_entities",
    None,
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
  use voter_chat <- decode.optional_field(
    "voter_chat",
    None,
    decode.optional(chat_decoder()),
  )
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user_decoder()),
  )
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
  use question_entities <- decode.optional_field(
    "question_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use options <- decode.field("options", decode.list(poll_option_decoder()))
  use total_voter_count <- decode.field("total_voter_count", decode.int)
  use is_closed <- decode.field("is_closed", decode.bool)
  use is_anonymous <- decode.field("is_anonymous", decode.bool)
  use type_ <- decode.field("type", decode.string)
  use allows_multiple_answers <- decode.field(
    "allows_multiple_answers",
    decode.bool,
  )
  use correct_option_id <- decode.optional_field(
    "correct_option_id",
    None,
    decode.optional(decode.int),
  )
  use explanation <- decode.optional_field(
    "explanation",
    None,
    decode.optional(decode.string),
  )
  use explanation_entities <- decode.optional_field(
    "explanation_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use open_period <- decode.optional_field(
    "open_period",
    None,
    decode.optional(decode.int),
  )
  use close_date <- decode.optional_field(
    "close_date",
    None,
    decode.optional(decode.int),
  )
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
  use horizontal_accuracy <- decode.optional_field(
    "horizontal_accuracy",
    None,
    decode.optional(decode.float),
  )
  use live_period <- decode.optional_field(
    "live_period",
    None,
    decode.optional(decode.int),
  )
  use heading <- decode.optional_field(
    "heading",
    None,
    decode.optional(decode.int),
  )
  use proximity_alert_radius <- decode.optional_field(
    "proximity_alert_radius",
    None,
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
  use foursquare_id <- decode.optional_field(
    "foursquare_id",
    None,
    decode.optional(decode.string),
  )
  use foursquare_type <- decode.optional_field(
    "foursquare_type",
    None,
    decode.optional(decode.string),
  )
  use google_place_id <- decode.optional_field(
    "google_place_id",
    None,
    decode.optional(decode.string),
  )
  use google_place_type <- decode.optional_field(
    "google_place_type",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use color <- decode.field("color", decode.int)
  decode.success(BackgroundFillSolid(type_: type_, color: color))
}

pub fn background_fill_gradient_decoder() -> decode.Decoder(
  BackgroundFillGradient,
) {
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
  use colors <- decode.field("colors", decode.list(decode.int))
  decode.success(BackgroundFillFreeformGradient(type_: type_, colors: colors))
}

pub fn background_type_fill_decoder() -> decode.Decoder(BackgroundTypeFill) {
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
  use document <- decode.field("document", document_decoder())
  use dark_theme_dimming <- decode.field("dark_theme_dimming", decode.int)
  use is_blurred <- decode.optional_field(
    "is_blurred",
    None,
    decode.optional(decode.bool),
  )
  use is_moving <- decode.optional_field(
    "is_moving",
    None,
    decode.optional(decode.bool),
  )
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
  use type_ <- decode.field("type", decode.string)
  use document <- decode.field("document", document_decoder())
  use fill <- decode.field("fill", background_fill_decoder())
  use intensity <- decode.field("intensity", decode.int)
  use is_inverted <- decode.optional_field(
    "is_inverted",
    None,
    decode.optional(decode.bool),
  )
  use is_moving <- decode.optional_field(
    "is_moving",
    None,
    decode.optional(decode.bool),
  )
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
  use type_ <- decode.field("type", decode.string)
  use theme_name <- decode.field("theme_name", decode.string)
  decode.success(BackgroundTypeChatTheme(type_: type_, theme_name: theme_name))
}

pub fn chat_background_decoder() -> decode.Decoder(ChatBackground) {
  use type_ <- decode.field("type", background_type_decoder())
  decode.success(ChatBackground(type_: type_))
}

pub fn forum_topic_created_decoder() -> decode.Decoder(ForumTopicCreated) {
  use name <- decode.field("name", decode.string)
  use icon_color <- decode.field("icon_color", decode.int)
  use icon_custom_emoji_id <- decode.optional_field(
    "icon_custom_emoji_id",
    None,
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
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use icon_custom_emoji_id <- decode.optional_field(
    "icon_custom_emoji_id",
    None,
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
  use first_name <- decode.optional_field(
    "first_name",
    None,
    decode.optional(decode.string),
  )
  use last_name <- decode.optional_field(
    "last_name",
    None,
    decode.optional(decode.string),
  )
  use username <- decode.optional_field(
    "username",
    None,
    decode.optional(decode.string),
  )
  use photo <- decode.optional_field(
    "photo",
    None,
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
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use username <- decode.optional_field(
    "username",
    None,
    decode.optional(decode.string),
  )
  use photo <- decode.optional_field(
    "photo",
    None,
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
  use from_request <- decode.optional_field(
    "from_request",
    None,
    decode.optional(decode.bool),
  )
  use web_app_name <- decode.optional_field(
    "web_app_name",
    None,
    decode.optional(decode.string),
  )
  use from_attachment_menu <- decode.optional_field(
    "from_attachment_menu",
    None,
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
  use prize_star_count <- decode.optional_field(
    "prize_star_count",
    None,
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
  use only_new_members <- decode.optional_field(
    "only_new_members",
    None,
    decode.optional(decode.bool),
  )
  use has_public_winners <- decode.optional_field(
    "has_public_winners",
    None,
    decode.optional(decode.bool),
  )
  use prize_description <- decode.optional_field(
    "prize_description",
    None,
    decode.optional(decode.string),
  )
  use country_codes <- decode.optional_field(
    "country_codes",
    None,
    decode.optional(decode.list(decode.string)),
  )
  use prize_star_count <- decode.optional_field(
    "prize_star_count",
    None,
    decode.optional(decode.int),
  )
  use premium_subscription_month_count <- decode.optional_field(
    "premium_subscription_month_count",
    None,
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
  use additional_chat_count <- decode.optional_field(
    "additional_chat_count",
    None,
    decode.optional(decode.int),
  )
  use prize_star_count <- decode.optional_field(
    "prize_star_count",
    None,
    decode.optional(decode.int),
  )
  use premium_subscription_month_count <- decode.optional_field(
    "premium_subscription_month_count",
    None,
    decode.optional(decode.int),
  )
  use unclaimed_prize_count <- decode.optional_field(
    "unclaimed_prize_count",
    None,
    decode.optional(decode.int),
  )
  use only_new_members <- decode.optional_field(
    "only_new_members",
    None,
    decode.optional(decode.bool),
  )
  use was_refunded <- decode.optional_field(
    "was_refunded",
    None,
    decode.optional(decode.bool),
  )
  use prize_description <- decode.optional_field(
    "prize_description",
    None,
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
  use unclaimed_prize_count <- decode.optional_field(
    "unclaimed_prize_count",
    None,
    decode.optional(decode.int),
  )
  use giveaway_message <- decode.optional_field(
    "giveaway_message",
    None,
    decode.optional(message_decoder()),
  )
  use is_star_giveaway <- decode.optional_field(
    "is_star_giveaway",
    None,
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
  use is_disabled <- decode.optional_field(
    "is_disabled",
    None,
    decode.optional(decode.bool),
  )
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use prefer_small_media <- decode.optional_field(
    "prefer_small_media",
    None,
    decode.optional(decode.bool),
  )
  use prefer_large_media <- decode.optional_field(
    "prefer_large_media",
    None,
    decode.optional(decode.bool),
  )
  use show_above_text <- decode.optional_field(
    "show_above_text",
    None,
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
  use file_size <- decode.optional_field(
    "file_size",
    None,
    decode.optional(decode.int),
  )
  use file_path <- decode.optional_field(
    "file_path",
    None,
    decode.optional(decode.string),
  )
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
  use is_persistent <- decode.optional_field(
    "is_persistent",
    None,
    decode.optional(decode.bool),
  )
  use resize_keyboard <- decode.optional_field(
    "resize_keyboard",
    None,
    decode.optional(decode.bool),
  )
  use one_time_keyboard <- decode.optional_field(
    "one_time_keyboard",
    None,
    decode.optional(decode.bool),
  )
  use input_field_placeholder <- decode.optional_field(
    "input_field_placeholder",
    None,
    decode.optional(decode.string),
  )
  use selective <- decode.optional_field(
    "selective",
    None,
    decode.optional(decode.bool),
  )
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
  use request_users <- decode.optional_field(
    "request_users",
    None,
    decode.optional(keyboard_button_request_users_decoder()),
  )
  use request_chat <- decode.optional_field(
    "request_chat",
    None,
    decode.optional(keyboard_button_request_chat_decoder()),
  )
  use request_contact <- decode.optional_field(
    "request_contact",
    None,
    decode.optional(decode.bool),
  )
  use request_location <- decode.optional_field(
    "request_location",
    None,
    decode.optional(decode.bool),
  )
  use request_poll <- decode.optional_field(
    "request_poll",
    None,
    decode.optional(keyboard_button_poll_type_decoder()),
  )
  use web_app <- decode.optional_field(
    "web_app",
    None,
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
  use user_is_bot <- decode.optional_field(
    "user_is_bot",
    None,
    decode.optional(decode.bool),
  )
  use user_is_premium <- decode.optional_field(
    "user_is_premium",
    None,
    decode.optional(decode.bool),
  )
  use max_quantity <- decode.optional_field(
    "max_quantity",
    None,
    decode.optional(decode.int),
  )
  use request_name <- decode.optional_field(
    "request_name",
    None,
    decode.optional(decode.bool),
  )
  use request_username <- decode.optional_field(
    "request_username",
    None,
    decode.optional(decode.bool),
  )
  use request_photo <- decode.optional_field(
    "request_photo",
    None,
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
  use chat_is_forum <- decode.optional_field(
    "chat_is_forum",
    None,
    decode.optional(decode.bool),
  )
  use chat_has_username <- decode.optional_field(
    "chat_has_username",
    None,
    decode.optional(decode.bool),
  )
  use chat_is_created <- decode.optional_field(
    "chat_is_created",
    None,
    decode.optional(decode.bool),
  )
  use user_administrator_rights <- decode.optional_field(
    "user_administrator_rights",
    None,
    decode.optional(chat_administrator_rights_decoder()),
  )
  use bot_administrator_rights <- decode.optional_field(
    "bot_administrator_rights",
    None,
    decode.optional(chat_administrator_rights_decoder()),
  )
  use bot_is_member <- decode.optional_field(
    "bot_is_member",
    None,
    decode.optional(decode.bool),
  )
  use request_title <- decode.optional_field(
    "request_title",
    None,
    decode.optional(decode.bool),
  )
  use request_username <- decode.optional_field(
    "request_username",
    None,
    decode.optional(decode.bool),
  )
  use request_photo <- decode.optional_field(
    "request_photo",
    None,
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
  use type_ <- decode.optional_field(
    "type",
    None,
    decode.optional(decode.string),
  )
  decode.success(KeyboardButtonPollType(type_: type_))
}

pub fn reply_keyboard_remove_decoder() -> decode.Decoder(ReplyKeyboardRemove) {
  use remove_keyboard <- decode.field("remove_keyboard", decode.bool)
  use selective <- decode.optional_field(
    "selective",
    None,
    decode.optional(decode.bool),
  )
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
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use callback_data <- decode.optional_field(
    "callback_data",
    None,
    decode.optional(decode.string),
  )
  use web_app <- decode.optional_field(
    "web_app",
    None,
    decode.optional(web_app_info_decoder()),
  )
  use login_url <- decode.optional_field(
    "login_url",
    None,
    decode.optional(login_url_decoder()),
  )
  use switch_inline_query <- decode.optional_field(
    "switch_inline_query",
    None,
    decode.optional(decode.string),
  )
  use switch_inline_query_current_chat <- decode.optional_field(
    "switch_inline_query_current_chat",
    None,
    decode.optional(decode.string),
  )
  use switch_inline_query_chosen_chat <- decode.optional_field(
    "switch_inline_query_chosen_chat",
    None,
    decode.optional(switch_inline_query_chosen_chat_decoder()),
  )
  use copy_text <- decode.optional_field(
    "copy_text",
    None,
    decode.optional(copy_text_button_decoder()),
  )
  use callback_game <- decode.optional_field(
    "callback_game",
    None,
    decode.optional(callback_game_decoder()),
  )
  use pay <- decode.optional_field("pay", None, decode.optional(decode.bool))
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
  use forward_text <- decode.optional_field(
    "forward_text",
    None,
    decode.optional(decode.string),
  )
  use bot_username <- decode.optional_field(
    "bot_username",
    None,
    decode.optional(decode.string),
  )
  use request_write_access <- decode.optional_field(
    "request_write_access",
    None,
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
  use query <- decode.optional_field(
    "query",
    None,
    decode.optional(decode.string),
  )
  use allow_user_chats <- decode.optional_field(
    "allow_user_chats",
    None,
    decode.optional(decode.bool),
  )
  use allow_bot_chats <- decode.optional_field(
    "allow_bot_chats",
    None,
    decode.optional(decode.bool),
  )
  use allow_group_chats <- decode.optional_field(
    "allow_group_chats",
    None,
    decode.optional(decode.bool),
  )
  use allow_channel_chats <- decode.optional_field(
    "allow_channel_chats",
    None,
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
  use message <- decode.optional_field(
    "message",
    None,
    decode.optional(maybe_inaccessible_message_decoder()),
  )
  use inline_message_id <- decode.optional_field(
    "inline_message_id",
    None,
    decode.optional(decode.string),
  )
  use chat_instance <- decode.field("chat_instance", decode.string)
  use data <- decode.optional_field(
    "data",
    None,
    decode.optional(decode.string),
  )
  use game_short_name <- decode.optional_field(
    "game_short_name",
    None,
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
  use input_field_placeholder <- decode.optional_field(
    "input_field_placeholder",
    None,
    decode.optional(decode.string),
  )
  use selective <- decode.optional_field(
    "selective",
    None,
    decode.optional(decode.bool),
  )
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
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use expire_date <- decode.optional_field(
    "expire_date",
    None,
    decode.optional(decode.int),
  )
  use member_limit <- decode.optional_field(
    "member_limit",
    None,
    decode.optional(decode.int),
  )
  use pending_join_request_count <- decode.optional_field(
    "pending_join_request_count",
    None,
    decode.optional(decode.int),
  )
  use subscription_period <- decode.optional_field(
    "subscription_period",
    None,
    decode.optional(decode.int),
  )
  use subscription_price <- decode.optional_field(
    "subscription_price",
    None,
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
  use can_post_messages <- decode.optional_field(
    "can_post_messages",
    None,
    decode.optional(decode.bool),
  )
  use can_edit_messages <- decode.optional_field(
    "can_edit_messages",
    None,
    decode.optional(decode.bool),
  )
  use can_pin_messages <- decode.optional_field(
    "can_pin_messages",
    None,
    decode.optional(decode.bool),
  )
  use can_manage_topics <- decode.optional_field(
    "can_manage_topics",
    None,
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
  use invite_link <- decode.optional_field(
    "invite_link",
    None,
    decode.optional(chat_invite_link_decoder()),
  )
  use via_join_request <- decode.optional_field(
    "via_join_request",
    None,
    decode.optional(decode.bool),
  )
  use via_chat_folder_invite_link <- decode.optional_field(
    "via_chat_folder_invite_link",
    None,
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
  use custom_title <- decode.optional_field(
    "custom_title",
    None,
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
  use can_post_messages <- decode.optional_field(
    "can_post_messages",
    None,
    decode.optional(decode.bool),
  )
  use can_edit_messages <- decode.optional_field(
    "can_edit_messages",
    None,
    decode.optional(decode.bool),
  )
  use can_pin_messages <- decode.optional_field(
    "can_pin_messages",
    None,
    decode.optional(decode.bool),
  )
  use can_manage_topics <- decode.optional_field(
    "can_manage_topics",
    None,
    decode.optional(decode.bool),
  )
  use custom_title <- decode.optional_field(
    "custom_title",
    None,
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
  use until_date <- decode.optional_field(
    "until_date",
    None,
    decode.optional(decode.int),
  )
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
  use bio <- decode.optional_field("bio", None, decode.optional(decode.string))
  use invite_link <- decode.optional_field(
    "invite_link",
    None,
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
  use can_send_messages <- decode.optional_field(
    "can_send_messages",
    None,
    decode.optional(decode.bool),
  )
  use can_send_audios <- decode.optional_field(
    "can_send_audios",
    None,
    decode.optional(decode.bool),
  )
  use can_send_documents <- decode.optional_field(
    "can_send_documents",
    None,
    decode.optional(decode.bool),
  )
  use can_send_photos <- decode.optional_field(
    "can_send_photos",
    None,
    decode.optional(decode.bool),
  )
  use can_send_videos <- decode.optional_field(
    "can_send_videos",
    None,
    decode.optional(decode.bool),
  )
  use can_send_video_notes <- decode.optional_field(
    "can_send_video_notes",
    None,
    decode.optional(decode.bool),
  )
  use can_send_voice_notes <- decode.optional_field(
    "can_send_voice_notes",
    None,
    decode.optional(decode.bool),
  )
  use can_send_polls <- decode.optional_field(
    "can_send_polls",
    None,
    decode.optional(decode.bool),
  )
  use can_send_other_messages <- decode.optional_field(
    "can_send_other_messages",
    None,
    decode.optional(decode.bool),
  )
  use can_add_web_page_previews <- decode.optional_field(
    "can_add_web_page_previews",
    None,
    decode.optional(decode.bool),
  )
  use can_change_info <- decode.optional_field(
    "can_change_info",
    None,
    decode.optional(decode.bool),
  )
  use can_invite_users <- decode.optional_field(
    "can_invite_users",
    None,
    decode.optional(decode.bool),
  )
  use can_pin_messages <- decode.optional_field(
    "can_pin_messages",
    None,
    decode.optional(decode.bool),
  )
  use can_manage_topics <- decode.optional_field(
    "can_manage_topics",
    None,
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
  use year <- decode.optional_field("year", None, decode.optional(decode.int))
  decode.success(Birthdate(day: day, month: month, year: year))
}

pub fn business_intro_decoder() -> decode.Decoder(BusinessIntro) {
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use message <- decode.optional_field(
    "message",
    None,
    decode.optional(decode.string),
  )
  use sticker <- decode.optional_field(
    "sticker",
    None,
    decode.optional(sticker_decoder()),
  )
  decode.success(BusinessIntro(title: title, message: message, sticker: sticker))
}

pub fn business_location_decoder() -> decode.Decoder(BusinessLocation) {
  use address <- decode.field("address", decode.string)
  use location <- decode.optional_field(
    "location",
    None,
    decode.optional(location_decoder()),
  )
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
  use type_ <- decode.field("type", decode.string)
  use emoji <- decode.field("emoji", decode.string)
  decode.success(ReactionTypeEmoji(type_: type_, emoji: emoji))
}

pub fn reaction_type_custom_emoji_decoder() -> decode.Decoder(
  ReactionTypeCustomEmoji,
) {
  use type_ <- decode.field("type", decode.string)
  use custom_emoji_id <- decode.field("custom_emoji_id", decode.string)
  decode.success(ReactionTypeCustomEmoji(
    type_: type_,
    custom_emoji_id: custom_emoji_id,
  ))
}

pub fn reaction_type_paid_decoder() -> decode.Decoder(ReactionTypePaid) {
  use type_ <- decode.field("type", decode.string)
  decode.success(ReactionTypePaid(type_: type_))
}

pub fn reaction_count_decoder() -> decode.Decoder(ReactionCount) {
  use type_ <- decode.field("type", reaction_type_decoder())
  use total_count <- decode.field("total_count", decode.int)
  decode.success(ReactionCount(type_: type_, total_count: total_count))
}

pub fn message_reaction_updated_decoder() -> decode.Decoder(
  MessageReactionUpdated,
) {
  use chat <- decode.field("chat", chat_decoder())
  use message_id <- decode.field("message_id", decode.int)
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user_decoder()),
  )
  use actor_chat <- decode.optional_field(
    "actor_chat",
    None,
    decode.optional(chat_decoder()),
  )
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
  use icon_custom_emoji_id <- decode.optional_field(
    "icon_custom_emoji_id",
    None,
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
  use type_ <- decode.field("type", decode.string)
  decode.success(BotCommandScopeDefault(type_: type_))
}

pub fn bot_command_scope_all_private_chats_decoder() -> decode.Decoder(
  BotCommandScopeAllPrivateChats,
) {
  use type_ <- decode.field("type", decode.string)
  decode.success(BotCommandScopeAllPrivateChats(type_: type_))
}

pub fn bot_command_scope_all_group_chats_decoder() -> decode.Decoder(
  BotCommandScopeAllGroupChats,
) {
  use type_ <- decode.field("type", decode.string)
  decode.success(BotCommandScopeAllGroupChats(type_: type_))
}

pub fn bot_command_scope_all_chat_administrators_decoder() -> decode.Decoder(
  BotCommandScopeAllChatAdministrators,
) {
  use type_ <- decode.field("type", decode.string)
  decode.success(BotCommandScopeAllChatAdministrators(type_: type_))
}

pub fn bot_command_scope_chat_decoder() -> decode.Decoder(BotCommandScopeChat) {
  use type_ <- decode.field("type", decode.string)
  use chat_id <- decode.field("chat_id", int_or_string_decoder())
  decode.success(BotCommandScopeChat(type_: type_, chat_id: chat_id))
}

pub fn bot_command_scope_chat_administrators_decoder() -> decode.Decoder(
  BotCommandScopeChatAdministrators,
) {
  use type_ <- decode.field("type", decode.string)
  use chat_id <- decode.field("chat_id", int_or_string_decoder())
  decode.success(BotCommandScopeChatAdministrators(
    type_: type_,
    chat_id: chat_id,
  ))
}

pub fn bot_command_scope_chat_member_decoder() -> decode.Decoder(
  BotCommandScopeChatMember,
) {
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
  decode.success(MenuButtonCommands(type_: type_))
}

pub fn menu_button_web_app_decoder() -> decode.Decoder(MenuButtonWebApp) {
  use type_ <- decode.field("type", decode.string)
  use text <- decode.field("text", decode.string)
  use web_app <- decode.field("web_app", web_app_info_decoder())
  decode.success(MenuButtonWebApp(type_: type_, text: text, web_app: web_app))
}

pub fn menu_button_default_decoder() -> decode.Decoder(MenuButtonDefault) {
  use type_ <- decode.field("type", decode.string)
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
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user_decoder()),
  )
  use prize_star_count <- decode.optional_field(
    "prize_star_count",
    None,
    decode.optional(decode.int),
  )
  use is_unclaimed <- decode.optional_field(
    "is_unclaimed",
    None,
    decode.optional(decode.bool),
  )
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

pub fn business_bot_rights_decoder() -> decode.Decoder(BusinessBotRights) {
  use can_reply <- decode.field("can_reply", decode.optional(decode.bool))
  use can_read_messages <- decode.field(
    "can_read_messages",
    decode.optional(decode.bool),
  )
  use can_delete_outgoing_messages <- decode.field(
    "can_delete_outgoing_messages",
    decode.optional(decode.bool),
  )
  use can_delete_all_messages <- decode.field(
    "can_delete_all_messages",
    decode.optional(decode.bool),
  )
  use can_edit_name <- decode.field(
    "can_edit_name",
    decode.optional(decode.bool),
  )
  use can_edit_bio <- decode.field("can_edit_bio", decode.optional(decode.bool))
  use can_edit_profile_photo <- decode.field(
    "can_edit_profile_photo",
    decode.optional(decode.bool),
  )
  use can_edit_username <- decode.field(
    "can_edit_username",
    decode.optional(decode.bool),
  )
  use can_change_gift_settings <- decode.field(
    "can_change_gift_settings",
    decode.optional(decode.bool),
  )
  use can_view_gifts_and_stars <- decode.field(
    "can_view_gifts_and_stars",
    decode.optional(decode.bool),
  )
  use can_convert_gifts_to_stars <- decode.field(
    "can_convert_gifts_to_stars",
    decode.optional(decode.bool),
  )
  use can_transfer_and_upgrade_gifts <- decode.field(
    "can_transfer_and_upgrade_gifts",
    decode.optional(decode.bool),
  )
  use can_transfer_stars <- decode.field(
    "can_transfer_stars",
    decode.optional(decode.bool),
  )
  use can_manage_stories <- decode.field(
    "can_manage_stories",
    decode.optional(decode.bool),
  )
  decode.success(BusinessBotRights(
    can_reply: can_reply,
    can_read_messages: can_read_messages,
    can_delete_outgoing_messages: can_delete_outgoing_messages,
    can_delete_all_messages: can_delete_all_messages,
    can_edit_name: can_edit_name,
    can_edit_bio: can_edit_bio,
    can_edit_profile_photo: can_edit_profile_photo,
    can_edit_username: can_edit_username,
    can_change_gift_settings: can_change_gift_settings,
    can_view_gifts_and_stars: can_view_gifts_and_stars,
    can_convert_gifts_to_stars: can_convert_gifts_to_stars,
    can_transfer_and_upgrade_gifts: can_transfer_and_upgrade_gifts,
    can_transfer_stars: can_transfer_stars,
    can_manage_stories: can_manage_stories,
  ))
}

pub fn business_connection_decoder() -> decode.Decoder(BusinessConnection) {
  use id <- decode.field("id", decode.string)
  use user <- decode.field("user", user_decoder())
  use user_chat_id <- decode.field("user_chat_id", decode.int)
  use date <- decode.field("date", decode.int)
  use rights <- decode.field(
    "rights",
    decode.optional(business_bot_rights_decoder()),
  )
  use is_enabled <- decode.field("is_enabled", decode.bool)
  decode.success(BusinessConnection(
    id: id,
    user: user,
    user_chat_id: user_chat_id,
    date: date,
    rights: rights,
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
  use migrate_to_chat_id <- decode.optional_field(
    "migrate_to_chat_id",
    None,
    decode.optional(decode.int),
  )
  use retry_after <- decode.optional_field(
    "retry_after",
    None,
    decode.optional(decode.int),
  )
  decode.success(ResponseParameters(
    migrate_to_chat_id: migrate_to_chat_id,
    retry_after: retry_after,
  ))
}

pub fn input_media_photo_decoder() -> decode.Decoder(InputMediaPhoto) {
  use type_ <- decode.field("type", decode.string)
  use media <- decode.field("media", decode.string)
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use has_spoiler <- decode.optional_field(
    "has_spoiler",
    None,
    decode.optional(decode.bool),
  )
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
  use type_ <- decode.field("type", decode.string)
  use media <- decode.field("media", decode.string)
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(decode.string),
  )
  use cover <- decode.optional_field(
    "cover",
    None,
    decode.optional(decode.string),
  )
  use start_timestamp <- decode.optional_field(
    "start_timestamp",
    None,
    decode.optional(decode.int),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use width <- decode.optional_field("width", None, decode.optional(decode.int))
  use height <- decode.optional_field(
    "height",
    None,
    decode.optional(decode.int),
  )
  use duration <- decode.optional_field(
    "duration",
    None,
    decode.optional(decode.int),
  )
  use supports_streaming <- decode.optional_field(
    "supports_streaming",
    None,
    decode.optional(decode.bool),
  )
  use has_spoiler <- decode.optional_field(
    "has_spoiler",
    None,
    decode.optional(decode.bool),
  )
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
  use type_ <- decode.field("type", decode.string)
  use media <- decode.field("media", decode.string)
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use width <- decode.optional_field("width", None, decode.optional(decode.int))
  use height <- decode.optional_field(
    "height",
    None,
    decode.optional(decode.int),
  )
  use duration <- decode.optional_field(
    "duration",
    None,
    decode.optional(decode.int),
  )
  use has_spoiler <- decode.optional_field(
    "has_spoiler",
    None,
    decode.optional(decode.bool),
  )
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
  use type_ <- decode.field("type", decode.string)
  use media <- decode.field("media", decode.string)
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use duration <- decode.optional_field(
    "duration",
    None,
    decode.optional(decode.int),
  )
  use performer <- decode.optional_field(
    "performer",
    None,
    decode.optional(decode.string),
  )
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
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
  use type_ <- decode.field("type", decode.string)
  use media <- decode.field("media", decode.string)
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use disable_content_type_detection <- decode.optional_field(
    "disable_content_type_detection",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use media <- decode.field("media", decode.string)
  decode.success(InputPaidMediaPhoto(type_: type_, media: media))
}

pub fn input_paid_media_video_decoder() -> decode.Decoder(InputPaidMediaVideo) {
  use type_ <- decode.field("type", decode.string)
  use media <- decode.field("media", decode.string)
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(decode.string),
  )
  use cover <- decode.optional_field(
    "cover",
    None,
    decode.optional(decode.string),
  )
  use start_timestamp <- decode.optional_field(
    "start_timestamp",
    None,
    decode.optional(decode.int),
  )
  use width <- decode.optional_field("width", None, decode.optional(decode.int))
  use height <- decode.optional_field(
    "height",
    None,
    decode.optional(decode.int),
  )
  use duration <- decode.optional_field(
    "duration",
    None,
    decode.optional(decode.int),
  )
  use supports_streaming <- decode.optional_field(
    "supports_streaming",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use width <- decode.field("width", decode.int)
  use height <- decode.field("height", decode.int)
  use is_animated <- decode.field("is_animated", decode.bool)
  use is_video <- decode.field("is_video", decode.bool)
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
    decode.optional(photo_size_decoder()),
  )
  use emoji <- decode.optional_field(
    "emoji",
    None,
    decode.optional(decode.string),
  )
  use set_name <- decode.optional_field(
    "set_name",
    None,
    decode.optional(decode.string),
  )
  use premium_animation <- decode.optional_field(
    "premium_animation",
    None,
    decode.optional(file_decoder()),
  )
  use mask_position <- decode.optional_field(
    "mask_position",
    None,
    decode.optional(mask_position_decoder()),
  )
  use custom_emoji_id <- decode.optional_field(
    "custom_emoji_id",
    None,
    decode.optional(decode.string),
  )
  use needs_repainting <- decode.optional_field(
    "needs_repainting",
    None,
    decode.optional(decode.bool),
  )
  use file_size <- decode.optional_field(
    "file_size",
    None,
    decode.optional(decode.int),
  )
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
  use thumbnail <- decode.optional_field(
    "thumbnail",
    None,
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
  use mask_position <- decode.optional_field(
    "mask_position",
    None,
    decode.optional(mask_position_decoder()),
  )
  use keywords <- decode.optional_field(
    "keywords",
    None,
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
  use upgrade_star_count <- decode.optional_field(
    "upgrade_star_count",
    None,
    decode.optional(decode.int),
  )
  use total_count <- decode.optional_field(
    "total_count",
    None,
    decode.optional(decode.int),
  )
  use remaining_count <- decode.optional_field(
    "remaining_count",
    None,
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
  use chat_type <- decode.optional_field(
    "chat_type",
    None,
    decode.optional(decode.string),
  )
  use location <- decode.optional_field(
    "location",
    None,
    decode.optional(location_decoder()),
  )
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
  use web_app <- decode.optional_field(
    "web_app",
    None,
    decode.optional(web_app_info_decoder()),
  )
  use start_parameter <- decode.optional_field(
    "start_parameter",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use input_message_content <- decode.field(
    "input_message_content",
    input_message_content_decoder(),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use url <- decode.optional_field("url", None, decode.optional(decode.string))
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use thumbnail_url <- decode.optional_field(
    "thumbnail_url",
    None,
    decode.optional(decode.string),
  )
  use thumbnail_width <- decode.optional_field(
    "thumbnail_width",
    None,
    decode.optional(decode.int),
  )
  use thumbnail_height <- decode.optional_field(
    "thumbnail_height",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use photo_url <- decode.field("photo_url", decode.string)
  use thumbnail_url <- decode.field("thumbnail_url", decode.string)
  use photo_width <- decode.optional_field(
    "photo_width",
    None,
    decode.optional(decode.int),
  )
  use photo_height <- decode.optional_field(
    "photo_height",
    None,
    decode.optional(decode.int),
  )
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use gif_url <- decode.field("gif_url", decode.string)
  use gif_width <- decode.optional_field(
    "gif_width",
    None,
    decode.optional(decode.int),
  )
  use gif_height <- decode.optional_field(
    "gif_height",
    None,
    decode.optional(decode.int),
  )
  use gif_duration <- decode.optional_field(
    "gif_duration",
    None,
    decode.optional(decode.int),
  )
  use thumbnail_url <- decode.field("thumbnail_url", decode.string)
  use thumbnail_mime_type <- decode.optional_field(
    "thumbnail_mime_type",
    None,
    decode.optional(decode.string),
  )
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use mpeg4_url <- decode.field("mpeg4_url", decode.string)
  use mpeg4_width <- decode.optional_field(
    "mpeg4_width",
    None,
    decode.optional(decode.int),
  )
  use mpeg4_height <- decode.optional_field(
    "mpeg4_height",
    None,
    decode.optional(decode.int),
  )
  use mpeg4_duration <- decode.optional_field(
    "mpeg4_duration",
    None,
    decode.optional(decode.int),
  )
  use thumbnail_url <- decode.field("thumbnail_url", decode.string)
  use thumbnail_mime_type <- decode.optional_field(
    "thumbnail_mime_type",
    None,
    decode.optional(decode.string),
  )
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use video_url <- decode.field("video_url", decode.string)
  use mime_type <- decode.field("mime_type", decode.string)
  use thumbnail_url <- decode.field("thumbnail_url", decode.string)
  use title <- decode.field("title", decode.string)
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use video_width <- decode.optional_field(
    "video_width",
    None,
    decode.optional(decode.int),
  )
  use video_height <- decode.optional_field(
    "video_height",
    None,
    decode.optional(decode.int),
  )
  use video_duration <- decode.optional_field(
    "video_duration",
    None,
    decode.optional(decode.int),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use audio_url <- decode.field("audio_url", decode.string)
  use title <- decode.field("title", decode.string)
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use performer <- decode.optional_field(
    "performer",
    None,
    decode.optional(decode.string),
  )
  use audio_duration <- decode.optional_field(
    "audio_duration",
    None,
    decode.optional(decode.int),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use voice_url <- decode.field("voice_url", decode.string)
  use title <- decode.field("title", decode.string)
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use voice_duration <- decode.optional_field(
    "voice_duration",
    None,
    decode.optional(decode.int),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use document_url <- decode.field("document_url", decode.string)
  use mime_type <- decode.field("mime_type", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
    decode.optional(input_message_content_decoder()),
  )
  use thumbnail_url <- decode.optional_field(
    "thumbnail_url",
    None,
    decode.optional(decode.string),
  )
  use thumbnail_width <- decode.optional_field(
    "thumbnail_width",
    None,
    decode.optional(decode.int),
  )
  use thumbnail_height <- decode.optional_field(
    "thumbnail_height",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use latitude <- decode.field("latitude", decode.float)
  use longitude <- decode.field("longitude", decode.float)
  use title <- decode.field("title", decode.string)
  use horizontal_accuracy <- decode.optional_field(
    "horizontal_accuracy",
    None,
    decode.optional(decode.float),
  )
  use live_period <- decode.optional_field(
    "live_period",
    None,
    decode.optional(decode.int),
  )
  use heading <- decode.optional_field(
    "heading",
    None,
    decode.optional(decode.int),
  )
  use proximity_alert_radius <- decode.optional_field(
    "proximity_alert_radius",
    None,
    decode.optional(decode.int),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
    decode.optional(input_message_content_decoder()),
  )
  use thumbnail_url <- decode.optional_field(
    "thumbnail_url",
    None,
    decode.optional(decode.string),
  )
  use thumbnail_width <- decode.optional_field(
    "thumbnail_width",
    None,
    decode.optional(decode.int),
  )
  use thumbnail_height <- decode.optional_field(
    "thumbnail_height",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use latitude <- decode.field("latitude", decode.float)
  use longitude <- decode.field("longitude", decode.float)
  use title <- decode.field("title", decode.string)
  use address <- decode.field("address", decode.string)
  use foursquare_id <- decode.optional_field(
    "foursquare_id",
    None,
    decode.optional(decode.string),
  )
  use foursquare_type <- decode.optional_field(
    "foursquare_type",
    None,
    decode.optional(decode.string),
  )
  use google_place_id <- decode.optional_field(
    "google_place_id",
    None,
    decode.optional(decode.string),
  )
  use google_place_type <- decode.optional_field(
    "google_place_type",
    None,
    decode.optional(decode.string),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
    decode.optional(input_message_content_decoder()),
  )
  use thumbnail_url <- decode.optional_field(
    "thumbnail_url",
    None,
    decode.optional(decode.string),
  )
  use thumbnail_width <- decode.optional_field(
    "thumbnail_width",
    None,
    decode.optional(decode.int),
  )
  use thumbnail_height <- decode.optional_field(
    "thumbnail_height",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use phone_number <- decode.field("phone_number", decode.string)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.optional_field(
    "last_name",
    None,
    decode.optional(decode.string),
  )
  use vcard <- decode.optional_field(
    "vcard",
    None,
    decode.optional(decode.string),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
    decode.optional(input_message_content_decoder()),
  )
  use thumbnail_url <- decode.optional_field(
    "thumbnail_url",
    None,
    decode.optional(decode.string),
  )
  use thumbnail_width <- decode.optional_field(
    "thumbnail_width",
    None,
    decode.optional(decode.int),
  )
  use thumbnail_height <- decode.optional_field(
    "thumbnail_height",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use game_short_name <- decode.field("game_short_name", decode.string)
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use photo_file_id <- decode.field("photo_file_id", decode.string)
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use gif_file_id <- decode.field("gif_file_id", decode.string)
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use mpeg4_file_id <- decode.field("mpeg4_file_id", decode.string)
  use title <- decode.optional_field(
    "title",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use sticker_file_id <- decode.field("sticker_file_id", decode.string)
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use document_file_id <- decode.field("document_file_id", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use video_file_id <- decode.field("video_file_id", decode.string)
  use title <- decode.field("title", decode.string)
  use description <- decode.optional_field(
    "description",
    None,
    decode.optional(decode.string),
  )
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use show_caption_above_media <- decode.optional_field(
    "show_caption_above_media",
    None,
    decode.optional(decode.bool),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use voice_file_id <- decode.field("voice_file_id", decode.string)
  use title <- decode.field("title", decode.string)
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use audio_file_id <- decode.field("audio_file_id", decode.string)
  use caption <- decode.optional_field(
    "caption",
    None,
    decode.optional(decode.string),
  )
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use caption_entities <- decode.optional_field(
    "caption_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use reply_markup <- decode.optional_field(
    "reply_markup",
    None,
    decode.optional(inline_keyboard_markup_decoder()),
  )
  use input_message_content <- decode.optional_field(
    "input_message_content",
    None,
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
  use parse_mode <- decode.optional_field(
    "parse_mode",
    None,
    decode.optional(decode.string),
  )
  use entities <- decode.optional_field(
    "entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use link_preview_options <- decode.optional_field(
    "link_preview_options",
    None,
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
  use horizontal_accuracy <- decode.optional_field(
    "horizontal_accuracy",
    None,
    decode.optional(decode.float),
  )
  use live_period <- decode.optional_field(
    "live_period",
    None,
    decode.optional(decode.int),
  )
  use heading <- decode.optional_field(
    "heading",
    None,
    decode.optional(decode.int),
  )
  use proximity_alert_radius <- decode.optional_field(
    "proximity_alert_radius",
    None,
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
  use foursquare_id <- decode.optional_field(
    "foursquare_id",
    None,
    decode.optional(decode.string),
  )
  use foursquare_type <- decode.optional_field(
    "foursquare_type",
    None,
    decode.optional(decode.string),
  )
  use google_place_id <- decode.optional_field(
    "google_place_id",
    None,
    decode.optional(decode.string),
  )
  use google_place_type <- decode.optional_field(
    "google_place_type",
    None,
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
  use last_name <- decode.optional_field(
    "last_name",
    None,
    decode.optional(decode.string),
  )
  use vcard <- decode.optional_field(
    "vcard",
    None,
    decode.optional(decode.string),
  )
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
  use provider_token <- decode.optional_field(
    "provider_token",
    None,
    decode.optional(decode.string),
  )
  use currency <- decode.field("currency", decode.string)
  use prices <- decode.field("prices", decode.list(labeled_price_decoder()))
  use max_tip_amount <- decode.optional_field(
    "max_tip_amount",
    None,
    decode.optional(decode.int),
  )
  use suggested_tip_amounts <- decode.optional_field(
    "suggested_tip_amounts",
    None,
    decode.optional(decode.list(decode.int)),
  )
  use provider_data <- decode.optional_field(
    "provider_data",
    None,
    decode.optional(decode.string),
  )
  use photo_url <- decode.optional_field(
    "photo_url",
    None,
    decode.optional(decode.string),
  )
  use photo_size <- decode.optional_field(
    "photo_size",
    None,
    decode.optional(decode.int),
  )
  use photo_width <- decode.optional_field(
    "photo_width",
    None,
    decode.optional(decode.int),
  )
  use photo_height <- decode.optional_field(
    "photo_height",
    None,
    decode.optional(decode.int),
  )
  use need_name <- decode.optional_field(
    "need_name",
    None,
    decode.optional(decode.bool),
  )
  use need_phone_number <- decode.optional_field(
    "need_phone_number",
    None,
    decode.optional(decode.bool),
  )
  use need_email <- decode.optional_field(
    "need_email",
    None,
    decode.optional(decode.bool),
  )
  use need_shipping_address <- decode.optional_field(
    "need_shipping_address",
    None,
    decode.optional(decode.bool),
  )
  use send_phone_number_to_provider <- decode.optional_field(
    "send_phone_number_to_provider",
    None,
    decode.optional(decode.bool),
  )
  use send_email_to_provider <- decode.optional_field(
    "send_email_to_provider",
    None,
    decode.optional(decode.bool),
  )
  use is_flexible <- decode.optional_field(
    "is_flexible",
    None,
    decode.optional(decode.bool),
  )
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
  use location <- decode.optional_field(
    "location",
    None,
    decode.optional(location_decoder()),
  )
  use inline_message_id <- decode.optional_field(
    "inline_message_id",
    None,
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
  use inline_message_id <- decode.optional_field(
    "inline_message_id",
    None,
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
  use name <- decode.optional_field(
    "name",
    None,
    decode.optional(decode.string),
  )
  use phone_number <- decode.optional_field(
    "phone_number",
    None,
    decode.optional(decode.string),
  )
  use email <- decode.optional_field(
    "email",
    None,
    decode.optional(decode.string),
  )
  use shipping_address <- decode.optional_field(
    "shipping_address",
    None,
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
  use subscription_expiration_date <- decode.optional_field(
    "subscription_expiration_date",
    None,
    decode.optional(decode.int),
  )
  use is_recurring <- decode.optional_field(
    "is_recurring",
    None,
    decode.optional(decode.bool),
  )
  use is_first_recurring <- decode.optional_field(
    "is_first_recurring",
    None,
    decode.optional(decode.bool),
  )
  use shipping_option_id <- decode.optional_field(
    "shipping_option_id",
    None,
    decode.optional(decode.string),
  )
  use order_info <- decode.optional_field(
    "order_info",
    None,
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
  use provider_payment_charge_id <- decode.optional_field(
    "provider_payment_charge_id",
    None,
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
  use shipping_option_id <- decode.optional_field(
    "shipping_option_id",
    None,
    decode.optional(decode.string),
  )
  use order_info <- decode.optional_field(
    "order_info",
    None,
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
  use type_ <- decode.field("type", decode.string)
  decode.success(RevenueWithdrawalStatePending(type_: type_))
}

pub fn revenue_withdrawal_state_succeeded_decoder() -> decode.Decoder(
  RevenueWithdrawalStateSucceeded,
) {
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
  decode.success(RevenueWithdrawalStateFailed(type_: type_))
}

pub fn affiliate_info_decoder() -> decode.Decoder(AffiliateInfo) {
  use affiliate_user <- decode.optional_field(
    "affiliate_user",
    None,
    decode.optional(user_decoder()),
  )
  use affiliate_chat <- decode.optional_field(
    "affiliate_chat",
    None,
    decode.optional(chat_decoder()),
  )
  use commission_per_mille <- decode.field("commission_per_mille", decode.int)
  use amount <- decode.field("amount", decode.int)
  use nanostar_amount <- decode.optional_field(
    "nanostar_amount",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use user <- decode.field("user", user_decoder())
  use affiliate <- decode.optional_field(
    "affiliate",
    None,
    decode.optional(affiliate_info_decoder()),
  )
  use invoice_payload <- decode.optional_field(
    "invoice_payload",
    None,
    decode.optional(decode.string),
  )
  use subscription_period <- decode.optional_field(
    "subscription_period",
    None,
    decode.optional(decode.int),
  )
  use paid_media <- decode.optional_field(
    "paid_media",
    None,
    decode.optional(decode.list(paid_media_decoder())),
  )
  use paid_media_payload <- decode.optional_field(
    "paid_media_payload",
    None,
    decode.optional(decode.string),
  )
  use gift <- decode.optional_field(
    "gift",
    None,
    decode.optional(gift_decoder()),
  )
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
  use type_ <- decode.field("type", decode.string)
  use chat <- decode.field("chat", chat_decoder())
  use gift <- decode.optional_field(
    "gift",
    None,
    decode.optional(gift_decoder()),
  )
  decode.success(TransactionPartnerChat(type_: type_, chat: chat, gift: gift))
}

pub fn transaction_partner_affiliate_program_decoder() -> decode.Decoder(
  TransactionPartnerAffiliateProgram,
) {
  use type_ <- decode.field("type", decode.string)
  use sponsor_user <- decode.optional_field(
    "sponsor_user",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use withdrawal_state <- decode.optional_field(
    "withdrawal_state",
    None,
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
  use type_ <- decode.field("type", decode.string)
  decode.success(TransactionPartnerTelegramAds(type_: type_))
}

pub fn transaction_partner_telegram_api_decoder() -> decode.Decoder(
  TransactionPartnerTelegramApi,
) {
  use type_ <- decode.field("type", decode.string)
  use request_count <- decode.field("request_count", decode.int)
  decode.success(TransactionPartnerTelegramApi(
    type_: type_,
    request_count: request_count,
  ))
}

pub fn transaction_partner_other_decoder() -> decode.Decoder(
  TransactionPartnerOther,
) {
  use type_ <- decode.field("type", decode.string)
  decode.success(TransactionPartnerOther(type_: type_))
}

pub fn star_transaction_decoder() -> decode.Decoder(StarTransaction) {
  use id <- decode.field("id", decode.string)
  use amount <- decode.field("amount", decode.int)
  use nanostar_amount <- decode.optional_field(
    "nanostar_amount",
    None,
    decode.optional(decode.int),
  )
  use date <- decode.field("date", decode.int)
  use source <- decode.optional_field(
    "source",
    None,
    decode.optional(transaction_partner_decoder()),
  )
  use receiver <- decode.optional_field(
    "receiver",
    None,
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
  use type_ <- decode.field("type", decode.string)
  use data <- decode.optional_field(
    "data",
    None,
    decode.optional(decode.string),
  )
  use phone_number <- decode.optional_field(
    "phone_number",
    None,
    decode.optional(decode.string),
  )
  use email <- decode.optional_field(
    "email",
    None,
    decode.optional(decode.string),
  )
  use files <- decode.optional_field(
    "files",
    None,
    decode.optional(decode.list(passport_file_decoder())),
  )
  use front_side <- decode.optional_field(
    "front_side",
    None,
    decode.optional(passport_file_decoder()),
  )
  use reverse_side <- decode.optional_field(
    "reverse_side",
    None,
    decode.optional(passport_file_decoder()),
  )
  use selfie <- decode.optional_field(
    "selfie",
    None,
    decode.optional(passport_file_decoder()),
  )
  use translation <- decode.optional_field(
    "translation",
    None,
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
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
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
  use type_ <- decode.field("type", decode.string)
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
  use text <- decode.optional_field(
    "text",
    None,
    decode.optional(decode.string),
  )
  use text_entities <- decode.optional_field(
    "text_entities",
    None,
    decode.optional(decode.list(message_entity_decoder())),
  )
  use animation <- decode.optional_field(
    "animation",
    None,
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
  use force <- decode.optional_field(
    "force",
    None,
    decode.optional(decode.bool),
  )
  use disable_edit_message <- decode.optional_field(
    "disable_edit_message",
    None,
    decode.optional(decode.bool),
  )
  use chat_id <- decode.optional_field(
    "chat_id",
    None,
    decode.optional(decode.int),
  )
  use message_id <- decode.optional_field(
    "message_id",
    None,
    decode.optional(decode.int),
  )
  use inline_message_id <- decode.optional_field(
    "inline_message_id",
    None,
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

pub fn encode_update(update: Update) -> Json {
  json_object_filter_nulls([
    #("update_id", json.int(update.update_id)),
    #("message", json.nullable(update.message, encode_message)),
    #("edited_message", json.nullable(update.edited_message, encode_message)),
    #("channel_post", json.nullable(update.channel_post, encode_message)),
    #(
      "edited_channel_post",
      json.nullable(update.edited_channel_post, encode_message),
    ),
    #(
      "business_connection",
      json.nullable(update.business_connection, encode_business_connection),
    ),
    #(
      "business_message",
      json.nullable(update.business_message, encode_message),
    ),
    #(
      "edited_business_message",
      json.nullable(update.edited_business_message, encode_message),
    ),
    #(
      "deleted_business_messages",
      json.nullable(
        update.deleted_business_messages,
        encode_business_messages_deleted,
      ),
    ),
    #(
      "message_reaction",
      json.nullable(update.message_reaction, encode_message_reaction_updated),
    ),
    #(
      "message_reaction_count",
      json.nullable(
        update.message_reaction_count,
        encode_message_reaction_count_updated,
      ),
    ),
    #("inline_query", json.nullable(update.inline_query, encode_inline_query)),
    #(
      "chosen_inline_result",
      json.nullable(update.chosen_inline_result, encode_chosen_inline_result),
    ),
    #(
      "callback_query",
      json.nullable(update.callback_query, encode_callback_query),
    ),
    #(
      "shipping_query",
      json.nullable(update.shipping_query, encode_shipping_query),
    ),
    #(
      "pre_checkout_query",
      json.nullable(update.pre_checkout_query, encode_pre_checkout_query),
    ),
    #(
      "purchased_paid_media",
      json.nullable(update.purchased_paid_media, encode_paid_media_purchased),
    ),
    #("poll", json.nullable(update.poll, encode_poll)),
    #("poll_answer", json.nullable(update.poll_answer, encode_poll_answer)),
    #(
      "my_chat_member",
      json.nullable(update.my_chat_member, encode_chat_member_updated),
    ),
    #(
      "chat_member",
      json.nullable(update.chat_member, encode_chat_member_updated),
    ),
    #(
      "chat_join_request",
      json.nullable(update.chat_join_request, encode_chat_join_request),
    ),
    #("chat_boost", json.nullable(update.chat_boost, encode_chat_boost_updated)),
    #(
      "removed_chat_boost",
      json.nullable(update.removed_chat_boost, encode_chat_boost_removed),
    ),
  ])
}

pub fn encode_webhook_info(webhook_info: WebhookInfo) -> Json {
  json_object_filter_nulls([
    #("url", json.string(webhook_info.url)),
    #("has_custom_certificate", json.bool(webhook_info.has_custom_certificate)),
    #("pending_update_count", json.int(webhook_info.pending_update_count)),
    #("ip_address", json.nullable(webhook_info.ip_address, json.string)),
    #("last_error_date", json.nullable(webhook_info.last_error_date, json.int)),
    #(
      "last_error_message",
      json.nullable(webhook_info.last_error_message, json.string),
    ),
    #(
      "last_synchronization_error_date",
      json.nullable(webhook_info.last_synchronization_error_date, json.int),
    ),
    #("max_connections", json.nullable(webhook_info.max_connections, json.int)),
    #(
      "allowed_updates",
      json.nullable(webhook_info.allowed_updates, json.array(_, json.string)),
    ),
  ])
}

pub fn encode_user(user: User) -> Json {
  json_object_filter_nulls([
    #("id", json.int(user.id)),
    #("is_bot", json.bool(user.is_bot)),
    #("first_name", json.string(user.first_name)),
    #("last_name", json.nullable(user.last_name, json.string)),
    #("username", json.nullable(user.username, json.string)),
    #("language_code", json.nullable(user.language_code, json.string)),
    #("is_premium", json.nullable(user.is_premium, json.bool)),
    #(
      "added_to_attachment_menu",
      json.nullable(user.added_to_attachment_menu, json.bool),
    ),
    #("can_join_groups", json.nullable(user.can_join_groups, json.bool)),
    #(
      "can_read_all_group_messages",
      json.nullable(user.can_read_all_group_messages, json.bool),
    ),
    #(
      "supports_inline_queries",
      json.nullable(user.supports_inline_queries, json.bool),
    ),
    #(
      "can_connect_to_business",
      json.nullable(user.can_connect_to_business, json.bool),
    ),
    #("has_main_web_app", json.nullable(user.has_main_web_app, json.bool)),
  ])
}

pub fn encode_chat(chat: Chat) -> Json {
  json_object_filter_nulls([
    #("id", json.int(chat.id)),
    #("type", json.nullable(chat.type_, json.string)),
    #("title", json.nullable(chat.title, json.string)),
    #("username", json.nullable(chat.username, json.string)),
    #("first_name", json.nullable(chat.first_name, json.string)),
    #("last_name", json.nullable(chat.last_name, json.string)),
    #("is_forum", json.nullable(chat.is_forum, json.bool)),
  ])
}

pub fn encode_chat_full_info(chat_full_info: ChatFullInfo) -> Json {
  json_object_filter_nulls([
    #("id", json.int(chat_full_info.id)),
    #("type", json.string(chat_full_info.type_)),
    #("title", json.nullable(chat_full_info.title, json.string)),
    #("username", json.nullable(chat_full_info.username, json.string)),
    #("first_name", json.nullable(chat_full_info.first_name, json.string)),
    #("last_name", json.nullable(chat_full_info.last_name, json.string)),
    #("is_forum", json.nullable(chat_full_info.is_forum, json.bool)),
    #("accent_color_id", json.int(chat_full_info.accent_color_id)),
    #("max_reaction_count", json.int(chat_full_info.max_reaction_count)),
    #("photo", json.nullable(chat_full_info.photo, encode_chat_photo)),
    #(
      "active_usernames",
      json.nullable(chat_full_info.active_usernames, json.array(_, json.string)),
    ),
    #("birthdate", json.nullable(chat_full_info.birthdate, encode_birthdate)),
    #(
      "business_intro",
      json.nullable(chat_full_info.business_intro, encode_business_intro),
    ),
    #(
      "business_location",
      json.nullable(chat_full_info.business_location, encode_business_location),
    ),
    #(
      "business_opening_hours",
      json.nullable(
        chat_full_info.business_opening_hours,
        encode_business_opening_hours,
      ),
    ),
    #("personal_chat", json.nullable(chat_full_info.personal_chat, encode_chat)),
    #(
      "available_reactions",
      json.nullable(chat_full_info.available_reactions, json.array(
        _,
        encode_reaction_type,
      )),
    ),
    #(
      "background_custom_emoji_id",
      json.nullable(chat_full_info.background_custom_emoji_id, json.string),
    ),
    #(
      "profile_accent_color_id",
      json.nullable(chat_full_info.profile_accent_color_id, json.int),
    ),
    #(
      "profile_background_custom_emoji_id",
      json.nullable(
        chat_full_info.profile_background_custom_emoji_id,
        json.string,
      ),
    ),
    #(
      "emoji_status_custom_emoji_id",
      json.nullable(chat_full_info.emoji_status_custom_emoji_id, json.string),
    ),
    #(
      "emoji_status_expiration_date",
      json.nullable(chat_full_info.emoji_status_expiration_date, json.int),
    ),
    #("bio", json.nullable(chat_full_info.bio, json.string)),
    #(
      "has_private_forwards",
      json.nullable(chat_full_info.has_private_forwards, json.bool),
    ),
    #(
      "has_restricted_voice_and_video_messages",
      json.nullable(
        chat_full_info.has_restricted_voice_and_video_messages,
        json.bool,
      ),
    ),
    #(
      "join_to_send_messages",
      json.nullable(chat_full_info.join_to_send_messages, json.bool),
    ),
    #(
      "join_by_request",
      json.nullable(chat_full_info.join_by_request, json.bool),
    ),
    #("description", json.nullable(chat_full_info.description, json.string)),
    #("invite_link", json.nullable(chat_full_info.invite_link, json.string)),
    #(
      "pinned_message",
      json.nullable(chat_full_info.pinned_message, encode_message),
    ),
    #(
      "permissions",
      json.nullable(chat_full_info.permissions, encode_chat_permissions),
    ),
    #("can_send_gift", json.nullable(chat_full_info.can_send_gift, json.bool)),
    #(
      "can_send_paid_media",
      json.nullable(chat_full_info.can_send_paid_media, json.bool),
    ),
    #(
      "slow_mode_delay",
      json.nullable(chat_full_info.slow_mode_delay, json.int),
    ),
    #(
      "unrestrict_boost_count",
      json.nullable(chat_full_info.unrestrict_boost_count, json.int),
    ),
    #(
      "message_auto_delete_time",
      json.nullable(chat_full_info.message_auto_delete_time, json.int),
    ),
    #(
      "has_aggressive_anti_spam_enabled",
      json.nullable(chat_full_info.has_aggressive_anti_spam_enabled, json.bool),
    ),
    #(
      "has_hidden_members",
      json.nullable(chat_full_info.has_hidden_members, json.bool),
    ),
    #(
      "has_protected_content",
      json.nullable(chat_full_info.has_protected_content, json.bool),
    ),
    #(
      "has_visible_history",
      json.nullable(chat_full_info.has_visible_history, json.bool),
    ),
    #(
      "sticker_set_name",
      json.nullable(chat_full_info.sticker_set_name, json.string),
    ),
    #(
      "can_set_sticker_set",
      json.nullable(chat_full_info.can_set_sticker_set, json.bool),
    ),
    #(
      "custom_emoji_sticker_set_name",
      json.nullable(chat_full_info.custom_emoji_sticker_set_name, json.string),
    ),
    #("linked_chat_id", json.nullable(chat_full_info.linked_chat_id, json.int)),
    #("location", json.nullable(chat_full_info.location, encode_chat_location)),
  ])
}

pub fn encode_message(message: Message) -> Json {
  json_object_filter_nulls([
    #("message_id", json.int(message.message_id)),
    #("message_thread_id", json.nullable(message.message_thread_id, json.int)),
    #("from", json.nullable(message.from, encode_user)),
    #("sender_chat", json.nullable(message.sender_chat, encode_chat)),
    #("sender_boost_count", json.nullable(message.sender_boost_count, json.int)),
    #(
      "sender_business_bot",
      json.nullable(message.sender_business_bot, encode_user),
    ),
    #("date", json.int(message.date)),
    #(
      "business_connection_id",
      json.nullable(message.business_connection_id, json.string),
    ),
    #("chat", encode_chat(message.chat)),
    #(
      "forward_origin",
      json.nullable(message.forward_origin, encode_message_origin),
    ),
    #("is_topic_message", json.nullable(message.is_topic_message, json.bool)),
    #(
      "is_automatic_forward",
      json.nullable(message.is_automatic_forward, json.bool),
    ),
    #(
      "reply_to_message",
      json.nullable(message.reply_to_message, encode_message),
    ),
    #(
      "external_reply",
      json.nullable(message.external_reply, encode_external_reply_info),
    ),
    #("quote", json.nullable(message.quote, encode_text_quote)),
    #("reply_to_story", json.nullable(message.reply_to_story, encode_story)),
    #("via_bot", json.nullable(message.via_bot, encode_user)),
    #("edit_date", json.nullable(message.edit_date, json.int)),
    #(
      "has_protected_content",
      json.nullable(message.has_protected_content, json.bool),
    ),
    #("is_from_offline", json.nullable(message.is_from_offline, json.bool)),
    #("media_group_id", json.nullable(message.media_group_id, json.string)),
    #("author_signature", json.nullable(message.author_signature, json.string)),
    #("text", json.nullable(message.text, json.string)),
    #(
      "entities",
      json.nullable(message.entities, json.array(_, encode_message_entity)),
    ),
    #(
      "link_preview_options",
      json.nullable(message.link_preview_options, encode_link_preview_options),
    ),
    #("effect_id", json.nullable(message.effect_id, json.string)),
    #("animation", json.nullable(message.animation, encode_animation)),
    #("audio", json.nullable(message.audio, encode_audio)),
    #("document", json.nullable(message.document, encode_document)),
    #("paid_media", json.nullable(message.paid_media, encode_paid_media_info)),
    #("photo", json.nullable(message.photo, json.array(_, encode_photo_size))),
    #("sticker", json.nullable(message.sticker, encode_sticker)),
    #("story", json.nullable(message.story, encode_story)),
    #("video", json.nullable(message.video, encode_video)),
    #("video_note", json.nullable(message.video_note, encode_video_note)),
    #("voice", json.nullable(message.voice, encode_voice)),
    #("caption", json.nullable(message.caption, json.string)),
    #(
      "caption_entities",
      json.nullable(message.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(message.show_caption_above_media, json.bool),
    ),
    #("has_media_spoiler", json.nullable(message.has_media_spoiler, json.bool)),
    #("contact", json.nullable(message.contact, encode_contact)),
    #("dice", json.nullable(message.dice, encode_dice)),
    #("game", json.nullable(message.game, encode_game)),
    #("poll", json.nullable(message.poll, encode_poll)),
    #("venue", json.nullable(message.venue, encode_venue)),
    #("location", json.nullable(message.location, encode_location)),
    #(
      "new_chat_members",
      json.nullable(message.new_chat_members, json.array(_, encode_user)),
    ),
    #("left_chat_member", json.nullable(message.left_chat_member, encode_user)),
    #("new_chat_title", json.nullable(message.new_chat_title, json.string)),
    #(
      "new_chat_photo",
      json.nullable(message.new_chat_photo, json.array(_, encode_photo_size)),
    ),
    #("delete_chat_photo", json.nullable(message.delete_chat_photo, json.bool)),
    #(
      "group_chat_created",
      json.nullable(message.group_chat_created, json.bool),
    ),
    #(
      "supergroup_chat_created",
      json.nullable(message.supergroup_chat_created, json.bool),
    ),
    #(
      "channel_chat_created",
      json.nullable(message.channel_chat_created, json.bool),
    ),
    #(
      "message_auto_delete_timer_changed",
      json.nullable(
        message.message_auto_delete_timer_changed,
        encode_message_auto_delete_timer_changed,
      ),
    ),
    #("migrate_to_chat_id", json.nullable(message.migrate_to_chat_id, json.int)),
    #(
      "migrate_from_chat_id",
      json.nullable(message.migrate_from_chat_id, json.int),
    ),
    #(
      "pinned_message",
      json.nullable(message.pinned_message, encode_maybe_inaccessible_message),
    ),
    #("invoice", json.nullable(message.invoice, encode_invoice)),
    #(
      "successful_payment",
      json.nullable(message.successful_payment, encode_successful_payment),
    ),
    #(
      "refunded_payment",
      json.nullable(message.refunded_payment, encode_refunded_payment),
    ),
    #("users_shared", json.nullable(message.users_shared, encode_users_shared)),
    #("chat_shared", json.nullable(message.chat_shared, encode_chat_shared)),
    #(
      "connected_website",
      json.nullable(message.connected_website, json.string),
    ),
    #(
      "write_access_allowed",
      json.nullable(message.write_access_allowed, encode_write_access_allowed),
    ),
    #(
      "passport_data",
      json.nullable(message.passport_data, encode_passport_data),
    ),
    #(
      "proximity_alert_triggered",
      json.nullable(
        message.proximity_alert_triggered,
        encode_proximity_alert_triggered,
      ),
    ),
    #(
      "boost_added",
      json.nullable(message.boost_added, encode_chat_boost_added),
    ),
    #(
      "chat_background_set",
      json.nullable(message.chat_background_set, encode_chat_background),
    ),
    #(
      "forum_topic_created",
      json.nullable(message.forum_topic_created, encode_forum_topic_created),
    ),
    #(
      "forum_topic_edited",
      json.nullable(message.forum_topic_edited, encode_forum_topic_edited),
    ),
    #(
      "forum_topic_closed",
      json.nullable(message.forum_topic_closed, encode_forum_topic_closed),
    ),
    #(
      "forum_topic_reopened",
      json.nullable(message.forum_topic_reopened, encode_forum_topic_reopened),
    ),
    #(
      "general_forum_topic_hidden",
      json.nullable(
        message.general_forum_topic_hidden,
        encode_general_forum_topic_hidden,
      ),
    ),
    #(
      "general_forum_topic_unhidden",
      json.nullable(
        message.general_forum_topic_unhidden,
        encode_general_forum_topic_unhidden,
      ),
    ),
    #(
      "giveaway_created",
      json.nullable(message.giveaway_created, encode_giveaway_created),
    ),
    #("giveaway", json.nullable(message.giveaway, encode_giveaway)),
    #(
      "giveaway_winners",
      json.nullable(message.giveaway_winners, encode_giveaway_winners),
    ),
    #(
      "giveaway_completed",
      json.nullable(message.giveaway_completed, encode_giveaway_completed),
    ),
    #(
      "video_chat_scheduled",
      json.nullable(message.video_chat_scheduled, encode_video_chat_scheduled),
    ),
    #(
      "video_chat_started",
      json.nullable(message.video_chat_started, encode_video_chat_started),
    ),
    #(
      "video_chat_ended",
      json.nullable(message.video_chat_ended, encode_video_chat_ended),
    ),
    #(
      "video_chat_participants_invited",
      json.nullable(
        message.video_chat_participants_invited,
        encode_video_chat_participants_invited,
      ),
    ),
    #("web_app_data", json.nullable(message.web_app_data, encode_web_app_data)),
    #(
      "reply_markup",
      json.nullable(message.reply_markup, encode_inline_keyboard_markup),
    ),
  ])
}

pub fn encode_message_id(message_id: MessageId) -> Json {
  json_object_filter_nulls([#("message_id", json.int(message_id.message_id))])
}

pub fn encode_inaccessible_message(
  inaccessible_message: InaccessibleMessage,
) -> Json {
  json_object_filter_nulls([
    #("chat", encode_chat(inaccessible_message.chat)),
    #("message_id", json.int(inaccessible_message.message_id)),
    #("date", json.int(inaccessible_message.date)),
  ])
}

pub fn encode_message_entity(message_entity: MessageEntity) -> Json {
  json_object_filter_nulls([
    #("type", json.string(message_entity.type_)),
    #("offset", json.int(message_entity.offset)),
    #("length", json.int(message_entity.length)),
    #("url", json.nullable(message_entity.url, json.string)),
    #("user", json.nullable(message_entity.user, encode_user)),
    #("language", json.nullable(message_entity.language, json.string)),
    #(
      "custom_emoji_id",
      json.nullable(message_entity.custom_emoji_id, json.string),
    ),
  ])
}

pub fn encode_text_quote(text_quote: TextQuote) -> Json {
  json_object_filter_nulls([
    #("text", json.string(text_quote.text)),
    #(
      "entities",
      json.nullable(text_quote.entities, json.array(_, encode_message_entity)),
    ),
    #("position", json.int(text_quote.position)),
    #("is_manual", json.nullable(text_quote.is_manual, json.bool)),
  ])
}

pub fn encode_external_reply_info(
  external_reply_info: ExternalReplyInfo,
) -> Json {
  json_object_filter_nulls([
    #("origin", encode_message_origin(external_reply_info.origin)),
    #("chat", json.nullable(external_reply_info.chat, encode_chat)),
    #("message_id", json.nullable(external_reply_info.message_id, json.int)),
    #(
      "link_preview_options",
      json.nullable(
        external_reply_info.link_preview_options,
        encode_link_preview_options,
      ),
    ),
    #(
      "animation",
      json.nullable(external_reply_info.animation, encode_animation),
    ),
    #("audio", json.nullable(external_reply_info.audio, encode_audio)),
    #("document", json.nullable(external_reply_info.document, encode_document)),
    #(
      "paid_media",
      json.nullable(external_reply_info.paid_media, encode_paid_media_info),
    ),
    #(
      "photo",
      json.nullable(external_reply_info.photo, json.array(_, encode_photo_size)),
    ),
    #("sticker", json.nullable(external_reply_info.sticker, encode_sticker)),
    #("story", json.nullable(external_reply_info.story, encode_story)),
    #("video", json.nullable(external_reply_info.video, encode_video)),
    #(
      "video_note",
      json.nullable(external_reply_info.video_note, encode_video_note),
    ),
    #("voice", json.nullable(external_reply_info.voice, encode_voice)),
    #(
      "has_media_spoiler",
      json.nullable(external_reply_info.has_media_spoiler, json.bool),
    ),
    #("contact", json.nullable(external_reply_info.contact, encode_contact)),
    #("dice", json.nullable(external_reply_info.dice, encode_dice)),
    #("game", json.nullable(external_reply_info.game, encode_game)),
    #("giveaway", json.nullable(external_reply_info.giveaway, encode_giveaway)),
    #(
      "giveaway_winners",
      json.nullable(
        external_reply_info.giveaway_winners,
        encode_giveaway_winners,
      ),
    ),
    #("invoice", json.nullable(external_reply_info.invoice, encode_invoice)),
    #("location", json.nullable(external_reply_info.location, encode_location)),
    #("poll", json.nullable(external_reply_info.poll, encode_poll)),
    #("venue", json.nullable(external_reply_info.venue, encode_venue)),
  ])
}

pub fn encode_reply_parameters(reply_parameters: ReplyParameters) -> Json {
  json_object_filter_nulls([
    #("message_id", json.int(reply_parameters.message_id)),
    #("chat_id", json.nullable(reply_parameters.chat_id, encode_int_or_string)),
    #(
      "allow_sending_without_reply",
      json.nullable(reply_parameters.allow_sending_without_reply, json.bool),
    ),
    #("quote", json.nullable(reply_parameters.quote, json.string)),
    #(
      "quote_parse_mode",
      json.nullable(reply_parameters.quote_parse_mode, json.string),
    ),
    #(
      "quote_entities",
      json.nullable(reply_parameters.quote_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "quote_position",
      json.nullable(reply_parameters.quote_position, json.int),
    ),
  ])
}

pub fn encode_message_origin_user(
  message_origin_user: MessageOriginUser,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(message_origin_user.type_)),
    #("date", json.int(message_origin_user.date)),
    #("sender_user", encode_user(message_origin_user.sender_user)),
  ])
}

pub fn encode_message_origin_hidden_user(
  message_origin_hidden_user: MessageOriginHiddenUser,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(message_origin_hidden_user.type_)),
    #("date", json.int(message_origin_hidden_user.date)),
    #(
      "sender_user_name",
      json.string(message_origin_hidden_user.sender_user_name),
    ),
  ])
}

pub fn encode_message_origin_chat(
  message_origin_chat: MessageOriginChat,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(message_origin_chat.type_)),
    #("date", json.int(message_origin_chat.date)),
    #("sender_chat", encode_chat(message_origin_chat.sender_chat)),
    #(
      "author_signature",
      json.nullable(message_origin_chat.author_signature, json.string),
    ),
  ])
}

pub fn encode_message_origin_channel(
  message_origin_channel: MessageOriginChannel,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(message_origin_channel.type_)),
    #("date", json.int(message_origin_channel.date)),
    #("chat", encode_chat(message_origin_channel.chat)),
    #("message_id", json.int(message_origin_channel.message_id)),
    #(
      "author_signature",
      json.nullable(message_origin_channel.author_signature, json.string),
    ),
  ])
}

pub fn encode_photo_size(photo_size: PhotoSize) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(photo_size.file_id)),
    #("file_unique_id", json.string(photo_size.file_unique_id)),
    #("width", json.int(photo_size.width)),
    #("height", json.int(photo_size.height)),
    #("file_size", json.nullable(photo_size.file_size, json.int)),
  ])
}

pub fn encode_animation(animation: Animation) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(animation.file_id)),
    #("file_unique_id", json.string(animation.file_unique_id)),
    #("width", json.int(animation.width)),
    #("height", json.int(animation.height)),
    #("duration", json.int(animation.duration)),
    #("thumbnail", json.nullable(animation.thumbnail, encode_photo_size)),
    #("file_name", json.nullable(animation.file_name, json.string)),
    #("mime_type", json.nullable(animation.mime_type, json.string)),
    #("file_size", json.nullable(animation.file_size, json.int)),
  ])
}

pub fn encode_audio(audio: Audio) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(audio.file_id)),
    #("file_unique_id", json.string(audio.file_unique_id)),
    #("duration", json.int(audio.duration)),
    #("performer", json.nullable(audio.performer, json.string)),
    #("title", json.nullable(audio.title, json.string)),
    #("file_name", json.nullable(audio.file_name, json.string)),
    #("mime_type", json.nullable(audio.mime_type, json.string)),
    #("file_size", json.nullable(audio.file_size, json.int)),
    #("thumbnail", json.nullable(audio.thumbnail, encode_photo_size)),
  ])
}

pub fn encode_document(document: Document) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(document.file_id)),
    #("file_unique_id", json.string(document.file_unique_id)),
    #("thumbnail", json.nullable(document.thumbnail, encode_photo_size)),
    #("file_name", json.nullable(document.file_name, json.string)),
    #("mime_type", json.nullable(document.mime_type, json.string)),
    #("file_size", json.nullable(document.file_size, json.int)),
  ])
}

pub fn encode_story(story: Story) -> Json {
  json_object_filter_nulls([
    #("chat", encode_chat(story.chat)),
    #("id", json.int(story.id)),
  ])
}

pub fn encode_video(video: Video) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(video.file_id)),
    #("file_unique_id", json.string(video.file_unique_id)),
    #("width", json.int(video.width)),
    #("height", json.int(video.height)),
    #("duration", json.int(video.duration)),
    #("thumbnail", json.nullable(video.thumbnail, encode_photo_size)),
    #("cover", json.nullable(video.cover, json.array(_, encode_photo_size))),
    #("start_timestamp", json.nullable(video.start_timestamp, json.int)),
    #("file_name", json.nullable(video.file_name, json.string)),
    #("mime_type", json.nullable(video.mime_type, json.string)),
    #("file_size", json.nullable(video.file_size, json.int)),
  ])
}

pub fn encode_video_note(video_note: VideoNote) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(video_note.file_id)),
    #("file_unique_id", json.string(video_note.file_unique_id)),
    #("length", json.int(video_note.length)),
    #("duration", json.int(video_note.duration)),
    #("thumbnail", json.nullable(video_note.thumbnail, encode_photo_size)),
    #("file_size", json.nullable(video_note.file_size, json.int)),
  ])
}

pub fn encode_voice(voice: Voice) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(voice.file_id)),
    #("file_unique_id", json.string(voice.file_unique_id)),
    #("duration", json.int(voice.duration)),
    #("mime_type", json.nullable(voice.mime_type, json.string)),
    #("file_size", json.nullable(voice.file_size, json.int)),
  ])
}

pub fn encode_paid_media_info(paid_media_info: PaidMediaInfo) -> Json {
  json_object_filter_nulls([
    #("star_count", json.int(paid_media_info.star_count)),
    #(
      "paid_media",
      json.array(_, encode_paid_media)(paid_media_info.paid_media),
    ),
  ])
}

pub fn encode_paid_media_preview(paid_media_preview: PaidMediaPreview) -> Json {
  json_object_filter_nulls([
    #("type", json.string(paid_media_preview.type_)),
    #("width", json.nullable(paid_media_preview.width, json.int)),
    #("height", json.nullable(paid_media_preview.height, json.int)),
    #("duration", json.nullable(paid_media_preview.duration, json.int)),
  ])
}

pub fn encode_paid_media_photo(paid_media_photo: PaidMediaPhoto) -> Json {
  json_object_filter_nulls([
    #("type", json.string(paid_media_photo.type_)),
    #("photo", json.array(_, encode_photo_size)(paid_media_photo.photo)),
  ])
}

pub fn encode_paid_media_video(paid_media_video: PaidMediaVideo) -> Json {
  json_object_filter_nulls([
    #("type", json.string(paid_media_video.type_)),
    #("video", encode_video(paid_media_video.video)),
  ])
}

pub fn encode_contact(contact: Contact) -> Json {
  json_object_filter_nulls([
    #("phone_number", json.string(contact.phone_number)),
    #("first_name", json.string(contact.first_name)),
    #("last_name", json.nullable(contact.last_name, json.string)),
    #("user_id", json.nullable(contact.user_id, json.int)),
    #("vcard", json.nullable(contact.vcard, json.string)),
  ])
}

pub fn encode_dice(dice: Dice) -> Json {
  json_object_filter_nulls([
    #("emoji", json.string(dice.emoji)),
    #("value", json.int(dice.value)),
  ])
}

pub fn encode_poll_option(poll_option: PollOption) -> Json {
  json_object_filter_nulls([
    #("text", json.string(poll_option.text)),
    #(
      "text_entities",
      json.nullable(poll_option.text_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("voter_count", json.int(poll_option.voter_count)),
  ])
}

pub fn encode_input_poll_option(input_poll_option: InputPollOption) -> Json {
  json_object_filter_nulls([
    #("text", json.string(input_poll_option.text)),
    #(
      "text_parse_mode",
      json.nullable(input_poll_option.text_parse_mode, json.string),
    ),
    #(
      "text_entities",
      json.nullable(input_poll_option.text_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
  ])
}

pub fn encode_poll_answer(poll_answer: PollAnswer) -> Json {
  json_object_filter_nulls([
    #("poll_id", json.string(poll_answer.poll_id)),
    #("voter_chat", json.nullable(poll_answer.voter_chat, encode_chat)),
    #("user", json.nullable(poll_answer.user, encode_user)),
    #("option_ids", json.array(_, json.int)(poll_answer.option_ids)),
  ])
}

pub fn encode_poll(poll: Poll) -> Json {
  json_object_filter_nulls([
    #("id", json.string(poll.id)),
    #("question", json.string(poll.question)),
    #(
      "question_entities",
      json.nullable(poll.question_entities, json.array(_, encode_message_entity)),
    ),
    #("options", json.array(_, encode_poll_option)(poll.options)),
    #("total_voter_count", json.int(poll.total_voter_count)),
    #("is_closed", json.bool(poll.is_closed)),
    #("is_anonymous", json.bool(poll.is_anonymous)),
    #("type", json.string(poll.type_)),
    #("allows_multiple_answers", json.bool(poll.allows_multiple_answers)),
    #("correct_option_id", json.nullable(poll.correct_option_id, json.int)),
    #("explanation", json.nullable(poll.explanation, json.string)),
    #(
      "explanation_entities",
      json.nullable(poll.explanation_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("open_period", json.nullable(poll.open_period, json.int)),
    #("close_date", json.nullable(poll.close_date, json.int)),
  ])
}

pub fn encode_location(location: Location) -> Json {
  json_object_filter_nulls([
    #("latitude", json.float(location.latitude)),
    #("longitude", json.float(location.longitude)),
    #(
      "horizontal_accuracy",
      json.nullable(location.horizontal_accuracy, json.float),
    ),
    #("live_period", json.nullable(location.live_period, json.int)),
    #("heading", json.nullable(location.heading, json.int)),
    #(
      "proximity_alert_radius",
      json.nullable(location.proximity_alert_radius, json.int),
    ),
  ])
}

pub fn encode_venue(venue: Venue) -> Json {
  json_object_filter_nulls([
    #("location", encode_location(venue.location)),
    #("title", json.string(venue.title)),
    #("address", json.string(venue.address)),
    #("foursquare_id", json.nullable(venue.foursquare_id, json.string)),
    #("foursquare_type", json.nullable(venue.foursquare_type, json.string)),
    #("google_place_id", json.nullable(venue.google_place_id, json.string)),
    #("google_place_type", json.nullable(venue.google_place_type, json.string)),
  ])
}

pub fn encode_web_app_data(web_app_data: WebAppData) -> Json {
  json_object_filter_nulls([
    #("data", json.string(web_app_data.data)),
    #("button_text", json.string(web_app_data.button_text)),
  ])
}

pub fn encode_proximity_alert_triggered(
  proximity_alert_triggered: ProximityAlertTriggered,
) -> Json {
  json_object_filter_nulls([
    #("traveler", encode_user(proximity_alert_triggered.traveler)),
    #("watcher", encode_user(proximity_alert_triggered.watcher)),
    #("distance", json.int(proximity_alert_triggered.distance)),
  ])
}

pub fn encode_message_auto_delete_timer_changed(
  message_auto_delete_timer_changed: MessageAutoDeleteTimerChanged,
) -> Json {
  json_object_filter_nulls([
    #(
      "message_auto_delete_time",
      json.int(message_auto_delete_timer_changed.message_auto_delete_time),
    ),
  ])
}

pub fn encode_chat_boost_added(chat_boost_added: ChatBoostAdded) -> Json {
  json_object_filter_nulls([
    #("boost_count", json.int(chat_boost_added.boost_count)),
  ])
}

pub fn encode_background_fill_solid(
  background_fill_solid: BackgroundFillSolid,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(background_fill_solid.type_)),
    #("color", json.int(background_fill_solid.color)),
  ])
}

pub fn encode_background_fill_gradient(
  background_fill_gradient: BackgroundFillGradient,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(background_fill_gradient.type_)),
    #("top_color", json.int(background_fill_gradient.top_color)),
    #("bottom_color", json.int(background_fill_gradient.bottom_color)),
    #("rotation_angle", json.int(background_fill_gradient.rotation_angle)),
  ])
}

pub fn encode_background_fill_freeform_gradient(
  background_fill_freeform_gradient: BackgroundFillFreeformGradient,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(background_fill_freeform_gradient.type_)),
    #(
      "colors",
      json.array(_, json.int)(background_fill_freeform_gradient.colors),
    ),
  ])
}

pub fn encode_background_type_fill(
  background_type_fill: BackgroundTypeFill,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(background_type_fill.type_)),
    #("fill", encode_background_fill(background_type_fill.fill)),
    #("dark_theme_dimming", json.int(background_type_fill.dark_theme_dimming)),
  ])
}

pub fn encode_background_type_wallpaper(
  background_type_wallpaper: BackgroundTypeWallpaper,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(background_type_wallpaper.type_)),
    #("document", encode_document(background_type_wallpaper.document)),
    #(
      "dark_theme_dimming",
      json.int(background_type_wallpaper.dark_theme_dimming),
    ),
    #(
      "is_blurred",
      json.nullable(background_type_wallpaper.is_blurred, json.bool),
    ),
    #(
      "is_moving",
      json.nullable(background_type_wallpaper.is_moving, json.bool),
    ),
  ])
}

pub fn encode_background_type_pattern(
  background_type_pattern: BackgroundTypePattern,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(background_type_pattern.type_)),
    #("document", encode_document(background_type_pattern.document)),
    #("fill", encode_background_fill(background_type_pattern.fill)),
    #("intensity", json.int(background_type_pattern.intensity)),
    #(
      "is_inverted",
      json.nullable(background_type_pattern.is_inverted, json.bool),
    ),
    #("is_moving", json.nullable(background_type_pattern.is_moving, json.bool)),
  ])
}

pub fn encode_background_type_chat_theme(
  background_type_chat_theme: BackgroundTypeChatTheme,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(background_type_chat_theme.type_)),
    #("theme_name", json.string(background_type_chat_theme.theme_name)),
  ])
}

pub fn encode_chat_background(chat_background: ChatBackground) -> Json {
  json_object_filter_nulls([
    #("type", encode_background_type(chat_background.type_)),
  ])
}

pub fn encode_forum_topic_created(
  forum_topic_created: ForumTopicCreated,
) -> Json {
  json_object_filter_nulls([
    #("name", json.string(forum_topic_created.name)),
    #("icon_color", json.int(forum_topic_created.icon_color)),
    #(
      "icon_custom_emoji_id",
      json.nullable(forum_topic_created.icon_custom_emoji_id, json.string),
    ),
  ])
}

pub fn encode_forum_topic_closed(_forum_topic_closed: ForumTopicClosed) -> Json {
  json_object_filter_nulls([])
}

pub fn encode_forum_topic_edited(forum_topic_edited: ForumTopicEdited) -> Json {
  json_object_filter_nulls([
    #("name", json.nullable(forum_topic_edited.name, json.string)),
    #(
      "icon_custom_emoji_id",
      json.nullable(forum_topic_edited.icon_custom_emoji_id, json.string),
    ),
  ])
}

pub fn encode_forum_topic_reopened(
  _forum_topic_reopened: ForumTopicReopened,
) -> Json {
  json_object_filter_nulls([])
}

pub fn encode_general_forum_topic_hidden(
  _general_forum_topic_hidden: GeneralForumTopicHidden,
) -> Json {
  json_object_filter_nulls([])
}

pub fn encode_general_forum_topic_unhidden(
  _general_forum_topic_unhidden: GeneralForumTopicUnhidden,
) -> Json {
  json_object_filter_nulls([])
}

pub fn encode_shared_user(shared_user: SharedUser) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(shared_user.user_id)),
    #("first_name", json.nullable(shared_user.first_name, json.string)),
    #("last_name", json.nullable(shared_user.last_name, json.string)),
    #("username", json.nullable(shared_user.username, json.string)),
    #(
      "photo",
      json.nullable(shared_user.photo, json.array(_, encode_photo_size)),
    ),
  ])
}

pub fn encode_users_shared(users_shared: UsersShared) -> Json {
  json_object_filter_nulls([
    #("request_id", json.int(users_shared.request_id)),
    #("users", json.array(_, encode_shared_user)(users_shared.users)),
  ])
}

pub fn encode_chat_shared(chat_shared: ChatShared) -> Json {
  json_object_filter_nulls([
    #("request_id", json.int(chat_shared.request_id)),
    #("chat_id", json.int(chat_shared.chat_id)),
    #("title", json.nullable(chat_shared.title, json.string)),
    #("username", json.nullable(chat_shared.username, json.string)),
    #(
      "photo",
      json.nullable(chat_shared.photo, json.array(_, encode_photo_size)),
    ),
  ])
}

pub fn encode_write_access_allowed(
  write_access_allowed: WriteAccessAllowed,
) -> Json {
  json_object_filter_nulls([
    #(
      "from_request",
      json.nullable(write_access_allowed.from_request, json.bool),
    ),
    #(
      "web_app_name",
      json.nullable(write_access_allowed.web_app_name, json.string),
    ),
    #(
      "from_attachment_menu",
      json.nullable(write_access_allowed.from_attachment_menu, json.bool),
    ),
  ])
}

pub fn encode_video_chat_scheduled(
  video_chat_scheduled: VideoChatScheduled,
) -> Json {
  json_object_filter_nulls([
    #("start_date", json.int(video_chat_scheduled.start_date)),
  ])
}

pub fn encode_video_chat_started(_video_chat_started: VideoChatStarted) -> Json {
  json_object_filter_nulls([])
}

pub fn encode_video_chat_ended(video_chat_ended: VideoChatEnded) -> Json {
  json_object_filter_nulls([#("duration", json.int(video_chat_ended.duration))])
}

pub fn encode_video_chat_participants_invited(
  video_chat_participants_invited: VideoChatParticipantsInvited,
) -> Json {
  json_object_filter_nulls([
    #(
      "users",
      json.array(_, encode_user)(video_chat_participants_invited.users),
    ),
  ])
}

pub fn encode_giveaway_created(giveaway_created: GiveawayCreated) -> Json {
  json_object_filter_nulls([
    #(
      "prize_star_count",
      json.nullable(giveaway_created.prize_star_count, json.int),
    ),
  ])
}

pub fn encode_giveaway(giveaway: Giveaway) -> Json {
  json_object_filter_nulls([
    #("chats", json.array(_, encode_chat)(giveaway.chats)),
    #("winners_selection_date", json.int(giveaway.winners_selection_date)),
    #("winner_count", json.int(giveaway.winner_count)),
    #("only_new_members", json.nullable(giveaway.only_new_members, json.bool)),
    #(
      "has_public_winners",
      json.nullable(giveaway.has_public_winners, json.bool),
    ),
    #(
      "prize_description",
      json.nullable(giveaway.prize_description, json.string),
    ),
    #(
      "country_codes",
      json.nullable(giveaway.country_codes, json.array(_, json.string)),
    ),
    #("prize_star_count", json.nullable(giveaway.prize_star_count, json.int)),
    #(
      "premium_subscription_month_count",
      json.nullable(giveaway.premium_subscription_month_count, json.int),
    ),
  ])
}

pub fn encode_giveaway_winners(giveaway_winners: GiveawayWinners) -> Json {
  json_object_filter_nulls([
    #("chat", encode_chat(giveaway_winners.chat)),
    #("giveaway_message_id", json.int(giveaway_winners.giveaway_message_id)),
    #(
      "winners_selection_date",
      json.int(giveaway_winners.winners_selection_date),
    ),
    #("winner_count", json.int(giveaway_winners.winner_count)),
    #("winners", json.array(_, encode_user)(giveaway_winners.winners)),
    #(
      "additional_chat_count",
      json.nullable(giveaway_winners.additional_chat_count, json.int),
    ),
    #(
      "prize_star_count",
      json.nullable(giveaway_winners.prize_star_count, json.int),
    ),
    #(
      "premium_subscription_month_count",
      json.nullable(giveaway_winners.premium_subscription_month_count, json.int),
    ),
    #(
      "unclaimed_prize_count",
      json.nullable(giveaway_winners.unclaimed_prize_count, json.int),
    ),
    #(
      "only_new_members",
      json.nullable(giveaway_winners.only_new_members, json.bool),
    ),
    #("was_refunded", json.nullable(giveaway_winners.was_refunded, json.bool)),
    #(
      "prize_description",
      json.nullable(giveaway_winners.prize_description, json.string),
    ),
  ])
}

pub fn encode_giveaway_completed(giveaway_completed: GiveawayCompleted) -> Json {
  json_object_filter_nulls([
    #("winner_count", json.int(giveaway_completed.winner_count)),
    #(
      "unclaimed_prize_count",
      json.nullable(giveaway_completed.unclaimed_prize_count, json.int),
    ),
    #(
      "giveaway_message",
      json.nullable(giveaway_completed.giveaway_message, encode_message),
    ),
    #(
      "is_star_giveaway",
      json.nullable(giveaway_completed.is_star_giveaway, json.bool),
    ),
  ])
}

pub fn encode_link_preview_options(
  link_preview_options: LinkPreviewOptions,
) -> Json {
  json_object_filter_nulls([
    #("is_disabled", json.nullable(link_preview_options.is_disabled, json.bool)),
    #("url", json.nullable(link_preview_options.url, json.string)),
    #(
      "prefer_small_media",
      json.nullable(link_preview_options.prefer_small_media, json.bool),
    ),
    #(
      "prefer_large_media",
      json.nullable(link_preview_options.prefer_large_media, json.bool),
    ),
    #(
      "show_above_text",
      json.nullable(link_preview_options.show_above_text, json.bool),
    ),
  ])
}

pub fn encode_user_profile_photos(
  user_profile_photos: UserProfilePhotos,
) -> Json {
  json_object_filter_nulls([
    #("total_count", json.int(user_profile_photos.total_count)),
    #(
      "photos",
      fn(outer_list) {
        json.array(outer_list, fn(inner_list) {
          json.array(inner_list, encode_photo_size)
        })
      }(user_profile_photos.photos),
    ),
  ])
}

pub fn encode_file(file: File) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(file.file_id)),
    #("file_unique_id", json.string(file.file_unique_id)),
    #("file_size", json.nullable(file.file_size, json.int)),
    #("file_path", json.nullable(file.file_path, json.string)),
  ])
}

pub fn encode_web_app_info(web_app_info: WebAppInfo) -> Json {
  json_object_filter_nulls([#("url", json.string(web_app_info.url))])
}

pub fn encode_reply_keyboard_markup(
  reply_keyboard_markup: ReplyKeyboardMarkup,
) -> Json {
  json_object_filter_nulls([
    #(
      "keyboard",
      fn(outer_list) {
        json.array(outer_list, fn(inner_list) {
          json.array(inner_list, encode_keyboard_button)
        })
      }(reply_keyboard_markup.keyboard),
    ),
    #(
      "is_persistent",
      json.nullable(reply_keyboard_markup.is_persistent, json.bool),
    ),
    #(
      "resize_keyboard",
      json.nullable(reply_keyboard_markup.resize_keyboard, json.bool),
    ),
    #(
      "one_time_keyboard",
      json.nullable(reply_keyboard_markup.one_time_keyboard, json.bool),
    ),
    #(
      "input_field_placeholder",
      json.nullable(reply_keyboard_markup.input_field_placeholder, json.string),
    ),
    #("selective", json.nullable(reply_keyboard_markup.selective, json.bool)),
  ])
}

pub fn encode_keyboard_button(keyboard_button: KeyboardButton) -> Json {
  json_object_filter_nulls([
    #("text", json.string(keyboard_button.text)),
    #(
      "request_users",
      json.nullable(
        keyboard_button.request_users,
        encode_keyboard_button_request_users,
      ),
    ),
    #(
      "request_chat",
      json.nullable(
        keyboard_button.request_chat,
        encode_keyboard_button_request_chat,
      ),
    ),
    #(
      "request_contact",
      json.nullable(keyboard_button.request_contact, json.bool),
    ),
    #(
      "request_location",
      json.nullable(keyboard_button.request_location, json.bool),
    ),
    #(
      "request_poll",
      json.nullable(
        keyboard_button.request_poll,
        encode_keyboard_button_poll_type,
      ),
    ),
    #("web_app", json.nullable(keyboard_button.web_app, encode_web_app_info)),
  ])
}

pub fn encode_keyboard_button_request_users(
  keyboard_button_request_users: KeyboardButtonRequestUsers,
) -> Json {
  json_object_filter_nulls([
    #("request_id", json.int(keyboard_button_request_users.request_id)),
    #(
      "user_is_bot",
      json.nullable(keyboard_button_request_users.user_is_bot, json.bool),
    ),
    #(
      "user_is_premium",
      json.nullable(keyboard_button_request_users.user_is_premium, json.bool),
    ),
    #(
      "max_quantity",
      json.nullable(keyboard_button_request_users.max_quantity, json.int),
    ),
    #(
      "request_name",
      json.nullable(keyboard_button_request_users.request_name, json.bool),
    ),
    #(
      "request_username",
      json.nullable(keyboard_button_request_users.request_username, json.bool),
    ),
    #(
      "request_photo",
      json.nullable(keyboard_button_request_users.request_photo, json.bool),
    ),
  ])
}

pub fn encode_keyboard_button_request_chat(
  keyboard_button_request_chat: KeyboardButtonRequestChat,
) -> Json {
  json_object_filter_nulls([
    #("request_id", json.int(keyboard_button_request_chat.request_id)),
    #(
      "chat_is_channel",
      json.bool(keyboard_button_request_chat.chat_is_channel),
    ),
    #(
      "chat_is_forum",
      json.nullable(keyboard_button_request_chat.chat_is_forum, json.bool),
    ),
    #(
      "chat_has_username",
      json.nullable(keyboard_button_request_chat.chat_has_username, json.bool),
    ),
    #(
      "chat_is_created",
      json.nullable(keyboard_button_request_chat.chat_is_created, json.bool),
    ),
    #(
      "user_administrator_rights",
      json.nullable(
        keyboard_button_request_chat.user_administrator_rights,
        encode_chat_administrator_rights,
      ),
    ),
    #(
      "bot_administrator_rights",
      json.nullable(
        keyboard_button_request_chat.bot_administrator_rights,
        encode_chat_administrator_rights,
      ),
    ),
    #(
      "bot_is_member",
      json.nullable(keyboard_button_request_chat.bot_is_member, json.bool),
    ),
    #(
      "request_title",
      json.nullable(keyboard_button_request_chat.request_title, json.bool),
    ),
    #(
      "request_username",
      json.nullable(keyboard_button_request_chat.request_username, json.bool),
    ),
    #(
      "request_photo",
      json.nullable(keyboard_button_request_chat.request_photo, json.bool),
    ),
  ])
}

pub fn encode_keyboard_button_poll_type(
  keyboard_button_poll_type: KeyboardButtonPollType,
) -> Json {
  json_object_filter_nulls([
    #("type", json.nullable(keyboard_button_poll_type.type_, json.string)),
  ])
}

pub fn encode_reply_keyboard_remove(
  reply_keyboard_remove: ReplyKeyboardRemove,
) -> Json {
  json_object_filter_nulls([
    #("remove_keyboard", json.bool(reply_keyboard_remove.remove_keyboard)),
    #("selective", json.nullable(reply_keyboard_remove.selective, json.bool)),
  ])
}

pub fn encode_inline_keyboard_markup(
  inline_keyboard_markup: InlineKeyboardMarkup,
) -> Json {
  json_object_filter_nulls([
    #(
      "inline_keyboard",
      fn(outer_list) {
        json.array(outer_list, fn(inner_list) {
          json.array(inner_list, encode_inline_keyboard_button)
        })
      }(inline_keyboard_markup.inline_keyboard),
    ),
  ])
}

pub fn encode_inline_keyboard_button(
  inline_keyboard_button: InlineKeyboardButton,
) -> Json {
  json_object_filter_nulls([
    #("text", json.string(inline_keyboard_button.text)),
    #("url", json.nullable(inline_keyboard_button.url, json.string)),
    #(
      "callback_data",
      json.nullable(inline_keyboard_button.callback_data, json.string),
    ),
    #(
      "web_app",
      json.nullable(inline_keyboard_button.web_app, encode_web_app_info),
    ),
    #(
      "login_url",
      json.nullable(inline_keyboard_button.login_url, encode_login_url),
    ),
    #(
      "switch_inline_query",
      json.nullable(inline_keyboard_button.switch_inline_query, json.string),
    ),
    #(
      "switch_inline_query_current_chat",
      json.nullable(
        inline_keyboard_button.switch_inline_query_current_chat,
        json.string,
      ),
    ),
    #(
      "switch_inline_query_chosen_chat",
      json.nullable(
        inline_keyboard_button.switch_inline_query_chosen_chat,
        encode_switch_inline_query_chosen_chat,
      ),
    ),
    #(
      "copy_text",
      json.nullable(inline_keyboard_button.copy_text, encode_copy_text_button),
    ),
    #(
      "callback_game",
      json.nullable(inline_keyboard_button.callback_game, encode_callback_game),
    ),
    #("pay", json.nullable(inline_keyboard_button.pay, json.bool)),
  ])
}

pub fn encode_login_url(login_url: LoginUrl) -> Json {
  json_object_filter_nulls([
    #("url", json.string(login_url.url)),
    #("forward_text", json.nullable(login_url.forward_text, json.string)),
    #("bot_username", json.nullable(login_url.bot_username, json.string)),
    #(
      "request_write_access",
      json.nullable(login_url.request_write_access, json.bool),
    ),
  ])
}

pub fn encode_switch_inline_query_chosen_chat(
  switch_inline_query_chosen_chat: SwitchInlineQueryChosenChat,
) -> Json {
  json_object_filter_nulls([
    #(
      "query",
      json.nullable(switch_inline_query_chosen_chat.query, json.string),
    ),
    #(
      "allow_user_chats",
      json.nullable(switch_inline_query_chosen_chat.allow_user_chats, json.bool),
    ),
    #(
      "allow_bot_chats",
      json.nullable(switch_inline_query_chosen_chat.allow_bot_chats, json.bool),
    ),
    #(
      "allow_group_chats",
      json.nullable(
        switch_inline_query_chosen_chat.allow_group_chats,
        json.bool,
      ),
    ),
    #(
      "allow_channel_chats",
      json.nullable(
        switch_inline_query_chosen_chat.allow_channel_chats,
        json.bool,
      ),
    ),
  ])
}

pub fn encode_copy_text_button(copy_text_button: CopyTextButton) -> Json {
  json_object_filter_nulls([#("text", json.string(copy_text_button.text))])
}

pub fn encode_callback_query(callback_query: CallbackQuery) -> Json {
  json_object_filter_nulls([
    #("id", json.string(callback_query.id)),
    #("from", encode_user(callback_query.from)),
    #(
      "message",
      json.nullable(callback_query.message, encode_maybe_inaccessible_message),
    ),
    #(
      "inline_message_id",
      json.nullable(callback_query.inline_message_id, json.string),
    ),
    #("chat_instance", json.string(callback_query.chat_instance)),
    #("data", json.nullable(callback_query.data, json.string)),
    #(
      "game_short_name",
      json.nullable(callback_query.game_short_name, json.string),
    ),
  ])
}

pub fn encode_force_reply(force_reply: ForceReply) -> Json {
  json_object_filter_nulls([
    #("force_reply", json.bool(force_reply.force_reply)),
    #(
      "input_field_placeholder",
      json.nullable(force_reply.input_field_placeholder, json.string),
    ),
    #("selective", json.nullable(force_reply.selective, json.bool)),
  ])
}

pub fn encode_chat_photo(chat_photo: ChatPhoto) -> Json {
  json_object_filter_nulls([
    #("small_file_id", json.string(chat_photo.small_file_id)),
    #("small_file_unique_id", json.string(chat_photo.small_file_unique_id)),
    #("big_file_id", json.string(chat_photo.big_file_id)),
    #("big_file_unique_id", json.string(chat_photo.big_file_unique_id)),
  ])
}

pub fn encode_chat_invite_link(chat_invite_link: ChatInviteLink) -> Json {
  json_object_filter_nulls([
    #("invite_link", json.string(chat_invite_link.invite_link)),
    #("creator", encode_user(chat_invite_link.creator)),
    #("creates_join_request", json.bool(chat_invite_link.creates_join_request)),
    #("is_primary", json.bool(chat_invite_link.is_primary)),
    #("is_revoked", json.bool(chat_invite_link.is_revoked)),
    #("name", json.nullable(chat_invite_link.name, json.string)),
    #("expire_date", json.nullable(chat_invite_link.expire_date, json.int)),
    #("member_limit", json.nullable(chat_invite_link.member_limit, json.int)),
    #(
      "pending_join_request_count",
      json.nullable(chat_invite_link.pending_join_request_count, json.int),
    ),
    #(
      "subscription_period",
      json.nullable(chat_invite_link.subscription_period, json.int),
    ),
    #(
      "subscription_price",
      json.nullable(chat_invite_link.subscription_price, json.int),
    ),
  ])
}

pub fn encode_chat_administrator_rights(
  chat_administrator_rights: ChatAdministratorRights,
) -> Json {
  json_object_filter_nulls([
    #("is_anonymous", json.bool(chat_administrator_rights.is_anonymous)),
    #("can_manage_chat", json.bool(chat_administrator_rights.can_manage_chat)),
    #(
      "can_delete_messages",
      json.bool(chat_administrator_rights.can_delete_messages),
    ),
    #(
      "can_manage_video_chats",
      json.bool(chat_administrator_rights.can_manage_video_chats),
    ),
    #(
      "can_restrict_members",
      json.bool(chat_administrator_rights.can_restrict_members),
    ),
    #(
      "can_promote_members",
      json.bool(chat_administrator_rights.can_promote_members),
    ),
    #("can_change_info", json.bool(chat_administrator_rights.can_change_info)),
    #("can_invite_users", json.bool(chat_administrator_rights.can_invite_users)),
    #("can_post_stories", json.bool(chat_administrator_rights.can_post_stories)),
    #("can_edit_stories", json.bool(chat_administrator_rights.can_edit_stories)),
    #(
      "can_delete_stories",
      json.bool(chat_administrator_rights.can_delete_stories),
    ),
    #(
      "can_post_messages",
      json.nullable(chat_administrator_rights.can_post_messages, json.bool),
    ),
    #(
      "can_edit_messages",
      json.nullable(chat_administrator_rights.can_edit_messages, json.bool),
    ),
    #(
      "can_pin_messages",
      json.nullable(chat_administrator_rights.can_pin_messages, json.bool),
    ),
    #(
      "can_manage_topics",
      json.nullable(chat_administrator_rights.can_manage_topics, json.bool),
    ),
  ])
}

pub fn encode_chat_member_updated(
  chat_member_updated: ChatMemberUpdated,
) -> Json {
  json_object_filter_nulls([
    #("chat", encode_chat(chat_member_updated.chat)),
    #("from", encode_user(chat_member_updated.from)),
    #("date", json.int(chat_member_updated.date)),
    #(
      "old_chat_member",
      encode_chat_member(chat_member_updated.old_chat_member),
    ),
    #(
      "new_chat_member",
      encode_chat_member(chat_member_updated.new_chat_member),
    ),
    #(
      "invite_link",
      json.nullable(chat_member_updated.invite_link, encode_chat_invite_link),
    ),
    #(
      "via_join_request",
      json.nullable(chat_member_updated.via_join_request, json.bool),
    ),
    #(
      "via_chat_folder_invite_link",
      json.nullable(chat_member_updated.via_chat_folder_invite_link, json.bool),
    ),
  ])
}

pub fn encode_chat_member_owner(chat_member_owner: ChatMemberOwner) -> Json {
  json_object_filter_nulls([
    #("status", json.string(chat_member_owner.status)),
    #("user", encode_user(chat_member_owner.user)),
    #("is_anonymous", json.bool(chat_member_owner.is_anonymous)),
    #(
      "custom_title",
      json.nullable(chat_member_owner.custom_title, json.string),
    ),
  ])
}

pub fn encode_chat_member_administrator(
  chat_member_administrator: ChatMemberAdministrator,
) -> Json {
  json_object_filter_nulls([
    #("status", json.string(chat_member_administrator.status)),
    #("user", encode_user(chat_member_administrator.user)),
    #("can_be_edited", json.bool(chat_member_administrator.can_be_edited)),
    #("is_anonymous", json.bool(chat_member_administrator.is_anonymous)),
    #("can_manage_chat", json.bool(chat_member_administrator.can_manage_chat)),
    #(
      "can_delete_messages",
      json.bool(chat_member_administrator.can_delete_messages),
    ),
    #(
      "can_manage_video_chats",
      json.bool(chat_member_administrator.can_manage_video_chats),
    ),
    #(
      "can_restrict_members",
      json.bool(chat_member_administrator.can_restrict_members),
    ),
    #(
      "can_promote_members",
      json.bool(chat_member_administrator.can_promote_members),
    ),
    #("can_change_info", json.bool(chat_member_administrator.can_change_info)),
    #("can_invite_users", json.bool(chat_member_administrator.can_invite_users)),
    #("can_post_stories", json.bool(chat_member_administrator.can_post_stories)),
    #("can_edit_stories", json.bool(chat_member_administrator.can_edit_stories)),
    #(
      "can_delete_stories",
      json.bool(chat_member_administrator.can_delete_stories),
    ),
    #(
      "can_post_messages",
      json.nullable(chat_member_administrator.can_post_messages, json.bool),
    ),
    #(
      "can_edit_messages",
      json.nullable(chat_member_administrator.can_edit_messages, json.bool),
    ),
    #(
      "can_pin_messages",
      json.nullable(chat_member_administrator.can_pin_messages, json.bool),
    ),
    #(
      "can_manage_topics",
      json.nullable(chat_member_administrator.can_manage_topics, json.bool),
    ),
    #(
      "custom_title",
      json.nullable(chat_member_administrator.custom_title, json.string),
    ),
  ])
}

pub fn encode_chat_member_member(chat_member_member: ChatMemberMember) -> Json {
  json_object_filter_nulls([
    #("status", json.string(chat_member_member.status)),
    #("user", encode_user(chat_member_member.user)),
    #("until_date", json.nullable(chat_member_member.until_date, json.int)),
  ])
}

pub fn encode_chat_member_restricted(
  chat_member_restricted: ChatMemberRestricted,
) -> Json {
  json_object_filter_nulls([
    #("status", json.string(chat_member_restricted.status)),
    #("user", encode_user(chat_member_restricted.user)),
    #("is_member", json.bool(chat_member_restricted.is_member)),
    #("can_send_messages", json.bool(chat_member_restricted.can_send_messages)),
    #("can_send_audios", json.bool(chat_member_restricted.can_send_audios)),
    #(
      "can_send_documents",
      json.bool(chat_member_restricted.can_send_documents),
    ),
    #("can_send_photos", json.bool(chat_member_restricted.can_send_photos)),
    #("can_send_videos", json.bool(chat_member_restricted.can_send_videos)),
    #(
      "can_send_video_notes",
      json.bool(chat_member_restricted.can_send_video_notes),
    ),
    #(
      "can_send_voice_notes",
      json.bool(chat_member_restricted.can_send_voice_notes),
    ),
    #("can_send_polls", json.bool(chat_member_restricted.can_send_polls)),
    #(
      "can_send_other_messages",
      json.bool(chat_member_restricted.can_send_other_messages),
    ),
    #(
      "can_add_web_page_previews",
      json.bool(chat_member_restricted.can_add_web_page_previews),
    ),
    #("can_change_info", json.bool(chat_member_restricted.can_change_info)),
    #("can_invite_users", json.bool(chat_member_restricted.can_invite_users)),
    #("can_pin_messages", json.bool(chat_member_restricted.can_pin_messages)),
    #("can_manage_topics", json.bool(chat_member_restricted.can_manage_topics)),
    #("until_date", json.int(chat_member_restricted.until_date)),
  ])
}

pub fn encode_chat_member_left(chat_member_left: ChatMemberLeft) -> Json {
  json_object_filter_nulls([
    #("status", json.string(chat_member_left.status)),
    #("user", encode_user(chat_member_left.user)),
  ])
}

pub fn encode_chat_member_banned(chat_member_banned: ChatMemberBanned) -> Json {
  json_object_filter_nulls([
    #("status", json.string(chat_member_banned.status)),
    #("user", encode_user(chat_member_banned.user)),
    #("until_date", json.int(chat_member_banned.until_date)),
  ])
}

pub fn encode_chat_join_request(chat_join_request: ChatJoinRequest) -> Json {
  json_object_filter_nulls([
    #("chat", encode_chat(chat_join_request.chat)),
    #("from", encode_user(chat_join_request.from)),
    #("user_chat_id", json.int(chat_join_request.user_chat_id)),
    #("date", json.int(chat_join_request.date)),
    #("bio", json.nullable(chat_join_request.bio, json.string)),
    #(
      "invite_link",
      json.nullable(chat_join_request.invite_link, encode_chat_invite_link),
    ),
  ])
}

pub fn encode_chat_permissions(chat_permissions: ChatPermissions) -> Json {
  json_object_filter_nulls([
    #(
      "can_send_messages",
      json.nullable(chat_permissions.can_send_messages, json.bool),
    ),
    #(
      "can_send_audios",
      json.nullable(chat_permissions.can_send_audios, json.bool),
    ),
    #(
      "can_send_documents",
      json.nullable(chat_permissions.can_send_documents, json.bool),
    ),
    #(
      "can_send_photos",
      json.nullable(chat_permissions.can_send_photos, json.bool),
    ),
    #(
      "can_send_videos",
      json.nullable(chat_permissions.can_send_videos, json.bool),
    ),
    #(
      "can_send_video_notes",
      json.nullable(chat_permissions.can_send_video_notes, json.bool),
    ),
    #(
      "can_send_voice_notes",
      json.nullable(chat_permissions.can_send_voice_notes, json.bool),
    ),
    #(
      "can_send_polls",
      json.nullable(chat_permissions.can_send_polls, json.bool),
    ),
    #(
      "can_send_other_messages",
      json.nullable(chat_permissions.can_send_other_messages, json.bool),
    ),
    #(
      "can_add_web_page_previews",
      json.nullable(chat_permissions.can_add_web_page_previews, json.bool),
    ),
    #(
      "can_change_info",
      json.nullable(chat_permissions.can_change_info, json.bool),
    ),
    #(
      "can_invite_users",
      json.nullable(chat_permissions.can_invite_users, json.bool),
    ),
    #(
      "can_pin_messages",
      json.nullable(chat_permissions.can_pin_messages, json.bool),
    ),
    #(
      "can_manage_topics",
      json.nullable(chat_permissions.can_manage_topics, json.bool),
    ),
  ])
}

pub fn encode_birthdate(birthdate: Birthdate) -> Json {
  json_object_filter_nulls([
    #("day", json.int(birthdate.day)),
    #("month", json.int(birthdate.month)),
    #("year", json.nullable(birthdate.year, json.int)),
  ])
}

pub fn encode_business_intro(business_intro: BusinessIntro) -> Json {
  json_object_filter_nulls([
    #("title", json.nullable(business_intro.title, json.string)),
    #("message", json.nullable(business_intro.message, json.string)),
    #("sticker", json.nullable(business_intro.sticker, encode_sticker)),
  ])
}

pub fn encode_business_location(business_location: BusinessLocation) -> Json {
  json_object_filter_nulls([
    #("address", json.string(business_location.address)),
    #("location", json.nullable(business_location.location, encode_location)),
  ])
}

pub fn encode_business_opening_hours_interval(
  business_opening_hours_interval: BusinessOpeningHoursInterval,
) -> Json {
  json_object_filter_nulls([
    #(
      "opening_minute",
      json.int(business_opening_hours_interval.opening_minute),
    ),
    #(
      "closing_minute",
      json.int(business_opening_hours_interval.closing_minute),
    ),
  ])
}

pub fn encode_business_opening_hours(
  business_opening_hours: BusinessOpeningHours,
) -> Json {
  json_object_filter_nulls([
    #("time_zone_name", json.string(business_opening_hours.time_zone_name)),
    #(
      "opening_hours",
      json.array(_, encode_business_opening_hours_interval)(
        business_opening_hours.opening_hours,
      ),
    ),
  ])
}

pub fn encode_chat_location(chat_location: ChatLocation) -> Json {
  json_object_filter_nulls([
    #("location", encode_location(chat_location.location)),
    #("address", json.string(chat_location.address)),
  ])
}

pub fn encode_reaction_type_emoji(
  reaction_type_emoji: ReactionTypeEmoji,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(reaction_type_emoji.type_)),
    #("emoji", json.string(reaction_type_emoji.emoji)),
  ])
}

pub fn encode_reaction_type_custom_emoji(
  reaction_type_custom_emoji: ReactionTypeCustomEmoji,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(reaction_type_custom_emoji.type_)),
    #(
      "custom_emoji_id",
      json.string(reaction_type_custom_emoji.custom_emoji_id),
    ),
  ])
}

pub fn encode_reaction_type_paid(reaction_type_paid: ReactionTypePaid) -> Json {
  json_object_filter_nulls([#("type", json.string(reaction_type_paid.type_))])
}

pub fn encode_reaction_count(reaction_count: ReactionCount) -> Json {
  json_object_filter_nulls([
    #("type", encode_reaction_type(reaction_count.type_)),
    #("total_count", json.int(reaction_count.total_count)),
  ])
}

pub fn encode_message_reaction_updated(
  message_reaction_updated: MessageReactionUpdated,
) -> Json {
  json_object_filter_nulls([
    #("chat", encode_chat(message_reaction_updated.chat)),
    #("message_id", json.int(message_reaction_updated.message_id)),
    #("user", json.nullable(message_reaction_updated.user, encode_user)),
    #(
      "actor_chat",
      json.nullable(message_reaction_updated.actor_chat, encode_chat),
    ),
    #("date", json.int(message_reaction_updated.date)),
    #(
      "old_reaction",
      json.array(_, encode_reaction_type)(message_reaction_updated.old_reaction),
    ),
    #(
      "new_reaction",
      json.array(_, encode_reaction_type)(message_reaction_updated.new_reaction),
    ),
  ])
}

pub fn encode_message_reaction_count_updated(
  message_reaction_count_updated: MessageReactionCountUpdated,
) -> Json {
  json_object_filter_nulls([
    #("chat", encode_chat(message_reaction_count_updated.chat)),
    #("message_id", json.int(message_reaction_count_updated.message_id)),
    #("date", json.int(message_reaction_count_updated.date)),
    #(
      "reactions",
      json.array(_, encode_reaction_count)(
        message_reaction_count_updated.reactions,
      ),
    ),
  ])
}

pub fn encode_forum_topic(forum_topic: ForumTopic) -> Json {
  json_object_filter_nulls([
    #("message_thread_id", json.int(forum_topic.message_thread_id)),
    #("name", json.string(forum_topic.name)),
    #("icon_color", json.int(forum_topic.icon_color)),
    #(
      "icon_custom_emoji_id",
      json.nullable(forum_topic.icon_custom_emoji_id, json.string),
    ),
  ])
}

pub fn encode_bot_command(bot_command: BotCommand) -> Json {
  json_object_filter_nulls([
    #("command", json.string(bot_command.command)),
    #("description", json.string(bot_command.description)),
  ])
}

pub fn encode_bot_command_scope_default(
  bot_command_scope_default: BotCommandScopeDefault,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(bot_command_scope_default.type_)),
  ])
}

pub fn encode_bot_command_scope_all_private_chats(
  bot_command_scope_all_private_chats: BotCommandScopeAllPrivateChats,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(bot_command_scope_all_private_chats.type_)),
  ])
}

pub fn encode_bot_command_scope_all_group_chats(
  bot_command_scope_all_group_chats: BotCommandScopeAllGroupChats,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(bot_command_scope_all_group_chats.type_)),
  ])
}

pub fn encode_bot_command_scope_all_chat_administrators(
  bot_command_scope_all_chat_administrators: BotCommandScopeAllChatAdministrators,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(bot_command_scope_all_chat_administrators.type_)),
  ])
}

pub fn encode_bot_command_scope_chat(
  bot_command_scope_chat: BotCommandScopeChat,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(bot_command_scope_chat.type_)),
    #("chat_id", encode_int_or_string(bot_command_scope_chat.chat_id)),
  ])
}

pub fn encode_bot_command_scope_chat_administrators(
  bot_command_scope_chat_administrators: BotCommandScopeChatAdministrators,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(bot_command_scope_chat_administrators.type_)),
    #(
      "chat_id",
      encode_int_or_string(bot_command_scope_chat_administrators.chat_id),
    ),
  ])
}

pub fn encode_bot_command_scope_chat_member(
  bot_command_scope_chat_member: BotCommandScopeChatMember,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(bot_command_scope_chat_member.type_)),
    #("chat_id", encode_int_or_string(bot_command_scope_chat_member.chat_id)),
    #("user_id", json.int(bot_command_scope_chat_member.user_id)),
  ])
}

pub fn encode_bot_name(bot_name: BotName) -> Json {
  json_object_filter_nulls([#("name", json.string(bot_name.name))])
}

pub fn encode_bot_description(bot_description: BotDescription) -> Json {
  json_object_filter_nulls([
    #("description", json.string(bot_description.description)),
  ])
}

pub fn encode_bot_short_description(
  bot_short_description: BotShortDescription,
) -> Json {
  json_object_filter_nulls([
    #("short_description", json.string(bot_short_description.short_description)),
  ])
}

pub fn encode_menu_button_commands(
  menu_button_commands: MenuButtonCommands,
) -> Json {
  json_object_filter_nulls([#("type", json.string(menu_button_commands.type_))])
}

pub fn encode_menu_button_web_app(menu_button_web_app: MenuButtonWebApp) -> Json {
  json_object_filter_nulls([
    #("type", json.string(menu_button_web_app.type_)),
    #("text", json.string(menu_button_web_app.text)),
    #("web_app", encode_web_app_info(menu_button_web_app.web_app)),
  ])
}

pub fn encode_menu_button_default(
  menu_button_default: MenuButtonDefault,
) -> Json {
  json_object_filter_nulls([#("type", json.string(menu_button_default.type_))])
}

pub fn encode_chat_boost_source_premium(
  chat_boost_source_premium: ChatBoostSourcePremium,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(chat_boost_source_premium.source)),
    #("user", encode_user(chat_boost_source_premium.user)),
  ])
}

pub fn encode_chat_boost_source_gift_code(
  chat_boost_source_gift_code: ChatBoostSourceGiftCode,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(chat_boost_source_gift_code.source)),
    #("user", encode_user(chat_boost_source_gift_code.user)),
  ])
}

pub fn encode_chat_boost_source_giveaway(
  chat_boost_source_giveaway: ChatBoostSourceGiveaway,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(chat_boost_source_giveaway.source)),
    #(
      "giveaway_message_id",
      json.int(chat_boost_source_giveaway.giveaway_message_id),
    ),
    #("user", json.nullable(chat_boost_source_giveaway.user, encode_user)),
    #(
      "prize_star_count",
      json.nullable(chat_boost_source_giveaway.prize_star_count, json.int),
    ),
    #(
      "is_unclaimed",
      json.nullable(chat_boost_source_giveaway.is_unclaimed, json.bool),
    ),
  ])
}

pub fn encode_chat_boost(chat_boost: ChatBoost) -> Json {
  json_object_filter_nulls([
    #("boost_id", json.string(chat_boost.boost_id)),
    #("add_date", json.int(chat_boost.add_date)),
    #("expiration_date", json.int(chat_boost.expiration_date)),
    #("source", encode_chat_boost_source(chat_boost.source)),
  ])
}

pub fn encode_chat_boost_updated(chat_boost_updated: ChatBoostUpdated) -> Json {
  json_object_filter_nulls([
    #("chat", encode_chat(chat_boost_updated.chat)),
    #("boost", encode_chat_boost(chat_boost_updated.boost)),
  ])
}

pub fn encode_chat_boost_removed(chat_boost_removed: ChatBoostRemoved) -> Json {
  json_object_filter_nulls([
    #("chat", encode_chat(chat_boost_removed.chat)),
    #("boost_id", json.string(chat_boost_removed.boost_id)),
    #("remove_date", json.int(chat_boost_removed.remove_date)),
    #("source", encode_chat_boost_source(chat_boost_removed.source)),
  ])
}

pub fn encode_user_chat_boosts(user_chat_boosts: UserChatBoosts) -> Json {
  json_object_filter_nulls([
    #("boosts", json.array(_, encode_chat_boost)(user_chat_boosts.boosts)),
  ])
}

pub fn encode_business_bot_rights(
  business_bot_rights: BusinessBotRights,
) -> Json {
  json_object_filter_nulls([
    #("can_reply", json.nullable(business_bot_rights.can_reply, json.bool)),
    #(
      "can_read_messages",
      json.nullable(business_bot_rights.can_read_messages, json.bool),
    ),
    #(
      "can_delete_outgoing_messages",
      json.nullable(business_bot_rights.can_delete_outgoing_messages, json.bool),
    ),
    #(
      "can_delete_all_messages",
      json.nullable(business_bot_rights.can_delete_all_messages, json.bool),
    ),
    #(
      "can_edit_name",
      json.nullable(business_bot_rights.can_edit_name, json.bool),
    ),
    #(
      "can_edit_bio",
      json.nullable(business_bot_rights.can_edit_bio, json.bool),
    ),
    #(
      "can_edit_profile_photo",
      json.nullable(business_bot_rights.can_edit_profile_photo, json.bool),
    ),
    #(
      "can_edit_username",
      json.nullable(business_bot_rights.can_edit_username, json.bool),
    ),
    #(
      "can_change_gift_settings",
      json.nullable(business_bot_rights.can_change_gift_settings, json.bool),
    ),
    #(
      "can_view_gifts_and_stars",
      json.nullable(business_bot_rights.can_view_gifts_and_stars, json.bool),
    ),
    #(
      "can_convert_gifts_to_stars",
      json.nullable(business_bot_rights.can_convert_gifts_to_stars, json.bool),
    ),
    #(
      "can_transfer_and_upgrade_gifts",
      json.nullable(
        business_bot_rights.can_transfer_and_upgrade_gifts,
        json.bool,
      ),
    ),
    #(
      "can_transfer_stars",
      json.nullable(business_bot_rights.can_transfer_stars, json.bool),
    ),
    #(
      "can_manage_stories",
      json.nullable(business_bot_rights.can_manage_stories, json.bool),
    ),
  ])
}

pub fn encode_business_connection(
  business_connection: BusinessConnection,
) -> Json {
  json_object_filter_nulls([
    #("id", json.string(business_connection.id)),
    #("user", encode_user(business_connection.user)),
    #("user_chat_id", json.int(business_connection.user_chat_id)),
    #("date", json.int(business_connection.date)),
    #(
      "rights",
      json.nullable(business_connection.rights, encode_business_bot_rights),
    ),
    #("is_enabled", json.bool(business_connection.is_enabled)),
  ])
}

pub fn encode_business_messages_deleted(
  business_messages_deleted: BusinessMessagesDeleted,
) -> Json {
  json_object_filter_nulls([
    #(
      "business_connection_id",
      json.string(business_messages_deleted.business_connection_id),
    ),
    #("chat", encode_chat(business_messages_deleted.chat)),
    #(
      "message_ids",
      json.array(_, json.int)(business_messages_deleted.message_ids),
    ),
  ])
}

pub fn encode_response_parameters(
  response_parameters: ResponseParameters,
) -> Json {
  json_object_filter_nulls([
    #(
      "migrate_to_chat_id",
      json.nullable(response_parameters.migrate_to_chat_id, json.int),
    ),
    #("retry_after", json.nullable(response_parameters.retry_after, json.int)),
  ])
}

pub fn encode_input_media_photo(input_media_photo: InputMediaPhoto) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_media_photo.type_)),
    #("media", json.string(input_media_photo.media)),
    #("caption", json.nullable(input_media_photo.caption, json.string)),
    #("parse_mode", json.nullable(input_media_photo.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(input_media_photo.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(input_media_photo.show_caption_above_media, json.bool),
    ),
    #("has_spoiler", json.nullable(input_media_photo.has_spoiler, json.bool)),
  ])
}

pub fn encode_input_media_video(input_media_video: InputMediaVideo) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_media_video.type_)),
    #("media", json.string(input_media_video.media)),
    #("thumbnail", json.nullable(input_media_video.thumbnail, json.string)),
    #("cover", json.nullable(input_media_video.cover, json.string)),
    #(
      "start_timestamp",
      json.nullable(input_media_video.start_timestamp, json.int),
    ),
    #("caption", json.nullable(input_media_video.caption, json.string)),
    #("parse_mode", json.nullable(input_media_video.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(input_media_video.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(input_media_video.show_caption_above_media, json.bool),
    ),
    #("width", json.nullable(input_media_video.width, json.int)),
    #("height", json.nullable(input_media_video.height, json.int)),
    #("duration", json.nullable(input_media_video.duration, json.int)),
    #(
      "supports_streaming",
      json.nullable(input_media_video.supports_streaming, json.bool),
    ),
    #("has_spoiler", json.nullable(input_media_video.has_spoiler, json.bool)),
  ])
}

pub fn encode_input_media_animation(
  input_media_animation: InputMediaAnimation,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_media_animation.type_)),
    #("media", json.string(input_media_animation.media)),
    #("thumbnail", json.nullable(input_media_animation.thumbnail, json.string)),
    #("caption", json.nullable(input_media_animation.caption, json.string)),
    #(
      "parse_mode",
      json.nullable(input_media_animation.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(input_media_animation.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(input_media_animation.show_caption_above_media, json.bool),
    ),
    #("width", json.nullable(input_media_animation.width, json.int)),
    #("height", json.nullable(input_media_animation.height, json.int)),
    #("duration", json.nullable(input_media_animation.duration, json.int)),
    #(
      "has_spoiler",
      json.nullable(input_media_animation.has_spoiler, json.bool),
    ),
  ])
}

pub fn encode_input_media_audio(input_media_audio: InputMediaAudio) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_media_audio.type_)),
    #("media", json.string(input_media_audio.media)),
    #("thumbnail", json.nullable(input_media_audio.thumbnail, json.string)),
    #("caption", json.nullable(input_media_audio.caption, json.string)),
    #("parse_mode", json.nullable(input_media_audio.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(input_media_audio.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("duration", json.nullable(input_media_audio.duration, json.int)),
    #("performer", json.nullable(input_media_audio.performer, json.string)),
    #("title", json.nullable(input_media_audio.title, json.string)),
  ])
}

pub fn encode_input_media_document(
  input_media_document: InputMediaDocument,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_media_document.type_)),
    #("media", json.string(input_media_document.media)),
    #("thumbnail", json.nullable(input_media_document.thumbnail, json.string)),
    #("caption", json.nullable(input_media_document.caption, json.string)),
    #("parse_mode", json.nullable(input_media_document.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(input_media_document.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "disable_content_type_detection",
      json.nullable(
        input_media_document.disable_content_type_detection,
        json.bool,
      ),
    ),
  ])
}

pub fn encode_input_paid_media_photo(
  input_paid_media_photo: InputPaidMediaPhoto,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_paid_media_photo.type_)),
    #("media", json.string(input_paid_media_photo.media)),
  ])
}

pub fn encode_input_paid_media_video(
  input_paid_media_video: InputPaidMediaVideo,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_paid_media_video.type_)),
    #("media", json.string(input_paid_media_video.media)),
    #("thumbnail", json.nullable(input_paid_media_video.thumbnail, json.string)),
    #("cover", json.nullable(input_paid_media_video.cover, json.string)),
    #(
      "start_timestamp",
      json.nullable(input_paid_media_video.start_timestamp, json.int),
    ),
    #("width", json.nullable(input_paid_media_video.width, json.int)),
    #("height", json.nullable(input_paid_media_video.height, json.int)),
    #("duration", json.nullable(input_paid_media_video.duration, json.int)),
    #(
      "supports_streaming",
      json.nullable(input_paid_media_video.supports_streaming, json.bool),
    ),
  ])
}

pub fn encode_sticker(sticker: Sticker) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(sticker.file_id)),
    #("file_unique_id", json.string(sticker.file_unique_id)),
    #("type", json.string(sticker.type_)),
    #("width", json.int(sticker.width)),
    #("height", json.int(sticker.height)),
    #("is_animated", json.bool(sticker.is_animated)),
    #("is_video", json.bool(sticker.is_video)),
    #("thumbnail", json.nullable(sticker.thumbnail, encode_photo_size)),
    #("emoji", json.nullable(sticker.emoji, json.string)),
    #("set_name", json.nullable(sticker.set_name, json.string)),
    #(
      "premium_animation",
      json.nullable(sticker.premium_animation, encode_file),
    ),
    #(
      "mask_position",
      json.nullable(sticker.mask_position, encode_mask_position),
    ),
    #("custom_emoji_id", json.nullable(sticker.custom_emoji_id, json.string)),
    #("needs_repainting", json.nullable(sticker.needs_repainting, json.bool)),
    #("file_size", json.nullable(sticker.file_size, json.int)),
  ])
}

pub fn encode_sticker_set(sticker_set: StickerSet) -> Json {
  json_object_filter_nulls([
    #("name", json.string(sticker_set.name)),
    #("title", json.string(sticker_set.title)),
    #("sticker_type", json.string(sticker_set.sticker_type)),
    #("stickers", json.array(_, encode_sticker)(sticker_set.stickers)),
    #("thumbnail", json.nullable(sticker_set.thumbnail, encode_photo_size)),
  ])
}

pub fn encode_mask_position(mask_position: MaskPosition) -> Json {
  json_object_filter_nulls([
    #("point", json.string(mask_position.point)),
    #("x_shift", json.float(mask_position.x_shift)),
    #("y_shift", json.float(mask_position.y_shift)),
    #("scale", json.float(mask_position.scale)),
  ])
}

pub fn encode_input_sticker(input_sticker: InputSticker) -> Json {
  json_object_filter_nulls([
    #("sticker", encode_file_or_string(input_sticker.sticker)),
    #("format", json.string(input_sticker.format)),
    #("emoji_list", json.array(_, json.string)(input_sticker.emoji_list)),
    #(
      "mask_position",
      json.nullable(input_sticker.mask_position, encode_mask_position),
    ),
    #(
      "keywords",
      json.nullable(input_sticker.keywords, json.array(_, json.string)),
    ),
  ])
}

pub fn encode_gift(gift: Gift) -> Json {
  json_object_filter_nulls([
    #("id", json.string(gift.id)),
    #("sticker", encode_sticker(gift.sticker)),
    #("star_count", json.int(gift.star_count)),
    #("upgrade_star_count", json.nullable(gift.upgrade_star_count, json.int)),
    #("total_count", json.nullable(gift.total_count, json.int)),
    #("remaining_count", json.nullable(gift.remaining_count, json.int)),
  ])
}

pub fn encode_gifts(gifts: Gifts) -> Json {
  json_object_filter_nulls([#("gifts", json.array(_, encode_gift)(gifts.gifts))])
}

pub fn encode_inline_query(inline_query: InlineQuery) -> Json {
  json_object_filter_nulls([
    #("id", json.string(inline_query.id)),
    #("from", encode_user(inline_query.from)),
    #("query", json.string(inline_query.query)),
    #("offset", json.string(inline_query.offset)),
    #("chat_type", json.nullable(inline_query.chat_type, json.string)),
    #("location", json.nullable(inline_query.location, encode_location)),
  ])
}

pub fn encode_inline_query_results_button(
  inline_query_results_button: InlineQueryResultsButton,
) -> Json {
  json_object_filter_nulls([
    #("text", json.string(inline_query_results_button.text)),
    #(
      "web_app",
      json.nullable(inline_query_results_button.web_app, encode_web_app_info),
    ),
    #(
      "start_parameter",
      json.nullable(inline_query_results_button.start_parameter, json.string),
    ),
  ])
}

pub fn encode_inline_query_result_article(
  inline_query_result_article: InlineQueryResultArticle,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_article.type_)),
    #("id", json.string(inline_query_result_article.id)),
    #("title", json.string(inline_query_result_article.title)),
    #(
      "input_message_content",
      encode_input_message_content(
        inline_query_result_article.input_message_content,
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_article.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #("url", json.nullable(inline_query_result_article.url, json.string)),
    #(
      "description",
      json.nullable(inline_query_result_article.description, json.string),
    ),
    #(
      "thumbnail_url",
      json.nullable(inline_query_result_article.thumbnail_url, json.string),
    ),
    #(
      "thumbnail_width",
      json.nullable(inline_query_result_article.thumbnail_width, json.int),
    ),
    #(
      "thumbnail_height",
      json.nullable(inline_query_result_article.thumbnail_height, json.int),
    ),
  ])
}

pub fn encode_inline_query_result_photo(
  inline_query_result_photo: InlineQueryResultPhoto,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_photo.type_)),
    #("id", json.string(inline_query_result_photo.id)),
    #("photo_url", json.string(inline_query_result_photo.photo_url)),
    #("thumbnail_url", json.string(inline_query_result_photo.thumbnail_url)),
    #(
      "photo_width",
      json.nullable(inline_query_result_photo.photo_width, json.int),
    ),
    #(
      "photo_height",
      json.nullable(inline_query_result_photo.photo_height, json.int),
    ),
    #("title", json.nullable(inline_query_result_photo.title, json.string)),
    #(
      "description",
      json.nullable(inline_query_result_photo.description, json.string),
    ),
    #("caption", json.nullable(inline_query_result_photo.caption, json.string)),
    #(
      "parse_mode",
      json.nullable(inline_query_result_photo.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(inline_query_result_photo.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(
        inline_query_result_photo.show_caption_above_media,
        json.bool,
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_photo.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_photo.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_gif(
  inline_query_result_gif: InlineQueryResultGif,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_gif.type_)),
    #("id", json.string(inline_query_result_gif.id)),
    #("gif_url", json.string(inline_query_result_gif.gif_url)),
    #("gif_width", json.nullable(inline_query_result_gif.gif_width, json.int)),
    #("gif_height", json.nullable(inline_query_result_gif.gif_height, json.int)),
    #(
      "gif_duration",
      json.nullable(inline_query_result_gif.gif_duration, json.int),
    ),
    #("thumbnail_url", json.string(inline_query_result_gif.thumbnail_url)),
    #(
      "thumbnail_mime_type",
      json.nullable(inline_query_result_gif.thumbnail_mime_type, json.string),
    ),
    #("title", json.nullable(inline_query_result_gif.title, json.string)),
    #("caption", json.nullable(inline_query_result_gif.caption, json.string)),
    #(
      "parse_mode",
      json.nullable(inline_query_result_gif.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(inline_query_result_gif.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(inline_query_result_gif.show_caption_above_media, json.bool),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_gif.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_gif.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_mpeg4_gif(
  inline_query_result_mpeg4_gif: InlineQueryResultMpeg4Gif,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_mpeg4_gif.type_)),
    #("id", json.string(inline_query_result_mpeg4_gif.id)),
    #("mpeg4_url", json.string(inline_query_result_mpeg4_gif.mpeg4_url)),
    #(
      "mpeg4_width",
      json.nullable(inline_query_result_mpeg4_gif.mpeg4_width, json.int),
    ),
    #(
      "mpeg4_height",
      json.nullable(inline_query_result_mpeg4_gif.mpeg4_height, json.int),
    ),
    #(
      "mpeg4_duration",
      json.nullable(inline_query_result_mpeg4_gif.mpeg4_duration, json.int),
    ),
    #("thumbnail_url", json.string(inline_query_result_mpeg4_gif.thumbnail_url)),
    #(
      "thumbnail_mime_type",
      json.nullable(
        inline_query_result_mpeg4_gif.thumbnail_mime_type,
        json.string,
      ),
    ),
    #("title", json.nullable(inline_query_result_mpeg4_gif.title, json.string)),
    #(
      "caption",
      json.nullable(inline_query_result_mpeg4_gif.caption, json.string),
    ),
    #(
      "parse_mode",
      json.nullable(inline_query_result_mpeg4_gif.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(inline_query_result_mpeg4_gif.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(
        inline_query_result_mpeg4_gif.show_caption_above_media,
        json.bool,
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_mpeg4_gif.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_mpeg4_gif.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_video(
  inline_query_result_video: InlineQueryResultVideo,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_video.type_)),
    #("id", json.string(inline_query_result_video.id)),
    #("video_url", json.string(inline_query_result_video.video_url)),
    #("mime_type", json.string(inline_query_result_video.mime_type)),
    #("thumbnail_url", json.string(inline_query_result_video.thumbnail_url)),
    #("title", json.string(inline_query_result_video.title)),
    #("caption", json.nullable(inline_query_result_video.caption, json.string)),
    #(
      "parse_mode",
      json.nullable(inline_query_result_video.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(inline_query_result_video.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(
        inline_query_result_video.show_caption_above_media,
        json.bool,
      ),
    ),
    #(
      "video_width",
      json.nullable(inline_query_result_video.video_width, json.int),
    ),
    #(
      "video_height",
      json.nullable(inline_query_result_video.video_height, json.int),
    ),
    #(
      "video_duration",
      json.nullable(inline_query_result_video.video_duration, json.int),
    ),
    #(
      "description",
      json.nullable(inline_query_result_video.description, json.string),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_video.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_video.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_audio(
  inline_query_result_audio: InlineQueryResultAudio,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_audio.type_)),
    #("id", json.string(inline_query_result_audio.id)),
    #("audio_url", json.string(inline_query_result_audio.audio_url)),
    #("title", json.string(inline_query_result_audio.title)),
    #("caption", json.nullable(inline_query_result_audio.caption, json.string)),
    #(
      "parse_mode",
      json.nullable(inline_query_result_audio.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(inline_query_result_audio.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "performer",
      json.nullable(inline_query_result_audio.performer, json.string),
    ),
    #(
      "audio_duration",
      json.nullable(inline_query_result_audio.audio_duration, json.int),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_audio.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_audio.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_voice(
  inline_query_result_voice: InlineQueryResultVoice,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_voice.type_)),
    #("id", json.string(inline_query_result_voice.id)),
    #("voice_url", json.string(inline_query_result_voice.voice_url)),
    #("title", json.string(inline_query_result_voice.title)),
    #("caption", json.nullable(inline_query_result_voice.caption, json.string)),
    #(
      "parse_mode",
      json.nullable(inline_query_result_voice.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(inline_query_result_voice.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "voice_duration",
      json.nullable(inline_query_result_voice.voice_duration, json.int),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_voice.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_voice.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_document(
  inline_query_result_document: InlineQueryResultDocument,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_document.type_)),
    #("id", json.string(inline_query_result_document.id)),
    #("title", json.string(inline_query_result_document.title)),
    #(
      "caption",
      json.nullable(inline_query_result_document.caption, json.string),
    ),
    #(
      "parse_mode",
      json.nullable(inline_query_result_document.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(inline_query_result_document.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("document_url", json.string(inline_query_result_document.document_url)),
    #("mime_type", json.string(inline_query_result_document.mime_type)),
    #(
      "description",
      json.nullable(inline_query_result_document.description, json.string),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_document.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_document.input_message_content,
        encode_input_message_content,
      ),
    ),
    #(
      "thumbnail_url",
      json.nullable(inline_query_result_document.thumbnail_url, json.string),
    ),
    #(
      "thumbnail_width",
      json.nullable(inline_query_result_document.thumbnail_width, json.int),
    ),
    #(
      "thumbnail_height",
      json.nullable(inline_query_result_document.thumbnail_height, json.int),
    ),
  ])
}

pub fn encode_inline_query_result_location(
  inline_query_result_location: InlineQueryResultLocation,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_location.type_)),
    #("id", json.string(inline_query_result_location.id)),
    #("latitude", json.float(inline_query_result_location.latitude)),
    #("longitude", json.float(inline_query_result_location.longitude)),
    #("title", json.string(inline_query_result_location.title)),
    #(
      "horizontal_accuracy",
      json.nullable(
        inline_query_result_location.horizontal_accuracy,
        json.float,
      ),
    ),
    #(
      "live_period",
      json.nullable(inline_query_result_location.live_period, json.int),
    ),
    #("heading", json.nullable(inline_query_result_location.heading, json.int)),
    #(
      "proximity_alert_radius",
      json.nullable(
        inline_query_result_location.proximity_alert_radius,
        json.int,
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_location.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_location.input_message_content,
        encode_input_message_content,
      ),
    ),
    #(
      "thumbnail_url",
      json.nullable(inline_query_result_location.thumbnail_url, json.string),
    ),
    #(
      "thumbnail_width",
      json.nullable(inline_query_result_location.thumbnail_width, json.int),
    ),
    #(
      "thumbnail_height",
      json.nullable(inline_query_result_location.thumbnail_height, json.int),
    ),
  ])
}

pub fn encode_inline_query_result_venue(
  inline_query_result_venue: InlineQueryResultVenue,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_venue.type_)),
    #("id", json.string(inline_query_result_venue.id)),
    #("latitude", json.float(inline_query_result_venue.latitude)),
    #("longitude", json.float(inline_query_result_venue.longitude)),
    #("title", json.string(inline_query_result_venue.title)),
    #("address", json.string(inline_query_result_venue.address)),
    #(
      "foursquare_id",
      json.nullable(inline_query_result_venue.foursquare_id, json.string),
    ),
    #(
      "foursquare_type",
      json.nullable(inline_query_result_venue.foursquare_type, json.string),
    ),
    #(
      "google_place_id",
      json.nullable(inline_query_result_venue.google_place_id, json.string),
    ),
    #(
      "google_place_type",
      json.nullable(inline_query_result_venue.google_place_type, json.string),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_venue.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_venue.input_message_content,
        encode_input_message_content,
      ),
    ),
    #(
      "thumbnail_url",
      json.nullable(inline_query_result_venue.thumbnail_url, json.string),
    ),
    #(
      "thumbnail_width",
      json.nullable(inline_query_result_venue.thumbnail_width, json.int),
    ),
    #(
      "thumbnail_height",
      json.nullable(inline_query_result_venue.thumbnail_height, json.int),
    ),
  ])
}

pub fn encode_inline_query_result_contact(
  inline_query_result_contact: InlineQueryResultContact,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_contact.type_)),
    #("id", json.string(inline_query_result_contact.id)),
    #("phone_number", json.string(inline_query_result_contact.phone_number)),
    #("first_name", json.string(inline_query_result_contact.first_name)),
    #(
      "last_name",
      json.nullable(inline_query_result_contact.last_name, json.string),
    ),
    #("vcard", json.nullable(inline_query_result_contact.vcard, json.string)),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_contact.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_contact.input_message_content,
        encode_input_message_content,
      ),
    ),
    #(
      "thumbnail_url",
      json.nullable(inline_query_result_contact.thumbnail_url, json.string),
    ),
    #(
      "thumbnail_width",
      json.nullable(inline_query_result_contact.thumbnail_width, json.int),
    ),
    #(
      "thumbnail_height",
      json.nullable(inline_query_result_contact.thumbnail_height, json.int),
    ),
  ])
}

pub fn encode_inline_query_result_game(
  inline_query_result_game: InlineQueryResultGame,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_game.type_)),
    #("id", json.string(inline_query_result_game.id)),
    #("game_short_name", json.string(inline_query_result_game.game_short_name)),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_game.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_cached_photo(
  inline_query_result_cached_photo: InlineQueryResultCachedPhoto,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_cached_photo.type_)),
    #("id", json.string(inline_query_result_cached_photo.id)),
    #(
      "photo_file_id",
      json.string(inline_query_result_cached_photo.photo_file_id),
    ),
    #(
      "title",
      json.nullable(inline_query_result_cached_photo.title, json.string),
    ),
    #(
      "description",
      json.nullable(inline_query_result_cached_photo.description, json.string),
    ),
    #(
      "caption",
      json.nullable(inline_query_result_cached_photo.caption, json.string),
    ),
    #(
      "parse_mode",
      json.nullable(inline_query_result_cached_photo.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(
        inline_query_result_cached_photo.caption_entities,
        json.array(_, encode_message_entity),
      ),
    ),
    #(
      "show_caption_above_media",
      json.nullable(
        inline_query_result_cached_photo.show_caption_above_media,
        json.bool,
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_cached_photo.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_cached_photo.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_cached_gif(
  inline_query_result_cached_gif: InlineQueryResultCachedGif,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_cached_gif.type_)),
    #("id", json.string(inline_query_result_cached_gif.id)),
    #("gif_file_id", json.string(inline_query_result_cached_gif.gif_file_id)),
    #("title", json.nullable(inline_query_result_cached_gif.title, json.string)),
    #(
      "caption",
      json.nullable(inline_query_result_cached_gif.caption, json.string),
    ),
    #(
      "parse_mode",
      json.nullable(inline_query_result_cached_gif.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(inline_query_result_cached_gif.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(
        inline_query_result_cached_gif.show_caption_above_media,
        json.bool,
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_cached_gif.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_cached_gif.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_cached_mpeg4_gif(
  inline_query_result_cached_mpeg4_gif: InlineQueryResultCachedMpeg4Gif,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_cached_mpeg4_gif.type_)),
    #("id", json.string(inline_query_result_cached_mpeg4_gif.id)),
    #(
      "mpeg4_file_id",
      json.string(inline_query_result_cached_mpeg4_gif.mpeg4_file_id),
    ),
    #(
      "title",
      json.nullable(inline_query_result_cached_mpeg4_gif.title, json.string),
    ),
    #(
      "caption",
      json.nullable(inline_query_result_cached_mpeg4_gif.caption, json.string),
    ),
    #(
      "parse_mode",
      json.nullable(
        inline_query_result_cached_mpeg4_gif.parse_mode,
        json.string,
      ),
    ),
    #(
      "caption_entities",
      json.nullable(
        inline_query_result_cached_mpeg4_gif.caption_entities,
        json.array(_, encode_message_entity),
      ),
    ),
    #(
      "show_caption_above_media",
      json.nullable(
        inline_query_result_cached_mpeg4_gif.show_caption_above_media,
        json.bool,
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_cached_mpeg4_gif.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_cached_mpeg4_gif.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_cached_sticker(
  inline_query_result_cached_sticker: InlineQueryResultCachedSticker,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_cached_sticker.type_)),
    #("id", json.string(inline_query_result_cached_sticker.id)),
    #(
      "sticker_file_id",
      json.string(inline_query_result_cached_sticker.sticker_file_id),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_cached_sticker.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_cached_sticker.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_cached_document(
  inline_query_result_cached_document: InlineQueryResultCachedDocument,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_cached_document.type_)),
    #("id", json.string(inline_query_result_cached_document.id)),
    #("title", json.string(inline_query_result_cached_document.title)),
    #(
      "document_file_id",
      json.string(inline_query_result_cached_document.document_file_id),
    ),
    #(
      "description",
      json.nullable(
        inline_query_result_cached_document.description,
        json.string,
      ),
    ),
    #(
      "caption",
      json.nullable(inline_query_result_cached_document.caption, json.string),
    ),
    #(
      "parse_mode",
      json.nullable(inline_query_result_cached_document.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(
        inline_query_result_cached_document.caption_entities,
        json.array(_, encode_message_entity),
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_cached_document.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_cached_document.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_cached_video(
  inline_query_result_cached_video: InlineQueryResultCachedVideo,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_cached_video.type_)),
    #("id", json.string(inline_query_result_cached_video.id)),
    #(
      "video_file_id",
      json.string(inline_query_result_cached_video.video_file_id),
    ),
    #("title", json.string(inline_query_result_cached_video.title)),
    #(
      "description",
      json.nullable(inline_query_result_cached_video.description, json.string),
    ),
    #(
      "caption",
      json.nullable(inline_query_result_cached_video.caption, json.string),
    ),
    #(
      "parse_mode",
      json.nullable(inline_query_result_cached_video.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(
        inline_query_result_cached_video.caption_entities,
        json.array(_, encode_message_entity),
      ),
    ),
    #(
      "show_caption_above_media",
      json.nullable(
        inline_query_result_cached_video.show_caption_above_media,
        json.bool,
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_cached_video.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_cached_video.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_cached_voice(
  inline_query_result_cached_voice: InlineQueryResultCachedVoice,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_cached_voice.type_)),
    #("id", json.string(inline_query_result_cached_voice.id)),
    #(
      "voice_file_id",
      json.string(inline_query_result_cached_voice.voice_file_id),
    ),
    #("title", json.string(inline_query_result_cached_voice.title)),
    #(
      "caption",
      json.nullable(inline_query_result_cached_voice.caption, json.string),
    ),
    #(
      "parse_mode",
      json.nullable(inline_query_result_cached_voice.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(
        inline_query_result_cached_voice.caption_entities,
        json.array(_, encode_message_entity),
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_cached_voice.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_cached_voice.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_inline_query_result_cached_audio(
  inline_query_result_cached_audio: InlineQueryResultCachedAudio,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(inline_query_result_cached_audio.type_)),
    #("id", json.string(inline_query_result_cached_audio.id)),
    #(
      "audio_file_id",
      json.string(inline_query_result_cached_audio.audio_file_id),
    ),
    #(
      "caption",
      json.nullable(inline_query_result_cached_audio.caption, json.string),
    ),
    #(
      "parse_mode",
      json.nullable(inline_query_result_cached_audio.parse_mode, json.string),
    ),
    #(
      "caption_entities",
      json.nullable(
        inline_query_result_cached_audio.caption_entities,
        json.array(_, encode_message_entity),
      ),
    ),
    #(
      "reply_markup",
      json.nullable(
        inline_query_result_cached_audio.reply_markup,
        encode_inline_keyboard_markup,
      ),
    ),
    #(
      "input_message_content",
      json.nullable(
        inline_query_result_cached_audio.input_message_content,
        encode_input_message_content,
      ),
    ),
  ])
}

pub fn encode_input_text_message_content(
  input_text_message_content: InputTextMessageContent,
) -> Json {
  json_object_filter_nulls([
    #("message_text", json.string(input_text_message_content.message_text)),
    #(
      "parse_mode",
      json.nullable(input_text_message_content.parse_mode, json.string),
    ),
    #(
      "entities",
      json.nullable(input_text_message_content.entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "link_preview_options",
      json.nullable(
        input_text_message_content.link_preview_options,
        encode_link_preview_options,
      ),
    ),
  ])
}

pub fn encode_input_location_message_content(
  input_location_message_content: InputLocationMessageContent,
) -> Json {
  json_object_filter_nulls([
    #("latitude", json.float(input_location_message_content.latitude)),
    #("longitude", json.float(input_location_message_content.longitude)),
    #(
      "horizontal_accuracy",
      json.nullable(
        input_location_message_content.horizontal_accuracy,
        json.float,
      ),
    ),
    #(
      "live_period",
      json.nullable(input_location_message_content.live_period, json.int),
    ),
    #(
      "heading",
      json.nullable(input_location_message_content.heading, json.int),
    ),
    #(
      "proximity_alert_radius",
      json.nullable(
        input_location_message_content.proximity_alert_radius,
        json.int,
      ),
    ),
  ])
}

pub fn encode_input_venue_message_content(
  input_venue_message_content: InputVenueMessageContent,
) -> Json {
  json_object_filter_nulls([
    #("latitude", json.float(input_venue_message_content.latitude)),
    #("longitude", json.float(input_venue_message_content.longitude)),
    #("title", json.string(input_venue_message_content.title)),
    #("address", json.string(input_venue_message_content.address)),
    #(
      "foursquare_id",
      json.nullable(input_venue_message_content.foursquare_id, json.string),
    ),
    #(
      "foursquare_type",
      json.nullable(input_venue_message_content.foursquare_type, json.string),
    ),
    #(
      "google_place_id",
      json.nullable(input_venue_message_content.google_place_id, json.string),
    ),
    #(
      "google_place_type",
      json.nullable(input_venue_message_content.google_place_type, json.string),
    ),
  ])
}

pub fn encode_input_contact_message_content(
  input_contact_message_content: InputContactMessageContent,
) -> Json {
  json_object_filter_nulls([
    #("phone_number", json.string(input_contact_message_content.phone_number)),
    #("first_name", json.string(input_contact_message_content.first_name)),
    #(
      "last_name",
      json.nullable(input_contact_message_content.last_name, json.string),
    ),
    #("vcard", json.nullable(input_contact_message_content.vcard, json.string)),
  ])
}

pub fn encode_input_invoice_message_content(
  input_invoice_message_content: InputInvoiceMessageContent,
) -> Json {
  json_object_filter_nulls([
    #("title", json.string(input_invoice_message_content.title)),
    #("description", json.string(input_invoice_message_content.description)),
    #("payload", json.string(input_invoice_message_content.payload)),
    #(
      "provider_token",
      json.nullable(input_invoice_message_content.provider_token, json.string),
    ),
    #("currency", json.string(input_invoice_message_content.currency)),
    #(
      "prices",
      json.array(_, encode_labeled_price)(input_invoice_message_content.prices),
    ),
    #(
      "max_tip_amount",
      json.nullable(input_invoice_message_content.max_tip_amount, json.int),
    ),
    #(
      "suggested_tip_amounts",
      json.nullable(
        input_invoice_message_content.suggested_tip_amounts,
        json.array(_, json.int),
      ),
    ),
    #(
      "provider_data",
      json.nullable(input_invoice_message_content.provider_data, json.string),
    ),
    #(
      "photo_url",
      json.nullable(input_invoice_message_content.photo_url, json.string),
    ),
    #(
      "photo_size",
      json.nullable(input_invoice_message_content.photo_size, json.int),
    ),
    #(
      "photo_width",
      json.nullable(input_invoice_message_content.photo_width, json.int),
    ),
    #(
      "photo_height",
      json.nullable(input_invoice_message_content.photo_height, json.int),
    ),
    #(
      "need_name",
      json.nullable(input_invoice_message_content.need_name, json.bool),
    ),
    #(
      "need_phone_number",
      json.nullable(input_invoice_message_content.need_phone_number, json.bool),
    ),
    #(
      "need_email",
      json.nullable(input_invoice_message_content.need_email, json.bool),
    ),
    #(
      "need_shipping_address",
      json.nullable(
        input_invoice_message_content.need_shipping_address,
        json.bool,
      ),
    ),
    #(
      "send_phone_number_to_provider",
      json.nullable(
        input_invoice_message_content.send_phone_number_to_provider,
        json.bool,
      ),
    ),
    #(
      "send_email_to_provider",
      json.nullable(
        input_invoice_message_content.send_email_to_provider,
        json.bool,
      ),
    ),
    #(
      "is_flexible",
      json.nullable(input_invoice_message_content.is_flexible, json.bool),
    ),
  ])
}

pub fn encode_chosen_inline_result(
  chosen_inline_result: ChosenInlineResult,
) -> Json {
  json_object_filter_nulls([
    #("result_id", json.string(chosen_inline_result.result_id)),
    #("from", encode_user(chosen_inline_result.from)),
    #("location", json.nullable(chosen_inline_result.location, encode_location)),
    #(
      "inline_message_id",
      json.nullable(chosen_inline_result.inline_message_id, json.string),
    ),
    #("query", json.string(chosen_inline_result.query)),
  ])
}

pub fn encode_sent_web_app_message(
  sent_web_app_message: SentWebAppMessage,
) -> Json {
  json_object_filter_nulls([
    #(
      "inline_message_id",
      json.nullable(sent_web_app_message.inline_message_id, json.string),
    ),
  ])
}

pub fn encode_prepared_inline_message(
  prepared_inline_message: PreparedInlineMessage,
) -> Json {
  json_object_filter_nulls([
    #("id", json.string(prepared_inline_message.id)),
    #("expiration_date", json.int(prepared_inline_message.expiration_date)),
  ])
}

pub fn encode_labeled_price(labeled_price: LabeledPrice) -> Json {
  json_object_filter_nulls([
    #("label", json.string(labeled_price.label)),
    #("amount", json.int(labeled_price.amount)),
  ])
}

pub fn encode_invoice(invoice: Invoice) -> Json {
  json_object_filter_nulls([
    #("title", json.string(invoice.title)),
    #("description", json.string(invoice.description)),
    #("start_parameter", json.string(invoice.start_parameter)),
    #("currency", json.string(invoice.currency)),
    #("total_amount", json.int(invoice.total_amount)),
  ])
}

pub fn encode_shipping_address(shipping_address: ShippingAddress) -> Json {
  json_object_filter_nulls([
    #("country_code", json.string(shipping_address.country_code)),
    #("state", json.string(shipping_address.state)),
    #("city", json.string(shipping_address.city)),
    #("street_line1", json.string(shipping_address.street_line1)),
    #("street_line2", json.string(shipping_address.street_line2)),
    #("post_code", json.string(shipping_address.post_code)),
  ])
}

pub fn encode_order_info(order_info: OrderInfo) -> Json {
  json_object_filter_nulls([
    #("name", json.nullable(order_info.name, json.string)),
    #("phone_number", json.nullable(order_info.phone_number, json.string)),
    #("email", json.nullable(order_info.email, json.string)),
    #(
      "shipping_address",
      json.nullable(order_info.shipping_address, encode_shipping_address),
    ),
  ])
}

pub fn encode_shipping_option(shipping_option: ShippingOption) -> Json {
  json_object_filter_nulls([
    #("id", json.string(shipping_option.id)),
    #("title", json.string(shipping_option.title)),
    #("prices", json.array(_, encode_labeled_price)(shipping_option.prices)),
  ])
}

pub fn encode_successful_payment(successful_payment: SuccessfulPayment) -> Json {
  json_object_filter_nulls([
    #("currency", json.string(successful_payment.currency)),
    #("total_amount", json.int(successful_payment.total_amount)),
    #("invoice_payload", json.string(successful_payment.invoice_payload)),
    #(
      "subscription_expiration_date",
      json.nullable(successful_payment.subscription_expiration_date, json.int),
    ),
    #("is_recurring", json.nullable(successful_payment.is_recurring, json.bool)),
    #(
      "is_first_recurring",
      json.nullable(successful_payment.is_first_recurring, json.bool),
    ),
    #(
      "shipping_option_id",
      json.nullable(successful_payment.shipping_option_id, json.string),
    ),
    #(
      "order_info",
      json.nullable(successful_payment.order_info, encode_order_info),
    ),
    #(
      "telegram_payment_charge_id",
      json.string(successful_payment.telegram_payment_charge_id),
    ),
    #(
      "provider_payment_charge_id",
      json.string(successful_payment.provider_payment_charge_id),
    ),
  ])
}

pub fn encode_refunded_payment(refunded_payment: RefundedPayment) -> Json {
  json_object_filter_nulls([
    #("currency", json.string(refunded_payment.currency)),
    #("total_amount", json.int(refunded_payment.total_amount)),
    #("invoice_payload", json.string(refunded_payment.invoice_payload)),
    #(
      "telegram_payment_charge_id",
      json.string(refunded_payment.telegram_payment_charge_id),
    ),
    #(
      "provider_payment_charge_id",
      json.nullable(refunded_payment.provider_payment_charge_id, json.string),
    ),
  ])
}

pub fn encode_shipping_query(shipping_query: ShippingQuery) -> Json {
  json_object_filter_nulls([
    #("id", json.string(shipping_query.id)),
    #("from", encode_user(shipping_query.from)),
    #("invoice_payload", json.string(shipping_query.invoice_payload)),
    #(
      "shipping_address",
      encode_shipping_address(shipping_query.shipping_address),
    ),
  ])
}

pub fn encode_pre_checkout_query(pre_checkout_query: PreCheckoutQuery) -> Json {
  json_object_filter_nulls([
    #("id", json.string(pre_checkout_query.id)),
    #("from", encode_user(pre_checkout_query.from)),
    #("currency", json.string(pre_checkout_query.currency)),
    #("total_amount", json.int(pre_checkout_query.total_amount)),
    #("invoice_payload", json.string(pre_checkout_query.invoice_payload)),
    #(
      "shipping_option_id",
      json.nullable(pre_checkout_query.shipping_option_id, json.string),
    ),
    #(
      "order_info",
      json.nullable(pre_checkout_query.order_info, encode_order_info),
    ),
  ])
}

pub fn encode_paid_media_purchased(
  paid_media_purchased: PaidMediaPurchased,
) -> Json {
  json_object_filter_nulls([
    #("from", encode_user(paid_media_purchased.from)),
    #(
      "paid_media_payload",
      json.string(paid_media_purchased.paid_media_payload),
    ),
  ])
}

pub fn encode_revenue_withdrawal_state_pending(
  revenue_withdrawal_state_pending: RevenueWithdrawalStatePending,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(revenue_withdrawal_state_pending.type_)),
  ])
}

pub fn encode_revenue_withdrawal_state_succeeded(
  revenue_withdrawal_state_succeeded: RevenueWithdrawalStateSucceeded,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(revenue_withdrawal_state_succeeded.type_)),
    #("date", json.int(revenue_withdrawal_state_succeeded.date)),
    #("url", json.string(revenue_withdrawal_state_succeeded.url)),
  ])
}

pub fn encode_revenue_withdrawal_state_failed(
  revenue_withdrawal_state_failed: RevenueWithdrawalStateFailed,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(revenue_withdrawal_state_failed.type_)),
  ])
}

pub fn encode_affiliate_info(affiliate_info: AffiliateInfo) -> Json {
  json_object_filter_nulls([
    #(
      "affiliate_user",
      json.nullable(affiliate_info.affiliate_user, encode_user),
    ),
    #(
      "affiliate_chat",
      json.nullable(affiliate_info.affiliate_chat, encode_chat),
    ),
    #("commission_per_mille", json.int(affiliate_info.commission_per_mille)),
    #("amount", json.int(affiliate_info.amount)),
    #(
      "nanostar_amount",
      json.nullable(affiliate_info.nanostar_amount, json.int),
    ),
  ])
}

pub fn encode_transaction_partner_user(
  transaction_partner_user: TransactionPartnerUser,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(transaction_partner_user.type_)),
    #("user", encode_user(transaction_partner_user.user)),
    #(
      "affiliate",
      json.nullable(transaction_partner_user.affiliate, encode_affiliate_info),
    ),
    #(
      "invoice_payload",
      json.nullable(transaction_partner_user.invoice_payload, json.string),
    ),
    #(
      "subscription_period",
      json.nullable(transaction_partner_user.subscription_period, json.int),
    ),
    #(
      "paid_media",
      json.nullable(transaction_partner_user.paid_media, json.array(
        _,
        encode_paid_media,
      )),
    ),
    #(
      "paid_media_payload",
      json.nullable(transaction_partner_user.paid_media_payload, json.string),
    ),
    #("gift", json.nullable(transaction_partner_user.gift, encode_gift)),
  ])
}

pub fn encode_transaction_partner_chat(
  transaction_partner_chat: TransactionPartnerChat,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(transaction_partner_chat.type_)),
    #("chat", encode_chat(transaction_partner_chat.chat)),
    #("gift", json.nullable(transaction_partner_chat.gift, encode_gift)),
  ])
}

pub fn encode_transaction_partner_affiliate_program(
  transaction_partner_affiliate_program: TransactionPartnerAffiliateProgram,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(transaction_partner_affiliate_program.type_)),
    #(
      "sponsor_user",
      json.nullable(
        transaction_partner_affiliate_program.sponsor_user,
        encode_user,
      ),
    ),
    #(
      "commission_per_mille",
      json.int(transaction_partner_affiliate_program.commission_per_mille),
    ),
  ])
}

pub fn encode_transaction_partner_fragment(
  transaction_partner_fragment: TransactionPartnerFragment,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(transaction_partner_fragment.type_)),
    #(
      "withdrawal_state",
      json.nullable(
        transaction_partner_fragment.withdrawal_state,
        encode_revenue_withdrawal_state,
      ),
    ),
  ])
}

pub fn encode_transaction_partner_telegram_ads(
  transaction_partner_telegram_ads: TransactionPartnerTelegramAds,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(transaction_partner_telegram_ads.type_)),
  ])
}

pub fn encode_transaction_partner_telegram_api(
  transaction_partner_telegram_api: TransactionPartnerTelegramApi,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(transaction_partner_telegram_api.type_)),
    #("request_count", json.int(transaction_partner_telegram_api.request_count)),
  ])
}

pub fn encode_transaction_partner_other(
  transaction_partner_other: TransactionPartnerOther,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(transaction_partner_other.type_)),
  ])
}

pub fn encode_star_transaction(star_transaction: StarTransaction) -> Json {
  json_object_filter_nulls([
    #("id", json.string(star_transaction.id)),
    #("amount", json.int(star_transaction.amount)),
    #(
      "nanostar_amount",
      json.nullable(star_transaction.nanostar_amount, json.int),
    ),
    #("date", json.int(star_transaction.date)),
    #(
      "source",
      json.nullable(star_transaction.source, encode_transaction_partner),
    ),
    #(
      "receiver",
      json.nullable(star_transaction.receiver, encode_transaction_partner),
    ),
  ])
}

pub fn encode_star_transactions(star_transactions: StarTransactions) -> Json {
  json_object_filter_nulls([
    #(
      "transactions",
      json.array(_, encode_star_transaction)(star_transactions.transactions),
    ),
  ])
}

pub fn encode_passport_data(passport_data: PassportData) -> Json {
  json_object_filter_nulls([
    #(
      "data",
      json.array(_, encode_encrypted_passport_element)(passport_data.data),
    ),
    #("credentials", encode_encrypted_credentials(passport_data.credentials)),
  ])
}

pub fn encode_passport_file(passport_file: PassportFile) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(passport_file.file_id)),
    #("file_unique_id", json.string(passport_file.file_unique_id)),
    #("file_size", json.int(passport_file.file_size)),
    #("file_date", json.int(passport_file.file_date)),
  ])
}

pub fn encode_encrypted_passport_element(
  encrypted_passport_element: EncryptedPassportElement,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(encrypted_passport_element.type_)),
    #("data", json.nullable(encrypted_passport_element.data, json.string)),
    #(
      "phone_number",
      json.nullable(encrypted_passport_element.phone_number, json.string),
    ),
    #("email", json.nullable(encrypted_passport_element.email, json.string)),
    #(
      "files",
      json.nullable(encrypted_passport_element.files, json.array(
        _,
        encode_passport_file,
      )),
    ),
    #(
      "front_side",
      json.nullable(encrypted_passport_element.front_side, encode_passport_file),
    ),
    #(
      "reverse_side",
      json.nullable(
        encrypted_passport_element.reverse_side,
        encode_passport_file,
      ),
    ),
    #(
      "selfie",
      json.nullable(encrypted_passport_element.selfie, encode_passport_file),
    ),
    #(
      "translation",
      json.nullable(encrypted_passport_element.translation, json.array(
        _,
        encode_passport_file,
      )),
    ),
    #("hash", json.string(encrypted_passport_element.hash)),
  ])
}

pub fn encode_encrypted_credentials(
  encrypted_credentials: EncryptedCredentials,
) -> Json {
  json_object_filter_nulls([
    #("data", json.string(encrypted_credentials.data)),
    #("hash", json.string(encrypted_credentials.hash)),
    #("secret", json.string(encrypted_credentials.secret)),
  ])
}

pub fn encode_passport_element_error_data_field(
  passport_element_error_data_field: PassportElementErrorDataField,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(passport_element_error_data_field.source)),
    #("type", json.string(passport_element_error_data_field.type_)),
    #("field_name", json.string(passport_element_error_data_field.field_name)),
    #("data_hash", json.string(passport_element_error_data_field.data_hash)),
    #("message", json.string(passport_element_error_data_field.message)),
  ])
}

pub fn encode_passport_element_error_front_side(
  passport_element_error_front_side: PassportElementErrorFrontSide,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(passport_element_error_front_side.source)),
    #("type", json.string(passport_element_error_front_side.type_)),
    #("file_hash", json.string(passport_element_error_front_side.file_hash)),
    #("message", json.string(passport_element_error_front_side.message)),
  ])
}

pub fn encode_passport_element_error_reverse_side(
  passport_element_error_reverse_side: PassportElementErrorReverseSide,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(passport_element_error_reverse_side.source)),
    #("type", json.string(passport_element_error_reverse_side.type_)),
    #("file_hash", json.string(passport_element_error_reverse_side.file_hash)),
    #("message", json.string(passport_element_error_reverse_side.message)),
  ])
}

pub fn encode_passport_element_error_selfie(
  passport_element_error_selfie: PassportElementErrorSelfie,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(passport_element_error_selfie.source)),
    #("type", json.string(passport_element_error_selfie.type_)),
    #("file_hash", json.string(passport_element_error_selfie.file_hash)),
    #("message", json.string(passport_element_error_selfie.message)),
  ])
}

pub fn encode_passport_element_error_file(
  passport_element_error_file: PassportElementErrorFile,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(passport_element_error_file.source)),
    #("type", json.string(passport_element_error_file.type_)),
    #("file_hash", json.string(passport_element_error_file.file_hash)),
    #("message", json.string(passport_element_error_file.message)),
  ])
}

pub fn encode_passport_element_error_files(
  passport_element_error_files: PassportElementErrorFiles,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(passport_element_error_files.source)),
    #("type", json.string(passport_element_error_files.type_)),
    #(
      "file_hashes",
      json.array(_, json.string)(passport_element_error_files.file_hashes),
    ),
    #("message", json.string(passport_element_error_files.message)),
  ])
}

pub fn encode_passport_element_error_translation_file(
  passport_element_error_translation_file: PassportElementErrorTranslationFile,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(passport_element_error_translation_file.source)),
    #("type", json.string(passport_element_error_translation_file.type_)),
    #(
      "file_hash",
      json.string(passport_element_error_translation_file.file_hash),
    ),
    #("message", json.string(passport_element_error_translation_file.message)),
  ])
}

pub fn encode_passport_element_error_translation_files(
  passport_element_error_translation_files: PassportElementErrorTranslationFiles,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(passport_element_error_translation_files.source)),
    #("type", json.string(passport_element_error_translation_files.type_)),
    #(
      "file_hashes",
      json.array(_, json.string)(
        passport_element_error_translation_files.file_hashes,
      ),
    ),
    #("message", json.string(passport_element_error_translation_files.message)),
  ])
}

pub fn encode_passport_element_error_unspecified(
  passport_element_error_unspecified: PassportElementErrorUnspecified,
) -> Json {
  json_object_filter_nulls([
    #("source", json.string(passport_element_error_unspecified.source)),
    #("type", json.string(passport_element_error_unspecified.type_)),
    #(
      "element_hash",
      json.string(passport_element_error_unspecified.element_hash),
    ),
    #("message", json.string(passport_element_error_unspecified.message)),
  ])
}

pub fn encode_game(game: Game) -> Json {
  json_object_filter_nulls([
    #("title", json.string(game.title)),
    #("description", json.string(game.description)),
    #("photo", json.array(_, encode_photo_size)(game.photo)),
    #("text", json.nullable(game.text, json.string)),
    #(
      "text_entities",
      json.nullable(game.text_entities, json.array(_, encode_message_entity)),
    ),
    #("animation", json.nullable(game.animation, encode_animation)),
  ])
}

pub fn encode_callback_game(callback_game: CallbackGame) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(callback_game.user_id)),
    #("score", json.int(callback_game.score)),
    #("force", json.nullable(callback_game.force, json.bool)),
    #(
      "disable_edit_message",
      json.nullable(callback_game.disable_edit_message, json.bool),
    ),
    #("chat_id", json.nullable(callback_game.chat_id, json.int)),
    #("message_id", json.nullable(callback_game.message_id, json.int)),
    #(
      "inline_message_id",
      json.nullable(callback_game.inline_message_id, json.string),
    ),
  ])
}

pub fn encode_game_high_score(game_high_score: GameHighScore) -> Json {
  json_object_filter_nulls([
    #("position", json.int(game_high_score.position)),
    #("user", encode_user(game_high_score.user)),
    #("score", json.int(game_high_score.score)),
  ])
}

fn maybe_inaccessible_message_message_decoder() {
  use message <- decode.then(message_decoder())
  decode.success(MessageMaybeInaccessibleMessage(message))
}

fn maybe_inaccessible_message_inaccessible_message_decoder() {
  use value <- decode.then(inaccessible_message_decoder())
  decode.success(InaccessibleMessageMaybeInaccessibleMessage(value))
}

pub fn maybe_inaccessible_message_decoder() -> decode.Decoder(
  MaybeInaccessibleMessage,
) {
  decode.one_of(maybe_inaccessible_message_message_decoder(), [
    maybe_inaccessible_message_inaccessible_message_decoder(),
  ])
}

pub fn message_origin_decoder() -> decode.Decoder(MessageOrigin) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "user" -> {
      use value <- decode.then(message_origin_user_decoder())
      decode.success(MessageOriginUserMessageOrigin(value))
    }
    "hidden_user" -> {
      use value <- decode.then(message_origin_hidden_user_decoder())
      decode.success(MessageOriginHiddenUserMessageOrigin(value))
    }
    "chat" -> {
      use value <- decode.then(message_origin_chat_decoder())
      decode.success(MessageOriginChatMessageOrigin(value))
    }
    "channel" -> {
      use value <- decode.then(message_origin_channel_decoder())
      decode.success(MessageOriginChannelMessageOrigin(value))
    }
    _ -> panic as "Invalid variant for MessageOrigin"
  }
}

pub fn paid_media_decoder() -> decode.Decoder(PaidMedia) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "preview" -> {
      use value <- decode.then(paid_media_preview_decoder())
      decode.success(PaidMediaPreviewPaidMedia(value))
    }
    "photo" -> {
      use value <- decode.then(paid_media_photo_decoder())
      decode.success(PaidMediaPhotoPaidMedia(value))
    }
    "video" -> {
      use value <- decode.then(paid_media_video_decoder())
      decode.success(PaidMediaVideoPaidMedia(value))
    }
    _ -> panic as "Invalid variant for PaidMedia"
  }
}

pub fn background_fill_decoder() -> decode.Decoder(BackgroundFill) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "solid" -> {
      use value <- decode.then(background_fill_solid_decoder())
      decode.success(BackgroundFillSolidBackgroundFill(value))
    }
    "gradient" -> {
      use value <- decode.then(background_fill_gradient_decoder())
      decode.success(BackgroundFillGradientBackgroundFill(value))
    }
    "freeform_gradient" -> {
      use value <- decode.then(background_fill_freeform_gradient_decoder())
      decode.success(BackgroundFillFreeformGradientBackgroundFill(value))
    }
    _ -> panic as "Invalid variant for BackgroundFill"
  }
}

pub fn background_type_decoder() -> decode.Decoder(BackgroundType) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "fill" -> {
      use value <- decode.then(background_type_fill_decoder())
      decode.success(BackgroundTypeFillBackgroundType(value))
    }
    "wallpaper" -> {
      use value <- decode.then(background_type_wallpaper_decoder())
      decode.success(BackgroundTypeWallpaperBackgroundType(value))
    }
    "pattern" -> {
      use value <- decode.then(background_type_pattern_decoder())
      decode.success(BackgroundTypePatternBackgroundType(value))
    }
    "chat_theme" -> {
      use value <- decode.then(background_type_chat_theme_decoder())
      decode.success(BackgroundTypeChatThemeBackgroundType(value))
    }
    _ -> panic as "Invalid variant for BackgroundType"
  }
}

pub fn chat_member_decoder() -> decode.Decoder(ChatMember) {
  use variant <- decode.field("status", decode.string)
  case variant {
    "creator" -> {
      use value <- decode.then(chat_member_owner_decoder())
      decode.success(ChatMemberOwnerChatMember(value))
    }
    "administrator" -> {
      use value <- decode.then(chat_member_administrator_decoder())
      decode.success(ChatMemberAdministratorChatMember(value))
    }
    "member" -> {
      use value <- decode.then(chat_member_member_decoder())
      decode.success(ChatMemberMemberChatMember(value))
    }
    "restricted" -> {
      use value <- decode.then(chat_member_restricted_decoder())
      decode.success(ChatMemberRestrictedChatMember(value))
    }
    "left" -> {
      use value <- decode.then(chat_member_left_decoder())
      decode.success(ChatMemberLeftChatMember(value))
    }
    "banned" -> {
      use value <- decode.then(chat_member_banned_decoder())
      decode.success(ChatMemberBannedChatMember(value))
    }
    _ -> panic as "Invalid variant for ChatMember"
  }
}

pub fn reaction_type_decoder() -> decode.Decoder(ReactionType) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "emoji" -> {
      use value <- decode.then(reaction_type_emoji_decoder())
      decode.success(ReactionTypeEmojiReactionType(value))
    }
    "custom_emoji" -> {
      use value <- decode.then(reaction_type_custom_emoji_decoder())
      decode.success(ReactionTypeCustomEmojiReactionType(value))
    }
    "paid" -> {
      use value <- decode.then(reaction_type_paid_decoder())
      decode.success(ReactionTypePaidReactionType(value))
    }
    _ -> panic as "Invalid variant for ReactionType"
  }
}

pub fn bot_command_scope_decoder() -> decode.Decoder(BotCommandScope) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "default" -> {
      use value <- decode.then(bot_command_scope_default_decoder())
      decode.success(BotCommandScopeDefaultBotCommandScope(value))
    }
    "all_private_chats" -> {
      use value <- decode.then(bot_command_scope_all_private_chats_decoder())
      decode.success(BotCommandScopeAllPrivateChatsBotCommandScope(value))
    }
    "all_group_chats" -> {
      use value <- decode.then(bot_command_scope_all_group_chats_decoder())
      decode.success(BotCommandScopeAllGroupChatsBotCommandScope(value))
    }
    "all_chat_administrators" -> {
      use value <- decode.then(
        bot_command_scope_all_chat_administrators_decoder(),
      )
      decode.success(BotCommandScopeAllChatAdministratorsBotCommandScope(value))
    }
    "chat" -> {
      use value <- decode.then(bot_command_scope_chat_decoder())
      decode.success(BotCommandScopeChatBotCommandScope(value))
    }
    "chat_administrators" -> {
      use value <- decode.then(bot_command_scope_chat_administrators_decoder())
      decode.success(BotCommandScopeChatAdministratorsBotCommandScope(value))
    }
    "chat_member" -> {
      use value <- decode.then(bot_command_scope_chat_member_decoder())
      decode.success(BotCommandScopeChatMemberBotCommandScope(value))
    }
    _ -> panic as "Invalid variant for BotCommandScope"
  }
}

pub fn menu_button_decoder() -> decode.Decoder(MenuButton) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "commands" -> {
      use value <- decode.then(menu_button_commands_decoder())
      decode.success(MenuButtonCommandsMenuButton(value))
    }
    "web_app" -> {
      use value <- decode.then(menu_button_web_app_decoder())
      decode.success(MenuButtonWebAppMenuButton(value))
    }
    "default" -> {
      use value <- decode.then(menu_button_default_decoder())
      decode.success(MenuButtonDefaultMenuButton(value))
    }
    _ -> panic as "Invalid variant for MenuButton"
  }
}

pub fn chat_boost_source_decoder() -> decode.Decoder(ChatBoostSource) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "premium" -> {
      use value <- decode.then(chat_boost_source_premium_decoder())
      decode.success(ChatBoostSourcePremiumChatBoostSource(value))
    }
    "gift_code" -> {
      use value <- decode.then(chat_boost_source_gift_code_decoder())
      decode.success(ChatBoostSourceGiftCodeChatBoostSource(value))
    }
    "giveaway" -> {
      use value <- decode.then(chat_boost_source_giveaway_decoder())
      decode.success(ChatBoostSourceGiveawayChatBoostSource(value))
    }
    _ -> panic as "Invalid variant for ChatBoostSource"
  }
}

pub fn input_media_decoder() -> decode.Decoder(InputMedia) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "animation" -> {
      use value <- decode.then(input_media_animation_decoder())
      decode.success(InputMediaAnimationInputMedia(value))
    }
    "document" -> {
      use value <- decode.then(input_media_document_decoder())
      decode.success(InputMediaDocumentInputMedia(value))
    }
    "audio" -> {
      use value <- decode.then(input_media_audio_decoder())
      decode.success(InputMediaAudioInputMedia(value))
    }
    "photo" -> {
      use value <- decode.then(input_media_photo_decoder())
      decode.success(InputMediaPhotoInputMedia(value))
    }
    "video" -> {
      use value <- decode.then(input_media_video_decoder())
      decode.success(InputMediaVideoInputMedia(value))
    }
    _ -> panic as "Invalid variant for InputMedia"
  }
}

pub fn input_paid_media_decoder() -> decode.Decoder(InputPaidMedia) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "photo" -> {
      use value <- decode.then(input_paid_media_photo_decoder())
      decode.success(InputPaidMediaPhotoInputPaidMedia(value))
    }
    "video" -> {
      use value <- decode.then(input_paid_media_video_decoder())
      decode.success(InputPaidMediaVideoInputPaidMedia(value))
    }
    _ -> panic as "Invalid variant for InputPaidMedia"
  }
}

pub fn inline_query_result_decoder() -> decode.Decoder(InlineQueryResult) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "audio" -> {
      decode.one_of(
        {
          use value <- decode.then(inline_query_result_cached_audio_decoder())
          decode.success(InlineQueryResultCachedAudioInlineQueryResult(value))
        },
        or: [
          {
            use value <- decode.then(inline_query_result_cached_audio_decoder())
            decode.success(InlineQueryResultCachedAudioInlineQueryResult(value))
          },
        ],
      )
    }
    "document" -> {
      decode.one_of(
        {
          use value <- decode.then(inline_query_result_document_decoder())
          decode.success(InlineQueryResultDocumentInlineQueryResult(value))
        },
        or: [
          {
            use value <- decode.then(
              inline_query_result_cached_document_decoder(),
            )
            decode.success(InlineQueryResultCachedDocumentInlineQueryResult(
              value,
            ))
          },
        ],
      )
    }
    "gif" -> {
      decode.one_of(
        {
          use value <- decode.then(inline_query_result_gif_decoder())
          decode.success(InlineQueryResultGifInlineQueryResult(value))
        },
        or: [
          {
            use value <- decode.then(inline_query_result_cached_gif_decoder())
            decode.success(InlineQueryResultCachedGifInlineQueryResult(value))
          },
        ],
      )
    }
    "mpeg4_gif" -> {
      decode.one_of(
        {
          use value <- decode.then(inline_query_result_mpeg4_gif_decoder())
          decode.success(InlineQueryResultMpeg4GifInlineQueryResult(value))
        },
        or: [
          {
            use value <- decode.then(
              inline_query_result_cached_mpeg4_gif_decoder(),
            )
            decode.success(InlineQueryResultCachedMpeg4GifInlineQueryResult(
              value,
            ))
          },
        ],
      )
    }
    "photo" -> {
      decode.one_of(
        {
          use value <- decode.then(inline_query_result_photo_decoder())
          decode.success(InlineQueryResultPhotoInlineQueryResult(value))
        },
        or: [
          {
            use value <- decode.then(inline_query_result_cached_photo_decoder())
            decode.success(InlineQueryResultCachedPhotoInlineQueryResult(value))
          },
        ],
      )
    }
    "video" -> {
      decode.one_of(
        {
          use value <- decode.then(inline_query_result_video_decoder())
          decode.success(InlineQueryResultVideoInlineQueryResult(value))
        },
        or: [
          {
            use value <- decode.then(inline_query_result_cached_video_decoder())
            decode.success(InlineQueryResultCachedVideoInlineQueryResult(value))
          },
        ],
      )
    }
    "voice" -> {
      decode.one_of(
        {
          use value <- decode.then(inline_query_result_voice_decoder())
          decode.success(InlineQueryResultVoiceInlineQueryResult(value))
        },
        or: [
          {
            use value <- decode.then(inline_query_result_cached_voice_decoder())
            decode.success(InlineQueryResultCachedVoiceInlineQueryResult(value))
          },
        ],
      )
    }
    "sticker" -> {
      use value <- decode.then(inline_query_result_cached_sticker_decoder())
      decode.success(InlineQueryResultCachedStickerInlineQueryResult(value))
    }
    "article" -> {
      use value <- decode.then(inline_query_result_article_decoder())
      decode.success(InlineQueryResultArticleInlineQueryResult(value))
    }
    "contact" -> {
      use value <- decode.then(inline_query_result_contact_decoder())
      decode.success(InlineQueryResultContactInlineQueryResult(value))
    }
    "game" -> {
      use value <- decode.then(inline_query_result_game_decoder())
      decode.success(InlineQueryResultGameInlineQueryResult(value))
    }
    "location" -> {
      use value <- decode.then(inline_query_result_location_decoder())
      decode.success(InlineQueryResultLocationInlineQueryResult(value))
    }
    "venue" -> {
      use value <- decode.then(inline_query_result_venue_decoder())
      decode.success(InlineQueryResultVenueInlineQueryResult(value))
    }

    _ -> panic as "Invalid variant for InlineQueryResult"
  }
}

pub fn input_message_content_decoder() -> decode.Decoder(InputMessageContent) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "input_text_message_content" -> {
      use value <- decode.then(input_text_message_content_decoder())
      decode.success(InputTextMessageContentInputMessageContent(value))
    }
    "input_location_message_content" -> {
      use value <- decode.then(input_location_message_content_decoder())
      decode.success(InputLocationMessageContentInputMessageContent(value))
    }
    "input_venue_message_content" -> {
      use value <- decode.then(input_venue_message_content_decoder())
      decode.success(InputVenueMessageContentInputMessageContent(value))
    }
    "input_contact_message_content" -> {
      use value <- decode.then(input_contact_message_content_decoder())
      decode.success(InputContactMessageContentInputMessageContent(value))
    }
    "input_invoice_message_content" -> {
      use value <- decode.then(input_invoice_message_content_decoder())
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
    "pending" -> {
      use value <- decode.then(revenue_withdrawal_state_pending_decoder())
      decode.success(RevenueWithdrawalStatePendingRevenueWithdrawalState(value))
    }
    "succeeded" -> {
      use value <- decode.then(revenue_withdrawal_state_succeeded_decoder())
      decode.success(RevenueWithdrawalStateSucceededRevenueWithdrawalState(
        value,
      ))
    }
    "failed" -> {
      use value <- decode.then(revenue_withdrawal_state_failed_decoder())
      decode.success(RevenueWithdrawalStateFailedRevenueWithdrawalState(value))
    }
    _ -> panic as "Invalid variant for RevenueWithdrawalState"
  }
}

pub fn transaction_partner_decoder() -> decode.Decoder(TransactionPartner) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "user" -> {
      use value <- decode.then(transaction_partner_user_decoder())
      decode.success(TransactionPartnerUserTransactionPartner(value))
    }
    "chat" -> {
      use value <- decode.then(transaction_partner_chat_decoder())
      decode.success(TransactionPartnerChatTransactionPartner(value))
    }
    "affiliate_program" -> {
      use value <- decode.then(transaction_partner_affiliate_program_decoder())
      decode.success(TransactionPartnerAffiliateProgramTransactionPartner(value))
    }
    "fragment" -> {
      use value <- decode.then(transaction_partner_fragment_decoder())
      decode.success(TransactionPartnerFragmentTransactionPartner(value))
    }
    "telegram_ads" -> {
      use value <- decode.then(transaction_partner_telegram_ads_decoder())
      decode.success(TransactionPartnerTelegramAdsTransactionPartner(value))
    }
    "telegram_api" -> {
      use value <- decode.then(transaction_partner_telegram_api_decoder())
      decode.success(TransactionPartnerTelegramApiTransactionPartner(value))
    }
    "other" -> {
      use value <- decode.then(transaction_partner_other_decoder())
      decode.success(TransactionPartnerOtherTransactionPartner(value))
    }
    _ -> panic as "Invalid variant for TransactionPartner"
  }
}

pub fn passport_element_error_decoder() -> decode.Decoder(PassportElementError) {
  use variant <- decode.field("sourse", decode.string)
  case variant {
    "data" -> {
      use value <- decode.then(passport_element_error_data_field_decoder())
      decode.success(PassportElementErrorDataFieldPassportElementError(value))
    }
    "front_side" -> {
      use value <- decode.then(passport_element_error_front_side_decoder())
      decode.success(PassportElementErrorFrontSidePassportElementError(value))
    }
    "reverse_side" -> {
      use value <- decode.then(passport_element_error_reverse_side_decoder())
      decode.success(PassportElementErrorReverseSidePassportElementError(value))
    }
    "selfie" -> {
      use value <- decode.then(passport_element_error_selfie_decoder())
      decode.success(PassportElementErrorSelfiePassportElementError(value))
    }
    "file" -> {
      use value <- decode.then(passport_element_error_file_decoder())
      decode.success(PassportElementErrorFilePassportElementError(value))
    }
    "files" -> {
      use value <- decode.then(passport_element_error_files_decoder())
      decode.success(PassportElementErrorFilesPassportElementError(value))
    }
    "translation_file" -> {
      use value <- decode.then(
        passport_element_error_translation_file_decoder(),
      )
      decode.success(PassportElementErrorTranslationFilePassportElementError(
        value,
      ))
    }
    "translation_files" -> {
      use value <- decode.then(
        passport_element_error_translation_files_decoder(),
      )
      decode.success(PassportElementErrorTranslationFilesPassportElementError(
        value,
      ))
    }
    "unspecified" -> {
      use value <- decode.then(passport_element_error_unspecified_decoder())
      decode.success(PassportElementErrorUnspecifiedPassportElementError(value))
    }
    _ -> panic as "Invalid variant for PassportElementError"
  }
}

pub fn encode_maybe_inaccessible_message(
  value: MaybeInaccessibleMessage,
) -> Json {
  case value {
    MessageMaybeInaccessibleMessage(inner_value) -> encode_message(inner_value)

    InaccessibleMessageMaybeInaccessibleMessage(inner_value) ->
      encode_inaccessible_message(inner_value)
  }
}

pub fn encode_message_origin(value: MessageOrigin) -> Json {
  case value {
    MessageOriginUserMessageOrigin(inner_value) ->
      encode_message_origin_user(inner_value)

    MessageOriginHiddenUserMessageOrigin(inner_value) ->
      encode_message_origin_hidden_user(inner_value)

    MessageOriginChatMessageOrigin(inner_value) ->
      encode_message_origin_chat(inner_value)

    MessageOriginChannelMessageOrigin(inner_value) ->
      encode_message_origin_channel(inner_value)
  }
}

pub fn encode_paid_media(value: PaidMedia) -> Json {
  case value {
    PaidMediaPreviewPaidMedia(inner_value) ->
      encode_paid_media_preview(inner_value)

    PaidMediaPhotoPaidMedia(inner_value) -> encode_paid_media_photo(inner_value)

    PaidMediaVideoPaidMedia(inner_value) -> encode_paid_media_video(inner_value)
  }
}

pub fn encode_background_fill(value: BackgroundFill) -> Json {
  case value {
    BackgroundFillSolidBackgroundFill(inner_value) ->
      encode_background_fill_solid(inner_value)

    BackgroundFillGradientBackgroundFill(inner_value) ->
      encode_background_fill_gradient(inner_value)

    BackgroundFillFreeformGradientBackgroundFill(inner_value) ->
      encode_background_fill_freeform_gradient(inner_value)
  }
}

pub fn encode_background_type(value: BackgroundType) -> Json {
  case value {
    BackgroundTypeFillBackgroundType(inner_value) ->
      encode_background_type_fill(inner_value)

    BackgroundTypeWallpaperBackgroundType(inner_value) ->
      encode_background_type_wallpaper(inner_value)

    BackgroundTypePatternBackgroundType(inner_value) ->
      encode_background_type_pattern(inner_value)

    BackgroundTypeChatThemeBackgroundType(inner_value) ->
      encode_background_type_chat_theme(inner_value)
  }
}

pub fn encode_chat_member(value: ChatMember) -> Json {
  case value {
    ChatMemberOwnerChatMember(inner_value) ->
      encode_chat_member_owner(inner_value)

    ChatMemberAdministratorChatMember(inner_value) ->
      encode_chat_member_administrator(inner_value)

    ChatMemberMemberChatMember(inner_value) ->
      encode_chat_member_member(inner_value)

    ChatMemberRestrictedChatMember(inner_value) ->
      encode_chat_member_restricted(inner_value)

    ChatMemberLeftChatMember(inner_value) ->
      encode_chat_member_left(inner_value)

    ChatMemberBannedChatMember(inner_value) ->
      encode_chat_member_banned(inner_value)
  }
}

pub fn encode_reaction_type(value: ReactionType) -> Json {
  case value {
    ReactionTypeEmojiReactionType(inner_value) ->
      encode_reaction_type_emoji(inner_value)

    ReactionTypeCustomEmojiReactionType(inner_value) ->
      encode_reaction_type_custom_emoji(inner_value)

    ReactionTypePaidReactionType(inner_value) ->
      encode_reaction_type_paid(inner_value)
  }
}

pub fn encode_bot_command_scope(value: BotCommandScope) -> Json {
  case value {
    BotCommandScopeDefaultBotCommandScope(inner_value) ->
      encode_bot_command_scope_default(inner_value)

    BotCommandScopeAllPrivateChatsBotCommandScope(inner_value) ->
      encode_bot_command_scope_all_private_chats(inner_value)

    BotCommandScopeAllGroupChatsBotCommandScope(inner_value) ->
      encode_bot_command_scope_all_group_chats(inner_value)

    BotCommandScopeAllChatAdministratorsBotCommandScope(inner_value) ->
      encode_bot_command_scope_all_chat_administrators(inner_value)

    BotCommandScopeChatBotCommandScope(inner_value) ->
      encode_bot_command_scope_chat(inner_value)

    BotCommandScopeChatAdministratorsBotCommandScope(inner_value) ->
      encode_bot_command_scope_chat_administrators(inner_value)

    BotCommandScopeChatMemberBotCommandScope(inner_value) ->
      encode_bot_command_scope_chat_member(inner_value)
  }
}

pub fn encode_menu_button(value: MenuButton) -> Json {
  case value {
    MenuButtonCommandsMenuButton(inner_value) ->
      encode_menu_button_commands(inner_value)

    MenuButtonWebAppMenuButton(inner_value) ->
      encode_menu_button_web_app(inner_value)

    MenuButtonDefaultMenuButton(inner_value) ->
      encode_menu_button_default(inner_value)
  }
}

pub fn encode_chat_boost_source(value: ChatBoostSource) -> Json {
  case value {
    ChatBoostSourcePremiumChatBoostSource(inner_value) ->
      encode_chat_boost_source_premium(inner_value)

    ChatBoostSourceGiftCodeChatBoostSource(inner_value) ->
      encode_chat_boost_source_gift_code(inner_value)

    ChatBoostSourceGiveawayChatBoostSource(inner_value) ->
      encode_chat_boost_source_giveaway(inner_value)
  }
}

pub fn encode_input_media(value: InputMedia) -> Json {
  case value {
    InputMediaAnimationInputMedia(inner_value) ->
      encode_input_media_animation(inner_value)

    InputMediaDocumentInputMedia(inner_value) ->
      encode_input_media_document(inner_value)

    InputMediaAudioInputMedia(inner_value) ->
      encode_input_media_audio(inner_value)

    InputMediaPhotoInputMedia(inner_value) ->
      encode_input_media_photo(inner_value)

    InputMediaVideoInputMedia(inner_value) ->
      encode_input_media_video(inner_value)
  }
}

pub fn encode_input_paid_media(value: InputPaidMedia) -> Json {
  case value {
    InputPaidMediaPhotoInputPaidMedia(inner_value) ->
      encode_input_paid_media_photo(inner_value)

    InputPaidMediaVideoInputPaidMedia(inner_value) ->
      encode_input_paid_media_video(inner_value)
  }
}

pub fn encode_inline_query_result(value: InlineQueryResult) -> Json {
  case value {
    InlineQueryResultCachedAudioInlineQueryResult(inner_value) ->
      encode_inline_query_result_cached_audio(inner_value)

    InlineQueryResultCachedDocumentInlineQueryResult(inner_value) ->
      encode_inline_query_result_cached_document(inner_value)

    InlineQueryResultCachedGifInlineQueryResult(inner_value) ->
      encode_inline_query_result_cached_gif(inner_value)

    InlineQueryResultCachedMpeg4GifInlineQueryResult(inner_value) ->
      encode_inline_query_result_cached_mpeg4_gif(inner_value)

    InlineQueryResultCachedPhotoInlineQueryResult(inner_value) ->
      encode_inline_query_result_cached_photo(inner_value)

    InlineQueryResultCachedStickerInlineQueryResult(inner_value) ->
      encode_inline_query_result_cached_sticker(inner_value)

    InlineQueryResultCachedVideoInlineQueryResult(inner_value) ->
      encode_inline_query_result_cached_video(inner_value)

    InlineQueryResultCachedVoiceInlineQueryResult(inner_value) ->
      encode_inline_query_result_cached_voice(inner_value)

    InlineQueryResultArticleInlineQueryResult(inner_value) ->
      encode_inline_query_result_article(inner_value)

    InlineQueryResultAudioInlineQueryResult(inner_value) ->
      encode_inline_query_result_audio(inner_value)

    InlineQueryResultContactInlineQueryResult(inner_value) ->
      encode_inline_query_result_contact(inner_value)

    InlineQueryResultGameInlineQueryResult(inner_value) ->
      encode_inline_query_result_game(inner_value)

    InlineQueryResultDocumentInlineQueryResult(inner_value) ->
      encode_inline_query_result_document(inner_value)

    InlineQueryResultGifInlineQueryResult(inner_value) ->
      encode_inline_query_result_gif(inner_value)

    InlineQueryResultLocationInlineQueryResult(inner_value) ->
      encode_inline_query_result_location(inner_value)

    InlineQueryResultMpeg4GifInlineQueryResult(inner_value) ->
      encode_inline_query_result_mpeg4_gif(inner_value)

    InlineQueryResultPhotoInlineQueryResult(inner_value) ->
      encode_inline_query_result_photo(inner_value)

    InlineQueryResultVenueInlineQueryResult(inner_value) ->
      encode_inline_query_result_venue(inner_value)

    InlineQueryResultVideoInlineQueryResult(inner_value) ->
      encode_inline_query_result_video(inner_value)

    InlineQueryResultVoiceInlineQueryResult(inner_value) ->
      encode_inline_query_result_voice(inner_value)
  }
}

pub fn encode_input_message_content(value: InputMessageContent) -> Json {
  case value {
    InputTextMessageContentInputMessageContent(inner_value) ->
      encode_input_text_message_content(inner_value)

    InputLocationMessageContentInputMessageContent(inner_value) ->
      encode_input_location_message_content(inner_value)

    InputVenueMessageContentInputMessageContent(inner_value) ->
      encode_input_venue_message_content(inner_value)

    InputContactMessageContentInputMessageContent(inner_value) ->
      encode_input_contact_message_content(inner_value)

    InputInvoiceMessageContentInputMessageContent(inner_value) ->
      encode_input_invoice_message_content(inner_value)
  }
}

pub fn encode_revenue_withdrawal_state(value: RevenueWithdrawalState) -> Json {
  case value {
    RevenueWithdrawalStatePendingRevenueWithdrawalState(inner_value) ->
      encode_revenue_withdrawal_state_pending(inner_value)

    RevenueWithdrawalStateSucceededRevenueWithdrawalState(inner_value) ->
      encode_revenue_withdrawal_state_succeeded(inner_value)

    RevenueWithdrawalStateFailedRevenueWithdrawalState(inner_value) ->
      encode_revenue_withdrawal_state_failed(inner_value)
  }
}

pub fn encode_transaction_partner(value: TransactionPartner) -> Json {
  case value {
    TransactionPartnerUserTransactionPartner(inner_value) ->
      encode_transaction_partner_user(inner_value)

    TransactionPartnerChatTransactionPartner(inner_value) ->
      encode_transaction_partner_chat(inner_value)

    TransactionPartnerAffiliateProgramTransactionPartner(inner_value) ->
      encode_transaction_partner_affiliate_program(inner_value)

    TransactionPartnerFragmentTransactionPartner(inner_value) ->
      encode_transaction_partner_fragment(inner_value)

    TransactionPartnerTelegramAdsTransactionPartner(inner_value) ->
      encode_transaction_partner_telegram_ads(inner_value)

    TransactionPartnerTelegramApiTransactionPartner(inner_value) ->
      encode_transaction_partner_telegram_api(inner_value)

    TransactionPartnerOtherTransactionPartner(inner_value) ->
      encode_transaction_partner_other(inner_value)
  }
}

pub fn encode_passport_element_error(value: PassportElementError) -> Json {
  case value {
    PassportElementErrorDataFieldPassportElementError(inner_value) ->
      encode_passport_element_error_data_field(inner_value)

    PassportElementErrorFrontSidePassportElementError(inner_value) ->
      encode_passport_element_error_front_side(inner_value)

    PassportElementErrorReverseSidePassportElementError(inner_value) ->
      encode_passport_element_error_reverse_side(inner_value)

    PassportElementErrorSelfiePassportElementError(inner_value) ->
      encode_passport_element_error_selfie(inner_value)

    PassportElementErrorFilePassportElementError(inner_value) ->
      encode_passport_element_error_file(inner_value)

    PassportElementErrorFilesPassportElementError(inner_value) ->
      encode_passport_element_error_files(inner_value)

    PassportElementErrorTranslationFilePassportElementError(inner_value) ->
      encode_passport_element_error_translation_file(inner_value)

    PassportElementErrorTranslationFilesPassportElementError(inner_value) ->
      encode_passport_element_error_translation_files(inner_value)

    PassportElementErrorUnspecifiedPassportElementError(inner_value) ->
      encode_passport_element_error_unspecified(inner_value)
  }
}

pub type FileOrString {
  FileV(value: File)
  StringV(string: String)
}

pub fn file_or_string_decoder() -> decode.Decoder(FileOrString) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "file_v" -> {
      use value <- decode.then(file_decoder())
      decode.success(FileV(value:))
    }
    "string" -> {
      use string <- decode.then(decode.string)
      decode.success(StringV(string:))
    }
    _ -> decode.failure(StringV(""), "FileOrString")
  }
}

pub fn encode_file_or_string(value: FileOrString) -> Json {
  case value {
    FileV(value) -> encode_file(value)
    StringV(string) -> json.string(string)
  }
}

// AnswerCallbackQueryParameters --------------------------------------------------------------------------------------
// https://core.telegram.org/bots/api#answercallbackquery
pub type AnswerCallbackQueryParameters {
  AnswerCallbackQueryParameters(
    /// Unique identifier for the query to be answered
    callback_query_id: String,
    /// Text of the notification. If not specified, nothing will be shown to the user
    text: Option(String),
    /// If true, an alert will be shown by the client instead of a notification at the top of the chat screen. Defaults to false.
    show_alert: Option(Bool),
    /// URL that will be opened by the user's client. If you have created a [Game](https://core.telegram.org/bots/api#games), you can use this
    /// field to redirect the player to your game
    url: Option(String),
    /// The maximum amount of time in seconds that the result of the callback query may be cached client-side. Telegram apps will support
    /// caching starting in version 3.14. Defaults to 0.
    cache_time: Option(Int),
  )
}

pub fn new_answer_callback_query_parameters(
  callback_query_id: String,
) -> AnswerCallbackQueryParameters {
  AnswerCallbackQueryParameters(
    callback_query_id: callback_query_id,
    text: None,
    show_alert: None,
    url: None,
    cache_time: None,
  )
}

pub fn encode_answer_callback_query_parameters(
  params: AnswerCallbackQueryParameters,
) -> Json {
  let callback_query_id = #(
    "callback_query_id",
    json.string(params.callback_query_id),
  )
  let text = #("text", json.nullable(params.text, json.string))
  let show_alert = #("show_alert", json.nullable(params.show_alert, json.bool))
  let url = #("url", json.nullable(params.url, json.string))
  let cache_time = #("cache_time", json.nullable(params.cache_time, json.int))

  json_object_filter_nulls([
    callback_query_id,
    text,
    show_alert,
    url,
    cache_time,
  ])
}

// BotCommandParameters ---------------------------------------------------------------------

pub type BotCommandParameters {
  BotCommandParameters(
    /// An object, describing scope of users for which the commands are relevant. Defaults to `BotCommandScopeDefault`.
    scope: Option(BotCommandScope),
    /// A two-letter ISO 639-1 language code. If empty, commands will be applied to all users from the given scope, for whose language there are no dedicated commands
    language_code: Option(String),
  )
}

pub fn default_bot_command_parameters() -> BotCommandParameters {
  BotCommandParameters(scope: None, language_code: None)
}

pub fn encode_bot_command_parameters(
  params: BotCommandParameters,
) -> List(#(String, Json)) {
  [
    #("scope", json.nullable(params.scope, bot_command_scope_to_json)),
    #("language_code", json.nullable(params.language_code, json.string)),
  ]
}

pub fn bot_command_scope_to_json(scope: BotCommandScope) {
  case scope {
    BotCommandScopeDefaultBotCommandScope(_) ->
      json_object_filter_nulls([#("type", json.string("default"))])
    BotCommandScopeAllPrivateChatsBotCommandScope(_) ->
      json_object_filter_nulls([#("type", json.string("all_private_chats"))])
    BotCommandScopeAllGroupChatsBotCommandScope(_) ->
      json_object_filter_nulls([#("type", json.string("all_group_chats"))])
    BotCommandScopeAllChatAdministratorsBotCommandScope(_) ->
      json_object_filter_nulls([
        #("type", json.string("all_chat_administrators")),
      ])
    BotCommandScopeChatBotCommandScope(BotCommandScopeChat(
      chat_id: chat_id,
      ..,
    )) ->
      json_object_filter_nulls([
        #("type", json.string("chat")),
        #("chat_id", encode_int_or_string(chat_id)),
      ])
    BotCommandScopeChatAdministratorsBotCommandScope(BotCommandScopeChatAdministrators(
      chat_id: chat_id,
      ..,
    )) ->
      json_object_filter_nulls([
        #("type", json.string("chat_administrators")),
        #("chat_id", encode_int_or_string(chat_id)),
      ])
    BotCommandScopeChatMemberBotCommandScope(BotCommandScopeChatMember(
      chat_id: chat_id,
      user_id: user_id,
      ..,
    )) ->
      json_object_filter_nulls([
        #("type", json.string("chat_member")),
        #("chat_id", encode_int_or_string(chat_id)),
        #("user_id", json.int(user_id)),
      ])
  }
}

pub fn bot_commands_from(commands: List(#(String, String))) -> List(BotCommand) {
  commands
  |> list.map(fn(command) {
    let #(command, description) = command
    BotCommand(command: command, description: description)
  })
}

// EditMessageTextParameters ------------------------------------------------------------------------------------------

pub type EditMessageTextParameters {
  EditMessageTextParameters(
    /// Required if _inline_message_id_ is not specified.
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: Option(IntOrString),
    /// Required if inline_message_id is not specified. Identifier of the message to edit
    message_id: Option(Int),
    /// Required if _chat_id_ and _message_id_ are not specified. Identifier of the inline message
    inline_message_id: Option(String),
    /// New text of the message, 1-4096 characters after entities parsing
    text: String,
    /// Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api#formatting-options) for more details.
    parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in message text, which can be specified instead of _parse_mode_
    entities: Option(List(MessageEntity)),
    /// Link preview generation options for the message
    link_preview_options: Option(LinkPreviewOptions),
    /// A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards).
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn encode_edit_message_text_parameters(
  params: EditMessageTextParameters,
) -> Json {
  let chat_id = #(
    "chat_id",
    json.nullable(params.chat_id, encode_int_or_string),
  )
  let message_id = #("message_id", json.nullable(params.message_id, json.int))
  let inline_message_id = #(
    "inline_message_id",
    json.nullable(params.inline_message_id, json.string),
  )
  let text = #("text", json.string(params.text))
  let parse_mode = #(
    "parse_mode",
    json.nullable(params.parse_mode, json.string),
  )
  let entities = #(
    "entities",
    json.nullable(params.entities, json.array(_, encode_message_entity)),
  )
  let link_preview_options = #(
    "link_preview_options",
    json.nullable(params.link_preview_options, encode_link_preview_options),
  )
  let reply_markup = #(
    "reply_markup",
    json.nullable(params.reply_markup, encode_inline_keyboard_markup),
  )

  json_object_filter_nulls([
    chat_id,
    message_id,
    inline_message_id,
    text,
    parse_mode,
    entities,
    link_preview_options,
    reply_markup,
  ])
}

// ForwardMessageParameters -------------------------------------------------------------------------------------------
/// https://core.telegram.org/bots/api#forwardmessage
pub type ForwardMessageParameters {
  ForwardMessageParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier for the chat where the original message was sent (or channel username in the format `@channelusername`)
    from_chat_id: IntOrString,
    /// Message identifier in the chat specified in _from_chat_id_
    message_id: Int,
    /// Sends the message silently. Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Protects the contents of the forwarded message from forwarding and saving
    protect_content: Option(Bool),
  )
}

pub fn encode_forward_message_parameters(
  params: ForwardMessageParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("from_chat_id", encode_int_or_string(params.from_chat_id)),
    #("message_id", json.int(params.message_id)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
  ])
}

// ForwardMessagesParameters -----------------------------------------------------------------------------------------------------
/// https://core.telegram.org/bots/api#forwardmessages
pub type ForwardMessagesParameters {
  ForwardMessagesParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Unique identifier for the chat where the original messages were sent (or channel username in the format `@channelusername`)
    from_chat_id: IntOrString,
    /// A JSON-serialized list of 1-100 identifiers of messages in the chat _from_chat_id_ to forward. The identifiers must be specified in a strictly increasing order.
    message_ids: List(Int),
    /// Sends the messages [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Protects the contents of the forwarded messages from forwarding and saving
    protect_content: Option(Bool),
  )
}

pub fn encode_forward_messages_parameters(
  forward_messages_parameters: ForwardMessagesParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(forward_messages_parameters.chat_id)),
    #(
      "message_thread_id",
      json.nullable(forward_messages_parameters.message_thread_id, json.int),
    ),
    #(
      "from_chat_id",
      encode_int_or_string(forward_messages_parameters.from_chat_id),
    ),
    #(
      "message_ids",
      json.array(forward_messages_parameters.message_ids, json.int),
    ),
    #(
      "disable_notification",
      json.nullable(forward_messages_parameters.disable_notification, json.bool),
    ),
    #(
      "protect_content",
      json.nullable(forward_messages_parameters.protect_content, json.bool),
    ),
  ])
}

// SendDiceParameters ------------------------------------------------------------------------------------------------------------

pub type SendDiceParameters {
  SendDiceParameters(
    chat_id: IntOrString,
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Emoji on which the dice throw animation is based. Currently, must be one of "🎲", "🎯", "🏀", "⚽", "🎳", or "🎰". Dice can have values 1-6 for "🎲", "🎯" and "🎳", values 1-5 for "🏀" and "⚽", and values 1-64 for "🎰". Defaults to "🎲"
    emoji: Option(String),
    /// Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Protects the contents of the sent message from forwarding
    protect_content: Option(Bool),
    /// Description of the message to reply to
    reply_parameters: Option(ReplyKeyboardMarkup),
  )
}

pub fn encode_send_dice_parameters(params: SendDiceParameters) -> Json {
  let chat_id = #("chat_id", encode_int_or_string(params.chat_id))
  let message_thread_id = #(
    "message_thread_id",
    json.nullable(params.message_thread_id, json.int),
  )
  let emoji = #("emoji", json.nullable(params.emoji, json.string))
  let disable_notification = #(
    "disable_notification",
    json.nullable(params.disable_notification, json.bool),
  )
  let protect_content = #(
    "protect_content",
    json.nullable(params.protect_content, json.bool),
  )
  let reply_parameters = #(
    "reply_parameters",
    json.nullable(params.reply_parameters, encode_reply_keyboard_markup),
  )

  json_object_filter_nulls([
    chat_id,
    message_thread_id,
    emoji,
    disable_notification,
    protect_content,
    reply_parameters,
  ])
}

// SendMessage ------------------------------------------------------------------------

pub type SendMessageReplyMarkupParameters {
  SendMessageReplyInlineKeyboardMarkupParameters(InlineKeyboardMarkup)
  SendMessageReplyReplyKeyboardMarkupParameters(ReplyKeyboardMarkup)
  SendMessageReplyRemoveKeyboardMarkupParameters(ReplyKeyboardRemove)
  SendMessageReplyForceReplyMarkupParameters(ForceReply)
}

pub fn encode_send_message_reply_markup_parameters(
  params: SendMessageReplyMarkupParameters,
) -> Json {
  case params {
    SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) ->
      encode_inline_keyboard_markup(inline_keyboard)
    SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) ->
      encode_reply_keyboard_markup(reply_keyboard)
    SendMessageReplyRemoveKeyboardMarkupParameters(remove_keyboard) ->
      encode_reply_keyboard_remove(remove_keyboard)
    SendMessageReplyForceReplyMarkupParameters(force_reply) ->
      encode_force_reply(force_reply)
  }
}

pub type SendMessageParameters {
  /// Parameters to send using the [sendMessage](https://core.telegram.org/bots/api#sendmessage) method
  SendMessageParameters(
    /// Unique identifier of the business connection on behalf of which the message will be sent
    business_connection_id: Option(String),
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Text of the message to be sent, 1-4096 characters after entities parsing
    text: String,
    /// Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api#formatting-options) for more details.
    parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in message text, which can be specified instead of _parse_mode_
    entities: Option(List(MessageEntity)),
    /// Link preview generation options for the message
    link_preview_options: Option(LinkPreviewOptions),
    /// Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Protects the contents of the sent message from forwarding and saving
    protect_content: Option(Bool),
    /// Pass True to allow up to 1000 messages per second, ignoring [broadcasting limits](https://core.telegram.org/bots/faq#how-can-i-message-all-of-my-bot-39s-subscribers-at-once) for a fee of 0.1 Telegram Stars per message. The relevant Stars will be withdrawn from the bot's balance
    allow_paid_broadcast: Option(Bool),
    /// Unique identifier of the message effect to be added to the message; for private chats only
    message_effect_id: Option(String),
    /// Description of the message to reply to
    reply_parameters: Option(ReplyParameters),
    /// Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards), [custom reply keyboard](https://core.telegram.org/bots/features#keyboards), instructions to remove a reply keyboard or to force a reply from the user. Not supported for messages sent on behalf of a business account
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_message_parameters(
  send_message_parameters: SendMessageParameters,
) -> Json {
  let business_connection_id = #(
    "business_connection_id",
    json.nullable(send_message_parameters.business_connection_id, json.string),
  )
  let chat_id = #(
    "chat_id",
    encode_int_or_string(send_message_parameters.chat_id),
  )

  let message_thread_id = #(
    "message_thread_id",
    json.nullable(send_message_parameters.message_thread_id, json.int),
  )
  let text = #("text", json.string(send_message_parameters.text))
  let parse_mode = #(
    "parse_mode",
    json.nullable(send_message_parameters.parse_mode, json.string),
  )
  let entities = #(
    "entities",
    json.nullable(send_message_parameters.entities, json.array(
      _,
      encode_message_entity,
    )),
  )
  let link_preview_options = #(
    "link_preview_options",
    json.nullable(
      send_message_parameters.link_preview_options,
      encode_link_preview_options,
    ),
  )
  let disable_notification = #(
    "disable_notification",
    json.nullable(send_message_parameters.disable_notification, json.bool),
  )
  let protect_content = #(
    "protect_content",
    json.nullable(send_message_parameters.protect_content, json.bool),
  )
  let reply_parameters = #(
    "reply_parameters",
    json.nullable(
      send_message_parameters.reply_parameters,
      encode_reply_parameters,
    ),
  )
  let reply_markup = #(
    "reply_markup",
    json.nullable(
      send_message_parameters.reply_markup,
      encode_send_message_reply_markup_parameters,
    ),
  )

  json_object_filter_nulls([
    business_connection_id,
    chat_id,
    message_thread_id,
    text,
    parse_mode,
    entities,
    link_preview_options,
    disable_notification,
    protect_content,
    reply_parameters,
    reply_markup,
  ])
}

// SetChatMenuButtonParameters ----------------------------------------------------------------------------------------

pub type SetChatMenuButtonParameters {
  SetChatMenuButtonParameters(
    /// Unique identifier for the target private chat. If not specified, default bot's menu button will be changed
    chat_id: Option(Int),
    /// A JSON-serialized object for the bot's new menu button. Defaults to MenuButtonDefault
    menu_button: Option(MenuButton),
  )
}

pub fn encode_set_chat_menu_button_parameters(
  params: SetChatMenuButtonParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", json.nullable(params.chat_id, json.int)),
    #("menu_button", json.nullable(params.menu_button, encode_menu_button)),
  ])
}

// SetWebhookParameters ----------------------------------------------------------------------------------------------

/// https://core.telegram.org/bots/api#setwebhook
pub type SetWebhookParameters {
  SetWebhookParameters(
    /// HTTPS url to send updates to. Use an empty string to remove webhook integration
    url: String,
    /// Upload your public key certificate so that the root certificate in use can be checked. See our [self-signed guide](https://core.telegram.org/bots/self-signed) for details.
    certificate: Option(File),
    /// Maximum allowed number of simultaneous HTTPS connections to the webhook for update delivery, 1-100. Defaults to 40. Use lower values to limit the load on your bot's server, and higher values to increase your bot's throughput.
    max_connections: Option(Int),
    /// The fixed IP address which will be used to send webhook requests instead of the IP address resolved through DNS
    ip_address: Option(String),
    /// A JSON-serialized list of the update types you want your bot to receive. For example, specify `["message", "edited_channel_post", "callback_query"]` to only receive updates of these types. See [Update](https://core.telegram.org/bots/api#update) for a complete list of available update types. Specify an empty list to receive all updates regardless of type (default). If not specified, the previous setting will be used.
    ///
    /// > Please note that this parameter doesn't affect updates created before the call to the setWebhook, so unwanted updates may be received for a short period of time.
    allowed_updates: Option(List(String)),
    /// Pass _True_ to drop all pending updates
    drop_pending_updates: Option(Bool),
    /// A secret token to be sent in a header "X-Telegram-Bot-Api-Secret-Token" in every webhook request, 1-256 characters. Only characters A-Z, a-z, 0-9, _ and - are allowed. The header is useful to ensure that the request comes from a webhook set by you.
    secret_token: Option(String),
  )
}

pub fn encode_set_webhook_parameters(params: SetWebhookParameters) -> Json {
  json_object_filter_nulls([
    #("url", json.string(params.url)),
    #("max_connections", json.nullable(params.max_connections, json.int)),
    #("ip_address", json.nullable(params.ip_address, json.string)),
    #(
      "allowed_updates",
      json.nullable(params.allowed_updates, json.array(_, json.string)),
    ),
    #(
      "drop_pending_updates",
      json.nullable(params.drop_pending_updates, json.bool),
    ),
    #("secret_token", json.nullable(params.secret_token, json.string)),
  ])
}

// GetUpdatesParameters ----------------------------------------------------------------------------------------------

/// https://core.telegram.org/bots/api#getupdates
pub type GetUpdatesParameters {
  GetUpdatesParameters(
    /// Identifier of the first update to be returned. Must be greater by one than the highest among the identifiers of previously received updates. By default, updates starting with the earliest unconfirmed update are returned. An update is considered confirmed as soon as getUpdates is called with an offset higher than its update_id. The negative offset can be specified to retrieve updates starting from -offset update from the end of the updates queue. All previous updates will be forgotten.
    offset: Option(Int),
    /// Limits the number of updates to be retrieved. Values between 1-100 are accepted. Defaults to 100.
    limit: Option(Int),
    /// Timeout in seconds for long polling. Defaults to 0, i.e. usual short polling. Should be positive, short polling should be used for testing purposes only.
    timeout: Option(Int),
    /// A JSON-serialized list of the update types you want your bot to receive. For example, specify ["message", "edited_channel_post", "callback_query"] to only receive updates of these types. See Update for a complete list of available update types. Specify an empty list to receive all update types except chat_member, message_reaction, and message_reaction_count (default). If not specified, the previous setting will be used.
    ///
    /// Please note that this parameter doesn't affect updates created before the call to getUpdates, so unwanted updates may be received for a short period of time.
    allowed_updates: Option(List(String)),
  )
}

// CopyMessageParameters ---------------------------------------------------------------------------------------------

/// https://core.telegram.org/bots/api#copymessage
pub type CopyMessageParameters {
  CopyMessageParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format @channelusername)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Unique identifier for the chat where the original message was sent (or channel username in the format @channelusername)
    from_chat_id: IntOrString,
    /// Message identifier in the chat specified in from_chat_id
    message_id: Int,
    /// New start timestamp for the copied video in the message
    video_start_timestamp: Option(Int),
    /// New caption for media, 0-1024 characters after entities parsing. If not specified, the original caption is kept
    caption: Option(String),
    /// Mode for parsing entities in the new caption. See formatting options for more details.
    parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in the new caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// Pass True, if the caption must be shown above the message media. Ignored if a new caption isn't specified.
    show_caption_above_media: Option(Bool),
    /// Sends the message silently. Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Protects the contents of the sent message from forwarding and saving
    protect_content: Option(Bool),
    /// Pass True to allow up to 1000 messages per second, ignoring broadcasting limits for a fee of 0.1 Telegram Stars per message. The relevant Stars will be withdrawn from the bot's balance
    allow_paid_broadcast: Option(Bool),
    /// Description of the message to reply to
    reply_parameters: Option(ReplyParameters),
    /// Additional interface options. A JSON-serialized object for an inline keyboard, custom reply keyboard, instructions to remove a reply keyboard or to force a reply from the user
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_copy_message_parameters(params: CopyMessageParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("from_chat_id", encode_int_or_string(params.from_chat_id)),
    #("message_id", json.int(params.message_id)),
    #(
      "video_start_timestamp",
      json.nullable(params.video_start_timestamp, json.int),
    ),
    #("caption", json.nullable(params.caption, json.string)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(params.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(params.show_caption_above_media, json.bool),
    ),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// CopyMessagesParameters --------------------------------------------------------------------------------------------

/// https://core.telegram.org/bots/api#copymessages
pub type CopyMessagesParameters {
  CopyMessagesParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format @channelusername)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Unique identifier for the chat where the original messages were sent (or channel username in the format @channelusername)
    from_chat_id: IntOrString,
    /// A JSON-serialized list of 1-100 identifiers of messages in the chat from_chat_id to copy
    message_ids: List(Int),
    /// Sends the messages silently. Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Protects the contents of the sent messages from forwarding and saving
    protect_content: Option(Bool),
    /// Pass True to copy the messages without their captions
    remove_caption: Option(Bool),
  )
}

pub fn encode_copy_messages_parameters(params: CopyMessagesParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("from_chat_id", encode_int_or_string(params.from_chat_id)),
    #("message_ids", json.array(params.message_ids, json.int)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #("remove_caption", json.nullable(params.remove_caption, json.bool)),
  ])
}

// SendPhotoParameters -----------------------------------------------------------------------------------------------

pub type SendPhotoParameters {
  SendPhotoParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Photo to send
    photo: FileOrString,
    /// Photo caption, 0-1024 characters
    caption: Option(String),
    /// Mode for parsing entities in the caption
    parse_mode: Option(String),
    /// List of special entities in the caption
    caption_entities: Option(List(MessageEntity)),
    /// Show caption above media
    show_caption_above_media: Option(Bool),
    /// Cover photo with spoiler animation
    has_spoiler: Option(Bool),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_photo_parameters(params: SendPhotoParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("photo", encode_file_or_string(params.photo)),
    #("caption", json.nullable(params.caption, json.string)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(params.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(params.show_caption_above_media, json.bool),
    ),
    #("has_spoiler", json.nullable(params.has_spoiler, json.bool)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendAudioParameters -----------------------------------------------------------------------------------------------

pub type SendAudioParameters {
  SendAudioParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Audio file to send
    audio: FileOrString,
    /// Audio caption, 0-1024 characters
    caption: Option(String),
    /// Mode for parsing entities in the caption
    parse_mode: Option(String),
    /// List of special entities in the caption
    caption_entities: Option(List(MessageEntity)),
    /// Duration of the audio in seconds
    duration: Option(Int),
    /// Performer name
    performer: Option(String),
    /// Track name
    title: Option(String),
    /// Thumbnail of the file
    thumbnail: Option(FileOrString),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_audio_parameters(params: SendAudioParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("audio", encode_file_or_string(params.audio)),
    #("caption", json.nullable(params.caption, json.string)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(params.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("duration", json.nullable(params.duration, json.int)),
    #("performer", json.nullable(params.performer, json.string)),
    #("title", json.nullable(params.title, json.string)),
    #("thumbnail", json.nullable(params.thumbnail, encode_file_or_string)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendDocumentParameters --------------------------------------------------------------------------------------------

pub type SendDocumentParameters {
  SendDocumentParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// File to send. Pass a file_id as String to send a file that exists on the Telegram servers (recommended), pass an HTTP URL as a String for Telegram to get a file from the Internet, or upload a new one using multipart/form-data. [More information on Sending Files »](https://core.telegram.org/bots/api#sending-files)
    document: FileOrString,
    /// Thumbnail of the file sent; can be ignored if thumbnail generation for the file is supported server-side. The thumbnail should be in JPEG format and less than 200 kB in size. A thumbnail's width and height should not exceed 320. Ignored if the file is not uploaded using multipart/form-data. Thumbnails can't be reused and can be only uploaded as a new file, so you can pass “attach://<file_attach_name>” if the thumbnail was uploaded using multipart/form-data under <file_attach_name>. [More information on Sending Files »](https://core.telegram.org/bots/api#sending-files)
    thumbnail: Option(FileOrString),
    /// Document caption, 0-1024 characters
    caption: Option(String),
    /// Mode for parsing entities in the caption
    parse_mode: Option(String),
    /// List of special entities in the caption
    caption_entities: Option(List(MessageEntity)),
    /// Disable automatic content type detection
    disable_content_type_detection: Option(Bool),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_document_parameters(params: SendDocumentParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("document", encode_file_or_string(params.document)),
    #("thumbnail", json.nullable(params.thumbnail, encode_file_or_string)),
    #("caption", json.nullable(params.caption, json.string)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(params.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "disable_content_type_detection",
      json.nullable(params.disable_content_type_detection, json.bool),
    ),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendVideoParameters -----------------------------------------------------------------------------------------------

pub type SendVideoParameters {
  SendVideoParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Video to send
    video: FileOrString,
    /// Duration of sent video in seconds
    duration: Option(Int),
    /// Video width
    width: Option(Int),
    /// Video height
    height: Option(Int),
    /// Thumbnail of the file
    thumbnail: Option(FileOrString),
    /// Cover for the video
    cover: Option(FileOrString),
    /// Start timestamp for the video
    start_timestamp: Option(Int),
    /// Video caption, 0-1024 characters
    caption: Option(String),
    /// Mode for parsing entities in the caption
    parse_mode: Option(String),
    /// List of special entities in the caption
    caption_entities: Option(List(MessageEntity)),
    /// Show caption above media
    show_caption_above_media: Option(Bool),
    /// Cover video with spoiler animation
    has_spoiler: Option(Bool),
    /// Video is suitable for streaming
    supports_streaming: Option(Bool),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_video_parameters(params: SendVideoParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("video", encode_file_or_string(params.video)),
    #("duration", json.nullable(params.duration, json.int)),
    #("width", json.nullable(params.width, json.int)),
    #("height", json.nullable(params.height, json.int)),
    #("thumbnail", json.nullable(params.thumbnail, encode_file_or_string)),
    #("cover", json.nullable(params.cover, encode_file_or_string)),
    #("start_timestamp", json.nullable(params.start_timestamp, json.int)),
    #("caption", json.nullable(params.caption, json.string)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(params.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(params.show_caption_above_media, json.bool),
    ),
    #("has_spoiler", json.nullable(params.has_spoiler, json.bool)),
    #("supports_streaming", json.nullable(params.supports_streaming, json.bool)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendAnimationParameters --------------------------------------------------------------------------------------------

pub type SendAnimationParameters {
  SendAnimationParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Animation to send
    animation: FileOrString,
    /// Duration of sent animation in seconds
    duration: Option(Int),
    /// Animation width
    width: Option(Int),
    /// Animation height
    height: Option(Int),
    /// Thumbnail of the file
    thumbnail: Option(FileOrString),
    /// Animation caption, 0-1024 characters
    caption: Option(String),
    /// Mode for parsing entities in the caption
    parse_mode: Option(String),
    /// List of special entities in the caption
    caption_entities: Option(List(MessageEntity)),
    /// Show caption above media
    show_caption_above_media: Option(Bool),
    /// Cover animation with spoiler animation
    has_spoiler: Option(Bool),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_animation_parameters(params: SendAnimationParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("animation", encode_file_or_string(params.animation)),
    #("duration", json.nullable(params.duration, json.int)),
    #("width", json.nullable(params.width, json.int)),
    #("height", json.nullable(params.height, json.int)),
    #("thumbnail", json.nullable(params.thumbnail, encode_file_or_string)),
    #("caption", json.nullable(params.caption, json.string)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(params.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(params.show_caption_above_media, json.bool),
    ),
    #("has_spoiler", json.nullable(params.has_spoiler, json.bool)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendVoiceParameters -----------------------------------------------------------------------------------------------

pub type SendVoiceParameters {
  SendVoiceParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Audio file to send
    voice: FileOrString,
    /// Voice message caption, 0-1024 characters
    caption: Option(String),
    /// Mode for parsing entities in the caption
    parse_mode: Option(String),
    /// List of special entities in the caption
    caption_entities: Option(List(MessageEntity)),
    /// Duration of the voice message in seconds
    duration: Option(Int),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_voice_parameters(params: SendVoiceParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("voice", encode_file_or_string(params.voice)),
    #("caption", json.nullable(params.caption, json.string)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(params.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("duration", json.nullable(params.duration, json.int)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendVideoNoteParameters ------------------------------------------------------------------------------------

pub type SendVideoNoteParameters {
  SendVideoNoteParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Video note to send
    video_note: FileOrString,
    /// Duration of sent video in seconds
    duration: Option(Int),
    /// Video width and height (diameter)
    length: Option(Int),
    /// Thumbnail of the file
    thumbnail: Option(FileOrString),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_video_note_parameters(
  params: SendVideoNoteParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("video_note", encode_file_or_string(params.video_note)),
    #("duration", json.nullable(params.duration, json.int)),
    #("length", json.nullable(params.length, json.int)),
    #("thumbnail", json.nullable(params.thumbnail, encode_file_or_string)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendMediaGroupParameters
pub type SendMediaGroupParameters {
  SendMediaGroupParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Array describing messages to be sent (2-10 items)
    media: List(InputMedia),
    /// Send messages silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
  )
}

pub fn encode_send_media_group_parameters(
  params: SendMediaGroupParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("media", json.array(params.media, encode_input_media)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
  ])
}

// SendLocationParameters
pub type SendLocationParameters {
  SendLocationParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Latitude of the location
    latitude: Float,
    /// Longitude of the location
    longitude: Float,
    /// Radius of uncertainty for the location (0-1500 meters)
    horizontal_accuracy: Option(Float),
    /// Period for location updates (60-86400 seconds)
    live_period: Option(Int),
    /// Direction of user movement (1-360 degrees)
    heading: Option(Int),
    /// Maximum distance for proximity alerts (1-100000 meters)
    proximity_alert_radius: Option(Int),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_location_parameters(params: SendLocationParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("latitude", json.float(params.latitude)),
    #("longitude", json.float(params.longitude)),
    #(
      "horizontal_accuracy",
      json.nullable(params.horizontal_accuracy, json.float),
    ),
    #("live_period", json.nullable(params.live_period, json.int)),
    #("heading", json.nullable(params.heading, json.int)),
    #(
      "proximity_alert_radius",
      json.nullable(params.proximity_alert_radius, json.int),
    ),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendVenueParameters
pub type SendVenueParameters {
  SendVenueParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Latitude of the venue
    latitude: Float,
    /// Longitude of the venue
    longitude: Float,
    /// Name of the venue
    title: String,
    /// Address of the venue
    address: String,
    /// Foursquare identifier
    foursquare_id: Option(String),
    /// Foursquare type of the venue
    foursquare_type: Option(String),
    /// Google Places identifier
    google_place_id: Option(String),
    /// Google Places type
    google_place_type: Option(String),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_venue_parameters(params: SendVenueParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("latitude", json.float(params.latitude)),
    #("longitude", json.float(params.longitude)),
    #("title", json.string(params.title)),
    #("address", json.string(params.address)),
    #("foursquare_id", json.nullable(params.foursquare_id, json.string)),
    #("foursquare_type", json.nullable(params.foursquare_type, json.string)),
    #("google_place_id", json.nullable(params.google_place_id, json.string)),
    #("google_place_type", json.nullable(params.google_place_type, json.string)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendContactParameters
pub type SendContactParameters {
  SendContactParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Contact's phone number
    phone_number: String,
    /// Contact's first name
    first_name: String,
    /// Contact's last name
    last_name: Option(String),
    /// Additional data about the contact in vCard format
    vcard: Option(String),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_contact_parameters(params: SendContactParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("phone_number", json.string(params.phone_number)),
    #("first_name", json.string(params.first_name)),
    #("last_name", json.nullable(params.last_name, json.string)),
    #("vcard", json.nullable(params.vcard, json.string)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendPollParameters
pub type SendPollParameters {
  SendPollParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Poll question (1-300 characters)
    question: String,
    /// Mode for parsing entities in the question
    question_parse_mode: Option(String),
    /// List of special entities in the question
    question_entities: Option(List(MessageEntity)),
    /// List of answer options (2-10 items)
    options: List(String),
    /// Whether the poll is anonymous
    is_anonymous: Option(Bool),
    /// Poll type ("quiz" or "regular")
    type_: Option(String),
    /// Whether multiple answers are allowed
    allows_multiple_answers: Option(Bool),
    /// Correct answer option ID (0-based)
    correct_option_id: Option(Int),
    /// Text shown for incorrect answers
    explanation: Option(String),
    /// Mode for parsing entities in the explanation
    explanation_parse_mode: Option(String),
    /// List of special entities in the explanation
    explanation_entities: Option(List(MessageEntity)),
    /// Poll active period in seconds (5-600)
    open_period: Option(Int),
    /// Poll close time (Unix timestamp)
    close_date: Option(Int),
    /// Whether the poll is closed
    is_closed: Option(Bool),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_poll_parameters(params: SendPollParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("question", json.string(params.question)),
    #(
      "question_parse_mode",
      json.nullable(params.question_parse_mode, json.string),
    ),
    #(
      "question_entities",
      json.nullable(params.question_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("options", json.array(params.options, json.string)),
    #("is_anonymous", json.nullable(params.is_anonymous, json.bool)),
    #("type", json.nullable(params.type_, json.string)),
    #(
      "allows_multiple_answers",
      json.nullable(params.allows_multiple_answers, json.bool),
    ),
    #("correct_option_id", json.nullable(params.correct_option_id, json.int)),
    #("explanation", json.nullable(params.explanation, json.string)),
    #(
      "explanation_parse_mode",
      json.nullable(params.explanation_parse_mode, json.string),
    ),
    #(
      "explanation_entities",
      json.nullable(params.explanation_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("open_period", json.nullable(params.open_period, json.int)),
    #("close_date", json.nullable(params.close_date, json.int)),
    #("is_closed", json.nullable(params.is_closed, json.bool)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// SendChatActionParameters ------------------------------------------------------------------------------------------

pub type ChatAction {
  Typing
  UploadPhoto
  RecordVideo
  UploadVideo
  RecordVoice
  UploadVoice
  UploadDocument
  ChooseSticker
  FindLocation
  RecordVideoNote
  UploadVideoNote
}

fn encode_chat_action(action: ChatAction) -> String {
  case action {
    Typing -> "typing"
    UploadPhoto -> "upload_photo"
    RecordVideo -> "record_video"
    UploadVideo -> "upload_video"
    RecordVoice -> "record_voice"
    UploadVoice -> "upload_voice"
    UploadDocument -> "upload_document"
    ChooseSticker -> "choose_sticker"
    FindLocation -> "find_location"
    RecordVideoNote -> "record_video_note"
    UploadVideoNote -> "upload_video_note"
  }
}

pub type SendChatActionParameters {
  SendChatActionParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread
    message_thread_id: Option(Int),
    /// Type of action to broadcast
    action: ChatAction,
  )
}

pub fn encode_send_chat_action_parameters(
  params: SendChatActionParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("action", json.string(encode_chat_action(params.action))),
  ])
}

// SendInvoiceParameters ---------------------------------------------------------------------------------------------

pub type SendInvoiceParameters {
  SendInvoiceParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Product name, 1-32 characters
    title: String,
    /// Product description, 1-255 characters
    description: String,
    /// Bot-defined invoice payload, 1-128 bytes
    payload: String,
    /// Payment provider token
    provider_token: Option(String),
    /// Three-letter ISO 4217 currency code
    currency: String,
    /// Price breakdown
    prices: List(LabeledPrice),
    /// Maximum accepted amount for tips
    max_tip_amount: Option(Int),
    /// Suggested amounts of tips
    suggested_tip_amounts: Option(List(Int)),
    /// Unique deep-linking parameter
    start_parameter: Option(String),
    /// JSON-serialized data about the invoice
    provider_data: Option(String),
    /// URL of the product photo
    photo_url: Option(String),
    /// Photo size in bytes
    photo_size: Option(Int),
    /// Photo width
    photo_width: Option(Int),
    /// Photo height
    photo_height: Option(Int),
    /// Require user's full name
    need_name: Option(Bool),
    /// Require user's phone number
    need_phone_number: Option(Bool),
    /// Require user's email address
    need_email: Option(Bool),
    /// Require user's shipping address
    need_shipping_address: Option(Bool),
    /// Send phone number to provider
    send_phone_number_to_provider: Option(Bool),
    /// Send email to provider
    send_email_to_provider: Option(Bool),
    /// Final price depends on shipping method
    is_flexible: Option(Bool),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Inline keyboard markup
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn encode_send_invoice_parameters(params: SendInvoiceParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("title", json.string(params.title)),
    #("description", json.string(params.description)),
    #("payload", json.string(params.payload)),
    #("provider_token", json.nullable(params.provider_token, json.string)),
    #("currency", json.string(params.currency)),
    #("prices", json.array(params.prices, encode_labeled_price)),
    #("max_tip_amount", json.nullable(params.max_tip_amount, json.int)),
    #(
      "suggested_tip_amounts",
      json.nullable(params.suggested_tip_amounts, json.array(_, json.int)),
    ),
    #("start_parameter", json.nullable(params.start_parameter, json.string)),
    #("provider_data", json.nullable(params.provider_data, json.string)),
    #("photo_url", json.nullable(params.photo_url, json.string)),
    #("photo_size", json.nullable(params.photo_size, json.int)),
    #("photo_width", json.nullable(params.photo_width, json.int)),
    #("photo_height", json.nullable(params.photo_height, json.int)),
    #("need_name", json.nullable(params.need_name, json.bool)),
    #("need_phone_number", json.nullable(params.need_phone_number, json.bool)),
    #("need_email", json.nullable(params.need_email, json.bool)),
    #(
      "need_shipping_address",
      json.nullable(params.need_shipping_address, json.bool),
    ),
    #(
      "send_phone_number_to_provider",
      json.nullable(params.send_phone_number_to_provider, json.bool),
    ),
    #(
      "send_email_to_provider",
      json.nullable(params.send_email_to_provider, json.bool),
    ),
    #("is_flexible", json.nullable(params.is_flexible, json.bool)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(params.reply_markup, encode_inline_keyboard_markup),
    ),
  ])
}

// CreateInvoiceLinkParameters ---------------------------------------------------------------------------------------

pub type CreateInvoiceLinkParameters {
  CreateInvoiceLinkParameters(
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Product name, 1-32 characters
    title: String,
    /// Product description, 1-255 characters
    description: String,
    /// Bot-defined invoice payload, 1-128 bytes
    payload: String,
    /// Payment provider token
    provider_token: Option(String),
    /// Three-letter ISO 4217 currency code
    currency: String,
    /// Price breakdown
    prices: List(LabeledPrice),
    /// Subscription period in seconds
    subscription_period: Option(Int),
    /// Maximum accepted amount for tips
    max_tip_amount: Option(Int),
    /// Suggested amounts of tips
    suggested_tip_amounts: Option(List(Int)),
    /// JSON-serialized data about the invoice
    provider_data: Option(String),
    /// URL of the product photo
    photo_url: Option(String),
    /// Photo size in bytes
    photo_size: Option(Int),
    /// Photo width
    photo_width: Option(Int),
    /// Photo height
    photo_height: Option(Int),
    /// Require user's full name
    need_name: Option(Bool),
    /// Require user's phone number
    need_phone_number: Option(Bool),
    /// Require user's email address
    need_email: Option(Bool),
    /// Require user's shipping address
    need_shipping_address: Option(Bool),
    /// Send phone number to provider
    send_phone_number_to_provider: Option(Bool),
    /// Send email to provider
    send_email_to_provider: Option(Bool),
    /// Final price depends on shipping method
    is_flexible: Option(Bool),
  )
}

pub fn encode_create_invoice_link_parameters(
  params: CreateInvoiceLinkParameters,
) -> Json {
  json_object_filter_nulls([
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("title", json.string(params.title)),
    #("description", json.string(params.description)),
    #("payload", json.string(params.payload)),
    #("provider_token", json.nullable(params.provider_token, json.string)),
    #("currency", json.string(params.currency)),
    #("prices", json.array(params.prices, encode_labeled_price)),
    #(
      "subscription_period",
      json.nullable(params.subscription_period, json.int),
    ),
    #("max_tip_amount", json.nullable(params.max_tip_amount, json.int)),
    #(
      "suggested_tip_amounts",
      json.nullable(params.suggested_tip_amounts, json.array(_, json.int)),
    ),
    #("provider_data", json.nullable(params.provider_data, json.string)),
    #("photo_url", json.nullable(params.photo_url, json.string)),
    #("photo_size", json.nullable(params.photo_size, json.int)),
    #("photo_width", json.nullable(params.photo_width, json.int)),
    #("photo_height", json.nullable(params.photo_height, json.int)),
    #("need_name", json.nullable(params.need_name, json.bool)),
    #("need_phone_number", json.nullable(params.need_phone_number, json.bool)),
    #("need_email", json.nullable(params.need_email, json.bool)),
    #(
      "need_shipping_address",
      json.nullable(params.need_shipping_address, json.bool),
    ),
    #(
      "send_phone_number_to_provider",
      json.nullable(params.send_phone_number_to_provider, json.bool),
    ),
    #(
      "send_email_to_provider",
      json.nullable(params.send_email_to_provider, json.bool),
    ),
    #("is_flexible", json.nullable(params.is_flexible, json.bool)),
  ])
}

// SendStickerParameters ---------------------------------------------------------------------------------------------

pub type SendStickerParameters {
  SendStickerParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target message thread (topic)
    message_thread_id: Option(Int),
    /// Sticker to send
    sticker: FileOrString,
    /// Emoji associated with the sticker
    emoji: Option(String),
    /// Send message silently
    disable_notification: Option(Bool),
    /// Protect content from forwarding and saving
    protect_content: Option(Bool),
    /// Allow paid broadcast
    allow_paid_broadcast: Option(Bool),
    /// Message effect identifier
    message_effect_id: Option(String),
    /// Reply parameters
    reply_parameters: Option(ReplyParameters),
    /// Reply markup
    reply_markup: Option(SendMessageReplyMarkupParameters),
  )
}

pub fn encode_send_sticker_parameters(params: SendStickerParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("sticker", encode_file_or_string(params.sticker)),
    #("emoji", json.nullable(params.emoji, json.string)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
    #(
      "allow_paid_broadcast",
      json.nullable(params.allow_paid_broadcast, json.bool),
    ),
    #("message_effect_id", json.nullable(params.message_effect_id, json.string)),
    #(
      "reply_parameters",
      json.nullable(params.reply_parameters, encode_reply_parameters),
    ),
    #(
      "reply_markup",
      json.nullable(
        params.reply_markup,
        encode_send_message_reply_markup_parameters,
      ),
    ),
  ])
}

// GetStickerSetParameters -------------------------------------------------------------------------------------------

pub type GetStickerSetParameters {
  GetStickerSetParameters(
    /// Name of the sticker set
    name: String,
  )
}

pub fn encode_get_sticker_set_parameters(
  params: GetStickerSetParameters,
) -> Json {
  json_object_filter_nulls([#("name", json.string(params.name))])
}

// SetMessageReactionParameters --------------------------------------------------------------------------------------

pub type SetMessageReactionParameters {
  SetMessageReactionParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Identifier of the target message
    message_id: Int,
    /// List of reaction types to set on the message
    reaction: Option(List(ReactionType)),
    /// Whether to set the reaction with a big animation
    is_big: Option(Bool),
  )
}

pub fn encode_set_message_reaction_parameters(
  params: SetMessageReactionParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_id", json.int(params.message_id)),
    #(
      "reaction",
      json.nullable(params.reaction, json.array(_, encode_reaction_type)),
    ),
    #("is_big", json.nullable(params.is_big, json.bool)),
  ])
}

// GetUserProfilePhotosParameters ------------------------------------------------------------------------------------

pub type GetUserProfilePhotosParameters {
  GetUserProfilePhotosParameters(
    /// Unique identifier of the target user
    user_id: Int,
    /// Sequential number of the first photo to be returned (0-based)
    offset: Option(Int),
    /// Limits the number of photos to be retrieved (1-100)
    limit: Option(Int),
  )
}

pub fn encode_get_user_profile_photos_parameters(
  params: GetUserProfilePhotosParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("offset", json.nullable(params.offset, json.int)),
    #("limit", json.nullable(params.limit, json.int)),
  ])
}

// EditMessageCaptionParameters --------------------------------------------------------------------------------------

pub type EditMessageCaptionParameters {
  EditMessageCaptionParameters(
    /// Unique identifier of the business connection on behalf of which the message to be edited was sent
    business_connection_id: Option(String),
    /// Required if _inline_message_id_ is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: Option(IntOrString),
    /// Required if _inline_message_id_ is not specified. Identifier of the message to edit
    message_id: Option(Int),
    /// Required if _chat_id_ and _message_id_ are not specified. Identifier of the inline message
    inline_message_id: Option(String),
    /// New text of the message, 1-4096 characters after entities parsing
    caption: Option(String),
    /// Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api#formatting-options) for more details.
    parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in message text, which can be specified instead of _parse_mode_
    caption_entities: Option(List(MessageEntity)),
    /// Link preview generation options for the message
    show_caption_above_media: Option(Bool),
    /// A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards).
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn encode_edit_message_caption_parameters(
  params: EditMessageCaptionParameters,
) -> Json {
  json_object_filter_nulls([
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("chat_id", json.nullable(params.chat_id, encode_int_or_string)),
    #("message_id", json.nullable(params.message_id, json.int)),
    #("inline_message_id", json.nullable(params.inline_message_id, json.string)),
    #("caption", json.nullable(params.caption, json.string)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(params.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "show_caption_above_media",
      json.nullable(params.show_caption_above_media, json.bool),
    ),
    #(
      "reply_markup",
      json.nullable(params.reply_markup, encode_inline_keyboard_markup),
    ),
  ])
}

// EditMessageMediaParameters ----------------------------------------------------------------------------------------

pub type EditMessageMediaParameters {
  EditMessageMediaParameters(
    /// Unique identifier of the business connection on behalf of which the message to be edited was sent
    business_connection_id: Option(String),
    /// Required if _inline_message_id_ is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: Option(IntOrString),
    /// Required if inline_message_id is not specified. Identifier of the message to edit
    message_id: Option(Int),
    /// Required if chat_id and message_id are not specified. Identifier of the inline message
    inline_message_id: Option(String),
    /// A JSON-serialized object for a new media content of the message
    media: InputMedia,
    /// A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards).
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn encode_edit_message_media_parameters(
  params: EditMessageMediaParameters,
) -> Json {
  json_object_filter_nulls([
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("chat_id", json.nullable(params.chat_id, encode_int_or_string)),
    #("message_id", json.nullable(params.message_id, json.int)),
    #("inline_message_id", json.nullable(params.inline_message_id, json.string)),
    #("media", encode_input_media(params.media)),
    #(
      "reply_markup",
      json.nullable(params.reply_markup, encode_inline_keyboard_markup),
    ),
  ])
}

// EditMessageLiveLocationParameters

pub type EditMessageLiveLocationParameters {
  EditMessageLiveLocationParameters(
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target chat
    chat_id: Option(IntOrString),
    /// Identifier of the message to edit
    message_id: Option(Int),
    /// Identifier of the inline message
    inline_message_id: Option(String),
    /// Latitude of new location
    latitude: Float,
    /// Longitude of new location
    longitude: Float,
    /// Period for location updates
    live_period: Option(Int),
    /// Radius of uncertainty for the location
    horizontal_accuracy: Option(Float),
    /// Direction of movement
    heading: Option(Int),
    /// Maximum distance for proximity alerts
    proximity_alert_radius: Option(Int),
    /// Inline keyboard markup
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn encode_edit_message_live_location_parameters(
  params: EditMessageLiveLocationParameters,
) -> Json {
  json_object_filter_nulls([
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("chat_id", json.nullable(params.chat_id, encode_int_or_string)),
    #("message_id", json.nullable(params.message_id, json.int)),
    #("inline_message_id", json.nullable(params.inline_message_id, json.string)),
    #("latitude", json.float(params.latitude)),
    #("longitude", json.float(params.longitude)),
    #("live_period", json.nullable(params.live_period, json.int)),
    #(
      "horizontal_accuracy",
      json.nullable(params.horizontal_accuracy, json.float),
    ),
    #("heading", json.nullable(params.heading, json.int)),
    #(
      "proximity_alert_radius",
      json.nullable(params.proximity_alert_radius, json.int),
    ),
    #(
      "reply_markup",
      json.nullable(params.reply_markup, encode_inline_keyboard_markup),
    ),
  ])
}

// StopMessageLiveLocationParameters
pub type StopMessageLiveLocationParameters {
  StopMessageLiveLocationParameters(
    /// Unique identifier of the business connection
    business_connection_id: Option(String),
    /// Unique identifier for the target chat
    chat_id: Option(IntOrString),
    /// Identifier of the message to stop
    message_id: Option(Int),
    /// Identifier of the inline message
    inline_message_id: Option(String),
    /// Inline keyboard markup
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn encode_stop_message_live_location_parameters(
  params: StopMessageLiveLocationParameters,
) -> Json {
  json_object_filter_nulls([
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("chat_id", json.nullable(params.chat_id, encode_int_or_string)),
    #("message_id", json.nullable(params.message_id, json.int)),
    #("inline_message_id", json.nullable(params.inline_message_id, json.string)),
    #(
      "reply_markup",
      json.nullable(params.reply_markup, encode_inline_keyboard_markup),
    ),
  ])
}

// EditMessageReplyMarkupParameters ----------------------------------------------------------------------------------

pub type EditMessageReplyMarkupParameters {
  EditMessageReplyMarkupParameters(
    /// Unique identifier of the business connection on behalf of which the message to be edited was sent
    business_connection_id: Option(String),
    /// Required if _inline_message_id_ is not specified. Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: Option(IntOrString),
    /// Required if _inline_message_id_ is not specified. Identifier of the message to edit
    message_id: Option(Int),
    /// Required if _chat_id_ and _message_id_ are not specified. Identifier of the inline message
    inline_message_id: Option(String),
    /// A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards)
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn encode_edit_message_reply_markup_parameters(
  params: EditMessageReplyMarkupParameters,
) -> Json {
  json_object_filter_nulls([
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("chat_id", json.nullable(params.chat_id, encode_int_or_string)),
    #("message_id", json.nullable(params.message_id, json.int)),
    #("inline_message_id", json.nullable(params.inline_message_id, json.string)),
    #(
      "reply_markup",
      json.nullable(params.reply_markup, encode_inline_keyboard_markup),
    ),
  ])
}

// StopPollParameters ------------------------------------------------------------------------------------------------

pub type StopPollParameters {
  StopPollParameters(
    /// Unique identifier of the business connection on behalf of which the message to be edited was sent
    business_connection_id: Option(String),
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Identifier of the original message with the poll
    message_id: Int,
    /// A JSON-serialized object for a new message [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards)
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn encode_stop_poll_parameters(params: StopPollParameters) -> Json {
  json_object_filter_nulls([
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_id", json.int(params.message_id)),
    #(
      "reply_markup",
      json.nullable(params.reply_markup, encode_inline_keyboard_markup),
    ),
  ])
}

// DeleteMessageParameters
pub type DeleteMessageParameters {
  DeleteMessageParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Identifier of the message to delete
    message_id: Int,
  )
}

pub fn encode_delete_message_parameters(params: DeleteMessageParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_id", json.int(params.message_id)),
  ])
}

// DeleteMessagesParameters -----------------------------------------------------------------------------------------

pub type DeleteMessagesParameters {
  DeleteMessagesParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// A JSON-serialized list of 1-100 identifiers of messages to delete
    message_ids: List(Int),
  )
}

pub fn encode_delete_messages_parameters(
  params: DeleteMessagesParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_ids", json.array(params.message_ids, json.int)),
  ])
}

// BanChatMemberParameters ------------------------------------------------------------------------------------------

pub type BanChatMemberParameters {
  BanChatMemberParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
    /// Date when the user will be unbanned; Unix time. If user is banned for more than 366 days or less than 30 seconds from the current time they are considered to be banned forever. Applied for supergroups and channels only.
    until_date: Option(Int),
    /// Pass `True` to delete all messages from the chat for the user that is being removed. If `False`, the user will be able to see messages in the group that were sent before the user was removed. Always `True` for supergroups and channels.
    revoke_messages: Option(Bool),
  )
}

pub fn encode_ban_chat_member_parameters(
  params: BanChatMemberParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
    #("until_date", json.nullable(params.until_date, json.int)),
    #("revoke_messages", json.nullable(params.revoke_messages, json.bool)),
  ])
}

// UnbanChatMemeberParameters ----------------------------------------------------------------------------------------

pub type UnbanChatMemberParameters {
  UnbanChatMemberParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
    /// Do nothing if the user is not banned
    only_if_banned: Option(Bool),
  )
}

pub fn encode_unban_chat_member_parameters(
  params: UnbanChatMemberParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
    #("only_if_banned", json.nullable(params.only_if_banned, json.bool)),
  ])
}

// RestrictChatMemberParameters -------------------------------------------------------------------------------------

pub type RestrictChatMemberParameters {
  RestrictChatMemberParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format @supergroupusername)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
    /// Pass `True` to restrict the user from sending messages, `False` to remove the restriction.
    permissions: ChatPermissions,
    /// Date when the user will be unbanned; Unix time. If user is banned for more than 366 days or less than 30 seconds from the current time they are considered to be banned forever.
    until_date: Option(Int),
  )
}

pub fn encode_restrict_chat_member_parameters(
  params: RestrictChatMemberParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
    #("permissions", encode_chat_permissions(params.permissions)),
    #("until_date", json.nullable(params.until_date, json.int)),
  ])
}

// PromoteChatMemberParameters -------------------------------------------------------------------------------------

/// Parameters for promoting or demoting a user in a supergroup or channel.
///
/// The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights.
/// Pass False for all boolean parameters to demote a user.
pub type PromoteChatMemberParameters {
  PromoteChatMemberParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
    /// Pass True if the administrator's presence in the chat is hidden
    is_anonymous: Option(Bool),
    /// Pass True if the administrator can access the chat event log, get boost list, see hidden supergroup and channel members, report spam messages and ignore slow mode. Implied by any other administrator privilege.
    can_manage_chat: Option(Bool),
    /// Pass True if the administrator can delete messages of other users
    can_delete_messages: Option(Bool),
    /// Pass True if the administrator can manage video chats
    can_manage_video_chats: Option(Bool),
    /// Pass True if the administrator can restrict, ban or unban chat members, or access supergroup statistics
    can_restrict_members: Option(Bool),
    /// Pass True if the administrator can add new administrators with a subset of their own privileges or demote administrators that they have promoted, directly or indirectly (promoted by administrators that were appointed by him)
    can_promote_members: Option(Bool),
    /// Pass True if the administrator can change chat title, photo and other settings
    can_change_info: Option(Bool),
    /// Pass True if the administrator can invite new users to the chat
    can_invite_users: Option(Bool),
    /// Pass True if the administrator can post stories to the chat
    can_post_stories: Option(Bool),
    /// Pass True if the administrator can edit stories posted by other users, post stories to the chat page, pin chat stories, and access the chat's story archive
    can_edit_stories: Option(Bool),
    /// Pass True if the administrator can delete stories posted by other users
    can_delete_stories: Option(Bool),
    /// Pass True if the administrator can post messages in the channel, or access channel statistics; for channels only
    can_post_messages: Option(Bool),
    /// Pass True if the administrator can edit messages of other users and can pin messages; for channels only
    can_edit_messages: Option(Bool),
    /// Pass True if the administrator can pin messages; for supergroups only
    can_pin_messages: Option(Bool),
    /// Pass True if the user is allowed to create, rename, close, and reopen forum topics; for supergroups only
    can_manage_topics: Option(Bool),
  )
}

pub fn encode_promote_chat_member_parameters(
  params: PromoteChatMemberParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
    #("is_anonymous", json.nullable(params.is_anonymous, json.bool)),
    #("can_manage_chat", json.nullable(params.can_manage_chat, json.bool)),
    #(
      "can_delete_messages",
      json.nullable(params.can_delete_messages, json.bool),
    ),
    #(
      "can_manage_video_chats",
      json.nullable(params.can_manage_video_chats, json.bool),
    ),
    #(
      "can_restrict_members",
      json.nullable(params.can_restrict_members, json.bool),
    ),
    #(
      "can_promote_members",
      json.nullable(params.can_promote_members, json.bool),
    ),
    #("can_change_info", json.nullable(params.can_change_info, json.bool)),
    #("can_invite_users", json.nullable(params.can_invite_users, json.bool)),
    #("can_post_stories", json.nullable(params.can_post_stories, json.bool)),
    #("can_edit_stories", json.nullable(params.can_edit_stories, json.bool)),
    #("can_delete_stories", json.nullable(params.can_delete_stories, json.bool)),
    #("can_post_messages", json.nullable(params.can_post_messages, json.bool)),
    #("can_edit_messages", json.nullable(params.can_edit_messages, json.bool)),
    #("can_pin_messages", json.nullable(params.can_pin_messages, json.bool)),
    #("can_manage_topics", json.nullable(params.can_manage_topics, json.bool)),
  ])
}

// SetChatAdministratorCustomTitleParameters --------------------------------------------------------------------------

pub type SetChatAdministratorCustomTitleParameters {
  SetChatAdministratorCustomTitleParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
    /// New custom title for the administrator; 0-16 characters, emoji are not allowed
    custom_title: String,
  )
}

pub fn encode_set_chat_administrator_custom_title_parameters(
  params: SetChatAdministratorCustomTitleParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
    #("custom_title", json.string(params.custom_title)),
  ])
}

// BanChatSenderChatParameters -------------------------------------------------------------------------------------

pub type BanChatSenderChatParameters {
  BanChatSenderChatParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target sender chat
    sender_chat_id: Int,
  )
}

pub fn encode_ban_chat_sender_chat_parameters(
  params: BanChatSenderChatParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("sender_chat_id", json.int(params.sender_chat_id)),
  ])
}

// UnbanChatSenderChatParameters -----------------------------------------------------------------------------------

pub type UnbanChatSenderChatParameters {
  UnbanChatSenderChatParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target sender chat
    sender_chat_id: Int,
  )
}

pub fn encode_unban_chat_sender_chat_parameters(
  params: UnbanChatSenderChatParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("sender_chat_id", json.int(params.sender_chat_id)),
  ])
}

// SetChatPermissionsParameters -------------------------------------------------------------------------------------

pub type SetChatPermissionsParameters {
  SetChatPermissionsParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// A JSON-serialized object for new default chat permissions
    permissions: ChatPermissions,
    /// Pass `True` if chat permissions are set independently.
    /// Otherwise, the `can_send_other_messages` and `can_add_web_page_previews` permissions will imply the `can_send_messages`, `can_send_audios`, `can_send_documents`, `can_send_photos`, `can_send_videos`, `can_send_video_notes`, and `can_send_voice_notes` permissions; the `can_send_polls` permission will imply the `can_send_messages` permission.
    use_independent_chat_permissions: Option(Bool),
  )
}

pub fn encode_set_chat_permissions_parameters(
  params: SetChatPermissionsParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("permissions", encode_chat_permissions(params.permissions)),
    #(
      "use_independent_chat_permissions",
      json.nullable(params.use_independent_chat_permissions, json.bool),
    ),
  ])
}

// ExportChatInviteLinkParameters -----------------------------------------------------------------------------------

pub type ExportChatInviteLinkParameters {
  ExportChatInviteLinkParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
  )
}

pub fn encode_export_chat_invite_link_parameters(
  params: ExportChatInviteLinkParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// CreateChatInviteLinkParameters ----------------------------------------------------------------------------------

pub type CreateChatInviteLinkParameters {
  CreateChatInviteLinkParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Invite link name; 0-32 characters
    name: Option(String),
    /// The maximum number of users that can be members of the chat simultaneously after joining the chat via this invite link; 1-99999
    member_limit: Option(Int),
    /// Point in time (Unix timestamp) when the link will expire.
    expire_date: Option(Int),
    /// `True`, if users joining the chat via the link need to be approved by chat administrators. If `True`, `member_limit` can't be specified
    creates_join_request: Option(Bool),
  )
}

pub fn encode_create_chat_invite_link_parameters(
  params: CreateChatInviteLinkParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("name", json.nullable(params.name, json.string)),
    #("member_limit", json.nullable(params.member_limit, json.int)),
    #("expire_date", json.nullable(params.expire_date, json.int)),
    #(
      "creates_join_request",
      json.nullable(params.creates_join_request, json.bool),
    ),
  ])
}

// EditChatInviteLinkParameters -------------------------------------------------------------------------------------

pub type EditChatInviteLinkParameters {
  EditChatInviteLinkParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the invite link
    invite_link: String,
    /// Invite link name; 0-32 characters
    name: Option(String),
    /// The maximum number of users that can be members of the chat simultaneously after joining the chat via the link; 1-99999
    member_limit: Option(Int),
    /// Point in time (Unix timestamp) when the link will expire.
    expire_date: Option(Int),
    /// `True`, if users joining the chat via the link need to be approved by chat administrators. If `True`, `member_limit` can't be specified
    creates_join_request: Option(Bool),
  )
}

pub fn encode_edit_chat_invite_link_parameters(
  params: EditChatInviteLinkParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("invite_link", json.string(params.invite_link)),
    #("name", json.nullable(params.name, json.string)),
    #("member_limit", json.nullable(params.member_limit, json.int)),
    #("expire_date", json.nullable(params.expire_date, json.int)),
    #(
      "creates_join_request",
      json.nullable(params.creates_join_request, json.bool),
    ),
  ])
}

// CreateChatSubscriptionInviteLinkParameters ------------------------------------------------------------

pub type CreateChatSubscriptionInviteLinkParameters {
  CreateChatSubscriptionInviteLinkParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Invite link name; 0-32 characters
    name: Option(String),
    /// The number of seconds the subscription will be active for before the next payment. Currently, it must always be 2592000 (30 days).
    period: Int,
    /// The amount of Telegram Stars a user must pay initially and after each subsequent subscription period to be a member of the chat; 1-2500
    amount: Int,
  )
}

pub fn encode_create_chat_subscription_invite_link_parameters(
  params: CreateChatSubscriptionInviteLinkParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("name", json.nullable(params.name, json.string)),
    #("period", json.int(params.period)),
    #("amount", json.int(params.amount)),
  ])
}

// EditChatSubscriptionInviteLinkParameters ------------------------------------------------------------

pub type EditChatSubscriptionInviteLinkParameters {
  EditChatSubscriptionInviteLinkParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// The invite link to edit
    invite_link: String,
    /// Invite link name; 0-32 characters
    name: Option(String),
  )
}

pub fn encode_edit_chat_subscription_invite_link_parameters(
  params: EditChatSubscriptionInviteLinkParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("invite_link", json.string(params.invite_link)),
    #("name", json.nullable(params.name, json.string)),
  ])
}

// RevokeChatInviteLinkParameters ------------------------------------------------------------

pub type RevokeChatInviteLinkParameters {
  RevokeChatInviteLinkParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// The invite link to revoke
    invite_link: String,
  )
}

pub fn encode_revoke_chat_invite_link_parameters(
  params: RevokeChatInviteLinkParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("invite_link", json.string(params.invite_link)),
  ])
}

// ApproveChatJoinRequestParameters ------------------------------------------------------------

pub type ApproveChatJoinRequestParameters {
  ApproveChatJoinRequestParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
  )
}

pub fn encode_approve_chat_join_request_parameters(
  params: ApproveChatJoinRequestParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
  ])
}

// DeclineChatJoinRequestParameters ------------------------------------------------------------

pub type DeclineChatJoinRequestParameters {
  DeclineChatJoinRequestParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
  )
}

pub fn encode_decline_chat_join_request_parameters(
  params: DeclineChatJoinRequestParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
  ])
}

// SetChatPhotoParameters ------------------------------------------------------------

pub type SetChatPhotoParameters {
  SetChatPhotoParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// New chat photo, uploaded using multipart/form-data
    photo: File,
  )
}

pub fn encode_set_chat_photo_parameters(params: SetChatPhotoParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("photo", encode_file(params.photo)),
  ])
}

// DeleteChatPhotoParameters ------------------------------------------------------------

pub type DeleteChatPhotoParameters {
  DeleteChatPhotoParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
  )
}

pub fn encode_delete_chat_photo_parameters(
  params: DeleteChatPhotoParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// Common ------------------------------------------------------------------------------------------------------------

pub type IntOrString {
  Int(value: Int)
  Str(value: String)
}

pub fn int_or_string_decoder() -> decode.Decoder(IntOrString) {
  use variant <- decode.field("type", decode.string)
  case variant {
    "int" -> {
      use value <- decode.then(decode.int)
      decode.success(Int(value:))
    }
    "str" -> {
      use value <- decode.then(decode.string)
      decode.success(Str(value:))
    }
    _ -> decode.failure(Int(0), "IntOrString")
  }
}

pub fn encode_int_or_string(value: IntOrString) -> Json {
  case value {
    Int(value) -> json.int(value)
    Str(value) -> json.string(value)
  }
}

pub fn json_object_filter_nulls(entries: List(#(String, Json))) -> Json {
  let null = json.null()

  entries
  |> list.filter(fn(entry) {
    let #(_, value) = entry
    value != null
  })
  |> json.object
}
