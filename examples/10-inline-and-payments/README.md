# Telega Inline Mode & Telegram Stars

A shop for digital goods. Two features that live outside the ordinary
message → handler pipeline:

- **Inline mode** — `@your_bot pack` typed in *any* chat, group or channel.
- **Payments in Telegram Stars** — an invoice, a pre-checkout query, a
  successful-payment message, and a refund.

## Setup

1. Get a bot token from [@BotFather](https://t.me/BotFather).
2. Turn inline mode on: `/setinline` in BotFather, then a placeholder like
   *"search the shop"*. Without this Telegram never sends inline queries.

```sh
export BOT_TOKEN="123456:your-token-here"
gleam run
```

Telegram Stars need **no payment provider token** — digital goods must be sold
in Stars (`XTR`), and BotFather has nothing to configure. Test purchases are
free for the developer of the bot.

## What it shows

### Inline mode

```gleam
fn inline_query_handler(ctx, query: types.InlineQuery) {
  let #(page, next_offset) =
    catalog.search(query.query)
    |> inline_mode.paginate(offset: query.offset, page_size: 10)

  page
  |> list.fold(inline_mode.new(), fn(builder, item) {
    inline_mode.article_described(builder, id:, title:, text:, description:)
  })
  |> inline_mode.with_cache_time(300)
  |> inline_mode.maybe_next_offset(next_offset)
  |> inline_mode.answer(ctx, query.id)
}
```

An inline query is its own update kind: there is no chat and no session behind
it, and Telegram allows at most 50 results per answer. `paginate` slices the
list for the offset the client sent and tells you the next one;
`maybe_next_offset` sets it **only** when another page exists — an offset on
the last page makes the client ask forever.

`on_chosen_inline_result` tells you which result was actually picked. Telegram
only sends it when `chosen_inline_result` is in `allowed_updates`, which
`with_auto_allowed_updates` handles as soon as the route exists.

### Payments

```gleam
router.new("shop")
|> router.on_callback_data(buy_callback(), buy_handler)      // send the invoice
|> router.on_pre_checkout_query(pre_checkout_handler)        // approve or refuse
|> router.on_custom(matcher: is_successful_payment, handler: paid_handler)
```

Three steps, three routes:

1. **The invoice.** `payments.stars_invoice(title:, description:, payload:,
   amount:)` then `payments.send(ctx)`. `payload` is invisible to the user and
   comes back in both later steps, so it has to identify the order — here it is
   the catalogue id.

2. **The pre-checkout query.** Telegram asks whether the payment may go
   through, and **fails it if the bot does not answer within 10 seconds**. This
   is the last point at which a shop can refuse: check that the item still
   exists and that the amount matches the price you quoted (the example refuses
   both cases — a stale invoice must not be paid at the old price).

3. **The successful payment.** It arrives as a service message rather than its
   own update kind, so it is matched with `on_custom` on
   `message.successful_payment`. Store
   `payment.telegram_payment_charge_id`: it is the only handle for a refund.

```gleam
api.refund_star_payment(
  ctx.config.api_client,
  parameters: types.RefundStarPaymentParameters(user_id:, telegram_payment_charge_id:),
)
```

> **Routes or `payments.wait_successful_payment`?** Both work.
> `wait_successful_payment` parks the handler until step 3 so the purchase
> reads top-to-bottom, and the pre-checkout query still reaches
> `on_pre_checkout_query` while it waits — a payment query is one of the few
> updates a pending `wait_*` hands to the router instead of consuming.
> This example uses routes throughout because they stay correct when the user
> pays the invoice hours later, from another device, or after the bot has been
> restarted — none of which an in-memory continuation survives.

## Tests

```sh
gleam test
```

The payment steps are driven directly through `router.handle` with a mock
client: an inline query in, an `answerInlineQuery` body out; a pre-checkout
query with the wrong amount in, an `"ok":false` out. No network, no Telegram.

## See also

- [`telega/inline_mode`](../../src/telega/inline_mode.gleam)
- [`telega/payments`](../../src/telega/payments.gleam) — regular currencies,
  shipping queries, tips, and the module guide
