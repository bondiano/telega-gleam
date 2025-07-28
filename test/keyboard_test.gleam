import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import telega/bot.{HearTexts}
import telega/keyboard
import telega/model

pub fn main() {
  gleeunit.main()
}

pub fn new_keyboard_test() {
  let button1 = keyboard.button("Button 1")
  let button2 = keyboard.button("Button 2")
  let kb = keyboard.new([[button1, button2]])

  let markup = keyboard.to_markup(kb)
  case markup {
    model.SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
      should.equal(reply_keyboard.keyboard, [[button1, button2]])
      should.equal(reply_keyboard.resize_keyboard, None)
    }
    _ -> should.fail()
  }
}

pub fn keyboard_options_test() {
  let button = keyboard.button("Test")
  let kb =
    keyboard.new([[button]])
    |> keyboard.one_time()
    |> keyboard.persistent()
    |> keyboard.resized()
    |> keyboard.placeholder("Enter text...")
    |> keyboard.selected()

  let markup = keyboard.to_markup(kb)
  case markup {
    model.SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
      should.equal(reply_keyboard.one_time_keyboard, Some(True))
      should.equal(reply_keyboard.is_persistent, Some(True))
      should.equal(reply_keyboard.resize_keyboard, Some(True))
      should.equal(
        reply_keyboard.input_field_placeholder,
        Some("Enter text..."),
      )
      should.equal(reply_keyboard.selective, Some(True))
    }
    _ -> should.fail()
  }
}

pub fn contact_button_test() {
  let button = keyboard.contact_button("Share Contact")
  should.equal(button.text, "Share Contact")
  should.equal(button.request_contact, Some(True))
  should.equal(button.request_location, None)
}

pub fn location_button_test() {
  let button = keyboard.location_button("Share Location")
  should.equal(button.text, "Share Location")
  should.equal(button.request_location, Some(True))
  should.equal(button.request_contact, None)
}

pub fn poll_button_test() {
  let button = keyboard.poll_button("Create Poll", Some("quiz"))
  should.equal(button.text, "Create Poll")
  case button.request_poll {
    Some(poll_type) -> should.equal(poll_type.type_, Some("quiz"))
    None -> should.fail()
  }
}

pub fn web_app_button_test() {
  let button = keyboard.web_app_button("Open App", "https://example.com")
  should.equal(button.text, "Open App")
  case button.web_app {
    Some(web_app) -> should.equal(web_app.url, "https://example.com")
    None -> should.fail()
  }
}

pub fn new_inline_keyboard_test() {
  let button = keyboard.inline_url_button("URL", "https://example.com")
  let kb = keyboard.new_inline([[button]])

  let markup = keyboard.to_inline_markup(kb)
  case markup {
    model.SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) -> {
      should.equal(inline_keyboard.inline_keyboard, [[button]])
    }
    _ -> should.fail()
  }
}

pub fn inline_url_button_test() {
  let button = keyboard.inline_url_button("Visit", "https://example.com")
  should.equal(button.text, "Visit")
  should.equal(button.url, Some("https://example.com"))
  should.equal(button.callback_data, None)
}

pub fn inline_web_app_button_test() {
  let button = keyboard.inline_web_app_button("App", "https://app.example.com")
  should.equal(button.text, "App")
  case button.web_app {
    Some(web_app) -> should.equal(web_app.url, "https://app.example.com")
    None -> should.fail()
  }
  should.equal(button.callback_data, None)
}

pub fn inline_switch_query_button_test() {
  let button = keyboard.inline_switch_query_button("Share", "hello world")
  should.equal(button.text, "Share")
  should.equal(button.switch_inline_query, Some("hello world"))
  should.equal(button.callback_data, None)
}

pub fn inline_switch_query_current_chat_button_test() {
  let button =
    keyboard.inline_switch_query_current_chat_button("Share Here", "test")
  should.equal(button.text, "Share Here")
  should.equal(button.switch_inline_query_current_chat, Some("test"))
  should.equal(button.callback_data, None)
}

pub fn inline_copy_text_button_test() {
  let button = keyboard.inline_copy_text_button("Copy", "Hello World!")
  should.equal(button.text, "Copy")
  case button.copy_text {
    Some(copy_text) -> should.equal(copy_text.text, "Hello World!")
    None -> should.fail()
  }
  should.equal(button.callback_data, None)
}

pub fn callback_data_validation_valid_test() {
  let callback_data = keyboard.string_callback_data("test")
  let callback = keyboard.pack_callback(callback_data, "short")

  case keyboard.inline_button("Test", callback) {
    Ok(button) -> {
      should.equal(button.text, "Test")
      should.equal(button.callback_data, Some(callback.payload))
    }
    Error(_) -> should.fail()
  }
}

pub fn callback_data_validation_too_long_test() {
  let callback_data = keyboard.string_callback_data("test")
  let long_data =
    "this_is_a_very_long_string_that_exceeds_64_bytes_limit_for_callback_data_in_telegram_api"
  let callback = keyboard.pack_callback(callback_data, long_data)

  case keyboard.inline_button("Test", callback) {
    Ok(_) -> should.fail()
    Error(msg) ->
      should.be_true(string.starts_with(
        msg,
        "Callback data must be 1-64 bytes long",
      ))
  }
}

pub fn filter_inline_keyboard_query_valid_test() {
  let callback_data = keyboard.string_callback_data("action")
  let callback1 = keyboard.pack_callback(callback_data, "click")
  let callback2 = keyboard.pack_callback(callback_data, "tap")

  case keyboard.inline_button("Click", callback1) {
    Ok(button1) -> {
      case keyboard.inline_button("Tap", callback2) {
        Ok(button2) -> {
          let kb = keyboard.new_inline([[button1, button2]])
          case keyboard.filter_inline_keyboard_query(kb) {
            Ok(_filter) -> {
              should.be_true(True)
            }
            Error(_) -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn filter_inline_keyboard_query_empty_test() {
  let button = keyboard.inline_url_button("URL", "https://example.com")
  let kb = keyboard.new_inline([[button]])

  case keyboard.filter_inline_keyboard_query(kb) {
    Ok(_) -> should.fail()
    Error(msg) -> should.equal(msg, "No callback data found in keyboard")
  }
}

pub fn single_keyboard_test() {
  let button = keyboard.button("Single")
  let kb = keyboard.single(button)

  let markup = keyboard.to_markup(kb)
  case markup {
    model.SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
      should.equal(reply_keyboard.keyboard, [[button]])
    }
    _ -> should.fail()
  }
}

pub fn inline_single_test() {
  let button = keyboard.inline_url_button("Single", "https://example.com")
  let kb = keyboard.inline_single(button)

  let markup = keyboard.to_inline_markup(kb)
  case markup {
    model.SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) -> {
      should.equal(inline_keyboard.inline_keyboard, [[button]])
    }
    _ -> should.fail()
  }
}

pub fn grid_keyboard_test() {
  let buttons = [
    keyboard.button("1"),
    keyboard.button("2"),
    keyboard.button("3"),
    keyboard.button("4"),
  ]
  let kb = keyboard.grid(buttons, 2)

  let markup = keyboard.to_markup(kb)
  case markup {
    model.SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
      should.equal(reply_keyboard.keyboard, [
        [keyboard.button("1"), keyboard.button("2")],
        [keyboard.button("3"), keyboard.button("4")],
      ])
    }
    _ -> should.fail()
  }
}

pub fn inline_grid_test() {
  let buttons = [
    keyboard.inline_url_button("1", "https://1.com"),
    keyboard.inline_url_button("2", "https://2.com"),
    keyboard.inline_url_button("3", "https://3.com"),
  ]
  let kb = keyboard.inline_grid(buttons, 2)

  let markup = keyboard.to_inline_markup(kb)
  case markup {
    model.SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) -> {
      should.equal(inline_keyboard.inline_keyboard, [
        [
          keyboard.inline_url_button("1", "https://1.com"),
          keyboard.inline_url_button("2", "https://2.com"),
        ],
        [keyboard.inline_url_button("3", "https://3.com")],
      ])
    }
    _ -> should.fail()
  }
}

pub fn remove_keyboard_test() {
  let markup = keyboard.remove()
  case markup {
    model.SendMessageReplyRemoveKeyboardMarkupParameters(remove_keyboard) -> {
      should.equal(remove_keyboard.remove_keyboard, True)
      should.equal(remove_keyboard.selective, None)
    }
    _ -> should.fail()
  }
}

pub fn string_callback_data_test() {
  let callback_data = keyboard.string_callback_data("test")
  let callback = keyboard.pack_callback(callback_data, "hello")

  should.equal(callback.id, "test")
  should.equal(callback.payload, "test:hello")
  should.equal(callback.data, "hello")

  case keyboard.unpack_callback(callback.payload, callback_data) {
    Ok(unpacked) -> {
      should.equal(unpacked.id, "test")
      should.equal(unpacked.data, "hello")
    }
    Error(_) -> should.fail()
  }
}

pub fn int_callback_data_test() {
  let callback_data = keyboard.int_callback_data("page")
  let callback = keyboard.pack_callback(callback_data, 42)

  should.equal(callback.id, "page")
  should.equal(callback.payload, "page:42")
  should.equal(callback.data, 42)

  case keyboard.unpack_callback(callback.payload, callback_data) {
    Ok(unpacked) -> {
      should.equal(unpacked.id, "page")
      should.equal(unpacked.data, 42)
    }
    Error(_) -> should.fail()
  }
}

pub fn bool_callback_data_test() {
  let callback_data = keyboard.bool_callback_data("enabled")
  let callback_true = keyboard.pack_callback(callback_data, True)
  let callback_false = keyboard.pack_callback(callback_data, False)

  should.equal(callback_true.payload, "enabled:true")
  should.equal(callback_false.payload, "enabled:false")

  case keyboard.unpack_callback(callback_true.payload, callback_data) {
    Ok(unpacked) -> should.equal(unpacked.data, True)
    Error(_) -> should.fail()
  }

  case keyboard.unpack_callback(callback_false.payload, callback_data) {
    Ok(unpacked) -> should.equal(unpacked.data, False)
    Error(_) -> should.fail()
  }
}

pub fn callback_data_custom_delimiter_test() {
  let callback_data =
    keyboard.string_callback_data("test")
    |> keyboard.set_callback_data_delimiter("|")

  let callback = keyboard.pack_callback(callback_data, "hello")
  should.equal(callback.payload, "test|hello")

  case keyboard.unpack_callback(callback.payload, callback_data) {
    Ok(unpacked) -> should.equal(unpacked.data, "hello")
    Error(_) -> should.fail()
  }
}

pub fn row_functions_test() {
  let buttons = [keyboard.button("1"), keyboard.button("2")]
  let row = keyboard.row(buttons)
  should.equal(row, buttons)

  let inline_buttons = [keyboard.inline_url_button("1", "https://1.com")]
  let inline_row = keyboard.inline_row(inline_buttons)
  should.equal(inline_row, inline_buttons)
}

pub fn hear_keyboard_test() {
  let button1 = keyboard.button("Button 1")
  let button2 = keyboard.button("Button 2")
  let button3 = keyboard.button("Button 3")

  let kb = keyboard.new([[button1, button2], [button3]])
  let hears = keyboard.hear(kb)

  case hears {
    HearTexts(texts) -> {
      should.equal(texts, ["Button 1", "Button 2", "Button 3"])
    }
    _ -> should.fail()
  }
}
