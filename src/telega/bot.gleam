import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/regexp.{type Regexp}
import gleam/result
import gleam/string
import telega/internal/log

import telega/internal/config.{type Config}
import telega/internal/registry.{type RegistrySubject}

import telega/error
import telega/model.{type User}
import telega/update.{
  type Command, type Update, CallbackQueryUpdate, CommandUpdate, TextUpdate,
}

/// Stores information about running bot instance
pub opaque type Bot(session, error) {
  Bot(
    self: BotSubject,
    config: Config,
    bot_info: User,
    catch_handler: CatchHandler(session, error),
    session_settings: SessionSettings(session, error),
    handlers: List(Handler(session, error)),
    registry_subject: RegistrySubject(ChatInstanceMessage(session, error)),
  )
}

pub type BotSubject =
  Subject(BotMessage)

pub opaque type BotMessage {
  CancelConversationBotMessage(key: String)
  // `reply_with` is a subject with `is_ok` field
  // It is used to notify the adapter that the update was handled successfully or not
  HandleUpdateBotMessage(update: Update, reply_with: Subject(Bool))
}

/// Handler called when an error occurs in handler
/// If handler returns `Error`, the bot will be stopped and the error will be logged
/// The default handler is `fn(_) -> Ok(Nil)`, which will do nothing if handler returns an error
pub type CatchHandler(session, error) =
  fn(Context(session, error), error) -> Result(Nil, error)

const bot_actor_init_timeout = 500

pub fn start(
  registry_subject registry_subject,
  config config,
  bot_info bot_info,
  handlers handlers,
  session_settings session_settings,
  catch_handler catch_handler,
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
          catch_handler:,
        )

      actor.Ready(bot, selector)
    },
    loop: bot_loop,
    init_timeout: bot_actor_init_timeout,
  ))
  |> result.map_error(fn(err) { error.BotStartError(string.inspect(err)) })
}

/// Stops waiting for any handler for specific key (chat_id)
pub fn cancel_conversation(bot bot: Bot(session, error), key key) {
  actor.send(bot.self, CancelConversationBotMessage(key: key))
}

fn bot_loop(message, bot) {
  case message {
    HandleUpdateBotMessage(update:, reply_with:) -> {
      case handle_update_bot_message(bot:, update:, reply_with:) {
        Ok(_) -> actor.continue(bot)
        Error(error) -> {
          log.error_d("Error in handler: ", error)
          actor.Stop(process.Normal)
        }
      }
    }
    CancelConversationBotMessage(key:) -> {
      registry.unregister(bot.registry_subject, key)
      actor.continue(bot)
    }
  }
}

fn handle_update_bot_message(
  bot bot: Bot(session, error),
  update update,
  reply_with reply_with,
) {
  let key = build_session_key(update)

  case registry.get(key:, in: bot.registry_subject) {
    Some(chat_subject) -> {
      let handlers = extract_update_handlers(bot.handlers, update)
      handle_update_chat_instance(
        chat_subject:,
        update:,
        handlers:,
        reply_with:,
      )
    }
    None -> {
      use chat_subject <- result.try(start_chat_instance(
        key:,
        config: bot.config,
        session_settings: bot.session_settings,
        catch_handler: bot.catch_handler,
      ))
      registry.register(key:, in: bot.registry_subject, subject: chat_subject)

      let handlers = extract_update_handlers(bot.handlers, update)
      handle_update_chat_instance(
        chat_subject:,
        update:,
        handlers:,
        reply_with:,
      )
    }
  }
}

// Chat Instance --------------------------------------------------------------------

pub type ChatInstanceSubject(session, error) =
  Subject(ChatInstanceMessage(session, error))

pub opaque type ChatInstanceMessage(session, error) {
  HandleNewChatInstanceMessage(
    update: Update,
    handlers: List(Handler(session, error)),
    reply_with: Subject(Bool),
  )
  WaitHandlerChatInstanceMessage(handler: Handler(session, error))
}

type ChatInstance(session, error) {
  ChatInstance(
    key: String,
    session: session,
    config: Config,
    catch_handler: CatchHandler(session, error),
    session_settings: SessionSettings(session, error),
    self: ChatInstanceSubject(session, error),
    continuation: Option(Handler(session, error)),
  )
}

const chat_instance_actor_init_timeout = 250

fn start_chat_instance(
  key key: String,
  config config: Config,
  session_settings session_settings: SessionSettings(session, error),
  catch_handler catch_handler: CatchHandler(session, error),
) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let self = process.new_subject()
      let selector =
        process.new_selector() |> process.selecting(self, function.identity)

      let session = case session_settings.get_session(key) {
        Ok(Some(session)) -> session
        Ok(None) -> session_settings.default_session()
        Error(error) ->
          panic as { "Failed to get session: " <> string.inspect(error) }
      }

      let chat_instance =
        ChatInstance(
          key:,
          config:,
          session:,
          self:,
          session_settings:,
          catch_handler:,
          continuation: None,
        )

      actor.Ready(chat_instance, selector)
    },
    loop: loop_chat_instance,
    init_timeout: chat_instance_actor_init_timeout,
  ))
  |> result.map_error(fn(error) {
    error.ChatInstanceStartError(string.inspect(error))
  })
}

fn handle_update_chat_instance(
  chat_subject chat_subject,
  update update,
  handlers handlers: List(Handler(session, error)),
  reply_with reply_with,
) {
  actor.send(
    chat_subject,
    HandleNewChatInstanceMessage(update:, handlers:, reply_with:),
  )
  |> Ok
}

fn loop_chat_instance(message, chat: ChatInstance(session, error)) {
  case message {
    HandleNewChatInstanceMessage(update:, handlers:, reply_with:) -> {
      let context = new_context(chat:, update:)
      case chat.continuation {
        None ->
          case
            loop_handlers(
              chat:,
              context:,
              update:,
              handlers:,
              config: chat.config,
            )
          {
            Ok(new_session) -> {
              actor.send(reply_with, True)
              actor.continue(ChatInstance(..chat, session: new_session))
            }
            Error(e) -> {
              case chat.catch_handler(context, e) {
                Ok(_) -> {
                  actor.send(reply_with, False)
                  actor.continue(chat)
                }
                Error(e) -> {
                  log.error_d("Error in catch handler: ", e)
                  actor.Stop(process.Normal)
                }
              }
            }
          }
        // There is a continuation, handle the update with it
        Some(handler) -> {
          case do_handle(context:, update:, handler:) {
            Some(Ok(Context(session: new_session, ..))) -> {
              actor.send(reply_with, True)
              actor.continue(
                ChatInstance(..chat, session: new_session, continuation: None),
              )
            }
            Some(Error(e)) -> {
              case chat.catch_handler(context, e) {
                Ok(_) -> {
                  actor.send(reply_with, False)
                  actor.continue(chat)
                }
                Error(e) -> {
                  log.error_d("Error in catch handler: ", e)
                  actor.Stop(process.Normal)
                }
              }
            }
            None -> {
              actor.send(reply_with, True)
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
pub type Context(session, error) {
  Context(
    key: String,
    update: Update,
    config: Config,
    session: session,
    chat_subject: ChatInstanceSubject(session, error),
  )
}

fn new_context(
  chat chat: ChatInstance(session, error),
  update update,
) -> Context(session, error) {
  Context(
    update:,
    config: chat.config,
    key: chat.key,
    session: chat.session,
    chat_subject: chat.self,
  )
}

// Handler ------------------------------------------------------------------------

pub type Handler(session, error) {
  /// Handle all messages.
  HandleAll(
    handler: fn(Context(session, error)) ->
      Result(Context(session, error), error),
  )
  /// Handle a specific command.
  HandleCommand(
    command: String,
    handler: fn(Context(session, error), Command) ->
      Result(Context(session, error), error),
  )
  /// Handle multiple commands.
  HandleCommands(
    commands: List(String),
    handler: fn(Context(session, error), Command) ->
      Result(Context(session, error), error),
  )
  /// Handle text messages.
  HandleText(
    handler: fn(Context(session, error), String) ->
      Result(Context(session, error), error),
  )
  /// Handle text message with a specific substring.
  HandleHears(
    hears: Hears,
    handler: fn(Context(session, error), String) ->
      Result(Context(session, error), error),
  )
  /// Handle callback query. Context, data from callback query and `callback_query_id` are passed to the handler.
  HandleCallbackQuery(
    filter: CallbackQueryFilter,
    handler: fn(Context(session, error), String, String) ->
      Result(Context(session, error), error),
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
      HandleCallbackQuery(filter: filter, ..), CallbackQueryUpdate(query:, ..) ->
        case query.data {
          Some(data) -> regexp.check(filter.re, data)
          None -> False
        }
      _, _ -> False
    }
  })
}

pub fn wait_handler(ctx: Context(session, error), handler) {
  process.send(ctx.chat_subject, WaitHandlerChatInstanceMessage(handler))
  Ok(ctx)
}

fn do_handle(context context, update update, handler handler) {
  // We already filtered updates and receives only valid handlers
  case handler, update {
    HandleAll(handler:), _ -> context |> handler |> Some
    HandleText(handler:), TextUpdate(text: text, ..) ->
      context |> handler(text) |> Some
    HandleHears(handler:, ..), TextUpdate(text: text, ..) ->
      context |> handler(text) |> Some
    HandleCommand(handler:, ..), CommandUpdate(command: update_command, ..) ->
      context |> handler(update_command) |> Some
    HandleCommands(handler:, ..), CommandUpdate(command: update_command, ..) ->
      context |> handler(update_command) |> Some
    HandleCallbackQuery(handler:, ..), CallbackQueryUpdate(query:, ..) -> {
      use data <- option.map(query.data)
      handler(context, data, query.id)
    }
    _, _ -> None
  }
}

fn loop_handlers(
  chat chat: ChatInstance(session, error),
  context context,
  config config,
  update update,
  handlers handlers,
) {
  case handlers {
    [handler, ..rest] ->
      case do_handle(context:, update:, handler:) {
        Some(Ok(Context(session: new_session, ..))) ->
          loop_handlers(
            chat:,
            context: Context(..context, session: new_session),
            handlers: rest,
            update:,
            config:,
          )
        Some(Error(e)) -> Error(e)
        None -> loop_handlers(chat:, context:, config:, update:, handlers: rest)
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

pub type SessionSettings(session, error) {
  SessionSettings(
    // Calls after all handlers to persist the session.
    persist_session: fn(String, session) -> Result(session, error),
    // Calls on initialization of the chat instance to get the session.
    // Returns `None` if no session is found.
    // **It will crash starting session process if error is returned.**
    get_session: fn(String) -> Result(Option(session), error),
    // Calls on initialization of the chat instance if no session is found.
    default_session: fn() -> session,
  )
}

pub fn next_session(ctx ctx, session session) {
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

// Utilities -------------------------------------------------------------------------------

pub fn update_to_string(update: Update) {
  case update {
    CommandUpdate(command:, chat_id:, ..) ->
      "command \"" <> command.command <> "\" from " <> int.to_string(chat_id)
    TextUpdate(text:, chat_id:, ..) ->
      "text \"" <> text <> "\" from " <> int.to_string(chat_id)
    CallbackQueryUpdate(query:, from_id:, ..) ->
      "callback query "
      <> option.unwrap(query.data, "no data")
      <> " from "
      <> int.to_string(from_id)
  }
}

// User should use methods from `telega` module.
@internal
pub fn handle_update(bot_subject bot_subject, update update) {
  process.try_call_forever(bot_subject, HandleUpdateBotMessage(update, _))
}
