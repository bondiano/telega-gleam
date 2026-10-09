//// The gate every webhook adapter runs an incoming request through.

import gleam/erlang/process
import gleam/http
import gleam/option.{Some}
import gleam/string
import gleeunit/should

import telega
import telega/model/encoder
import telega/router
import telega/testing/factory
import telega/testing/mock
import telega/webhook

fn webhook_routes() {
  [
    mock.route_with_response(
      "getMe",
      mock.ok_response(encoder.encode_user(factory.bot_user())),
    ),
    mock.route_with_response("setWebhook", mock.bool_response()),
  ]
}

fn start_bot() -> telega.Telega(Nil, Nil, Nil) {
  let #(client, _calls) = mock.routed_client(webhook_routes())
  let assert Ok(bot) =
    telega.new(client)
    |> telega.webhook(
      url: "https://example.com",
      path: "hook",
      secret_token: Some("s3cret"),
    )
    |> telega.router(router.new("webhook_test"))
    |> telega.start()
  bot
}

fn stop(bot: telega.Telega(session, error, dependencies)) -> Nil {
  process.unlink(telega.get_supervisor_pid(bot))
  telega.shutdown(bot)
}

pub fn admit_lets_other_paths_through_test() {
  let bot = start_bot()
  webhook.admit(bot, ["metrics"], Error(Nil))
  |> should.equal(webhook.NotWebhook)
  stop(bot)
}

pub fn admit_rejects_a_wrong_or_missing_secret_with_401_test() {
  let bot = start_bot()
  webhook.admit(bot, ["hook"], Error(Nil))
  |> should.equal(webhook.Rejected(401))
  webhook.admit(bot, ["hook"], Ok("nope"))
  |> should.equal(webhook.Rejected(401))
  stop(bot)
}

pub fn admit_accepts_a_healthy_bot_with_the_right_secret_test() {
  let bot = start_bot()
  webhook.admit(bot, ["hook"], Ok("s3cret")) |> should.equal(webhook.Admitted)
  stop(bot)
}

pub fn admit_rejects_with_503_once_the_bot_is_gone_test() {
  let bot = start_bot()
  stop(bot)
  webhook.admit(bot, ["hook"], Ok("s3cret"))
  |> should.equal(webhook.Rejected(503))
}

pub fn health_probe_answers_a_get_on_its_path_test() {
  let bot = start_bot()
  let assert Ok(#(200, body)) =
    webhook.health_probe(bot, http.Get, ["healthz"], "healthz")
  string.contains(body, "\"status\":\"healthy\"") |> should.be_true

  // Slashes around the configured path do not matter.
  let assert Ok(#(200, _)) =
    webhook.health_probe(bot, http.Get, ["ops", "healthz"], "/ops/healthz/")

  webhook.health_probe(bot, http.Post, ["healthz"], "healthz")
  |> should.equal(Error(Nil))
  webhook.health_probe(bot, http.Get, ["hook"], "healthz")
  |> should.equal(Error(Nil))
  stop(bot)
}

pub fn health_probe_reports_503_once_the_bot_is_gone_test() {
  let bot = start_bot()
  stop(bot)
  let assert Ok(#(503, body)) =
    webhook.health_probe(bot, http.Get, ["healthz"], "healthz")
  string.contains(body, "\"status\":\"unavailable\"") |> should.be_true
}
