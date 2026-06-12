# Telega Bot With Keyboard & Formatting

```sh
gleam run   # Run the server
gleam test  # Run the tests
```

This example demonstrates keyboard functionality and text formatting in Telega, including both reply keyboards and inline keyboards with callback data, along with rich text formatting using the `telega/format` module.

It also shows three newer Telega features:

- **Rate limiting** (`router.with_rate_limit`) - per-user flood control middleware: at most 5 updates per 3 seconds, excess updates are dropped silently and emit a `telega.rate_limit.hit` telemetry event
- **Inline mode** (`telega/inline_mode`) - type `@your_bot <query>` in any chat to share a phrase from the built-in English-Russian phrasebook; results are paginated with `inline_mode.paginate`. Enable inline mode for the bot via [@BotFather](https://t.me/BotFather) (`/setinline`) first
- **Payments** (`telega/payments`) - `/donate` sells a donation for Telegram Stars: invoice via `payments.stars_invoice`, pre-checkout confirmation via `router.on_pre_checkout_query`, and `payments.wait_successful_payment` resumes the conversation once the payment goes through

## Commands

- `/start` - Initialize bot with formatted welcome message
- `/lang` - Show reply keyboard for language selection
- `/lang_inline` - Show inline keyboard for language selection
- `/donate` - Pick an amount and donate Telegram Stars
