import gleam/result

import telega/keyboard.{type KeyboardCallbackData}

import session.{type Language, English, Russian}

const keyboard_id = "language"

pub type LanguageInlineKeyboardData =
  KeyboardCallbackData(Language)

pub fn new_inline_keyboard(lang, callback_data) {
  let russian_callback = keyboard.pack_callback(callback_data, Russian)
  let english_callback = keyboard.pack_callback(callback_data, English)

  let assert Ok(keyboard_result) = {
    use builder <- result.try(
      keyboard.inline_builder()
      |> keyboard.inline_text(t_russian_button_text(lang), russian_callback),
    )
    use builder <- result.try(keyboard.inline_text(
      builder,
      t_english_button_text(lang),
      english_callback,
    ))
    Ok(keyboard.inline_build(builder))
  }

  keyboard_result
}

pub fn build_keyboard_callback_data() {
  keyboard.new_callback_data(
    id: keyboard_id,
    serialize: fn(data) {
      case data {
        Russian -> "russian"
        English -> "english"
      }
    },
    // A payload that is neither is not this keyboard's — `unpack_callback`
    // turns the error into `Error(Nil)` instead of crashing the handler.
    deserialize: fn(payload) {
      case payload {
        "russian" -> Ok(Russian)
        "english" -> Ok(English)
        _ -> Error(Nil)
      }
    },
  )
}

pub fn t_russian_button_text(lang) {
  case lang {
    Russian -> "✅ 🇷🇺 Русский"
    English -> "🇷🇺 Russian"
  }
}

pub fn t_english_button_text(lang) {
  case lang {
    Russian -> "🇬🇧 Английский"
    English -> "✅ 🇬🇧 English"
  }
}
