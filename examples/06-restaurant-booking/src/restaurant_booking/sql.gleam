//// This module contains the code to run the sql queries defined in
//// `./src/restaurant_booking/sql`.
//// > 🐿️ This module was generated automatically using v4.4.1 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/json.{type Json}
import gleam/option.{type Option}
import gleam/time/calendar.{type Date, type TimeOfDay}
import gleam/time/timestamp.{type Timestamp}
import pog

/// A row you get from running the `create_booking` query
/// defined in `./src/restaurant_booking/sql/create_booking.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateBookingRow {
  CreateBookingRow(
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

/// Create a new booking
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_booking(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Int,
  arg_3: Date,
  arg_4: TimeOfDay,
  arg_5: Int,
  arg_6: String,
  arg_7: String,
) -> Result(pog.Returned(CreateBookingRow), pog.QueryError) {
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
    decode.success(CreateBookingRow(
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

  "-- Create a new booking
INSERT INTO bookings 
  (user_id, table_id, booking_date, booking_time, guests, special_requests, confirmation_code, status)
VALUES ($1, $2, $3::date, $4::time, $5, $6, $7, 'confirmed')
RETURNING id, user_id, table_id, booking_date::text, booking_time::text, guests, special_requests, status, confirmation_code"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.parameter(pog.calendar_date(arg_3))
  |> pog.parameter(pog.calendar_time_of_day(arg_4))
  |> pog.parameter(pog.int(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_or_update_user` query
/// defined in `./src/restaurant_booking/sql/create_or_update_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateOrUpdateUserRow {
  CreateOrUpdateUserRow(
    id: Int,
    telegram_id: Int,
    chat_id: Int,
    name: String,
    phone: String,
    email: Option(String),
    created_at: Option(Timestamp),
    updated_at: Option(Timestamp),
  )
}

/// Create or update user in database
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_or_update_user(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Int,
  arg_3: String,
  arg_4: String,
  arg_5: String,
) -> Result(pog.Returned(CreateOrUpdateUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use telegram_id <- decode.field(1, decode.int)
    use chat_id <- decode.field(2, decode.int)
    use name <- decode.field(3, decode.string)
    use phone <- decode.field(4, decode.string)
    use email <- decode.field(5, decode.optional(decode.string))
    use created_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(7, decode.optional(pog.timestamp_decoder()))
    decode.success(CreateOrUpdateUserRow(
      id:,
      telegram_id:,
      chat_id:,
      name:,
      phone:,
      email:,
      created_at:,
      updated_at:,
    ))
  }

  "-- Create or update user in database
INSERT INTO users (telegram_id, chat_id, name, phone, email, updated_at)
VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP)
ON CONFLICT (telegram_id)
DO UPDATE SET 
  chat_id = EXCLUDED.chat_id,
  name = EXCLUDED.name, 
  phone = EXCLUDED.phone, 
  email = EXCLUDED.email, 
  updated_at = CURRENT_TIMESTAMP
RETURNING id, telegram_id, chat_id, name, phone, email, created_at, updated_at"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Delete a flow instance by ID
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_flow_instance(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Delete a flow instance by ID
DELETE FROM flow_instances WHERE id = $1"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_available_tables` query
/// defined in `./src/restaurant_booking/sql/get_available_tables.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetAvailableTablesRow {
  GetAvailableTablesRow(
    id: Int,
    table_number: Int,
    capacity: Int,
    location: Option(String),
    is_available: Option(Bool),
  )
}

/// Get available tables for date, time and guest count
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_available_tables(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Date,
  arg_3: TimeOfDay,
) -> Result(pog.Returned(GetAvailableTablesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use table_number <- decode.field(1, decode.int)
    use capacity <- decode.field(2, decode.int)
    use location <- decode.field(3, decode.optional(decode.string))
    use is_available <- decode.field(4, decode.optional(decode.bool))
    decode.success(GetAvailableTablesRow(
      id:,
      table_number:,
      capacity:,
      location:,
      is_available:,
    ))
  }

  "-- Get available tables for date, time and guest count
SELECT t.id, t.table_number, t.capacity, t.location, t.is_available
FROM restaurant_tables t
WHERE t.capacity >= $1
  AND t.is_available = true
  AND t.id NOT IN (
    SELECT table_id FROM bookings
    WHERE booking_date = $2::date
      AND booking_time = $3::time
      AND status != 'cancelled'
  )
ORDER BY t.capacity, t.table_number"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.calendar_date(arg_2))
  |> pog.parameter(pog.calendar_time_of_day(arg_3))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_table` query
/// defined in `./src/restaurant_booking/sql/get_table.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetTableRow {
  GetTableRow(
    id: Int,
    table_number: Int,
    capacity: Int,
    location: Option(String),
    is_available: Option(Bool),
  )
}

/// Get table by ID
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_table(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(GetTableRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use table_number <- decode.field(1, decode.int)
    use capacity <- decode.field(2, decode.int)
    use location <- decode.field(3, decode.optional(decode.string))
    use is_available <- decode.field(4, decode.optional(decode.bool))
    decode.success(GetTableRow(
      id:,
      table_number:,
      capacity:,
      location:,
      is_available:,
    ))
  }

  "-- Get table by ID
SELECT id, table_number, capacity, location, is_available 
FROM restaurant_tables 
WHERE id = $1"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_user` query
/// defined in `./src/restaurant_booking/sql/get_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetUserRow {
  GetUserRow(
    id: Int,
    telegram_id: Int,
    chat_id: Int,
    name: String,
    phone: String,
    email: Option(String),
    created_at: Option(Timestamp),
    updated_at: Option(Timestamp),
  )
}

/// Get user by telegram_id and chat_id
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_user(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Int,
) -> Result(pog.Returned(GetUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use telegram_id <- decode.field(1, decode.int)
    use chat_id <- decode.field(2, decode.int)
    use name <- decode.field(3, decode.string)
    use phone <- decode.field(4, decode.string)
    use email <- decode.field(5, decode.optional(decode.string))
    use created_at <- decode.field(6, decode.optional(pog.timestamp_decoder()))
    use updated_at <- decode.field(7, decode.optional(pog.timestamp_decoder()))
    decode.success(GetUserRow(
      id:,
      telegram_id:,
      chat_id:,
      name:,
      phone:,
      email:,
      created_at:,
      updated_at:,
    ))
  }

  "-- Get user by telegram_id and chat_id
SELECT id, telegram_id, chat_id, name, phone, email, created_at, updated_at 
FROM users 
WHERE telegram_id = $1 AND chat_id = $2"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_user_bookings` query
/// defined in `./src/restaurant_booking/sql/get_user_bookings.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetUserBookingsRow {
  GetUserBookingsRow(
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
    created_at: Option(Timestamp),
  )
}

/// Get all bookings for a specific user
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_user_bookings(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(GetUserBookingsRow), pog.QueryError) {
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
    use created_at <- decode.field(10, decode.optional(pog.timestamp_decoder()))
    decode.success(GetUserBookingsRow(
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
      created_at:,
    ))
  }

  "-- Get all bookings for a specific user
SELECT 
    b.id,
    b.booking_date::text,
    b.booking_time::text,
    b.guests,
    b.special_requests,
    b.status,
    b.confirmation_code,
    t.table_number,
    t.capacity,
    t.location,
    b.created_at
FROM bookings b
JOIN restaurant_tables t ON b.table_id = t.id
WHERE b.user_id = $1
ORDER BY b.booking_date DESC, b.booking_time DESC"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_user_instances` query
/// defined in `./src/restaurant_booking/sql/list_user_instances.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListUserInstancesRow {
  ListUserInstancesRow(
    id: String,
    flow_name: String,
    user_id: Int,
    chat_id: Int,
    current_step: String,
    state_data: Option(String),
    scene_data: Option(String),
    wait_token: Option(String),
    created_at: Int,
    updated_at: Int,
  )
}

/// List all flow instances for a user and chat
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_user_instances(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Int,
) -> Result(pog.Returned(ListUserInstancesRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.string)
    use flow_name <- decode.field(1, decode.string)
    use user_id <- decode.field(2, decode.int)
    use chat_id <- decode.field(3, decode.int)
    use current_step <- decode.field(4, decode.string)
    use state_data <- decode.field(5, decode.optional(decode.string))
    use scene_data <- decode.field(6, decode.optional(decode.string))
    use wait_token <- decode.field(7, decode.optional(decode.string))
    use created_at <- decode.field(8, decode.int)
    use updated_at <- decode.field(9, decode.int)
    decode.success(ListUserInstancesRow(
      id:,
      flow_name:,
      user_id:,
      chat_id:,
      current_step:,
      state_data:,
      scene_data:,
      wait_token:,
      created_at:,
      updated_at:,
    ))
  }

  "-- List all flow instances for a user and chat
SELECT id, flow_name, user_id, chat_id, current_step, 
       state_data, scene_data, wait_token,
       EXTRACT(EPOCH FROM created_at)::INT as created_at,
       EXTRACT(EPOCH FROM updated_at)::INT as updated_at
FROM flow_instances 
WHERE user_id = $1 AND chat_id = $2"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `load_flow_instance` query
/// defined in `./src/restaurant_booking/sql/load_flow_instance.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type LoadFlowInstanceRow {
  LoadFlowInstanceRow(
    id: String,
    flow_name: String,
    user_id: Int,
    chat_id: Int,
    current_step: String,
    state_data: Option(String),
    scene_data: Option(String),
    wait_token: Option(String),
    created_at: Int,
    updated_at: Int,
  )
}

/// Load a flow instance by ID or wait token
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn load_flow_instance(
  db: pog.Connection,
  arg_1: String,
) -> Result(pog.Returned(LoadFlowInstanceRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.string)
    use flow_name <- decode.field(1, decode.string)
    use user_id <- decode.field(2, decode.int)
    use chat_id <- decode.field(3, decode.int)
    use current_step <- decode.field(4, decode.string)
    use state_data <- decode.field(5, decode.optional(decode.string))
    use scene_data <- decode.field(6, decode.optional(decode.string))
    use wait_token <- decode.field(7, decode.optional(decode.string))
    use created_at <- decode.field(8, decode.int)
    use updated_at <- decode.field(9, decode.int)
    decode.success(LoadFlowInstanceRow(
      id:,
      flow_name:,
      user_id:,
      chat_id:,
      current_step:,
      state_data:,
      scene_data:,
      wait_token:,
      created_at:,
      updated_at:,
    ))
  }

  "-- Load a flow instance by ID or wait token
SELECT id, flow_name, user_id, chat_id, current_step, 
       state_data, scene_data, wait_token, 
       EXTRACT(EPOCH FROM created_at)::INT as created_at,
       EXTRACT(EPOCH FROM updated_at)::INT as updated_at
FROM flow_instances 
WHERE id = $1 OR wait_token = $1"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// Save or update a flow instance
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn save_flow_instance(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: Int,
  arg_4: Int,
  arg_5: String,
  arg_6: Json,
  arg_7: Json,
  arg_8: String,
) -> Result(pog.Returned(Nil), pog.QueryError) {
  let decoder = decode.map(decode.dynamic, fn(_) { Nil })

  "-- Save or update a flow instance
INSERT INTO flow_instances 
  (id, flow_name, user_id, chat_id, current_step, state_data, scene_data, wait_token)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
ON CONFLICT (id) DO UPDATE SET
  current_step = EXCLUDED.current_step,
  state_data = EXCLUDED.state_data,
  scene_data = EXCLUDED.scene_data,
  wait_token = EXCLUDED.wait_token,
  updated_at = CURRENT_TIMESTAMP"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.int(arg_3))
  |> pog.parameter(pog.int(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(json.to_string(arg_6)))
  |> pog.parameter(pog.text(json.to_string(arg_7)))
  |> pog.parameter(pog.text(arg_8))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `upsert_user` query
/// defined in `./src/restaurant_booking/sql/upsert_user.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.4.1 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpsertUserRow {
  UpsertUserRow(
    id: Int,
    telegram_id: Int,
    chat_id: Int,
    name: String,
    phone: String,
    email: Option(String),
  )
}

/// Create or update a user
///
/// > 🐿️ This function was generated automatically using v4.4.1 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn upsert_user(
  db: pog.Connection,
  arg_1: Int,
  arg_2: Int,
  arg_3: String,
  arg_4: String,
  arg_5: String,
) -> Result(pog.Returned(UpsertUserRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use telegram_id <- decode.field(1, decode.int)
    use chat_id <- decode.field(2, decode.int)
    use name <- decode.field(3, decode.string)
    use phone <- decode.field(4, decode.string)
    use email <- decode.field(5, decode.optional(decode.string))
    decode.success(UpsertUserRow(
      id:,
      telegram_id:,
      chat_id:,
      name:,
      phone:,
      email:,
    ))
  }

  "-- Create or update a user
INSERT INTO users (telegram_id, chat_id, name, phone, email)
VALUES ($1, $2, $3, $4, $5)
ON CONFLICT (telegram_id) DO UPDATE SET
  chat_id = EXCLUDED.chat_id,
  name = EXCLUDED.name,
  phone = EXCLUDED.phone,
  email = EXCLUDED.email,
  updated_at = CURRENT_TIMESTAMP
RETURNING id, telegram_id, chat_id, name, phone, email"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.parameter(pog.int(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.returning(decoder)
  |> pog.execute(db)
}
