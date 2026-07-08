//// Tests for the booking dialog.
////
//// Window renders are pure (`render(state, ctx)` — the only effect is
//// reading the i18n locale set with `telega_i18n.enter`), so frames are
//// checked without a network. Dialog construction is a smoke test over the
//// real SQLite-backed storage.
////
//// The per-locale snapshots at the bottom pin the same frame in `en` and
//// `ru` — the recipe for snapshotting a localized bot with the pure
//// canonicalizers from `telega/testing/render` (see docs/dialogs.md
//// § Testing).

import birdie
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should
import sqlight

import telega/bot as telega_bot
import telega/dialog/types
import telega/dialog/widget
import telega/testing/context
import telega/testing/render
import telega_i18n

import restaurant_booking/dependencies.{type Dependencies, Dependencies}
import restaurant_booking/flows/booking
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
  telega_i18n.enter(catalog:, locale:)
  test_fn(context.context_with_dependencies(
    session: Nil,
    dependencies: Dependencies(db:, catalog:),
  ))
  telega_i18n.leave()
}

fn empty_state() -> booking.BookingState {
  booking.BookingState(
    date: "",
    time: "",
    guests: 0,
    address: None,
    error: None,
    confirmation: None,
  )
}

/// The dialog builds successfully over the real storage backend.
pub fn create_booking_dialog_test() {
  use db <- run_with_db
  let _ = booking.create_booking_dialog(db)
  Nil
}

pub fn date_window_frame_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  let frame = render.window_frame(booking.render_date(empty_state(), ctx))
  frame |> string.contains("Enter date (YYYY-MM-DD)") |> should.be_true()
  // First window: text input only, no buttons.
  frame |> string.contains("](") |> should.be_false()
}

pub fn date_window_shows_validation_error_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  let state =
    booking.BookingState(..empty_state(), error: Some("error.invalid_date"))
  render.window_frame(booking.render_date(state, ctx))
  |> string.contains("⚠️ Date format must be YYYY-MM-DD")
  |> should.be_true()
}

/// The guests window itself only draws the prompt and `‹ Back` — the 1-6
/// grid is a `select` widget appended by the engine at render time. The
/// prompt-only windows share one `prompt_window(key)` render.
pub fn guests_window_frame_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  let render_guests = booking.prompt_window("book.ask_guests")
  let frame = render.window_frame(render_guests(empty_state(), ctx))
  frame |> string.contains("How many guests?") |> should.be_true()
  frame |> string.contains("[ ‹ Back ](back)") |> should.be_true()
}

pub fn confirm_window_localized_frame_test() {
  use db <- run_with_db
  use ctx <- with_locale("ru", db)

  let state =
    booking.BookingState(
      date: "2024-12-25",
      time: "19:30",
      guests: 4,
      address: None,
      error: None,
      confirmation: None,
    )
  // Widget stores are read from a per-process stash: reset them so this
  // frame shows the defaults regardless of test order.
  widget.seed_store(
    window_id: "prefs",
    widget_id: "zone",
    store: types.new_store(),
  )
  widget.seed_store(
    window_id: "prefs",
    widget_id: "extras",
    store: types.new_store(),
  )

  let frame = render.window_frame(booking.render_confirm(state, ctx))
  frame |> string.contains("Подтвердите бронь") |> should.be_true()
  frame |> string.contains("📅 Дата: 2024-12-25") |> should.be_true()
  // Empty stores: the summary falls back to the default zone.
  frame |> string.contains("📍 Зона: 🏠 Основной зал") |> should.be_true()
  frame |> string.contains("[ ✅ Подтвердить бронь ](book)") |> should.be_true()
}

/// The confirm summary reads the prefs widgets through `dialog.widget_store`;
/// seeded stores show up in the rendered frame.
pub fn confirm_window_reads_widget_selections_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  widget.seed_store(
    window_id: "prefs",
    widget_id: "zone",
    store: types.new_store() |> types.store_set("value", "terrace"),
  )
  widget.seed_store(
    window_id: "prefs",
    widget_id: "extras",
    store: types.new_store()
      |> types.store_set("values", "[\"cake\",\"flowers\"]"),
  )

  let frame = render.window_frame(booking.render_confirm(empty_state(), ctx))
  frame |> string.contains("📍 Seating: 🌿 Terrace") |> should.be_true()
  frame
  |> string.contains("✨ Extras: 🎂 Birthday cake, 💐 Flowers on the table")
  |> should.be_true()
}

pub fn confirm_window_offers_photo_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  render.window_frame(booking.render_confirm(empty_state(), ctx))
  |> string.contains("](photo)")
  |> should.be_true()
}

/// The photo window is a media window: the frame carries a `media:` line and
/// the caption, and `‹ Back` returns to the text confirm window (the engine
/// recreates the live message on the text ↔ media transition).
pub fn photo_window_frame_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  let frame = render.window_frame(booking.render_photo(empty_state(), ctx))
  frame |> string.contains("media: photo https://") |> should.be_true()
  frame |> string.contains("Our dining hall") |> should.be_true()
  frame |> string.contains("[ ‹ Back ](back)") |> should.be_true()
}

/// The confirm window offers the delivery-address sub-dialog and shows the
/// collected address once `on_sub_result` stored it in the state.
pub fn confirm_window_shows_address_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  let frame = render.window_frame(booking.render_confirm(empty_state(), ctx))
  frame |> string.contains("](address)") |> should.be_true()
  frame |> string.contains("🏠 Cake delivery: —") |> should.be_true()

  let with_address =
    booking.BookingState(..empty_state(), address: Some("Springfield, 742"))
  render.window_frame(booking.render_confirm(with_address, ctx))
  |> string.contains("🏠 Cake delivery: Springfield, 742")
  |> should.be_true()
}

pub fn address_sub_dialog_frames_test() {
  use db <- run_with_db
  use ctx <- with_locale("ru", db)

  let state = booking.AddressState(city: "Же", street: "")
  render.window_frame(booking.render_address_city(state, ctx))
  |> string.contains("В какой город")
  |> should.be_true()

  render.window_frame(booking.render_address_street(state, ctx))
  |> string.contains("Же — записали")
  |> should.be_true()
}

pub fn validate_date_test() {
  booking.validate_date("2024-12-25") |> should.equal(Ok(Nil))
  booking.validate_date("25.12.2024")
  |> should.equal(Error("error.invalid_date"))
  booking.validate_date("not-a-date")
  |> should.equal(Error("error.invalid_date"))
}

/// Only the offered half-hour slots pass — a forged callback arg does not.
pub fn validate_time_test() {
  booking.validate_time("19:30") |> should.equal(Ok(Nil))
  booking.validate_time("03:15") |> should.equal(Error("error.invalid_time"))
  booking.validate_time("drop table")
  |> should.equal(Error("error.invalid_time"))
}

// ============================================================================
// Per-locale snapshots: the same frame rendered in en and ru
// ============================================================================

fn filled_state() -> booking.BookingState {
  booking.BookingState(
    date: "2024-12-25",
    time: "19:30",
    guests: 4,
    address: Some("Springfield, Evergreen Terrace 742"),
    error: None,
    confirmation: None,
  )
}

fn seed_prefs_stores() -> Nil {
  widget.seed_store(
    window_id: "prefs",
    widget_id: "zone",
    store: types.new_store() |> types.store_set("value", "terrace"),
  )
  widget.seed_store(
    window_id: "prefs",
    widget_id: "extras",
    store: types.new_store()
      |> types.store_set("values", "[\"cake\",\"flowers\"]"),
  )
}

pub fn confirm_frame_en_snapshot_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)
  seed_prefs_stores()

  render.window_frame(booking.render_confirm(filled_state(), ctx))
  |> birdie.snap(title: "booking:confirm:frame_en")
}

pub fn confirm_frame_ru_snapshot_test() {
  use db <- run_with_db
  use ctx <- with_locale("ru", db)
  seed_prefs_stores()

  render.window_frame(booking.render_confirm(filled_state(), ctx))
  |> birdie.snap(title: "booking:confirm:frame_ru")
}

pub fn address_street_frame_en_snapshot_test() {
  use db <- run_with_db
  use ctx <- with_locale("en", db)

  let state = booking.AddressState(city: "Springfield", street: "")
  render.window_frame(booking.render_address_street(state, ctx))
  |> birdie.snap(title: "booking:address:street_frame_en")
}

pub fn address_street_frame_ru_snapshot_test() {
  use db <- run_with_db
  use ctx <- with_locale("ru", db)

  let state = booking.AddressState(city: "Спрингфилд", street: "")
  render.window_frame(booking.render_address_street(state, ctx))
  |> birdie.snap(title: "booking:address:street_frame_ru")
}
