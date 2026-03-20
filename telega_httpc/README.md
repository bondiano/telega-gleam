# telega_httpc

httpc adapter for [Telega](https://github.com/bondiano/telega-gleam) Telegram Bot Library.

## Usage

```gleam
import telega
import telega_httpc

pub fn main() {
  let client = telega_httpc.new("BOT_TOKEN")

  let assert Ok(_bot) =
    telega.new_for_polling(client)
    |> telega.with_router(router)
    |> telega.init_for_polling_nil_session()
}
```
