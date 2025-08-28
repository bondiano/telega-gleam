import gleam/erlang/process
import telega
import telega/polling
import telega/reply
import telega/update.{CommandUpdate, TextUpdate}

fn echo_handler(ctx, update) {
  use ctx <- telega.log_context(ctx, "echo")

  case update {
    TextUpdate(text:, ..) -> {
      let assert Ok(_) = reply.with_text(ctx, text)
      Ok(ctx)
    }
    CommandUpdate(command:, ..) -> {
      let assert Ok(_) = reply.with_text(ctx, "Command: " <> command.text)
      Ok(ctx)
    }
    _ -> Ok(ctx)
  }
}

pub fn main() {
  let assert Ok(bot) =
    telega.new_for_polling(token: "BOT_TOKEN")
    |> telega.handle_all(echo_handler)
    |> telega.init_nil_session()

  let assert Ok(_poller) = polling.init_polling_default(bot)

  process.sleep_forever()
}
