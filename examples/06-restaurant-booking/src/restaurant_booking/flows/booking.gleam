import gleam/int
import gleam/option
import gleam/result
import gleam/string
import sqlight

import telega/bot.{type Context}
import telega/flow/action
import telega/flow/builder
import telega/flow/handler
import telega/flow/instance
import telega/flow/types
import telega/reply

import restaurant_booking/dependencies.{type Dependencies}
import restaurant_booking/i18n
import restaurant_booking/sql
import restaurant_booking/util

pub type BookingStep {
  CheckUser
  Welcome
  Date
  Time
  Guests
  Confirm
}

fn step_to_string(step: BookingStep) -> String {
  case step {
    CheckUser -> "check_user"
    Welcome -> "welcome"
    Date -> "date"
    Time -> "time"
    Guests -> "guests"
    Confirm -> "confirm"
  }
}

fn string_to_step(name: String) -> Result(BookingStep, Nil) {
  case name {
    "check_user" -> Ok(CheckUser)
    "welcome" -> Ok(Welcome)
    "date" -> Ok(Date)
    "time" -> Ok(Time)
    "guests" -> Ok(Guests)
    "confirm" -> Ok(Confirm)
    _ -> Error(Nil)
  }
}

/// Create simplified booking flow using built-in helpers
pub fn create_booking_flow(
  db: sqlight.Connection,
) -> types.Flow(BookingStep, Nil, String, Dependencies) {
  // `db` builds the flow's persistence backend at init (resolved before any
  // update). Step handlers read their query db from `ctx.dependencies.db`.
  let storage = util.create_database_storage(db)

  builder.new("booking", storage, step_to_string, string_to_step)
  |> builder.add_step(CheckUser, check_user_registration)
  |> builder.add_step(
    Welcome,
    // `_with` variants resolve the text per update, so the middleware's locale
    // is already in effect — no need for a custom step wrapper.
    handler.message_step_with(
      fn(ctx, _inst) {
        i18n.t(ctx, "book.welcome", [
          #("restaurant", util.get_restaurant_name()),
        ])
      },
      option.Some(Date),
    ),
  )
  |> builder.add_step(
    Date,
    handler.text_step_with(
      fn(ctx, _inst) { i18n.t(ctx, "book.ask_date", []) },
      "booking_date",
      Time,
    ),
  )
  |> builder.add_step(
    Time,
    handler.text_step_with(
      fn(ctx, _inst) { i18n.t(ctx, "book.ask_time", []) },
      "booking_time",
      Guests,
    ),
  )
  |> builder.add_step(
    Guests,
    handler.text_step_with(
      fn(ctx, _inst) { i18n.t(ctx, "book.ask_guests", []) },
      "guest_count",
      Confirm,
    ),
  )
  |> builder.add_step(Confirm, confirm_and_book_step)
  |> builder.on_error(fn(ctx, _, error) {
    let error_msg = option.unwrap(error, "Unknown error")
    util.log_error("Booking flow error: " <> error_msg)
    use _ <- result.try(
      reply.with_text(
        ctx,
        i18n.t(ctx, "book.error", [#("error", i18n.t(ctx, error_msg, []))]),
      )
      |> result.map_error(fn(err) {
        "Error message failed: " <> string.inspect(err)
      }),
    )

    Ok(ctx)
  })
  |> builder.build(initial: CheckUser)
}

/// Check if user is registered before allowing booking
fn check_user_registration(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(BookingStep, Nil, String, Dependencies) {
  case
    sql.get_user(
      ctx.dependencies.db,
      instance.instance_user_id(instance),
      instance.instance_chat_id(instance),
    )
  {
    Ok([_user, ..]) -> action.next(ctx, instance, Welcome)

    Ok([]) -> {
      let _ =
        reply.with_text(ctx, i18n.t(ctx, "common.registration_required", []))

      action.cancel(ctx, instance)
    }

    Error(err) ->
      Error("Failed to check user registration: " <> string.inspect(err))
  }
}

/// Simplified step: Confirm and create booking
fn confirm_and_book_step(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(BookingStep, Nil, String, Dependencies) {
  use booking_data <- action.try_with_message(
    ctx,
    instance,
    extract_booking_data(instance),
    fn(err) { "❌ " <> i18n.t(ctx, err, []) },
  )

  let confirmation =
    i18n.t(ctx, "book.confirm", [
      #("date", booking_data.booking_date),
      #("time", booking_data.booking_time),
      #("guests", int.to_string(booking_data.guest_count)),
      #("restaurant", util.get_restaurant_name()),
    ])

  use _ <- action.try(ctx, instance, reply.with_text(ctx, confirmation))

  use booking <- action.try_with_message(
    ctx,
    instance,
    create_booking(
      ctx,
      booking_data.booking_date,
      booking_data.booking_time,
      booking_data.guest_count,
    ),
    fn(err) { "❌ " <> i18n.t(ctx, err, []) },
  )

  let success_message =
    i18n.t(ctx, "book.success", [
      #("code", option.unwrap(booking.confirmation_code, "PENDING")),
      #("date", booking.booking_date),
      #("time", booking.booking_time),
      #("guests", int.to_string(booking.guests)),
      #("restaurant", util.get_restaurant_name()),
    ])

  use _ <- action.try(ctx, instance, reply.with_text(ctx, success_message))
  action.complete(ctx, instance)
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
  instance: types.FlowInstance,
) -> Result(BookingData, String) {
  use booking_date <- result.try(
    instance.get_data(instance, "booking_date")
    |> option.to_result("Missing booking date"),
  )

  use booking_time <- result.try(
    instance.get_data(instance, "booking_time")
    |> option.to_result("Missing booking time"),
  )

  use guest_count_str <- result.try(
    instance.get_data(instance, "guest_count")
    |> option.to_result("Missing guest count"),
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

/// Create real booking in database
fn create_booking(
  ctx: Context(Nil, String, Dependencies),
  date: String,
  time: String,
  guests: Int,
) -> Result(Booking, String) {
  use _ <- result.try(validate_date(date))
  use _ <- result.try(validate_time(time))

  let db = ctx.dependencies.db

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
          "",
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

/// Validate a date string is `YYYY-MM-DD` (stored as text in SQLite).
fn validate_date(date_str: String) -> Result(Nil, String) {
  case string.split(date_str, "-") {
    [year, month, day] ->
      case int.parse(year), int.parse(month), int.parse(day) {
        Ok(_), Ok(_), Ok(_) -> Ok(Nil)
        _, _, _ -> Error("error.invalid_date")
      }
    _ -> Error("error.invalid_date")
  }
}

/// Validate a time string is `HH:MM` (stored as text in SQLite).
fn validate_time(time_str: String) -> Result(Nil, String) {
  case string.split(time_str, ":") {
    [hour, minute] ->
      case int.parse(hour), int.parse(minute) {
        Ok(_), Ok(_) -> Ok(Nil)
        _, _ -> Error("error.invalid_time")
      }
    _ -> Error("error.invalid_time")
  }
}
