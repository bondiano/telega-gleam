import dotenv_gleam
import envoy
import gleam/erlang/process
import gleam/option.{None, Some}
import mist
import wisp
import wisp/wisp_mist

import telega
import telega/adapters/wisp as telega_wisp
import telega/api as telega_api
import telega/error as telega_error
import telega/model as telega_model
import telega/reply

fn middleware(req, bot, handle_request) {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use <- telega_wisp.handle_bot(req, bot)
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

fn dice_command_handler(ctx, _) {
  use <- telega.log_context(ctx, "dice")
  use _ <- try(reply.with_dice(ctx, None))

  Ok(ctx)
}

fn start_command_handler(ctx, _) {
  use <- telega.log_context(ctx, "start")

  use _ <- try(telega_api.set_my_commands(
    ctx.config.api_client,
    telega_model.bot_commands_from([#("/dice", "Roll a dice")]),
    None,
  ))
  use _ <- try(reply.with_text(
    ctx,
    "Hello! I'm a dice bot. You can roll a dice by sending /dice command.",
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
  |> telega.handle_command("dice", dice_command_handler)
  |> telega.init_nil_session
}

pub fn main() {
  dotenv_gleam.config()
  wisp.configure_logger()

  let assert Ok(bot) = build_bot()
  let secret_key_base = wisp.random_string(64)
  let assert Ok(_) =
    wisp_mist.handler(handle_request(bot, _), secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}

type BotError {
  TelegaBotError(telega_error.TelegaError)
}

fn try(result, fun) {
  telega_error.try(result, TelegaBotError, fun)
}
