//// The shortcuts a handler actually reaches for, and the streaming reply.
////
//// Everything here is about which API call goes out and with what body: the
//// point of a shortcut is that the record it fills in is right, and the point
//// of the stream is that it flushes on a clock rather than per token.

import gleam/list
import gleam/string
import gleam/yielder
import gleeunit
import gleeunit/should

import telega/bot
import telega/client
import telega/error
import telega/format
import telega/reply
import telega/testing/context as testing_context
import telega/testing/factory
import telega/testing/mock
import telega/update

pub fn main() {
  gleeunit.main()
}

const chat_id = -100_500

const user_id = 888

fn context_with(
  tg_client: client.TelegramClient,
  update: update.Update,
) -> bot.Context(Nil, error.TelegaError, Nil) {
  let ctx =
    testing_context.context_with_all(
      session: Nil,
      update:,
      key: "-100500:888",
      bot_info: factory.bot_user(),
      dependencies: Nil,
    )
  bot.Context(..ctx, config: testing_context.config_with_client(tg_client))
}

fn text_context(
  tg_client: client.TelegramClient,
) -> bot.Context(Nil, error.TelegaError, Nil) {
  context_with(
    tg_client,
    factory.text_update_with(text: "hi", from_id: user_id, chat_id:),
  )
}

fn callback_context(
  tg_client: client.TelegramClient,
) -> bot.Context(Nil, error.TelegaError, Nil) {
  context_with(
    tg_client,
    factory.callback_query_update_with(
      data: "menu:1",
      from_id: user_id,
      chat_id:,
    ),
  )
}

fn bodies(calls: List(mock.ApiCall), path: String) -> List(String) {
  calls
  |> list.filter(fn(call) { string.contains(call.request.path, path) })
  |> list.map(fn(call) { call.request.body })
}

// Shortcuts

pub fn text_hands_the_context_back_test() {
  let #(tg_client, calls) = mock.message_client()
  let ctx = text_context(tg_client)

  // The whole point: a handler body with no `let assert` and no `Message` to
  // thread through.
  reply.text(ctx, "pong") |> should.equal(Ok(ctx))

  let assert [body] = bodies(mock.get_calls(calls), "sendMessage")
  body |> string.contains("\"text\":\"pong\"") |> should.be_true
}

pub fn quote_replies_to_the_incoming_message_test() {
  let #(tg_client, calls) = mock.message_client()

  let assert Ok(_) = reply.quote(text_context(tg_client), "answering that")

  let assert [body] = bodies(mock.get_calls(calls), "sendMessage")
  body |> string.contains("\"reply_parameters\"") |> should.be_true
  body
  |> string.contains("\"allow_sending_without_reply\":true")
  |> should.be_true
}

pub fn quote_without_a_message_sends_plainly_test() {
  let #(tg_client, calls) = mock.message_client()
  let ctx = context_with(tg_client, factory.inline_query_update("search"))

  let assert Ok(_) = reply.quote(ctx, "nothing to quote")

  // An inline query happens in no message, so there is nothing to reply to —
  // the text still goes out.
  let assert [body] = bodies(mock.get_calls(calls), "sendMessage")
  body |> string.contains("reply_parameters") |> should.be_false
}

pub fn remove_keyboard_sends_the_removal_markup_test() {
  let #(tg_client, calls) = mock.message_client()

  let assert Ok(_) = reply.remove_keyboard(text_context(tg_client), "done")

  let assert [body] = bodies(mock.get_calls(calls), "sendMessage")
  body |> string.contains("\"remove_keyboard\":true") |> should.be_true
}

pub fn with_entities_sends_text_verbatim_test() {
  let #(tg_client, calls) = mock.message_client()

  let document =
    format.build()
    |> format.text("Found: ")
    |> format.bold_text("*raw*")
    |> format.to_formatted()

  let assert Ok(_) = reply.with_entities(text_context(tg_client), document)

  let assert [body] = bodies(mock.get_calls(calls), "sendMessage")
  // Nothing is escaped and no parse mode is involved.
  body |> string.contains("\"text\":\"Found: *raw*\"") |> should.be_true
  body |> string.contains("\"type\":\"bold\"") |> should.be_true
  body |> string.contains("parse_mode") |> should.be_false
}

pub fn edit_callback_message_targets_the_pressed_message_test() {
  let #(tg_client, calls) = mock.message_client()

  let assert Ok(_) =
    reply.edit_callback_message(callback_context(tg_client), "updated")

  let assert [body] = bodies(mock.get_calls(calls), "editMessageText")
  body |> string.contains("\"text\":\"updated\"") |> should.be_true
  body |> string.contains("\"message_id\"") |> should.be_true
}

pub fn edit_callback_message_needs_a_callback_query_test() {
  let #(tg_client, calls) = mock.message_client()

  let assert Error(reason) =
    reply.edit_callback_message(text_context(tg_client), "updated")

  // Silently sending a new message instead would be worse than refusing.
  error.to_string(reason)
  |> string.contains("needs a callback query update")
  |> should.be_true

  mock.assert_no_calls(calls)
}

pub fn answer_alert_and_toast_differ_only_in_show_alert_test() {
  let #(tg_client, calls) =
    mock.routed_client([
      mock.route_with_response(
        path_contains: "answerCallbackQuery",
        response: mock.bool_response(),
      ),
    ])
  let ctx = callback_context(tg_client)

  let assert Ok(_) = reply.answer_toast(ctx, "saved")
  let assert Ok(_) = reply.answer_alert(ctx, "not allowed")
  let assert Ok(_) = reply.answer_quietly(ctx)

  let assert [toast, alert, quiet] =
    bodies(mock.get_calls(calls), "answerCallbackQuery")

  toast |> string.contains("\"show_alert\":false") |> should.be_true
  alert |> string.contains("\"show_alert\":true") |> should.be_true
  quiet |> string.contains("\"text\"") |> should.be_false
}

// Streaming

pub fn stream_text_flushes_on_a_clock_not_per_chunk_test() {
  let #(tg_client, calls) = mock.message_client()

  let assert Ok(_) =
    reply.stream_text(
      text_context(tg_client),
      yielder.from_list(["Hel", "lo, ", "world"]),
      // Far longer than the test takes: no chunk earns a flush of its own.
      every_ms: 60_000,
    )

  let calls = mock.get_calls(calls)

  // The first chunk shows up at once, so the user is not left staring at
  // nothing for a window.
  let assert [sent] = bodies(calls, "sendMessage")
  sent |> string.contains("\"text\":\"Hel▌\"") |> should.be_true

  // The two that follow are inside the window: they are collected, not sent,
  // and one final edit carries the finished text.
  let assert [final] = bodies(calls, "editMessageText")
  final |> string.contains("\"text\":\"Hello, world\"") |> should.be_true
}

pub fn stream_text_edits_one_message_as_it_grows_test() {
  let #(tg_client, calls) = mock.message_client()

  let assert Ok(_) =
    reply.stream_text(
      text_context(tg_client),
      yielder.from_list(["one ", "two ", "three"]),
      // Every chunk is late already, so every chunk flushes.
      every_ms: 0,
    )

  let calls = mock.get_calls(calls)

  // The first chunk sends; the rest edit the same message.
  let assert [sent] = bodies(calls, "sendMessage")
  sent |> string.contains("\"text\":\"one ▌\"") |> should.be_true

  let edits = bodies(calls, "editMessageText")
  // The last edit is the finished text, with the cursor gone.
  let assert Ok(final) = list.last(edits)
  final |> string.contains("\"text\":\"one two three\"") |> should.be_true
  final |> string.contains("▌") |> should.be_false
}

pub fn stream_text_survives_a_failed_edit_test() {
  let #(tg_client, calls) =
    mock.routed_client([
      mock.route_with_body(
        path_contains: "editMessageText",
        body: "{\"ok\":false,\"error_code\":429,\"description\":\"Too Many Requests\"}",
      ),
    ])
  // Without this the client would sleep off its own 429 backoff first.
  let tg_client = client.set_max_retry_attempts(tg_client, 0)

  let assert Error(_) =
    reply.stream_text(
      text_context(tg_client),
      yielder.from_list(["a", "b", "c"]),
      every_ms: 0,
    )

  let calls = mock.get_calls(calls)
  // The intermediate edits failed and were swallowed — the stream kept
  // collecting — and only the final edit reported the failure.
  bodies(calls, "sendMessage") |> list.length |> should.equal(1)
  { list.length(bodies(calls, "editMessageText")) > 1 } |> should.be_true
}

pub fn stream_into_edits_an_existing_message_test() {
  let #(tg_client, calls) = mock.message_client()

  let assert Ok(_) =
    reply.stream_into(
      text_context(tg_client),
      message_id: 4242,
      chunks: yielder.from_list(["thinking done"]),
      every_ms: 60_000,
    )

  // The placeholder is reused: nothing new is sent.
  let calls = mock.get_calls(calls)
  bodies(calls, "sendMessage") |> should.equal([])

  let assert Ok(final) = list.last(bodies(calls, "editMessageText"))
  final |> string.contains("\"message_id\":4242") |> should.be_true
  final |> string.contains("\"text\":\"thinking done\"") |> should.be_true
  final |> string.contains("▌") |> should.be_false
}

pub fn stream_text_of_an_empty_stream_sends_nothing_test() {
  let #(tg_client, calls) = mock.message_client()

  let assert Error(reason) =
    reply.stream_text(text_context(tg_client), yielder.empty(), every_ms: 0)

  error.to_string(reason)
  |> string.contains("produced no text")
  |> should.be_true

  mock.assert_no_calls(calls)
}
