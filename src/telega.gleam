import gleam/bool
import gleam/dict
import gleam/erlang/atom
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
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
import telega/router.{type Routable, type Router, type RouterTree}
import telega/scope
import telega/telemetry
import telega/update
import telega/webhook_reply

pub opaque type Telega(session, error, dependencies) {
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
    /// Kept so `background_context` can load a session and inject the same
    /// services a handler would see.
    session_settings: SessionSettings(session, error),
    /// Kept so `background_context` keys a session exactly as an update would.
    session_key: fn(update.Update) -> String,
    /// Kept so `background_context` treats an unreadable session the same way
    /// a chat instance start does.
    session_load_error: bot.SessionLoadError,
    dependencies: dependencies,
  )
}

/// Builder state: nothing typed by `session` or `dependencies` has been
/// registered yet, so both type parameters are still free to be fixed.
///
/// `dependencies` and `session` are callable **only** in this state. That is
/// what makes it impossible for either of them to silently drop a router that
/// was typed against the parameters they replace — the mistake is now a
/// compile error instead of a bot with no routes.
pub type Fresh

/// Builder state: a router (or another handler typed by `session` /
/// `dependencies`) is registered, which pins both type parameters.
pub type Configured

/// How the bot receives updates.
type Mode {
  PollingMode(settings: polling.PollingSettings)
  WebhookMode
}

pub opaque type TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(
    config: Config,
    /// Long polling (the default) or a webhook registered on start.
    mode: Mode,
    router: Option(Routable(session, error, dependencies)),
    /// The stateless `Nil` session until `session` replaces it.
    session_settings: SessionSettings(session, error),
    catch_handler: Option(bot.CatchHandler(session, error, dependencies)),
    // Global pre-router middleware, run once per update before routing.
    // Added via `use_pre_handler`; executed in registration order.
    pre_handlers: List(bot.PreHandler(dependencies)),
    // Non-persisted services/dependencies injected into every `Context`.
    // Defaults to `Nil`; set via `dependencies`.
    dependencies: dependencies,
    // --- SetWebhook parameters ---
    drop_pending_updates: Option(Bool),
    max_connections: Option(Int),
    ip_address: Option(String),
    allowed_updates: Option(List(String)),
    certificate: Option(File),
    // --- Chat instance factory parameters ---
    chat_restart_tolerance_intensity: Option(Int),
    chat_restart_tolerance_period: Option(Int),
    chat_init_timeout: Option(Int),
    /// How long (ms) a chat instance may sit idle before it is stopped.
    /// `None` falls back to `bot.default_chat_idle_timeout` (30 minutes);
    /// eviction is turned off entirely by `chat_idle_eviction: False`.
    chat_idle_timeout: Option(Int),
    /// Whether idle instances are evicted at all. `with_chat_idle_timeout`
    /// leaves it on; `without_chat_idle_timeout` turns it off.
    chat_idle_eviction: Bool,
    /// How long (ms) a chat instance may sit idle before it compacts its heap.
    /// `None` falls back to `bot.default_hibernate_after`; compaction is turned
    /// off entirely by `chat_hibernation: False`.
    chat_hibernate_after: Option(Int),
    chat_hibernation: Bool,
    /// Whether a session no handler changed is written back anyway.
    session_persistence: bot.SessionPersistence,
    /// How an update maps to a session key (and therefore to a chat
    /// instance). `None` uses `bot.default_session_key`.
    session_key: Option(fn(update.Update) -> String),
    /// What happens when the session cannot be read from storage.
    session_load_error: bot.SessionLoadError,
    media_group_timeout: Option(Int),
    // --- Lifecycle parameters ---
    on_start: Option(
      fn(Telega(session, error, dependencies)) -> Result(Nil, error.TelegaError),
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
    /// Update types added to the derived set — what the router cannot know
    /// about, such as a conversation's `wait_callback`.
    extra_allowed_updates: List(String),
    /// When `True` and `allowed_updates` was not set manually, derive the
    /// requested update types from the router's registered routes.
    auto_allowed_updates: Bool,
  )
}

/// Internal function to get bot subject for polling
@internal
pub fn get_bot_subject_internal(
  telega: Telega(session, error, dependencies),
) -> BotSubject {
  telega.bot_subject
}

/// Internal function to get client for polling
@internal
pub fn get_client_internal(
  telega: Telega(session, error, dependencies),
) -> client.TelegramClient {
  telega.config.api_client
}

/// Check if a path is the webhook path for the bot.
///
/// Useful if you plan to implement own adapter.
pub fn is_webhook_path(
  telega: Telega(session, error, dependencies),
  path: String,
) {
  telega.config.webhook_path == path
}

/// Check if a secret token is valid.
///
/// Useful if you plan to implement own adapter.
pub fn is_secret_token_valid(
  telega: Telega(session, error, dependencies),
  token: String,
) {
  constant_time_compare(telega.config.secret_token, token)
}

/// Compare two secrets without giving away where they first differ.
///
/// `==` on binaries stops at the first differing byte, so the response time
/// reveals how long a shared prefix is and the secret can be guessed one byte
/// at a time. Use this in your own webhook adapter for any value an attacker
/// gets to retry.
pub fn constant_time_compare(left: String, right: String) -> Bool {
  utils.constant_time_compare(left, right)
}

/// Build a `Context` for work happening **outside** an update: a background
/// job that finished, a cron tick, a webhook from another service.
///
/// The context carries the same config, injected `dependencies` and bot info a
/// handler would see, and the user's persisted session — so a render or a
/// `reply.*` call behaves as it does inside an update.
///
/// Two things it cannot carry, because there is no chat instance behind it:
///
///   * `ctx.update` is a placeholder holding only `chat_id`/`from_id`
///     (an `UnknownUpdate`). Anything reading the update's content sees
///     nothing.
///   * `wait_*` and `cancel_conversation_in` have no instance to suspend, so
///     they do nothing. Start conversations from a real update.
///
/// Fails when the session cannot be read — same rule as a chat instance start:
/// acting on a default here would persist it over the real session.
///
/// ```gleam
/// // Refresh a user's open dialog once their export finishes.
/// let assert Ok(ctx) = telega.background_context(bot, chat_id:, user_id:)
/// let _ = dialog.refresh(ctx, registry, dialog_id: "export")
/// ```
pub fn background_context(
  telega telega: Telega(session, error, dependencies),
  chat_id chat_id: Int,
  user_id user_id: Int,
) -> Result(Context(session, error, dependencies), error.TelegaError) {
  let background = update.background_update(chat_id:, user_id:)
  let key = telega.session_key(background)

  use session <- result.try(case telega.session_settings.get_session(key) {
    Ok(Some(session)) -> Ok(session)
    Ok(None) -> Ok(telega.session_settings.default_session())
    Error(_) ->
      case telega.session_load_error {
        bot.FailUpdate ->
          Error(error.BotHandleUpdateError(
            "failed to read the session for " <> key,
          ))
        bot.UseDefault | bot.ReadOnly ->
          Ok(telega.session_settings.default_session())
      }
  })

  Ok(bot.Context(
    key:,
    update: background,
    config: telega.config,
    session:,
    dependencies: telega.dependencies,
    chat_subject: process.new_subject(),
    start_time: None,
    log_prefix: None,
    bot_info: telega.bot_info,
    // No update, so no pre-router middleware ran to annotate one.
    annotations: dict.new(),
    scope: scope.new(),
  ))
}

/// Helper to get the config for API requests.
pub fn get_api_config(telega: Telega(session, error, dependencies)) {
  telega.config.api_client
}

/// The session settings a bot runs with until it asks for others: nothing is
/// stored, and every chat starts from `Nil`.
///
/// This is the *only* nil-session path — a bot that never calls `session`
/// simply keeps these.
fn nil_session_settings() -> SessionSettings(Nil, error) {
  bot.SessionSettings(
    persist_session: fn(_key, _session) { Ok(Nil) },
    get_session: fn(_key) { Ok(None) },
    default_session: fn() { Nil },
  )
}

/// Start building a bot from an API client.
///
/// The client comes from an adapter package like `telega_httpc` or
/// `telega_hackney`. The builder starts out in long-polling mode with a `Nil`
/// session and no injected dependencies; `polling`, `webhook`, `session` and
/// `dependencies` change that.
///
/// ```gleam
/// telega.new(api_client)
/// |> telega.dependencies(Dependencies(db:, catalog:))
/// |> telega.session(session_settings)
/// |> telega.router(router)
/// |> telega.start()
/// ```
///
/// `dependencies` and `session` fix type parameters the router is typed
/// against, so they only compile *before* `router` (see `Fresh`).
pub fn new(
  api_client api_client: client.TelegramClient,
) -> TelegaBuilder(Nil, error, Nil, Fresh) {
  TelegaBuilder(
    config: config.new(
      api_client:,
      url: "https://api.telegram.org",
      webhook_path: "/webhook",
      secret_token: None,
    ),
    mode: PollingMode(polling.default_settings()),
    dependencies: Nil,
    router: None,
    session_settings: nil_session_settings(),
    catch_handler: None,
    pre_handlers: [],
    drop_pending_updates: None,
    max_connections: None,
    ip_address: None,
    allowed_updates: None,
    certificate: None,
    chat_restart_tolerance_intensity: None,
    chat_restart_tolerance_period: None,
    chat_init_timeout: None,
    chat_idle_timeout: None,
    chat_idle_eviction: True,
    chat_hibernate_after: None,
    chat_hibernation: True,
    session_persistence: bot.PersistOnChange,
    session_key: None,
    session_load_error: bot.FailUpdate,
    media_group_timeout: None,
    on_start: None,
    on_shutdown: None,
    drain_timeout: None,
    handle_signals: False,
    auto_commands: False,
    command_locales: [],
    command_translate: None,
    extra_allowed_updates: [],
    auto_allowed_updates: False,
  )
}

/// Inject typed, non-persisted dependencies (services) available in every
/// handler via `ctx.dependencies` (or `get_dependencies`).
///
/// Use this for things that are not user state and must not be persisted —
/// a database pool, an http client, an i18n catalog, configuration. The rule
/// of thumb: `session` is the user's state (persisted), `dependencies` is the
/// bot's services (set once at startup, never persisted).
///
/// Only callable while the builder is `Fresh`, i.e. before `router` or any
/// other handler that is typed against `dependencies`. Calling it later is a
/// compile error rather than a silently dropped router.
///
/// ```gleam
/// telega.new(api_client)
/// |> telega.dependencies(Dependencies(db:, catalog:))
/// |> telega.router(router)
/// |> telega.start()
/// ```
pub fn dependencies(
  builder builder: TelegaBuilder(session, error, old_dependencies, Fresh),
  dependencies dependencies: dependencies,
) -> TelegaBuilder(session, error, dependencies, Fresh) {
  // The `Fresh` state guarantees the `dependencies`-typed fields are still at
  // their defaults, so rebuilding the record loses nothing.
  TelegaBuilder(
    dependencies:,
    router: None,
    catch_handler: None,
    pre_handlers: [],
    on_start: None,
    config: builder.config,
    mode: builder.mode,
    session_settings: builder.session_settings,
    drop_pending_updates: builder.drop_pending_updates,
    max_connections: builder.max_connections,
    ip_address: builder.ip_address,
    allowed_updates: builder.allowed_updates,
    certificate: builder.certificate,
    chat_restart_tolerance_intensity: builder.chat_restart_tolerance_intensity,
    chat_restart_tolerance_period: builder.chat_restart_tolerance_period,
    chat_init_timeout: builder.chat_init_timeout,
    chat_idle_timeout: builder.chat_idle_timeout,
    chat_idle_eviction: builder.chat_idle_eviction,
    chat_hibernate_after: builder.chat_hibernate_after,
    chat_hibernation: builder.chat_hibernation,
    session_persistence: builder.session_persistence,
    session_key: builder.session_key,
    session_load_error: builder.session_load_error,
    media_group_timeout: builder.media_group_timeout,
    on_shutdown: builder.on_shutdown,
    drain_timeout: builder.drain_timeout,
    handle_signals: builder.handle_signals,
    auto_commands: builder.auto_commands,
    command_locales: builder.command_locales,
    command_translate: builder.command_translate,
    extra_allowed_updates: builder.extra_allowed_updates,
    auto_allowed_updates: builder.auto_allowed_updates,
  )
}

/// Give the bot a persisted session.
///
/// Without this call the bot runs on the stateless `Nil` session — there is no
/// separate "nil session" constructor to remember. Storage adapters build the
/// settings for you (`storage.session_settings_from_storage` and friends).
///
/// Like `dependencies`, it fixes a type parameter the router is typed against,
/// so it only compiles while the builder is `Fresh`.
///
/// ```gleam
/// telega.new(api_client)
/// |> telega.session(storage.session_settings_from_storage(
///   storage:,
///   encode: encode_session,
///   decode: session_decoder(),
///   default: fn() { Session(count: 0) },
/// ))
/// |> telega.router(router)
/// |> telega.start()
/// ```
pub fn session(
  builder builder: TelegaBuilder(old_session, error, dependencies, Fresh),
  settings settings: SessionSettings(session, error),
) -> TelegaBuilder(session, error, dependencies, Fresh) {
  // The `Fresh` state guarantees the `session`-typed fields are still at their
  // defaults, so rebuilding the record loses nothing.
  TelegaBuilder(
    session_settings: settings,
    router: None,
    catch_handler: None,
    on_start: None,
    config: builder.config,
    mode: builder.mode,
    pre_handlers: builder.pre_handlers,
    dependencies: builder.dependencies,
    drop_pending_updates: builder.drop_pending_updates,
    max_connections: builder.max_connections,
    ip_address: builder.ip_address,
    allowed_updates: builder.allowed_updates,
    certificate: builder.certificate,
    chat_restart_tolerance_intensity: builder.chat_restart_tolerance_intensity,
    chat_restart_tolerance_period: builder.chat_restart_tolerance_period,
    chat_init_timeout: builder.chat_init_timeout,
    chat_idle_timeout: builder.chat_idle_timeout,
    chat_idle_eviction: builder.chat_idle_eviction,
    chat_hibernate_after: builder.chat_hibernate_after,
    chat_hibernation: builder.chat_hibernation,
    session_persistence: builder.session_persistence,
    session_key: builder.session_key,
    session_load_error: builder.session_load_error,
    media_group_timeout: builder.media_group_timeout,
    on_shutdown: builder.on_shutdown,
    drain_timeout: builder.drain_timeout,
    handle_signals: builder.handle_signals,
    auto_commands: builder.auto_commands,
    command_locales: builder.command_locales,
    command_translate: builder.command_translate,
    extra_allowed_updates: builder.extra_allowed_updates,
    auto_allowed_updates: builder.auto_allowed_updates,
  )
}

/// Mark the builder as carrying handlers typed by `session`/`dependencies`,
/// which pins both parameters. Every registration that stores such a handler
/// goes through here, so `dependencies` and `session` can no longer be called.
fn configured(
  builder: TelegaBuilder(session, error, dependencies, old_state),
) -> TelegaBuilder(session, error, dependencies, Configured) {
  TelegaBuilder(
    config: builder.config,
    mode: builder.mode,
    router: builder.router,
    session_settings: builder.session_settings,
    catch_handler: builder.catch_handler,
    pre_handlers: builder.pre_handlers,
    dependencies: builder.dependencies,
    drop_pending_updates: builder.drop_pending_updates,
    max_connections: builder.max_connections,
    ip_address: builder.ip_address,
    allowed_updates: builder.allowed_updates,
    certificate: builder.certificate,
    chat_restart_tolerance_intensity: builder.chat_restart_tolerance_intensity,
    chat_restart_tolerance_period: builder.chat_restart_tolerance_period,
    chat_init_timeout: builder.chat_init_timeout,
    chat_idle_timeout: builder.chat_idle_timeout,
    chat_idle_eviction: builder.chat_idle_eviction,
    chat_hibernate_after: builder.chat_hibernate_after,
    chat_hibernation: builder.chat_hibernation,
    session_persistence: builder.session_persistence,
    session_key: builder.session_key,
    session_load_error: builder.session_load_error,
    media_group_timeout: builder.media_group_timeout,
    on_start: builder.on_start,
    on_shutdown: builder.on_shutdown,
    drain_timeout: builder.drain_timeout,
    handle_signals: builder.handle_signals,
    auto_commands: builder.auto_commands,
    command_locales: builder.command_locales,
    command_translate: builder.command_translate,
    extra_allowed_updates: builder.extra_allowed_updates,
    auto_allowed_updates: builder.auto_allowed_updates,
  )
}

/// Set the router that handles updates.
///
/// This is the primary way to handle updates — build one with `router.new()`
/// and register commands, text handlers, middleware on it. For a composition
/// built with `router.compose`/`router.branch`, use `router_tree`.
pub fn router(
  builder: TelegaBuilder(session, error, dependencies, state),
  router router_: Router(session, error, dependencies),
) -> TelegaBuilder(session, error, dependencies, Configured) {
  configured(TelegaBuilder(..builder, router: Some(router.routable(router_))))
}

/// Set a composed `router.RouterTree` that handles updates.
///
/// ```gleam
/// let tree =
///   router.tree()
///   |> router.branch(router.is_private_chat(), private_router)
///   |> router.branch(router.is_group_chat(), group_router)
///
/// telega.new(api_client)
/// |> telega.router_tree(tree)
/// ```
pub fn router_tree(
  builder: TelegaBuilder(session, error, dependencies, state),
  tree tree: RouterTree(session, error, dependencies),
) -> TelegaBuilder(session, error, dependencies, Configured) {
  configured(TelegaBuilder(..builder, router: Some(router.tree_routable(tree))))
}

/// Receive updates by long polling (the default) with explicit settings.
///
/// ```gleam
/// telega.new(api_client)
/// |> telega.router(router)
/// |> telega.polling(polling.PollingSettings(
///   ..polling.default_settings(),
///   limit: 10,
/// ))
/// |> telega.start()
/// ```
///
/// A builder that calls neither `polling` nor `webhook` polls with
/// `polling.default_settings()`.
pub fn polling(
  builder: TelegaBuilder(session, error, dependencies, state),
  settings settings: polling.PollingSettings,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, mode: PollingMode(settings))
}

/// Receive updates through a webhook, registered with `setWebhook` on `start`.
///
/// `url` is the public base URL of your server and `path` the route your web
/// adapter serves; Telegram is told to POST to `url <> "/" <> path`. A
/// `secret_token` of `None` generates a random one — adapters compare it for
/// you (`is_secret_token_valid`).
///
/// ```gleam
/// telega.new(api_client)
/// |> telega.webhook(
///   url: "https://bot.example.com",
///   path: "webhook",
///   secret_token: Some(secret),
/// )
/// |> telega.router(router)
/// |> telega.start()
/// ```
pub fn webhook(
  builder: TelegaBuilder(session, error, dependencies, state),
  url server_url: String,
  path webhook_path: String,
  secret_token secret_token: Option(String),
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(
    ..builder,
    mode: WebhookMode,
    config: config.new(
      api_client: builder.config.api_client,
      url: utils.normalize_url(server_url),
      webhook_path: utils.normalize_webhook_path(webhook_path),
      secret_token:,
    ),
  )
}

/// Set the catch handler for system errors (like session persistence failures)
/// and [conversation](/docs/conversation) errors.
///
/// This is different from the router's catch handler, which handles route
/// errors.
pub fn with_catch_handler(
  builder: TelegaBuilder(session, error, dependencies, state),
  catch_handler: bot.CatchHandler(session, error, dependencies),
) -> TelegaBuilder(session, error, dependencies, Configured) {
  configured(TelegaBuilder(..builder, catch_handler: Some(catch_handler)))
}

/// Register a global pre-router middleware ([`bot.PreHandler`](./telega/bot.html#PreHandler)).
///
/// Pre-router middleware runs once per update inside the bot actor, *before*
/// routing and before any chat instance is spawned or session loaded. Use it
/// for cross-cutting concerns that apply to every update: anti-spam, analytics,
/// and update deduplication. Returning `bot.Stop` drops the update before
/// routing; `bot.Continue` lets it through to the next pre-handler and the
/// router. Handlers run in the order they are registered, and the first `Stop`
/// short-circuits the rest. Because they all run sequentially in the single bot
/// actor, read-then-write logic (like dedup) is race-free across updates.
///
/// ```gleam
/// // Drop updates from a banned chat before they reach any handler.
/// telega.new(api_client)
/// |> telega.use_pre_handler(fn(pre) {
///   case pre.update.chat_id == banned_chat {
///     True -> bot.Stop
///     False -> bot.proceed()
///   }
/// })
/// |> telega.router(router)
///
/// // Webhook idempotency: drop updates Telegram re-delivers on retry.
/// |> telega.use_pre_handler(idempotency.deduplicate(storage:, ttl_ms: 3600_000))
/// ```
pub fn use_pre_handler(
  builder: TelegaBuilder(session, error, dependencies, state),
  pre_handler: bot.PreHandler(dependencies),
) -> TelegaBuilder(session, error, dependencies, Configured) {
  configured(
    TelegaBuilder(
      ..builder,
      pre_handlers: list.append(builder.pre_handlers, [pre_handler]),
    ),
  )
}

/// Drop the updates Telegram accumulated while the bot was down
/// (webhook mode).
pub fn with_drop_pending_updates(
  builder: TelegaBuilder(session, error, dependencies, state),
  drop drop: Bool,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, drop_pending_updates: Some(drop))
}

/// Set the maximum number of simultaneous webhook connections Telegram opens.
pub fn with_max_connections(
  builder: TelegaBuilder(session, error, dependencies, state),
  max max: Int,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, max_connections: Some(max))
}

/// Set the fixed IP address Telegram sends webhook updates to.
pub fn with_ip_address(
  builder: TelegaBuilder(session, error, dependencies, state),
  ip ip: String,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, ip_address: Some(ip))
}

/// Restrict the update types Telegram sends, by hand.
///
/// Always wins over `with_auto_allowed_updates` — this is the escape hatch for
/// when derivation is not what you want.
pub fn with_allowed_updates(
  builder: TelegaBuilder(session, error, dependencies, state),
  updates updates: List(String),
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, allowed_updates: Some(updates))
}

/// Upload a self-signed certificate along with the webhook.
pub fn with_certificate(
  builder: TelegaBuilder(session, error, dependencies, state),
  certificate certificate: File,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, certificate: Some(certificate))
}

/// Set how tolerant the chat instance factory supervisor is of restarts:
/// at most `intensity` restarts within `period` seconds (default: 5 in 10).
pub fn with_chat_restart_tolerance(
  builder: TelegaBuilder(session, error, dependencies, state),
  intensity intensity: Int,
  period period: Int,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(
    ..builder,
    chat_restart_tolerance_intensity: Some(intensity),
    chat_restart_tolerance_period: Some(period),
  )
}

/// Set how long (ms) a chat instance may take to start, which includes loading
/// its session from storage (default: 10 000).
pub fn with_chat_init_timeout(
  builder: TelegaBuilder(session, error, dependencies, state),
  timeout timeout: Int,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, chat_init_timeout: Some(timeout))
}

/// Stop chat instances that have been idle for `timeout` milliseconds.
///
/// One `ChatInstance` process is started per `{chat_id}:{from_id}`, so a bot
/// used by many distinct people accumulates one process (plus its session and
/// any suspended conversation) per person. They are evicted after half an hour
/// of silence by default — `bot.default_chat_idle_timeout` — and this changes
/// that bound.
///
/// An instance that has received nothing for that long is deregistered and
/// stopped by the bot actor. The next update from that user simply starts a
/// fresh instance, which re-reads the session from storage — so nothing
/// persisted is lost.
///
/// A pending conversation (`wait_*`) lives only in the instance's memory, so it
/// is dropped along with the instance. Pick an idle timeout comfortably larger
/// than the conversation timeouts you use.
///
/// ```gleam
/// telega.new(api_client)
/// |> telega.router(router)
/// // reclaim a user's process after five minutes of silence
/// |> telega.with_chat_idle_timeout(1000 * 60 * 5)
/// |> telega.start()
/// ```
pub fn with_chat_idle_timeout(
  builder: TelegaBuilder(session, error, dependencies, state),
  timeout timeout: Int,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(
    ..builder,
    chat_idle_timeout: Some(timeout),
    chat_idle_eviction: True,
  )
}

/// Keep every chat instance alive for as long as the bot runs.
///
/// This undoes the default half-hour eviction. Only worth it when a bot serves
/// a small, known set of chats and wants their in-memory conversations to
/// survive any amount of silence — an open-ended process per user is exactly
/// how a busy bot runs out of BEAM processes.
pub fn without_chat_idle_timeout(
  builder: TelegaBuilder(session, error, dependencies, state),
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, chat_idle_eviction: False)
}

/// Compact a chat instance's heap once it has been quiet for `after`
/// milliseconds (default: `bot.default_hibernate_after`, one minute).
///
/// An instance that handled a burst of messages keeps the heap that burst grew
/// until it is evicted. One full garbage collection after the chat goes quiet
/// gives it back, which for a bot holding many idle instances is the difference
/// between kilobytes and tens of kilobytes each.
pub fn with_chat_hibernate_after(
  builder: TelegaBuilder(session, error, dependencies, state),
  after after: Int,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(
    ..builder,
    chat_hibernate_after: Some(after),
    chat_hibernation: True,
  )
}

/// Never compact an idle chat instance's heap.
pub fn without_chat_hibernation(
  builder: TelegaBuilder(session, error, dependencies, state),
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, chat_hibernation: False)
}

/// Choose whether a session no handler changed is still written back.
///
/// The default is `bot.PersistOnChange`: a handler that returns the session it
/// was given costs no storage write at all, which for a bot whose handlers
/// mostly read is most of its writes. Switch to `bot.PersistAlways` when the
/// write itself does something you rely on — refreshing an expiry, touching a
/// "last seen" column.
///
/// ```gleam
/// telega.new(api_client)
/// |> telega.session(settings)
/// |> telega.with_session_persistence(bot.PersistAlways)
/// ```
pub fn with_session_persistence(
  builder: TelegaBuilder(session, error, dependencies, state),
  persistence persistence: bot.SessionPersistence,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, session_persistence: persistence)
}

/// Choose what an update is keyed by — its session *and* the chat instance
/// that handles it.
///
/// The default is `bot.default_session_key`: `"{chat_id}:{from_id}"`, one
/// session per user per chat. `bot.chat_session_key` gives a group one shared
/// session (and one instance, so members are serialized through it);
/// `bot.user_session_key` follows a user across chats. Anything else is a
/// function of the update:
///
/// ```gleam
/// // One session per forum topic rather than per chat.
/// telega.with_session_key(builder, fn(update) {
///   case update.thread_id {
///     Some(thread) -> int.to_string(update.chat_id) <> ":t" <> int.to_string(thread)
///     None -> bot.default_session_key(update)
///   }
/// })
/// ```
///
/// Two updates that map to the same key share one process and one session, so
/// the key decides both concurrency and isolation. The trade-offs of the
/// built-in keys — anonymous group admins, inline-message callbacks, updates
/// with no user — are in `docs/session-serialization.md`.
pub fn with_session_key(
  builder: TelegaBuilder(session, error, dependencies, state),
  key key: fn(update.Update) -> String,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, session_key: Some(key))
}

/// Choose what happens when the session cannot be read from storage.
///
/// The default is `bot.FailUpdate`: the chat instance refuses to start and the
/// update is reported unhandled, because serving it on a default session would
/// let the first handler persist that default over the real, still-stored
/// data. `bot.ReadOnly` keeps the bot answering while the backend is down
/// (handlers run on the default session, every write is skipped with a
/// warning); `bot.UseDefault` is the old, lossy behaviour — pick it only when
/// losing a session costs less than dropping the update.
///
/// ```gleam
/// telega.new(api_client)
/// |> telega.session(settings)
/// |> telega.with_session_load_error(bot.ReadOnly)
/// ```
pub fn with_session_load_error(
  builder: TelegaBuilder(session, error, dependencies, state),
  policy policy: bot.SessionLoadError,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, session_load_error: policy)
}

/// Gather the messages of an album into a single `MediaGroupUpdate`.
///
/// Telegram delivers an album as separate messages that share a
/// `media_group_id`, so without this setting they arrive one by one on
/// `on_photo` / `on_video` / `on_audio` and `router.on_media_group` never
/// fires. With it, a chat instance holds them back until `timeout`
/// milliseconds pass without another message of the same album (1000 is a
/// good starting point) and then routes them together.
///
/// The individual messages are *not* delivered as well — a bot that turns this
/// on handles albums in `on_media_group` and single media in `on_photo` and
/// friends. Messages that arrive while a `wait_*` conversation is pending are
/// left alone, since the waiting handler expects them one at a time.
///
/// ```gleam
/// telega.new(api_client)
/// |> telega.router(router)
/// |> telega.with_media_group_timeout(1000)
/// |> telega.start()
/// ```
pub fn with_media_group_timeout(
  builder: TelegaBuilder(session, error, dependencies, state),
  timeout timeout: Int,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, media_group_timeout: Some(timeout))
}

/// Set a hook to run once the bot has fully started.
///
/// Runs after the supervision tree is up and the `Telega` instance is built, so
/// you can use it for warming caches, registering commands via the API, etc.
/// Returning `Error` aborts startup and tears the supervision tree back down.
///
/// ```gleam
/// telega.new(api_client)
/// |> telega.router(router)
/// |> telega.with_on_start(fn(bot) {
///   // register commands, warm caches...
///   Ok(Nil)
/// })
/// |> telega.start()
/// ```
pub fn with_on_start(
  builder: TelegaBuilder(session, error, dependencies, state),
  on_start on_start: fn(Telega(session, error, dependencies)) ->
    Result(Nil, error.TelegaError),
) -> TelegaBuilder(session, error, dependencies, Configured) {
  configured(TelegaBuilder(..builder, on_start: Some(on_start)))
}

/// Set a hook to run during `shutdown`, after in-flight updates have drained
/// and before the supervision tree is stopped. Use it to release resources
/// (close pools, flush buffers, deregister from a service discovery, …).
pub fn with_on_shutdown(
  builder: TelegaBuilder(session, error, dependencies, state),
  on_shutdown on_shutdown: fn() -> Nil,
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, on_shutdown: Some(on_shutdown))
}

/// Set the maximum time (in milliseconds) `shutdown` waits for in-flight
/// updates to finish before forcibly stopping the supervision tree.
///
/// Defaults to 5000ms.
pub fn with_drain_timeout(
  builder: TelegaBuilder(session, error, dependencies, state),
  timeout timeout: Int,
) -> TelegaBuilder(session, error, dependencies, state) {
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
  builder: TelegaBuilder(session, error, dependencies, state),
) -> TelegaBuilder(session, error, dependencies, state) {
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
/// telega.new(api_client)
/// |> telega.router(router)
/// |> telega.with_auto_commands()
/// |> telega.start()
/// ```
pub fn with_auto_commands(
  builder: TelegaBuilder(session, error, dependencies, state),
) -> TelegaBuilder(session, error, dependencies, state) {
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
/// telega.new(api_client)
/// |> telega.router(router)
/// |> telega.with_command_translations(
///   locales: ["en", "ru"],
///   translate: fn(command, locale) { lookup_description(command, locale) },
/// )
/// |> telega.start()
/// ```
pub fn with_command_translations(
  builder: TelegaBuilder(session, error, dependencies, state),
  locales locales: List(String),
  translate translate: fn(String, String) -> Option(String),
) -> TelegaBuilder(session, error, dependencies, state) {
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
/// out traffic for routes you never registered. A manual `with_allowed_updates`
/// always wins (the escape hatch). If the router has a fallback, custom, or
/// filtered route — which can match anything — derivation can't narrow safely
/// and falls back to Telegram's default update set.
pub fn with_auto_allowed_updates(
  builder: TelegaBuilder(session, error, dependencies, state),
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(..builder, auto_allowed_updates: True)
}

/// Add update types to the auto-derived `allowed_updates`.
///
/// Derivation only sees the *router*. Updates a conversation or a flow waits
/// for are invisible to it: a bot whose router registers only commands, but
/// whose handlers use `wait_callback`, derives `["message"]` — and then waits
/// forever for a `callback_query` Telegram was never asked to send.
///
/// ```gleam
/// |> telega.with_auto_allowed_updates()
/// |> telega.with_extra_allowed_updates(["message_reaction"])
/// ```
///
/// Has no effect when derivation already returns "do not restrict" (a router
/// with a fallback, custom or filtered route), and none when
/// `with_allowed_updates` set the list manually.
pub fn with_extra_allowed_updates(
  builder: TelegaBuilder(session, error, dependencies, state),
  updates updates: List(String),
) -> TelegaBuilder(session, error, dependencies, state) {
  TelegaBuilder(
    ..builder,
    extra_allowed_updates: list.append(builder.extra_allowed_updates, updates),
  )
}

/// Start the bot.
///
/// Builds the supervision tree (chat instance factory → bot, plus a polling
/// worker in polling mode) and, in webhook mode, registers the webhook with
/// Telegram. Fails when the router is missing, the token is rejected, or a
/// child cannot start.
///
/// ```gleam
/// let assert Ok(bot) =
///   telega.new(api_client)
///   |> telega.router(router)
///   |> telega.start()
/// ```
pub fn start(
  builder: TelegaBuilder(session, error, dependencies, state),
) -> Result(Telega(session, error, dependencies), error.TelegaError) {
  case builder.mode {
    WebhookMode -> start_webhook(builder)
    PollingMode(settings) -> start_polling(builder, settings)
  }
}

fn start_webhook(
  builder: TelegaBuilder(session, error, dependencies, state),
) -> Result(Telega(session, error, dependencies), error.TelegaError) {
  let api_client = builder.config.api_client

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

  use bot_info <- result.try(fetch_bot_info(api_client))
  boot(builder, bot_info, None)
}

fn start_polling(
  builder: TelegaBuilder(session, error, dependencies, state),
  settings: polling.PollingSettings,
) -> Result(Telega(session, error, dependencies), error.TelegaError) {
  use bot_info <- result.try(fetch_bot_info(builder.config.api_client))
  boot(builder, bot_info, Some(settings))
}

/// Ask Telegram who the bot is, spelling out what a rejected token means.
fn fetch_bot_info(
  api_client: client.TelegramClient,
) -> Result(User, error.TelegaError) {
  api.get_me(api_client)
  |> result.map_error(fn(err) {
    case err {
      error.TelegramApiError(error_code: 404, ..) ->
        error.TelegramApiError(
          error_code: 404,
          description: "Bot not found. Please check that your BOT_TOKEN is valid and the bot exists. Get a valid token from @BotFather on Telegram.",
          parameters: option.None,
        )
      error.TelegramApiError(error_code: 401, ..) ->
        error.TelegramApiError(
          error_code: 401,
          description: "Unauthorized. Your bot token is invalid. Please get a valid token from @BotFather on Telegram.",
          parameters: option.None,
        )
      _ -> err
    }
  })
}

/// Build and start the supervision tree shared by both modes, adding a polling
/// worker when polling settings are given.
fn boot(
  builder: TelegaBuilder(session, error, dependencies, state),
  bot_info: User,
  polling_settings: Option(polling.PollingSettings),
) -> Result(Telega(session, error, dependencies), error.TelegaError) {
  use routable <- result.try(option.to_result(
    builder.router,
    error.RouterError(
      "Router is required. Use router() or router_tree() to set one.",
    ),
  ))

  let config = builder.config
  let api_client = config.api_client
  let session_settings = builder.session_settings
  let router_handler = routable.handle
  let catch_handler =
    option.unwrap(builder.catch_handler, fn(_ctx, err) { Error(err) })

  let registry_name = generate_registry_name(client.get_token(api_client))
  use registry <- result.try(registry.start(registry_name))

  // Build supervision tree: factory → bot (→ polling)
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
        pre_handlers: builder.pre_handlers,
        session_settings:,
        catch_handler:,
        dependencies: builder.dependencies,
        chat_factory: chat_factory_ref,
        chat_settings: chat_settings(builder),
        name: Some(bot_name),
      )
    })
    |> supervision.restart(supervision.Permanent)

  let tree =
    sup.new(sup.OneForOne)
    |> sup.add(chat_factory_spec)
    |> sup.add(bot_spec)

  let #(tree, poller) = case polling_settings {
    None -> #(tree, None)
    Some(settings) -> {
      let poller_name = process.new_name("telega_poller")
      let polling_spec =
        polling.supervised(
          client: api_client,
          bot: bot_subject,
          timeout: settings.timeout,
          limit: settings.limit,
          allowed_updates: option.unwrap(resolve_allowed_updates(builder), []),
          poll_interval: settings.poll_interval,
          on_stop: settings.on_stop,
          name: poller_name,
        )
      #(sup.add(tree, polling_spec), Some(process.named_subject(poller_name)))
    }
  }

  use sup_started <- result.try(
    tree
    |> sup.start
    |> result.map_error(error.SupervisorStartError),
  )

  finalize(
    builder:,
    config:,
    bot_info:,
    bot_subject:,
    supervisor_pid: sup_started.pid,
    poller:,
    session_settings:,
  )
}

/// Run the bot as a child of your own supervision tree.
///
/// Wraps `start` into a `ChildSpecification`: telega still builds and owns its
/// internal `chat factory → bot (→ polling)` tree, but that tree's root becomes
/// a child of YOUR supervisor. If the bot tree dies, your supervisor restarts
/// it by re-running `start` — `setWebhook` (webhook mode), `getMe` and a fresh
/// internal tree.
///
/// Add it after the resources the bot depends on (database pool, caches) —
/// with a `RestForOne` strategy a dead dependency restarts the bot too:
///
/// ```gleam
/// let bot_ready = process.new_subject()
/// let bot_child =
///   telega.new(api_client)
///   |> telega.webhook(url:, path:, secret_token:)
///   |> telega.router(router)
///   |> telega.with_on_start(fn(bot) { Ok(process.send(bot_ready, bot)) })
///   |> telega.supervised()
///
/// let assert Ok(_) =
///   static_supervisor.new(static_supervisor.RestForOne)
///   |> static_supervisor.add(db_pool_child)
///   |> static_supervisor.add(bot_child)
///   |> static_supervisor.start
///
/// // Webhook adapters need the instance — receive it from the hook.
/// let assert Ok(bot) = process.receive(bot_ready, within: 10_000)
/// ```
///
/// The started `Telega` instance is the child's data; supervisors don't hand
/// child data back, so capture it in `with_on_start` as above when you need
/// it outside the tree (webhook adapters, manual `shutdown`). Stopping your
/// tree stops the bot the standard OTP way (no drain); for a drained stop use
/// `shutdown` or `with_signal_handlers`.
pub fn supervised(
  builder: TelegaBuilder(session, error, dependencies, state),
) -> supervision.ChildSpecification(Telega(session, error, dependencies)) {
  supervision.supervisor(fn() { child_started(start(builder)) })
}

fn child_started(
  started: Result(Telega(session, error, dependencies), error.TelegaError),
) -> Result(
  actor.Started(Telega(session, error, dependencies)),
  actor.StartError,
) {
  case started {
    Ok(telega) -> Ok(actor.Started(pid: telega.supervisor_pid, data: telega))
    Error(e) -> Error(actor.InitFailed(error.to_string(e)))
  }
}

/// Handle an update.
///
/// This function is useful when you want to handle updates in your own way.
pub fn handle_update(
  telega: Telega(session, error, dependencies),
  raw_update: Update,
) -> Bool {
  let update = update.raw_to_update(raw_update)
  bot.handle_update(telega.bot_subject, update)
}

/// What the webhook HTTP endpoint should answer for an update processed with
/// `handle_update_webhook`.
pub type WebhookResponse {
  /// Answer with an empty `200 OK`; every bot API call went (or will go) over
  /// HTTP as usual.
  EmptyResponse
  /// Answer with this JSON body (`{"method": "...", ...}`) and
  /// `Content-Type: application/json` — Telegram executes the embedded API
  /// call, saving one HTTP round-trip.
  JsonResponse(body: String)
}

type WebhookEvent {
  ReplyClaimed(
    reply: webhook_reply.WebhookReply,
    granted: process.Subject(Bool),
  )
  UpdateHandled
}

/// Handle an update, allowing the handler to answer it directly in the
/// webhook HTTP response body ([webhook reply](https://core.telegram.org/bots/api#making-requests-when-getting-updates)).
///
/// Waits up to `timeout` ms for the handler to either claim an eligible API
/// call (see `telega/webhook_reply`) or finish. On a claim it returns
/// `JsonResponse` for the adapter to send back; otherwise `EmptyResponse`.
/// After the timeout the handler keeps running in the background and all its
/// API calls go over regular HTTP.
///
/// Pick a `timeout` safely below Telegram's webhook timeout — e.g. 5000 ms.
/// Adapters expose this as `handle_bot_with_reply`; use this function directly
/// only when implementing your own adapter.
///
/// > ⚠️ A claimed call resolves to a synthetic stub in the handler: `True` for
/// > boolean methods, a fake `Message` (`message_id: -1`, `date: 0`) for
/// > `sendMessage`. Full guide in the `telega/webhook_reply` module docs.
pub fn handle_update_webhook(
  telega telega: Telega(session, error, dependencies),
  update raw_update: Update,
  timeout timeout: Int,
) -> WebhookResponse {
  let update = update.raw_to_update(raw_update)
  let envelope: webhook_reply.Envelope = process.new_subject()
  let done = process.new_subject()

  bot.dispatch_update_with_envelope(
    bot_subject: telega.bot_subject,
    update:,
    reply_with: done,
    envelope:,
  )

  let selector =
    process.new_selector()
    |> process.select_map(envelope, fn(message) {
      let webhook_reply.Claim(reply:, granted:) = message
      ReplyClaimed(reply:, granted:)
    })
    |> process.select_map(done, fn(_handled) { UpdateHandled })

  case process.selector_receive(from: selector, within: timeout) {
    Ok(ReplyClaimed(reply:, granted:)) -> {
      process.send(granted, True)
      JsonResponse(body: webhook_reply.to_response_body(reply))
    }
    // Handler finished without claiming, or timed out — plain 200. In the
    // timeout case any later claim finds no waiting grantor and falls back to
    // a regular HTTP call.
    Ok(UpdateHandled) | Error(Nil) -> EmptyResponse
  }
}

/// Get the bot's information.
pub fn get_me(telega: Telega(session, error, dependencies)) -> User {
  telega.bot_info
}

/// Get session for the current context.
pub fn get_session(ctx: Context(session, error, dependencies)) -> session {
  ctx.session
}

/// Get the injected dependencies (services) for the current context.
///
/// `dependencies` is set once at bot init via `with_dependencies` and is never persisted.
/// See the `session` vs `dependencies` distinction in `with_dependencies`.
pub fn get_dependencies(
  ctx: Context(session, error, dependencies),
) -> dependencies {
  ctx.dependencies
}

/// Add logging context to the current context.
pub fn log_context(
  ctx: Context(session, error, dependencies),
  prefix: String,
  fun: fn(Context(session, error, dependencies)) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
  let ctx_with_log = bot.Context(..ctx, log_prefix: Some(prefix))
  fun(ctx_with_log)
}

/// Context helpers for logging
pub fn log_info(ctx: Context(session, error, dependencies), message: String) {
  case ctx.log_prefix {
    Some(prefix) -> log.info_d(prefix, message)
    None -> log.info(message)
  }
}

pub fn log_error(ctx: Context(session, error, dependencies), message: String) {
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
  ctx ctx: Context(session, error, dependencies),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue handler: fn(Context(session, error, dependencies), update.Update) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  command command: String,
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), update.Command) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  commands commands: List(String),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), update.Command) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), String) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  hears hears: bot.Hears,
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), String) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), types.Message) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  filter filter: Option(bot.CallbackQueryFilter),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), String, String) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), types.Audio) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), types.Video) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), types.Voice) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(
    Context(session, error, dependencies),
    List(types.PhotoSize),
  ) -> Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  min min: Option(Int),
  max max: Option(Int),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), Int) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
  ctx ctx: Context(session, error, dependencies),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), String) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
/// This function sends `text` with an inline keyboard built from `options`
/// and waits for user to select one.
///
/// If the prompt cannot be sent (network error, bot blocked, empty `text`),
/// the error is logged and the conversation is **not** started: the function
/// returns `Ok(ctx)` instead of waiting for a press that can never come.
///
/// ## Examples
///
/// ```gleam
/// use ctx, color <- wait_choice(
///   ctx,
///   text: "Pick a color",
///   options: [
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
  ctx ctx: Context(session, error, dependencies),
  text text: String,
  options options: List(#(String, a)),
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), a) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
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
        disabled: None,
      )
    })

  let keyboard =
    types.InlineKeyboardMarkup(inline_keyboard: [buttons], force_reply: None)

  // Send message with keyboard
  let send_params =
    types.SendMessageParameters(
      business_connection_id: None,
      chat_id: types.Int(ctx.update.chat_id),
      message_thread_id: None,
      text:,
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
      ephemeral_message_parameters: None,
    )

  case api.send_message(ctx.config.api_client, send_params) {
    Error(err) -> {
      log.error_d("wait_choice: failed to send the choice prompt", err)
      Ok(ctx)
    }
    Ok(_) -> {
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
              wait_choice(
                ctx,
                text:,
                options:,
                or: handle_else,
                timeout:,
                continue:,
              )
          }
        Error(_) ->
          wait_choice(
            ctx,
            text:,
            options:,
            or: handle_else,
            timeout:,
            continue:,
          )
      }
    }
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
  ctx ctx: Context(session, error, dependencies),
  filter filter: fn(update.Update) -> Bool,
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), update.Update) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
  bot.wait_handler(
    ctx:,
    timeout:,
    handle_else:,
    handler: bot.HandleFiltered(filter:, handler: continue),
  )
}

/// Pauses the current chat actor's handler and waits for an update that matches
/// a composable `router.Filter`.
///
/// Unlike the typed waiters (`wait_text`, `wait_photos`, …) which each listen
/// for a single update type, this accepts the router's filter combinators, so a
/// single continuation can wait for several types at once. Combine with
/// `router.or`/`router.or2` (any), `router.and`/`router.and2` (all) and
/// `router.not`:
///
/// ```gleam
/// use ctx, upd <- wait_filtered(
///   ctx,
///   filter: router.or2(router.is_text(), router.has_photo()),
///   or: None,
///   timeout: None,
/// )
/// case upd {
///   update.TextUpdate(text:, ..) -> // ...
///   update.PhotoUpdate(photos:, ..) -> // ...
///   _ -> // ...
/// }
/// ```
///
/// `wait_for` remains the escape hatch for a raw `fn(Update) -> Bool` predicate.
pub fn wait_filtered(
  ctx ctx: Context(session, error, dependencies),
  filter filter: router.Filter,
  or handle_else: Option(bot.Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
  continue continue: fn(Context(session, error, dependencies), update.Update) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
  wait_for(
    ctx:,
    filter: router.matches(filter, _),
    or: handle_else,
    timeout:,
    continue:,
  )
}

/// Start polling with default configuration for a Telega instance.
/// This is useful when you want to manually start polling outside the supervision tree.
pub fn start_polling_default(
  telega: Telega(session, error, dependencies),
) -> Result(polling.Poller, error.TelegaError) {
  polling.start_polling_default(
    client: telega.config.api_client,
    bot: telega.bot_subject,
  )
}

/// Cancel the conversation a chat is currently waiting in.
///
/// `key` is the session key of the chat instance — the `"{chat_id}:{from_id}"`
/// string available in any handler as `ctx.key`. The pending `wait_*`
/// continuation is dropped, so the next update from that chat is routed
/// normally again. The chat instance itself and its session are untouched, and
/// cancelling a chat that is not waiting for anything does nothing.
pub fn cancel_conversation(
  telega telega: Telega(session, error, dependencies),
  key key: String,
) -> Nil {
  bot.cancel_conversation_for(bot_subject: telega.bot_subject, key:)
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
pub fn shutdown(telega: Telega(session, error, dependencies)) -> Nil {
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
pub fn is_draining(telega: Telega(session, error, dependencies)) -> Bool {
  bot.is_draining(telega.bot_subject)
}

/// Get the supervisor PID for the running bot instance.
pub fn get_supervisor_pid(
  telega: Telega(session, error, dependencies),
) -> process.Pid {
  telega.supervisor_pid
}

const default_drain_timeout = 5000

/// Build the `Telega` value, run the `on_start` hook, and install signal
/// handlers if requested. Shared by both start modes.
fn finalize(
  builder builder: TelegaBuilder(session, error, dependencies, state),
  config config: Config,
  bot_info bot_info: User,
  bot_subject bot_subject: BotSubject,
  supervisor_pid supervisor_pid: process.Pid,
  poller poller: Option(process.Subject(polling.PollingMessage)),
  session_settings session_settings: SessionSettings(session, error),
) -> Result(Telega(session, error, dependencies), error.TelegaError) {
  let telega =
    Telega(
      config:,
      bot_info:,
      bot_subject:,
      supervisor_pid:,
      poller:,
      drain_timeout: option.unwrap(builder.drain_timeout, default_drain_timeout),
      on_shutdown: builder.on_shutdown,
      session_settings:,
      session_key: session_key(builder),
      session_load_error: builder.session_load_error,
      dependencies: builder.dependencies,
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
/// `with_allowed_updates`) always wins; otherwise, when `with_auto_allowed_updates`
/// is enabled, derive the set from the router. `None` means "do not restrict".
fn resolve_allowed_updates(
  builder: TelegaBuilder(session, error, dependencies, state),
) -> Option(List(String)) {
  case builder.allowed_updates {
    Some(_) as manual -> manual
    None ->
      case builder.auto_allowed_updates, builder.router {
        True, Some(routable) ->
          case routable.allowed_updates {
            // Derivation gave up on narrowing; adding extras would turn "send
            // everything" into a narrower list than the router can handle.
            [] -> None
            updates ->
              list.append(updates, builder.extra_allowed_updates)
              |> list.unique
              |> list.sort(string.compare)
              |> Some
          }
        _, _ -> None
      }
  }
}

/// Publish the router's described commands via `setMyCommands` when
/// `auto_commands` is enabled: a default-language call first, then one
/// `setMyCommands(language_code:)` per configured locale.
fn maybe_sync_commands(
  builder: TelegaBuilder(session, error, dependencies, state),
  config: Config,
) -> Result(Nil, error.TelegaError) {
  use <- bool.guard(!builder.auto_commands, Ok(Nil))

  case builder.router {
    None -> Ok(Nil)
    Some(routable) -> {
      let described = routable.registered_commands
      use <- bool.guard(described == [], Ok(Nil))

      let client = config.api_client
      let base_commands =
        list.map(described, fn(pair) {
          types.BotCommand(
            command: pair.0,
            description: pair.1,
            is_ephemeral: None,
          )
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
                types.BotCommand(
                  command: pair.0,
                  description:,
                  is_ephemeral: None,
                )
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

fn install_signal_handlers(
  telega: Telega(session, error, dependencies),
) -> Nil {
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

// Build the chat factory child spec from builder settings
fn build_chat_factory_spec(
  builder: TelegaBuilder(session, error, dependencies, state),
) {
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
  let name = process.new_name("telega_chat_factory")

  let spec =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.named(name)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.restart_tolerance(intensity, period)
    |> fsup.supervised

  #(spec, name)
}

// The lifetime and persistence knobs handed to every chat instance.
@internal
pub fn chat_settings(
  builder: TelegaBuilder(session, error, dependencies, state),
) -> bot.ChatSettings {
  let defaults = bot.default_chat_settings()
  bot.ChatSettings(
    idle_timeout: case builder.chat_idle_eviction {
      False -> None
      True ->
        Some(option.unwrap(
          builder.chat_idle_timeout,
          bot.default_chat_idle_timeout,
        ))
    },
    init_timeout: option.unwrap(
      builder.chat_init_timeout,
      defaults.init_timeout,
    ),
    media_group_timeout: builder.media_group_timeout,
    hibernate_after: case builder.chat_hibernation {
      False -> None
      True ->
        Some(option.unwrap(
          builder.chat_hibernate_after,
          bot.default_hibernate_after,
        ))
    },
    session_persistence: builder.session_persistence,
    session_key: session_key(builder),
    on_load_error: builder.session_load_error,
  )
}

// How an update maps to a session key, with the default filled in.
fn session_key(
  builder: TelegaBuilder(session, error, dependencies, state),
) -> fn(update.Update) -> String {
  option.unwrap(builder.session_key, bot.default_session_key)
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
