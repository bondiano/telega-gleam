# telega_storage_redis

[Redis/Valkey](https://hexdocs.pm/valkyrie/) storage adapter for the [Telega](https://github.com/bondiano/telega-gleam) Telegram Bot Library.

[![Package Version](https://img.shields.io/hexpm/v/telega_storage_redis)](https://hex.pm/packages/telega_storage_redis)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/telega_storage_redis/)

Fast, server-side persistence for sessions and flows on Redis or Valkey, with native TTL. Built on [valkyrie](https://hexdocs.pm/valkyrie/) and implements `telega/storage.KeyValueStorage`, so a single backend serves both sessions and flows.

## Installation

```sh
gleam add telega_storage_redis
```

## Usage

```gleam
import gleam/erlang/process
import gleam/option.{Some}
import gleam/otp/static_supervisor as supervisor
import telega/storage
import telega_storage_redis as redis
import valkyrie

pub fn main() {
  let pool_name = process.new_name("bot_redis")
  let spec =
    valkyrie.default_config()
    |> valkyrie.supervised_pool(size: 10, name: Some(pool_name), timeout: 1000)

  let assert Ok(_) =
    supervisor.new(supervisor.OneForOne)
    |> supervisor.add(spec)
    |> supervisor.start

  let kv = redis.new(valkyrie.named_connection(pool_name))

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

## Notes

- **TTL** is enforced by the server (`EXPIRE`), so expired keys vanish on their own. Redis works in whole seconds, so a sub-second TTL is rounded up to one second.
- **`scan`** uses cursor-based `SCAN` over the key prefix (not `KEYS`), so it is safe to use against a production database.

## Testing

```sh
gleam test
```

Integration tests connect to a local Redis on the default port. They are skipped automatically when no server is reachable.
