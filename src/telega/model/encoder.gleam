//// This module contains all encoders for types [Telegram Bot API](https://core.telegram.org/bots/api).

import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None, Some}
import telega/internal/utils.{json_object_filter_nulls}
import telega/model/types.{
  type AcceptedGiftTypes, type AddStickerToSetParameters, type AffiliateInfo,
  type Animation, type AnswerCallbackQueryParameters,
  type AnswerInlineQueryParameters, type AnswerPreCheckoutQueryParameters,
  type AnswerShippingQueryParameters, type ApproveChatJoinRequestParameters,
  type Audio, type BackgroundFill, type BackgroundFillFreeformGradient,
  type BackgroundFillGradient, type BackgroundFillSolid, type BackgroundType,
  type BackgroundTypeChatTheme, type BackgroundTypeFill,
  type BackgroundTypePattern, type BackgroundTypeWallpaper,
  type BanChatMemberParameters, type BanChatSenderChatParameters, type Birthdate,
  type BotCommand, type BotCommandParameters, type BotCommandScope,
  type BotCommandScopeAllChatAdministrators, type BotCommandScopeAllGroupChats,
  type BotCommandScopeAllPrivateChats, type BotCommandScopeChat,
  type BotCommandScopeChatAdministrators, type BotCommandScopeChatMember,
  type BotCommandScopeDefault, type BotDescription, type BotName,
  type BotShortDescription, type BusinessBotRights, type BusinessConnection,
  type BusinessIntro, type BusinessLocation, type BusinessMessagesDeleted,
  type BusinessOpeningHours, type BusinessOpeningHoursInterval,
  type CallbackGame, type CallbackQuery, type Chat, type ChatAction,
  type ChatAdministratorRights, type ChatBackground, type ChatBoost,
  type ChatBoostAdded, type ChatBoostRemoved, type ChatBoostSource,
  type ChatBoostSourceGiftCode, type ChatBoostSourceGiveaway,
  type ChatBoostSourcePremium, type ChatBoostUpdated, type ChatFullInfo,
  type ChatInviteLink, type ChatJoinRequest, type ChatLocation, type ChatMember,
  type ChatMemberAdministrator, type ChatMemberBanned, type ChatMemberLeft,
  type ChatMemberMember, type ChatMemberOwner, type ChatMemberRestricted,
  type ChatMemberUpdated, type ChatOwnerChanged, type ChatOwnerLeft,
  type ChatPermissions, type ChatPhoto, type ChatShared, type Checklist,
  type ChecklistTask, type ChecklistTasksAdded, type ChecklistTasksDone,
  type ChosenInlineResult, type CloseForumTopicParameters,
  type CloseGeneralForumTopicParameters, type Contact,
  type ConvertGiftToStarsParameters, type CopyMessageParameters,
  type CopyMessagesParameters, type CopyTextButton,
  type CreateChatInviteLinkParameters,
  type CreateChatSubscriptionInviteLinkParameters,
  type CreateForumTopicParameters, type CreateInvoiceLinkParameters,
  type CreateNewStickerSetParameters, type DeclineChatJoinRequestParameters,
  type DeleteBusinessMessagesParameters, type DeleteChatPhotoParameters,
  type DeleteChatStickerSetParameters, type DeleteForumTopicParameters,
  type DeleteMessageParameters, type DeleteMessagesParameters,
  type DeleteStickerFromSetParameters, type DeleteStickerSetParameters,
  type DeleteStoryParameters, type Dice, type DirectMessagePriceChanged,
  type Document, type EditChatInviteLinkParameters,
  type EditChatSubscriptionInviteLinkParameters, type EditForumTopicParameters,
  type EditGeneralForumTopicParameters, type EditMessageCaptionParameters,
  type EditMessageLiveLocationParameters, type EditMessageMediaParameters,
  type EditMessageReplyMarkupParameters, type EditMessageTextParameters,
  type EditStoryParameters, type EditUserStarSubscriptionParameters,
  type EncryptedCredentials, type EncryptedPassportElement,
  type ExportChatInviteLinkParameters, type ExternalReplyInfo, type File,
  type FileOrString, type ForceReply, type ForumTopic, type ForumTopicClosed,
  type ForumTopicCreated, type ForumTopicEdited, type ForumTopicReopened,
  type ForwardMessageParameters, type ForwardMessagesParameters, type Game,
  type GameHighScore, type GeneralForumTopicHidden,
  type GeneralForumTopicUnhidden, type GetBusinessAccountGiftsParameters,
  type GetBusinessAccountStarBalanceParameters,
  type GetBusinessConnectionParameters, type GetChatAdministratorsParameters,
  type GetChatGiftsParameters, type GetChatMemberCountParameters,
  type GetChatMemberParameters, type GetChatMenuButtonParameters,
  type GetCustomEmojiStickersParameters, type GetGameHighScoresParameters,
  type GetMyDefaultAdministratorRightsParameters,
  type GetMyDescriptionParameters, type GetMyNameParameters,
  type GetMyShortDescriptionParameters, type GetStarTransactionsParameters,
  type GetStickerSetParameters, type GetUpdatesParameters,
  type GetUserChatBoostsParameters, type GetUserGiftsParameters,
  type GetUserProfileAudiosParameters, type GetUserProfilePhotosParameters,
  type Gift, type GiftInfo, type GiftPremiumSubscriptionParameters, type Gifts,
  type Giveaway, type GiveawayCompleted, type GiveawayCreated,
  type GiveawayWinners, type HideGeneralForumTopicParameters,
  type InaccessibleMessage, type InlineKeyboardButton, type InlineKeyboardMarkup,
  type InlineQuery, type InlineQueryResult, type InlineQueryResultArticle,
  type InlineQueryResultAudio, type InlineQueryResultCachedAudio,
  type InlineQueryResultCachedDocument, type InlineQueryResultCachedGif,
  type InlineQueryResultCachedMpeg4Gif, type InlineQueryResultCachedPhoto,
  type InlineQueryResultCachedSticker, type InlineQueryResultCachedVideo,
  type InlineQueryResultCachedVoice, type InlineQueryResultContact,
  type InlineQueryResultDocument, type InlineQueryResultGame,
  type InlineQueryResultGif, type InlineQueryResultLocation,
  type InlineQueryResultMpeg4Gif, type InlineQueryResultPhoto,
  type InlineQueryResultVenue, type InlineQueryResultVideo,
  type InlineQueryResultVoice, type InlineQueryResultsButton,
  type InputChecklist, type InputChecklistTask, type InputContactMessageContent,
  type InputInvoiceMessageContent, type InputLocationMessageContent,
  type InputMedia, type InputMediaAnimation, type InputMediaAudio,
  type InputMediaDocument, type InputMediaPhoto, type InputMediaVideo,
  type InputMessageContent, type InputPaidMedia, type InputPaidMediaPhoto,
  type InputPaidMediaVideo, type InputPollOption, type InputProfilePhoto,
  type InputProfilePhotoAnimated, type InputProfilePhotoStatic,
  type InputSticker, type InputStoryContent, type InputStoryContentPhoto,
  type InputStoryContentVideo, type InputTextMessageContent,
  type InputVenueMessageContent, type IntOrString, type Invoice,
  type KeyboardButton, type KeyboardButtonPollType,
  type KeyboardButtonRequestChat, type KeyboardButtonRequestUsers,
  type LabeledPrice, type LeaveChatParameters, type LinkPreviewOptions,
  type Location, type LocationAddress, type LoginUrl, type MaskPosition,
  type MaybeInaccessibleMessage, type MenuButton, type MenuButtonCommands,
  type MenuButtonDefault, type MenuButtonWebApp, type Message,
  type MessageAutoDeleteTimerChanged, type MessageEntity, type MessageId,
  type MessageOrigin, type MessageOriginChannel, type MessageOriginChat,
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
  type PinChatMessageParameters, type Poll, type PollAnswer, type PollOption,
  type PostStoryParameters, type PreCheckoutQuery, type PreparedInlineMessage,
  type PromoteChatMemberParameters, type ProximityAlertTriggered,
  type ReactionCount, type ReactionType, type ReactionTypeCustomEmoji,
  type ReactionTypeEmoji, type ReactionTypePaid,
  type ReadBusinessMessageParameters, type RefundStarPaymentParameters,
  type RefundedPayment, type RemoveBusinessAccountProfilePhotoParameters,
  type RemoveChatVerificationParameters, type RemoveUserVerificationParameters,
  type ReopenForumTopicParameters, type ReopenGeneralForumTopicParameters,
  type ReplaceStickerInSetParameters, type ReplyKeyboardMarkup,
  type ReplyKeyboardRemove, type ReplyParameters, type RepostStoryParameters,
  type ResponseParameters, type RestrictChatMemberParameters,
  type RevenueWithdrawalState, type RevenueWithdrawalStateFailed,
  type RevenueWithdrawalStatePending, type RevenueWithdrawalStateSucceeded,
  type RevokeChatInviteLinkParameters, type SendAnimationParameters,
  type SendAudioParameters, type SendChatActionParameters,
  type SendContactParameters, type SendDiceParameters,
  type SendDocumentParameters, type SendGameParameters, type SendGiftParameters,
  type SendInvoiceParameters, type SendLocationParameters,
  type SendMediaGroupParameters, type SendMessageDraftParameters,
  type SendMessageParameters, type SendMessageReplyMarkupParameters,
  type SendPhotoParameters, type SendPollParameters, type SendStickerParameters,
  type SendVenueParameters, type SendVideoNoteParameters,
  type SendVideoParameters, type SendVoiceParameters, type SentWebAppMessage,
  type SetBusinessAccountBioParameters,
  type SetBusinessAccountGiftSettingsParameters,
  type SetBusinessAccountNameParameters,
  type SetBusinessAccountProfilePhotoParameters,
  type SetBusinessAccountUsernameParameters,
  type SetChatAdministratorCustomTitleParameters,
  type SetChatDescriptionParameters, type SetChatMenuButtonParameters,
  type SetChatPermissionsParameters, type SetChatPhotoParameters,
  type SetChatStickerSetParameters, type SetChatTitleParameters,
  type SetCustomEmojiStickerSetThumbnailParameters, type SetGameScoreParameters,
  type SetMessageReactionParameters,
  type SetMyDefaultAdministratorRightsParameters,
  type SetMyDescriptionParameters, type SetMyNameParameters,
  type SetMyProfilePhotoParameters, type SetMyShortDescriptionParameters,
  type SetStickerEmojiListParameters, type SetStickerKeywordsParameters,
  type SetStickerMaskPositionParameters, type SetStickerPositionInSetParameters,
  type SetStickerSetThumbnailParameters, type SetStickerSetTitleParameters,
  type SetWebhookParameters, type SharedUser, type ShippingAddress,
  type ShippingOption, type ShippingQuery, type StarAmount, type StarTransaction,
  type StarTransactions, type Sticker, type StickerSet,
  type StopMessageLiveLocationParameters, type StopPollParameters, type Story,
  type StoryArea, type StoryAreaPosition, type StoryAreaType,
  type StoryAreaTypeLink, type StoryAreaTypeLocation,
  type StoryAreaTypeSuggestedReaction, type StoryAreaTypeUniqueGift,
  type StoryAreaTypeWeather, type SuccessfulPayment,
  type SwitchInlineQueryChosenChat, type TextQuote, type TransactionPartner,
  type TransactionPartnerAffiliateProgram, type TransactionPartnerChat,
  type TransactionPartnerFragment, type TransactionPartnerOther,
  type TransactionPartnerTelegramAds, type TransactionPartnerTelegramApi,
  type TransactionPartnerUser, type TransferBusinessAccountStarsParameters,
  type TransferGiftParameters, type UnbanChatMemberParameters,
  type UnbanChatSenderChatParameters, type UnhideGeneralForumTopicParameters,
  type UniqueGift, type UniqueGiftBackdrop, type UniqueGiftBackdropColors,
  type UniqueGiftInfo, type UniqueGiftModel, type UniqueGiftSymbol,
  type UnpinAllChatMessagesParameters, type UnpinAllForumTopicMessagesParameters,
  type UnpinAllGeneralForumTopicMessagesParameters,
  type UnpinAllGeneralForumTopicPinnedMessagesParameters,
  type UnpinChatMessageParameters, type Update, type UpgradeGiftParameters,
  type UploadStickerFileParameters, type User, type UserChatBoosts,
  type UserProfileAudios, type UserProfilePhotos, type UsersShared, type Venue,
  type VerifyChatParameters, type VerifyUserParameters, type Video,
  type VideoChatEnded, type VideoChatParticipantsInvited,
  type VideoChatScheduled, type VideoChatStarted, type VideoNote,
  type VideoQuality, type Voice, type WebAppData, type WebAppInfo,
  type WebhookInfo, type WriteAccessAllowed,
  BackgroundFillFreeformGradientBackgroundFill,
  BackgroundFillGradientBackgroundFill, BackgroundFillSolidBackgroundFill,
  BackgroundTypeChatThemeBackgroundType, BackgroundTypeFillBackgroundType,
  BackgroundTypePatternBackgroundType, BackgroundTypeWallpaperBackgroundType,
  BotCommand, BotCommandScopeAllChatAdministratorsBotCommandScope,
  BotCommandScopeAllGroupChatsBotCommandScope,
  BotCommandScopeAllPrivateChatsBotCommandScope,
  BotCommandScopeChatAdministratorsBotCommandScope,
  BotCommandScopeChatBotCommandScope, BotCommandScopeChatMemberBotCommandScope,
  BotCommandScopeDefaultBotCommandScope, ChatBoostSourceGiftCodeChatBoostSource,
  ChatBoostSourceGiveawayChatBoostSource, ChatBoostSourcePremiumChatBoostSource,
  ChatMemberAdministratorChatMember, ChatMemberBannedChatMember,
  ChatMemberLeftChatMember, ChatMemberMemberChatMember,
  ChatMemberOwnerChatMember, ChatMemberRestrictedChatMember, ChooseSticker,
  FileV, FindLocation, InaccessibleMessageMaybeInaccessibleMessage,
  InlineQueryResultArticleInlineQueryResult,
  InlineQueryResultAudioInlineQueryResult,
  InlineQueryResultCachedAudioInlineQueryResult,
  InlineQueryResultCachedDocumentInlineQueryResult,
  InlineQueryResultCachedGifInlineQueryResult,
  InlineQueryResultCachedMpeg4GifInlineQueryResult,
  InlineQueryResultCachedPhotoInlineQueryResult,
  InlineQueryResultCachedStickerInlineQueryResult,
  InlineQueryResultCachedVideoInlineQueryResult,
  InlineQueryResultCachedVoiceInlineQueryResult,
  InlineQueryResultContactInlineQueryResult,
  InlineQueryResultDocumentInlineQueryResult,
  InlineQueryResultGameInlineQueryResult, InlineQueryResultGifInlineQueryResult,
  InlineQueryResultLocationInlineQueryResult,
  InlineQueryResultMpeg4GifInlineQueryResult,
  InlineQueryResultPhotoInlineQueryResult,
  InlineQueryResultVenueInlineQueryResult,
  InlineQueryResultVideoInlineQueryResult,
  InlineQueryResultVoiceInlineQueryResult,
  InputContactMessageContentInputMessageContent,
  InputInvoiceMessageContentInputMessageContent,
  InputLocationMessageContentInputMessageContent, InputMediaAnimationInputMedia,
  InputMediaAudioInputMedia, InputMediaDocumentInputMedia,
  InputMediaPhotoInputMedia, InputMediaVideoInputMedia,
  InputPaidMediaPhotoInputPaidMedia, InputPaidMediaVideoInputPaidMedia,
  InputProfilePhotoAnimatedInputProfilePhoto,
  InputProfilePhotoStaticInputProfilePhoto,
  InputTextMessageContentInputMessageContent,
  InputVenueMessageContentInputMessageContent, Int, MenuButtonCommandsMenuButton,
  MenuButtonDefaultMenuButton, MenuButtonWebAppMenuButton,
  MessageMaybeInaccessibleMessage, MessageOriginChannelMessageOrigin,
  MessageOriginChatMessageOrigin, MessageOriginHiddenUserMessageOrigin,
  MessageOriginUserMessageOrigin, PaidMediaPhotoPaidMedia,
  PaidMediaPreviewPaidMedia, PaidMediaVideoPaidMedia,
  PassportElementErrorDataFieldPassportElementError,
  PassportElementErrorFilePassportElementError,
  PassportElementErrorFilesPassportElementError,
  PassportElementErrorFrontSidePassportElementError,
  PassportElementErrorReverseSidePassportElementError,
  PassportElementErrorSelfiePassportElementError,
  PassportElementErrorTranslationFilePassportElementError,
  PassportElementErrorTranslationFilesPassportElementError,
  PassportElementErrorUnspecifiedPassportElementError,
  ReactionTypeCustomEmojiReactionType, ReactionTypeEmojiReactionType,
  ReactionTypePaidReactionType, RecordVideo, RecordVideoNote, RecordVoice,
  RevenueWithdrawalStateFailedRevenueWithdrawalState,
  RevenueWithdrawalStatePendingRevenueWithdrawalState,
  RevenueWithdrawalStateSucceededRevenueWithdrawalState,
  SendMessageReplyForceReplyMarkupParameters,
  SendMessageReplyInlineKeyboardMarkupParameters,
  SendMessageReplyRemoveKeyboardMarkupParameters,
  SendMessageReplyReplyKeyboardMarkupParameters, Str, StringV,
  TransactionPartnerAffiliateProgramTransactionPartner,
  TransactionPartnerChatTransactionPartner,
  TransactionPartnerFragmentTransactionPartner,
  TransactionPartnerOtherTransactionPartner,
  TransactionPartnerTelegramAdsTransactionPartner,
  TransactionPartnerTelegramApiTransactionPartner,
  TransactionPartnerUserTransactionPartner, Typing, UploadDocument, UploadPhoto,
  UploadVideo, UploadVideoNote, UploadVoice,
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
    #("has_topics_enabled", json.nullable(user.has_topics_enabled, json.bool)),
    #(
      "allows_users_to_create_topics",
      json.nullable(user.allows_users_to_create_topics, json.bool),
    ),
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
    #("is_direct_messages", json.nullable(chat.is_direct_messages, json.bool)),
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
    #(
      "first_profile_audio",
      json.nullable(chat_full_info.first_profile_audio, encode_audio),
    ),
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
      "chat_owner_left",
      json.nullable(message.chat_owner_left, encode_chat_owner_left),
    ),
    #(
      "chat_owner_changed",
      json.nullable(message.chat_owner_changed, encode_chat_owner_changed),
    ),
    #(
      "checklist_tasks_done",
      json.nullable(message.checklist_tasks_done, encode_checklist_tasks_done),
    ),
    #(
      "checklist_tasks_added",
      json.nullable(message.checklist_tasks_added, encode_checklist_tasks_added),
    ),
    #(
      "direct_message_price_changed",
      json.nullable(
        message.direct_message_price_changed,
        encode_direct_message_price_changed,
      ),
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
    #(
      "qualities",
      json.nullable(video.qualities, json.array(_, encode_video_quality)),
    ),
  ])
}

pub fn encode_video_quality(video_quality: VideoQuality) -> Json {
  json_object_filter_nulls([
    #("file_id", json.string(video_quality.file_id)),
    #("file_unique_id", json.string(video_quality.file_unique_id)),
    #("width", json.int(video_quality.width)),
    #("height", json.int(video_quality.height)),
    #("codec", json.string(video_quality.codec)),
    #("file_size", json.nullable(video_quality.file_size, json.int)),
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

pub fn encode_checklist_task(checklist_task: ChecklistTask) -> Json {
  json_object_filter_nulls([
    #("id", json.int(checklist_task.id)),
    #("text", json.string(checklist_task.text)),
    #(
      "text_entities",
      json.nullable(checklist_task.text_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "completed_by_user",
      json.nullable(checklist_task.completed_by_user, encode_user),
    ),
    #(
      "completion_date",
      json.nullable(checklist_task.completion_date, json.int),
    ),
  ])
}

pub fn encode_checklist(checklist: Checklist) -> Json {
  json_object_filter_nulls([
    #("title", json.string(checklist.title)),
    #(
      "title_entities",
      json.nullable(checklist.title_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("tasks", json.array(_, encode_checklist_task)(checklist.tasks)),
    #(
      "others_can_add_tasks",
      json.nullable(checklist.others_can_add_tasks, json.bool),
    ),
    #(
      "others_can_mark_tasks_as_done",
      json.nullable(checklist.others_can_mark_tasks_as_done, json.bool),
    ),
  ])
}

pub fn encode_input_checklist_task(
  input_checklist_task: InputChecklistTask,
) -> Json {
  json_object_filter_nulls([
    #("id", json.int(input_checklist_task.id)),
    #("text", json.string(input_checklist_task.text)),
    #("parse_mode", json.string(input_checklist_task.parse_mode)),
    #(
      "text_entities",
      json.nullable(input_checklist_task.text_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
  ])
}

pub fn encode_input_checklist(input_checklist: InputChecklist) -> Json {
  json_object_filter_nulls([
    #("title", json.string(input_checklist.title)),
    #("parse_mode", json.string(input_checklist.parse_mode)),
    #(
      "title_entities",
      json.nullable(input_checklist.title_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #(
      "tasks",
      json.array(_, encode_input_checklist_task)(input_checklist.tasks),
    ),
    #(
      "others_can_add_tasks",
      json.nullable(input_checklist.others_can_add_tasks, json.bool),
    ),
    #(
      "others_can_mark_tasks_as_done",
      json.nullable(input_checklist.others_can_mark_tasks_as_done, json.bool),
    ),
  ])
}

pub fn encode_checklist_tasks_done(
  checklist_tasks_done: ChecklistTasksDone,
) -> Json {
  json_object_filter_nulls([
    #(
      "checklist_message",
      json.nullable(checklist_tasks_done.checklist_message, encode_message),
    ),
    #(
      "marked_as_done_task_ids",
      json.nullable(checklist_tasks_done.marked_as_done_task_ids, json.array(
        _,
        json.int,
      )),
    ),
    #(
      "marked_as_not_done_task_ids",
      json.nullable(
        checklist_tasks_done.marked_as_not_done_task_ids,
        json.array(_, json.int),
      ),
    ),
  ])
}

pub fn encode_checklist_tasks_added(
  checklist_tasks_added: ChecklistTasksAdded,
) -> Json {
  json_object_filter_nulls([
    #(
      "checklist_message",
      json.nullable(checklist_tasks_added.checklist_message, encode_message),
    ),
    #(
      "tasks",
      json.array(_, encode_checklist_task)(checklist_tasks_added.tasks),
    ),
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

pub fn encode_chat_owner_left(chat_owner_left: ChatOwnerLeft) -> Json {
  json_object_filter_nulls([
    #("new_owner", json.nullable(chat_owner_left.new_owner, encode_user)),
  ])
}

pub fn encode_chat_owner_changed(chat_owner_changed: ChatOwnerChanged) -> Json {
  json_object_filter_nulls([
    #("new_owner", encode_user(chat_owner_changed.new_owner)),
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

pub fn encode_paid_message_price_changed(
  paid_message_price_changed: PaidMessagePriceChanged,
) -> Json {
  json_object_filter_nulls([
    #(
      "paid_message_star_count",
      json.int(paid_message_price_changed.paid_message_star_count),
    ),
  ])
}

pub fn encode_direct_message_price_changed(
  direct_message_price_changed: DirectMessagePriceChanged,
) -> Json {
  json_object_filter_nulls([
    #(
      "are_direct_messages_enabled",
      json.bool(direct_message_price_changed.are_direct_messages_enabled),
    ),
    #(
      "direct_message_star_count",
      json.nullable(
        direct_message_price_changed.direct_message_star_count,
        json.int,
      ),
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

pub fn encode_user_profile_audios(
  user_profile_audios: UserProfileAudios,
) -> Json {
  json_object_filter_nulls([
    #("total_count", json.int(user_profile_audios.total_count)),
    #("audios", json.array(user_profile_audios.audios, encode_audio)),
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
      "icon_custom_emoji_id",
      json.nullable(keyboard_button.icon_custom_emoji_id, json.string),
    ),
    #("style", json.nullable(keyboard_button.style, json.string)),
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
    #(
      "icon_custom_emoji_id",
      json.nullable(inline_keyboard_button.icon_custom_emoji_id, json.string),
    ),
    #("style", json.nullable(inline_keyboard_button.style, json.string)),
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

pub fn encode_story_area_position(
  story_area_position: StoryAreaPosition,
) -> Json {
  json_object_filter_nulls([
    #("x_percentage", json.float(story_area_position.x_percentage)),
    #("y_percentage", json.float(story_area_position.y_percentage)),
    #("width_percentage", json.float(story_area_position.width_percentage)),
    #("height_percentage", json.float(story_area_position.height_percentage)),
    #("rotation_angle", json.float(story_area_position.rotation_angle)),
    #(
      "corner_radius_percentage",
      json.float(story_area_position.corner_radius_percentage),
    ),
  ])
}

pub fn encode_location_address(location_address: LocationAddress) -> Json {
  json_object_filter_nulls([
    #("country_code", json.string(location_address.country_code)),
    #("state", json.nullable(location_address.state, json.string)),
    #("city", json.nullable(location_address.city, json.string)),
    #("street", json.nullable(location_address.street, json.string)),
  ])
}

pub fn encode_story_area_type(story_area_type: StoryAreaType) -> Json {
  json_object_filter_nulls([
    #("type", json.string(story_area_type.type_)),
    #("latitude", json.float(story_area_type.latitude)),
    #("longitude", json.float(story_area_type.longitude)),
    #(
      "address",
      json.nullable(story_area_type.address, encode_location_address),
    ),
  ])
}

pub fn encode_story_area_type_location(
  story_area_type_location: StoryAreaTypeLocation,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(story_area_type_location.type_)),
    #("latitude", json.float(story_area_type_location.latitude)),
    #("longitude", json.float(story_area_type_location.longitude)),
    #(
      "address",
      json.nullable(story_area_type_location.address, encode_location_address),
    ),
  ])
}

pub fn encode_story_area_type_suggested_reaction(
  story_area_type_suggested_reaction: StoryAreaTypeSuggestedReaction,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(story_area_type_suggested_reaction.type_)),
    #(
      "reaction_type",
      encode_reaction_type(story_area_type_suggested_reaction.reaction_type),
    ),
    #(
      "is_dark",
      json.nullable(story_area_type_suggested_reaction.is_dark, json.bool),
    ),
    #(
      "is_flipped",
      json.nullable(story_area_type_suggested_reaction.is_flipped, json.bool),
    ),
  ])
}

pub fn encode_story_area_type_link(
  story_area_type_link: StoryAreaTypeLink,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(story_area_type_link.type_)),
    #("url", json.string(story_area_type_link.url)),
  ])
}

pub fn encode_story_area_type_weather(
  story_area_type_weather: StoryAreaTypeWeather,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(story_area_type_weather.type_)),
    #("temperature", json.float(story_area_type_weather.temperature)),
    #("emoji", json.string(story_area_type_weather.emoji)),
    #("background_color", json.int(story_area_type_weather.background_color)),
  ])
}

pub fn encode_story_area_type_unique_gift(
  story_area_type_unique_gift: StoryAreaTypeUniqueGift,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(story_area_type_unique_gift.type_)),
    #("name", json.string(story_area_type_unique_gift.name)),
  ])
}

pub fn encode_story_area(story_area: StoryArea) -> Json {
  json_object_filter_nulls([
    #("position", encode_story_area_position(story_area.position)),
    #("type", encode_story_area_type(story_area.type_)),
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

pub fn encode_unique_gift_model(unique_gift_model: UniqueGiftModel) -> Json {
  json_object_filter_nulls([
    #("name", json.string(unique_gift_model.name)),
    #("sticker", encode_sticker(unique_gift_model.sticker)),
    #("rarity_per_mille", json.int(unique_gift_model.rarity_per_mille)),
    #("rarity", json.nullable(unique_gift_model.rarity, json.string)),
  ])
}

pub fn encode_unique_gift_symbol(unique_gift_symbol: UniqueGiftSymbol) -> Json {
  json_object_filter_nulls([
    #("name", json.string(unique_gift_symbol.name)),
    #("sticker", encode_sticker(unique_gift_symbol.sticker)),
    #("rarity_per_mille", json.int(unique_gift_symbol.rarity_per_mille)),
  ])
}

pub fn encode_unique_gift_backdrop_colors(
  unique_gift_backdrop_colors: UniqueGiftBackdropColors,
) -> Json {
  json_object_filter_nulls([
    #("center_color", json.int(unique_gift_backdrop_colors.center_color)),
    #("edge_color", json.int(unique_gift_backdrop_colors.edge_color)),
    #("symbol_color", json.int(unique_gift_backdrop_colors.symbol_color)),
    #("text_color", json.int(unique_gift_backdrop_colors.text_color)),
  ])
}

pub fn encode_unique_gift_backdrop(
  unique_gift_backdrop: UniqueGiftBackdrop,
) -> Json {
  json_object_filter_nulls([
    #("name", json.string(unique_gift_backdrop.name)),
    #("colors", encode_unique_gift_backdrop_colors(unique_gift_backdrop.colors)),
    #("rarity_per_mille", json.int(unique_gift_backdrop.rarity_per_mille)),
  ])
}

pub fn encode_unique_gift(unique_gift: UniqueGift) -> Json {
  json_object_filter_nulls([
    #("gift_id", json.string(unique_gift.gift_id)),
    #("base_name", json.string(unique_gift.base_name)),
    #("name", json.string(unique_gift.name)),
    #("number", json.int(unique_gift.number)),
    #("model", encode_unique_gift_model(unique_gift.model)),
    #("symbol", encode_unique_gift_symbol(unique_gift.symbol)),
    #("backdrop", encode_unique_gift_backdrop(unique_gift.backdrop)),
    #("is_premium", json.nullable(unique_gift.is_premium, json.bool)),
    #("is_burned", json.nullable(unique_gift.is_burned, json.bool)),
    #(
      "is_from_blockchain",
      json.nullable(unique_gift.is_from_blockchain, json.bool),
    ),
  ])
}

pub fn encode_gift_info(gift_info: GiftInfo) -> Json {
  json_object_filter_nulls([
    #("gift", encode_gift(gift_info.gift)),
    #("owned_gift_id", json.nullable(gift_info.owned_gift_id, json.string)),
    #(
      "convert_star_count",
      json.nullable(gift_info.convert_star_count, json.int),
    ),
    #(
      "prepaid_upgrade_star_count",
      json.nullable(gift_info.prepaid_upgrade_star_count, json.int),
    ),
    #("can_be_upgraded", json.nullable(gift_info.can_be_upgraded, json.bool)),
    #("text", json.nullable(gift_info.text, json.string)),
    #(
      "entities",
      json.nullable(gift_info.entities, json.array(_, encode_message_entity)),
    ),
    #("is_private", json.nullable(gift_info.is_private, json.bool)),
  ])
}

pub fn encode_unique_gift_info(unique_gift_info: UniqueGiftInfo) -> Json {
  json_object_filter_nulls([
    #("gift", encode_unique_gift(unique_gift_info.gift)),
    #("origin", json.string(unique_gift_info.origin)),
    #(
      "last_resale_currency",
      json.nullable(unique_gift_info.last_resale_currency, json.string),
    ),
    #(
      "last_resale_amount",
      json.nullable(unique_gift_info.last_resale_amount, json.int),
    ),
    #(
      "owned_gift_id",
      json.nullable(unique_gift_info.owned_gift_id, json.string),
    ),
    #(
      "transfer_star_count",
      json.nullable(unique_gift_info.transfer_star_count, json.int),
    ),
    #(
      "next_transfer_date",
      json.nullable(unique_gift_info.next_transfer_date, json.int),
    ),
  ])
}

pub fn encode_owned_gift(owned_gift: OwnedGift) -> Json {
  json_object_filter_nulls([
    #("type", json.string(owned_gift.type_)),
    #("gift", encode_gift(owned_gift.gift)),
    #("owned_gift_id", json.nullable(owned_gift.owned_gift_id, json.string)),
    #("sender_user", json.nullable(owned_gift.sender_user, encode_user)),
    #("send_date", json.int(owned_gift.send_date)),
    #("text", json.nullable(owned_gift.text, json.string)),
    #(
      "entities",
      json.nullable(owned_gift.entities, json.array(_, encode_message_entity)),
    ),
    #("is_private", json.nullable(owned_gift.is_private, json.bool)),
    #("is_saved", json.nullable(owned_gift.is_saved, json.bool)),
    #("can_be_upgraded", json.nullable(owned_gift.can_be_upgraded, json.bool)),
    #("was_refunded", json.nullable(owned_gift.was_refunded, json.bool)),
    #(
      "convert_star_count",
      json.nullable(owned_gift.convert_star_count, json.int),
    ),
    #(
      "prepaid_upgrade_star_count",
      json.nullable(owned_gift.prepaid_upgrade_star_count, json.int),
    ),
  ])
}

pub fn encode_owned_gift_regular(owned_gift_regular: OwnedGiftRegular) -> Json {
  json_object_filter_nulls([
    #("type", json.string(owned_gift_regular.type_)),
    #("gift", encode_gift(owned_gift_regular.gift)),
    #(
      "owned_gift_id",
      json.nullable(owned_gift_regular.owned_gift_id, json.string),
    ),
    #("sender_user", json.nullable(owned_gift_regular.sender_user, encode_user)),
    #("send_date", json.int(owned_gift_regular.send_date)),
    #("text", json.nullable(owned_gift_regular.text, json.string)),
    #(
      "entities",
      json.nullable(owned_gift_regular.entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("is_private", json.nullable(owned_gift_regular.is_private, json.bool)),
    #("is_saved", json.nullable(owned_gift_regular.is_saved, json.bool)),
    #(
      "can_be_upgraded",
      json.nullable(owned_gift_regular.can_be_upgraded, json.bool),
    ),
    #("was_refunded", json.nullable(owned_gift_regular.was_refunded, json.bool)),
    #(
      "convert_star_count",
      json.nullable(owned_gift_regular.convert_star_count, json.int),
    ),
    #(
      "prepaid_upgrade_star_count",
      json.nullable(owned_gift_regular.prepaid_upgrade_star_count, json.int),
    ),
  ])
}

pub fn encode_owned_gift_unique(owned_gift_unique: OwnedGiftUnique) -> Json {
  json_object_filter_nulls([
    #("type", json.string(owned_gift_unique.type_)),
    #("gift", encode_unique_gift(owned_gift_unique.gift)),
    #(
      "owned_gift_id",
      json.nullable(owned_gift_unique.owned_gift_id, json.string),
    ),
    #("sender_user", json.nullable(owned_gift_unique.sender_user, encode_user)),
    #("send_date", json.int(owned_gift_unique.send_date)),
    #("is_saved", json.nullable(owned_gift_unique.is_saved, json.bool)),
    #(
      "can_be_transferred",
      json.nullable(owned_gift_unique.can_be_transferred, json.bool),
    ),
    #(
      "transfer_star_count",
      json.nullable(owned_gift_unique.transfer_star_count, json.int),
    ),
    #(
      "next_transfer_date",
      json.nullable(owned_gift_unique.next_transfer_date, json.int),
    ),
  ])
}

pub fn encode_owned_gifts(owned_gifts: OwnedGifts) -> Json {
  json_object_filter_nulls([
    #("total_count", json.int(owned_gifts.total_count)),
    #("gifts", json.array(_, encode_owned_gift)(owned_gifts.gifts)),
    #("next_offset", json.nullable(owned_gifts.next_offset, json.string)),
  ])
}

pub fn encode_accepted_gift_types(
  accepted_gift_types: AcceptedGiftTypes,
) -> Json {
  json_object_filter_nulls([
    #("unlimited_gifts", json.bool(accepted_gift_types.unlimited_gifts)),
    #("limited_gifts", json.bool(accepted_gift_types.limited_gifts)),
    #("unique_gifts", json.bool(accepted_gift_types.unique_gifts)),
    #(
      "premium_subscription",
      json.bool(accepted_gift_types.premium_subscription),
    ),
  ])
}

pub fn encode_star_amount(star_amount: StarAmount) -> Json {
  json_object_filter_nulls([
    #("amount", json.int(star_amount.amount)),
    #("nanostar_amount", json.nullable(star_amount.nanostar_amount, json.int)),
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
      "can_delete_sent_messages",
      json.nullable(business_bot_rights.can_delete_sent_messages, json.bool),
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

pub fn encode_input_profile_photo_static(
  input_profile_photo_static: InputProfilePhotoStatic,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_profile_photo_static.type_)),
    #("photo", json.string(input_profile_photo_static.photo)),
  ])
}

pub fn encode_input_profile_photo_animated(
  input_profile_photo_animated: InputProfilePhotoAnimated,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_profile_photo_animated.type_)),
    #("animation", json.string(input_profile_photo_animated.animation)),
    #(
      "main_frame_timestamp",
      json.nullable(
        input_profile_photo_animated.main_frame_timestamp,
        json.float,
      ),
    ),
  ])
}

pub fn encode_input_story_content(
  input_story_content: InputStoryContent,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_story_content.type_)),
    #("photo", json.string(input_story_content.photo)),
  ])
}

pub fn encode_input_story_content_photo(
  input_story_content_photo: InputStoryContentPhoto,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_story_content_photo.type_)),
    #("photo", json.string(input_story_content_photo.photo)),
  ])
}

pub fn encode_input_story_content_video(
  input_story_content_video: InputStoryContentVideo,
) -> Json {
  json_object_filter_nulls([
    #("type", json.string(input_story_content_video.type_)),
    #("video", json.string(input_story_content_video.video)),
    #("duration", json.nullable(input_story_content_video.duration, json.float)),
    #(
      "cover_frame_timestamp",
      json.nullable(input_story_content_video.cover_frame_timestamp, json.float),
    ),
    #(
      "is_animation",
      json.nullable(input_story_content_video.is_animation, json.bool),
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

pub fn encode_input_profile_photo(value: InputProfilePhoto) -> Json {
  case value {
    InputProfilePhotoStaticInputProfilePhoto(inner_value) ->
      encode_input_profile_photo_static(inner_value)

    InputProfilePhotoAnimatedInputProfilePhoto(inner_value) ->
      encode_input_profile_photo_animated(inner_value)
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

pub fn encode_file_or_string(value: FileOrString) -> Json {
  case value {
    FileV(value) -> encode_file(value)
    StringV(string) -> json.string(string)
  }
}

// AnswerCallbackQueryParameters --------------------------------------------------------------------------------------
// https://core.telegram.org/bots/api#answercallbackquery

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

pub fn encode_bot_command_parameters(
  params: BotCommandParameters,
) -> List(#(String, Json)) {
  [
    #("scope", json.nullable(params.scope, bot_command_scope_to_json)),
    #("language_code", json.nullable(params.language_code, json.string)),
  ]
}

pub fn bot_command_scope_to_json(scope: BotCommandScope) -> Json {
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
    BotCommandScopeChatBotCommandScope(scope) ->
      json_object_filter_nulls([
        #("type", json.string("chat")),
        #("chat_id", encode_int_or_string(scope.chat_id)),
      ])
    BotCommandScopeChatAdministratorsBotCommandScope(scope) ->
      json_object_filter_nulls([
        #("type", json.string("chat_administrators")),
        #("chat_id", encode_int_or_string(scope.chat_id)),
      ])
    BotCommandScopeChatMemberBotCommandScope(scope) ->
      json_object_filter_nulls([
        #("type", json.string("chat_member")),
        #("chat_id", encode_int_or_string(scope.chat_id)),
        #("user_id", json.int(scope.user_id)),
      ])
  }
}

pub fn bot_commands_from(commands: List(#(String, String))) -> List(BotCommand) {
  commands
  |> list.map(fn(cmd) {
    let #(command, description) = cmd
    BotCommand(command: command, description: description)
  })
}

// EditMessageTextParameters ------------------------------------------------------------------------------------------

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

pub fn encode_set_chat_menu_button_parameters(
  params: SetChatMenuButtonParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", json.nullable(params.chat_id, json.int)),
    #("menu_button", json.nullable(params.menu_button, encode_menu_button)),
  ])
}

// SetWebhookParameters ----------------------------------------------------------------------------------------------

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

pub fn encode_get_updates_parameters(params: GetUpdatesParameters) -> Json {
  json_object_filter_nulls([
    #("offset", json.nullable(params.offset, json.int)),
    #("limit", json.nullable(params.limit, json.int)),
    #("timeout", json.nullable(params.timeout, json.int)),
    #(
      "allowed_updates",
      json.nullable(params.allowed_updates, json.array(_, json.string)),
    ),
  ])
}

pub fn encode_get_updates_parameters_as_query(
  params: GetUpdatesParameters,
) -> List(#(String, String)) {
  let mut_query = []

  let mut_query = case params.offset {
    Some(offset) -> [#("offset", int.to_string(offset)), ..mut_query]
    None -> mut_query
  }

  let mut_query = case params.limit {
    Some(limit) -> [#("limit", int.to_string(limit)), ..mut_query]
    None -> mut_query
  }

  let mut_query = case params.timeout {
    Some(timeout) -> [#("timeout", int.to_string(timeout)), ..mut_query]
    None -> mut_query
  }

  let mut_query = case params.allowed_updates {
    Some(allowed_updates) -> [
      #(
        "allowed_updates",
        json.array(allowed_updates, json.string) |> json.to_string,
      ),
      ..mut_query
    ]
    None -> mut_query
  }

  list.reverse(mut_query)
}

// CopyMessageParameters ---------------------------------------------------------------------------------------------

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

pub fn encode_get_sticker_set_parameters(
  params: GetStickerSetParameters,
) -> Json {
  json_object_filter_nulls([#("name", json.string(params.name))])
}

// SetMessageReactionParameters --------------------------------------------------------------------------------------

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

pub fn encode_get_user_profile_photos_parameters(
  params: GetUserProfilePhotosParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("offset", json.nullable(params.offset, json.int)),
    #("limit", json.nullable(params.limit, json.int)),
  ])
}

// GetUserProfileAudiosParameters --------------------------------------------------------------------------------------

pub fn encode_get_user_profile_audios_parameters(
  params: GetUserProfileAudiosParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("offset", json.nullable(params.offset, json.int)),
    #("limit", json.nullable(params.limit, json.int)),
  ])
}

// SetMyProfilePhotoParameters --------------------------------------------------------------------------------------

pub fn encode_set_my_profile_photo_parameters(
  params: SetMyProfilePhotoParameters,
) -> Json {
  json_object_filter_nulls([
    #("photo", encode_input_profile_photo(params.photo)),
  ])
}

// EditMessageCaptionParameters --------------------------------------------------------------------------------------

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

// EditMessageLiveLocationParameters ----------------------------------------------

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

// StopMessageLiveLocationParameters ----------------------------------------------

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

pub fn encode_delete_message_parameters(params: DeleteMessageParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_id", json.int(params.message_id)),
  ])
}

// DeleteMessagesParameters -----------------------------------------------------------------------------------------

pub fn encode_delete_messages_parameters(
  params: DeleteMessagesParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_ids", json.array(params.message_ids, json.int)),
  ])
}

// BanChatMemberParameters ------------------------------------------------------------------------------------------

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

pub fn encode_ban_chat_sender_chat_parameters(
  params: BanChatSenderChatParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("sender_chat_id", json.int(params.sender_chat_id)),
  ])
}

// UnbanChatSenderChatParameters -----------------------------------------------------------------------------------

pub fn encode_unban_chat_sender_chat_parameters(
  params: UnbanChatSenderChatParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("sender_chat_id", json.int(params.sender_chat_id)),
  ])
}

// SetChatPermissionsParameters -------------------------------------------------------------------------------------

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

pub fn encode_export_chat_invite_link_parameters(
  params: ExportChatInviteLinkParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// CreateChatInviteLinkParameters ----------------------------------------------------------------------------------

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

pub fn encode_revoke_chat_invite_link_parameters(
  params: RevokeChatInviteLinkParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("invite_link", json.string(params.invite_link)),
  ])
}

// ApproveChatJoinRequestParameters ------------------------------------------------------------

pub fn encode_approve_chat_join_request_parameters(
  params: ApproveChatJoinRequestParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
  ])
}

// DeclineChatJoinRequestParameters ------------------------------------------------------------

pub fn encode_decline_chat_join_request_parameters(
  params: DeclineChatJoinRequestParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
  ])
}

// SetChatPhotoParameters ------------------------------------------------------------

pub fn encode_set_chat_photo_parameters(params: SetChatPhotoParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("photo", encode_file(params.photo)),
  ])
}

// DeleteChatPhotoParameters ------------------------------------------------------------

pub fn encode_delete_chat_photo_parameters(
  params: DeleteChatPhotoParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// SetChatTitleParameters ------------------------------------------------------------

pub fn encode_set_chat_title_parameters(params: SetChatTitleParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("title", json.string(params.title)),
  ])
}

// SetChatDescriptionParameters ------------------------------------------------------------

pub fn encode_set_chat_description_parameters(
  params: SetChatDescriptionParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("description", json.nullable(params.description, json.string)),
  ])
}

// PinChatMessageParameters ------------------------------------------------------------

pub fn encode_pin_chat_message_parameters(
  params: PinChatMessageParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_id", json.int(params.message_id)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
  ])
}

// UnpinChatMessageParameters ------------------------------------------------------------

pub fn encode_unpin_chat_message_parameters(
  params: UnpinChatMessageParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_id", json.nullable(params.message_id, json.int)),
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
  ])
}

// UnpinAllChatMessagesParameters ------------------------------------------------------------

pub fn encode_unpin_all_chat_messages_parameters(
  params: UnpinAllChatMessagesParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// LeaveChatParameters ------------------------------------------------------------

pub fn encode_leave_chat_parameters(params: LeaveChatParameters) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// GetChatAdministratorsParameters ------------------------------------------------------------

pub fn encode_get_chat_administrators_parameters(
  params: GetChatAdministratorsParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// GetChatMemberCountParameters ------------------------------------------------------------

pub fn encode_get_chat_member_count_parameters(
  params: GetChatMemberCountParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// GetChatMemberParameters ------------------------------------------------------------

pub fn encode_get_chat_member_parameters(
  params: GetChatMemberParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
  ])
}

// SetChatStickerSetParameters ------------------------------------------------------------

pub fn encode_set_chat_sticker_set_parameters(
  params: SetChatStickerSetParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("sticker_set_name", json.string(params.sticker_set_name)),
  ])
}

// DeleteChatStickerSetParameters ------------------------------------------------------------

pub fn encode_delete_chat_sticker_set_parameters(
  params: DeleteChatStickerSetParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// CreateForumTopicParameters ------------------------------------------------------------

pub fn encode_create_forum_topic_parameters(
  params: CreateForumTopicParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("name", json.string(params.name)),
    #("icon_color", json.nullable(params.icon_color, json.int)),
    #(
      "icon_custom_emoji_id",
      json.nullable(params.icon_custom_emoji_id, json.string),
    ),
  ])
}

// EditForumTopicParameters ------------------------------------------------------------

pub fn encode_edit_forum_topic_parameters(
  params: EditForumTopicParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_thread_id", json.int(params.message_thread_id)),
    #("name", json.nullable(params.name, json.string)),
    #(
      "icon_custom_emoji_id",
      json.nullable(params.icon_custom_emoji_id, json.string),
    ),
  ])
}

// CloseForumTopicParameters ------------------------------------------------------------

pub fn encode_close_forum_topic_parameters(
  params: CloseForumTopicParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_thread_id", json.int(params.message_thread_id)),
  ])
}

// ReopenForumTopicParameters ------------------------------------------------------------

pub fn encode_reopen_forum_topic_parameters(
  params: ReopenForumTopicParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_thread_id", json.int(params.message_thread_id)),
  ])
}

// DeleteForumTopicParameters ------------------------------------------------------------

pub fn encode_delete_forum_topic_parameters(
  params: DeleteForumTopicParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_thread_id", json.int(params.message_thread_id)),
  ])
}

// UnpinAllForumTopicMessagesParameters ------------------------------------------------------------

pub fn encode_unpin_all_forum_topic_messages_parameters(
  params: UnpinAllForumTopicMessagesParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("message_thread_id", json.int(params.message_thread_id)),
  ])
}

// UnpinAllGeneralForumTopicPinnedMessagesParameters ------------------------------------------------------------

pub fn encode_unpin_all_general_forum_topic_pinned_messages_parameters(
  params: UnpinAllGeneralForumTopicPinnedMessagesParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// EditGeneralForumTopicParameters ------------------------------------------------------------

pub fn encode_edit_general_forum_topic_parameters(
  params: EditGeneralForumTopicParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("name", json.string(params.name)),
  ])
}

// CloseGeneralForumTopicParameters ------------------------------------------------------------

pub fn encode_close_general_forum_topic_parameters(
  params: CloseGeneralForumTopicParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// ReopenGeneralForumTopicParameters ------------------------------------------------------------

pub fn encode_reopen_general_forum_topic_parameters(
  params: ReopenGeneralForumTopicParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// HideGeneralForumTopicParameters ------------------------------------------------------------

pub fn encode_hide_general_forum_topic_parameters(
  params: HideGeneralForumTopicParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// UnhideGeneralForumTopicParameters ------------------------------------------------------------

pub fn encode_unhide_general_forum_topic_parameters(
  params: UnhideGeneralForumTopicParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// UnpinAllGeneralForumTopicMessagesParameters ------------------------------------------------------------

pub fn encode_unpin_all_general_forum_topic_messages_parameters(
  params: UnpinAllGeneralForumTopicMessagesParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// GetUserChatBoostsParameters ------------------------------------------------------------

pub fn encode_get_user_chat_boosts_parameters(
  params: GetUserChatBoostsParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("user_id", json.int(params.user_id)),
  ])
}

// GetBusinessConnectionParameters ------------------------------------------------------------

pub fn encode_get_business_connection_parameters(
  params: GetBusinessConnectionParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
  ])
}

// SetMyNameParameters ------------------------------------------------------------

pub fn encode_set_my_name_parameters(params: SetMyNameParameters) -> Json {
  json_object_filter_nulls([
    #("name", json.nullable(params.name, json.string)),
    #("language_code", json.nullable(params.language_code, json.string)),
  ])
}

// GetMyNameParameters ------------------------------------------------------------

pub fn encode_get_my_name_parameters(params: GetMyNameParameters) -> Json {
  json_object_filter_nulls([
    #("language_code", json.nullable(params.language_code, json.string)),
  ])
}

// SetMyDescriptionParameters ------------------------------------------------------------

pub fn encode_set_my_description_parameters(
  params: SetMyDescriptionParameters,
) -> Json {
  json_object_filter_nulls([
    #("description", json.nullable(params.description, json.string)),
    #("language_code", json.nullable(params.language_code, json.string)),
  ])
}

// GetMyDescriptionParameters ------------------------------------------------------------

pub fn encode_get_my_description_parameters(
  params: GetMyDescriptionParameters,
) -> Json {
  json_object_filter_nulls([
    #("language_code", json.nullable(params.language_code, json.string)),
  ])
}

// SetMyShortDescriptionParameters ------------------------------------------------------------

pub fn encode_set_my_short_description_parameters(
  params: SetMyShortDescriptionParameters,
) -> Json {
  json_object_filter_nulls([
    #("short_description", json.nullable(params.short_description, json.string)),
    #("language_code", json.nullable(params.language_code, json.string)),
  ])
}

// GetMyShortDescriptionParameters ------------------------------------------------------------

pub fn encode_get_my_short_description_parameters(
  params: GetMyShortDescriptionParameters,
) -> Json {
  json_object_filter_nulls([
    #("language_code", json.nullable(params.language_code, json.string)),
  ])
}

// GetChatMenuButtonParameters ------------------------------------------------------------

pub fn encode_get_chat_menu_button_parameters(
  params: GetChatMenuButtonParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", json.nullable(params.chat_id, json.int)),
  ])
}

// SetMyDefaultAdministratorRightsParameters ------------------------------------------------------------

pub fn encode_set_my_default_administrator_rights_parameters(
  params: SetMyDefaultAdministratorRightsParameters,
) -> Json {
  json_object_filter_nulls([
    #("rights", json.nullable(params.rights, encode_chat_administrator_rights)),
    #("for_channels", json.nullable(params.for_channels, json.bool)),
  ])
}

// GetMyDefaultAdministratorRightsParameters ------------------------------------------------------------

pub fn encode_get_my_default_administrator_rights_parameters(
  params: GetMyDefaultAdministratorRightsParameters,
) -> Json {
  json_object_filter_nulls([
    #("for_channels", json.nullable(params.for_channels, json.bool)),
  ])
}

// SendGiftParameters ------------------------------------------------------------

pub fn encode_send_gift_parameters(params: SendGiftParameters) -> Json {
  json_object_filter_nulls([
    #("user_id", json.nullable(params.user_id, json.int)),
    #("chat_id", json.nullable(params.chat_id, encode_int_or_string)),
    #("gift_id", json.string(params.gift_id)),
    #("pay_for_upgrade", json.nullable(params.pay_for_upgrade, json.bool)),
    #("text", json.nullable(params.text, json.string)),
    #("text_parse_mode", json.nullable(params.text_parse_mode, json.string)),
    #(
      "text_entities",
      json.nullable(params.text_entities, json.array(_, encode_message_entity)),
    ),
  ])
}

// GiftPremiumSubscriptionParameters ------------------------------------------------------------

pub fn encode_gift_premium_subscription_parameters(
  params: GiftPremiumSubscriptionParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("month_count", json.int(params.month_count)),
    #("star_count", json.int(params.star_count)),
    #("text", json.nullable(params.text, json.string)),
    #("text_parse_mode", json.nullable(params.text_parse_mode, json.string)),
    #(
      "text_entities",
      json.nullable(params.text_entities, json.array(_, encode_message_entity)),
    ),
  ])
}

// SendMessageDraftParameters ------------------------------------------------------------

pub fn encode_send_message_draft_parameters(
  params: SendMessageDraftParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", json.int(params.chat_id)),
    #("draft_id", json.int(params.draft_id)),
    #("text", json.string(params.text)),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "entities",
      json.nullable(params.entities, json.array(_, encode_message_entity)),
    ),
  ])
}

// GetUserGiftsParameters ------------------------------------------------------------

pub fn encode_get_user_gifts_parameters(params: GetUserGiftsParameters) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("exclude_unlimited", json.nullable(params.exclude_unlimited, json.bool)),
    #(
      "exclude_limited_upgradable",
      json.nullable(params.exclude_limited_upgradable, json.bool),
    ),
    #(
      "exclude_limited_non_upgradable",
      json.nullable(params.exclude_limited_non_upgradable, json.bool),
    ),
    #(
      "exclude_from_blockchain",
      json.nullable(params.exclude_from_blockchain, json.bool),
    ),
    #("exclude_unique", json.nullable(params.exclude_unique, json.bool)),
    #("sort_by_price", json.nullable(params.sort_by_price, json.bool)),
    #("offset", json.nullable(params.offset, json.string)),
    #("limit", json.nullable(params.limit, json.int)),
  ])
}

// GetChatGiftsParameters ------------------------------------------------------------

pub fn encode_get_chat_gifts_parameters(params: GetChatGiftsParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("exclude_unsaved", json.nullable(params.exclude_unsaved, json.bool)),
    #("exclude_saved", json.nullable(params.exclude_saved, json.bool)),
    #("exclude_unlimited", json.nullable(params.exclude_unlimited, json.bool)),
    #(
      "exclude_limited_upgradable",
      json.nullable(params.exclude_limited_upgradable, json.bool),
    ),
    #(
      "exclude_limited_non_upgradable",
      json.nullable(params.exclude_limited_non_upgradable, json.bool),
    ),
    #(
      "exclude_from_blockchain",
      json.nullable(params.exclude_from_blockchain, json.bool),
    ),
    #("exclude_unique", json.nullable(params.exclude_unique, json.bool)),
    #("sort_by_price", json.nullable(params.sort_by_price, json.bool)),
    #("offset", json.nullable(params.offset, json.string)),
    #("limit", json.nullable(params.limit, json.int)),
  ])
}

// RepostStoryParameters ------------------------------------------------------------

pub fn encode_repost_story_parameters(params: RepostStoryParameters) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("from_chat_id", json.int(params.from_chat_id)),
    #("from_story_id", json.int(params.from_story_id)),
    #("active_period", json.int(params.active_period)),
    #("post_to_chat_page", json.nullable(params.post_to_chat_page, json.bool)),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
  ])
}

// VerifyUserParameters ------------------------------------------------------------

pub fn encode_verify_user_parameters(params: VerifyUserParameters) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #(
      "custom_description",
      json.nullable(params.custom_description, json.string),
    ),
  ])
}

// VerifyChatParameters ------------------------------------------------------------

pub fn encode_verify_chat_parameters(params: VerifyChatParameters) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #(
      "custom_description",
      json.nullable(params.custom_description, json.string),
    ),
  ])
}

// RemoveUserVerificationParameters ------------------------------------------------------------

pub fn encode_remove_user_verification_parameters(
  params: RemoveUserVerificationParameters,
) -> Json {
  json_object_filter_nulls([#("user_id", json.int(params.user_id))])
}

// RemoveChatVerificationParameters ------------------------------------------------------------

pub fn encode_remove_chat_verification_parameters(
  params: RemoveChatVerificationParameters,
) -> Json {
  json_object_filter_nulls([#("chat_id", encode_int_or_string(params.chat_id))])
}

// GetCustomEmojiStickersParameters ------------------------------------------------------------

pub fn encode_get_custom_emoji_stickers_parameters(
  params: GetCustomEmojiStickersParameters,
) -> Json {
  json_object_filter_nulls([
    #("custom_emoji_ids", json.array(params.custom_emoji_ids, json.string)),
  ])
}

// UploadStickerFileParameters ------------------------------------------------------------

pub fn encode_upload_sticker_file_parameters(
  params: UploadStickerFileParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("sticker", encode_file(params.sticker)),
    #("sticker_format", json.string(params.sticker_format)),
  ])
}

// CreateNewStickerSetParameters ------------------------------------------------------------

pub fn encode_create_new_sticker_set_parameters(
  params: CreateNewStickerSetParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("name", json.string(params.name)),
    #("title", json.string(params.title)),
    #("stickers", json.array(params.stickers, encode_input_sticker)),
    #("sticker_type", json.nullable(params.sticker_type, json.string)),
    #("needs_repainting", json.nullable(params.needs_repainting, json.bool)),
  ])
}

// AddStickerToSetParameters ------------------------------------------------------------

pub fn encode_add_sticker_to_set_parameters(
  params: AddStickerToSetParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("name", json.string(params.name)),
    #("sticker", encode_input_sticker(params.sticker)),
  ])
}

// SetStickerPositionInSetParameters ------------------------------------------------------------

pub fn encode_set_sticker_position_in_set_parameters(
  params: SetStickerPositionInSetParameters,
) -> Json {
  json_object_filter_nulls([
    #("sticker", json.string(params.sticker)),
    #("position", json.int(params.position)),
  ])
}

// DeleteStickerFromSetParameters ------------------------------------------------------------

pub fn encode_delete_sticker_from_set_parameters(
  params: DeleteStickerFromSetParameters,
) -> Json {
  json_object_filter_nulls([#("sticker", json.string(params.sticker))])
}

// ReplaceStickerInSetParameters ------------------------------------------------------------

pub fn encode_replace_sticker_in_set_parameters(
  params: ReplaceStickerInSetParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("name", json.string(params.name)),
    #("old_sticker", json.string(params.old_sticker)),
    #("sticker", encode_input_sticker(params.sticker)),
  ])
}

// SetStickerEmojiListParameters ------------------------------------------------------------

pub fn encode_set_sticker_emoji_list_parameters(
  params: SetStickerEmojiListParameters,
) -> Json {
  json_object_filter_nulls([
    #("sticker", json.string(params.sticker)),
    #("emoji_list", json.array(params.emoji_list, json.string)),
  ])
}

// SetStickerKeywordsParameters ------------------------------------------------------------

pub fn encode_set_sticker_keywords_parameters(
  params: SetStickerKeywordsParameters,
) -> Json {
  json_object_filter_nulls([
    #("sticker", json.string(params.sticker)),
    #(
      "keywords",
      json.nullable(params.keywords, fn(keywords) {
        json.array(keywords, json.string)
      }),
    ),
  ])
}

// SetStickerMaskPositionParameters ------------------------------------------------------------

pub fn encode_set_sticker_mask_position_parameters(
  params: SetStickerMaskPositionParameters,
) -> Json {
  json_object_filter_nulls([
    #("sticker", json.string(params.sticker)),
    #(
      "mask_position",
      json.nullable(params.mask_position, encode_mask_position),
    ),
  ])
}

// SetStickerSetTitleParameters ------------------------------------------------------------

pub fn encode_set_sticker_set_title_parameters(
  params: SetStickerSetTitleParameters,
) -> Json {
  json_object_filter_nulls([
    #("name", json.string(params.name)),
    #("title", json.string(params.title)),
  ])
}

// SetStickerSetThumbnailParameters ------------------------------------------------------------

pub fn encode_set_sticker_set_thumbnail_parameters(
  params: SetStickerSetThumbnailParameters,
) -> Json {
  json_object_filter_nulls([
    #("name", json.string(params.name)),
    #("user_id", json.int(params.user_id)),
    #("thumbnail", json.nullable(params.thumbnail, encode_file_or_string)),
    #("format", json.string(params.format)),
  ])
}

// SetCustomEmojiStickerSetThumbnailParameters ------------------------------------------------------------

pub fn encode_set_custom_emoji_sticker_set_thumbnail_parameters(
  params: SetCustomEmojiStickerSetThumbnailParameters,
) -> Json {
  json_object_filter_nulls([
    #("name", json.string(params.name)),
    #("custom_emoji_id", json.nullable(params.custom_emoji_id, json.string)),
  ])
}

// DeleteStickerSetParameters ------------------------------------------------------------

pub fn encode_delete_sticker_set_parameters(
  params: DeleteStickerSetParameters,
) -> Json {
  json_object_filter_nulls([#("name", json.string(params.name))])
}

// AnswerInlineQueryParameters ------------------------------------------------------------

pub fn encode_answer_inline_query_parameters(
  params: AnswerInlineQueryParameters,
) -> Json {
  json_object_filter_nulls([
    #("inline_query_id", json.string(params.inline_query_id)),
    #("results", json.array(params.results, encode_inline_query_result)),
    #("cache_time", json.nullable(params.cache_time, json.int)),
    #("is_personal", json.nullable(params.is_personal, json.bool)),
    #("next_offset", json.nullable(params.next_offset, json.string)),
    #(
      "button",
      json.nullable(params.button, encode_inline_query_results_button),
    ),
  ])
}

// AnswerShippingQueryParameters ------------------------------------------------------------

pub fn encode_answer_shipping_query_parameters(
  params: AnswerShippingQueryParameters,
) -> Json {
  json_object_filter_nulls([
    #("shipping_query_id", json.string(params.shipping_query_id)),
    #("ok", json.bool(params.ok)),
    #(
      "shipping_options",
      json.nullable(params.shipping_options, fn(options) {
        json.array(options, encode_shipping_option)
      }),
    ),
    #("error_message", json.nullable(params.error_message, json.string)),
  ])
}

// AnswerPreCheckoutQueryParameters ------------------------------------------------------------

pub fn encode_answer_pre_checkout_query_parameters(
  params: AnswerPreCheckoutQueryParameters,
) -> Json {
  json_object_filter_nulls([
    #("pre_checkout_query_id", json.string(params.pre_checkout_query_id)),
    #("ok", json.bool(params.ok)),
    #("error_message", json.nullable(params.error_message, json.string)),
  ])
}

// GetStarTransactionsParameters ------------------------------------------------------------

pub fn encode_get_star_transactions_parameters(
  params: GetStarTransactionsParameters,
) -> Json {
  json_object_filter_nulls([
    #("offset", json.nullable(params.offset, json.int)),
    #("limit", json.nullable(params.limit, json.int)),
  ])
}

// RefundStarPaymentParameters ------------------------------------------------------------

pub fn encode_refund_star_payment_parameters(
  params: RefundStarPaymentParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #(
      "telegram_payment_charge_id",
      json.string(params.telegram_payment_charge_id),
    ),
  ])
}

// EditUserStarSubscriptionParameters ------------------------------------------------------------

pub fn encode_edit_user_star_subscription_parameters(
  params: EditUserStarSubscriptionParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #(
      "telegram_payment_charge_id",
      json.string(params.telegram_payment_charge_id),
    ),
    #("is_canceled", json.bool(params.is_canceled)),
  ])
}

// SendGameParameters ------------------------------------------------------------

pub fn encode_send_game_parameters(params: SendGameParameters) -> Json {
  json_object_filter_nulls([
    #(
      "business_connection_id",
      json.nullable(params.business_connection_id, json.string),
    ),
    #("chat_id", json.int(params.chat_id)),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("game_short_name", json.string(params.game_short_name)),
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

// SetGameScoreParameters ------------------------------------------------------------

pub fn encode_set_game_score_parameters(params: SetGameScoreParameters) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("score", json.int(params.score)),
    #("force", json.nullable(params.force, json.bool)),
    #(
      "disable_edit_message",
      json.nullable(params.disable_edit_message, json.bool),
    ),
    #("chat_id", json.nullable(params.chat_id, json.int)),
    #("message_id", json.nullable(params.message_id, json.int)),
    #("inline_message_id", json.nullable(params.inline_message_id, json.string)),
  ])
}

// GetGameHighScoresParameters ------------------------------------------------------------

pub fn encode_get_game_high_scores_parameters(
  params: GetGameHighScoresParameters,
) -> Json {
  json_object_filter_nulls([
    #("user_id", json.int(params.user_id)),
    #("chat_id", json.nullable(params.chat_id, json.int)),
    #("message_id", json.nullable(params.message_id, json.int)),
    #("inline_message_id", json.nullable(params.inline_message_id, json.string)),
  ])
}

// ReadBusinessMessageParameters ------------------------------------------------------------

pub fn encode_read_business_message_parameters(
  params: ReadBusinessMessageParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("chat_id", json.int(params.chat_id)),
    #("message_id", json.int(params.message_id)),
  ])
}

// DeleteBusinessMessagesParameters ------------------------------------------------------------

pub fn encode_delete_business_messages_parameters(
  params: DeleteBusinessMessagesParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("message_ids", json.array(params.message_ids, json.int)),
  ])
}

// SetBusinessAccountNameParameters ------------------------------------------------------------

pub fn encode_set_business_account_name_parameters(
  params: SetBusinessAccountNameParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("first_name", json.string(params.first_name)),
    #("last_name", json.nullable(params.last_name, json.string)),
  ])
}

// SetBusinessAccountUsernameParameters ------------------------------------------------------------

pub fn encode_set_business_account_username_parameters(
  params: SetBusinessAccountUsernameParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("username", json.nullable(params.username, json.string)),
  ])
}

// SetBusinessAccountBioParameters ------------------------------------------------------------

pub fn encode_set_business_account_bio_parameters(
  params: SetBusinessAccountBioParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("bio", json.nullable(params.bio, json.string)),
  ])
}

// SetBusinessAccountProfilePhotoParameters ------------------------------------------------------------

pub fn encode_set_business_account_profile_photo_parameters(
  params: SetBusinessAccountProfilePhotoParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("photo", encode_input_profile_photo(params.photo)),
    #("is_public", json.nullable(params.is_public, json.bool)),
  ])
}

// RemoveBusinessAccountProfilePhotoParameters ------------------------------------------------------------

pub fn encode_remove_business_account_profile_photo_parameters(
  params: RemoveBusinessAccountProfilePhotoParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("is_public", json.nullable(params.is_public, json.bool)),
  ])
}

// SetBusinessAccountGiftSettingsParameters ------------------------------------------------------------

pub fn encode_set_business_account_gift_settings_parameters(
  params: SetBusinessAccountGiftSettingsParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("show_gift_button", json.bool(params.show_gift_button)),
    #(
      "accepted_gift_types",
      encode_accepted_gift_types(params.accepted_gift_types),
    ),
  ])
}

// GetBusinessAccountStarBalanceParameters ------------------------------------------------------------

pub fn encode_get_business_account_star_balance_parameters(
  params: GetBusinessAccountStarBalanceParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
  ])
}

// TransferBusinessAccountStarsParameters ------------------------------------------------------------

pub fn encode_transfer_business_account_stars_parameters(
  params: TransferBusinessAccountStarsParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("star_count", json.int(params.star_count)),
  ])
}

// GetBusinessAccountGiftsParameters ------------------------------------------------------------

pub fn encode_get_business_account_gifts_parameters(
  params: GetBusinessAccountGiftsParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("exclude_unsaved", json.nullable(params.exclude_unsaved, json.bool)),
    #("exclude_saved", json.nullable(params.exclude_saved, json.bool)),
    #("exclude_unlimited", json.nullable(params.exclude_unlimited, json.bool)),
    #("exclude_limited", json.nullable(params.exclude_limited, json.bool)),
    #("exclude_unique", json.nullable(params.exclude_unique, json.bool)),
    #("sort_by_price", json.nullable(params.sort_by_price, json.bool)),
    #("offset", json.nullable(params.offset, json.string)),
    #("limit", json.nullable(params.limit, json.int)),
  ])
}

// ConvertGiftToStarsParameters ------------------------------------------------------------

pub fn encode_convert_gift_to_stars_parameters(
  params: ConvertGiftToStarsParameters,
) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("owned_gift_id", json.string(params.owned_gift_id)),
  ])
}

// UpgradeGiftParameters ------------------------------------------------------------

pub fn encode_upgrade_gift_parameters(params: UpgradeGiftParameters) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("owned_gift_id", json.string(params.owned_gift_id)),
    #(
      "keep_original_details",
      json.nullable(params.keep_original_details, json.bool),
    ),
    #("star_count", json.nullable(params.star_count, json.int)),
  ])
}

// TransferGiftParameters ------------------------------------------------------------

pub fn encode_transfer_gift_parameters(params: TransferGiftParameters) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("owned_gift_id", json.string(params.owned_gift_id)),
    #("new_owner_chat_id", json.int(params.new_owner_chat_id)),
    #("star_count", json.nullable(params.star_count, json.int)),
  ])
}

// PostStoryParameters ------------------------------------------------------------

pub fn encode_post_story_parameters(params: PostStoryParameters) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("content", encode_input_story_content(params.content)),
    #("active_period", json.int(params.active_period)),
    #("caption", json.nullable(params.caption, json.string)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(params.caption_entities, fn(entities) {
        json.array(entities, encode_message_entity)
      }),
    ),
    #(
      "areas",
      json.nullable(params.areas, fn(areas) {
        json.array(areas, encode_story_area)
      }),
    ),
    #("post_to_chat_page", json.nullable(params.post_to_chat_page, json.bool)),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
  ])
}

// EditStoryParameters ------------------------------------------------------------

pub fn encode_edit_story_parameters(params: EditStoryParameters) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("story_id", json.int(params.story_id)),
    #("content", encode_input_story_content(params.content)),
    #("caption", json.nullable(params.caption, json.string)),
    #("parse_mode", json.nullable(params.parse_mode, json.string)),
    #(
      "caption_entities",
      json.nullable(params.caption_entities, json.array(
        _,
        encode_message_entity,
      )),
    ),
    #("areas", json.nullable(params.areas, json.array(_, encode_story_area))),
  ])
}

// DeleteStoryParameters ------------------------------------------------------------

pub fn encode_delete_story_parameters(params: DeleteStoryParameters) -> Json {
  json_object_filter_nulls([
    #("business_connection_id", json.string(params.business_connection_id)),
    #("story_id", json.int(params.story_id)),
  ])
}

// Common ------------------------------------------------------------------------------------------------------------

pub fn encode_int_or_string(value: IntOrString) -> Json {
  case value {
    Int(value:) -> json.int(value)
    Str(value:) -> json.string(value)
  }
}
