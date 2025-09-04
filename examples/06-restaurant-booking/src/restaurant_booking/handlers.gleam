import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import pog
import restaurant_booking/sql
import telega/bot.{type Context}
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
        <> "/mybookings - View your reservations\n"
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
    Ok(pog.Returned(count: _, rows: [user])) -> {
      show_user_bookings(db, ctx, user.id)
    }
    Ok(pog.Returned(count: _, rows: [])) -> {
      send_registration_required_message(ctx)
    }
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
        Error(_) -> Error("Failed to send bookings message")
      }
    }
    Ok(pog.Returned(count: _, rows: bookings)) -> {
      let bookings_text = format_bookings_list(bookings)
      case reply.with_text(ctx, bookings_text) {
        Ok(_) -> Ok(ctx)
        Error(_) -> Error("Failed to send bookings list")
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
    Error(_) -> Error("Failed to send registration message")
  }
}

fn format_bookings_list(bookings: List(sql.GetUserBookingsRow)) -> String {
  let header = "📋 Your Bookings\n\n"

  let bookings_text =
    bookings
    |> list.map(format_single_booking)
    |> string.join("\n━━━━━━━━━━━━━━━━━━━━━\n")

  header <> bookings_text
}

fn format_single_booking(booking: sql.GetUserBookingsRow) -> String {
  let status_emoji = get_status_emoji(booking.status)
  let location_text = format_location(booking.location)
  let special_requests_text = format_special_requests(booking.special_requests)
  let confirmation_text = format_confirmation_code(booking.confirmation_code)

  status_emoji
  <> " **Reservation**\n"
  <> "📅 "
  <> booking.booking_date
  <> " at "
  <> booking.booking_time
  <> "\n"
  <> "👥 "
  <> int.to_string(booking.guests)
  <> " guests\n"
  <> "🪑 Table "
  <> int.to_string(booking.table_number)
  <> " (capacity: "
  <> int.to_string(booking.capacity)
  <> ")"
  <> location_text
  <> special_requests_text
  <> confirmation_text
}

fn get_status_emoji(status: option.Option(String)) -> String {
  case status {
    Some("confirmed") -> "✅"
    Some("pending") -> "⏳"
    Some("cancelled") -> "❌"
    _ -> "❓"
  }
}

fn format_location(location: option.Option(String)) -> String {
  case location {
    Some(loc) -> " (" <> loc <> ")"
    None -> ""
  }
}

fn format_special_requests(
  requests: option.Option(String),
) -> String {
  case requests {
    Some(req) -> "\n💬 Special requests: " <> req
    None -> ""
  }
}

fn format_confirmation_code(code: option.Option(String)) -> String {
  case code {
    Some(c) -> "\n🎫 Confirmation: " <> c
    None -> ""
  }
}