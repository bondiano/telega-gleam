//// This module contains all types from [Telegram Bot API](https://core.telegram.org/bots/api).
////
//// Most of types named in the same way as in the official documentation.
//// But some types are renamed to more verbose names for using from Gleam code (ex. `type` -> `type_`).

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

pub type InputProfilePhoto {
  InputProfilePhotoStaticInputProfilePhoto(InputProfilePhotoStatic)
  InputProfilePhotoAnimatedInputProfilePhoto(InputProfilePhotoAnimated)
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
    /// Optional. True, if the bot has forum topic mode enabled in private chats. Returned only in getMe.
    has_topics_enabled: Option(Bool),
    /// Optional. True, if the bot allows users to create and delete topics in private chats. Returned only in getMe.
    allows_users_to_create_topics: Option(Bool),
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
    /// Optional. True, if the chat is the direct messages chat of a channel
    is_direct_messages: Option(Bool),
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
    /// Optional. True, if the chat is the direct messages chat of a channel
    is_direct_messages: Option(Bool),
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
    /// Optional. Information about the corresponding channel chat; for direct messages chats only
    parent_chat: Option(Chat),
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
    /// Optional. For private chats, the rating of the user if any
    rating: Option(UserRating),
    /// Optional. The color scheme based on a unique gift that must be used for the chat's name, message replies and link previews
    unique_gift_colors: Option(UniqueGiftColors),
    /// Optional. The number of Telegram Stars a general user have to pay to send a message to the chat
    paid_message_star_count: Option(Int),
    /// Optional. For private chats, the first audio added to the profile of the user
    first_profile_audio: Option(Audio),
  )
}

/// **Official reference:** This object represents a message.
pub type Message {
  Message(
    /// Unique message identifier inside this chat. In specific instances (e.g., message containing a video sent to a big chat), the server might automatically schedule a message instead of sending it immediately. In such cases, this field will be 0 and the relevant message will be unusable until it is actually sent
    message_id: Int,
    /// Optional. Unique identifier of a message thread or forum topic to which the message belongs; for supergroups and private chats only
    message_thread_id: Option(Int),
    /// Optional. Information about the direct messages chat topic that contains the message
    direct_messages_topic: Option(DirectMessagesTopic),
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
    /// Optional. True, if the message is sent to a topic in a forum supergroup or a private chat with the bot
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
    /// Optional. Identifier of the specific checklist task that is being replied to
    reply_to_checklist_task_id: Option(Int),
    /// Optional. Bot through which the message was sent
    via_bot: Option(User),
    /// Optional. Date the message was last edited in Unix time
    edit_date: Option(Int),
    /// Optional. True, if the message can't be forwarded
    has_protected_content: Option(Bool),
    /// Optional. True, if the message was sent by an implicit action, for example, as an away or a greeting business message, or as a scheduled message
    is_from_offline: Option(Bool),
    /// Optional. True, if the message is a paid post. Note that such posts must not be deleted for 24 hours to receive the payment and can't be edited.
    is_paid_post: Option(Bool),
    /// Optional. The unique identifier of a media message group this message belongs to
    media_group_id: Option(String),
    /// Optional. Signature of the post author for messages in channels, or the custom title of an anonymous group administrator
    author_signature: Option(String),
    /// Optional. The number of Telegram Stars that were paid by the sender of the message to send it
    paid_star_count: Option(Int),
    /// Optional. For text messages, the actual UTF-8 text of the message
    text: Option(String),
    /// Optional. For text messages, special entities like usernames, URLs, bot commands, etc. that appear in the text
    entities: Option(List(MessageEntity)),
    /// Optional. Options used for link preview generation for the message, if it is a text message and link preview options were changed
    link_preview_options: Option(LinkPreviewOptions),
    /// Optional. Information about suggested post parameters if the message is a suggested post in a channel direct messages chat. If the message is an approved or declined suggested post, then it can't be edited.
    suggested_post_info: Option(SuggestedPostInfo),
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
    /// Optional. Message is a checklist
    checklist: Option(Checklist),
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
    /// Optional. Service message: a regular gift was sent or received
    gift: Option(GiftInfo),
    /// Optional. Service message: a unique gift was sent or received
    unique_gift: Option(UniqueGiftInfo),
    /// Optional. Service message: upgrade of a gift was purchased after the gift was sent
    gift_upgrade_sent: Option(GiftInfo),
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
    /// Optional. Service message: chat owner has left
    chat_owner_left: Option(ChatOwnerLeft),
    /// Optional. Service message: chat owner has changed
    chat_owner_changed: Option(ChatOwnerChanged),
    /// Optional. Service message: some tasks in a checklist were marked as done or not done
    checklist_tasks_done: Option(ChecklistTasksDone),
    /// Optional. Service message: tasks were added to a checklist
    checklist_tasks_added: Option(ChecklistTasksAdded),
    /// Optional. Service message: the price for paid messages in the corresponding direct messages chat of a channel has changed
    direct_message_price_changed: Option(DirectMessagePriceChanged),
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
    /// Optional. Service message: the price for paid messages has changed in the chat
    paid_message_price_changed: Option(PaidMessagePriceChanged),
    /// Optional. Service message: a suggested post was approved
    suggested_post_approved: Option(SuggestedPostApproved),
    /// Optional. Service message: approval of a suggested post has failed
    suggested_post_approval_failed: Option(SuggestedPostApprovalFailed),
    /// Optional. Service message: a suggested post was declined
    suggested_post_declined: Option(SuggestedPostDeclined),
    /// Optional. Service message: payment for a suggested post was received
    suggested_post_paid: Option(SuggestedPostPaid),
    /// Optional. Service message: payment for a suggested post was refunded
    suggested_post_refunded: Option(SuggestedPostRefunded),
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
    /// Optional. Message is a checklist
    checklist: Option(Checklist),
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
    /// Optional. Identifier of the checklist task to be replied to; for checklists only
    checklist_task_id: Option(Int),
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
    /// Optional. List of available qualities of the video
    qualities: Option(List(VideoQuality)),
  )
}

/// **Official reference:** This object represents a video file of a specific quality.
pub type VideoQuality {
  VideoQuality(
    /// Identifier for this file, which can be used to download or reuse the file
    file_id: String,
    /// Unique identifier for this file, which is supposed to be the same over time and for different bots. Can't be used to download or reuse the file.
    file_unique_id: String,
    /// Video width
    width: Int,
    /// Video height
    height: Int,
    /// Codec that was used to encode the video, for example, "h264", "h265", or "av01"
    codec: String,
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

/// **Official reference:** Describes a task in a checklist.
pub type ChecklistTask {
  ChecklistTask(
    /// Unique identifier of the task
    id: Int,
    /// Text of the task
    text: String,
    /// Optional. Special entities that appear in the task text
    text_entities: Option(List(MessageEntity)),
    /// Optional. User that completed the task; omitted if the task wasn't completed by a user
    completed_by_user: Option(User),
    /// Optional. Chat that completed the task; omitted if the task wasn't completed by a chat
    completed_by_chat: Option(Chat),
    /// Optional. Point in time (Unix timestamp) when the task was completed; 0 if the task wasn't completed
    completion_date: Option(Int),
  )
}

/// **Official reference:** Describes a checklist.
pub type Checklist {
  Checklist(
    /// Title of the checklist
    title: String,
    /// Optional. Special entities that appear in the checklist title
    title_entities: Option(List(MessageEntity)),
    /// List of tasks in the checklist
    tasks: List(ChecklistTask),
    /// Optional. True, if users other than the creator of the list can add tasks to the list
    others_can_add_tasks: Option(Bool),
    /// Optional. True, if users other than the creator of the list can mark tasks as done or not done
    others_can_mark_tasks_as_done: Option(Bool),
  )
}

/// **Official reference:** Describes a task to add to a checklist.
pub type InputChecklistTask {
  InputChecklistTask(
    /// Unique identifier of the task; must be positive and unique among all task identifiers currently present in the checklist
    id: Int,
    /// Text of the task; 1-100 characters after entities parsing
    text: String,
    /// Optional. Mode for parsing entities in the text. See formatting options for more details.
    parse_mode: String,
    /// Optional. List of special entities that appear in the text, which can be specified instead of parse_mode. Currently, only bold, italic, underline, strikethrough, spoiler, and custom_emoji entities are allowed.
    text_entities: Option(List(MessageEntity)),
  )
}

/// **Official reference:** Describes a checklist to create.
pub type InputChecklist {
  InputChecklist(
    /// Title of the checklist; 1-255 characters after entities parsing
    title: String,
    /// Optional. Mode for parsing entities in the title. See formatting options for more details.
    parse_mode: String,
    /// Optional. List of special entities that appear in the title, which can be specified instead of parse_mode. Currently, only bold, italic, underline, strikethrough, spoiler, and custom_emoji entities are allowed.
    title_entities: Option(List(MessageEntity)),
    /// List of 1-30 tasks in the checklist
    tasks: List(InputChecklistTask),
    /// Optional. Pass True if other users can add tasks to the checklist
    others_can_add_tasks: Option(Bool),
    /// Optional. Pass True if other users can mark tasks as done or not done in the checklist
    others_can_mark_tasks_as_done: Option(Bool),
  )
}

/// **Official reference:** Describes a service message about checklist tasks marked as done or not done.
pub type ChecklistTasksDone {
  ChecklistTasksDone(
    /// Optional. Message containing the checklist whose tasks were marked as done or not done. Note that the Message object in this field will not contain the reply_to_message field even if it itself is a reply.
    checklist_message: Option(Message),
    /// Optional. Identifiers of the tasks that were marked as done
    marked_as_done_task_ids: Option(List(Int)),
    /// Optional. Identifiers of the tasks that were marked as not done
    marked_as_not_done_task_ids: Option(List(Int)),
  )
}

/// **Official reference:** Describes a service message about tasks added to a checklist.
pub type ChecklistTasksAdded {
  ChecklistTasksAdded(
    /// Optional. Message containing the checklist to which the tasks were added. Note that the Message object in this field will not contain the reply_to_message field even if it itself is a reply.
    checklist_message: Option(Message),
    /// List of tasks added to the checklist
    tasks: List(ChecklistTask),
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

/// **Official reference:** Describes a service message about the chat owner leaving the chat.
pub type ChatOwnerLeft {
  ChatOwnerLeft(
    /// Optional. The user which will be the new owner of the chat if the previous owner does not return to the chat
    new_owner: Option(User),
  )
}

/// **Official reference:** Describes a service message about an ownership change in the chat.
pub type ChatOwnerChanged {
  ChatOwnerChanged(
    /// The new owner of the chat
    new_owner: User,
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
    /// Optional. True, if the name of the topic wasn't specified explicitly by its creator and likely needs to be changed by the bot
    is_name_implicit: Option(Bool),
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

/// **Official reference:** Describes a service message about a change in the price of paid messages within a chat.
pub type PaidMessagePriceChanged {
  PaidMessagePriceChanged(
    /// The new number of Telegram Stars that must be paid by non-administrator users of the supergroup chat for each sent message
    paid_message_star_count: Int,
  )
}

/// **Official reference:** Describes a service message about a change in the price of direct messages sent to a channel chat.
pub type DirectMessagePriceChanged {
  DirectMessagePriceChanged(
    /// True, if direct messages are enabled for the channel chat; false otherwise
    are_direct_messages_enabled: Bool,
    /// Optional. The new number of Telegram Stars that must be paid by users for each direct message sent to the channel. Does not apply to users who have been exempted by administrators. Defaults to 0.
    direct_message_star_count: Option(Int),
  )
}

/// **Official reference:** Describes a service message about the approval of a suggested post.
pub type SuggestedPostApproved {
  SuggestedPostApproved(
    /// Optional. Message containing the suggested post. Note that the Message object in this field will not contain the reply_to_message field even if it itself is a reply.
    suggested_post_message: Option(Message),
    /// Optional. Amount paid for the post
    price: Option(SuggestedPostPrice),
    /// Date when the post will be published
    send_date: Int,
  )
}

/// **Official reference:** Describes a service message about the failed approval of a suggested post. Currently, only caused by insufficient user funds at the time of approval.
pub type SuggestedPostApprovalFailed {
  SuggestedPostApprovalFailed(
    /// Optional. Message containing the suggested post whose approval has failed. Note that the Message object in this field will not contain the reply_to_message field even if it itself is a reply.
    suggested_post_message: Option(Message),
    /// Expected price of the post
    price: SuggestedPostPrice,
  )
}

/// **Official reference:** Describes a service message about the rejection of a suggested post.
pub type SuggestedPostDeclined {
  SuggestedPostDeclined(
    /// Optional. Message containing the suggested post. Note that the Message object in this field will not contain the reply_to_message field even if it itself is a reply.
    suggested_post_message: Option(Message),
    /// Optional. Comment with which the post was declined
    comment: Option(String),
  )
}

/// **Official reference:** Describes a service message about a successful payment for a suggested post.
pub type SuggestedPostPaid {
  SuggestedPostPaid(
    /// Optional. Message containing the suggested post. Note that the Message object in this field will not contain the reply_to_message field even if it itself is a reply.
    suggested_post_message: Option(Message),
    /// Currency in which the payment was made. Currently, one of "XTR" for Telegram Stars or "TON" for toncoins
    currency: String,
    /// Optional. The amount of the currency that was received by the channel in nanotoncoins; for payments in toncoins only
    amount: Option(Int),
    /// Optional. The amount of Telegram Stars that was received by the channel; for payments in Telegram Stars only
    star_amount: Option(StarAmount),
  )
}

/// **Official reference:** Describes a service message about a payment refund for a suggested post.
pub type SuggestedPostRefunded {
  SuggestedPostRefunded(
    /// Optional. Message containing the suggested post. Note that the Message object in this field will not contain the reply_to_message field even if it itself is a reply.
    suggested_post_message: Option(Message),
    /// Reason for the refund. Currently, one of "post_deleted" if the post was deleted within 24 hours of being posted or removed from scheduled messages without being posted, or "payment_refunded" if the payer refunded their payment.
    reason: String,
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

/// **Official reference:** Describes the price of a suggested post.
pub type SuggestedPostPrice {
  SuggestedPostPrice(
    /// Currency in which the post will be paid. Currently, must be one of "XTR" for Telegram Stars or "TON" for toncoins
    currency: String,
    /// The amount of the currency that will be paid for the post in the smallest units of the currency, i.e. Telegram Stars or nanotoncoins. Currently, price in Telegram Stars must be between 5 and 100000, and price in nanotoncoins must be between 10000000 and 10000000000000.
    amount: Int,
  )
}

/// **Official reference:** Contains information about a suggested post.
pub type SuggestedPostInfo {
  SuggestedPostInfo(
    /// State of the suggested post. Currently, it can be one of "pending", "approved", "declined".
    state: String,
    /// Optional. Proposed price of the post. If the field is omitted, then the post is unpaid.
    price: Option(SuggestedPostPrice),
    /// Optional. Proposed send date of the post. If the field is omitted, then the post can be published at any time within 30 days at the sole discretion of the user or administrator who approves it.
    send_date: Option(Int),
  )
}

/// **Official reference:** Contains parameters of a post that is being suggested by the bot.
pub type SuggestedPostParameters {
  SuggestedPostParameters(
    /// Optional. Proposed price for the post. If the field is omitted, then the post is unpaid.
    price: Option(SuggestedPostPrice),
    /// Optional. Proposed send date of the post. If specified, then the date must be between 300 second and 2678400 seconds (30 days) in the future. If the field is omitted, then the post can be published at any time within 30 days at the sole discretion of the user who approves it.
    send_date: Option(Int),
  )
}

/// **Official reference:** Describes a topic of a direct messages chat.
pub type DirectMessagesTopic {
  DirectMessagesTopic(
    /// Unique identifier of the topic. This number may have more than 32 significant bits and some programming languages may have difficulty/silent defects in interpreting it. But it has at most 52 significant bits, so a 64-bit integer or double-precision float type are safe for storing this identifier.
    topic_id: Int,
    /// Optional. Information about the user that created the topic. Currently, it is always present
    user: Option(User),
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

/// **Official reference:** This object represents the audios displayed on a user's profile.
pub type UserProfileAudios {
  UserProfileAudios(
    /// Total number of profile audios for the target user
    total_count: Int,
    /// Requested profile audios
    audios: List(Audio),
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
    /// Optional. Unique identifier of the custom emoji shown before the text of the button.
    icon_custom_emoji_id: Option(String),
    /// Optional. Style of the button. Must be one of "danger" (red), "success" (green) or "primary" (blue).
    style: Option(String),
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
    /// Optional. Unique identifier of the custom emoji shown before the text of the button.
    icon_custom_emoji_id: Option(String),
    /// Optional. Style of the button. Must be one of "danger" (red), "success" (green) or "primary" (blue).
    style: Option(String),
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
    /// True, if the administrator can access the chat event log, get boost list, see hidden supergroup and channel members, report spam messages, ignore slow mode, and send messages to the chat without paying Telegram Stars. Implied by any other administrator privilege.
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
    /// Optional. True, if the administrator can post messages in the channel, approve suggested posts, or access channel statistics; for channels only
    can_post_messages: Option(Bool),
    /// Optional. True, if the administrator can edit messages of other users and can pin messages; for channels only
    can_edit_messages: Option(Bool),
    /// Optional. True, if the user is allowed to pin messages; for groups and supergroups only
    can_pin_messages: Option(Bool),
    /// Optional. True, if the user is allowed to create, rename, close, and reopen forum topics; for supergroups only
    can_manage_topics: Option(Bool),
    /// Optional. True, if the administrator can manage direct messages of the channel and decline suggested posts; for channels only
    can_manage_direct_messages: Option(Bool),
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
    /// True, if the administrator can access the chat event log, get boost list, see hidden supergroup and channel members, report spam messages, ignore slow mode, and send messages to the chat without paying Telegram Stars. Implied by any other administrator privilege.
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
    /// Optional. True, if the administrator can manage direct messages of the channel and decline suggested posts; for channels only
    can_manage_direct_messages: Option(Bool),
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

/// **Official reference:** Describes the position of a clickable area within a story.
pub type StoryAreaPosition {
  StoryAreaPosition(
    /// The abscissa of the area's center, as a percentage of the media width
    x_percentage: Float,
    /// The ordinate of the area's center, as a percentage of the media height
    y_percentage: Float,
    /// The width of the area's rectangle, as a percentage of the media width
    width_percentage: Float,
    /// The height of the area's rectangle, as a percentage of the media height
    height_percentage: Float,
    /// The clockwise rotation angle of the rectangle, in degrees; 0-360
    rotation_angle: Float,
    /// The radius of the rectangle corner rounding, as a percentage of the media width
    corner_radius_percentage: Float,
  )
}

/// **Official reference:** Describes the physical address of a location.
pub type LocationAddress {
  LocationAddress(
    /// The two-letter ISO 3166-1 alpha-2 country code of the country where the location is located
    country_code: String,
    /// Optional. State of the location
    state: Option(String),
    /// Optional. City of the location
    city: Option(String),
    /// Optional. Street address of the location
    street: Option(String),
  )
}

/// **Official reference:** Describes the type of a clickable area on a story. Currently, it can be one of
pub type StoryAreaType {
  StoryAreaType(
    /// Type of the area, always “location”
    type_: String,
    /// Location latitude in degrees
    latitude: Float,
    /// Location longitude in degrees
    longitude: Float,
    /// Optional. Address of the location
    address: Option(LocationAddress),
  )
}

/// **Official reference:** Describes a story area pointing to a location. Currently, a story can have up to 10 location areas.
pub type StoryAreaTypeLocation {
  StoryAreaTypeLocation(
    /// Type of the area, always “location”
    type_: String,
    /// Location latitude in degrees
    latitude: Float,
    /// Location longitude in degrees
    longitude: Float,
    /// Optional. Address of the location
    address: Option(LocationAddress),
  )
}

/// **Official reference:** Describes a story area pointing to a suggested reaction. Currently, a story can have up to 5 suggested reaction areas.
pub type StoryAreaTypeSuggestedReaction {
  StoryAreaTypeSuggestedReaction(
    /// Type of the area, always “suggested_reaction”
    type_: String,
    /// Type of the reaction
    reaction_type: ReactionType,
    /// Optional. Pass True if the reaction area has a dark background
    is_dark: Option(Bool),
    /// Optional. Pass True if reaction area corner is flipped
    is_flipped: Option(Bool),
  )
}

/// **Official reference:** Describes a story area pointing to an HTTP or tg:// link. Currently, a story can have up to 3 link areas.
pub type StoryAreaTypeLink {
  StoryAreaTypeLink(
    /// Type of the area, always “link”
    type_: String,
    /// HTTP or tg:// URL to be opened when the area is clicked
    url: String,
  )
}

/// **Official reference:** Describes a story area containing weather information. Currently, a story can have up to 3 weather areas.
pub type StoryAreaTypeWeather {
  StoryAreaTypeWeather(
    /// Type of the area, always “weather”
    type_: String,
    /// Temperature, in degree Celsius
    temperature: Float,
    /// Emoji representing the weather
    emoji: String,
    /// A color of the area background in the ARGB format
    background_color: Int,
  )
}

/// **Official reference:** Describes a story area pointing to a unique gift. Currently, a story can have at most 1 unique gift area.
pub type StoryAreaTypeUniqueGift {
  StoryAreaTypeUniqueGift(
    /// Type of the area, always “unique_gift”
    type_: String,
    /// Unique name of the gift
    name: String,
  )
}

/// **Official reference:** Describes a clickable area on a story media.
pub type StoryArea {
  StoryArea(
    /// Position of the area
    position: StoryAreaPosition,
    /// Type of the area
    type_: StoryAreaType,
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
    /// Optional. True, if the name of the topic wasn't specified explicitly by its creator and likely needs to be changed by the bot
    is_name_implicit: Option(Bool),
  )
}

/// **Official reference:** This object describes the rating of a user.
pub type UserRating {
  UserRating(
    /// Current level of the user, indicating their reliability when purchasing digital goods and services. A higher level suggests a more trustworthy customer; a negative level is likely reason for concern.
    level: Int,
    /// Numerical value of the user's rating; the higher the rating, the better
    rating: Int,
    /// The rating value required to get the current level
    current_level_rating: Int,
    /// Optional. The rating value required to get to the next level; omitted if the maximum level was reached
    next_level_rating: Option(Int),
  )
}

/// **Official reference:** This object describes the model of a unique gift.
pub type UniqueGiftModel {
  UniqueGiftModel(
    /// Name of the model
    name: String,
    /// The sticker that represents the unique gift
    sticker: Sticker,
    /// The number of unique gifts that receive this model for every 1000 gifts upgraded
    rarity_per_mille: Int,
    /// Optional. Rarity of the model if it is a crafted model. Currently, can be "uncommon", "rare", "epic", or "legendary".
    rarity: Option(String),
  )
}

/// **Official reference:** This object describes the symbol shown on the pattern of a unique gift.
pub type UniqueGiftSymbol {
  UniqueGiftSymbol(
    /// Name of the symbol
    name: String,
    /// The sticker that represents the unique gift
    sticker: Sticker,
    /// The number of unique gifts that receive this model for every 1000 gifts upgraded
    rarity_per_mille: Int,
  )
}

/// **Official reference:** This object describes the colors of the backdrop of a unique gift.
pub type UniqueGiftBackdropColors {
  UniqueGiftBackdropColors(
    /// The color in the center of the backdrop in RGB format
    center_color: Int,
    /// The color on the edges of the backdrop in RGB format
    edge_color: Int,
    /// The color to be applied to the symbol in RGB format
    symbol_color: Int,
    /// The color for the text on the backdrop in RGB format
    text_color: Int,
  )
}

/// **Official reference:** This object describes the backdrop of a unique gift.
pub type UniqueGiftBackdrop {
  UniqueGiftBackdrop(
    /// Name of the backdrop
    name: String,
    /// Colors of the backdrop
    colors: UniqueGiftBackdropColors,
    /// The number of unique gifts that receive this backdrop for every 1000 gifts upgraded
    rarity_per_mille: Int,
  )
}

/// **Official reference:** This object describes the color scheme for a user's name, replies to messages and link previews based on a unique gift.
pub type UniqueGiftColors {
  UniqueGiftColors(
    /// Custom emoji identifier of the unique gift's model
    model_custom_emoji_id: String,
    /// Custom emoji identifier of the unique gift's symbol
    symbol_custom_emoji_id: String,
    /// Main color used in light themes; RGB format
    light_theme_main_color: Int,
    /// List of 1-3 additional colors used in light themes; RGB format
    light_theme_other_colors: List(Int),
    /// Main color used in dark themes; RGB format
    dark_theme_main_color: Int,
    /// List of 1-3 additional colors used in dark themes; RGB format
    dark_theme_other_colors: List(Int),
  )
}

/// **Official reference:** This object describes a unique gift that was upgraded from a regular gift.
pub type UniqueGift {
  UniqueGift(
    /// Identifier of the regular gift from which the gift was upgraded
    gift_id: String,
    /// Human-readable name of the regular gift from which this unique gift was upgraded
    base_name: String,
    /// Unique name of the gift. This name can be used in https://t.me/nft/... links and story areas
    name: String,
    /// Unique number of the upgraded gift among gifts upgraded from the same regular gift
    number: Int,
    /// Model of the gift
    model: UniqueGiftModel,
    /// Symbol of the gift
    symbol: UniqueGiftSymbol,
    /// Backdrop of the gift
    backdrop: UniqueGiftBackdrop,
    /// Optional. True, if the original regular gift was exclusively purchaseable by Telegram Premium subscribers
    is_premium: Option(Bool),
    /// Optional. True, if the gift was used to craft another gift and isn't available anymore
    is_burned: Option(Bool),
    /// Optional. True, if the gift is assigned from the TON blockchain and can't be resold or transferred in Telegram
    is_from_blockchain: Option(Bool),
    /// Optional. The color scheme that can be used by the gift's owner for the chat's name, replies to messages and link previews; for business account gifts and gifts that are currently on sale only
    colors: Option(UniqueGiftColors),
    /// Optional. Information about the chat that published the gift
    publisher_chat: Option(Chat),
  )
}

/// **Official reference:** Describes a service message about a regular gift that was sent or received.
pub type GiftInfo {
  GiftInfo(
    /// Information about the gift
    gift: Gift,
    /// Optional. Unique identifier of the received gift for the bot; only present for gifts received on behalf of business accounts
    owned_gift_id: Option(String),
    /// Optional. Number of Telegram Stars that can be claimed by the receiver by converting the gift; omitted if conversion to Telegram Stars is impossible
    convert_star_count: Option(Int),
    /// Optional. Number of Telegram Stars that were prepaid for the ability to upgrade the gift
    prepaid_upgrade_star_count: Option(Int),
    /// Optional. True, if the gift's upgrade was purchased after the gift was sent
    is_upgrade_separate: Option(Bool),
    /// Optional. True, if the gift can be upgraded to a unique gift
    can_be_upgraded: Option(Bool),
    /// Optional. Text of the message that was added to the gift
    text: Option(String),
    /// Optional. Special entities that appear in the text
    entities: Option(List(MessageEntity)),
    /// Optional. True, if the sender and gift text are shown only to the gift receiver; otherwise, everyone will be able to see them
    is_private: Option(Bool),
    /// Optional. Unique number reserved for this gift when upgraded. See the number field in UniqueGift
    unique_gift_number: Option(Int),
  )
}

/// **Official reference:** Describes a service message about a unique gift that was sent or received.
pub type UniqueGiftInfo {
  UniqueGiftInfo(
    /// Information about the gift
    gift: UniqueGift,
    /// Origin of the gift. Currently, either "upgrade" for gifts upgraded from regular gifts, "transfer" for gifts transferred from other users or channels, "resale" for gifts bought from other users, "gifted_upgrade" for upgrades purchased after the gift was sent, or "offer" for gifts bought or sold through gift purchase offers
    origin: String,
    /// Optional. For gifts bought from other users, the currency in which the payment for the gift was done. Currently, one of "XTR" for Telegram Stars or "TON" for toncoins.
    last_resale_currency: Option(String),
    /// Optional. For gifts bought from other users, the price paid for the gift in either Telegram Stars or nanotoncoins
    last_resale_amount: Option(Int),
    /// Optional. Unique identifier of the received gift for the bot; only present for gifts received on behalf of business accounts
    owned_gift_id: Option(String),
    /// Optional. Number of Telegram Stars that must be paid to transfer the gift; omitted if the bot cannot transfer the gift
    transfer_star_count: Option(Int),
    /// Optional. Point in time (Unix timestamp) when the gift can be transferred. If it is in the past, then the gift can be transferred now
    next_transfer_date: Option(Int),
  )
}

/// **Official reference:** This object describes a gift received and owned by a user or a chat. Currently, it can be one of
pub type OwnedGift {
  OwnedGift(
    /// Type of the gift, always “regular”
    type_: String,
    /// Information about the regular gift
    gift: Gift,
    /// Optional. Unique identifier of the gift for the bot; for gifts received on behalf of business accounts only
    owned_gift_id: Option(String),
    /// Optional. Sender of the gift if it is a known user
    sender_user: Option(User),
    /// Date the gift was sent in Unix time
    send_date: Int,
    /// Optional. Text of the message that was added to the gift
    text: Option(String),
    /// Optional. Special entities that appear in the text
    entities: Option(List(MessageEntity)),
    /// Optional. True, if the sender and gift text are shown only to the gift receiver; otherwise, everyone will be able to see them
    is_private: Option(Bool),
    /// Optional. True, if the gift is displayed on the account's profile page; for gifts received on behalf of business accounts only
    is_saved: Option(Bool),
    /// Optional. True, if the gift can be upgraded to a unique gift; for gifts received on behalf of business accounts only
    can_be_upgraded: Option(Bool),
    /// Optional. True, if the gift was refunded and isn't available anymore
    was_refunded: Option(Bool),
    /// Optional. Number of Telegram Stars that can be claimed by the receiver instead of the gift; omitted if the gift cannot be converted to Telegram Stars
    convert_star_count: Option(Int),
    /// Optional. Number of Telegram Stars that were paid by the sender for the ability to upgrade the gift
    prepaid_upgrade_star_count: Option(Int),
  )
}

/// **Official reference:** Describes a regular gift owned by a user or a chat.
pub type OwnedGiftRegular {
  OwnedGiftRegular(
    /// Type of the gift, always "regular"
    type_: String,
    /// Information about the regular gift
    gift: Gift,
    /// Optional. Unique identifier of the gift for the bot; for gifts received on behalf of business accounts only
    owned_gift_id: Option(String),
    /// Optional. Sender of the gift if it is a known user
    sender_user: Option(User),
    /// Date the gift was sent in Unix time
    send_date: Int,
    /// Optional. Text of the message that was added to the gift
    text: Option(String),
    /// Optional. Special entities that appear in the text
    entities: Option(List(MessageEntity)),
    /// Optional. True, if the sender and gift text are shown only to the gift receiver; otherwise, everyone will be able to see them
    is_private: Option(Bool),
    /// Optional. True, if the gift is displayed on the account's profile page; for gifts received on behalf of business accounts only
    is_saved: Option(Bool),
    /// Optional. True, if the gift can be upgraded to a unique gift; for gifts received on behalf of business accounts only
    can_be_upgraded: Option(Bool),
    /// Optional. True, if the gift was refunded and isn't available anymore
    was_refunded: Option(Bool),
    /// Optional. Number of Telegram Stars that can be claimed by the receiver instead of the gift; omitted if the gift cannot be converted to Telegram Stars; for gifts received on behalf of business accounts only
    convert_star_count: Option(Int),
    /// Optional. Number of Telegram Stars that were paid for the ability to upgrade the gift
    prepaid_upgrade_star_count: Option(Int),
    /// Optional. True, if the gift's upgrade was purchased after the gift was sent; for gifts received on behalf of business accounts only
    is_upgrade_separate: Option(Bool),
    /// Optional. Unique number reserved for this gift when upgraded. See the number field in UniqueGift
    unique_gift_number: Option(Int),
  )
}

/// **Official reference:** Describes a unique gift received and owned by a user or a chat.
pub type OwnedGiftUnique {
  OwnedGiftUnique(
    /// Type of the gift, always “unique”
    type_: String,
    /// Information about the unique gift
    gift: UniqueGift,
    /// Optional. Unique identifier of the received gift for the bot; for gifts received on behalf of business accounts only
    owned_gift_id: Option(String),
    /// Optional. Sender of the gift if it is a known user
    sender_user: Option(User),
    /// Date the gift was sent in Unix time
    send_date: Int,
    /// Optional. True, if the gift is displayed on the account's profile page; for gifts received on behalf of business accounts only
    is_saved: Option(Bool),
    /// Optional. True, if the gift can be transferred to another owner; for gifts received on behalf of business accounts only
    can_be_transferred: Option(Bool),
    /// Optional. Number of Telegram Stars that must be paid to transfer the gift; omitted if the bot cannot transfer the gift
    transfer_star_count: Option(Int),
    /// Optional. Point in time (Unix timestamp) when the gift can be transferred. If it is in the past, then the gift can be transferred now
    next_transfer_date: Option(Int),
  )
}

/// **Official reference:** Contains the list of gifts received and owned by a user or a chat.
pub type OwnedGifts {
  OwnedGifts(
    /// The total number of gifts owned by the user or the chat
    total_count: Int,
    /// The list of gifts
    gifts: List(OwnedGift),
    /// Optional. Offset for the next request. If empty, then there are no more results
    next_offset: Option(String),
  )
}

/// **Official reference:** This object describes the types of gifts that can be gifted to a user or a chat.
pub type AcceptedGiftTypes {
  AcceptedGiftTypes(
    /// True, if unlimited regular gifts are accepted
    unlimited_gifts: Bool,
    /// True, if limited regular gifts are accepted
    limited_gifts: Bool,
    /// True, if unique gifts or gifts that can be upgraded to unique for free are accepted
    unique_gifts: Bool,
    /// True, if a Telegram Premium subscription is accepted
    premium_subscription: Bool,
    /// True, if transfers of unique gifts from channels are accepted
    gifts_from_channels: Bool,
  )
}

/// **Official reference:** Describes an amount of Telegram Stars.
pub type StarAmount {
  StarAmount(
    /// Integer amount of Telegram Stars, rounded to 0; can be negative
    amount: Int,
    /// Optional. The number of 1/1000000000 shares of Telegram Stars; from -999999999 to 999999999; can be negative if and only if amount is non-positive
    nanostar_amount: Option(Int),
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
    can_delete_sent_messages: Option(Bool),
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

/// **Official reference:** A static profile photo in the .JPG format.
pub type InputProfilePhotoStatic {
  InputProfilePhotoStatic(
    /// Type of the profile photo, must be static
    type_: String,
    /// The static profile photo. Profile photos can't be reused and can only be uploaded as a new file, so you can pass “attach://<file_attach_name>” if the photo was uploaded using multipart/form-data under <file_attach_name>. More information on Sending Files »
    photo: String,
  )
}

/// **Official reference:** An animated profile photo in the MPEG4 format.
pub type InputProfilePhotoAnimated {
  InputProfilePhotoAnimated(
    /// Type of the profile photo, must be animated
    type_: String,
    /// The animated profile photo. Profile photos can't be reused and can only be uploaded as a new file, so you can pass “attach://<file_attach_name>” if the photo was uploaded using multipart/form-data under <file_attach_name>. More information on Sending Files »
    animation: String,
    /// Optional. Timestamp in seconds of the frame that will be used as the static profile photo. Defaults to 0.0.
    main_frame_timestamp: Option(Float),
  )
}

/// **Official reference:** This object describes the content of a story to post. Currently, it can be one of
pub type InputStoryContent {
  InputStoryContent(
    /// Type of the content, must be photo
    type_: String,
    /// The photo to post as a story. The photo must be of the size 1080x1920 and must not exceed 10 MB. The photo can't be reused and can only be uploaded as a new file, so you can pass “attach://<file_attach_name>” if the photo was uploaded using multipart/form-data under <file_attach_name>. More information on Sending Files »
    photo: String,
  )
}

/// **Official reference:** Describes a photo to post as a story.
pub type InputStoryContentPhoto {
  InputStoryContentPhoto(
    /// Type of the content, must be photo
    type_: String,
    /// The photo to post as a story. The photo must be of the size 1080x1920 and must not exceed 10 MB. The photo can't be reused and can only be uploaded as a new file, so you can pass “attach://<file_attach_name>” if the photo was uploaded using multipart/form-data under <file_attach_name>. More information on Sending Files »
    photo: String,
  )
}

/// **Official reference:** Describes a video to post as a story.
pub type InputStoryContentVideo {
  InputStoryContentVideo(
    /// Type of the content, must be video
    type_: String,
    /// The video to post as a story. The video must be of the size 720x1280, streamable, encoded with H.265 codec, with key frames added each second in the MPEG4 format, and must not exceed 30 MB. The video can't be reused and can only be uploaded as a new file, so you can pass “attach://<file_attach_name>” if the video was uploaded using multipart/form-data under <file_attach_name>. More information on Sending Files »
    video: String,
    /// Optional. Precise duration of the video in seconds; 0-60
    duration: Option(Float),
    /// Optional. Timestamp in seconds of the frame that will be used as the static cover for the story. Defaults to 0.0.
    cover_frame_timestamp: Option(Float),
    /// Optional. Pass True if the video has no sound
    is_animation: Option(Bool),
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

/// **Official reference:** This object describes the background of a gift.
pub type GiftBackground {
  GiftBackground(
    /// Center color of the background in RGB format
    center_color: Int,
    /// Edge color of the background in RGB format
    edge_color: Int,
    /// Text color of the background in RGB format
    text_color: Int,
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
    /// Optional. True, if the gift can only be purchased by Telegram Premium subscribers
    is_premium: Option(Bool),
    /// Optional. True, if the gift can be used (after being upgraded) to customize a user's appearance
    has_colors: Option(Bool),
    /// Optional. The total number of gifts of this type that can be sent by all users; for limited gifts only
    total_count: Option(Int),
    /// Optional. The number of remaining gifts of this type that can be sent by all users; for limited gifts only
    remaining_count: Option(Int),
    /// Optional. The total number of gifts of this type that can be sent by the bot; for limited gifts only
    personal_total_count: Option(Int),
    /// Optional. The number of remaining gifts of this type that can be sent by the bot; for limited gifts only
    personal_remaining_count: Option(Int),
    /// Optional. Background of the gift
    background: Option(GiftBackground),
    /// Optional. The total number of different unique gifts that can be obtained by upgrading the gift
    unique_gift_variant_count: Option(Int),
    /// Optional. Information about the chat that published the gift
    publisher_chat: Option(Chat),
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

// Parameter types from encoder.gleam ------------------------------------------------------------

// SendMessageReplyMarkupParameters ------------------------------------------------------------

pub type SendMessageReplyMarkupParameters {
  SendMessageReplyInlineKeyboardMarkupParameters(InlineKeyboardMarkup)
  SendMessageReplyReplyKeyboardMarkupParameters(ReplyKeyboardMarkup)
  SendMessageReplyRemoveKeyboardMarkupParameters(ReplyKeyboardRemove)
  SendMessageReplyForceReplyMarkupParameters(ForceReply)
}

// AnswerCallbackQueryParameters ------------------------------------------------------------

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

// SetChatMenuButtonParameters ----------------------------------------------------------------------------------------

pub type SetChatMenuButtonParameters {
  SetChatMenuButtonParameters(
    /// Unique identifier for the target private chat. If not specified, default bot's menu button will be changed
    chat_id: Option(Int),
    /// A JSON-serialized object for the bot's new menu button. Defaults to MenuButtonDefault
    menu_button: Option(MenuButton),
  )
}

// SendMessageParameters ------------------------------------------------------------------------

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

// RefundStarPaymentParameters ------------------------------------------------------------

pub type RefundStarPaymentParameters {
  RefundStarPaymentParameters(
    /// Identifier of the user whose payment will be refunded
    user_id: Int,
    /// Telegram payment identifier
    telegram_payment_charge_id: String,
  )
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

// GetStickerSetParameters -------------------------------------------------------------------------------------------
pub type GetStickerSetParameters {
  GetStickerSetParameters(
    /// Name of the sticker set
    name: String,
  )
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

// GetUserProfileAudiosParameters --------------------------------------------------------------------------------------
pub type GetUserProfileAudiosParameters {
  GetUserProfileAudiosParameters(
    /// Unique identifier of the target user
    user_id: Int,
    /// Sequential number of the first audio to be returned (0-based)
    offset: Option(Int),
    /// Limits the number of audios to be retrieved (1-100)
    limit: Option(Int),
  )
}

// SetMyProfilePhotoParameters --------------------------------------------------------------------------------------
pub type SetMyProfilePhotoParameters {
  SetMyProfilePhotoParameters(
    /// The new profile photo to set
    photo: InputProfilePhoto,
  )
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

// EditMessageLiveLocationParameters ----------------------------------------------
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

// StopMessageLiveLocationParameters ----------------------------------------------
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

// DeleteMessageParameters
pub type DeleteMessageParameters {
  DeleteMessageParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Identifier of the message to delete
    message_id: Int,
  )
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

/// Pass False for all boolean parameters to demote a user.
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

// BanChatSenderChatParameters -------------------------------------------------------------------------------------
pub type BanChatSenderChatParameters {
  BanChatSenderChatParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target sender chat
    sender_chat_id: Int,
  )
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

// ExportChatInviteLinkParameters -----------------------------------------------------------------------------------
pub type ExportChatInviteLinkParameters {
  ExportChatInviteLinkParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
  )
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

// RevokeChatInviteLinkParameters ------------------------------------------------------------
pub type RevokeChatInviteLinkParameters {
  RevokeChatInviteLinkParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// The invite link to revoke
    invite_link: String,
  )
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

// DeclineChatJoinRequestParameters ------------------------------------------------------------
pub type DeclineChatJoinRequestParameters {
  DeclineChatJoinRequestParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
  )
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

// DeleteChatPhotoParameters ------------------------------------------------------------
pub type DeleteChatPhotoParameters {
  DeleteChatPhotoParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
  )
}

// SetChatTitleParameters ------------------------------------------------------------
pub type SetChatTitleParameters {
  SetChatTitleParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// New chat title, 1-128 characters
    title: String,
  )
}

// SetChatDescriptionParameters ------------------------------------------------------------
pub type SetChatDescriptionParameters {
  SetChatDescriptionParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// New chat description, 0-255 characters
    description: Option(String),
  )
}

// PinChatMessageParameters ------------------------------------------------------------
pub type PinChatMessageParameters {
  PinChatMessageParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Identifier of a message to pin
    message_id: Int,
    /// Unique identifier of the business connection on behalf of which the message will be pinned
    business_connection_id: Option(String),
    /// Pass True if it is not necessary to send a notification to all chat members about the new pinned message
    disable_notification: Option(Bool),
  )
}

// UnpinChatMessageParameters ------------------------------------------------------------
pub type UnpinChatMessageParameters {
  UnpinChatMessageParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Identifier of the message to unpin. If not specified, the most recent pinned message (by sending date) will be unpinned.
    message_id: Option(Int),
    /// Unique identifier of the business connection on behalf of which the message will be unpinned
    business_connection_id: Option(String),
  )
}

// UnpinAllChatMessagesParameters ------------------------------------------------------------
pub type UnpinAllChatMessagesParameters {
  UnpinAllChatMessagesParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
  )
}

// LeaveChatParameters ------------------------------------------------------------
pub type LeaveChatParameters {
  LeaveChatParameters(
    /// Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
    chat_id: IntOrString,
  )
}

// GetChatAdministratorsParameters ------------------------------------------------------------
pub type GetChatAdministratorsParameters {
  GetChatAdministratorsParameters(
    /// Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
    chat_id: IntOrString,
  )
}

// GetChatMemberCountParameters ------------------------------------------------------------
pub type GetChatMemberCountParameters {
  GetChatMemberCountParameters(
    /// Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
    chat_id: IntOrString,
  )
}

// GetChatMemberParameters ------------------------------------------------------------
pub type GetChatMemberParameters {
  GetChatMemberParameters(
    /// Unique identifier for the target chat or username of the target supergroup or channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
  )
}

// SetChatStickerSetParameters ------------------------------------------------------------
pub type SetChatStickerSetParameters {
  SetChatStickerSetParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
    /// Name of the sticker set to be set as the group sticker set
    sticker_set_name: String,
  )
}

// DeleteChatStickerSetParameters ------------------------------------------------------------
pub type DeleteChatStickerSetParameters {
  DeleteChatStickerSetParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
  )
}

// CreateForumTopicParameters ------------------------------------------------------------
pub type CreateForumTopicParameters {
  CreateForumTopicParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
    /// Topic name, 1-128 characters
    name: String,
    /// Color of the topic icon in RGB format
    icon_color: Option(Int),
    /// Unique identifier of the custom emoji shown as the topic icon
    icon_custom_emoji_id: Option(String),
  )
}

// EditForumTopicParameters ------------------------------------------------------------
pub type EditForumTopicParameters {
  EditForumTopicParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread of the forum topic
    message_thread_id: Int,
    /// New topic name, 0-128 characters
    name: Option(String),
    /// New unique identifier of the custom emoji shown as the topic icon
    icon_custom_emoji_id: Option(String),
  )
}

// CloseForumTopicParameters ------------------------------------------------------------
pub type CloseForumTopicParameters {
  CloseForumTopicParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread of the forum topic
    message_thread_id: Int,
  )
}

// ReopenForumTopicParameters ------------------------------------------------------------
pub type ReopenForumTopicParameters {
  ReopenForumTopicParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread of the forum topic
    message_thread_id: Int,
  )
}

// DeleteForumTopicParameters ------------------------------------------------------------
pub type DeleteForumTopicParameters {
  DeleteForumTopicParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread of the forum topic
    message_thread_id: Int,
  )
}

// UnpinAllForumTopicMessagesParameters ------------------------------------------------------------
pub type UnpinAllForumTopicMessagesParameters {
  UnpinAllForumTopicMessagesParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread of the forum topic
    message_thread_id: Int,
  )
}

// UnpinAllGeneralForumTopicPinnedMessagesParameters ------------------------------------------------------------
pub type UnpinAllGeneralForumTopicPinnedMessagesParameters {
  UnpinAllGeneralForumTopicPinnedMessagesParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
  )
}

// EditGeneralForumTopicParameters ------------------------------------------------------------
pub type EditGeneralForumTopicParameters {
  EditGeneralForumTopicParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
    /// New topic name, 1-128 characters
    name: String,
  )
}

// CloseGeneralForumTopicParameters ------------------------------------------------------------
pub type CloseGeneralForumTopicParameters {
  CloseGeneralForumTopicParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
  )
}

// ReopenGeneralForumTopicParameters ------------------------------------------------------------
pub type ReopenGeneralForumTopicParameters {
  ReopenGeneralForumTopicParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
  )
}

// HideGeneralForumTopicParameters ------------------------------------------------------------
pub type HideGeneralForumTopicParameters {
  HideGeneralForumTopicParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
  )
}

// UnhideGeneralForumTopicParameters ------------------------------------------------------------
pub type UnhideGeneralForumTopicParameters {
  UnhideGeneralForumTopicParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
  )
}

// UnpinAllGeneralForumTopicMessagesParameters ------------------------------------------------------------
pub type UnpinAllGeneralForumTopicMessagesParameters {
  UnpinAllGeneralForumTopicMessagesParameters(
    /// Unique identifier for the target chat or username of the target supergroup (in the format `@supergroupusername`)
    chat_id: IntOrString,
  )
}

// GetUserChatBoostsParameters ------------------------------------------------------------
pub type GetUserChatBoostsParameters {
  GetUserChatBoostsParameters(
    /// Unique identifier for the chat or username of the channel (in the format @channelusername)
    chat_id: IntOrString,
    /// Unique identifier of the target user
    user_id: Int,
  )
}

// GetBusinessConnectionParameters ------------------------------------------------------------
pub type GetBusinessConnectionParameters {
  GetBusinessConnectionParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
  )
}

// SetMyNameParameters ------------------------------------------------------------
pub type SetMyNameParameters {
  SetMyNameParameters(
    /// New bot name; 0-64 characters. Pass an empty string to remove the dedicated name for the given language.
    name: Option(String),
    /// A two-letter ISO 639-1 language code. If empty, the name will be shown to all users for whose language there is no dedicated name.
    language_code: Option(String),
  )
}

// GetMyNameParameters ------------------------------------------------------------
pub type GetMyNameParameters {
  GetMyNameParameters(
    /// A two-letter ISO 639-1 language code or an empty string
    language_code: Option(String),
  )
}

// SetMyDescriptionParameters ------------------------------------------------------------
pub type SetMyDescriptionParameters {
  SetMyDescriptionParameters(
    /// New bot description; 0-512 characters. Pass an empty string to remove the dedicated description for the given language.
    description: Option(String),
    /// A two-letter ISO 639-1 language code. If empty, the description will be applied to all users for whose language there is no dedicated description.
    language_code: Option(String),
  )
}

// GetMyDescriptionParameters ------------------------------------------------------------
pub type GetMyDescriptionParameters {
  GetMyDescriptionParameters(
    /// A two-letter ISO 639-1 language code or an empty string
    language_code: Option(String),
  )
}

// SetMyShortDescriptionParameters ------------------------------------------------------------
pub type SetMyShortDescriptionParameters {
  SetMyShortDescriptionParameters(
    /// New short description for the bot; 0-120 characters. Pass an empty string to remove the dedicated short description for the given language.
    short_description: Option(String),
    /// A two-letter ISO 639-1 language code. If empty, the short description will be applied to all users for whose language there is no dedicated short description.
    language_code: Option(String),
  )
}

// GetMyShortDescriptionParameters ------------------------------------------------------------
pub type GetMyShortDescriptionParameters {
  GetMyShortDescriptionParameters(
    /// A two-letter ISO 639-1 language code or an empty string
    language_code: Option(String),
  )
}

// GetChatMenuButtonParameters ------------------------------------------------------------
pub type GetChatMenuButtonParameters {
  GetChatMenuButtonParameters(
    /// Unique identifier for the target private chat. If not specified, default bot's menu button will be returned
    chat_id: Option(Int),
  )
}

// SetMyDefaultAdministratorRightsParameters ------------------------------------------------------------
pub type SetMyDefaultAdministratorRightsParameters {
  SetMyDefaultAdministratorRightsParameters(
    /// A JSON-serialized object describing new default administrator rights. If not specified, the default administrator rights will be cleared.
    rights: Option(ChatAdministratorRights),
    /// Pass True to change the default administrator rights of the bot in channels. Otherwise, the default administrator rights of the bot for groups and supergroups will be changed.
    for_channels: Option(Bool),
  )
}

// GetMyDefaultAdministratorRightsParameters ------------------------------------------------------------
pub type GetMyDefaultAdministratorRightsParameters {
  GetMyDefaultAdministratorRightsParameters(
    /// Pass True to get default administrator rights of the bot in channels. Otherwise, default administrator rights of the bot for groups and supergroups will be returned.
    for_channels: Option(Bool),
  )
}

// SendGiftParameters ------------------------------------------------------------
pub type SendGiftParameters {
  SendGiftParameters(
    /// Required if chat_id is not specified. Unique identifier of the target user who will receive the gift.
    user_id: Option(Int),
    /// Required if user_id is not specified. Unique identifier for the chat or username of the channel (in the format @channelusername) that will receive the gift.
    chat_id: Option(IntOrString),
    /// Identifier of the gift
    gift_id: String,
    /// Pass True to pay for the gift upgrade from the bot's balance, thereby making the upgrade free for the receiver
    pay_for_upgrade: Option(Bool),
    /// Text that will be shown along with the gift; 0-128 characters
    text: Option(String),
    /// Mode for parsing entities in the text. See formatting options for more details.
    text_parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in the gift text. It can be specified instead of text_parse_mode.
    text_entities: Option(List(MessageEntity)),
  )
}

// GiftPremiumSubscriptionParameters ------------------------------------------------------------
pub type GiftPremiumSubscriptionParameters {
  GiftPremiumSubscriptionParameters(
    /// Unique identifier of the target user who will receive a Telegram Premium subscription
    user_id: Int,
    /// Number of months the Telegram Premium subscription will be active for the user; must be one of 3, 6, or 12
    month_count: Int,
    /// Number of Telegram Stars to pay for the Telegram Premium subscription; must be 1000 for 3 months, 1500 for 6 months, and 2500 for 12 months
    star_count: Int,
    /// Text that will be shown along with the service message about the subscription; 0-128 characters
    text: Option(String),
    /// Mode for parsing entities in the text. See formatting options for more details.
    text_parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in the gift text. It can be specified instead of text_parse_mode.
    text_entities: Option(List(MessageEntity)),
  )
}

// SendMessageDraftParameters ------------------------------------------------------------
/// Parameters for the sendMessageDraft method
pub type SendMessageDraftParameters {
  SendMessageDraftParameters(
    /// Identifier for the target private chat
    chat_id: Int,
    /// Unique identifier of the message draft; must be non-zero. Changes of drafts with the same identifier are animated
    draft_id: Int,
    /// Text of the message to be sent, 1-4096 characters after entities parsing
    text: String,
    /// Optional. Identifier for the target message thread
    message_thread_id: Option(Int),
    /// Optional. Mode for parsing entities in the message text
    parse_mode: Option(String),
    /// Optional. A JSON-serialized list of special entities that appear in message text
    entities: Option(List(MessageEntity)),
  )
}

// GetUserGiftsParameters ------------------------------------------------------------
/// Parameters for the getUserGifts method
pub type GetUserGiftsParameters {
  GetUserGiftsParameters(
    /// Unique identifier of the user
    user_id: Int,
    /// Optional. Pass True to exclude gifts that can be purchased an unlimited number of times
    exclude_unlimited: Option(Bool),
    /// Optional. Pass True to exclude gifts that can be purchased a limited number of times and can be upgraded to unique
    exclude_limited_upgradable: Option(Bool),
    /// Optional. Pass True to exclude gifts that can be purchased a limited number of times and can't be upgraded to unique
    exclude_limited_non_upgradable: Option(Bool),
    /// Optional. Pass True to exclude gifts that were assigned from the TON blockchain
    exclude_from_blockchain: Option(Bool),
    /// Optional. Pass True to exclude unique gifts
    exclude_unique: Option(Bool),
    /// Optional. Pass True to sort results by gift price instead of send date
    sort_by_price: Option(Bool),
    /// Optional. Offset of the first entry to return
    offset: Option(String),
    /// Optional. The maximum number of gifts to be returned; 1-100. Defaults to 100
    limit: Option(Int),
  )
}

// GetChatGiftsParameters ------------------------------------------------------------
/// Parameters for the getChatGifts method
pub type GetChatGiftsParameters {
  GetChatGiftsParameters(
    /// Unique identifier for the target chat or username of the target channel
    chat_id: IntOrString,
    /// Optional. Pass True to exclude gifts that aren't saved to the chat's profile page
    exclude_unsaved: Option(Bool),
    /// Optional. Pass True to exclude gifts that are saved to the chat's profile page
    exclude_saved: Option(Bool),
    /// Optional. Pass True to exclude gifts that can be purchased an unlimited number of times
    exclude_unlimited: Option(Bool),
    /// Optional. Pass True to exclude gifts that can be purchased a limited number of times and can be upgraded to unique
    exclude_limited_upgradable: Option(Bool),
    /// Optional. Pass True to exclude gifts that can be purchased a limited number of times and can't be upgraded to unique
    exclude_limited_non_upgradable: Option(Bool),
    /// Optional. Pass True to exclude gifts that were assigned from the TON blockchain
    exclude_from_blockchain: Option(Bool),
    /// Optional. Pass True to exclude unique gifts
    exclude_unique: Option(Bool),
    /// Optional. Pass True to sort results by gift price instead of send date
    sort_by_price: Option(Bool),
    /// Optional. Offset of the first entry to return
    offset: Option(String),
    /// Optional. The maximum number of gifts to be returned; 1-100. Defaults to 100
    limit: Option(Int),
  )
}

// RepostStoryParameters ------------------------------------------------------------
/// Parameters for the repostStory method
pub type RepostStoryParameters {
  RepostStoryParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Unique identifier of the chat which posted the story that should be reposted
    from_chat_id: Int,
    /// Unique identifier of the story that should be reposted
    from_story_id: Int,
    /// Period after which the story is moved to the archive, in seconds
    active_period: Int,
    /// Optional. Pass True to keep the story accessible after it expires
    post_to_chat_page: Option(Bool),
    /// Optional. Pass True if the content of the story must be protected from forwarding and screenshotting
    protect_content: Option(Bool),
  )
}

// VerifyUserParameters ------------------------------------------------------------
pub type VerifyUserParameters {
  VerifyUserParameters(
    /// Unique identifier of the target user
    user_id: Int,
    /// Custom description for the verification; 0-70 characters. Must be empty if the organization isn't allowed to provide a custom verification description.
    custom_description: Option(String),
  )
}

// VerifyChatParameters ------------------------------------------------------------
pub type VerifyChatParameters {
  VerifyChatParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format @channelusername)
    chat_id: IntOrString,
    /// Custom description for the verification; 0-70 characters. Must be empty if the organization isn't allowed to provide a custom verification description.
    custom_description: Option(String),
  )
}

// RemoveUserVerificationParameters ------------------------------------------------------------
pub type RemoveUserVerificationParameters {
  RemoveUserVerificationParameters(
    /// Unique identifier of the target user
    user_id: Int,
  )
}

// RemoveChatVerificationParameters ------------------------------------------------------------
pub type RemoveChatVerificationParameters {
  RemoveChatVerificationParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format @channelusername)
    chat_id: IntOrString,
  )
}

// GetCustomEmojiStickersParameters ------------------------------------------------------------
pub type GetCustomEmojiStickersParameters {
  GetCustomEmojiStickersParameters(
    /// A JSON-serialized list of custom emoji identifiers. At most 200 custom emoji identifiers can be specified.
    custom_emoji_ids: List(String),
  )
}

// UploadStickerFileParameters ------------------------------------------------------------
pub type UploadStickerFileParameters {
  UploadStickerFileParameters(
    /// User identifier of sticker file owner
    user_id: Int,
    /// A file with the sticker in .WEBP, .PNG, .TGS, or .WEBM format.
    sticker: File,
    /// Format of the sticker, must be one of "static", "animated", "video"
    sticker_format: String,
  )
}

// CreateNewStickerSetParameters ------------------------------------------------------------
pub type CreateNewStickerSetParameters {
  CreateNewStickerSetParameters(
    /// User identifier of created sticker set owner
    user_id: Int,
    /// Short name of sticker set, to be used in t.me/addstickers/ URLs
    name: String,
    /// Sticker set title, 1-64 characters
    title: String,
    /// A JSON-serialized list of 1-50 initial stickers to be added to the sticker set
    stickers: List(InputSticker),
    /// Type of stickers in the set, pass "regular", "mask", or "custom_emoji". By default, a regular sticker set is created.
    sticker_type: Option(String),
    /// Pass True if stickers in the sticker set must be repainted to the color of text when used in messages
    needs_repainting: Option(Bool),
  )
}

// AddStickerToSetParameters ------------------------------------------------------------
pub type AddStickerToSetParameters {
  AddStickerToSetParameters(
    /// User identifier of sticker set owner
    user_id: Int,
    /// Sticker set name
    name: String,
    /// A JSON-serialized object with information about the added sticker
    sticker: InputSticker,
  )
}

// SetStickerPositionInSetParameters ------------------------------------------------------------
pub type SetStickerPositionInSetParameters {
  SetStickerPositionInSetParameters(
    /// File identifier of the sticker
    sticker: String,
    /// New sticker position in the set, zero-based
    position: Int,
  )
}

// DeleteStickerFromSetParameters ------------------------------------------------------------
pub type DeleteStickerFromSetParameters {
  DeleteStickerFromSetParameters(
    /// File identifier of the sticker
    sticker: String,
  )
}

// ReplaceStickerInSetParameters ------------------------------------------------------------
pub type ReplaceStickerInSetParameters {
  ReplaceStickerInSetParameters(
    /// User identifier of the sticker set owner
    user_id: Int,
    /// Sticker set name
    name: String,
    /// File identifier of the replaced sticker
    old_sticker: String,
    /// A JSON-serialized object with information about the added sticker
    sticker: InputSticker,
  )
}

// SetStickerEmojiListParameters ------------------------------------------------------------
pub type SetStickerEmojiListParameters {
  SetStickerEmojiListParameters(
    /// File identifier of the sticker
    sticker: String,
    /// A JSON-serialized list of 1-20 emoji associated with the sticker
    emoji_list: List(String),
  )
}

// SetStickerKeywordsParameters ------------------------------------------------------------
pub type SetStickerKeywordsParameters {
  SetStickerKeywordsParameters(
    /// File identifier of the sticker
    sticker: String,
    /// A JSON-serialized list of 0-20 search keywords for the sticker with total length of up to 64 characters
    keywords: Option(List(String)),
  )
}

// SetStickerMaskPositionParameters ------------------------------------------------------------
pub type SetStickerMaskPositionParameters {
  SetStickerMaskPositionParameters(
    /// File identifier of the sticker
    sticker: String,
    /// A JSON-serialized object with the position where the mask should be placed on faces
    mask_position: Option(MaskPosition),
  )
}

// SetStickerSetTitleParameters ------------------------------------------------------------
pub type SetStickerSetTitleParameters {
  SetStickerSetTitleParameters(
    /// Sticker set name
    name: String,
    /// Sticker set title, 1-64 characters
    title: String,
  )
}

// SetStickerSetThumbnailParameters ------------------------------------------------------------
pub type SetStickerSetThumbnailParameters {
  SetStickerSetThumbnailParameters(
    /// Sticker set name
    name: String,
    /// User identifier of the sticker set owner
    user_id: Int,
    /// A .WEBP or .PNG image with the thumbnail, or .TGS animation or .WEBM video
    thumbnail: Option(FileOrString),
    /// Format of the thumbnail, must be one of "static" for a .WEBP or .PNG image, "animated" for a .TGS animation, or "video" for a .WEBM video
    format: String,
  )
}

// SetCustomEmojiStickerSetThumbnailParameters ------------------------------------------------------------
pub type SetCustomEmojiStickerSetThumbnailParameters {
  SetCustomEmojiStickerSetThumbnailParameters(
    /// Sticker set name
    name: String,
    /// Custom emoji identifier of a sticker from the sticker set; pass an empty string to drop the thumbnail
    custom_emoji_id: Option(String),
  )
}

// DeleteStickerSetParameters ------------------------------------------------------------
pub type DeleteStickerSetParameters {
  DeleteStickerSetParameters(
    /// Sticker set name
    name: String,
  )
}

// AnswerInlineQueryParameters ------------------------------------------------------------
pub type AnswerInlineQueryParameters {
  AnswerInlineQueryParameters(
    /// Unique identifier for the answered query
    inline_query_id: String,
    /// A JSON-serialized array of results for the inline query
    results: List(InlineQueryResult),
    /// The maximum amount of time in seconds that the result of the inline query may be cached on the server. Defaults to 300.
    cache_time: Option(Int),
    /// Pass `True` if results may be cached on the server side only for the user that sent the query. By default, results may be returned to any user who sends the same query.
    is_personal: Option(Bool),
    /// Pass the offset that a client should send in the next query with the same text to receive more results. Pass an empty string if there are no more results or if you don't support pagination. Offset length can't exceed 64 bytes.
    next_offset: Option(String),
    /// A JSON-serialized object describing a button to be shown above inline query results
    button: Option(InlineQueryResultsButton),
  )
}

// AnswerShippingQueryParameters ------------------------------------------------------------
pub type AnswerShippingQueryParameters {
  AnswerShippingQueryParameters(
    /// Unique identifier for the query to be answered
    shipping_query_id: String,
    /// Pass True if delivery to the specified address is possible and False if there are any problems
    ok: Bool,
    /// Required if ok is True. A JSON-serialized array of available shipping options.
    shipping_options: Option(List(ShippingOption)),
    /// Required if ok is False. Error message in human readable form that explains why it is impossible to complete the order
    error_message: Option(String),
  )
}

// AnswerPreCheckoutQueryParameters ------------------------------------------------------------
pub type AnswerPreCheckoutQueryParameters {
  AnswerPreCheckoutQueryParameters(
    /// Unique identifier for the query to be answered
    pre_checkout_query_id: String,
    /// Specify True if everything is alright and the bot is ready to proceed with the order. Use False if there are any problems.
    ok: Bool,
    /// Required if ok is False. Error message in human readable form that explains the reason for failure to proceed with the checkout
    error_message: Option(String),
  )
}

// GetStarTransactionsParameters ------------------------------------------------------------
pub type GetStarTransactionsParameters {
  GetStarTransactionsParameters(
    /// Number of transactions to skip in the response
    offset: Option(Int),
    /// The maximum number of transactions to be retrieved. Values between 1-100 are accepted. Defaults to 100.
    limit: Option(Int),
  )
}

// EditUserStarSubscriptionParameters ------------------------------------------------------------
pub type EditUserStarSubscriptionParameters {
  EditUserStarSubscriptionParameters(
    /// Identifier of the user whose subscription will be edited
    user_id: Int,
    /// Telegram payment identifier for the subscription
    telegram_payment_charge_id: String,
    /// Pass True to cancel extension of the user subscription; the subscription must be active up to the end of the current subscription period. Pass False to allow the user to re-enable a subscription that was previously canceled by the bot.
    is_canceled: Bool,
  )
}

// SendGameParameters ------------------------------------------------------------
pub type SendGameParameters {
  SendGameParameters(
    /// Unique identifier of the business connection on behalf of which the message will be sent
    business_connection_id: Option(String),
    /// Unique identifier for the target chat
    chat_id: Int,
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Short name of the game, serves as the unique identifier for the game. Set up your games via @BotFather.
    game_short_name: String,
    /// Sends the message silently. Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Protects the contents of the sent message from forwarding and saving
    protect_content: Option(Bool),
    /// Pass True to allow up to 1000 messages per second, ignoring broadcasting limits for a fee of 0.1 Telegram Stars per message
    allow_paid_broadcast: Option(Bool),
    /// Unique identifier of the message effect to be added to the message; for private chats only
    message_effect_id: Option(String),
    /// Description of the message to reply to
    reply_parameters: Option(ReplyParameters),
    /// A JSON-serialized object for an inline keyboard. If empty, one 'Play game_title' button will be shown.
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

// SetGameScoreParameters ------------------------------------------------------------
pub type SetGameScoreParameters {
  SetGameScoreParameters(
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

// GetGameHighScoresParameters ------------------------------------------------------------
pub type GetGameHighScoresParameters {
  GetGameHighScoresParameters(
    /// Target user id
    user_id: Int,
    /// Required if inline_message_id is not specified. Unique identifier for the target chat
    chat_id: Option(Int),
    /// Required if inline_message_id is not specified. Identifier of the sent message
    message_id: Option(Int),
    /// Required if chat_id and message_id are not specified. Identifier of the inline message
    inline_message_id: Option(String),
  )
}

// ReadBusinessMessageParameters ------------------------------------------------------------
pub type ReadBusinessMessageParameters {
  ReadBusinessMessageParameters(
    /// Unique identifier of the business connection on behalf of which to read the message
    business_connection_id: String,
    /// Unique identifier of the chat in which the message was received. The chat must have been active in the last 24 hours.
    chat_id: Int,
    /// Unique identifier of the message to mark as read
    message_id: Int,
  )
}

// DeleteBusinessMessagesParameters ------------------------------------------------------------
pub type DeleteBusinessMessagesParameters {
  DeleteBusinessMessagesParameters(
    /// Unique identifier of the business connection on behalf of which to delete the messages
    business_connection_id: String,
    /// A JSON-serialized list of 1-100 identifiers of messages to delete. All messages must be from the same chat. See deleteMessage for limitations on which messages can be deleted
    message_ids: List(Int),
  )
}

// SetBusinessAccountNameParameters ------------------------------------------------------------
pub type SetBusinessAccountNameParameters {
  SetBusinessAccountNameParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// The new value of the first name for the business account; 1-64 characters
    first_name: String,
    /// The new value of the last name for the business account; 0-64 characters
    last_name: Option(String),
  )
}

// SetBusinessAccountUsernameParameters ------------------------------------------------------------
pub type SetBusinessAccountUsernameParameters {
  SetBusinessAccountUsernameParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// The new value of the username for the business account; 0-32 characters
    username: Option(String),
  )
}

// SetBusinessAccountBioParameters ------------------------------------------------------------
pub type SetBusinessAccountBioParameters {
  SetBusinessAccountBioParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// The new value of the bio for the business account; 0-140 characters
    bio: Option(String),
  )
}

// SetBusinessAccountProfilePhotoParameters ------------------------------------------------------------
pub type SetBusinessAccountProfilePhotoParameters {
  SetBusinessAccountProfilePhotoParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// The new profile photo to set
    photo: InputProfilePhoto,
    /// Pass True to set the public photo, which will be visible even if the main photo is hidden by the business account's privacy settings. An account can have only one public photo.
    is_public: Option(Bool),
  )
}

// RemoveBusinessAccountProfilePhotoParameters ------------------------------------------------------------
pub type RemoveBusinessAccountProfilePhotoParameters {
  RemoveBusinessAccountProfilePhotoParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Pass True to remove the public photo, which is visible even if the main photo is hidden by the business account's privacy settings. After the main photo is removed, the previous profile photo (if present) becomes the main photo.
    is_public: Option(Bool),
  )
}

// SetBusinessAccountGiftSettingsParameters ------------------------------------------------------------
pub type SetBusinessAccountGiftSettingsParameters {
  SetBusinessAccountGiftSettingsParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Pass True, if a button for sending a gift to the user or by the business account must always be shown in the input field
    show_gift_button: Bool,
    /// Types of gifts accepted by the business account
    accepted_gift_types: AcceptedGiftTypes,
  )
}

// GetBusinessAccountStarBalanceParameters ------------------------------------------------------------
pub type GetBusinessAccountStarBalanceParameters {
  GetBusinessAccountStarBalanceParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
  )
}

// TransferBusinessAccountStarsParameters ------------------------------------------------------------
pub type TransferBusinessAccountStarsParameters {
  TransferBusinessAccountStarsParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Number of Telegram Stars to transfer; 1-10000
    star_count: Int,
  )
}

// GetBusinessAccountGiftsParameters ------------------------------------------------------------
pub type GetBusinessAccountGiftsParameters {
  GetBusinessAccountGiftsParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Pass True to exclude gifts that aren't saved to the account's profile page
    exclude_unsaved: Option(Bool),
    /// Pass True to exclude gifts that are saved to the account's profile page
    exclude_saved: Option(Bool),
    /// Pass True to exclude gifts that can be purchased an unlimited number of times
    exclude_unlimited: Option(Bool),
    /// Pass True to exclude gifts that can be purchased a limited number of times
    exclude_limited: Option(Bool),
    /// Pass True to exclude unique gifts
    exclude_unique: Option(Bool),
    /// Pass True to sort results by gift price instead of send date. Sorting is applied before pagination.
    sort_by_price: Option(Bool),
    /// Offset of the first entry to return as received from the previous request; use empty string to get the first chunk of results
    offset: Option(String),
    /// The maximum number of gifts to be returned; 1-100. Defaults to 100
    limit: Option(Int),
  )
}

// ConvertGiftToStarsParameters ------------------------------------------------------------
pub type ConvertGiftToStarsParameters {
  ConvertGiftToStarsParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Unique identifier of the regular gift that should be converted to Telegram Stars
    owned_gift_id: String,
  )
}

// UpgradeGiftParameters ------------------------------------------------------------
pub type UpgradeGiftParameters {
  UpgradeGiftParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Unique identifier of the regular gift that should be upgraded to a unique one
    owned_gift_id: String,
    /// Pass True to keep the original gift text, sender and receiver in the upgraded gift
    keep_original_details: Option(Bool),
    /// The amount of Telegram Stars that will be paid for the upgrade from the business account balance. If gift.prepaid_upgrade_star_count > 0, then pass 0, otherwise, the can_transfer_stars business bot right is required and gift.upgrade_star_count must be passed.
    star_count: Option(Int),
  )
}

// TransferGiftParameters ------------------------------------------------------------
pub type TransferGiftParameters {
  TransferGiftParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Unique identifier of the regular gift that should be transferred
    owned_gift_id: String,
    /// Unique identifier of the chat which will own the gift. The chat must be active in the last 24 hours.
    new_owner_chat_id: Int,
    /// The amount of Telegram Stars that will be paid for the transfer from the business account balance. If positive, then the can_transfer_stars business bot right is required.
    star_count: Option(Int),
  )
}

// PostStoryParameters ------------------------------------------------------------
pub type PostStoryParameters {
  PostStoryParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Content of the story
    content: InputStoryContent,
    /// Period after which the story is moved to the archive, in seconds; must be one of 6 * 3600, 12 * 3600, 86400, or 2 * 86400
    active_period: Int,
    /// Caption of the story, 0-2048 characters after entities parsing
    caption: Option(String),
    /// Mode for parsing entities in the story caption. See formatting options for more details.
    parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// A JSON-serialized list of clickable areas to be shown on the story
    areas: Option(List(StoryArea)),
    /// Pass True to keep the story accessible after it expires
    post_to_chat_page: Option(Bool),
    /// Pass True if the content of the story must be protected from forwarding and screenshotting
    protect_content: Option(Bool),
  )
}

// EditStoryParameters ------------------------------------------------------------
pub type EditStoryParameters {
  EditStoryParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Unique identifier of the story to edit
    story_id: Int,
    /// Content of the story
    content: InputStoryContent,
    /// Caption of the story, 0-2048 characters after entities parsing
    caption: Option(String),
    /// Mode for parsing entities in the story caption. See formatting options for more details.
    parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in the caption, which can be specified instead of parse_mode
    caption_entities: Option(List(MessageEntity)),
    /// A JSON-serialized list of clickable areas to be shown on the story
    areas: Option(List(StoryArea)),
  )
}

// DeleteStoryParameters ------------------------------------------------------------
pub type DeleteStoryParameters {
  DeleteStoryParameters(
    /// Unique identifier of the business connection
    business_connection_id: String,
    /// Unique identifier of the story to delete
    story_id: Int,
  )
}

// Common ------------------------------------------------------------------------------------------------------------

pub type FileOrString {
  FileV(value: File)
  StringV(string: String)
}

pub type IntOrString {
  Int(value: Int)
  Str(value: String)
}
