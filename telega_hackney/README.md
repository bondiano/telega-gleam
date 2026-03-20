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
