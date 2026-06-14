# telega_mist

[Mist](https://hexdocs.pm/mist/) webhook adapter for [Telega](https://github.com/bondiano/telega-gleam) Telegram Bot Library.

[![Package Version](https://img.shields.io/hexpm/v/telega_mist)](https://hex.pm/packages/telega_mist)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/telega_mist/)

A minimal webhook adapter built directly on top of `mist`, without `wisp`. Use it for lightweight deployments where you don't need a full web framework. If you already use `wisp`, prefer [`telega_wisp`](https://hexdocs.pm/telega_wisp/).

## Installation

```sh
gleam add telega_mist
```

## Usage

`telega_mist` provides a `handle_bot` handler that plugs into your mist request handler. It validates the secret token, decodes incoming Telegram updates, and dispatches them to your bot.

```gleam
import gleam/bytes_tree
import gleam/erlang/process
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import mist.{type Connection, type ResponseData}
import telega.{type Telega}
import telega_mist

fn handle_request(
  req: Request(Connection),
  bot: Telega(session, error),
) -> Response(ResponseData) {
  use <- telega_mist.handle_bot(telega: bot, req:)

  // Your other routes here...
  response.new(404)
  |> response.set_body(mist.Bytes(bytes_tree.new()))
}

pub fn main() {
  let assert Ok(bot) = // ... build and init your Telega bot for webhooks

  let assert Ok(_) =
    fn(req) { handle_request(req, bot) }
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
```

The handler will:

1. Check if the request matches the bot's webhook path
2. Validate the `x-telegram-bot-api-secret-token` header
3. Decode the update and pass it to the bot asynchronously
4. Return `200 OK` immediately so Telegram doesn't retry

Use `handle_bot_with_limit` to override the maximum request body size (defaults to 4MB).

## Requirements

- Gleam >= 1.12.0
- Erlang target only
