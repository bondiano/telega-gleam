# Restaurant Booking Bot - Persistent Flow Example

A complete restaurant table booking system demonstrating Telega's persistent flow capabilities, backed by **SQLite** — single-file persistence with no external services.

## Features Demonstrated

- 🍽️ **Multi-step conversational flows** - User registration and table booking with persistence
- 📊 **Unified storage** - Sessions *and* flows persisted via `telega_storage_sqlite`, with no hand-written storage code
- 🔄 **Flow resumption** - Continue conversations after interruptions and across restarts
- ✅ **Input validation** - Robust error handling and user feedback
- 🗄️ **Real-time data** - Live table availability checking
- 🏗️ **Interactive Menus** - Advanced menu system using menu_builder with categories and pagination
- 🔭 **Observability** - `telega/telemetry` events turned into logs, plus custom spans around database queries
- 🌍 **Internationalization** - English/Russian via `telega_i18n`; locale auto-selected from the user's Telegram language and switchable with `/language`

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

### Observability

Telega emits [`telemetry`](https://hexdocs.pm/telemetry/) events at every key
point of the update lifecycle (see the `telega/telemetry` module docs for the
full event reference). The `observability` module attaches one handler at
startup that turns the most useful events into log lines:

- slow updates (handler took longer than 1 second)
- handler errors (`telega.update.exception`)
- Telegram API rate-limit retries (`telega.api_call.retry`)
- flow steps, timeouts and cancellations
- the example's own database spans

Custom spans use the same `start`/`stop`/`exception` convention as the
built-in events:

```gleam
// handlers.gleam — emits restaurant_booking.db.start / .stop / .exception
telemetry.span(
  event: ["restaurant_booking", "db"],
  metadata: [#("query", telemetry.StringValue("get_user_bookings"))],
  run: fn() { sql.get_user_bookings(db, user_id) },
)
```

The same events can feed Prometheus or OpenTelemetry exporters instead of
logs — the attached handler is the only thing to swap.

### Internationalization

All user-facing copy lives in TOML catalogs under `locales/` (`en.toml` is the
default, `ru.toml` the translation). They are loaded once at startup and the
`telega_i18n` middleware resolves the active locale per update:

1. the user's stored override (set via `/language`), else
2. the user's Telegram `language_code`, else
3. the default locale (`en`).

```gleam
// bot.gleam
router.new(...)
|> router.use_middleware(i18n.middleware(catalog, db))
```

```gleam
// i18n.gleam — catalog loaded from the TOML files
pub fn catalog() -> Catalog {
  let assert Ok(catalog) =
    telega_i18n.new(default_locale: "en")
    |> telega_i18n.load_toml_dir("locales")
  catalog
}
```

Handlers and flow steps then translate by key — the middleware already stashed
the locale for the current update:

```gleam
i18n.t(ctx, "reg.welcome", [#("restaurant", util.get_restaurant_name())])
i18n.tn(ctx, "menu.items", count, [])   // CLDR pluralization (one/few/many)
```

Helpers without a `Context` (e.g. the bookings list formatter) use `i18n.tr`,
which reads the same per-process locale. Missing keys fall back through the
locale chain to the default, then to the key itself — so a typo degrades
gracefully instead of crashing.

**Switching language.** `/language` shows an inline keyboard (each language in
its own name). The chosen locale is persisted per user in the same SQLite
key-value store the flows use (key `lang:{chat}:{from}`), so it survives
restarts and is independent of registration. The selection callbacks are
registered as exact matches (`lang:en`, `lang:ru`) so they take priority over
the flows' catch-all callback handler:

```gleam
// settings.gleam — persist, acknowledge, then confirm in the new language
use _ <- result.try(i18n.set_user_language(db, chat_id, from_id, locale))
let _ = reply.answer_callback_query(ctx, types.new_answer_callback_query_parameters(query_id))
telega_i18n.enter(catalog:, locale:)
reply.with_text(ctx, i18n.t(ctx, "settings.language_set", []))
```

The plain `handler.text_step` / `message_step` bake their text in at startup,
before any locale is known. The booking flow instead uses the context-aware
`handler.text_step_with` / `handler.message_step_with`, which resolve the text
per update (when the middleware's locale is already in effect):

```gleam
// flows/booking.gleam
builder.add_step(
  Date,
  handler.text_step_with(
    fn(ctx, _inst) { i18n.t(ctx, "book.ask_date", []) },
    "booking_date",
    Time,
  ),
)
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
- `/language` - Switch language (English / Русский)
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
