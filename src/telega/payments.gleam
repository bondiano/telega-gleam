//// Helpers for sending invoices and answering payment queries, on top of
//// the raw Bot API methods in `telega/api`.
////
//// ## Telegram Stars
////
//// [Telegram Stars](https://core.telegram.org/bots/payments-stars) (`XTR`)
//// are the first-class case: digital goods and services must be sold in
//// Stars, no payment provider is required, and the invoice has a single
//// price.
////
//// ```gleam
//// import telega/payments
////
//// fn buy_handler(ctx, _command) {
////   let assert Ok(_) =
////     payments.stars_invoice(
////       title: "Premium",
////       description: "Premium access for a month",
////       payload: "premium:1m",
////       amount: 100,
////     )
////     |> payments.send(ctx)
////   Ok(ctx)
//// }
//// ```
////
//// `payload` is not shown to the user — it comes back in the pre-checkout
//// query and in the successful payment message, so put your order identifier
//// there.
////
//// ## Regular currencies
////
//// For physical goods, pass an ISO 4217 currency, a provider token from
//// [@BotFather](https://t.me/BotFather), and a price breakdown in the
//// smallest units of the currency:
////
//// ```gleam
//// payments.invoice(
////   title: "Order #42",
////   description: "2 pizzas",
////   payload: "order:42",
////   currency: "USD",
////   provider_token: provider_token,
////   prices: [
////     payments.price("2x Pepperoni", 2490),
////     payments.price("Delivery", 500),
////   ],
//// )
//// |> payments.with_photo("https://example.com/pizza.jpg")
//// |> payments.require_email()
//// |> payments.send(ctx)
//// ```
////
//// Other builder options: `with_tips`, `with_flexible_shipping`,
//// `with_provider_data`, `with_start_parameter`, `with_reply_markup`,
//// `require_name`, `require_phone_number`. `create_link` builds a shareable
//// payment URL instead of sending a message.
////
//// ## Answering the pre-checkout query
////
//// After the user confirms the payment, Telegram sends a pre-checkout query
//// that **must be answered within 10 seconds**, otherwise the payment fails:
////
//// ```gleam
//// import telega/router
////
//// router.new("shop")
//// |> router.on_pre_checkout_query(fn(ctx, query) {
////   let assert Ok(_) = case in_stock(query.invoice_payload) {
////     True -> payments.answer_pre_checkout_ok(ctx, query)
////     False -> payments.answer_pre_checkout_error(ctx, query, "Out of stock")
////   }
////   Ok(ctx)
//// })
//// ```
////
//// ## Shipping queries
////
//// For invoices created with `with_flexible_shipping`, Telegram asks the bot
//// for shipping options once the user fills in an address:
////
//// ```gleam
//// router.on_shipping_query(router, fn(ctx, query) {
////   let assert Ok(_) = case ships_to(query.shipping_address) {
////     True ->
////       payments.answer_shipping_ok(ctx, query, [
////         payments.shipping_option(id: "dhl", title: "DHL", prices: [
////           payments.price("Shipping", 500),
////         ]),
////       ])
////     False -> payments.answer_shipping_error(ctx, query, "No delivery there")
////   }
////   Ok(ctx)
//// })
//// ```
////
//// ## Waiting for the payment in a conversation
////
//// `wait_successful_payment` pauses the handler until the successful payment
//// service message arrives, so the whole purchase reads top-to-bottom (see
//// the [conversation guide](/docs/conversation.html)):
////
//// ```gleam
//// fn buy_handler(ctx, _command) {
////   let assert Ok(_) =
////     payments.stars_invoice(
////       title: "Premium",
////       description: "Premium access for a month",
////       payload: "premium:1m",
////       amount: 100,
////     )
////     |> payments.send(ctx)
////
////   use ctx, payment <- payments.wait_successful_payment(
////     ctx,
////     or: None,
////     timeout: Some(600_000),
////   )
////
////   // Store payment.telegram_payment_charge_id — it is needed for refunds
////   reply.with_text(ctx, "Thanks! Your order: " <> payment.invoice_payload)
//// }
//// ```
////
//// ## Refunds
////
//// For Telegram Stars, refund through the raw API method with the charge id
//// from the successful payment:
////
//// ```gleam
//// import telega/api
//// import telega/model/types
////
//// api.refund_star_payment(
////   ctx.config.api_client,
////   parameters: types.RefundStarPaymentParameters(
////     user_id: user_id,
////     telegram_payment_charge_id: charge_id,
////   ),
//// )
//// ```

import gleam/option.{type Option, None, Some}

import telega/api
import telega/bot.{type Context}
import telega/error
import telega/model/types.{
  type InlineKeyboardMarkup, type LabeledPrice, type Message,
  type PreCheckoutQuery, type ShippingOption, type ShippingQuery,
  type SuccessfulPayment, AnswerPreCheckoutQueryParameters,
  AnswerShippingQueryParameters, CreateInvoiceLinkParameters, LabeledPrice,
  SendInvoiceParameters, ShippingOption,
}

/// Telegram Stars currency code.
pub const stars_currency = "XTR"

/// Invoice under construction — build with `stars_invoice` or `invoice`,
/// refine with the `with_*`/`require_*` functions, then `send` or
/// `create_link`.
pub opaque type Invoice {
  Invoice(
    title: String,
    description: String,
    payload: String,
    currency: String,
    prices: List(LabeledPrice),
    provider_token: Option(String),
    photo_url: Option(String),
    start_parameter: Option(String),
    provider_data: Option(String),
    max_tip_amount: Option(Int),
    suggested_tip_amounts: Option(List(Int)),
    need_name: Option(Bool),
    need_phone_number: Option(Bool),
    need_email: Option(Bool),
    need_shipping_address: Option(Bool),
    is_flexible: Option(Bool),
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

/// A labeled portion of the invoice price. `amount` is in the smallest units
/// of the currency (cents for USD, stars for XTR).
pub fn price(label label: String, amount amount: Int) -> LabeledPrice {
  LabeledPrice(label:, amount:)
}

/// Invoice in Telegram Stars: no provider token, single price portion.
pub fn stars_invoice(
  title title: String,
  description description: String,
  payload payload: String,
  amount amount: Int,
) -> Invoice {
  new_invoice(
    title:,
    description:,
    payload:,
    currency: stars_currency,
    provider_token: None,
    prices: [price(label: title, amount:)],
  )
}

/// Invoice in a regular currency through a payment provider.
pub fn invoice(
  title title: String,
  description description: String,
  payload payload: String,
  currency currency: String,
  provider_token provider_token: String,
  prices prices: List(LabeledPrice),
) -> Invoice {
  new_invoice(
    title:,
    description:,
    payload:,
    currency:,
    provider_token: Some(provider_token),
    prices:,
  )
}

fn new_invoice(
  title title: String,
  description description: String,
  payload payload: String,
  currency currency: String,
  provider_token provider_token: Option(String),
  prices prices: List(LabeledPrice),
) -> Invoice {
  Invoice(
    title:,
    description:,
    payload:,
    currency:,
    prices:,
    provider_token:,
    photo_url: None,
    start_parameter: None,
    provider_data: None,
    max_tip_amount: None,
    suggested_tip_amounts: None,
    need_name: None,
    need_phone_number: None,
    need_email: None,
    need_shipping_address: None,
    is_flexible: None,
    reply_markup: None,
  )
}

/// Product photo shown in the invoice.
pub fn with_photo(invoice invoice: Invoice, url url: String) -> Invoice {
  Invoice(..invoice, photo_url: Some(url))
}

/// Allow tips up to `max` with suggested amounts (smallest currency units).
/// Not supported for Telegram Stars.
pub fn with_tips(
  invoice invoice: Invoice,
  max max: Int,
  suggested suggested: List(Int),
) -> Invoice {
  Invoice(
    ..invoice,
    max_tip_amount: Some(max),
    suggested_tip_amounts: Some(suggested),
  )
}

/// Request a shipping address and make the final price depend on the chosen
/// shipping option — the bot will receive shipping queries, handle them with
/// `router.on_shipping_query` and `answer_shipping_ok`/`answer_shipping_error`.
pub fn with_flexible_shipping(invoice invoice: Invoice) -> Invoice {
  Invoice(..invoice, need_shipping_address: Some(True), is_flexible: Some(True))
}

/// JSON-serialized data for the payment provider.
pub fn with_provider_data(
  invoice invoice: Invoice,
  data data: String,
) -> Invoice {
  Invoice(..invoice, provider_data: Some(data))
}

/// Deep-linking parameter to recreate the invoice via a `/start` link.
pub fn with_start_parameter(
  invoice invoice: Invoice,
  parameter parameter: String,
) -> Invoice {
  Invoice(..invoice, start_parameter: Some(parameter))
}

/// Inline keyboard for the invoice message. The first button must be a Pay
/// button, otherwise Telegram inserts one.
pub fn with_reply_markup(
  invoice invoice: Invoice,
  markup markup: InlineKeyboardMarkup,
) -> Invoice {
  Invoice(..invoice, reply_markup: Some(markup))
}

/// Require the user's full name to complete the order.
pub fn require_name(invoice invoice: Invoice) -> Invoice {
  Invoice(..invoice, need_name: Some(True))
}

/// Require the user's phone number to complete the order.
pub fn require_phone_number(invoice invoice: Invoice) -> Invoice {
  Invoice(..invoice, need_phone_number: Some(True))
}

/// Require the user's email to complete the order.
pub fn require_email(invoice invoice: Invoice) -> Invoice {
  Invoice(..invoice, need_email: Some(True))
}

/// Send the invoice to the current chat.
pub fn send(
  invoice invoice: Invoice,
  ctx ctx: Context(session, error, dependencies),
) -> Result(Message, error.TelegaError) {
  api.send_invoice(
    ctx.config.api_client,
    parameters: SendInvoiceParameters(
      chat_id: types.Int(ctx.update.chat_id),
      message_thread_id: None,
      title: invoice.title,
      description: invoice.description,
      payload: invoice.payload,
      provider_token: invoice.provider_token,
      currency: invoice.currency,
      prices: invoice.prices,
      max_tip_amount: invoice.max_tip_amount,
      suggested_tip_amounts: invoice.suggested_tip_amounts,
      start_parameter: invoice.start_parameter,
      provider_data: invoice.provider_data,
      photo_url: invoice.photo_url,
      photo_size: None,
      photo_width: None,
      photo_height: None,
      need_name: invoice.need_name,
      need_phone_number: invoice.need_phone_number,
      need_email: invoice.need_email,
      need_shipping_address: invoice.need_shipping_address,
      send_phone_number_to_provider: None,
      send_email_to_provider: None,
      is_flexible: invoice.is_flexible,
      disable_notification: None,
      protect_content: None,
      allow_paid_broadcast: None,
      message_effect_id: None,
      reply_parameters: None,
      reply_markup: invoice.reply_markup,
    ),
  )
}

/// Create a shareable payment link for the invoice.
pub fn create_link(
  invoice invoice: Invoice,
  ctx ctx: Context(session, error, dependencies),
) -> Result(String, error.TelegaError) {
  api.create_invoice_link(
    ctx.config.api_client,
    parameters: CreateInvoiceLinkParameters(
      business_connection_id: None,
      title: invoice.title,
      description: invoice.description,
      payload: invoice.payload,
      provider_token: invoice.provider_token,
      currency: invoice.currency,
      prices: invoice.prices,
      subscription_period: None,
      max_tip_amount: invoice.max_tip_amount,
      suggested_tip_amounts: invoice.suggested_tip_amounts,
      provider_data: invoice.provider_data,
      photo_url: invoice.photo_url,
      photo_size: None,
      photo_width: None,
      photo_height: None,
      need_name: invoice.need_name,
      need_phone_number: invoice.need_phone_number,
      need_email: invoice.need_email,
      need_shipping_address: invoice.need_shipping_address,
      send_phone_number_to_provider: None,
      send_email_to_provider: None,
      is_flexible: invoice.is_flexible,
    ),
  )
}

/// Confirm a pre-checkout query: the order can proceed.
/// Must be sent within 10 seconds after the query arrives.
pub fn answer_pre_checkout_ok(
  ctx ctx: Context(session, error, dependencies),
  query query: PreCheckoutQuery,
) -> Result(Bool, error.TelegaError) {
  api.answer_pre_checkout_query(
    ctx.config.api_client,
    parameters: AnswerPreCheckoutQueryParameters(
      pre_checkout_query_id: query.id,
      ok: True,
      error_message: None,
    ),
  )
}

/// Reject a pre-checkout query with a human-readable reason shown to the user.
pub fn answer_pre_checkout_error(
  ctx ctx: Context(session, error, dependencies),
  query query: PreCheckoutQuery,
  message message: String,
) -> Result(Bool, error.TelegaError) {
  api.answer_pre_checkout_query(
    ctx.config.api_client,
    parameters: AnswerPreCheckoutQueryParameters(
      pre_checkout_query_id: query.id,
      ok: False,
      error_message: Some(message),
    ),
  )
}

/// A shipping option offered in response to a shipping query.
pub fn shipping_option(
  id id: String,
  title title: String,
  prices prices: List(LabeledPrice),
) -> ShippingOption {
  ShippingOption(id:, title:, prices:)
}

/// Confirm delivery to the queried address with the available options.
pub fn answer_shipping_ok(
  ctx ctx: Context(session, error, dependencies),
  query query: ShippingQuery,
  options options: List(ShippingOption),
) -> Result(Bool, error.TelegaError) {
  api.answer_shipping_query(
    ctx.config.api_client,
    parameters: AnswerShippingQueryParameters(
      shipping_query_id: query.id,
      ok: True,
      shipping_options: Some(options),
      error_message: None,
    ),
  )
}

/// Reject a shipping query with a human-readable reason shown to the user.
pub fn answer_shipping_error(
  ctx ctx: Context(session, error, dependencies),
  query query: ShippingQuery,
  message message: String,
) -> Result(Bool, error.TelegaError) {
  api.answer_shipping_query(
    ctx.config.api_client,
    parameters: AnswerShippingQueryParameters(
      shipping_query_id: query.id,
      ok: False,
      shipping_options: None,
      error_message: Some(message),
    ),
  )
}

/// Pauses the current chat actor's handler and waits for a successful payment
/// service message. Other (non-payment) messages keep the conversation
/// waiting, or go to the `or` handler if one is given.
///
/// ```gleam
/// let assert Ok(_) = payments.stars_invoice(...) |> payments.send(ctx)
/// use ctx, payment <- payments.wait_successful_payment(ctx, or: None, timeout: None)
/// reply.with_text(ctx, "Thanks! Charge id: " <> payment.telegram_payment_charge_id)
/// ```
///
/// See [conversation](/docs/conversation)
pub fn wait_successful_payment(
  ctx ctx: Context(session, error, dependencies),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(
    Context(session, error, dependencies),
    SuccessfulPayment,
  ) -> Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
  let payment_handler =
    bot.HandleMessage(fn(ctx, message) {
      case message.successful_payment {
        Some(payment) -> continue(ctx, payment)
        None ->
          wait_successful_payment(ctx, or: handle_else, timeout:, continue:)
      }
    })

  bot.wait_handler(ctx:, timeout:, handle_else:, handler: payment_handler)
}
