//// # Dialog Module
////
//// Simple, immediate dialog utilities for Telegram bot conversations.
//// Uses continuation-passing style for sequential operations within a single handler.
////
//// ## When to Use
////
//// - Simple question-answer interactions
//// - Input validation with retry logic
//// - Menu selections with inline keyboards
//// - Single-message exchanges
//// - Temporary conversations that don't need persistence
////
//// ## Dialog vs Flow
////
//// - **Dialog**: Simple, immediate interactions within one handler session
//// - **Flow**: Complex, persistent multi-step processes with external storage
////
//// Use Dialog for quick interactions, use Flow for complex workflows.
////
//// ## Example
////
//// ```gleam
//// // Ask questions sequentially
//// use ctx, name <- dialog.ask(ctx, "What's your name?", None)
//// use ctx, age <- dialog.ask(ctx, "How old are you?", None)
////
//// // With validation
//// use ctx, email <- dialog.ask_validated(
////   ctx,
////   "Enter your email:",
////   validate_email,
////   retry_prompt: Some("Invalid email. Try again:"),
////   max_attempts: Some(3),
////   timeout: None,
//// )
////
//// // Menu selection
//// use ctx, color <- dialog.select_menu(
////   ctx,
////   "Choose a color:",
////   [#("🔴 Red", "red"), #("🔵 Blue", "blue")],
////   timeout: None,
//// )
//// ```
////
//// ## Comparison
////
//// - Use `dialog` for simple, immediate interactions
//// - Use `flow` for multi-step processes with navigation

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import telega.{wait_callback_query, wait_text}
import telega/api
import telega/bot.{type Context}
import telega/error
import telega/model/types.{
  type InlineKeyboardButton, type Message, InlineKeyboardButton,
  InlineKeyboardMarkup, Int as IntId, SendMessageParameters,
  SendMessageReplyInlineKeyboardMarkupParameters,
}
import telega/update

/// Helper function to get chat_id from update
fn get_chat_id(upd: update.Update) -> Int {
  upd.chat_id
}

/// Helper to send text with inline keyboard buttons
fn send_with_inline_keyboard_buttons(
  ctx: Context(session, error),
  text: String,
  buttons: List(List(InlineKeyboardButton)),
) -> Result(Message, error.TelegaError) {
  let markup = InlineKeyboardMarkup(inline_keyboard: buttons)
  let params =
    SendMessageParameters(
      business_connection_id: None,
      chat_id: IntId(get_chat_id(ctx.update)),
      message_thread_id: None,
      text:,
      parse_mode: None,
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      allow_paid_broadcast: None,
      message_effect_id: None,
      reply_parameters: None,
      reply_markup: Some(SendMessageReplyInlineKeyboardMarkupParameters(markup)),
    )
  api.send_message(ctx.config.api_client, params)
}

/// Helper to send text without keyboard
fn send_text(
  ctx: Context(session, error),
  text: String,
) -> Result(Message, error.TelegaError) {
  let params =
    SendMessageParameters(
      business_connection_id: None,
      chat_id: IntId(get_chat_id(ctx.update)),
      message_thread_id: None,
      text:,
      parse_mode: None,
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      allow_paid_broadcast: None,
      message_effect_id: None,
      reply_parameters: None,
      reply_markup: None,
    )
  api.send_message(ctx.config.api_client, params)
}

/// Ask a question and wait for text response.
///
/// Sends a prompt message to the user and waits for their text reply.
/// Uses continuation-passing style to handle the response.
///
/// ## Parameters
/// - `ctx`: Current bot context
/// - `prompt`: Question text to send to user
/// - `timeout`: Optional timeout in milliseconds
/// - `continue`: Continuation function that receives the user's response
///
/// ## Example
/// ```gleam
/// use ctx, name <- dialog.ask(ctx, "What's your name?", Some(30_000))
/// use ctx, age <- dialog.ask(ctx, "How old are you, " <> name <> "?", None)
/// reply.with_text(ctx, "Thanks " <> name <> "!")
/// ```
pub fn ask(
  ctx: Context(session, error),
  prompt: String,
  timeout: Option(Int),
  continue: fn(Context(session, error), String) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let _ = send_text(ctx, prompt)
  use ctx, text <- wait_text(ctx, or: None, timeout:)
  continue(ctx, text)
}

/// Present a menu with inline keyboard buttons for selection.
///
/// Creates an inline keyboard with options and waits for user selection.
/// Each option is a tuple of display text and associated value.
///
/// ## Parameters
/// - `ctx`: Current bot context
/// - `prompt`: Message to display with the menu
/// - `options`: List of tuples (display_text, value)
/// - `timeout`: Optional timeout in milliseconds
/// - `continue`: Continuation receiving Some(value) on selection, None on timeout
///
/// ## Example
/// ```gleam
/// use ctx, color <- dialog.select_menu(
///   ctx,
///   "Choose your favorite color:",
///   [
///     #("🔴 Red", "red"),
///     #("🔵 Blue", "blue"),
///     #("🟢 Green", "green"),
///   ],
///   timeout: Some(60_000),
/// )
///
/// case color {
///   Some(c) -> reply.with_text(ctx, "You chose " <> c)
///   None -> reply.with_text(ctx, "No selection made")
/// }
/// ```
pub fn select_menu(
  ctx: Context(session, error),
  prompt: String,
  options: List(#(String, a)),
  timeout: Option(Int),
  continue: fn(Context(session, error), Option(a)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let buttons =
    list.index_map(options, fn(opt, idx) {
      let #(label, _value) = opt
      let callback_data = int.to_string(idx)
      InlineKeyboardButton(
        text: label,
        url: None,
        callback_data: Some(callback_data),
        web_app: None,
        login_url: None,
        switch_inline_query: None,
        switch_inline_query_current_chat: None,
        switch_inline_query_chosen_chat: None,
        callback_game: None,
        pay: None,
        copy_text: None,
      )
    })

  let keyboard_buttons = [buttons]

  let _ = send_with_inline_keyboard_buttons(ctx, prompt, keyboard_buttons)

  use ctx, data, _id <- wait_callback_query(
    ctx,
    filter: None,
    or: None,
    timeout:,
  )

  let selected = case int.parse(data) {
    Ok(idx) -> {
      case list_at(options, idx) {
        Ok(#(_label, value)) -> Some(value)
        Error(_) -> None
      }
    }
    Error(_) -> None
  }

  continue(ctx, selected)
}

/// Helper to get list element at index
fn list_at(list: List(a), index: Int) -> Result(a, Nil) {
  case list, index {
    [], _ -> Error(Nil)
    [head, ..], 0 -> Ok(head)
    [_, ..tail], n -> list_at(tail, n - 1)
  }
}

/// Create a router handler for a dialog
///
/// ## Example
///
/// ```gleam
/// fn greeting_dialog(ctx) {
///   use ctx <- dialog.ask(ctx, "What's your name?")
///   use ctx, name <- dialog.wait_text(ctx)
///   dialog.reply(ctx, "Nice to meet you, " <> name.text <> "!")
/// }
///
/// router.new("my_bot")
///   |> router.on_command("greet", dialog.to_handler(greeting_dialog))
/// ```
pub fn to_handler(
  dialog_fn: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _update) { dialog_fn(ctx) }
}
