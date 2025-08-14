import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import telega/bot.{HearTexts}
import telega/keyboard
import telega/model/types.{
  SendMessageReplyInlineKeyboardMarkupParameters,
  SendMessageReplyRemoveKeyboardMarkupParameters,
  SendMessageReplyReplyKeyboardMarkupParameters,
}

pub fn main() {
  gleeunit.main()
}

pub fn new_keyboard_test() {
  let button1 = keyboard.button("Button 1")
  let button2 = keyboard.button("Button 2")
  let kb = keyboard.new([[button1, button2]])

  let markup = keyboard.to_markup(kb)
  case markup {
    SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
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
    SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
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
    SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) -> {
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
    SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
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
    SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) -> {
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
    SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
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
    SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) -> {
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
    SendMessageReplyRemoveKeyboardMarkupParameters(remove_keyboard) -> {
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

pub fn keyboard_builder_basic_test() {
  let kb =
    keyboard.builder()
    |> keyboard.text("Button 1")
    |> keyboard.text("Button 2")
    |> keyboard.build()

  let markup = keyboard.to_markup(kb)
  case markup {
    SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
      should.equal(reply_keyboard.keyboard, [
        [keyboard.button("Button 1"), keyboard.button("Button 2")],
      ])
    }
    _ -> should.fail()
  }
}

pub fn keyboard_builder_multi_row_test() {
  let kb =
    keyboard.builder()
    |> keyboard.text("Row 1 Button 1")
    |> keyboard.text("Row 1 Button 2")
    |> keyboard.next_row()
    |> keyboard.text("Row 2 Button 1")
    |> keyboard.build()

  let markup = keyboard.to_markup(kb)
  case markup {
    SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
      should.equal(reply_keyboard.keyboard, [
        [keyboard.button("Row 1 Button 1"), keyboard.button("Row 1 Button 2")],
        [keyboard.button("Row 2 Button 1")],
      ])
    }
    _ -> should.fail()
  }
}

pub fn keyboard_builder_special_buttons_test() {
  let kb =
    keyboard.builder()
    |> keyboard.contact("Share Contact")
    |> keyboard.location("Share Location")
    |> keyboard.next_row()
    |> keyboard.web_app("Open App", "https://example.com")
    |> keyboard.build()

  let markup = keyboard.to_markup(kb)
  case markup {
    SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
      let expected_row1 = [
        keyboard.contact_button("Share Contact"),
        keyboard.location_button("Share Location"),
      ]
      let expected_row2 = [
        keyboard.web_app_button("Open App", "https://example.com"),
      ]
      should.equal(reply_keyboard.keyboard, [expected_row1, expected_row2])
    }
    _ -> should.fail()
  }
}

pub fn keyboard_builder_empty_test() {
  let kb =
    keyboard.builder()
    |> keyboard.build()

  let markup = keyboard.to_markup(kb)
  case markup {
    SendMessageReplyReplyKeyboardMarkupParameters(reply_keyboard) -> {
      should.equal(reply_keyboard.keyboard, [])
    }
    _ -> should.fail()
  }
}

pub fn inline_keyboard_builder_basic_test() {
  let callback_data = keyboard.string_callback_data("action")
  let callback1 = keyboard.pack_callback(callback_data, "btn1")
  let callback2 = keyboard.pack_callback(callback_data, "btn2")

  case
    keyboard.inline_builder()
    |> keyboard.inline_text("Button 1", callback1)
  {
    Ok(builder) -> {
      case keyboard.inline_text(builder, "Button 2", callback2) {
        Ok(builder) -> {
          let kb = keyboard.inline_build(builder)
          let markup = keyboard.to_inline_markup(kb)
          case markup {
            SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) -> {
              case inline_keyboard.inline_keyboard {
                [[button1, button2]] -> {
                  should.equal(button1.text, "Button 1")
                  should.equal(button2.text, "Button 2")
                }
                _ -> should.fail()
              }
            }
            _ -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn inline_keyboard_builder_multi_row_test() {
  let callback_data = keyboard.string_callback_data("action")
  let callback1 = keyboard.pack_callback(callback_data, "btn1")
  let callback2 = keyboard.pack_callback(callback_data, "btn2")

  case
    keyboard.inline_builder()
    |> keyboard.inline_text("Row 1 Button", callback1)
  {
    Ok(builder) -> {
      let builder = keyboard.inline_next_row(builder)
      case keyboard.inline_text(builder, "Row 2 Button", callback2) {
        Ok(builder) -> {
          let kb = keyboard.inline_build(builder)
          let markup = keyboard.to_inline_markup(kb)
          case markup {
            SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) -> {
              case inline_keyboard.inline_keyboard {
                [[row1_btn], [row2_btn]] -> {
                  should.equal(row1_btn.text, "Row 1 Button")
                  should.equal(row2_btn.text, "Row 2 Button")
                }
                _ -> should.fail()
              }
            }
            _ -> should.fail()
          }
        }
        Error(_) -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn inline_keyboard_builder_mixed_buttons_test() {
  let callback_data = keyboard.string_callback_data("action")
  let callback = keyboard.pack_callback(callback_data, "action")

  case
    keyboard.inline_builder()
    |> keyboard.inline_text("Callback", callback)
  {
    Ok(builder) -> {
      let builder = keyboard.inline_url(builder, "URL", "https://example.com")
      let builder = keyboard.inline_next_row(builder)
      let builder =
        keyboard.inline_web_app(builder, "WebApp", "https://app.example.com")
      let builder = keyboard.inline_copy_text(builder, "Copy", "Hello!")

      let kb = keyboard.inline_build(builder)
      let markup = keyboard.to_inline_markup(kb)
      case markup {
        SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) -> {
          case inline_keyboard.inline_keyboard {
            [[callback_btn, url_btn], [webapp_btn, copy_btn]] -> {
              should.equal(callback_btn.text, "Callback")
              should.equal(url_btn.text, "URL")
              should.equal(webapp_btn.text, "WebApp")
              should.equal(copy_btn.text, "Copy")
            }
            _ -> should.fail()
          }
        }
        _ -> should.fail()
      }
    }
    Error(_) -> should.fail()
  }
}

pub fn inline_keyboard_builder_switch_query_test() {
  let builder =
    keyboard.inline_builder()
    |> keyboard.inline_switch_query("Share", "hello world")
    |> keyboard.inline_next_row()
    |> keyboard.inline_url("Visit", "https://example.com")

  let kb = keyboard.inline_build(builder)
  let markup = keyboard.to_inline_markup(kb)
  case markup {
    SendMessageReplyInlineKeyboardMarkupParameters(inline_keyboard) -> {
      case inline_keyboard.inline_keyboard {
        [[share_btn], [visit_btn]] -> {
          should.equal(share_btn.text, "Share")
          should.equal(share_btn.switch_inline_query, Some("hello world"))
          should.equal(visit_btn.text, "Visit")
          should.equal(visit_btn.url, Some("https://example.com"))
        }
        _ -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn builder_vs_manual_equivalence_test() {
  let builder_kb =
    keyboard.builder()
    |> keyboard.text("Yes")
    |> keyboard.text("No")
    |> keyboard.next_row()
    |> keyboard.text("Cancel")
    |> keyboard.build()

  let manual_kb =
    keyboard.new([
      [keyboard.button("Yes"), keyboard.button("No")],
      [keyboard.button("Cancel")],
    ])

  should.equal(keyboard.to_markup(builder_kb), keyboard.to_markup(manual_kb))
}
