/// `reply` provides a convenient way to send messages to the active chat.
/// It uses the `Context` object to access the chat ID and other necessary information.
import gleam/option.{type Option, None, Some}
import gleam/result
import telega/api
import telega/bot.{type Context}
import telega/model.{type Message, type SendDiceParameters}

/// Use this method to send text messages.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn with_text(
  ctx ctx: Context(session),
  text text: String,
) -> Result(Message, String) {
  api.send_message(
    ctx.config.api,
    parameters: model.SendMessageParameters(
      text: text,
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
  ctx ctx: Context(session),
  text text: String,
  markup reply_markup: model.SendMessageReplyMarkupParameters,
) {
  api.send_message(
    ctx.config.api,
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

/// Use this method to send an animated emoji that will display a random value.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddice
pub fn with_dice(
  ctx ctx: Context(session),
  parameters parameters: Option(SendDiceParameters),
) -> Result(Message, String) {
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

  api.send_dice(ctx.config.api, parameters)
}

/// Use this method to edit text and game messages.
/// On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagetext
pub fn edit_text(
  ctx ctx: Context(session),
  parameters parameters: model.EditMessageTextParameters,
) -> Result(Message, String) {
  api.edit_message_text(ctx.config.api, parameters)
}

/// Use this method to forward messages of any kind. Service messages and messages with protected content can't be forwarded.
/// On success, the sent Message is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessage
pub fn forward(
  ctx ctx: Context(session),
  parameters parameters: model.ForwardMessageParameters,
) -> Result(Message, String) {
  api.forward_message(ctx.config.api, parameters)
}

/// Use this method to send answers to callback queries sent from inline keyboards.
/// The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
/// On success, _True_ is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#answercallbackquery
pub fn answer_callback_query(
  ctx ctx: Context(session),
  parameters parameters: model.AnswerCallbackQueryParameters,
) -> Result(Bool, String) {
  api.answer_callback_query(ctx.config.api, parameters)
}

/// Get download link for the file.
pub fn with_file_link(
  ctx ctx: Context(session),
  file_id file_id: String,
) -> Result(String, String) {
  use file <- result.try(api.get_file(ctx.config.api, file_id))
  use file_path <- result.try(option.to_result(
    file.file_path,
    "File path is missing",
  ))

  Ok(
    ctx.config.api.tg_api_url
    <> "/file/bot"
    <> ctx.config.secret_token
    <> "/"
    <> file_path,
  )
}
