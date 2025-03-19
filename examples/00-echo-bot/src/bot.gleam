import gleam/erlang/process
import gleam/option.{None}
import gleam/result
import mist
import telega
import telega/adapters/wisp as telega_wisp
import telega/reply
import telega/update.{CommandUpdate, TextUpdate}
import wisp
import wisp/wisp_mist

fn handle_request(bot, req) {
  use <- telega_wisp.handle_bot(req, bot)
  wisp.not_found()
}

fn echo_handler(ctx) {
  use <- telega.log_context(ctx, "echo")
  use _ <- result.try(case ctx.update {
    TextUpdate(text:, ..) -> reply.with_text(ctx, text)
    CommandUpdate(command:, ..) -> reply.with_text(ctx, command.text)
    _ -> Error("No text message")
  })
  Ok(ctx)
}

pub fn main() {
  wisp.configure_logger()

  let assert Ok(bot) =
    telega.new(
      token: "your bot token from @BotFather",
      url: "your bot url",
      webhook_path: "secret path",
      secret_token: None,
    )
    |> telega.handle_all(echo_handler)
    |> telega.init_nil_session()

  let assert Ok(_) =
    wisp_mist.handler(handle_request(bot, _), wisp.random_string(64))
    |> mist.new()
    |> mist.port(8000)
    |> mist.start_http()

  process.sleep_forever()
}
