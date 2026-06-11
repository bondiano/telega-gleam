import gleam/io
import gleam/result
import gleam/string
import sqlight
import telega_storage_sqlite as sqlite

/// Connection configuration — just a file path for SQLite.
pub type ConnectionConfig {
  ConnectionConfig(path: String)
}

/// Open the SQLite database and ensure the schema exists.
pub fn connect(cfg: ConnectionConfig) -> Result(sqlight.Connection, String) {
  use db <- result.try(
    sqlight.open(cfg.path)
    |> result.map_error(fn(err) {
      "Failed to open database: " <> string.inspect(err)
    }),
  )

  use _ <- result.try(
    migrate(db)
    |> result.map_error(fn(err) {
      "Failed to run migrations: " <> string.inspect(err)
    }),
  )

  io.println("✅ Connected to SQLite database: " <> cfg.path)
  Ok(db)
}

/// Create domain tables, the telega_storage table, and seed sample tables.
pub fn migrate(db: sqlight.Connection) -> Result(Nil, sqlight.Error) {
  use _ <- result.try(sqlight.exec(schema, db))
  use _ <- result.try(sqlite.migrate(db))
  use _ <- result.try(sqlight.exec(seed_tables, db))
  Ok(Nil)
}

const schema = "
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  telegram_id INTEGER UNIQUE NOT NULL,
  chat_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT,
  created_at TEXT DEFAULT (datetime('now')),
  updated_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS restaurant_tables (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_number INTEGER UNIQUE NOT NULL,
  capacity INTEGER NOT NULL,
  location TEXT,
  is_available INTEGER DEFAULT 1
);

CREATE TABLE IF NOT EXISTS bookings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER REFERENCES users(id),
  table_id INTEGER REFERENCES restaurant_tables(id),
  booking_date TEXT NOT NULL,
  booking_time TEXT NOT NULL,
  guests INTEGER NOT NULL,
  special_requests TEXT,
  status TEXT DEFAULT 'pending',
  confirmation_code TEXT UNIQUE,
  created_at TEXT DEFAULT (datetime('now')),
  UNIQUE(table_id, booking_date, booking_time)
);
"

const seed_tables = "
INSERT OR IGNORE INTO restaurant_tables (table_number, capacity, location) VALUES
  (1, 2, 'window'),
  (2, 2, 'window'),
  (3, 4, 'center'),
  (4, 4, 'center'),
  (5, 6, 'center'),
  (6, 2, 'terrace'),
  (7, 4, 'terrace'),
  (8, 8, 'terrace');
"
