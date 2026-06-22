import envoy
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import mist
import taskle
import wisp
import wisp/wisp_mist

import telega
import telega/bot.{type Context}
import telega/error as telega_error
import telega/format as fmt
import telega/inline_mode
import telega/keyboard as telega_keyboard
import telega/model/types.{
  type InlineQuery, type PreCheckoutQuery, AnswerCallbackQueryParameters,
}
import telega/payments
import telega/reply
import telega/router
import telega_httpc
import telega_wisp

import bot/utils
import language_keyboard
import session.{type LanguageBotSession, English, LanguageBotSession, Russian}

fn middleware(bot, req, handle_request) {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use <- telega_wisp.handle_bot(bot, req)
  use req <- wisp.handle_head(req)
  handle_request(req)
}

fn handle_request(bot, req) {
  use req <- middleware(bot, req)

  case wisp.path_segments(req) {
    ["health"] -> wisp.ok()
    _ -> wisp.not_found()
  }
}

fn t_welcome_message(language) {
  case language {
    English ->
      fmt.build()
      |> fmt.bold_text("Hello! ")
      |> fmt.text("I'm a Change Language bot.")
      |> fmt.line_break()
      |> fmt.text("You can change language with ")
      |> fmt.code_text("/lang")
      |> fmt.text(" or ")
      |> fmt.code_text("/lang_inline")
      |> fmt.text(" commands.")
      |> fmt.to_formatted()
    Russian ->
      fmt.build()
      |> fmt.bold_text("Привет! ")
      |> fmt.text("Я бот для смены языка.")
      |> fmt.line_break()
      |> fmt.text("Вы можете сменить язык с помощью команд ")
      |> fmt.code_text("/lang")
      |> fmt.text(" или ")
      |> fmt.code_text("/lang_inline")
      |> fmt.text(".")
      |> fmt.to_formatted()
  }
}

fn t_change_language_message(language) {
  case language {
    English ->
      fmt.build()
      |> fmt.underline_text("Choose your language")
      |> fmt.to_formatted()
    Russian ->
      fmt.build()
      |> fmt.underline_text("Выберите ваш язык")
      |> fmt.to_formatted()
  }
}

fn t_language_changed_message(language) {
  case language {
    English ->
      fmt.build()
      |> fmt.bold_text("✅ Language changed to ")
      |> fmt.code_text("English")
    Russian ->
      fmt.build()
      |> fmt.bold_text("✅ Язык изменен на ")
      |> fmt.code_text("русский")
  }
  |> fmt.to_formatted()
}

fn change_languages_keyboard(ctx: BotContext, _command) {
  use ctx <- telega.log_context(ctx, "change language with keyboard")

  let language = ctx.session.language

  use ctx, selected_language <- telega.wait_choice(
    ctx:,
    options: [
      #(language_keyboard.t_russian_button_text(language), Russian),
      #(language_keyboard.t_english_button_text(language), English),
    ],
    or: None,
    timeout: None,
  )

  use _ <- try(reply.with_formatted(
    ctx,
    t_language_changed_message(selected_language),
  ))

  bot.next_session(ctx, LanguageBotSession(selected_language))
}

fn handle_inline_change_language(ctx: BotContext, _command) {
  use ctx <- telega.log_context(ctx, "change language inline")

  let language = ctx.session.language
  let callback_data = language_keyboard.build_keyboard_callback_data()
  let keyboard = language_keyboard.new_inline_keyboard(language, callback_data)
  use message <- try(reply.with_formatted_markup(
    ctx,
    t_change_language_message(language),
    telega_keyboard.inline_to_markup(keyboard),
  ))

  let assert Ok(filter) = telega_keyboard.filter_inline_keyboard_query(keyboard)

  use ctx, payload, callback_query_id <- telega.wait_callback_query(
    ctx:,
    filter: Some(filter),
    or: None,
    timeout: Some(1000),
  )

  let assert Ok(language_callback) =
    telega_keyboard.unpack_callback(payload, callback_data)
  let language = language_callback.data

  let tasks =
    taskle.await2(
      taskle.async(fn() {
        reply.answer_callback_query(
          ctx,
          AnswerCallbackQueryParameters(
            callback_query_id: callback_query_id,
            text: None,
            show_alert: None,
            url: None,
            cache_time: None,
          ),
        )
      }),
      taskle.async(fn() {
        reply.edit_text_formatted(
          ctx,
          message.message_id,
          t_language_changed_message(language),
        )
      }),
      1000,
    )

  use _ <- try_taskle(tasks)
  bot.next_session(ctx, LanguageBotSession(language))
}

fn t_donate_title(language) {
  case language {
    English -> "Support the bot"
    Russian -> "Поддержать бота"
  }
}

fn t_donate_description(language) {
  case language {
    English -> "A small donation to keep the bot running"
    Russian -> "Небольшое пожертвование на работу бота"
  }
}

fn t_donate_thanks(language, amount) {
  case language {
    English -> "🎉 Thank you for " <> int.to_string(amount) <> " ⭐!"
    Russian -> "🎉 Спасибо за " <> int.to_string(amount) <> " ⭐!"
  }
}

const donate_amounts = [1, 25, 50]

/// Sells a "donation" for Telegram Stars: the user picks an amount,
/// gets an invoice, the pre-checkout query is confirmed by
/// `handle_pre_checkout_query`, and the handler resumes once the
/// successful payment service message arrives.
fn donate_command_handler(ctx: BotContext, _command) {
  use ctx <- telega.log_context(ctx, "donate")

  let language = ctx.session.language

  use ctx, amount <- telega.wait_choice(
    ctx:,
    options: list.map(donate_amounts, fn(amount) {
      #("⭐ " <> int.to_string(amount), amount)
    }),
    or: None,
    timeout: None,
  )

  use _ <- try(
    payments.stars_invoice(
      title: t_donate_title(language),
      description: t_donate_description(language),
      payload: "donate:" <> int.to_string(amount),
      amount:,
    )
    |> payments.send(ctx),
  )

  use ctx, payment <- payments.wait_successful_payment(
    ctx,
    or: None,
    timeout: Some(600_000),
  )

  use _ <- try(reply.with_text(
    ctx,
    t_donate_thanks(language, payment.total_amount),
  ))

  Ok(ctx)
}

/// Telegram requires an answer within 10 seconds, otherwise the payment
/// fails — donations need no validation, so always confirm.
fn handle_pre_checkout_query(ctx: BotContext, query: PreCheckoutQuery) {
  use ctx <- telega.log_context(ctx, "pre_checkout")

  use _ <- try(payments.answer_pre_checkout_ok(ctx, query))

  Ok(ctx)
}

/// Phrasebook shared via inline mode: type `@bot <query>` in any chat.
const phrasebook = [
  #("Hello", "Привет"),
  #("Good morning", "Доброе утро"),
  #("Good evening", "Добрый вечер"),
  #("Thank you", "Спасибо"),
  #("You're welcome", "Пожалуйста"),
  #("How are you?", "Как дела?"),
  #("Nice to meet you", "Приятно познакомиться"),
  #("Goodbye", "До свидания"),
]

fn handle_inline_query(ctx: BotContext, query: InlineQuery) {
  use ctx <- telega.log_context(ctx, "inline query")

  let search = string.lowercase(query.query)
  let matches =
    list.filter(phrasebook, fn(phrase) {
      string.contains(string.lowercase(phrase.0), search)
      || string.contains(string.lowercase(phrase.1), search)
    })

  let #(page, next_offset) =
    inline_mode.paginate(items: matches, offset: query.offset, page_size: 5)

  use _ <- try(
    list.index_fold(page, inline_mode.new(), fn(builder, phrase, index) {
      let #(english, russian) = phrase
      inline_mode.article_described(
        builder,
        id: query.offset <> ":" <> int.to_string(index),
        title: english,
        text: english <> " — " <> russian,
        description: Some(russian),
      )
    })
    |> inline_mode.with_cache_time(60)
    |> inline_mode.maybe_next_offset(next_offset)
    |> inline_mode.answer(ctx, query.id),
  )

  Ok(ctx)
}

fn start_command_handler(ctx: BotContext, _command) {
  use ctx <- telega.log_context(ctx, "start")
  use _ <- try(reply.with_formatted(
    ctx,
    t_welcome_message(ctx.session.language),
  ))

  Ok(ctx)
}

pub type BotContext =
  Context(LanguageBotSession, BotError, Nil)

pub type BotError {
  TelegaBotError(telega_error.TelegaError)
  TaskleError(taskle.Error)
}

pub fn build_router() -> router.Router(LanguageBotSession, BotError, Nil) {
  router.new("keyboard_bot")
  // Per-user flood control: at most 5 updates in 3 seconds,
  // excess updates are dropped silently.
  |> router.use_middleware(
    router.with_rate_limit(limit: 5, window_ms: 3000, on_limit: fn(ctx) {
      Ok(ctx)
    }),
  )
  |> router.on_command("start", start_command_handler)
  |> router.on_command_with_description(
    "lang",
    "Shows custom keyboard with languages",
    change_languages_keyboard,
  )
  |> router.on_command_with_description(
    "lang_inline",
    "Change language inline",
    handle_inline_change_language,
  )
  |> router.on_command_with_description(
    "donate",
    "Support the bot with Telegram Stars",
    donate_command_handler,
  )
  |> router.on_inline_query(handle_inline_query)
  |> router.on_pre_checkout_query(handle_pre_checkout_query)
}

fn build_bot() {
  let assert Ok(token) = envoy.get("BOT_TOKEN")
  let assert Ok(webhook_path) = envoy.get("WEBHOOK_PATH")
  let assert Ok(url) = envoy.get("SERVER_URL")
  let assert Ok(secret_token) = envoy.get("BOT_SECRET_TOKEN")

  let assert Ok(client) = telega_httpc.new_with_queue(token)
  let router = build_router()

  telega.new(
    api_client: client,
    url:,
    webhook_path:,
    secret_token: Some(secret_token),
  )
  |> telega.with_router(router)
  |> telega.set_drop_pending_updates(True)
  |> session.attach()
  // Publish the router's commands to the Telegram menu on start, and request
  // only the update types the router actually handles.
  |> telega.with_auto_commands()
  |> telega.with_auto_allowed_updates()
  |> telega.init()
}

pub fn main() {
  let assert Ok(_) = utils.env_config()
  wisp.configure_logger()

  let assert Ok(bot) = build_bot()
  let secret_key_base = wisp.random_string(64)
  let assert Ok(_) =
    wisp_mist.handler(handle_request(bot, _), secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}

fn try(result, fun) {
  telega_error.try(result, TelegaBotError, fun)
}

fn try_taskle(result, fun) {
  case result {
    Ok(x) -> fun(x)
    Error(e) -> Error(TaskleError(e))
  }
}
