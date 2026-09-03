# Dependency Injection (`dependencies`)

How to give handlers access to shared services — a database pool, an HTTP
client, an i18n catalog, configuration — without globals and without abusing
the session.

## `session` vs `dependencies`

Every `Context` carries two distinct, typed slots:

| Slot      | Holds                              | Lifetime / scope            | Persisted? |
| --------- | ---------------------------------- | --------------------------- | ---------- |
| `session` | **user state** (cart, step, prefs) | per `{chat_id}:{from_id}`   | **Yes**    |
| `dependencies`    | **services** (db, http, catalog)   | whole bot, set once at init | **No**     |

```gleam
pub type Context(session, error, dependencies) {
  Context(
    // ...
    session: session,
    dependencies: dependencies,
    // ...
  )
}
```

The rule of thumb: if it describes *the user*, it goes in `session` and gets
persisted to your storage backend. If it is *a service the handler calls*, it
goes in `dependencies` — injected at startup, never serialized.

Putting services in `session` is a common anti-pattern: they leak into your
storage backend, complicate (de)serialization, and make handlers hard to test.
`dependencies` fixes that.

## Defining and injecting dependencies

Declare a type for your services and inject it with `telega.dependencies`:

```gleam
import telega

pub type Dependencies {
  Dependencies(db: Connection, catalog: Catalog)
}

pub fn start(client: TelegramClient, db: Connection, catalog: Catalog) {
  telega.new(client)
  |> telega.dependencies(Dependencies(db:, catalog:))
  |> telega.router(router)
  |> telega.start()
}
```

`dependencies` fixes the builder's `dependencies` type, which the router and the
other handlers are typed against — so it has to come **before** them. That is not
a convention you have to remember: the builder carries a state type parameter
(`telega.Fresh` until a handler is registered, `telega.Configured` afterwards)
and `dependencies` only accepts a `Fresh` builder. Calling it after
`telega.router` is a compile error:

```
Expected type:
    telega.TelegaBuilder(Nil, e, Nil, telega.Fresh)
Found type:
    telega.TelegaBuilder(Nil, e, Nil, telega.Configured)
```

`telega.session` works the same way, and for the same reason.

A bot that needs no services doesn't have to do anything: `dependencies` defaults
to `Nil`, so `telega.new` produces a `dependencies`-of-`Nil` builder and your
handlers see `Context(session, error, Nil)`.

## Reading dependencies in handlers

`dependencies` is available on every `Context`, so any handler — including flow steps,
middleware, and conversation `wait_*` continuations — can read it directly:

```gleam
fn my_bookings(ctx: Context(Nil, String, Dependencies), _cmd) {
  let bookings = db.list_bookings(ctx.dependencies.db, ctx.update.from_id)
  reply.with_text(ctx, format_bookings(bookings))
}
```

Or use the accessor `telega.get_dependencies(ctx)` when you prefer a function.

Because `dependencies` is just a field, it threads through the type system: your router
becomes `Router(session, error, Dependencies)`, your handlers
`Context(session, error, Dependencies)`, and the compiler guarantees every handler is
wired to the same `Dependencies`.

## Testing with mocked services

The testing builders let you substitute mock services with
`context_with_dependencies`:

```gleam
import telega/testing/context

pub fn my_bookings_test() {
  let ctx =
    context.context_with_dependencies(
      session: Nil,
      dependencies: Dependencies(db: mock_db(), catalog: test_catalog()),
    )

  let assert Ok(_) = my_bookings(ctx, command)
}
```

`context`, `context_with`, and `context_with_all` default `dependencies` to `Nil`;
`context_with_dependencies` (and the `dependencies:` argument on `context_with_all`) inject a
concrete value.

To drive a `dependencies`-bearing bot end-to-end through the actor system, the
integration helpers take a `dependencies` value:

```gleam
conversation.conversation_test()
|> conversation.send("/my_bookings")
|> conversation.expect_reply_containing("No bookings")
|> conversation.run_with_dependencies(build_router(), fn() { Nil }, Dependencies(db:, catalog:))

// or, with the bot subject directly:
handler.with_test_bot_with_dependencies(
  router: build_router(),
  session: fn() { Nil },
  dependencies: Dependencies(db:, catalog:),
  handler: fn(bot_subject, calls) { /* ... */ },
)
```

Need a custom mock client *and* dependencies, or full control over every input? Use the
dependencies-aware lower-level runners: `conversation.run_with_mock_with_dependencies` /
`conversation.run_with_client_with_dependencies`, and
`handler.with_test_bot_advanced_with_dependencies`.

## Reference

- `telega.dependencies(builder, dependencies)` — inject dependencies; only compiles before `telega.router` (see `telega.Fresh`).
- `telega.get_dependencies(ctx)` — read dependencies (same as `ctx.dependencies`).
- `telega/testing/context.context_with_dependencies(session:, dependencies:)` — build a test
  context with mock services.

See `examples/06-restaurant-booking` for a complete bot that injects a SQLite
connection and an i18n catalog through `dependencies`.
