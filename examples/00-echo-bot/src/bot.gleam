import gleam/erlang/process
import telega
import telega/reply
import telega/router
import telega/update
import telega_httpc

fn handle_text(ctx, text) {
  use ctx <- telega.log_context(ctx, "echo_text")
  reply.text(ctx, text)
}

fn handle_command(ctx, command: update.Command) {
  use ctx <- telega.log_context(ctx, "echo_command")
  reply.text(ctx, "Command: " <> command.text)
}

pub fn build_router() {
  router.new("echo_bot")
  |> router.on_any_text(handle_text)
  |> router.on_commands(["start", "help"], handle_command)
}

pub fn main() {
  let router = build_router()

  let api_client =
    telega_httpc.new("8442380256:AAG0sVX3zmGZUCEjAGutcVBcVtB-XLYuvWY")

  let assert Ok(_bot) =
    telega.new(api_client)
    |> telega.router(router)
    |> telega.start()

  process.sleep_forever()
}
