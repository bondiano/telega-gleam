import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/string
import restaurant_booking/dependencies.{type Dependencies}
import restaurant_booking/i18n
import restaurant_booking/sql
import sqlight
import telega/bot.{type Context}
import telega/format as fmt
import telega/reply
import telega/telemetry
import telega/update

pub fn help(
  ctx: Context(Nil, String, Dependencies),
  _cmd: update.Command,
) -> Result(Context(Nil, String, Dependencies), String) {
  case reply.with_text(ctx, i18n.t(ctx, "help.text", [])) {
    Ok(_) -> Ok(ctx)
    Error(_) -> Error("Failed to send help message")
  }
}

pub fn my_bookings(
  ctx: Context(Nil, String, Dependencies),
  _cmd: update.Command,
) -> Result(Context(Nil, String, Dependencies), String) {
  let db = ctx.dependencies.db
  let chat_id = ctx.update.chat_id
  let telegram_id = ctx.update.from_id

  case db_span("get_user", fn() { sql.get_user(db, telegram_id, chat_id) }) {
    Ok([user, ..]) -> show_user_bookings(db, ctx, user.id)

    Ok([]) -> send_registration_required_message(ctx)

    Error(_) -> Error("Failed to fetch user from database")
  }
}

/// Wrap a database query in a custom telemetry span: emits
/// `restaurant_booking.db.start` / `.stop` / `.exception` with the query name
/// and a monotonic `duration`. The observability module logs these events.
fn db_span(query: String, run: fn() -> Result(a, e)) -> Result(a, e) {
  telemetry.span(
    event: ["restaurant_booking", "db"],
    metadata: [#("query", telemetry.StringValue(query))],
    run:,
  )
}

fn show_user_bookings(
  db: sqlight.Connection,
  ctx: Context(Nil, String, Dependencies),
  user_id: Int,
) -> Result(Context(Nil, String, Dependencies), String) {
  case
    db_span("get_user_bookings", fn() { sql.get_user_bookings(db, user_id) })
  {
    Ok([]) -> {
      case reply.with_text(ctx, i18n.t(ctx, "bookings.none", [])) {
        Ok(_) -> Ok(ctx)
        Error(error) ->
          Error("Failed to send bookings message: " <> string.inspect(error))
      }
    }
    Ok(bookings) -> {
      let bookings_text = format_bookings_list(bookings)
      case reply.with_formatted(ctx, bookings_text) {
        Ok(_) -> Ok(ctx)
        Error(error) ->
          Error("Failed to send bookings list: " <> string.inspect(error))
      }
    }
    Error(_) -> Error("Failed to fetch bookings from database")
  }
}

fn send_registration_required_message(
  ctx: Context(Nil, String, Dependencies),
) -> Result(Context(Nil, String, Dependencies), String) {
  case reply.with_text(ctx, i18n.t(ctx, "common.registration_required", [])) {
    Ok(_) -> Ok(ctx)
    Error(error) ->
      Error("Failed to send registration message: " <> string.inspect(error))
  }
}

fn format_bookings_list(
  bookings: List(sql.UserBookingRow),
) -> fmt.FormattedText {
  let builder =
    fmt.build()
    |> fmt.with_mode(fmt.HTML)
    |> fmt.text("📋 ")
    |> fmt.bold_text(i18n.tr("bookings.header", []))
    |> fmt.line_break()
    |> fmt.line_break()

  bookings
  |> list.fold(builder, fn(b, booking) {
    b
    |> format_single_booking(booking)
    |> fmt.text("\n━━━━━━━━━━━━━━━━━━━━━\n")
  })
  |> fmt.to_formatted()
}

fn format_single_booking(
  builder: fmt.FormatBuilder,
  booking: sql.UserBookingRow,
) -> fmt.FormatBuilder {
  let status_emoji = get_status_emoji(booking.status)
  let status_text = format_status(booking.status)

  let single_booking_builder =
    builder
    |> fmt.text(status_emoji <> " ")
    |> fmt.bold_text(i18n.tr("bookings.reservation", []) <> status_text)
    |> fmt.line_break()
    |> fmt.text(
      "📅 "
      <> booking.booking_date
      <> " "
      <> i18n.tr("bookings.at", [])
      <> " "
      <> booking.booking_time,
    )
    |> fmt.line_break()
    |> fmt.text(
      "👥 "
      <> int.to_string(booking.guests)
      <> " "
      <> i18n.tr("bookings.guests", []),
    )
    |> fmt.line_break()
    |> fmt.text(
      "🪑 "
      <> i18n.tr("bookings.table", [])
      <> " "
      <> int.to_string(booking.table_number)
      <> " ("
      <> i18n.tr("bookings.capacity", [])
      <> ": "
      <> int.to_string(booking.capacity)
      <> ")",
    )

  let single_booking_builder = case booking.location {
    Some(loc) -> single_booking_builder |> fmt.text(" (" <> loc <> ")")
    _ -> single_booking_builder
  }

  let single_booking_builder = case booking.special_requests {
    Some(req) if req != "" ->
      single_booking_builder
      |> fmt.line_break()
      |> fmt.text(
        "💬 " <> i18n.tr("bookings.special_requests", []) <> ": " <> req,
      )
    _ -> single_booking_builder
  }

  case booking.confirmation_code {
    Some(code) ->
      single_booking_builder
      |> fmt.line_break()
      |> fmt.text("🎫 " <> i18n.tr("bookings.confirmation", []) <> ": " <> code)
    _ -> single_booking_builder
  }
}

fn get_status_emoji(status: option.Option(String)) -> String {
  case status {
    Some("confirmed") -> "✅"
    Some("pending") -> "⏳"
    Some("cancelled") -> "❌"
    _ -> "❓"
  }
}

fn format_status(status: option.Option(String)) -> String {
  case status {
    Some("confirmed") -> i18n.tr("bookings.confirmed", [])
    Some("pending") -> i18n.tr("bookings.pending", [])
    Some("cancelled") -> i18n.tr("bookings.cancelled", [])
    _ -> ""
  }
}
