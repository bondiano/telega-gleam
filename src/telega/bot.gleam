import gleam/erlang/process.{type Subject}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/otp/actor
import gleam/regexp.{type Regexp}
import gleam/result
import gleam/string
import gleam/time/duration
import gleam/time/timestamp.{type Timestamp}

import telega/internal/config.{type Config}
import telega/internal/log
import telega/internal/registry.{type RegistrySubject}

import telega/error
import telega/model.{type User}
import telega/update.{
  type Command, type Update, AudioUpdate, CallbackQueryUpdate, ChatMemberUpdate,
  CommandUpdate, MessageUpdate, TextUpdate, VideoUpdate, VoiceUpdate,
  WebAppUpdate,
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

pub fn start(
  registry_subject registry_subject: Subject(
    registry.RegistryMessage(ChatInstanceMessage(session, error)),
  ),
  config config: Config,
  bot_info bot_info: User,
  handlers handlers: List(Handler(session, error)),
  session_settings session_settings: SessionSettings(session, error),
  catch_handler catch_handler: CatchHandler(session, error),
) -> Result(Subject(BotMessage), error.TelegaError) {
  let self = process.new_subject()
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

  actor.new(bot)
  |> actor.on_message(bot_loop)
  |> actor.start
  |> result.map(fn(started) { started.data })
  |> result.map_error(error.BotStartError)
}

/// Stops waiting for any handler for specific key (chat_id)
pub fn cancel_conversation(bot bot: Bot(session, error), key key: String) -> Nil {
  actor.send(bot.self, CancelConversationBotMessage(key: key))
}

fn bot_loop(bot, message) {
  case message {
    HandleUpdateBotMessage(update:, reply_with:) -> {
      case handle_update_bot_message(bot:, update:, reply_with:) {
        Ok(_) -> actor.continue(bot)
        Error(error) -> {
          log.error_d("Error in handler: ", error)
          actor.stop()
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
      actor.send(
        chat_subject,
        HandleNewChatInstanceMessage(update:, handlers:, reply_with:),
      )
      |> Ok
    }
    None -> {
      use subject <- result.try(start_chat_instance(
        key:,
        config: bot.config,
        session_settings: bot.session_settings,
        catch_handler: bot.catch_handler,
      ))
      let chat_subject =
        registry.register(key:, in: bot.registry_subject, subject:)

      let handlers = extract_update_handlers(bot.handlers, update)
      actor.send(
        chat_subject,
        HandleNewChatInstanceMessage(update:, handlers:, reply_with:),
      )
      |> Ok
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
  WaitHandlerChatInstanceMessage(
    handler: Handler(session, error),
    handle_else: Option(Handler(session, error)),
    timeout: Option(Int),
  )
}

type Continuation(session, error) {
  Continuation(
    handler: Handler(session, error),
    handle_else: Option(Handler(session, error)),
    ttl: Option(Timestamp),
  )
}

type ChatInstance(session, error) {
  ChatInstance(
    key: String,
    session: session,
    config: Config,
    catch_handler: CatchHandler(session, error),
    session_settings: SessionSettings(session, error),
    self: ChatInstanceSubject(session, error),
    continuation: Option(Continuation(session, error)),
  )
}

const initialisation_timeout = 100

fn start_chat_instance(
  key key: String,
  config config: Config,
  session_settings session_settings: SessionSettings(session, error),
  catch_handler catch_handler: CatchHandler(session, error),
) {
  let session = case session_settings.get_session(key) {
    Ok(Some(session)) -> session
    Ok(None) -> session_settings.default_session()
    Error(error) ->
      panic as { "Failed to get session: " <> string.inspect(error) }
  }

  use started <- result.try(
    actor.new_with_initialiser(initialisation_timeout, fn(subject) {
      let chat_instance =
        ChatInstance(
          key:,
          config:,
          session:,
          session_settings:,
          catch_handler:,
          self: subject,
          continuation: None,
        )
      actor.initialised(chat_instance)
      |> actor.returning(subject)
      |> Ok
    })
    |> actor.on_message(loop_chat_instance)
    |> actor.start
    |> result.map_error(error.ChatInstanceStartError),
  )

  Ok(started.data)
}

fn loop_chat_instance(chat: ChatInstance(session, error), message) {
  case message {
    HandleNewChatInstanceMessage(update:, handlers:, reply_with:) ->
      do_handle_new_chat_instance_message(
        context: new_context(chat:, update:),
        chat:,
        update:,
        handlers:,
        reply_with:,
      )
    WaitHandlerChatInstanceMessage(handler:, handle_else:, timeout:) ->
      ChatInstance(
        ..chat,
        continuation: Continuation(handler:, handle_else:, ttl: {
            use timeout <- option.map(timeout)
            timestamp.system_time()
            |> timestamp.add(duration.seconds(timeout))
          })
          |> Some,
      )
      |> actor.continue
  }
}

fn do_handle_new_chat_instance_message(
  context context: Context(session, error),
  chat chat: ChatInstance(session, error),
  update update,
  handlers handlers,
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
                handlers:,
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
        loop_handlers(chat:, context:, update:, handlers:, config: chat.config)
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
              actor.stop()
            }
          }
        }
      }
  }
}

fn do_handle_continuation(
  context context: Context(session, error),
  continuation continuation: Continuation(session, error),
  update update: Update,
  reply_with reply_with: Subject(Bool),
  chat chat: ChatInstance(session, error),
) {
  case do_handle(context:, update:, handler: continuation.handler) {
    Some(Ok(Context(session: new_session, ..))) -> {
      // Persist the new session after continuation completes
      case chat.session_settings.persist_session(chat.key, new_session) {
        Ok(persisted_session) -> {
          actor.send(reply_with, True)
          actor.continue(
            ChatInstance(..chat, session: persisted_session, continuation: None),
          )
        }
        Error(e) -> {
          case chat.catch_handler(context, e) {
            Ok(_) -> {
              actor.send(reply_with, False)
              actor.continue(chat)
            }
            Error(e) -> {
              log.error_d(
                "Error in session persistence after continuation: ",
                e,
              )
              actor.stop()
            }
          }
        }
      }
    }
    Some(Error(e)) -> {
      case chat.catch_handler(context, e) {
        Ok(_) -> {
          actor.send(reply_with, False)
          actor.continue(chat)
        }
        Error(e) -> {
          log.error_d("Error in catch handler: ", e)
          actor.stop()
        }
      }
    }
    None -> {
      case continuation.handle_else {
        Some(handler) ->
          case do_handle(context:, update:, handler:) {
            Some(Ok(Context(session: new_session, ..))) -> {
              // Persist the new session after handle_else completes
              case
                chat.session_settings.persist_session(chat.key, new_session)
              {
                Ok(persisted_session) -> {
                  actor.send(reply_with, True)
                  actor.continue(
                    ChatInstance(..chat, session: persisted_session),
                  )
                }
                Error(e) -> {
                  case chat.catch_handler(context, e) {
                    Ok(_) -> {
                      actor.send(reply_with, False)
                      actor.continue(chat)
                    }
                    Error(e) -> {
                      log.error_d(
                        "Error in session persistence after handle_else: ",
                        e,
                      )
                      actor.stop()
                    }
                  }
                }
              }
            }
            Some(Error(e)) -> {
              case chat.catch_handler(context, e) {
                Ok(_) -> {
                  actor.send(reply_with, False)
                  actor.continue(chat)
                }
                Error(e) -> {
                  log.error_d("Error in catch else handler: ", e)
                  actor.stop()
                }
              }
            }
            None -> {
              actor.send(reply_with, False)
              actor.continue(chat)
            }
          }
        None -> {
          actor.send(reply_with, False)
          actor.continue(chat)
        }
      }
    }
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
    /// Used to calculate the duration of the conversation in logs
    start_time: Option(Timestamp),
    log_prefix: Option(String),
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
    start_time: None,
    log_prefix: None,
  )
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

pub fn next_session(
  ctx ctx: Context(session, error),
  session session: session,
) -> Result(Context(session, error), error) {
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

// User should use methods from `telega` module.
@internal
pub fn handle_update(bot_subject bot_subject, update update) {
  process.call_forever(bot_subject, HandleUpdateBotMessage(update, _))
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

// Handler ------------------------------------------------------------------------

pub type Handler(session, error) {
  /// Handle all messages.
  HandleAll(
    handler: fn(Context(session, error), Update) ->
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
  /// Handle any message.
  HandleMessage(
    handler: fn(Context(session, error), model.Message) ->
      Result(Context(session, error), error),
  )
  /// Handle voice messages.
  HandleVoice(
    handler: fn(Context(session, error), model.Voice) ->
      Result(Context(session, error), error),
  )
  /// Handle audio messages.
  HandleAudio(
    handler: fn(Context(session, error), model.Audio) ->
      Result(Context(session, error), error),
  )
  /// Handle video messages.
  HandleVideo(
    handler: fn(Context(session, error), model.Video) ->
      Result(Context(session, error), error),
  )
  /// Handle photo messages.
  HandlePhotos(
    handler: fn(Context(session, error), List(model.PhotoSize)) ->
      Result(Context(session, error), error),
  )
  /// Handle web app data messages.
  HandleWebAppData(
    handler: fn(Context(session, error), model.WebAppData) ->
      Result(Context(session, error), error),
  )
  /// Handle callback query. Context, data from callback query and `callback_query_id` are passed to the handler.
  HandleCallbackQuery(
    filter: CallbackQueryFilter,
    handler: fn(Context(session, error), String, String) ->
      Result(Context(session, error), error),
  )
  /// Handle chat member update (when user joins/leaves a group). The bot must be an administrator in the chat and must explicitly specify "chat_member" in the list of `allowed_updates` to receive these updates.
  HandleChatMember(
    handler: fn(Context(session, error), model.ChatMemberUpdated) ->
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

/// Pass any handler to start waiting
///
/// `or` - calls if there are any other updates
/// `timeout` - the conversation will be canceled after this timeout
pub fn wait_handler(
  ctx ctx: Context(session, error),
  handler handler: Handler(session, error),
  handle_else handle_else: Option(Handler(session, error)),
  timeout timeout: Option(Int),
) -> Result(Context(session, error), error) {
  actor.send(
    ctx.chat_subject,
    WaitHandlerChatInstanceMessage(handler:, handle_else:, timeout:),
  )
  Ok(ctx)
}

fn do_handle(context context, update update, handler handler) {
  // We already filtered updates and receives only valid handlers
  case handler, update {
    HandleAll(handler:), _ -> context |> handler(update) |> Some
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
    HandleMessage(handler:), MessageUpdate(message:, ..) ->
      context |> handler(message) |> Some
    HandleChatMember(handler:), ChatMemberUpdate(chat_member_updated:, ..) ->
      context |> handler(chat_member_updated) |> Some
    HandleVoice(handler:), VoiceUpdate(voice:, ..) ->
      context |> handler(voice) |> Some
    HandleAudio(handler:), AudioUpdate(audio:, ..) ->
      context |> handler(audio) |> Some
    HandleVideo(handler:), VideoUpdate(video:, ..) ->
      context |> handler(video) |> Some
    HandleWebAppData(handler:), WebAppUpdate(web_app_data:, ..) ->
      context |> handler(web_app_data) |> Some
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
    [] -> chat.session_settings.persist_session(chat.key, context.session)
  }
}
