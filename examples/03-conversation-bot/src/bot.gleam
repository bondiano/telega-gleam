import envoy
import gleam/erlang/process
import gleam/option.{None, Some}
import mist
import session.{type NameBotSession, NameBotSession}
import wisp
import wisp/wisp_mist

import telega
import telega/adapters/wisp as telega_wisp
import telega/api as telega_api
import telega/bot.{type Context}
import telega/client as telega_client
import telega/error as telega_error
import telega/model/encoder as telega_encoder
import telega/reply
import telega/router

import bot/utils

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

fn set_name_command_handler(ctx, _command) {
  use ctx <- telega.log_context(ctx, "set_name command")
  use _ <- try(reply.with_text(ctx, "What's your name?"))

  use ctx, name <- telega.wait_text(ctx, or: None, timeout: Some(1000))
  use _ <- try(reply.with_text(ctx, "Your name is: " <> name <> " set!"))

  bot.next_session(ctx, NameBotSession(name: name))
}

fn get_name_command_handler(ctx: BotContext, _command) {
  use ctx <- telega.log_context(ctx, "get_name command")
  use _ <- try(reply.with_text(ctx, "Your name is: " <> ctx.session.name))
  Ok(ctx)
}

fn start_command_handler(ctx, _command) {
  use ctx <- telega.log_context(ctx, "start")
  use _ <- try(reply.with_text(
    ctx,
    "Hello! I'm a Name bot. You can set your name with /set_name command.",
  ))
  Ok(ctx)
}

const commands = [#("/set_name", "Set name"), #("/get_name", "Get name")]

fn build_bot() {
  let assert Ok(token) = envoy.get("BOT_TOKEN")
  let assert Ok(webhook_path) = envoy.get("WEBHOOK_PATH")
  let assert Ok(url) = envoy.get("SERVER_URL")
  let assert Ok(secret_token) = envoy.get("BOT_SECRET_TOKEN")

  let client = telega_client.new(token)
  let assert Ok(_) =
    telega_api.set_my_commands(
      client,
      telega_encoder.bot_commands_from(commands),
      None,
    )

  let router =
    router.new("conversation_bot")
    |> router.on_command("start", start_command_handler)
    |> router.on_command("set_name", set_name_command_handler)
    |> router.on_command("get_name", get_name_command_handler)

  telega.new(token:, url:, webhook_path:, secret_token: Some(secret_token))
  |> telega.with_router(router)
  |> session.attach
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
  Context(NameBotSession, BotError)

type BotError {
  TelegaBotError(telega_error.TelegaError)
}

fn try(result, fun) {
  telega_error.try(result, TelegaBotError, fun)
}
