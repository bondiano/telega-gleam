# telega_httpc

httpc adapter for [Telega](https://github.com/bondiano/telega-gleam) Telegram Bot Library.

## Usage

```gleam
import telega
import telega_httpc

pub fn main() {
  let client = telega_httpc.new("BOT_TOKEN")

  let assert Ok(_bot) =
    telega.new(client)
    |> telega.with_router(router)
    |> telega.start()
}
```

## Timeouts

A single HTTP call is bounded at **60 seconds** by default, deliberately longer
than the 30-second long poll Telega opens for `getUpdates` — a shorter timeout
aborts every empty poll and quietly degrades the bot to polling at whatever
rate the timeout allows.

If you raise the polling timeout (`polling.PollingSettings(timeout:)`) past ~55 seconds, raise this to
match:

```gleam
let client = telega_httpc.new_with_timeout(token: "BOT_TOKEN", timeout_ms: 90_000)
```
