# Telega

[![Package Version](https://img.shields.io/hexpm/v/telega)](https://hex.pm/packages/telega)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/telega/)

A [Gleam](https://gleam.run/) library for the Telegram Bot API.

<a href="#" target="blank">
  <img src="https://raw.githubusercontent.com/bondiano/telega-gleam/refs/heads/master/docs/logo.png" alt="Telega" width="244" style="display: block; margin: 0 auto;" />
</a>

## It provides

- an interface to the Telegram Bot HTTP-based APIs `telega/api`
- an client for the Telegram Bot API `telega/client`
- adapter to use with [wisp](https://github.com/gleam-wisp/wisp)
- polling implementation
- session bot implementation
- conversation implementation
- convenient utilities for common tasks

## Quick start

> If you are new to Telegram bots, read the official [Introduction for Developers](https://core.telegram.org/bots) written by the Telegram team.

First, visit [@BotFather](https://t.me/botfather) to create a new bot. Copy **the token** and save it for later.

Initiate a gleam project and add `telega` as a dependencies:

```sh
$ gleam new first_tg_bot
$ cd first_tg_bot
$ gleam add telega
```

Replace the `first_tg_bot.gleam` file content with the following code:

```gleam
import telega
import telega/polling
import telega/reply
import telega/update.{CommandUpdate, TextUpdate}

fn echo_handler(ctx, update) {
  use ctx <- telega.log_context(ctx, "echo")

  case update {
    TextUpdate(text:, ..) -> {
      let assert Ok(_) = reply.with_text(ctx, text)
      Ok(ctx)
    }
    CommandUpdate(command:, ..) -> {
      let assert Ok(_) = reply.with_text(ctx, "Command: " <> command.text)
      Ok(ctx)
    }
    _ -> Ok(ctx)
  }
}

pub fn main() {
  let assert Ok(bot) =
    telega.new_for_polling(token: "BOT_TOKEN")
    |> telega.handle_all(echo_handler)
    |> telega.init_nil_session()

  let assert Ok(poller) = polling.init_polling_default(bot)

  polling.wait_finish(poller)
}
```

Replace `"BOT_TOKEN"` with the token you received from the BotFather. Then run the bot:

```sh
$ gleam run
```

And it will echo all received text messages.

Congratulations! You just wrote a Telegram bot :)

## Examples

Other examples can be found in the [examples](./examples) directory.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
