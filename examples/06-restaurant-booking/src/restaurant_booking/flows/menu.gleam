//// The restaurant menu as a **declarative dialog** (`telega/dialog`).
////
//// One live message the user browses in place: categories → a paged list of
//// dishes → one dish. The paging comes from `widget.paged_select`, the
//// callback payloads are generated and size-checked at build time, and going
//// `Back` is the engine's own history — none of which this file has to spell
//// out. It replaced a `menu_builder` flow that re-sent the whole menu on
//// every press.

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import sqlight

import telega/bot.{type Context}
import telega/dialog
import telega/dialog/types.{type ActionEvent, type DialogAction} as dtypes
import telega/dialog/widget.{type SelectItem, SelectItem}
import telega/format as fmt
import telega/reply

import restaurant_booking/dependencies.{type Dependencies}
import restaurant_booking/i18n
import restaurant_booking/util

type Ctx =
  Context(Nil, String, Dependencies)

pub type MenuItem {
  MenuItem(
    id: Int,
    name: String,
    description: String,
    price: String,
    category: String,
  )
}

pub type MenuCategory {
  MenuCategory(name: String, emoji: String, item_count: Int)
}

/// What the user is looking at: a category, and inside it a dish. The page of
/// the dish list is the `paged_select` widget's own state, persisted beside
/// this one.
pub type MenuState {
  MenuState(category: String, item: Option(Int))
}

fn menu_codec() -> #(
  fn(MenuState) -> String,
  fn(String) -> Result(MenuState, Nil),
) {
  dialog.json_codec(
    encoder: fn(state: MenuState) {
      json.object([
        #("category", json.string(state.category)),
        #("item", json.nullable(state.item, json.int)),
      ])
    },
    decoder: {
      use category <- decode.field("category", decode.string)
      use item <- decode.field("item", decode.optional(decode.int))
      decode.success(MenuState(category:, item:))
    },
  )
}

pub fn create_menu_dialog(
  db: sqlight.Connection,
) -> dialog.Dialog(MenuState, Nil, String, Dependencies) {
  // `db` builds the dialog's persistence backend at init. The windows use
  // mock data and don't query the db at all.
  let storage = util.create_database_storage(db)
  let #(encode_state, decode_state) = menu_codec()

  let assert Ok(menu_dialog) =
    dialog.new(
      id: "menu",
      storage:,
      initial_state: fn(_ctx) { MenuState(category: "", item: None) },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "categories",
      render: render_categories,
      on_action: handle_categories,
    )
    |> dialog.window_with_widgets(
      id: "items",
      render: render_items,
      on_action: back_or_stay,
      widgets: [items_widget()],
    )
    |> dialog.window(id: "item", render: render_item, on_action: back_or_stay)
    |> dialog.initial("categories")
    |> dialog.with_labels(dialog_labels)
    |> dialog.build()

  menu_dialog
}

// Windows ----------------------------------------------------------------------------

pub fn render_categories(_state: MenuState, ctx: Ctx) -> dtypes.RenderedWindow {
  let text =
    fmt.build()
    |> fmt.with_mode(fmt.HTML)
    |> fmt.bold_text(
      i18n.t(ctx, "menu.title", [#("restaurant", util.get_restaurant_name())]),
    )
    |> fmt.line_break()
    |> fmt.line_break()
    |> fmt.text(i18n.t(ctx, "menu.food_categories", []))
    |> fmt.to_formatted()

  dtypes.RenderedWindow(
    text:,
    buttons: list.append(category_rows(ctx), [
      // A section header, the way an inline keyboard spells one.
      [dtypes.NoopButton(i18n.t(ctx, "menu.reservations", []))],
      [dtypes.ActionButton(i18n.t(ctx, "menu.make_reservation", []), "book")],
      [dtypes.ActionButton(i18n.t(ctx, "menu.my_bookings", []), "bookings")],
    ]),
    media: None,
  )
}

/// Categories two to a row; the category name travels in the button's
/// argument, so one action id serves all of them.
fn category_rows(ctx: Ctx) -> List(List(dtypes.DialogButton)) {
  get_menu_categories()
  |> list.map(fn(category) {
    dtypes.ActionArgButton(
      category.emoji
        <> " "
        <> category.name
        <> " ("
        <> i18n.tn(ctx, "menu.items", category.item_count, [])
        <> ")",
      "cat",
      category.name,
    )
  })
  |> list.sized_chunk(into: 2)
}

fn handle_categories(
  state: MenuState,
  event: ActionEvent,
  ctx: Ctx,
) -> Result(DialogAction(MenuState), String) {
  case event.action_id, event.arg {
    "cat", Some(category) ->
      Ok(dtypes.Goto("items", MenuState(category:, item: None)))
    "book", _ -> {
      let _ = reply.with_text(ctx, i18n.t(ctx, "menu.use_book", []))
      Ok(dtypes.Done(state))
    }
    "bookings", _ -> {
      let _ = reply.with_text(ctx, i18n.t(ctx, "menu.use_my_bookings", []))
      Ok(dtypes.Done(state))
    }
    _, _ -> Ok(dtypes.Stay(state))
  }
}

pub fn render_items(state: MenuState, ctx: Ctx) -> dtypes.RenderedWindow {
  let text =
    fmt.build()
    |> fmt.with_mode(fmt.HTML)
    |> fmt.bold_text(
      i18n.t(ctx, "menu.category_menu", [#("category", state.category)]),
    )
    |> fmt.to_formatted()

  // The dish buttons and the pager are the widget's rows, appended after
  // these by the engine.
  dtypes.RenderedWindow(text:, buttons: [[back_button(ctx)]], media: None)
}

fn items_widget() -> dtypes.KeyboardWidget(MenuState, Nil, String, Dependencies) {
  widget.paged_select(
    id: "list",
    items: item_options,
    page_size: 6,
    columns: 1,
    on_selected: fn(state: MenuState, id, _ctx) {
      Ok(dtypes.Goto(
        "item",
        MenuState(..state, item: int.parse(id) |> option.from_result),
      ))
    },
  )
}

fn item_options(state: MenuState, _ctx: Ctx) -> List(SelectItem) {
  get_menu_items(state.category)
  |> list.map(fn(item) {
    SelectItem(
      id: int.to_string(item.id),
      label: item.name <> " — " <> item.price,
    )
  })
}

pub fn render_item(state: MenuState, ctx: Ctx) -> dtypes.RenderedWindow {
  let builder = fmt.build() |> fmt.with_mode(fmt.HTML)
  let text = case selected_item(state) {
    Some(item) ->
      builder
      |> fmt.bold_text(item.name)
      |> fmt.line_break()
      |> fmt.text(item.description)
      |> fmt.line_break()
      |> fmt.line_break()
      |> fmt.text("💰 " <> item.price)
      |> fmt.line_break()
      |> fmt.line_break()
      |> fmt.text(i18n.t(ctx, "menu.use_book", []))
      |> fmt.to_formatted()
    // The dish went away between the render that offered it and the press.
    None ->
      builder
      |> fmt.text(i18n.t(ctx, "menu.item_gone", []))
      |> fmt.to_formatted()
  }

  dtypes.RenderedWindow(text:, buttons: [[back_button(ctx)]], media: None)
}

fn selected_item(state: MenuState) -> Option(MenuItem) {
  use id <- option.then(state.item)
  get_menu_items(state.category)
  |> list.find(fn(item) { item.id == id })
  |> option.from_result
}

// Shared bits ------------------------------------------------------------------------

fn back_button(ctx: Ctx) -> dtypes.DialogButton {
  dtypes.ActionButton(i18n.t(ctx, "menu.back", []), "back")
}

fn back_or_stay(
  state: MenuState,
  event: ActionEvent,
  _ctx: Ctx,
) -> Result(DialogAction(MenuState), String) {
  case event.action_id {
    "back" -> Ok(dtypes.Back(state))
    _ -> Ok(dtypes.Stay(state))
  }
}

/// Localized engine labels: the pager arrows and the stale-button notice come
/// from the i18n catalog instead of the wordless unicode defaults.
fn dialog_labels(ctx: Ctx) -> dtypes.Labels {
  let defaults = dtypes.default_labels()
  dtypes.Labels(
    ..defaults,
    prev: i18n.t(ctx, "menu.prev", []),
    next: i18n.t(ctx, "menu.next", []),
    stale: i18n.t(ctx, "common.stale", []),
  )
}

// Mock data --------------------------------------------------------------------------

/// Get menu categories (mock data)
fn get_menu_categories() -> List(MenuCategory) {
  [
    MenuCategory("Appetizers", "🥗", 8),
    MenuCategory("Main Courses", "🍖", 12),
    MenuCategory("Pasta", "🍝", 10),
    MenuCategory("Pizza", "🍕", 15),
    MenuCategory("Desserts", "🍰", 6),
    MenuCategory("Beverages", "🥤", 20),
  ]
}

/// Get menu items for category (mock data)
fn get_menu_items(category: String) -> List(MenuItem) {
  case category {
    "Appetizers" -> [
      MenuItem(
        1,
        "Caesar Salad",
        "Fresh romaine lettuce with parmesan",
        "$12.99",
        category,
      ),
      MenuItem(
        2,
        "Bruschetta",
        "Toasted bread with tomatoes and basil",
        "$8.99",
        category,
      ),
      MenuItem(3, "Calamari", "Crispy fried squid rings", "$14.99", category),
      MenuItem(
        4,
        "Mozzarella Sticks",
        "Golden fried mozzarella",
        "$9.99",
        category,
      ),
      MenuItem(5, "Wings", "Buffalo or BBQ chicken wings", "$11.99", category),
      MenuItem(6, "Nachos", "Loaded cheese nachos", "$10.99", category),
      MenuItem(
        7,
        "Shrimp Cocktail",
        "Fresh shrimp with cocktail sauce",
        "$16.99",
        category,
      ),
      MenuItem(
        8,
        "Spinach Dip",
        "Creamy spinach and artichoke dip",
        "$9.99",
        category,
      ),
    ]
    "Main Courses" -> [
      MenuItem(
        9,
        "Grilled Salmon",
        "Atlantic salmon with vegetables",
        "$24.99",
        category,
      ),
      MenuItem(
        10,
        "Ribeye Steak",
        "Premium cut with garlic butter",
        "$32.99",
        category,
      ),
      MenuItem(
        11,
        "Chicken Parmesan",
        "Breaded chicken with marinara",
        "$19.99",
        category,
      ),
      MenuItem(
        12,
        "Fish & Chips",
        "Beer battered cod with fries",
        "$17.99",
        category,
      ),
      MenuItem(13, "BBQ Ribs", "Slow-cooked baby back ribs", "$26.99", category),
      MenuItem(
        14,
        "Lamb Chops",
        "Herb-crusted rack of lamb",
        "$29.99",
        category,
      ),
    ]
    "Pizza" -> [
      MenuItem(
        15,
        "Margherita",
        "Tomato, mozzarella, fresh basil",
        "$16.99",
        category,
      ),
      MenuItem(16, "Pepperoni", "Classic pepperoni pizza", "$18.99", category),
      MenuItem(17, "Quattro Stagioni", "Four seasons pizza", "$21.99", category),
      MenuItem(18, "Hawaiian", "Ham and pineapple", "$19.99", category),
      MenuItem(
        19,
        "Meat Lovers",
        "Pepperoni, sausage, bacon",
        "$23.99",
        category,
      ),
      MenuItem(
        20,
        "Veggie Supreme",
        "Fresh vegetables and herbs",
        "$20.99",
        category,
      ),
    ]
    "Beverages" -> [
      MenuItem(
        21,
        "House Wine",
        "Red or white wine selection",
        "$8.99",
        category,
      ),
      MenuItem(22, "Craft Beer", "Local brewery selection", "$6.99", category),
      MenuItem(
        23,
        "Fresh Juice",
        "Orange, apple, or cranberry",
        "$4.99",
        category,
      ),
      MenuItem(24, "Cocktails", "Premium mixed drinks", "$12.99", category),
      MenuItem(25, "Coffee", "Freshly brewed coffee", "$3.99", category),
      MenuItem(26, "Tea Selection", "Various tea options", "$3.99", category),
    ]
    _ -> []
  }
}
