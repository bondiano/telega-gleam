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
import telega/keyboard as telega_keyboard
import telega/model.{EditMessageTextParameters} as telega_model
import telega/reply

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

fn t_welcome_message(language) -> String {
  case language {
    English ->
      "Hello! I'm a Change Language bot. You can change language with /lang or /lang_inline commands."
    Russian ->
      "Привет! Я бот для смены языка. Вы можете сменить язык с помощью команд /lang или /lang_inline."
  }
}

fn t_change_language_message(language) {
  case language {
    English -> "Choose your language"
    Russian -> "Выберите ваш язык"
  }
}

fn t_language_changed_message(language) {
  case language {
    English -> "Language changed to English"
    Russian -> "Язык изменен на русский"
  }
}

fn t_none_keyboard_message(language) {
  case language {
    English -> "Use buttons to change language"
    Russian -> "Используйте кнопки для смены языка"
  }
}

fn change_languages_keyboard(ctx: BotContext, _) {
  use ctx <- telega.log_context(ctx, "change language with keyboard")

  let language = ctx.session.language
  let keyboard = language_keyboard.new_keyboard(language)
  use _ <- try(reply.with_markup(
    ctx,
    t_change_language_message(language),
    telega_keyboard.to_markup(keyboard),
  ))

  use _, text <- telega.wait_hears(
    ctx:,
    hears: telega_keyboard.hear(keyboard),
    or: bot.HandleAll(handle_none_keyboard_message) |> Some,
    timeout: None,
  )
  let language = language_keyboard.option_to_language(text)
  use _ <- try(reply.with_text(ctx, t_language_changed_message(language)))
  bot.next_session(ctx, LanguageBotSession(language))
}

fn handle_none_keyboard_message(ctx: BotContext, _) {
  use ctx <- telega.log_context(ctx, "change language with none keyboard")
  use _ <- try(reply.with_text(
    ctx,
    t_none_keyboard_message(ctx.session.language),
  ))
  bot.next_session(ctx, LanguageBotSession(ctx.session.language))
}

fn handle_inline_change_language(ctx: BotContext, _) {
  use ctx <- telega.log_context(ctx, "change language inline")

  let language = ctx.session.language
  let callback_data = language_keyboard.build_keyboard_callback_data()
  let keyboard = language_keyboard.new_inline_keyboard(language, callback_data)
  use message <- try(reply.with_markup(
    ctx,
    t_change_language_message(language),
    telega_keyboard.to_inline_markup(keyboard),
  ))

  let assert Ok(filter) = telega_keyboard.filter_inline_keyboard_query(keyboard)

  use ctx, payload, callback_query_id <- telega.wait_callback_query(
    ctx:,
    filter:,
    or: None,
    timeout: Some(1000),
  )

  let assert Ok(language_callback) =
    telega_keyboard.unpack_callback(payload, callback_data)
  let language = language_callback.data

  use _ <- try_taskle(taskle.await2(
    taskle.async(fn() {
      reply.answer_callback_query(
        ctx,
        telega_model.new_answer_callback_query_parameters(callback_query_id),
      )
    }),
    taskle.async(fn() {
      reply.edit_text(
        ctx,
        EditMessageTextParameters(
          text: t_language_changed_message(language),
          message_id: Some(message.message_id),
          chat_id: Some(telega_model.Str(ctx.key)),
          entities: None,
          inline_message_id: None,
          link_preview_options: None,
          parse_mode: None,
          reply_markup: None,
        ),
      )
    }),
    1000,
  ))

  bot.next_session(ctx, LanguageBotSession(language))
}

fn start_command_handler(ctx: BotContext, _) {
  use ctx <- telega.log_context(ctx, "start")
  use _ <- try(reply.with_text(ctx, t_welcome_message(ctx.session.language)))

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

  let client = telega_client.new(token)
  let assert Ok(_) =
    telega_api.set_my_commands(
      client,
      telega_model.bot_commands_from(commands),
      None,
    )

  telega.new(token:, url:, webhook_path:, secret_token: Some(secret_token))
  |> telega.handle_command("start", start_command_handler)
  |> telega.handle_command("lang", change_languages_keyboard)
  |> telega.handle_command("lang_inline", handle_inline_change_language)
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
