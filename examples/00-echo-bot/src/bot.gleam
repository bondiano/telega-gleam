import telega
import telega/polling
import telega/reply
import telega/router
import telega/update

fn handle_text(ctx, text) {
  use ctx <- telega.log_context(ctx, "echo_text")
  let assert Ok(_) = reply.with_text(ctx, text)
  Ok(ctx)
}

fn handle_command(ctx, command: update.Command) {
  use ctx <- telega.log_context(ctx, "echo_command")
  let assert Ok(_) = reply.with_text(ctx, "Command: " <> command.text)
  Ok(ctx)
}

pub fn main() {
  let router =
    router.new("echo_bot")
    |> router.on_any_text(handle_text)
    |> router.on_commands(["start", "help"], handle_command)

  let assert Ok(bot) =
    telega.new_for_polling(token: "BOT_TOKEN")
    |> telega.with_router(router)
    |> telega.init_for_polling_nil_session()

  let assert Ok(poller) = polling.start_polling_default(bot)

  polling.wait_finish(poller)
}
