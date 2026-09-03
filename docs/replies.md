# Replies: shortcuts, entities and streaming

`telega/reply` sends things to the chat of the current update. Most of it is a
thin, complete wrapper over the corresponding `telega/api` call — `with_photo`,
`with_poll`, `with_invoice` and friends take the full parameter record. This
guide covers the parts that are not thin: the shortcuts a handler reaches for
every time, the escape-free way to format text, and streaming an answer into a
single message.

## Shortcuts

`reply.text` sends a message and hands the context straight back, which is the
shape a handler wants:

```gleam
fn handle_text(ctx, text) {
  reply.text(ctx, "You said: " <> text)
}
```

No `let assert`, no `Message` to thread through a handler that does not need
one. The failure is a `TelegaError`, so a router built out of these shortcuts
has `TelegaError` as its error type; a bot with an error type of its own keeps
using `with_text` and maps the error itself.

| Shortcut | What it does |
| --- | --- |
| `reply.text(ctx, text)` | Send, return the context unchanged |
| `reply.quote(ctx, text)` | Send as a reply to the incoming message |
| `reply.remove_keyboard(ctx, text)` | Send and take the custom keyboard off screen |
| `reply.edit_callback_message(ctx, text)` | Replace the text of the message the pressed button sits on |
| `reply.edit_callback_markup(ctx, text, markup)` | The same, and replace the inline keyboard |
| `reply.answer_toast(ctx, text)` | Answer the callback query with a notification |
| `reply.answer_alert(ctx, text)` | Answer it with a modal the user must dismiss |
| `reply.answer_quietly(ctx)` | Answer it with nothing — just stop the spinner |

The four callback shortcuts need a callback query in `ctx.update` and return an
error otherwise; silently sending a new message instead would be worse than
refusing. Every callback query must be answered, or the client keeps a spinner
on the button for a minute.

`quote` on an update that is not about a message (an inline query, a poll
answer) has nothing to quote, so it sends the text plainly.

## Entities instead of a parse mode

A parse mode makes characters special, and anything a user typed then has to be
escaped — one missed `_` breaks the whole message. The alternative is to send
the text raw and describe the formatting positionally:

```gleam
import telega/format as fmt

let document =
  fmt.build()
  |> fmt.text("Found: ")
  |> fmt.bold_text(whatever_the_user_typed)
  |> fmt.to_formatted()

reply.with_entities(ctx, document)
```

No parse mode is sent, so no character in the text is special. `format.entities`
does the same conversion outside of `reply`:

```gleam
let #(text, entities) = format.entities(document)
```

Offsets and lengths are in UTF-16 code units, as the Bot API requires — an emoji
outside the BMP counts as two. A zero-length segment produces no entity
(Telegram rejects those), a `Mention` renders as `@username` with a `mention`
entity over it, and a nested group contributes its children's entities without
one of its own.

## Streaming

An LLM produces tokens faster than Telegram lets anyone edit a message.
`reply.stream_text` collects them and flushes on a clock:

```gleam
import gleam/yielder

fn handle_prompt(ctx, prompt) {
  use _ <- result.try(reply.stream_text(
    ctx,
    chunks: llm_tokens(prompt),
    every_ms: 700,
  ))
  Ok(ctx)
}
```

`chunks` is any `Yielder(String)`, pulled to exhaustion. The first chunk sends a
message at once — the user should not sit through a window of silence — and
after that the message is edited at most once per `every_ms`, with a `▌` cursor
appended so it reads as "still writing". A final edit drops the cursor and shows
the complete text. Four hundred tokens cost a handful of API calls, not four
hundred.

`reply.stream_into` fills in a message that already exists, which is the shape a
real assistant wants: answer immediately so the user knows they were heard, then
write into that same message.

```gleam
use placeholder <- result.try(reply.with_text(ctx, "Thinking…"))
use _ <- result.try(reply.stream_into(
  ctx,
  message_id: placeholder.message_id,
  chunks: llm_tokens(prompt),
  every_ms: 700,
))
```

Pick `every_ms` above Telegram's per-chat pacing. Below ~500 ms in a private
chat the edits queue up behind the rate limiter and the animation stutters;
700 ms is a good default.

Edits that fail while the stream runs are swallowed: a flood wait halfway
through must not cost the user the answer, and the next flush carries the text
the failed one would have. The first send and the final edit are not — their
failure is returned. A stream that produces no text sends nothing and is an
error, since Telegram has no empty message to return.

Working example: [`examples/07-streaming-bot`](../examples/07-streaming-bot).
