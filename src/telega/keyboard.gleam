//// This module contains the keyboard constructors and useful utilities to work with keyboards
//// You can create a keyboard with `new` or `new_inline`.
////
//// The simplest way to create a keyboard is to use `new` and use `hear` to listen for button presses:
//// ```gleam
//// let keyboard = keyboard.new([
////   [keyboard.button("Button 1"), keyboard.button("Button 2")],
////   [keyboard.button("Button 3"), keyboard.button("Button 4")],
//// ])
//// ```
////
//// If you're using inline keyboard, you can use `new_inline` and `filter_inline_keyboard_query` to listen for button presses:
////
//// ```gleam
//// let keyboard = keyboard.new_inline([
////   [keyboard.inline_button("Button 1", keyboard.pack_callback(callback_data, "data"))],
//// ])
////
//// // In handler:
//// let filter = keyboard.filter_inline_keyboard_query(keyboard)
//// ```

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/result
import gleam/string
import telega/bot.{
  type CallbackQueryFilter, type Hears, CallbackQueryFilter, HearTexts,
}
import telega/model.{
  type InlineKeyboardButton, type KeyboardButton, InlineKeyboardButton,
  KeyboardButton,
}

// Keyboard -------------------------------------------------------------------------------------------

pub opaque type Keyboard {
  Keyboard(
    buttons: List(List(KeyboardButton)),
    is_persistent: Option(Bool),
    resize_keyboard: Option(Bool),
    one_time_keyboard: Option(Bool),
    input_field_placeholder: Option(String),
    selective: Option(Bool),
  )
}

/// Create a new keyboard
pub fn new(buttons: List(List(KeyboardButton))) -> Keyboard {
  Keyboard(
    buttons: buttons,
    is_persistent: None,
    resize_keyboard: None,
    one_time_keyboard: None,
    input_field_placeholder: None,
    selective: None,
  )
}

pub fn hear(keyboard: Keyboard) -> Hears {
  keyboard.buttons
  |> list.flat_map(fn(row) { list.map(row, fn(button) { button.text }) })
  |> HearTexts
}

/// Build a reply markup for `Message` from a keyboard
pub fn to_markup(keyboard: Keyboard) -> model.SendMessageReplyMarkupParameters {
  model.SendMessageReplyReplyKeyboardMarkupParameters(model.ReplyKeyboardMarkup(
    keyboard: keyboard.buttons,
    resize_keyboard: keyboard.resize_keyboard,
    one_time_keyboard: keyboard.one_time_keyboard,
    selective: keyboard.selective,
    input_field_placeholder: keyboard.input_field_placeholder,
    is_persistent: keyboard.is_persistent,
  ))
}

/// Make the keyboard one-time
pub fn one_time(keyboard: Keyboard) -> Keyboard {
  Keyboard(..keyboard, one_time_keyboard: Some(True))
}

/// Make the keyboard persistent
pub fn persistent(keyboard: Keyboard) -> Keyboard {
  Keyboard(..keyboard, is_persistent: Some(True))
}

/// Make the keyboard resizable
pub fn resized(keyboard: Keyboard) -> Keyboard {
  Keyboard(..keyboard, resize_keyboard: Some(True))
}

/// Set the placeholder for the input field
pub fn placeholder(keyboard: Keyboard, text: String) -> Keyboard {
  Keyboard(..keyboard, input_field_placeholder: Some(text))
}

/// Make the keyboard selective.
/// Use this parameter if you want to show the keyboard to specific users only.
pub fn selected(keyboard: Keyboard) -> Keyboard {
  Keyboard(..keyboard, selective: Some(True))
}

/// Create a new keyboard button
pub fn button(text: String) -> KeyboardButton {
  KeyboardButton(
    text:,
    request_users: None,
    request_chat: None,
    request_contact: None,
    request_location: None,
    request_poll: None,
    web_app: None,
  )
}

/// Create a new web app button
pub fn web_app_button(text text: String, url url: String) -> KeyboardButton {
  KeyboardButton(..button(text), web_app: Some(model.WebAppInfo(url:)))
}

// Inline keyboard ------------------------------------------------------------------------------------

pub opaque type InlineKeyboard {
  InlineKeyboard(buttons: List(List(InlineKeyboardButton)))
}

/// Create a new inline keyboard
pub fn new_inline(buttons: List(List(InlineKeyboardButton))) -> InlineKeyboard {
  InlineKeyboard(buttons)
}

/// Build a reply markup for `Message` from an inline keyboard
pub fn to_inline_markup(
  keyboard: InlineKeyboard,
) -> model.SendMessageReplyMarkupParameters {
  model.SendMessageReplyInlineKeyboardMarkupParameters(
    model.InlineKeyboardMarkup(inline_keyboard: keyboard.buttons),
  )
}

/// Create a new inline button
pub fn inline_button(
  text text: String,
  callback_data callback_data: KeyboardCallback(data),
) -> InlineKeyboardButton {
  InlineKeyboardButton(
    text:,
    callback_data: Some(callback_data.payload),
    url: None,
    login_url: None,
    pay: None,
    switch_inline_query: None,
    switch_inline_query_current_chat: None,
    switch_inline_query_chosen_chat: None,
    web_app: None,
    callback_game: None,
    copy_text: None,
  )
}

/// Create a new web app button
pub fn inline_web_app_button(
  text text: String,
  url url: String,
) -> InlineKeyboardButton {
  InlineKeyboardButton(
    text:,
    web_app: Some(model.WebAppInfo(url:)),
    callback_data: None,
    url: None,
    login_url: None,
    pay: None,
    switch_inline_query: None,
    switch_inline_query_current_chat: None,
    switch_inline_query_chosen_chat: None,
    callback_game: None,
    copy_text: None,
  )
}

/// Filter for inline keyboard queries
pub fn filter_inline_keyboard_query(
  keyboard: InlineKeyboard,
) -> CallbackQueryFilter {
  let options =
    keyboard.buttons
    |> list.flat_map(fn(row) {
      list.map(row, fn(button) { button.callback_data })
    })
    |> option.values
    |> string.join("|")

  let assert Ok(re) = regexp.from_string("^(" <> options <> ")$")

  CallbackQueryFilter(re)
}

// Callback --------------------------------------------------------------------------------------------

pub opaque type KeyboardCallbackData(data) {
  KeyboardCallbackData(
    id: String,
    serialize: fn(data) -> String,
    deserialize: fn(String) -> data,
    delimiter: String,
  )
}

pub type KeyboardCallback(data) {
  KeyboardCallback(
    data: data,
    id: String,
    payload: String,
    callback_data: KeyboardCallbackData(data),
  )
}

/// Create a new callback data for inline keyboard buttons
pub fn new_callback_data(
  id id: String,
  serialize serialize: fn(data) -> String,
  deserialize deserialize: fn(String) -> data,
) -> KeyboardCallbackData(data) {
  KeyboardCallbackData(id:, serialize:, deserialize:, delimiter: ":")
}

/// Change the delimiter for the callback data, usefull if you need to use `:` in the id
pub fn set_callback_data_delimiter(
  data: KeyboardCallbackData(data),
  delimiter: String,
) -> KeyboardCallbackData(data) {
  KeyboardCallbackData(..data, delimiter: delimiter)
}

/// Pack callback data into a callback
pub fn pack_callback(
  callback_data callback_data: KeyboardCallbackData(data),
  data data: data,
) -> KeyboardCallback(data) {
  let payload =
    callback_data.id <> callback_data.delimiter <> callback_data.serialize(data)

  KeyboardCallback(data:, payload:, callback_data:, id: callback_data.id)
}

/// Unpack payload into a callback
pub fn unpack_callback(
  payload payload: String,
  callback_data callback_data: KeyboardCallbackData(data),
) -> Result(KeyboardCallback(data), Nil) {
  use #(id, data) <- result.try(string.split_once(
    payload,
    callback_data.delimiter,
  ))

  Ok(KeyboardCallback(
    id:,
    payload:,
    callback_data:,
    data: callback_data.deserialize(data),
  ))
}
