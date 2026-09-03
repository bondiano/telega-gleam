# Streaming Bot Example

An LLM-shaped bot: the answer arrives token by token into **one message that
grows**, instead of a wall of fragments or a long silence.

The model is faked — a canned answer, split into words, with a pause between
them. Swap `answer_tokens` for your provider's token stream and nothing else
changes: `reply.stream_text` takes any `Yielder(String)`.

## Features

- ✍️ **`reply.stream_text`** — sends the first chunk at once, then edits the
  same message on a clock (`every_ms`) until the stream ends
- 💬 **`reply.stream_into`** — answers with a "Thinking…" placeholder first, then
  fills that message in
- 🔒 **`reply.with_entities`** — echoes the user's text verbatim; nothing is
  escaped because with entities nothing is special
- 🩺 **`client.trace_transformer`** — every API call, its body, and how long it
  took
- 📇 **`client.cache_get_me`** — `getMe` answered from a cache after the first call

## Usage

```bash
export BOT_TOKEN="your_bot_token_here"
gleam run
```

### Commands

- `/start` — what the bot does
- `/story` — stream a short story into a fresh message
- `/echo <text>` — echo your text back with entity formatting
- anything else — streamed answer, into a placeholder

## Why a clock and not a token

Telegram paces edits into a private chat at roughly one per second. Editing per
token would spend the whole rate budget on animation and then queue up behind
the limiter, so `stream_text` accumulates and flushes every `every_ms` —
700 ms is a good default. Four hundred tokens cost a handful of API calls, not
four hundred.

Edits that fail mid-stream are swallowed: a flood wait halfway through must not
cost the user the answer, and the next flush carries the text the failed one
would have. The first send and the final edit do report their failure.

## Tests

```bash
gleam test
```

Runs the router against a mock client (`telega/testing/conversation`) — no
token, no network.
