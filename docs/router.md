# Router

The router is how Telega decides which handler runs for each incoming update. You
build one with `router.new`, attach handlers for the update types you care about,
and pass it to the bot with `telega.router`.

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
arguments. The leading slash is optional — `"start"` and `"/start"` are
equivalent — and matching is case-insensitive, so `/Start` reaches
`on_command("start", ...)`. The command name ends at the first whitespace of
any kind: `/start\nref=42` is the command `start` with the payload `ref=42`.

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

### Typed callback routes

A `keyboard.KeyboardCallbackData` factory already knows how to build and parse
its own payloads. `on_callback_data` registers a route for exactly those
payloads and hands the handler the decoded value:

```gleam
let page = keyboard.int_callback_data("page")

router
|> router.on_callback_data(page, fn(ctx, _query, page_number) {
  // page_number: Int — no unpack_callback, no error handling in the handler
  reply.with_text(ctx, "Page " <> int.to_string(page_number))
})
```

A payload belonging to another factory, or one the factory cannot deserialize,
never reaches the handler — it leaves the context untouched rather than handing
you a `0`/`False` stand-in.

## Media

```gleam
router
|> router.on_photo(handle_photo)            // List(PhotoSize)
|> router.on_video(handle_video)            // Video
|> router.on_voice(handle_voice_message)    // Voice
|> router.on_audio(handle_audio_file)       // Audio
|> router.on_media_group(handle_album)      // media group id + List(Message)
```

Telegram delivers an album as separate messages sharing a `media_group_id`, so
`on_media_group` only fires when the bot asks for them to be gathered:

```gleam
telega.new(api_client)
|> telega.router(router)
// hold an album's messages until 1s passes without another one
|> telega.with_media_group_timeout(1000)
```

Without it, each message of an album arrives on its own `on_photo` / `on_video`
/ `on_audio` route. With it, they arrive together on `on_media_group` and not
individually. Messages that arrive while a `wait_*` conversation is pending are
never gathered — the waiting handler expects them one at a time.

## Specialized routes

Dedicated handlers exist for the rest of the Telegram update types:

- **Inline mode** — `on_inline_query`, `on_chosen_inline_result`
- **Payments** — `on_shipping_query`, `on_pre_checkout_query`
- **Polls** — `on_poll`, `on_poll_answer`
- **Reactions** — `on_reaction`, `on_reaction_emoji`, `on_reaction_emojis`,
  `on_paid_reaction`, `on_reaction_added`, `on_reaction_removed`, `on_reaction_count`
- **Chat events** — `on_chat_member_updated` (another member's status changed),
  `on_my_chat_member_updated` (the *bot's own* status changed: blocked,
  unblocked, added to a group, promoted), `on_chat_join_request`,
  `on_chat_boost`, `on_removed_chat_boost`
- **Messages that aren't new messages** — `on_edited_message`,
  `on_channel_post`, `on_edited_channel_post`, `on_business_message`
  (all receive a `Message`)
- **Mini Apps** — `on_web_app_data` (`WebAppData` from `sendData`)
- **Paid media** — `on_paid_media_purchase`
- **Anything else** — `on_unknown_update` receives an `UnknownUpdate`: a Bot API
  kind this version does not know, or one whose payload failed to decode. Read
  the raw payload with `update.raw`. Registering it turns off `allowed_updates`
  narrowing, since an unknown kind can never be in a derived set.

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
`command_equals`), user/chat filters (`from_user`, `from_users`, `in_chat`,
`from_chats`, `is_private_chat`, `is_group_chat`, `chat_type`,
`callback_data_starts_with`), and message-content filters (`is_forwarded`,
`is_reply`, `in_topic`, `has_entity`, `via_bot`, `via_bot_id`,
`is_automatic_forward`, `has_media_spoiler`).

The message-content filters read the update's own `Message` through
`update.message`, which is `None` for updates that are not about a message
(callback queries, inline queries, polls, member changes) — those match none of
them. `has_entity` searches both `entities` and `caption_entities`, so a
captioned photo with a link matches `has_entity("url")` just as a text message
does. The full table is in the
[`telega/router` module docs](https://hexdocs.pm/telega/telega/router.html).

`from_user` / `from_users` match on the update's sender whatever its kind.
`is_private_chat` / `is_group_chat` / `chat_type` read the chat's own `type_`
via `update.chat`, so an update that happens in no chat at all — an inline
query, a poll answer — matches none of them, rather than being classified by
the sign of its stand-in `chat_id`.
Combine them with `and`/`and2`, `or`/`or2`, and `not`, or build your own with
`filter`.

`from_users` / `from_chats` are whitelists; wrap them in `not` for a blacklist:

```gleam
// Only react in the support chats:
router.on_filtered(router.from_chats([support_a, support_b]), handler)
// React everywhere except a banned chat:
router.on_filtered(router.not(router.from_chats([banned_chat])), handler)
```

### Role filters (`is_admin` / `is_owner`)

Filters are pure predicates over the update, so they can't make API calls.
Role checks need `getChatMember`, so they live in [`telega/roles`](https://hexdocs.pm/telega/telega/roles.html),
which caches results in ETS (one round-trip is too slow to repeat per message).
It exposes booleans (`is_admin` / `is_owner`), `use`-friendly guards
(`ensure_admin` / `ensure_owner`), and router middleware (`require_admin` /
`require_owner`):

```gleam
import telega/roles

let cache = roles.new_cache(ttl_ms: 60_000)

router.new("admin")
|> router.on_command("ban", fn(ctx, _cmd) {
  use ctx <- roles.ensure_admin(ctx, cache, on_denied: fn(ctx) {
    reply.with_text(ctx, "Admins only.")
  })
  // ... only reached for admins/owner ...
  Ok(ctx)
})
```

"Admin" means administrator or owner; "owner" means the chat creator. Checks
fail closed (access denied) on an API error. Pass `ttl_ms: 0` to disable caching.

## Middleware

Middleware wraps handlers with cross-cutting behavior. The first one added is
the outermost, so it runs first and sees the handler's result last:

```gleam
router
|> router.use_middleware(router.with_logging)     // outermost, runs first
|> router.use_middleware(auth_middleware)
|> router.use_middleware(rate_limit_middleware)   // innermost, closest to the handler
```

Built-ins: `with_logging`, `with_filter`, `with_recovery`, and `with_rate_limit`.

## Pre-router middleware

Router middleware runs *per router*, after an update has been dispatched to a
chat instance and a session loaded. For cross-cutting concerns that apply to
**every** update — anti-spam, analytics, deduplication — register a *pre-router*
middleware with `telega.use_pre_handler`. It runs once per update inside the bot
actor, **before** routing and before any chat instance is spawned, so it is
cheaper and can drop an update outright:

```gleam
import telega
import telega/bot

telega.new(api_client)
|> telega.use_pre_handler(fn(pre: bot.PreContext(deps)) {
  case is_banned(pre.update.chat_id) {
    True -> bot.Stop        // drop before routing
    False -> bot.proceed()  // let it through
  }
})
|> telega.router(router)
```

Pre-handlers run in registration order; the first `bot.Stop` short-circuits the
rest and the router. A `PreContext` carries the `update`, `config`,
`dependencies`, `bot_info`, and the `annotations` earlier pre-handlers set — but
no `session` (it hasn't been loaded yet). Because they all run sequentially in
the single bot actor, read-then-write logic is race-free across concurrent
updates.

### Annotations

A pre-handler can attach per-update facts for the handlers downstream by
returning `bot.Continue(annotations:)` instead of `bot.proceed()`. Annotations
from successive pre-handlers are merged (a repeated key takes the newer value)
and arrive in every handler as `ctx.annotations`, read back with
`bot.annotation`:

```gleam
import gleam/dict
import gleam/dynamic
import gleam/dynamic/decode
import gleam/result

telega.new(api_client)
|> telega.use_pre_handler(fn(pre: bot.PreContext(deps)) {
  bot.Continue(annotations: dict.from_list([
    #("locale", dynamic.string(resolve_locale(pre.update))),
  ]))
})

// ... in any handler
let locale =
  bot.annotation(ctx, "locale", decode.string)
  |> result.unwrap("en")
```

Annotations live for one update and are never persisted — long-lived services
belong in `dependencies`, per-user state in the session.

### Webhook idempotency (deduplication)

Telegram re-delivers an update (same `update_id`) when it doesn't get a `200` in
time — on a slow response, a redeploy, or a network blip. That double-runs
non-idempotent commands (sending an invoice, charging Stars). The
[`telega/idempotency`](https://hexdocs.pm/telega/telega/idempotency.html) module
provides a ready-made pre-router middleware that remembers each `update_id` in a
[`KeyValueStorage`](https://hexdocs.pm/telega/telega/storage.html) for a TTL
window and drops duplicates:

```gleam
import telega/idempotency
import telega/storage/ets

let assert Ok(store) = ets.new(name: "telega_dedup")

telega.new(api_client)
|> telega.webhook(url:, path:, secret_token:)
|> telega.use_pre_handler(idempotency.deduplicate(storage: store, ttl_ms: 3600_000))
|> telega.router(router)
```

Use a persistent backend (Postgres/SQLite/Redis) when running more than one node
or to survive restarts. On a storage error the update is let through (fail-open):
processing twice is recoverable, dropping a real update is not.

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

There are two types, and they do different jobs.

- `router.Router` is a **leaf**: routes, middleware, a catch handler, a scope.
  Everything named `on_*` registers on a leaf, and `telega.router` takes one.
- `router.RouterTree` is a **composition**: an ordered list of leaves, some of
  them guarded by a filter. It has no routes of its own — `on_command` on a tree
  does not compile — and `telega.router_tree` takes one.

**Merge** combines two leaves into one flat leaf; the first wins on conflicts:

```gleam
let main = router.merge(admin_router, user_router)
```

**A tree** tries each leaf in order, each keeping its own middleware and catch
handler. `append` adds a leaf that is always consulted; `branch` adds one that is
only consulted when a filter matches:

```gleam
let app =
  router.tree()
  |> router.branch(router.is_private_chat(), private_router)
  |> router.branch(router.is_group_chat(), group_router)
  |> router.append(shared_router)
  |> router.tree_fallback(handle_unknown)

telega.new(api_client)
|> telega.router_tree(app)
```

`compose(a, b)` and `compose_many([a, b, c])` are shorthand for a tree of
unconditional branches.

A branch whose filter matches but which has no route for the update is skipped,
so the next branch gets its turn. Routes that used to be registered *on* a
composition now go into an explicit trailing leaf:

```gleam
// `/help` is handled after `private_router` and `public_router` decline it
let app =
  router.compose(private_router, public_router)
  |> router.append(router.new("direct") |> router.on_command("help", handle_help))
```

Settings that belong to each branch rather than to one of them have tree-level
forms: `use_middleware_on_tree` and `with_catch_handler_on_tree` (the latter
leaves a branch that already has its own catch handler alone).

**Scope** restricts a leaf to updates matching a predicate. A scoped leaf
declines updates outside its scope, so in a tree the next branch gets
its turn:

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

telega.new(api_client)
|> telega.router(router)
|> telega.with_auto_commands()
|> telega.start()
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

telega.new(api_client)
|> telega.router(router)
|> i18n.with_command_translations(catalog, prefix: "commands.")
|> telega.start()
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
telega.new(api_client)
|> telega.router(router)
|> telega.with_auto_allowed_updates()
|> telega.start()
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
| `on_my_chat_member_updated` | `my_chat_member` |
| `on_chat_join_request` | `chat_join_request` |
| `on_chat_boost` / `on_removed_chat_boost` | `chat_boost` / `removed_chat_boost` |
| `on_edited_message` | `edited_message` |
| `on_channel_post` / `on_edited_channel_post` | `channel_post` / `edited_channel_post` |
| `on_business_message` | `business_message` |
| `on_web_app_data` | `message` |
| `on_paid_media_purchase` | `purchased_paid_media` |

`router.allowed_updates(router)` returns the derived list directly;
`router.tree_allowed_updates(tree)` does the same for a composition (one branch
that gives up on narrowing gives up for the whole tree).

**A narrowed set always admits `callback_query`.** Derivation only sees the
router, and a handler that parks on `bot.wait_callback` is invisible to it — a
bot whose router registers only commands used to derive `["message"]` and then
wait forever. `callback_query` is therefore always in a non-empty derived set;
allowing it costs nothing when unused, because Telegram only sends callback
queries for keyboards the bot itself put on screen.

Other kinds a conversation or flow waits for are still invisible. Add them
explicitly:

```gleam
|> telega.with_auto_allowed_updates()
|> telega.with_extra_allowed_updates(["message_reaction"])
```

**Escape hatches.** A manual `telega.with_allowed_updates(builder, updates)` always
wins; auto derivation is skipped entirely. And if the router has a **fallback**,
**custom**, **filtered**, or **`on_unknown_update`** route — which can match any
update — the set can't be narrowed safely, so derivation returns the empty list
and Telegram falls back to its default update set
(`with_extra_allowed_updates` is a no-op in that case). Use
`with_allowed_updates` when you need narrowing alongside catch-all routes.
