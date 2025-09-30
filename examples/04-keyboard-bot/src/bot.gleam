import envoy
import gleam/erlang/process
import gleam/option.{None, Some}
import mist
import taskle
import wisp
import wisp/wisp_mist

import telega
import telega/adapters/wisp as telega_wisp
import telega/api as telega_api
import telega/bot.{type Context}
import telega/client as telega_client
import telega/error as telega_error
import telega/format as fmt
import telega/keyboard as telega_keyboard
import telega/model/encoder as telega_model_encoder
import telega/model/types.{AnswerCallbackQueryParameters}
import telega/reply
import telega/router

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

fn start_command_handler(ctx: BotContext, _command) {
  use ctx <- telega.log_context(ctx, "start")
  use _ <- try(reply.with_formatted(
    ctx,
    t_welcome_message(ctx.session.language),
  ))

  Ok(ctx)
}

const commands = [
  #("/lang", "Shows custom keyboard with languages"),
  #("/lang_inline", "Change language inline"),
]

fn build_bot() {
  let assert Ok(token) = envoy.get("BOT_TOKEN")
  let assert Ok(webhook_path) = envoy.get("WEBHOOK_PATH")
  let assert Ok(url) = envoy.get("SERVER_URL")
  let assert Ok(secret_token) = envoy.get("BOT_SECRET_TOKEN")

  let assert Ok(client) = telega_client.new_with_queue(token)
  let assert Ok(_) =
    telega_api.set_my_commands(
      client,
      telega_model_encoder.bot_commands_from(commands),
      None,
    )

  let router =
    router.new("keyboard_bot")
    |> router.on_command("start", start_command_handler)
    |> router.on_command("lang", change_languages_keyboard)
    |> router.on_command("lang_inline", handle_inline_change_language)

  telega.new(token:, url:, webhook_path:, secret_token: Some(secret_token))
  |> telega.set_api_client(client)
  |> telega.with_router(router)
  |> telega.set_drop_pending_updates(True)
  |> session.attach()
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

type BotContext =
  Context(LanguageBotSession, BotError)

type BotError {
  TelegaBotError(telega_error.TelegaError)
  TaskleError(taskle.Error)
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
