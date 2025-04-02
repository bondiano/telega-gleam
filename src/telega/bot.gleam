import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/regexp.{type Regexp}
import gleam/result
import gleam/string

import telega/internal/config.{type Config}
import telega/internal/registry.{type RegistrySubject}

import telega/api
import telega/model.{type User}
import telega/update.{
  type Command, type Update, CallbackQueryUpdate, CommandUpdate, TextUpdate,
  UnknownUpdate,
}

/// Stores information about runned bot instance
pub opaque type Bot(session) {
  Bot(
    self: BotSubject,
    config: Config,
    bot_info: User,
    session_settings: SessionSettings(session),
    handlers: List(Handler(session)),
    registry_subject: RegistrySubject(ChatInstanceMessage(session)),
  )
}

pub type BotSubject =
  Subject(BotMessage)

pub opaque type BotMessage {
  CancelConversationBotMessage(key: String)
  HandleUpdateBotMessage(update: Update, reply_with: Subject(Option(Nil)))
}

const bot_actor_init_timeout = 100

pub fn start(
  registry_subject registry_subject,
  config config,
  bot_info bot_info,
  handlers handlers,
  session_settings session_settings,
) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let self = process.new_subject()
      let selector =
        process.new_selector() |> process.selecting(self, function.identity)
      let bot =
        Bot(
          self:,
          registry_subject:,
          config:,
          bot_info:,
          handlers:,
          session_settings:,
        )

      actor.Ready(bot, selector)
    },
    loop: bot_loop,
    init_timeout: bot_actor_init_timeout,
  ))
}

/// Stops waiting for any handler for specific key (chat_id)
pub fn cancel_conversation(bot bot: Bot(message), key key) {
  actor.send(bot.self, CancelConversationBotMessage(key: key))
}

fn bot_loop(message: BotMessage, bot: Bot(message)) {
  case message {
    HandleUpdateBotMessage(update:, reply_with:) -> {
      case handle_update_bot_message(bot:, update:, reply_with:) {
        // TODO: Implement error handling
        _ -> actor.continue(bot)
      }
    }
    CancelConversationBotMessage(key:) -> {
      registry.unregister(bot.registry_subject, key)
      actor.continue(bot)
    }
  }
}

fn handle_update_bot_message(
  bot bot: Bot(session),
  update update,
  reply_with reply_with,
) {
  use key <- result.try(get_session_key(update))
  case registry.get(key:, in: bot.registry_subject) {
    Some(chat_subject) -> {
      let handlers = extract_update_handlers(bot.handlers, update)
      handle_update_chat_instance(
        chat_subject:,
        update:,
        handlers:,
        reply_with:,
      )
      |> Ok
    }
    None -> {
      use chat_subject <- result.try(
        start_chat_instance(
          key:,
          config: bot.config,
          session_settings: bot.session_settings,
        )
        |> result.map_error(fn(error) {
          "Failed to start chat instance: " <> string.inspect(error)
        }),
      )
      registry.register(key:, in: bot.registry_subject, subject: chat_subject)

      let handlers = extract_update_handlers(bot.handlers, update)
      handle_update_chat_instance(
        chat_subject:,
        update:,
        handlers:,
        reply_with:,
      )
      |> Ok
    }
  }
}

// Chat Instance --------------------------------------------------------------------

pub type ChatInstanceSubject(session) =
  Subject(ChatInstanceMessage(session))

pub opaque type ChatInstanceMessage(session) {
  HandleNewChatInstanceMessage(
    update: Update,
    handlers: List(Handler(session)),
    reply_with: Subject(Option(Nil)),
  )
  WaitHandlerChatInstanceMessage(handler: Handler(session))
}

type ChatInstance(session) {
  ChatInstance(
    key: String,
    session: session,
    config: Config,
    session_settings: SessionSettings(session),
    self: ChatInstanceSubject(session),
    continuation: Option(Handler(session)),
  )
}

const chat_instance_actor_init_timeout = 250

fn start_chat_instance(
  key key: String,
  config config: Config,
  session_settings session_settings: SessionSettings(session),
) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let self = process.new_subject()
      let selector =
        process.new_selector() |> process.selecting(self, function.identity)
      // TODO: default should be passed only on NOT FOUND error
      let session =
        result.lazy_unwrap(session_settings.get_session(key), fn() {
          session_settings.default_session()
        })
      let chat_instance =
        ChatInstance(
          key:,
          config:,
          session:,
          self:,
          session_settings:,
          continuation: None,
        )

      actor.Ready(chat_instance, selector)
    },
    loop: loop_chat_instance,
    init_timeout: chat_instance_actor_init_timeout,
  ))
}

fn handle_update_chat_instance(
  chat_subject chat_subject,
  update update,
  handlers handlers: List(Handler(session)),
  reply_with reply_with,
) {
  actor.send(
    chat_subject,
    HandleNewChatInstanceMessage(update:, handlers:, reply_with:),
  )
}

fn loop_chat_instance(
  message: ChatInstanceMessage(session),
  chat: ChatInstance(session),
) {
  case message {
    HandleNewChatInstanceMessage(
      update: update,
      handlers: handlers,
      reply_with: reply_with,
    ) -> {
      case chat.continuation {
        None ->
          case loop_handlers(chat:, update:, handlers:, config: chat.config) {
            Ok(new_session) -> {
              actor.send(reply_with, Some(Nil))
              actor.continue(ChatInstance(..chat, session: new_session))
            }
            Error(_e) -> {
              actor.send(reply_with, None)
              actor.Stop(process.Normal)
            }
          }
        Some(handler) -> {
          case do_handle(chat:, update:, handler:) {
            Some(Ok(Context(session: new_session, ..))) -> {
              actor.send(reply_with, Some(Nil))
              actor.continue(
                ChatInstance(..chat, session: new_session, continuation: None),
              )
            }
            Some(Error(_e)) -> {
              actor.send(reply_with, None)
              actor.Stop(process.Normal)
            }
            None -> {
              actor.send(reply_with, Some(Nil))
              actor.continue(chat)
            }
          }
        }
      }
    }
    WaitHandlerChatInstanceMessage(handler: handler) ->
      actor.continue(ChatInstance(..chat, continuation: Some(handler)))
  }
}

// Context ----------------------------------------------------------------------------

/// Context holds information needed for the bot instance and the current update.
pub type Context(session) {
  Context(
    key: String,
    update: Update,
    config: Config,
    session: session,
    chat_subject: ChatInstanceSubject(session),
  )
}

fn new_context(
  chat chat: ChatInstance(session),
  update update,
) -> Context(session) {
  Context(
    update:,
    config: chat.config,
    key: chat.key,
    session: chat.session,
    chat_subject: chat.self,
  )
}

// Handler ------------------------------------------------------------------------

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

fn extract_update_handlers(handlers, update) {
  list.filter(handlers, fn(handler) {
    case handler, update {
      HandleAll(_), _ -> True
      HandleText(_), TextUpdate(..) -> True
      HandleHears(hears: hears, ..), TextUpdate(text: text, ..) ->
        check_hears(text, hears)
      HandleCommand(
        command: command,
        ..,
      ),
        CommandUpdate(
          command: update_command,
          ..,
        )
      -> update_command.command == command
      HandleCallbackQuery(filter: filter, ..), CallbackQueryUpdate(raw: raw, ..)
      ->
        case raw.data {
          Some(data) -> regexp.check(filter.re, data)
          None -> False
        }
      _, _ -> False
    }
  })
}

pub fn wait_handler(ctx: Context(session), handler) {
  process.send(ctx.chat_subject, WaitHandlerChatInstanceMessage(handler))
  Ok(ctx)
}

fn do_handle(chat chat, update update, handler handler) {
  // We already filtered update and receives only valid handler
  case handler, update {
    HandleAll(handler:), _ -> chat |> new_context(update) |> handler |> Some
    HandleText(handler:), TextUpdate(text: text, ..) ->
      chat |> new_context(update) |> handler(text) |> Some
    HandleHears(handler:, ..), TextUpdate(text: text, ..) ->
      chat |> new_context(update) |> handler(text) |> Some
    HandleCommand(handler:, ..), CommandUpdate(command: update_command, ..) ->
      chat |> new_context(update) |> handler(update_command) |> Some
    HandleCommands(handler:, ..), CommandUpdate(command: update_command, ..) ->
      chat |> new_context(update) |> handler(update_command) |> Some
    HandleCallbackQuery(handler:, ..), CallbackQueryUpdate(raw: raw, ..) ->
      case raw.data {
        Some(data) ->
          chat |> new_context(update) |> handler(data, raw.id) |> Some
        None -> None
      }
    _, _ -> None
  }
}

fn loop_handlers(chat chat, config config, update update, handlers handlers) {
  case handlers {
    [handler, ..rest] ->
      case do_handle(chat:, update:, handler:) {
        Some(Ok(Context(session: new_session, ..))) ->
          loop_handlers(
            chat: ChatInstance(..chat, session: new_session),
            handlers: rest,
            update:,
            config:,
          )
        Some(Error(e)) ->
          Error(
            "Failed to handle message " <> string.inspect(update) <> ": " <> e,
          )
        None -> loop_handlers(chat:, config:, update:, handlers: rest)
      }
    [] -> chat.session_settings.persist_session(chat.key, chat.session)
  }
}

// Hears --------------------------------------------------------------------------

pub type CallbackQueryFilter {
  CallbackQueryFilter(re: Regexp)
}

pub type Hears {
  HearText(text: String)
  HearTexts(texts: List(String))
  HearRegex(regex: Regexp)
  HearRegexes(regexes: List(Regexp))
}

fn check_hears(text, hear) -> Bool {
  case hear {
    HearText(str) -> text == str
    HearTexts(strings) -> list.contains(strings, text)
    HearRegex(re) -> regexp.check(re, text)
    HearRegexes(regexes) -> list.any(regexes, regexp.check(_, text))
  }
}

// Session --------------------------------------------------------------------------

pub type SessionSettings(session) {
  SessionSettings(
    // Calls after all handlers to persist the session.
    persist_session: fn(String, session) -> Result(session, String),
    // Calls on initialization of the chat instance to get the session.
    get_session: fn(String) -> Result(session, String),
    // Calls on initialization of the chat instance if no session is found.
    default_session: fn() -> session,
  )
}

pub fn next_session(ctx ctx, session session) {
  Ok(Context(..ctx, session:))
}

fn get_session_key(update) {
  case update {
    CommandUpdate(chat_id: chat_id, ..) -> Ok(int.to_string(chat_id))
    TextUpdate(chat_id: chat_id, ..) -> Ok(int.to_string(chat_id))
    CallbackQueryUpdate(from_id: from_id, ..) -> Ok(int.to_string(from_id))
    UnknownUpdate(..) ->
      Error("Unknown update type don't allow to get session key")
  }
}

pub fn get_session(
  session_settings: SessionSettings(session),
  update: Update,
) -> Result(session, String) {
  use key <- result.try(get_session_key(update))

  session_settings.get_session(key)
  |> result.map_error(fn(e) { "Failed to get session:\n " <> string.inspect(e) })
}

// Utilities -------------------------------------------------------------------------------

/// Set webhook for the bot.
pub fn set_webhook(config config: Config) {
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

pub fn fmt_update(ctx: Context(session)) {
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

const handle_update_timeout = 1000

// User should use methods from `telega` module.
@internal
pub fn handle_update(bot_subject bot_subject, update update) {
  actor.call(
    bot_subject,
    HandleUpdateBotMessage(update, _),
    handle_update_timeout,
  )
}
