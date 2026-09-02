//// Core bot actor and chat instance management.
////
//// This module implements the actor-based architecture for handling Telegram updates.
//// It contains the `Bot` actor (the central dispatcher) and `ChatInstance` actors
//// (one per unique `{chat_id}:{from_id}` combination).
////
//// ## Supervision tree
////
//// Both the `Bot` actor and `ChatInstance` actors run inside a supervision tree
//// created by `telega.init()` or `telega.init_for_polling()`:
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
//// pair and, by default, lives as long as the bot does. `telega.with_chat_idle_timeout`
//// puts a bound on that: an instance that has received nothing for the
//// configured time asks the `Bot` actor to evict it. The bot — the only process
//// that dispatches updates — deregisters the key first and only then tells the
//// instance to stop, so an update can never be delivered to an instance on its
//// way out. The next update simply starts a fresh instance that re-reads the
//// session from storage; only an in-memory conversation continuation is lost.
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
  type Audio, type ChatMemberUpdated, type Message, type PhotoSize, type User,
  type Video, type Voice, type WebAppData,
}
import telega/telemetry
import telega/update.{
  type Command, type Update, AudioUpdate, CallbackQueryUpdate, ChatMemberUpdate,
  CommandUpdate, MessageUpdate, TextUpdate, VideoUpdate, VoiceUpdate,
  WebAppUpdate,
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
    // How long (ms) a chat instance may sit idle before it is stopped and
    // dropped from the registry. `None` keeps every instance alive forever.
    chat_idle_timeout: Option(Int),
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
    // How long (ms) the instance may sit idle before asking the bot to stop it.
    // `None` disables idle eviction.
    idle_timeout: Option(Int),
  )
}

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
  )
}

/// Decision returned by a `PreHandler`: keep processing the update through the
/// router, or stop it here (drop it before routing).
pub type PreRouterResult {
  /// Continue to the next pre-router middleware and, eventually, the router.
  Continue
  /// Stop processing this update. The webhook/poller is told the update was
  /// acknowledged (so Telegram does not retry it) but no handler runs.
  Stop
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
  chat_idle_timeout chat_idle_timeout: Option(Int),
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
        chat_idle_timeout:,
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
            Continue ->
              case
                handle_update_bot_message(bot:, update:, reply_with:, envelope:)
              {
                Ok(bot) ->
                  actor.continue(Bot(..bot, in_flight: bot.in_flight + 1))
                Error(error) -> {
                  log.error_d("Error in handler: ", error)
                  // The update never reached an instance, so nothing else will
                  // ever answer the caller.
                  process.send(reply_with, False)
                  actor.stop()
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
    [] -> Continue
    handlers -> {
      let pre_ctx =
        PreContext(
          update:,
          config: bot.config,
          dependencies: bot.dependencies,
          bot_info: bot.bot_info,
        )
      do_run_pre_handlers(handlers, pre_ctx)
    }
  }
}

fn do_run_pre_handlers(
  handlers: List(PreHandler(dependencies)),
  pre_ctx: PreContext(dependencies),
) -> PreRouterResult {
  case handlers {
    [] -> Continue
    [handler, ..rest] ->
      case handler(pre_ctx) {
        Stop -> Stop
        Continue -> do_run_pre_handlers(rest, pre_ctx)
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
) -> Result(Bot(session, error, dependencies), error.TelegaError) {
  let key = build_session_key(update)

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
          idle_timeout: bot.chat_idle_timeout,
        )
      // No need to register here — start_chat_instance self-registers
      fsup.start_child(bot.chat_factory, args)
      |> result.map(fn(started) { started.data })
      |> result.map_error(error.ChatInstanceStartError)
    }
  })

  actor.send(
    chat_subject,
    HandleNewChatInstanceMessage(update:, reply_with:, envelope:),
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
    // How long (ms) the instance may sit idle before asking the bot to stop it.
    idle_timeout: Option(Int),
    // When this instance last received a message of its own.
    last_activity: Timestamp,
  )
}

const initialisation_timeout = 10

/// Start a chat instance. Used as the template function for factory_supervisor.
/// Self-registers in the registry on start (handles both first start and restart after crash).
pub fn start_chat_instance(
  args: ChatInstanceArgs(session, error, dependencies),
) -> actor.StartResult(ChatInstanceSubject(session, error, dependencies)) {
  let session = case args.session_settings.get_session(args.key) {
    Ok(Some(session)) -> session
    Ok(None) -> args.session_settings.default_session()
    Error(error) -> {
      log.warning(
        "Failed to get session for key "
        <> args.key
        <> ", falling back to default: "
        <> string.inspect(error),
      )
      args.session_settings.default_session()
    }
  }

  actor.new_with_initialiser(initialisation_timeout, fn(subject) {
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
        idle_timeout: args.idle_timeout,
        last_activity: timestamp.system_time(),
      )
    // Self-register in registry (overwrites stale Subject on restart)
    registry.register(args.registry, key: args.key, subject:)
    schedule_idle_check(subject, args.idle_timeout)
    actor.initialised(chat_instance)
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
    HandleNewChatInstanceMessage(update:, reply_with:, envelope:) -> {
      let chat = touch(chat)
      do_handle_new_chat_instance_message(
        context: new_context_with_envelope(chat:, update:, envelope:),
        chat:,
        update:,
        reply_with:,
      )
    }
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

/// Remember that the instance is doing something right now, so the idle clock
/// starts over.
fn touch(
  chat: ChatInstance(session, error, dependencies),
) -> ChatInstance(session, error, dependencies) {
  case chat.idle_timeout {
    None -> chat
    Some(_) -> ChatInstance(..chat, last_activity: timestamp.system_time())
  }
}

/// Arm the next idle tick, if idle eviction is enabled at all.
fn schedule_idle_check(
  subject: ChatInstanceSubject(session, error, dependencies),
  delay: Option(Int),
) -> Nil {
  case delay {
    None -> Nil
    Some(delay) -> {
      let _ =
        process.send_after(
          subject,
          int.max(delay, 1),
          IdleCheckChatInstanceMessage,
        )
      Nil
    }
  }
}

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
  case chat.idle_timeout {
    None -> actor.continue(chat)
    Some(timeout) -> {
      let idle_for = idle_for(chat)
      let next_check = case idle_for >= timeout {
        True -> {
          process.send(
            chat.bot_subject,
            ChatInstanceIdleBotMessage(key: chat.key, pid: process.self()),
          )
          // The bot declines while the instance is still busy with an update;
          // ask again a whole timeout later rather than spinning on the tick.
          timeout
        }
        // Not idle long enough yet — check again when it could be.
        False -> timeout - idle_for
      }
      schedule_idle_check(chat.self, Some(next_check))
      actor.continue(chat)
    }
  }
}

fn do_handle_new_chat_instance_message(
  context context: Context(session, error, dependencies),
  chat chat: ChatInstance(session, error, dependencies),
  update update,
  reply_with reply_with,
) {
  case chat.continuation {
    // There is a continuation, handle the update with it
    Some(continuation) ->
      case continuation.ttl {
        Some(ttl) -> {
          case timestamp.compare(ttl, timestamp.system_time()) {
            // When ttl is expired, handle update without continuation
            order.Lt ->
              do_handle_new_chat_instance_message(
                context:,
                chat: ChatInstance(..chat, continuation: None),
                update:,
                reply_with:,
              )
            _ ->
              do_handle_continuation(
                context:,
                continuation:,
                update:,
                reply_with:,
                chat:,
              )
          }
        }
        None ->
          do_handle_continuation(
            context:,
            continuation:,
            update:,
            reply_with:,
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
        Ok(Context(session: new_session, ..)) -> {
          case chat.session_settings.persist_session(chat.key, new_session) {
            Ok(persisted_session) -> {
              ack(chat, reply_with, True)
              actor.continue(ChatInstance(..chat, session: persisted_session))
            }
            Error(e) -> {
              case chat.catch_handler(context, e) {
                Ok(_) -> {
                  ack(chat, reply_with, False)
                  actor.continue(chat)
                }
                Error(e) -> {
                  log.error_d("Error in session persistence: ", e)
                  stop_chat_instance(chat, reply_with, "session_persist_failed")
                }
              }
            }
          }
        }
        Error(e) -> {
          case chat.catch_handler(context, e) {
            Ok(_) -> {
              ack(chat, reply_with, False)
              actor.continue(chat)
            }
            Error(e) -> {
              log.error_d("Error in catch handler: ", e)
              stop_chat_instance(chat, reply_with, "catch_handler_failed")
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

/// Give up on this chat instance.
///
/// The update in flight is answered (`False`) before stopping: the caller is
/// blocked on that reply and nothing else would ever send it. The registry
/// entry goes too — the instance stops *normally*, so its `Transient`
/// supervisor will not restart it, and a stale entry would silently swallow
/// every later update for this chat.
fn stop_chat_instance(
  chat: ChatInstance(session, error, dependencies),
  reply_with: Subject(Bool),
  reason: String,
) {
  ack(chat, reply_with, False)
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
  reply_with reply_with: Subject(Bool),
  chat chat: ChatInstance(session, error, dependencies),
) {
  case
    do_handle_with_telemetry(context:, update:, handler: continuation.handler)
  {
    Some(Ok(Context(session: new_session, ..))) -> {
      // Persist the new session after continuation completes
      case chat.session_settings.persist_session(chat.key, new_session) {
        Ok(persisted_session) -> {
          ack(chat, reply_with, True)
          actor.continue(
            ChatInstance(..chat, session: persisted_session, continuation: None),
          )
        }
        Error(e) -> {
          case chat.catch_handler(context, e) {
            Ok(_) -> {
              ack(chat, reply_with, False)
              actor.continue(chat)
            }
            Error(e) -> {
              log.error_d(
                "Error in session persistence after continuation: ",
                e,
              )
              stop_chat_instance(chat, reply_with, "session_persist_failed")
            }
          }
        }
      }
    }
    Some(Error(e)) -> {
      case chat.catch_handler(context, e) {
        Ok(_) -> {
          ack(chat, reply_with, False)
          actor.continue(chat)
        }
        Error(e) -> {
          log.error_d("Error in catch handler: ", e)
          stop_chat_instance(chat, reply_with, "catch_handler_failed")
        }
      }
    }
    None -> {
      case continuation.handle_else {
        Some(handler) ->
          case do_handle(context:, update:, handler:) {
            Some(Ok(Context(session: new_session, ..))) -> {
              case
                chat.session_settings.persist_session(chat.key, new_session)
              {
                Ok(persisted_session) -> {
                  ack(chat, reply_with, True)
                  actor.continue(
                    ChatInstance(..chat, session: persisted_session),
                  )
                }
                Error(e) -> {
                  case chat.catch_handler(context, e) {
                    Ok(_) -> {
                      ack(chat, reply_with, False)
                      actor.continue(chat)
                    }
                    Error(e) -> {
                      log.error_d(
                        "Error in session persistence after handle_else: ",
                        e,
                      )
                      stop_chat_instance(
                        chat,
                        reply_with,
                        "session_persist_failed",
                      )
                    }
                  }
                }
              }
            }
            Some(Error(e)) -> {
              case chat.catch_handler(context, e) {
                Ok(_) -> {
                  ack(chat, reply_with, False)
                  actor.continue(chat)
                }
                Error(e) -> {
                  log.error_d("Error in catch else handler: ", e)
                  stop_chat_instance(chat, reply_with, "catch_handler_failed")
                }
              }
            }
            None -> {
              ack(chat, reply_with, False)
              actor.continue(chat)
            }
          }
        None -> {
          ack(chat, reply_with, False)
          actor.continue(chat)
        }
      }
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
  )
}

fn new_context(
  chat chat: ChatInstance(session, error, dependencies),
  update update,
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
  )
}

/// Build the update's context; when the update was dispatched with a
/// webhook-reply envelope, wrap the API client in a per-update transformer so
/// the handler's first eligible call can be claimed for the webhook response.
fn new_context_with_envelope(
  chat chat: ChatInstance(session, error, dependencies),
  update update,
  envelope envelope: Option(Envelope),
) -> Context(session, error, dependencies) {
  let context = new_context(chat:, update:)
  case envelope {
    None -> context
    Some(envelope) -> {
      let api_client =
        client.use_transformer(
          context.config.api_client,
          webhook_reply.transformer(envelope),
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
    // On error, logs a warning and falls back to `default_session()`.
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

fn build_session_key(update: Update) {
  int.to_string(update.chat_id) <> ":" <> int.to_string(update.from_id)
}

pub fn get_session(
  session_settings: SessionSettings(session, error),
  update: Update,
) -> Result(Option(session), error) {
  update
  |> build_session_key
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
  actor.send(
    ctx.chat_subject,
    WaitHandlerChatInstanceMessage(handler:, handle_else:, timeout:),
  )
  Ok(ctx)
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
