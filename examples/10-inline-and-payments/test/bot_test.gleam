import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot
import telega/client
import telega/error
import telega/model/types
import telega/router
import telega/testing/context as testing_context
import telega/testing/conversation
import telega/testing/factory
import telega/testing/mock
import telega/update

import bot as shop
import catalog

pub fn main() {
  gleeunit.main()
}

// --- Catalogue --------------------------------------------------------------

pub fn search_is_case_insensitive_test() {
  catalog.search("NORD")
  |> list.map(fn(item: catalog.Item) { item.id })
  |> should.equal(["theme-nord"])
}

pub fn empty_search_returns_everything_test() {
  catalog.search("  ")
  |> list.length
  |> should.equal(list.length(catalog.items))
}

// --- Chat routes ------------------------------------------------------------

pub fn shop_lists_every_item_test() {
  conversation.conversation_test()
  |> conversation.send("/shop")
  |> conversation.expect_reply_containing("Pick one")
  |> conversation.run(shop.build_router(), fn() { Nil })
}

pub fn refund_without_a_charge_id_explains_itself_test() {
  conversation.conversation_test()
  |> conversation.send("/refund")
  |> conversation.expect_reply_containing("charge id")
  |> conversation.run(shop.build_router(), fn() { Nil })
}

// --- Inline mode ------------------------------------------------------------

pub fn inline_query_answers_matching_items_test() {
  let #(tg_client, calls) = bool_client()

  shop.build_router()
  |> router.handle(context_with(tg_client), inline_query("pack"))
  |> should.be_ok

  let call =
    mock.get_calls(from: calls)
    |> list.first
    |> should.be_ok

  call.request.path |> string.contains("answerInlineQuery") |> should.be_true
  // Both packs match, and nothing else does.
  call.request.body |> string.contains("pack-emoji") |> should.be_true
  call.request.body |> string.contains("pack-sounds") |> should.be_true
  call.request.body |> string.contains("theme-nord") |> should.be_false
}

// --- Payments ---------------------------------------------------------------

pub fn pre_checkout_is_confirmed_for_a_valid_order_test() {
  let #(tg_client, calls) = bool_client()

  shop.build_router()
  |> router.handle(
    context_with(tg_client),
    pre_checkout("theme-nord", total_amount: 50),
  )
  |> should.be_ok

  let call = mock.get_calls(from: calls) |> list.first |> should.be_ok
  call.request.path
  |> string.contains("answerPreCheckoutQuery")
  |> should.be_true
  call.request.body |> string.contains("\"ok\":true") |> should.be_true
}

/// The price the user is about to pay must be the price the bot quoted —
/// otherwise a stale invoice could be paid at the old amount.
pub fn pre_checkout_is_refused_when_the_price_moved_test() {
  let #(tg_client, calls) = bool_client()

  shop.build_router()
  |> router.handle(
    context_with(tg_client),
    pre_checkout("theme-nord", total_amount: 1),
  )
  |> should.be_ok

  let call = mock.get_calls(from: calls) |> list.first |> should.be_ok
  call.request.body |> string.contains("\"ok\":false") |> should.be_true
}

pub fn pre_checkout_is_refused_for_an_unknown_item_test() {
  let #(tg_client, calls) = bool_client()

  shop.build_router()
  |> router.handle(
    context_with(tg_client),
    pre_checkout("theme-gone", total_amount: 50),
  )
  |> should.be_ok

  let call = mock.get_calls(from: calls) |> list.first |> should.be_ok
  call.request.body |> string.contains("no longer for sale") |> should.be_true
}

pub fn successful_payment_hands_back_the_charge_id_test() {
  let #(tg_client, calls) = mock.message_client()

  shop.build_router()
  |> router.handle(context_with(tg_client), successful_payment("theme-nord"))
  |> should.be_ok

  let call = mock.get_calls(from: calls) |> list.first |> should.be_ok
  call.request.path |> string.contains("sendMessage") |> should.be_true
  call.request.body |> string.contains("Nord theme") |> should.be_true
  call.request.body |> string.contains("charge-1") |> should.be_true
}

// --- Fixtures ---------------------------------------------------------------

const user_id = 123

/// `answerInlineQuery` and `answerPreCheckoutQuery` return a plain `true`, not
/// a `Message`, so the default mock response does not decode.
fn bool_client() {
  mock.routed_client(routes: [
    mock.route_with_response(
      path_contains: "answer",
      response: mock.bool_response(),
    ),
  ])
}

fn context_with(
  tg_client: client.TelegramClient,
) -> bot.Context(Nil, error.TelegaError, Nil) {
  let ctx =
    testing_context.context_with_all(
      session: Nil,
      update: factory.text_update(text: ""),
      key: "123:123",
      bot_info: factory.bot_user(),
      dependencies: Nil,
    )
  bot.Context(..ctx, config: testing_context.config_with_client(tg_client))
}

fn inline_query(query: String) -> update.Update {
  update.InlineQueryUpdate(
    from_id: user_id,
    chat_id: user_id,
    inline_query: types.InlineQuery(
      id: "q1",
      from: factory.user_with(id: user_id, first_name: "Test"),
      query:,
      offset: "",
      chat_type: None,
      location: None,
    ),
    raw: factory.raw_update(message: factory.message(text: "")),
  )
}

fn pre_checkout(
  payload: String,
  total_amount total_amount: Int,
) -> update.Update {
  update.PreCheckoutQueryUpdate(
    from_id: user_id,
    chat_id: user_id,
    pre_checkout_query: types.PreCheckoutQuery(
      id: "pcq1",
      from: factory.user_with(id: user_id, first_name: "Test"),
      currency: "XTR",
      total_amount:,
      invoice_payload: payload,
      shipping_option_id: None,
      order_info: None,
    ),
    raw: factory.raw_update(message: factory.message(text: "")),
  )
}

fn successful_payment(payload: String) -> update.Update {
  let message =
    types.Message(
      ..factory.message(text: ""),
      successful_payment: Some(types.SuccessfulPayment(
        currency: "XTR",
        total_amount: 50,
        invoice_payload: payload,
        subscription_expiration_date: None,
        is_recurring: None,
        is_first_recurring: None,
        shipping_option_id: None,
        order_info: None,
        telegram_payment_charge_id: "charge-1",
        provider_payment_charge_id: "",
      )),
    )
  factory.message_update(message:)
}
