# Testing Telegram Bots with Telega

Telega provides a built-in testing toolkit under `telega/testing/` for writing integration and unit tests without hitting the real Telegram API.

## Modules Overview

| Module | Purpose |
|--------|---------|
| `telega/testing/conversation` | Declarative DSL for multi-message conversation tests |
| `telega/testing/handler` | Isolated handler testing and `with_test_bot` helper |
| `telega/testing/mock` | Mock Telegram client with API call recording and assertions |
| `telega/testing/factory` | Deterministic test data factories (users, chats, messages, updates) |
| `telega/testing/context` | Test config and context builders |

## Quick Start

### Conversation DSL

The highest-level API. Chain `send` and `expect_*` steps, then `run` against your router:

```gleam
import telega/testing/conversation

pub fn greeting_flow_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Hello")
  |> conversation.send("/set_name")
  |> conversation.expect_reply("What's your name?")
  |> conversation.send("Alice")
  |> conversation.expect_reply("Your name is: Alice set!")
  |> conversation.run(build_router(), fn() { MySession(name: "Unknown") })
}
```

### Available Steps

| Step | Description |
|------|-------------|
| `send(text)` | Send text message (auto-detects `/commands`) |
| `send_callback(data)` | Send callback query with data |
| `send_photo()` / `send_photo_with(photos)` | Send photo message (default or custom) |
| `send_video()` / `send_video_with(video)` | Send video message (default or custom) |
| `send_audio()` / `send_audio_with(audio)` | Send audio message (default or custom) |
| `send_voice()` / `send_voice_with(voice)` | Send voice message (default or custom) |
| `send_message(message)` | Send a raw `Message` update |
| `expect_reply(text)` | Assert exact text match |
| `expect_reply_containing(substring)` | Assert text contains substring |
| `expect_keyboard(buttons: [...])` | Assert reply has inline keyboard with given button texts |
| `expect_reply_with_keyboard(containing: text, buttons: [...])` | Assert both text and keyboard buttons |
| `expect_api_call(path_contains: path, body_contains: body)` | Assert a raw API call was made |

### Keyboard Assertions

Verify that your bot sends inline keyboards with expected buttons:

```gleam
pub fn confirmation_keyboard_test() {
  conversation.conversation_test()
  |> conversation.send("/confirm")
  |> conversation.expect_reply_with_keyboard(
    containing: "Please confirm",
    buttons: ["Yes", "No"],
  )
  |> conversation.run(build_router(), default_session)
}
```

### API Call Assertions

Check specific API call parameters (path, body content):

```gleam
pub fn api_call_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_api_call(
    path_contains: "sendMessage",
    body_contains: "Welcome",
  )
  |> conversation.run(build_router(), default_session)
}
```

### Sending Media in Conversation Tests

Test flows that use `wait_photos`, `wait_voice`, etc.:

```gleam
import telega/testing/conversation
import telega/testing/factory

pub fn photo_upload_flow_test() {
  conversation.conversation_test()
  |> conversation.send("/upload")
  |> conversation.expect_reply("Please send a photo")
  |> conversation.send_photo()
  |> conversation.expect_reply_containing("received your photo")
  |> conversation.run(build_router(), fn() { Nil })
}

pub fn voice_message_test() {
  conversation.conversation_test()
  |> conversation.send("/record")
  |> conversation.expect_reply("Send a voice message")
  |> conversation.send_voice()
  |> conversation.expect_reply_containing("Got your voice")
  |> conversation.run(build_router(), fn() { Nil })
}

// Use _with variants for custom media
pub fn custom_photo_test() {
  let photos = [
    factory.photo_size_with(file_id: "high_res"),
    factory.photo_size_with(file_id: "low_res"),
  ]
  conversation.conversation_test()
  |> conversation.send("/upload")
  |> conversation.expect_reply("Please send a photo")
  |> conversation.send_photo_with(photos)
  |> conversation.expect_reply_containing("received")
  |> conversation.run(build_router(), fn() { Nil })
}
```

## Isolated Handler Testing

Test a single handler without the router or actor system:

```gleam
import telega/testing/handler
import telega/testing/factory
import telega/testing/mock

pub fn my_handler_test() {
  let update = factory.command_update("start")
  let #(result, calls) =
    handler.test_handler(
      session: MySession(name: "Unknown"),
      update:,
      handler: fn(ctx, _update) {
        start_command_handler(ctx, factory.command(command: "start"))
      },
    )

  let assert Ok(_ctx) = result
  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendMessage",
      body_contains: "Hello",
    )
  Nil
}
```

## Full Bot Testing with `with_test_bot`

Spin up a complete bot (router + registry + actors) backed by a mock client:

```gleam
import telega/testing/handler
import telega/testing/factory
import telega/testing/mock
import telega/bot

pub fn full_bot_test() {
  handler.with_test_bot(
    router: build_router(),
    session: fn() { MySession(name: "Unknown") },
    handler: fn(bot_subject, calls) {
      let update = factory.command_update("start")
      bot.handle_update(bot_subject:, update:)

      let _ =
        mock.assert_called_with_body(
          from: calls,
          path_contains: "sendMessage",
          body_contains: "Hello",
        )
      Nil
    },
  )
}
```

## Mock Client Assertions

The `mock` module provides API call recording and assertions:

```gleam
import telega/testing/mock

// Create a mock client that returns valid Message responses
let #(client, calls) = mock.message_client()

// After running your bot logic...

// Assert exact number of API calls (drains the calls subject)
let _ = mock.assert_call_count(from: calls, expected: 2)

// Assert a call was made to a specific path
let _ = mock.assert_called_with_path(from: calls, path_contains: "sendMessage")

// Assert a call with specific path AND body content
let _ = mock.assert_called_with_body(
  from: calls,
  path_contains: "sendMessage",
  body_contains: "Hello",
)

// Assert no calls were made
mock.assert_no_calls(from: calls)
```

> **Important:** `get_calls`, `assert_call_count`, `assert_called_with_path`, and `assert_called_with_body` all drain the calls subject. Don't chain multiple drain-based assertions on the same subject — pick one that covers what you need.

### Routed Mock Client

Use `mock.routed_client` for MSW-like request routing — different API endpoints return different responses:

```gleam
import gleam/json
import telega/testing/mock
import telega/testing/conversation

pub fn routed_mock_test() {
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "sendMessage",
        response: mock.message_response(),
      ),
      mock.route_with_response(
        path_contains: "answerCallbackQuery",
        response: mock.bool_response(),
      ),
      mock.route_with_response(
        path_contains: "getFile",
        response: mock.ok_response(result: json.object([
          #("file_id", json.string("abc")),
          #("file_unique_id", json.string("abc_u")),
          #("file_path", json.string("photos/abc.jpg")),
        ])),
      ),
    ])

  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Hello")
  |> conversation.run_with_mock(build_router(), fn() { Nil }, client, calls)
}
```

Unmatched requests fall back to a default `message_response()`.

### Stateful Mock Client

Use `mock.stateful_client` when responses depend on call order:

```gleam
import gleam/http/response
import telega/testing/mock

pub fn stateful_mock_test() {
  let #(client, calls) =
    mock.stateful_client(handler: fn(_req, call_index) {
      let body = case call_index {
        1 -> mock.bool_response()
        _ -> mock.message_response()
      }
      Ok(response.new(200) |> response.set_body(body))
    })

  // Use client + calls with conversation.run_with_mock or handler.with_test_bot
  Nil
}
```

## Factories

Create deterministic test data:

```gleam
import telega/testing/factory

// Updates
let text = factory.text_update(text: "hello")
let cmd = factory.command_update("start")
let cmd_with_payload = factory.command_update_with(
  command: "set",
  payload: Some("value"),
  from_id: 123,
  chat_id: 456,
)
let callback = factory.callback_query_update(data: "action:confirm")

// Media updates
let photo = factory.photo_update()
let video = factory.video_update()
let audio = factory.audio_update()
let voice = factory.voice_update()
let msg_update = factory.message_update(message: factory.photo_message(photos: [factory.photo_size()]))

// Media types
let photo_size = factory.photo_size()
let audio_obj = factory.audio_with(file_id: "my_audio", duration: 10)
let video_obj = factory.video()
let voice_obj = factory.voice()

// Media messages
let photo_msg = factory.photo_message(photos: [photo_size])
let video_msg = factory.video_message(video: video_obj)

// Lower-level types
let user = factory.user()
let chat = factory.chat()
let message = factory.message(text: "hello")
let bot = factory.bot_user()
```

## Database-Dependent Tests

For tests that need a database (e.g., flow persistence), use a helper pattern:

```gleam
fn with_db(test_fn: fn(pog.Connection) -> Nil) -> Nil {
  case test_db.try_connect_and_setup() {
    None -> Nil  // Gracefully skip when DB unavailable
    Some(db) -> {
      test_fn(db)
      test_db.cleanup(db)
    }
  }
}

pub fn my_db_test() {
  use db <- with_db
  let router = build_router(config, db)
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("Welcome")
  |> conversation.run(router, fn() { Nil })
}
```

## Testing Patterns Summary

| Scenario | Tool |
|----------|------|
| Multi-message conversation flows | `conversation.conversation_test()` DSL |
| Media-heavy flows (photo/video/audio/voice) | `conversation.send_photo()`, `send_video()`, etc. |
| Single handler logic | `handler.test_handler()` |
| Full bot with actors | `handler.with_test_bot()` |
| Keyboard presence | `conversation.expect_keyboard()` |
| API call parameters | `conversation.expect_api_call()` or `mock.assert_called_with_body()` |
| Endpoint-specific mock responses | `mock.routed_client(routes: [...])` |
| Call-order-dependent responses | `mock.stateful_client(handler: fn(req, n) { ... })` |
| Custom client in conversation DSL | `conversation.run_with_mock(...)` or `conversation.run_with_client(...)` |
| Session state | Check `ctx.session` from `handler.test_handler()` result |
