import envoy
import gleam/erlang/process
import gleam/option.{None, Some}
import mist
import wisp
import wisp/wisp_mist

import telega
import telega/adapters/wisp as telega_wisp
import telega/api as telega_api
import telega/client as telega_client
import telega/error as telega_error
import telega/model as telega_model
import telega/reply

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

fn dice_command_handler(ctx, _) {
  use ctx <- telega.log_context(ctx, "dice")
  use _ <- try(reply.with_dice(ctx, None))

  Ok(ctx)
}

fn start_command_handler(ctx, _) {
  use ctx <- telega.log_context(ctx, "start")
  use _ <- try(reply.with_text(
    ctx,
    "Hello! I'm a dice bot. You can roll a dice by sending /dice command.",
  ))

  Ok(ctx)
}

const commands = [#("/dice", "Roll a dice")]

fn build_bot() {
  let assert Ok(token) = envoy.get("BOT_TOKEN")
  let assert Ok(webhook_path) = envoy.get("WEBHOOK_PATH")
  let assert Ok(url) = envoy.get("SERVER_URL")
  let assert Ok(secret_token) = envoy.get("BOT_SECRET_TOKEN")

  // Set bot commands once at startup
  let client = telega_client.new(token)
  let assert Ok(_) =
    telega_api.set_my_commands(
      client,
      telega_model.bot_commands_from(commands),
      None,
    )

  telega.new(token:, url:, webhook_path:, secret_token: Some(secret_token))
  |> telega.handle_command("start", start_command_handler)
  |> telega.handle_command("dice", dice_command_handler)
  |> telega.init_nil_session
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

type BotError {
  TelegaBotError(telega_error.TelegaError)
}

fn try(result, fun) {
  telega_error.try(result, TelegaBotError, fun)
}
