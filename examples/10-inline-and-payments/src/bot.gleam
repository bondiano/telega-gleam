//// A tiny shop that sells digital goods for Telegram Stars, and lets anyone
//// share the catalogue from any chat through inline mode.
////
//// Two independent features, both of which need routes the message/callback
//// pipeline does not give you:
////
////   * **Inline mode** — `@your_bot nord` in *any* chat. The bot answers with
////     a paginated result list (`telega/inline_mode`); Telegram never routes
////     these through a chat, so they arrive as their own update kind.
////   * **Payments** — an invoice, a pre-checkout query that must be answered
////     within 10 seconds, and a successful-payment service message.
////     Digital goods must be sold in Stars (`XTR`), which needs no payment
////     provider at all (`telega/payments`).

import envoy
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import telega
import telega/api
import telega/error as telega_error
import telega/inline_mode
import telega/keyboard
import telega/model/types
import telega/payments
import telega/reply
import telega/router
import telega/update
import telega_httpc

import catalog.{type Item}

/// Telegram allows at most 50 inline results per answer; a page of 10 keeps
/// the list readable and exercises `paginate`.
const inline_page_size = 10

/// Results are identical for everyone, so let Telegram cache them.
const inline_cache_seconds = 300

/// One callback factory for the buy buttons: the route below matches exactly
/// the payloads it builds, and hands the handler the item id already decoded.
fn buy_callback() -> keyboard.KeyboardCallbackData(String) {
  keyboard.string_callback_data("buy")
}

// --- Browsing in a chat -----------------------------------------------------

fn start_handler(ctx, _command) {
  use ctx <- telega.log_context(ctx, "start")
  reply.text(
    ctx,
    "This is a shop for Telegram Stars.\n\n"
      <> "/shop — see what is for sale\n"
      <> "/refund <charge id> — undo a purchase\n\n"
      <> "You can also type @"
      <> ctx.bot_info.username |> option.unwrap("this_bot")
      <> " in any chat to share an item.",
  )
}

fn shop_handler(ctx, _command) {
  use ctx <- telega.log_context(ctx, "shop")

  let buttons =
    catalog.items
    |> list.map(fn(item) {
      keyboard.inline_button(
        text: item.title <> " — " <> int.to_string(item.stars) <> " ⭐",
        callback_data: keyboard.pack_callback(buy_callback(), item.id),
      )
    })
    |> result.all

  case buttons {
    Ok(buttons) -> {
      let markup =
        buttons
        |> list.map(fn(button) { [button] })
        |> keyboard.new_inline
        |> keyboard.to_inline_markup

      use _ <- try(reply.with_markup(ctx, "Pick one:", markup))
      Ok(ctx)
    }
    // A payload longer than 64 bytes: a catalogue bug, not a user error.
    Error(reason) -> {
      use _ <- try(reply.with_text(ctx, "The shop is misconfigured: " <> reason))
      Ok(ctx)
    }
  }
}

// --- Buying -----------------------------------------------------------------

/// The button press: acknowledge it (Telegram shows a spinner until you do)
/// and send the invoice.
fn buy_handler(ctx, _query, item_id: String) {
  use ctx <- telega.log_context(ctx, "buy")

  case catalog.find(item_id) {
    Ok(item) -> {
      use _ <- try(reply.answer_quietly(ctx))
      use _ <- try(invoice_for(item) |> payments.send(ctx))
      Ok(ctx)
    }
    Error(Nil) -> {
      use _ <- try(reply.answer_alert(ctx, "That item is gone."))
      Ok(ctx)
    }
  }
}

fn invoice_for(item: Item) {
  payments.stars_invoice(
    title: item.title,
    description: item.description,
    // Comes back in the pre-checkout query and the successful payment.
    payload: item.id,
    amount: item.stars,
  )
}

/// Telegram asks "may this payment go through?" and **fails the payment if the
/// bot does not answer within 10 seconds**. This is where a real shop checks
/// stock, the price it quoted, and whether the order still exists.
fn pre_checkout_handler(ctx, query: types.PreCheckoutQuery) {
  use ctx <- telega.log_context(ctx, "pre_checkout")

  case catalog.find(query.invoice_payload) {
    Ok(item) if item.stars == query.total_amount -> {
      use _ <- try(payments.answer_pre_checkout_ok(ctx, query))
      Ok(ctx)
    }
    Ok(_) -> {
      use _ <- try(payments.answer_pre_checkout_error(
        ctx,
        query,
        "The price changed while you were paying. Please try again.",
      ))
      Ok(ctx)
    }
    Error(Nil) -> {
      use _ <- try(payments.answer_pre_checkout_error(
        ctx,
        query,
        "That item is no longer for sale.",
      ))
      Ok(ctx)
    }
  }
}

/// The payment went through. Telegram delivers it as a service message, so it
/// is matched with `on_custom` rather than a dedicated route.
fn successful_payment_handler(ctx, upd) {
  use ctx <- telega.log_context(ctx, "paid")

  case successful_payment(upd) {
    Some(payment) -> {
      let title =
        catalog.find(payment.invoice_payload)
        |> result.map(fn(item: Item) { item.title })
        |> result.unwrap("your order")

      // Keep the charge id: it is the only way to refund the payment later.
      use _ <- try(reply.with_text(
        ctx,
        "Thanks! "
          <> title
          <> " is yours.\n\nRefund with:\n/refund "
          <> payment.telegram_payment_charge_id,
      ))
      Ok(ctx)
    }
    None -> Ok(ctx)
  }
}

fn successful_payment(upd: update.Update) -> Option(types.SuccessfulPayment) {
  case update.message(upd) {
    Some(message) -> message.successful_payment
    None -> None
  }
}

fn is_successful_payment(upd: update.Update) -> Bool {
  successful_payment(upd) |> option.is_some
}

/// Stars can be refunded through the raw API method, with the charge id from
/// the successful payment.
fn refund_handler(ctx, command: update.Command) {
  use ctx <- telega.log_context(ctx, "refund")

  case command.payload |> option.unwrap("") |> string.trim {
    "" -> {
      use _ <- try(reply.with_text(
        ctx,
        "Send the charge id too: /refund <charge id>",
      ))
      Ok(ctx)
    }
    charge_id -> {
      let refunded =
        api.refund_star_payment(
          ctx.config.api_client,
          parameters: types.RefundStarPaymentParameters(
            user_id: ctx.update.from_id,
            telegram_payment_charge_id: charge_id,
          ),
        )

      let answer = case refunded {
        Ok(True) -> "Refunded. The stars are back in your balance."
        _ -> "I could not refund that charge id."
      }
      use _ <- try(reply.with_text(ctx, answer))
      Ok(ctx)
    }
  }
}

// --- Inline mode ------------------------------------------------------------

/// `@your_bot nord` from any chat, group or channel. There is no chat instance
/// and no session behind an inline query — it is the bot's own update kind,
/// answered once with up to 50 results.
fn inline_query_handler(ctx, query: types.InlineQuery) {
  use ctx <- telega.log_context(ctx, "inline_query")

  let #(page, next_offset) =
    catalog.search(query.query)
    |> inline_mode.paginate(offset: query.offset, page_size: inline_page_size)

  let answer =
    page
    |> list.fold(inline_mode.new(), fn(builder, item: Item) {
      inline_mode.article_described(
        builder,
        id: item.id,
        title: item.title <> " — " <> int.to_string(item.stars) <> " ⭐",
        text: item.title <> "\n" <> item.description,
        description: Some(item.description),
      )
    })
    |> inline_mode.with_cache_time(inline_cache_seconds)
    // Only set when there is another page — Telegram asks for it by sending
    // the same query back with this offset.
    |> inline_mode.maybe_next_offset(next_offset)

  use _ <- try(inline_mode.answer(answer, ctx, query.id))
  Ok(ctx)
}

/// Which result the user actually picked. Telegram only sends this if the bot
/// asked for `chosen_inline_result` in `allowed_updates` — which
/// `with_auto_allowed_updates` does as soon as this route exists.
fn chosen_result_handler(ctx, chosen: types.ChosenInlineResult) {
  use ctx <- telega.log_context(ctx, "chosen_inline_result")
  telega.log_info(ctx, "shared item: " <> chosen.result_id)
  Ok(ctx)
}

// --- Wiring -----------------------------------------------------------------

pub fn build_router() -> router.Router(Nil, telega_error.TelegaError, Nil) {
  router.new("shop")
  |> router.on_command_with_description(
    "start",
    "What this bot does",
    start_handler,
  )
  |> router.on_command_with_description(
    "shop",
    "Browse the catalogue",
    shop_handler,
  )
  |> router.on_command_with_description(
    "refund",
    "Refund a purchase",
    refund_handler,
  )
  |> router.on_callback_data(buy_callback(), buy_handler)
  |> router.on_pre_checkout_query(pre_checkout_handler)
  |> router.on_custom(
    matcher: is_successful_payment,
    handler: successful_payment_handler,
  )
  |> router.on_inline_query(inline_query_handler)
  |> router.on_chosen_inline_result(chosen_result_handler)
}

pub fn main() {
  let assert Ok(token) = envoy.get("BOT_TOKEN")

  let assert Ok(_bot) =
    telega.new(telega_httpc.new(token))
    |> telega.router(build_router())
    |> telega.with_auto_commands()
    |> telega.with_auto_allowed_updates()
    |> telega.start()

  process.sleep_forever()
}

fn try(result, fun) {
  telega_error.try(result, fn(e) { e }, fun)
}
