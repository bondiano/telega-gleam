# telega_webapp

[Telegram Mini Apps](https://core.telegram.org/bots/webapps) (Web Apps) support for the [Telega](https://github.com/bondiano/telega-gleam) Telegram Bot Library.

[![Package Version](https://img.shields.io/hexpm/v/telega_webapp)](https://hex.pm/packages/telega_webapp)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/telega_webapp/)

A Mini App's frontend hands your backend a signed `initData` string. This package verifies that signature and decodes it into typed values, so you can trust who is calling. Pure Gleam, Erlang target.

- **First-party validation** — `HMAC-SHA256` with your bot token (`validate`, `validate_with_max_age`).
- **Third-party validation** — `Ed25519` `signature` field, for apps opened on behalf of another bot (`validate_third_party`).
- **Typed payload** — `WebAppInitData`, `WebAppUser`, `WebAppChat`.
- **`answer_web_app_query`** — reply to an inline Mini App query.

## Installation

```sh
gleam add telega_webapp
```

## Usage

```gleam
import telega_webapp

pub fn authenticate(token: String, init_data: String) {
  // `init_data` is the raw `Telegram.WebApp.initData` query string your
  // frontend forwarded (commonly in an `Authorization: tma <initData>` header).
  case telega_webapp.validate_with_max_age(token, init_data, 86_400) {
    Ok(data) -> {
      let assert option.Some(user) = data.user
      // `user` is now trusted: user.id, user.first_name, user.username, ...
      Ok(user)
    }
    Error(reason) -> Error(reason)
  }
}
```

### Third-party apps

When your service receives Mini App data for a bot whose token you don't hold,
verify the `Ed25519` `signature` instead, using the bot's numeric id:

```gleam
telega_webapp.validate_third_party(bot_id, init_data, telega_webapp.Production)
```

### Answering inline queries

```gleam
import telega/inline_mode
import telega_webapp

let result =
  inline_mode.new()
  |> inline_mode.article(id: "1", title: "Done", text: "Saved!")
  |> inline_mode.results
  |> list.first

let assert Ok(result) = result
telega_webapp.answer_web_app_query(client, query_id, result)
```

Pair it with [`telega_wisp`](https://github.com/bondiano/telega-gleam/tree/master/telega_wisp):
forward `Telegram.WebApp.initData` from your frontend (e.g. in an
`Authorization: tma <initData>` header), validate it in your wisp handler, and
you have a full-stack Telegram app — `telega` + `telega_wisp` + `telega_webapp`.

## License

Apache-2.0
