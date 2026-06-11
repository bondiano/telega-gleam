//// SQLite data access for the restaurant booking example.
////
//// Domain queries (users, tables, bookings) backed by `sqlight`. Flow
//// persistence lives in `telega_storage_sqlite` (see `util.create_database_storage`),
//// so there is no hand-written flow-instance storage here.

import gleam/dynamic/decode
import gleam/option.{type Option}
import sqlight

pub type GetUserRow {
  GetUserRow(
    id: Int,
    telegram_id: Int,
    chat_id: Int,
    name: String,
    phone: String,
    email: Option(String),
  )
}

/// Get user by telegram_id and chat_id.
pub fn get_user(
  db: sqlight.Connection,
  telegram_id: Int,
  chat_id: Int,
) -> Result(List(GetUserRow), sqlight.Error) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use telegram_id <- decode.field(1, decode.int)
    use chat_id <- decode.field(2, decode.int)
    use name <- decode.field(3, decode.string)
    use phone <- decode.field(4, decode.string)
    use email <- decode.field(5, decode.optional(decode.string))
    decode.success(GetUserRow(
      id:,
      telegram_id:,
      chat_id:,
      name:,
      phone:,
      email:,
    ))
  }

  sqlight.query(
    "SELECT id, telegram_id, chat_id, name, phone, email
     FROM users WHERE telegram_id = ? AND chat_id = ?",
    on: db,
    with: [sqlight.int(telegram_id), sqlight.int(chat_id)],
    expecting: decoder,
  )
}

/// Create or update a user (upsert on telegram_id).
pub fn create_or_update_user(
  db: sqlight.Connection,
  telegram_id: Int,
  chat_id: Int,
  name: String,
  phone: String,
  email: String,
) -> Result(Nil, sqlight.Error) {
  let result =
    sqlight.query(
      "INSERT INTO users (telegram_id, chat_id, name, phone, email, updated_at)
       VALUES (?, ?, ?, ?, ?, datetime('now'))
       ON CONFLICT(telegram_id) DO UPDATE SET
         chat_id = excluded.chat_id,
         name = excluded.name,
         phone = excluded.phone,
         email = excluded.email,
         updated_at = datetime('now')",
      on: db,
      with: [
        sqlight.int(telegram_id),
        sqlight.int(chat_id),
        sqlight.text(name),
        sqlight.text(phone),
        sqlight.text(email),
      ],
      expecting: decode.dynamic,
    )
  case result {
    Ok(_) -> Ok(Nil)
    Error(err) -> Error(err)
  }
}

pub type AvailableTableRow {
  AvailableTableRow(
    id: Int,
    table_number: Int,
    capacity: Int,
    location: Option(String),
  )
}

/// Get tables that seat at least `guests` and are free at the date/time.
pub fn get_available_tables(
  db: sqlight.Connection,
  guests: Int,
  date: String,
  time: String,
) -> Result(List(AvailableTableRow), sqlight.Error) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use table_number <- decode.field(1, decode.int)
    use capacity <- decode.field(2, decode.int)
    use location <- decode.field(3, decode.optional(decode.string))
    decode.success(AvailableTableRow(id:, table_number:, capacity:, location:))
  }

  sqlight.query(
    "SELECT t.id, t.table_number, t.capacity, t.location
     FROM restaurant_tables t
     WHERE t.capacity >= ?
       AND t.is_available = 1
       AND t.id NOT IN (
         SELECT table_id FROM bookings
         WHERE booking_date = ? AND booking_time = ? AND status != 'cancelled'
       )
     ORDER BY t.capacity, t.table_number",
    on: db,
    with: [sqlight.int(guests), sqlight.text(date), sqlight.text(time)],
    expecting: decoder,
  )
}

pub type BookingRow {
  BookingRow(
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

/// Create a confirmed booking, then read it back by confirmation code.
pub fn create_booking(
  db: sqlight.Connection,
  user_id: Int,
  table_id: Int,
  date: String,
  time: String,
  guests: Int,
  special_requests: String,
  confirmation_code: String,
) -> Result(List(BookingRow), sqlight.Error) {
  let insert =
    sqlight.query(
      "INSERT INTO bookings
         (user_id, table_id, booking_date, booking_time, guests,
          special_requests, confirmation_code, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, 'confirmed')",
      on: db,
      with: [
        sqlight.int(user_id),
        sqlight.int(table_id),
        sqlight.text(date),
        sqlight.text(time),
        sqlight.int(guests),
        sqlight.text(special_requests),
        sqlight.text(confirmation_code),
      ],
      expecting: decode.dynamic,
    )
  case insert {
    Ok(_) -> read_booking(db, confirmation_code)
    Error(err) -> Error(err)
  }
}

fn read_booking(
  db: sqlight.Connection,
  confirmation_code: String,
) -> Result(List(BookingRow), sqlight.Error) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use user_id <- decode.field(1, decode.optional(decode.int))
    use table_id <- decode.field(2, decode.optional(decode.int))
    use booking_date <- decode.field(3, decode.string)
    use booking_time <- decode.field(4, decode.string)
    use guests <- decode.field(5, decode.int)
    use special_requests <- decode.field(6, decode.optional(decode.string))
    use status <- decode.field(7, decode.optional(decode.string))
    use confirmation_code <- decode.field(8, decode.optional(decode.string))
    decode.success(BookingRow(
      id:,
      user_id:,
      table_id:,
      booking_date:,
      booking_time:,
      guests:,
      special_requests:,
      status:,
      confirmation_code:,
    ))
  }

  sqlight.query(
    "SELECT id, user_id, table_id, booking_date, booking_time, guests,
            special_requests, status, confirmation_code
     FROM bookings WHERE confirmation_code = ?",
    on: db,
    with: [sqlight.text(confirmation_code)],
    expecting: decoder,
  )
}

pub type UserBookingRow {
  UserBookingRow(
    id: Int,
    booking_date: String,
    booking_time: String,
    guests: Int,
    special_requests: Option(String),
    status: Option(String),
    confirmation_code: Option(String),
    table_number: Int,
    capacity: Int,
    location: Option(String),
  )
}

/// Get all bookings for a user, newest first.
pub fn get_user_bookings(
  db: sqlight.Connection,
  user_id: Int,
) -> Result(List(UserBookingRow), sqlight.Error) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use booking_date <- decode.field(1, decode.string)
    use booking_time <- decode.field(2, decode.string)
    use guests <- decode.field(3, decode.int)
    use special_requests <- decode.field(4, decode.optional(decode.string))
    use status <- decode.field(5, decode.optional(decode.string))
    use confirmation_code <- decode.field(6, decode.optional(decode.string))
    use table_number <- decode.field(7, decode.int)
    use capacity <- decode.field(8, decode.int)
    use location <- decode.field(9, decode.optional(decode.string))
    decode.success(UserBookingRow(
      id:,
      booking_date:,
      booking_time:,
      guests:,
      special_requests:,
      status:,
      confirmation_code:,
      table_number:,
      capacity:,
      location:,
    ))
  }

  sqlight.query(
    "SELECT b.id, b.booking_date, b.booking_time, b.guests,
            b.special_requests, b.status, b.confirmation_code,
            t.table_number, t.capacity, t.location
     FROM bookings b
     JOIN restaurant_tables t ON b.table_id = t.id
     WHERE b.user_id = ?
     ORDER BY b.booking_date DESC, b.booking_time DESC",
    on: db,
    with: [sqlight.int(user_id)],
    expecting: decoder,
  )
}
