# Conversation API

Low-level conversation API for building interactive message handlers with `wait_*` functions.

> **Looking for structured conversation management?** Check out the [Conversation Flows](./conversation-flows.md) guide for high-level flow modules (`dialog`, `flow`, `persistent_flow`).

## Introduction

The Conversation API provides fundamental building blocks for creating handlers that span multiple messages. It's built into Telega and leverages BEAM actor system's power to pause and resume handler execution.

This API was inspired by [grammY's conversations plugin](https://grammy.dev/plugins/conversations), adapted to take advantage of Gleam and BEAM's capabilities.

## How Conversations Work

In traditional message handlers, you only have access to a single update at a time:

```gleam
handle_command("start", fn(ctx, _) {
  reply.with_text(ctx, "Welcome!")
})
```

With conversations, you can create handlers that span multiple messages:

```gleam
handle_command("name", fn(ctx, _) {
  // First message
  reply.with_text(ctx, "What's your name?")

  // Wait for user's text response
  use ctx, name <- wait_text(ctx, or: None, timeout: None)

  // Handle the response
  reply.with_text(ctx, "Hello, " <> name <> "!")
})
```

Under the hood, Telega uses the BEAM actor model to pause the execution of your handler at each `wait_*` call, resuming it when the expected message type arrives.

## Using Conversations

To start a conversation, you just need to call any of the `wait_*` functions within your handler.

### Available Wait Functions

All wait functions stop the current handler execution and wait for a specific type of update from the user:

- `wait_any`: Waits for any update
- `wait_command`: Waits for a specific command
- `wait_commands`: Waits for one of multiple commands
- `wait_text`: Waits for a text message
- `wait_hears`: Waits for text matching a pattern
- `wait_message`: Waits for any message
- `wait_callback_query`: Waits for callback query from inline keyboard
- `wait_voice`: Waits for voice message
- `wait_audio`: Waits for audio message
- `wait_video`: Waits for video message
- `wait_photos`: Waits for photo message
- `wait_web_app_data`: Waits for web app data

### Common Parameters

Each wait function accepts these common parameters:

- `ctx`: The current context
- `continue`: A function to handle the expected update (e.g., text message, command)
- `or`: Optional handler for other types of updates (use `Some(handler)` to specify one)
- `timeout`: Optional timeout in seconds (use `Some(seconds)` to set a timeout)

### Syntax Pattern

Each wait function follows this pattern:

```gleam
use ctx, data <- wait_*(ctx, or: handler_option, timeout: timeout_option)
// Continue with the conversation using updated ctx and data
```

## Examples

### Basic Usage

Here's a simple name-setting bot:

```gleam
fn set_name_command_handler(ctx, _) {
  // Ask for a name
  use _ <- try(reply.with_text(ctx, "What's your name?"))

  // Wait for text response and capture name
  use ctx, name <- telega.wait_text(ctx, or: None, timeout: None)

  // Confirm and store the name
  use _ <- try(reply.with_text(ctx, "Your name is: " <> name <> " set!"))
  bot.next_session(ctx, NameBotSession(name: name))
}
```

### With Fallback Handler

Example with fallback for handling other message types:

```gleam
use ctx, text <- telega.wait_hears(
  ctx,
  telega_keyboard.hear(keyboard),
  or: bot.HandleAll(handle_other_message) |> Some,
  timeout: None,
)
```

It will wait for a text message or a callback query from the inline keyboard. If the user sends any other message type, it will call `handle_other_message`.

### With Timeout

Example with a timeout that will cancel the conversation after 1000 seconds:

```gleam
use ctx, payload, callback_query_id <- telega.wait_callback_query(
  ctx,
  telega_keyboard.filter_inline_keyboard_query(keyboard),
  or: None,
  timeout: Some(1000),
)
```

Conversation will be stopped after 1000 seconds of waiting for a callback query. And normal handler execution will continue.

## Advanced Features

- **Context Handling**: Each wait function returns an updated context along with the requested data
- **Fallback Handlers**: Use the `or` parameter to handle unexpected message types
- **Timeouts**: Set the `timeout` parameter to automatically cancel conversations after a period of inactivity
- **Session Management**: Conversations work seamlessly with session management to store data between messages
- **Error Handling**: Use `try` to handle potential errors in your conversation flow

## Best Practices

1. **Keep conversations focused**: Design conversations for specific tasks with clear endpoints
2. **Handle timeouts**: Consider what happens if a user doesn't respond by setting appropriate timeouts
3. **Provide fallback handlers**: Use the `or` parameter to handle unexpected message types
4. **Provide exit commands**: Allow users to exit conversations gracefully
5. **Use session storage**: Store conversation state in the session
