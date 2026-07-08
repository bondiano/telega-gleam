//// Built-in managed keyboard widgets for dialogs.
////
//// A widget renders extra button rows for a window and handles their events
//// itself (see `KeyboardWidget` in `telega/dialog/types`): the dialog engine
//// appends widget rows after the window's own buttons and routes widget
//// button presses (`w:<widget_id>:<cmd>` action ids) to the widget, bypassing
//// the window's `on_action`. Widget state lives in a per-widget `WidgetStore`
//// persisted with the dialog instance, so selections and page positions
//// survive restarts.
////
//// Built-ins:
////
//// - `pager` — page navigation row (`‹ 2/5 ›`); read the page with
////   `current_page` to slice content in the window's render.
//// - `select` — one-shot choice: a press calls `on_selected` (usually a
////   `Goto`).
//// - `radio` — single choice kept in the store, marked with
////   `labels.checked`; read with `radio_value`.
//// - `multiselect` — a set of choices with checkboxes and a `done` button
////   shown only while the selection count is within `min`/`max`; read with
////   `multiselect_values`.
//// - `paged_select` — `select` and `pager` combined: items are sliced by the
////   widget itself.
////
//// Reading widget state from window handlers (`on_action`, `on_text`,
//// `on_done`) and renders goes through `dialog.widget_store`:
////
//// ```gleam
//// let zone =
////   dialog.widget_store(ctx, window_id: "prefs", widget_id: "zone")
////   |> widget.radio_value
////   |> option.unwrap("hall")
//// ```
////
//// All user-facing symbols (`‹`, `›`, `●`, `☑`, "done") come from the
//// dialog's `Labels` — override them with `dialog.with_labels` for i18n.

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, Some}
import gleam/result
import gleam/string

import telega/bot.{type Context}
import telega/dialog/types.{
  type DialogAction, type DialogButton, type KeyboardWidget, type Labels,
  type WidgetCtx, type WidgetResult, type WidgetStore, KeyboardWidget,
}

/// An item offered by `select`/`radio`/`multiselect`/`paged_select`. The `id`
/// travels in callback data — keep it short (the 64-byte limit is validated
/// on every render) and without `:` at the edges of your scheme (an id may
/// contain `:`, it is re-joined on parse).
pub type SelectItem {
  SelectItem(id: String, label: String)
}

const page_key = "page"

const value_key = "value"

const values_key = "values"

// Pager ---------------------------------------------------------------------------

/// Page navigation: the store keeps the current page, the row renders as
/// `‹  2/5  ›` (the counter is a no-op button). `total` returns the number of
/// items; the row disappears when everything fits on one page. Slice your
/// content in the window's render with `current_page`.
pub fn pager(
  id id: String,
  page_size page_size: Int,
  total total: fn(state, Context(session, error, dependencies)) -> Int,
) -> KeyboardWidget(state, session, error, dependencies) {
  KeyboardWidget(
    id:,
    render: fn(wctx: WidgetCtx(state, session, error, dependencies)) {
      let pages = page_count(total(wctx.state, wctx.ctx), page_size)
      pager_row(
        id,
        clamp_page(current_page(wctx.store), pages),
        pages,
        wctx.labels,
      )
    },
    on_event: fn(wctx, cmd, _arg) {
      let pages = page_count(total(wctx.state, wctx.ctx), page_size)
      Ok(types.StoreUpdated(turn_page(wctx.store, cmd, pages)))
    },
    goto_targets: [],
    static_actions: [action(id, "prev"), action(id, "next")],
  )
}

/// The current 0-based page kept by a `pager`/`paged_select` store.
pub fn current_page(store store: WidgetStore) -> Int {
  types.store_get(store, page_key)
  |> option.map(int.parse)
  |> option.map(option.from_result)
  |> option.flatten
  |> option.unwrap(0)
}

// Select --------------------------------------------------------------------------

/// One-shot choice: each item is a button, a press calls `on_selected` with
/// the item id and the resulting `DialogAction` is applied (usually a
/// `Goto`). Nothing is stored. `columns` lays the buttons out in a grid
/// (`1` = one item per row).
pub fn select(
  id id: String,
  items items: fn(state, Context(session, error, dependencies)) ->
    List(SelectItem),
  columns columns: Int,
  on_selected on_selected: fn(
    state,
    String,
    Context(session, error, dependencies),
  ) -> Result(DialogAction(state), error),
) -> KeyboardWidget(state, session, error, dependencies) {
  KeyboardWidget(
    id:,
    render: fn(wctx: WidgetCtx(state, session, error, dependencies)) {
      items(wctx.state, wctx.ctx)
      |> item_grid(id, columns)
    },
    on_event: fn(wctx, cmd, arg) {
      pick_or_ignore(wctx, cmd, arg, items, on_selected)
    },
    goto_targets: [],
    static_actions: [action(id, "pick")],
  )
}

// Radio ---------------------------------------------------------------------------

/// Single choice kept in the widget store: the selected item is marked with
/// `labels.checked`, the rest with `labels.unchecked`. `default` is only a
/// visual pre-selection — `radio_value` stays `None` until the user actually
/// picks, so apply the same default when reading.
pub fn radio(
  id id: String,
  items items: fn(state, Context(session, error, dependencies)) ->
    List(SelectItem),
  default default: Option(String),
) -> KeyboardWidget(state, session, error, dependencies) {
  KeyboardWidget(
    id:,
    render: fn(wctx: WidgetCtx(state, session, error, dependencies)) {
      let selected = radio_value(wctx.store) |> option.or(default)
      items(wctx.state, wctx.ctx)
      |> list.map(fn(item) {
        let mark = case selected == Some(item.id) {
          True -> wctx.labels.checked
          False -> wctx.labels.unchecked
        }
        [types.ActionArgButton(mark <> item.label, action(id, "pick"), item.id)]
      })
    },
    on_event: fn(wctx, cmd, arg) {
      case cmd, arg {
        // Only ids the widget currently offers are stored — callback data
        // can be forged or outdated.
        "pick", Some(item_id) ->
          case offers(items, wctx, item_id) {
            True ->
              Ok(
                types.StoreUpdated(types.store_set(
                  wctx.store,
                  value_key,
                  item_id,
                )),
              )
            False -> Ok(types.StoreUpdated(wctx.store))
          }
        _, _ -> Ok(types.StoreUpdated(wctx.store))
      }
    },
    goto_targets: [],
    static_actions: [action(id, "pick")],
  )
}

/// The item id picked in a `radio` store, `None` until the first press.
pub fn radio_value(store store: WidgetStore) -> Option(String) {
  types.store_get(store, value_key)
}

// Multiselect ---------------------------------------------------------------------

/// A set of choices with checkbox marks. Toggling above `max` is ignored;
/// the `labels.done` button renders only while the count is within
/// `min`/`max` and emits `Goto(done, state)` when pressed. `done` must be an
/// existing window id — validated by `dialog.build()`.
pub fn multiselect(
  id id: String,
  items items: fn(state, Context(session, error, dependencies)) ->
    List(SelectItem),
  min min: Int,
  max max: Int,
  done done: String,
) -> KeyboardWidget(state, session, error, dependencies) {
  KeyboardWidget(
    id:,
    render: fn(wctx: WidgetCtx(state, session, error, dependencies)) {
      let selected = multiselect_values(wctx.store)
      let rows =
        items(wctx.state, wctx.ctx)
        |> list.map(fn(item) {
          let mark = case list.contains(selected, item.id) {
            True -> wctx.labels.checkbox_on
            False -> wctx.labels.checkbox_off
          }
          [
            types.ActionArgButton(
              mark <> item.label,
              action(id, "tgl"),
              item.id,
            ),
          ]
        })
      case within(list.length(selected), min, max) {
        True ->
          list.append(rows, [
            [types.ActionButton(wctx.labels.done, action(id, "done"))],
          ])
        False -> rows
      }
    },
    on_event: fn(wctx, cmd, arg) {
      case cmd, arg {
        // See `pick_or_ignore`: only offered ids may be toggled.
        "tgl", Some(item_id) ->
          case offers(items, wctx, item_id) {
            True -> Ok(types.StoreUpdated(toggle(wctx.store, item_id, max)))
            False -> Ok(types.StoreUpdated(wctx.store))
          }
        "done", _ ->
          case within(list.length(multiselect_values(wctx.store)), min, max) {
            True -> Ok(types.Emit(types.Goto(done, wctx.state)))
            // A stale press on a "done" that is no longer valid: re-render.
            False -> Ok(types.StoreUpdated(wctx.store))
          }
        _, _ -> Ok(types.StoreUpdated(wctx.store))
      }
    },
    goto_targets: [done],
    static_actions: [action(id, "tgl"), action(id, "done")],
  )
}

/// The item ids currently selected in a `multiselect` store, in pick order.
pub fn multiselect_values(store store: WidgetStore) -> List(String) {
  types.store_get(store, values_key)
  |> option.map(fn(raw) {
    json.parse(raw, decode.list(decode.string))
    |> result.unwrap([])
  })
  |> option.unwrap([])
}

fn toggle(store: WidgetStore, item_id: String, max: Int) -> WidgetStore {
  let values = multiselect_values(store)
  let values = case list.contains(values, item_id) {
    True -> list.filter(values, fn(value) { value != item_id })
    False ->
      case list.length(values) >= max {
        True -> values
        False -> list.append(values, [item_id])
      }
  }
  types.store_set(
    store,
    values_key,
    json.to_string(json.array(values, json.string)),
  )
}

fn within(count: Int, min: Int, max: Int) -> Bool {
  min <= count && count <= max
}

// Paged select ---------------------------------------------------------------------

/// `select` and `pager` in one widget: items are sliced to the current page
/// by the widget itself (`page_size` counts items, not rows), the pager row
/// appears only when there is more than one page.
pub fn paged_select(
  id id: String,
  items items: fn(state, Context(session, error, dependencies)) ->
    List(SelectItem),
  page_size page_size: Int,
  columns columns: Int,
  on_selected on_selected: fn(
    state,
    String,
    Context(session, error, dependencies),
  ) -> Result(DialogAction(state), error),
) -> KeyboardWidget(state, session, error, dependencies) {
  KeyboardWidget(
    id:,
    render: fn(wctx: WidgetCtx(state, session, error, dependencies)) {
      let all = items(wctx.state, wctx.ctx)
      let pages = page_count(list.length(all), page_size)
      let page = clamp_page(current_page(wctx.store), pages)
      let rows =
        all
        |> list.drop(page * page_size)
        |> list.take(page_size)
        |> item_grid(id, columns)
      list.append(rows, pager_row(id, page, pages, wctx.labels))
    },
    on_event: fn(wctx, cmd, arg) {
      case cmd {
        "pick" -> pick_or_ignore(wctx, cmd, arg, items, on_selected)
        _ -> {
          let pages =
            page_count(list.length(items(wctx.state, wctx.ctx)), page_size)
          Ok(types.StoreUpdated(turn_page(wctx.store, cmd, pages)))
        }
      }
    },
    goto_targets: [],
    static_actions: [action(id, "pick"), action(id, "prev"), action(id, "next")],
  )
}

// Shared helpers --------------------------------------------------------------------

fn action(widget_id: String, cmd: String) -> String {
  "w:" <> widget_id <> ":" <> cmd
}

fn item_grid(
  items: List(SelectItem),
  widget_id: String,
  columns: Int,
) -> List(List(DialogButton)) {
  items
  |> list.map(fn(item) {
    types.ActionArgButton(item.label, action(widget_id, "pick"), item.id)
  })
  |> list.sized_chunk(into: int.max(columns, 1))
}

/// A picked id is only trusted if the widget currently offers it — callback
/// data arrives from the client and can be forged or outdated, so an unknown
/// id is ignored (re-render) instead of reaching `on_selected`.
fn pick_or_ignore(
  wctx: WidgetCtx(state, session, error, dependencies),
  cmd: String,
  arg: Option(String),
  items: fn(state, Context(session, error, dependencies)) -> List(SelectItem),
  on_selected: fn(state, String, Context(session, error, dependencies)) ->
    Result(DialogAction(state), error),
) -> Result(WidgetResult(state), error) {
  case cmd, arg {
    "pick", Some(item_id) ->
      case offers(items, wctx, item_id) {
        True ->
          on_selected(wctx.state, item_id, wctx.ctx) |> result.map(types.Emit)
        False -> Ok(types.StoreUpdated(wctx.store))
      }
    _, _ -> Ok(types.StoreUpdated(wctx.store))
  }
}

fn offers(
  items: fn(state, Context(session, error, dependencies)) -> List(SelectItem),
  wctx: WidgetCtx(state, session, error, dependencies),
  item_id: String,
) -> Bool {
  list.any(items(wctx.state, wctx.ctx), fn(item) { item.id == item_id })
}

fn page_count(total: Int, page_size: Int) -> Int {
  case total <= 0 || page_size <= 0 {
    True -> 1
    False -> { total + page_size - 1 } / page_size
  }
}

fn clamp_page(page: Int, pages: Int) -> Int {
  int.clamp(page, 0, int.max(pages - 1, 0))
}

fn turn_page(store: WidgetStore, cmd: String, pages: Int) -> WidgetStore {
  let page = current_page(store)
  let page = case cmd {
    "prev" -> page - 1
    "next" -> page + 1
    _ -> page
  }
  types.store_set(store, page_key, int.to_string(clamp_page(page, pages)))
}

fn pager_row(
  widget_id: String,
  page: Int,
  pages: Int,
  labels: Labels,
) -> List(List(DialogButton)) {
  case pages > 1 {
    False -> []
    True -> {
      let info =
        labels.page_info
        |> string.replace("{current}", int.to_string(page + 1))
        |> string.replace("{total}", int.to_string(pages))
      [
        [
          types.ActionButton(labels.prev, action(widget_id, "prev")),
          types.NoopButton(info),
          types.ActionButton(labels.next, action(widget_id, "next")),
        ],
      ]
    }
  }
}

// Store access from user code --------------------------------------------------------
//
// Window renders and handlers receive only `(state, ctx)`, while widget
// stores live in the flow instance. The engine stashes the instance's widget
// entries in the process dictionary before invoking any user code (the chat
// instance is a single process, so this is race-free — same precedent as the
// answered-callback flag in `dialog/render`), and `widget_store` reads from
// that stash.

const stores_pdict_key = "__telega_dialog_widget_stores"

const store_data_prefix = "__dialog_widget:"

/// The instance-data key a widget's store is persisted under.
@internal
pub fn store_data_key(window_id: String, widget_id: String) -> String {
  store_data_prefix <> window_id <> ":" <> widget_id
}

/// Stash the instance data for `widget_store` reads. Called by the engine
/// before user code runs; replaces the previous stash. The full dict is
/// stashed as-is (an O(1) reference on the BEAM) — `widget_store` looks up
/// its `__dialog_widget:` key directly.
@internal
pub fn stash_stores(data: Dict(String, String)) -> Nil {
  let _ = pdict_put(stores_pdict_key, data)
  Nil
}

/// Drop the stash — called by the engine when the dialog finishes, so later
/// non-dialog handlers don't read the finished dialog's stores.
@internal
pub fn clear_stash() -> Nil {
  let _ = pdict_erase(stores_pdict_key)
  Nil
}

/// Read a widget's store from inside a window render or handler. Returns an
/// empty store when the widget has no state yet. Prefer the typed readers on
/// top: `radio_value`, `multiselect_values`, `current_page`.
pub fn widget_store(
  _ctx: Context(session, error, dependencies),
  window_id window_id: String,
  widget_id widget_id: String,
) -> WidgetStore {
  stashed_stores()
  |> dict.get(store_data_key(window_id, widget_id))
  |> result.try(fn(raw) { types.decode_store(raw) })
  |> result.unwrap(types.new_store())
}

/// Seed a widget store for pure render tests — the runtime equivalent is the
/// engine's automatic stash before user code. Merges into the current stash.
pub fn seed_store(
  window_id window_id: String,
  widget_id widget_id: String,
  store store: WidgetStore,
) -> Nil {
  let stores =
    dict.insert(
      stashed_stores(),
      store_data_key(window_id, widget_id),
      types.encode_store(store),
    )
  let _ = pdict_put(stores_pdict_key, stores)
  Nil
}

fn stashed_stores() -> Dict(String, String) {
  pdict_get(stores_pdict_key)
  |> decode.run(decode.dict(decode.string, decode.string))
  |> result.unwrap(dict.new())
}

@external(erlang, "erlang", "put")
fn pdict_put(key: String, value: Dict(String, String)) -> Dynamic

@external(erlang, "erlang", "get")
fn pdict_get(key: String) -> Dynamic

@external(erlang, "erlang", "erase")
fn pdict_erase(key: String) -> Dynamic
