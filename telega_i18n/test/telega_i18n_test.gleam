import gleam/dict
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

import telega_i18n

pub fn main() {
  gleeunit.main()
}

fn sample_catalog() -> telega_i18n.Catalog {
  telega_i18n.new(default_locale: "en")
  |> telega_i18n.add_locale(
    "en",
    dict.from_list([
      #("greeting", "Hello, {name}!"),
      #("cart.title", "Your cart"),
      #("items.one", "{count} item"),
      #("items.other", "{count} items"),
    ]),
  )
  |> telega_i18n.add_locale(
    "ru",
    dict.from_list([
      #("greeting", "Привет, {name}!"),
      #("items.one", "{count} товар"),
      #("items.few", "{count} товара"),
      #("items.many", "{count} товаров"),
    ]),
  )
}

// translate / interpolation --------------------------------------------------

pub fn translate_interpolates_test() {
  sample_catalog()
  |> telega_i18n.translate("en", "greeting", [#("name", "Lucy")])
  |> should.equal("Hello, Lucy!")
}

pub fn translate_picks_locale_test() {
  sample_catalog()
  |> telega_i18n.translate("ru", "greeting", [#("name", "Lucy")])
  |> should.equal("Привет, Lucy!")
}

pub fn translate_nested_key_test() {
  sample_catalog()
  |> telega_i18n.translate("en", "cart.title", [])
  |> should.equal("Your cart")
}

pub fn translate_missing_key_returns_key_test() {
  sample_catalog()
  |> telega_i18n.translate("en", "nope.missing", [])
  |> should.equal("nope.missing")
}

// fallback -------------------------------------------------------------------

pub fn translate_falls_back_to_default_test() {
  // `cart.title` only exists in `en` (the default).
  sample_catalog()
  |> telega_i18n.translate("ru", "cart.title", [])
  |> should.equal("Your cart")
}

pub fn translate_falls_back_to_base_language_test() {
  // `en-US` is not a defined locale, so it falls back to `en`.
  sample_catalog()
  |> telega_i18n.translate("en-US", "greeting", [#("name", "Sam")])
  |> should.equal("Hello, Sam!")
}

pub fn translate_explicit_fallback_chain_test() {
  let catalog =
    telega_i18n.new(default_locale: "en")
    |> telega_i18n.add_locale("en", dict.from_list([#("hi", "Hi")]))
    |> telega_i18n.add_locale("de", dict.from_list([#("hi", "Hallo")]))
    |> telega_i18n.add_locale("gsw", dict.from_list([]))
    |> telega_i18n.with_fallback("gsw", ["de"])

  catalog
  |> telega_i18n.translate("gsw", "hi", [])
  |> should.equal("Hallo")
}

// pluralization --------------------------------------------------------------

pub fn english_plural_categories_test() {
  telega_i18n.plural_category("en", 1) |> should.equal("one")
  telega_i18n.plural_category("en", 0) |> should.equal("other")
  telega_i18n.plural_category("en", 5) |> should.equal("other")
}

pub fn russian_plural_categories_test() {
  telega_i18n.plural_category("ru", 1) |> should.equal("one")
  telega_i18n.plural_category("ru", 21) |> should.equal("one")
  telega_i18n.plural_category("ru", 2) |> should.equal("few")
  telega_i18n.plural_category("ru", 23) |> should.equal("few")
  telega_i18n.plural_category("ru", 5) |> should.equal("many")
  telega_i18n.plural_category("ru", 11) |> should.equal("many")
  telega_i18n.plural_category("ru", 12) |> should.equal("many")
  telega_i18n.plural_category("ru", 100) |> should.equal("many")
}

pub fn translate_count_english_test() {
  let catalog = sample_catalog()
  telega_i18n.translate_count(catalog, "en", "items", 1, [])
  |> should.equal("1 item")
  telega_i18n.translate_count(catalog, "en", "items", 5, [])
  |> should.equal("5 items")
}

pub fn translate_count_russian_test() {
  let catalog = sample_catalog()
  telega_i18n.translate_count(catalog, "ru", "items", 1, [])
  |> should.equal("1 товар")
  telega_i18n.translate_count(catalog, "ru", "items", 3, [])
  |> should.equal("3 товара")
  telega_i18n.translate_count(catalog, "ru", "items", 5, [])
  |> should.equal("5 товаров")
}

pub fn translate_count_falls_back_to_other_test() {
  let catalog =
    telega_i18n.new(default_locale: "en")
    |> telega_i18n.add_locale("en", dict.from_list([#("x.other", "{count} x")]))
  // `one` category is missing, so it uses `other`.
  telega_i18n.translate_count(catalog, "en", "x", 1, [])
  |> should.equal("1 x")
}

// resolve_locale -------------------------------------------------------------

pub fn resolve_locale_prefers_session_test() {
  let catalog = sample_catalog()
  telega_i18n.resolve_locale(catalog, Some("ru"), Some("en"))
  |> should.equal("ru")
}

pub fn resolve_locale_uses_update_test() {
  let catalog = sample_catalog()
  telega_i18n.resolve_locale(catalog, None, Some("en"))
  |> should.equal("en")
}

pub fn resolve_locale_defaults_test() {
  let catalog = sample_catalog()
  telega_i18n.resolve_locale(catalog, None, None)
  |> should.equal("en")
}

// TOML / JSON loading --------------------------------------------------------

pub fn add_toml_flattens_test() {
  let toml =
    "
greeting = \"Hello, {name}!\"

[cart]
title = \"Your cart\"
items = 3
"
  let assert Ok(catalog) =
    telega_i18n.new(default_locale: "en")
    |> telega_i18n.add_toml("en", toml)

  telega_i18n.translate(catalog, "en", "greeting", [#("name", "Lucy")])
  |> should.equal("Hello, Lucy!")
  telega_i18n.translate(catalog, "en", "cart.title", [])
  |> should.equal("Your cart")
  // non-string leaves are stringified
  telega_i18n.translate(catalog, "en", "cart.items", [])
  |> should.equal("3")
}

pub fn add_json_flattens_test() {
  let json = "{\"greeting\": \"Hi {name}\", \"cart\": {\"title\": \"Cart\"}}"
  let assert Ok(catalog) =
    telega_i18n.new(default_locale: "en")
    |> telega_i18n.add_json("en", json)

  telega_i18n.translate(catalog, "en", "greeting", [#("name", "Sam")])
  |> should.equal("Hi Sam")
  telega_i18n.translate(catalog, "en", "cart.title", [])
  |> should.equal("Cart")
}

pub fn add_toml_invalid_test() {
  let result =
    telega_i18n.new(default_locale: "en")
    |> telega_i18n.add_toml("en", "= broken")
  case result {
    Error(telega_i18n.ParseError(_)) -> Nil
    _ -> should.fail()
  }
}

// process-dictionary state ---------------------------------------------------

pub fn enter_and_translate_current_test() {
  let catalog = sample_catalog()
  telega_i18n.leave()
  // No state yet: returns the key unchanged.
  telega_i18n.translate_current("greeting", [#("name", "X")])
  |> should.equal("greeting")

  telega_i18n.enter(catalog:, locale: "ru")
  telega_i18n.current_locale()
  |> should.equal(Some("ru"))
  telega_i18n.translate_current("greeting", [#("name", "Лена")])
  |> should.equal("Привет, Лена!")

  telega_i18n.leave()
  telega_i18n.current_locale()
  |> should.equal(None)
}
