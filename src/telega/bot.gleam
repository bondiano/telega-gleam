//// Core bot actor and chat instance management.
////
//// This module implements the actor-based architecture for handling Telegram updates.
//// It contains the `Bot` actor (the central dispatcher) and `ChatInstance` actors
//// (one per unique `{chat_id}:{from_id}` combination).
////
//// ## Supervision tree
////
//// Both the `Bot` actor and `ChatInstance` actors run inside a supervision tree
//// created by `telega.start()` or `telega.start()`:
////
//// ```text
//// TelegaRootSupervisor (static_supervisor, OneForOne)
//// ├── ChatInstances (factory_supervisor, Transient children)
//// │   ├── ChatInstance {chat1:user1}
//// │   ├── ChatInstance {chat2:user2}
//// │   └── ...
//// ├── Bot actor (worker, Permanent)
//// └── Polling worker (worker, Permanent) — only for polling mode
//// ```
////
//// - The `Bot` actor is a `Permanent` worker — it always restarts on crash.
//// - `ChatInstance` actors are `Transient` — they restart only on abnormal exit,
////   not on normal shutdown. On restart a `ChatInstance` re-registers itself in
////   the ETS registry, overwriting the stale subject.
//// - The `Bot` creates new `ChatInstance` actors via `factory_supervisor.start_child`,
////   which ensures they are supervised from the moment they start.
////
//// ## Chat instance lifetime
////
//// A `ChatInstance` is started on the first update of a `{chat_id}:{from_id}`
//// pair and is evicted after half an hour of silence (`ChatSettings.idle_timeout`,
//// set with `telega.with_chat_idle_timeout` and lifted with
//// `telega.without_chat_idle_timeout`): an instance that has received nothing
//// for that long asks the `Bot` actor to evict it. The bot — the only process
//// that dispatches updates — deregisters the key first and only then tells the
//// instance to stop, so an update can never be delivered to an instance on its
//// way out. The next update simply starts a fresh instance that re-reads the
//// session from storage; only an in-memory conversation continuation is lost.
////
//// Long before that, an instance that has been quiet for `hibernate_after`
//// compacts itself: one full garbage collection shrinks its heap back to
//// roughly what a freshly started instance uses, so the memory a burst of
//// traffic left behind is not held for the rest of the idle window.
////
//// ## Handler pattern
////
//// All handlers follow this signature:
////
//// ```gleam
//// fn handler(ctx: Context(session, error, dependencies), data: Type) -> Result(Context(session, error, dependencies), error)
//// ```
////
//// Always return the updated context — it carries the (potentially modified) session.
////
//// ## Conversation API
////
//// The `wait_handler` function and the `Handler` type enable multi-message
//// conversations: the chat instance suspends its main handler and waits for a
//// specific update type. See `telega.wait_text`, `telega.wait_command`, etc.

import gleam/bool
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode.{type Decoder}
import gleam/erlang/process.{type Pid, type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/otp/actor
import gleam/otp/factory_supervisor as fsup
import gleam/regexp.{type Regexp}
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}

import telega/internal/config.{type Config}
import telega/internal/log
import telega/internal/registry.{type Registry}

import telega/client
import telega/error
import telega/model/types.{
  type Audio, type ChatMemberUpdated, type Message, type PhotoSize,
  type Update as RawUpdate, type User, type Video, type Voice, type WebAppData,
}
import telega/scope.{type Scope}
import telega/telemetry
import telega/update.{
  type Command, type Update, AudioUpdate, CallbackQueryUpdate, ChatMemberUpdate,
  CommandUpdate, MediaGroupUpdate, MessageUpdate, PhotoUpdate, TextUpdate,
  VideoUpdate, VoiceUpdate, WebAppUpdate,
}
import telega/webhook_reply.{type Envelope}

/// Stores information about running bot instance
pub opaque type Bot(session, error, dependencies) {
  Bot(
    self: BotSubject,
    config: Config,
    bot_info: User,
    catch_handler: CatchHandler(session, error, dependencies),
    session_settings: SessionSettings(session, error),
    // Non-persisted services/dependencies shared by every handler.
    dependencies: dependencies,
    // Store a handler function that encapsulates the router
    router_handler: RouterHandler(session, error, dependencies),
    // Global pre-router middleware, run once per update before any chat
    // instance is involved. Executed in order; first `Stop` short-circuits.
    pre_handlers: List(PreHandler(dependencies)),
    registry: Registry(ChatInstanceMessage(session, error, dependencies)),
    chat_factory: fsup.Supervisor(
      ChatInstanceArgs(session, error, dependencies),
      ChatInstanceSubject(session, error, dependencies),
    ),
    // --- Graceful lifecycle / drain ---
    // When `False`, new updates are rejected (replied with `False`) instead of
    // being dispatched — used during graceful drain.
    accepting: Bool,
    // Number of updates currently being handled by chat instances.
    in_flight: Int,
    // `True` once a drain has been requested.
    draining: Bool,
    // Number of in-flight updates captured when the drain started — reported
    // back to the drain caller as the "drained" count.
    drain_count: Int,
    // Subject to notify once the drain completes (in_flight reaches zero).
    drain_waiter: Option(Subject(Int)),
    // Chat instances this bot has dispatched to, keyed by their pid. Each entry
    // monitors the instance and remembers the callers still waiting on it, so a
    // crashed instance can be answered for and evicted from the registry rather
    // than leaving the poller (or a webhook request) blocked forever.
    instances: Dict(Pid, InstanceWatch),
    // Lifetime and persistence knobs handed to every chat instance.
    chat_settings: ChatSettings,
  )
}

/// A monitored chat instance and the update callers it has not answered yet.
type InstanceWatch {
  InstanceWatch(
    key: String,
    monitor: process.Monitor,
    /// Reply subjects of dispatched-but-unfinished updates, oldest first.
    pending: List(Subject(Bool)),
  )
}

/// Arguments for starting a chat instance via factory supervisor.
pub type ChatInstanceArgs(session, error, dependencies) {
  ChatInstanceArgs(
    key: String,
    config: Config,
    session_settings: SessionSettings(session, error),
    catch_handler: CatchHandler(session, error, dependencies),
    dependencies: dependencies,
    router_handler: RouterHandler(session, error, dependencies),
    bot_info: User,
    registry: Registry(ChatInstanceMessage(session, error, dependencies)),
    // Subject of the owning `Bot` actor, used to report update completion so
    // the bot can track in-flight work for graceful draining.
    bot_subject: BotSubject,
    settings: ChatSettings,
  )
}

/// How a chat instance is keyed, how long it lives, and how it writes its
/// session.
///
/// Built with `default_chat_settings` and overridden field by field; the
/// `telega` builder (`with_chat_idle_timeout`, `with_media_group_timeout`,
/// `with_session_persistence`, `with_session_key`, ...) is the usual way to
/// reach it.
pub type ChatSettings {
  /// - `idle_timeout` — how long (ms) an instance may sit idle before asking
  ///   the bot to stop it. `None` keeps every instance alive for the bot's
  ///   lifetime.
  /// - `init_timeout` — how long (ms) the initialiser, which loads the session
  ///   from storage, may take before the start counts as failed.
  /// - `media_group_timeout` — debounce (ms) for gathering the separate
  ///   messages of an album into one `MediaGroupUpdate`. `None` delivers them
  ///   one by one.
  /// - `hibernate_after` — how long (ms) an instance may sit idle before it
  ///   compacts its heap. `None` never compacts.
  /// - `session_persistence` — whether an unchanged session is written back.
  /// - `session_key` — the storage key (and chat instance identity) an update
  ///   maps to. Defaults to [`default_session_key`](#default_session_key).
  /// - `on_load_error` — what happens when the session cannot be read.
  ChatSettings(
    idle_timeout: Option(Int),
    init_timeout: Int,
    media_group_timeout: Option(Int),
    hibernate_after: Option(Int),
    session_persistence: SessionPersistence,
    session_key: fn(Update) -> String,
    on_load_error: SessionLoadError,
  )
}

/// What a chat instance does when `get_session` returns an `Error`.
///
/// A read that *failed* is not the same as "this user has no session yet", so
/// none of these are the `Ok(None)` path — that one always uses
/// `default_session()`.
pub type SessionLoadError {
  /// Refuse to start: the update is answered `False` and nothing is written.
  /// The default, because handling the update on a default session would let
  /// the first handler persist that default over the real, still-stored data.
  FailUpdate
  /// Start on `default_session()` and persist normally. Only safe when losing
  /// a session is cheaper than dropping the update — a cache, a counter.
  UseDefault
  /// Start on `default_session()` but never write: handlers run, every
  /// persist is skipped with a warning. The stored session survives a backend
  /// that is briefly unreadable, and the next update tries the read again.
  ReadOnly
}

/// Whether the session is written back after an update that did not change it.
pub type SessionPersistence {
  /// Skip `persist_session` when the handler returned the session it was given.
  /// A chat that only reads its session — most of them, most of the time —
  /// then costs no storage write at all.
  PersistOnChange
  /// Call `persist_session` after every handled update, changed or not. Pick
  /// this when writing has a side effect you rely on, such as refreshing an
  /// expiry or a "last seen" column.
  PersistAlways
}

/// Evict a chat instance after half an hour of silence, compact its heap after
/// a minute of it, and skip writing a session no handler changed.
pub fn default_chat_settings() -> ChatSettings {
  ChatSettings(
    idle_timeout: Some(default_chat_idle_timeout),
    init_timeout: default_chat_init_timeout,
    media_group_timeout: None,
    hibernate_after: Some(default_hibernate_after),
    session_persistence: PersistOnChange,
    session_key: default_session_key,
    on_load_error: FailUpdate,
  )
}

/// One process per `{chat_id}:{from_id}` adds up: a bot with a million users
/// that never evicts anything runs out of BEAM processes. Half an hour is far
/// longer than any conversation timeout a bot is likely to use, and a chat that
/// comes back simply starts a fresh instance from the stored session.
pub const default_chat_idle_timeout = 1_800_000

/// A minute of silence is long enough that the instance is unlikely to be in
/// the middle of anything, and short enough that the heap a burst grew is not
/// carried for the rest of the idle window.
pub const default_hibernate_after = 60_000

/// How long a chat instance may take to start, session load included.
pub const default_chat_init_timeout = 10_000

type RouterHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), Update) ->
    Result(Context(session, error, dependencies), error)

/// Limited context handed to pre-router middleware. A `PreHandler` runs once per
/// incoming update inside the `Bot` actor — *before* any chat instance is
/// spawned or session is loaded — so it only carries update-level data, not a
/// `session`. Use it for cross-cutting concerns that apply to every update:
/// anti-spam, analytics, and update deduplication (`telega/idempotency`).
pub type PreContext(dependencies) {
  PreContext(
    update: Update,
    config: Config,
    /// The same injected services available to handlers via `Context`.
    dependencies: dependencies,
    bot_info: User,
    /// What the pre-handlers before this one annotated the update with.
    annotations: Dict(String, Dynamic),
  )
}

/// Decision returned by a `PreHandler`: keep processing the update through the
/// router, or stop it here (drop it before routing).
pub type PreRouterResult {
  /// Continue to the next pre-router middleware and, eventually, the router,
  /// attaching `annotations` to this update.
  ///
  /// Annotations are merged into what earlier pre-handlers set (a repeated key
  /// takes the newer value) and reach every handler as `ctx.annotations`, read
  /// back with [`annotation`](#annotation). They live for one update and are
  /// never persisted — long-lived services belong in `dependencies`, per-user
  /// state in the session.
  ///
  /// Use [`proceed`](#proceed) when there is nothing to annotate.
  Continue(annotations: Dict(String, Dynamic))
  /// Stop processing this update. The webhook/poller is told the update was
  /// acknowledged (so Telegram does not retry it) but no handler runs.
  Stop
}

/// Continue without annotating the update — `Continue(dict.new())`.
pub fn proceed() -> PreRouterResult {
  Continue(dict.new())
}

/// Pre-router middleware: a single global pass over every update, run before
/// routing. Registered with `telega.use_pre_handler` and executed in the order
/// added; the first one that returns `Stop` short-circuits the rest and the
/// router. Because they run sequentially inside the single `Bot` actor,
/// read-then-write logic (e.g. dedup) is race-free across concurrent updates.
pub type PreHandler(dependencies) =
  fn(PreContext(dependencies)) -> PreRouterResult

pub type BotSubject =
  Subject(BotMessage)

pub opaque type BotMessage {
  CancelConversationBotMessage(key: String)
  // `reply_with` is a subject with `is_ok` field
  // It is used to notify the adapter that the update was handled successfully or not.
  // `envelope`, when present, lets the handler claim one API call for delivery
  // in the webhook HTTP response body (see `telega/webhook_reply`).
  HandleUpdateBotMessage(
    update: Update,
    reply_with: Subject(Bool),
    envelope: Option(Envelope),
  )
  // Sent by a chat instance once it finishes handling one update (success or
  // handled error). Used to keep the in-flight counter accurate for draining
  // and to forget the caller it has just answered.
  UpdateHandledBotMessage(pid: Pid)
  // A monitored chat instance exited. Any update it was still handling is
  // answered here — nothing else would ever answer it.
  ChatInstanceDownBotMessage(down: process.Down)
  // A chat instance has been idle for longer than the configured idle timeout
  // and asks to be stopped. The bot is the only process that dispatches to it,
  // so only the bot can decide that safely: it deregisters the key first and
  // then tells the instance to stop, which makes the eviction race-free.
  ChatInstanceIdleBotMessage(key: String, pid: Pid)
  // Begin a graceful drain: stop accepting new updates and reply on
  // `reply_with` with the number of drained updates once all in-flight work
  // completes.
  StartDrainBotMessage(reply_with: Subject(Int))
  // Query whether the bot is currently draining (used by webhook adapters to
  // return 503 and let Telegram retry).
  IsDrainingBotMessage(reply_with: Subject(Bool))
}

/// Handler called when an error occurs in handler
/// If handler returns `Error`, the bot will be stopped and the error will be logged
/// The default handler is `fn(_) -> Ok(Nil)`, which will do nothing if handler returns an error
pub type CatchHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), error) -> Result(Nil, error)

pub fn start(
  registry registry: Registry(ChatInstanceMessage(session, error, dependencies)),
  config config: Config,
  bot_info bot_info: User,
  router_handler router_handler: RouterHandler(session, error, dependencies),
  pre_handlers pre_handlers: List(PreHandler(dependencies)),
  session_settings session_settings: SessionSettings(session, error),
  catch_handler catch_handler: CatchHandler(session, error, dependencies),
  dependencies dependencies: dependencies,
  chat_factory chat_factory: fsup.Supervisor(
    ChatInstanceArgs(session, error, dependencies),
    ChatInstanceSubject(session, error, dependencies),
  ),
  chat_settings chat_settings: ChatSettings,
  name name: Option(process.Name(BotMessage)),
) -> actor.StartResult(BotSubject) {
  let builder =
    actor.new_with_initialiser(bot_init_timeout, fn(self) {
      // Chat instances are monitored, not linked: their `DOWN` messages arrive
      // as `ChatInstanceDownBotMessage` alongside the bot's own messages.
      let selector =
        process.new_selector()
        |> process.select(self)
        |> process.select_monitors(ChatInstanceDownBotMessage)

      Bot(
        self:,
        config:,
        bot_info:,
        catch_handler:,
        session_settings:,
        dependencies:,
        router_handler:,
        pre_handlers:,
        registry:,
        chat_factory:,
        accepting: True,
        in_flight: 0,
        draining: False,
        drain_count: 0,
        drain_waiter: None,
        instances: dict.new(),
        chat_settings:,
      )
      |> actor.initialised
      |> actor.selecting(selector)
      |> actor.returning(self)
      |> Ok
    })
    |> actor.on_message(bot_loop)

  let builder = case name {
    Some(n) -> actor.named(builder, n)
    None -> builder
  }

  actor.start(builder)
}

const bot_init_timeout = 1000

/// Stops waiting for any handler for specific key (chat_id)
pub fn cancel_conversation(
  bot bot: Bot(session, error, dependencies),
  key key: String,
) -> Nil {
  cancel_conversation_for(bot_subject: bot.self, key: key)
}

/// Drop the pending conversation continuation of one chat instance.
///
/// The instance itself keeps running (with its loaded session) — only the
/// suspended `wait_*` handler is forgotten, so the next update is routed
/// normally again. The registry is deliberately left alone: unregistering a
/// *live* instance would orphan the process and leak it forever.
pub fn cancel_conversation_for(
  bot_subject bot_subject: BotSubject,
  key key: String,
) -> Nil {
  actor.send(bot_subject, CancelConversationBotMessage(key: key))
}

/// Drop this chat's pending `wait_*` continuation from inside a handler.
///
/// The companion to commands reaching the router while a conversation waits:
/// this is how a `/cancel` route ends the conversation it interrupted. The
/// chat instance and its session are untouched — only the suspended handler is
/// forgotten, so the next update routes normally.
pub fn cancel_conversation_in(
  ctx ctx: Context(session, error, dependencies),
) -> Nil {
  actor.send(ctx.chat_subject, CancelContinuationChatInstanceMessage)
}

fn bot_loop(
  bot: Bot(session, error, dependencies),
  message: BotMessage,
) -> actor.Next(Bot(session, error, dependencies), BotMessage) {
  case message {
    HandleUpdateBotMessage(update:, reply_with:, envelope:) ->
      case bot.accepting {
        // Draining — reject new updates so the caller (polling worker or
        // webhook dispatch) knows the update was not handled.
        False -> {
          process.send(reply_with, False)
          actor.continue(bot)
        }
        True ->
          case run_pre_handlers(bot, update) {
            // A pre-router middleware dropped the update. Acknowledge it to the
            // caller (so Telegram does not retry) without spawning a chat
            // instance or touching the in-flight counter.
            Stop -> {
              process.send(reply_with, True)
              actor.continue(bot)
            }
            Continue(annotations) ->
              case
                handle_update_bot_message(
                  bot:,
                  update:,
                  reply_with:,
                  envelope:,
                  annotations:,
                )
              {
                Ok(bot) ->
                  actor.continue(Bot(..bot, in_flight: bot.in_flight + 1))
                Error(error) -> {
                  log.error_d("Failed to dispatch update: ", error)
                  // The update never reached an instance, so nothing else will
                  // ever answer the caller. One failed spawn (a storage outage,
                  // a hit process limit) must not take the whole bot down: the
                  // next update gets a fresh attempt.
                  process.send(reply_with, False)
                  actor.continue(bot)
                }
              }
          }
      }
    UpdateHandledBotMessage(pid:) ->
      Bot(..bot, instances: forget_answered(bot.instances, pid))
      |> settle_in_flight(finished: 1)
    ChatInstanceDownBotMessage(down:) -> handle_instance_down(bot, down)
    ChatInstanceIdleBotMessage(key:, pid:) ->
      handle_instance_idle(bot, key, pid)
    StartDrainBotMessage(reply_with:) -> {
      let bot =
        Bot(..bot, accepting: False, draining: True, drain_count: bot.in_flight)
      case bot.in_flight {
        0 -> {
          process.send(reply_with, 0)
          actor.continue(bot)
        }
        _ -> actor.continue(Bot(..bot, drain_waiter: Some(reply_with)))
      }
    }
    IsDrainingBotMessage(reply_with:) -> {
      process.send(reply_with, bot.draining)
      actor.continue(bot)
    }
    CancelConversationBotMessage(key:) -> {
      // Clear the continuation, keep the instance and its registration: an
      // unregistered but running instance would never receive another update
      // and would live on as a leaked process.
      case registry.get(bot.registry, key:) {
        Some(chat_subject) ->
          actor.send(chat_subject, CancelContinuationChatInstanceMessage)
        None -> Nil
      }
      actor.continue(bot)
    }
  }
}

/// Begin a graceful drain of the bot.
///
/// Stops accepting new updates and blocks until all in-flight updates finish or
/// `timeout` milliseconds elapse. Returns the number of updates that were
/// in-flight when the drain started, or `-1` if the timeout was reached before
/// draining completed.
pub fn drain(bot_subject bot_subject: BotSubject, timeout timeout: Int) -> Int {
  let reply = process.new_subject()
  process.send(bot_subject, StartDrainBotMessage(reply))
  case process.receive(reply, timeout) {
    Ok(count) -> count
    Error(_) -> -1
  }
}

/// Whether the bot is currently draining (no longer accepting new updates).
///
/// Webhook adapters use this to answer `503` so Telegram retries the update
/// after the deploy instead of dropping it.
pub fn is_draining(bot_subject bot_subject: BotSubject) -> Bool {
  let reply = process.new_subject()
  process.send(bot_subject, IsDrainingBotMessage(reply))
  case process.receive(reply, 1000) {
    Ok(draining) -> draining
    Error(_) -> False
  }
}

/// Run the global pre-router middleware chain. Returns `Stop` as soon as one
/// of them stops the update, otherwise `Continue`.
fn run_pre_handlers(
  bot: Bot(session, error, dependencies),
  update: Update,
) -> PreRouterResult {
  case bot.pre_handlers {
    [] -> Continue(dict.new())
    handlers -> do_run_pre_handlers(handlers, bot, update, dict.new())
  }
}

fn do_run_pre_handlers(
  handlers: List(PreHandler(dependencies)),
  bot: Bot(session, error, dependencies),
  update: Update,
  annotations: Dict(String, Dynamic),
) -> PreRouterResult {
  case handlers {
    [] -> Continue(annotations)
    [handler, ..rest] -> {
      let pre_ctx =
        PreContext(
          update:,
          config: bot.config,
          dependencies: bot.dependencies,
          bot_info: bot.bot_info,
          annotations:,
        )
      case handler(pre_ctx) {
        Stop -> Stop
        Continue(added) ->
          do_run_pre_handlers(rest, bot, update, dict.merge(annotations, added))
      }
    }
  }
}

/// One update finished: forget the caller the instance has just answered.
fn forget_answered(
  instances: Dict(Pid, InstanceWatch),
  pid: Pid,
) -> Dict(Pid, InstanceWatch) {
  case dict.get(instances, pid) {
    Ok(InstanceWatch(pending: [_answered, ..rest], ..) as watch) ->
      dict.insert(instances, pid, InstanceWatch(..watch, pending: rest))
    _ -> instances
  }
}

/// Account for `finished` updates leaving the in-flight set, completing a
/// pending drain once nothing is left.
fn settle_in_flight(
  bot: Bot(session, error, dependencies),
  finished finished: Int,
) -> actor.Next(Bot(session, error, dependencies), BotMessage) {
  let in_flight = int.max(0, bot.in_flight - finished)
  case bot.draining && in_flight == 0 {
    True -> {
      case bot.drain_waiter {
        Some(waiter) -> process.send(waiter, bot.drain_count)
        None -> Nil
      }
      actor.continue(Bot(..bot, in_flight: 0, drain_waiter: None))
    }
    False -> actor.continue(Bot(..bot, in_flight:))
  }
}

/// A chat instance exited — through a crash, or through its own `actor.stop`.
///
/// Whatever it was still handling will never be answered by anyone else, so the
/// bot answers for it, and drops the instance from the registry unless a
/// restarted one has already claimed the key.
fn handle_instance_down(
  bot: Bot(session, error, dependencies),
  down: process.Down,
) -> actor.Next(Bot(session, error, dependencies), BotMessage) {
  case down {
    process.ProcessDown(pid:, ..) ->
      case dict.get(bot.instances, pid) {
        Error(Nil) -> actor.continue(bot)
        Ok(watch) -> {
          list.each(watch.pending, process.send(_, False))
          registry.unregister_owned_by(bot.registry, key: watch.key, pid:)
          telemetry.execute(
            ["telega", "chat_instance", "down"],
            [#("unanswered", list.length(watch.pending))],
            [#("key", telemetry.StringValue(watch.key))],
          )
          Bot(..bot, instances: dict.delete(bot.instances, pid))
          |> settle_in_flight(finished: list.length(watch.pending))
        }
      }
    process.PortDown(..) -> actor.continue(bot)
  }
}

/// A chat instance reports it has been idle for the configured timeout.
///
/// Only the bot dispatches updates, and it does so from this very actor, so
/// deciding here is race-free: an update that was already sent to the instance
/// is still listed in its `pending` set (its ack has not come back yet), and
/// an update that arrives later can no longer reach the instance because the
/// registry entry is gone by then — it spawns a fresh instance instead.
fn handle_instance_idle(
  bot: Bot(session, error, dependencies),
  key: String,
  pid: Pid,
) -> actor.Next(Bot(session, error, dependencies), BotMessage) {
  let busy = case dict.get(bot.instances, pid) {
    Ok(InstanceWatch(pending: [_, ..], ..)) -> True
    _ -> False
  }
  use <- bool.guard(when: busy, return: actor.continue(bot))

  case registry.get(bot.registry, key:) {
    Some(chat_subject) ->
      case process.subject_owner(chat_subject) {
        Ok(owner) if owner == pid -> {
          registry.unregister_owned_by(bot.registry, key:, pid:)
          actor.send(chat_subject, ShutdownChatInstanceMessage)
        }
        // The key belongs to a different (restarted) instance now — leave it.
        _ -> Nil
      }
    None -> Nil
  }
  actor.continue(bot)
}

/// Start monitoring the instance (once) and remember the caller waiting on it.
fn watch_instance(
  bot: Bot(session, error, dependencies),
  key key: String,
  chat_subject chat_subject: ChatInstanceSubject(session, error, dependencies),
  reply_with reply_with: Subject(Bool),
) -> Bot(session, error, dependencies) {
  case process.subject_owner(chat_subject) {
    Error(Nil) -> bot
    Ok(pid) -> {
      let watch = case dict.get(bot.instances, pid) {
        Ok(watch) ->
          InstanceWatch(
            ..watch,
            pending: list.append(watch.pending, [reply_with]),
          )
        Error(Nil) ->
          InstanceWatch(key:, monitor: process.monitor(pid), pending: [
            reply_with,
          ])
      }
      Bot(..bot, instances: dict.insert(bot.instances, pid, watch))
    }
  }
}

fn handle_update_bot_message(
  bot bot: Bot(session, error, dependencies),
  update update,
  reply_with reply_with,
  envelope envelope,
  annotations annotations,
) -> Result(Bot(session, error, dependencies), error.TelegaError) {
  let key = bot.chat_settings.session_key(update)

  use chat_subject <- result.try(case registry.get(bot.registry, key:) {
    Some(chat_subject) -> Ok(chat_subject)
    None -> {
      telemetry.execute(["telega", "chat_instance", "spawn"], [#("count", 1)], [
        #("chat_id", telemetry.IntValue(update.chat_id)),
        #("from_id", telemetry.IntValue(update.from_id)),
      ])
      let args =
        ChatInstanceArgs(
          key:,
          config: bot.config,
          session_settings: bot.session_settings,
          catch_handler: bot.catch_handler,
          dependencies: bot.dependencies,
          router_handler: bot.router_handler,
          bot_info: bot.bot_info,
          registry: bot.registry,
          bot_subject: bot.self,
          settings: bot.chat_settings,
        )
      // No need to register here — start_chat_instance self-registers
      fsup.start_child(bot.chat_factory, args)
      |> result.map(fn(started) { started.data })
      |> result.map_error(error.ChatInstanceStartError)
    }
  })

  actor.send(
    chat_subject,
    HandleNewChatInstanceMessage(update:, reply_with:, envelope:, annotations:),
  )
  Ok(watch_instance(bot, key:, chat_subject:, reply_with:))
}

// Chat Instance --------------------------------------------------------------------

pub type ChatInstanceSubject(session, error, dependencies) =
  Subject(ChatInstanceMessage(session, error, dependencies))

pub opaque type ChatInstanceMessage(session, error, dependencies) {
  HandleNewChatInstanceMessage(
    update: Update,
    reply_with: Subject(Bool),
    envelope: Option(Envelope),
    /// What the pre-router middleware attached to this update.
    annotations: Dict(String, Dynamic),
  )
  WaitHandlerChatInstanceMessage(
    handler: Handler(session, error, dependencies),
    handle_else: Option(Handler(session, error, dependencies)),
    timeout: Option(Int),
  )
  /// Forget the suspended `wait_*` handler, keep serving updates.
  CancelContinuationChatInstanceMessage
  /// Self-sent tick that checks how long this instance has been idle.
  IdleCheckChatInstanceMessage
  /// Self-sent once an album has stopped growing: route what was gathered.
  FlushMediaGroupChatInstanceMessage(media_group_id: String, epoch: Int)
  /// Sent by the bot once it has deregistered this instance: stop for good.
  ShutdownChatInstanceMessage
}

type Continuation(session, error, dependencies) {
  Continuation(
    handler: Handler(session, error, dependencies),
    handle_else: Option(Handler(session, error, dependencies)),
    ttl: Option(Timestamp),
  )
}

type ChatInstance(session, error, dependencies) {
  ChatInstance(
    key: String,
    session: session,
    dependencies: dependencies,
    config: Config,
    session_settings: SessionSettings(session, error),
    self: ChatInstanceSubject(session, error, dependencies),
    continuation: Option(Continuation(session, error, dependencies)),
    router_handler: RouterHandler(session, error, dependencies),
    catch_handler: CatchHandler(session, error, dependencies),
    bot_info: User,
    // Subject of the owning `Bot` actor, notified when an update completes.
    bot_subject: BotSubject,
    // The registry this instance registered itself in, so it can deregister
    // when it stops for good.
    registry: Registry(ChatInstanceMessage(session, error, dependencies)),
    settings: ChatSettings,
    // When this instance last received a message of its own.
    last_activity: Timestamp,
    // Whether the heap has already been compacted since that last message, so
    // a long silence pays for one collection rather than one per idle tick.
    compacted: Bool,
    // Whether an idle tick is already on its way. Exactly one is ever alive:
    // the tick re-arms itself while there is still something to wait for, and
    // the next update re-arms it once there is not.
    tick_armed: Bool,
    // Albums still being gathered, keyed by `media_group_id`.
    media_groups: Dict(String, MediaGroupBuffer),
    // Set when the session could not be read and `ReadOnly` was chosen: the
    // instance serves updates off the default session and writes nothing.
    read_only: Bool,
    // Set when a write failed: the session in memory is ahead of storage, so
    // the next update writes it again even if no handler changed it.
    dirty: Bool,
  )
}

/// The messages of one album gathered so far, newest first.
type MediaGroupBuffer {
  MediaGroupBuffer(
    from_id: Int,
    chat_id: Int,
    messages: List(Message),
    raw: RawUpdate,
    // Bumped by every added message so an earlier flush timer is ignored.
    epoch: Int,
  )
}

/// Start a chat instance. Used as the template function for factory_supervisor.
/// Self-registers in the registry on start (handles both first start and restart after crash).
///
/// The session is loaded **inside** the initialiser, so it runs in the instance
/// process: a slow storage backend delays only this chat, and a crash there
/// fails this one start instead of taking the factory supervisor — and every
/// other chat instance with it — down.
pub fn start_chat_instance(
  args: ChatInstanceArgs(session, error, dependencies),
) -> actor.StartResult(ChatInstanceSubject(session, error, dependencies)) {
  actor.new_with_initialiser(args.settings.init_timeout, fn(subject) {
    // A read that *failed* is not the same as "this user has no session yet":
    // starting on a default here would let the first handler persist it over
    // the real, still-stored data. What happens instead is
    // `settings.on_load_error`'s call — by default the start fails, the update
    // is answered `False`, and the next one gets a fresh attempt.
    use #(session, read_only) <- result.try(
      case args.session_settings.get_session(args.key) {
        Ok(Some(session)) -> Ok(#(session, False))
        Ok(None) -> Ok(#(args.session_settings.default_session(), False))
        Error(error) -> {
          let reason =
            "Failed to get session for key "
            <> args.key
            <> ": "
            <> string.inspect(error)
          case args.settings.on_load_error {
            FailUpdate -> {
              log.error(reason)
              Error(reason)
            }
            UseDefault -> {
              log.error(reason <> " — starting on the default session")
              report_load_error(args.key, "use_default")
              Ok(#(args.session_settings.default_session(), False))
            }
            ReadOnly -> {
              log.error(reason <> " — starting read-only, writes are skipped")
              report_load_error(args.key, "read_only")
              Ok(#(args.session_settings.default_session(), True))
            }
          }
        }
      },
    )

    let chat_instance =
      ChatInstance(
        key: args.key,
        config: args.config,
        session:,
        dependencies: args.dependencies,
        session_settings: args.session_settings,
        catch_handler: args.catch_handler,
        self: subject,
        continuation: None,
        router_handler: args.router_handler,
        bot_info: args.bot_info,
        bot_subject: args.bot_subject,
        registry: args.registry,
        settings: args.settings,
        last_activity: timestamp.system_time(),
        compacted: False,
        tick_armed: False,
        media_groups: dict.new(),
        read_only:,
        dirty: False,
      )
    // Self-register in registry (overwrites stale Subject on restart)
    registry.register(args.registry, key: args.key, subject:)
    actor.initialised(arm_tick(chat_instance))
    |> actor.returning(subject)
    |> Ok
  })
  |> actor.on_message(loop_chat_instance)
  |> actor.start
}

fn loop_chat_instance(
  chat: ChatInstance(session, error, dependencies),
  message,
) {
  case message {
    HandleNewChatInstanceMessage(update:, reply_with:, envelope:, annotations:) -> {
      let chat = touch(chat)
      case media_group_part(chat, update) {
        Some(#(media_group_id, message)) ->
          buffer_media_group(chat, media_group_id, message, update, reply_with)
        None ->
          do_handle_new_chat_instance_message(
            context: new_context_with_envelope(
              chat:,
              update:,
              envelope:,
              annotations:,
            ),
            chat:,
            update:,
            reply_with:,
          )
      }
    }
    FlushMediaGroupChatInstanceMessage(media_group_id:, epoch:) ->
      flush_media_group(chat, media_group_id, epoch)
    WaitHandlerChatInstanceMessage(handler:, handle_else:, timeout:) ->
      ChatInstance(
        ..touch(chat),
        continuation: Continuation(handler:, handle_else:, ttl: {
            use timeout <- option.map(timeout)
            timestamp.system_time()
            |> timestamp.add(duration.milliseconds(timeout))
          })
          |> Some,
      )
      |> actor.continue
    CancelContinuationChatInstanceMessage ->
      ChatInstance(..touch(chat), continuation: None)
      |> actor.continue
    IdleCheckChatInstanceMessage -> handle_idle_check(chat)
    ShutdownChatInstanceMessage -> {
      telemetry.execute(
        ["telega", "chat_instance", "terminate"],
        [#("count", 1)],
        [
          #("key", telemetry.StringValue(chat.key)),
          #("reason", telemetry.StringValue("idle_timeout")),
        ],
      )
      actor.stop()
    }
  }
}

/// Remember that the instance is doing something right now, so both the idle
/// clock and the heap-compaction clock start over — and the tick that watches
/// them comes back if it had run out of things to wait for.
fn touch(
  chat: ChatInstance(session, error, dependencies),
) -> ChatInstance(session, error, dependencies) {
  case chat.settings.idle_timeout, chat.settings.hibernate_after {
    None, None -> chat
    _, _ ->
      ChatInstance(
        ..chat,
        last_activity: timestamp.system_time(),
        compacted: False,
      )
      |> arm_tick
  }
}

/// Arm the next idle tick, unless one is already on its way or there is
/// nothing left to wait for.
fn arm_tick(
  chat: ChatInstance(session, error, dependencies),
) -> ChatInstance(session, error, dependencies) {
  use <- bool.guard(when: chat.tick_armed, return: chat)

  case next_idle_check(chat.settings, idle_for(chat), chat.compacted) {
    None -> chat
    Some(delay) -> {
      let _ =
        process.send_after(
          chat.self,
          int.max(delay, 1),
          IdleCheckChatInstanceMessage,
        )
      ChatInstance(..chat, tick_armed: True)
    }
  }
}

/// When the next idle tick should fire, given how long the instance has been
/// quiet and whether it has already compacted.
///
/// Compaction happens once per quiet spell, so once it has there is nothing
/// left to wait for on that side. Eviction, on the other hand, has to be asked
/// for again — the bot declines while an update is still in flight to the
/// instance — but a whole timeout later rather than on every tick.
///
/// `None` means there is nothing to wait for at all; the tick stops until the
/// next update re-arms it (see `touch`).
fn next_idle_check(
  settings: ChatSettings,
  idle_for: Int,
  compacted: Bool,
) -> Option(Int) {
  let deadlines =
    [
      case settings.hibernate_after {
        Some(after) if !compacted && after > idle_for -> Some(after - idle_for)
        // Due, but this tick could not do it (an album is still being
        // gathered): come back a whole period later rather than every
        // millisecond until it can.
        Some(after) if !compacted -> Some(after)
        _ -> None
      },
      case settings.idle_timeout {
        Some(timeout) if timeout > idle_for -> Some(timeout - idle_for)
        Some(timeout) -> Some(timeout)
        None -> None
      },
    ]
    |> list.filter_map(option.to_result(_, Nil))

  case deadlines {
    [] -> None
    [first, ..rest] -> Some(list.fold(rest, first, int.min))
  }
}

/// Give the heap back after a quiet spell.
///
/// A chat instance that handled a burst keeps the heap that burst grew for as
/// long as it lives. `erlang:garbage_collect/0` does a full sweep and shrinks
/// it back to about what a freshly started instance uses. (BEAM's `hibernate`
/// proper cannot be reached from inside a `gleam_otp` actor callback — it never
/// returns to the loop — but the heap reclamation is the part that matters
/// here, and this is the same collection hibernation would run.)
fn hibernate(
  chat: ChatInstance(session, error, dependencies),
) -> ChatInstance(session, error, dependencies) {
  garbage_collect()
  telemetry.execute(["telega", "chat_instance", "hibernate"], [#("count", 1)], [
    #("key", telemetry.StringValue(chat.key)),
  ])
  ChatInstance(..chat, compacted: True)
}

@external(erlang, "erlang", "garbage_collect")
fn garbage_collect() -> Bool

/// How long the instance has been doing nothing, in milliseconds.
fn idle_for(chat: ChatInstance(session, error, dependencies)) -> Int {
  timestamp.difference(chat.last_activity, timestamp.system_time())
  |> duration.to_milliseconds
}

/// The idle tick fired: either ask the bot to evict this instance, or re-arm
/// the tick for the time that is still left.
///
/// The instance never stops on its own — an update could already be on its way
/// to it. It asks the bot, which owns both the registry and the dispatch, and
/// stops only when the bot answers with `ShutdownChatInstanceMessage`.
fn handle_idle_check(chat: ChatInstance(session, error, dependencies)) {
  let chat = ChatInstance(..chat, tick_armed: False)
  let idle_for = idle_for(chat)

  // An album still being gathered is work in progress, however quiet the chat
  // looks: neither evict nor compact until it has been flushed.
  use <- bool.guard(when: !dict.is_empty(chat.media_groups), return: {
    actor.continue(arm_tick(chat))
  })

  let chat = case chat.settings.hibernate_after {
    Some(after) if !chat.compacted && idle_for >= after -> hibernate(chat)
    _ -> chat
  }

  case chat.settings.idle_timeout {
    Some(timeout) if idle_for >= timeout ->
      process.send(
        chat.bot_subject,
        ChatInstanceIdleBotMessage(key: chat.key, pid: process.self()),
      )
    _ -> Nil
  }

  actor.continue(arm_tick(chat))
}

/// The album this update belongs to, when albums are being gathered at all.
///
/// Telegram sends an album as separate messages sharing one `media_group_id`;
/// aggregation is opt-in (`telega.with_media_group_timeout`) because without it
/// each message keeps arriving on its own `on_photo`/`on_video` route.
fn media_group_part(
  chat: ChatInstance(session, error, dependencies),
  update: Update,
) -> Option(#(String, Message)) {
  use <- bool.guard(
    when: chat.settings.media_group_timeout == None,
    return: None,
  )
  // An album that arrives mid-conversation is left alone: the waiting handler
  // is expecting the individual messages.
  use <- bool.guard(when: chat.continuation != None, return: None)

  let message = case update {
    PhotoUpdate(message:, ..)
    | VideoUpdate(message:, ..)
    | AudioUpdate(message:, ..)
    | VoiceUpdate(message:, ..)
    | MessageUpdate(message:, ..) -> Some(message)
    _ -> None
  }

  case message {
    Some(message) ->
      case message.media_group_id {
        Some(id) -> Some(#(id, message))
        None -> None
      }
    None -> None
  }
}

/// Hold on to one message of an album and (re)arm its flush timer.
///
/// The caller is answered right away: the update has been taken care of, and
/// making a webhook request wait out the debounce would be worse than useless.
fn buffer_media_group(
  chat: ChatInstance(session, error, dependencies),
  media_group_id: String,
  message: Message,
  source: Update,
  reply_with: Subject(Bool),
) -> actor.Next(
  ChatInstance(session, error, dependencies),
  ChatInstanceMessage(session, error, dependencies),
) {
  ack(chat, reply_with, True)

  let buffer = case dict.get(chat.media_groups, media_group_id) {
    Ok(existing) ->
      MediaGroupBuffer(
        ..existing,
        messages: [message, ..existing.messages],
        epoch: existing.epoch + 1,
      )
    Error(Nil) ->
      MediaGroupBuffer(
        from_id: source.from_id,
        chat_id: source.chat_id,
        messages: [message],
        raw: update.raw(source),
        epoch: 0,
      )
  }

  case chat.settings.media_group_timeout {
    Some(timeout) -> {
      process.send_after(
        chat.self,
        timeout,
        FlushMediaGroupChatInstanceMessage(media_group_id:, epoch: buffer.epoch),
      )
      Nil
    }
    None -> Nil
  }

  ChatInstance(
    ..chat,
    media_groups: dict.insert(chat.media_groups, media_group_id, buffer),
  )
  |> actor.continue
}

/// Route what was gathered as a single `MediaGroupUpdate`.
///
/// Each buffered message was already answered when it arrived, so this path
/// does not answer again — it only routes.
fn flush_media_group(
  chat: ChatInstance(session, error, dependencies),
  media_group_id: String,
  epoch: Int,
) -> actor.Next(
  ChatInstance(session, error, dependencies),
  ChatInstanceMessage(session, error, dependencies),
) {
  case dict.get(chat.media_groups, media_group_id) {
    // A later message reset the timer, or the album was already flushed.
    Error(Nil) -> actor.continue(chat)
    Ok(buffer) ->
      case buffer.epoch == epoch {
        False -> actor.continue(chat)
        True -> {
          let chat =
            ChatInstance(
              ..chat,
              media_groups: dict.delete(chat.media_groups, media_group_id),
            )
          let update =
            MediaGroupUpdate(
              from_id: buffer.from_id,
              chat_id: buffer.chat_id,
              media_group_id:,
              messages: list.reverse(buffer.messages),
              raw: buffer.raw,
            )
          do_handle_update(
            // The album was assembled from several updates over the debounce
            // window; there is no single set of annotations to carry over.
            context: new_context(chat:, update:, annotations: dict.new()),
            chat:,
            update:,
            ack_with: fn(_settled) { Nil },
          )
        }
      }
  }
}

fn do_handle_new_chat_instance_message(
  context context: Context(session, error, dependencies),
  chat chat: ChatInstance(session, error, dependencies),
  update update,
  reply_with reply_with,
) {
  do_handle_update(context:, chat:, update:, ack_with: ack(chat, reply_with, _))
}

/// The routing path, with the way this update is answered left to the caller:
/// an album's messages are answered as they are buffered, so the aggregated
/// update they turn into must not answer for them a second time.
///
/// The update's [`Scope`](scope.html) is dropped on the way out — a chat
/// instance outlives thousands of updates, so each one's scratch space has to
/// go with it.
fn do_handle_update(
  context context: Context(session, error, dependencies),
  chat chat: ChatInstance(session, error, dependencies),
  update update,
  ack_with ack_with: fn(Bool) -> Nil,
) {
  let next = route_update(context:, chat:, update:, ack_with:)
  scope.clear(context.scope)
  next
}

fn route_update(
  context context: Context(session, error, dependencies),
  chat chat: ChatInstance(session, error, dependencies),
  update update,
  ack_with ack_with: fn(Bool) -> Nil,
) {
  case chat.continuation {
    // There is a continuation, handle the update with it
    Some(continuation) ->
      case continuation.ttl {
        Some(ttl) -> {
          case timestamp.compare(ttl, timestamp.system_time()) {
            // When ttl is expired, handle update without continuation
            order.Lt ->
              route_update(
                context:,
                chat: ChatInstance(..chat, continuation: None),
                update:,
                ack_with:,
              )
            _ ->
              do_handle_continuation(
                context:,
                continuation:,
                update:,
                ack_with:,
                chat:,
              )
          }
        }
        None ->
          do_handle_continuation(
            context:,
            continuation:,
            update:,
            ack_with:,
            chat:,
          )
      }
    None ->
      case
        telemetry.span(
          event: ["telega", "update"],
          metadata: update_telemetry_metadata(update),
          run: fn() { chat.router_handler(context, update) },
        )
      {
        Ok(Context(session: new_session, ..)) ->
          persist_and_continue(
            chat:,
            context:,
            session: new_session,
            clear_continuation: False,
            ack_with:,
            failure_label: "Error in session persistence: ",
          )
        Error(e) -> {
          case chat.catch_handler(context, e) {
            Ok(_) -> {
              ack_with(False)
              actor.continue(chat)
            }
            Error(e) -> {
              log.error_d("Error in catch handler: ", e)
              stop_chat_instance(chat, ack_with, "catch_handler_failed")
            }
          }
        }
      }
  }
}

fn update_telemetry_metadata(upd: Update) -> List(#(String, telemetry.Value)) {
  [
    #("update_type", telemetry.StringValue(update.type_to_string(upd))),
    #("chat_id", telemetry.IntValue(upd.chat_id)),
    #("from_id", telemetry.IntValue(upd.from_id)),
  ]
}

/// Write the session back, answer the update, and carry on.
///
/// The write is the one thing every handled-update path has in common, and the
/// only one that can fail after the handler has already succeeded: a storage
/// error goes to the bot's catch handler, and an instance whose catch handler
/// fails too is given up on.
fn persist_and_continue(
  chat chat: ChatInstance(session, error, dependencies),
  context context: Context(session, error, dependencies),
  session new_session: session,
  clear_continuation clear_continuation: Bool,
  ack_with ack_with: fn(Bool) -> Nil,
  failure_label failure_label: String,
) {
  case persist_session(chat, new_session) {
    Ok(session) -> {
      ack_with(True)
      let chat = ChatInstance(..chat, session:, dirty: False)
      actor.continue(case clear_continuation {
        True -> ChatInstance(..chat, continuation: None)
        False -> chat
      })
    }
    Error(e) ->
      // Keep the handler's session in memory and remember that storage is
      // behind it: the update is reported as failed, but the next one retries
      // the write instead of silently reverting the change.
      case chat.catch_handler(context, e) {
        Ok(_) -> {
          ack_with(False)
          actor.continue(
            ChatInstance(..chat, session: new_session, dirty: True),
          )
        }
        Error(e) -> {
          log.error_d(failure_label, e)
          stop_chat_instance(chat, ack_with, "session_persist_failed")
        }
      }
  }
}

/// Store the session, unless it is the one the handler was given and the bot
/// was not asked to write those back too.
///
/// Most updates read the session without changing it, so under the default
/// `PersistOnChange` most of them cost no storage write at all. Skipping is
/// safe because the value is unchanged by definition — what is in storage is
/// already what would be written.
fn persist_session(
  chat: ChatInstance(session, error, dependencies),
  new_session: session,
) -> Result(session, error) {
  // `bool.guard` would evaluate the warning eagerly — this branch has to be
  // lazy, not just short.
  use <- guard_read_only(chat, new_session)
  case chat.settings.session_persistence {
    PersistAlways ->
      chat.session_settings.persist_session(chat.key, new_session)
    PersistOnChange ->
      // `dirty` means storage is behind what is in memory: the last write
      // failed, so this one goes out even though nothing changed since.
      case !chat.dirty && new_session == chat.session {
        True -> Ok(new_session)
        False -> chat.session_settings.persist_session(chat.key, new_session)
      }
  }
}

fn guard_read_only(
  chat: ChatInstance(session, error, dependencies),
  new_session: session,
  write: fn() -> Result(session, error),
) -> Result(session, error) {
  case chat.read_only {
    False -> write()
    True -> {
      log.warning(
        "[session] skipping the write for key "
        <> chat.key
        <> ": this instance is read-only because its session could not be read",
      )
      Ok(new_session)
    }
  }
}

fn report_load_error(key: String, policy: String) -> Nil {
  telemetry.execute(["telega", "session", "load_error"], [#("count", 1)], [
    #("key", telemetry.StringValue(key)),
    #("policy", telemetry.StringValue(policy)),
  ])
}

/// Give up on this chat instance.
///
/// The update in flight is answered (`False`) before stopping: the caller is
/// blocked on that reply and nothing else would ever send it. The registry
/// entry goes too — the instance stops *normally*, so its `Transient`
/// supervisor will not restart it, and a stale entry would silently swallow
/// every later update for this chat.
fn stop_chat_instance(
  chat: ChatInstance(session, error, dependencies),
  ack_with: fn(Bool) -> Nil,
  reason: String,
) {
  ack_with(False)
  registry.unregister(chat.registry, key: chat.key)
  telemetry.execute(["telega", "chat_instance", "terminate"], [#("count", 1)], [
    #("key", telemetry.StringValue(chat.key)),
    #("reason", telemetry.StringValue(reason)),
  ])
  actor.stop()
}

/// Reply to the update's caller and notify the owning bot that one in-flight
/// update has finished, so the in-flight counter stays accurate for draining.
fn ack(
  chat: ChatInstance(session, error, dependencies),
  reply_with: Subject(Bool),
  value: Bool,
) -> Nil {
  process.send(reply_with, value)
  process.send(chat.bot_subject, UpdateHandledBotMessage(process.self()))
}

fn do_handle_continuation(
  context context: Context(session, error, dependencies),
  continuation continuation: Continuation(session, error, dependencies),
  update update: Update,
  ack_with ack_with: fn(Bool) -> Nil,
  chat chat: ChatInstance(session, error, dependencies),
) {
  case
    do_handle_with_telemetry(context:, update:, handler: continuation.handler)
  {
    Some(Ok(Context(session: new_session, ..))) ->
      // Persist the new session after continuation completes
      persist_and_continue(
        chat:,
        context:,
        session: new_session,
        clear_continuation: True,
        ack_with:,
        failure_label: "Error in session persistence after continuation: ",
      )
    Some(Error(e)) -> {
      case chat.catch_handler(context, e) {
        Ok(_) -> {
          ack_with(False)
          actor.continue(chat)
        }
        Error(e) -> {
          log.error_d("Error in catch handler: ", e)
          stop_chat_instance(chat, ack_with, "catch_handler_failed")
        }
      }
    }
    None -> {
      case continuation.handle_else {
        Some(handler) ->
          case do_handle(context:, update:, handler:) {
            Some(Ok(Context(session: new_session, ..))) ->
              persist_and_continue(
                chat:,
                context:,
                session: new_session,
                clear_continuation: False,
                ack_with:,
                failure_label: "Error in session persistence after handle_else: ",
              )
            Some(Error(e)) -> {
              case chat.catch_handler(context, e) {
                Ok(_) -> {
                  ack_with(False)
                  actor.continue(chat)
                }
                Error(e) -> {
                  log.error_d("Error in catch else handler: ", e)
                  stop_chat_instance(chat, ack_with, "catch_handler_failed")
                }
              }
            }
            None -> unmatched_while_waiting(context:, update:, chat:, ack_with:)
          }
        None -> unmatched_while_waiting(context:, update:, chat:, ack_with:)
      }
    }
  }
}

/// Nothing in the pending conversation wanted this update.
///
/// A command still belongs to the router: swallowing it would leave `/cancel`
/// (and every other registered command) dead for as long as a `wait_*` is
/// armed, which is exactly how a user gets stuck in a conversation. The
/// continuation stays armed — a command handler that means to end it calls
/// `cancel_conversation_in`.
///
/// Anything else is the conversation's business and keeps waiting.
fn unmatched_while_waiting(
  context context: Context(session, error, dependencies),
  update update: Update,
  chat chat: ChatInstance(session, error, dependencies),
  ack_with ack_with: fn(Bool) -> Nil,
) {
  case update {
    CommandUpdate(..) ->
      case
        telemetry.span(
          event: ["telega", "update"],
          metadata: update_telemetry_metadata(update),
          run: fn() { chat.router_handler(context, update) },
        )
      {
        Ok(Context(session: new_session, ..)) ->
          persist_and_continue(
            chat:,
            context:,
            session: new_session,
            clear_continuation: False,
            ack_with:,
            failure_label: "Error in session persistence: ",
          )
        Error(e) -> handle_handler_error(chat, context, e, ack_with)
      }
    _ -> {
      ack_with(False)
      actor.continue(chat)
    }
  }
}

/// Give the bot's catch handler a chance; stop the instance if that fails too.
fn handle_handler_error(
  chat: ChatInstance(session, error, dependencies),
  context: Context(session, error, dependencies),
  error: error,
  ack_with: fn(Bool) -> Nil,
) {
  case chat.catch_handler(context, error) {
    Ok(_) -> {
      ack_with(False)
      actor.continue(chat)
    }
    Error(e) -> {
      log.error_d("Error in catch handler: ", e)
      stop_chat_instance(chat, ack_with, "catch_handler_failed")
    }
  }
}

// Context ----------------------------------------------------------------------------

/// Context holds information needed for the bot instance and the current update.
pub type Context(session, error, dependencies) {
  Context(
    key: String,
    update: Update,
    config: Config,
    session: session,
    /// Non-persisted services/dependencies injected at bot init (DI container).
    /// Unlike `session`, `dependencies` is never persisted — it holds things like a db
    /// pool, http client, or i18n catalog. See `telega.with_dependencies`.
    dependencies: dependencies,
    chat_subject: ChatInstanceSubject(session, error, dependencies),
    /// Used to calculate the duration of the conversation in logs
    start_time: Option(Timestamp),
    log_prefix: Option(String),
    bot_info: User,
    /// What the pre-router middleware attached to *this* update, read back
    /// with [`annotation`](#annotation). Scoped to one update and never
    /// persisted — unlike `dependencies` (services) and `session` (per-user
    /// state).
    annotations: Dict(String, Dynamic),
    /// Scratch space for *this* update, shared by every copy of the context
    /// and dropped once the update is handled. Where the dialog engine keeps
    /// its "callback already answered" flag and its widget stash, and where a
    /// middleware can hand a resolved locale to handlers nested below it. See
    /// [`telega/scope`](scope.html).
    scope: Scope,
  )
}

fn new_context(
  chat chat: ChatInstance(session, error, dependencies),
  update update,
  annotations annotations: Dict(String, Dynamic),
) -> Context(session, error, dependencies) {
  Context(
    update:,
    config: chat.config,
    key: chat.key,
    session: chat.session,
    dependencies: chat.dependencies,
    chat_subject: chat.self,
    start_time: None,
    log_prefix: None,
    bot_info: chat.bot_info,
    annotations:,
    scope: scope.new(),
  )
}

/// Read one pre-router annotation, decoded.
///
/// `Error(Nil)` when the key was never set or the value does not decode as
/// `decoder` expects, so a handler can fall back with `result.unwrap`:
///
/// ```gleam
/// let locale =
///   bot.annotation(ctx, "locale", decode.string)
///   |> result.unwrap("en")
/// ```
pub fn annotation(
  ctx: Context(session, error, dependencies),
  key: String,
  decoder: Decoder(a),
) -> Result(a, Nil) {
  use value <- result.try(dict.get(ctx.annotations, key))
  decode.run(value, decoder) |> result.replace_error(Nil)
}

/// Build the update's context; when the update was dispatched with a
/// webhook-reply envelope, wrap the API client in a per-update transformer so
/// the handler's first eligible call can be claimed for the webhook response.
fn new_context_with_envelope(
  chat chat: ChatInstance(session, error, dependencies),
  update update,
  envelope envelope: Option(Envelope),
  annotations annotations: Dict(String, Dynamic),
) -> Context(session, error, dependencies) {
  let context = new_context(chat:, update:, annotations:)
  case envelope {
    None -> context
    Some(envelope) -> {
      let api_client =
        client.use_transformer(
          context.config.api_client,
          webhook_reply.transformer(envelope:, scope: context.scope),
        )
      Context(..context, config: config.Config(..context.config, api_client:))
    }
  }
}

// Session --------------------------------------------------------------------------

pub type SessionSettings(session, error) {
  SessionSettings(
    // Calls after all handlers to persist the session.
    persist_session: fn(String, session) -> Result(session, error),
    // Calls on initialization of the chat instance to get the session.
    // Returns `None` if no session is found.
    // On error the chat instance refuses to start: the update is answered
    // `False` rather than handled on a default session that would then be
    // persisted over the still-stored real one.
    get_session: fn(String) -> Result(Option(session), error),
    // Calls on initialization of the chat instance if no session is found.
    default_session: fn() -> session,
  )
}

pub fn next_session(
  ctx ctx: Context(session, error, dependencies),
  session session: session,
) -> Result(Context(session, error, dependencies), error) {
  Ok(Context(..ctx, session:))
}

/// The key an update maps to unless `with_session_key` says otherwise:
/// `"{chat_id}:{from_id}"`, one session (and one chat instance) per user per
/// chat.
///
/// Alternatives ship beside it — [`chat_session_key`](#chat_session_key) for
/// one shared session per chat, [`user_session_key`](#user_session_key) for
/// one per user across chats. The caveats of each are in
/// `docs/session-serialization.md`.
pub fn default_session_key(update: Update) -> String {
  int.to_string(update.chat_id) <> ":" <> int.to_string(update.from_id)
}

/// One session per chat, shared by everyone in it: `"chat:{chat_id}"`.
///
/// The natural key for a group bot whose state is about the chat rather than
/// the member — a shared counter, the group's language. Note that it also
/// makes the chat a single instance, so members' updates are serialized
/// through one process (which is what makes a shared counter safe).
pub fn chat_session_key(update: Update) -> String {
  "chat:" <> int.to_string(update.chat_id)
}

/// One session per user, shared across every chat they write in:
/// `"user:{from_id}"`. Careful with updates that carry no user (a poll update
/// keys as `user:-1`).
pub fn user_session_key(update: Update) -> String {
  "user:" <> int.to_string(update.from_id)
}

/// Read the session an update maps to under the **default** key.
///
/// A bot that changed its key with `telega.with_session_key` has to read
/// through its own key function instead — this helper predates the setting and
/// cannot see it.
pub fn get_session(
  session_settings: SessionSettings(session, error),
  update: Update,
) -> Result(Option(session), error) {
  update
  |> default_session_key
  |> session_settings.get_session
}

/// How long a caller waits for an update to be handled before it stops
/// blocking on the answer.
///
/// A chat instance that dies is answered straight away (the bot monitors it),
/// and every handled-error path answers too; this is the last-resort backstop
/// for a handler that is alive but wedged. The handler keeps running — only the
/// caller gives up waiting, and reports the update as unhandled.
pub const update_dispatch_timeout = 60_000

// User should use methods from `telega` module.
@internal
pub fn handle_update(bot_subject bot_subject, update update) -> Bool {
  handle_update_within(bot_subject:, update:, timeout: update_dispatch_timeout)
}

/// Dispatch an update and wait up to `timeout` ms for it to be handled.
/// Returns `False` if the bot is gone, rejects the update, or does not answer
/// in time. Users should use methods from the `telega` module.
@internal
pub fn handle_update_within(
  bot_subject bot_subject: BotSubject,
  update update: Update,
  timeout timeout: Int,
) -> Bool {
  case process.subject_owner(bot_subject) {
    Error(Nil) -> False
    Ok(bot_pid) -> {
      let reply_with = process.new_subject()
      let monitor = process.monitor(bot_pid)
      let selector =
        process.new_selector()
        |> process.select(reply_with)
        |> process.select_specific_monitor(monitor, fn(_down) { False })

      process.send(
        bot_subject,
        HandleUpdateBotMessage(update:, reply_with:, envelope: None),
      )

      let handled =
        process.selector_receive(from: selector, within: timeout)
        |> result.unwrap(False)

      process.demonitor_process(monitor)
      handled
    }
  }
}

/// Dispatch an update without waiting for it to be handled.
///
/// The bot answers `reply_with` once the update settles (handled, failed, or
/// its chat instance died), which lets the caller — the polling worker — keep
/// fetching and dispatching while handlers run, and still count what is in
/// flight. Users should use methods from the `telega` module.
@internal
pub fn dispatch_update(
  bot_subject bot_subject: BotSubject,
  update update: Update,
  reply_with reply_with: Subject(Bool),
) -> Nil {
  process.send(
    bot_subject,
    HandleUpdateBotMessage(update:, reply_with:, envelope: None),
  )
}

// Dispatch an update with a webhook-reply envelope without blocking. The
// caller (`telega.handle_update_webhook`) listens on both `reply_with` and
// the envelope itself. Users should use `telega.handle_update_webhook`.
@internal
pub fn dispatch_update_with_envelope(
  bot_subject bot_subject: BotSubject,
  update update: Update,
  reply_with reply_with: Subject(Bool),
  envelope envelope: Envelope,
) -> Nil {
  process.send(
    bot_subject,
    HandleUpdateBotMessage(update:, reply_with:, envelope: Some(envelope)),
  )
}

// Handler ------------------------------------------------------------------------

pub type CallbackQueryFilter {
  CallbackQueryFilter(re: Regexp)
}

pub type Hears {
  HearText(text: String)
  HearTexts(texts: List(String))
  HearRegex(regex: Regexp)
  HearRegexes(regexes: List(Regexp))
}

// Handlers used for [conversation API](/docs/conversation)
pub type Handler(session, error, dependencies) {
  /// Handle all messages.
  HandleAll(
    handler: fn(Context(session, error, dependencies), Update) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle a specific command.
  HandleCommand(
    command: String,
    handler: fn(Context(session, error, dependencies), Command) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle multiple commands.
  HandleCommands(
    commands: List(String),
    handler: fn(Context(session, error, dependencies), Command) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle text messages.
  HandleText(
    handler: fn(Context(session, error, dependencies), String) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle text message with a specific substring.
  HandleHears(
    hears: Hears,
    handler: fn(Context(session, error, dependencies), String) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle any message.
  HandleMessage(
    handler: fn(Context(session, error, dependencies), Message) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle voice messages.
  HandleVoice(
    handler: fn(Context(session, error, dependencies), Voice) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle audio messages.
  HandleAudio(
    handler: fn(Context(session, error, dependencies), Audio) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle video messages.
  HandleVideo(
    handler: fn(Context(session, error, dependencies), Video) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle photo messages.
  HandlePhotos(
    handler: fn(Context(session, error, dependencies), List(PhotoSize)) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle web app data messages.
  HandleWebAppData(
    handler: fn(Context(session, error, dependencies), WebAppData) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle callback query. Context, data from callback query and `callback_query_id` are passed to the handler.
  HandleCallbackQuery(
    filter: CallbackQueryFilter,
    handler: fn(Context(session, error, dependencies), String, String) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle any update that satisfies `filter`. Updates that fail the filter
  /// fall through to the conversation's `or:` handler, exactly like the typed
  /// handlers above. Used by `telega.wait_for`/`telega.wait_filtered`.
  HandleFiltered(
    filter: fn(Update) -> Bool,
    handler: fn(Context(session, error, dependencies), Update) ->
      Result(Context(session, error, dependencies), error),
  )
  /// Handle chat member update (when user joins/leaves a group). The bot must be an administrator in the chat and must explicitly specify "chat_member" in the list of `allowed_updates` to receive these updates.
  HandleChatMember(
    handler: fn(Context(session, error, dependencies), ChatMemberUpdated) ->
      Result(Context(session, error, dependencies), error),
  )
}

/// Where the flow engine records that user code is running inside a step, so
/// a `wait_*` called from there can say what is wrong instead of silently
/// stalling the flow. Scoped to the update, like everything else in `Scope`.
const flow_step_key: scope.Key(String) = scope.Key("bot/flow_step")

/// Run `step` marked as flow-step code. The flow and dialog engines wrap
/// every user step handler in this.
@internal
pub fn in_flow_step(
  ctx ctx: Context(session, error, dependencies),
  flow_name flow_name: String,
  step step: fn() -> a,
) -> a {
  scope.put(ctx.scope, flow_step_key, flow_name)
  let result = step()
  scope.erase(ctx.scope, flow_step_key)
  result
}

/// The flow whose step is running right now, if user code is inside one.
/// Lets `dialog.start` record which dialog opened the one it starts.
@internal
pub fn current_flow_step(
  ctx: Context(session, error, dependencies),
) -> Option(String) {
  scope.get(ctx.scope, flow_step_key) |> option.from_result
}

/// Pass any handler to start waiting
///
/// `or` - calls if there are any other updates
/// `timeout` - the conversation will be canceled after this timeout
pub fn wait_handler(
  ctx ctx: Context(session, error, dependencies),
  handler handler: Handler(session, error, dependencies),
  handle_else handle_else: Option(Handler(session, error, dependencies)),
  timeout timeout: Option(Int),
) -> Result(Context(session, error, dependencies), error) {
  warn_if_inside_flow_step(ctx)
  actor.send(
    ctx.chat_subject,
    WaitHandlerChatInstanceMessage(handler:, handle_else:, timeout:),
  )
  Ok(ctx)
}

/// A chat instance answers a pending continuation *before* it routes, so a
/// `wait_*` armed from inside a flow step swallows the very update the flow
/// is parked on: the flow never resumes, and its `wait_token` sits there
/// until the TTL. The two waiting mechanisms cannot both own the next update,
/// so say so rather than let the flow appear to hang.
fn warn_if_inside_flow_step(ctx: Context(session, error, dependencies)) -> Nil {
  case scope.get(ctx.scope, flow_step_key) {
    Error(Nil) -> Nil
    Ok(flow_name) -> {
      telemetry.execute(["telega", "flow", "wait_in_step"], [#("count", 1)], [
        #("flow_name", telemetry.StringValue(flow_name)),
      ])
      log.warning(
        "[flow:"
        <> flow_name
        <> "] wait_* was called from inside a flow step. The chat instance's"
        <> " continuation is consulted before the router, so it will consume"
        <> " the update the flow is waiting for and the flow will not resume."
        <> " Park the step instead: `action.wait`/`action.wait_callback` in a"
        <> " flow, `on_text`/`on_message` in a dialog.",
      )
    }
  }
}

/// Same as `do_handle`, but wraps the handler invocation in a
/// `telega.update` start/stop/exception telemetry span.
/// A handler that did not match the update (`None`) emits `stop`.
fn do_handle_with_telemetry(
  context context: Context(session, error, dependencies),
  update upd: Update,
  handler handler: Handler(session, error, dependencies),
) {
  let metadata = update_telemetry_metadata(upd)
  let started_at = telemetry.monotonic_time()
  telemetry.execute(
    ["telega", "update", "start"],
    [#("system_time", telemetry.system_time())],
    metadata,
  )

  let result = do_handle(context:, update: upd, handler:)

  let duration = telemetry.monotonic_time() - started_at
  case result {
    Some(Error(error)) ->
      telemetry.execute(
        ["telega", "update", "exception"],
        [#("duration", duration)],
        [#("error", telemetry.StringValue(string.inspect(error))), ..metadata],
      )
    _ ->
      telemetry.execute(
        ["telega", "update", "stop"],
        [#("duration", duration)],
        metadata,
      )
  }

  result
}

/// Does the text satisfy a `Hears` pattern?
fn hears_matches(hears: Hears, text: String) -> Bool {
  case hears {
    HearText(text: expected) -> expected == text
    HearTexts(texts:) -> list.contains(texts, text)
    HearRegex(regex:) -> regexp.check(regex, text)
    HearRegexes(regexes:) -> list.any(regexes, regexp.check(_, text))
  }
}

/// Run `handler` against `update`, or return `None` when the handler does not
/// apply — either the update is of the wrong kind, or it fails the handler's
/// own filter (`wait_command`'s command name, `wait_hears`' patterns,
/// `wait_callback_query`'s regexp). `None` is what routes the update to the
/// conversation's `or:` handler instead.
fn do_handle(context context, update update, handler handler) {
  case handler, update {
    HandleAll(handler:), _ -> context |> handler(update) |> Some
    HandleFiltered(handler:, filter:), _ ->
      case filter(update) {
        True -> context |> handler(update) |> Some
        False -> None
      }
    HandleText(handler:), TextUpdate(text:, ..) ->
      context |> handler(text) |> Some
    HandleHears(handler:, hears:), TextUpdate(text:, ..) ->
      case hears_matches(hears, text) {
        True -> context |> handler(text) |> Some
        False -> None
      }
    HandleCommand(handler:, command:),
      CommandUpdate(command: update_command, ..)
    ->
      case update_command.command == command {
        True -> context |> handler(update_command) |> Some
        False -> None
      }
    HandleCommands(handler:, commands:),
      CommandUpdate(command: update_command, ..)
    ->
      case list.contains(commands, update_command.command) {
        True -> context |> handler(update_command) |> Some
        False -> None
      }
    HandleCallbackQuery(handler:, filter:), CallbackQueryUpdate(query:, ..) -> {
      use data <- option.then(query.data)
      case regexp.check(filter.re, data) {
        True -> Some(handler(context, data, query.id))
        False -> None
      }
    }
    HandleMessage(handler), MessageUpdate(message:, ..) ->
      context |> handler(message) |> Some
    HandleChatMember(handler), ChatMemberUpdate(chat_member_updated:, ..) ->
      context |> handler(chat_member_updated) |> Some
    HandleVoice(handler), VoiceUpdate(voice:, ..) ->
      context |> handler(voice) |> Some
    HandleAudio(handler), AudioUpdate(audio:, ..) ->
      context |> handler(audio) |> Some
    HandleVideo(handler), VideoUpdate(video:, ..) ->
      context |> handler(video) |> Some
    HandleWebAppData(handler), WebAppUpdate(web_app_data:, ..) ->
      context |> handler(web_app_data) |> Some
    _, _ -> None
  }
}
