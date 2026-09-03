//// Tests for the menu dialog.
////
//// Window renders are pure, so the frames are checked without a network; the
//// navigation is checked by exporting the dialog's graph, which presses every
//// button the windows render and records where each one leads.

import birdie
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import sqlight

import telega/bot as telega_bot
import telega/testing/context
import telega/testing/graph
import telega/testing/render
import telega_i18n

import restaurant_booking/dependencies.{type Dependencies, Dependencies}
import restaurant_booking/flows/menu
import restaurant_booking/i18n

import test_db

fn run_with_db(test_fn: fn(sqlight.Connection) -> Nil) -> Nil {
  case test_db.try_connect_and_setup() {
    None -> Nil
    Some(db) -> {
      test_fn(db)
      test_db.cleanup(db)
    }
  }
}

fn with_locale(
  locale: String,
  db: sqlight.Connection,
  test_fn: fn(telega_bot.Context(Nil, String, Dependencies)) -> Nil,
) -> Nil {
  let catalog = i18n.catalog()
  let ctx =
    context.context_with_dependencies(
      session: Nil,
      dependencies: Dependencies(db:, catalog:),
    )
  telega_i18n.enter(ctx, catalog:, locale:)
  test_fn(ctx)
  telega_i18n.leave(ctx)
}

pub fn menu_dialog_builds_test() {
  use db <- run_with_db
  // `build()` validates window ids, widget ids and the 64-byte callback
  // budget — a category name travelling in a button argument is the part
  // worth a smoke test.
  let _dialog = menu.create_menu_dialog(db)
  Nil
}

pub fn categories_window_frame_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  let frame =
    render.window_frame(menu.render_categories(
      menu.MenuState(category: "", item: None),
      ctx,
    ))
  frame |> string.contains("Food Categories") |> should.be_true()
  // The item count is pluralized through the catalog.
  frame |> string.contains("(8 items)") |> should.be_true()
  frame |> birdie.snap(title: "menu:categories:frame_en")
}

/// The window's own frame is the header and the way back — the dish buttons
/// and the pager are the `paged_select` widget's rows, which the engine
/// appends after these (the graph snapshot below is what covers them).
pub fn items_window_frame_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  menu.render_items(menu.MenuState(category: "Appetizers", item: None), ctx)
  |> render.window_frame
  |> birdie.snap(title: "menu:items:frame_en")
}

pub fn item_window_shows_the_dish_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  let frame =
    render.window_frame(menu.render_item(
      menu.MenuState(category: "Appetizers", item: Some(1)),
      ctx,
    ))
  frame |> string.contains("Caesar Salad") |> should.be_true()
  frame |> string.contains("$12.99") |> should.be_true()
}

/// A dish id that is no longer in the category must render something rather
/// than take the window down.
pub fn item_window_survives_a_missing_dish_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  render.window_frame(menu.render_item(
    menu.MenuState(category: "Appetizers", item: Some(999)),
    ctx,
  ))
  |> string.contains("no longer on the menu")
  |> should.be_true()
}

pub fn menu_dialog_graph_snapshot_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  graph.of_dialog_probing(
    dialog: menu.create_menu_dialog(db),
    ctx:,
    states: [menu.MenuState(category: "Appetizers", item: Some(1))],
    texts: [],
  )
  |> graph.to_mermaid
  |> birdie.snap(title: "menu:dialog:graph")
}
