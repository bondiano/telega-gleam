# telega_storage_sqlite

[SQLite](https://hexdocs.pm/sqlight/) storage adapter for the [Telega](https://github.com/bondiano/telega-gleam) Telegram Bot Library.

[![Package Version](https://img.shields.io/hexpm/v/telega_storage_sqlite)](https://hex.pm/packages/telega_storage_sqlite)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/telega_storage_sqlite/)

Single-file, zero-server persistence for sessions and flows — ideal for small bots on a VPS. Implements `telega/storage.KeyValueStorage`, so the same backend serves both sessions and flows.

## Installation

```sh
gleam add telega_storage_sqlite
```

## Usage

```gleam
import sqlight
import telega
import telega/storage
import telega_storage_sqlite as sqlite

pub fn main() {
  let assert Ok(conn) = sqlight.open("bot.db")
  let assert Ok(Nil) = sqlite.migrate(conn)

  let kv = sqlite.new(conn)

  // Sessions — provide JSON encode/decode for your session type.
  let session_settings =
    storage.session_settings_from_storage(
      storage: kv,
      encode: encode_my_session,
      decode: my_session_decoder(),
      default: fn() { default_session() },
    )

  // Flows — the full instance is serialized for you.
  let flow_storage = storage.flow_storage_from_storage(kv)

  // ... wire `session_settings` and `flow_storage` into your bot.
}
```

## Schema

`migrate` creates this table (use `migrate_table` / `new_with_table` for a custom name):

```sql
CREATE TABLE IF NOT EXISTS telega_storage (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  expires_at INTEGER  -- epoch ms; NULL = never
);
```

TTL is enforced lazily — expired rows are dropped on access (`get`/`scan`).

## Testing

```sh
gleam test
```

Tests run against an in-memory database, so no server is required.
