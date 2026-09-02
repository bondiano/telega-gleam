//// Regression tests for H1: the polling worker used to wait for each update to
//// be fully handled before dispatching the next one, so a slow handler in one
//// chat stalled every other chat and the next `getUpdates`.

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
import telega/internal/registry
import telega/model/encoder
import telega/model/types
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

const chat_a = 1001

const chat_b = 2002

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
      name: None,
    )
  started.data
}

/// A raw update from `chat_id`, sent by a user with the same id.
fn chat_update(
  update_id update_id: Int,
  chat_id chat_id: Int,
  text text: String,
) -> types.Update {
  factory.raw_update_with(
    message: factory.message_with(
      text:,
      from: factory.user_with(id: chat_id, first_name: "U"),
      chat: factory.chat_with(id: chat_id, type_: "private"),
    ),
    update_id:,
  )
}

/// A mock Telegram client that answers a `getUpdates` whose query contains the
/// given marker (e.g. `"offset=0"`) with that batch, and every other poll with
/// an empty list.
fn polling_client_with(batches: List(#(String, List(types.Update)))) {
  let bodies =
    list.map(batches, fn(batch) {
      #(
        batch.0,
        mock.ok_response(result: json.array(batch.1, encoder.encode_update)),
      )
    })
  let empty_body = mock.ok_response(result: json.preprocessed_array([]))

  mock.client_with(handler: fn(req) {
    let body = case string.contains(req.path, "getUpdates") {
      False -> mock.bool_response()
      True -> {
        let query = option.unwrap(req.query, "")
        case list.find(bodies, fn(body) { string.contains(query, body.0) }) {
          Ok(#(_, body)) -> body
          Error(Nil) -> empty_body
        }
      }
    }
    Ok(response.new(200) |> response.set_body(body))
  })
}

/// A client that answers only the very first poll (still at `offset=0`).
fn polling_client(batch: List(types.Update)) {
  polling_client_with([#("offset=0", batch)])
}

fn get_updates_count(calls: process.Subject(mock.ApiCall)) -> Int {
  mock.get_calls(from: calls)
  |> list.filter(fn(call) { string.contains(call.request.path, "getUpdates") })
  |> list.length
}

pub fn h1_slow_handler_does_not_stall_other_chats_test() {
  let events = process.new_subject()
  let router = fn(ctx, update: update_module.Update) {
    case update.chat_id == chat_a {
      True -> {
        process.send(events, "a_start")
        process.sleep(1000)
        process.send(events, "a_end")
      }
      False -> process.send(events, "b_start")
    }
    Ok(ctx)
  }

  let bot_subject = start_bot(name: "h1_concurrency", router:)
  let #(client, _calls) =
    polling_client([
      chat_update(update_id: 1, chat_id: chat_a, text: "slow"),
      chat_update(update_id: 2, chat_id: chat_b, text: "fast"),
    ])

  let assert Ok(poller) =
    polling.start_polling(
      client:,
      bot: bot_subject,
      timeout: 0,
      limit: 100,
      allowed_updates: [],
      poll_interval: 200,
    )

  let assert Ok(first) = process.receive(events, 3000)
  // Chat B has to be handled while chat A's handler is still sleeping.
  let assert Ok(second) = process.receive(events, 500)
  polling.stop(poller)

  [first, second]
  |> list.sort(string.compare)
  |> should.equal(["a_start", "b_start"])
}

pub fn h1_same_chat_updates_stay_ordered_test() {
  let events = process.new_subject()
  let router = fn(ctx, update: update_module.Update) {
    case update {
      update_module.TextUpdate(text:, ..) -> process.send(events, text)
      _ -> Nil
    }
    Ok(ctx)
  }

  let bot_subject = start_bot(name: "h1_ordering", router:)
  let #(client, _calls) =
    polling_client([
      chat_update(update_id: 1, chat_id: chat_a, text: "1"),
      chat_update(update_id: 2, chat_id: chat_a, text: "2"),
      chat_update(update_id: 3, chat_id: chat_a, text: "3"),
    ])

  let assert Ok(poller) =
    polling.start_polling(
      client:,
      bot: bot_subject,
      timeout: 0,
      limit: 100,
      allowed_updates: [],
      poll_interval: 200,
    )

  let assert Ok(first) = process.receive(events, 3000)
  let assert Ok(second) = process.receive(events, 1000)
  let assert Ok(third) = process.receive(events, 1000)
  polling.stop(poller)

  [first, second, third]
  |> should.equal(["1", "2", "3"])
}

pub fn h1_poller_waits_for_capacity_before_fetching_more_test() {
  let events = process.new_subject()
  let router = fn(ctx, update: update_module.Update) {
    case update.chat_id == chat_a {
      True -> {
        process.send(events, "a_start")
        process.sleep(700)
        process.send(events, "a_end")
      }
      False -> process.send(events, "b_start")
    }
    Ok(ctx)
  }

  let bot_subject = start_bot(name: "h1_backpressure", router:)
  let #(client, calls) =
    polling_client_with([
      #("offset=0", [chat_update(update_id: 1, chat_id: chat_a, text: "slow")]),
      #("offset=2", [chat_update(update_id: 2, chat_id: chat_b, text: "next")]),
    ])

  // `limit: 1` also bounds how many updates may be in flight at once.
  let assert Ok(poller) =
    polling.start_polling(
      client:,
      bot: bot_subject,
      timeout: 0,
      limit: 1,
      allowed_updates: [],
      poll_interval: 100,
    )

  let assert Ok("a_start") = process.receive(events, 3000)
  // Several poll intervals pass while the only in-flight update is still busy.
  process.sleep(400)
  let fetches_while_busy = get_updates_count(calls)

  // Once it settles the poller picks up where it left off.
  let assert Ok("a_end") = process.receive(events, 3000)
  let assert Ok("b_start") = process.receive(events, 3000)
  polling.stop(poller)

  fetches_while_busy |> should.equal(1)
}
