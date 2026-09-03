# Session Storage

How to persist session state in Telega bots.

> Sessions are for **user state**. Shared services (a db pool, http client, i18n
> catalog) belong in the non-persisted `dependencies` slot instead — see the
> [Dependency Injection guide](https://hexdocs.pm/telega/docs/dependency-injection.html).
> Don't put services in `session`: they would be serialized to your storage backend.

## Overview

Telega sessions are keyed by `"{chat_id}:{from_id}"` and configured via `SessionSettings`:

```gleam
pub type SessionSettings(session, error) {
  SessionSettings(
    // Save session after each handler call.
    persist_session: fn(String, session) -> Result(session, error),
    // Load session on chat instance init. Return `None` if not found.
    get_session: fn(String) -> Result(Option(session), error),
    // Provide a default when no session exists (or on load error).
    default_session: fn() -> session,
  )
}
```

If `get_session` returns an `Error`, the chat instance **refuses to start**: the
update is answered as unhandled and the next one gets a fresh attempt. Falling
back to `default_session()` would let the first handler persist that default
over the user's real, still-stored data. `default_session()` is used only for
`Ok(None)` — a user who genuinely has no session yet.

A stored value that will not *decode* is a different case: the bridge in
`telega/storage` treats it as absent so the bot keeps working, but reports it
first with an error log and a `telega.storage.decode_error` telemetry event.
The next persist overwrites it, which is usually what a schema change wants.

## When the session is written

By default a session is written back only when a handler **changed** it: if the
handler returns the session it was given, `persist_session` is not called at
all. Most updates read the session without touching it, so for most bots this
is most of the storage writes — and skipping them is safe by definition, since
what is stored is already the value that would be written.

Switch it off when the write itself does something you rely on — refreshing an
expiry, touching a "last seen" column:

```gleam
telega.new_for_polling(api_client:)
|> telega.with_session_settings(settings)
|> telega.with_session_persistence(bot.PersistAlways)
```

## When the session cannot be read

A read that *failed* is not the same as "this user has no session yet". By
default (`bot.FailUpdate`) the chat instance refuses to start: the update is
reported unhandled and nothing is written, because serving it on a default
session would let the first handler persist that default over the real,
still-stored data.

```gleam
telega.new_for_polling(api_client:)
|> telega.with_session_settings(settings)
|> telega.with_session_load_error(bot.ReadOnly)
```

- `bot.FailUpdate` (default) — drop the update, keep the stored session.
- `bot.ReadOnly` — handlers run on the default session and every write is
  skipped with a warning. The bot keeps answering while the backend is down,
  and the stored session is still there when it comes back.
- `bot.UseDefault` — handlers run on the default session and write normally.
  Only when losing a session costs less than dropping the update.

Either fallback emits `telega.session.load_error` telemetry with the policy
that was applied.

A **write** that fails is different again: the value the handler returned stays
in memory and is written again on the next update, even under
`PersistOnChange`, so a transient backend failure costs one update rather than
the change.

## What the key identifies

The default key is `"{chat_id}:{from_id}"`, and a few update kinds map onto it in ways
worth knowing before you store anything sensitive per key:

- **Anonymous group admins** post as the chat itself, so `from_id` is the
  group's id and every anonymous admin of that group shares one session.
- **Callback queries on inline-mode messages** have no chat, so they are keyed
  `"{from_id}:{from_id}"` — a *different* session from the same user's private
  chat with the bot.
- **Chat-wide updates with no user** (`message_reaction_count`, a deleted
  business message, a removed chat boost) are keyed `"{chat_id}:{chat_id}"`.
- **Updates with no user or chat at all** (`poll`, a stopped message-draft
  generation) use `-1` for both, so they all share one session.

If per-user isolation matters for one of these, key your own storage on
something you derive from the update rather than on `ctx.key`.

## Choosing the key

`telega.with_session_key` decides what an update is keyed by — its session
*and* the chat instance that handles it. Two updates with the same key share
one process and one session, so the key decides both isolation and
concurrency.

```gleam
telega.new_for_polling(api_client:)
|> telega.with_session_key(bot.chat_session_key)
```

| Key function | Key | One session per |
|---|---|---|
| `bot.default_session_key` | `"{chat_id}:{from_id}"` | user, per chat |
| `bot.chat_session_key` | `"chat:{chat_id}"` | chat, shared by its members |
| `bot.user_session_key` | `"user:{from_id}"` | user, across every chat |

Anything else is a plain function of the update — one session per forum topic,
per business connection, per language:

```gleam
telega.with_session_key(builder, fn(update) {
  case update.thread_id {
    Some(thread) ->
      int.to_string(update.chat_id) <> ":t" <> int.to_string(thread)
    None -> bot.default_session_key(update)
  }
})
```

`bot.chat_session_key` also serializes the chat: every member's update goes
through one instance, which is what makes a read-modify-write on the shared
session safe.

## State that is not the session

A session belongs to one chat instance and is loaded once when it starts —
wrong for anything several instances share. A group's counter written by one
member would be invisible to another member's instance until it restarted.

`telega/store` is that other shape: a typed view of one key-space, read and
written straight through to the backend, never cached.

```gleam
import telega/store

let counters =
  store.chat_data(
    storage: kv,
    encode: json.int,
    decode: decode.int,
    default: fn() { 0 },
  )

fn handle_message(ctx, _text) {
  use total <- result.try(store.update(ctx, counters, fn(n) { n + 1 }))
  reply.text(ctx, "messages here: " <> int.to_string(total))
}
```

| Constructor | Key | Scope |
|---|---|---|
| `store.chat_data` | `data:chat:{chat_id}` | the chat |
| `store.user_data` | `data:user:{from_id}` | the user, across chats |
| `store.global_data(name:)` | `data:global:{name}` | the whole bot |
| `store.custom(key:)` | whatever you return | your call |

A store is a plain value: build it at startup, put it in `dependencies`, and
hand it to the handlers that need it. `store.with_ttl` expires written values;
`store.get_at` / `set_at` / `update_at` / `delete_at` reach a key with no
`Context` to derive one from (a job, an admin command reading another chat).

`store.update` is read-modify-write and **not atomic** — two instances updating
the same key at once can lose one of the changes. Where that matters, key the
session by chat instead and let the single instance serialize the members.

## Unified Storage Interface

`SessionSettings` (sessions) and `FlowStorage` (flows) are both *derived* from a single low-level contract, `telega/storage.KeyValueStorage`. Wire up one backend and use it for both:

```gleam
pub type KeyValueStorage(error) {
  KeyValueStorage(
    get: fn(String) -> Result(Option(String), error),
    set: fn(String, String) -> Result(Nil, error),
    set_with_ttl: fn(String, String, Int) -> Result(Nil, error),
    delete: fn(String) -> Result(Nil, error),
    scan: fn(String) -> Result(List(String), error),
  )
}
```

Values are opaque JSON `String`s — you bring your own encode/decode for sessions; flow instances are serialized automatically.

### ETS (built in)

```gleam
import telega/storage
import telega/storage/ets

let assert Ok(kv) = ets.new("my_bot_storage")

// Sessions: provide JSON encode/decode for your session type.
let session_settings =
  storage.session_settings_from_storage(
    storage: kv,
    encode: encode_my_session,           // fn(MySession) -> json.Json
    decode: my_session_decoder(),         // decode.Decoder(MySession)
    default: fn() { MySession(count: 0) },
  )

// Flows: no per-type wiring needed — the full instance is serialized for you.
let flow_storage = storage.flow_storage_from_storage(kv)
```

`ets.new` keeps data in memory for the lifetime of the VM (lost on restart) and emulates `set_with_ttl` with lazy expiration on access. For persistence across restarts, back `KeyValueStorage` with a database (see below) and pass it to the same two bridges.

### Custom backend

Implement `KeyValueStorage` once and both sessions and flows work. The contract is small: `get`/`set`/`set_with_ttl`/`delete`/`scan(prefix)`. Keys are namespaced for you (`session:…`, `flow:…`), so a single store can hold both. `scan(prefix)` must return live keys beginning with the prefix; it backs `FlowStorage.list_by_user` and TTL cleanup.

```gleam
fn my_kv(conn) -> storage.KeyValueStorage(MyError) {
  storage.KeyValueStorage(
    get: fn(key) { /* SELECT value WHERE key = $1 */ },
    set: fn(key, value) { /* UPSERT */ },
    set_with_ttl: fn(key, value, ttl_ms) { /* UPSERT with expires_at */ },
    delete: fn(key) { /* DELETE */ },
    scan: fn(prefix) { /* SELECT key WHERE key LIKE $1 || '%' AND not expired */ },
  )
}
```

The manual `SessionSettings` recipes below remain valid if you prefer to wire sessions directly without the `KeyValueStorage` bridge.

## Storage Backends

### In-Memory (Actor)

Wrap a `Dict` in an actor. Simple but data is lost on crash or restart.

```gleam
import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import gleam/otp/actor
import gleam/result

pub type StorageMessage(value) {
  Get(reply_with: Subject(Option(value)), key: String)
  Set(key: String, value: value)
}

pub type StorageSubject(value) =
  Subject(StorageMessage(value))

pub fn start() -> Result(StorageSubject(value), actor.StartError) {
  let initial_state = dict.new()

  actor.new(initial_state)
  |> actor.on_message(handle_message)
  |> actor.start
  |> result.map(fn(started) { started.data })
}

pub fn get(in actor: StorageSubject(value), key key: String) -> Option(value) {
  process.call_forever(actor, Get(_, key))
}

pub fn set(
  in actor: StorageSubject(value),
  key key: String,
  value value: value,
) -> Nil {
  process.send(actor, Set(key, value))
}
```

Wiring:

```gleam
let assert Ok(storage) = storage.start()

telega.with_session_settings(
  builder,
  bot.SessionSettings(
    default_session: fn() { MySession(count: 0) },
    get_session: fn(key) { storage.get(storage, key) |> Ok },
    persist_session: fn(key, session) {
      storage.set(storage, key, session)
      Ok(session)
    },
  ),
)
```

See `examples/02-session-bot` for a working example.

### ETS

ETS tables survive actor crashes and provide fast concurrent access. The table lives as long as the owning process (typically the app supervisor).

```gleam
import gleam/dynamic
import gleam/erlang/atom.{type Atom}
import gleam/option.{type Option}

type EtsTable

pub opaque type SessionEtsStorage {
  SessionEtsStorage(table: EtsTable)
}

pub fn start() -> Result(SessionEtsStorage, Nil) {
  let name = atom.create("telega_session_storage")
  let table = case is_undefined(ets_whereis_raw(name)) {
    True ->
      ets_new(name, [
        atom.create("set"),
        atom.create("public"),
        atom.create("named_table"),
      ])
    False -> coerce(ets_whereis_raw(name))
  }
  Ok(SessionEtsStorage(table:))
}

pub fn get(storage: SessionEtsStorage, key: String) -> Option(value) {
  case ets_lookup(storage.table, key) {
    [] -> option.None
    [#(_, value), ..] -> option.Some(value)
  }
}

pub fn set(storage: SessionEtsStorage, key: String, value: value) -> Nil {
  ets_insert(storage.table, #(key, value))
  Nil
}

@external(erlang, "ets", "whereis")
fn ets_whereis_raw(name: Atom) -> dynamic.Dynamic

fn is_undefined(value: dynamic.Dynamic) -> Bool {
  case atom.get("undefined") {
    Ok(undefined) -> value == atom.to_dynamic(undefined)
    Error(_) -> False
  }
}

@external(erlang, "gleam_stdlib", "identity")
fn coerce(value: dynamic.Dynamic) -> EtsTable

@external(erlang, "ets", "new")
fn ets_new(name: Atom, options: List(Atom)) -> EtsTable

@external(erlang, "ets", "insert")
fn ets_insert(table: EtsTable, tuple: #(String, value)) -> Bool

@external(erlang, "ets", "lookup")
fn ets_lookup(table: EtsTable, key: String) -> List(#(String, value))
```

Wiring is identical to the actor example — just swap `storage` for `ets_storage`.

**Trade-off:** Survives actor crashes, but data is still lost on app restart.

### File (JSON)

Write sessions to disk for persistence across restarts. Requires `simplifile` and JSON encode/decode for your session type.

```gleam
import gleam/json
import gleam/option.{type Option, None, Some}
import simplifile

fn session_path(key: String) -> String {
  "data/sessions/" <> key <> ".json"
}

fn get_session(key: String) -> Result(Option(MySession), MyError) {
  case simplifile.read(session_path(key)) {
    Ok(content) ->
      case json.parse(content, my_session_decoder()) {
        Ok(session) -> Ok(Some(session))
        Error(_) -> Ok(None)  // Corrupt file — fall back to default
      }
    Error(_) -> Ok(None)  // File not found
  }
}

fn persist_session(key: String, session: MySession) -> Result(MySession, MyError) {
  let content = encode_session(session) |> json.to_string
  case simplifile.write(session_path(key), content) {
    Ok(_) -> Ok(session)
    Error(err) -> Error(FileError(err))
  }
}
```

**Trade-off:** Survives restarts, but slow under high throughput and no built-in concurrency control.

### Database (PostgreSQL)

For production bots. Example with `pog`:

```sql
CREATE TABLE bot_sessions (
  key TEXT PRIMARY KEY,
  data JSONB NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

```gleam
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/pog

fn get_session(db: pog.Connection, key: String) -> Result(Option(MySession), MyError) {
  let query = "SELECT data FROM bot_sessions WHERE key = $1"
  case pog.execute(query, db, [pog.text(key)], session_row_decoder()) {
    Ok(pog.Returned(count: 0, ..)) -> Ok(None)
    Ok(pog.Returned(rows: [session, ..], ..)) -> Ok(Some(session))
    Error(err) -> Error(DatabaseError(err))
  }
}

fn persist_session(db: pog.Connection, key: String, session: MySession) -> Result(MySession, MyError) {
  let data = encode_session(session) |> json.to_string
  let query = "
    INSERT INTO bot_sessions (key, data, updated_at)
    VALUES ($1, $2::jsonb, NOW())
    ON CONFLICT (key) DO UPDATE SET data = $2::jsonb, updated_at = NOW()
  "
  case pog.execute(query, db, [pog.text(key), pog.text(data)], pog.ok_decoder()) {
    Ok(_) -> Ok(session)
    Error(err) -> Error(DatabaseError(err))
  }
}
```

**Trade-off:** Full persistence and ACID, but requires an external dependency.

## Session Migration

When the shape of your session changes, version it. The stored value is wrapped
in `{"v": <version>, "d": <session>}`, and a value written by an older build is
handed to `migrate` instead of being read as garbage:

```gleam
storage.session_settings_from_storage_versioned(
  storage: kv,
  encode: encode_session,
  decode: session_decoder(),
  default: fn() { Session(name: "", locale: "en") },
  version: 2,
  migrate: fn(from, raw) {
    case from {
      // v1 had no `locale`; v0 is what an unversioned build wrote.
      0 | 1 -> decode.run(raw, v1_decoder()) |> result.replace_error(Nil)
      _ -> Error(Nil)
    }
  },
)
```

- the envelope's version matches → decoded with `decode`;
- it does not → `migrate` gets the stored version and the raw payload;
- there is no envelope (written by `session_settings_from_storage`) → the
  version is `0` and `migrate` gets the whole value.

A `migrate` that returns `Error(Nil)` — including for a version from a *newer*
build — is treated like a value that will not decode: reported through
`telega.storage.decode_error`, then read as "no session", so the caller falls
back to `default`. That is deliberate: half-populating a session from a shape
you do not recognise is worse than starting over.

Without versioning, a decode failure in `get_session` still does not crash the
bot — it is reported and falls back to `default_session()` — but the next write
overwrites the value that failed, so migrate explicitly rather than relying on
it.

## Session TTL

Telega doesn't provide built-in TTL. Implement cleanup per backend:

- **ETS:** Store `#(key, #(session, timestamp))`, run a periodic actor to delete expired entries.
- **Database:** `DELETE FROM bot_sessions WHERE updated_at < NOW() - INTERVAL '30 days'`
- **File:** Delete files older than your threshold based on modification time.
