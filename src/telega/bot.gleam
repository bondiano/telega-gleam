import gleam/bool
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/otp/supervisor
import gleam/regexp.{type Regexp}
import gleam/result
import gleam/string
import telega/api
import telega/internal/config.{type Config}
import telega/model.{type User}
import telega/update.{
  type Command, type Update, CallbackQueryUpdate, CommandUpdate, TextUpdate,
  UnknownUpdate,
}

// Registry --------------------------------------------------------------------

type RegistrySubject =
  Subject(RegistryMessage)

type RootBotInstanceSubject(session) =
  Subject(Subject(BotInstanceMessage(session)))

type Registry(session) {
  /// Registry works as routing for chat_id to bot instance.
  /// If no bot instance in registry, it will create a new one.
  Registry(
    bots: Dict(String, RegistryItem(session)),
    config: Config,
    bot_info: User,
    session_settings: SessionSettings(session),
    handlers: List(Handler(session)),
    registry_subject: RegistrySubject,
    bot_instances_subject: RootBotInstanceSubject(session),
  )
}

type BotInstanceSubject(session) =
  Subject(BotInstanceMessage(session))

type RegistryItem(session) =
  BotInstanceSubject(session)

pub type RegistryMessage {
  HandleBotRegistryMessage(update: Update)
}

fn try_send_update(registry_item: RegistryItem(session), update: Update) {
  process.try_call(registry_item, BotInstanceMessageNew(_, update), 1000)
}

fn handle_registry_message(
  message: RegistryMessage,
  registry: Registry(session),
) {
  case message {
    HandleBotRegistryMessage(message) ->
      case get_session_key(message) {
        Ok(session_key) ->
          case dict.get(registry.bots, session_key) {
            Ok(registry_item) -> {
              case try_send_update(registry_item, message) {
                Ok(_) -> actor.continue(registry)
                Error(_) -> add_bot_instance(registry, session_key, message)
              }
            }
            Error(Nil) -> add_bot_instance(registry, session_key, message)
          }
        Error(_e) -> actor.continue(registry)
      }
  }
}

fn add_bot_instance(
  registry: Registry(session),
  session_key: String,
  update: Update,
) {
  let registry_actor =
    supervisor.supervisor(fn(_) {
      start_bot_instance(
        registry: registry,
        update: update,
        session_key: session_key,
        parent_subject: registry.bot_instances_subject,
      )
    })

  let assert Ok(_supervisor_subject) =
    supervisor.start(supervisor.add(_, registry_actor))

  let bot_subject_result =
    process.receive(registry.bot_instances_subject, 100)
    |> result.map_error(fn(e) {
      "Failed to start bot instance: " <> string.inspect(e)
    })

  case bot_subject_result {
    Ok(bot_subject) -> {
      case try_send_update(bot_subject, update) {
        Ok(_) ->
          actor.continue(
            Registry(
              ..registry,
              bots: dict.insert(registry.bots, session_key, bot_subject),
            ),
          )
        Error(_e) -> actor.continue(registry)
      }
    }
    Error(_e) -> actor.continue(registry)
  }
}

/// Set webhook for the bot.
pub fn set_webhook(config config: Config) -> Result(Bool, String) {
  api.set_webhook(
    config.api,
    model.SetWebhookParameters(
      url: config.server_url <> "/" <> config.webhook_path,
      max_connections: None,
      ip_address: None,
      allowed_updates: None,
      drop_pending_updates: None,
      secret_token: Some(config.secret_token),
      certificate: None,
    ),
  )
}

pub fn start_registry(
  config config: Config,
  handlers handlers: List(Handler(session)),
  session_settings session_settings: SessionSettings(session),
  root_subject root_subject: Subject(RegistrySubject),
  bot_info bot_info: User,
) -> Result(RegistrySubject, actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let registry_subject = process.new_subject()
      let bot_instances_subject = process.new_subject()
      process.send(root_subject, registry_subject)

      let selector =
        process.new_selector()
        |> process.selecting(registry_subject, function.identity)

      Registry(
        config:,
        handlers:,
        bot_info:,
        session_settings:,
        registry_subject:,
        bot_instances_subject:,
        bots: dict.new(),
      )
      |> actor.Ready(selector)
    },
    loop: handle_registry_message,
    init_timeout: 10_000,
  ))
}

pub fn wait_handler(
  ctx: Context(session),
  handler: Handler(session),
) -> Result(Context(session), String) {
  process.send(ctx.bot_subject, BotInstanceMessageWaitHandler(handler))
  Ok(ctx)
}

fn new_context(bot: BotInstance(session), update: Update) -> Context(session) {
  Context(
    update:,
    key: bot.key,
    config: bot.config,
    session: bot.session,
    bot_subject: bot.own_subject,
    bot_info: bot.bot_info,
  )
}

// Session ---------------------------------------------------------------------

pub type SessionSettings(session) {
  SessionSettings(
    // Calls after all handlers to persist the session.
    persist_session: fn(String, session) -> Result(session, String),
    // Calls on initialization of the bot instance to get the session.
    get_session: fn(String) -> Result(session, String),
  )
}

pub fn next_session(
  ctx ctx: Context(session),
  session session: session,
) -> Result(Context(session), String) {
  Ok(Context(..ctx, session:))
}

fn get_session_key(update: Update) -> Result(String, String) {
  case update {
    CommandUpdate(chat_id: chat_id, ..) -> Ok(int.to_string(chat_id))
    TextUpdate(chat_id: chat_id, ..) -> Ok(int.to_string(chat_id))
    CallbackQueryUpdate(from_id: from_id, ..) -> Ok(int.to_string(from_id))
    UnknownUpdate(..) ->
      Error("Unknown update type don't allow to get session key")
  }
}

fn get_session(
  session_settings: SessionSettings(session),
  update: Update,
) -> Result(session, String) {
  use key <- result.try(get_session_key(update))

  session_settings.get_session(key)
  |> result.map_error(fn(e) { "Failed to get session:\n " <> string.inspect(e) })
}

fn start_bot_instance(
  registry registry: Registry(session),
  update update: Update,
  session_key session_key: String,
  parent_subject parent_subject: RootBotInstanceSubject(session),
) -> Result(BotInstanceSubject(session), actor.StartError) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let actor_subj = process.new_subject()
      process.send(parent_subject, actor_subj)

      let selector =
        process.new_selector()
        |> process.selecting(actor_subj, function.identity)

      case get_session(registry.session_settings, update) {
        Ok(session) ->
          BotInstance(
            session:,
            key: session_key,
            bot_info: registry.bot_info,
            config: registry.config,
            handlers: registry.handlers,
            session_settings: registry.session_settings,
            active_handler: None,
            own_subject: actor_subj,
          )
          |> actor.Ready(selector)
        Error(e) -> actor.Failed("Failed to init bot instance:\n" <> e)
      }
    },
    loop: handle_bot_instance_message,
    init_timeout: 1000,
  ))
}

// Bot Instance --------------------------------------------------------------------

/// Context holds information needed for the bot instance and the current update.
pub type Context(session) {
  Context(
    key: String,
    update: Update,
    bot_info: User,
    config: Config,
    session: session,
    bot_subject: BotInstanceSubject(session),
  )
}

pub type BotInstanceMessage(session) {
  BotInstanceMessageOk
  BotInstanceMessageNew(client: BotInstanceSubject(session), update: Update)
  BotInstanceMessageWaitHandler(handler: Handler(session))
}

type BotInstance(session) {
  BotInstance(
    key: String,
    session: session,
    config: Config,
    handlers: List(Handler(session)),
    bot_info: User,
    session_settings: SessionSettings(session),
    active_handler: Option(Handler(session)),
    own_subject: BotInstanceSubject(session),
  )
}

fn handle_bot_instance_message(
  message: BotInstanceMessage(session),
  bot: BotInstance(session),
) {
  case message {
    BotInstanceMessageNew(client, message) -> {
      case bot.active_handler {
        Some(handler) ->
          case do_handle(bot, message, handler) {
            Some(Ok(Context(session: new_session, ..))) -> {
              actor.send(client, BotInstanceMessageOk)
              actor.continue(
                BotInstance(..bot, session: new_session, active_handler: None),
              )
            }
            Some(Error(_e)) -> actor.Stop(process.Normal)
            None -> {
              actor.send(client, BotInstanceMessageOk)
              actor.continue(bot)
            }
          }
        None ->
          case loop_handlers(bot, message, bot.handlers) {
            Ok(new_session) -> {
              actor.send(client, BotInstanceMessageOk)
              actor.continue(BotInstance(..bot, session: new_session))
            }
            Error(_e) -> actor.Stop(process.Normal)
          }
      }
    }
    BotInstanceMessageWaitHandler(handler) ->
      actor.continue(BotInstance(..bot, active_handler: Some(handler)))
    BotInstanceMessageOk -> actor.continue(bot)
  }
}

// Hears -----------------------------------------------------------------------

pub type Hears {
  HearText(text: String)
  HearTexts(texts: List(String))
  HearRegex(regex: Regexp)
  HearRegexes(regexes: List(Regexp))
}

fn hears_check(text: String, hear: Hears) -> Bool {
  case hear {
    HearText(str) -> text == str
    HearTexts(strings) -> list.contains(strings, text)
    HearRegex(re) -> regexp.check(re, text)
    HearRegexes(regexes) -> list.any(regexes, regexp.check(_, text))
  }
}

pub type Handler(session) {
  /// Handle all messages.
  HandleAll(handler: fn(Context(session)) -> Result(Context(session), String))
  /// Handle a specific command.
  HandleCommand(
    command: String,
    handler: fn(Context(session), Command) -> Result(Context(session), String),
  )
  /// Handle multiple commands.
  HandleCommands(
    commands: List(String),
    handler: fn(Context(session), Command) -> Result(Context(session), String),
  )
  /// Handle text messages.
  HandleText(
    handler: fn(Context(session), String) -> Result(Context(session), String),
  )
  /// Handle text message with a specific substring.
  HandleHears(
    hears: Hears,
    handler: fn(Context(session), String) -> Result(Context(session), String),
  )
  /// Handle callback query. Context, data from callback query and `callback_query_id` are passed to the handler.
  HandleCallbackQuery(
    filter: CallbackQueryFilter,
    handler: fn(Context(session), String, String) ->
      Result(Context(session), String),
  )
}

pub type CallbackQueryFilter {
  CallbackQueryFilter(re: Regexp)
}

fn do_handle(
  bot: BotInstance(session),
  update: Update,
  handler: Handler(session),
) -> Option(Result(Context(session), String)) {
  case handler, update {
    HandleAll(handle), _ -> Some(handle(new_context(bot, update)))
    HandleText(handle), TextUpdate(text: text, ..) ->
      Some(handle(new_context(bot, update), text))
    HandleHears(hear, handle), TextUpdate(text: text, ..) -> {
      use <- bool.guard(!hears_check(text, hear), None)
      Some(handle(new_context(bot, update), text))
    }
    HandleCommand(command, handle), CommandUpdate(command: update_command, ..) -> {
      use <- bool.guard(update_command.command != command, None)
      Some(handle(new_context(bot, update), update_command))
    }
    HandleCommands(commands, handle), CommandUpdate(command: update_command, ..)
    -> {
      use <- bool.guard(!list.contains(commands, update_command.command), None)
      Some(handle(new_context(bot, update), update_command))
    }
    HandleCallbackQuery(filter, handle), CallbackQueryUpdate(raw: raw, ..) ->
      case raw.data {
        Some(data) -> {
          use <- bool.guard(!regexp.check(filter.re, data), None)
          Some(handle(new_context(bot, update), data, raw.id))
        }
        None -> None
      }
    _, _ -> None
  }
}

fn loop_handlers(
  bot: BotInstance(session),
  update: Update,
  handlers: List(Handler(session)),
) {
  case handlers {
    [handler, ..rest] ->
      case do_handle(bot, update, handler) {
        Some(Ok(Context(session: new_session, ..))) ->
          loop_handlers(BotInstance(..bot, session: new_session), update, rest)
        Some(Error(e)) ->
          Error(
            "Failed to handle message " <> string.inspect(update) <> ": " <> e,
          )
        None -> loop_handlers(bot, update, rest)
      }
    [] -> bot.session_settings.persist_session(bot.key, bot.session)
  }
}

pub fn fmt_update(ctx: Context(session)) -> String {
  case ctx.update {
    CommandUpdate(command: command, chat_id: chat_id, ..) ->
      "command \"" <> command.command <> "\" from " <> int.to_string(chat_id)
    TextUpdate(text: text, chat_id: chat_id, ..) ->
      "text \"" <> text <> "\" from " <> int.to_string(chat_id)
    CallbackQueryUpdate(raw: raw, from_id: from_id) ->
      "callback query "
      <> option.unwrap(raw.data, "no data")
      <> " from "
      <> int.to_string(from_id)
    UnknownUpdate(update) -> "unknown: " <> string.inspect(update)
  }
}
