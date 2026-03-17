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
import telega/internal/registry
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
  ExpectReply(text: String)
  ExpectReplyContaining(substring: String)
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
  let body = call.request.body
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
