# Restaurant Booking Bot - Persistent Flow Example

A complete restaurant table booking system demonstrating Telega's persistent flow capabilities, backed by **SQLite** — single-file persistence with no external services.

## Features Demonstrated

- 🍽️ **Multi-step conversational flows** - User registration as a hand-written flow with persistence
- 🪟 **Declarative dialogs** - Table booking (`/book`) as a `telega/dialog`: windows rendered into one live message, Back navigation, in-window validation errors
- 📊 **Unified storage** - Sessions, flows *and* dialogs persisted via `telega_storage_sqlite`, with no hand-written storage code
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

### Booking dialog vs. hand-written flows

Registration and menu are hand-written flows (`telega/flow`): each step sends
its own messages and parses its own callbacks. Booking (`/book`) shows the
higher-level alternative — a **declarative dialog** (`telega/dialog`):

- each window is a pure `render(state, ctx) -> RenderedWindow` plus handlers
  returning `Stay`/`Goto`/`Back`/`Done` — no manual `edit`, no callback parsing
- the engine keeps **one live message** and edits it on every transition —
  including **media windows**: the `photo` window attaches a
  `PhotoMedia` and the engine recreates the message on text ↔ media
  transitions (the Bot API can't edit one into the other)
- interactive keyboards are **managed widgets** (`telega/dialog/widget`):
  the `time` window pages through 12 half-hour slots (`paged_select`), the
  `guests` window is a `select` grid, and the `prefs` window combines a
  `radio` (seating area) with a `multiselect` (extras) — the engine renders
  their buttons, handles their callbacks, and persists their selections;
  the confirm window reads them back with `dialog.widget_store`
- validation errors are part of the state and re-rendered inside the window
- the optional delivery address is a **sub-dialog** (`dialog.subdialog`): a
  reusable two-window dialog with its own state type (`AddressState`) started
  from the confirm window via `StartSub`; it takes over the same live
  message, its `Done` hands the exported result to the confirm window's
  `on_sub_result` (which stores the address in `BookingState`), and `‹ Back`
  on its first window cancels it
- state persists through the same SQLite storage, so a half-finished booking
  (including widget selections and a half-entered address) survives restarts;
  `/cancel` aborts it

```gleam
// flows/booking.gleam
dialog.new(id: "booking", storage:, initial_state:, encode_state:, decode_state:)
|> dialog.window_with_input(id: "date", render: render_date, on_action:, on_text:)
|> dialog.window_with_widgets(id: "time", ..., widgets: [
  widget.paged_select(id: "slot", items: time_slot_items, page_size: 6,
    columns: 3, on_selected: time_selected),
])
|> dialog.window_with_widgets(id: "guests", ..., widgets: [
  widget.select(id: "n", items: guest_items, columns: 3, on_selected: guests_selected),
])
|> dialog.window_with_widgets(id: "prefs", ..., widgets: [
  widget.radio(id: "zone", items: zone_items, default: Some("hall")),
  widget.multiselect(id: "extras", items: extra_items, min: 0, max: 3, done: "confirm"),
])
|> dialog.window(id: "confirm", render: render_confirm, on_action:)
|> dialog.window(id: "photo", render: render_photo, on_action:)  // media window
|> dialog.subdialog(sub: create_address_dialog(storage),         // city → street
  init: fn(_booking, _args) { AddressState(city: "", street: "") },
  result: address_result)
|> dialog.on_sub_result(window: "confirm", handler: confirm_sub_result)
|> dialog.initial("date")
|> dialog.on_done(booking_done)
|> dialog.with_labels(dialog_labels)  // i18n for the Done button / stale notice
|> dialog.build()
```

The dialog is registered without a trigger (`dialog.attach`) and started from
the `/book` handler after the registration check via `dialog.start`. Window
renders are pure, so `test/booking_dialog_test.gleam` checks the frames with
`telega/testing/render.window_frame` — no network, no actors.

> **Migration note:** booking used to be a hand-written flow registered as
> `"booking"`; the dialog compiles to the flow name `"__dialog:booking"`.
> Persisted instances are keyed by flow name, so renaming a flow (or turning
> it into a dialog) **orphans** any instances saved under the old name — they
> are never resumed and never expire on their own. After such a rename, clean
> the stale rows from the sessions storage (here: the `telega_storage` SQLite
> table, keys prefixed with the old flow name).

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
