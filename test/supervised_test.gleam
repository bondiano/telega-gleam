//// Tests for `telega.supervised` / `telega.supervised_for_polling`: the bot
//// as a child of the user's own supervision tree. Uses routed mock clients
//// (no network); the parent tree is torn down at the end of each test.

import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{None}
import gleam/otp/static_supervisor as sup
import gleam/string
import gleeunit/should

import telega
import telega/bot.{type Context}
import telega/error.{type TelegaError}
import telega/model/encoder
import telega/router
import telega/testing/factory
import telega/testing/mock.{type ApiCall, ApiCall}

fn ok_1(
  ctx: Context(Nil, TelegaError, Nil),
  _x: a,
) -> Result(Context(Nil, TelegaError, Nil), TelegaError) {
  Ok(ctx)
}

fn webhook_routes() {
  [
    mock.route_with_response(
      "getMe",
      mock.ok_response(encoder.encode_user(factory.bot_user())),
    ),
    mock.route_with_response("setWebhook", mock.bool_response()),
  ]
}

fn polling_routes() {
  [
    mock.route_with_response(
      "getMe",
      mock.ok_response(encoder.encode_user(factory.bot_user())),
    ),
    mock.route_with_response("deleteWebhook", mock.bool_response()),
    mock.route_with_response("getUpdates", "{\"ok\":true,\"result\":[]}"),
  ]
}

fn build_router() {
  router.new("supervised") |> router.on_command("start", ok_1)
}

/// A webhook builder that reports the started instance to `ready` — the
/// documented pattern for getting the `Telega` handle out of the tree.
fn webhook_builder(
  client,
  ready: Subject(telega.Telega(Nil, TelegaError, Nil)),
) {
  telega.new(
    api_client: client,
    url: "https://example.com",
    webhook_path: "/hook",
    secret_token: None,
  )
  |> telega.with_router(build_router())
  |> telega.with_nil_session()
  |> telega.with_on_start(fn(bot) { Ok(process.send(ready, bot)) })
}

fn seen(calls: List(ApiCall), path: String) -> Int {
  list.count(calls, fn(call) {
    let ApiCall(request:) = call
    string.contains(request.path, path)
  })
}

/// The parent tree is linked to the test process — unlink before stopping so
/// tearing it down does not take the test with it.
fn stop_tree(pid: process.Pid) -> Nil {
  process.unlink(pid)
  process.send_abnormal_exit(pid, "shutdown")
}

pub fn supervised_starts_under_parent_tree_test() {
  let #(client, calls) = mock.routed_client(webhook_routes())
  let ready = process.new_subject()

  let assert Ok(parent) =
    sup.new(sup.OneForOne)
    |> sup.add(telega.supervised(webhook_builder(client, ready)))
    |> sup.start

  // The instance is delivered through the on_start hook, fully initialized:
  // setWebhook + getMe went through the mock client.
  let assert Ok(bot) = process.receive(ready, 1000)
  let calls = mock.get_calls(from: calls)
  seen(calls, "getMe") |> should.equal(1)
  seen(calls, "setWebhook") |> should.equal(1)

  // The child's pid is telega's internal root, alive under the parent.
  telega.get_supervisor_pid(bot)
  |> process.is_alive
  |> should.be_true

  stop_tree(parent.pid)
}

pub fn supervised_restarts_bot_after_crash_test() {
  let #(client, calls) = mock.routed_client(webhook_routes())
  let ready = process.new_subject()

  let assert Ok(parent) =
    sup.new(sup.OneForOne)
    |> sup.add(telega.supervised(webhook_builder(client, ready)))
    |> sup.start

  let assert Ok(bot_before) = process.receive(ready, 1000)
  let pid_before = telega.get_supervisor_pid(bot_before)

  // Kill telega's internal root: the parent must re-run init and hand a
  // fresh instance to on_start.
  process.kill(pid_before)
  let assert Ok(bot_after) = process.receive(ready, 1000)
  let pid_after = telega.get_supervisor_pid(bot_after)

  should.be_true(pid_before != pid_after)
  process.is_alive(pid_after) |> should.be_true
  // Both boots went through the API: getMe was called once per init.
  seen(mock.get_calls(from: calls), "getMe") |> should.equal(2)

  stop_tree(parent.pid)
}

pub fn supervised_for_polling_starts_under_parent_tree_test() {
  let #(client, calls) = mock.routed_client(polling_routes())
  let ready = process.new_subject()

  let builder =
    telega.new_for_polling(api_client: client)
    |> telega.with_router(build_router())
    |> telega.with_nil_session()
    |> telega.with_on_start(fn(bot) { Ok(process.send(ready, bot)) })

  let assert Ok(parent) =
    sup.new(sup.OneForOne)
    |> sup.add(telega.supervised_for_polling(builder))
    |> sup.start

  let assert Ok(bot) = process.receive(ready, 1000)
  telega.get_supervisor_pid(bot)
  |> process.is_alive
  |> should.be_true
  seen(mock.get_calls(from: calls), "getMe") |> should.equal(1)

  stop_tree(parent.pid)
}

pub fn supervised_init_failure_fails_parent_start_test() {
  // getMe fails: the child start function must surface an error instead of
  // leaving a half-started tree behind. The failing parent exits its linked
  // starter, so trap exits for the duration of the start call.
  let #(client, _calls) =
    mock.routed_client([
      mock.route("getMe", fn(_req) { Error(error.FetchError("boom")) }),
      mock.route_with_response("setWebhook", mock.bool_response()),
    ])
  let ready = process.new_subject()

  process.trap_exits(True)
  let result =
    sup.new(sup.OneForOne)
    |> sup.add(telega.supervised(webhook_builder(client, ready)))
    |> sup.start
  process.trap_exits(False)

  should.be_error(result)
}
