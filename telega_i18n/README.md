# telega_i18n

[![Package Version](https://img.shields.io/hexpm/v/telega_i18n)](https://hex.pm/packages/telega_i18n)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/telega_i18n/)

Internationalization (i18n) for the [Telega](https://hexdocs.pm/telega) Telegram
Bot Library: TOML/JSON translation catalogs, a locale-resolving middleware,
`{placeholder}` interpolation, and CLDR pluralization.

```sh
gleam add telega_i18n
```

## Overview

- **Catalogs** — one flat table of dotted keys per locale, loaded from TOML or
  JSON (files or strings). Nested tables/objects flatten to dotted keys.
- **Middleware** — resolves the active locale per update (session override →
  Telegram `language_code` → default) and stashes it for the handler.
- **`t` / `tn`** — translate by key inside handlers; `tn` pluralizes.
- **Fallback chains** — active locale → base language (`en-US` → `en`) →
  explicit fallbacks → default. Missing keys return the key, never crash.

## Usage

`locales/en.toml`:

```toml
greeting = "Hello, {name}!"

[cart]
title = "Your cart"

[items]
one = "{count} item"
other = "{count} items"
```

`locales/ru.toml`:

```toml
greeting = "Привет, {name}!"

[items]
one = "{count} товар"
few = "{count} товара"
many = "{count} товаров"
```

```gleam
import gleam/option.{None}
import telega/reply
import telega/router
import telega_i18n

pub fn build_router(catalog) {
  router.new("bot")
  |> router.use_middleware(telega_i18n.middleware(
    catalog:,
    // Per-user override from the session; `None` falls back to the user's
    // Telegram `language_code`, then the catalog default.
    from: fn(_session) { None },
  ))
  |> router.on_command("start", greet)
}

fn greet(ctx, _command) {
  let hi = telega_i18n.t(ctx, "greeting", [#("name", "Lucy")])
  // -> "Hello, Lucy!" or "Привет, Lucy!"
  let count = telega_i18n.tn(ctx, "items", 5, [])
  // -> "5 items" or "5 товаров"
  reply.with_text(ctx, hi <> "\n" <> count)
}
```

Load the catalog once at startup:

```gleam
let assert Ok(catalog) =
  telega_i18n.new(default_locale: "en")
  |> telega_i18n.load_toml_dir("locales")
```

You can also build catalogs by hand or from strings:

```gleam
telega_i18n.new(default_locale: "en")
|> telega_i18n.add_toml("en", en_toml_string)
|> result.try(telega_i18n.add_json(_, "ru", ru_json_string))
```

## Pluralization

`tn` picks a CLDR category for `count` and looks up `"<key>.<category>"`
(falling back to `"<key>.other"`), injecting `count` as `{count}`. English and
Russian (and other East-Slavic `uk`/`be`) rules are built in; every other
locale uses the English rule.

## License

Apache-2.0
