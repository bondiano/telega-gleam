# Conversation API

Low-level conversation API for building interactive message handlers with `wait_*` functions.

> **Looking for structured conversation management?** Check out the [Conversation Flows](./conversation-flows.md) guide for high-level flow modules with persistent state.

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
  use _ <- try(reply.with_text(ctx, "What's your name?"))

  // Wait for user's text response
  use ctx, name <- wait_text(ctx, or: None, timeout: None)

  // Handle the response
  reply.with_text(ctx, "Hello, " <> name <> "!")
})
```

> `reply.with_text` returns `Result(Message, _)`, so chain it with `use _ <- try(...)`
> (from `gleam/result`). Only the `wait_*` functions hand you back an updated `ctx`.

Under the hood, Telega uses the BEAM actor model to pause the execution of your handler at each `wait_*` call, resuming it when the expected message type arrives.

> **Important:** Each `wait_*` call only pauses the current chat actor (identified by `{chat_id}:{from_id}`). Other users and chats continue to be handled concurrently. Think of it like `await` in async code — it yields the current "coroutine" (actor) but doesn't block the event loop or other conversations.

## Available Wait Functions

### Basic Wait Functions

- **`wait_any`**: Waits for any update
- **`wait_command`**: Waits for a specific command
- **`wait_commands`**: Waits for one of multiple commands
- **`wait_text`**: Waits for a text message
- **`wait_hears`**: Waits for text matching a pattern
- **`wait_message`**: Waits for any message
- **`wait_callback_query`**: Waits for callback query from inline keyboard
- **`wait_voice`**: Waits for voice message
- **`wait_audio`**: Waits for audio message
- **`wait_video`**: Waits for video message
- **`wait_photos`**: Waits for photo message

### Enhanced Wait Functions (Forms API)

These functions provide built-in validation and error handling:

#### `wait_number` - Validated Number Input

Wait for a number with automatic validation:

```gleam
use ctx, age <- wait_number(
  ctx,
  min: Some(0),
  max: Some(120),
  or: Some(bot.HandleText(fn(ctx, invalid) {
    reply.with_text(ctx, "Please enter valid age (0-120)")
  })),
  timeout: None,
)
```

**Parameters:**
- `min`: Optional minimum value
- `max`: Optional maximum value
- `or`: Handler for invalid input
- `timeout`: Optional timeout in milliseconds

#### `wait_email` - Email Validation

Wait for email with regex validation:

```gleam
use ctx, email <- wait_email(
  ctx,
  or: Some(bot.HandleText(fn(ctx, invalid) {
    reply.with_text(ctx, "Invalid email format. Try again.")
  })),
  timeout: None,
)
```

**Pattern**: `^[^\s@]+@[^\s@]+\.[^\s@]+$`

#### `wait_choice` - Multiple Choice Selection

Create inline keyboard and wait for user selection:

```gleam
use ctx, color <- wait_choice(
  ctx,
  text: "Pick a color",
  options: [
    #("🔴 Red", Red),
    #("🔵 Blue", Blue),
    #("🟢 Green", Green),
  ],
  or: None,
  timeout: None,
)
```

**Features:**
- Sends `text` together with the generated inline keyboard
- Maps selection back to typed value
- Handles invalid selections
- If the prompt cannot be sent, logs the error and returns `Ok(ctx)` instead of
  waiting for a press that will never arrive

#### `wait_for` - Custom Filter

Wait for update matching custom filter:

```gleam
use ctx, photo_update <- wait_for(
  ctx,
  filter: fn(upd) {
    case upd {
      update.PhotoUpdate(..) -> True
      _ -> False
    }
  },
  or: Some(bot.HandleAll(fn(ctx, wrong_update) {
    reply.with_text(ctx, "Please send a photo")
  })),
  timeout: Some(60_000),
)
```

## Common Parameters

Each wait function accepts these common parameters:

- **`ctx`**: The current context
- **`or`**: Optional handler for updates the wait did not ask for (use `Some(handler)` to specify one)
- **`timeout`**: Optional timeout in milliseconds (use `Some(ms)` to set a timeout)
- **`continue`**: A function to handle the expected update

The `or` handler covers both kinds of mismatch: an update of the wrong type
(a photo while waiting for text), and an update of the right type that fails
the wait's own filter — a different command than `wait_command` asked for, text
that no `wait_hears` pattern matches, callback data the `wait_callback_query`
regexp rejects, an update rejected by `wait_for`/`wait_filtered`. After `or`
runs the conversation keeps waiting, so the user can try again; without an `or`
handler the update is simply ignored and reported as unhandled.

## Examples

### Basic Name Collection

```gleam
fn set_name_command_handler(ctx, _) {
  // Ask for a name
  use _ <- try(reply.with_text(ctx, "What's your name?"))

  // Wait for text response
  use ctx, name <- wait_text(ctx, or: None, timeout: None)

  // Confirm and store the name
  use _ <- try(reply.with_text(ctx, "Your name is: " <> name <> " set!"))
  bot.next_session(ctx, NameBotSession(name: name))
}
```

### Registration Form with Validation

```gleam
fn registration_handler(ctx, _cmd) {
  // Collect age with validation
  use _ <- try(reply.with_text(ctx, "Let's register! What's your age?"))

  use ctx, age <- wait_number(
    ctx,
    min: Some(13),
    max: Some(120),
    or: Some(bot.HandleText(fn(ctx, invalid) {
      reply.with_text(ctx, "Invalid age. Please enter 13-120")
    })),
    timeout: None,
  )

  // Collect email with validation
  use _ <- try(reply.with_text(ctx, "What's your email?"))

  use ctx, email <- wait_email(
    ctx,
    or: Some(bot.HandleText(fn(ctx, invalid) {
      reply.with_text(ctx, "Invalid email. Try again.")
    })),
    timeout: None,
  )

  // Select plan
  use ctx, plan <- wait_choice(
    ctx,
    text: "Choose your plan:",
    options: [
      #("🆓 Free", Free),
      #("💎 Premium", Premium),
      #("🚀 Enterprise", Enterprise),
    ],
    or: None,
    timeout: None,
  )

  // Complete
  reply.with_text(ctx, "Registration complete! Age: "
    <> int.to_string(age)
    <> ", Email: " <> email)
}
```

### With Fallback Handler

```gleam
use ctx, text <- wait_hears(
  ctx,
  telega_keyboard.hear(keyboard),
  or: Some(bot.HandleAll(fn(ctx, other_update) {
    reply.with_text(ctx, "Please use the keyboard buttons")
  })),
  timeout: None,
)
```

### With Timeout

```gleam
let assert Ok(filter) = telega_keyboard.filter_inline_keyboard_query(keyboard)

use ctx, payload, callback_query_id <- wait_callback_query(
  ctx,
  filter: Some(filter),
  or: None,
  timeout: Some(30_000),  // 30 seconds
)
```

`filter_inline_keyboard_query` returns `Result(CallbackQueryFilter, String)`, so
unwrap it first and pass `Some(filter)` — the `filter:` parameter is an `Option`.

Conversation will be stopped after 30 seconds of waiting for a callback query, and normal handler execution will continue.

## Advanced Features

- **Context Handling**: Each wait function returns an updated context along with the requested data
- **Fallback Handlers**: Use the `or` parameter to handle unexpected message types
- **Timeouts**: Set the `timeout` parameter to automatically cancel conversations after a period of inactivity
- **Session Management**: Conversations work seamlessly with session management to store data between messages
- **Error Handling**: Use `try` to handle potential errors in your conversation flow

## Conversations and chat instance lifetime

A conversation lives in the memory of the chat instance process that runs it, so
it survives for as long as that process does. Two settings bound that:

- The `timeout` of each `wait_*` call (milliseconds): once it passes, the next
  update is routed normally again instead of resuming the conversation.
- `telega.with_chat_idle_timeout(ms)`: an instance that has received nothing for
  that long is stopped and its pending conversation is dropped. Only in-memory
  state is lost — the session is re-read from storage for the next update. Pick
  an idle timeout comfortably larger than the conversation timeouts you use, or
  keep long-lived, restart-safe state in a [flow](./conversation-flows.html)
  instead.

## Best Practices

1. **Keep conversations focused**: Design conversations for specific tasks with clear endpoints
2. **Handle timeouts**: Consider what happens if a user doesn't respond by setting appropriate timeouts
3. **Provide fallback handlers**: Use the `or` parameter to handle unexpected message types
4. **Provide exit commands**: Allow users to exit conversations gracefully (e.g., `/cancel`)
5. **Use session storage**: Store conversation state in the session
6. **Use validation**: Take advantage of `wait_number`, `wait_email`, `wait_choice` for better UX
7. **Clear error messages**: Provide helpful feedback when validation fails
