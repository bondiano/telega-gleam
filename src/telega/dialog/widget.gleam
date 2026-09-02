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
//// - `counter` — a number nudged with −/+ within `min`…`max`; read with
////   `counter_value`.
//// - `calendar` — a month grid bounded by a date range, with month paging.
//// - `list_group` — a row of buttons per item ("Edit / Delete" per row).
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
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import gleam/time/calendar

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

// List group ----------------------------------------------------------------------

/// One button repeated for every item of a `list_group`. `label` builds its
/// text from the item, so it can carry the item's own name.
pub type ItemAction {
  ItemAction(id: String, label: fn(SelectItem) -> String)
}

/// A row of buttons **per item** — the shape `select` cannot express, where
/// every row acts on one thing: "Edit / Delete", "▲ / ▼", "Book / Details".
///
/// A press calls `on_action` with the pressed action id and the item id.
/// Callback data is `w:<widget_id>:<action_id>` carrying the item id as its
/// argument, so keep both short (the 64-byte limit is checked on every
/// render). Item ids the widget does not currently offer are ignored —
/// callback data can be forged or come from an outdated message.
///
/// ```gleam
/// widget.list_group(
///   id: "bk",
///   items: fn(state: State, _ctx) {
///     list.map(state.bookings, fn(b) { SelectItem(id: b.id, label: b.date) })
///   },
///   actions: [
///     widget.ItemAction("open", fn(item: SelectItem) { item.label }),
///     widget.ItemAction("drop", fn(_item) { "🗑" }),
///   ],
///   on_action: fn(state, action, item_id, _ctx) {
///     case action {
///       "open" -> Ok(types.Goto("details", select_booking(state, item_id)))
///       _ -> Ok(types.Stay(remove_booking(state, item_id)))
///     }
///   },
/// )
/// ```
pub fn list_group(
  id id: String,
  items items: fn(state, Context(session, error, dependencies)) ->
    List(SelectItem),
  actions actions: List(ItemAction),
  on_action on_action: fn(
    state,
    String,
    String,
    Context(session, error, dependencies),
  ) -> Result(DialogAction(state), error),
) -> KeyboardWidget(state, session, error, dependencies) {
  KeyboardWidget(
    id:,
    render: fn(wctx: WidgetCtx(state, session, error, dependencies)) {
      items(wctx.state, wctx.ctx)
      |> list.map(fn(item) {
        list.map(actions, fn(item_action: ItemAction) {
          types.ActionArgButton(
            item_action.label(item),
            action(id, item_action.id),
            item.id,
          )
        })
      })
    },
    on_event: fn(wctx, cmd, arg) {
      let known = list.any(actions, fn(a: ItemAction) { a.id == cmd })
      case known, arg {
        True, Some(item_id) ->
          case offers(items, wctx, item_id) {
            True ->
              on_action(wctx.state, cmd, item_id, wctx.ctx)
              |> result.map(types.Emit)
            False -> Ok(types.StoreUpdated(wctx.store))
          }
        _, _ -> Ok(types.StoreUpdated(wctx.store))
      }
    },
    goto_targets: [],
    static_actions: list.map(actions, fn(a: ItemAction) { action(id, a.id) }),
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
/// engine's automatic stash before user code.
///
/// **Merges** into the current stash, so several widgets can be seeded for one
/// render. Tests in the same process therefore inherit each other's seeds:
/// call `reset_stores` first when that matters.
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

/// Drop everything `seed_store` put in place. Tests run in one process, so a
/// seed from an earlier test is still visible without this.
pub fn reset_stores() -> Nil {
  clear_stash()
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

// Counter -------------------------------------------------------------------------

const counter_key = "count"

/// A number the user nudges with `labels.decrement` / `labels.increment`,
/// clamped to `min`…`max`. The value lives in the widget store; read it with
/// `counter_value`, passing the same `initial`.
///
/// ```gleam
/// |> dialog.window_with_widgets(id: "guests", render:, on_action:, widgets: [
///   widget.counter(id: "n", min: 1, max: 12, step: 1, initial: 2),
/// ])
///
/// // in the render or a handler:
/// let guests =
///   dialog.widget_store(ctx, window_id: "guests", widget_id: "n")
///   |> widget.counter_value(default: 2)
/// ```
pub fn counter(
  id id: String,
  min min: Int,
  max max: Int,
  step step: Int,
  initial initial: Int,
) -> KeyboardWidget(state, session, error, dependencies) {
  KeyboardWidget(
    id:,
    render: fn(wctx: WidgetCtx(state, session, error, dependencies)) {
      let value = counter_value(wctx.store, default: initial)
      [
        [
          types.ActionButton(wctx.labels.decrement, action(id, "dec")),
          // The value itself is a button because Telegram has no other way to
          // put text in a keyboard row; pressing it does nothing.
          types.ActionButton(int.to_string(value), action(id, "noop")),
          types.ActionButton(wctx.labels.increment, action(id, "inc")),
        ],
      ]
    },
    on_event: fn(wctx, cmd, _arg) {
      let value = counter_value(wctx.store, default: initial)
      let next = case cmd {
        "dec" -> value - step
        "inc" -> value + step
        _ -> value
      }
      let clamped = int.clamp(next, min:, max:)
      Ok(
        types.StoreUpdated(types.store_set(
          wctx.store,
          counter_key,
          int.to_string(clamped),
        )),
      )
    },
    goto_targets: [],
    static_actions: [action(id, "dec"), action(id, "inc"), action(id, "noop")],
  )
}

/// The number in a `counter` store, or `default` before the first press.
pub fn counter_value(store store: WidgetStore, default default: Int) -> Int {
  types.store_get(store, counter_key)
  |> option.then(fn(raw) { option.from_result(int.parse(raw)) })
  |> option.unwrap(default)
}

// Calendar ------------------------------------------------------------------------

const calendar_view_key = "view"

/// A month grid of days with `‹`/`›` month navigation, bounded by `from`…`to`.
///
/// Pressing a day calls `on_picked` with that date and emits whatever action
/// it returns — usually a `Goto` or a `Stay` that stores the date in your own
/// state. The displayed month lives in the widget store, so paging around does
/// not touch the dialog state.
///
/// ```gleam
/// widget.calendar(
///   id: "date",
///   from: calendar.Date(2026, calendar.September, 1),
///   to: calendar.Date(2026, calendar.December, 31),
///   on_picked: fn(state, date, _ctx) { Ok(types.Goto("time", with_date(state, date))) },
/// )
/// ```
pub fn calendar(
  id id: String,
  from from: calendar.Date,
  to to: calendar.Date,
  on_picked on_picked: fn(
    state,
    calendar.Date,
    Context(session, error, dependencies),
  ) -> Result(DialogAction(state), error),
) -> KeyboardWidget(state, session, error, dependencies) {
  KeyboardWidget(
    id:,
    render: fn(wctx: WidgetCtx(state, session, error, dependencies)) {
      let #(year, month) = viewed_month(wctx.store, from)
      let header = [
        types.ActionButton(wctx.labels.prev, action(id, "prev")),
        types.ActionButton(
          calendar.month_to_string(month) <> " " <> int.to_string(year),
          action(id, "noop"),
        ),
        types.ActionButton(wctx.labels.next, action(id, "next")),
      ]
      let weekdays =
        list.map(wctx.labels.weekdays, types.ActionButton(_, action(id, "noop")))

      [header, weekdays, ..day_rows(id, year, month, from, to)]
    },
    on_event: fn(wctx, cmd, arg) {
      let #(year, month) = viewed_month(wctx.store, from)
      case cmd, arg {
        "prev", _ -> Ok(shift_month(wctx.store, year, month, -1, from, to))
        "next", _ -> Ok(shift_month(wctx.store, year, month, 1, from, to))
        // Only a date the grid currently offers is accepted — callback data
        // can be forged or come from an outdated message.
        "day", Some(raw) ->
          case parse_date(raw) {
            Ok(date) ->
              case date_within(date, from, to) {
                True ->
                  on_picked(wctx.state, date, wctx.ctx)
                  |> result.map(types.Emit)
                False -> Ok(types.StoreUpdated(wctx.store))
              }
            Error(Nil) -> Ok(types.StoreUpdated(wctx.store))
          }
        _, _ -> Ok(types.StoreUpdated(wctx.store))
      }
    },
    goto_targets: [],
    static_actions: [
      action(id, "prev"),
      action(id, "next"),
      action(id, "noop"),
      action(id, "day"),
    ],
  )
}

/// The month currently on screen: what the store remembers, or the month
/// `from` falls in.
fn viewed_month(
  store: WidgetStore,
  from: calendar.Date,
) -> #(Int, calendar.Month) {
  case types.store_get(store, calendar_view_key) {
    Some(raw) ->
      case string.split(raw, "-") {
        [year, month] ->
          case int.parse(year), int.parse(month) {
            Ok(year), Ok(month) ->
              case calendar.month_from_int(month) {
                Ok(month) -> #(year, month)
                Error(Nil) -> #(from.year, from.month)
              }
            _, _ -> #(from.year, from.month)
          }
        _ -> #(from.year, from.month)
      }
    None -> #(from.year, from.month)
  }
}

fn shift_month(
  store: WidgetStore,
  year: Int,
  month: calendar.Month,
  by: Int,
  from: calendar.Date,
  to: calendar.Date,
) -> WidgetResult(state) {
  let index = year * 12 + calendar.month_to_int(month) - 1 + by
  let first = from.year * 12 + calendar.month_to_int(from.month) - 1
  let last = to.year * 12 + calendar.month_to_int(to.month) - 1
  let index = int.clamp(index, min: first, max: last)

  types.StoreUpdated(types.store_set(
    store,
    calendar_view_key,
    int.to_string(index / 12) <> "-" <> int.to_string(index % 12 + 1),
  ))
}

/// Weeks of the month as button rows, Monday first, padded so the 1st sits
/// under its weekday. Days outside `from`…`to` render as blanks.
fn day_rows(
  widget_id: String,
  year: Int,
  month: calendar.Month,
  from: calendar.Date,
  to: calendar.Date,
) -> List(List(DialogButton)) {
  let blank = types.ActionButton(" ", action(widget_id, "noop"))
  let leading = list.repeat(blank, weekday_index(year, month, 1))
  let days =
    // `int.range`'s `to` is exclusive, so count down past 1 to include it.
    int.range(
      from: days_in_month(year, month),
      to: 0,
      with: [],
      run: fn(acc, day) { [day, ..acc] },
    )
    |> list.map(fn(day) {
      let date = calendar.Date(year:, month:, day:)
      case date_within(date, from, to) {
        True ->
          types.ActionArgButton(
            int.to_string(day),
            action(widget_id, "day"),
            format_date(date),
          )
        False -> blank
      }
    })
  list.append(leading, days)
  |> list.sized_chunk(into: 7)
}

fn date_within(
  date: calendar.Date,
  from: calendar.Date,
  to: calendar.Date,
) -> Bool {
  calendar.naive_date_compare(date, from) != order.Lt
  && calendar.naive_date_compare(date, to) != order.Gt
}

fn days_in_month(year: Int, month: calendar.Month) -> Int {
  case month {
    calendar.January
    | calendar.March
    | calendar.May
    | calendar.July
    | calendar.August
    | calendar.October
    | calendar.December -> 31
    calendar.April | calendar.June | calendar.September | calendar.November ->
      30
    calendar.February ->
      case calendar.is_leap_year(year) {
        True -> 29
        False -> 28
      }
  }
}

/// Zeller's congruence, shifted so Monday is 0 — the column a date sits in.
fn weekday_index(year: Int, month: calendar.Month, day: Int) -> Int {
  let month_number = calendar.month_to_int(month)
  // January and February count as months 13 and 14 of the previous year.
  let #(y, m) = case month_number < 3 {
    True -> #(year - 1, month_number + 12)
    False -> #(year, month_number)
  }
  let k = y % 100
  let j = y / 100
  let h = { day + { 13 * { m + 1 } } / 5 + k + k / 4 + j / 4 + 5 * j } % 7
  // Zeller: 0 = Saturday. Monday first means Monday must land on 0.
  { h + 5 } % 7
}

fn format_date(date: calendar.Date) -> String {
  int.to_string(date.year)
  <> "-"
  <> pad2(calendar.month_to_int(date.month))
  <> "-"
  <> pad2(date.day)
}

fn pad2(value: Int) -> String {
  int.to_string(value) |> string.pad_start(to: 2, with: "0")
}

fn parse_date(raw: String) -> Result(calendar.Date, Nil) {
  case string.split(raw, "-") {
    [year, month, day] -> {
      use year <- result.try(int.parse(year))
      use month <- result.try(int.parse(month))
      use day <- result.try(int.parse(day))
      use month <- result.try(calendar.month_from_int(month))
      let date = calendar.Date(year:, month:, day:)
      case calendar.is_valid_date(date) {
        True -> Ok(date)
        False -> Error(Nil)
      }
    }
    _ -> Error(Nil)
  }
}
