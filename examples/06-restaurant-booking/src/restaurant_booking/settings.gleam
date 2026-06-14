//// User settings: the `/language` command and its callback.
////
//// Language preferences are persisted per user (see `restaurant_booking/i18n`),
//// so the choice survives restarts and is independent of registration.

import gleam/list
import gleam/result
import gleam/string

import sqlight
import telega/bot.{type Context}
import telega/keyboard
import telega/model/types
import telega/reply
import telega/update
import telega_i18n.{type Catalog}

import restaurant_booking/i18n

/// `/language` — show an inline keyboard of the supported languages. Each
/// language is labeled in its own name (a picker shouldn't depend on the
/// current locale).
pub fn language(
  ctx: Context(Nil, String),
  _cmd: update.Command,
) -> Result(Context(Nil, String), String) {
  let markup = keyboard.to_inline_markup(language_keyboard())
  case
    reply.with_markup(ctx, i18n.t(ctx, "settings.choose_language", []), markup)
  {
    Ok(_) -> Ok(ctx)
    Error(err) -> Error("Failed to send language menu: " <> string.inspect(err))
  }
}

/// Callback for `lang:<locale>` buttons: persist the choice, acknowledge the
/// tap, then confirm in the newly chosen language.
pub fn set_language(
  catalog: Catalog,
  db: sqlight.Connection,
  ctx: Context(Nil, String),
  query_id: String,
  data: String,
) -> Result(Context(Nil, String), String) {
  let locale = parse_locale(catalog, data)

  use _ <- result.try(i18n.set_user_language(
    db,
    ctx.update.chat_id,
    ctx.update.from_id,
    locale,
  ))

  // Acknowledge the button tap (best effort — a failed ack must not abort).
  let _ =
    reply.answer_callback_query(
      ctx,
      types.new_answer_callback_query_parameters(query_id),
    )

  // Re-resolve for this update so the confirmation is in the new language.
  telega_i18n.enter(catalog:, locale:)

  case reply.with_text(ctx, i18n.t(ctx, "settings.language_set", [])) {
    Ok(_) -> Ok(ctx)
    Error(err) -> Error("Failed to confirm language: " <> string.inspect(err))
  }
}

fn language_keyboard() -> keyboard.InlineKeyboard {
  let callback_data = keyboard.string_callback_data("lang")

  let buttons =
    i18n.supported_locales
    |> list.filter_map(fn(locale) {
      keyboard.inline_button(
        language_label(locale),
        keyboard.pack_callback(callback_data, locale),
      )
    })

  keyboard.new_inline([buttons])
}

fn language_label(locale: String) -> String {
  case locale {
    "ru" -> "🇷🇺 Русский"
    "en" -> "🇬🇧 English"
    _ -> locale
  }
}

/// Extract the locale from `lang:<locale>` callback data, falling back to the
/// default if it is unknown.
fn parse_locale(catalog: Catalog, data: String) -> String {
  let candidate = case string.split(data, ":") {
    [_prefix, locale, ..] -> locale
    _ -> data
  }
  case list.contains(i18n.supported_locales, candidate) {
    True -> candidate
    False -> telega_i18n.default_locale(catalog)
  }
}
