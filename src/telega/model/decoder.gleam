//// This module contains all decoders for types [Telegram Bot API](https://core.telegram.org/bots/api).

import gleam/dynamic/decode
import gleam/option.{None}

import telega/model/types.{
  type AcceptedGiftTypes, type AffiliateInfo, type Animation, type Audio,
  type BackgroundFill, type BackgroundFillFreeformGradient,
  type BackgroundFillGradient, type BackgroundFillSolid, type BackgroundType,
  type BackgroundTypeChatTheme, type BackgroundTypeFill,
  type BackgroundTypePattern, type BackgroundTypeWallpaper, type Birthdate,
  type BotCommand, type BotCommandScope,
  type BotCommandScopeAllChatAdministrators, type BotCommandScopeAllGroupChats,
  type BotCommandScopeAllPrivateChats, type BotCommandScopeChat,
  type BotCommandScopeChatAdministrators, type BotCommandScopeChatMember,
  type BotCommandScopeDefault, type BotDescription, type BotName,
  type BotShortDescription, type BusinessBotRights, type BusinessConnection,
  type BusinessIntro, type BusinessLocation, type BusinessMessagesDeleted,
  type BusinessOpeningHours, type BusinessOpeningHoursInterval,
  type CallbackGame, type CallbackQuery, type Chat, type ChatAdministratorRights,
  type ChatBackground, type ChatBoost, type ChatBoostAdded,
  type ChatBoostRemoved, type ChatBoostSource, type ChatBoostSourceGiftCode,
  type ChatBoostSourceGiveaway, type ChatBoostSourcePremium,
  type ChatBoostUpdated, type ChatFullInfo, type ChatInviteLink,
  type ChatJoinRequest, type ChatLocation, type ChatMember,
  type ChatMemberAdministrator, type ChatMemberBanned, type ChatMemberLeft,
  type ChatMemberMember, type ChatMemberOwner, type ChatMemberRestricted,
  type ChatMemberUpdated, type ChatPermissions, type ChatPhoto, type ChatShared,
  type Checklist, type ChecklistTask, type ChecklistTasksAdded,
  type ChecklistTasksDone, type ChosenInlineResult, type Contact,
  type CopyTextButton, type Dice, type DirectMessagePriceChanged,
  type DirectMessagesTopic, type Document, type EncryptedCredentials,
  type EncryptedPassportElement, type ExternalReplyInfo, type File,
  type FileOrString, type ForceReply, type ForumTopic, type ForumTopicClosed,
  type ForumTopicCreated, type ForumTopicEdited, type ForumTopicReopened,
  type Game, type GameHighScore, type GeneralForumTopicHidden,
  type GeneralForumTopicUnhidden, type Gift, type GiftBackground, type GiftInfo,
  type Gifts, type Giveaway, type GiveawayCompleted, type GiveawayCreated,
  type GiveawayWinners, type InaccessibleMessage, type InlineKeyboardButton,
  type InlineKeyboardMarkup, type InlineQuery, type InlineQueryResult,
  type InlineQueryResultArticle, type InlineQueryResultAudio,
  type InlineQueryResultCachedAudio, type InlineQueryResultCachedDocument,
  type InlineQueryResultCachedGif, type InlineQueryResultCachedMpeg4Gif,
  type InlineQueryResultCachedPhoto, type InlineQueryResultCachedSticker,
  type InlineQueryResultCachedVideo, type InlineQueryResultCachedVoice,
  type InlineQueryResultContact, type InlineQueryResultDocument,
  type InlineQueryResultGame, type InlineQueryResultGif,
  type InlineQueryResultLocation, type InlineQueryResultMpeg4Gif,
  type InlineQueryResultPhoto, type InlineQueryResultVenue,
  type InlineQueryResultVideo, type InlineQueryResultVoice,
  type InlineQueryResultsButton, type InputChecklist, type InputChecklistTask,
  type InputContactMessageContent, type InputInvoiceMessageContent,
  type InputLocationMessageContent, type InputMedia, type InputMediaAnimation,
  type InputMediaAudio, type InputMediaDocument, type InputMediaPhoto,
  type InputMediaVideo, type InputMessageContent, type InputPaidMedia,
  type InputPaidMediaPhoto, type InputPaidMediaVideo, type InputPollOption,
  type InputSticker, type InputTextMessageContent, type InputVenueMessageContent,
  type IntOrString, type Invoice, type KeyboardButton,
  type KeyboardButtonPollType, type KeyboardButtonRequestChat,
  type KeyboardButtonRequestUsers, type LabeledPrice, type LinkPreviewOptions,
  type Location, type LoginUrl, type MaskPosition, type MaybeInaccessibleMessage,
  type MenuButton, type MenuButtonCommands, type MenuButtonDefault,
  type MenuButtonWebApp, type Message, type MessageAutoDeleteTimerChanged,
  type MessageEntity, type MessageId, type MessageOrigin,
  type MessageOriginChannel, type MessageOriginChat,
  type MessageOriginHiddenUser, type MessageOriginUser,
  type MessageReactionCountUpdated, type MessageReactionUpdated, type OrderInfo,
  type OwnedGift, type OwnedGiftRegular, type OwnedGiftUnique, type OwnedGifts,
  type PaidMedia, type PaidMediaInfo, type PaidMediaPhoto, type PaidMediaPreview,
  type PaidMediaPurchased, type PaidMediaVideo, type PaidMessagePriceChanged,
  type PassportData, type PassportElementError,
  type PassportElementErrorDataField, type PassportElementErrorFile,
  type PassportElementErrorFiles, type PassportElementErrorFrontSide,
  type PassportElementErrorReverseSide, type PassportElementErrorSelfie,
  type PassportElementErrorTranslationFile,
  type PassportElementErrorTranslationFiles,
  type PassportElementErrorUnspecified, type PassportFile, type PhotoSize,
  type Poll, type PollAnswer, type PollOption, type PreCheckoutQuery,
  type PreparedInlineMessage, type ProximityAlertTriggered, type ReactionCount,
  type ReactionType, type ReactionTypeCustomEmoji, type ReactionTypeEmoji,
  type ReactionTypePaid, type RefundedPayment, type ReplyKeyboardMarkup,
  type ReplyKeyboardRemove, type ReplyParameters, type ResponseParameters,
  type RevenueWithdrawalState, type RevenueWithdrawalStateFailed,
  type RevenueWithdrawalStatePending, type RevenueWithdrawalStateSucceeded,
  type SentWebAppMessage, type SharedUser, type ShippingAddress,
  type ShippingOption, type ShippingQuery, type StarAmount, type StarTransaction,
  type StarTransactions, type Sticker, type StickerSet, type Story,
  type SuccessfulPayment, type SuggestedPostApprovalFailed,
  type SuggestedPostApproved, type SuggestedPostDeclined, type SuggestedPostInfo,
  type SuggestedPostPaid, type SuggestedPostPrice, type SuggestedPostRefunded,
  type SwitchInlineQueryChosenChat, type TextQuote, type TransactionPartner,
  type TransactionPartnerAffiliateProgram, type TransactionPartnerChat,
  type TransactionPartnerFragment, type TransactionPartnerOther,
  type TransactionPartnerTelegramAds, type TransactionPartnerTelegramApi,
  type TransactionPartnerUser, type UniqueGift, type UniqueGiftBackdrop,
  type UniqueGiftBackdropColors, type UniqueGiftColors, type UniqueGiftInfo,
  type UniqueGiftModel, type UniqueGiftSymbol, type Update, type User,
  type UserChatBoosts, type UserProfilePhotos, type UserRating, type UsersShared,
  type Venue, type Video, type VideoChatEnded, type VideoChatParticipantsInvited,
  type VideoChatScheduled, type VideoChatStarted, type VideoNote, type Voice,
  type WebAppData, type WebAppInfo, type WebhookInfo, type WriteAccessAllowed,
  AcceptedGiftTypes, AffiliateInfo, Animation, Audio,
  BackgroundFillFreeformGradient, BackgroundFillFreeformGradientBackgroundFill,
  BackgroundFillGradient, BackgroundFillGradientBackgroundFill,
  BackgroundFillSolid, BackgroundFillSolidBackgroundFill,
  BackgroundTypeChatTheme, BackgroundTypeChatThemeBackgroundType,
  BackgroundTypeFill, BackgroundTypeFillBackgroundType, BackgroundTypePattern,
  BackgroundTypePatternBackgroundType, BackgroundTypeWallpaper,
  BackgroundTypeWallpaperBackgroundType, Birthdate, BotCommand,
  BotCommandScopeAllChatAdministrators,
  BotCommandScopeAllChatAdministratorsBotCommandScope,
  BotCommandScopeAllGroupChats, BotCommandScopeAllGroupChatsBotCommandScope,
  BotCommandScopeAllPrivateChats, BotCommandScopeAllPrivateChatsBotCommandScope,
  BotCommandScopeChat, BotCommandScopeChatAdministrators,
  BotCommandScopeChatAdministratorsBotCommandScope,
  BotCommandScopeChatBotCommandScope, BotCommandScopeChatMember,
  BotCommandScopeChatMemberBotCommandScope, BotCommandScopeDefault,
  BotCommandScopeDefaultBotCommandScope, BotDescription, BotName,
  BotShortDescription, BusinessBotRights, BusinessConnection, BusinessIntro,
  BusinessLocation, BusinessMessagesDeleted, BusinessOpeningHours,
  BusinessOpeningHoursInterval, CallbackGame, CallbackQuery, Chat,
  ChatAdministratorRights, ChatBackground, ChatBoost, ChatBoostAdded,
  ChatBoostRemoved, ChatBoostSourceGiftCode,
  ChatBoostSourceGiftCodeChatBoostSource, ChatBoostSourceGiveaway,
  ChatBoostSourceGiveawayChatBoostSource, ChatBoostSourcePremium,
  ChatBoostSourcePremiumChatBoostSource, ChatBoostUpdated, ChatFullInfo,
  ChatInviteLink, ChatJoinRequest, ChatLocation, ChatMemberAdministrator,
  ChatMemberAdministratorChatMember, ChatMemberBanned,
  ChatMemberBannedChatMember, ChatMemberLeft, ChatMemberLeftChatMember,
  ChatMemberMember, ChatMemberMemberChatMember, ChatMemberOwner,
  ChatMemberOwnerChatMember, ChatMemberRestricted,
  ChatMemberRestrictedChatMember, ChatMemberUpdated, ChatPermissions, ChatPhoto,
  ChatShared, Checklist, ChecklistTask, ChecklistTasksAdded, ChecklistTasksDone,
  ChosenInlineResult, Contact, CopyTextButton, Dice, DirectMessagePriceChanged,
  DirectMessagesTopic, Document, EncryptedCredentials, EncryptedPassportElement,
  ExternalReplyInfo, File, FileV, ForceReply, ForumTopic, ForumTopicClosed,
  ForumTopicCreated, ForumTopicEdited, ForumTopicReopened, Game, GameHighScore,
  GeneralForumTopicHidden, GeneralForumTopicUnhidden, Gift, GiftBackground,
  GiftInfo, Gifts, Giveaway, GiveawayCompleted, GiveawayCreated, GiveawayWinners,
  InaccessibleMessage, InaccessibleMessageMaybeInaccessibleMessage,
  InlineKeyboardButton, InlineKeyboardMarkup, InlineQuery,
  InlineQueryResultArticle, InlineQueryResultArticleInlineQueryResult,
  InlineQueryResultAudio, InlineQueryResultCachedAudio,
  InlineQueryResultCachedAudioInlineQueryResult, InlineQueryResultCachedDocument,
  InlineQueryResultCachedDocumentInlineQueryResult, InlineQueryResultCachedGif,
  InlineQueryResultCachedGifInlineQueryResult, InlineQueryResultCachedMpeg4Gif,
  InlineQueryResultCachedMpeg4GifInlineQueryResult, InlineQueryResultCachedPhoto,
  InlineQueryResultCachedPhotoInlineQueryResult, InlineQueryResultCachedSticker,
  InlineQueryResultCachedStickerInlineQueryResult, InlineQueryResultCachedVideo,
  InlineQueryResultCachedVideoInlineQueryResult, InlineQueryResultCachedVoice,
  InlineQueryResultCachedVoiceInlineQueryResult, InlineQueryResultContact,
  InlineQueryResultContactInlineQueryResult, InlineQueryResultDocument,
  InlineQueryResultDocumentInlineQueryResult, InlineQueryResultGame,
  InlineQueryResultGameInlineQueryResult, InlineQueryResultGif,
  InlineQueryResultGifInlineQueryResult, InlineQueryResultLocation,
  InlineQueryResultLocationInlineQueryResult, InlineQueryResultMpeg4Gif,
  InlineQueryResultMpeg4GifInlineQueryResult, InlineQueryResultPhoto,
  InlineQueryResultPhotoInlineQueryResult, InlineQueryResultVenue,
  InlineQueryResultVenueInlineQueryResult, InlineQueryResultVideo,
  InlineQueryResultVideoInlineQueryResult, InlineQueryResultVoice,
  InlineQueryResultVoiceInlineQueryResult, InlineQueryResultsButton,
  InputChecklist, InputChecklistTask, InputContactMessageContent,
  InputContactMessageContentInputMessageContent, InputInvoiceMessageContent,
  InputInvoiceMessageContentInputMessageContent, InputLocationMessageContent,
  InputLocationMessageContentInputMessageContent, InputMediaAnimation,
  InputMediaAnimationInputMedia, InputMediaAudio, InputMediaAudioInputMedia,
  InputMediaDocument, InputMediaDocumentInputMedia, InputMediaPhoto,
  InputMediaPhotoInputMedia, InputMediaVideo, InputMediaVideoInputMedia,
  InputPaidMediaPhoto, InputPaidMediaPhotoInputPaidMedia, InputPaidMediaVideo,
  InputPaidMediaVideoInputPaidMedia, InputPollOption, InputSticker,
  InputTextMessageContent, InputTextMessageContentInputMessageContent,
  InputVenueMessageContent, InputVenueMessageContentInputMessageContent, Int,
  Invoice, KeyboardButton, KeyboardButtonPollType, KeyboardButtonRequestChat,
  KeyboardButtonRequestUsers, LabeledPrice, LinkPreviewOptions, Location,
  LoginUrl, MaskPosition, MenuButtonCommands, MenuButtonCommandsMenuButton,
  MenuButtonDefault, MenuButtonDefaultMenuButton, MenuButtonWebApp,
  MenuButtonWebAppMenuButton, Message, MessageAutoDeleteTimerChanged,
  MessageEntity, MessageId, MessageMaybeInaccessibleMessage,
  MessageOriginChannel, MessageOriginChannelMessageOrigin, MessageOriginChat,
  MessageOriginChatMessageOrigin, MessageOriginHiddenUser,
  MessageOriginHiddenUserMessageOrigin, MessageOriginUser,
  MessageOriginUserMessageOrigin, MessageReactionCountUpdated,
  MessageReactionUpdated, OrderInfo, OwnedGift, OwnedGiftRegular,
  OwnedGiftUnique, OwnedGifts, PaidMediaInfo, PaidMediaPhoto,
  PaidMediaPhotoPaidMedia, PaidMediaPreview, PaidMediaPreviewPaidMedia,
  PaidMediaPurchased, PaidMediaVideo, PaidMediaVideoPaidMedia,
  PaidMessagePriceChanged, PassportData, PassportElementErrorDataField,
  PassportElementErrorDataFieldPassportElementError, PassportElementErrorFile,
  PassportElementErrorFilePassportElementError, PassportElementErrorFiles,
  PassportElementErrorFilesPassportElementError, PassportElementErrorFrontSide,
  PassportElementErrorFrontSidePassportElementError,
  PassportElementErrorReverseSide,
  PassportElementErrorReverseSidePassportElementError,
  PassportElementErrorSelfie, PassportElementErrorSelfiePassportElementError,
  PassportElementErrorTranslationFile,
  PassportElementErrorTranslationFilePassportElementError,
  PassportElementErrorTranslationFiles,
  PassportElementErrorTranslationFilesPassportElementError,
  PassportElementErrorUnspecified,
  PassportElementErrorUnspecifiedPassportElementError, PassportFile, PhotoSize,
  Poll, PollAnswer, PollOption, PreCheckoutQuery, PreparedInlineMessage,
  ProximityAlertTriggered, ReactionCount, ReactionTypeCustomEmoji,
  ReactionTypeCustomEmojiReactionType, ReactionTypeEmoji,
  ReactionTypeEmojiReactionType, ReactionTypePaid, ReactionTypePaidReactionType,
  RefundedPayment, ReplyKeyboardMarkup, ReplyKeyboardRemove, ReplyParameters,
  ResponseParameters, RevenueWithdrawalStateFailed,
  RevenueWithdrawalStateFailedRevenueWithdrawalState,
  RevenueWithdrawalStatePending,
  RevenueWithdrawalStatePendingRevenueWithdrawalState,
  RevenueWithdrawalStateSucceeded,
  RevenueWithdrawalStateSucceededRevenueWithdrawalState, SentWebAppMessage,
  SharedUser, ShippingAddress, ShippingOption, ShippingQuery, StarAmount,
  StarTransaction, StarTransactions, Sticker, StickerSet, Story, Str, StringV,
  SuccessfulPayment, SuggestedPostApprovalFailed, SuggestedPostApproved,
  SuggestedPostDeclined, SuggestedPostInfo, SuggestedPostPaid,
  SuggestedPostPrice, SuggestedPostRefunded, SwitchInlineQueryChosenChat,
  TextQuote, TransactionPartnerAffiliateProgram,
  TransactionPartnerAffiliateProgramTransactionPartner, TransactionPartnerChat,
  TransactionPartnerChatTransactionPartner, TransactionPartnerFragment,
  TransactionPartnerFragmentTransactionPartner, TransactionPartnerOther,
  TransactionPartnerOtherTransactionPartner, TransactionPartnerTelegramAds,
  TransactionPartnerTelegramAdsTransactionPartner, TransactionPartnerTelegramApi,
  TransactionPartnerTelegramApiTransactionPartner, TransactionPartnerUser,
  TransactionPartnerUserTransactionPartner, UniqueGift, UniqueGiftBackdrop,
  UniqueGiftBackdropColors, UniqueGiftColors, UniqueGiftInfo, UniqueGiftModel,
  UniqueGiftSymbol, Update, User, UserChatBoosts, UserProfilePhotos, UserRating,
  UsersShared, Venue, Video, VideoChatEnded, VideoChatParticipantsInvited,
  VideoChatScheduled, VideoChatStarted, VideoNote, Voice, WebAppData, WebAppInfo,
  WebhookInfo, WriteAccessAllowed,
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
  use has_topics_enabled <- decode.optional_field(
    "has_topics_enabled",
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
    has_topics_enabled: has_topics_enabled,
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
  use is_direct_messages <- decode.optional_field(
    "is_direct_messages",
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
    is_direct_messages: is_direct_messages,
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
  use is_direct_messages <- decode.optional_field(
    "is_direct_messages",
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
  use parent_chat <- decode.optional_field(
    "parent_chat",
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
  use rating <- decode.optional_field(
    "rating",
    None,
    decode.optional(user_rating_decoder()),
  )
  use unique_gift_colors <- decode.optional_field(
    "unique_gift_colors",
    None,
    decode.optional(unique_gift_colors_decoder()),
  )
  use paid_message_star_count <- decode.optional_field(
    "paid_message_star_count",
    None,
    decode.optional(decode.int),
  )
  decode.success(ChatFullInfo(
    id: id,
    type_: type_,
    title: title,
    username: username,
    first_name: first_name,
    last_name: last_name,
    is_forum: is_forum,
    is_direct_messages: is_direct_messages,
    accent_color_id: accent_color_id,
    max_reaction_count: max_reaction_count,
    photo: photo,
    active_usernames: active_usernames,
    birthdate: birthdate,
    business_intro: business_intro,
    business_location: business_location,
    business_opening_hours: business_opening_hours,
    personal_chat: personal_chat,
    parent_chat: parent_chat,
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
    rating: rating,
    unique_gift_colors: unique_gift_colors,
    paid_message_star_count: paid_message_star_count,
  ))
}

/// Decoder for an array of messages (used by sendMediaGroup)
pub fn messages_array_decoder() -> decode.Decoder(List(Message)) {
  decode.list(message_decoder())
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
  use direct_messages_topic <- decode.optional_field(
    "direct_messages_topic",
    None,
    decode.optional(direct_messages_topic_decoder()),
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
  use reply_to_checklist_task_id <- decode.optional_field(
    "reply_to_checklist_task_id",
    None,
    decode.optional(decode.int),
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
  use is_paid_post <- decode.optional_field(
    "is_paid_post",
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
  use paid_star_count <- decode.optional_field(
    "paid_star_count",
    None,
    decode.optional(decode.int),
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
  use suggested_post_info <- decode.optional_field(
    "suggested_post_info",
    None,
    decode.optional(suggested_post_info_decoder()),
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
  use checklist <- decode.optional_field(
    "checklist",
    None,
    decode.optional(checklist_decoder()),
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
  use gift <- decode.optional_field(
    "gift",
    None,
    decode.optional(gift_info_decoder()),
  )
  use unique_gift <- decode.optional_field(
    "unique_gift",
    None,
    decode.optional(unique_gift_info_decoder()),
  )
  use gift_upgrade_sent <- decode.optional_field(
    "gift_upgrade_sent",
    None,
    decode.optional(gift_info_decoder()),
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
  use checklist_tasks_done <- decode.optional_field(
    "checklist_tasks_done",
    None,
    decode.optional(checklist_tasks_done_decoder()),
  )
  use checklist_tasks_added <- decode.optional_field(
    "checklist_tasks_added",
    None,
    decode.optional(checklist_tasks_added_decoder()),
  )
  use direct_message_price_changed <- decode.optional_field(
    "direct_message_price_changed",
    None,
    decode.optional(direct_message_price_changed_decoder()),
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
  use paid_message_price_changed <- decode.optional_field(
    "paid_message_price_changed",
    None,
    decode.optional(paid_message_price_changed_decoder()),
  )
  use suggested_post_approved <- decode.optional_field(
    "suggested_post_approved",
    None,
    decode.optional(suggested_post_approved_decoder()),
  )
  use suggested_post_approval_failed <- decode.optional_field(
    "suggested_post_approval_failed",
    None,
    decode.optional(suggested_post_approval_failed_decoder()),
  )
  use suggested_post_declined <- decode.optional_field(
    "suggested_post_declined",
    None,
    decode.optional(suggested_post_declined_decoder()),
  )
  use suggested_post_paid <- decode.optional_field(
    "suggested_post_paid",
    None,
    decode.optional(suggested_post_paid_decoder()),
  )
  use suggested_post_refunded <- decode.optional_field(
    "suggested_post_refunded",
    None,
    decode.optional(suggested_post_refunded_decoder()),
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
    direct_messages_topic: direct_messages_topic,
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
    reply_to_checklist_task_id: reply_to_checklist_task_id,
    via_bot: via_bot,
    edit_date: edit_date,
    has_protected_content: has_protected_content,
    is_from_offline: is_from_offline,
    is_paid_post: is_paid_post,
    media_group_id: media_group_id,
    author_signature: author_signature,
    paid_star_count: paid_star_count,
    text: text,
    entities: entities,
    link_preview_options: link_preview_options,
    effect_id: effect_id,
    suggested_post_info: suggested_post_info,
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
    checklist: checklist,
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
    gift: gift,
    unique_gift: unique_gift,
    gift_upgrade_sent: gift_upgrade_sent,
    connected_website: connected_website,
    write_access_allowed: write_access_allowed,
    passport_data: passport_data,
    proximity_alert_triggered: proximity_alert_triggered,
    boost_added: boost_added,
    chat_background_set: chat_background_set,
    checklist_tasks_done: checklist_tasks_done,
    checklist_tasks_added: checklist_tasks_added,
    direct_message_price_changed: direct_message_price_changed,
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
    paid_message_price_changed: paid_message_price_changed,
    suggested_post_approved: suggested_post_approved,
    suggested_post_approval_failed: suggested_post_approval_failed,
    suggested_post_declined: suggested_post_declined,
    suggested_post_paid: suggested_post_paid,
    suggested_post_refunded: suggested_post_refunded,
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
  use checklist <- decode.optional_field(
    "checklist",
    None,
    decode.optional(checklist_decoder()),
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
    checklist: checklist,
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
  use checklist_task_id <- decode.optional_field(
    "checklist_task_id",
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
    checklist_task_id: checklist_task_id,
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

pub fn checklist_task_decoder() -> decode.Decoder(ChecklistTask) {
  use id <- decode.field("id", decode.int)
  use text <- decode.field("text", decode.string)
  use text_entities <- decode.field(
    "text_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use completed_by_user <- decode.field(
    "completed_by_user",
    decode.optional(user_decoder()),
  )
  use completion_date <- decode.field(
    "completion_date",
    decode.optional(decode.int),
  )
  use completed_by_chat <- decode.optional_field(
    "completed_by_chat",
    None,
    decode.optional(chat_decoder()),
  )
  decode.success(ChecklistTask(
    id: id,
    text: text,
    text_entities: text_entities,
    completed_by_user: completed_by_user,
    completion_date: completion_date,
    completed_by_chat: completed_by_chat,
  ))
}

pub fn checklist_decoder() -> decode.Decoder(Checklist) {
  use title <- decode.field("title", decode.string)
  use title_entities <- decode.field(
    "title_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use tasks <- decode.field("tasks", decode.list(checklist_task_decoder()))
  use others_can_add_tasks <- decode.field(
    "others_can_add_tasks",
    decode.optional(decode.bool),
  )
  use others_can_mark_tasks_as_done <- decode.field(
    "others_can_mark_tasks_as_done",
    decode.optional(decode.bool),
  )
  decode.success(Checklist(
    title: title,
    title_entities: title_entities,
    tasks: tasks,
    others_can_add_tasks: others_can_add_tasks,
    others_can_mark_tasks_as_done: others_can_mark_tasks_as_done,
  ))
}

pub fn input_checklist_task_decoder() -> decode.Decoder(InputChecklistTask) {
  use id <- decode.field("id", decode.int)
  use text <- decode.field("text", decode.string)
  use parse_mode <- decode.field("parse_mode", decode.string)
  use text_entities <- decode.field(
    "text_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  decode.success(InputChecklistTask(
    id: id,
    text: text,
    parse_mode: parse_mode,
    text_entities: text_entities,
  ))
}

pub fn input_checklist_decoder() -> decode.Decoder(InputChecklist) {
  use title <- decode.field("title", decode.string)
  use parse_mode <- decode.field("parse_mode", decode.string)
  use title_entities <- decode.field(
    "title_entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use tasks <- decode.field(
    "tasks",
    decode.list(input_checklist_task_decoder()),
  )
  use others_can_add_tasks <- decode.field(
    "others_can_add_tasks",
    decode.optional(decode.bool),
  )
  use others_can_mark_tasks_as_done <- decode.field(
    "others_can_mark_tasks_as_done",
    decode.optional(decode.bool),
  )
  decode.success(InputChecklist(
    title: title,
    parse_mode: parse_mode,
    title_entities: title_entities,
    tasks: tasks,
    others_can_add_tasks: others_can_add_tasks,
    others_can_mark_tasks_as_done: others_can_mark_tasks_as_done,
  ))
}

pub fn checklist_tasks_done_decoder() -> decode.Decoder(ChecklistTasksDone) {
  use checklist_message <- decode.field(
    "checklist_message",
    decode.optional(message_decoder()),
  )
  use marked_as_done_task_ids <- decode.field(
    "marked_as_done_task_ids",
    decode.optional(decode.list(decode.int)),
  )
  use marked_as_not_done_task_ids <- decode.field(
    "marked_as_not_done_task_ids",
    decode.optional(decode.list(decode.int)),
  )
  decode.success(ChecklistTasksDone(
    checklist_message: checklist_message,
    marked_as_done_task_ids: marked_as_done_task_ids,
    marked_as_not_done_task_ids: marked_as_not_done_task_ids,
  ))
}

pub fn checklist_tasks_added_decoder() -> decode.Decoder(ChecklistTasksAdded) {
  use checklist_message <- decode.field(
    "checklist_message",
    decode.optional(message_decoder()),
  )
  use tasks <- decode.field("tasks", decode.list(checklist_task_decoder()))
  decode.success(ChecklistTasksAdded(
    checklist_message: checklist_message,
    tasks: tasks,
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
  use is_name_implicit <- decode.optional_field(
    "is_name_implicit",
    None,
    decode.optional(decode.bool),
  )
  decode.success(ForumTopicCreated(
    name: name,
    icon_color: icon_color,
    icon_custom_emoji_id: icon_custom_emoji_id,
    is_name_implicit: is_name_implicit,
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

pub fn paid_message_price_changed_decoder() -> decode.Decoder(
  PaidMessagePriceChanged,
) {
  use paid_message_star_count <- decode.field(
    "paid_message_star_count",
    decode.int,
  )
  decode.success(PaidMessagePriceChanged(
    paid_message_star_count: paid_message_star_count,
  ))
}

pub fn direct_message_price_changed_decoder() -> decode.Decoder(
  DirectMessagePriceChanged,
) {
  use are_direct_messages_enabled <- decode.field(
    "are_direct_messages_enabled",
    decode.bool,
  )
  use direct_message_star_count <- decode.field(
    "direct_message_star_count",
    decode.optional(decode.int),
  )
  decode.success(DirectMessagePriceChanged(
    are_direct_messages_enabled: are_direct_messages_enabled,
    direct_message_star_count: direct_message_star_count,
  ))
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
  use can_manage_direct_messages <- decode.optional_field(
    "can_manage_direct_messages",
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
    can_manage_direct_messages: can_manage_direct_messages,
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
  use can_manage_direct_messages <- decode.optional_field(
    "can_manage_direct_messages",
    None,
    decode.optional(decode.bool),
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
    can_manage_direct_messages: can_manage_direct_messages,
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
  use is_name_implicit <- decode.optional_field(
    "is_name_implicit",
    None,
    decode.optional(decode.bool),
  )
  decode.success(ForumTopic(
    message_thread_id: message_thread_id,
    name: name,
    icon_color: icon_color,
    icon_custom_emoji_id: icon_custom_emoji_id,
    is_name_implicit: is_name_implicit,
  ))
}

pub fn user_rating_decoder() -> decode.Decoder(UserRating) {
  use level <- decode.field("level", decode.int)
  use rating <- decode.field("rating", decode.int)
  use current_level_rating <- decode.field("current_level_rating", decode.int)
  use next_level_rating <- decode.optional_field(
    "next_level_rating",
    None,
    decode.optional(decode.int),
  )
  decode.success(UserRating(
    level: level,
    rating: rating,
    current_level_rating: current_level_rating,
    next_level_rating: next_level_rating,
  ))
}

pub fn unique_gift_colors_decoder() -> decode.Decoder(UniqueGiftColors) {
  use model_custom_emoji_id <- decode.field(
    "model_custom_emoji_id",
    decode.string,
  )
  use symbol_custom_emoji_id <- decode.field(
    "symbol_custom_emoji_id",
    decode.string,
  )
  use light_theme_main_color <- decode.field(
    "light_theme_main_color",
    decode.int,
  )
  use light_theme_other_colors <- decode.field(
    "light_theme_other_colors",
    decode.list(decode.int),
  )
  use dark_theme_main_color <- decode.field("dark_theme_main_color", decode.int)
  use dark_theme_other_colors <- decode.field(
    "dark_theme_other_colors",
    decode.list(decode.int),
  )
  decode.success(UniqueGiftColors(
    model_custom_emoji_id: model_custom_emoji_id,
    symbol_custom_emoji_id: symbol_custom_emoji_id,
    light_theme_main_color: light_theme_main_color,
    light_theme_other_colors: light_theme_other_colors,
    dark_theme_main_color: dark_theme_main_color,
    dark_theme_other_colors: dark_theme_other_colors,
  ))
}

pub fn gift_background_decoder() -> decode.Decoder(GiftBackground) {
  use center_color <- decode.field("center_color", decode.int)
  use edge_color <- decode.field("edge_color", decode.int)
  use text_color <- decode.field("text_color", decode.int)
  decode.success(GiftBackground(
    center_color: center_color,
    edge_color: edge_color,
    text_color: text_color,
  ))
}

pub fn direct_messages_topic_decoder() -> decode.Decoder(DirectMessagesTopic) {
  use topic_id <- decode.field("topic_id", decode.int)
  use user <- decode.optional_field(
    "user",
    None,
    decode.optional(user_decoder()),
  )
  decode.success(DirectMessagesTopic(topic_id: topic_id, user: user))
}

pub fn suggested_post_price_decoder() -> decode.Decoder(SuggestedPostPrice) {
  use currency <- decode.field("currency", decode.string)
  use amount <- decode.field("amount", decode.int)
  decode.success(SuggestedPostPrice(currency: currency, amount: amount))
}

pub fn suggested_post_info_decoder() -> decode.Decoder(SuggestedPostInfo) {
  use state <- decode.field("state", decode.string)
  use price <- decode.optional_field(
    "price",
    None,
    decode.optional(suggested_post_price_decoder()),
  )
  use send_date <- decode.optional_field(
    "send_date",
    None,
    decode.optional(decode.int),
  )
  decode.success(SuggestedPostInfo(
    state: state,
    price: price,
    send_date: send_date,
  ))
}

pub fn suggested_post_approved_decoder() -> decode.Decoder(
  SuggestedPostApproved,
) {
  use suggested_post_message <- decode.optional_field(
    "suggested_post_message",
    None,
    decode.optional(message_decoder()),
  )
  use price <- decode.optional_field(
    "price",
    None,
    decode.optional(suggested_post_price_decoder()),
  )
  use send_date <- decode.field("send_date", decode.int)
  decode.success(SuggestedPostApproved(
    suggested_post_message: suggested_post_message,
    price: price,
    send_date: send_date,
  ))
}

pub fn suggested_post_approval_failed_decoder() -> decode.Decoder(
  SuggestedPostApprovalFailed,
) {
  use suggested_post_message <- decode.optional_field(
    "suggested_post_message",
    None,
    decode.optional(message_decoder()),
  )
  use price <- decode.field("price", suggested_post_price_decoder())
  decode.success(SuggestedPostApprovalFailed(
    suggested_post_message: suggested_post_message,
    price: price,
  ))
}

pub fn suggested_post_declined_decoder() -> decode.Decoder(
  SuggestedPostDeclined,
) {
  use suggested_post_message <- decode.optional_field(
    "suggested_post_message",
    None,
    decode.optional(message_decoder()),
  )
  use comment <- decode.optional_field(
    "comment",
    None,
    decode.optional(decode.string),
  )
  decode.success(SuggestedPostDeclined(
    suggested_post_message: suggested_post_message,
    comment: comment,
  ))
}

pub fn suggested_post_paid_decoder() -> decode.Decoder(SuggestedPostPaid) {
  use suggested_post_message <- decode.optional_field(
    "suggested_post_message",
    None,
    decode.optional(message_decoder()),
  )
  use currency <- decode.field("currency", decode.string)
  use amount <- decode.optional_field(
    "amount",
    None,
    decode.optional(decode.int),
  )
  use star_amount <- decode.optional_field(
    "star_amount",
    None,
    decode.optional(star_amount_decoder()),
  )
  decode.success(SuggestedPostPaid(
    suggested_post_message: suggested_post_message,
    currency: currency,
    amount: amount,
    star_amount: star_amount,
  ))
}

pub fn suggested_post_refunded_decoder() -> decode.Decoder(
  SuggestedPostRefunded,
) {
  use suggested_post_message <- decode.optional_field(
    "suggested_post_message",
    None,
    decode.optional(message_decoder()),
  )
  use reason <- decode.field("reason", decode.string)
  decode.success(SuggestedPostRefunded(
    suggested_post_message: suggested_post_message,
    reason: reason,
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
  use is_premium <- decode.optional_field(
    "is_premium",
    None,
    decode.optional(decode.bool),
  )
  use has_colors <- decode.optional_field(
    "has_colors",
    None,
    decode.optional(decode.bool),
  )
  use total_count <- decode.field("total_count", decode.optional(decode.int))
  use remaining_count <- decode.field(
    "remaining_count",
    decode.optional(decode.int),
  )
  use personal_total_count <- decode.optional_field(
    "personal_total_count",
    None,
    decode.optional(decode.int),
  )
  use personal_remaining_count <- decode.optional_field(
    "personal_remaining_count",
    None,
    decode.optional(decode.int),
  )
  use background <- decode.optional_field(
    "background",
    None,
    decode.optional(gift_background_decoder()),
  )
  use unique_gift_variant_count <- decode.optional_field(
    "unique_gift_variant_count",
    None,
    decode.optional(decode.int),
  )
  use publisher_chat <- decode.optional_field(
    "publisher_chat",
    None,
    decode.optional(chat_decoder()),
  )
  decode.success(Gift(
    id: id,
    sticker: sticker,
    star_count: star_count,
    upgrade_star_count: upgrade_star_count,
    is_premium: is_premium,
    has_colors: has_colors,
    total_count: total_count,
    remaining_count: remaining_count,
    personal_total_count: personal_total_count,
    personal_remaining_count: personal_remaining_count,
    background: background,
    unique_gift_variant_count: unique_gift_variant_count,
    publisher_chat: publisher_chat,
  ))
}

pub fn gifts_decoder() -> decode.Decoder(Gifts) {
  use gifts <- decode.field("gifts", decode.list(gift_decoder()))
  decode.success(Gifts(gifts: gifts))
}

pub fn unique_gift_model_decoder() -> decode.Decoder(UniqueGiftModel) {
  use name <- decode.field("name", decode.string)
  use sticker <- decode.field("sticker", sticker_decoder())
  use rarity_per_mille <- decode.field("rarity_per_mille", decode.int)
  decode.success(UniqueGiftModel(
    name: name,
    sticker: sticker,
    rarity_per_mille: rarity_per_mille,
  ))
}

pub fn unique_gift_symbol_decoder() -> decode.Decoder(UniqueGiftSymbol) {
  use name <- decode.field("name", decode.string)
  use sticker <- decode.field("sticker", sticker_decoder())
  use rarity_per_mille <- decode.field("rarity_per_mille", decode.int)
  decode.success(UniqueGiftSymbol(
    name: name,
    sticker: sticker,
    rarity_per_mille: rarity_per_mille,
  ))
}

pub fn unique_gift_backdrop_colors_decoder() -> decode.Decoder(
  UniqueGiftBackdropColors,
) {
  use center_color <- decode.field("center_color", decode.int)
  use edge_color <- decode.field("edge_color", decode.int)
  use symbol_color <- decode.field("symbol_color", decode.int)
  use text_color <- decode.field("text_color", decode.int)
  decode.success(UniqueGiftBackdropColors(
    center_color: center_color,
    edge_color: edge_color,
    symbol_color: symbol_color,
    text_color: text_color,
  ))
}

pub fn unique_gift_backdrop_decoder() -> decode.Decoder(UniqueGiftBackdrop) {
  use name <- decode.field("name", decode.string)
  use colors <- decode.field("colors", unique_gift_backdrop_colors_decoder())
  use rarity_per_mille <- decode.field("rarity_per_mille", decode.int)
  decode.success(UniqueGiftBackdrop(
    name: name,
    colors: colors,
    rarity_per_mille: rarity_per_mille,
  ))
}

pub fn unique_gift_decoder() -> decode.Decoder(UniqueGift) {
  use gift_id <- decode.field("gift_id", decode.string)
  use base_name <- decode.field("base_name", decode.string)
  use name <- decode.field("name", decode.string)
  use number <- decode.field("number", decode.int)
  use model <- decode.field("model", unique_gift_model_decoder())
  use symbol <- decode.field("symbol", unique_gift_symbol_decoder())
  use backdrop <- decode.field("backdrop", unique_gift_backdrop_decoder())
  use is_premium <- decode.optional_field(
    "is_premium",
    None,
    decode.optional(decode.bool),
  )
  use is_from_blockchain <- decode.optional_field(
    "is_from_blockchain",
    None,
    decode.optional(decode.bool),
  )
  use colors <- decode.optional_field(
    "colors",
    None,
    decode.optional(unique_gift_colors_decoder()),
  )
  use publisher_chat <- decode.optional_field(
    "publisher_chat",
    None,
    decode.optional(chat_decoder()),
  )
  decode.success(UniqueGift(
    gift_id: gift_id,
    base_name: base_name,
    name: name,
    number: number,
    model: model,
    symbol: symbol,
    backdrop: backdrop,
    is_premium: is_premium,
    is_from_blockchain: is_from_blockchain,
    colors: colors,
    publisher_chat: publisher_chat,
  ))
}

pub fn gift_info_decoder() -> decode.Decoder(GiftInfo) {
  use gift <- decode.field("gift", gift_decoder())
  use owned_gift_id <- decode.field(
    "owned_gift_id",
    decode.optional(decode.string),
  )
  use convert_star_count <- decode.field(
    "convert_star_count",
    decode.optional(decode.int),
  )
  use prepaid_upgrade_star_count <- decode.field(
    "prepaid_upgrade_star_count",
    decode.optional(decode.int),
  )
  use can_be_upgraded <- decode.field(
    "can_be_upgraded",
    decode.optional(decode.bool),
  )
  use text <- decode.field("text", decode.optional(decode.string))
  use entities <- decode.field(
    "entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use is_private <- decode.field("is_private", decode.optional(decode.bool))
  use is_upgrade_separate <- decode.optional_field(
    "is_upgrade_separate",
    None,
    decode.optional(decode.bool),
  )
  use unique_gift_number <- decode.optional_field(
    "unique_gift_number",
    None,
    decode.optional(decode.int),
  )
  decode.success(GiftInfo(
    gift: gift,
    owned_gift_id: owned_gift_id,
    convert_star_count: convert_star_count,
    prepaid_upgrade_star_count: prepaid_upgrade_star_count,
    is_upgrade_separate: is_upgrade_separate,
    can_be_upgraded: can_be_upgraded,
    text: text,
    entities: entities,
    is_private: is_private,
    unique_gift_number: unique_gift_number,
  ))
}

pub fn unique_gift_info_decoder() -> decode.Decoder(UniqueGiftInfo) {
  use gift <- decode.field("gift", unique_gift_decoder())
  use origin <- decode.field("origin", decode.string)
  use last_resale_currency <- decode.optional_field(
    "last_resale_currency",
    None,
    decode.optional(decode.string),
  )
  use last_resale_amount <- decode.optional_field(
    "last_resale_amount",
    None,
    decode.optional(decode.int),
  )
  use owned_gift_id <- decode.field(
    "owned_gift_id",
    decode.optional(decode.string),
  )
  use transfer_star_count <- decode.field(
    "transfer_star_count",
    decode.optional(decode.int),
  )
  use next_transfer_date <- decode.field(
    "next_transfer_date",
    decode.optional(decode.int),
  )

  decode.success(UniqueGiftInfo(
    gift: gift,
    origin: origin,
    last_resale_currency: last_resale_currency,
    last_resale_amount: last_resale_amount,
    owned_gift_id: owned_gift_id,
    transfer_star_count: transfer_star_count,
    next_transfer_date: next_transfer_date,
  ))
}

pub fn owned_gift_decoder() -> decode.Decoder(OwnedGift) {
  use type_ <- decode.field("type_", decode.string)
  use gift <- decode.field("gift", gift_decoder())
  use owned_gift_id <- decode.field(
    "owned_gift_id",
    decode.optional(decode.string),
  )
  use sender_user <- decode.field(
    "sender_user",
    decode.optional(user_decoder()),
  )
  use send_date <- decode.field("send_date", decode.int)
  use text <- decode.field("text", decode.optional(decode.string))
  use entities <- decode.field(
    "entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use is_private <- decode.field("is_private", decode.optional(decode.bool))
  use is_saved <- decode.field("is_saved", decode.optional(decode.bool))
  use can_be_upgraded <- decode.field(
    "can_be_upgraded",
    decode.optional(decode.bool),
  )
  use was_refunded <- decode.field("was_refunded", decode.optional(decode.bool))
  use convert_star_count <- decode.field(
    "convert_star_count",
    decode.optional(decode.int),
  )
  use prepaid_upgrade_star_count <- decode.field(
    "prepaid_upgrade_star_count",
    decode.optional(decode.int),
  )
  decode.success(OwnedGift(
    type_: type_,
    gift: gift,
    owned_gift_id: owned_gift_id,
    sender_user: sender_user,
    send_date: send_date,
    text: text,
    entities: entities,
    is_private: is_private,
    is_saved: is_saved,
    can_be_upgraded: can_be_upgraded,
    was_refunded: was_refunded,
    convert_star_count: convert_star_count,
    prepaid_upgrade_star_count: prepaid_upgrade_star_count,
  ))
}

pub fn owned_gift_regular_decoder() -> decode.Decoder(OwnedGiftRegular) {
  use type_ <- decode.field("type_", decode.string)
  use gift <- decode.field("gift", gift_decoder())
  use owned_gift_id <- decode.field(
    "owned_gift_id",
    decode.optional(decode.string),
  )
  use sender_user <- decode.field(
    "sender_user",
    decode.optional(user_decoder()),
  )
  use send_date <- decode.field("send_date", decode.int)
  use text <- decode.field("text", decode.optional(decode.string))
  use entities <- decode.field(
    "entities",
    decode.optional(decode.list(message_entity_decoder())),
  )
  use is_private <- decode.field("is_private", decode.optional(decode.bool))
  use is_saved <- decode.field("is_saved", decode.optional(decode.bool))
  use can_be_upgraded <- decode.field(
    "can_be_upgraded",
    decode.optional(decode.bool),
  )
  use was_refunded <- decode.field("was_refunded", decode.optional(decode.bool))
  use convert_star_count <- decode.field(
    "convert_star_count",
    decode.optional(decode.int),
  )
  use prepaid_upgrade_star_count <- decode.field(
    "prepaid_upgrade_star_count",
    decode.optional(decode.int),
  )
  use is_upgrade_separate <- decode.optional_field(
    "is_upgrade_separate",
    None,
    decode.optional(decode.bool),
  )
  use unique_gift_number <- decode.optional_field(
    "unique_gift_number",
    None,
    decode.optional(decode.int),
  )
  decode.success(OwnedGiftRegular(
    type_: type_,
    gift: gift,
    owned_gift_id: owned_gift_id,
    sender_user: sender_user,
    send_date: send_date,
    text: text,
    entities: entities,
    is_private: is_private,
    is_saved: is_saved,
    can_be_upgraded: can_be_upgraded,
    was_refunded: was_refunded,
    convert_star_count: convert_star_count,
    prepaid_upgrade_star_count: prepaid_upgrade_star_count,
    is_upgrade_separate: is_upgrade_separate,
    unique_gift_number: unique_gift_number,
  ))
}

pub fn owned_gift_unique_decoder() -> decode.Decoder(OwnedGiftUnique) {
  use type_ <- decode.field("type_", decode.string)
  use gift <- decode.field("gift", unique_gift_decoder())
  use owned_gift_id <- decode.field(
    "owned_gift_id",
    decode.optional(decode.string),
  )
  use sender_user <- decode.field(
    "sender_user",
    decode.optional(user_decoder()),
  )
  use send_date <- decode.field("send_date", decode.int)
  use is_saved <- decode.field("is_saved", decode.optional(decode.bool))
  use can_be_transferred <- decode.field(
    "can_be_transferred",
    decode.optional(decode.bool),
  )
  use transfer_star_count <- decode.field(
    "transfer_star_count",
    decode.optional(decode.int),
  )
  use next_transfer_date <- decode.field(
    "next_transfer_date",
    decode.optional(decode.int),
  )

  decode.success(OwnedGiftUnique(
    type_: type_,
    gift: gift,
    owned_gift_id: owned_gift_id,
    sender_user: sender_user,
    send_date: send_date,
    is_saved: is_saved,
    can_be_transferred: can_be_transferred,
    transfer_star_count: transfer_star_count,
    next_transfer_date: next_transfer_date,
  ))
}

pub fn owned_gifts_decoder() -> decode.Decoder(OwnedGifts) {
  use total_count <- decode.field("total_count", decode.int)
  use gifts <- decode.field("gifts", decode.list(owned_gift_decoder()))
  use next_offset <- decode.field("next_offset", decode.optional(decode.string))
  decode.success(OwnedGifts(
    total_count: total_count,
    gifts: gifts,
    next_offset: next_offset,
  ))
}

pub fn accepted_gift_types_decoder() -> decode.Decoder(AcceptedGiftTypes) {
  use unlimited_gifts <- decode.field("unlimited_gifts", decode.bool)
  use limited_gifts <- decode.field("limited_gifts", decode.bool)
  use unique_gifts <- decode.field("unique_gifts", decode.bool)
  use premium_subscription <- decode.field("premium_subscription", decode.bool)
  use gifts_from_channels <- decode.field("gifts_from_channels", decode.bool)
  decode.success(AcceptedGiftTypes(
    unlimited_gifts: unlimited_gifts,
    limited_gifts: limited_gifts,
    unique_gifts: unique_gifts,
    premium_subscription: premium_subscription,
    gifts_from_channels: gifts_from_channels,
  ))
}

pub fn star_amount_decoder() -> decode.Decoder(StarAmount) {
  use amount <- decode.field("amount", decode.int)
  use nanostar_amount <- decode.field(
    "nanostar_amount",
    decode.optional(decode.int),
  )
  decode.success(StarAmount(amount: amount, nanostar_amount: nanostar_amount))
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
  use can_delete_sent_messages <- decode.field(
    "can_delete_sent_messages",
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
    can_delete_sent_messages: can_delete_sent_messages,
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
    "kicked" -> {
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

// Common ------------------------------------------------------------------------------------------------------------

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
