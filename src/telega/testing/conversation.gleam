//// Declarative conversation testing DSL for integration testing bot flows.
////
//// ```gleam
//// import telega/testing/conversation
////
//// conversation.conversation_test()
//// |> conversation.send("/start")
//// |> conversation.expect_reply_containing("Hello")
//// |> conversation.send("/set_name")
//// |> conversation.expect_reply("What's your name?")
//// |> conversation.send("Alice")
//// |> conversation.expect_reply_containing("Alice")
//// |> conversation.run(router, fn() { Nil })
//// ```

import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

import telega/bot
import telega/client
import telega/internal/registry
import telega/model/types
import telega/router
import telega/testing/context as test_context
import telega/testing/factory
import telega/testing/mock
import telega/update

/// Opaque type representing a sequence of conversation test steps.
pub opaque type ConversationTest {
  ConversationTest(steps: List(Step))
}

type Step {
  SendText(text: String)
  SendCommand(command: String, payload: Option(String))
  SendCallback(data: String)
  SendPhoto(photos: List(types.PhotoSize))
  SendVideo(video: types.Video)
  SendAudio(audio: types.Audio)
  SendVoice(voice: types.Voice)
  SendMessageUpdate(message: types.Message)
  ExpectReply(text: String)
  ExpectReplyContaining(substring: String)
  ExpectKeyboard(buttons: List(String))
  ExpectReplyWithKeyboard(substring: String, buttons: List(String))
  ExpectApiCall(path_contains: String, body_contains: String)
}

/// Creates a new empty conversation test.
pub fn conversation_test() -> ConversationTest {
  ConversationTest(steps: [])
}

/// Sends a message. Text starting with `/` is auto-detected as a command.
/// Command payloads are supported: `/cmd payload here`.
pub fn send(ct: ConversationTest, text: String) -> ConversationTest {
  let step = case string.starts_with(text, "/") {
    True -> {
      let without_slash = string.drop_start(text, 1)
      case string.split_once(without_slash, " ") {
        Ok(#(cmd, payload)) -> SendCommand(command: cmd, payload: Some(payload))
        Error(_) -> SendCommand(command: without_slash, payload: None)
      }
    }
    False -> SendText(text:)
  }
  ConversationTest(steps: list.append(ct.steps, [step]))
}

/// Sends a callback query with the given data.
pub fn send_callback(ct: ConversationTest, data: String) -> ConversationTest {
  ConversationTest(steps: list.append(ct.steps, [SendCallback(data:)]))
}

/// Sends a photo message with a single default photo.
pub fn send_photo(ct: ConversationTest) -> ConversationTest {
  ConversationTest(
    steps: list.append(ct.steps, [SendPhoto(photos: [factory.photo_size()])]),
  )
}

/// Sends a photo message with custom photos.
pub fn send_photo_with(
  ct: ConversationTest,
  photos: List(types.PhotoSize),
) -> ConversationTest {
  ConversationTest(steps: list.append(ct.steps, [SendPhoto(photos:)]))
}

/// Sends a video message with a default video.
pub fn send_video(ct: ConversationTest) -> ConversationTest {
  ConversationTest(
    steps: list.append(ct.steps, [SendVideo(video: factory.video())]),
  )
}

/// Sends a video message with a custom video.
pub fn send_video_with(
  ct: ConversationTest,
  video: types.Video,
) -> ConversationTest {
  ConversationTest(steps: list.append(ct.steps, [SendVideo(video:)]))
}

/// Sends an audio message with a default audio.
pub fn send_audio(ct: ConversationTest) -> ConversationTest {
  ConversationTest(
    steps: list.append(ct.steps, [SendAudio(audio: factory.audio())]),
  )
}

/// Sends an audio message with custom audio.
pub fn send_audio_with(
  ct: ConversationTest,
  audio: types.Audio,
) -> ConversationTest {
  ConversationTest(steps: list.append(ct.steps, [SendAudio(audio:)]))
}

/// Sends a voice message with a default voice.
pub fn send_voice(ct: ConversationTest) -> ConversationTest {
  ConversationTest(
    steps: list.append(ct.steps, [SendVoice(voice: factory.voice())]),
  )
}

/// Sends a voice message with custom voice.
pub fn send_voice_with(
  ct: ConversationTest,
  voice: types.Voice,
) -> ConversationTest {
  ConversationTest(steps: list.append(ct.steps, [SendVoice(voice:)]))
}

/// Sends a raw message update with a user-provided message.
pub fn send_message(
  ct: ConversationTest,
  message: types.Message,
) -> ConversationTest {
  ConversationTest(steps: list.append(ct.steps, [SendMessageUpdate(message:)]))
}

/// Expects the next reply to exactly match the given text.
pub fn expect_reply(ct: ConversationTest, text: String) -> ConversationTest {
  ConversationTest(steps: list.append(ct.steps, [ExpectReply(text:)]))
}

/// Expects the next reply to contain the given substring.
pub fn expect_reply_containing(
  ct: ConversationTest,
  substring: String,
) -> ConversationTest {
  ConversationTest(
    steps: list.append(ct.steps, [ExpectReplyContaining(substring:)]),
  )
}

/// Expects the next reply to include an inline keyboard containing all specified button texts.
pub fn expect_keyboard(
  ct: ConversationTest,
  buttons buttons: List(String),
) -> ConversationTest {
  ConversationTest(steps: list.append(ct.steps, [ExpectKeyboard(buttons:)]))
}

/// Expects the next reply to contain the given substring AND include a keyboard with specified buttons.
pub fn expect_reply_with_keyboard(
  ct: ConversationTest,
  containing substring: String,
  buttons buttons: List(String),
) -> ConversationTest {
  ConversationTest(
    steps: list.append(ct.steps, [
      ExpectReplyWithKeyboard(substring:, buttons:),
    ]),
  )
}

/// Expects the next API call to have a path containing `path_contains`
/// and a body containing `body_contains`.
pub fn expect_api_call(
  ct: ConversationTest,
  path_contains path_contains: String,
  body_contains body_contains: String,
) -> ConversationTest {
  ConversationTest(
    steps: list.append(ct.steps, [
      ExpectApiCall(path_contains:, body_contains:),
    ]),
  )
}

/// Runs the conversation test against a router with the given default session factory.
pub fn run(
  ct: ConversationTest,
  router: router.Router(session, error),
  default_session: fn() -> session,
) -> Nil {
  run_with(
    ct,
    fn(ctx, update) { router.handle(router, ctx, update) },
    test_context.session_settings(default: default_session),
  )
}

/// Lower-level variant: runs the test with a custom router handler and session settings.
pub fn run_with(
  ct: ConversationTest,
  router_handler: fn(bot.Context(session, error), update.Update) ->
    Result(bot.Context(session, error), error),
  session_settings: bot.SessionSettings(session, error),
) -> Nil {
  let #(client, calls) = mock.message_client()
  run_with_client(ct, client, calls, router_handler, session_settings)
}

/// Runs the test with a custom mock client (e.g. from `mock.routed_client`).
pub fn run_with_mock(
  ct: ConversationTest,
  router: router.Router(session, error),
  default_session: fn() -> session,
  client: client.TelegramClient,
  calls: process.Subject(mock.ApiCall),
) -> Nil {
  run_with_client(
    ct,
    client,
    calls,
    fn(ctx, update) { router.handle(router, ctx, update) },
    test_context.session_settings(default: default_session),
  )
}

/// Runs the test with a custom client, calls subject, router handler, and session settings.
pub fn run_with_client(
  ct: ConversationTest,
  client: client.TelegramClient,
  calls: process.Subject(mock.ApiCall),
  router_handler: fn(bot.Context(session, error), update.Update) ->
    Result(bot.Context(session, error), error),
  session_settings: bot.SessionSettings(session, error),
) -> Nil {
  let config = test_context.config_with_client(client)

  let assert Ok(reg) = registry.start()
  let assert Ok(bot_subject) =
    bot.start(
      registry: reg,
      config:,
      bot_info: factory.bot_user(),
      router_handler:,
      session_settings:,
      catch_handler: fn(_ctx, _err) { Ok(Nil) },
    )

  execute_steps(ct.steps, bot_subject, calls)
  let _ = registry.stop(reg)
  Nil
}

fn execute_steps(
  steps: List(Step),
  bot_subject: bot.BotSubject,
  calls: process.Subject(mock.ApiCall),
) -> Nil {
  case steps {
    [] -> Nil
    [step, ..rest] -> {
      case step {
        SendText(text:) -> {
          let update = factory.text_update(text:)
          bot.handle_update(bot_subject:, update:)
          Nil
        }
        SendCommand(command:, payload:) -> {
          let update =
            factory.command_update_with(
              command:,
              payload:,
              from_id: 987_654_321,
              chat_id: 123_456_789,
            )
          bot.handle_update(bot_subject:, update:)
          Nil
        }
        SendCallback(data:) -> {
          let update = factory.callback_query_update(data:)
          bot.handle_update(bot_subject:, update:)
          Nil
        }
        SendPhoto(photos:) -> {
          let update =
            factory.photo_update_with(
              photos:,
              from_id: 987_654_321,
              chat_id: 123_456_789,
            )
          bot.handle_update(bot_subject:, update:)
          Nil
        }
        SendVideo(video:) -> {
          let update =
            factory.video_update_with(
              video:,
              from_id: 987_654_321,
              chat_id: 123_456_789,
            )
          bot.handle_update(bot_subject:, update:)
          Nil
        }
        SendAudio(audio:) -> {
          let update =
            factory.audio_update_with(
              audio:,
              from_id: 987_654_321,
              chat_id: 123_456_789,
            )
          bot.handle_update(bot_subject:, update:)
          Nil
        }
        SendVoice(voice:) -> {
          let update =
            factory.voice_update_with(
              voice:,
              from_id: 987_654_321,
              chat_id: 123_456_789,
            )
          bot.handle_update(bot_subject:, update:)
          Nil
        }
        SendMessageUpdate(message:) -> {
          let update = factory.message_update(message:)
          bot.handle_update(bot_subject:, update:)
          Nil
        }
        ExpectReply(text:) -> {
          assert_next_reply(calls, fn(reply_text) {
            case reply_text == text {
              True -> Nil
              False ->
                panic as {
                  "Expected reply '" <> text <> "', got '" <> reply_text <> "'"
                }
            }
          })
        }
        ExpectReplyContaining(substring:) -> {
          assert_next_reply(calls, fn(reply_text) {
            case string.contains(reply_text, substring) {
              True -> Nil
              False ->
                panic as {
                  "Expected reply containing '"
                  <> substring
                  <> "', got '"
                  <> reply_text
                  <> "'"
                }
            }
          })
        }
        ExpectKeyboard(buttons:) -> {
          assert_next_reply_keyboard(calls, buttons)
        }
        ExpectReplyWithKeyboard(substring:, buttons:) -> {
          let call = receive_next_send_message(calls, 0)
          let body = call.request.body
          assert_body_text(body, fn(reply_text) {
            case string.contains(reply_text, substring) {
              True -> Nil
              False ->
                panic as {
                  "Expected reply containing '"
                  <> substring
                  <> "', got '"
                  <> reply_text
                  <> "'"
                }
            }
          })
          assert_body_keyboard(body, buttons)
        }
        ExpectApiCall(path_contains:, body_contains:) -> {
          assert_next_api_call(calls, path_contains, body_contains)
        }
      }
      execute_steps(rest, bot_subject, calls)
    }
  }
}

fn receive_next_send_message(
  calls: process.Subject(mock.ApiCall),
  attempts: Int,
) -> mock.ApiCall {
  case attempts > 20 {
    True ->
      panic as "Expected a reply but no sendMessage API call was received after waiting"
    False -> {
      case process.receive(calls, 100) {
        Ok(call) -> {
          let is_message_call =
            string.contains(call.request.path, "sendMessage")
            || string.contains(call.request.path, "editMessageText")
          case is_message_call {
            True -> call
            // Skip non-message calls (e.g. answerCallbackQuery) and try next
            False -> receive_next_send_message(calls, attempts + 1)
          }
        }
        Error(_) -> receive_next_send_message(calls, attempts + 1)
      }
    }
  }
}

fn assert_next_reply(
  calls: process.Subject(mock.ApiCall),
  check: fn(String) -> Nil,
) -> Nil {
  let call = receive_next_send_message(calls, 0)
  assert_body_text(call.request.body, check)
}

fn assert_body_text(body: String, check: fn(String) -> Nil) -> Nil {
  let text_result =
    json.parse(body, {
      use text <- decode.field("text", decode.string)
      decode.success(text)
    })
  case text_result {
    Ok(text) -> check(text)
    Error(_) ->
      panic as { "Could not extract 'text' from API call body: " <> body }
  }
}

fn assert_body_keyboard(body: String, expected_buttons: List(String)) -> Nil {
  // reply_markup.inline_keyboard is [[{text, ...}, ...], ...]
  // We extract all button texts and check that expected ones are present
  case string.contains(body, "inline_keyboard") {
    False ->
      panic as {
        "Expected reply to contain an inline keyboard, but none found in: "
        <> body
      }
    True -> {
      list.each(expected_buttons, fn(button_text) {
        case string.contains(body, button_text) {
          True -> Nil
          False ->
            panic as {
              "Expected keyboard button '"
              <> button_text
              <> "' not found in reply body: "
              <> body
            }
        }
      })
    }
  }
}

fn assert_next_reply_keyboard(
  calls: process.Subject(mock.ApiCall),
  expected_buttons: List(String),
) -> Nil {
  let call = receive_next_send_message(calls, 0)
  assert_body_keyboard(call.request.body, expected_buttons)
}

fn assert_next_api_call(
  calls: process.Subject(mock.ApiCall),
  path_contains: String,
  body_contains: String,
) -> Nil {
  let call = receive_next_call_matching(calls, path_contains, 0)
  case string.contains(call.request.body, body_contains) {
    True -> Nil
    False ->
      panic as {
        "Expected API call body to contain '"
        <> body_contains
        <> "', got: "
        <> call.request.body
      }
  }
}

fn receive_next_call_matching(
  calls: process.Subject(mock.ApiCall),
  path_contains: String,
  attempts: Int,
) -> mock.ApiCall {
  case attempts > 20 {
    True ->
      panic as {
        "No API call with path containing '"
        <> path_contains
        <> "' received after waiting"
      }
    False -> {
      case process.receive(calls, 100) {
        Ok(call) -> {
          case string.contains(call.request.path, path_contains) {
            True -> call
            False ->
              receive_next_call_matching(calls, path_contains, attempts + 1)
          }
        }
        Error(_) ->
          receive_next_call_matching(calls, path_contains, attempts + 1)
      }
    }
  }
}
