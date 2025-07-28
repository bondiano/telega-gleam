import telega/keyboard.{type KeyboardCallbackData}

import session.{type Language, English, Russian}

const keyboard_id = "language"

pub type LanguageInlineKeyboardData =
  KeyboardCallbackData(Language)

pub fn new_inline_keyboard(lang, callback_data) {
  let russian_callback = keyboard.pack_callback(callback_data, Russian)
  let english_callback = keyboard.pack_callback(callback_data, English)
  
  let assert Ok(russian_button) = keyboard.inline_button(
    text: t_russian_button_text(lang),
    callback_data: russian_callback,
  )
  
  let assert Ok(english_button) = keyboard.inline_button(
    text: t_english_button_text(lang),
    callback_data: english_callback,
  )
  
  keyboard.new_inline([[russian_button, english_button]])
}

pub fn new_keyboard(lang) {
  let buttons_row = case lang {
    Russian -> [keyboard.button(t_english_button_text(lang))]
    English -> [keyboard.button(t_russian_button_text(lang))]
  }

  keyboard.new([buttons_row])
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
