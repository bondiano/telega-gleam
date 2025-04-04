import gleam/bool
import gleam/float
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp

import telega/internal/config.{type Config}
import telega/internal/log
import telega/internal/registry

import telega/api
import telega/bot.{
  type BotSubject, type CallbackQueryFilter, type Context, type Handler,
  type Hears, type SessionSettings, CallbackQueryFilter, HandleAll,
  HandleCallbackQuery, HandleCommand, HandleCommands, HandleHears, HandleText,
  SessionSettings,
}
import telega/model.{type User}
import telega/update.{type Command, type Update}

pub opaque type Telega(session) {
  Telega(config: Config, bot_info: User, bot_subject: BotSubject)
}

pub opaque type TelegaBuilder(session) {
  TelegaBuilder(
    config: Config,
    handlers: List(Handler(session)),
    session_settings: Option(SessionSettings(session)),
    bot_subject: Option(BotSubject),
  )
}

/// Check if a path is the webhook path for the bot.
///
/// Useful if you plan to implement own adapter.
pub fn is_webhook_path(telega: Telega(session), path: String) {
  telega.config.webhook_path == path
}

/// Check if a secret token is valid.
///
/// Useful if you plan to implement own adapter.
pub fn is_secret_token_valid(telega: Telega(session), token: String) {
  telega.config.secret_token == token
}

/// Helper to get the config for API requests.
pub fn get_api_config(telega: Telega(session)) {
  telega.config.api
}

/// Create a new Telega instance.
pub fn new(
  token token: String,
  url server_url: String,
  webhook_path webhook_path: String,
  secret_token secret_token: Option(String),
) {
  TelegaBuilder(
    handlers: [],
    config: config.new(token:, webhook_path:, secret_token:, url: server_url),
    session_settings: None,
    bot_subject: None,
  )
}

/// Handles all messages.
pub fn handle_all(
  bot builder: TelegaBuilder(session),
  handler handler: fn(Context(session)) -> Result(Context(session), String),
) {
  TelegaBuilder(..builder, handlers: [HandleAll(handler), ..builder.handlers])
}

/// Stops bot message handling from current chat and waits for any message.
///
/// See [conversation]
pub fn wait_any(
  ctx ctx: Context(session),
  continue continue: fn(Context(session)) -> Result(Context(session), String),
) {
  bot.wait_handler(ctx, HandleAll(continue))
}

/// Handles a specific command.
pub fn handle_command(
  bot builder: TelegaBuilder(session),
  command command: String,
  handler handler: fn(Context(session), Command) ->
    Result(Context(session), String),
) {
  TelegaBuilder(..builder, handlers: [
    HandleCommand(command, handler),
    ..builder.handlers
  ])
}

/// Stops bot message handling from current chat and waits for a specific command.
///
/// See [conversation]
pub fn wait_command(
  ctx ctx: Context(session),
  command command: String,
  continue continue: fn(Context(session), Command) ->
    Result(Context(session), String),
) {
  bot.wait_handler(ctx, HandleCommand(command, continue))
}

/// Handles multiple commands.
pub fn handle_commands(
  bot builder: TelegaBuilder(session),
  commands commands: List(String),
  handler handler: fn(Context(session), Command) ->
    Result(Context(session), String),
) {
  TelegaBuilder(..builder, handlers: [
    HandleCommands(commands, handler),
    ..builder.handlers
  ])
}

/// Stops bot message handling from current chat and waits for a specific command.
///
/// See [conversation]
pub fn wait_commands(
  ctx ctx: Context(session),
  commands commands: List(String),
  continue continue: fn(Context(session), Command) ->
    Result(Context(session), String),
) -> Result(Context(session), String) {
  bot.wait_handler(ctx, HandleCommands(commands, continue))
}

/// Handles text messages.
pub fn handle_text(
  bot builder: TelegaBuilder(session),
  handler handler: fn(Context(session), String) ->
    Result(Context(session), String),
) {
  TelegaBuilder(..builder, handlers: [HandleText(handler), ..builder.handlers])
}

/// Stops bot message handling from current chat and waits for a text message.
///
/// See [conversation]
pub fn wait_text(
  ctx ctx: Context(session),
  continue continue: fn(Context(session), String) ->
    Result(Context(session), String),
) {
  bot.wait_handler(ctx, HandleText(continue))
}

/// Handles messages that match the given `Hears`.
pub fn handle_hears(
  bot builder: TelegaBuilder(session),
  hears hears: Hears,
  handler handler: fn(Context(session), String) ->
    Result(Context(session), String),
) -> TelegaBuilder(session) {
  TelegaBuilder(..builder, handlers: [
    HandleHears(hears, handler),
    ..builder.handlers
  ])
}

/// Stops bot message handling from current chat and waits for a message that matches the given `Hears`.
///
/// See [conversation]
pub fn wait_hears(
  ctx ctx: Context(session),
  hears hears: Hears,
  continue continue: fn(Context(session), String) ->
    Result(Context(session), String),
) {
  bot.wait_handler(ctx, HandleHears(hears, continue))
}

/// Handles messages from inline keyboard callback.
pub fn handle_callback_query(
  bot builder: TelegaBuilder(session),
  filter filter: CallbackQueryFilter,
  handler handler: fn(Context(session), String, String) ->
    Result(Context(session), String),
) {
  TelegaBuilder(..builder, handlers: [
    HandleCallbackQuery(filter, handler),
    ..builder.handlers
  ])
}

/// Wait for a callback query and continue with the given function.
pub fn wait_callback_query(
  ctx ctx: Context(session),
  filter filter: CallbackQueryFilter,
  continue continue: fn(Context(session), String, String) ->
    Result(Context(session), String),
) {
  bot.wait_handler(ctx, HandleCallbackQuery(filter, continue))
}

/// Log the message and error message if the handler fails.
pub fn log_context(
  ctx ctx: Context(session),
  prefix prefix: String,
  handler handler: fn() -> Result(Context(session), String),
) {
  let prefix = "[" <> prefix <> "] "

  log.info(prefix <> "received update: " <> bot.fmt_update(ctx))

  let start_time = timestamp.system_time()
  let result =
    handler()
    |> result.map_error(fn(e) {
      log.error(prefix <> "handler failed: " <> string.inspect(e))
      e
    })
  let end_time = timestamp.system_time()
  let time =
    start_time
    |> timestamp.difference(end_time)
    |> duration.to_seconds
    |> float.to_string

  log.info(prefix <> "handler completed in " <> time <> " seconds")

  result
}

/// Construct a session settings.
pub fn with_session_settings(
  builder,
  persist_session persist_session,
  get_session get_session,
  default_session default_session,
) {
  TelegaBuilder(
    ..builder,
    session_settings: Some(SessionSettings(
      persist_session:,
      get_session:,
      default_session:,
    )),
  )
}

/// Initialize a Telega instance with a `Nil` session.
/// Useful when you don't need to persist the session.
pub fn init_nil_session(builder: TelegaBuilder(Nil)) {
  let persist_session = fn(_, _) { Ok(Nil) }
  let get_session = fn(_) { Ok(Nil) }
  let default_session = fn() { Nil }

  TelegaBuilder(
    ..builder,
    session_settings: Some(SessionSettings(
      persist_session:,
      get_session:,
      default_session:,
    )),
  )
  |> init
}

/// Initialize a Telega instance.
/// This function should be called **only** after all handlers are added to the builder.
/// It will set the webhook and start handling messages.
pub fn init(builder: TelegaBuilder(session)) {
  use is_ok <- result.try(bot.set_webhook(builder.config))
  use <- bool.guard(!is_ok, Error("Failed to set webhook"))

  use bot_info <- result.try(api.get_me(builder.config.api))

  let session_settings =
    option.to_result(
      builder.session_settings,
      "Session settings not initialized",
    )

  use session_settings <- result.try(session_settings)

  use registry_subject <- result.try(
    registry.start()
    |> result.map_error(fn(error) {
      "Failed to start registry: " <> string.inspect(error)
    }),
  )

  use bot_subject <- result.try(
    bot.start(
      bot_info:,
      registry_subject:,
      session_settings:,
      config: builder.config,
      handlers: builder.handlers,
    )
    |> result.map_error(fn(error) {
      "Failed to start bot: " <> string.inspect(error)
    }),
  )

  Ok(Telega(bot_info:, bot_subject:, config: builder.config))
}

/// Handle an update from the Telegram API.
pub fn handle_update(telega: Telega(session), update: Update) {
  bot.handle_update(telega.bot_subject, update)
}
