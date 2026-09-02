//// `reply` provides a convenient way to send messages to the active chat.
//// It uses the `Context` object to access the chat ID and other necessary information.
////
//// ## Ephemeral messages (Bot API 10.3)
////
//// In a group chat a message can be addressed to a single user — nobody else
//// sees it. `with_ephemeral_text` and `with_ephemeral_markup` aim at the user
//// of the current update, wiring `callback_query_id` in when that update is a
//// callback query, so the message appears under the pressed button:
////
//// ```gleam
//// let assert Ok(_) = reply.with_ephemeral_text(ctx, "Booked — only you see this")
//// ```
////
//// `with_ephemeral` takes explicit parameters instead, built with
//// `ephemeral_parameters` or `types.new_ephemeral_message_parameters`:
////
//// ```gleam
//// reply.with_ephemeral(
////   ctx:,
////   text: "Shown in place of the original message",
////   parameters: types.EphemeralMessageParameters(
////     ..reply.ephemeral_parameters(ctx),
////     replace_callback_query_message: Some(True),
////   ),
//// )
//// ```
////
//// Every `send*` parameter record carries the same optional
//// `ephemeral_message_parameters` field, so photos, videos, stickers and the
//// rest can be ephemeral too:
////
//// ```gleam
//// api.send_photo(
////   client,
////   parameters: types.SendPhotoParameters(
////     ..parameters,
////     ephemeral_message_parameters: Some(reply.ephemeral_parameters(ctx)),
////   ),
//// )
//// ```
////
//// The sent `Message` carries an `ephemeral_message_id`; pass it to
//// `api.edit_ephemeral_message_*` / `api.delete_ephemeral_message` to change or
//// remove the message later. Under `handle_bot_with_reply` the first eligible
//// send of an update is answered through the webhook response itself and comes
//// back as a stub `Message` without that id — wrap such a call in
//// `webhook_reply.without_claim` when you need the real one.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

import telega/api
import telega/bot.{type Context}
import telega/client
import telega/error
import telega/file
import telega/format.{type FormattedText}
import telega/model/types.{
  type AnswerCallbackQueryParameters, type EditMessageTextParameters,
  type EphemeralMessageParameters, type FileOrString,
  type ForwardMessageParameters, type InputMedia, type InputPaidMedia,
  type Message, type SendDiceParameters, type SendMessageReplyMarkupParameters,
  EditMessageTextParameters, EphemeralMessageParameters, LabeledPrice,
  SendDiceParameters, SendInvoiceParameters, SendMediaGroupParameters,
  SendMessageParameters, SendPaidMediaParameters, SendPhotoParameters,
  SendPollParameters, SendStickerParameters,
}
import telega/update

/// Use this method to send text messages.
///
/// Uses the client's default parse mode if one is configured
/// via `client.set_default_parse_mode`.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_text(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      text:,
      chat_id: types.Int(ctx.update.chat_id),
      business_connection_id: None,
      message_thread_id: None,
      parse_mode: client.default_parse_mode_string(ctx.config.api_client),
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      message_effect_id: None,
      allow_paid_broadcast: None,
      reply_parameters: None,
      reply_markup: None,
      ephemeral_message_parameters: None,
    ),
  )
}

/// Use this method to send text messages with keyboard markup.
///
/// Uses the client's default parse mode if one is configured
/// via `client.set_default_parse_mode`.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_markup(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
  markup reply_markup: SendMessageReplyMarkupParameters,
) -> Result(Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      text:,
      chat_id: types.Int(ctx.update.chat_id),
      reply_markup: Some(reply_markup),
      business_connection_id: None,
      message_thread_id: None,
      parse_mode: client.default_parse_mode_string(ctx.config.api_client),
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      reply_parameters: None,
      message_effect_id: None,
      allow_paid_broadcast: None,
      ephemeral_message_parameters: None,
    ),
  )
}

/// Use this method to send formatted text messages.
///
/// ## Example
/// ```gleam
/// let formatted = format.build()
///   |> format.bold_text("Important!")
///   |> format.to_formatted()
/// reply.with_formatted(ctx, formatted)
/// ```
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_formatted(
  ctx ctx: Context(session, error, dependencies),
  formatted formatted: FormattedText,
) -> Result(Message, error.TelegaError) {
  let #(text, parse_mode) = format.render(formatted)

  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      text:,
      chat_id: types.Int(ctx.update.chat_id),
      parse_mode: Some(format.parse_mode_to_string(parse_mode)),
      business_connection_id: None,
      message_thread_id: None,
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      message_effect_id: None,
      allow_paid_broadcast: None,
      reply_parameters: None,
      reply_markup: None,
      ephemeral_message_parameters: None,
    ),
  )
}

/// Use this method to send HTML formatted text messages.
///
/// ## Example
/// ```gleam
/// let html = format.bold("Hello") <> " " <> format.italic("World")
/// reply.with_html(ctx, html)
/// ```
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_html(
  ctx ctx: Context(session, error, dependencies),
  html html: String,
) -> Result(Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      text: html,
      chat_id: types.Int(ctx.update.chat_id),
      parse_mode: Some("HTML"),
      business_connection_id: None,
      message_thread_id: None,
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      message_effect_id: None,
      allow_paid_broadcast: None,
      reply_parameters: None,
      reply_markup: None,
      ephemeral_message_parameters: None,
    ),
  )
}

/// Use this method to send Markdown formatted text messages.
///
/// ## Example
/// ```gleam
/// reply.with_markdown(ctx, "*Bold* _Italic_")
/// ```
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_markdown(
  ctx ctx: Context(session, error, dependencies),
  markdown markdown: String,
) -> Result(Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      text: markdown,
      chat_id: types.Int(ctx.update.chat_id),
      parse_mode: Some("Markdown"),
      business_connection_id: None,
      message_thread_id: None,
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      message_effect_id: None,
      allow_paid_broadcast: None,
      reply_parameters: None,
      reply_markup: None,
      ephemeral_message_parameters: None,
    ),
  )
}

/// Use this method to send MarkdownV2 formatted text messages.
///
/// ## Example
/// ```gleam
/// reply.with_markdown_v2(ctx, "*Bold* _Italic_ __Underline__")
/// ```
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_markdown_v2(
  ctx ctx: Context(session, error, dependencies),
  markdown markdown: String,
) -> Result(Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      text: markdown,
      chat_id: types.Int(ctx.update.chat_id),
      parse_mode: Some("MarkdownV2"),
      business_connection_id: None,
      message_thread_id: None,
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      message_effect_id: None,
      allow_paid_broadcast: None,
      reply_parameters: None,
      reply_markup: None,
      ephemeral_message_parameters: None,
    ),
  )
}

/// Use this method to send formatted text messages with keyboard markup.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_formatted_markup(
  ctx ctx: Context(session, error, dependencies),
  formatted formatted: FormattedText,
  markup reply_markup: SendMessageReplyMarkupParameters,
) -> Result(Message, error.TelegaError) {
  let #(text, parse_mode) = format.render(formatted)

  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      text:,
      chat_id: types.Int(ctx.update.chat_id),
      parse_mode: Some(format.parse_mode_to_string(parse_mode)),
      reply_markup: Some(reply_markup),
      business_connection_id: None,
      message_thread_id: None,
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      message_effect_id: None,
      allow_paid_broadcast: None,
      reply_parameters: None,
      ephemeral_message_parameters: None,
    ),
  )
}

/// Use this method to send an animated emoji that will display a random value.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddice
pub fn with_dice(
  ctx ctx: Context(session, error, dependencies),
  parameters parameters: Option(SendDiceParameters),
) -> Result(Message, error.TelegaError) {
  let parameters =
    parameters
    |> option.lazy_unwrap(fn() {
      SendDiceParameters(
        chat_id: types.Int(ctx.update.chat_id),
        message_thread_id: None,
        emoji: None,
        disable_notification: None,
        protect_content: None,
        reply_parameters: None,
      )
    })

  api.send_dice(ctx.config.api_client, parameters)
}

/// Use this method to send a photo — by `file_id`, URL, or upload.
///
/// The caption uses the client's default parse mode if one is configured
/// via `client.set_default_parse_mode`.
///
/// ## Example
/// ```gleam
/// reply.with_photo(ctx, types.StringV("https://example.com/cat.jpg"), Some("A cat"))
/// ```
///
/// **Official reference:** https://core.telegram.org/bots/api#sendphoto
pub fn with_photo(
  ctx ctx: Context(session, error, dependencies),
  photo photo: FileOrString,
  caption caption: Option(String),
) -> Result(Message, error.TelegaError) {
  api.send_photo(
    ctx.config.api_client,
    parameters: SendPhotoParameters(
      chat_id: types.Int(ctx.update.chat_id),
      photo:,
      caption:,
      parse_mode: option.then(caption, fn(_) {
        client.default_parse_mode_string(ctx.config.api_client)
      }),
      business_connection_id: None,
      message_thread_id: None,
      caption_entities: None,
      show_caption_above_media: None,
      has_spoiler: None,
      disable_notification: None,
      protect_content: None,
      allow_paid_broadcast: None,
      message_effect_id: None,
      reply_parameters: None,
      reply_markup: None,
      ephemeral_message_parameters: None,
    ),
  )
}

/// Send a photo to the active chat by uploading raw `bytes`
/// (`multipart/form-data`) — for art the bot holds in memory / object storage
/// but has never sent before, so there is no `file_id` yet. The returned
/// `Message`'s largest `PhotoSize` carries the new `file_id`; cache it and reuse
/// `with_photo` (a plain JSON send) next time.
///
/// If `caption` is `Some`, the client's default parse mode (if configured) is
/// applied, matching `with_photo`.
pub fn with_photo_bytes(
  ctx ctx: Context(session, error, dependencies),
  bytes bytes: BitArray,
  filename filename: String,
  content_type content_type: String,
  caption caption: Option(String),
) -> Result(Message, error.TelegaError) {
  api.send_photo_bytes(
    ctx.config.api_client,
    chat_id: int.to_string(ctx.update.chat_id),
    content: bytes,
    filename:,
    content_type:,
    caption:,
    parse_mode: option.then(caption, fn(_) {
      client.default_parse_mode_string(ctx.config.api_client)
    }),
  )
}

/// Use this method to edit text and game messages.
/// On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// If `parameters.parse_mode` is `None`, the client's default parse mode
/// (set via `client.set_default_parse_mode`) is used.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagetext
pub fn edit_text(
  ctx ctx: Context(session, error, dependencies),
  parameters parameters: EditMessageTextParameters,
) -> Result(Message, error.TelegaError) {
  let parameters = case parameters.parse_mode {
    None ->
      EditMessageTextParameters(
        ..parameters,
        parse_mode: client.default_parse_mode_string(ctx.config.api_client),
      )
    Some(_) -> parameters
  }
  api.edit_message_text(ctx.config.api_client, parameters)
}

/// Use this method to edit formatted text messages.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagetext
pub fn edit_text_formatted(
  ctx ctx: Context(session, error, dependencies),
  message_id message_id: Int,
  formatted formatted: FormattedText,
) -> Result(Message, error.TelegaError) {
  let #(text, parse_mode) = format.render(formatted)

  let parameters =
    EditMessageTextParameters(
      text:,
      message_id: Some(message_id),
      parse_mode: Some(format.parse_mode_to_string(parse_mode)),
      chat_id: Some(types.Int(ctx.update.chat_id)),
      reply_markup: None,
      entities: None,
      link_preview_options: None,
      inline_message_id: None,
    )

  api.edit_message_text(ctx.config.api_client, parameters)
}

/// Use this method to forward messages of any kind. Service messages and messages with protected content can't be forwarded.
/// On success, the sent Message is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessage
pub fn forward(
  ctx ctx: Context(session, error, dependencies),
  parameters parameters: ForwardMessageParameters,
) -> Result(Message, error.TelegaError) {
  api.forward_message(ctx.config.api_client, parameters)
}

/// Ephemeral parameters aimed at the user of the current update (Bot API 10.3).
///
/// When the update is a callback query, its id is wired in, so Telegram can
/// attach the ephemeral message to the pressed button. Adjust the result with
/// a record update to show the message in place of the original one:
///
/// ```gleam
/// types.EphemeralMessageParameters(
///   ..reply.ephemeral_parameters(ctx),
///   replace_callback_query_message: Some(True),
/// )
/// ```
pub fn ephemeral_parameters(
  ctx ctx: Context(session, error, dependencies),
) -> EphemeralMessageParameters {
  let parameters =
    types.new_ephemeral_message_parameters(receiver_user_id: ctx.update.from_id)

  case ctx.update {
    update.CallbackQueryUpdate(query:, ..) ->
      EphemeralMessageParameters(
        ..parameters,
        callback_query_id: Some(query.id),
      )
    _ -> parameters
  }
}

/// Use this method to send a text message that only one user of the chat sees
/// (Bot API 10.3). Ephemeral messages work in group chats only; in private
/// chats use `with_text`.
///
/// The message is aimed at the user of the current update — see
/// `ephemeral_parameters` for finer control, and pass the result to
/// `with_ephemeral`.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_ephemeral_text(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Message, error.TelegaError) {
  with_ephemeral(ctx:, text:, parameters: ephemeral_parameters(ctx))
}

/// Use this method to send an ephemeral text message with explicit
/// `EphemeralMessageParameters` (Bot API 10.3).
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_ephemeral(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
  parameters ephemeral_message_parameters: EphemeralMessageParameters,
) -> Result(Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      text:,
      chat_id: types.Int(ctx.update.chat_id),
      ephemeral_message_parameters: Some(ephemeral_message_parameters),
      business_connection_id: None,
      message_thread_id: None,
      parse_mode: client.default_parse_mode_string(ctx.config.api_client),
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      message_effect_id: None,
      allow_paid_broadcast: None,
      reply_parameters: None,
      reply_markup: None,
    ),
  )
}

/// Use this method to send an ephemeral text message with keyboard markup
/// (Bot API 10.3).
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_ephemeral_markup(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
  markup reply_markup: SendMessageReplyMarkupParameters,
) -> Result(Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      text:,
      chat_id: types.Int(ctx.update.chat_id),
      reply_markup: Some(reply_markup),
      ephemeral_message_parameters: Some(ephemeral_parameters(ctx)),
      business_connection_id: None,
      message_thread_id: None,
      parse_mode: client.default_parse_mode_string(ctx.config.api_client),
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      message_effect_id: None,
      allow_paid_broadcast: None,
      reply_parameters: None,
    ),
  )
}

/// Use this method to send answers to callback queries sent from inline keyboards.
/// The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
/// On success, _True_ is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#answercallbackquery
pub fn answer_callback_query(
  ctx ctx: Context(session, error, dependencies),
  parameters parameters: AnswerCallbackQueryParameters,
) -> Result(Bool, error.TelegaError) {
  api.answer_callback_query(ctx.config.api_client, parameters)
}

/// Get download link for the file.
///
/// The link embeds the bot token: it grants access to every file of the bot,
/// so keep it server-side instead of sending it to a user.
pub fn with_file_link(
  ctx ctx: Context(session, error, dependencies),
  file_id file_id: String,
) -> Result(String, error.TelegaError) {
  use file <- result.try(api.get_file(ctx.config.api_client, file_id))
  use file_path <- result.try(option.to_result(
    file.file_path,
    error.FileNotFoundError,
  ))

  Ok(file.file_url(ctx.config.api_client, file_path))
}

/// Use this method to send a native poll.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendpoll
pub fn with_poll(
  ctx ctx: Context(session, error, dependencies),
  question question: String,
  options options: List(String),
) -> Result(Message, error.TelegaError) {
  api.send_poll(
    ctx.config.api_client,
    parameters: SendPollParameters(
      question:,
      options:,
      chat_id: types.Int(ctx.update.chat_id),
      message_thread_id: None,
      disable_notification: None,
      protect_content: None,
      reply_parameters: None,
      type_: None,
      reply_markup: None,
      allow_paid_broadcast: None,
      allows_multiple_answers: None,
      allows_revoting: None,
      business_connection_id: None,
      close_date: None,
      correct_option_ids: None,
      explanation: None,
      explanation_entities: None,
      explanation_parse_mode: None,
      is_anonymous: None,
      is_closed: None,
      shuffle_options: None,
      allow_adding_options: None,
      hide_results_until_closes: None,
      description: None,
      description_parse_mode: None,
      description_entities: None,
      message_effect_id: None,
      open_period: None,
      question_entities: None,
      question_parse_mode: None,
      members_only: None,
      country_codes: None,
      explanation_media: None,
      media: None,
    ),
  )
}

/// Use this method to send an invoice.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendinvoice
pub fn with_invoice(
  ctx ctx: Context(session, error, dependencies),
  title title: String,
  description description: String,
  payload payload: String,
  currency currency: String,
  prices prices: List(#(String, Int)),
) -> Result(Message, error.TelegaError) {
  api.send_invoice(
    ctx.config.api_client,
    parameters: SendInvoiceParameters(
      title:,
      description:,
      payload:,
      currency:,
      prices: list.map(prices, fn(price) {
        let #(label, amount) = price
        LabeledPrice(label:, amount:)
      }),
      chat_id: types.Int(ctx.update.chat_id),
      message_thread_id: None,
      disable_notification: None,
      protect_content: None,
      reply_parameters: None,
      message_effect_id: None,
      reply_markup: None,
      allow_paid_broadcast: None,
      is_flexible: None,
      max_tip_amount: None,
      suggested_tip_amounts: None,
      provider_token: None,
      provider_data: None,
      photo_height: None,
      photo_size: None,
      photo_url: None,
      photo_width: None,
      send_email_to_provider: None,
      send_phone_number_to_provider: None,
      start_parameter: None,
      need_email: None,
      need_name: None,
      need_phone_number: None,
      need_shipping_address: None,
    ),
  )
}

/// Use this method to send a sticker.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendsticker
pub fn with_sticker(
  ctx ctx: Context(session, error, dependencies),
  sticker sticker: FileOrString,
) -> Result(Message, error.TelegaError) {
  api.send_sticker(
    ctx.config.api_client,
    parameters: SendStickerParameters(
      sticker:,
      chat_id: types.Int(ctx.update.chat_id),
      message_thread_id: None,
      disable_notification: None,
      protect_content: None,
      reply_parameters: None,
      allow_paid_broadcast: None,
      business_connection_id: None,
      message_effect_id: None,
      emoji: None,
      reply_markup: None,
      ephemeral_message_parameters: None,
    ),
  )
}

/// Use this method to send a group of photos, videos, documents or audios as an album.
/// Documents and audio files can be only grouped in an album with messages of the same type.
/// Returns a list of messages that were sent.
///
/// ## Example
/// ```gleam
/// let media_group = media_group.new()
///   |> media_group.add_photo("https://example.com/photo1.jpg", None)
///   |> media_group.add_photo("https://example.com/photo2.jpg", Some(
///     media_group.PhotoOptions(
///       caption: Some("Second photo"),
///       parse_mode: Some("Markdown"),
///       ..media_group.default_photo_options()
///     )
///   ))
///   |> media_group.build()
///
/// reply.with_media_group(ctx, media_group)
/// ```
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmediagroup
pub fn with_media_group(
  ctx ctx: Context(session, error, dependencies),
  media media: List(InputMedia),
) -> Result(List(Message), error.TelegaError) {
  api.send_media_group(
    ctx.config.api_client,
    parameters: SendMediaGroupParameters(
      chat_id: types.Int(ctx.update.chat_id),
      media:,
      business_connection_id: None,
      message_thread_id: None,
      disable_notification: None,
      protect_content: None,
      message_effect_id: None,
      reply_parameters: None,
      allow_paid_broadcast: None,
    ),
  )
}

/// Use this method to send paid media — photos and videos that the user must
/// pay Telegram Stars to unlock.
///
/// Uses the client's default parse mode if one is configured
/// via `client.set_default_parse_mode`.
///
/// ## Example
/// ```gleam
/// reply.with_paid_media(ctx, star_count: 10, media: [
///   types.InputPaidMediaPhotoInputPaidMedia(types.InputPaidMediaPhoto(
///     type_: "photo",
///     media: "https://example.com/photo.jpg",
///   )),
/// ])
/// ```
///
/// **Official reference:** https://core.telegram.org/bots/api#sendpaidmedia
pub fn with_paid_media(
  ctx ctx: Context(session, error, dependencies),
  star_count star_count: Int,
  media media: List(InputPaidMedia),
) -> Result(Message, error.TelegaError) {
  api.send_paid_media(
    ctx.config.api_client,
    parameters: SendPaidMediaParameters(
      chat_id: types.Int(ctx.update.chat_id),
      star_count:,
      media:,
      business_connection_id: None,
      payload: None,
      caption: None,
      parse_mode: client.default_parse_mode_string(ctx.config.api_client),
      caption_entities: None,
      show_caption_above_media: None,
      disable_notification: None,
      protect_content: None,
      allow_paid_broadcast: None,
      reply_parameters: None,
      reply_markup: None,
    ),
  )
}
