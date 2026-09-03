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

import gleam/erlang/atom.{type Atom}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/yielder.{type Yielder}

import telega/api
import telega/bot.{type Context}
import telega/client
import telega/error
import telega/file
import telega/format.{type FormattedText}
import telega/model/types.{
  type AnswerCallbackQueryParameters, type EditMessageTextParameters,
  type EphemeralMessageParameters, type FileOrString,
  type ForwardMessageParameters, type InlineKeyboardMarkup, type InputMedia,
  type InputPaidMedia, type Message, type SendDiceParameters,
  type SendMessageReplyMarkupParameters, EditMessageTextParameters,
  EphemeralMessageParameters, LabeledPrice, SendDiceParameters,
  SendInvoiceParameters, SendMediaGroupParameters, SendMessageParameters,
  SendPaidMediaParameters, SendPhotoParameters, SendPollParameters,
  SendStickerParameters,
}
import telega/update
import telega/webhook_reply

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

// Shortcuts
//
// The handful of calls a handler makes over and over: answer the chat, answer
// the button, edit the message the button sits on. Each is one line here and
// a record with a dozen `None`s without.

/// Send `text` to the active chat and hand the context back unchanged.
///
/// The shape a handler wants: `reply.text` *is* the handler body, with no
/// `let assert` and no `use _ <- result.try` around a `Message` nobody reads.
///
/// ```gleam
/// fn handle_text(ctx, text) {
///   reply.text(ctx, "You said: " <> text)
/// }
/// ```
///
/// The failure is a `TelegaError`, so a router using this shortcut has
/// `TelegaError` as its error type. A bot with an error type of its own keeps
/// using `with_text` and maps the error itself.
pub fn text(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Context(session, error, dependencies), error.TelegaError) {
  use _ <- result.try(with_text(ctx:, text:))
  Ok(ctx)
}

/// Send text with formatting described positionally, as `MessageEntity`s,
/// instead of through a parse mode.
///
/// Nothing is escaped, because nothing is special: a user-supplied string
/// carrying `*`, `_` or `<b>` arrives exactly as typed. See `format.entities`.
///
/// ```gleam
/// format.build()
/// |> format.text("Result: ")
/// |> format.bold_text(whatever_the_user_typed)
/// |> format.to_formatted
/// |> reply.with_entities(ctx, _)
/// ```
pub fn with_entities(
  ctx ctx: Context(session, error, dependencies),
  formatted formatted: FormattedText,
) -> Result(Message, error.TelegaError) {
  let #(text, entities) = format.entities(formatted)

  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      ..base_message_parameters(ctx, text),
      parse_mode: None,
      entities: Some(entities),
    ),
  )
}

/// Reply to the message that triggered this update, quoting it in the client.
///
/// An update that is not about a message (a callback query, an inline query)
/// has nothing to quote, so the text is sent as a plain message.
pub fn quote(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Message, error.TelegaError) {
  let reply_parameters =
    update.message(ctx.update)
    |> option.map(fn(message) {
      types.ReplyParameters(
        message_id: Some(message.message_id),
        chat_id: None,
        ephemeral_message_id: None,
        // The user may delete their message between sending it and this reply;
        // arriving without the quote beats not arriving.
        allow_sending_without_reply: Some(True),
        quote: None,
        quote_parse_mode: None,
        quote_entities: None,
        quote_position: None,
        checklist_task_id: None,
        poll_option_id: None,
      )
    })

  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      ..base_message_parameters(ctx, text),
      reply_parameters:,
    ),
  )
}

/// Send `text` and take the custom (reply) keyboard off the user's screen.
pub fn remove_keyboard(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      ..base_message_parameters(ctx, text),
      reply_markup: Some(
        types.SendMessageReplyRemoveKeyboardMarkupParameters(
          types.ReplyKeyboardRemove(remove_keyboard: True, selective: None),
        ),
      ),
    ),
  )
}

/// Replace the text of the message the pressed button belongs to.
///
/// Works for an inline-mode message too (`inline_message_id`), which is why it
/// returns whatever `editMessageText` returned rather than assuming a chat
/// message. Errors when the update is not a callback query.
pub fn edit_callback_message(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Message, error.TelegaError) {
  edit_callback(ctx, text, None)
}

/// `edit_callback_message` that also replaces the inline keyboard — the usual
/// way to advance a menu in place.
pub fn edit_callback_markup(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
  markup markup: InlineKeyboardMarkup,
) -> Result(Message, error.TelegaError) {
  edit_callback(ctx, text, Some(markup))
}

fn edit_callback(
  ctx: Context(session, error, dependencies),
  text: String,
  reply_markup: Option(InlineKeyboardMarkup),
) -> Result(Message, error.TelegaError) {
  use query <- result.try(callback_query(ctx, "edit_callback_message"))

  let #(chat_id, message_id) = case query.message {
    Some(types.MessageMaybeInaccessibleMessage(message)) -> #(
      Some(types.Int(message.chat.id)),
      Some(message.message_id),
    )
    Some(types.InaccessibleMessageMaybeInaccessibleMessage(message)) -> #(
      Some(types.Int(message.chat.id)),
      Some(message.message_id),
    )
    None -> #(None, None)
  }

  api.edit_message_text(
    ctx.config.api_client,
    EditMessageTextParameters(
      text:,
      chat_id:,
      message_id:,
      inline_message_id: query.inline_message_id,
      parse_mode: client.default_parse_mode_string(ctx.config.api_client),
      entities: None,
      link_preview_options: None,
      reply_markup:,
    ),
  )
}

/// Answer the callback query of this update with a toast — the notification
/// strip at the top of the chat.
///
/// Every callback query must be answered, or the client keeps showing a
/// spinner on the button for a minute. Errors when the update is not a
/// callback query.
pub fn answer_toast(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Bool, error.TelegaError) {
  answer_query(ctx, "answer_toast", Some(text), show_alert: False)
}

/// Answer the callback query of this update with a modal alert the user has to
/// dismiss. Use it for refusals and mistakes; `answer_toast` for everything
/// else.
pub fn answer_alert(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Bool, error.TelegaError) {
  answer_query(ctx, "answer_alert", Some(text), show_alert: True)
}

/// Answer the callback query of this update without showing anything — just
/// stop the button's spinner.
pub fn answer_quietly(
  ctx ctx: Context(session, error, dependencies),
) -> Result(Bool, error.TelegaError) {
  answer_query(ctx, "answer_quietly", None, show_alert: False)
}

fn answer_query(
  ctx: Context(session, error, dependencies),
  caller: String,
  text: Option(String),
  show_alert show_alert: Bool,
) -> Result(Bool, error.TelegaError) {
  use query <- result.try(callback_query(ctx, caller))

  api.answer_callback_query(
    ctx.config.api_client,
    types.AnswerCallbackQueryParameters(
      callback_query_id: query.id,
      text:,
      show_alert: Some(show_alert),
      url: None,
      cache_time: None,
    ),
  )
}

fn callback_query(
  ctx: Context(session, error, dependencies),
  caller: String,
) -> Result(types.CallbackQuery, error.TelegaError) {
  case ctx.update {
    update.CallbackQueryUpdate(query:, ..) -> Ok(query)
    _ ->
      Error(error.BotHandleUpdateError(
        "reply."
        <> caller
        <> " needs a callback query update, got a "
        <> update.type_to_string(ctx.update),
      ))
  }
}

/// The `sendMessage` parameters every shortcut starts from: this chat, the
/// client's default parse mode, nothing else set.
fn base_message_parameters(
  ctx: Context(session, error, dependencies),
  text: String,
) -> types.SendMessageParameters {
  SendMessageParameters(
    text:,
    chat_id: types.Int(ctx.update.chat_id),
    parse_mode: client.default_parse_mode_string(ctx.config.api_client),
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
  )
}

// Streaming
//
// One message that grows, instead of a wall of fragments. A token stream from
// an LLM arrives faster than Telegram lets anyone edit a message, so the text
// is accumulated and flushed on a clock.

/// The block cursor appended while a stream is still running, so the message
/// reads as "still writing" rather than "finished, oddly short".
const stream_cursor = "▌"

/// Stream text into a single message that is edited as it grows.
///
/// `chunks` is pulled to exhaustion — token by token from an LLM, line by line
/// from a long job. The first non-empty chunk sends a message; after that the
/// message is edited at most once per `every_ms`, and a final edit drops the
/// cursor and shows the complete text. A stream of 400 tokens costs a handful
/// of API calls, not 400.
///
/// ```gleam
/// use ctx <- telega.log_context(ctx, "answer")
/// let assert Ok(_) = reply.stream_text(ctx, llm_tokens(prompt), every_ms: 700)
/// ```
///
/// Pick `every_ms` above Telegram's per-chat pacing — 700 ms is a good
/// default, and below ~500 ms in a private chat the edits queue up behind the
/// rate limiter and the animation stutters.
///
/// Edits that fail while the stream runs are swallowed: a flood wait halfway
/// through must not cost the user the answer, and the next flush carries the
/// text the failed one would have. The first send and the final edit are not —
/// their failure is returned. An empty stream sends nothing and is an error,
/// since Telegram has no empty message to return.
pub fn stream_text(
  ctx ctx: Context(session, error, dependencies),
  chunks chunks: Yielder(String),
  every_ms every_ms: Int,
) -> Result(Message, error.TelegaError) {
  stream(ctx, chunks, every_ms, into: None)
}

/// `stream_text` into a message that already exists — the "Thinking…" placeholder
/// you sent before calling the model, so the user sees something immediately.
///
/// The message must be one the bot can edit in this chat. Under
/// `handle_bot_with_reply`, send that placeholder inside
/// `webhook_reply.without_claim` — a claimed send returns a stub with
/// `message_id: -1`, and there is nothing to write into.
pub fn stream_into(
  ctx ctx: Context(session, error, dependencies),
  message_id message_id: Int,
  chunks chunks: Yielder(String),
  every_ms every_ms: Int,
) -> Result(Message, error.TelegaError) {
  stream(ctx, chunks, every_ms, into: Some(message_id))
}

/// What the stream knows between chunks: where it is writing, what it has
/// collected so far, and when it last flushed.
type Stream {
  Stream(message_id: Option(Int), text: String, last_flush_ms: Int)
}

fn stream(
  ctx: Context(session, error, dependencies),
  chunks: Yielder(String),
  every_ms: Int,
  into message_id: Option(Int),
) -> Result(Message, error.TelegaError) {
  // Dated one window into the past, so the first chunk shows up at once
  // instead of after `every_ms` of silence.
  let initial =
    Stream(message_id:, text: "", last_flush_ms: monotonic_ms() - every_ms)

  // Under `handle_bot_with_reply` the first eligible send of an update is
  // answered through the webhook response itself and comes back as a stub with
  // `message_id: -1` — every edit after it would target a message that does
  // not exist.
  use <- webhook_reply.without_claim(ctx.scope)

  use stream <- result.try(
    yielder.try_fold(over: chunks, from: initial, with: fn(stream, chunk) {
      push_chunk(ctx, stream, chunk, every_ms)
    }),
  )

  finish_stream(ctx, stream)
}

fn push_chunk(
  ctx: Context(session, error, dependencies),
  stream: Stream,
  chunk: String,
  every_ms: Int,
) -> Result(Stream, error.TelegaError) {
  let stream = Stream(..stream, text: stream.text <> chunk)
  let now = monotonic_ms()

  case stream.text == "" || now - stream.last_flush_ms < every_ms {
    True -> Ok(stream)
    False -> flush(ctx, stream, now)
  }
}

/// Show what has accumulated so far, with the cursor.
///
/// Only the very first send can fail the stream: without a message there is
/// nothing to edit later, and a second attempt could leave the user with two
/// half-written answers. A failed *edit* costs nothing — the text is still in
/// `stream.text` and the next flush carries it — so it is swallowed, and only
/// the clock moves on.
fn flush(
  ctx: Context(session, error, dependencies),
  stream: Stream,
  now: Int,
) -> Result(Stream, error.TelegaError) {
  let body = stream.text <> stream_cursor

  case stream.message_id {
    None -> {
      use message <- result.try(with_text(ctx:, text: body))
      Ok(
        Stream(
          ..stream,
          message_id: Some(message.message_id),
          last_flush_ms: now,
        ),
      )
    }
    Some(message_id) -> {
      let _ = edit_stream_message(ctx, message_id, body)
      Ok(Stream(..stream, last_flush_ms: now))
    }
  }
}

/// The last write: the full text, no cursor.
fn finish_stream(
  ctx: Context(session, error, dependencies),
  stream: Stream,
) -> Result(Message, error.TelegaError) {
  case stream.message_id, stream.text {
    _, "" ->
      Error(error.BotHandleUpdateError(
        "reply.stream_text: the stream produced no text",
      ))
    None, text -> with_text(ctx:, text:)
    // Every flush appends the cursor, so what is on screen never equals the
    // final text: this edit always has something to change.
    Some(message_id), text -> edit_stream_message(ctx, message_id, text)
  }
}

fn edit_stream_message(
  ctx: Context(session, error, dependencies),
  message_id: Int,
  text: String,
) -> Result(Message, error.TelegaError) {
  api.edit_message_text(
    ctx.config.api_client,
    EditMessageTextParameters(
      text:,
      chat_id: Some(types.Int(ctx.update.chat_id)),
      message_id: Some(message_id),
      inline_message_id: None,
      parse_mode: client.default_parse_mode_string(ctx.config.api_client),
      entities: None,
      link_preview_options: None,
      reply_markup: None,
    ),
  )
}

@external(erlang, "erlang", "monotonic_time")
fn erlang_monotonic_time(unit: Atom) -> Int

fn monotonic_ms() -> Int {
  erlang_monotonic_time(atom.create("millisecond"))
}
