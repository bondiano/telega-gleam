# Telega Commands Bot

```sh
gleam run   # Run the server
gleam test  # Run the tests
```

This is an example of a simple commands bot using the Telega library.

## Deep-linking: `/start` payload

Links like `https://t.me/your_bot?start=ref-42` open the bot and deliver
`ref-42` inside the `/start` command. The `telega/deep_link` module builds
such links and reads the payload back:

```gleam
import telega/deep_link

fn start_command_handler(ctx, command) {
  use ctx <- telega.log_context(ctx, "start")
  let greeting = case deep_link.payload_from_command(command) {
    Some(payload) -> "You came from: " <> payload
    None -> "Hello! I'm a dice bot. Roll a dice with /dice."
  }
  use _ <- try(reply.with_text(ctx, greeting))
  Ok(ctx)
}
```

To carry arbitrary data (ids with separators, unicode), build the link with
`deep_link.encoded_start_link_for_bot` — it base64-encodes the data to fit
the `A-Za-z0-9_-` alphabet Telegram requires — and read it back with
`deep_link.decoded_payload_from_command`:

```gleam
let assert Ok(link) = deep_link.encoded_start_link_for_bot(ctx.bot_info, "ref:42")
// -> "https://t.me/your_bot?start=cmVmOjQy"
```