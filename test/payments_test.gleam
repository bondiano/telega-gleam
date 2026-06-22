import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot.{type Context, Context}
import telega/error.{type TelegaError}
import telega/model/types
import telega/payments
import telega/reply
import telega/router
import telega/testing/context as test_context
import telega/testing/conversation
import telega/testing/factory
import telega/testing/mock

pub fn main() {
  gleeunit.main()
}

fn ctx_with_client(client) -> Context(String, TelegaError, Nil) {
  let base: Context(String, TelegaError, Nil) =
    test_context.context_with(
      session: "initial",
      update: factory.text_update_with(text: "hi", from_id: 123, chat_id: 456),
    )
  Context(..base, config: test_context.config_with_client(client))
}

pub fn stars_invoice_send_test() {
  let #(client, calls) = mock.message_client()
  let ctx = ctx_with_client(client)

  payments.stars_invoice(
    title: "Premium",
    description: "Premium access",
    payload: "premium:1m",
    amount: 100,
  )
  |> payments.send(ctx)
  |> should.be_ok()

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendInvoice",
      body_contains: "\"currency\":\"XTR\"",
    )
  Nil
}

pub fn stars_invoice_targets_update_chat_test() {
  let #(client, calls) = mock.message_client()
  let ctx = ctx_with_client(client)

  payments.stars_invoice(
    title: "Premium",
    description: "Premium access",
    payload: "premium:1m",
    amount: 100,
  )
  |> payments.send(ctx)
  |> should.be_ok()

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendInvoice",
      body_contains: "\"chat_id\":456",
    )
  Nil
}

pub fn currency_invoice_with_options_test() {
  let #(client, calls) = mock.message_client()
  let ctx = ctx_with_client(client)

  payments.invoice(
    title: "Order #42",
    description: "2 pizzas",
    payload: "order:42",
    currency: "USD",
    provider_token: "provider_token_123",
    prices: [payments.price("2x Pepperoni", 2490)],
  )
  |> payments.with_photo("https://example.com/pizza.jpg")
  |> payments.with_flexible_shipping()
  |> payments.require_email()
  |> payments.send(ctx)
  |> should.be_ok()

  let assert [call] = mock.get_calls(from: calls)
  call.request.path |> string.contains("sendInvoice") |> should.be_true()
  call.request.body
  |> string.contains("\"provider_token\":\"provider_token_123\"")
  |> should.be_true()
  call.request.body
  |> string.contains("\"is_flexible\":true")
  |> should.be_true()
  call.request.body
  |> string.contains("\"need_email\":true")
  |> should.be_true()
  call.request.body
  |> string.contains("\"photo_url\":\"https://example.com/pizza.jpg\"")
  |> should.be_true()
}

pub fn create_link_test() {
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "createInvoiceLink",
        response: mock.ok_response(json.string("https://t.me/invoice/abc")),
      ),
    ])
  let ctx = ctx_with_client(client)

  payments.stars_invoice(
    title: "Premium",
    description: "Premium access",
    payload: "premium:1m",
    amount: 100,
  )
  |> payments.create_link(ctx)
  |> should.be_ok()
  |> should.equal("https://t.me/invoice/abc")

  let _ =
    mock.assert_called_with_path(
      from: calls,
      path_contains: "createInvoiceLink",
    )
  Nil
}

fn pre_checkout_query() -> types.PreCheckoutQuery {
  types.PreCheckoutQuery(
    id: "pcq_1",
    from: factory.user(),
    currency: "XTR",
    total_amount: 100,
    invoice_payload: "premium:1m",
    shipping_option_id: None,
    order_info: None,
  )
}

pub fn answer_pre_checkout_ok_test() {
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "answerPreCheckoutQuery",
        response: mock.bool_response(),
      ),
    ])
  let ctx = ctx_with_client(client)

  payments.answer_pre_checkout_ok(ctx, pre_checkout_query())
  |> should.be_ok()
  |> should.equal(True)

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "answerPreCheckoutQuery",
      body_contains: "\"ok\":true",
    )
  Nil
}

pub fn answer_pre_checkout_error_test() {
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "answerPreCheckoutQuery",
        response: mock.bool_response(),
      ),
    ])
  let ctx = ctx_with_client(client)

  payments.answer_pre_checkout_error(ctx, pre_checkout_query(), "Out of stock")
  |> should.be_ok()

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "answerPreCheckoutQuery",
      body_contains: "\"error_message\":\"Out of stock\"",
    )
  Nil
}

pub fn answer_shipping_ok_test() {
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "answerShippingQuery",
        response: mock.bool_response(),
      ),
    ])
  let ctx = ctx_with_client(client)

  let query =
    types.ShippingQuery(
      id: "sq_1",
      from: factory.user(),
      invoice_payload: "order:42",
      shipping_address: types.ShippingAddress(
        country_code: "DE",
        state: "",
        city: "Berlin",
        street_line1: "Street 1",
        street_line2: "",
        post_code: "10115",
      ),
    )

  payments.answer_shipping_ok(ctx, query, [
    payments.shipping_option(id: "dhl", title: "DHL", prices: [
      payments.price("Shipping", 500),
    ]),
  ])
  |> should.be_ok()

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "answerShippingQuery",
      body_contains: "\"id\":\"dhl\"",
    )
  Nil
}

fn successful_payment_message() -> types.Message {
  let payment =
    types.SuccessfulPayment(
      currency: "XTR",
      total_amount: 100,
      invoice_payload: "premium:1m",
      subscription_expiration_date: None,
      is_recurring: None,
      is_first_recurring: None,
      shipping_option_id: None,
      order_info: None,
      telegram_payment_charge_id: "charge_1",
      provider_payment_charge_id: "provider_charge_1",
    )
  types.Message(..factory.message(text: ""), successful_payment: Some(payment))
}

pub fn wait_successful_payment_conversation_test() {
  let buy_handler = fn(ctx: Context(Nil, TelegaError, Nil), _cmd) {
    let assert Ok(_) = reply.with_text(ctx, "Invoice sent")
    use ctx, payment <- payments.wait_successful_payment(
      ctx,
      or: None,
      timeout: None,
    )
    let assert Ok(_) =
      reply.with_text(ctx, "Thanks for " <> payment.invoice_payload)
    Ok(ctx)
  }

  let r =
    router.new("payments_test")
    |> router.on_command("buy", buy_handler)

  conversation.conversation_test()
  |> conversation.send("/buy")
  |> conversation.expect_reply("Invoice sent")
  |> conversation.send_message(successful_payment_message())
  |> conversation.expect_reply("Thanks for premium:1m")
  |> conversation.run(r, fn() { Nil })
}
