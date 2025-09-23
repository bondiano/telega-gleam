import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import telega/keyboard
import telega/menu_builder
import telega/model/types

pub fn main() {
  gleeunit.main()
}

pub type TestState {
  TestState(counter: Int, items: List(String))
}

pub fn simple_menu_keyboard_structure_test() {
  let menu =
    menu_builder.new("simple")
    |> menu_builder.title("Simple Menu")
    |> menu_builder.add_item("Action 1", "action1")
    |> menu_builder.add_item("Action 2", "action2")
    |> menu_builder.build()

  let assert Ok(keyboard) = menu_builder.to_keyboard(menu)

  let markup = keyboard.to_inline_markup(keyboard)

  case markup {
    types.SendMessageReplyInlineKeyboardMarkupParameters(types.InlineKeyboardMarkup(
      inline_keyboard: buttons,
    )) -> {
      list.length(buttons) |> should.equal(2)

      let assert [first_row, second_row] = buttons
      list.length(first_row) |> should.equal(1)
      list.length(second_row) |> should.equal(1)

      let assert [button1] = first_row
      let assert [button2] = second_row

      button1.text |> should.equal("Action 1")
      button2.text |> should.equal("Action 2")

      button1.callback_data |> should.equal(Some("menu:simple:action1"))
      button2.callback_data |> should.equal(Some("menu:simple:action2"))
    }
    _ -> should.fail()
  }

  menu_builder.get_title(menu) |> should.equal("Simple Menu")
}

pub fn complex_menu_with_sections_keyboard_test() {
  let menu =
    menu_builder.new("complex")
    |> menu_builder.title("🏠 Complex Menu")
    |> menu_builder.section(Some("📊 Data Actions"))
    |> menu_builder.add_item("📈 Analytics", "analytics")
    |> menu_builder.add_item("📋 Reports", "reports")
    |> menu_builder.section(Some("⚙️ System"))
    |> menu_builder.add_item("🔧 Settings", "settings")
    |> menu_builder.add_disabled_item("🚫 Maintenance", "maintenance")
    |> menu_builder.section(None)
    |> menu_builder.add_item("ℹ️ Help", "help")
    |> menu_builder.with_back_button_text("home", "← Home")
    |> menu_builder.layout(2, None, True)
    |> menu_builder.build()

  let assert Ok(keyboard) = menu_builder.to_keyboard(menu)

  // Examine full keyboard structure
  let markup = keyboard.to_inline_markup(keyboard)

  case markup {
    types.SendMessageReplyInlineKeyboardMarkupParameters(types.InlineKeyboardMarkup(
      inline_keyboard: button_rows,
    )) -> {
      let row_count = list.length(button_rows)
      case row_count >= 3 {
        True -> Nil
        False -> should.fail()
      }

      let total_buttons =
        list.fold(button_rows, 0, fn(count, row) { count + list.length(row) })
      total_buttons |> should.equal(6)

      let all_buttons = list.flatten(button_rows)
      let disabled_button =
        list.find(all_buttons, fn(btn) {
          string.contains(btn.text, "🚫 Maintenance")
        })

      case disabled_button {
        Ok(btn) -> {
          btn.text |> should.equal("🚫 🚫 Maintenance")
          btn.callback_data |> should.equal(Some("menu:complex:maintenance"))
        }
        Error(_) -> should.fail()
      }

      let back_button = list.find(all_buttons, fn(btn) { btn.text == "← Home" })

      case back_button {
        Ok(btn) -> {
          btn.callback_data |> should.equal(Some("menu:complex:home"))
        }
        Error(_) -> should.fail()
      }
    }
    _ -> should.fail()
  }

  menu_builder.get_title(menu) |> should.equal("🏠 Complex Menu")
}

pub fn paginated_menu_keyboard_test() {
  let items = [
    "Item 1",
    "Item 2",
    "Item 3",
    "Item 4",
    "Item 5",
    "Item 6",
    "Item 7",
  ]
  let initial_state = TestState(counter: 0, items: items)

  let menu =
    menu_builder.new_stateful("paginated", initial_state)
    |> menu_builder.title("📋 Paginated Items")
    |> menu_builder.add_items_from_list(items, fn(item, index) {
      #(item, "select:" <> string.inspect(index))
    })
    |> menu_builder.paginate_with_text(
      3,
      True,
      "◀️ Prev",
      "Next ▶️",
      "Page {current}/{total}",
    )
    |> menu_builder.with_back_button_text("main", "🏠 Main")
    |> menu_builder.build()

  let assert Ok(keyboard_page1) = menu_builder.to_keyboard(menu)
  let markup1 = keyboard.to_inline_markup(keyboard_page1)

  case markup1 {
    types.SendMessageReplyInlineKeyboardMarkupParameters(types.InlineKeyboardMarkup(
      inline_keyboard: button_rows,
    )) -> {
      let all_buttons = list.flatten(button_rows)
      let total_buttons = list.length(all_buttons)

      total_buttons |> should.equal(6)

      let next_button = list.find(all_buttons, fn(btn) { btn.text == "Next ▶️" })
      let page_info =
        list.find(all_buttons, fn(btn) { string.contains(btn.text, "Page") })
      let back_button = list.find(all_buttons, fn(btn) { btn.text == "🏠 Main" })

      case next_button {
        Ok(btn) ->
          btn.callback_data |> should.equal(Some("menu:paginated:page:2"))
        Error(_) -> should.fail()
      }

      case page_info {
        Ok(btn) -> btn.text |> should.equal("Page 1/3")
        Error(_) -> should.fail()
      }

      case back_button {
        Ok(btn) ->
          btn.callback_data |> should.equal(Some("menu:paginated:main"))
        Error(_) -> should.fail()
      }
    }
    _ -> should.fail()
  }

  let assert Ok(menu_page2) = menu_builder.handle_action(menu, "page:2")
  let assert Ok(keyboard_page2) = menu_builder.to_keyboard(menu_page2)
  let markup2 = keyboard.to_inline_markup(keyboard_page2)

  case markup2 {
    types.SendMessageReplyInlineKeyboardMarkupParameters(types.InlineKeyboardMarkup(
      inline_keyboard: button_rows,
    )) -> {
      let all_buttons = list.flatten(button_rows)

      let prev_button = list.find(all_buttons, fn(btn) { btn.text == "◀️ Prev" })
      let next_button = list.find(all_buttons, fn(btn) { btn.text == "Next ▶️" })
      let page_info =
        list.find(all_buttons, fn(btn) { string.contains(btn.text, "Page") })

      case prev_button {
        Ok(btn) ->
          btn.callback_data |> should.equal(Some("menu:paginated:page:1"))
        Error(_) -> should.fail()
      }

      case next_button {
        Ok(btn) ->
          btn.callback_data |> should.equal(Some("menu:paginated:page:3"))
        Error(_) -> should.fail()
      }

      case page_info {
        Ok(btn) -> btn.text |> should.equal("Page 2/3")
        Error(_) -> should.fail()
      }
    }
    _ -> should.fail()
  }
}

pub fn settings_menu_keyboard_validation_test() {
  let settings = [
    #("🔔 Notifications", "toggle_notifications", True),
    #("🎨 Dark Mode", "toggle_dark_mode", False),
    #("🔊 Sound", "toggle_sound", True),
  ]

  let menu = menu_builder.settings_menu("settings", "⚙️ User Settings", settings)

  let assert Ok(keyboard) = menu_builder.to_keyboard(menu)

  let markup = keyboard.to_inline_markup(keyboard)

  case markup {
    types.SendMessageReplyInlineKeyboardMarkupParameters(types.InlineKeyboardMarkup(
      inline_keyboard: button_rows,
    )) -> {
      let all_buttons = list.flatten(button_rows)

      list.length(all_buttons) |> should.equal(3)

      let notification_btn =
        list.find(all_buttons, fn(btn) {
          string.contains(btn.text, "Notifications")
        })
      let dark_mode_btn =
        list.find(all_buttons, fn(btn) {
          string.contains(btn.text, "Dark Mode")
        })
      let sound_btn =
        list.find(all_buttons, fn(btn) { string.contains(btn.text, "Sound") })

      case notification_btn {
        Ok(btn) -> {
          btn.text |> should.equal("🔔 Notifications ✅")
          btn.callback_data
          |> should.equal(Some("menu:settings:toggle_notifications"))
        }
        Error(_) -> should.fail()
      }

      case dark_mode_btn {
        Ok(btn) -> {
          btn.text |> should.equal("🎨 Dark Mode ❌")
          btn.callback_data
          |> should.equal(Some("menu:settings:toggle_dark_mode"))
        }
        Error(_) -> should.fail()
      }

      case sound_btn {
        Ok(btn) -> {
          btn.text |> should.equal("🔊 Sound ✅")
          btn.callback_data |> should.equal(Some("menu:settings:toggle_sound"))
        }
        Error(_) -> should.fail()
      }
    }
    _ -> should.fail()
  }

  menu_builder.get_title(menu) |> should.equal("⚙️ User Settings")
}

pub fn confirmation_menu_keyboard_test() {
  let menu =
    menu_builder.confirmation(
      "delete_confirmation",
      "🗑️ Delete all data?",
      "confirm_delete",
      "cancel_delete",
      "✅ Yes, Delete",
      "❌ Cancel",
    )

  let assert Ok(keyboard) = menu_builder.to_keyboard(menu)

  let markup = keyboard.to_inline_markup(keyboard)

  case markup {
    types.SendMessageReplyInlineKeyboardMarkupParameters(types.InlineKeyboardMarkup(
      inline_keyboard: button_rows,
    )) -> {
      list.length(button_rows) |> should.equal(1)

      let assert [button_row] = button_rows
      list.length(button_row) |> should.equal(2)

      let assert [confirm_btn, cancel_btn] = button_row

      confirm_btn.text |> should.equal("✅ Yes, Delete")
      cancel_btn.text |> should.equal("❌ Cancel")

      confirm_btn.callback_data
      |> should.equal(Some("menu:delete_confirmation:confirm_delete"))
      cancel_btn.callback_data
      |> should.equal(Some("menu:delete_confirmation:cancel_delete"))
    }
    _ -> should.fail()
  }

  menu_builder.get_title(menu) |> should.equal("🗑️ Delete all data?")
}

pub fn stateful_menu_with_actions_keyboard_test() {
  let initial_state = TestState(counter: 5, items: ["A", "B", "C"])

  let menu =
    menu_builder.new_stateful("stateful", initial_state)
    |> menu_builder.title("📊 Counter: 5")
    |> menu_builder.add_item("➕ Increment", "increment")
    |> menu_builder.add_item("➖ Decrement", "decrement")
    |> menu_builder.add_item("🔄 Reset", "reset")
    |> menu_builder.on_action("increment", fn(state, _action) {
      menu_builder.MenuState(
        ..state,
        data: TestState(..state.data, counter: state.data.counter + 1),
      )
    })
    |> menu_builder.on_action("decrement", fn(state, _action) {
      menu_builder.MenuState(
        ..state,
        data: TestState(..state.data, counter: state.data.counter - 1),
      )
    })
    |> menu_builder.build()

  let assert Ok(keyboard) = menu_builder.to_keyboard(menu)
  let markup = keyboard.to_inline_markup(keyboard)

  case markup {
    types.SendMessageReplyInlineKeyboardMarkupParameters(types.InlineKeyboardMarkup(
      inline_keyboard: button_rows,
    )) -> {
      list.length(button_rows) |> should.equal(3)

      let assert [row1, row2, row3] = button_rows
      let assert [inc_btn] = row1
      let assert [dec_btn] = row2
      let assert [reset_btn] = row3

      inc_btn.text |> should.equal("➕ Increment")
      dec_btn.text |> should.equal("➖ Decrement")
      reset_btn.text |> should.equal("🔄 Reset")

      inc_btn.callback_data |> should.equal(Some("menu:stateful:increment"))
      dec_btn.callback_data |> should.equal(Some("menu:stateful:decrement"))
      reset_btn.callback_data |> should.equal(Some("menu:stateful:reset"))
    }
    _ -> should.fail()
  }

  let assert Ok(incremented_menu) =
    menu_builder.handle_action(menu, "increment")
  let assert Some(incremented_state) = menu_builder.get_state(incremented_menu)
  incremented_state.data.counter |> should.equal(6)

  let assert Ok(updated_keyboard) = menu_builder.to_keyboard(incremented_menu)
  let updated_markup = keyboard.to_inline_markup(updated_keyboard)

  case updated_markup {
    types.SendMessageReplyInlineKeyboardMarkupParameters(types.InlineKeyboardMarkup(
      inline_keyboard: updated_rows,
    )) -> {
      list.length(updated_rows) |> should.equal(3)
    }
    _ -> should.fail()
  }
}
