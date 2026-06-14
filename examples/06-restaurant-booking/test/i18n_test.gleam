//// Verifies the bot's translation catalog loads from `locales/` and resolves
//// both locales, including interpolation and Russian pluralization.

import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should

import telega_i18n

import restaurant_booking/i18n
import test_db

pub fn catalog_loads_both_locales_test() {
  let catalog = i18n.catalog()

  telega_i18n.locales(catalog)
  |> list.sort(string.compare)
  |> should.equal(["en", "ru"])
}

pub fn english_is_default_test() {
  let catalog = i18n.catalog()

  telega_i18n.translate(catalog, "en", "reg.ask_name", [])
  |> should.equal("Please enter your full name:")
}

pub fn russian_interpolation_test() {
  let catalog = i18n.catalog()

  telega_i18n.translate(catalog, "ru", "reg.welcome", [
    #("restaurant", "Bella Vista"),
  ])
  |> should.equal(
    "🍽️ Добро пожаловать в Bella Vista!\n\nЧтобы забронировать столик, мне нужно немного информации о вас.\nЭто займёт всего пару минут.\n\nНачнём! 👋",
  )
}

pub fn unknown_locale_falls_back_to_default_test() {
  let catalog = i18n.catalog()

  // French is not defined; lookup falls back to the default locale (en).
  telega_i18n.translate(catalog, "fr", "reg.ask_name", [])
  |> should.equal("Please enter your full name:")
}

pub fn russian_plural_menu_items_test() {
  let catalog = i18n.catalog()

  telega_i18n.translate_count(catalog, "ru", "menu.items", 1, [])
  |> should.equal("1 блюдо")
  telega_i18n.translate_count(catalog, "ru", "menu.items", 3, [])
  |> should.equal("3 блюда")
  telega_i18n.translate_count(catalog, "ru", "menu.items", 8, [])
  |> should.equal("8 блюд")
}

pub fn english_plural_menu_items_test() {
  let catalog = i18n.catalog()

  telega_i18n.translate_count(catalog, "en", "menu.items", 1, [])
  |> should.equal("1 item")
  telega_i18n.translate_count(catalog, "en", "menu.items", 8, [])
  |> should.equal("8 items")
}

// Per-user language override (set by the /language command) ------------------

pub fn language_override_roundtrip_test() {
  case test_db.try_connect_and_setup() {
    None -> Nil
    Some(db) -> {
      // No override stored yet.
      i18n.get_user_language(db, 100, 200) |> should.equal(None)

      let assert Ok(_) = i18n.set_user_language(db, 100, 200, "ru")
      i18n.get_user_language(db, 100, 200) |> should.equal(Some("ru"))

      // Overrides are per chat+user.
      i18n.get_user_language(db, 100, 999) |> should.equal(None)

      // It can be changed.
      let assert Ok(_) = i18n.set_user_language(db, 100, 200, "en")
      i18n.get_user_language(db, 100, 200) |> should.equal(Some("en"))

      test_db.cleanup(db)
    }
  }
}

/// A stored override wins over the Telegram `language_code`.
pub fn stored_override_beats_telegram_language_test() {
  let catalog = i18n.catalog()

  telega_i18n.resolve_locale(catalog, Some("ru"), Some("en"))
  |> should.equal("ru")
}
