# telega_storage_postgres

[PostgreSQL](https://hexdocs.pm/pog/) storage adapter for the [Telega](https://github.com/bondiano/telega-gleam) Telegram Bot Library.

[![Package Version](https://img.shields.io/hexpm/v/telega_storage_postgres)](https://hex.pm/packages/telega_storage_postgres)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/telega_storage_postgres/)

Production-grade persistence for sessions and flows on PostgreSQL. Implements `telega/storage.KeyValueStorage`, so a single backend serves both sessions and flows.

## Installation

```sh
gleam add telega_storage_postgres
```

## Usage

```gleam
import gleam/erlang/process
import gleam/option.{Some}
import pog
import telega/storage
import telega_storage_postgres as postgres

pub fn main() {
  let name = process.new_name("bot_db")
  let assert Ok(_) =
    pog.default_config(name)
    |> pog.database("bot")
    |> pog.user("postgres")
    |> pog.password(Some("postgres"))
    |> pog.start
  let conn = pog.named_connection(name)

  let assert Ok(Nil) = postgres.migrate(conn)
  let kv = postgres.new(conn)

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
  expires_at BIGINT  -- epoch ms; NULL = never
);
```

TTL is enforced lazily — expired rows are dropped on access (`get`/`scan`). For eager cleanup you may run a periodic `DELETE FROM telega_storage WHERE expires_at IS NOT NULL AND expires_at < <now_ms>`.

## Testing

```sh
gleam test
```

Integration tests connect to `localhost` database `telega_test` (user/password `postgres`). They are skipped automatically when no database is reachable.
