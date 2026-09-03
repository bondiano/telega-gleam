//// Tests for the v3 builder: one constructor, an explicit mode step, and a
//// `Nil` session unless one is asked for.
////
//// The ordering rules (`dependencies`/`session` only before `router`) are
//// enforced by the builder's state type parameter, so they are compile
//// errors rather than something a test can observe — see `docs/migration-v3.md`.

import gleam/erlang/process
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit/should

import telega
import telega/bot.{type Context}
import telega/error.{type TelegaError}
import telega/model/encoder
import telega/polling
import telega/reply
import telega/router
import telega/testing/factory
import telega/testing/mock.{type ApiCall, ApiCall}

fn polling_routes(on_get_updates: fn(request.Request(String)) -> Nil) {
  [
    mock.route_with_response(
      "getMe",
      mock.ok_response(encoder.encode_user(factory.bot_user())),
    ),
    mock.route_with_response("deleteWebhook", mock.bool_response()),
    mock.route("getUpdates", fn(req) {
      on_get_updates(req)
      Ok(
        response.new(200)
        |> response.set_body("{\"ok\":true,\"result\":[]}"),
      )
    }),
  ]
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

fn echo_router() {
  router.new("builder")
  |> router.on_any_text(fn(ctx: Context(Nil, TelegaError, Nil), text) {
    use _ <- result.map(reply.with_text(ctx, "echo:" <> text))
    ctx
  })
}

fn stop(bot: telega.Telega(session, error, dependencies)) -> Nil {
  process.unlink(telega.get_supervisor_pid(bot))
  telega.shutdown(bot)
}

fn paths(calls: List(ApiCall)) -> List(String) {
  list.map(calls, fn(call) {
    let ApiCall(request:) = call
    request.path
  })
}

fn any_path(calls: List(ApiCall), fragment: String) -> Bool {
  list.any(paths(calls), string.contains(_, fragment))
}

pub fn a_builder_with_no_mode_polls_test() {
  let seen = process.new_subject()
  let #(client, calls) =
    mock.routed_client(polling_routes(fn(_req) { process.send(seen, Nil) }))

  let assert Ok(bot) =
    telega.new(client)
    |> telega.router(echo_router())
    |> telega.start()

  let assert Ok(Nil) = process.receive(seen, 2000)
  // Polling never registers a webhook.
  any_path(mock.get_calls(from: calls), "setWebhook") |> should.be_false

  stop(bot)
}

pub fn polling_settings_reach_get_updates_test() {
  let queries = process.new_subject()
  let #(client, _calls) =
    mock.routed_client(
      polling_routes(fn(req) {
        process.send(queries, option.unwrap(req.query, ""))
      }),
    )

  let assert Ok(bot) =
    telega.new(client)
    |> telega.router(echo_router())
    |> telega.polling(
      polling.PollingSettings(
        ..polling.default_settings(),
        timeout: 5,
        limit: 7,
        poll_interval: 50,
      ),
    )
    |> telega.start()

  let assert Ok(query) = process.receive(queries, 2000)
  string.contains(query, "limit=7") |> should.be_true
  string.contains(query, "timeout=5") |> should.be_true

  stop(bot)
}

pub fn webhook_mode_normalizes_url_and_path_test() {
  let #(client, calls) = mock.routed_client(webhook_routes())

  let assert Ok(bot) =
    telega.new(client)
    |> telega.webhook(
      url: "https://example.com/",
      path: "/hook/",
      secret_token: Some("s3cret"),
    )
    |> telega.router(echo_router())
    |> telega.start()

  // The trailing and leading slashes are gone, and the adapter can recognise
  // both the path and the secret.
  telega.is_webhook_path(bot, "hook") |> should.be_true
  telega.is_secret_token_valid(bot, "s3cret") |> should.be_true
  telega.is_secret_token_valid(bot, "nope") |> should.be_false

  any_path(mock.get_calls(from: calls), "setWebhook") |> should.be_true

  stop(bot)
}

pub fn a_bot_without_a_session_step_runs_on_nil_test() {
  let #(client, calls) = mock.routed_client(webhook_routes())

  let assert Ok(bot) =
    telega.new(client)
    |> telega.webhook(
      url: "https://example.com",
      path: "hook",
      secret_token: None,
    )
    |> telega.router(echo_router())
    |> telega.start()

  let _ = mock.get_calls(from: calls)

  telega.handle_update(bot, factory.raw_update(message: factory.message("hi")))
  |> should.be_true

  any_path(mock.get_calls(from: calls), "sendMessage") |> should.be_true

  stop(bot)
}

pub fn dependencies_reach_handlers_test() {
  let #(client, calls) = mock.routed_client(webhook_routes())

  let assert Ok(bot) =
    telega.new(client)
    |> telega.dependencies("injected")
    |> telega.webhook(
      url: "https://example.com",
      path: "hook",
      secret_token: None,
    )
    |> telega.router(
      router.new("deps")
      |> router.on_any_text(fn(ctx: Context(Nil, TelegaError, String), _text) {
        use _ <- result.map(reply.with_text(ctx, ctx.dependencies))
        ctx
      }),
    )
    |> telega.start()

  let _ = mock.get_calls(from: calls)

  telega.handle_update(bot, factory.raw_update(message: factory.message("hi")))
  |> should.be_true

  let bodies =
    list.map(mock.get_calls(from: calls), fn(call) {
      let ApiCall(request:) = call
      request.body
    })
  list.any(bodies, string.contains(_, "injected")) |> should.be_true

  stop(bot)
}
