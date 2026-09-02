//// Regression tests for H11: the polling worker used to stop for good after a
//// handful of consecutive failures — a minute without network, a `409`, or any
//// error code it did not know about — and its `deleteWebhook` lived in `init`,
//// so a restart failed too and took the supervision tree down with it.

import gleam/erlang/process
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleam/string
import gleeunit/should

import telega/bot
import telega/error
import telega/internal/registry
import telega/model/encoder
import telega/polling
import telega/testing/context
import telega/testing/factory
import telega/testing/mock
import telega/update as update_module

pub type Sess {
  Sess(counter: Int)
}

pub type Err {
  Err(message: String)
}

// Classification ------------------------------------------------------------

pub fn h11_recoverable_errors_never_stop_polling_test() {
  [
    error.FetchError("connection refused"),
    error.TelegramApiError(409, "Conflict: webhook is active", option.None),
    error.TelegramApiError(429, "Too Many Requests", option.None),
    error.TelegramApiError(500, "Internal Server Error", option.None),
    error.TelegramApiError(418, "I'm a teapot", option.None),
    error.ApiToRequestConvertError,
  ]
  |> list.map(polling.stops_polling)
  |> should.equal([False, False, False, False, False, False])
}

pub fn h11_only_fatal_errors_stop_polling_test() {
  [
    error.TelegramApiError(401, "Unauthorized", option.None),
    error.TelegramApiError(404, "Not Found", option.None),
  ]
  |> list.map(polling.stops_polling)
  |> should.equal([True, True])
}

pub fn h11_backoff_grows_and_is_capped_test() {
  [1, 2, 3, 5, 7, 42]
  |> list.map(fn(attempt) { polling.retry_delay(attempt:) })
  |> should.equal([1000, 2000, 4000, 16_000, 60_000, 60_000])
}

// Lazy `deleteWebhook` and 409 recovery --------------------------------------

fn start_test_factory() {
  let assert Ok(started) =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.start
  started.data
}

fn start_bot(
  name name: String,
  router router: fn(bot.Context(Sess, Err, Nil), update_module.Update) ->
    Result(bot.Context(Sess, Err, Nil), Err),
) -> bot.BotSubject {
  let assert Ok(reg) = registry.start(name)
  let assert Ok(started) =
    bot.start(
      registry: reg,
      config: context.config(),
      bot_info: factory.bot_user(),
      router_handler: router,
      pre_handlers: [],
      session_settings: context.session_settings_with(
        default: fn() { Sess(0) },
        initial: Sess(0),
      ),
      catch_handler: context.catch_handler(),
      dependencies: Nil,
      chat_factory: start_test_factory(),
      chat_idle_timeout: None,
      chat_init_timeout: 5000,
      media_group_timeout: option.None,
      name: None,
    )
  started.data
}

fn update_batch() -> String {
  mock.ok_response(result: json.array(
    [
      factory.raw_update_with(
        message: factory.message_with(
          text: "hello",
          from: factory.user_with(id: 7, first_name: "U"),
          chat: factory.chat_with(id: 7, type_: "private"),
        ),
        update_id: 1,
      ),
    ],
    encoder.encode_update,
  ))
}

/// Counts calls to `path` recorded so far.
fn seen(calls: process.Subject(mock.ApiCall), path: String) -> Int {
  mock.get_calls(from: calls)
  |> list.filter(fn(call) { string.contains(call.request.path, path) })
  |> list.length
}

/// The mock runs inside the polling worker, so its call counters have to be
/// shared across processes.
type AtomicsRef

@external(erlang, "atomics", "new")
fn atomics_new(size: Int, options: List(options)) -> AtomicsRef

@external(erlang, "atomics", "add_get")
fn atomics_add_get(ref: AtomicsRef, index: Int, increment: Int) -> Int

const api_error = "{\"ok\":false,\"error_code\":500,\"description\":\"Nope\"}"

const conflict = "{\"ok\":false,\"error_code\":409,\"description\":\"Conflict\"}"

pub fn h11_webhook_deletion_and_conflict_are_retried_test() {
  let events = process.new_subject()
  let router = fn(ctx, update: update_module.Update) {
    process.send(events, update.chat_id)
    Ok(ctx)
  }
  let bot_subject = start_bot(name: "h11_lazy_webhook", router:)

  let counters = atomics_new(2, [])
  let #(client, calls) =
    mock.client_with(handler: fn(req) {
      let body = case
        string.contains(req.path, "deleteWebhook"),
        string.contains(req.path, "getUpdates")
      {
        // The first `deleteWebhook` fails: the worker has to retry it instead
        // of failing its own start.
        True, _ ->
          case atomics_add_get(counters, 1, 1) {
            1 -> api_error
            _ -> mock.bool_response()
          }
        // A conflict used to end polling outright.
        _, True ->
          case atomics_add_get(counters, 2, 1) {
            1 -> conflict
            _ -> update_batch()
          }
        _, _ -> mock.bool_response()
      }
      Ok(response.new(200) |> response.set_body(body))
    })

  let assert Ok(poller) =
    polling.start_polling(
      client:,
      bot: bot_subject,
      timeout: 0,
      limit: 10,
      allowed_updates: [],
      poll_interval: 50,
    )

  // One second of backoff for the failed `deleteWebhook`, another for the 409.
  let assert Ok(chat_id) = process.receive(events, 8000)
  polling.stop(poller)

  chat_id |> should.equal(7)
  { seen(calls, "deleteWebhook") >= 2 } |> should.be_true
}
