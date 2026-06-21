import gleam/bool
import gleam/erlang/atom
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/static_supervisor as sup
import gleam/otp/supervision
import gleam/regexp
import gleam/result
import gleam/string

import telega/internal/config.{type Config}
import telega/internal/log
import telega/internal/registry
import telega/internal/signal
import telega/internal/utils

import telega/api
import telega/bot.{type BotSubject, type Context, type SessionSettings}
import telega/client
import telega/error
import telega/model/types.{type File, type Update, type User}
import telega/polling
import telega/router.{type Router}
import telega/telemetry
import telega/update

pub opaque type Telega(session, error) {
  Telega(
    config: Config,
    bot_info: User,
    bot_subject: BotSubject,
    supervisor_pid: process.Pid,
    /// Polling worker subject, present only in polling mode. Used by graceful
    /// shutdown to stop fetching updates before draining.
    poller: Option(process.Subject(polling.PollingMessage)),
    /// Max time (ms) `shutdown` waits for in-flight updates to drain.
    drain_timeout: Int,
    /// Hook run during `shutdown`, after draining and before stopping children.
    on_shutdown: Option(fn() -> Nil),
  )
}

pub opaque type TelegaBuilder(session, error) {
  TelegaBuilder(
    config: Config,
    router: Option(Router(session, error)),
    session_settings: Option(SessionSettings(session, error)),
    catch_handler: Option(bot.CatchHandler(session, error)),
    bot_subject: Option(BotSubject),
    api_client: Option(client.TelegramClient),
    // --- SetWebhook parameters ---
    drop_pending_updates: Option(Bool),
    max_connections: Option(Int),
    ip_address: Option(String),
    allowed_updates: Option(List(String)),
    certificate: Option(File),
    // --- Polling parameters ---
    polling_timeout: Option(Int),
    polling_limit: Option(Int),
    polling_interval: Option(Int),
    polling_on_stop: Option(fn(error.TelegaError) -> Nil),
    // --- Chat instance factory parameters ---
    chat_restart_tolerance_intensity: Option(Int),
    chat_restart_tolerance_period: Option(Int),
    chat_init_timeout: Option(Int),
    // --- Lifecycle parameters ---
    on_start: Option(
      fn(Telega(session, error)) -> Result(Nil, error.TelegaError),
    ),
    on_shutdown: Option(fn() -> Nil),
    drain_timeout: Option(Int),
    handle_signals: Bool,
    // --- Command/route auto-synchronization ---
    /// When `True`, publish the router's described commands via `setMyCommands`
    /// on start. Enabled by `with_auto_commands`/`with_command_translations`.
    auto_commands: Bool,
    /// Language codes to publish localized command descriptions for.
    command_locales: List(String),
    /// Localizer: `(command, language_code) -> Option(description)`. `None`
    /// for a given pair falls back to the router's default description.
    command_translate: Option(fn(String, String) -> Option(String)),
    /// When `True` and `allowed_updates` was not set manually, derive the
    /// requested update types from the router's registered routes.
    auto_allowed_updates: Bool,
  )
}

/// Internal function to get bot subject for polling
@internal
pub fn get_bot_subject_internal(telega: Telega(session, error)) -> BotSubject {
  telega.bot_subject
}

/// Internal function to get client for polling
@internal
pub fn get_client_internal(
  telega: Telega(session, error),
) -> client.TelegramClient {
  telega.config.api_client
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
///
/// Requires an `api_client` created by an adapter package like `telega_httpc` or `telega_hackney`.
pub fn new(
  api_client api_client: client.TelegramClient,
  url server_url: String,
  webhook_path webhook_path: String,
  secret_token secret_token: Option(String),
) {
  let url = utils.normalize_url(server_url)
  let webhook_path = utils.normalize_webhook_path(webhook_path)

  TelegaBuilder(
    router: None,
    config: config.new(api_client:, webhook_path:, secret_token:, url:),
    session_settings: None,
    catch_handler: None,
    bot_subject: None,
    api_client: None,
    drop_pending_updates: None,
    max_connections: None,
    ip_address: None,
    allowed_updates: None,
    certificate: None,
    polling_timeout: None,
    polling_limit: None,
    polling_interval: None,
    polling_on_stop: None,
    chat_restart_tolerance_intensity: None,
    chat_restart_tolerance_period: None,
    chat_init_timeout: None,
    on_start: None,
    on_shutdown: None,
    drain_timeout: None,
    handle_signals: False,
    auto_commands: False,
    command_locales: [],
    command_translate: None,
    auto_allowed_updates: False,
  )
}

/// Create a new Telega instance optimized for long polling.
///
/// Requires an `api_client` created by an adapter package like `telega_httpc` or `telega_hackney`.
/// This is a convenience function for polling bots that don't need webhook configuration.
pub fn new_for_polling(api_client api_client: client.TelegramClient) {
  TelegaBuilder(
    router: None,
    config: config.new(
      api_client:,
      webhook_path: "/webhook",
      secret_token: None,
      url: "https://api.telegram.org",
    ),
    session_settings: None,
    catch_handler: None,
    bot_subject: None,
    api_client: None,
    drop_pending_updates: None,
    max_connections: None,
    ip_address: None,
    allowed_updates: None,
    certificate: None,
    polling_timeout: None,
    polling_limit: None,
    polling_interval: None,
    polling_on_stop: None,
    chat_restart_tolerance_intensity: None,
    chat_restart_tolerance_period: None,
    chat_init_timeout: None,
    on_start: None,
    on_shutdown: None,
    drain_timeout: None,
    handle_signals: False,
    auto_commands: False,
    command_locales: [],
    command_translate: None,
    auto_allowed_updates: False,
  )
}

/// Set the router for handling updates.
/// This is the primary way to handle updates - use router.new() to create a router
/// and configure it with command handlers, text handlers, middleware, etc.
pub fn with_router(
  builder: TelegaBuilder(session, error),
  router: Router(session, error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, router: Some(router))
}

/// Set session settings for the bot.
pub fn with_session_settings(
  builder: TelegaBuilder(session, error),
  session_settings: SessionSettings(session, error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, session_settings: Some(session_settings))
}

/// Set catch handler for system errors (like session persistence failures) and [conversation](/docs/conversation) errors.
/// This is different from router's catch handler which handles route errors.
pub fn with_catch_handler(
  builder: TelegaBuilder(session, error),
  catch_handler: bot.CatchHandler(session, error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, catch_handler: Some(catch_handler))
}

/// Set whether to drop pending updates.
pub fn set_drop_pending_updates(
  builder: TelegaBuilder(session, error),
  drop: Bool,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, drop_pending_updates: Some(drop))
}

/// Set max connections for webhook.
pub fn set_max_connections(
  builder: TelegaBuilder(session, error),
  max: Int,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, max_connections: Some(max))
}

/// Set IP address for webhook.
pub fn set_ip_address(
  builder: TelegaBuilder(session, error),
  ip: String,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, ip_address: Some(ip))
}

/// Set allowed updates for webhook.
pub fn set_allowed_updates(
  builder: TelegaBuilder(session, error),
  updates: List(String),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, allowed_updates: Some(updates))
}

/// Set certificate for webhook.
pub fn set_certificate(
  builder: TelegaBuilder(session, error),
  cert: File,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, certificate: Some(cert))
}

/// Set a custom API client.
pub fn set_api_client(
  builder: TelegaBuilder(session, error),
  client: client.TelegramClient,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, api_client: Some(client))
}

/// Set polling configuration for the supervised polling worker.
pub fn with_polling_config(
  builder: TelegaBuilder(session, error),
  timeout timeout: Int,
  limit limit: Int,
  poll_interval poll_interval: Int,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(
    ..builder,
    polling_timeout: Some(timeout),
    polling_limit: Some(limit),
    polling_interval: Some(poll_interval),
  )
}

/// Set a callback for when polling stops due to errors.
pub fn with_polling_on_stop(
  builder: TelegaBuilder(session, error),
  on_stop on_stop: fn(error.TelegaError) -> Nil,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, polling_on_stop: Some(on_stop))
}

/// Configure the chat instance factory supervisor.
///
/// - `restart_tolerance_intensity` — max restarts within the period (default: 5)
/// - `restart_tolerance_period` — period in seconds (default: 10)
/// - `init_timeout` — chat instance init timeout in ms (default: 10 000)
pub fn with_chat_config(
  builder: TelegaBuilder(session, error),
  restart_tolerance_intensity intensity: Int,
  restart_tolerance_period period: Int,
  init_timeout timeout: Int,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(
    ..builder,
    chat_restart_tolerance_intensity: Some(intensity),
    chat_restart_tolerance_period: Some(period),
    chat_init_timeout: Some(timeout),
  )
}

/// Set a hook to run once the bot has fully started.
///
/// Runs after the supervision tree is up and the `Telega` instance is built, so
/// you can use it for warming caches, registering commands via the API, etc.
/// Returning `Error` aborts startup and tears the supervision tree back down.
///
/// ```gleam
/// telega.new_for_polling(api_client:)
/// |> telega.with_router(router)
/// |> telega.with_on_start(fn(bot) {
///   // register commands, warm caches...
///   Ok(Nil)
/// })
/// |> telega.init_for_polling()
/// ```
pub fn with_on_start(
  builder: TelegaBuilder(session, error),
  on_start on_start: fn(Telega(session, error)) ->
    Result(Nil, error.TelegaError),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, on_start: Some(on_start))
}

/// Set a hook to run during `shutdown`, after in-flight updates have drained
/// and before the supervision tree is stopped. Use it to release resources
/// (close pools, flush buffers, deregister from a service discovery, …).
pub fn with_on_shutdown(
  builder: TelegaBuilder(session, error),
  on_shutdown on_shutdown: fn() -> Nil,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, on_shutdown: Some(on_shutdown))
}

/// Set the maximum time (in milliseconds) `shutdown` waits for in-flight
/// updates to finish before forcibly stopping the supervision tree.
///
/// Defaults to 5000ms.
pub fn with_drain_timeout(
  builder: TelegaBuilder(session, error),
  timeout timeout: Int,
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, drain_timeout: Some(timeout))
}

/// Install an OS signal handler (SIGTERM) that runs a graceful `shutdown` and
/// then halts the VM.
///
/// This makes the bot survive rolling deploys on platforms like fly.io or
/// Kubernetes: on SIGTERM the bot stops accepting new updates, drains in-flight
/// work (bounded by `with_drain_timeout`), runs the `on_shutdown` hook, and
/// stops cleanly. The handler replaces the runtime's default signal behavior.
///
/// Only SIGTERM is handled — BEAM reserves SIGINT for its interactive break
/// handler, so it cannot be intercepted this way.
pub fn with_signal_handlers(
  builder: TelegaBuilder(session, error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, handle_signals: True)
}

/// Publish the router's commands to Telegram on start.
///
/// Every command registered with `router.on_command_with_description` is sent
/// via `setMyCommands` once the bot is up, so the Telegram client shows them in
/// the command menu without a manual call. Commands added with plain
/// `router.on_command` (no description) are not published.
///
/// For localized descriptions use `with_command_translations` instead — it
/// turns this on as well.
///
/// ```gleam
/// telega.new_for_polling(api_client:)
/// |> telega.with_router(router)
/// |> telega.with_auto_commands()
/// |> telega.init_for_polling()
/// ```
pub fn with_auto_commands(
  builder: TelegaBuilder(session, error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, auto_commands: True)
}

/// Publish localized command descriptions on start.
///
/// Implies `with_auto_commands`: the default-language commands are published
/// first, then for every locale in `locales` a `setMyCommands(language_code:)`
/// call is made. `translate(command, locale)` supplies the per-language text;
/// returning `None` keeps the router's default description for that command.
///
/// `telega_i18n` provides a convenience wrapper that builds `translate` from a
/// translation catalog, so you usually call this through it.
///
/// ```gleam
/// telega.new_for_polling(api_client:)
/// |> telega.with_router(router)
/// |> telega.with_command_translations(
///   locales: ["en", "ru"],
///   translate: fn(command, locale) { lookup_description(command, locale) },
/// )
/// |> telega.init_for_polling()
/// ```
pub fn with_command_translations(
  builder: TelegaBuilder(session, error),
  locales locales: List(String),
  translate translate: fn(String, String) -> Option(String),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(
    ..builder,
    auto_commands: True,
    command_locales: locales,
    command_translate: Some(translate),
  )
}

/// Derive `allowed_updates` from the router's registered routes.
///
/// Telegram then sends only the update types the bot actually handles, cutting
/// out traffic for routes you never registered. A manual `set_allowed_updates`
/// always wins (the escape hatch). If the router has a fallback, custom, or
/// filtered route — which can match anything — derivation can't narrow safely
/// and falls back to Telegram's default update set.
pub fn with_auto_allowed_updates(
  builder: TelegaBuilder(session, error),
) -> TelegaBuilder(session, error) {
  TelegaBuilder(..builder, auto_allowed_updates: True)
}

/// Set nil session for the bot.
pub fn with_nil_session(
  builder: TelegaBuilder(Nil, error),
) -> TelegaBuilder(Nil, error) {
  builder
  |> with_session_settings(
    bot.SessionSettings(
      persist_session: fn(_key, _session) { Ok(Nil) },
      get_session: fn(_key) { Ok(None) },
      default_session: fn() { Nil },
    ),
  )
}

/// Initialize the bot for long polling with nil session.
pub fn init_for_polling_nil_session(
  builder: TelegaBuilder(Nil, error),
) -> Result(Telega(Nil, error), error.TelegaError) {
  builder
  |> with_session_settings(
    bot.SessionSettings(
      persist_session: fn(_key, _session) { Ok(Nil) },
      get_session: fn(_key) { Ok(None) },
      default_session: fn() { Nil },
    ),
  )
  |> init_for_polling()
}

/// Initialize the bot for webhook mode with a supervision tree.
pub fn init(
  builder: TelegaBuilder(session, error),
) -> Result(Telega(session, error), error.TelegaError) {
  let api_client = option.unwrap(builder.api_client, builder.config.api_client)

  use is_ok <- result.try(api.set_webhook(
    api_client,
    types.SetWebhookParameters(
      url: builder.config.server_url <> "/" <> builder.config.webhook_path,
      secret_token: Some(builder.config.secret_token),
      drop_pending_updates: builder.drop_pending_updates,
      max_connections: builder.max_connections,
      ip_address: builder.ip_address,
      allowed_updates: resolve_allowed_updates(builder),
      certificate: builder.certificate,
    ),
  ))
  use <- bool.guard(!is_ok, Error(error.SetWebhookError))

  use bot_info <- result.try(api.get_me(api_client))

  let session_settings =
    option.to_result(builder.session_settings, error.NoSessionSettingsError)

  use session_settings <- result.try(session_settings)

  let router =
    option.to_result(
      builder.router,
      error.RouterError(
        "Router is required. Use with_router() to set a router.",
      ),
    )
  use router <- result.try(router)

  let router_handler = fn(ctx, upd) { router.handle(router, ctx, upd) }
  let catch_handler =
    option.unwrap(builder.catch_handler, fn(_ctx, err) { Error(err) })
  let config = config.Config(..builder.config, api_client:)

  let registry_name =
    generate_registry_name(client.get_token(config.api_client))
  use registry <- result.try(registry.start(registry_name))

  // Build supervision tree: factory → bot (no polling for webhook mode)
  let #(chat_factory_spec, chat_factory_name) = build_chat_factory_spec(builder)
  let bot_name = process.new_name("telega_bot")
  let bot_subject = process.named_subject(bot_name)
  let chat_factory_ref = fsup.get_by_name(chat_factory_name)

  let bot_spec =
    supervision.worker(fn() {
      bot.start(
        registry:,
        config:,
        bot_info:,
        router_handler:,
        session_settings:,
        catch_handler:,
        chat_factory: chat_factory_ref,
        name: Some(bot_name),
      )
    })
    |> supervision.restart(supervision.Permanent)

  use sup_started <- result.try(
    sup.new(sup.OneForOne)
    |> sup.add(chat_factory_spec)
    |> sup.add(bot_spec)
    |> sup.start
    |> result.map_error(error.SupervisorStartError),
  )

  finalize(
    builder:,
    config:,
    bot_info:,
    bot_subject:,
    supervisor_pid: sup_started.pid,
    poller: None,
  )
}

/// Initialize the bot for long polling with a supervision tree.
/// Includes a supervised polling worker that auto-starts.
pub fn init_for_polling(
  builder: TelegaBuilder(session, error),
) -> Result(Telega(session, error), error.TelegaError) {
  let api_client = option.unwrap(builder.api_client, builder.config.api_client)

  use bot_info <- result.try(
    api.get_me(api_client)
    |> result.map_error(fn(err) {
      case err {
        error.TelegramApiError(404, _desc) ->
          error.TelegramApiError(
            404,
            "Bot not found. Please check that your BOT_TOKEN is valid and the bot exists. Get a valid token from @BotFather on Telegram.",
          )
        error.TelegramApiError(401, _desc) ->
          error.TelegramApiError(
            401,
            "Unauthorized. Your bot token is invalid. Please get a valid token from @BotFather on Telegram.",
          )
        _ -> err
      }
    }),
  )

  let session_settings =
    option.to_result(builder.session_settings, error.NoSessionSettingsError)

  use session_settings <- result.try(session_settings)

  let router =
    option.to_result(
      builder.router,
      error.ActorError("Router is required. Use with_router() to set a router."),
    )
  use router <- result.try(router)

  let router_handler = fn(ctx, upd) { router.handle(router, ctx, upd) }
  let catch_handler =
    option.unwrap(builder.catch_handler, fn(_ctx, err) { Error(err) })
  let config = config.Config(..builder.config, api_client:)

  // Create registry with unique name
  let registry_name =
    generate_registry_name(client.get_token(config.api_client))
  use registry <- result.try(registry.start(registry_name))

  // Build supervision tree: factory → bot → polling
  let #(chat_factory_spec, chat_factory_name) = build_chat_factory_spec(builder)
  let bot_name = process.new_name("telega_bot")
  let bot_subject = process.named_subject(bot_name)
  let chat_factory_ref = fsup.get_by_name(chat_factory_name)

  let bot_spec =
    supervision.worker(fn() {
      bot.start(
        registry:,
        config:,
        bot_info:,
        router_handler:,
        session_settings:,
        catch_handler:,
        chat_factory: chat_factory_ref,
        name: Some(bot_name),
      )
    })
    |> supervision.restart(supervision.Permanent)

  let polling_timeout = option.unwrap(builder.polling_timeout, 30)
  let polling_limit = option.unwrap(builder.polling_limit, 100)
  let polling_interval = option.unwrap(builder.polling_interval, 1000)
  let allowed_updates = option.unwrap(resolve_allowed_updates(builder), [])

  let poller_name = process.new_name("telega_poller")
  let poller = process.named_subject(poller_name)

  let polling_spec =
    polling.supervised(
      client: api_client,
      bot: bot_subject,
      timeout: polling_timeout,
      limit: polling_limit,
      allowed_updates:,
      poll_interval: polling_interval,
      on_stop: builder.polling_on_stop,
      name: poller_name,
    )

  use sup_started <- result.try(
    sup.new(sup.OneForOne)
    |> sup.add(chat_factory_spec)
    |> sup.add(bot_spec)
    |> sup.add(polling_spec)
    |> sup.start
    |> result.map_error(error.SupervisorStartError),
  )

  finalize(
    builder:,
    config:,
    bot_info:,
    bot_subject:,
    supervisor_pid: sup_started.pid,
    poller: Some(poller),
  )
}

/// Handle an update.
///
/// This function is useful when you want to handle updates in your own way.
pub fn handle_update(
  telega: Telega(session, error),
  raw_update: Update,
) -> Bool {
  let update = update.raw_to_update(raw_update)
  bot.handle_update(telega.bot_subject, update)
}

/// Get the bot's information.
pub fn get_me(telega: Telega(session, error)) -> User {
  telega.bot_info
}

/// Get session for the current context.
pub fn get_session(ctx: Context(session, error)) -> session {
  ctx.session
}

/// Add logging context to the current context.
pub fn log_context(
  ctx: Context(session, error),
  prefix: String,
  fun: fn(Context(session, error)) -> Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let ctx_with_log = bot.Context(..ctx, log_prefix: Some(prefix))
  fun(ctx_with_log)
}

/// Context helpers for logging
pub fn log_info(ctx: Context(session, error), message: String) {
  case ctx.log_prefix {
    Some(prefix) -> log.info_d(prefix, message)
    None -> log.info(message)
  }
}

pub fn log_error(ctx: Context(session, error), message: String) {
  case ctx.log_prefix {
    Some(prefix) -> log.error_d(prefix, message)
    None -> log.error(message)
  }
}

/// Pauses the current chat actor's handler and waits for any update.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_any(
  ctx ctx: Context(session, error),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue handler: fn(Context(session, error), update.Update) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    handler: bot.HandleAll(handler:),
    handle_else:,
    timeout:,
  )
}

/// Pauses the current chat actor's handler and waits for a specific command.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_command(
  ctx ctx: Context(session, error),
  command command: String,
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), update.Command) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: bot.HandleCommand(command, continue),
  )
}

/// Pauses the current chat actor's handler and waits for one of the specified commands.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_commands(
  ctx ctx: Context(session, error),
  commands commands: List(String),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), update.Command) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: bot.HandleCommands(commands, continue),
  )
}

/// Pauses the current chat actor's handler and waits for a text message.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_text(
  ctx ctx: Context(session, error),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), String) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    handler: bot.HandleText(continue),
    handle_else:,
    timeout:,
  )
}

/// Pauses the current chat actor's handler and waits for a message that matches the given `Hears`.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_hears(
  ctx ctx: Context(session, error),
  hears hears: bot.Hears,
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), String) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: bot.HandleHears(hears, continue),
  )
}

/// Pauses the current chat actor's handler and waits for any message.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_message(
  ctx ctx: Context(session, error),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), types.Message) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: bot.HandleMessage(continue),
  )
}

/// Pauses the current chat actor's handler and waits for a callback query.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_callback_query(
  ctx ctx: Context(session, error),
  filter filter: Option(bot.CallbackQueryFilter),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), String, String) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let assert Ok(default_re) = regexp.from_string(".*")
  let filter_value =
    option.unwrap(filter, bot.CallbackQueryFilter(re: default_re))
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: bot.HandleCallbackQuery(filter: filter_value, handler: continue),
  )
}

/// Pauses the current chat actor's handler and waits for an audio message.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_audio(
  ctx ctx: Context(session, error),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), types.Audio) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: bot.HandleAudio(continue),
  )
}

/// Pauses the current chat actor's handler and waits for a video message.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_video(
  ctx ctx: Context(session, error),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), types.Video) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: bot.HandleVideo(continue),
  )
}

/// Pauses the current chat actor's handler and waits for a voice message.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_voice(
  ctx ctx: Context(session, error),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), types.Voice) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: bot.HandleVoice(continue),
  )
}

/// Pauses the current chat actor's handler and waits for photos.
/// Other chats and users continue to be handled concurrently.
///
/// See [conversation](/docs/conversation)
pub fn wait_photos(
  ctx ctx: Context(session, error),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), List(types.PhotoSize)) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: bot.HandlePhotos(continue),
  )
}

/// Wait for a number with validation.
///
/// This function waits for user to send text that can be parsed as an integer,
/// with optional min/max validation.
///
/// If validation fails and `or` handler is provided, it will be called.
/// Otherwise, the function will keep waiting for valid input.
///
/// ## Examples
///
/// ```gleam
/// use ctx, age <- wait_number(
///   ctx,
///   min: Some(0),
///   max: Some(120),
///   or: Some(bot.HandleText(fn(ctx, invalid) {
///     reply.with_text(ctx, "Please enter age between 0 and 120")
///   })),
///   timeout: None,
/// )
/// ```
///
/// See [conversation](/docs/conversation)
pub fn wait_number(
  ctx ctx: Context(session, error),
  min min: Option(Int),
  max max: Option(Int),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), Int) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let validation_handler =
    bot.HandleText(fn(ctx, text) {
      case int.parse(text) {
        Ok(number) -> {
          // Validate min
          let min_ok = case min {
            Some(min_val) -> number >= min_val
            None -> True
          }

          // Validate max
          let max_ok = case max {
            Some(max_val) -> number <= max_val
            None -> True
          }

          case min_ok && max_ok {
            True -> continue(ctx, number)
            False ->
              wait_number(ctx, min:, max:, or: handle_else, timeout:, continue:)
          }
        }
        Error(_) ->
          wait_number(ctx, min:, max:, or: handle_else, timeout:, continue:)
      }
    })

  bot.wait_handler(ctx:, timeout:, handle_else:, handler: validation_handler)
}

/// Wait for email with validation.
///
/// This function waits for user to send text that matches email pattern.
///
/// If validation fails and `or` handler is provided, it will be called.
/// Otherwise, the function will keep waiting for valid input.
///
/// ## Examples
///
/// ```gleam
/// use ctx, email <- wait_email(
///   ctx,
///   or: Some(bot.HandleText(fn(ctx, invalid) {
///     reply.with_text(ctx, "Invalid email format. Try again.")
///   })),
///   timeout: None,
/// )
/// ```
///
/// See [conversation](/docs/conversation)
pub fn wait_email(
  ctx ctx: Context(session, error),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), String) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let email_pattern = "^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$"

  let validation_handler =
    bot.HandleText(fn(ctx, text) {
      case regexp.from_string(email_pattern) {
        Ok(re) ->
          case regexp.check(re, text) {
            True -> continue(ctx, text)
            False -> wait_email(ctx, or: handle_else, timeout:, continue:)
          }
        Error(_) -> continue(ctx, text)
      }
    })

  bot.wait_handler(ctx:, timeout:, handle_else:, handler: validation_handler)
}

/// Wait for user choice from inline keyboard.
///
/// This function creates an inline keyboard with provided options
/// and waits for user to select one.
///
/// ## Examples
///
/// ```gleam
/// use ctx, color <- wait_choice(
///   ctx,
///   [
///     #("🔴 Red", Red),
///     #("🔵 Blue", Blue),
///     #("🟢 Green", Green),
///   ],
///   or: None,
///   timeout: None,
/// )
/// ```
///
/// See [conversation](/docs/conversation)
pub fn wait_choice(
  ctx ctx: Context(session, error),
  options options: List(#(String, a)),
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), a) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  // Create inline keyboard buttons from options
  let buttons =
    options
    |> list.index_map(fn(opt, idx) {
      let #(label, _value) = opt
      let callback_data = int.to_string(idx)
      types.InlineKeyboardButton(
        text: label,
        icon_custom_emoji_id: None,
        style: None,
        url: None,
        callback_data: Some(callback_data),
        web_app: None,
        login_url: None,
        switch_inline_query: None,
        switch_inline_query_current_chat: None,
        switch_inline_query_chosen_chat: None,
        callback_game: None,
        pay: None,
        copy_text: None,
      )
    })

  let keyboard = types.InlineKeyboardMarkup(inline_keyboard: [buttons])

  // Send message with keyboard
  let send_params =
    types.SendMessageParameters(
      business_connection_id: None,
      chat_id: types.Int(ctx.update.chat_id),
      message_thread_id: None,
      text: "",
      parse_mode: None,
      entities: None,
      link_preview_options: None,
      disable_notification: None,
      protect_content: None,
      allow_paid_broadcast: None,
      message_effect_id: None,
      reply_parameters: None,
      reply_markup: Some(types.SendMessageReplyInlineKeyboardMarkupParameters(
        keyboard,
      )),
    )

  let _ = api.send_message(ctx.config.api_client, send_params)

  // Wait for callback query
  use ctx, data, _callback_query_id <- wait_callback_query(
    ctx,
    filter: None,
    or: handle_else,
    timeout:,
  )

  // Parse index and get value
  case int.parse(data) {
    Ok(idx) ->
      case list_at(options, idx) {
        Ok(#(_label, value)) -> continue(ctx, value)
        Error(_) ->
          wait_choice(ctx, options:, or: handle_else, timeout:, continue:)
      }
    Error(_) -> wait_choice(ctx, options:, or: handle_else, timeout:, continue:)
  }
}

/// Wait for update matching custom filter.
///
/// This function waits for any update that passes the provided filter function.
///
/// ## Examples
///
/// ```gleam
/// use ctx, photo_update <- wait_for(
///   ctx,
///   filter: fn(upd) {
///     case upd {
///       update.PhotoUpdate(..) -> True
///       _ -> False
///     }
///   },
///   or: Some(bot.HandleAll(fn(ctx, wrong_update) {
///     reply.with_text(ctx, "Please send a photo")
///   })),
///   timeout: Some(60_000),
/// )
/// ```
///
/// See [conversation](/docs/conversation)
pub fn wait_for(
  ctx ctx: Context(session, error),
  filter filter: fn(update.Update) -> Bool,
  or handle_else: Option(bot.Handler(session, error)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error), update.Update) ->
    Result(Context(session, error), error),
) -> Result(Context(session, error), error) {
  let filter_handler =
    bot.HandleAll(fn(ctx, upd) {
      case filter(upd) {
        True -> continue(ctx, upd)
        False -> wait_for(ctx, filter:, or: handle_else, timeout:, continue:)
      }
    })

  bot.wait_handler(ctx:, timeout:, handle_else:, handler: filter_handler)
}

/// Start polling with default configuration for a Telega instance.
/// This is useful when you want to manually start polling outside the supervision tree.
pub fn start_polling_default(
  telega: Telega(session, error),
) -> Result(polling.Poller, error.TelegaError) {
  polling.start_polling_default(
    client: telega.config.api_client,
    bot: telega.bot_subject,
  )
}

/// Graceful shutdown with in-flight draining.
///
/// 1. Emits `[telega, shutdown, start]`.
/// 2. Stops intake — for polling, tells the worker to stop fetching updates
///    (Telegram re-delivers unconfirmed updates on the next start); for webhook,
///    the bot starts rejecting updates and `is_draining` reports `True` so
///    adapters can answer `503`.
/// 3. Waits up to `drain_timeout` for in-flight updates to finish.
/// 4. Runs the `on_shutdown` hook.
/// 5. Emits `[telega, shutdown, stop]` with the number of drained updates.
/// 6. Stops the supervisor, cascading to all children (polling → bot →
///    chat_factory).
pub fn shutdown(telega: Telega(session, error)) -> Nil {
  let started_at = telemetry.monotonic_time()
  telemetry.execute(
    ["telega", "shutdown", "start"],
    [#("system_time", telemetry.system_time())],
    [],
  )

  // Stop intake before draining so no new updates are accepted mid-drain.
  case telega.poller {
    Some(poller) -> polling.stop_worker(poller)
    None -> Nil
  }

  let drained = bot.drain(telega.bot_subject, telega.drain_timeout)

  case telega.on_shutdown {
    Some(on_shutdown) -> on_shutdown()
    None -> Nil
  }

  let duration = telemetry.monotonic_time() - started_at
  telemetry.execute(
    ["telega", "shutdown", "stop"],
    [#("duration", duration), #("drained", int.max(0, drained))],
    [#("timed_out", telemetry.BoolValue(drained < 0))],
  )

  process.send_abnormal_exit(telega.supervisor_pid, atom.create("shutdown"))
}

/// Whether the bot is currently draining and no longer accepting updates.
///
/// Webhook adapters should answer `503` when this is `True` so Telegram retries
/// the update after the deploy instead of it being dropped.
pub fn is_draining(telega: Telega(session, error)) -> Bool {
  bot.is_draining(telega.bot_subject)
}

/// Get the supervisor PID for the running bot instance.
pub fn get_supervisor_pid(telega: Telega(session, error)) -> process.Pid {
  telega.supervisor_pid
}

const default_drain_timeout = 5000

/// Build the `Telega` value, run the `on_start` hook, and install signal
/// handlers if requested. Shared by `init` and `init_for_polling`.
fn finalize(
  builder builder: TelegaBuilder(session, error),
  config config: Config,
  bot_info bot_info: User,
  bot_subject bot_subject: BotSubject,
  supervisor_pid supervisor_pid: process.Pid,
  poller poller: Option(process.Subject(polling.PollingMessage)),
) -> Result(Telega(session, error), error.TelegaError) {
  let telega =
    Telega(
      config:,
      bot_info:,
      bot_subject:,
      supervisor_pid:,
      poller:,
      drain_timeout: option.unwrap(builder.drain_timeout, default_drain_timeout),
      on_shutdown: builder.on_shutdown,
    )

  // Auto-publish commands first, then run the user hook. Either failing tears
  // the just-started tree back down before surfacing the error.
  let run_startup = fn() {
    use _ <- result.try(maybe_sync_commands(builder, config))
    case builder.on_start {
      Some(on_start) -> on_start(telega)
      None -> Ok(Nil)
    }
  }

  use _ <- result.try(case run_startup() {
    Ok(_) -> Ok(Nil)
    Error(e) -> {
      process.send_abnormal_exit(supervisor_pid, atom.create("shutdown"))
      Error(e)
    }
  })

  case builder.handle_signals {
    True -> install_signal_handlers(telega)
    False -> Nil
  }

  Ok(telega)
}

/// Resolve the effective `allowed_updates`. A manual value (via
/// `set_allowed_updates`) always wins; otherwise, when `with_auto_allowed_updates`
/// is enabled, derive the set from the router. `None` means "do not restrict".
fn resolve_allowed_updates(
  builder: TelegaBuilder(session, error),
) -> Option(List(String)) {
  case builder.allowed_updates {
    Some(_) as manual -> manual
    None ->
      case builder.auto_allowed_updates, builder.router {
        True, Some(router) ->
          case router.allowed_updates(router) {
            [] -> None
            updates -> Some(updates)
          }
        _, _ -> None
      }
  }
}

/// Publish the router's described commands via `setMyCommands` when
/// `auto_commands` is enabled: a default-language call first, then one
/// `setMyCommands(language_code:)` per configured locale.
fn maybe_sync_commands(
  builder: TelegaBuilder(session, error),
  config: Config,
) -> Result(Nil, error.TelegaError) {
  use <- bool.guard(!builder.auto_commands, Ok(Nil))

  case builder.router {
    None -> Ok(Nil)
    Some(router) -> {
      let described = router.registered_commands(router)
      use <- bool.guard(described == [], Ok(Nil))

      let client = config.api_client
      let base_commands =
        list.map(described, fn(pair) {
          types.BotCommand(command: pair.0, description: pair.1)
        })

      use _ <- result.try(api.set_my_commands(
        client:,
        commands: base_commands,
        parameters: None,
      ))

      case builder.command_translate {
        None -> Ok(Nil)
        Some(translate) ->
          list.try_each(builder.command_locales, fn(locale) {
            let localized =
              list.map(described, fn(pair) {
                let description =
                  translate(pair.0, locale) |> option.unwrap(pair.1)
                types.BotCommand(command: pair.0, description:)
              })

            api.set_my_commands(
              client:,
              commands: localized,
              parameters: Some(types.BotCommandParameters(
                scope: None,
                language_code: Some(locale),
              )),
            )
            |> result.map(fn(_) { Nil })
          })
      }
    }
  }
}

fn install_signal_handlers(telega: Telega(session, error)) -> Nil {
  signal.install(fn(_signal) {
    shutdown(telega)
    halt(0)
  })
}

@external(erlang, "erlang", "halt")
fn halt(code: Int) -> Nil

// Default chat instance factory settings
const default_chat_restart_intensity = 5

const default_chat_restart_period = 10

const default_chat_init_timeout = 10_000

// Build the chat factory child spec from builder settings
fn build_chat_factory_spec(builder: TelegaBuilder(session, error)) {
  let intensity =
    option.unwrap(
      builder.chat_restart_tolerance_intensity,
      default_chat_restart_intensity,
    )
  let period =
    option.unwrap(
      builder.chat_restart_tolerance_period,
      default_chat_restart_period,
    )
  let timeout =
    option.unwrap(builder.chat_init_timeout, default_chat_init_timeout)

  let name = process.new_name("telega_chat_factory")

  let spec =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.named(name)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.restart_tolerance(intensity, period)
    |> fsup.timeout(timeout)
    |> fsup.supervised

  #(spec, name)
}

// Generate a unique registry name from the bot token
fn generate_registry_name(token: String) -> String {
  token
  |> string.slice(0, 8)
  |> string.append("_" <> int.to_string(int.random(1_000_000)))
}

// Helper to get list element at index
fn list_at(list: List(a), index: Int) -> Result(a, Nil) {
  case list, index {
    [], _ -> Error(Nil)
    [head, ..], 0 -> Ok(head)
    [_, ..tail], n -> list_at(tail, n - 1)
  }
}
