# Router

The router is how Telega decides which handler runs for each incoming update. You
build one with `router.new`, attach handlers for the update types you care about,
and pass it to the bot with `telega.with_router`.

```gleam
import telega/router
import telega/reply

let router =
  router.new("my_bot")
  |> router.on_command("start", handle_start)
  |> router.on_command("help", handle_help)
  |> router.on_any_text(handle_text)
  |> router.on_photo(handle_photo)
  |> router.fallback(handle_unknown)
```

Every handler has the same shape — it receives the context (with the current
session) and the update-specific payload, and returns the updated context:

```gleam
fn handle_start(ctx, _command: update.Command) {
  use _ <- try(reply.with_text(ctx, "Welcome!"))
  Ok(ctx)
}
```

`reply.with_text` returns `Result(Message, _)`, so chain it with `use _ <- try(...)`
(from `gleam/result`) and return the context yourself.

## Routing priority

For each update the router tries routes in this order, and the first match wins:

1. **Commands** — exact matches like `/start`, `/help`
2. **Callback queries** — button presses, matched by callback data
3. **Custom routes** — your own matcher functions
4. **Media routes** — photo, video, voice, audio, media groups
5. **Text routes** — pattern matching on message text
6. **Specialized routes** — inline queries, polls, payments, reactions, chat events
7. **Fallback** — catch-all for anything unmatched

Within a category routes are tried in registration order.

## Commands

```gleam
router
|> router.on_command("start", handle_start)
|> router.on_commands(["help", "about"], show_info)  // one handler, many commands
```

Command handlers receive a parsed `update.Command` with the command name and any
arguments. The leading slash is optional — `"start"` and `"/start"` are equivalent.

To make a command show up in the Telegram command menu, register it with a
description (see [Command & update auto-sync](#command--update-auto-sync)):

```gleam
router
|> router.on_command_with_description("start", "Start the bot", handle_start)
```

## Text and patterns

Text routes match on the message body using a `Pattern`:

```gleam
router
|> router.on_text(router.Exact("hello"), handle_hello)
|> router.on_text(router.Prefix("search:"), handle_search)
|> router.on_text(router.Contains("help"), handle_help_mention)
|> router.on_text(router.Suffix("?"), handle_question)
|> router.on_any_text(handle_any_text)  // every text message
```

Text handlers receive the message text as a `String`.

## Callback queries

Button presses are matched on their callback data, with the same `Pattern` type:

```gleam
router
|> router.on_callback(router.Prefix("page:"), handle_pagination)
|> router.on_callback(router.Exact("cancel"), handle_cancel)
```

Callback handlers receive the callback query id and the data string.

## Media

```gleam
router
|> router.on_photo(handle_photo)            // List(PhotoSize)
|> router.on_video(handle_video)            // Video
|> router.on_voice(handle_voice_message)    // Voice
|> router.on_audio(handle_audio_file)       // Audio
|> router.on_media_group(handle_album)      // media group id + List(Message)
```

## Specialized routes

Dedicated handlers exist for the rest of the Telegram update types:

- **Inline mode** — `on_inline_query`, `on_chosen_inline_result`
- **Payments** — `on_shipping_query`, `on_pre_checkout_query`
- **Polls** — `on_poll`, `on_poll_answer`
- **Reactions** — `on_reaction`, `on_reaction_emoji`, `on_reaction_emojis`,
  `on_paid_reaction`, `on_reaction_added`, `on_reaction_removed`, `on_reaction_count`
- **Chat events** — `on_chat_member_updated`, `on_chat_join_request`

```gleam
router
|> router.on_inline_query(handle_inline)
|> router.on_pre_checkout_query(handle_pre_checkout)
|> router.on_reaction_emojis(["👍", "🔥"], handle_thumbs_up)
|> router.on_chat_join_request(handle_join_request)
```

## Custom routes and filters

For logic that doesn't fit the built-in categories, use a custom matcher:

```gleam
router
|> router.on_custom(
  matcher: fn(update) {
    case update {
      update.TextUpdate(text: t, ..) -> string.starts_with(t, "https://")
      _ -> False
    }
  },
  handler: handle_link,
)
```

Filters are composable predicates over updates:

```gleam
router
|> router.on_filtered(router.is_private_chat(), handle_private)
|> router.on_filtered(router.from_user(admin_id), handle_admin)
|> router.on_filtered(
  router.and([
    router.is_text(),
    router.from_users([admin1, admin2]),
    router.not(router.text_starts_with("/")),
  ]),
  handle_admin_text,
)
```

Available predicates include message-type filters (`is_text`, `is_command`,
`has_photo`, `has_video`, `has_media`, `is_media_group`, `is_callback_query`),
text-content filters (`text_equals`, `text_starts_with`, `text_contains`,
`command_equals`), and user/chat filters (`from_user`, `from_users`, `in_chat`,
`is_private_chat`, `is_group_chat`, `callback_data_starts_with`). Combine them
with `and`/`and2`, `or`/`or2`, and `not`, or build your own with `filter`.

## Middleware

Middleware wraps handlers with cross-cutting behavior. It is applied in reverse
order of addition, so the last added runs first (outermost):

```gleam
router
|> router.use_middleware(router.with_logging)
|> router.use_middleware(auth_middleware)
|> router.use_middleware(rate_limit_middleware)
```

Built-ins: `with_logging`, `with_filter`, `with_recovery`, and `with_rate_limit`.

## Error handling

A route handler that returns `Error` is passed to the router's catch handler, if
set. `fallback` handles updates that no route matched.

```gleam
router
|> router.with_catch_handler(fn(error) {
  log.error("Route error: " <> string.inspect(error))
  Error(error)
})
|> router.fallback(handle_unknown)
```

The catch handler receives only the `error` (no context) and returns
`Result(Context, error)` — log and re-raise with `Error(error)`, or recover with a
context you already hold in scope.

The router's catch handler only handles errors from route handlers. System-level
errors (like session persistence) go to the bot's catch handler configured via
`telega.with_catch_handler`.

## Composition

Routers compose, so you can build complex routing from small pieces.

**Merge** combines two routers into one flat router; the first wins on conflicts:

```gleam
let main = router.merge(admin_router, user_router)
```

**Compose** tries each sub-router in sequence, each keeping its own middleware and
catch handler:

```gleam
let app = router.compose(private_router, public_router)
let app = router.compose_many([admin, moderator, user])
```

**Scope** restricts a router to updates matching a predicate:

```gleam
let admin =
  router.new("admin")
  |> router.on_command("ban", handle_ban)
  |> router.scope(fn(update) {
    case update {
      update.CommandUpdate(from_id: id, ..) -> is_admin(id)
      _ -> False
    }
  })
```

## Command & update auto-sync

Because the router already knows every command and update type the bot handles,
Telega can keep Telegram in sync with it automatically — no hand-maintained
`setMyCommands` list and no `allowed_updates` that drifts out of date. All of this
is opt-in, with manual escape hatches.

### Publishing commands on start

Register commands with `on_command_with_description` and enable
`telega.with_auto_commands`. On startup — after the supervision tree is up and
before your `with_on_start` hook — Telega calls `setMyCommands` with every
described command:

```gleam
let router =
  router.new("my_bot")
  |> router.on_command_with_description("start", "Start the bot", handle_start)
  |> router.on_command_with_description("help", "Show help", handle_help)
  |> router.on_command("secret", handle_secret)
  // ^ no description → still routed, but not published

telega.new_for_polling(api_client:)
|> telega.with_router(router)
|> telega.with_auto_commands()
|> telega.init_for_polling()
```

Commands added with plain `on_command` are skipped. If nothing has a description,
no API call is made. `router.registered_commands(router)` returns the
`#(command, description)` pairs if you want to inspect them yourself.

### Localized descriptions with `telega_i18n`

Put the descriptions in a `telega_i18n` catalog under a common prefix and wire them
in with `telega_i18n.with_command_translations`. It implies `with_auto_commands`:
the default-language menu is published first, then one
`setMyCommands(language_code:)` call per catalog locale.

```toml
# locales/en.toml
[commands]
start = "Start the bot"
help = "Show help"
```

```toml
# locales/ru.toml
[commands]
start = "Запустить бота"
help = "Показать справку"
```

```gleam
import telega
import telega_i18n as i18n

let assert Ok(catalog) =
  i18n.new("en")
  |> i18n.load_toml_dir("locales")

telega.new_for_polling(api_client:)
|> telega.with_router(router)
|> i18n.with_command_translations(catalog, prefix: "commands.")
|> telega.init_for_polling()
```

The description for command `start` is looked up at `commands.start`, honoring the
catalog's fallback chains. A missing key falls back to the description the command
was registered with on the router.

If you are not using `telega_i18n`, supply the translator yourself:

```gleam
telega.with_command_translations(
  builder,
  locales: ["en", "ru"],
  translate: fn(command, locale) {
    // `Some(description)` to override, `None` to keep the router default
    my_lookup(command, locale)
  },
)
```

### Deriving `allowed_updates`

Enable `telega.with_auto_allowed_updates` and Telega requests only the update
types the router can handle, cutting traffic for everything else:

```gleam
telega.new_for_polling(api_client:)
|> telega.with_router(router)
|> telega.with_auto_allowed_updates()
|> telega.init_for_polling()
```

Route → update type mapping:

| Routes | `allowed_updates` |
| --- | --- |
| commands, text, photo/video/voice/audio, media groups | `message` |
| callback handlers | `callback_query` |
| `on_inline_query` | `inline_query` |
| `on_chosen_inline_result` | `chosen_inline_result` |
| `on_shipping_query` | `shipping_query` |
| `on_pre_checkout_query` | `pre_checkout_query` |
| `on_poll` / `on_poll_answer` | `poll` / `poll_answer` |
| reaction handlers | `message_reaction` |
| `on_reaction_count` | `message_reaction_count` |
| `on_chat_member_updated` | `chat_member` |
| `on_chat_join_request` | `chat_join_request` |

`router.allowed_updates(router)` returns the derived list directly.

**Escape hatches.** A manual `telega.set_allowed_updates(builder, updates)` always
wins; auto derivation is skipped entirely. And if the router has a **fallback**,
**custom**, or **filtered** route — which can match any update — the set can't be
narrowed safely, so derivation returns the empty list and Telegram falls back to
its default update set. Use `set_allowed_updates` when you need narrowing alongside
catch-all routes.
