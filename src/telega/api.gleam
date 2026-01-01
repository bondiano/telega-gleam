//// This module provides an interface for interacting with the Telegram Bot API.
//// It will be useful if you want to interact with the Telegram Bot API directly, without running a bot.
//// But it will be more convenient to use the `reply` module in bot handlers.

import gleam/dynamic/decode
import gleam/http/response.{type Response}
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result

import telega/client.{fetch, new_get_request, new_post_request}
import telega/error
import telega/model/decoder
import telega/model/encoder
import telega/model/types.{
  type AddStickerToSetParameters, type AnswerCallbackQueryParameters,
  type AnswerInlineQueryParameters, type AnswerPreCheckoutQueryParameters,
  type AnswerShippingQueryParameters, type ApproveChatJoinRequestParameters,
  type BanChatMemberParameters, type BanChatSenderChatParameters,
  type BotCommand, type BotCommandParameters, type BotDescription, type BotName,
  type BotShortDescription, type BusinessConnection,
  type ChatAdministratorRights, type ChatFullInfo, type ChatInviteLink,
  type ChatMember, type CloseForumTopicParameters,
  type CloseGeneralForumTopicParameters, type ConvertGiftToStarsParameters,
  type CopyMessageParameters, type CopyMessagesParameters,
  type CreateChatInviteLinkParameters,
  type CreateChatSubscriptionInviteLinkParameters,
  type CreateForumTopicParameters, type CreateInvoiceLinkParameters,
  type CreateNewStickerSetParameters, type DeclineChatJoinRequestParameters,
  type DeleteBusinessMessagesParameters, type DeleteChatPhotoParameters,
  type DeleteChatStickerSetParameters, type DeleteForumTopicParameters,
  type DeleteMessageParameters, type DeleteMessagesParameters,
  type DeleteStickerFromSetParameters, type DeleteStickerSetParameters,
  type DeleteStoryParameters, type EditChatInviteLinkParameters,
  type EditChatSubscriptionInviteLinkParameters, type EditForumTopicParameters,
  type EditGeneralForumTopicParameters, type EditMessageCaptionParameters,
  type EditMessageLiveLocationParameters, type EditMessageMediaParameters,
  type EditMessageReplyMarkupParameters, type EditMessageTextParameters,
  type EditStoryParameters, type EditUserStarSubscriptionParameters,
  type ExportChatInviteLinkParameters, type File, type ForumTopic,
  type ForwardMessageParameters, type ForwardMessagesParameters,
  type GameHighScore, type GetBusinessAccountGiftsParameters,
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
  type GetUserProfilePhotosParameters, type GiftPremiumSubscriptionParameters,
  type Gifts, type HideGeneralForumTopicParameters, type LeaveChatParameters,
  type MenuButton, type Message, type OwnedGifts, type PinChatMessageParameters,
  type Poll, type PostStoryParameters, type PromoteChatMemberParameters,
  type ReadBusinessMessageParameters, type RefundStarPaymentParameters,
  type RemoveBusinessAccountProfilePhotoParameters,
  type RemoveChatVerificationParameters, type RemoveUserVerificationParameters,
  type ReopenForumTopicParameters, type ReopenGeneralForumTopicParameters,
  type ReplaceStickerInSetParameters, type RepostStoryParameters,
  type RestrictChatMemberParameters, type RevokeChatInviteLinkParameters,
  type SendAnimationParameters, type SendAudioParameters,
  type SendChatActionParameters, type SendContactParameters,
  type SendDiceParameters, type SendDocumentParameters, type SendGameParameters,
  type SendGiftParameters, type SendInvoiceParameters,
  type SendLocationParameters, type SendMediaGroupParameters,
  type SendMessageDraftParameters, type SendMessageParameters,
  type SendPhotoParameters, type SendPollParameters, type SendStickerParameters,
  type SendVenueParameters, type SendVideoNoteParameters,
  type SendVideoParameters, type SendVoiceParameters,
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
  type SetMyShortDescriptionParameters, type SetStickerEmojiListParameters,
  type SetStickerKeywordsParameters, type SetStickerMaskPositionParameters,
  type SetStickerPositionInSetParameters, type SetStickerSetThumbnailParameters,
  type SetStickerSetTitleParameters, type SetWebhookParameters, type StarAmount,
  type StarTransactions, type Sticker, type StickerSet,
  type StopMessageLiveLocationParameters, type StopPollParameters, type Story,
  type TransferBusinessAccountStarsParameters, type TransferGiftParameters,
  type UnbanChatMemberParameters, type UnbanChatSenderChatParameters,
  type UnhideGeneralForumTopicParameters, type UnpinAllChatMessagesParameters,
  type UnpinAllForumTopicMessagesParameters,
  type UnpinAllGeneralForumTopicPinnedMessagesParameters,
  type UnpinChatMessageParameters, type Update, type UpgradeGiftParameters,
  type UploadStickerFileParameters, type User, type UserChatBoosts,
  type UserProfilePhotos, type VerifyChatParameters, type VerifyUserParameters,
  type WebhookInfo,
}

type ApiResponse(result) {
  ApiSuccessResponse(ok: Bool, result: result)
  ApiErrorResponse(ok: Bool, error_code: Int, description: String)
}

/// Set the webhook URL using [setWebhook](https://core.telegram.org/bots/api#setwebhook) API.
///
/// **Official reference:** https://core.telegram.org/bots/api#setwebhook
pub fn set_webhook(
  client client: client.TelegramClient,
  parameters parameters: SetWebhookParameters,
) -> Result(Bool, error.TelegaError) {
  let body = encoder.encode_set_webhook_parameters(parameters)

  new_post_request(client:, path: "setWebhook", body: json.to_string(body))
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get current webhook status.
///
/// **Official reference:** https://core.telegram.org/bots/api#getwebhookinfo
pub fn get_webhook_info(
  client client: client.TelegramClient,
) -> Result(WebhookInfo, error.TelegaError) {
  new_get_request(client:, path: "getWebhookInfo", query: None)
  |> fetch(client)
  |> map_response(decoder.webhook_info_decoder())
}

/// Use this method to remove webhook integration if you decide to switch back to [getUpdates](https://core.telegram.org/bots/api#getupdates).
///
/// **Official reference:** https://core.telegram.org/bots/api#deletewebhook
pub fn delete_webhook(
  client client: client.TelegramClient,
) -> Result(Bool, error.TelegaError) {
  new_get_request(client:, path: "deleteWebhook", query: None)
  |> fetch(client)
  |> map_response(decode.bool)
}

/// The same as [delete_webhook](#delete_webhook) but also drops all pending updates.
pub fn delete_webhook_and_drop_updates(
  client client: client.TelegramClient,
) -> Result(Bool, error.TelegaError) {
  new_get_request(
    client:,
    path: "deleteWebhook",
    query: Some([#("drop_pending_updates", "true")]),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to log out from the cloud Bot API server before launching the bot locally.
/// You **must** log out the bot before running it locally, otherwise there is no guarantee that the bot will receive updates.
/// After a successful call, you can immediately log in on a local server, but will not be able to log in back to the cloud Bot API server for 10 minutes.
///
/// **Official reference:** https://core.telegram.org/bots/api#logout
pub fn log_out(
  client client: client.TelegramClient,
) -> Result(Bool, error.TelegaError) {
  new_get_request(client:, path: "logOut", query: None)
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to close the bot instance before moving it from one local server to another.
/// You need to delete the webhook before calling this method to ensure that the bot isn't launched again after server restart.
/// The method will return error 429 in the first 10 minutes after the bot is launched.
///
/// **Official reference:** https://core.telegram.org/bots/api#close
pub fn close(
  client client: client.TelegramClient,
) -> Result(Bool, error.TelegaError) {
  new_get_request(client:, path: "close", query: None)
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to send text messages with additional parameters.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn send_message(
  client client: client.TelegramClient,
  parameters parameters: SendMessageParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_message_parameters(parameters)

  new_post_request(
    client:,
    path: "sendMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send an animated emoji that will display a random value.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddice
pub fn send_dice(
  client client: client.TelegramClient,
  parameters parameters: SendDiceParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_dice_parameters(parameters)

  new_post_request(client:, path: "sendDice", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// A simple method for testing your bot's authentication token.
///
/// **Official reference:** https://core.telegram.org/bots/api#getme
pub fn get_me(
  client client: client.TelegramClient,
) -> Result(User, error.TelegaError) {
  new_get_request(client:, path: "getMe", query: None)
  |> fetch(client)
  |> map_response(decoder.user_decoder())
}

/// Use this method to send answers to callback queries sent from [inline keyboards](https://core.telegram.org/bots/features#inline-keyboards).
/// The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
/// On success, _True_ is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#answercallbackquery
pub fn answer_callback_query(
  client client: client.TelegramClient,
  parameters parameters: AnswerCallbackQueryParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_answer_callback_query_parameters(parameters)

  new_post_request(
    client:,
    path: "answerCallbackQuery",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to forward messages of any kind. Service messages and messages with protected content can't be forwarded.
/// On success, the sent Message is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessage
pub fn forward_message(
  client client: client.TelegramClient,
  parameters parameters: ForwardMessageParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_forward_message_parameters(parameters)

  new_post_request(
    client:,
    path: "forwardMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to receive incoming updates using long polling ([wiki](https://en.wikipedia.org/wiki/Push_technology#Long_polling)).
///
/// > Notes
/// > 1. This method will not work if an outgoing webhook is set up.
/// > 2. In order to avoid getting duplicate updates, recalculate offset after each server response.
///
/// **Official reference:** https://core.telegram.org/bots/api#getupdates
pub fn get_updates(
  client client: client.TelegramClient,
  parameters parameters: Option(GetUpdatesParameters),
) -> Result(List(Update), error.TelegaError) {
  let query = case parameters {
    Some(params) -> Some(encoder.encode_get_updates_parameters_as_query(params))
    None -> None
  }
  new_get_request(client:, path: "getUpdates", query:)
  |> fetch(client)
  |> map_response(decode.list(decoder.update_decoder()))
}

/// Use this method to forward multiple messages of any kind. If some of the specified messages can't be found or forwarded, they are skipped. Service messages and messages with protected content can't be forwarded. Album grouping is kept for forwarded messages. On success, an array of [MessageId](https://core.telegram.org/bots/api#messageid) of the sent messages is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessages
pub fn forward_messages(
  client client: client.TelegramClient,
  parameters parameters: ForwardMessagesParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_forward_messages_parameters(parameters)

  new_post_request(
    client:,
    path: "forwardMessages",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to copy messages of any kind. Service messages, paid media messages, giveaway messages, giveaway winners messages, and invoice messages can't be copied. A quiz [poll](https://core.telegram.org/bots/api#poll) can be copied only if the value of the field correct_option_id is known to the bot. The method is analogous to the method [forwardMessage](https://core.telegram.org/bots/api#forwardmessage), but the copied message doesn't have a link to the original message. Returns the [MessageId](https://core.telegram.org/bots/api#messageid) of the sent message on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#copymessage
pub fn copy_message(
  client client: client.TelegramClient,
  parameters parameters: CopyMessageParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_copy_message_parameters(parameters)

  new_post_request(
    client:,
    path: "copyMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to copy messages of any kind. If some of the specified messages can't be found or copied, they are skipped. Service messages, paid media messages, giveaway messages, giveaway winners messages, and invoice messages can't be copied. A quiz [poll](https://core.telegram.org/bots/api#poll) can be copied only if the value of the field correct_option_id is known to the bot. The method is analogous to the method [forwardMessage](https://core.telegram.org/bots/api#forwardmessage), but the copied message doesn't have a link to the original message. Returns the [MessageId](https://core.telegram.org/bots/api#messageid) of the sent message on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#copymessages
pub fn copy_messages(
  client client: client.TelegramClient,
  parameters parameters: CopyMessagesParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_copy_messages_parameters(parameters)

  new_post_request(
    client:,
    path: "copyMessages",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send photos. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendphoto
pub fn send_photo(
  client client: client.TelegramClient,
  parameters parameters: SendPhotoParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_photo_parameters(parameters)

  new_post_request(client:, path: "sendPhoto", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send audio files, if you want Telegram clients to display them in the music player. Your audio must be in the .MP3 or .M4A format. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future.
///
/// For sending voice messages, use the [sendVoice](https://core.telegram.org/bots/api#sendvoice) method instead.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendaudio
pub fn send_audio(
  client client: client.TelegramClient,
  parameters parameters: SendAudioParameters,
) -> Result(Response(String), error.TelegaError) {
  let body_json = encoder.encode_send_audio_parameters(parameters)

  new_post_request(client:, path: "sendAudio", body: json.to_string(body_json))
  |> fetch(client)
}

/// Use this method to send general files. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send files of any type of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddocument
pub fn send_document(
  client client: client.TelegramClient,
  parameters parameters: SendDocumentParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_document_parameters(parameters)

  new_post_request(
    client:,
    path: "sendDocument",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send video files, Telegram clients support MPEG4 videos (other formats may be sent as Document). On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send video files of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvideo
pub fn send_video(
  client client: client.TelegramClient,
  parameters parameters: SendVideoParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_video_parameters(parameters)

  new_post_request(client:, path: "sendVideo", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send animation files (GIF or H.264/MPEG-4 AVC video without sound). On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send animation files of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendanimation
pub fn send_animation(
  client client: client.TelegramClient,
  parameters parameters: SendAnimationParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_animation_parameters(parameters)

  new_post_request(
    client:,
    path: "sendAnimation",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send audio files, if you want Telegram clients to display the file as a playable voice message. For this to work, your audio must be in an .ogg file encoded with OPUS (other formats may be sent as Audio or Document). On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send voice messages of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvoice
pub fn send_voice(
  client client: client.TelegramClient,
  parameters parameters: SendVoiceParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_voice_parameters(parameters)

  new_post_request(client:, path: "sendVoice", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send video messages. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvideonote
pub fn send_video_note(
  client client: client.TelegramClient,
  parameters parameters: SendVideoNoteParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_video_note_parameters(parameters)

  new_post_request(
    client:,
    path: "sendVideoNote",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send a group of photos, videos, documents or audio files as an album. Documents and audio files can be only grouped in an album with the first item having a filename. On success, an array of the sent Messages is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmediagroup
pub fn send_media_group(
  client client: client.TelegramClient,
  parameters parameters: SendMediaGroupParameters,
) -> Result(List(Message), error.TelegaError) {
  let body_json = encoder.encode_send_media_group_parameters(parameters)

  new_post_request(
    client:,
    path: "sendMediaGroup",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.messages_array_decoder())
}

/// Use this method to send point on the map. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendlocation
pub fn send_location(
  client client: client.TelegramClient,
  parameters parameters: SendLocationParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_location_parameters(parameters)

  new_post_request(
    client:,
    path: "sendLocation",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send information about a venue. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvenue
pub fn send_venue(
  client client: client.TelegramClient,
  parameters parameters: SendVenueParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_venue_parameters(parameters)

  new_post_request(client:, path: "sendVenue", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send phone contacts. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendcontact
pub fn send_contact(
  client client: client.TelegramClient,
  parameters parameters: SendContactParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_contact_parameters(parameters)

  new_post_request(
    client:,
    path: "sendContact",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to send a native poll. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendpoll
pub fn send_poll(
  client client: client.TelegramClient,
  parameters parameters: SendPollParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_poll_parameters(parameters)

  new_post_request(client:, path: "sendPoll", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status). Returns True on success.
///
/// > Example: The [ImageBot](https://t.me/imagebot) needs some time to process a request and upload the image. Instead of sending a text message along the lines of “Retrieving image, please wait…”, the bot may use [sendChatAction](https://core.telegram.org/bots/api#sendchataction) with action = upload_photo. The user will see a “sending photo” status for the bot.
///
/// We only recommend using this method when a response from the bot will take a noticeable amount of time to arrive.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendchataction
pub fn send_chat_action(
  client client: client.TelegramClient,
  parameters parameters: SendChatActionParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_chat_action_parameters(parameters)

  new_post_request(
    client:,
    path: "sendChatAction",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to change the chosen reactions on a message. Service messages of some types can't be reacted to. Automatically forwarded messages from a channel to its discussion group have the same available reactions as messages in the channel. Bots can't use paid reactions. Returns _True_ on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmessagereaction
pub fn set_message_reaction(
  client client: client.TelegramClient,
  parameters parameters: SetMessageReactionParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_message_reaction_parameters(parameters)

  new_post_request(
    client:,
    path: "setMessageReaction",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get a list of profile pictures for a user. Returns a [UserProfilePhotos](https://core.telegram.org/bots/api#userprofilephotos) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#getuserprofilephotos
pub fn get_user_profile_photos(
  client client: client.TelegramClient,
  parameters parameters: GetUserProfilePhotosParameters,
) -> Result(UserProfilePhotos, error.TelegaError) {
  let body_json = encoder.encode_get_user_profile_photos_parameters(parameters)

  new_post_request(
    client:,
    path: "getUserProfilePhotos",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.user_profile_photos_decoder())
}

/// Use this method to edit text and game messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api#message) is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagetext
pub fn edit_message_text(
  client client: client.TelegramClient,
  parameters parameters: EditMessageTextParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_edit_message_text_parameters(parameters)

  new_post_request(
    client:,
    path: "editMessageText",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to edit captions of messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api#message) is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagecaption
pub fn edit_message_caption(
  client client: client.TelegramClient,
  parameters parameters: EditMessageCaptionParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_edit_message_caption_parameters(parameters)

  new_post_request(
    client:,
    path: "editMessageCaption",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to edit animation, audio, document, photo, or video messages, or to add media to text messages. If a message is part of a message album, then it can be edited only to an audio for audio albums, only to a document for document albums and to a photo or a video otherwise. When an inline message is edited, a new file can't be uploaded; use a previously uploaded file via its file_id or specify a URL. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagemedia
pub fn edit_message_media(
  client client: client.TelegramClient,
  parameters parameters: EditMessageMediaParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_edit_message_media_parameters(parameters)

  new_post_request(
    client:,
    path: "editMessageMedia",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to edit live location messages. A location can be edited until its live_period expires or editing is explicitly disabled by a call to stopMessageLiveLocation. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagelivelocation
pub fn edit_message_live_location(
  client client: client.TelegramClient,
  parameters parameters: EditMessageLiveLocationParameters,
) -> Result(Message, error.TelegaError) {
  let body_json =
    encoder.encode_edit_message_live_location_parameters(parameters)

  new_post_request(
    client:,
    path: "editMessageLiveLocation",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to stop updating a live location message before live_period expires. On success, if the message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#stopmessagelivelocation
pub fn stop_message_live_location(
  client client: client.TelegramClient,
  parameters parameters: StopMessageLiveLocationParameters,
) -> Result(Message, error.TelegaError) {
  let body_json =
    encoder.encode_stop_message_live_location_parameters(parameters)

  new_post_request(
    client:,
    path: "stopMessageLiveLocation",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to edit only the reply markup of messages. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagereplymarkup
pub fn edit_message_reply_markup(
  client client: client.TelegramClient,
  parameters parameters: EditMessageReplyMarkupParameters,
) -> Result(Message, error.TelegaError) {
  let body_json =
    encoder.encode_edit_message_reply_markup_parameters(parameters)

  new_post_request(
    client:,
    path: "editMessageReplyMarkup",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to stop a poll which was sent by the bot. On success, the stopped Poll is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#stoppoll
pub fn stop_poll(
  client client: client.TelegramClient,
  parameters parameters: StopPollParameters,
) -> Result(Poll, error.TelegaError) {
  let body_json = encoder.encode_stop_poll_parameters(parameters)

  new_post_request(client:, path: "stopPoll", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.poll_decoder())
}

/// Use this method to delete a message, including service messages, with the following limitations:
/// - A message can only be deleted if it was sent less than 48 hours ago.
/// - Service messages about a supergroup, channel, or forum topic creation can't be deleted.
/// - A dice message in a private chat can only be deleted if it was sent more than 24 hours ago.
/// - Bots can delete outgoing messages in private chats, groups, and supergroups.
/// - Bots can delete incoming messages in private chats.
/// - Bots granted can_post_messages permissions can delete outgoing messages in channels.
/// - If the bot is an administrator of a group, it can delete any message there.
/// - If the bot has can_delete_messages permission in a supergroup or a channel, it can delete any message there.
/// Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletemessage
pub fn delete_message(
  client client: client.TelegramClient,
  parameters parameters: DeleteMessageParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_delete_message_parameters(parameters)

  new_post_request(
    client:,
    path: "deleteMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to delete multiple messages simultaneously. If some of the specified messages can't be found, they are skipped. Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletemessagessimultaneously
pub fn delete_messages(
  client client: client.TelegramClient,
  parameters parameters: DeleteMessagesParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_delete_messages_parameters(parameters)

  new_post_request(
    client:,
    path: "deleteMessages",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Returns the list of gifts that can be sent by the bot to users and channel chats. Requires no parameters. Returns a Gifts object.
///
/// **Official reference:** https://core.telegram.org/bots/api#getavailablegifts
pub fn get_available_gifts(
  client client: client.TelegramClient,
) -> Result(Gifts, error.TelegaError) {
  new_get_request(client, path: "getAvailableGifts", query: None)
  |> fetch(client)
  |> map_response(decoder.gifts_decoder())
}

/// Sends a gift to the given user or channel chat. The gift can't be converted to Telegram Stars by the receiver. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendgift
pub fn send_gift(
  client client: client.TelegramClient,
  parameters parameters: SendGiftParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_send_gift_parameters(parameters)

  new_post_request(client:, path: "sendGift", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Gifts a Telegram Premium subscription to the given user. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#giftpremium
pub fn gift_premium(
  client client: client.TelegramClient,
  parameters parameters: GiftPremiumSubscriptionParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_gift_premium_subscription_parameters(parameters)

  new_post_request(
    client:,
    path: "giftPremium",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Verifies a user [on behalf of the organization](https://core.telegram.org/bots/api#verifyuser) which is represented by the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#verifyuser
pub fn verify_user(
  client client: client.TelegramClient,
  parameters parameters: VerifyUserParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_verify_user_parameters(parameters)

  new_post_request(client:, path: "verifyUser", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Verifies a chat [on behalf of the organization](https://core.telegram.org/bots/api#verifychat) which is represented by the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#verifychat
pub fn verify_chat(
  client client: client.TelegramClient,
  parameters parameters: VerifyChatParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_verify_chat_parameters(parameters)

  new_post_request(client:, path: "verifyChat", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Removes verification from a user who is currently verified [on behalf of the organization](https://core.telegram.org/bots/api#removeuserverification) represented by the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#removeuserverification
pub fn remove_user_verification(
  client client: client.TelegramClient,
  parameters parameters: RemoveUserVerificationParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_remove_user_verification_parameters(parameters)

  new_post_request(
    client:,
    path: "removeUserVerification",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Removes verification from a chat that is currently verified [on behalf of the organization](https://core.telegram.org/bots/api#removechatverification) represented by the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#removechatverification
pub fn remove_chat_verification(
  client client: client.TelegramClient,
  parameters parameters: RemoveChatVerificationParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_remove_chat_verification_parameters(parameters)

  new_post_request(
    client:,
    path: "removeChatVerification",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Marks incoming message as read on behalf of a business account. Requires the *can_read_messages* business bot right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#readbusinessmessage
pub fn read_business_message(
  client client: client.TelegramClient,
  parameters parameters: ReadBusinessMessageParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_read_business_message_parameters(parameters)

  new_post_request(
    client:,
    path: "readBusinessMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Delete messages on behalf of a business account. Requires the can_delete_sent_messages business bot right to delete messages sent by the bot itself, or the can_delete_all_messages business bot right to delete any message. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletebusinessmessages
pub fn delete_business_messages(
  client client: client.TelegramClient,
  parameters parameters: DeleteBusinessMessagesParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_delete_business_messages_parameters(parameters)

  new_post_request(
    client:,
    path: "deleteBusinessMessages",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Changes the username of a managed business account. Requires the can_change_username business bot right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setbusinessaccountusername
pub fn set_business_account_username(
  client client: client.TelegramClient,
  parameters parameters: SetBusinessAccountUsernameParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_set_business_account_username_parameters(parameters)

  new_post_request(
    client:,
    path: "setBusinessAccountUsername",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Changes the bio of a managed business account. Requires the can_change_bio business bot right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setbusinessaccountbio
pub fn set_business_account_bio(
  client client: client.TelegramClient,
  parameters parameters: SetBusinessAccountBioParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_business_account_bio_parameters(parameters)

  new_post_request(
    client:,
    path: "setBusinessAccountBio",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Changes the first and last name of a managed business account. Requires the can_change_name business bot right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setbusinessaccountname
pub fn set_business_account_name(
  client client: client.TelegramClient,
  parameters parameters: SetBusinessAccountNameParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_set_business_account_name_parameters(parameters)

  new_post_request(
    client:,
    path: "setBusinessAccountName",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Changes the profile photo of a managed business account. Requires the *can_edit_profile_photo* business bot right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setbusinessaccountprofilephoto
pub fn set_business_account_profile_photo(
  client client: client.TelegramClient,
  parameters parameters: SetBusinessAccountProfilePhotoParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_set_business_account_profile_photo_parameters(parameters)

  new_post_request(
    client:,
    path: "setBusinessAccountProfilePhoto",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Removes the current profile photo of a managed business account. Requires the *can_edit_profile_photo* business bot right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#removebusinessaccountprofilephoto
pub fn remove_business_account_profile_photo(
  client client: client.TelegramClient,
  parameters parameters: RemoveBusinessAccountProfilePhotoParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_remove_business_account_profile_photo_parameters(parameters)

  new_post_request(
    client:,
    path: "removeBusinessAccountProfilePhoto",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Changes the privacy settings pertaining to incoming gifts in a managed business account. Requires the *can_change_gift_settings* business bot right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setbusinessaccountgiftsettings
pub fn set_business_account_gift_settings(
  client client: client.TelegramClient,
  parameters parameters: SetBusinessAccountGiftSettingsParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_set_business_account_gift_settings_parameters(parameters)

  new_post_request(
    client:,
    path: "setBusinessAccountGiftSettings",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Returns the amount of Telegram Stars owned by a managed business account. Requires the can_view_gifts_and_stars business bot right. Returns [StarAmount](https://core.telegram.org/bots/api#staramount) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getbusinessaccountstarbalance
pub fn get_business_account_star_balance(
  client client: client.TelegramClient,
  parameters parameters: GetBusinessAccountStarBalanceParameters,
) -> Result(StarAmount, error.TelegaError) {
  let body_json =
    encoder.encode_get_business_account_star_balance_parameters(parameters)

  new_post_request(
    client:,
    path: "getBusinessAccountStarBalance",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.star_amount_decoder())
}

/// Transfers Telegram Stars from the business account balance to the bot's balance. Requires the can_transfer_stars business bot right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#transferbusinessaccountstars
pub fn transfer_business_account_stars(
  client client: client.TelegramClient,
  parameters parameters: TransferBusinessAccountStarsParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_transfer_business_account_stars_parameters(parameters)

  new_post_request(
    client:,
    path: "transferBusinessAccountStars",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Returns the gifts received and owned by a managed business account. Requires the *can_view_gifts_and_stars* business bot right. Returns [OwnedGifts](https://core.telegram.org/bots/api#ownedgifts) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getbusinessaccountgifts
pub fn get_business_account_gifts(
  client client: client.TelegramClient,
  parameters parameters: GetBusinessAccountGiftsParameters,
) -> Result(OwnedGifts, error.TelegaError) {
  let body_json =
    encoder.encode_get_business_account_gifts_parameters(parameters)

  new_post_request(
    client:,
    path: "getBusinessAccountGifts",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.owned_gifts_decoder())
}

/// Converts a given regular gift to Telegram Stars. Requires the *can_convert_gifts_to_stars* business bot right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#convertgifttostars
pub fn convert_gift_to_stars(
  client client: client.TelegramClient,
  parameters parameters: ConvertGiftToStarsParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_convert_gift_to_stars_parameters(parameters)

  new_post_request(
    client:,
    path: "convertGiftToStars",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Upgrades a given regular gift to a unique gift. Requires the *can_transfer_and_upgrade_gifts* business bot right. Additionally requires the *can_transfer_stars* business bot right if the upgrade is paid. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#upgradegift
pub fn upgrade_gift(
  client client: client.TelegramClient,
  parameters parameters: UpgradeGiftParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_upgrade_gift_parameters(parameters)

  new_post_request(
    client:,
    path: "upgradeGift",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Transfers an owned unique gift to another user. Requires the *can_transfer_and_upgrade_gifts* business bot right. Requires *can_transfer_stars* business bot right if the transfer is paid. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#transfergift
pub fn transfer_gift(
  client client: client.TelegramClient,
  parameters parameters: TransferGiftParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_transfer_gift_parameters(parameters)

  new_post_request(
    client:,
    path: "transferGift",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Posts a story on behalf of a managed business account. Requires the *can_manage_stories* business bot right. Returns [Story](https://core.telegram.org/bots/api#story) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#poststory
pub fn post_business_story(
  client client: client.TelegramClient,
  parameters parameters: PostStoryParameters,
) -> Result(Story, error.TelegaError) {
  let body_json = encoder.encode_post_story_parameters(parameters)

  new_post_request(client:, path: "postStory", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.story_decoder())
}

/// Edits a story previously posted by the bot on behalf of a managed business account. Requires the *can_manage_stories* business bot right. Returns [Story](https://core.telegram.org/bots/api#story) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#editstory
pub fn edit_story(
  client client: client.TelegramClient,
  parameters parameters: EditStoryParameters,
) -> Result(Story, error.TelegaError) {
  let body_json = encoder.encode_edit_story_parameters(parameters)

  new_post_request(client:, path: "editStory", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.story_decoder())
}

/// Deletes a story previously posted by the bot on behalf of a managed business account. Requires the can_manage_stories business bot right. Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletestory
pub fn delete_story(
  client client: client.TelegramClient,
  parameters parameters: DeleteStoryParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_delete_story_parameters(parameters)

  new_post_request(
    client:,
    path: "deleteStory",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get up-to-date information about the chat. Returns a [ChatFullInfo](https://core.telegram.org/bots/api#chatfullinfo) object on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getchat
pub fn get_chat(
  client client: client.TelegramClient,
  chat_id chat_id: String,
) -> Result(ChatFullInfo, error.TelegaError) {
  new_get_request(client, path: "getChat", query: Some([#("chat_id", chat_id)]))
  |> fetch(client)
  |> map_response(decoder.chat_full_info_decoder())
}

/// Use this method to get basic information about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link `https://api.telegram.org/file/bot<token>/<file_path>`, where `<file_path>` is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile again.
///
/// **Official reference:** https://core.telegram.org/bots/api#getfile
pub fn get_file(
  client client: client.TelegramClient,
  file_id file_id: String,
) -> Result(File, error.TelegaError) {
  new_get_request(client, path: "getFile", query: Some([#("file_id", file_id)]))
  |> fetch(client)
  |> map_response(decoder.file_decoder())
}

/// Use this method to ban a user in a group, a supergroup or a channel. In the case of supergroups and channels, the user will not be able to return to the chat on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#banchatmember
pub fn ban_chat_member(
  client client: client.TelegramClient,
  parameters parameters: BanChatMemberParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_ban_chat_member_parameters(parameters)

  new_post_request(
    client:,
    path: "banChatMember",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to unban a previously banned user in a supergroup or channel. The user will not return to the group or channel automatically, but will be able to join via link, etc. The bot must be an administrator for this to work. By default, this method guarantees that after the call the user is not a member of the chat, but will be able to join it. So if the user is a member of the chat they will also be removed from the chat. If you don't want this, use the parameter only_if_banned. Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#unbanchatmember
pub fn unban_chat_member(
  client client: client.TelegramClient,
  parameters parameters: UnbanChatMemberParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_unban_chat_member_parameters(parameters)

  new_post_request(
    client:,
    path: "unbanChatMember",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to restrict a user in a supergroup. The bot must be an administrator in the supergroup for this to work and must have the appropriate administrator rights. Pass `True` for all permissions to lift restrictions from a user. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#restrictchatmember
pub fn restrict_chat_member(
  client client: client.TelegramClient,
  parameters parameters: RestrictChatMemberParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_restrict_chat_member_parameters(parameters)

  new_post_request(
    client:,
    path: "restrictChatMember",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to promote or demote a user in a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Pass `False` for all boolean parameters to demote a user. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#promotechatmember
pub fn promote_chat_member(
  client client: client.TelegramClient,
  parameters parameters: PromoteChatMemberParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_promote_chat_member_parameters(parameters)

  new_post_request(
    client:,
    path: "promoteChatMember",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to set a custom title for an administrator in a supergroup promoted by the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchatadministratorcustomtitle
pub fn set_chat_administrator_custom_title(
  client client: client.TelegramClient,
  parameters parameters: SetChatAdministratorCustomTitleParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_set_chat_administrator_custom_title_parameters(parameters)

  new_post_request(
    client:,
    path: "setChatAdministratorCustomTitle",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to ban a channel chat in a supergroup or a channel. Until the chat is [unbanned](https://core.telegram.org/bots/api#unbanchatsenderchat), the owner of the banned chat won't be able to send messages on behalf of **any of their channels**. The bot must be an administrator in the supergroup or channel for this to work and must have the appropriate administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#banchatsenderchat
pub fn ban_chat_sender_chat(
  client client: client.TelegramClient,
  parameters parameters: BanChatSenderChatParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_ban_chat_sender_chat_parameters(parameters)

  new_post_request(
    client:,
    path: "banChatSenderChat",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to unban a previously banned channel chat in a supergroup or channel. The bot must be an administrator for this to work and must have the appropriate administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#unbanchatsenderchat
pub fn unban_chat_sender_chat(
  client client: client.TelegramClient,
  parameters parameters: UnbanChatSenderChatParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_unban_chat_sender_chat_parameters(parameters)

  new_post_request(
    client:,
    path: "unbanChatSenderChat",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to set default chat permissions for all members. The bot must be an administrator in the group or a supergroup for this to work and must have the `can_restrict_members` administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchatpermissions
pub fn set_chat_permissions(
  client client: client.TelegramClient,
  parameters parameters: SetChatPermissionsParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_chat_permissions_parameters(parameters)

  new_post_request(
    client:,
    path: "setChatPermissions",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to generate a new primary invite link for a chat; any previously generated primary link is revoked. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns the new invite link as String on success.
///
/// > Note: Each administrator in a chat generates their own invite links. Bots can't use invite links generated by other administrators. If you want your bot to work with invite links, it will need to generate its own link using [exportChatInviteLink](https://core.telegram.org/bots/api#exportchatinvitelink) or by calling the [getChat](https://core.telegram.org/bots/api#getchat) method. If your bot needs to generate a new primary invite link replacing its previous one, use [exportChatInviteLink](https://core.telegram.org/bots/api#exportchatinvitelink) again.
///
/// **Official reference:** https://core.telegram.org/bots/api#exportchatinvitelink
pub fn export_chat_invite_link(
  client client: client.TelegramClient,
  parameters parameters: ExportChatInviteLinkParameters,
) -> Result(String, error.TelegaError) {
  let body_json = encoder.encode_export_chat_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "exportChatInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.string)
}

/// Use this method to create an additional invite link for a chat. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. The link can be revoked using the method [revokeChatInviteLink](https://core.telegram.org/bots/api#revokechatinvitelink). Returns the new invite link as [ChatInviteLink](https://core.telegram.org/bots/api#chatinvitelink) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#createchatinvitelink
pub fn create_chat_invite_link(
  client client: client.TelegramClient,
  parameters parameters: CreateChatInviteLinkParameters,
) -> Result(ChatInviteLink, error.TelegaError) {
  let body_json = encoder.encode_create_chat_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "createChatInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.chat_invite_link_decoder())
}

/// Use this method to edit a non-primary invite link created by the bot. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns the edited invite link as a [ChatInviteLink](https://core.telegram.org/bots/api#chatinvitelink) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#editchatinvitelink
pub fn edit_chat_invite_link(
  client client: client.TelegramClient,
  parameters parameters: EditChatInviteLinkParameters,
) -> Result(ChatInviteLink, error.TelegaError) {
  let body_json = encoder.encode_edit_chat_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "editChatInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.chat_invite_link_decoder())
}

/// Use this method to create a [subscription invite link](https://core.telegram.org/bots/api#chatinvitelink) for a channel chat. The bot must have the `can_invite_users` administrator rights. The link can be edited using the method [editChatSubscriptionInviteLink](https://core.telegram.org/bots/api#editchatsubscriptioninvitelink) or revoked using the method [revokeChatInviteLink](https://core.telegram.org/bots/api#revokechatinvitelink). Returns the new invite link as a [ChatInviteLink](https://core.telegram.org/bots/api#chatinvitelink) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#createchatsubscriptioninvitelink
pub fn create_chat_subscription_invite_link(
  client client: client.TelegramClient,
  parameters parameters: CreateChatSubscriptionInviteLinkParameters,
) -> Result(ChatInviteLink, error.TelegaError) {
  let body_json =
    encoder.encode_create_chat_subscription_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "createChatSubscriptionInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.chat_invite_link_decoder())
}

/// Use this method to edit a subscription invite link created by the bot. The bot must have the can_invite_users administrator rights. Returns the edited invite link as a [ChatInviteLink](https://core.telegram.org/bots/api#chatinvitelink) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#editchatsubscriptioninvitelink
pub fn edit_chat_subscription_invite_link(
  client client: client.TelegramClient,
  parameters parameters: EditChatSubscriptionInviteLinkParameters,
) -> Result(ChatInviteLink, error.TelegaError) {
  let body_json =
    encoder.encode_edit_chat_subscription_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "editChatSubscriptionInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.chat_invite_link_decoder())
}

/// Use this method to revoke an invite link created by the bot. If the primary link is revoked, a new link is automatically generated. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns the revoked invite link as [ChatInviteLink](https://core.telegram.org/bots/api#chatinvitelink) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#revokechatinvitelink
pub fn revoke_chat_invite_link(
  client client: client.TelegramClient,
  parameters parameters: RevokeChatInviteLinkParameters,
) -> Result(ChatInviteLink, error.TelegaError) {
  let body_json = encoder.encode_revoke_chat_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "revokeChatInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.chat_invite_link_decoder())
}

/// Use this method to approve a chat join request. The bot must be an administrator in the chat for this to work and must have the `can_invite_users` administrator right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#approvechatjoinrequest
pub fn approve_chat_join_request(
  client client: client.TelegramClient,
  parameters parameters: ApproveChatJoinRequestParameters,
) -> Result(Response(String), error.TelegaError) {
  let body_json =
    encoder.encode_approve_chat_join_request_parameters(parameters)

  new_post_request(
    client:,
    path: "approveChatJoinRequest",
    body: json.to_string(body_json),
  )
  |> fetch(client)
}

/// Use this method to decline a chat join request. The bot must be an administrator in the chat for this to work and must have the `can_invite_users` administrator right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#declinechatjoinrequest
pub fn decline_chat_join_request(
  client client: client.TelegramClient,
  parameters parameters: DeclineChatJoinRequestParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_decline_chat_join_request_parameters(parameters)

  new_post_request(
    client:,
    path: "declineChatJoinRequest",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to set a new profile photo for the chat. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchatphoto
pub fn set_chat_photo(
  client client: client.TelegramClient,
  parameters parameters: SetChatPhotoParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_chat_photo_parameters(parameters)

  new_post_request(
    client:,
    path: "setChatPhoto",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to delete a chat photo. Photos can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletechatphoto
pub fn delete_chat_photo(
  client client: client.TelegramClient,
  parameters parameters: DeleteChatPhotoParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_delete_chat_photo_parameters(parameters)

  new_post_request(
    client:,
    path: "deleteChatPhoto",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to change the title of a chat. Titles can't be changed for private chats. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchattitle
pub fn set_chat_title(
  client client: client.TelegramClient,
  parameters parameters: SetChatTitleParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_chat_title_parameters(parameters)

  new_post_request(
    client:,
    path: "setChatTitle",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to change the description of a group, a supergroup or a channel. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchatdescription
pub fn set_chat_description(
  client client: client.TelegramClient,
  parameters parameters: SetChatDescriptionParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_chat_description_parameters(parameters)

  new_post_request(
    client:,
    path: "setChatDescription",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to add a message to the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can_pin_messages' administrator right in a supergroup or 'can_edit_messages' administrator right in a channel. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#pinchatmessage
pub fn pin_chat_message(
  client client: client.TelegramClient,
  parameters parameters: PinChatMessageParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_pin_chat_message_parameters(parameters)

  new_post_request(
    client:,
    path: "pinChatMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to remove a message from the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can_pin_messages' administrator right in a supergroup or 'can_edit_messages' administrator right in a channel. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#unpinchatmessage
pub fn unpin_chat_message(
  client client: client.TelegramClient,
  parameters parameters: UnpinChatMessageParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_unpin_chat_message_parameters(parameters)

  new_post_request(
    client:,
    path: "unpinChatMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to clear the list of pinned messages in a chat. If the chat is not a private chat, the bot must be an administrator in the chat for this to work and must have the 'can_pin_messages' administrator right in a supergroup or 'can_edit_messages' administrator right in a channel. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#clearchatpinnedmessages
pub fn unpin_all_chat_messages(
  client client: client.TelegramClient,
  parameters parameters: UnpinAllChatMessagesParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_unpin_all_chat_messages_parameters(parameters)

  new_post_request(
    client:,
    path: "unpinAllChatMessages",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method for your bot to leave a group, supergroup or channel. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#leavechat
pub fn leave_chat(
  client client: client.TelegramClient,
  parameters parameters: LeaveChatParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_leave_chat_parameters(parameters)

  new_post_request(client:, path: "leaveChat", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get a list of administrators in a chat, which aren't bots. Returns an Array of [ChatMember](https://core.telegram.org/bots/api#chatmember) objects.
///
/// **Official reference:** https://core.telegram.org/bots/api#getchatadministrators
pub fn get_chat_administrators(
  client client: client.TelegramClient,
  parameters parameters: GetChatAdministratorsParameters,
) -> Result(List(ChatMember), error.TelegaError) {
  let body_json = encoder.encode_get_chat_administrators_parameters(parameters)

  new_post_request(
    client:,
    path: "getChatAdministrators",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.list(decoder.chat_member_decoder()))
}

/// Use this method to get the number of members in a chat. Returns `Int` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getchatmembercount
pub fn get_chat_member_count(
  client client: client.TelegramClient,
  parameters parameters: GetChatMemberCountParameters,
) -> Result(Int, error.TelegaError) {
  let body_json = encoder.encode_get_chat_member_count_parameters(parameters)

  new_post_request(
    client:,
    path: "getChatMemberCount",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.int)
}

/// Use this method to get information about a member of a chat. The method is only guaranteed to work for other users if the bot is an administrator in the chat. Returns a [ChatMember](https://core.telegram.org/bots/api#chatmember) object on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getchatmember
pub fn get_chat_member(
  client client: client.TelegramClient,
  parameters parameters: GetChatMemberParameters,
) -> Result(ChatMember, error.TelegaError) {
  let body_json = encoder.encode_get_chat_member_parameters(parameters)

  new_post_request(
    client:,
    path: "getChatMember",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.chat_member_decoder())
}

/// Use this method to set a new group sticker set for a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Use the field `can_set_sticker_set` optionally returned in `getChat` requests to check if the bot can use this method. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchatstickerset
pub fn set_chat_sticker_set(
  client client: client.TelegramClient,
  parameters parameters: SetChatStickerSetParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_chat_sticker_set_parameters(parameters)

  new_post_request(
    client:,
    path: "setChatStickerSet",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to delete a group sticker set from a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Use the field `can_set_sticker_set` optionally returned in `getChat` requests to check if the bot can use this method. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletechatstickerset
pub fn delete_chat_sticker_set(
  client client: client.TelegramClient,
  parameters parameters: DeleteChatStickerSetParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_delete_chat_sticker_set_parameters(parameters)

  new_post_request(
    client:,
    path: "deleteChatStickerSet",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get custom emoji stickers, which can be used as a forum topic icon by any user. Requires no parameters. Returns an Array of [Sticker](https://core.telegram.org/bots/api#sticker) objects.
///
/// **Official reference:** https://core.telegram.org/bots/api#getforumtopiciconstickers
pub fn get_forum_topic_icon_stickers(
  client client: client.TelegramClient,
) -> Result(List(Sticker), error.TelegaError) {
  new_get_request(client:, path: "getForumTopicIconStickers", query: None)
  |> fetch(client)
  |> map_response(decode.list(decoder.sticker_decoder()))
}

/// Use this method to create a topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights. Returns information about the created topic as a [ForumTopic](https://core.telegram.org/bots/api#forumtopic) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#createforumtopic
pub fn create_forum_topic(
  client client: client.TelegramClient,
  parameters parameters: CreateForumTopicParameters,
) -> Result(ForumTopic, error.TelegaError) {
  let body_json = encoder.encode_create_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "createForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.forum_topic_decoder())
}

/// Use this method to edit name and icon of a topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights, unless it is the creator of the topic. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#editforumtopic
pub fn edit_forum_topic(
  client client: client.TelegramClient,
  parameters parameters: EditForumTopicParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_edit_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "editForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to close an open topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights, unless it is the creator of the topic. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#closeforumtopic
pub fn close_forum_topic(
  client client: client.TelegramClient,
  parameters parameters: CloseForumTopicParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_close_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "closeForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to reopen a closed topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights, unless it is the creator of the topic. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#reopenforumtopic
pub fn reopen_forum_topic(
  client client: client.TelegramClient,
  parameters parameters: ReopenForumTopicParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_reopen_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "reopenForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to delete a forum topic along with all its messages in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_delete_messages` administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#deleteforumtopic
pub fn delete_forum_topic(
  client client: client.TelegramClient,
  parameters parameters: DeleteForumTopicParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_delete_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "deleteForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to clear the list of pinned messages in a forum topic. The bot must be an administrator in the chat for this to work and must have the `can_pin_messages` administrator right in the supergroup. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#unpinallforumtopicpinnedmessages
pub fn unpin_all_forum_topic_pinned_messages(
  client client: client.TelegramClient,
  parameters parameters: UnpinAllForumTopicMessagesParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_unpin_all_forum_topic_messages_parameters(parameters)

  new_post_request(
    client:,
    path: "unpinAllForumTopicMessages",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to edit the name of the 'General' topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#editgeneralforumtopic
pub fn edit_general_forum_topic(
  client client: client.TelegramClient,
  parameters parameters: EditGeneralForumTopicParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_edit_general_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "editGeneralForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to close an open 'General' topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#closegeneralforumtopic
pub fn close_general_forum_topic(
  client client: client.TelegramClient,
  parameters parameters: CloseGeneralForumTopicParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_close_general_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "closeGeneralForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to reopen a closed 'General' topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights. The topic will be automatically unhidden if it was hidden. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#reopengeneralforumtopic
pub fn reopen_general_forum_topic(
  client client: client.TelegramClient,
  parameters parameters: ReopenGeneralForumTopicParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_reopen_general_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "reopenGeneralForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to hide the 'General' topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights. The topic will be automatically closed if it was open. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#hidegeneralforumtopic
pub fn hide_general_forum_topic(
  client client: client.TelegramClient,
  parameters parameters: HideGeneralForumTopicParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_hide_general_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "hideGeneralForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to unhide the 'General' topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#unhidegeneralforumtopic
pub fn unhide_general_forum_topic(
  client client: client.TelegramClient,
  parameters parameters: UnhideGeneralForumTopicParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_unhide_general_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "unhideGeneralForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to clear the list of pinned messages in a General forum topic. The bot must be an administrator in the chat for this to work and must have the `can_pin_messages` administrator right in the supergroup. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#unpinallgeneralforumtopicmessages
pub fn unpin_all_general_forum_topic_messages(
  client client: client.TelegramClient,
  parameters parameters: UnpinAllGeneralForumTopicPinnedMessagesParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_unpin_all_general_forum_topic_pinned_messages_parameters(
      parameters,
    )

  new_post_request(
    client:,
    path: "unpinAllGeneralForumTopicMessages",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get the list of boosts added to a chat by a user. Requires administrator rights in the chat. Returns a [UserChatBoosts](https://core.telegram.org/bots/api#userchatboosts) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#getuserchatboosts
pub fn get_user_chat_boosts(
  client client: client.TelegramClient,
  parameters parameters: GetUserChatBoostsParameters,
) -> Result(UserChatBoosts, error.TelegaError) {
  let body_json = encoder.encode_get_user_chat_boosts_parameters(parameters)

  new_post_request(
    client:,
    path: "getUserChatBoosts",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.user_chat_boosts_decoder())
}

/// Use this method to get information about the connection of the bot with a business account. Returns a [BusinessConnection](https://core.telegram.org/bots/api#businessconnection) object on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getbusinessconnection
pub fn get_business_connection(
  client client: client.TelegramClient,
  parameters parameters: GetBusinessConnectionParameters,
) -> Result(BusinessConnection, error.TelegaError) {
  let body_json = encoder.encode_get_business_connection_parameters(parameters)

  new_post_request(
    client:,
    path: "getBusinessConnection",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.business_connection_decoder())
}

/// Use this method to change the list of the bot's commands. See [commands documentation](https://core.telegram.org/bots/features#commands) for more details about bot commands.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmycommands
pub fn set_my_commands(
  client client: client.TelegramClient,
  commands commands: List(BotCommand),
  parameters parameters: Option(BotCommandParameters),
) -> Result(Bool, error.TelegaError) {
  let parameters =
    option.unwrap(parameters, types.default_bot_command_parameters())
    |> encoder.encode_bot_command_parameters()

  let body_json =
    json.object([
      #(
        "commands",
        json.array(commands, fn(command) {
          json.object([
            #("command", json.string(command.command)),
            #("description", json.string(command.description)),
            ..parameters
          ])
        }),
      ),
    ])

  new_post_request(
    client:,
    path: "setMyCommands",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to delete the list of the bot's commands for the given scope and user language.
/// After deletion, [higher level commands](https://core.telegram.org/bots/api#determining-list-of-commands) will be shown to affected users.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletemycommands
pub fn delete_my_commands(
  client client: client.TelegramClient,
  parameters parameters: Option(BotCommandParameters),
) -> Result(Bool, error.TelegaError) {
  let parameters =
    option.unwrap(parameters, types.default_bot_command_parameters())
    |> encoder.encode_bot_command_parameters()

  let body_json = json.object(parameters)

  new_post_request(
    client:,
    path: "deleteMyCommands",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get the current list of the bot's commands for the given scope and user language.
///
/// **Official reference:** https://core.telegram.org/bots/api#getmycommands
pub fn get_my_commands(
  client client: client.TelegramClient,
  parameters parameters: Option(BotCommandParameters),
) -> Result(BotCommand, error.TelegaError) {
  let parameters =
    option.unwrap(parameters, types.default_bot_command_parameters())
    |> encoder.encode_bot_command_parameters

  let body_json = json.object(parameters)

  new_post_request(
    client:,
    path: "getMyCommands",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.bot_command_decoder())
}

/// Use this method to change the bot's name. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmyname
pub fn set_my_name(
  client client: client.TelegramClient,
  parameters parameters: SetMyNameParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_my_name_parameters(parameters)

  new_post_request(client:, path: "setMyName", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get the current bot name for the given user language. Returns [BotName](https://core.telegram.org/bots/api#botname) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getmyname
pub fn get_my_name(
  client client: client.TelegramClient,
  parameters parameters: GetMyNameParameters,
) -> Result(BotName, error.TelegaError) {
  let body_json = encoder.encode_get_my_name_parameters(parameters)

  new_post_request(client:, path: "getMyName", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.bot_name_decoder())
}

/// Use this method to change the bot's description, which is shown in the chat with the bot if the chat is empty. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmydescription
pub fn set_my_description(
  client client: client.TelegramClient,
  parameters parameters: SetMyDescriptionParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_my_description_parameters(parameters)

  new_post_request(
    client:,
    path: "setMyDescription",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get the current bot description for the given user language. Returns [BotDescription](https://core.telegram.org/bots/api#botdescription) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getmydescription
pub fn get_my_description(
  client client: client.TelegramClient,
  parameters parameters: GetMyDescriptionParameters,
) -> Result(BotDescription, error.TelegaError) {
  let body_json = encoder.encode_get_my_description_parameters(parameters)

  new_post_request(
    client:,
    path: "getMyDescription",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.bot_description_decoder())
}

/// Use this method to change the bot's short description, which is shown on the bot's profile page and is sent together with the link when users share the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmyshortdescription
pub fn set_my_short_description(
  client client: client.TelegramClient,
  parameters parameters: SetMyShortDescriptionParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_my_short_description_parameters(parameters)

  new_post_request(
    client:,
    path: "setMyShortDescription",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get the current bot short description for the given user language. Returns [BotShortDescription](https://core.telegram.org/bots/api#botshortdescription) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getmyshortdescription
pub fn get_my_short_description(
  client client: client.TelegramClient,
  parameters parameters: GetMyShortDescriptionParameters,
) -> Result(BotShortDescription, error.TelegaError) {
  let body_json = encoder.encode_get_my_short_description_parameters(parameters)

  new_post_request(
    client:,
    path: "getMyShortDescription",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.bot_short_description_decoder())
}

/// Use this method to change the bot's menu button in a private chat, or the default menu button. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchatmenubutton
pub fn set_chat_menu_button(
  client client: client.TelegramClient,
  parameters parameters: SetChatMenuButtonParameters,
) -> Result(Bool, error.TelegaError) {
  new_post_request(
    client:,
    path: "setChatMenuButton",
    body: encoder.encode_set_chat_menu_button_parameters(parameters)
      |> json.to_string(),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get the current value of the bot's menu button in a private chat, or the default menu button. Returns [MenuButton](https://core.telegram.org/bots/api#menubutton) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getchatmenubutton
pub fn get_chat_menu_button(
  client client: client.TelegramClient,
  parameters parameters: GetChatMenuButtonParameters,
) -> Result(MenuButton, error.TelegaError) {
  let body_json = encoder.encode_get_chat_menu_button_parameters(parameters)

  new_post_request(
    client:,
    path: "getChatMenuButton",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.menu_button_decoder())
}

/// Use this method to change the default administrator rights requested by the bot when it's added as an administrator to groups or channels. These rights will be suggested to users, but they are free to modify the list before adding the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmydefaultadministratorrights
pub fn set_my_default_administrator_rights(
  client client: client.TelegramClient,
  parameters parameters: SetMyDefaultAdministratorRightsParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_set_my_default_administrator_rights_parameters(parameters)

  new_post_request(
    client:,
    path: "setMyDefaultAdministratorRights",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get the current default administrator rights of the bot. Returns [ChatAdministratorRights](https://core.telegram.org/bots/api#chatadministratorrights) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getmydefaultadministratorrights
pub fn get_my_default_administrator_rights(
  client client: client.TelegramClient,
  parameters parameters: GetMyDefaultAdministratorRightsParameters,
) -> Result(ChatAdministratorRights, error.TelegaError) {
  let body_json =
    encoder.encode_get_my_default_administrator_rights_parameters(parameters)

  new_post_request(
    client:,
    path: "getMyDefaultAdministratorRights",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.chat_administrator_rights_decoder())
}

/// Use this method to send static .WEBP, [animated](https://telegram.org/blog/animated-stickers) .TGS, or [video](https://telegram.org/blog/video-stickers-better-reactions/ru?ln=a) .WEBM stickers. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendsticker
pub fn send_sticker(
  client client: client.TelegramClient,
  parameters parameters: SendStickerParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_sticker_parameters(parameters)

  new_post_request(
    client:,
    path: "sendSticker",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to get a sticker set. On success, a [StickerSet](https://core.telegram.org/bots/api#stickerset) object is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#getstickerset
pub fn get_sticker_set(
  client client: client.TelegramClient,
  parameters parameters: GetStickerSetParameters,
) -> Result(StickerSet, error.TelegaError) {
  let body_json = encoder.encode_get_sticker_set_parameters(parameters)

  new_post_request(
    client:,
    path: "getStickerSet",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.sticker_set_decoder())
}

/// Use this method to get information about custom emoji stickers by their identifiers. Returns an Array of [Sticker](https://core.telegram.org/bots/api#sticker) objects.
///
/// **Official reference:** https://core.telegram.org/bots/api#getcustomemojistickers
pub fn get_custom_emoji_stickers(
  client client: client.TelegramClient,
  parameters parameters: GetCustomEmojiStickersParameters,
) -> Result(Sticker, error.TelegaError) {
  let body_json =
    encoder.encode_get_custom_emoji_stickers_parameters(parameters)

  new_post_request(
    client:,
    path: "getCustomEmojiStickers",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.sticker_decoder())
}

/// Use this method to upload a file with a sticker for later use in the [createNewStickerSet](https://core.telegram.org/bots/api#createnewstickerset), [addStickerToSet](https://core.telegram.org/bots/api#addstickertoset), or [replaceStickerInSet](https://core.telegram.org/bots/api#replacestickerinset) methods (the file can be used multiple times). Returns the uploaded [File](https://core.telegram.org/bots/api#file) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#uploadstickerfile
pub fn upload_sticker_file(
  client client: client.TelegramClient,
  parameters parameters: UploadStickerFileParameters,
) -> Result(File, error.TelegaError) {
  let body_json = encoder.encode_upload_sticker_file_parameters(parameters)

  new_post_request(
    client:,
    path: "uploadStickerFile",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.file_decoder())
}

/// Use this method to create a new sticker set owned by a user. The bot will be able to edit the sticker set thus created. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#createnewstickerset
pub fn create_new_sticker_set(
  client client: client.TelegramClient,
  parameters parameters: CreateNewStickerSetParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_create_new_sticker_set_parameters(parameters)

  new_post_request(
    client:,
    path: "createNewStickerSet",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to add a new sticker to a set created by the bot. Emoji sticker sets can have up to 200 stickers. Other sticker sets can have up to 120 stickers. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#addstickertoset
pub fn add_sticker_to_set(
  client client: client.TelegramClient,
  parameters parameters: AddStickerToSetParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_add_sticker_to_set_parameters(parameters)

  new_post_request(
    client:,
    path: "addStickerToSet",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to move a sticker in a set to a specific position. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setstickerpositioninset
pub fn set_sticker_position_in_set(
  client client: client.TelegramClient,
  parameters parameters: SetStickerPositionInSetParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_set_sticker_position_in_set_parameters(parameters)

  new_post_request(
    client:,
    path: "setStickerPositionInSet",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to delete a sticker from a set created by the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletestickerfromset
pub fn delete_sticker_from_set(
  client client: client.TelegramClient,
  parameters parameters: DeleteStickerFromSetParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_delete_sticker_from_set_parameters(parameters)

  new_post_request(
    client:,
    path: "deleteStickerFromSet",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to replace an existing sticker in a sticker set with a new one. The method is equivalent to calling deleteStickerFromSet, then addStickerToSet, then setStickerPositionInSet. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#replacestickerinset
pub fn replace_sticker_in_set(
  client client: client.TelegramClient,
  parameters parameters: ReplaceStickerInSetParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_replace_sticker_in_set_parameters(parameters)

  new_post_request(
    client:,
    path: "replaceStickerInSet",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to change the list of emoji assigned to a regular or custom emoji sticker. The sticker must belong to a sticker set created by the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setstickeremojilist
pub fn set_sticker_emoji_list(
  client client: client.TelegramClient,
  parameters parameters: SetStickerEmojiListParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_sticker_emoji_list_parameters(parameters)

  new_post_request(
    client:,
    path: "setStickerEmojiList",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to change search keywords assigned to a regular or custom emoji sticker. The sticker must belong to a sticker set created by the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setstickerkeywords
pub fn set_sticker_keywords(
  client client: client.TelegramClient,
  parameters parameters: SetStickerKeywordsParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_sticker_keywords_parameters(parameters)

  new_post_request(
    client:,
    path: "setStickerKeywords",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to change the mask position of a mask sticker. The sticker must belong to a sticker set that was created by the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setstickermaskposition
pub fn set_sticker_mask_position(
  client client: client.TelegramClient,
  parameters parameters: SetStickerMaskPositionParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_set_sticker_mask_position_parameters(parameters)

  new_post_request(
    client:,
    path: "setStickerMaskPosition",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to set the title of a created sticker set. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setstickersettitle
pub fn set_sticker_set_title(
  client client: client.TelegramClient,
  parameters parameters: SetStickerSetTitleParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_set_sticker_set_title_parameters(parameters)

  new_post_request(
    client:,
    path: "setStickerSetTitle",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to set the thumbnail of a regular or mask sticker set. The format of the thumbnail file must match the format of the stickers in the set. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setstickersetthumbnail
pub fn set_sticker_set_thumbnail(
  client client: client.TelegramClient,
  parameters parameters: SetStickerSetThumbnailParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_set_sticker_set_thumbnail_parameters(parameters)

  new_post_request(
    client:,
    path: "setStickerSetThumbnail",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to set the thumbnail of a custom emoji sticker set. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setcustomemojistickersetthumbnail
pub fn set_custom_emoji_sticker_set_thumbnail(
  client client: client.TelegramClient,
  parameters parameters: SetCustomEmojiStickerSetThumbnailParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_set_custom_emoji_sticker_set_thumbnail_parameters(parameters)

  new_post_request(
    client:,
    path: "setCustomEmojiStickerSetThumbnail",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to delete a sticker set that was created by the bot. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletestickerset
pub fn delete_sticker_set(
  client client: client.TelegramClient,
  parameters parameters: DeleteStickerSetParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_delete_sticker_set_parameters(parameters)

  new_post_request(
    client:,
    path: "deleteStickerSet",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to send answers to an inline query. On success, True is returned.
/// No more than 50 results per query are allowed.
///
/// **Official reference:** https://core.telegram.org/bots/api#answerinlinequery
pub fn answer_inline_query(
  client client: client.TelegramClient,
  parameters parameters: AnswerInlineQueryParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_answer_inline_query_parameters(parameters)

  new_post_request(
    client:,
    path: "answerInlineQuery",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to send invoices. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendinvoice
pub fn send_invoice(
  client client: client.TelegramClient,
  parameters parameters: SendInvoiceParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_invoice_parameters(parameters)

  new_post_request(
    client:,
    path: "sendInvoice",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to create a link for an invoice.
///
/// **Official reference:** https://core.telegram.org/bots/api#createinvoicelink
pub fn create_invoice_link(
  client client: client.TelegramClient,
  parameters parameters: CreateInvoiceLinkParameters,
) -> Result(String, error.TelegaError) {
  let body_json = encoder.encode_create_invoice_link_parameters(parameters)

  new_post_request(
    client,
    path: "createInvoiceLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.string)
}

/// If you sent an invoice requesting a shipping address and the parameter `is_flexible` was specified, the Bot API will send an [Update](https://core.telegram.org/bots/api#update) with a `shipping_query` field to the bot. Use this method to reply to shipping queries. On success, `True` is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#answershippingquery
pub fn answer_shipping_query(
  client client: client.TelegramClient,
  parameters parameters: AnswerShippingQueryParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_answer_shipping_query_parameters(parameters)

  new_post_request(
    client:,
    path: "answerShippingQuery",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Once the user has confirmed their payment and shipping details, the Bot API sends the final confirmation in the form of an [Update](https://core.telegram.org/bots/api#update) with the field `pre_checkout_query`. Use this method to respond to such pre-checkout queries. On success, `True` is returned.
/// > **Note:** The Bot API must receive an answer within 10 seconds after the pre-checkout query was sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#answerprecheckoutquery
pub fn answer_pre_checkout_query(
  client client: client.TelegramClient,
  parameters parameters: AnswerPreCheckoutQueryParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_answer_pre_checkout_query_parameters(parameters)

  new_post_request(
    client:,
    path: "answerPreCheckoutQuery",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Returns the bot's Telegram Star transactions in chronological order. On success, returns a [StarTransactions](https://core.telegram.org/bots/api#startransactions) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#getmystartransactions
pub fn get_star_transactions(
  client client: client.TelegramClient,
  parameters parameters: GetStarTransactionsParameters,
) -> Result(StarTransactions, error.TelegaError) {
  let body_json = encoder.encode_get_star_transactions_parameters(parameters)

  new_post_request(
    client:,
    path: "getStarTransactions",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.star_transactions_decoder())
}

/// Refunds a successful payment in Telegram Stars. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#refundstars
pub fn refund_star_payment(
  client client: client.TelegramClient,
  parameters parameters: RefundStarPaymentParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json = encoder.encode_refund_star_payment_parameters(parameters)

  new_post_request(
    client:,
    path: "refundStarPayment",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Allows the bot to cancel or re-enable extension of a subscription paid in Telegram Stars. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#edituserstarsubscription
pub fn edit_user_star_subscription(
  client client: client.TelegramClient,
  parameters parameters: EditUserStarSubscriptionParameters,
) -> Result(Bool, error.TelegaError) {
  let body_json =
    encoder.encode_edit_user_star_subscription_parameters(parameters)

  new_post_request(
    client:,
    path: "editUserStarSubscription",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to send a game. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendgame
pub fn send_game(
  client client: client.TelegramClient,
  parameters parameters: SendGameParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_send_game_parameters(parameters)

  new_post_request(client:, path: "sendGame", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to set the score of the specified user in a game message. On success, if the message is not an inline message, the [Message](https://core.telegram.org/bots/api#message) is returned, otherwise `True` is returned. Returns an error, if the new score is not greater than the user's current score in the chat and `force` is `False`.
///
/// **Official reference:** https://core.telegram.org/bots/api#setgamescore
pub fn set_game_score(
  client client: client.TelegramClient,
  parameters parameters: SetGameScoreParameters,
) -> Result(Message, error.TelegaError) {
  let body_json = encoder.encode_set_game_score_parameters(parameters)

  new_post_request(
    client:,
    path: "setGameScore",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_decoder())
}

/// Use this method to get data for high score tables. Will return the score of the specified user and several of their neighbors in a game. Returns an Array of [GameHighScore](https://core.telegram.org/bots/api#gamehighscore) objects.
///
/// > This method will currently return scores for the target user, plus two of their closest neighbors on each side. Will also return the top three users if the user and their neighbors are not among them. Please note that this behavior is subject to change.
///
/// **Official reference:** https://core.telegram.org/bots/api#getgamehighscores
pub fn get_game_high_scores(
  client client: client.TelegramClient,
  parameters parameters: GetGameHighScoresParameters,
) -> Result(GameHighScore, error.TelegaError) {
  let body_json = encoder.encode_get_game_high_scores_parameters(parameters)

  new_post_request(
    client:,
    path: "getGameHighScores",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.game_high_score_decoder())
}

/// Use this method to send a draft message created by the user in a chat managed by the bot. Requires the `can_post_messages` administrator right. Returns `MessageId` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessagedraft
pub fn send_message_draft(
  client client: client.TelegramClient,
  parameters parameters: SendMessageDraftParameters,
) -> Result(types.MessageId, error.TelegaError) {
  let body_json = encoder.encode_send_message_draft_parameters(parameters)

  new_post_request(
    client:,
    path: "sendMessageDraft",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.message_id_decoder())
}

/// Use this method to get the list of gifts owned by a user. Requires no authorization if the user's gift list is public. Returns an [OwnedGifts](https://core.telegram.org/bots/api#ownedgifts) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#getusergifts
pub fn get_user_gifts(
  client client: client.TelegramClient,
  parameters parameters: GetUserGiftsParameters,
) -> Result(OwnedGifts, error.TelegaError) {
  let body_json = encoder.encode_get_user_gifts_parameters(parameters)

  new_post_request(
    client:,
    path: "getUserGifts",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.owned_gifts_decoder())
}

/// Use this method to get the list of gifts received by a channel chat or a business account managed by the bot. Requires the `can_view_gifts_and_stars` administrator right if the chat is a channel. Returns an [OwnedGifts](https://core.telegram.org/bots/api#ownedgifts) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#getchatgifts
pub fn get_chat_gifts(
  client client: client.TelegramClient,
  parameters parameters: GetChatGiftsParameters,
) -> Result(OwnedGifts, error.TelegaError) {
  let body_json = encoder.encode_get_chat_gifts_parameters(parameters)

  new_post_request(
    client:,
    path: "getChatGifts",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.owned_gifts_decoder())
}

/// Use this method to repost a story to another chat. The story must have been originally posted by the bot or must be a repostable chat story. Returns [Story](https://core.telegram.org/bots/api#story) on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#repoststory
pub fn repost_story(
  client client: client.TelegramClient,
  parameters parameters: RepostStoryParameters,
) -> Result(Story, error.TelegaError) {
  let body_json = encoder.encode_repost_story_parameters(parameters)

  new_post_request(
    client:,
    path: "repostStory",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decoder.story_decoder())
}

// Common Helpers --------------------------------------------------------------------------------------

fn map_response(
  response: Result(Response(String), error.TelegaError),
  result_decoder: decode.Decoder(b),
) -> Result(b, error.TelegaError) {
  use response <- result.try(response)

  json.parse(from: response.body, using: response_decoder(result_decoder))
  |> result.map_error(error.JsonDecodeError)
  |> result.try(fn(response) {
    case response {
      ApiSuccessResponse(result: result, ..) -> {
        Ok(result)
      }
      ApiErrorResponse(error_code: error_code, description: description, ..) -> {
        Error(error.TelegramApiError(error_code, description))
      }
    }
  })
}

fn response_decoder(
  result_decoder: decode.Decoder(a),
) -> decode.Decoder(ApiResponse(a)) {
  use ok <- decode.field("ok", decode.bool)

  case ok {
    True -> {
      use result <- decode.field("result", result_decoder)
      decode.success(ApiSuccessResponse(ok:, result:))
    }
    False -> {
      use error_code <- decode.field("error_code", decode.int)
      use description <- decode.field("description", decode.string)
      decode.success(ApiErrorResponse(ok:, error_code:, description:))
    }
  }
}
