import gleam/dict
import gleam/int
import gleam/option.{Some}
import gleam/result
import gleam/string
import gleam/time/calendar
import pog

import telega/bot.{type Context}
import telega/flow
import telega/reply

import restaurant_booking/sql
import restaurant_booking/util

/// Create simplified booking flow using built-in helpers
pub fn create_booking_flow(
  db: pog.Connection,
) -> flow.PersistentFlow(Nil, String) {
  let storage = util.create_database_storage(db)

  flow.new("booking", "check_user", storage)
  |> flow.add_step("check_user", fn(ctx, instance) {
    check_user_registration(db, ctx, instance)
  })
  |> flow.add_step(
    "welcome",
    flow.message_step(
      fn(_) {
        "🍽️ Let's make your reservation at "
        <> util.get_restaurant_name()
        <> "!\n\nI'll help you book the perfect table."
      },
      Some("date"),
    ),
  )
  |> flow.add_step(
    "date",
    flow.text_step(
      "📅 Enter date (YYYY-MM-DD):\nExample: 2024-12-25",
      "booking_date",
      "time",
    ),
  )
  |> flow.add_step(
    "time",
    flow.text_step(
      "🕐 Enter time (HH:MM):\nExample: 19:30\n\nHours: Mon-Thu 17:00-23:00, Fri-Sat 17:00-24:00, Sun 17:00-22:00",
      "booking_time",
      "guests",
    ),
  )
  |> flow.add_step(
    "guests",
    flow.text_step("👥 How many guests? (1-12)", "guest_count", "confirm"),
  )
  |> flow.add_step("confirm", fn(ctx, instance) {
    confirm_and_book_step(db, ctx, instance)
  })
  |> flow.on_error(fn(ctx, _, error) {
    util.log_error("Booking flow error: " <> error)
    use _ <- result.try(
      reply.with_text(
        ctx,
        "❌ Booking error: " <> error <> "\nUse /book to try again.",
      )
      |> result.map_error(fn(err) {
        "Error message failed: " <> string.inspect(err)
      }),
    )

    Ok(ctx)
  })
}

/// Check if user is registered before allowing booking
fn check_user_registration(
  db: pog.Connection,
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
) -> flow.StepResult(Nil, String) {
  case sql.get_user(db, instance.user_id, instance.chat_id) {
    Ok(pog.Returned(count: _, rows: [_user])) ->
      flow.next(ctx, instance, "welcome")

    Ok(pog.Returned(count: _, rows: [])) -> {
      let _ =
        reply.with_text(
          ctx,
          "❌ You need to register first!\n\nUse /start to create your profile.",
        )

      flow.cancel(ctx, instance)
    }

    Ok(pog.Returned(count: _, rows: _)) ->
      Error("Multiple users found for same telegram_id")

    Error(err) ->
      Error("Failed to check user registration: " <> string.inspect(err))
  }
}

/// Simplified step: Confirm and create booking
fn confirm_and_book_step(
  db: pog.Connection,
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
) -> flow.StepResult(Nil, String) {
  case extract_booking_data(instance) {
    Ok(booking_data) -> {
      let confirmation = "
🎉 Confirm your reservation:

📅 Date: " <> booking_data.booking_date <> "
🕐 Time: " <> booking_data.booking_time <> "
👥 Guests: " <> int.to_string(booking_data.guest_count) <> "
🍽️ Restaurant: " <> util.get_restaurant_name() <> "

We'll book an available table for you!
      "

      case reply.with_text(ctx, confirmation) {
        Ok(_) -> {
          case
            create_booking(
              db,
              ctx,
              booking_data.booking_date,
              booking_data.booking_time,
              booking_data.guest_count,
            )
          {
            Ok(booking) -> {
              let success_message = "
✅ Booking confirmed!

Confirmation: " <> option.unwrap(booking.confirmation_code, "PENDING") <> "
📅 " <> booking.booking_date <> " at " <> booking.booking_time <> "
👥 " <> int.to_string(booking.guests) <> " guests

Thank you for choosing " <> util.get_restaurant_name() <> "!
              "

              case reply.with_text(ctx, success_message) {
                Ok(_) -> flow.complete(ctx, instance)
                Error(_) -> flow.cancel(ctx, instance)
              }
            }
            Error(err) -> {
              let _ = reply.with_text(ctx, "❌ Booking failed: " <> err)
              flow.cancel(ctx, instance)
            }
          }
        }
        Error(_) -> flow.cancel(ctx, instance)
      }
    }
    Error(error_msg) -> {
      let _ = reply.with_text(ctx, "❌ Error: " <> error_msg)
      flow.cancel(ctx, instance)
    }
  }
}

/// Booking type for the flow (matching database structure)
type Booking {
  Booking(
    id: Int,
    user_id: option.Option(Int),
    table_id: option.Option(Int),
    booking_date: String,
    booking_time: String,
    guests: Int,
    special_requests: option.Option(String),
    status: option.Option(String),
    confirmation_code: option.Option(String),
  )
}

/// Booking data extracted from flow state
pub type BookingData {
  BookingData(booking_date: String, booking_time: String, guest_count: Int)
}

/// Extract and validate booking data from flow instance state
fn extract_booking_data(
  instance: flow.FlowInstance,
) -> Result(BookingData, String) {
  use booking_date <- result.try(
    dict.get(instance.state.data, "booking_date")
    |> result.map_error(fn(_) { "Missing booking date" }),
  )

  use booking_time <- result.try(
    dict.get(instance.state.data, "booking_time")
    |> result.map_error(fn(_) { "Missing booking time" }),
  )

  use guest_count_str <- result.try(
    dict.get(instance.state.data, "guest_count")
    |> result.map_error(fn(_) { "Missing guest count" }),
  )

  use guest_count <- result.try(
    int.parse(guest_count_str)
    |> result.map_error(fn(_) { "Invalid guest count: " <> guest_count_str }),
  )

  Ok(BookingData(
    booking_date: booking_date,
    booking_time: booking_time,
    guest_count: guest_count,
  ))
}

/// Parse and validate date string (YYYY-MM-DD)
fn parse_date(date_str: String) -> Result(calendar.Date, String) {
  case string.split(date_str, "-") {
    [year_str, month_str, day_str] -> {
      use year <- result.try(
        int.parse(year_str)
        |> result.map_error(fn(_) { "Invalid year: " <> year_str }),
      )
      use month_int <- result.try(
        int.parse(month_str)
        |> result.map_error(fn(_) { "Invalid month: " <> month_str }),
      )
      use day <- result.try(
        int.parse(day_str)
        |> result.map_error(fn(_) { "Invalid day: " <> day_str }),
      )
      use month <- result.try(
        calendar.month_from_int(month_int)
        |> result.map_error(fn(_) { "Invalid month value: " <> month_str }),
      )

      Ok(calendar.Date(year, month, day))
    }
    _ -> Error("Date format must be YYYY-MM-DD")
  }
}

/// Parse and validate time string (HH:MM)
fn parse_time(time_str: String) -> Result(calendar.TimeOfDay, String) {
  case string.split(time_str, ":") {
    [hour_str, minute_str] -> {
      use hour <- result.try(
        int.parse(hour_str)
        |> result.map_error(fn(_) { "Invalid hour: " <> hour_str }),
      )
      use minute <- result.try(
        int.parse(minute_str)
        |> result.map_error(fn(_) { "Invalid minute: " <> minute_str }),
      )

      Ok(calendar.TimeOfDay(hour, minute, 0, 0))
    }
    _ -> Error("Time format must be HH:MM")
  }
}

/// Create real booking in database
fn create_booking(
  db: pog.Connection,
  ctx: Context(Nil, String),
  date: String,
  time: String,
  guests: Int,
) -> Result(Booking, String) {
  use date_val <- result.try(parse_date(date))
  use time_val <- result.try(parse_time(time))

  // Get the user's internal database ID
  let telegram_id = ctx.update.from_id
  let chat_id = ctx.update.chat_id

  use user_result <- result.try(
    sql.get_user(db, telegram_id, chat_id)
    |> result.map_error(fn(err) {
      "Failed to get user: " <> string.inspect(err)
    }),
  )

  let user_id = case user_result {
    pog.Returned(count: _, rows: [user]) -> Ok(user.id)
    pog.Returned(count: _, rows: []) -> Error("User not found in database")
    _ -> Error("Multiple users found for same telegram_id")
  }

  use user_id <- result.try(user_id)
  let confirmation_code = util.generate_confirmation_code()

  use available_tables <- result.try(
    sql.get_available_tables(db, guests, date_val, time_val)
    |> result.map_error(fn(err) {
      "Failed to check availability: " <> string.inspect(err)
    }),
  )

  case available_tables {
    pog.Returned(count: _, rows: []) ->
      Error("No tables available for that date and time")

    pog.Returned(count: _, rows: [first_table, ..]) -> {
      let table_id = first_table.id

      use booking_result <- result.try(
        sql.create_booking(
          db,
          user_id,
          table_id,
          date_val,
          time_val,
          guests,
          "",
          confirmation_code,
        )
        |> result.map_error(fn(err) {
          "Database error: " <> string.inspect(err)
        }),
      )

      case booking_result {
        pog.Returned(count: _, rows: [row]) ->
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
        _ -> Error("Failed to create booking")
      }
    }
  }
}
