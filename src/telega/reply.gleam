//// `reply` provides a convenient way to send messages to the active chat.
//// It uses the `Context` object to access the chat ID and other necessary information.

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result

import telega/api
import telega/bot.{type Context}
import telega/client
import telega/error
import telega/format.{type FormattedText}
import telega/model.{type SendDiceParameters}

/// Use this method to send text messages.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_text(
  ctx ctx: Context(session, error),
  text text: String,
) -> Result(model.Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: model.SendMessageParameters(
      text:,
      chat_id: model.Str(ctx.key),
      business_connection_id: None,
      message_thread_id: None,
      parse_mode: None,
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

/// Use this method to send text messages with keyboard markup.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_markup(
  ctx ctx: Context(session, error),
  text text: String,
  markup reply_markup: model.SendMessageReplyMarkupParameters,
) -> Result(model.Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: model.SendMessageParameters(
      text:,
      chat_id: model.Str(ctx.key),
      reply_markup: Some(reply_markup),
      business_connection_id: None,
      message_thread_id: None,
      parse_mode: None,
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      reply_parameters: None,
      message_effect_id: None,
      allow_paid_broadcast: None,
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
  ctx ctx: Context(session, error),
  formatted formatted: FormattedText,
) -> Result(model.Message, error.TelegaError) {
  let #(text, parse_mode) = format.render(formatted)

  api.send_message(
    ctx.config.api_client,
    parameters: model.SendMessageParameters(
      text:,
      chat_id: model.Str(ctx.key),
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
  ctx ctx: Context(session, error),
  html html: String,
) -> Result(model.Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: model.SendMessageParameters(
      text: html,
      chat_id: model.Str(ctx.key),
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
  ctx ctx: Context(session, error),
  markdown markdown: String,
) -> Result(model.Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: model.SendMessageParameters(
      text: markdown,
      chat_id: model.Str(ctx.key),
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
  ctx ctx: Context(session, error),
  markdown markdown: String,
) -> Result(model.Message, error.TelegaError) {
  api.send_message(
    ctx.config.api_client,
    parameters: model.SendMessageParameters(
      text: markdown,
      chat_id: model.Str(ctx.key),
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
    ),
  )
}

/// Use this method to send formatted text messages with keyboard markup.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_formatted_markup(
  ctx ctx: Context(session, error),
  formatted formatted: FormattedText,
  markup reply_markup: model.SendMessageReplyMarkupParameters,
) -> Result(model.Message, error.TelegaError) {
  let #(text, parse_mode) = format.render(formatted)

  api.send_message(
    ctx.config.api_client,
    parameters: model.SendMessageParameters(
      text:,
      chat_id: model.Str(ctx.key),
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
    ),
  )
}

/// Use this method to send an animated emoji that will display a random value.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddice
pub fn with_dice(
  ctx ctx: Context(session, error),
  parameters parameters: Option(SendDiceParameters),
) -> Result(model.Message, error.TelegaError) {
  let parameters =
    parameters
    |> option.lazy_unwrap(fn() {
      model.SendDiceParameters(
        chat_id: model.Str(ctx.key),
        message_thread_id: None,
        emoji: None,
        disable_notification: None,
        protect_content: None,
        reply_parameters: None,
      )
    })

  api.send_dice(ctx.config.api_client, parameters)
}

/// Use this method to edit text and game messages.
/// On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagetext
pub fn edit_text(
  ctx ctx: Context(session, error),
  parameters parameters: model.EditMessageTextParameters,
) -> Result(model.Message, error.TelegaError) {
  api.edit_message_text(ctx.config.api_client, parameters)
}

/// Use this method to forward messages of any kind. Service messages and messages with protected content can't be forwarded.
/// On success, the sent Message is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessage
pub fn forward(
  ctx ctx: Context(session, error),
  parameters parameters: model.ForwardMessageParameters,
) -> Result(model.Message, error.TelegaError) {
  api.forward_message(ctx.config.api_client, parameters)
}

/// Use this method to send answers to callback queries sent from inline keyboards.
/// The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
/// On success, _True_ is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#answercallbackquery
pub fn answer_callback_query(
  ctx ctx: Context(session, error),
  parameters parameters: model.AnswerCallbackQueryParameters,
) -> Result(Bool, error.TelegaError) {
  api.answer_callback_query(ctx.config.api_client, parameters)
}

/// Get download link for the file.
pub fn with_file_link(
  ctx ctx: Context(session, error),
  file_id file_id: String,
) -> Result(String, error.TelegaError) {
  use file <- result.try(api.get_file(ctx.config.api_client, file_id))
  use file_path <- result.try(option.to_result(
    file.file_path,
    error.FileNotFoundError,
  ))

  Ok(
    client.get_api_url(ctx.config.api_client)
    <> "/file/bot"
    <> ctx.config.secret_token
    <> "/"
    <> file_path,
  )
}

/// Use this method to send a native poll.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendpoll
pub fn with_poll(
  ctx ctx: Context(session, error),
  question question: String,
  options options: List(String),
) -> Result(model.Message, error.TelegaError) {
  api.send_poll(
    ctx.config.api_client,
    parameters: model.SendPollParameters(
      question:,
      options:,
      chat_id: model.Str(ctx.key),
      message_thread_id: None,
      disable_notification: None,
      protect_content: None,
      reply_parameters: None,
      type_: None,
      reply_markup: None,
      allow_paid_broadcast: None,
      allows_multiple_answers: None,
      business_connection_id: None,
      close_date: None,
      correct_option_id: None,
      explanation: None,
      explanation_entities: None,
      explanation_parse_mode: None,
      is_anonymous: None,
      is_closed: None,
      message_effect_id: None,
      open_period: None,
      question_entities: None,
      question_parse_mode: None,
    ),
  )
}

/// Use this method to send an invoice.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendinvoice
pub fn with_invoice(
  ctx ctx: Context(session, error),
  title title: String,
  description description: String,
  payload payload: String,
  currency currency: String,
  prices prices: List(#(String, Int)),
) -> Result(model.Message, error.TelegaError) {
  api.send_invoice(
    ctx.config.api_client,
    parameters: model.SendInvoiceParameters(
      title:,
      description:,
      payload:,
      currency:,
      prices: list.map(prices, fn(price) {
        let #(label, amount) = price
        model.LabeledPrice(label:, amount:)
      }),
      chat_id: model.Str(ctx.key),
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
  ctx ctx: Context(session, error),
  sticker sticker: model.FileOrString,
) -> Result(model.Message, error.TelegaError) {
  api.send_sticker(
    ctx.config.api_client,
    parameters: model.SendStickerParameters(
      sticker:,
      chat_id: model.Str(ctx.key),
      message_thread_id: None,
      disable_notification: None,
      protect_content: None,
      reply_parameters: None,
      allow_paid_broadcast: None,
      business_connection_id: None,
      message_effect_id: None,
      emoji: None,
      reply_markup: None,
    ),
  )
}
