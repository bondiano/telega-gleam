# Migration: builder API v3

v3 replaces the bot builder. The old entry points are **gone** — there is no
`telega/compat` module and no deprecation period, so this is a single mechanical
pass over the code that constructs your bot. Handlers, routers, sessions, flows,
dialogs and everything else are untouched.

Three things changed:

1. **One constructor.** `telega.new(api_client)`. The webhook/polling choice is
   an explicit step (`telega.webhook(...)` / `telega.polling(...)`), not a pair
   of constructors and a pair of `init` functions.
2. **One prefix per role.** The pipeline steps are bare verbs (`dependencies`,
   `session`, `router`, `router_tree`, `polling`, `webhook`, `start`,
   `supervised`); everything optional is `with_*`. All `set_*` functions are
   gone.
3. **The `with_dependencies` footgun is a compile error.** `dependencies` and
   `session` fix type parameters the router is typed against, so they now only
   accept a builder that has no handlers registered yet.

## The shape of a v3 bot

```gleam
telega.new(api_client)
|> telega.dependencies(Dependencies(db:, catalog:))  // optional
|> telega.session(session_settings)                  // optional → Nil session
|> telega.router(router)
|> telega.polling(polling.default_settings())        // optional → this is the default
|> telega.start()
```

Webhook mode is the same pipeline with one step swapped:

```gleam
telega.new(api_client)
|> telega.webhook(url: "https://bot.example.com", path: "webhook", secret_token: Some(secret))
|> telega.router(router)
|> telega.start()
```

## Rename table

| v2 | v3 |
| --- | --- |
| `telega.new_for_polling(api_client:)` | `telega.new(api_client)` |
| `telega.new(api_client:, url:, webhook_path:, secret_token:)` | `telega.new(api_client)` + `telega.webhook(url:, path:, secret_token:)` |
| `telega.new_for_polling_with_dependencies(api_client:, dependencies:)` | `telega.new(api_client)` + `telega.dependencies(deps)` |
| `telega.new_with_dependencies(...)` | `telega.new(api_client)` + `telega.webhook(...)` + `telega.dependencies(deps)` |
| `telega.with_dependencies(deps)` | `telega.dependencies(deps)` |
| `telega.with_router(router)` | `telega.router(router)` |
| `telega.with_router_tree(tree)` | `telega.router_tree(tree)` |
| `telega.with_session_settings(settings)` | `telega.session(settings)` |
| `telega.with_nil_session()` | *(delete the call — `Nil` is the default)* |
| `telega.init()` / `telega.init_for_polling()` | `telega.start()` |
| `telega.init_for_polling_nil_session()` | `telega.start()` |
| `telega.supervised()` / `telega.supervised_for_polling()` | `telega.supervised()` |
| `telega.with_polling_config(timeout:, limit:, poll_interval:)` | `telega.polling(polling.PollingSettings(..polling.default_settings(), timeout:, limit:, poll_interval:))` |
| `telega.with_polling_on_stop(f)` | the `on_stop` field of `polling.PollingSettings` |
| `telega.with_chat_config(restart_tolerance_intensity:, restart_tolerance_period:, init_timeout:)` | `telega.with_chat_restart_tolerance(intensity:, period:)` + `telega.with_chat_init_timeout(ms)` |
| `telega.set_allowed_updates(updates)` | `telega.with_allowed_updates(updates)` |
| `telega.set_drop_pending_updates(bool)` | `telega.with_drop_pending_updates(bool)` |
| `telega.set_max_connections(n)` | `telega.with_max_connections(n)` |
| `telega.set_ip_address(ip)` | `telega.with_ip_address(ip)` |
| `telega.set_certificate(file)` | `telega.with_certificate(file)` |
| `telega.set_api_client(client)` | *(removed — pass the client to `telega.new`)* |

Everything else (`with_catch_handler`, `use_pre_handler`, `with_session_key`,
`with_session_persistence`, `with_session_load_error`, `with_chat_idle_timeout`,
`without_chat_idle_timeout`, `with_chat_hibernate_after`,
`without_chat_hibernation`, `with_media_group_timeout`, `with_on_start`,
`with_on_shutdown`, `with_drain_timeout`, `with_signal_handlers`,
`with_auto_commands`, `with_command_translations`, `with_auto_allowed_updates`,
`with_extra_allowed_updates`) keeps its name and meaning.

## Ordering: `dependencies` and `session` come first

`TelegaBuilder` gained a fourth type parameter — a state marker. It is
`telega.Fresh` on a new builder and `telega.Configured` once anything typed
against `session`/`dependencies` is registered (`router`, `router_tree`,
`with_catch_handler`, `use_pre_handler`, `with_on_start`). `dependencies` and
`session` only accept a `Fresh` builder.

In v2, calling `with_dependencies` after `with_router` silently reset the router
and you got a bot with no routes and no error. In v3 that same code does not
compile:

```
Expected type:
    telega.TelegaBuilder(Nil, e, Nil, telega.Fresh)
Found type:
    telega.TelegaBuilder(Nil, e, Nil, telega.Configured)
```

The fix is always the same: move `dependencies` / `session` above the handler
steps. Optional `with_*` settings can go anywhere.

If you wrapped the builder in a helper of your own, give it the extra parameter:

```gleam
// v2
fn attach(builder: telega.TelegaBuilder(session, error, dependencies)) { ... }

// v3
fn attach(builder: telega.TelegaBuilder(session, error, dependencies, state)) { ... }
```

A helper that calls `telega.session` or `telega.dependencies` has to name the
state explicitly instead, since it only works on a fresh builder:

```gleam
fn attach(builder: telega.TelegaBuilder(old, error, dependencies, telega.Fresh)) { ... }
```

## `with_chat_config` split in two

The three-argument `with_chat_config` is gone. Restart tolerance is
`telega.with_chat_restart_tolerance(intensity:, period:)` (default: 5 restarts in
10 seconds), and the init timeout is `telega.with_chat_init_timeout(ms)` — how
long a chat instance may take to start, which includes loading its session from
storage (default: 10 000 ms). The name now says exactly what the value bounds.

## One way to get a `Nil` session

v2 had three (`with_nil_session`, `init_for_polling_nil_session`, and passing
nil-ish `with_session_settings`). v3 has none: a builder starts with a session
that stores nothing and reads back `Nil`, and `telega.session(settings)` replaces
it. Delete the nil-session calls; a bot that never calls `telega.session` is a
`Nil`-session bot.

`telega.start()` therefore no longer fails for a missing session, and
`error.NoSessionSettingsError` — which nothing could return any more — was
removed from `error.TelegaError`. A `case` over that type that listed it needs
the arm deleted. `start` still fails with `error.RouterError` when no router was
set.

## Errors from your handlers

Unchanged, but worth repeating while you are touching startup code: your `error`
type is generic, while `reply.*` and `api.*` return `error.TelegaError`. The
recommended shape for a bot that also talks to a database is one wrapper type
plus `error.try`:

```gleam
pub type BotError {
  Api(error.TelegaError)
  Db(pog.QueryError)
}

fn handler(ctx, _cmd) {
  use ctx <- error.try(reply.with_text(ctx, "hi"), to: Api)
  Ok(ctx)
}
```

## Checklist

1. Replace the constructor and add `telega.webhook(...)` if you are on webhooks.
2. `with_router` → `router`, `with_session_settings` → `session`,
   `with_dependencies` → `dependencies`; drop `with_nil_session`.
3. Move `dependencies` / `session` above `router`.
4. `init*` → `start`, `supervised_for_polling` → `supervised`.
5. `set_*` → `with_*`; `with_polling_config`/`with_polling_on_stop` →
   `telega.polling(polling.PollingSettings(..))`; `with_chat_config` → the two
   new chat functions.
6. Add the fourth type parameter to any helper that mentions `TelegaBuilder`.
