import gleam/bool
import gleam/float
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp

import telega/internal/config.{type Config}
import telega/internal/log
import telega/internal/registry
import telega/internal/utils

import telega/api
import telega/bot.{
  type BotSubject, type CallbackQueryFilter, type CatchHandler, type Context,
  type Handler, type Hears, type SessionSettings, Context, HandleAll,
  HandleAudio, HandleCallbackQuery, HandleChatMember, HandleCommand,
  HandleCommands, HandleHears, HandleMessage, HandlePhotos, HandleText,
  HandleVideo, HandleVoice, HandleWebAppData, SessionSettings,
}
import telega/client.{type TelegramClient}
import telega/error
import telega/model.{type Update, type User}
import telega/update.{type Command}

pub opaque type Telega(session, error) {
  Telega(config: Config, bot_info: User, bot_subject: BotSubject)
}

pub opaque type TelegaBuilder(session, error) {
  TelegaBuilder(
    config: Config,
    handlers: List(Handler(session, error)),
    session_settings: Option(SessionSettings(session, error)),
    bot_subject: Option(BotSubject),
    catch_handler: Option(CatchHandler(session, error)),
    // SetWebhook parameters
    drop_pending_updates: Option(Bool),
    max_connections: Option(Int),
    ip_address: Option(String),
    allowed_updates: Option(List(String)),
    certificate: Option(model.File),
  )
}

/// Check if a path is the webhook path for the bot.
///
/// Useful if you plan to implement own adapter.
pub fn is_webhook_path(telega: Telega(session, error), path: String) {
  telega.config.webhook_path == path
}

/// Check if a secret token is valid.
///
/// Useful if you plan to implement own adapter.
pub fn is_secret_token_valid(telega: Telega(session, error), token: String) {
  telega.config.secret_token == token
}

/// Helper to get the config for API requests.
pub fn get_api_config(telega: Telega(session, error)) {
  telega.config.api_client
}

/// Create a new Telega instance.
pub fn new(
  token token: String,
  url server_url: String,
  webhook_path webhook_path: String,
  secret_token secret_token: Option(String),
) {
  let url = utils.normalize_url(server_url)
  let webhook_path = utils.normalize_webhook_path(webhook_path)

  TelegaBuilder(
    handlers: [],
    config: config.new(token:, webhook_path:, secret_token:, url:),
    session_settings: None,
    bot_subject: None,
    catch_handler: None,
    drop_pending_updates: None,
    max_connections: None,
    ip_address: None,
    allowed_updates: None,
    certificate: None,
  )
}

/// Handles all messages.
pub fn handle_all(
  bot builder: TelegaBuilder(session, error),
  handler handler: fn(Context(session, error), update.Update) ->
    Result(Context(session, error), error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, handlers: [HandleAll(handler), ..builder.handlers])
}

/// Stops bot message handling from current chat and waits for any message.
///
/// See [conversation](/docs/conversation)
pub fn wait_any(
  ctx ctx: Context(session, error),
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue handler: fn(Context(session, error), update.Update) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(ctx:, handler: HandleAll(handler:), handle_else:, timeout:)
}

/// Handles a specific command.
pub fn handle_command(
  bot builder: TelegaBuilder(session, error),
  command command: String,
  handler handler: fn(Context(session, error), Command) ->
    Result(Context(session, error), error),
) {
  TelegaBuilder(..builder, handlers: [
    HandleCommand(command, handler),
    ..builder.handlers
  ])
}

/// Stops bot message handling from current chat and waits for a specific command.
///
/// See [conversation](/docs/conversation)
pub fn wait_command(
  ctx ctx: Context(session, error),
  command command: String,
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), Command) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: HandleCommand(command, continue),
  )
}

/// Handles multiple commands.
pub fn handle_commands(
  bot builder: TelegaBuilder(session, error),
  commands commands: List(String),
  handler handler: fn(Context(session, error), Command) ->
    Result(Context(session, error), error),
) {
  TelegaBuilder(..builder, handlers: [
    HandleCommands(commands, handler),
    ..builder.handlers
  ])
}

/// Stops bot message handling from current chat and waits for a specific command.
///
/// See [conversation](/docs/conversation)
pub fn wait_commands(
  ctx ctx: Context(session, error),
  commands commands: List(String),
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), Command) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: HandleCommands(commands, continue),
  )
}

/// Handles text messages.
pub fn handle_text(
  bot builder: TelegaBuilder(session, error),
  handler handler: fn(Context(session, error), String) ->
    Result(Context(session, error), error),
) {
  TelegaBuilder(..builder, handlers: [HandleText(handler), ..builder.handlers])
}

/// Stops bot message handling from current chat and waits for a text message.
///
/// See [conversation](/docs/conversation)
pub fn wait_text(
  ctx ctx: Context(session, error),
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), String) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(ctx:, handler: HandleText(continue), handle_else:, timeout:)
}

/// Handles messages that match the given `Hears`.
pub fn handle_hears(
  bot builder: TelegaBuilder(session, error),
  hears hears: Hears,
  handler handler: fn(Context(session, error), String) ->
    Result(Context(session, error), error),
) {
  TelegaBuilder(..builder, handlers: [
    HandleHears(hears, handler),
    ..builder.handlers
  ])
}

/// Stops bot message handling from current chat and waits for a message that matches the given `Hears`.
///
/// See [conversation](/docs/conversation)
pub fn wait_hears(
  ctx ctx: Context(session, error),
  hears hears: Hears,
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), String) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: HandleHears(hears, continue),
  )
}

/// Handles any message.
pub fn handle_message(
  bot builder: TelegaBuilder(session, error),
  handler handler: fn(Context(session, error), model.Message) ->
    Result(Context(session, error), error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, handlers: [
    HandleMessage(handler:),
    ..builder.handlers
  ])
}

/// Stops bot message handling from current chat and waits for any message.
///
/// See [conversation](/docs/conversation)
pub fn wait_message(
  ctx ctx: Context(session, error),
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), model.Message) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: HandleMessage(continue),
  )
}

/// Handles messages from inline keyboard callback.
///
/// See [conversation](/docs/conversation)
pub fn handle_callback_query(
  bot builder: TelegaBuilder(session, error),
  filter filter: CallbackQueryFilter,
  handler handler: fn(Context(session, error), String, String) ->
    Result(Context(session, error), error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, handlers: [
    HandleCallbackQuery(filter, handler),
    ..builder.handlers
  ])
}

/// Wait for a callback query and continue with the given function.
///
/// See [conversation](/docs/conversation)
pub fn wait_callback_query(
  ctx ctx: Context(session, error),
  filter filter: CallbackQueryFilter,
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), String, String) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: HandleCallbackQuery(filter, continue),
  )
}

/// Handles voice messages.
pub fn handle_voice(
  bot builder: TelegaBuilder(session, error),
  handler handler: fn(Context(session, error), model.Voice) ->
    Result(Context(session, error), error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, handlers: [HandleVoice(handler), ..builder.handlers])
}

/// Stops bot message handling from current chat and waits for a voice message.
///
/// See [conversation](/docs/conversation)
pub fn wait_voice(
  ctx ctx: Context(session, error),
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), model.Voice) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(ctx:, handler: HandleVoice(continue), handle_else:, timeout:)
}

/// Handles audio messages.
pub fn handle_audio(
  bot builder: TelegaBuilder(session, error),
  handler handler: fn(Context(session, error), model.Audio) ->
    Result(Context(session, error), error),
) {
  TelegaBuilder(..builder, handlers: [HandleAudio(handler), ..builder.handlers])
}

/// Stops bot message handling from current chat and waits for an audio message.
///
/// See [conversation](/docs/conversation)
pub fn wait_audio(
  ctx ctx: Context(session, error),
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), model.Audio) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(ctx:, handler: HandleAudio(continue), handle_else:, timeout:)
}

/// Handles video messages.
pub fn handle_video(
  bot builder: TelegaBuilder(session, error),
  handler handler: fn(Context(session, error), model.Video) ->
    Result(Context(session, error), error),
) {
  TelegaBuilder(..builder, handlers: [HandleVideo(handler), ..builder.handlers])
}

/// Stops bot message handling from current chat and waits for a video message.
///
/// See [conversation](/docs/conversation)
pub fn wait_video(
  ctx ctx: Context(session, error),
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), model.Video) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(ctx:, handler: HandleVideo(continue), handle_else:, timeout:)
}

/// Handles photo messages.
pub fn handle_photos(
  bot builder: TelegaBuilder(session, error),
  handler handler: fn(Context(session, error), List(model.PhotoSize)) ->
    Result(Context(session, error), error),
) {
  TelegaBuilder(..builder, handlers: [HandlePhotos(handler), ..builder.handlers])
}

/// Stops bot message handling from current chat and waits for a photo message.
///
/// See [conversation](/docs/conversation)
pub fn wait_photos(
  ctx ctx: Context(session, error),
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), List(model.PhotoSize)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: HandlePhotos(continue),
  )
}

/// Handles web app data messages.
pub fn handle_web_app_data(
  bot builder: TelegaBuilder(session, error),
  handler handler: fn(Context(session, error), model.WebAppData) ->
    Result(Context(session, error), error),
) {
  TelegaBuilder(..builder, handlers: [
    HandleWebAppData(handler),
    ..builder.handlers
  ])
}

/// Stops bot message handling from current chat and waits for a web app data message.
///
/// See [conversation](/docs/conversation)
pub fn wait_web_app_data(
  ctx ctx: Context(session, error),
  or handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), model.WebAppData) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: HandleWebAppData(continue),
  )
}

/// Set a catch handler for all handlers.
///
/// If handler returns `Error`, the chat instance will be stopped and the error will be logged
/// The default handler is `fn(_) -> Ok(Nil)`, which will do nothing if handler returns an error
pub fn with_catch_handler(
  builder builder: TelegaBuilder(session, error),
  catch_handler catch_handler: CatchHandler(session, error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, catch_handler: Some(catch_handler))
}

/// Handles chat member update (when user joins/leaves a group). The bot must be an administrator in the chat and must explicitly specify "chat_member" in the list of `allowed_updates` to receive these updates.
pub fn handle_chat_member(
  bot builder: TelegaBuilder(session, error),
  handler handler: fn(Context(session, error), model.ChatMemberUpdated) ->
    Result(Context(session, error), error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, handlers: [
    HandleChatMember(handler),
    ..builder.handlers
  ])
}

// TODO: figure out how to correct log continuation
/// Log the message and error message if the handler fails.
pub fn log_context(
  ctx ctx: Context(session, error),
  prefix prefix: String,
  handler handler: fn(Context(session, error)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let start_time = option.unwrap(ctx.start_time, timestamp.system_time())
  let log_prefix =
    option.lazy_unwrap(ctx.log_prefix, fn() {
      let id = utils.random_string(5)
      "[" <> prefix <> ": " <> id <> "] "
    })

  let ctx = Context(..ctx, start_time: Some(start_time))

  log.info(log_prefix <> "received update: " <> update.to_string(ctx.update))

  let result =
    handler(ctx)
    |> result.map_error(fn(e) {
      log.error(log_prefix <> "handler failed: " <> string.inspect(e))
      e
    })
  let end_time = timestamp.system_time()
  let time =
    start_time
    |> timestamp.difference(end_time)
    |> duration.to_seconds
    |> utils.seconds_to_milliseconds
    |> float.truncate
    |> int.to_string

  log.info(log_prefix <> "handler completed in " <> time <> "ms")

  result
}

/// Construct a session settings.
///
/// `get_session` should return `Ok(None)` if there is no session for the given key `default_session` will be used in this case. `Error` will crash chat actor.
pub fn with_session_settings(
  builder: TelegaBuilder(session, error),
  persist_session persist_session: fn(String, session) -> Result(session, error),
  get_session get_session: fn(String) -> Result(Option(session), error),
  default_session default_session: fn() -> session,
) -> TelegaBuilder(session, error) {
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
pub fn init_nil_session(
  builder: TelegaBuilder(Nil, error),
) -> Result(Telega(Nil, error), error.TelegaError) {
  let persist_session = fn(_, _) { Ok(Nil) }
  let get_session = fn(_) { Ok(Some(Nil)) }
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

/// Set the drop pending updates flag as set webhook parameter.
pub fn set_drop_pending_updates(
  builder: TelegaBuilder(session, error),
  drop_pending_updates: Bool,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, drop_pending_updates: Some(drop_pending_updates))
}

/// Set the max connections as set webhook parameter.
pub fn set_max_connections(
  builder: TelegaBuilder(session, error),
  max_connections: Int,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, max_connections: Some(max_connections))
}

/// Set the ip address as set webhook parameter.
pub fn set_ip_address(
  builder: TelegaBuilder(session, error),
  ip_address: String,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, ip_address: Some(ip_address))
}

/// Set the allowed updates as set webhook parameter.
pub fn set_allowed_updates(
  builder: TelegaBuilder(session, error),
  allowed_updates: List(String),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, allowed_updates: Some(allowed_updates))
}

/// Set the certificate as set webhook parameter.
pub fn set_certificate(
  builder: TelegaBuilder(session, error),
  certificate: model.File,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, certificate: Some(certificate))
}

/// Pass custom api client to the builder.
///
/// Useful if you want set custom fetch function or pass your api client options
pub fn set_api_client(
  builder: TelegaBuilder(session, error),
  api_client: TelegramClient,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, config: config.Config(..builder.config, api_client:))
}

/// Initialize a Telega instance.
/// This function should be called **only** after all handlers are added to the builder.
/// It will set the webhook and start handling messages.
pub fn init(
  builder: TelegaBuilder(session, error),
) -> Result(Telega(session, error), error.TelegaError) {
  use is_ok <- result.try(api.set_webhook(
    builder.config.api_client,
    model.SetWebhookParameters(
      url: builder.config.server_url <> "/" <> builder.config.webhook_path,
      secret_token: Some(builder.config.secret_token),
      drop_pending_updates: builder.drop_pending_updates,
      max_connections: builder.max_connections,
      ip_address: builder.ip_address,
      allowed_updates: builder.allowed_updates,
      certificate: builder.certificate,
    ),
  ))
  use <- bool.guard(!is_ok, Error(error.SetWebhookError))

  use bot_info <- result.try(api.get_me(builder.config.api_client))

  let session_settings =
    option.to_result(builder.session_settings, error.NoSessionSettingsError)

  use session_settings <- result.try(session_settings)
  use registry_subject <- result.try(registry.start())

  let catch_handler =
    option.lazy_unwrap(builder.catch_handler, fn() { nil_catch_handler })

  use bot_subject <- result.try(bot.start(
    bot_info:,
    catch_handler:,
    registry_subject:,
    session_settings:,
    config: builder.config,
    handlers: builder.handlers,
  ))

  Ok(Telega(bot_info:, bot_subject:, config: builder.config))
}

fn nil_catch_handler(_, _) {
  Ok(Nil)
}

/// Handle an update from the Telegram API.
pub fn handle_update(telega: Telega(session, error), raw_update: Update) -> Bool {
  update.raw_to_update(raw_update)
  |> bot.handle_update(telega.bot_subject, _)
}
