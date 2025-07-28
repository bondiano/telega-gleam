# Telega Bot With Keyboard

```sh
gleam run   # Run the server
gleam test  # Run the tests
```

This example demonstrates keyboard functionality in Telega, including both reply keyboards and inline keyboards with callback data. It showcases the new **builder pattern API** for creating keyboards.

## Features Demonstrated

### 1. Reply Keyboards
The bot creates custom keyboards that replace the user's default keyboard:

```gleam
// Using the new builder pattern API
pub fn new_keyboard(lang) {
  let keyboard_result = case lang {
    Russian -> keyboard.builder()
      |> keyboard.text(t_english_button_text(lang))
      |> keyboard.build()
    English -> keyboard.builder()
      |> keyboard.text(t_russian_button_text(lang))
      |> keyboard.build()
  }

  keyboard_result
  |> keyboard.one_time()
}
```

### 2. Inline Keyboards with Callbacks
The bot creates inline keyboards with callback data for interactive buttons:

```gleam
// Using the new builder pattern API
pub fn new_inline_keyboard(lang, callback_data) {
  let russian_callback = keyboard.pack_callback(callback_data, Russian)
  let english_callback = keyboard.pack_callback(callback_data, English)
  
  let assert Ok(keyboard_result) = {
    use builder <- result.try(keyboard.inline_builder()
      |> keyboard.inline_text(t_russian_button_text(lang), russian_callback))
    use builder <- result.try(keyboard.inline_text(builder, t_english_button_text(lang), english_callback))
    Ok(keyboard.inline_build(builder))
  }
  
  keyboard_result
}
```

### 3. Typed Callback Data
The example uses typed callback data for type-safe button interactions:

```gleam
pub fn build_keyboard_callback_data() {
  keyboard.new_callback_data(
    id: keyboard_id,
    serialize: serialize_language,
    deserialize: deserialize_language,
  )
}
```

## Builder Pattern Benefits

The new builder pattern API provides several advantages over the traditional array-based approach:

- **🔥 Readability**: Code follows logical flow
- **⚡ Flexibility**: Easy to add/remove buttons conditionally 
- **🛡️ Type Safety**: Maintained with improved ergonomics
- **🚀 Modern API**: Similar to Grammy/GramIO patterns

## Commands

- `/start` - Initialize bot and set commands
- `/lang` - Show reply keyboard for language selection
- `/lang_inline` - Show inline keyboard for language selection
