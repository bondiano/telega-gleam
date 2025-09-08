import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/string
import pog
import restaurant_booking/sql
import telega/bot.{type Context}
import telega/format as fmt
import telega/reply
import telega/update

pub fn help(
  ctx: Context(Nil, String),
  _cmd: update.Command,
) -> Result(Context(Nil, String), String) {
  case
    reply.with_text(
      ctx,
      "🍽️ Restaurant Booking Bot\n\n"
        <> "Available commands:\n"
        <> "/start - Register or update your profile\n"
        <> "/book - Make a new reservation\n"
        <> "/my_bookings - View your reservations\n"
        <> "/help - Show this message",
    )
  {
    Ok(_) -> Ok(ctx)
    Error(_) -> Error("Failed to send help message")
  }
}

pub fn my_bookings(
  db: pog.Connection,
  ctx: Context(Nil, String),
  _cmd: update.Command,
) -> Result(Context(Nil, String), String) {
  let chat_id = ctx.update.chat_id
  let telegram_id = ctx.update.from_id

  case sql.get_user(db, telegram_id, chat_id) {
    Ok(pog.Returned(count: _, rows: [user])) ->
      show_user_bookings(db, ctx, user.id)

    Ok(pog.Returned(count: _, rows: [])) ->
      send_registration_required_message(ctx)

    Ok(pog.Returned(count: _, rows: _)) ->
      Error("Multiple users found for same telegram_id")

    Error(_) -> Error("Failed to fetch user from database")
  }
}

fn show_user_bookings(
  db: pog.Connection,
  ctx: Context(Nil, String),
  user_id: Int,
) -> Result(Context(Nil, String), String) {
  case sql.get_user_bookings(db, user_id) {
    Ok(pog.Returned(count: _, rows: [])) -> {
      case
        reply.with_text(
          ctx,
          "📋 Your Bookings\n\n"
            <> "You don't have any bookings yet.\n"
            <> "Use /book to make a reservation!",
        )
      {
        Ok(_) -> Ok(ctx)
        Error(error) ->
          Error("Failed to send bookings message: " <> string.inspect(error))
      }
    }
    Ok(pog.Returned(count: _, rows: bookings)) -> {
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
  ctx: Context(Nil, String),
) -> Result(Context(Nil, String), String) {
  case
    reply.with_text(
      ctx,
      "❌ You need to register first!\n\nUse /start to create your profile.",
    )
  {
    Ok(_) -> Ok(ctx)
    Error(error) ->
      Error("Failed to send registration message: " <> string.inspect(error))
  }
}

fn format_bookings_list(
  bookings: List(sql.GetUserBookingsRow),
) -> fmt.FormattedText {
  let builder =
    fmt.build()
    |> fmt.with_mode(fmt.HTML)
    |> fmt.text("📋 ")
    |> fmt.bold_text("Your Bookings")
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
  booking: sql.GetUserBookingsRow,
) -> fmt.FormatBuilder {
  let status_emoji = get_status_emoji(booking.status)
  let status_text = format_status(booking.status)

  let single_booking_builder =
    builder
    |> fmt.text(status_emoji <> " ")
    |> fmt.bold_text("Reservation" <> status_text)
    |> fmt.line_break()
    |> fmt.text("📅 " <> booking.booking_date <> " at " <> booking.booking_time)
    |> fmt.line_break()
    |> fmt.text("👥 " <> int.to_string(booking.guests) <> " guests")
    |> fmt.line_break()
    |> fmt.text(
      "🪑 Table "
      <> int.to_string(booking.table_number)
      <> " (capacity: "
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
      |> fmt.text("💬 Special requests: " <> req)
    _ -> single_booking_builder
  }

  case booking.confirmation_code {
    Some(code) ->
      single_booking_builder
      |> fmt.line_break()
      |> fmt.text("🎫 Confirmation: " <> code)
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
    Some("confirmed") -> " (Confirmed)"
    Some("pending") -> " (Pending)"
    Some("cancelled") -> " (Cancelled)"
    _ -> ""
  }
}
