# Telega

[![Package Version](https://img.shields.io/hexpm/v/telega)](https://hex.pm/packages/telega)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/telega/)

A [Gleam](https://gleam.run/) library for the Telegram Bot API on BEAM.

<a href="#" target="blank">
  <img src="https://raw.githubusercontent.com/bondiano/telega-gleam/refs/heads/master/docs/logo.png" alt="Telega" width="254" style="display: block; margin: 0 auto;" />
</a>

## It provides

- an interface to the Telegram Bot HTTP-based APIs `telega/api`
- a client for the Telegram Bot API `telega/client`
- OTP supervision tree for all bot processes (bot actor, chat instances, polling)
- adapter to use with [wisp](https://github.com/gleam-wisp/wisp)
- long polling with automatic retry and exponential backoff
- session bot implementation
- conversation implementation (multi-message flows)
- declarative single-message dialogs with widgets and sub-dialogs (`telega/dialog`, [guide](https://hexdocs.pm/telega/docs/dialogs.html))
- per-user flood control middleware (`router.with_rate_limit`)
- inline mode result builders with pagination (`telega/inline_mode`)
- payments helpers — Telegram Stars first-class (`telega/payments`)
- paid media — `sendPaidMedia` via `api.send_paid_media` / `reply.with_paid_media`
- production observability via [telemetry](https://hexdocs.pm/telemetry/) events (`telega/telemetry`)
- graceful shutdown via `telega.shutdown()`

## Quick start

> If you are new to Telegram bots, read the official [Introduction for Developers](https://core.telegram.org/bots) written by the Telegram team.

First, visit [@BotFather](https://t.me/botfather) to create a new bot. Copy **the token** and save it for later.

Initiate a gleam project and add `telega` as a dependency:

```sh
$ gleam new first_tg_bot
$ cd first_tg_bot
$ gleam add telega gleam_erlang telega_httpc
```

Replace the `first_tg_bot.gleam` file content with the following code:

```gleam
import gleam/erlang/process
import telega
import telega/reply
import telega/router
import telega/update
import telega_httpc

fn handle_text(ctx, text) {
  use ctx <- telega.log_context(ctx, "echo_text")
  let assert Ok(_) = reply.with_text(ctx, text)
  Ok(ctx)
}

fn handle_command(ctx, command: update.Command) {
  use ctx <- telega.log_context(ctx, "echo_command")
  let assert Ok(_) = reply.with_text(ctx, "Command: " <> command.text)
  Ok(ctx)
}

pub fn main() {
  let router = router.new("echo_bot")
  |> router.on_any_text(handle_text)
  |> router.on_commands(["start", "help"], handle_command)

  let client =
    telega_httpc.new("BOT_TOKEN")

  let assert Ok(_bot) =
    telega.new_for_polling(api_client: client)
    |> telega.with_router(router)
    |> telega.init_for_polling_nil_session()

  process.sleep_forever()
}
```

Replace `"BOT_TOKEN"` with the token you received from the BotFather. Then run the bot:

```sh
$ gleam run
```

And it will echo all received text messages.

Congratulations! You just wrote a Telegram bot :)

## Architecture

Calling `telega.init_for_polling()` (or `telega.init()` for webhooks) starts an OTP supervision tree:

```text
TelegaRootSupervisor (OneForOne)
├── ChatInstances (factory_supervisor, Transient children)
│   ├── ChatInstance {chat1:user1}
│   ├── ChatInstance {chat2:user2}
│   └── ...
├── Bot actor (Permanent)
└── Polling worker (Permanent) — only in polling mode
```

- **Bot actor** — dispatches incoming updates to the correct `ChatInstance` by `{chat_id}:{from_id}` key.
- **ChatInstance** — one per user-chat combination; holds session state and conversation continuations. Transient restart strategy means it restarts only on abnormal exit and re-registers itself in the ETS registry automatically.
- **Polling worker** — long-polls the Telegram API with exponential backoff on errors.

Each `telega.init*` call creates an independent tree with its own ETS registry, so multiple bot instances don't conflict.

### Graceful shutdown

```gleam
telega.shutdown(bot)
```

Sends an OTP `shutdown` signal to the root supervisor, which stops children in reverse start order (polling → bot → chat factory).

## Dependency injection

Handlers reach shared services — a database pool, an HTTP client, an i18n catalog — through the typed, non-persisted `dependencies` slot on `Context`. It is set once at init and is never serialized, unlike `session` (which holds per-user state):

```gleam
pub type Dependencies {
  Dependencies(db: Connection, catalog: Catalog)
}

telega.new_for_polling_with_dependencies(api_client: client, dependencies: Dependencies(db:, catalog:))
|> telega.with_router(router)
|> telega.init_for_polling()

// in any handler / flow step / middleware:
fn my_bookings(ctx: Context(Nil, String, Dependencies), _cmd) {
  let bookings = db.list_bookings(ctx.dependencies.db, ctx.update.from_id)
  reply.with_text(ctx, format_bookings(bookings))
}
```

Bots that need no services pay nothing: `dependencies` defaults to `Nil`. See the [Dependency injection guide](https://hexdocs.pm/telega/docs/dependency-injection.html).

## Testing

Telega ships with a testing toolkit under `telega/testing/` — mock clients, data factories, and a declarative conversation DSL. No real Telegram API calls needed.

```gleam
import telega/testing/conversation

pub fn greeting_flow_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Hello")
  |> conversation.send("Alice")
  |> conversation.expect_reply_containing("Alice")
  |> conversation.run(build_router(), fn() { MySession(name: "") })
}
```

See the full [Testing guide](https://hexdocs.pm/telega/docs/testing.html) for handler isolation, mock clients, media assertions, and more.

## Ecosystem

Telega is a monorepo. The core `telega` package is HTTP-client- and storage-agnostic; pick the adapters you need:

| Package | Purpose |
| --- | --- |
| [`telega_wisp`](https://github.com/bondiano/telega-gleam/tree/master/telega_wisp) | Wisp webhook adapter (endpoint handling, secret-token validation) |
| [`telega_mist`](https://github.com/bondiano/telega-gleam/tree/master/telega_mist) | Minimal webhook adapter directly over `mist`, without wisp |
| [`telega_httpc`](https://github.com/bondiano/telega-gleam/tree/master/telega_httpc) | HTTP client adapter over Erlang `httpc` |
| [`telega_hackney`](https://github.com/bondiano/telega-gleam/tree/master/telega_hackney) | HTTP client adapter over `hackney` |
| [`telega_storage_postgres`](https://github.com/bondiano/telega-gleam/tree/master/telega_storage_postgres) | PostgreSQL session/flow storage adapter |
| [`telega_storage_sqlite`](https://github.com/bondiano/telega-gleam/tree/master/telega_storage_sqlite) | SQLite session/flow storage adapter |
| [`telega_storage_redis`](https://github.com/bondiano/telega-gleam/tree/master/telega_storage_redis) | Redis/Valkey session/flow storage adapter |
| [`telega_webapp`](https://github.com/bondiano/telega-gleam/tree/master/telega_webapp) | Telegram Mini Apps (Web App) `initData` validation and helpers |
| [`telega_i18n`](https://github.com/bondiano/telega-gleam/tree/master/telega_i18n) | Internationalization: TOML/JSON catalogs, locale middleware, interpolation, CLDR pluralization |

## Examples

Progressive examples in the [examples](./examples) directory:

1. `00-echo-bot` — Basic echo with long polling
2. `01-commands-bot` — Command handling
3. `02-session-bot` — Stateful sessions
4. `03-conversation-bot` — Multi-message conversations
5. `04-keyboard-bot` — Inline keyboards and callbacks
6. `05-media-group-bot` — Media group handling
7. `06-restaurant-booking` — Full-featured application with flows and database

## Development

```sh
gleam build  # Build the project
gleam test   # Run the tests
gleam format # Format code
gleam shell  # Run an Erlang shell
```
