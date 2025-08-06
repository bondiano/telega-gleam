# Telega Bot With Keyboard & Formatting

```sh
gleam run   # Run the server
gleam test  # Run the tests
```

This example demonstrates keyboard functionality and text formatting in Telega, including both reply keyboards and inline keyboards with callback data, along with rich text formatting using the `telega/format` module.

## Commands

- `/start` - Initialize bot with formatted welcome message
- `/lang` - Show reply keyboard for language selection
- `/lang_inline` - Show inline keyboard for language selection
