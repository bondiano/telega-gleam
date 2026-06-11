# Restaurant Booking Bot - Persistent Flow Example

A complete restaurant table booking system demonstrating Telega's persistent flow capabilities, backed by **SQLite** — single-file persistence with no external services.

## Features Demonstrated

- 🍽️ **Multi-step conversational flows** - User registration and table booking with persistence
- 📊 **Unified storage** - Sessions *and* flows persisted via `telega_storage_sqlite`, with no hand-written storage code
- 🔄 **Flow resumption** - Continue conversations after interruptions and across restarts
- ✅ **Input validation** - Robust error handling and user feedback
- 🗄️ **Real-time data** - Live table availability checking
- 🏗️ **Interactive Menus** - Advanced menu system using menu_builder with categories and pagination

## Setup

### Prerequisites
- Gleam
- Telegram Bot Token from @BotFather

No database server is required — the bot creates and seeds a local SQLite file on first run.

### Quick Start

1. Set environment variables (the bot reads them from the process environment):

```bash
export BOT_TOKEN="<your bot token>"
export RESTAURANT_NAME="Bella Vista"      # optional
export DATABASE_PATH="restaurant_booking.db"  # optional, this is the default
```

2. Run the bot:

```bash
gleam run
```

The SQLite schema (users, tables, bookings) and the `telega_storage` table for flow
persistence are created automatically, and sample tables are seeded on startup.

### Flow persistence

Flow state is stored through the unified `KeyValueStorage` contract:

```gleam
// util.gleam — no bespoke SQL, just the adapter + the core bridge
pub fn create_database_storage(db: sqlight.Connection) -> types.FlowStorage(String) {
  sqlite.new(db)
  |> with_string_errors
  |> storage.flow_storage_from_storage
}
```

## Testing

```bash
gleam test
```

Integration tests run against an in-memory SQLite database, so they need no setup.

## Usage

- `/start` - Register your profile
- `/menu` - Browse restaurant menu with interactive categories
- `/book` - Make a table reservation
- `/my_bookings` - View your reservations
- `/help` - Show available commands

The bot guides users through multi-step flows that persist across bot restarts and handle interruptions gracefully.

### Menu System

The new `/menu` command demonstrates the `menu_builder` module capabilities:

- **Categorized browsing** - Browse by food categories (Appetizers, Main Courses, Pizza, etc.)
- **Pagination** - Large item lists automatically paginated
- **Navigation** - Smooth back/forward navigation between menu levels
- **Rich formatting** - Emojis, pricing, and item counts for better UX
- **Integration** - Seamlessly integrated with existing flows and database

Example menu structure:
```
🍽️ Restaurant Name Menu

🍽️ Food Categories
🥗 Appetizers (8 items)    🍖 Main Courses (12 items)
🍝 Pasta (10 items)        🍕 Pizza (15 items)
🍰 Desserts (6 items)      🥤 Beverages (20 items)

📋 Reservations
🍽️ Make Reservation       📋 My Bookings
```
