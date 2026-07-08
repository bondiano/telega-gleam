import birdie
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/keyboard
import telega/menu_builder
import telega/model/types.{SendMessageReplyInlineKeyboardMarkupParameters}
import telega/testing/render

pub fn main() {
  gleeunit.main()
}

pub type TestState {
  TestState(counter: Int, items: List(String))
}

fn snap_menu(menu: menu_builder.Menu(state), title title: String) -> Nil {
  let assert Ok(kb) = menu_builder.to_keyboard(menu)
  let assert SendMessageReplyInlineKeyboardMarkupParameters(markup) =
    keyboard.to_inline_markup(kb)
  birdie.snap(render.keyboard_grid(markup), title:)
}

pub fn simple_menu_keyboard_test() {
  let menu =
    menu_builder.new("simple")
    |> menu_builder.title("Simple Menu")
    |> menu_builder.add_item("Action 1", "action1")
    |> menu_builder.add_item("Action 2", "action2")
    |> menu_builder.build()

  menu_builder.get_title(menu) |> should.equal("Simple Menu")
  snap_menu(menu, title: "menu_builder:simple:grid")
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

  menu_builder.get_title(menu) |> should.equal("🏠 Complex Menu")
  snap_menu(menu, title: "menu_builder:sections:two_column_grid")
}

fn paginated_menu() -> menu_builder.Menu(TestState) {
  let items = [
    "Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6", "Item 7",
  ]
  menu_builder.new_stateful("paginated", TestState(counter: 0, items:))
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
}

pub fn paginated_menu_first_page_test() {
  snap_menu(paginated_menu(), title: "menu_builder:paginated:page_1")
}

pub fn paginated_menu_second_page_test() {
  let assert Ok(menu) = menu_builder.handle_action(paginated_menu(), "page:2")
  snap_menu(menu, title: "menu_builder:paginated:page_2")
}

pub fn paginated_menu_last_page_test() {
  let assert Ok(menu) = menu_builder.handle_action(paginated_menu(), "page:3")
  snap_menu(menu, title: "menu_builder:paginated:page_3")
}

pub fn settings_menu_keyboard_test() {
  let settings = [
    #("🔔 Notifications", "toggle_notifications", True),
    #("🎨 Dark Mode", "toggle_dark_mode", False),
    #("🔊 Sound", "toggle_sound", True),
  ]

  let menu = menu_builder.settings_menu("settings", "⚙️ User Settings", settings)

  menu_builder.get_title(menu) |> should.equal("⚙️ User Settings")
  snap_menu(menu, title: "menu_builder:settings:toggles")
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

  menu_builder.get_title(menu) |> should.equal("🗑️ Delete all data?")
  snap_menu(menu, title: "menu_builder:confirmation:grid")
}

pub fn stateful_menu_with_actions_test() {
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

  let assert Ok(incremented_menu) =
    menu_builder.handle_action(menu, "increment")
  let assert Some(incremented_state) = menu_builder.get_state(incremented_menu)
  incremented_state.data.counter |> should.equal(6)

  snap_menu(incremented_menu, title: "menu_builder:stateful:grid")
}

pub fn handle_action_unknown_test() {
  let menu =
    menu_builder.new_stateful("s", TestState(counter: 0, items: []))
    |> menu_builder.add_item("X", "x")
    |> menu_builder.build()

  menu_builder.handle_action(menu, "nope")
  |> should.equal(Error("Unknown action: nope"))
}

pub fn handle_action_on_stateless_menu_test() {
  let menu =
    menu_builder.new("stateless")
    |> menu_builder.add_item("X", "x")
    |> menu_builder.build()

  menu_builder.handle_action(menu, "x")
  |> should.equal(Error("Cannot handle action on stateless menu"))
}
