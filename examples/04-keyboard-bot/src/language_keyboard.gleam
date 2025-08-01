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

pub fn new_keyboard(lang) {
  let keyboard_result = case lang {
    Russian ->
      keyboard.builder()
      |> keyboard.text(t_english_button_text(lang))
      |> keyboard.build()
    English ->
      keyboard.builder()
      |> keyboard.text(t_russian_button_text(lang))
      |> keyboard.build()
  }

  keyboard_result
  |> keyboard.one_time()
}

pub fn option_to_language(option) {
  case option {
    "🇷🇺 Russian" -> Russian
    "🇬🇧 Английский" -> English
    _ -> panic as "Unknown keyboard language"
  }
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
    deserialize: fn(payload) {
      case payload {
        "russian" -> Russian
        "english" -> English
        _ -> panic as "Unknown keyboard language"
      }
    },
  )
}

fn t_russian_button_text(lang) {
  case lang {
    Russian -> "✅ 🇷🇺 Русский"
    English -> "🇷🇺 Russian"
  }
}

fn t_english_button_text(lang) {
  case lang {
    Russian -> "🇬🇧 Английский"
    English -> "✅ 🇬🇧 English"
  }
}
