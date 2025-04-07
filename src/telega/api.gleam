//// This module provides an interface for interacting with the Telegram Bot API.
//// It will be useful if you want to interact with the Telegram Bot API directly, without running a bot.
//// But it will be more convenient to use the `reply` module in bot handlers.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/http/response.{type Response, Response}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

import telega/error
import telega/internal/fetch.{fetch, new_get_request, new_post_request}
import telega/model.{type BotCommand, type GetUpdatesParameters}

type ApiResponse(result) {
  ApiSuccessResponse(ok: Bool, result: result)
  ApiErrorResponse(ok: Bool, error_code: Int, description: String)
}

/// Set the webhook URL using [setWebhook](https://core.telegram.org/bots/api#setwebhook) API.
///
/// **Official reference:** https://core.telegram.org/bots/api#setwebhook
pub fn set_webhook(config config, parameters parameters) {
  let body = model.encode_set_webhook_parameters(parameters)

  new_post_request(
    config:,
    path: "setWebhook",
    body: json.to_string(body),
    query: None,
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to get current webhook status.
///
/// **Official reference:** https://core.telegram.org/bots/api#getwebhookinfo
pub fn get_webhook_info(config config) {
  new_get_request(config:, path: "getWebhookInfo", query: None)
  |> fetch(config)
  |> map_response(model.webhook_info_decoder())
}

/// Use this method to remove webhook integration if you decide to switch back to [getUpdates](https://core.telegram.org/bots/api#getupdates).
///
/// **Official reference:** https://core.telegram.org/bots/api#deletewebhook
pub fn delete_webhook(config config) {
  new_get_request(config:, path: "deleteWebhook", query: None)
  |> fetch(config)
  |> map_response(decode.bool)
}

/// The same as [delete_webhook](#delete_webhook) but also drops all pending updates.
pub fn delete_webhook_and_drop_updates(config config) {
  new_get_request(
    config:,
    path: "deleteWebhook",
    query: Some([#("drop_pending_updates", "true")]),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to log out from the cloud Bot API server before launching the bot locally.
/// You **must** log out the bot before running it locally, otherwise there is no guarantee that the bot will receive updates.
/// After a successful call, you can immediately log in on a local server, but will not be able to log in back to the cloud Bot API server for 10 minutes.
///
/// **Official reference:** https://core.telegram.org/bots/api#logout
pub fn log_out(config config) {
  new_get_request(config:, path: "logOut", query: None)
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to close the bot instance before moving it from one local server to another.
/// You need to delete the webhook before calling this method to ensure that the bot isn't launched again after server restart.
/// The method will return error 429 in the first 10 minutes after the bot is launched.
///
/// **Official reference:** https://core.telegram.org/bots/api#close
pub fn close(config config) {
  new_get_request(config:, path: "close", query: None)
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to send text messages with additional parameters.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn send_message(config config, parameters parameters) {
  let body_json = model.encode_send_message_parameters(parameters)

  new_post_request(
    config:,
    path: "sendMessage",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to change the list of the bot's commands. See [commands documentation](https://core.telegram.org/bots/features#commands) for more details about bot commands.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmycommands
pub fn set_my_commands(
  config config,
  commands commands: List(BotCommand),
  parameters parameters,
) {
  let parameters =
    option.unwrap(parameters, model.default_bot_command_parameters())
    |> model.encode_bot_command_parameters()

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
    config:,
    path: "setMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to delete the list of the bot's commands for the given scope and user language.
/// After deletion, [higher level commands](https://core.telegram.org/bots/api#determining-list-of-commands) will be shown to affected users.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletemycommands
pub fn delete_my_commands(config config, parameters parameters) {
  let parameters =
    option.unwrap(parameters, model.default_bot_command_parameters())
    |> model.encode_bot_command_parameters()

  let body_json = json.object(parameters)

  new_post_request(
    config:,
    path: "deleteMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to get the current list of the bot's commands for the given scope and user language.
///
/// **Official reference:** https://core.telegram.org/bots/api#getmycommands
pub fn get_my_commands(config config, parameters parameters) {
  let parameters =
    option.unwrap(parameters, model.default_bot_command_parameters())
    |> model.encode_bot_command_parameters

  let body_json = json.object(parameters)

  new_post_request(
    config:,
    path: "getMyCommands",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.bot_command_decoder())
}

/// Use this method to send an animated emoji that will display a random value.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddice
pub fn send_dice(config config, parameters parameters) {
  let body_json = model.encode_send_dice_parameters(parameters)

  new_post_request(
    config:,
    path: "sendDice",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// A simple method for testing your bot's authentication token.
///
/// **Official reference:** https://core.telegram.org/bots/api#getme
pub fn get_me(config config) {
  new_get_request(config:, path: "getMe", query: None)
  |> fetch(config)
  |> map_response(model.user_decoder())
}

/// Use this method to send answers to callback queries sent from inline keyboards.
/// The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
/// On success, _True_ is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#answercallbackquery
pub fn answer_callback_query(config config, parameters parameters) {
  let body_json = model.encode_answer_callback_query_parameters(parameters)

  new_post_request(
    config:,
    path: "answerCallbackQuery",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to forward messages of any kind. Service messages and messages with protected content can't be forwarded.
/// On success, the sent Message is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessage
pub fn forward_message(config config, parameters parameters) {
  let body_json = model.encode_forward_message_parameters(parameters)

  new_post_request(
    config:,
    path: "forwardMessage",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to change the bot's menu button in a private chat, or the default menu button. Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchatmenubutton
pub fn set_chat_menu_button(config config, parameters parameters) {
  new_post_request(
    config:,
    path: "setChatMenuButton",
    query: None,
    body: model.encode_set_chat_menu_button_parameters(parameters)
      |> json.to_string(),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to receive incoming updates using long polling ([wiki](https://en.wikipedia.org/wiki/Push_technology#Long_polling)).
///
/// > Notes
/// > 1. This method will not work if an outgoing webhook is set up.
/// > 2. In order to avoid getting duplicate updates, recalculate offset after each server response.
///
/// **Official reference:** https://core.telegram.org/bots/api#getupdates
pub fn get_updates(
  config config,
  parameters parameters: Option(GetUpdatesParameters),
) {
  let query =
    option.map(parameters, fn(p) {
      [#("offset", p.offset), #("limit", p.limit), #("timeout", p.timeout)]
      |> list.filter_map(fn(x) {
        let #(key, value) = x

        case value {
          Some(value) -> Ok(#(key, int.to_string(value)))
          None -> Error(Nil)
        }
      })
    })
  new_get_request(config:, path: "getUpdates", query:)
  |> fetch(config)
  |> map_response(decode.list(model.update_decoder()))
}

/// Use this method to forward multiple messages of any kind. If some of the specified messages can't be found or forwarded, they are skipped. Service messages and messages with protected content can't be forwarded. Album grouping is kept for forwarded messages. On success, an array of [MessageId](https://core.telegram.org/bots/api#messageid) of the sent messages is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessages
pub fn forward_messages(config config, parameters parameters) {
  let body_json = model.encode_forward_messages_parameters(parameters)

  new_post_request(
    config:,
    path: "forwardMessage",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to copy messages of any kind. Service messages, paid media messages, giveaway messages, giveaway winners messages, and invoice messages can't be copied. A quiz [poll](https://core.telegram.org/bots/api#poll) can be copied only if the value of the field correct_option_id is known to the bot. The method is analogous to the method [forwardMessage](https://core.telegram.org/bots/api#forwardmessage), but the copied message doesn't have a link to the original message. Returns the [MessageId](https://core.telegram.org/bots/api#messageid) of the sent message on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#copymessage
pub fn copy_message(config config, parameters parameters) {
  let body_json = model.encode_copy_message_parameters(parameters)

  new_post_request(
    config:,
    path: "copyMessage",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to copy messages of any kind. If some of the specified messages can't be found or copied, they are skipped. Service messages, paid media messages, giveaway messages, giveaway winners messages, and invoice messages can't be copied. A quiz [poll](https://core.telegram.org/bots/api#poll) can be copied only if the value of the field correct_option_id is known to the bot. The method is analogous to the method [forwardMessage](https://core.telegram.org/bots/api#forwardmessage), but the copied message doesn't have a link to the original message. Returns the [MessageId](https://core.telegram.org/bots/api#messageid) of the sent message on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#copymessages
pub fn copy_messages(config config, parameters parameters) {
  let body_json = model.encode_copy_messages_parameters(parameters)

  new_post_request(
    config:,
    path: "copyMessages",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send photos. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendphoto
pub fn send_photo(config config, parameters parameters) {
  let body_json = model.encode_send_photo_parameters(parameters)

  new_post_request(
    config:,
    path: "sendPhoto",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send audio files, if you want Telegram clients to display them in the music player. Your audio must be in the .MP3 or .M4A format. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future.
///
/// For sending voice messages, use the [sendVoice](https://core.telegram.org/bots/api#sendvoice) method instead.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendaudio
pub fn send_audio(config config, parameters parameters) {
  let body_json = model.encode_send_audio_parameters(parameters)

  new_post_request(
    config:,
    path: "sendAudio",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
}

/// Use this method to send general files. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send files of any type of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddocument
pub fn send_document(config config, parameters parameters) {
  let body_json = model.encode_send_document_parameters(parameters)

  new_post_request(
    config:,
    path: "sendDocument",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send video files, Telegram clients support MPEG4 videos (other formats may be sent as Document). On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send video files of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvideo
pub fn send_video(config config, parameters parameters) {
  let body_json = model.encode_send_video_parameters(parameters)

  new_post_request(
    config:,
    path: "sendVideo",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send animation files (GIF or H.264/MPEG-4 AVC video without sound). On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send animation files of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendanimation
pub fn send_animation(config config, parameters parameters) {
  let body_json = model.encode_send_animation_parameters(parameters)

  new_post_request(
    config:,
    path: "sendAnimation",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send audio files, if you want Telegram clients to display the file as a playable voice message. For this to work, your audio must be in an .ogg file encoded with OPUS (other formats may be sent as Audio or Document). On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send voice messages of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvoice
pub fn send_voice(config config, parameters parameters) {
  let body_json = model.encode_send_voice_parameters(parameters)

  new_post_request(
    config:,
    path: "sendVoice",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send video messages. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvideonote
pub fn send_video_note(config config, parameters parameters) {
  let body_json = model.encode_send_video_note_parameters(parameters)

  new_post_request(
    config:,
    path: "sendVideoNote",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send a group of photos, videos, documents or audio files as an album. Documents and audio files can be only grouped in an album with the first item having a filename. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmediagroup
pub fn send_media_group(config config, parameters parameters) {
  let body_json = model.encode_send_media_group_parameters(parameters)

  new_post_request(
    config:,
    path: "sendMediaGroup",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send point on the map. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendlocation
pub fn send_location(config config, parameters parameters) {
  let body_json = model.encode_send_location_parameters(parameters)

  new_post_request(
    config:,
    path: "sendLocation",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send information about a venue. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvenue
pub fn send_venue(config config, parameters parameters) {
  let body_json = model.encode_send_venue_parameters(parameters)

  new_post_request(
    config:,
    path: "sendVenue",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send phone contacts. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendcontact
pub fn send_contact(config config, parameters parameters) {
  let body_json = model.encode_send_contact_parameters(parameters)

  new_post_request(
    config:,
    path: "sendContact",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send a native poll. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendpoll
pub fn send_poll(config config, parameters parameters) {
  let body_json = model.encode_send_poll_parameters(parameters)

  new_post_request(
    config:,
    path: "sendPoll",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status). Returns True on success.
///
/// > Example: The [ImageBot](https://t.me/imagebot) needs some time to process a request and upload the image. Instead of sending a text message along the lines of “Retrieving image, please wait…”, the bot may use [sendChatAction](https://core.telegram.org/bots/api#sendchataction) with action = upload_photo. The user will see a “sending photo” status for the bot.
///
/// We only recommend using this method when a response from the bot will take a noticeable amount of time to arrive.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendchataction
pub fn send_chat_action(config config, parameters parameters) {
  let body_json = model.encode_send_chat_action_parameters(parameters)

  new_post_request(
    config:,
    path: "sendChatAction",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to send invoices. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendinvoice
pub fn send_invoice(config config, parameters parameters) {
  let body_json = model.encode_send_invoice_parameters(parameters)

  new_post_request(
    config:,
    path: "sendInvoice",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to create a link for an invoice.
///
/// **Official reference:** https://core.telegram.org/bots/api#createinvoicelink
pub fn create_invoice_link(config config, parameters parameters) {
  let body_json = model.encode_create_invoice_link_parameters(parameters)

  new_post_request(
    config,
    path: "createInvoiceLink",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(config)
  |> map_response(decode.string)
}

/// Use this method to change the chosen reactions on a message. Service messages of some types can't be reacted to. Automatically forwarded messages from a channel to its discussion group have the same available reactions as messages in the channel. Bots can't use paid reactions. Returns _True_ on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmessagereaction
pub fn set_message_reaction(config config, parameters parameters) {
  let body_json = model.encode_set_message_reaction_parameters(parameters)

  new_post_request(
    config:,
    path: "setMessageReaction",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to get a list of profile pictures for a user. Returns a [UserProfilePhotos](https://core.telegram.org/bots/api#userprofilephotos) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#getuserprofilephotos
pub fn get_user_profile_photos(config config, parameters parameters) {
  let body_json = model.encode_get_user_profile_photos_parameters(parameters)

  new_post_request(
    config:,
    path: "getUserProfilePhotos",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.user_profile_photos_decoder())
}

/// Use this method to send static .WEBP, [animated](https://telegram.org/blog/animated-stickers) .TGS, or [video](https://telegram.org/blog/video-stickers-better-reactions/ru?ln=a) .WEBM stickers. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendsticker
pub fn send_sticker(config config, parameters parameters) {
  let body_json = model.encode_send_sticker_parameters(parameters)

  new_post_request(
    config:,
    path: "sendSticker",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to get a sticker set. On success, a [StickerSet](https://core.telegram.org/bots/api#stickerset) object is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#getstickerset
pub fn get_sticker_set(config config, parameters parameters) {
  let body_json = model.encode_get_sticker_set_parameters(parameters)

  new_post_request(
    config:,
    path: "getStickerSet",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.sticker_set_decoder())
}

/// Use this method to edit text and game messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api#message) is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagetext
pub fn edit_message_text(config config, parameters parameters) {
  let body_json = model.encode_edit_message_text_parameters(parameters)

  new_post_request(
    config:,
    path: "editMessageText",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to edit captions of messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api#message) is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagecaption
pub fn edit_message_caption(config config, parameters parameters) {
  let body_json = model.encode_edit_message_caption_parameters(parameters)

  new_post_request(
    config:,
    path: "editMessageCaption",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to edit animation, audio, document, photo, or video messages, or to add media to text messages. If a message is part of a message album, then it can be edited only to an audio for audio albums, only to a document for document albums and to a photo or a video otherwise. When an inline message is edited, a new file can't be uploaded; use a previously uploaded file via its file_id or specify a URL. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagemedia
pub fn edit_message_media(config config, parameters parameters) {
  let body_json = model.encode_edit_message_media_parameters(parameters)

  new_post_request(
    config:,
    path: "editMessageMedia",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to edit live location messages. A location can be edited until its live_period expires or editing is explicitly disabled by a call to stopMessageLiveLocation. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagelivelocation
pub fn edit_message_live_location(config config, parameters parameters) {
  let body_json = model.encode_edit_message_live_location_parameters(parameters)

  new_post_request(
    config:,
    path: "editMessageLiveLocation",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to stop updating a live location message before live_period expires. On success, if the message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#stopmessagelivelocation
pub fn stop_message_live_location(config config, parameters parameters) {
  let body_json = model.encode_stop_message_live_location_parameters(parameters)

  new_post_request(
    config:,
    path: "stopMessageLiveLocation",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to edit only the reply markup of messages. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagereplymarkup
pub fn edit_message_reply_markup(config config, parameters parameters) {
  let body_json = model.encode_edit_message_reply_markup_parameters(parameters)

  new_post_request(
    config:,
    path: "editMessageReplyMarkup",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to stop a poll which was sent by the bot. On success, the stopped Poll is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#stoppoll
pub fn stop_poll(config config, parameters parameters) {
  let body_json = model.encode_stop_poll_parameters(parameters)

  new_post_request(
    config:,
    path: "stopPoll",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.poll_decoder())
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
pub fn delete_message(config config, parameters parameters) {
  let body_json = model.encode_delete_message_parameters(parameters)

  new_post_request(
    config:,
    path: "deleteMessage",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to delete multiple messages simultaneously. If some of the specified messages can't be found, they are skipped. Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletemessagessimultaneously
pub fn delete_messages(config config, parameters parameters) {
  let body_json = model.encode_delete_messages_parameters(parameters)

  new_post_request(
    config:,
    path: "deleteMessages",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to get up-to-date information about the chat. Returns a [ChatFullInfo](https://core.telegram.org/bots/api#chatfullinfo) object on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getchat
pub fn get_chat(config config, chat_id chat_id) {
  new_get_request(config, path: "getChat", query: Some([#("chat_id", chat_id)]))
  |> fetch(config)
  |> map_response(model.chat_full_info_decoder())
}

/// Use this method to get basic information about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link `https://api.telegram.org/file/bot<token>/<file_path>`, where `<file_path>` is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile again.
///
/// **Official reference:** https://core.telegram.org/bots/api#getfile
pub fn get_file(config config, file_id file_id) {
  new_get_request(config, path: "getFile", query: Some([#("file_id", file_id)]))
  |> fetch(config)
  |> map_response(model.file_decoder())
}

/// Use this method to ban a user in a group, a supergroup or a channel. In the case of supergroups and channels, the user will not be able to return to the chat on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#banchatmember
pub fn ban_chat_member(config config, parameters parameters) {
  let body_json = model.encode_ban_chat_member_parameters(parameters)

  new_post_request(
    config:,
    path: "banChatMember",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to unban a previously banned user in a supergroup or channel. The user will not return to the group or channel automatically, but will be able to join via link, etc. The bot must be an administrator for this to work. By default, this method guarantees that after the call the user is not a member of the chat, but will be able to join it. So if the user is a member of the chat they will also be removed from the chat. If you don't want this, use the parameter only_if_banned. Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#unbanchatmember
pub fn unban_chat_member(config config, parameters parameters) {
  let body_json = model.encode_unban_chat_member_parameters(parameters)

  new_post_request(
    config:,
    path: "unbanChatMember",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

// Common Helpers --------------------------------------------------------------------------------------

fn map_response(
  response: Result(Response(String), error.TelegaError),
  result_decoder,
) {
  use response <- result.try(response)

  json.decode(from: response.body, using: parse_api_response(_, result_decoder))
  |> result.map_error(error.JsonDecodeError)
  |> result.then(fn(response) {
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

fn parse_api_response(json, result_decoder) {
  decode.run(json, response_decoder(result_decoder))
  |> result.map_error(fn(errors) {
    list.map(errors, fn(error) {
      dynamic.DecodeError(
        expected: error.expected,
        found: error.found,
        path: error.path,
      )
    })
  })
}

fn response_decoder(result_decoder) {
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
