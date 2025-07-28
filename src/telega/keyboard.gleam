//// # Keyboard Module
////
//// This module provides comprehensive keyboard functionality for Telegram bots, including:
//// - Regular reply keyboards with special buttons (contact, location, polls, etc.)
//// - Inline keyboards with callback data, URLs, and other interactive elements
//// - Helper functions for creating grid layouts and complex keyboard structures
//// - Type-safe callback data handling with validation
//// - Error handling and validation for Telegram API constraints
////
//// ## Quick Start
////
//// ### Basic Reply Keyboard
//// ```gleam
//// let keyboard = keyboard.new([
////   [keyboard.button("Option 1"), keyboard.button("Option 2")],
////   [keyboard.contact_button("📞 Share Contact"), keyboard.location_button("📍 Location")],
//// ])
//// |> keyboard.one_time()
//// |> keyboard.resized()
//// ```
////
//// ### Inline Keyboard with Callbacks
//// ```gleam
//// let callback_data = keyboard.string_callback_data("action")
//// let assert Ok(button) = keyboard.inline_button("Click Me", 
////   keyboard.pack_callback(callback_data, "click"))
//// 
//// let keyboard = keyboard.new_inline([[
////   button,
////   keyboard.inline_url_button("Visit", "https://example.com"),
//// ]])
////
//// // In your handler:
//// let assert Ok(filter) = keyboard.filter_inline_keyboard_query(keyboard)
//// ```
////
//// ### Grid Layouts
//// ```gleam
//// let buttons = [
////   keyboard.button("1"), keyboard.button("2"), 
////   keyboard.button("3"), keyboard.button("4"),
//// ]
//// let grid_keyboard = keyboard.grid(buttons, 2) // 2x2 grid
//// ```
////
//// ## Special Button Types
////
//// - **Contact buttons**: Request user's phone number
//// - **Location buttons**: Request user's location
//// - **Poll buttons**: Allow users to create polls
//// - **Web App buttons**: Launch mini-apps
//// - **User/Chat request buttons**: Request access to users or chats
////
//// ## Inline Button Types
////
//// - **Callback buttons**: Execute bot commands with data
//// - **URL buttons**: Open external links
//// - **Switch inline buttons**: Switch to inline mode
//// - **Copy text buttons**: Copy text to clipboard
//// - **Web app buttons**: Launch inline web applications
////
//// ## Error Handling
////
//// The module uses Result types for operations that can fail:
//// - Callback data validation (max 64 bytes)
//// - Inline button creation with validation
//// - Filter creation for callback queries
////
//// ## Best Practices
////
//// 1. **Use typed callback data** for better type safety
//// 2. **Validate callback data length** before creating buttons
//// 3. **Use grid layouts** for better UX with many buttons
//// 4. **Handle Result types** properly when using validation functions
//// 5. **Use one-time keyboards** for single-use interactions
////
//// ## Advanced Usage Patterns
////
//// ### Dynamic Keyboards
//// ```gleam
//// // Create keyboards based on data
//// pub fn create_user_list_keyboard(users: List(User)) -> InlineKeyboard {
////   let user_callback = keyboard.int_callback_data("select_user")
////   let buttons = list.filter_map(users, fn(user) {
////     let callback = keyboard.pack_callback(user_callback, user.id)
////     case keyboard.inline_button(user.name, callback) {
////       Ok(button) -> Some(button)
////       Error(_) -> None
////     }
////   })
////   keyboard.inline_grid(buttons, 2) // 2 columns
//// }
//// ```
////
//// ### Pagination Pattern
//// ```gleam
//// pub fn create_pagination_keyboard(
////   current_page: Int,
////   total_pages: Int,
//// ) -> InlineKeyboard {
////   let page_callback = keyboard.int_callback_data("page")
////   let buttons = []
////   
////   // Build buttons list
////   let buttons = case current_page > 1 {
////     True -> {
////       let prev_callback = keyboard.pack_callback(page_callback, current_page - 1)
////       case keyboard.inline_button("← Previous", prev_callback) {
////         Ok(prev_btn) -> [prev_btn, ..buttons]
////         Error(_) -> buttons
////       }
////     }
////     False -> buttons
////   }
////   
////   // Add page indicator
////   let page_info = int.to_string(current_page) <> "/" <> int.to_string(total_pages)
////   let info_btn = keyboard.inline_copy_text_button(page_info, page_info)
////   let buttons = [info_btn, ..buttons]
////   
////   // Add next button
////   let buttons = case current_page < total_pages {
////     True -> {
////       let next_callback = keyboard.pack_callback(page_callback, current_page + 1)
////       case keyboard.inline_button("Next →", next_callback) {
////         Ok(next_btn) -> [next_btn, ..buttons]
////         Error(_) -> buttons
////       }
////     }
////     False -> buttons
////   }
////   
////   keyboard.new_inline([list.reverse(buttons)])
//// }
//// ```
////
//// ### Error Handling Best Practices
//// ```gleam
//// // Always handle Result types properly
//// case keyboard.inline_button("Action", callback) {
////   Ok(button) -> {
////     let keyboard = keyboard.inline_single(button)
////     reply.with_markup(ctx, "Choose action:", keyboard.to_inline_markup(keyboard))
////   }
////   Error(msg) -> {
////     // Log the error and provide fallback
////     logging.log(logging.Error, "Keyboard error: " <> msg)
////     reply.with_text(ctx, "Sorry, something went wrong.")
////   }
//// }
//// ```
////
//// ### Performance Tips
//// - Use `grid()` and `inline_grid()` for better organization
//// - Keep callback data under 64 bytes (validated automatically)
//// - Use typed callback data for better type safety
//// - Cache callback data configurations to avoid recreation
//// - Consider using `one_time()` keyboards for single interactions

import gleam/int
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

/// Create a new reply keyboard from a list of button rows.
///
/// ## Example
/// ```gleam
/// let keyboard = keyboard.new([
///   [keyboard.button("Yes"), keyboard.button("No")],
///   [keyboard.button("Cancel")],
/// ])
/// ```
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

/// Extract button texts from a keyboard for use with `telega.wait_hears()`.
/// This is useful for listening to button presses in conversation flows.
///
/// ## Example
/// ```gleam
/// let keyboard = keyboard.new([[keyboard.button("Yes"), keyboard.button("No")]])
/// let hears = keyboard.hear(keyboard)
/// 
/// use _, text <- telega.wait_hears(ctx:, hears:, or: None, timeout: None)
/// case text {
///   "Yes" -> // handle yes
///   "No" -> // handle no
///   _ -> // handle other
/// }
/// ```
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

// Helper functions for easier keyboard creation

/// Create a keyboard row from a list of buttons
pub fn row(buttons: List(KeyboardButton)) -> List(KeyboardButton) {
  buttons
}

/// Create an inline keyboard row from a list of buttons
pub fn inline_row(
  buttons: List(InlineKeyboardButton),
) -> List(InlineKeyboardButton) {
  buttons
}

/// Create a grid keyboard with buttons arranged in rows of specified width.
/// This is useful for creating organized layouts with many buttons.
///
/// ## Example
/// ```gleam
/// let buttons = [
///   keyboard.button("1"), keyboard.button("2"), keyboard.button("3"),
///   keyboard.button("4"), keyboard.button("5"), keyboard.button("6"),
/// ]
/// let grid_keyboard = keyboard.grid(buttons, 3) // 3 columns per row
/// // Results in: [[1, 2, 3], [4, 5, 6]]
/// ```
pub fn grid(buttons: List(KeyboardButton), columns: Int) -> Keyboard {
  let rows = chunk_list(buttons, columns)
  new(rows)
}

/// Create a grid inline keyboard with buttons arranged in rows of specified width
pub fn inline_grid(
  buttons: List(InlineKeyboardButton),
  columns: Int,
) -> InlineKeyboard {
  let rows = chunk_list(buttons, columns)
  new_inline(rows)
}

/// Split a list into chunks of specified size
fn chunk_list(list: List(a), size: Int) -> List(List(a)) {
  case list {
    [] -> []
    _ -> {
      let #(chunk, rest) = list.split(list, size)
      [chunk, ..chunk_list(rest, size)]
    }
  }
}

/// Remove keyboard markup - useful for hiding keyboards
pub fn remove() -> model.SendMessageReplyMarkupParameters {
  model.SendMessageReplyRemoveKeyboardMarkupParameters(
    model.ReplyKeyboardRemove(remove_keyboard: True, selective: None),
  )
}

/// Create a single-button keyboard
pub fn single(button: KeyboardButton) -> Keyboard {
  new([[button]])
}

/// Create a single-button inline keyboard
pub fn inline_single(button: InlineKeyboardButton) -> InlineKeyboard {
  new_inline([[button]])
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

/// Create a button that requests the user's contact information.
/// When pressed, the user will be prompted to share their phone number.
///
/// ## Example
/// ```gleam
/// let contact_btn = keyboard.contact_button("📞 Share Contact")
/// let keyboard = keyboard.single(contact_btn)
/// ```
pub fn contact_button(text: String) -> KeyboardButton {
  KeyboardButton(..button(text), request_contact: Some(True))
}

/// Create a button that requests the user's location.
/// When pressed, the user will be prompted to share their current location.
///
/// ## Example
/// ```gleam
/// let location_btn = keyboard.location_button("📍 Share Location")
/// let keyboard = keyboard.single(location_btn)
/// ```
pub fn location_button(text: String) -> KeyboardButton {
  KeyboardButton(..button(text), request_location: Some(True))
}

/// Create a button that requests poll creation
pub fn poll_button(
  text: String,
  poll_type poll_type: Option(String),
) -> KeyboardButton {
  KeyboardButton(
    ..button(text),
    request_poll: Some(model.KeyboardButtonPollType(type_: poll_type)),
  )
}

/// Create a button that requests users to be shared
pub fn users_button(
  text: String,
  request_id: Int,
  user_is_bot: Option(Bool),
  user_is_premium: Option(Bool),
  max_quantity: Option(Int),
  request_name: Option(Bool),
  request_username: Option(Bool),
  request_photo: Option(Bool),
) -> KeyboardButton {
  KeyboardButton(
    ..button(text),
    request_users: Some(model.KeyboardButtonRequestUsers(
      request_id:,
      user_is_bot:,
      user_is_premium:,
      max_quantity:,
      request_name:,
      request_username:,
      request_photo:,
    )),
  )
}

/// Create a button that requests a chat to be shared
pub fn chat_button(
  text: String,
  request_id: Int,
  chat_is_channel: Bool,
  chat_is_forum: Option(Bool),
  chat_has_username: Option(Bool),
  chat_is_created: Option(Bool),
  user_administrator_rights: Option(model.ChatAdministratorRights),
  bot_administrator_rights: Option(model.ChatAdministratorRights),
  bot_is_member: Option(Bool),
  request_title: Option(Bool),
  request_username: Option(Bool),
  request_photo: Option(Bool),
) -> KeyboardButton {
  KeyboardButton(
    ..button(text),
    request_chat: Some(model.KeyboardButtonRequestChat(
      request_id:,
      chat_is_channel:,
      chat_is_forum:,
      chat_has_username:,
      chat_is_created:,
      user_administrator_rights:,
      bot_administrator_rights:,
      bot_is_member:,
      request_title:,
      request_username:,
      request_photo:,
    )),
  )
}

// Inline keyboard ------------------------------------------------------------------------------------

pub opaque type InlineKeyboard {
  InlineKeyboard(buttons: List(List(InlineKeyboardButton)))
}

/// Create a new inline keyboard from a list of button rows.
/// Inline keyboards appear directly below messages and don't replace the user's keyboard.
///
/// ## Example
/// ```gleam
/// let callback_data = keyboard.string_callback_data("action")
/// let assert Ok(callback_btn) = keyboard.inline_button("Click", 
///   keyboard.pack_callback(callback_data, "click"))
/// 
/// let keyboard = keyboard.new_inline([
///   [callback_btn, keyboard.inline_url_button("Visit", "https://example.com")],
///   [keyboard.inline_copy_text_button("Copy", "Hello World!")],
/// ])
/// ```
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

/// Create a new inline button with callback data
pub fn inline_button(
  text text: String,
  callback_data callback_data: KeyboardCallback(data),
) -> Result(InlineKeyboardButton, String) {
  case validate_callback_data(callback_data.payload) {
    Ok(_) ->
      Ok(InlineKeyboardButton(
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
      ))
    Error(msg) -> Error(msg)
  }
}

/// Create an inline URL button
pub fn inline_url_button(
  text text: String,
  url url: String,
) -> InlineKeyboardButton {
  InlineKeyboardButton(
    text:,
    url: Some(url),
    callback_data: None,
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

/// Create an inline web app button
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

/// Create an inline switch query button
pub fn inline_switch_query_button(
  text text: String,
  query query: String,
) -> InlineKeyboardButton {
  InlineKeyboardButton(
    text:,
    switch_inline_query: Some(query),
    callback_data: None,
    url: None,
    login_url: None,
    pay: None,
    switch_inline_query_current_chat: None,
    switch_inline_query_chosen_chat: None,
    web_app: None,
    callback_game: None,
    copy_text: None,
  )
}

/// Create an inline switch query current chat button
pub fn inline_switch_query_current_chat_button(
  text text: String,
  query query: String,
) -> InlineKeyboardButton {
  InlineKeyboardButton(
    text:,
    switch_inline_query_current_chat: Some(query),
    callback_data: None,
    url: None,
    login_url: None,
    pay: None,
    switch_inline_query: None,
    switch_inline_query_chosen_chat: None,
    web_app: None,
    callback_game: None,
    copy_text: None,
  )
}

/// Create an inline copy text button
pub fn inline_copy_text_button(
  text text: String,
  copy_text copy_text: String,
) -> InlineKeyboardButton {
  InlineKeyboardButton(
    text:,
    copy_text: Some(model.CopyTextButton(text: copy_text)),
    callback_data: None,
    url: None,
    login_url: None,
    pay: None,
    switch_inline_query: None,
    switch_inline_query_current_chat: None,
    switch_inline_query_chosen_chat: None,
    web_app: None,
    callback_game: None,
  )
}

/// Create a filter for inline keyboard callback queries.
/// This filter can be used with `telega.wait_callback_query()` to only listen
/// for callbacks from buttons in this specific keyboard.
///
/// ## Example
/// ```gleam
/// let callback_data = keyboard.string_callback_data("action")
/// let assert Ok(button1) = keyboard.inline_button("Yes", 
///   keyboard.pack_callback(callback_data, "yes"))
/// let assert Ok(button2) = keyboard.inline_button("No", 
///   keyboard.pack_callback(callback_data, "no"))
/// 
/// let keyboard = keyboard.new_inline([[button1, button2]])
/// let assert Ok(filter) = keyboard.filter_inline_keyboard_query(keyboard)
/// 
/// // In your handler:
/// use ctx, payload, query_id <- telega.wait_callback_query(
///   ctx:, filter:, or: None, timeout: None
/// )
/// let assert Ok(callback) = keyboard.unpack_callback(payload, callback_data)
/// ```
/// 
/// ## Errors
/// - Returns `Error` if the keyboard has no callback buttons
/// - Returns `Error` if the callback data creates an invalid regex pattern
pub fn filter_inline_keyboard_query(
  keyboard: InlineKeyboard,
) -> Result(CallbackQueryFilter, String) {
  let options =
    keyboard.buttons
    |> list.flat_map(fn(row) {
      list.map(row, fn(button) { button.callback_data })
    })
    |> option.values
    |> string.join("|")

  case options {
    "" -> Error("No callback data found in keyboard")
    _ ->
      case regexp.from_string("^(" <> options <> ")$") {
        Ok(re) -> Ok(CallbackQueryFilter(re))
        Error(_) -> Error("Invalid regex pattern from callback data")
      }
  }
}

/// Validate callback data according to Telegram API limits
fn validate_callback_data(data: String) -> Result(Nil, String) {
  let byte_length = string.byte_size(data)
  case byte_length > 64 {
    True ->
      Error(
        "Callback data must be 1-64 bytes long, got "
        <> int.to_string(byte_length)
        <> " bytes",
      )
    False -> Ok(Nil)
  }
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

/// Create a new callback data configuration for inline keyboard buttons.
/// This defines how data is serialized/deserialized when buttons are pressed.
///
/// ## Parameters
/// - `id`: Unique identifier for this callback type
/// - `serialize`: Function to convert your data to a string
/// - `deserialize`: Function to convert string back to your data
///
/// ## Example
/// ```gleam
/// // For custom enum types
/// pub type Action {
///   Save
///   Delete
///   Edit
/// }
/// 
/// let action_callback = keyboard.new_callback_data(
///   id: "action",
///   serialize: fn(action) { 
///     case action {
///       Save -> "save"
///       Delete -> "delete" 
///       Edit -> "edit"
///     }
///   },
///   deserialize: fn(str) {
///     case str {
///       "save" -> Save
///       "delete" -> Delete
///       _ -> Edit
///     }
///   }
/// )
/// ```
pub fn new_callback_data(
  id id: String,
  serialize serialize: fn(data) -> String,
  deserialize deserialize: fn(String) -> data,
) -> KeyboardCallbackData(data) {
  KeyboardCallbackData(id:, serialize:, deserialize:, delimiter: ":")
}

/// Change the delimiter for the callback data, useful if you need to use `:` in the id
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

// Convenience functions for common callback data patterns

/// Create a simple string callback data configuration.
/// This is the most common type for simple string-based callbacks.
///
/// ## Example
/// ```gleam
/// let callback_data = keyboard.string_callback_data("action")
/// let callback = keyboard.pack_callback(callback_data, "delete_user")
/// let assert Ok(button) = keyboard.inline_button("Delete", callback)
/// 
/// // In your callback handler:
/// let assert Ok(unpacked) = keyboard.unpack_callback(payload, callback_data)
/// case unpacked.data {
///   "delete_user" -> // handle deletion
///   _ -> // handle other actions
/// }
/// ```
pub fn string_callback_data(id: String) -> KeyboardCallbackData(String) {
  new_callback_data(id: id, serialize: fn(data) { data }, deserialize: fn(data) {
    data
  })
}

/// Create an integer callback data configuration.
/// Useful for pagination, user IDs, or any numeric data.
///
/// ## Example
/// ```gleam
/// let page_callback = keyboard.int_callback_data("page")
/// let next_page = keyboard.pack_callback(page_callback, 2)
/// let assert Ok(button) = keyboard.inline_button("Next →", next_page)
/// 
/// // In your callback handler:
/// let assert Ok(unpacked) = keyboard.unpack_callback(payload, page_callback)
/// let page_number = unpacked.data // Int
/// ```
pub fn int_callback_data(id: String) -> KeyboardCallbackData(Int) {
  new_callback_data(id: id, serialize: int.to_string, deserialize: fn(data) {
    case int.parse(data) {
      Ok(i) -> i
      Error(_) -> 0
    }
  })
}

/// Create a boolean callback data configuration.
/// Useful for toggle buttons, settings, or yes/no choices.
///
/// ## Example
/// ```gleam
/// let toggle_callback = keyboard.bool_callback_data("notifications")
/// let enable_btn = keyboard.pack_callback(toggle_callback, True)
/// let disable_btn = keyboard.pack_callback(toggle_callback, False)
/// 
/// let assert Ok(enable) = keyboard.inline_button("🔔 Enable", enable_btn)
/// let assert Ok(disable) = keyboard.inline_button("🔕 Disable", disable_btn)
/// 
/// // In your callback handler:
/// let assert Ok(unpacked) = keyboard.unpack_callback(payload, toggle_callback)
/// case unpacked.data {
///   True -> // enable notifications
///   False -> // disable notifications
/// }
/// ```
pub fn bool_callback_data(id: String) -> KeyboardCallbackData(Bool) {
  new_callback_data(
    id: id,
    serialize: fn(data) {
      case data {
        True -> "true"
        False -> "false"
      }
    },
    deserialize: fn(data) { data == "true" },
  )
}
