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
| `telega/testing/render` | Pure canonicalizers for snapshot testing (API-call transcripts, keyboard grids) |
| `telega/testing/graph` | Navigation graph of a dialog or flow, exported as Graphviz DOT or Mermaid |

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

## Testing with Dependencies

If your bot injects services through the `dependencies` slot (see the
[Dependency Injection guide](https://hexdocs.pm/telega/docs/dependency-injection.html)),
substitute mocks in tests.

For isolated handler tests, build the context with `context_with_dependencies`:

```gleam
import telega/testing/context

pub fn my_bookings_test() {
  let ctx =
    context.context_with_dependencies(
      session: Nil,
      dependencies: Deps(db: mock_db(), catalog: test_catalog()),
    )

  let assert Ok(_) = my_bookings(ctx, command)
}
```

For full actor-level tests, the runners take a `dependencies` value:

```gleam
// conversation DSL
conversation.conversation_test()
|> conversation.send("/my_bookings")
|> conversation.expect_reply_containing("No bookings")
|> conversation.run_with_dependencies(build_router(), fn() { Nil }, Deps(db:, catalog:))

// or the bot subject directly
handler.with_test_bot_with_dependencies(
  router: build_router(),
  session: fn() { Nil },
  dependencies: Deps(db:, catalog:),
  handler: fn(bot_subject, calls) { /* ... */ },
)

// custom mock client + dependencies, or full control over every input:
conversation.run_with_mock_with_dependencies(build_router(), fn() { Nil }, client, calls, Deps(db:, catalog:))
handler.with_test_bot_advanced_with_dependencies(
  router_handler:,
  session_settings:,
  dependencies: Deps(db:, catalog:),
  handler:,
)
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

## Snapshot Testing

For tests where the interesting output is *everything the user sees* — message
text, keyboard layout, the exact sequence of API calls — assert-by-substring
gets verbose and misses regressions. Instead, snapshot the full canonical
output with a snapshot library like [birdie](https://hexdocs.pm/birdie) and
review diffs on change.

`telega/testing/render` provides pure canonicalizers (plain `String` output,
no dependency on any snapshot library):

| Function | Output |
|----------|--------|
| `calls_transcript(calls)` | Numbered list of recorded API calls: method name + canonical JSON body (token stripped, keys sorted) |
| `keyboard_grid(markup)` | ASCII grid of an inline keyboard: `[ text ](payload)` cells, one row per line |
| `formatted_frame(formatted)` | Parse mode header + rendered text of a `format.FormattedText` |
| `window_frame(window)` | Full visible frame of a dialog window: parse mode, media, text, button grid (see [dialogs.md](./dialogs.md) § Testing) |
| `canonical_json(string)` | Any JSON re-serialized with sorted keys and stable indentation |

### Example: snapshot a whole interaction

```gleam
import birdie
import telega/testing/mock
import telega/testing/render

pub fn start_command_transcript_test() {
  let #(client, calls) = mock.message_client()
  // ... drive your bot with the mock client ...

  mock.get_calls(calls)
  |> render.calls_transcript
  |> birdie.snap(title: "my_bot:start:transcript")
}
```

The first run records the snapshot; review and accept it with
`gleam run -m birdie` (or `gleam run -m birdie accept`). Accepted snapshots
live in `test/birdie_snapshots/` and belong in git. On any behavior change the
test fails with a diff — review it like a code change.

### Example: snapshot a keyboard

```gleam
import birdie
import telega/keyboard
import telega/model/types.{SendMessageReplyInlineKeyboardMarkupParameters}
import telega/testing/render

pub fn menu_keyboard_test() {
  let assert SendMessageReplyInlineKeyboardMarkupParameters(markup) =
    keyboard.to_inline_markup(build_menu_keyboard())

  render.keyboard_grid(markup)
  |> birdie.snap(title: "my_bot:menu:keyboard")
}
```

### Conventions

- Snapshot titles: `"<module>:<entity>:<case>"` (e.g. `format:daily_report:html`). Birdie requires globally unique titles — one test, one snapshot.
- Keep snapshots deterministic: use `telega/testing/factory` data (fixed ids and dates) and the mock client (token never reaches the transcript).
- Localized bots: pin the same frame once per locale (suffix the title:
  `booking:confirm:frame_en` / `frame_ru`). With `telega_i18n`, wrap the
  render in `telega_i18n.enter(catalog:, locale:)` / `leave()` — see
  `examples/06-restaurant-booking/test/booking_dialog_test.gleam`.
- CI: `gleam test` fails on unaccepted snapshots, so a snapshot diff can't slip through unreviewed.

## Graph Export

`telega/testing/graph` turns a dialog or a flow into a navigation graph and
renders it as Graphviz DOT or Mermaid — the whole set of windows and the
transitions between them, without running the bot:

```gleam
import gleam/io
import telega/testing/context
import telega/testing/graph

pub fn main() {
  graph.of_dialog(dialog: booking_dialog(), ctx: context.context(session: Nil))
  |> graph.to_dot
  |> io.println
}
```

```sh
gleam run -m my_bot/graph > booking.dot && dot -Tsvg booking.dot -o booking.svg
```

### Dialogs are probed

A window's `render` is pure and its handlers are pure functions of the state,
so the exporter can just run them: it renders every window, presses every
button it finds and records where the returned `DialogAction` points.

- Widget buttons are routed to the widget's `on_event` exactly the way the
  engine routes them, so `select`/`radio` navigation shows up too.
- Sub-dialogs are entered through the sub's own `init`/`result`, so their
  windows are probed with real sub state, and a sub's `Done` is drawn back to
  the window that started it (its `on_sub_result` is probed as well).
- `Back` targets depend on history, so they point at a single `back` node and
  are drawn dashed.

Probing sees one state at a time, and a text window that validates its input
only ever draws the re-render for a sample it rejects. Pass states and texts
your handlers accept:

```gleam
graph.of_dialog_probing(
  dialog: booking_dialog(),
  ctx: context.context(session: Nil),
  states: [Booking(..empty, table: Some("t1"))],
  texts: ["Ivan", ""],
)
```

Probing **runs your handlers**. Windows are pure by contract, but a handler
that writes to a database or calls the API on its way to a `Done` will do
exactly that while the graph is built. Give it a test context — the mock
client and the test database — never a production one.

### Flows are declarative

A flow's transitions are returned by its step handlers (`Next`, `GoTo`,
`Complete`), and handlers are effectful — they send messages — so they are
never called. `graph.of_flow` draws what the builder knows: steps, conditional
branches (`if #1` / `else`), parallel fan-out and join, subflows (as a cluster
with its own `return` node), and every transition the author declared:

```gleam
|> builder.add_step(AskName, ask_name)
|> builder.declare_next(from: AskName, to: AskEmail)
|> builder.declare_complete(from: Publish)
```

Declarations are documentation, not behaviour — the engine ignores them (see
[conversation-flows.md](./conversation-flows.md) § Declaring Transitions), and
`builder.declaration_errors(flow)` keeps them from drifting after a rename.
A step with no declared outgoing edge is marked `OpaqueNode` and drawn dashed:
the honest signal that its navigation is only visible in the handler.

### Snapshot the graph

Both renderers produce deterministic strings (nodes and edges are sorted), so
the graph snapshots like any other frame — a changed navigation path shows up
as a diff in review:

```gleam
pub fn booking_graph_test() {
  graph.of_dialog(dialog: booking_dialog(), ctx: context.context(session: Nil))
  |> graph.to_mermaid
  |> birdie.snap(title: "booking:dialog:graph")
}
```

Mermaid output renders inline in GitHub and in `docs/` pages without a local
Graphviz; DOT gives better layout control for large dialogs.

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
| Full visible output (text + keyboards + call sequence) | `telega/testing/render` + birdie snapshots |
| Whole navigation map of a dialog or flow | `telega/testing/graph` + `to_dot` / `to_mermaid` |
| Injected services (`dependencies`) | `context.context_with_dependencies()`, `conversation.run_with_dependencies()`, `handler.with_test_bot_with_dependencies()` |
