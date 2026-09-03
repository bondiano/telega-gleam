//// A bot that answers the way an LLM does: one message that fills in as the
//// tokens arrive, instead of a wall of fragments or a long silence.
////
//// The model here is fake — a canned answer, chopped into words, with a pause
//// between them. Swap `answer_tokens` for your provider's token stream and
//// nothing else changes: `reply.stream_text` takes any `Yielder(String)`.

import envoy
import gleam/erlang/process
import gleam/list
import gleam/option
import gleam/result.{try}
import gleam/string
import gleam/yielder.{type Yielder}
import logging

import telega
import telega/client
import telega/error
import telega/format as fmt
import telega/reply
import telega/router
import telega/update
import telega_httpc

/// How often the growing message is edited. Telegram paces edits into a
/// private chat at one per second, so anything under ~500 ms just queues up
/// behind the rate limiter and makes the animation stutter.
const flush_every_ms = 700

fn handle_start(ctx, _command: update.Command) {
  use ctx <- telega.log_context(ctx, "start")

  // `reply.text` hands the context straight back: no `let assert`, no
  // `Message` to thread through a handler that does not need one.
  reply.text(
    ctx,
    "Send me anything and I will answer it token by token.\n\n"
      <> "/story — stream a story into a fresh message\n"
      <> "/echo <text> — echo you back with entity formatting",
  )
}

/// The plain shape: `stream_text` sends the first message itself.
fn handle_story(ctx, _command: update.Command) {
  use ctx <- telega.log_context(ctx, "story")
  use _ <- try(reply.stream_text(
    ctx,
    chunks: answer_tokens(story),
    every_ms: flush_every_ms,
  ))
  Ok(ctx)
}

/// Echo the user back through `format.entities`.
///
/// The text goes out verbatim beside a positional description of its
/// formatting, so a message full of `*`, `_` and `<b>` arrives exactly as
/// typed. With a parse mode the same text would need escaping — and one missed
/// character would break the whole message.
fn handle_echo(ctx, command: update.Command) {
  use ctx <- telega.log_context(ctx, "echo")

  let document =
    fmt.build()
    |> fmt.text("You said: ")
    |> fmt.bold_text(option.unwrap(command.payload, ""))
    |> fmt.to_formatted()

  use _ <- try(reply.with_entities(ctx, document))
  Ok(ctx)
}

/// The shape a real assistant wants: answer immediately with a placeholder so
/// the user knows they were heard, then fill that same message in.
fn handle_prompt(ctx, prompt) {
  use ctx <- telega.log_context(ctx, "prompt")

  use placeholder <- try(reply.with_text(ctx, "Thinking…"))
  use _ <- try(reply.stream_into(
    ctx,
    message_id: placeholder.message_id,
    chunks: answer_tokens(reply_to(prompt)),
    every_ms: flush_every_ms,
  ))

  Ok(ctx)
}

fn reply_to(prompt: String) -> String {
  "About “"
  <> prompt
  <> "”: a token stream arrives faster than Telegram lets anyone edit a "
  <> "message, so telega collects the tokens and flushes them on a clock. "
  <> "Four hundred tokens cost a handful of API calls, not four hundred."
}

const story = "Once upon a time a bot answered instantly, and nobody believed "
  <> "it had thought about the question at all. So it learned to write the way "
  <> "people do — a word at a time, in one message that grows."

/// Stand-in for a provider's token stream.
///
/// A real one is a `Yielder` over the SSE chunks of the completion; the only
/// thing that matters here is that it is pulled lazily and takes real time.
fn answer_tokens(answer: String) -> Yielder(String) {
  answer
  |> string.split(" ")
  |> list.map(fn(word) { word <> " " })
  |> yielder.from_list
  |> yielder.map(fn(token) {
    process.sleep(40)
    token
  })
}

pub fn build_router() -> router.Router(Nil, error.TelegaError, Nil) {
  router.new("streaming_bot")
  |> router.on_command_with_description(
    "start",
    "Show what this bot does",
    handle_start,
  )
  |> router.on_command_with_description(
    "story",
    "Stream a short story",
    handle_story,
  )
  |> router.on_command_with_description(
    "echo",
    "Echo your text back, formatting-safe",
    handle_echo,
  )
  |> router.on_any_text(handle_prompt)
}

pub fn main() {
  logging.configure()

  let assert Ok(token) = envoy.get("BOT_TOKEN")
    as "BOT_TOKEN environment variable is not set"

  let api_client =
    telega_httpc.new(token)
    // Every API call, its body and how long it took. Debugging only: request
    // bodies carry whatever the user typed.
    |> client.use_transformer(client.trace_transformer(logging.Debug))
    // `getMe` is asked for at startup and by anything that wants `bot_info`;
    // one call is enough for the life of the node.
    |> client.cache_get_me

  let assert Ok(_bot) =
    telega.new(api_client)
    |> telega.router(build_router())
    |> telega.start()

  process.sleep_forever()
}
