import telega/bot.{type Context, type Feature}

pub fn new() {
  #(Ok, [])
}

/// private, group, supergroup, or channel
pub fn chat_type(
  chat_type: String,
  next: fn(Context(session, error)) -> Feature(session, error),
) {
  todo
}

pub fn handle_command(
  command: String,
  handler: fn(Context(session, error)) -> Context(session, error),
  next: fn(Context(session, error)) -> Feature(session, error),
) {
  todo
}

pub fn handle_text(
  text: String,
  handler: fn(Context(session, error)) -> Context(session, error),
  next: fn(Context(session, error)) -> Feature(session, error),
) {
  todo
}
