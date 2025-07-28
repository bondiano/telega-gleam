import envoy
import gleam/bool
import gleam/erlang/process
import gleam/option.{None, Some}
import mist
import session.{type NameBotSession, NameBotSession, SetName, WaitName}
import wisp
import wisp/wisp_mist

import telega
import telega/adapters/wisp as telega_wisp
import telega/api as telega_api
import telega/bot.{type Context}
import telega/error as telega_error
import telega/model as telega_model
import telega/reply

import bot/utils

fn middleware(req, bot, handle_request) {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use <- telega_wisp.handle_bot(bot, req)
  use req <- wisp.handle_head(req)
  handle_request(req)
}

fn handle_request(bot, req) {
  use req <- middleware(req, bot)

  case wisp.path_segments(req) {
    ["health"] -> wisp.ok()
    _ -> wisp.not_found()
  }
}

fn set_name_command_handler(ctx: BotContext, _) {
  use <- bool.guard(ctx.session.state != WaitName, Ok(ctx))
  use <- telega.log_context(ctx, "set_name command")
  use _ <- try(reply.with_text(ctx, "What's your name?"))

  bot.next_session(ctx, NameBotSession(..ctx.session, state: SetName))
}

fn set_name_message_handler(ctx: BotContext, name) {
  use <- bool.guard(ctx.session.state != SetName, Ok(ctx))
  use <- telega.log_context(ctx, "set_name")
  use _ <- try(reply.with_text(ctx, "Your name is: " <> name <> " set!"))

  bot.next_session(ctx, NameBotSession(name:, state: WaitName))
}

fn get_name_command_handler(ctx: BotContext, _) {
  use <- telega.log_context(ctx, "get_name command")
  use _ <- try(reply.with_text(ctx, "Your name is: " <> ctx.session.name))

  Ok(ctx)
}

fn start_command_handler(ctx, _) {
  use <- telega.log_context(ctx, "start")

  use _ <- try(telega_api.set_my_commands(
    ctx.config.api_client,
    telega_model.bot_commands_from([
      #("/set_name", "Set name"),
      #("/get_name", "Get name"),
    ]),
    None,
  ))
  use _ <- try(reply.with_text(
    ctx,
    "Hello! I'm a Name bot. You can set your name with /set_name command.",
  ))

  Ok(ctx)
}

fn build_bot() {
  let assert Ok(token) = envoy.get("BOT_TOKEN")
  let assert Ok(webhook_path) = envoy.get("WEBHOOK_PATH")
  let assert Ok(url) = envoy.get("SERVER_URL")
  let assert Ok(secret_token) = envoy.get("BOT_SECRET_TOKEN")

  telega.new(token:, url:, webhook_path:, secret_token: Some(secret_token))
  |> telega.handle_command("start", start_command_handler)
  |> telega.handle_command("set_name", set_name_command_handler)
  |> telega.handle_command("get_name", get_name_command_handler)
  |> telega.handle_text(set_name_message_handler)
  |> session.attach
  |> telega.init
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
  Context(NameBotSession, BotError)

type BotError {
  TelegaBotError(telega_error.TelegaError)
}

fn try(result, fun) {
  telega_error.try(result, TelegaBotError, fun)
}
