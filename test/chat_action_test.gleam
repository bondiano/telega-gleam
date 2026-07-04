import gleam/erlang/process
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot.{type Context, Context}
import telega/chat_action
import telega/error.{type TelegaError}
import telega/testing/context as test_context
import telega/testing/mock

pub fn main() {
  gleeunit.main()
}

fn ctx_with_client(client) -> Context(String, TelegaError, Nil) {
  let base: Context(String, TelegaError, Nil) =
    test_context.context(session: "initial")
  Context(..base, config: test_context.config_with_client(client))
}

fn assert_all_send_chat_action(calls: List(mock.ApiCall)) -> Nil {
  list.each(calls, fn(call) {
    should.be_true(string.contains(call.request.path, "sendChatAction"))
  })
}

pub fn resends_action_while_running_test() {
  let #(client, calls) = mock.client()
  let ctx = ctx_with_client(client)

  let result =
    chat_action.with_action_every(
      ctx:,
      action: chat_action.Typing,
      interval: 20,
      run: fn() {
        process.sleep(60)
        "handler result"
      },
    )

  should.equal(result, "handler result")

  let recorded = mock.get_calls(from: calls)
  // Initial synchronous send + at least 2 periodic re-sends during 60ms
  should.be_true(list.length(recorded) >= 3)
  assert_all_send_chat_action(recorded)
}

pub fn stops_resending_after_return_test() {
  let #(client, calls) = mock.client()
  let ctx = ctx_with_client(client)

  chat_action.with_action_every(
    ctx:,
    action: chat_action.UploadPhoto,
    interval: 10,
    run: fn() { process.sleep(25) },
  )

  // Let any in-flight send settle, then drain everything recorded so far
  process.sleep(30)
  let _ = mock.get_calls(from: calls)

  // Well past several intervals: the worker must be gone, no new calls
  process.sleep(50)
  should.equal(mock.get_calls(from: calls), [])
}

pub fn caller_crash_stops_worker_test() {
  let #(client, calls) = mock.client()
  let ctx = ctx_with_client(client)

  let pid =
    process.spawn_unlinked(fn() {
      chat_action.with_action_every(
        ctx:,
        action: chat_action.Typing,
        interval: 10,
        run: fn() { process.sleep_forever() },
      )
    })

  // Worker is re-sending while the wrapped process is alive
  process.sleep(35)
  should.be_true(list.length(mock.get_calls(from: calls)) >= 2)

  process.kill(pid)

  // Monitor `Down` reaches the worker; drain leftovers, then verify silence
  process.sleep(30)
  let _ = mock.get_calls(from: calls)
  process.sleep(50)
  should.equal(mock.get_calls(from: calls), [])
}

pub fn with_action_returns_run_result_test() {
  let #(client, _calls) = mock.client()
  let ctx = ctx_with_client(client)

  let result = {
    use <- chat_action.with_action(ctx, chat_action.Typing)
    42
  }

  should.equal(result, 42)
}
