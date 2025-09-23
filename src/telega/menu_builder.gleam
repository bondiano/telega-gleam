//// # Menu Builder Module
////
//// This module provides an advanced menu system for Telegram bots, extending beyond basic keyboards
//// to create rich, interactive menu experiences with state management, navigation, and pagination.
////
//// ## Key Features
////
//// - **Stateful Menus**: Menus that maintain state across interactions
//// - **Navigation System**: Back/forward navigation with breadcrumbs
//// - **Pagination**: Built-in pagination for large datasets
//// - **Dynamic Menus**: Menus that update based on data changes
//// - **Context Actions**: Actions that can modify menu state
//// - **Nested Menus**: Support for hierarchical menu structures
////
//// ## Quick Start
////
//// ### Simple Menu
//// ```gleam
//// let menu = menu_builder.new("main_menu")
////   |> menu_builder.title("🏠 Main Menu")
////   |> menu_builder.add_item("📋 View Items", "view_items")
////   |> menu_builder.add_item("➕ Add Item", "add_item")
////   |> menu_builder.add_item("⚙️ Settings", "settings")
////   |> menu_builder.build()
//// ```
////
//// ### Paginated Menu
//// ```gleam
//// let items = ["Item 1", "Item 2", "Item 3", ..., "Item 100"]
//// let menu = menu_builder.new("item_list")
////   |> menu_builder.title("📋 Items")
////   |> menu_builder.paginate(items, page: 1, items_per_page: 10)
////   |> menu_builder.with_back_button("main_menu")
////   |> menu_builder.build()
//// ```
////
//// ### Stateful Menu with Actions
//// ```gleam
//// pub type MenuState {
////   MenuState(items: List(String), selected: Option(Int))
//// }
////
//// let menu = menu_builder.new_stateful("item_selector", initial_state)
////   |> menu_builder.title("Select an Item")
////   |> menu_builder.add_stateful_items(state.items, fn(item, index) {
////     let selected = case state.selected {
////       Some(i) if i == index -> "✅ "
////       _ -> ""
////     }
////     #(selected <> item, "select:" <> int.to_string(index))
////   })
////   |> menu_builder.on_action("select", fn(state, data) {
////     let index = int.parse(data) |> result.unwrap(0)
////     MenuState(..state, selected: Some(index))
////   })
////   |> menu_builder.build()
//// ```

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/keyboard.{type InlineKeyboard, type KeyboardCallbackData}
import telega/model/types.{type InlineKeyboardButton}

// Core Types -----------------------------------------------------------------------------------------

/// Represents a menu item with text and action data
pub type MenuItem {
  MenuItem(text: String, action: String, enabled: Bool)
}

/// Represents a menu section for grouping related items
pub type MenuSection {
  MenuSection(title: Option(String), items: List(MenuItem))
}

/// Configuration for pagination
pub type PaginationConfig {
  PaginationConfig(
    items_per_page: Int,
    show_page_info: Bool,
    prev_text: String,
    next_text: String,
    page_info_template: String,
  )
}

/// Menu layout configuration
pub type MenuLayout {
  MenuLayout(
    columns: Int,
    max_rows_per_section: Option(Int),
    section_separator: Bool,
  )
}

/// Navigation configuration
pub type NavigationConfig {
  NavigationConfig(
    back_button: Option(String),
    back_text: String,
    home_button: Option(String),
    home_text: String,
    show_breadcrumbs: Bool,
  )
}

/// Menu state for stateful menus
pub type MenuState(state) {
  MenuState(
    id: String,
    data: state,
    current_page: Int,
    navigation_stack: List(String),
    context: Dict(String, String),
  )
}

/// Menu action handler
pub type MenuAction(state) =
  fn(MenuState(state), String) -> MenuState(state)

/// Menu configuration
pub opaque type Menu(state) {
  Menu(
    id: String,
    title: Option(String),
    sections: List(MenuSection),
    layout: MenuLayout,
    pagination: Option(PaginationConfig),
    navigation: NavigationConfig,
    state: Option(MenuState(state)),
    actions: Dict(String, MenuAction(state)),
    callback_data: KeyboardCallbackData(String),
  )
}

/// Menu builder for constructing menus
pub opaque type MenuBuilder(state) {
  MenuBuilder(
    id: String,
    title: Option(String),
    sections: List(MenuSection),
    current_section: MenuSection,
    layout: MenuLayout,
    pagination: Option(PaginationConfig),
    navigation: NavigationConfig,
    state: Option(MenuState(state)),
    actions: Dict(String, MenuAction(state)),
  )
}

// Core Functions --------------------------------------------------------------------------------------

/// Create a new stateless menu builder
pub fn new(id: String) -> MenuBuilder(Nil) {
  MenuBuilder(
    id: id,
    title: None,
    sections: [],
    current_section: MenuSection(title: None, items: []),
    layout: MenuLayout(
      columns: 1,
      max_rows_per_section: None,
      section_separator: True,
    ),
    pagination: None,
    navigation: NavigationConfig(
      back_button: None,
      back_text: "",
      home_button: None,
      home_text: "",
      show_breadcrumbs: False,
    ),
    state: None,
    actions: dict.new(),
  )
}

/// Create a new stateful menu builder
pub fn new_stateful(id: String, initial_state: state) -> MenuBuilder(state) {
  let state =
    MenuState(
      id: id,
      data: initial_state,
      current_page: 1,
      navigation_stack: [],
      context: dict.new(),
    )

  MenuBuilder(
    id: id,
    title: None,
    sections: [],
    current_section: MenuSection(title: None, items: []),
    layout: MenuLayout(
      columns: 1,
      max_rows_per_section: None,
      section_separator: True,
    ),
    pagination: None,
    navigation: NavigationConfig(
      back_button: None,
      back_text: "",
      home_button: None,
      home_text: "",
      show_breadcrumbs: False,
    ),
    state: Some(state),
    actions: dict.new(),
  )
}

/// Set the menu title
pub fn title(builder: MenuBuilder(state), title: String) -> MenuBuilder(state) {
  MenuBuilder(..builder, title: Some(title))
}

/// Add a simple menu item
pub fn add_item(
  builder: MenuBuilder(state),
  text: String,
  action: String,
) -> MenuBuilder(state) {
  let item = MenuItem(text: text, action: action, enabled: True)
  let updated_section =
    MenuSection(..builder.current_section, items: [
      item,
      ..builder.current_section.items
    ])
  MenuBuilder(..builder, current_section: updated_section)
}

/// Add a disabled menu item
pub fn add_disabled_item(
  builder: MenuBuilder(state),
  text: String,
  action: String,
) -> MenuBuilder(state) {
  let item = MenuItem(text: text, action: action, enabled: False)
  let updated_section =
    MenuSection(..builder.current_section, items: [
      item,
      ..builder.current_section.items
    ])
  MenuBuilder(..builder, current_section: updated_section)
}

/// Start a new section with optional title
pub fn section(
  builder: MenuBuilder(state),
  title: Option(String),
) -> MenuBuilder(state) {
  let current_section =
    MenuSection(
      ..builder.current_section,
      items: list.reverse(builder.current_section.items),
    )
  let new_section = MenuSection(title: title, items: [])

  MenuBuilder(
    ..builder,
    sections: [current_section, ..builder.sections],
    current_section: new_section,
  )
}

/// Configure menu layout
pub fn layout(
  builder: MenuBuilder(state),
  columns: Int,
  max_rows_per_section: Option(Int),
  section_separator: Bool,
) -> MenuBuilder(state) {
  let layout =
    MenuLayout(
      columns: columns,
      max_rows_per_section: max_rows_per_section,
      section_separator: section_separator,
    )
  MenuBuilder(..builder, layout: layout)
}

/// Configure pagination
pub fn paginate(
  builder: MenuBuilder(state),
  items_per_page: Int,
  show_page_info: Bool,
) -> MenuBuilder(state) {
  let pagination =
    PaginationConfig(
      items_per_page: items_per_page,
      show_page_info: show_page_info,
      prev_text: "",
      next_text: "",
      page_info_template: "{current}/{total}",
    )
  MenuBuilder(..builder, pagination: Some(pagination))
}

/// Configure pagination with custom texts
pub fn paginate_with_text(
  builder: MenuBuilder(state),
  items_per_page: Int,
  show_page_info: Bool,
  prev_text: String,
  next_text: String,
  page_info_template: String,
) -> MenuBuilder(state) {
  let pagination =
    PaginationConfig(
      items_per_page: items_per_page,
      show_page_info: show_page_info,
      prev_text: prev_text,
      next_text: next_text,
      page_info_template: page_info_template,
    )
  MenuBuilder(..builder, pagination: Some(pagination))
}

/// Add back button navigation
pub fn with_back_button(
  builder: MenuBuilder(state),
  back_action: String,
) -> MenuBuilder(state) {
  let navigation =
    NavigationConfig(..builder.navigation, back_button: Some(back_action))
  MenuBuilder(..builder, navigation: navigation)
}

/// Add back button navigation with custom text
pub fn with_back_button_text(
  builder: MenuBuilder(state),
  back_action: String,
  back_text: String,
) -> MenuBuilder(state) {
  let navigation =
    NavigationConfig(
      ..builder.navigation,
      back_button: Some(back_action),
      back_text: back_text,
    )
  MenuBuilder(..builder, navigation: navigation)
}

/// Add home button navigation
pub fn with_home_button(
  builder: MenuBuilder(state),
  home_action: String,
) -> MenuBuilder(state) {
  let navigation =
    NavigationConfig(..builder.navigation, home_button: Some(home_action))
  MenuBuilder(..builder, navigation: navigation)
}

/// Add home button navigation with custom text
pub fn with_home_button_text(
  builder: MenuBuilder(state),
  home_action: String,
  home_text: String,
) -> MenuBuilder(state) {
  let navigation =
    NavigationConfig(
      ..builder.navigation,
      home_button: Some(home_action),
      home_text: home_text,
    )
  MenuBuilder(..builder, navigation: navigation)
}

/// Register an action handler for stateful menus
pub fn on_action(
  builder: MenuBuilder(state),
  action_name: String,
  handler: MenuAction(state),
) -> MenuBuilder(state) {
  let actions = dict.insert(builder.actions, action_name, handler)
  MenuBuilder(..builder, actions: actions)
}

/// Build the final menu
pub fn build(builder: MenuBuilder(state)) -> Menu(state) {
  let current_section =
    MenuSection(
      ..builder.current_section,
      items: list.reverse(builder.current_section.items),
    )
  let all_sections = case current_section.items {
    [] -> list.reverse(builder.sections)
    _ -> list.reverse([current_section, ..builder.sections])
  }

  let callback_data = keyboard.string_callback_data("menu:" <> builder.id)

  Menu(
    id: builder.id,
    title: builder.title,
    sections: all_sections,
    layout: builder.layout,
    pagination: builder.pagination,
    navigation: builder.navigation,
    state: builder.state,
    actions: builder.actions,
    callback_data: callback_data,
  )
}

/// Add multiple items from a list with custom formatting
pub fn add_items_from_list(
  builder: MenuBuilder(state),
  items: List(item),
  formatter: fn(item, Int) -> #(String, String),
) -> MenuBuilder(state) {
  use builder, item, index <- list.index_fold(items, builder)
  let #(text, action) = formatter(item, index)
  add_item(builder, text, action)
}

/// Add items for stateful menus that can access state
pub fn add_stateful_items(
  builder: MenuBuilder(state),
  items: List(item),
  formatter: fn(item, Int, state) -> #(String, String, Bool),
) -> MenuBuilder(state) {
  case builder.state {
    None -> builder
    Some(menu_state) -> {
      use builder, item, index <- list.index_fold(items, builder)
      let #(text, action, enabled) = formatter(item, index, menu_state.data)
      case enabled {
        True -> add_item(builder, text, action)
        False -> add_disabled_item(builder, text, action)
      }
    }
  }
}

/// Create a submenu item that navigates to another menu
pub fn add_submenu(
  builder: MenuBuilder(state),
  text: String,
  submenu_id: String,
) -> MenuBuilder(state) {
  add_item(builder, text, "nav:" <> submenu_id)
}

/// Create a toggle item for boolean settings
pub fn add_toggle(
  builder: MenuBuilder(state),
  text_template: String,
  action: String,
  current_value: Bool,
) -> MenuBuilder(state) {
  let status = case current_value {
    True -> "✅"
    False -> "❌"
  }
  let text = string.replace(text_template, "{status}", status)
  add_item(builder, text, action)
}

/// Convert menu to inline keyboard
pub fn to_keyboard(menu: Menu(state)) -> Result(InlineKeyboard, String) {
  let current_page = case menu.state {
    Some(state) -> state.current_page
    None -> 1
  }

  use main_buttons <- result.try(build_main_buttons(menu, current_page))
  let nav_buttons = build_navigation_buttons(menu, current_page)

  let pagination_buttons = case menu.pagination {
    Some(config) -> build_pagination_buttons(menu, config, current_page)
    None -> []
  }

  let all_buttons =
    list.flatten([main_buttons, nav_buttons, pagination_buttons])

  let keyboard = case menu.layout.columns {
    1 -> keyboard.new_inline(list.map(all_buttons, fn(btn) { [btn] }))
    cols -> keyboard.inline_grid(all_buttons, cols)
  }

  Ok(keyboard)
}

fn build_main_buttons(
  menu: Menu(state),
  current_page: Int,
) -> Result(List(InlineKeyboardButton), String) {
  let all_items = list.flat_map(menu.sections, fn(section) { section.items })

  let items_to_show = case menu.pagination {
    Some(config) -> {
      let start_index = { current_page - 1 } * config.items_per_page
      let _end_index = start_index + config.items_per_page
      list.drop(all_items, start_index) |> list.take(config.items_per_page)
    }
    None -> all_items
  }

  use buttons <- result.try(
    list.try_map(items_to_show, fn(item) {
      let text = case item.enabled {
        True -> item.text
        False -> "🚫 " <> item.text
      }
      let callback = keyboard.pack_callback(menu.callback_data, item.action)
      keyboard.inline_button(text, callback)
    }),
  )

  Ok(buttons)
}

fn build_navigation_buttons(
  menu: Menu(state),
  _current_page: Int,
) -> List(InlineKeyboardButton) {
  let nav_buttons = []

  let nav_buttons = case menu.navigation.back_button {
    Some(action) -> {
      let callback = keyboard.pack_callback(menu.callback_data, action)
      case keyboard.inline_button(menu.navigation.back_text, callback) {
        Ok(button) -> [button, ..nav_buttons]
        Error(_) -> nav_buttons
      }
    }
    None -> nav_buttons
  }

  let nav_buttons = case menu.navigation.home_button {
    Some(action) -> {
      let callback = keyboard.pack_callback(menu.callback_data, action)
      case keyboard.inline_button(menu.navigation.home_text, callback) {
        Ok(button) -> [button, ..nav_buttons]
        Error(_) -> nav_buttons
      }
    }
    None -> nav_buttons
  }

  list.reverse(nav_buttons)
}

fn build_pagination_buttons(
  menu: Menu(state),
  config: PaginationConfig,
  current_page: Int,
) -> List(InlineKeyboardButton) {
  let all_items = list.flat_map(menu.sections, fn(section) { section.items })
  let total_items = list.length(all_items)
  let total_pages = case total_items {
    0 -> 1
    _ -> { total_items + config.items_per_page - 1 } / config.items_per_page
  }

  let buttons = []

  let buttons = case current_page > 1 {
    True -> {
      let action = "page:" <> int.to_string(current_page - 1)
      let callback = keyboard.pack_callback(menu.callback_data, action)
      case keyboard.inline_button(config.prev_text, callback) {
        Ok(button) -> [button, ..buttons]
        Error(_) -> buttons
      }
    }
    False -> buttons
  }

  let buttons = case config.show_page_info {
    True -> {
      let page_info =
        config.page_info_template
        |> string.replace("{current}", int.to_string(current_page))
        |> string.replace("{total}", int.to_string(total_pages))

      let info_button = keyboard.inline_copy_text_button(page_info, page_info)
      [info_button, ..buttons]
    }
    False -> buttons
  }

  let buttons = case current_page < total_pages {
    True -> {
      let action = "page:" <> int.to_string(current_page + 1)
      let callback = keyboard.pack_callback(menu.callback_data, action)
      case keyboard.inline_button(config.next_text, callback) {
        Ok(button) -> [button, ..buttons]
        Error(_) -> buttons
      }
    }
    False -> buttons
  }

  list.reverse(buttons)
}

/// Handle menu action and return updated menu
pub fn handle_action(
  menu: Menu(state),
  action: String,
) -> Result(Menu(state), String) {
  case menu.state {
    None -> Error("Cannot handle action on stateless menu")
    Some(menu_state) -> {
      case string.starts_with(action, "page:") {
        True -> {
          let page_str = string.drop_start(action, 5)
          case int.parse(page_str) {
            Ok(page) -> {
              let updated_state = MenuState(..menu_state, current_page: page)
              Ok(Menu(..menu, state: Some(updated_state)))
            }
            Error(_) -> Error("Invalid page number")
          }
        }
        False -> {
          case dict.get(menu.actions, action) {
            Ok(handler) -> {
              let updated_state = handler(menu_state, action)
              Ok(Menu(..menu, state: Some(updated_state)))
            }
            Error(_) -> Error("Unknown action: " <> action)
          }
        }
      }
    }
  }
}

/// Get menu state
pub fn get_state(menu: Menu(state)) -> Option(MenuState(state)) {
  menu.state
}

/// Update menu state
pub fn update_state(
  menu: Menu(state),
  updater: fn(MenuState(state)) -> MenuState(state),
) -> Menu(state) {
  case menu.state {
    Some(state) -> Menu(..menu, state: Some(updater(state)))
    None -> menu
  }
}

/// Get menu callback data for filtering
pub fn get_callback_data(menu: Menu(state)) -> KeyboardCallbackData(String) {
  menu.callback_data
}

/// Helper to get menu title with optional state formatting
pub fn get_title(menu: Menu(state)) -> String {
  case menu.title {
    Some(title) -> title
    None -> ""
  }
}

/// Create a confirmation menu
pub fn confirmation(
  id: String,
  message: String,
  confirm_action: String,
  cancel_action: String,
  confirm_text: String,
  cancel_text: String,
) -> Menu(Nil) {
  new(id)
  |> title(message)
  |> add_item(confirm_text, confirm_action)
  |> add_item(cancel_text, cancel_action)
  |> layout(2, None, False)
  |> build()
}

/// Create a settings menu with toggles
pub fn settings_menu(
  id: String,
  menu_title: String,
  settings: List(#(String, String, Bool)),
) -> Menu(Nil) {
  let initial_builder = new(id) |> title(menu_title)

  list.fold(settings, initial_builder, fn(builder, setting) {
    let #(name, action, value) = setting
    add_toggle(builder, name <> " {status}", action, value)
  })
  |> build()
}
