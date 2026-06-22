import gleam/int
import gleam/option.{None, Some}
import gleam/string
import sqlight

import telega/bot.{type Context}
import telega/flow/action
import telega/flow/builder
import telega/flow/instance
import telega/flow/types
import telega/keyboard
import telega/menu_builder
import telega/reply

import restaurant_booking/dependencies.{type Dependencies}
import restaurant_booking/i18n
import restaurant_booking/util

pub type MenuStep {
  ShowCategories
  ShowItems
}

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

fn step_to_string(step: MenuStep) -> String {
  case step {
    ShowCategories -> "categories"
    ShowItems -> "items"
  }
}

fn string_to_step(name: String) -> Result(MenuStep, Nil) {
  case name {
    "categories" -> Ok(ShowCategories)
    "items" -> Ok(ShowItems)
    _ -> Error(Nil)
  }
}

pub fn create_menu_flow(
  db: sqlight.Connection,
) -> types.Flow(MenuStep, Nil, String, Dependencies) {
  // `db` builds the flow's persistence backend at init. The menu steps use mock
  // data and don't query the db, so they take no db at all.
  let storage = util.create_database_storage(db)

  builder.new("menu", storage, step_to_string, string_to_step)
  |> builder.add_step(ShowCategories, show_categories_step)
  |> builder.add_step(ShowItems, show_items_step)
  |> builder.on_error(fn(ctx, _, error) {
    let error_msg = option.unwrap(error, "Unknown error")
    util.log_error("Menu flow error: " <> error_msg)
    let _ =
      reply.with_text(
        ctx,
        i18n.t(ctx, "menu.error", [#("error", i18n.t(ctx, error_msg, []))]),
      )
    Ok(ctx)
  })
  |> builder.build(initial: ShowCategories)
}

fn show_categories_step(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(MenuStep, Nil, String, Dependencies) {
  let categories = get_menu_categories()

  let menu =
    menu_builder.new("categories")
    |> menu_builder.title(
      i18n.t(ctx, "menu.title", [#("restaurant", util.get_restaurant_name())]),
    )
    |> menu_builder.section(Some(i18n.t(ctx, "menu.food_categories", [])))
    |> menu_builder.add_items_from_list(categories, fn(category, _index) {
      #(
        category.emoji
          <> " "
          <> category.name
          <> " ("
          <> i18n.tn(ctx, "menu.items", category.item_count, [])
          <> ")",
        "category:" <> category.name,
      )
    })
    |> menu_builder.section(Some(i18n.t(ctx, "menu.reservations", [])))
    |> menu_builder.add_item(
      i18n.t(ctx, "menu.make_reservation", []),
      "book_table",
    )
    |> menu_builder.add_item(i18n.t(ctx, "menu.my_bookings", []), "my_bookings")
    |> menu_builder.layout(2, None, True)
    |> menu_builder.build()

  case menu_builder.to_keyboard(menu) {
    Ok(keyboard) -> {
      let markup = keyboard.to_inline_markup(keyboard)
      case reply.with_markup(ctx, menu_builder.get_title(menu), markup) {
        Ok(_) -> action.wait_callback(ctx, instance)
        Error(_) -> Error("Failed to send menu")
      }
    }
    Error(msg) -> Error("Failed to create menu: " <> msg)
  }
}

/// Show items in selected category
fn show_items_step(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(MenuStep, Nil, String, Dependencies) {
  // Get category from flow data
  case instance.get_data(instance, "selected_category") {
    Some(category) -> {
      let items = get_menu_items(category)

      let menu =
        menu_builder.new("items")
        |> menu_builder.title(
          i18n.t(ctx, "menu.category_menu", [#("category", category)]),
        )
        |> menu_builder.add_items_from_list(items, fn(item, _index) {
          #(item.name <> " - " <> item.price, "item:" <> int.to_string(item.id))
        })
        |> menu_builder.paginate_with_text(
          6,
          True,
          i18n.t(ctx, "menu.prev", []),
          i18n.t(ctx, "menu.next", []),
          // {current}/{total} are filled by menu_builder, not i18n.
          i18n.t(ctx, "menu.page", []),
        )
        |> menu_builder.with_back_button_text(
          "back_to_categories",
          i18n.t(ctx, "menu.back", []),
        )
        |> menu_builder.layout(1, None, False)
        |> menu_builder.build()

      case menu_builder.to_keyboard(menu) {
        Ok(keyboard) -> {
          let markup = keyboard.to_inline_markup(keyboard)
          case reply.with_markup(ctx, menu_builder.get_title(menu), markup) {
            Ok(_) -> action.wait_callback(ctx, instance)
            Error(_) -> Error("Failed to send items menu")
          }
        }
        Error(msg) -> Error("Failed to create items menu: " <> msg)
      }
    }
    None -> Error("No category selected")
  }
}

// Helper Functions ------------------------------------------------------------------------------------

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

/// Handle menu navigation callbacks
pub fn handle_menu_callback(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
  callback_data: String,
) -> types.StepResult(MenuStep, Nil, String, Dependencies) {
  case string.starts_with(callback_data, "category:") {
    True -> {
      let category = string.drop_start(callback_data, 9)
      // Store selected category in flow data
      let updated_instance =
        instance.store_data(instance, "selected_category", category)
      action.next(ctx, updated_instance, ShowItems)
    }
    False -> {
      case string.starts_with(callback_data, "item:") {
        True -> {
          let item_id_str = string.drop_start(callback_data, 5)
          case int.parse(item_id_str) {
            Ok(item_id) -> {
              let item_info =
                i18n.t(ctx, "menu.item_info", [
                  #("id", int.to_string(item_id)),
                ])
              let _ = reply.with_text(ctx, item_info)
              action.complete(ctx, instance)
            }
            Error(_) -> Error("Invalid item ID")
          }
        }
        False -> {
          case callback_data {
            "back_to_categories" -> action.next(ctx, instance, ShowCategories)
            "book_table" -> {
              let _ = reply.with_text(ctx, i18n.t(ctx, "menu.use_book", []))
              action.complete(ctx, instance)
            }
            "my_bookings" -> {
              let _ =
                reply.with_text(ctx, i18n.t(ctx, "menu.use_my_bookings", []))
              action.complete(ctx, instance)
            }
            _ -> Error("Unknown menu action: " <> callback_data)
          }
        }
      }
    }
  }
}
