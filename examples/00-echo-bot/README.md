# Telega Echo Bot with Long Polling

A simple echo bot that responds to text messages and commands using Telegram's long polling.

## Setup

1. Get a bot token from [@BotFather](https://t.me/BotFather) on Telegram
2. Set the token as an environment variable: `export BOT_TOKEN="your_bot_token_here"`

## Running the bot

```sh
gleam run   # Start the bot
gleam test  # Run the tests
```

## How it works

This bot demonstrates the simplest possible Telegram bot using long polling:

1. **Echo Handler**: Responds to text messages by echoing them back
2. **Command Handler**: Responds to commands by showing the command text
3. **Long Polling**: Uses `polling.init_polling_default()` to receive updates
4. **No Session State**: Uses `init_nil_session()` for stateless operation

The bot will:
- Echo back any text message you send
- Respond to commands like `/start` or `/help`
- Ignore other types of updates (photos, documents, etc.)

## Key Features Demonstrated

- ✅ Long polling instead of webhooks (no server setup needed)
- ✅ Basic message handling
- ✅ Command processing
- ✅ Environment variable configuration
- ✅ Logging with context
- ✅ Stateless bot operation

This is the simplest way to get started with a Telegram bot using Telega!
