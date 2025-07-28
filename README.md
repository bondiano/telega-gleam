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
- session bot implementation
- conversation implementation
- convenient utilities for common tasks

## Quick start

> If you are new to Telegram bots, read the official [Introduction for Developers](https://core.telegram.org/bots) written by the Telegram team.

First, visit [@BotFather](https://t.me/botfather) to create a new bot. Copy **the token** and save it for later.

Initiate a gleam project and add `telega` and `wisp` as a dependencies:

```sh
$ gleam new first_tg_bot
$ cd first_tg_bot
$ gleam add telega wisp mist gleam_erlang
```

Replace the `first_tg_bot.gleam` file content with the following code:

```gleam
import gleam/erlang/process
import gleam/option.{None}
import mist
import telega
import telega/adapters/wisp as telega_wisp
import telega/reply
import telega/update.{CommandUpdate, TextUpdate}
import wisp
import wisp/wisp_mist

fn handle_request(bot, req) {
  use <- telega_wisp.handle_bot(bot, req)
  wisp.not_found()
}

fn echo_handler(ctx, update) {
  use <- telega.log_context(ctx, "echo")
  let assert Ok(_) = case update {
    TextUpdate(text:, ..) -> reply.with_text(ctx, text)
    CommandUpdate(command:, ..) -> reply.with_text(ctx, command.text)
    _ -> panic as "No text message"
  }
  Ok(ctx)
}

pub fn main() {
  wisp.configure_logger()

  let assert Ok(bot) =
    telega.new(
      token: "your bot token from @BotFather",
      url: "your bot url",
      webhook_path: "secret path",
      secret_token: None,
    )
    |> telega.handle_all(echo_handler)
    |> telega.init_nil_session()

  let assert Ok(_) =
    wisp_mist.handler(handle_request(bot, _), wisp.random_string(64))
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
```

Replace `"your bot token from @BotFather"` with the token you received from the BotFather. Set the `url` and `webhook_path` to your server's URL and the desired path for the webhook. If you don't have a server yet, you can use [ngrok](https://ngrok.com/) or [localtunnel](https://localtunnel.me/) to create a tunnel to your local machine.

Then run the bot:

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
