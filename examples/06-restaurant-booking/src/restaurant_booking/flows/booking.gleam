//// Table booking as a **declarative dialog** (`telega/dialog`).
////
//// Unlike the registration and menu *flows* in this example (hand-written
//// steps, manual sends), a dialog is a set of windows rendered into one live
//// message: the engine edits it on every transition, builds callback data
//// for the buttons, and supports `Back` out of the box. State persists in
//// the same SQLite-backed flow storage, so a half-finished booking survives
//// restarts.
////
//// ```
//// /book → [date]   text input, format validated in-window
////       → [time]   paged_select widget: 12 slots, 6 per page + ‹ Back
////       → [guests] select widget: a 1-6 grid + ‹ Back
////       → [prefs]  radio (seating area) + multiselect (extras) → Done
////       → [confirm] summary → ✅ creates the booking → success message
////                          → 📷 [photo] media window (hall photo, text ↔ media)
////                          → 🏠 StartSub(delivery_address: city → street)
//// ```
////
//// Validation errors are part of the window state and re-rendered
//// declaratively — no ad-hoc error messages breaking the single-message UI.
//// The time/guests/prefs keyboards are **managed widgets**
//// (`telega/dialog/widget`): the engine renders their buttons, handles their
//// callbacks, and persists their selections with the dialog instance; the
//// confirm window reads them back with `dialog.widget_store`.
////
//// The optional delivery address is a **sub-dialog** (`dialog.subdialog`):
//// a reusable two-window dialog with its own state type that takes over the
//// same live message; its `Done` hands the exported result dict to the
//// confirm window's `on_sub_result`, which stores the address in
//// `BookingState`. `‹ Back` on its first window cancels it.

import gleam/dict
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import sqlight

import telega/bot.{type Context}
import telega/dialog
import telega/dialog/types.{type ActionEvent, type DialogAction} as dtypes
import telega/dialog/widget.{type SelectItem, SelectItem}
import telega/flow/registry as flow_registry
import telega/flow/types as flow_types
import telega/format as fmt
import telega/reply
import telega/update

import restaurant_booking/dependencies.{type Dependencies}
import restaurant_booking/i18n
import restaurant_booking/sql
import restaurant_booking/util

type Ctx =
  Context(Nil, String, Dependencies)

// State ------------------------------------------------------------------------

/// Dialog state: collected step by step, `error` carries the current
/// validation problem — usually an i18n key, or an already-localized message
/// for interpolated errors (either way rendered inside the window by
/// `with_error_line`), `confirmation` is filled right before `Done`.
pub type BookingState {
  BookingState(
    date: String,
    time: String,
    guests: Int,
    /// Optional delivery address collected by the `delivery_address`
    /// sub-dialog, formatted as "City, Street".
    address: Option(String),
    error: Option(String),
    confirmation: Option(String),
  )
}

fn initial_state() -> BookingState {
  BookingState(
    date: "",
    time: "",
    guests: 0,
    address: None,
    error: None,
    confirmation: None,
  )
}

fn booking_codec() -> #(
  fn(BookingState) -> String,
  fn(String) -> Result(BookingState, Nil),
) {
  dialog.json_codec(
    encoder: fn(state: BookingState) {
      json.object([
        #("date", json.string(state.date)),
        #("time", json.string(state.time)),
        #("guests", json.int(state.guests)),
        #("address", json.nullable(state.address, json.string)),
        #("error", json.nullable(state.error, json.string)),
        #("confirmation", json.nullable(state.confirmation, json.string)),
      ])
    },
    decoder: {
      use date <- decode.field("date", decode.string)
      use time <- decode.field("time", decode.string)
      use guests <- decode.field("guests", decode.int)
      use address <- decode.field("address", decode.optional(decode.string))
      use error <- decode.field("error", decode.optional(decode.string))
      use confirmation <- decode.field(
        "confirmation",
        decode.optional(decode.string),
      )
      decode.success(BookingState(
        date:,
        time:,
        guests:,
        address:,
        error:,
        confirmation:,
      ))
    },
  )
}

// Windows ----------------------------------------------------------------------

pub fn render_date(state: BookingState, ctx: Ctx) -> dtypes.RenderedWindow {
  let text =
    fmt.build()
    |> fmt.text(
      i18n.t(ctx, "book.welcome", [#("restaurant", util.get_restaurant_name())]),
    )
    |> fmt.line_break()
    |> fmt.line_break()
    |> fmt.text(i18n.t(ctx, "book.ask_date", []))
    |> with_error_line(state, ctx)
    |> fmt.to_formatted()
  dtypes.RenderedWindow(text:, buttons: [], media: None)
}

/// Time, guests and prefs are picked from widget-rendered keyboards, so
/// their windows only draw the prompt (a single i18n key) and the manual
/// `‹ Back` row — the `paged_select`/`select`/`radio`/`multiselect` button
/// grids are appended by the engine.
pub fn prompt_window(
  key: String,
) -> fn(BookingState, Ctx) -> dtypes.RenderedWindow {
  fn(state: BookingState, ctx: Ctx) {
    let text =
      fmt.build()
      |> fmt.text(i18n.t(ctx, key, []))
      |> with_error_line(state, ctx)
      |> fmt.to_formatted()
    dtypes.RenderedWindow(text:, buttons: [[back_button(ctx)]], media: None)
  }
}

/// The confirm summary reads the widget selections back through
/// `dialog.widget_store` — they live with the dialog instance, not in
/// `BookingState`; the delivery address comes from the sub-dialog via
/// `on_sub_result`.
pub fn render_confirm(state: BookingState, ctx: Ctx) -> dtypes.RenderedWindow {
  let address =
    option.unwrap(state.address, i18n.t(ctx, "book.address_none", []))
  let text =
    fmt.build()
    |> fmt.text(
      i18n.t(ctx, "book.confirm", [
        #("date", state.date),
        #("time", state.time),
        #("guests", int.to_string(state.guests)),
        #("zone", zone_label(ctx, picked_zone(ctx))),
        #("extras", extras_summary(ctx)),
        #("address", address),
        #("restaurant", util.get_restaurant_name()),
      ]),
    )
    |> with_error_line(state, ctx)
    |> fmt.to_formatted()
  dtypes.RenderedWindow(
    text:,
    buttons: [
      [dtypes.ActionButton(i18n.t(ctx, "book.confirm_button", []), "book")],
      [dtypes.ActionButton(i18n.t(ctx, "book.add_address", []), "address")],
      [dtypes.ActionButton(i18n.t(ctx, "book.view_photo", []), "photo")],
      [back_button(ctx)],
    ],
    media: None,
  )
}

/// A photo of the dining hall (a stable Telegram CDN-friendly URL; a real bot
/// would use a `file_id`). Demonstrates the text ↔ media transition: opening
/// this window recreates the live message as a photo, going `Back` recreates
/// it as text again.
const hall_photo_url = "https://telegram.org/img/t_logo.png"

pub fn render_photo(_state: BookingState, ctx: Ctx) -> dtypes.RenderedWindow {
  let text =
    fmt.build()
    |> fmt.text(
      i18n.t(ctx, "book.photo_caption", [
        #("restaurant", util.get_restaurant_name()),
      ]),
    )
    |> fmt.to_formatted()
  dtypes.RenderedWindow(
    text:,
    buttons: [[back_button(ctx)]],
    media: Some(dtypes.PhotoMedia(media: hall_photo_url, has_spoiler: False)),
  )
}

fn back_button(ctx: Ctx) -> dtypes.DialogButton {
  dtypes.ActionButton(i18n.t(ctx, "common.back", []), "back")
}

// Delivery address sub-dialog ------------------------------------------------------

/// The sub-dialog's own state type — independent from `BookingState`; the
/// engine keeps both apart by construction (the parent state is parked while
/// the sub runs).
pub type AddressState {
  AddressState(city: String, street: String)
}

fn address_codec() -> #(
  fn(AddressState) -> String,
  fn(String) -> Result(AddressState, Nil),
) {
  dialog.json_codec(
    encoder: fn(state: AddressState) {
      json.object([
        #("city", json.string(state.city)),
        #("street", json.string(state.street)),
      ])
    },
    decoder: {
      use city <- decode.field("city", decode.string)
      use street <- decode.field("street", decode.string)
      decode.success(AddressState(city:, street:))
    },
  )
}

pub fn render_address_city(
  _state: AddressState,
  ctx: Ctx,
) -> dtypes.RenderedWindow {
  let text =
    fmt.build()
    |> fmt.text(i18n.t(ctx, "address.ask_city", []))
    |> fmt.to_formatted()
  dtypes.RenderedWindow(text:, buttons: [[back_button(ctx)]], media: None)
}

pub fn render_address_street(
  state: AddressState,
  ctx: Ctx,
) -> dtypes.RenderedWindow {
  let text =
    fmt.build()
    |> fmt.text(i18n.t(ctx, "address.ask_street", [#("city", state.city)]))
    |> fmt.to_formatted()
  dtypes.RenderedWindow(text:, buttons: [[back_button(ctx)]], media: None)
}

fn address_back_or_stay(
  state: AddressState,
  event: ActionEvent,
  _ctx: Ctx,
) -> Result(DialogAction(AddressState), String) {
  case event.action_id {
    // On the first window this crosses the sub boundary: the engine cancels
    // the sub and returns to the confirm window without a result.
    "back" -> Ok(dtypes.Back(state))
    _ -> Ok(dtypes.Stay(state))
  }
}

/// A reusable address dialog: it could equally be attached to another parent
/// or registered standalone. `storage`/`labels` are taken from the parent
/// while it runs as a sub.
pub fn create_address_dialog(
  storage: flow_types.FlowStorage(String),
) -> dialog.Dialog(AddressState, Nil, String, Dependencies) {
  let #(encode_state, decode_state) = address_codec()
  let assert Ok(address) =
    dialog.new(
      id: "delivery_address",
      storage:,
      initial_state: fn() { AddressState(city: "", street: "") },
      encode_state:,
      decode_state:,
    )
    |> dialog.window_with_input(
      id: "city",
      render: render_address_city,
      on_action: address_back_or_stay,
      on_text: fn(state, text, _ctx) {
        Ok(dtypes.Goto("street", AddressState(..state, city: string.trim(text))))
      },
    )
    |> dialog.window_with_input(
      id: "street",
      render: render_address_street,
      on_action: address_back_or_stay,
      on_text: fn(state, text, _ctx) {
        Ok(dtypes.Done(AddressState(..state, street: string.trim(text))))
      },
    )
    |> dialog.initial("city")
    |> dialog.build()
  address
}

fn address_result(state: AddressState) -> dict.Dict(String, String) {
  dict.from_list([
    #("address.city", state.city),
    #("address.street", state.street),
  ])
}

/// Applied when the sub-dialog finishes: store the formatted address in the
/// booking state and re-render the confirm window.
fn confirm_sub_result(
  state: BookingState,
  result: dict.Dict(String, String),
  _ctx: Ctx,
) -> Result(DialogAction(BookingState), String) {
  let address = case
    dict.get(result, "address.city"),
    dict.get(result, "address.street")
  {
    Ok(city), Ok(street) -> Some(city <> ", " <> street)
    _, _ -> None
  }
  Ok(dtypes.Stay(BookingState(..state, address:)))
}

// Widgets ------------------------------------------------------------------------

/// Half-hour slots for the evening service: 12 items, paged by the
/// `paged_select` widget (6 per page, 3 per row).
const time_slots = [
  "17:00", "17:30", "18:00", "18:30", "19:00", "19:30", "20:00", "20:30",
  "21:00", "21:30", "22:00", "22:30",
]

fn time_slot_items(_state: BookingState, _ctx: Ctx) -> List(SelectItem) {
  list.map(time_slots, fn(slot) { SelectItem(id: slot, label: slot) })
}

const max_guests = 6

fn guest_items(_state: BookingState, _ctx: Ctx) -> List(SelectItem) {
  ["1", "2", "3", "4", "5", "6"]
  |> list.map(fn(n) { SelectItem(id: n, label: n) })
}

const default_zone = "hall"

const zone_ids = ["hall", "terrace", "window"]

fn zone_items(_state: BookingState, ctx: Ctx) -> List(SelectItem) {
  list.map(zone_ids, fn(zone) {
    SelectItem(id: zone, label: zone_label(ctx, zone))
  })
}

fn zone_label(ctx: Ctx, zone: String) -> String {
  i18n.t(ctx, "book.zone_" <> zone, [])
}

const extra_ids = ["kids_chair", "cake", "flowers"]

fn extra_items(_state: BookingState, ctx: Ctx) -> List(SelectItem) {
  list.map(extra_ids, fn(extra) {
    SelectItem(id: extra, label: extra_label(ctx, extra))
  })
}

fn extra_label(ctx: Ctx, extra: String) -> String {
  i18n.t(ctx, "book.extra_" <> extra, [])
}

/// Widget selections persisted with the dialog instance, read back in the
/// confirm window and when creating the booking.
fn picked_zone(ctx: Ctx) -> String {
  dialog.widget_store(ctx, window_id: "prefs", widget_id: "zone")
  |> widget.radio_value
  |> option.unwrap(default_zone)
}

fn picked_extras(ctx: Ctx) -> List(String) {
  dialog.widget_store(ctx, window_id: "prefs", widget_id: "extras")
  |> widget.multiselect_values
}

fn extras_summary(ctx: Ctx) -> String {
  case picked_extras(ctx) {
    [] -> i18n.t(ctx, "book.extras_none", [])
    extras -> extras |> list.map(extra_label(ctx, _)) |> string.join(", ")
  }
}

/// Localized engine labels: the multiselect "Done" button and the
/// stale-button notice come from the i18n catalog instead of the wordless
/// unicode defaults.
fn dialog_labels(ctx: Ctx) -> dtypes.Labels {
  let defaults = dtypes.default_labels()
  dtypes.Labels(
    ..defaults,
    done: i18n.t(ctx, "book.prefs_done", []),
    stale: i18n.t(ctx, "common.stale", []),
  )
}

/// Append the current validation error (if any) to the window text.
/// `state.error` is usually an i18n key; already-localized messages pass
/// through unchanged because `i18n.t` returns unknown keys as-is.
fn with_error_line(
  builder: fmt.FormatBuilder,
  state: BookingState,
  ctx: Ctx,
) -> fmt.FormatBuilder {
  case state.error {
    Some(key) ->
      builder
      |> fmt.line_break()
      |> fmt.line_break()
      |> fmt.text("⚠️ " <> i18n.t(ctx, key, []))
    None -> builder
  }
}

// Handlers ----------------------------------------------------------------------

fn buttons_only(
  state: BookingState,
  _event: ActionEvent,
  _ctx: Ctx,
) -> Result(DialogAction(BookingState), String) {
  Ok(dtypes.Stay(state))
}

fn go_back_or(
  handle: fn(BookingState, ActionEvent, Ctx) ->
    Result(DialogAction(BookingState), String),
) -> fn(BookingState, ActionEvent, Ctx) ->
  Result(DialogAction(BookingState), String) {
  fn(state: BookingState, event: ActionEvent, ctx: Ctx) {
    case event.action_id {
      "back" -> Ok(dtypes.Back(BookingState(..state, error: None)))
      _ -> handle(state, event, ctx)
    }
  }
}

fn handle_date_text(
  state: BookingState,
  text: String,
  _ctx: Ctx,
) -> Result(DialogAction(BookingState), String) {
  case validate_date(text) {
    Ok(Nil) ->
      Ok(dtypes.Goto("time", BookingState(..state, date: text, error: None)))
    Error(key) -> Ok(dtypes.Stay(BookingState(..state, error: Some(key))))
  }
}

/// `paged_select` slot picked. The widget builds the keyboard from our
/// items, but the callback arg still comes over the wire — re-validate it
/// against the offered slots instead of trusting it.
fn time_selected(
  state: BookingState,
  slot: String,
  _ctx: Ctx,
) -> Result(DialogAction(BookingState), String) {
  case validate_time(slot) {
    Ok(Nil) ->
      Ok(dtypes.Goto("guests", BookingState(..state, time: slot, error: None)))
    Error(key) -> Ok(dtypes.Stay(BookingState(..state, error: Some(key))))
  }
}

/// `select` guest count picked: the grid offers "1".."6", so anything that
/// doesn't parse into that range is a forged/stale callback — stay on the
/// window with a visible error instead of silently booking a default.
fn guests_selected(
  state: BookingState,
  raw: String,
  _ctx: Ctx,
) -> Result(DialogAction(BookingState), String) {
  case int.parse(raw) {
    Ok(guests) if guests >= 1 && guests <= max_guests ->
      Ok(dtypes.Goto("prefs", BookingState(..state, guests:, error: None)))
    _ ->
      Ok(dtypes.Stay(BookingState(..state, error: Some("error.invalid_guests"))))
  }
}

fn handle_confirm_action(
  state: BookingState,
  event: ActionEvent,
  ctx: Ctx,
) -> Result(DialogAction(BookingState), String) {
  case event.action_id {
    "photo" -> Ok(dtypes.Goto("photo", state))
    "address" -> Ok(dtypes.StartSub("delivery_address", dict.new(), state))
    "book" ->
      // Last line of defence before the DB insert: the time must still be
      // one of the offered slots (state could carry a forged callback arg).
      case validate_time(state.time) {
        Error(key) -> Ok(dtypes.Stay(BookingState(..state, error: Some(key))))
        Ok(Nil) ->
          case
            create_booking(
              ctx,
              state.date,
              state.time,
              state.guests,
              special_requests(ctx, state),
            )
          {
            Ok(booking) -> {
              let confirmation =
                Some(option.unwrap(booking.confirmation_code, "PENDING"))
              Ok(dtypes.Done(BookingState(..state, confirmation:, error: None)))
            }
            Error("book.no_tables") -> {
              let _ = dialog.toast(ctx, i18n.t(ctx, "book.no_tables", []))
              Ok(dtypes.Stay(
                BookingState(..state, error: Some("book.no_tables")),
              ))
            }
            // Unexpected failures (SQLite error, missing user row) must be
            // visible: returning `Error` would only log and re-render the
            // unchanged window. Localize `book.error` now (with_error_line
            // passes non-key strings through unchanged) and stay.
            Error(other) -> {
              let message = i18n.t(ctx, "book.error", [#("error", other)])
              Ok(dtypes.Stay(BookingState(..state, error: Some(message))))
            }
          }
      }
    _ -> Ok(dtypes.Stay(state))
  }
}

/// A locale-independent note for the database: raw widget ids, not labels.
fn special_requests(ctx: Ctx, state: BookingState) -> String {
  let notes = [
    Some("zone: " <> picked_zone(ctx)),
    case picked_extras(ctx) {
      [] -> None
      extras -> Some("extras: " <> string.join(extras, ", "))
    },
    option.map(state.address, fn(address) { "address: " <> address }),
  ]
  notes |> option.values |> string.join("; ")
}

fn booking_done(state: BookingState, ctx: Ctx) -> Result(Ctx, String) {
  reply.with_text(
    ctx,
    i18n.t(ctx, "book.success", [
      #("code", option.unwrap(state.confirmation, "PENDING")),
      #("date", state.date),
      #("time", state.time),
      #("guests", int.to_string(state.guests)),
      #("restaurant", util.get_restaurant_name()),
    ]),
  )
  |> result.map_error(string.inspect)
  |> result.replace(ctx)
}

// Wiring ------------------------------------------------------------------------

/// Build the booking dialog. `db` backs the persistence storage (resolved at
/// init); handlers read their query connection from `ctx.dependencies.db`.
pub fn create_booking_dialog(
  db: sqlight.Connection,
) -> dialog.Dialog(BookingState, Nil, String, Dependencies) {
  let storage = util.create_database_storage(db)
  let #(encode_state, decode_state) = booking_codec()

  let assert Ok(booking_dialog) =
    dialog.new(
      id: "booking",
      storage:,
      initial_state:,
      encode_state:,
      decode_state:,
    )
    |> dialog.window_with_input(
      id: "date",
      render: render_date,
      on_action: buttons_only,
      on_text: handle_date_text,
    )
    |> dialog.window_with_widgets(
      id: "time",
      render: prompt_window("book.ask_time"),
      on_action: go_back_or(buttons_only),
      widgets: [
        widget.paged_select(
          id: "slot",
          items: time_slot_items,
          page_size: 6,
          columns: 3,
          on_selected: time_selected,
        ),
      ],
    )
    |> dialog.window_with_widgets(
      id: "guests",
      render: prompt_window("book.ask_guests"),
      on_action: go_back_or(buttons_only),
      widgets: [
        widget.select(
          id: "n",
          items: guest_items,
          columns: 3,
          on_selected: guests_selected,
        ),
      ],
    )
    |> dialog.window_with_widgets(
      id: "prefs",
      render: prompt_window("book.ask_prefs"),
      on_action: go_back_or(buttons_only),
      widgets: [
        widget.radio(id: "zone", items: zone_items, default: Some(default_zone)),
        widget.multiselect(
          id: "extras",
          items: extra_items,
          min: 0,
          max: 3,
          done: "confirm",
        ),
      ],
    )
    |> dialog.window(
      id: "confirm",
      render: render_confirm,
      on_action: go_back_or(handle_confirm_action),
    )
    |> dialog.window(
      id: "photo",
      render: render_photo,
      on_action: go_back_or(buttons_only),
    )
    |> dialog.subdialog(
      sub: create_address_dialog(storage),
      init: fn(_booking_state, _args) { AddressState(city: "", street: "") },
      result: address_result,
    )
    |> dialog.on_sub_result(window: "confirm", handler: confirm_sub_result)
    |> dialog.initial("date")
    |> dialog.on_done(booking_done)
    |> dialog.with_labels(dialog_labels)
    |> dialog.with_ttl(ms: 3_600_000)
    |> dialog.build()

  booking_dialog
}

/// `/book` command handler: only registered users may book — then start (or
/// resume) the dialog programmatically via `dialog.start`.
pub fn start_booking(
  registry: flow_registry.FlowRegistry(Nil, String, Dependencies),
) -> fn(Ctx, update.Command) -> Result(Ctx, String) {
  fn(ctx: Ctx, _command) {
    case
      sql.get_user(ctx.dependencies.db, ctx.update.from_id, ctx.update.chat_id)
    {
      Ok([_user, ..]) -> dialog.start(ctx, registry, "booking")
      Ok([]) -> {
        let _ =
          reply.with_text(ctx, i18n.t(ctx, "common.registration_required", []))
        Ok(ctx)
      }
      Error(err) ->
        Error("Failed to check user registration: " <> string.inspect(err))
    }
  }
}

// Booking creation (database) ------------------------------------------------------

/// Booking type for the dialog (matching database structure)
type Booking {
  Booking(
    id: Int,
    user_id: Option(Int),
    table_id: Option(Int),
    booking_date: String,
    booking_time: String,
    guests: Int,
    special_requests: Option(String),
    status: Option(String),
    confirmation_code: Option(String),
  )
}

/// Create real booking in database
fn create_booking(
  ctx: Ctx,
  date: String,
  time: String,
  guests: Int,
  special_requests: String,
) -> Result(Booking, String) {
  let db = ctx.dependencies.db

  let telegram_id = ctx.update.from_id
  let chat_id = ctx.update.chat_id

  use user_result <- result.try(
    sql.get_user(db, telegram_id, chat_id)
    |> result.map_error(fn(err) {
      "Failed to get user: " <> string.inspect(err)
    }),
  )

  let user_id = case user_result {
    [user, ..] -> Ok(user.id)
    [] -> Error("User not found in database")
  }

  use user_id <- result.try(user_id)
  let confirmation_code = util.generate_confirmation_code()

  use available_tables <- result.try(
    sql.get_available_tables(db, guests, date, time)
    |> result.map_error(fn(err) {
      "Failed to check availability: " <> string.inspect(err)
    }),
  )

  case available_tables {
    [] -> Error("book.no_tables")

    [first_table, ..] -> {
      let table_id = first_table.id

      use booking_result <- result.try(
        sql.create_booking(
          db,
          user_id,
          table_id,
          date,
          time,
          guests,
          special_requests,
          confirmation_code,
        )
        |> result.map_error(fn(err) {
          "Database error: " <> string.inspect(err)
        }),
      )

      case booking_result {
        [row, ..] ->
          Ok(Booking(
            id: row.id,
            user_id: row.user_id,
            table_id: row.table_id,
            booking_date: row.booking_date,
            booking_time: row.booking_time,
            guests: row.guests,
            special_requests: row.special_requests,
            status: row.status,
            confirmation_code: row.confirmation_code,
          ))
        [] -> Error("Failed to create booking")
      }
    }
  }
}

// Validation ---------------------------------------------------------------------

/// Validate a date string is `YYYY-MM-DD` (stored as text in SQLite).
pub fn validate_date(date_str: String) -> Result(Nil, String) {
  case string.split(date_str, "-") {
    [year, month, day] ->
      case int.parse(year), int.parse(month), int.parse(day) {
        Ok(_), Ok(_), Ok(_) -> Ok(Nil)
        _, _, _ -> Error("error.invalid_date")
      }
    _ -> Error("error.invalid_date")
  }
}

/// Validate a time string is one of the offered half-hour slots.
pub fn validate_time(time_str: String) -> Result(Nil, String) {
  case list.contains(time_slots, time_str) {
    True -> Ok(Nil)
    False -> Error("error.invalid_time")
  }
}
