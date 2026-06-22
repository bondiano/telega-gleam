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

If `get_session` returns an `Error`, Telega logs a warning and falls back to `default_session()` instead of crashing. This keeps the bot running during transient storage failures.

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

When your session type changes, version it and handle old formats in the decoder:

```gleam
pub type MySession {
  MySession(version: Int, name: String, preferences: Preferences)
}

fn decode_session(json_str: String) -> Result(MySession, DecodeError) {
  case json.parse(json_str, v2_decoder()) {
    Ok(session) -> Ok(session)
    Error(_) ->
      case json.parse(json_str, v1_decoder()) {
        Ok(v1) -> Ok(migrate_v1_to_v2(v1))
        Error(err) -> Error(err)
      }
  }
}
```

Decode failures in `get_session` won't crash the bot (Telega falls back to `default_session()`), but handle migrations explicitly to avoid losing user data.

## Session TTL

Telega doesn't provide built-in TTL. Implement cleanup per backend:

- **ETS:** Store `#(key, #(session, timestamp))`, run a periodic actor to delete expired entries.
- **Database:** `DELETE FROM bot_sessions WHERE updated_at < NOW() - INTERVAL '30 days'`
- **File:** Delete files older than your threshold based on modification time.
