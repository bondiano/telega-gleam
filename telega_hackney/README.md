# telega_hackney

hackney adapter for [Telega](https://github.com/bondiano/telega-gleam) Telegram Bot Library.

## Usage

```gleam
import telega
import telega_hackney

pub fn main() {
  let client = telega_hackney.new("BOT_TOKEN")

  let assert Ok(_bot) =
    telega.new_for_polling(client)
    |> telega.with_router(router)
    |> telega.init_for_polling_nil_session()
}
```

## Timeouts

A single HTTP call is bounded at **60 seconds** by default, deliberately longer
than the 30-second long poll Telega opens for `getUpdates` — a shorter timeout
aborts every empty poll and quietly degrades the bot to polling at whatever
rate the timeout allows.

If you raise `telega.set_polling_timeout` past ~55 seconds, raise this to
match:

```gleam
let client = telega_hackney.new_with_timeout(token: "BOT_TOKEN", timeout_ms: 90_000)
```
