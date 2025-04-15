//// This module provides an interface for interacting with the Telegram Bot API.
//// It will be useful if you want to interact with the Telegram Bot API directly, without running a bot.
//// But it will be more convenient to use the `reply` module in bot handlers.

import gleam/dynamic
import gleam/dynamic/decode
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

import telega/client.{fetch, new_get_request, new_post_request}
import telega/error
import telega/model.{type BotCommand, type GetUpdatesParameters}

type ApiResponse(result) {
  ApiSuccessResponse(ok: Bool, result: result)
  ApiErrorResponse(ok: Bool, error_code: Int, description: String)
}

/// Set the webhook URL using [setWebhook](https://core.telegram.org/bots/api#setwebhook) API.
///
/// **Official reference:** https://core.telegram.org/bots/api#setwebhook
pub fn set_webhook(client client, parameters parameters) {
  let body = model.encode_set_webhook_parameters(parameters)

  new_post_request(client:, path: "setWebhook", body: json.to_string(body))
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get current webhook status.
///
/// **Official reference:** https://core.telegram.org/bots/api#getwebhookinfo
pub fn get_webhook_info(client client) {
  new_get_request(client:, path: "getWebhookInfo", query: None)
  |> fetch(client)
  |> map_response(model.webhook_info_decoder())
}

/// Use this method to remove webhook integration if you decide to switch back to [getUpdates](https://core.telegram.org/bots/api#getupdates).
///
/// **Official reference:** https://core.telegram.org/bots/api#deletewebhook
pub fn delete_webhook(client client) {
  new_get_request(client:, path: "deleteWebhook", query: None)
  |> fetch(client)
  |> map_response(decode.bool)
}

/// The same as [delete_webhook](#delete_webhook) but also drops all pending updates.
pub fn delete_webhook_and_drop_updates(client client) {
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
pub fn log_out(client client) {
  new_get_request(client:, path: "logOut", query: None)
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to close the bot instance before moving it from one local server to another.
/// You need to delete the webhook before calling this method to ensure that the bot isn't launched again after server restart.
/// The method will return error 429 in the first 10 minutes after the bot is launched.
///
/// **Official reference:** https://core.telegram.org/bots/api#close
pub fn close(client client) {
  new_get_request(client:, path: "close", query: None)
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to send text messages with additional parameters.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn send_message(client client, parameters parameters) {
  let body_json = model.encode_send_message_parameters(parameters)

  new_post_request(
    client:,
    path: "sendMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to change the list of the bot's commands. See [commands documentation](https://core.telegram.org/bots/features#commands) for more details about bot commands.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmycommands
pub fn set_my_commands(
  client client,
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
pub fn delete_my_commands(client client, parameters parameters) {
  let parameters =
    option.unwrap(parameters, model.default_bot_command_parameters())
    |> model.encode_bot_command_parameters()

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
pub fn get_my_commands(client client, parameters parameters) {
  let parameters =
    option.unwrap(parameters, model.default_bot_command_parameters())
    |> model.encode_bot_command_parameters

  let body_json = json.object(parameters)

  new_post_request(
    client:,
    path: "getMyCommands",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.bot_command_decoder())
}

/// Use this method to send an animated emoji that will display a random value.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddice
pub fn send_dice(client client, parameters parameters) {
  let body_json = model.encode_send_dice_parameters(parameters)

  new_post_request(client:, path: "sendDice", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// A simple method for testing your bot's authentication token.
///
/// **Official reference:** https://core.telegram.org/bots/api#getme
pub fn get_me(client client) {
  new_get_request(client:, path: "getMe", query: None)
  |> fetch(client)
  |> map_response(model.user_decoder())
}

/// Use this method to send answers to callback queries sent from [inline keyboards](https://core.telegram.org/bots/features#inline-keyboards).
/// The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
/// On success, _True_ is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#answercallbackquery
pub fn answer_callback_query(client client, parameters parameters) {
  let body_json = model.encode_answer_callback_query_parameters(parameters)

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
pub fn forward_message(client client, parameters parameters) {
  let body_json = model.encode_forward_message_parameters(parameters)

  new_post_request(
    client:,
    path: "forwardMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to change the bot's menu button in a private chat, or the default menu button. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchatmenubutton
pub fn set_chat_menu_button(client client, parameters parameters) {
  new_post_request(
    client:,
    path: "setChatMenuButton",
    body: model.encode_set_chat_menu_button_parameters(parameters)
      |> json.to_string(),
  )
  |> fetch(client)
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
  client client,
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
  new_get_request(client:, path: "getUpdates", query:)
  |> fetch(client)
  |> map_response(decode.list(model.update_decoder()))
}

/// Use this method to forward multiple messages of any kind. If some of the specified messages can't be found or forwarded, they are skipped. Service messages and messages with protected content can't be forwarded. Album grouping is kept for forwarded messages. On success, an array of [MessageId](https://core.telegram.org/bots/api#messageid) of the sent messages is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessages
pub fn forward_messages(client client, parameters parameters) {
  let body_json = model.encode_forward_messages_parameters(parameters)

  new_post_request(
    client:,
    path: "forwardMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to copy messages of any kind. Service messages, paid media messages, giveaway messages, giveaway winners messages, and invoice messages can't be copied. A quiz [poll](https://core.telegram.org/bots/api#poll) can be copied only if the value of the field correct_option_id is known to the bot. The method is analogous to the method [forwardMessage](https://core.telegram.org/bots/api#forwardmessage), but the copied message doesn't have a link to the original message. Returns the [MessageId](https://core.telegram.org/bots/api#messageid) of the sent message on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#copymessage
pub fn copy_message(client client, parameters parameters) {
  let body_json = model.encode_copy_message_parameters(parameters)

  new_post_request(
    client:,
    path: "copyMessage",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to copy messages of any kind. If some of the specified messages can't be found or copied, they are skipped. Service messages, paid media messages, giveaway messages, giveaway winners messages, and invoice messages can't be copied. A quiz [poll](https://core.telegram.org/bots/api#poll) can be copied only if the value of the field correct_option_id is known to the bot. The method is analogous to the method [forwardMessage](https://core.telegram.org/bots/api#forwardmessage), but the copied message doesn't have a link to the original message. Returns the [MessageId](https://core.telegram.org/bots/api#messageid) of the sent message on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#copymessages
pub fn copy_messages(client client, parameters parameters) {
  let body_json = model.encode_copy_messages_parameters(parameters)

  new_post_request(
    client:,
    path: "copyMessages",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send photos. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendphoto
pub fn send_photo(client client, parameters parameters) {
  let body_json = model.encode_send_photo_parameters(parameters)

  new_post_request(client:, path: "sendPhoto", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send audio files, if you want Telegram clients to display them in the music player. Your audio must be in the .MP3 or .M4A format. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send audio files of up to 50 MB in size, this limit may be changed in the future.
///
/// For sending voice messages, use the [sendVoice](https://core.telegram.org/bots/api#sendvoice) method instead.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendaudio
pub fn send_audio(client client, parameters parameters) {
  let body_json = model.encode_send_audio_parameters(parameters)

  new_post_request(client:, path: "sendAudio", body: json.to_string(body_json))
  |> fetch(client)
}

/// Use this method to send general files. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send files of any type of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddocument
pub fn send_document(client client, parameters parameters) {
  let body_json = model.encode_send_document_parameters(parameters)

  new_post_request(
    client:,
    path: "sendDocument",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send video files, Telegram clients support MPEG4 videos (other formats may be sent as Document). On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send video files of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvideo
pub fn send_video(client client, parameters parameters) {
  let body_json = model.encode_send_video_parameters(parameters)

  new_post_request(client:, path: "sendVideo", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send animation files (GIF or H.264/MPEG-4 AVC video without sound). On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send animation files of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendanimation
pub fn send_animation(client client, parameters parameters) {
  let body_json = model.encode_send_animation_parameters(parameters)

  new_post_request(
    client:,
    path: "sendAnimation",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send audio files, if you want Telegram clients to display the file as a playable voice message. For this to work, your audio must be in an .ogg file encoded with OPUS (other formats may be sent as Audio or Document). On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned. Bots can currently send voice messages of up to 50 MB in size, this limit may be changed in the future.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvoice
pub fn send_voice(client client, parameters parameters) {
  let body_json = model.encode_send_voice_parameters(parameters)

  new_post_request(client:, path: "sendVoice", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send video messages. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvideonote
pub fn send_video_note(client client, parameters parameters) {
  let body_json = model.encode_send_video_note_parameters(parameters)

  new_post_request(
    client:,
    path: "sendVideoNote",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send a group of photos, videos, documents or audio files as an album. Documents and audio files can be only grouped in an album with the first item having a filename. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmediagroup
pub fn send_media_group(client client, parameters parameters) {
  let body_json = model.encode_send_media_group_parameters(parameters)

  new_post_request(
    client:,
    path: "sendMediaGroup",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send point on the map. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendlocation
pub fn send_location(client client, parameters parameters) {
  let body_json = model.encode_send_location_parameters(parameters)

  new_post_request(
    client:,
    path: "sendLocation",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send information about a venue. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendvenue
pub fn send_venue(client client, parameters parameters) {
  let body_json = model.encode_send_venue_parameters(parameters)

  new_post_request(client:, path: "sendVenue", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send phone contacts. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendcontact
pub fn send_contact(client client, parameters parameters) {
  let body_json = model.encode_send_contact_parameters(parameters)

  new_post_request(
    client:,
    path: "sendContact",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send a native poll. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendpoll
pub fn send_poll(client client, parameters parameters) {
  let body_json = model.encode_send_poll_parameters(parameters)

  new_post_request(client:, path: "sendPoll", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method when you need to tell the user that something is happening on the bot's side. The status is set for 5 seconds or less (when a message arrives from your bot, Telegram clients clear its typing status). Returns True on success.
///
/// > Example: The [ImageBot](https://t.me/imagebot) needs some time to process a request and upload the image. Instead of sending a text message along the lines of “Retrieving image, please wait…”, the bot may use [sendChatAction](https://core.telegram.org/bots/api#sendchataction) with action = upload_photo. The user will see a “sending photo” status for the bot.
///
/// We only recommend using this method when a response from the bot will take a noticeable amount of time to arrive.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendchataction
pub fn send_chat_action(client client, parameters parameters) {
  let body_json = model.encode_send_chat_action_parameters(parameters)

  new_post_request(
    client:,
    path: "sendChatAction",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to send invoices. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendinvoice
pub fn send_invoice(client client, parameters parameters) {
  let body_json = model.encode_send_invoice_parameters(parameters)

  new_post_request(
    client:,
    path: "sendInvoice",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to create a link for an invoice.
///
/// **Official reference:** https://core.telegram.org/bots/api#createinvoicelink
pub fn create_invoice_link(client client, parameters parameters) {
  let body_json = model.encode_create_invoice_link_parameters(parameters)

  new_post_request(
    client,
    path: "createInvoiceLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.string)
}

/// Use this method to change the chosen reactions on a message. Service messages of some types can't be reacted to. Automatically forwarded messages from a channel to its discussion group have the same available reactions as messages in the channel. Bots can't use paid reactions. Returns _True_ on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmessagereaction
pub fn set_message_reaction(client client, parameters parameters) {
  let body_json = model.encode_set_message_reaction_parameters(parameters)

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
pub fn get_user_profile_photos(client client, parameters parameters) {
  let body_json = model.encode_get_user_profile_photos_parameters(parameters)

  new_post_request(
    client:,
    path: "getUserProfilePhotos",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.user_profile_photos_decoder())
}

/// Use this method to send static .WEBP, [animated](https://telegram.org/blog/animated-stickers) .TGS, or [video](https://telegram.org/blog/video-stickers-better-reactions/ru?ln=a) .WEBM stickers. On success, the sent [Message](https://core.telegram.org/bots/api#message) is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendsticker
pub fn send_sticker(client client, parameters parameters) {
  let body_json = model.encode_send_sticker_parameters(parameters)

  new_post_request(
    client:,
    path: "sendSticker",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to get a sticker set. On success, a [StickerSet](https://core.telegram.org/bots/api#stickerset) object is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#getstickerset
pub fn get_sticker_set(client client, parameters parameters) {
  let body_json = model.encode_get_sticker_set_parameters(parameters)

  new_post_request(
    client:,
    path: "getStickerSet",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.sticker_set_decoder())
}

/// Use this method to edit text and game messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api#message) is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagetext
pub fn edit_message_text(client client, parameters parameters) {
  let body_json = model.encode_edit_message_text_parameters(parameters)

  new_post_request(
    client:,
    path: "editMessageText",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to edit captions of messages. On success, if the edited message is not an inline message, the edited [Message](https://core.telegram.org/bots/api#message) is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagecaption
pub fn edit_message_caption(client client, parameters parameters) {
  let body_json = model.encode_edit_message_caption_parameters(parameters)

  new_post_request(
    client:,
    path: "editMessageCaption",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to edit animation, audio, document, photo, or video messages, or to add media to text messages. If a message is part of a message album, then it can be edited only to an audio for audio albums, only to a document for document albums and to a photo or a video otherwise. When an inline message is edited, a new file can't be uploaded; use a previously uploaded file via its file_id or specify a URL. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagemedia
pub fn edit_message_media(client client, parameters parameters) {
  let body_json = model.encode_edit_message_media_parameters(parameters)

  new_post_request(
    client:,
    path: "editMessageMedia",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to edit live location messages. A location can be edited until its live_period expires or editing is explicitly disabled by a call to stopMessageLiveLocation. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagelivelocation
pub fn edit_message_live_location(client client, parameters parameters) {
  let body_json = model.encode_edit_message_live_location_parameters(parameters)

  new_post_request(
    client:,
    path: "editMessageLiveLocation",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to stop updating a live location message before live_period expires. On success, if the message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#stopmessagelivelocation
pub fn stop_message_live_location(client client, parameters parameters) {
  let body_json = model.encode_stop_message_live_location_parameters(parameters)

  new_post_request(
    client:,
    path: "stopMessageLiveLocation",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to edit only the reply markup of messages. On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned. Note that business messages that were not sent by the bot and do not contain an inline keyboard can only be edited within 48 hours from the time they were sent.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagereplymarkup
pub fn edit_message_reply_markup(client client, parameters parameters) {
  let body_json = model.encode_edit_message_reply_markup_parameters(parameters)

  new_post_request(
    client:,
    path: "editMessageReplyMarkup",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.message_decoder())
}

/// Use this method to stop a poll which was sent by the bot. On success, the stopped Poll is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#stoppoll
pub fn stop_poll(client client, parameters parameters) {
  let body_json = model.encode_stop_poll_parameters(parameters)

  new_post_request(client:, path: "stopPoll", body: json.to_string(body_json))
  |> fetch(client)
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
pub fn delete_message(client client, parameters parameters) {
  let body_json = model.encode_delete_message_parameters(parameters)

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
pub fn delete_messages(client client, parameters parameters) {
  let body_json = model.encode_delete_messages_parameters(parameters)

  new_post_request(
    client:,
    path: "deleteMessages",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get up-to-date information about the chat. Returns a [ChatFullInfo](https://core.telegram.org/bots/api#chatfullinfo) object on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getchat
pub fn get_chat(client client, chat_id chat_id) {
  new_get_request(client, path: "getChat", query: Some([#("chat_id", chat_id)]))
  |> fetch(client)
  |> map_response(model.chat_full_info_decoder())
}

/// Use this method to get basic information about a file and prepare it for downloading. For the moment, bots can download files of up to 20MB in size. On success, a File object is returned. The file can then be downloaded via the link `https://api.telegram.org/file/bot<token>/<file_path>`, where `<file_path>` is taken from the response. It is guaranteed that the link will be valid for at least 1 hour. When the link expires, a new one can be requested by calling getFile again.
///
/// **Official reference:** https://core.telegram.org/bots/api#getfile
pub fn get_file(client client, file_id file_id) {
  new_get_request(client, path: "getFile", query: Some([#("file_id", file_id)]))
  |> fetch(client)
  |> map_response(model.file_decoder())
}

/// Use this method to ban a user in a group, a supergroup or a channel. In the case of supergroups and channels, the user will not be able to return to the chat on their own using invite links, etc., unless unbanned first. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#banchatmember
pub fn ban_chat_member(client client, parameters parameters) {
  let body_json = model.encode_ban_chat_member_parameters(parameters)

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
pub fn unban_chat_member(client client, parameters parameters) {
  let body_json = model.encode_unban_chat_member_parameters(parameters)

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
pub fn restrict_chat_member(client client, parameters parameters) {
  let body_json = model.encode_restrict_chat_member_parameters(parameters)

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
pub fn promote_chat_member(client client, parameters parameters) {
  let body_json = model.encode_promote_chat_member_parameters(parameters)

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
pub fn set_chat_administrator_custom_title(client client, parameters parameters) {
  let body_json =
    model.encode_set_chat_administrator_custom_title_parameters(parameters)

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
pub fn ban_chat_sender_chat(client client, parameters parameters) {
  let body_json = model.encode_ban_chat_sender_chat_parameters(parameters)

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
pub fn unban_chat_sender_chat(client client, parameters parameters) {
  let body_json = model.encode_unban_chat_sender_chat_parameters(parameters)

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
pub fn set_chat_permissions(client client, parameters parameters) {
  let body_json = model.encode_set_chat_permissions_parameters(parameters)

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
pub fn export_chat_invite_link(client client, parameters parameters) {
  let body_json = model.encode_export_chat_invite_link_parameters(parameters)

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
pub fn create_chat_invite_link(client client, parameters parameters) {
  let body_json = model.encode_create_chat_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "createChatInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.chat_invite_link_decoder())
}

/// Use this method to edit a non-primary invite link created by the bot. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns the edited invite link as a [ChatInviteLink](https://core.telegram.org/bots/api#chatinvitelink) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#editchatinvitelink
pub fn edit_chat_invite_link(client client, parameters parameters) {
  let body_json = model.encode_edit_chat_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "editChatInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.chat_invite_link_decoder())
}

/// Use this method to create a [subscription invite link](https://core.telegram.org/bots/api#chatinvitelink) for a channel chat. The bot must have the `can_invite_users` administrator rights. The link can be edited using the method [editChatSubscriptionInviteLink](https://core.telegram.org/bots/api#editchatsubscriptioninvitelink) or revoked using the method [revokeChatInviteLink](https://core.telegram.org/bots/api#revokechatinvitelink). Returns the new invite link as a [ChatInviteLink](https://core.telegram.org/bots/api#chatinvitelink) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#createchatsubscriptioninvitelink
pub fn create_chat_subscription_invite_link(
  client client,
  parameters parameters,
) {
  let body_json =
    model.encode_create_chat_subscription_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "createChatSubscriptionInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.chat_invite_link_decoder())
}

/// Use this method to edit a subscription invite link created by the bot. The bot must have the can_invite_users administrator rights. Returns the edited invite link as a [ChatInviteLink](https://core.telegram.org/bots/api#chatinvitelink) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#editchatsubscriptioninvitelink
pub fn edit_chat_subscription_invite_link(client client, parameters parameters) {
  let body_json =
    model.encode_edit_chat_subscription_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "editChatSubscriptionInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.chat_invite_link_decoder())
}

/// Use this method to revoke an invite link created by the bot. If the primary link is revoked, a new link is automatically generated. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Returns the revoked invite link as [ChatInviteLink](https://core.telegram.org/bots/api#chatinvitelink) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#revokechatinvitelink
pub fn revoke_chat_invite_link(client client, parameters parameters) {
  let body_json = model.encode_revoke_chat_invite_link_parameters(parameters)

  new_post_request(
    client:,
    path: "revokeChatInviteLink",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.chat_invite_link_decoder())
}

/// Use this method to approve a chat join request. The bot must be an administrator in the chat for this to work and must have the `can_invite_users` administrator right. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#approvechatjoinrequest
pub fn approve_chat_join_request(client client, parameters parameters) {
  let body_json = model.encode_approve_chat_join_request_parameters(parameters)

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
pub fn decline_chat_join_request(client client, parameters parameters) {
  let body_json = model.encode_decline_chat_join_request_parameters(parameters)

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
pub fn set_chat_photo(client client, parameters parameters) {
  let body_json = model.encode_set_chat_photo_parameters(parameters)

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
pub fn delete_chat_photo(client client, parameters parameters) {
  let body_json = model.encode_delete_chat_photo_parameters(parameters)

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
pub fn set_chat_title(client client, parameters parameters) {
  let body_json = model.encode_set_chat_title_parameters(parameters)

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
pub fn set_chat_description(client client, parameters parameters) {
  let body_json = model.encode_set_chat_description_parameters(parameters)

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
pub fn pin_chat_message(client client, parameters parameters) {
  let body_json = model.encode_pin_chat_message_parameters(parameters)

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
pub fn unpin_chat_message(client client, parameters parameters) {
  let body_json = model.encode_unpin_chat_message_parameters(parameters)

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
pub fn unpin_all_chat_messages(client client, parameters parameters) {
  let body_json = model.encode_unpin_all_chat_messages_parameters(parameters)

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
pub fn leave_chat(client client, parameters parameters) {
  let body_json = model.encode_leave_chat_parameters(parameters)

  new_post_request(client:, path: "leaveChat", body: json.to_string(body_json))
  |> fetch(client)
  |> map_response(decode.bool)
}

/// Use this method to get a list of administrators in a chat, which aren't bots. Returns an Array of [ChatMember](https://core.telegram.org/bots/api#chatmember) objects.
///
/// **Official reference:** https://core.telegram.org/bots/api#getchatadministrators
pub fn get_chat_administrators(client client, parameters parameters) {
  let body_json = model.encode_get_chat_administrators_parameters(parameters)

  new_post_request(
    client:,
    path: "getChatAdministrators",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(decode.list(model.chat_member_decoder()))
}

/// Use this method to get the number of members in a chat. Returns `Int` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#getchatmembercount
pub fn get_chat_member_count(client client, parameters parameters) {
  let body_json = model.encode_get_chat_member_count_parameters(parameters)

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
pub fn get_chat_member(client client, parameters parameters) {
  let body_json = model.encode_get_chat_member_parameters(parameters)

  new_post_request(
    client:,
    path: "getChatMember",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.chat_member_decoder())
}

/// Use this method to set a new group sticker set for a supergroup. The bot must be an administrator in the chat for this to work and must have the appropriate administrator rights. Use the field `can_set_sticker_set` optionally returned in `getChat` requests to check if the bot can use this method. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchatstickerset
pub fn set_chat_sticker_set(client client, parameters parameters) {
  let body_json = model.encode_set_chat_sticker_set_parameters(parameters)

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
pub fn delete_chat_sticker_set(client client, parameters parameters) {
  let body_json = model.encode_delete_chat_sticker_set_parameters(parameters)

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
pub fn get_forum_topic_icon_stickers(client client) {
  new_get_request(client:, path: "getForumTopicIconStickers", query: None)
  |> fetch(client)
  |> map_response(decode.list(model.sticker_decoder()))
}

/// Use this method to create a topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights. Returns information about the created topic as a [ForumTopic](https://core.telegram.org/bots/api#forumtopic) object.
///
/// **Official reference:** https://core.telegram.org/bots/api#createforumtopic
pub fn create_forum_topic(client client, parameters parameters) {
  let body_json = model.encode_create_forum_topic_parameters(parameters)

  new_post_request(
    client:,
    path: "createForumTopic",
    body: json.to_string(body_json),
  )
  |> fetch(client)
  |> map_response(model.forum_topic_decoder())
}

/// Use this method to edit name and icon of a topic in a forum supergroup chat. The bot must be an administrator in the chat for this to work and must have the `can_manage_topics` administrator rights, unless it is the creator of the topic. Returns `True` on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#editforumtopic
pub fn edit_forum_topic(client client, parameters parameters) {
  let body_json = model.encode_edit_forum_topic_parameters(parameters)

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
pub fn close_forum_topic(client client, parameters parameters) {
  let body_json = model.encode_close_forum_topic_parameters(parameters)

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
pub fn reopen_forum_topic(client client, parameters parameters) {
  let body_json = model.encode_reopen_forum_topic_parameters(parameters)

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
pub fn delete_forum_topic(client client, parameters parameters) {
  let body_json = model.encode_delete_forum_topic_parameters(parameters)

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
  client client,
  parameters parameters,
) {
  let body_json =
    model.encode_unpin_all_forum_topic_messages_parameters(parameters)

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
pub fn edit_general_forum_topic(client client, parameters parameters) {
  let body_json = model.encode_edit_general_forum_topic_parameters(parameters)

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
pub fn close_general_forum_topic(client client, parameters parameters) {
  let body_json = model.encode_close_general_forum_topic_parameters(parameters)

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
pub fn reopen_general_forum_topic(client client, parameters parameters) {
  let body_json = model.encode_reopen_general_forum_topic_parameters(parameters)

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
pub fn hide_general_forum_topic(client client, parameters parameters) {
  let body_json = model.encode_hide_general_forum_topic_parameters(parameters)

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
pub fn unhide_general_forum_topic(client client, parameters parameters) {
  let body_json = model.encode_unhide_general_forum_topic_parameters(parameters)

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
/// **Official reference:** https://core.telegram.org/bots/api#unpinallgeneralforumtopicpinnedmessages
pub fn unpin_all_general_forum_topic_pinned_messages(
  client client,
  parameters parameters,
) {
  let body_json =
    model.encode_unpin_all_forum_topic_messages_parameters(parameters)

  new_post_request(
    client:,
    path: "unpinAllGeneralForumTopicPinnedMessages",
    body: json.to_string(body_json),
  )
  |> fetch(client)
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
