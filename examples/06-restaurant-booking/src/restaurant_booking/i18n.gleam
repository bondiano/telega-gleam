//// i18n wiring for the bot.
////
//// Translations live in `locales/en.toml` (default) and `locales/ru.toml` and
//// are loaded once at startup with `telega_i18n.load_toml_dir`. The
//// [`middleware`](#middleware) resolves the active locale per update and stores
//// it for the handler, so call sites only need a key:
////
//// ```gleam
//// i18n.t(ctx, "reg.ask_name", [])
//// ```
////
//// Helpers without a `Context` (e.g. formatting code) can use `tr`/`tn`, which
//// read the same per-process locale set by the middleware.
////
//// ## Locale resolution
////
//// The session is `Nil`, so the per-user language override is persisted in the
//// SQLite key-value store (the same one flows use) under `lang:{chat}:{from}`,
//// set from the `/language` command. For each update the middleware picks:
////
//// 1. the stored override (if the user chose a language), else
//// 2. the user's Telegram `language_code`, else
//// 3. the default locale (`en`).

import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import sqlight
import telega/bot.{type Context}
import telega/router.{type Middleware}
import telega/update
import telega_i18n.{type Catalog}
import telega_storage_sqlite as sqlite

import restaurant_booking/dependencies.{type Dependencies, Dependencies}

/// Locales the bot ships translations for. Drives the `/language` picker.
pub const supported_locales = ["en", "ru"]

/// Load the translation catalog from `locales/`. Panics if the files are
/// missing or malformed — they are part of the project and must be present.
pub fn catalog() -> Catalog {
  let assert Ok(catalog) =
    telega_i18n.new(default_locale: "en")
    |> telega_i18n.load_toml_dir("locales")
  catalog
}

/// Locale-resolving middleware: stored per-user override → Telegram
/// `language_code` → default. The resolved locale is stored for the handler,
/// so `t`/`tr`/`tn` only need a key.
pub fn middleware() -> Middleware(Nil, String, Dependencies) {
  fn(handler) {
    fn(ctx: Context(Nil, String, Dependencies), upd: update.Update) {
      let Dependencies(db:, catalog:) = ctx.dependencies
      let stored = get_user_language(db, ctx.update.chat_id, ctx.update.from_id)
      let from_telegram = telega_i18n.user_language_code(update.raw(ctx.update))
      let locale = telega_i18n.resolve_locale(catalog, stored, from_telegram)
      telega_i18n.enter(catalog:, locale:)
      handler(ctx, upd)
    }
  }
}

/// Read the user's stored language override, if any.
pub fn get_user_language(
  db: sqlight.Connection,
  chat_id: Int,
  from_id: Int,
) -> Option(String) {
  let kv = sqlite.new(db)
  case kv.get(language_key(chat_id, from_id)) {
    Ok(Some(locale)) -> Some(locale)
    _ -> None
  }
}

/// Persist the user's language override.
pub fn set_user_language(
  db: sqlight.Connection,
  chat_id: Int,
  from_id: Int,
  locale: String,
) -> Result(Nil, String) {
  let kv = sqlite.new(db)
  kv.set(language_key(chat_id, from_id), locale)
  |> result.map_error(string.inspect)
}

fn language_key(chat_id: Int, from_id: Int) -> String {
  "lang:" <> int.to_string(chat_id) <> ":" <> int.to_string(from_id)
}

/// Translate a key for the active handler's locale.
pub fn t(
  ctx: Context(Nil, String, Dependencies),
  key: String,
  args: List(#(String, String)),
) -> String {
  telega_i18n.t(ctx, key, args)
}

/// Translate without a `Context`, using the per-process locale set by the
/// middleware. Handy inside formatting helpers.
pub fn tr(key: String, args: List(#(String, String))) -> String {
  telega_i18n.translate_current(key, args)
}

/// Pluralizing translate for the active handler's locale.
pub fn tn(
  ctx: Context(Nil, String, Dependencies),
  key: String,
  count: Int,
  args: List(#(String, String)),
) -> String {
  telega_i18n.tn(ctx, key, count, args)
}
