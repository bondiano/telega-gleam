//// The edit-or-send engine behind dialogs.
////
//// Keeps one live dialog message per chat: sends it the first time, edits it
//// on every subsequent render. Media windows are supported by the strategy
//// matrix below — the Bot API cannot turn a text message into a media one
//// (or back), so a kind change recreates the message:
////
//// | was \ becomes     | text                       | media                      |
//// |-------------------|----------------------------|----------------------------|
//// | — (no message)    | `sendMessage`              | `sendPhoto`/`sendVideo`/…  |
//// | text              | `editMessageText`          | delete (best effort) + send |
//// | media (any kind)  | delete (best effort) + send | `editMessageMedia`         |
////
//// `deleteMessage` is best effort (messages older than 48 hours cannot be
//// deleted): its failure is swallowed and the fresh message is sent anyway.
////
//// Also hosts the `alert`/`toast` helpers and the Bot API error classifiers
//// (`is_not_modified` & co) — the latter are useful outside dialogs too.

import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import telega/api
import telega/bot.{type Context}
import telega/dialog/types as dialog_types
import telega/error.{type TelegaError}
import telega/format
import telega/keyboard
import telega/model/types.{
  type InlineKeyboardButton, type InlineKeyboardMarkup,
  AnswerCallbackQueryParameters, DeleteMessageParameters,
  EditMessageMediaParameters, EditMessageReplyMarkupParameters,
  EditMessageTextParameters, InlineKeyboardMarkup, SendAnimationParameters,
  SendDocumentParameters, SendMessageParameters,
  SendMessageReplyInlineKeyboardMarkupParameters, SendPhotoParameters,
  SendVideoParameters,
}
import telega/scope
import telega/update
import telega/webhook_reply

/// Why a window could not be rendered.
pub type RenderError {
  /// The Telegram API call failed (after the edit-fallback matrix).
  ApiError(TelegaError)
  /// A button is misconfigured: callback data over 64 bytes or a reserved
  /// `:` in an action id. This is a developer error and must be visible,
  /// not silently degraded.
  InvalidButton(action_id: String, reason: String)
}

// Bot API edit-error classifiers ----------------------------------------------
//
// Thin aliases over the shared classifiers in `telega/error` — kept here so
// dialog code reads naturally, useful directly from `telega/error` elsewhere.

/// The edit was a no-op: new content equals the current one. Safe to treat
/// as success.
pub fn is_not_modified(error error: TelegaError) -> Bool {
  error.is_message_not_modified(error)
}

/// The message to edit no longer exists (deleted by the user or too old).
pub fn is_message_not_found(error error: TelegaError) -> Bool {
  error.is_message_not_found(error)
}

/// The message exists but cannot be edited (e.g. not sent by the bot).
pub fn is_cant_be_edited(error error: TelegaError) -> Bool {
  error.is_message_cant_be_edited(error)
}

// Rendering --------------------------------------------------------------------

/// The kind of the live dialog message. The Bot API cannot edit a text
/// message into a media one or back, so the engine tracks the kind to pick
/// the right strategy from the matrix in the module doc. All media messages
/// share one kind: `editMessageMedia` changes the file, the media type, and
/// the caption in a single call.
pub type MessageKind {
  TextMessage
  MediaMessage
}

/// Render a window into the live dialog message following the edit-or-send
/// strategy matrix (see the module doc): send when there is no message yet,
/// edit when the kind is unchanged, delete-and-resend when it changed. Edits
/// fall back to a fresh send when the old message is gone. Returns the id
/// and kind of the live message.
pub fn render_window(
  ctx ctx: Context(session, error, dependencies),
  chat_id chat_id: Int,
  message message: Option(#(Int, MessageKind)),
  dialog_id dialog_id: String,
  window_id window_id: String,
  window window: dialog_types.RenderedWindow,
  resend resend: Bool,
) -> Result(#(Int, MessageKind), RenderError) {
  use markup <- result.try(build_markup(dialog_id, window_id, window.buttons))
  let #(text, parse_mode) = format.render(window.text)
  let parse_mode = format.parse_mode_to_string(parse_mode)

  let send_text = fn() {
    send_window(ctx, chat_id, text, parse_mode, markup)
    |> result.map(fn(id) { #(id, TextMessage) })
  }
  let send_media = fn(media) {
    send_media_window(ctx, chat_id, media, text, parse_mode, markup)
    |> result.map(fn(id) { #(id, MediaMessage) })
  }

  // Replacing the live message instead of editing it: take the old one down
  // first (best effort — a message older than 48 hours cannot be deleted) and
  // fall through to the fresh-send arms.
  let message = case resend, message {
    True, Some(#(message_id, _)) -> {
      delete_best_effort(ctx, chat_id, message_id)
      None
    }
    _, message -> message
  }

  case message, window.media {
    None, None -> send_text()
    None, Some(media) -> send_media(media)

    Some(#(message_id, TextMessage)), None ->
      edit_window(ctx, chat_id, message_id, text, parse_mode, markup)
      |> or_send_fallback(message_id, TextMessage, send_text)

    Some(#(message_id, MediaMessage)), Some(media) ->
      edit_media_window(
        ctx,
        chat_id,
        message_id,
        media,
        text,
        parse_mode,
        markup,
      )
      |> or_send_fallback(message_id, MediaMessage, fn() { send_media(media) })

    // The message kind changes: recreate. deleteMessage is best effort — it
    // fails for messages older than 48 hours, and the fresh send must happen
    // regardless.
    Some(#(message_id, TextMessage)), Some(media) -> {
      delete_best_effort(ctx, chat_id, message_id)
      send_media(media)
    }
    Some(#(message_id, MediaMessage)), None -> {
      delete_best_effort(ctx, chat_id, message_id)
      send_text()
    }
  }
}

/// Apply the shared edit-fallback matrix: "not modified" is success, a gone
/// message falls back to a fresh send, anything else is an error.
fn or_send_fallback(
  edited: Result(Int, TelegaError),
  current_id: Int,
  kind: MessageKind,
  send: fn() -> Result(#(Int, MessageKind), RenderError),
) -> Result(#(Int, MessageKind), RenderError) {
  case edited {
    Ok(message_id) -> Ok(#(message_id, kind))
    Error(api_error) ->
      case
        is_not_modified(api_error),
        is_message_not_found(api_error) || is_cant_be_edited(api_error)
      {
        True, _ -> Ok(#(current_id, kind))
        _, True -> send()
        _, _ -> Error(ApiError(api_error))
      }
  }
}

fn delete_best_effort(
  ctx: Context(session, error, dependencies),
  chat_id: Int,
  message_id: Int,
) -> Nil {
  let _ =
    api.delete_message(
      ctx.config.api_client,
      parameters: DeleteMessageParameters(
        chat_id: types.Int(chat_id),
        message_id:,
      ),
    )
  Nil
}

fn send_window(
  ctx: Context(session, error, dependencies),
  chat_id: Int,
  text: String,
  parse_mode: String,
  markup: Option(InlineKeyboardMarkup),
) -> Result(Int, RenderError) {
  // The engine tracks the sent message's id to edit it later, so this call
  // must not be claimed by webhook reply (a claim yields a fake stub id).
  use <- webhook_reply.without_claim(ctx.scope)
  api.send_message(
    ctx.config.api_client,
    parameters: SendMessageParameters(
      text:,
      chat_id: types.Int(chat_id),
      parse_mode: Some(parse_mode),
      reply_markup: option.map(
        markup,
        SendMessageReplyInlineKeyboardMarkupParameters,
      ),
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
  |> result.map(fn(message) { message.message_id })
  |> result.map_error(ApiError)
}

fn edit_window(
  ctx: Context(session, error, dependencies),
  chat_id: Int,
  message_id: Int,
  text: String,
  parse_mode: String,
  markup: Option(InlineKeyboardMarkup),
) -> Result(Int, TelegaError) {
  api.edit_message_text(
    ctx.config.api_client,
    parameters: EditMessageTextParameters(
      chat_id: Some(types.Int(chat_id)),
      message_id: Some(message_id),
      inline_message_id: None,
      text:,
      parse_mode: Some(parse_mode),
      entities: None,
      link_preview_options: None,
      reply_markup: markup,
    ),
  )
  |> result.map(fn(message) { message.message_id })
}

// Media rendering ---------------------------------------------------------------

fn send_media_window(
  ctx: Context(session, error, dependencies),
  chat_id: Int,
  media: dialog_types.DialogMedia,
  text: String,
  parse_mode: String,
  markup: Option(InlineKeyboardMarkup),
) -> Result(Int, RenderError) {
  // See `send_window`: the real message id is required for later edits.
  use <- webhook_reply.without_claim(ctx.scope)
  let chat_id = types.Int(chat_id)
  let caption = caption_for(text)
  let parse_mode = option.map(caption, fn(_) { parse_mode })
  let reply_markup =
    option.map(markup, SendMessageReplyInlineKeyboardMarkupParameters)

  case media {
    dialog_types.PhotoMedia(media:, has_spoiler:) ->
      api.send_photo(
        ctx.config.api_client,
        parameters: SendPhotoParameters(
          chat_id:,
          photo: types.StringV(media),
          caption:,
          parse_mode:,
          has_spoiler: spoiler_option(has_spoiler),
          reply_markup:,
          business_connection_id: None,
          message_thread_id: None,
          caption_entities: None,
          show_caption_above_media: None,
          disable_notification: None,
          protect_content: None,
          allow_paid_broadcast: None,
          message_effect_id: None,
          reply_parameters: None,
          ephemeral_message_parameters: None,
        ),
      )
    dialog_types.VideoMedia(media:, has_spoiler:) ->
      api.send_video(
        ctx.config.api_client,
        parameters: SendVideoParameters(
          chat_id:,
          video: types.StringV(media),
          caption:,
          parse_mode:,
          has_spoiler: spoiler_option(has_spoiler),
          reply_markup:,
          business_connection_id: None,
          message_thread_id: None,
          duration: None,
          width: None,
          height: None,
          thumbnail: None,
          cover: None,
          start_timestamp: None,
          caption_entities: None,
          show_caption_above_media: None,
          supports_streaming: None,
          disable_notification: None,
          protect_content: None,
          allow_paid_broadcast: None,
          message_effect_id: None,
          reply_parameters: None,
          ephemeral_message_parameters: None,
        ),
      )
    dialog_types.AnimationMedia(media:) ->
      api.send_animation(
        ctx.config.api_client,
        parameters: SendAnimationParameters(
          chat_id:,
          animation: types.StringV(media),
          caption:,
          parse_mode:,
          reply_markup:,
          business_connection_id: None,
          message_thread_id: None,
          duration: None,
          width: None,
          height: None,
          thumbnail: None,
          caption_entities: None,
          show_caption_above_media: None,
          has_spoiler: None,
          disable_notification: None,
          protect_content: None,
          allow_paid_broadcast: None,
          message_effect_id: None,
          reply_parameters: None,
          ephemeral_message_parameters: None,
        ),
      )
    dialog_types.DocumentMedia(media:) ->
      api.send_document(
        ctx.config.api_client,
        parameters: SendDocumentParameters(
          chat_id:,
          document: types.StringV(media),
          caption:,
          parse_mode:,
          reply_markup:,
          business_connection_id: None,
          message_thread_id: None,
          thumbnail: None,
          caption_entities: None,
          disable_content_type_detection: None,
          disable_notification: None,
          protect_content: None,
          allow_paid_broadcast: None,
          message_effect_id: None,
          reply_parameters: None,
          ephemeral_message_parameters: None,
        ),
      )
  }
  |> result.map(fn(message) { message.message_id })
  |> result.map_error(ApiError)
}

fn edit_media_window(
  ctx: Context(session, error, dependencies),
  chat_id: Int,
  message_id: Int,
  media: dialog_types.DialogMedia,
  text: String,
  parse_mode: String,
  markup: Option(InlineKeyboardMarkup),
) -> Result(Int, TelegaError) {
  api.edit_message_media(
    ctx.config.api_client,
    parameters: EditMessageMediaParameters(
      business_connection_id: None,
      chat_id: Some(types.Int(chat_id)),
      message_id: Some(message_id),
      inline_message_id: None,
      media: input_media(media, caption_for(text), parse_mode),
      reply_markup: markup,
    ),
  )
  |> result.map(fn(message) { message.message_id })
}

fn input_media(
  media: dialog_types.DialogMedia,
  caption: Option(String),
  parse_mode: String,
) -> types.InputMedia {
  let parse_mode = option.map(caption, fn(_) { parse_mode })
  case media {
    dialog_types.PhotoMedia(media:, has_spoiler:) ->
      types.InputMediaPhotoInputMedia(types.InputMediaPhoto(
        type_: "photo",
        media:,
        caption:,
        parse_mode:,
        caption_entities: None,
        show_caption_above_media: None,
        has_spoiler: spoiler_option(has_spoiler),
      ))
    dialog_types.VideoMedia(media:, has_spoiler:) ->
      types.InputMediaVideoInputMedia(types.InputMediaVideo(
        type_: "video",
        media:,
        caption:,
        parse_mode:,
        thumbnail: None,
        cover: None,
        start_timestamp: None,
        caption_entities: None,
        show_caption_above_media: None,
        width: None,
        height: None,
        duration: None,
        supports_streaming: None,
        has_spoiler: spoiler_option(has_spoiler),
      ))
    dialog_types.AnimationMedia(media:) ->
      types.InputMediaAnimationInputMedia(types.InputMediaAnimation(
        type_: "animation",
        media:,
        caption:,
        parse_mode:,
        thumbnail: None,
        caption_entities: None,
        show_caption_above_media: None,
        width: None,
        height: None,
        duration: None,
        has_spoiler: None,
      ))
    dialog_types.DocumentMedia(media:) ->
      types.InputMediaDocumentInputMedia(types.InputMediaDocument(
        type_: "document",
        media:,
        caption:,
        parse_mode:,
        thumbnail: None,
        caption_entities: None,
        disable_content_type_detection: None,
      ))
  }
}

fn caption_for(text: String) -> Option(String) {
  case text {
    "" -> None
    _ -> Some(text)
  }
}

fn spoiler_option(has_spoiler: Bool) -> Option(Bool) {
  case has_spoiler {
    True -> Some(True)
    False -> None
  }
}

/// Remove the inline keyboard from the live dialog message (used on `Done`).
/// Best effort: failures are reported but callers usually ignore them.
pub fn remove_keyboard(
  ctx ctx: Context(session, error, dependencies),
  chat_id chat_id: Int,
  message_id message_id: Int,
) -> Result(Nil, TelegaError) {
  api.edit_message_reply_markup(
    ctx.config.api_client,
    parameters: EditMessageReplyMarkupParameters(
      business_connection_id: None,
      chat_id: Some(types.Int(chat_id)),
      message_id: Some(message_id),
      inline_message_id: None,
      reply_markup: None,
    ),
  )
  |> result.replace(Nil)
}

// Keyboard building -------------------------------------------------------------

/// Build the inline keyboard for a window, generating callback data by the
/// `dlg:<dialog>:<window>:<action>[:<arg>]` scheme and validating the 64-byte
/// limit and reserved characters per button.
pub fn build_markup(
  dialog_id dialog_id: String,
  window_id window_id: String,
  buttons buttons: List(List(dialog_types.DialogButton)),
) -> Result(Option(InlineKeyboardMarkup), RenderError) {
  case buttons {
    [] -> Ok(None)
    _ -> {
      use rows <- result.try(
        list.try_map(buttons, fn(row) {
          list.try_map(row, fn(button) {
            build_button(dialog_id, window_id, button)
          })
        }),
      )
      Ok(Some(InlineKeyboardMarkup(inline_keyboard: rows, force_reply: None)))
    }
  }
}

fn build_button(
  dialog_id: String,
  window_id: String,
  button: dialog_types.DialogButton,
) -> Result(InlineKeyboardButton, RenderError) {
  case button {
    dialog_types.ActionButton(text:, action_id:) -> {
      use data <- result.try(pack_callback_data(
        dialog_id,
        window_id,
        action_id,
        None,
      ))
      Ok(keyboard.inline_raw_callback_button(text, data))
    }
    dialog_types.ActionArgButton(text:, action_id:, arg:) -> {
      use data <- result.try(pack_callback_data(
        dialog_id,
        window_id,
        action_id,
        Some(arg),
      ))
      Ok(keyboard.inline_raw_callback_button(text, data))
    }
    dialog_types.UrlButton(text:, url:) ->
      Ok(keyboard.inline_url_button(text, url))
    dialog_types.WebAppButton(text:, url:) ->
      Ok(keyboard.inline_web_app_button(text, url))
    dialog_types.NoopButton(text:) ->
      Ok(keyboard.inline_copy_text_button(text, text))
  }
}

/// Telegram's callback-data byte limit; validation and packing share it.
pub const max_callback_data_bytes = 64

/// The exact callback-data string for an action — the single place the
/// `dlg:` scheme is constructed. Build-time validation measures budgets
/// through this same function, so packing and validation can never diverge.
pub fn callback_data(
  dialog_id dialog_id: String,
  window_id window_id: String,
  action_id action_id: String,
  arg arg: Option(String),
) -> String {
  let data = "dlg:" <> dialog_id <> ":" <> window_id <> ":" <> action_id
  case arg {
    Some(arg) -> data <> ":" <> arg
    None -> data
  }
}

/// Build callback data for an action, checking the reserved `:` in the
/// action id and Telegram's 64-byte limit. The `w:` action-id prefix is the
/// widget namespace (`w:<widget_id>:<cmd>`) and is the only place `:` is
/// allowed — the engine routes such presses to the widget's `on_event`. The
/// bare id `"w"` is rejected too: with a `:`-carrying arg it would be
/// indistinguishable from a widget event on parse.
pub fn pack_callback_data(
  dialog_id dialog_id: String,
  window_id window_id: String,
  action_id action_id: String,
  arg arg: Option(String),
) -> Result(String, RenderError) {
  use <- bool.guard(
    !{ string.starts_with(action_id, "w:") || !string.contains(action_id, ":") },
    Error(InvalidButton(
      action_id:,
      reason: "action id must not contain ':' (reserved for the w: widget namespace)",
    )),
  )
  use <- bool.guard(
    action_id == "w",
    Error(InvalidButton(
      action_id:,
      reason: "action id 'w' is reserved for the widget namespace",
    )),
  )
  let data = callback_data(dialog_id, window_id, action_id, arg)
  let bytes = string.byte_size(data)
  use <- bool.guard(
    bytes > max_callback_data_bytes,
    Error(InvalidButton(
      action_id:,
      reason: "callback data is "
        <> int.to_string(bytes)
        <> " bytes, max is "
        <> int.to_string(max_callback_data_bytes),
    )),
  )
  Ok(data)
}

// Callback answering -------------------------------------------------------------

/// Show a modal alert to the user who pressed the button. Call from
/// `on_action` before returning; the engine then skips its automatic
/// `answer_callback_query` for this event.
pub fn alert(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Nil, TelegaError) {
  answer_with(ctx, Some(text), show_alert: True)
}

/// Show a toast notification at the top of the chat. Same contract as
/// `alert`, but without the modal dialog.
pub fn toast(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Nil, TelegaError) {
  answer_with(ctx, Some(text), show_alert: False)
}

/// Answer the current callback query without text (removes the client-side
/// spinner). Used by the engine; no-op if the update is not a callback query
/// or the query was already answered — by `alert`/`toast`, or by an earlier
/// `auto_answer` for the same query.
///
/// Idempotent per query id, so the engine can call it at every point a step
/// can leave without answering twice.
@internal
pub fn auto_answer(ctx: Context(session, error, dependencies)) -> Nil {
  case ctx.update {
    update.CallbackQueryUpdate(query:, ..) ->
      case answered_query(ctx) == Some(query.id) {
        True -> Nil
        False -> {
          let _ = do_answer(ctx, query.id, None, False)
          mark_answered(ctx, query.id)
          Nil
        }
      }
    _ -> Nil
  }
}

fn answer_with(
  ctx: Context(session, error, dependencies),
  text: Option(String),
  show_alert show_alert: Bool,
) -> Result(Nil, TelegaError) {
  case ctx.update {
    update.CallbackQueryUpdate(query:, ..) -> {
      use _ <- result.try(do_answer(ctx, query.id, text, show_alert))
      mark_answered(ctx, query.id)
      Ok(Nil)
    }
    _ -> Ok(Nil)
  }
}

fn do_answer(
  ctx: Context(session, error, dependencies),
  query_id: String,
  text: Option(String),
  show_alert: Bool,
) -> Result(Nil, TelegaError) {
  api.answer_callback_query(
    ctx.config.api_client,
    parameters: AnswerCallbackQueryParameters(
      callback_query_id: query_id,
      text:,
      show_alert: Some(show_alert),
      url: None,
      cache_time: None,
    ),
  )
  |> result.replace(Nil)
}

/// Answer the current callback query with the given text (no alert). Used by
/// the engine for stale-button and foreign-payload responses; marks the query
/// answered so the step's own `auto_answer` does not answer it a second time.
@internal
pub fn answer_quietly(
  ctx: Context(session, error, dependencies),
  text: Option(String),
) -> Nil {
  case ctx.update {
    update.CallbackQueryUpdate(query:, ..) -> {
      let _ = do_answer(ctx, query.id, text, False)
      mark_answered(ctx, query.id)
      Nil
    }
    _ -> Nil
  }
}

// "Already answered" flag ----------------------------------------------------
//
// alert/toast run inside the user's `on_action`, so the engine can't see
// their effect through the return value. The flag lives in the update's
// `Scope`, which the whole update shares and nothing outside it can read.

const answered_key: scope.Key(String) = scope.Key("dialog/answered")

fn mark_answered(
  ctx: Context(session, error, dependencies),
  query_id: String,
) -> Nil {
  scope.put(ctx.scope, answered_key, query_id)
}

/// The query already answered, if any. Peeks rather than consumes, so several
/// `auto_answer` calls within one update stay a single answer.
fn answered_query(
  ctx: Context(session, error, dependencies),
) -> Option(String) {
  scope.get(ctx.scope, answered_key)
  |> option.from_result
}

/// Start handling a callback query: forget a mark left by an *earlier* update.
///
/// A mark for this same query is kept — one update can run several dialog
/// steps (a `Goto` re-enters the step handler), and an `alert` from the first
/// of them must still count.
@internal
pub fn begin_callback_answer(
  ctx: Context(session, error, dependencies),
) -> Nil {
  case ctx.update {
    update.CallbackQueryUpdate(query:, ..) -> {
      let current = query.id
      case answered_query(ctx) {
        Some(id) if id != current -> reset_answered(ctx)
        _ -> Nil
      }
    }
    _ -> Nil
  }
}

/// Forget which query was answered. The runtime drops the whole scope between
/// updates; a test driver that replays one query id against a single context
/// needs this.
@internal
pub fn reset_answered(ctx: Context(session, error, dependencies)) -> Nil {
  scope.erase(ctx.scope, answered_key)
}

/// Human-readable description of a render error, for logs.
@internal
pub fn describe_error(error: RenderError) -> String {
  case error {
    ApiError(api_error) -> error.to_string(api_error)
    InvalidButton(action_id:, reason:) ->
      "invalid button '" <> action_id <> "': " <> reason
  }
}
