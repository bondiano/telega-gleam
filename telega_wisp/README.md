# telega_wisp

[Wisp](https://hexdocs.pm/wisp/) webhook adapter for [Telega](https://github.com/bondiano/telega-gleam) Telegram Bot Library.

[![Package Version](https://img.shields.io/hexpm/v/telega_wisp)](https://hex.pm/packages/telega_wisp)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/telega_wisp/)

## Installation

```sh
gleam add telega_wisp
```

## Usage

`telega_wisp` provides a `handle_bot` middleware that plugs into your Wisp request handler. It validates the secret token, decodes incoming Telegram updates, and dispatches them to your bot.

```gleam
import wisp.{type Request, type Response}
import telega.{type Telega}
import telega_wisp

fn handle_request(req: Request, telega: Telega(session, error)) -> Response {
  use <- telega_wisp.handle_bot(telega:, req:)

  // Your other routes here...
  wisp.not_found()
}
```

The middleware will:

1. Check if the request matches the bot's webhook path
2. Validate the `x-telegram-bot-api-secret-token` header
3. Decode the update and pass it to the bot asynchronously
4. Return `200 OK` immediately so Telegram doesn't retry

## Requirements

- Gleam >= 1.12.0
- Erlang target only
