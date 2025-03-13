//// This module provides an interface for interacting with the Telegram Bot API.
//// It will be useful if you want to interact with the Telegram Bot API directly, without running a bot.
//// But it will be more convenient to use the `reply` module in bot handlers.

import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http.{Get, Post}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response, Response}
import gleam/httpc
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/log
import telega/model.{
  type BotCommand, type BotCommandScope, type File, type InlineKeyboardButton,
  type InlineKeyboardMarkup, type IntOrString, type KeyboardButton,
  type LinkPreviewOptions, type LoginUrl, type Message as ModelMessage,
  type MessageEntity, type ReplyKeyboardMarkup, type ReplyParameters,
  type SwitchInlineQueryChosenChat, type User,
}

const default_retry_delay = 1000

pub type TelegramApiConfig {
  TelegramApiConfig(
    token: String,
    /// The maximum number of times to retry sending a API message. Default is 3.
    max_retry_attempts: Int,
    /// The Telegram Bot API URL. Default is "https://api.telegram.org".
    /// This is useful for running [a local server](https://core.telegram.org/bots/api#using-a-local-bot-api-server).
    tg_api_url: String,
  )
}

pub fn new_api_config(token token: String) -> TelegramApiConfig {
  TelegramApiConfig(
    token,
    max_retry_attempts: 3,
    tg_api_url: "https://api.telegram.org",
  )
}

type TelegramApiRequest {
  TelegramApiPostRequest(
    url: String,
    body: String,
    query: Option(List(#(String, String))),
  )
  TelegramApiGetRequest(url: String, query: Option(List(#(String, String))))
}

type ApiResponse(result) {
  ApiResponse(ok: Bool, result: result)
}

// TODO: Support all options from the official reference.
/// Set the webhook URL using [setWebhook](https://core.telegram.org/bots/api#setwebhook) API.
///
/// **Official reference:** https://core.telegram.org/bots/api#setwebhook
pub fn set_webhook(
  config config: TelegramApiConfig,
  parameters parameters: SetWebhookParameters,
) -> Result(Bool, String) {
  let body = encode_set_webhook_parameters(parameters)

  new_post_request(
    config,
    path: "setWebhook",
    body: json.to_string(body),
    query: None,
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to get current webhook status.
///
/// **Official reference:** https://core.telegram.org/bots/api#getwebhookinfo
pub fn get_webhook_info(config config) {
  new_get_request(config, path: "getWebhookInfo", query: None)
  |> fetch(config)
  |> map_response(model.webhook_info_decoder())
}

/// Use this method to remove webhook integration if you decide to switch back to [getUpdates](https://core.telegram.org/bots/api#getupdates).
///
/// **Official reference:** https://core.telegram.org/bots/api#deletewebhook
pub fn delete_webhook(config config: TelegramApiConfig) {
  new_get_request(config, path: "deleteWebhook", query: None)
  |> fetch(config)
  |> map_response(decode.bool)
}

/// The same as [delete_webhook](#delete_webhook) but also drops all pending updates.
pub fn delete_webhook_and_drop_updates(config config) {
  new_get_request(
    config,
    path: "deleteWebhook",
    query: Some([#("drop_pending_updates", "true")]),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to log out from the cloud Bot API server before launching the bot locally.
/// You **must** log out the bot before running it locally, otherwise there is no guarantee that the bot will receive updates.
/// After a successful call, you can immediately log in on a local server, but will not be able to log in back to the cloud Bot API server for 10 minutes.
///
/// **Official reference:** https://core.telegram.org/bots/api#logout
pub fn log_out(config config: TelegramApiConfig) {
  new_get_request(config, path: "logOut", query: None)
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to close the bot instance before moving it from one local server to another.
/// You need to delete the webhook before calling this method to ensure that the bot isn't launched again after server restart.
/// The method will return error 429 in the first 10 minutes after the bot is launched.
///
/// **Official reference:** https://core.telegram.org/bots/api#close
pub fn close(config config: TelegramApiConfig) {
  new_get_request(config, path: "close", query: None)
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to send text messages with additional parameters.
///
/// **Official reference:** https://core.telegram.org/bots/api#sendmessage
pub fn send_message(
  config config: TelegramApiConfig,
  parameters parameters: SendMessageParameters,
) {
  let body_json = encode_send_message_parameters(parameters)

  new_post_request(
    config,
    path: "sendMessage",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to change the list of the bot's commands. See [commands documentation](https://core.telegram.org/bots/features#commands) for more details about bot commands.
///
/// **Official reference:** https://core.telegram.org/bots/api#setmycommands
pub fn set_my_commands(
  config config: TelegramApiConfig,
  commands commands: List(BotCommand),
  parameters parameters: Option(BotCommandParameters),
) {
  let parameters =
    option.unwrap(parameters, default_bot_command_parameters())
    |> encode_bot_command_parameters()

  let body_json =
    json.object([
      #(
        "commands",
        json.array(commands, fn(command: BotCommand) {
          json.object([
            #("command", json.string(command.command)),
            #("description", json.string(command.description)),
            ..parameters
          ])
        }),
      ),
    ])

  new_post_request(
    config,
    path: "setMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to delete the list of the bot's commands for the given scope and user language.
/// After deletion, [higher level commands](https://core.telegram.org/bots/api#determining-list-of-commands) will be shown to affected users.
///
/// **Official reference:** https://core.telegram.org/bots/api#deletemycommands
pub fn delete_my_commands(
  config config: TelegramApiConfig,
  parameters parameters: Option(BotCommandParameters),
) {
  let parameters =
    option.unwrap(parameters, default_bot_command_parameters())
    |> encode_bot_command_parameters()

  let body_json = json.object(parameters)

  new_post_request(
    config,
    path: "deleteMyCommands",
    body: json.to_string(body_json),
    query: None,
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to get the current list of the bot's commands for the given scope and user language.
///
/// **Official reference:** https://core.telegram.org/bots/api#getmycommands
pub fn get_my_commands(
  config config: TelegramApiConfig,
  parameters parameters: Option(BotCommandParameters),
) {
  let parameters =
    option.unwrap(parameters, default_bot_command_parameters())
    |> encode_bot_command_parameters()

  let body_json = json.object(parameters)

  new_post_request(
    config,
    path: "getMyCommands",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.bot_command_decoder())
}

/// Use this method to send an animated emoji that will display a random value.
///
/// **Official reference:** https://core.telegram.org/bots/api#senddice
pub fn send_dice(
  config config: TelegramApiConfig,
  parameters parameters: SendDiceParameters,
) {
  let body_json = encode_send_dice_parameters(parameters)

  new_post_request(
    config:,
    path: "sendDice",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// A simple method for testing your bot's authentication token.
///
/// **Official reference:** https://core.telegram.org/bots/api#getme
pub fn get_me(config config: TelegramApiConfig) {
  new_get_request(config, path: "getMe", query: None)
  |> fetch(config)
  |> map_response(model.user_decoder())
}

/// Use this method to send answers to callback queries sent from inline keyboards.
/// The answer will be displayed to the user as a notification at the top of the chat screen or as an alert.
/// On success, _True_ is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#answercallbackquery
pub fn answer_callback_query(
  config config: TelegramApiConfig,
  parameters parameters: AnswerCallbackQueryParameters,
) -> Result(Bool, String) {
  let body_json = encode_answer_callback_query_parameters(parameters)

  new_post_request(
    config:,
    path: "answerCallbackQuery",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

/// Use this method to edit text and game messages.
/// On success, if the edited message is not an inline message, the edited Message is returned, otherwise True is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#editmessagetext
pub fn edit_message_text(
  config config: TelegramApiConfig,
  parameters parameters: EditMessageTextParameters,
) -> Result(ModelMessage, String) {
  let body_json = encode_edit_message_text_parameters(parameters)

  new_post_request(
    config:,
    path: "editMessageText",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to forward messages of any kind. Service messages and messages with protected content can't be forwarded.
/// On success, the sent Message is returned.
///
/// **Official reference:** https://core.telegram.org/bots/api#forwardmessage
pub fn forward_message(
  config config: TelegramApiConfig,
  parameters parameters: ForwardMessageParameters,
) -> Result(ModelMessage, String) {
  let body_json = encode_forward_message_parameters(parameters)

  new_post_request(
    config:,
    path: "forwardMessage",
    query: None,
    body: json.to_string(body_json),
  )
  |> fetch(config)
  |> map_response(model.message_decoder())
}

/// Use this method to change the bot's menu button in a private chat, or the default menu button. Returns True on success.
///
/// **Official reference:** https://core.telegram.org/bots/api#setchatmenubutton
pub fn set_chat_menu_button(
  config config: TelegramApiConfig,
  parameters parameters: SetChatMenuButtonParameters,
) -> Result(Bool, String) {
  new_post_request(
    config:,
    path: "setChatMenuButton",
    query: None,
    body: encode_set_chat_menu_button_parameters(parameters)
      |> json.to_string(),
  )
  |> fetch(config)
  |> map_response(decode.bool)
}

fn build_url(config: TelegramApiConfig, path: String) -> String {
  config.tg_api_url <> config.token <> "/" <> path
}

pub fn get_file(
  config config: TelegramApiConfig,
  file_id file_id: String,
) -> Result(File, String) {
  new_get_request(config, path: "getFile", query: Some([#("file_id", file_id)]))
  |> fetch(config)
  |> map_response(model.file_decoder())
}

fn new_post_request(
  config config: TelegramApiConfig,
  path path: String,
  body body: String,
  query query: Option(List(#(String, String))),
) {
  TelegramApiPostRequest(url: build_url(config, path), body: body, query: query)
}

fn new_get_request(
  config config: TelegramApiConfig,
  path path: String,
  query query: Option(List(#(String, String))),
) {
  TelegramApiGetRequest(url: build_url(config, path), query: query)
}

fn set_query(
  api_request: Request(String),
  query: Option(List(#(String, String))),
) -> Request(String) {
  case query {
    None -> api_request
    Some(query) -> {
      request.set_query(api_request, query)
    }
  }
}

fn api_to_request(
  api_request: TelegramApiRequest,
) -> Result(Request(String), String) {
  case api_request {
    TelegramApiGetRequest(url: url, query: query) -> {
      request.to(url)
      |> result.map(request.set_method(_, Get))
      |> result.map(set_query(_, query))
    }
    TelegramApiPostRequest(url: url, query: query, body: body) -> {
      request.to(url)
      |> result.map(request.set_body(_, body))
      |> result.map(request.set_method(_, Post))
      |> result.map(request.set_header(_, "Content-Type", "application/json"))
      |> result.map(set_query(_, query))
    }
  }
  |> result.map_error(fn(error) {
    "Failed to convert API request to HTTP request: " <> string.inspect(error)
  })
}

fn map_response(
  response: Result(Response(String), String),
  result_decoder,
) -> Result(a, String) {
  response
  |> result.map(fn(response) {
    json.decode(from: response.body, using: parse_api_response(
      _,
      result_decoder,
    ))
    |> result.replace_error("Failed to decode response: " <> response.body)
    |> result.map(fn(response) { response.result })
  })
  |> result.flatten
}

fn parse_api_response(json, result_decoder) {
  decode.run(json, response_decoder(result_decoder))
  |> result.map_error(fn(errors) {
    list.map(errors, fn(error) {
      dynamic.DecodeError(
        expected: error.expected,
        found: error.found,
        path: error.path,
      )
    })
  })
}

// TODO: decode error
fn response_decoder(result_decoder) {
  use ok <- decode.field("ok", decode.bool)
  use result <- decode.field("result", result_decoder)

  decode.success(ApiResponse(ok: ok, result: result))
}

// TODO: add rate limit handling
fn fetch(
  api_request: TelegramApiRequest,
  config: TelegramApiConfig,
) -> Result(Response(String), String) {
  use api_request <- result.try(api_to_request(api_request))

  send_with_retry(api_request, config.max_retry_attempts)
  |> result.map_error(fn(error) {
    log.info("Api request failed with error:" <> string.inspect(error))

    dynamic.string(error)
    |> result.unwrap("Failed to send request")
  })
}

fn send_with_retry(
  api_request: Request(String),
  retries: Int,
) -> Result(Response(String), Dynamic) {
  let response = httpc.send(api_request)

  case retries {
    0 -> response |> result.map_error(dynamic.from)
    _ -> {
      case response {
        Ok(response) -> {
          case response.status {
            429 -> {
              log.warn("Telegram API throttling, HTTP 429 'Too Many Requests'")
              // TODO: remake it with smart request balancer
              // https://github.com/energizer91/smart-request-balancer/tree/master - for reference
              process.sleep(default_retry_delay)
              send_with_retry(api_request, retries - 1)
            }
            _ -> Ok(response)
          }
        }
        Error(_) -> {
          process.sleep(default_retry_delay)
          send_with_retry(api_request, retries - 1)
        }
      }
    }
  }
}

// AnswerCallbackQueryParameters --------------------------------------------------------------------------------------
// https://core.telegram.org/bots/api#answercallbackquery
pub type AnswerCallbackQueryParameters {
  AnswerCallbackQueryParameters(
    /// Unique identifier for the query to be answered
    callback_query_id: String,
    /// Text of the notification. If not specified, nothing will be shown to the user
    text: Option(String),
    /// If true, an alert will be shown by the client instead of a notification at the top of the chat screen. Defaults to false.
    show_alert: Option(Bool),
    /// URL that will be opened by the user's client. If you have created a [Game](https://core.telegram.org/bots/api#games), you can use this
    /// field to redirect the player to your game
    url: Option(String),
    /// The maximum amount of time in seconds that the result of the callback query may be cached client-side. Telegram apps will support
    /// caching starting in version 3.14. Defaults to 0.
    cache_time: Option(Int),
  )
}

pub fn new_answer_callback_query_parameters(
  callback_query_id: String,
) -> AnswerCallbackQueryParameters {
  AnswerCallbackQueryParameters(
    callback_query_id: callback_query_id,
    text: None,
    show_alert: None,
    url: None,
    cache_time: None,
  )
}

pub fn encode_answer_callback_query_parameters(
  params: AnswerCallbackQueryParameters,
) -> Json {
  let callback_query_id = #(
    "callback_query_id",
    json.string(params.callback_query_id),
  )
  let text = #("text", json.nullable(params.text, json.string))
  let show_alert = #("show_alert", json.nullable(params.show_alert, json.bool))
  let url = #("url", json.nullable(params.url, json.string))
  let cache_time = #("cache_time", json.nullable(params.cache_time, json.int))

  json_object_filter_nulls([
    callback_query_id,
    text,
    show_alert,
    url,
    cache_time,
  ])
}

// BotCommandParameters ---------------------------------------------------------------------

pub type BotCommandParameters {
  BotCommandParameters(
    /// An object, describing scope of users for which the commands are relevant. Defaults to `BotCommandScopeDefault`.
    scope: Option(BotCommandScope),
    /// A two-letter ISO 639-1 language code. If empty, commands will be applied to all users from the given scope, for whose language there are no dedicated commands
    language_code: Option(String),
  )
}

pub fn default_bot_command_parameters() -> BotCommandParameters {
  BotCommandParameters(scope: None, language_code: None)
}

pub fn encode_bot_command_parameters(
  params: BotCommandParameters,
) -> List(#(String, Json)) {
  [
    #("scope", json.nullable(params.scope, bot_command_scope_to_json)),
    #("language_code", json.nullable(params.language_code, json.string)),
  ]
}

pub fn bot_command_scope_to_json(scope: BotCommandScope) {
  case scope {
    model.BotCommandScopeDefaultBotCommandScope(_) ->
      json_object_filter_nulls([#("type", json.string("default"))])
    model.BotCommandScopeAllPrivateChatsBotCommandScope(_) ->
      json_object_filter_nulls([#("type", json.string("all_private_chats"))])
    model.BotCommandScopeAllGroupChatsBotCommandScope(_) ->
      json_object_filter_nulls([#("type", json.string("all_group_chats"))])
    model.BotCommandScopeAllChatAdministratorsBotCommandScope(_) ->
      json_object_filter_nulls([
        #("type", json.string("all_chat_administrators")),
      ])
    model.BotCommandScopeChatBotCommandScope(model.BotCommandScopeChat(
      chat_id: chat_id,
      ..,
    )) ->
      json_object_filter_nulls([
        #("type", json.string("chat")),
        #("chat_id", encode_int_or_string(chat_id)),
      ])
    model.BotCommandScopeChatAdministratorsBotCommandScope(model.BotCommandScopeChatAdministrators(
      chat_id: chat_id,
      ..,
    )) ->
      json_object_filter_nulls([
        #("type", json.string("chat_administrators")),
        #("chat_id", encode_int_or_string(chat_id)),
      ])
    model.BotCommandScopeChatMemberBotCommandScope(model.BotCommandScopeChatMember(
      chat_id: chat_id,
      user_id: user_id,
      ..,
    )) ->
      json_object_filter_nulls([
        #("type", json.string("chat_member")),
        #("chat_id", encode_int_or_string(chat_id)),
        #("user_id", json.int(user_id)),
      ])
  }
}

pub fn bot_commands_from(commands: List(#(String, String))) -> List(BotCommand) {
  commands
  |> list.map(fn(command) {
    let #(command, description) = command
    model.BotCommand(command: command, description: description)
  })
}

// EditMessageTextParameters ------------------------------------------------------------------------------------------

pub type EditMessageTextParameters {
  EditMessageTextParameters(
    /// Required if _inline_message_id_ is not specified.
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: Option(IntOrString),
    /// Required if inline_message_id is not specified. Identifier of the message to edit
    message_id: Option(Int),
    /// Required if _chat_id_ and _message_id_ are not specified. Identifier of the inline message
    inline_message_id: Option(String),
    /// New text of the message, 1-4096 characters after entities parsing
    text: String,
    /// Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api#formatting-options) for more details.
    parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in message text, which can be specified instead of _parse_mode_
    entities: Option(List(MessageEntity)),
    /// Link preview generation options for the message
    link_preview_options: Option(LinkPreviewOptions),
    /// A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards).
    reply_markup: Option(InlineKeyboardMarkup),
  )
}

pub fn default_edit_message_text_parameters() -> EditMessageTextParameters {
  EditMessageTextParameters(
    chat_id: None,
    message_id: None,
    inline_message_id: None,
    text: "",
    parse_mode: None,
    entities: None,
    link_preview_options: None,
    reply_markup: None,
  )
}

pub fn encode_edit_message_text_parameters(
  params: EditMessageTextParameters,
) -> Json {
  let chat_id = #(
    "chat_id",
    json.nullable(params.chat_id, encode_int_or_string),
  )
  let message_id = #("message_id", json.nullable(params.message_id, json.int))
  let inline_message_id = #(
    "inline_message_id",
    json.nullable(params.inline_message_id, json.string),
  )
  let text = #("text", json.string(params.text))
  let parse_mode = #(
    "parse_mode",
    json.nullable(params.parse_mode, json.string),
  )
  let entities = #(
    "entities",
    json.nullable(params.entities, json.array(_, encode_message_entity)),
  )
  let link_preview_options = #(
    "link_preview_options",
    json.nullable(params.link_preview_options, encode_link_preview_options),
  )
  let reply_markup = #(
    "reply_markup",
    json.nullable(params.reply_markup, encode_inline_keyboard_markup),
  )

  json_object_filter_nulls([
    chat_id,
    message_id,
    inline_message_id,
    text,
    parse_mode,
    entities,
    link_preview_options,
    reply_markup,
  ])
}

// ForwardMessageParameters -------------------------------------------------------------------------------------------
// https://core.telegram.org/bots/api#forwardmessage
pub type ForwardMessageParameters {
  ForwardMessageParameters(
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier for the chat where the original message was sent (or channel username in the format `@channelusername`)
    from_chat_id: IntOrString,
    /// Message identifier in the chat specified in _from_chat_id_
    message_id: Int,
    /// Sends the message silently. Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Protects the contents of the forwarded message from forwarding and saving
    protect_content: Option(Bool),
  )
}

pub fn encode_forward_message_parameters(
  params: ForwardMessageParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", encode_int_or_string(params.chat_id)),
    #("from_chat_id", encode_int_or_string(params.from_chat_id)),
    #("message_id", json.int(params.message_id)),
    #(
      "disable_notification",
      json.nullable(params.disable_notification, json.bool),
    ),
    #("message_thread_id", json.nullable(params.message_thread_id, json.int)),
    #("protect_content", json.nullable(params.protect_content, json.bool)),
  ])
}

// SendDice ------------------------------------------------------------------------------------------------------------

pub type SendDiceParameters {
  SendDiceParameters(
    chat_id: IntOrString,
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Emoji on which the dice throw animation is based. Currently, must be one of "🎲", "🎯", "🏀", "⚽", "🎳", or "🎰". Dice can have values 1-6 for "🎲", "🎯" and "🎳", values 1-5 for "🏀" and "⚽", and values 1-64 for "🎰". Defaults to "🎲"
    emoji: Option(String),
    /// Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Protects the contents of the sent message from forwarding
    protect_content: Option(Bool),
    /// Description of the message to reply to
    reply_parameters: Option(ReplyKeyboardMarkup),
  )
}

pub fn new_send_dice_parameters(
  chat_id chat_id: model.IntOrString,
) -> SendDiceParameters {
  SendDiceParameters(
    chat_id: chat_id,
    message_thread_id: None,
    emoji: None,
    disable_notification: None,
    protect_content: None,
    reply_parameters: None,
  )
}

pub fn encode_send_dice_parameters(params: SendDiceParameters) -> Json {
  let chat_id = #("chat_id", encode_int_or_string(params.chat_id))
  let message_thread_id = #(
    "message_thread_id",
    json.nullable(params.message_thread_id, json.int),
  )
  let emoji = #("emoji", json.nullable(params.emoji, json.string))
  let disable_notification = #(
    "disable_notification",
    json.nullable(params.disable_notification, json.bool),
  )
  let protect_content = #(
    "protect_content",
    json.nullable(params.protect_content, json.bool),
  )
  let reply_parameters = #(
    "reply_parameters",
    json.nullable(params.reply_parameters, encode_reply_keyboard_markup),
  )

  json_object_filter_nulls([
    chat_id,
    message_thread_id,
    emoji,
    disable_notification,
    protect_content,
    reply_parameters,
  ])
}

// SendMessage ------------------------------------------------------------------------

pub type SendMessageParameters {
  /// Parameters to send using the [sendMessage](https://core.telegram.org/bots/api#sendmessage) method
  SendMessageParameters(
    /// Unique identifier of the business connection on behalf of which the message will be sent
    business_connection_id: Option(String),
    /// Unique identifier for the target chat or username of the target channel (in the format `@channelusername`)
    chat_id: IntOrString,
    /// Unique identifier for the target message thread (topic) of the forum; for forum supergroups only
    message_thread_id: Option(Int),
    /// Text of the message to be sent, 1-4096 characters after entities parsing
    text: String,
    /// Mode for parsing entities in the message text. See [formatting options](https://core.telegram.org/bots/api#formatting-options) for more details.
    parse_mode: Option(String),
    /// A JSON-serialized list of special entities that appear in message text, which can be specified instead of _parse_mode_
    entities: Option(List(MessageEntity)),
    /// Link preview generation options for the message
    link_preview_options: Option(LinkPreviewOptions),
    /// Sends the message [silently](https://telegram.org/blog/channels-2-0#silent-messages). Users will receive a notification with no sound.
    disable_notification: Option(Bool),
    /// Protects the contents of the sent message from forwarding and saving
    protect_content: Option(Bool),
    /// Description of the message to reply to
    reply_parameters: Option(ReplyParameters),
    /// Additional interface options. A JSON-serialized object for an [inline keyboard](https://core.telegram.org/bots/features#inline-keyboards), [custom reply keyboard](https://core.telegram.org/bots/features#keyboards), instructions to remove a reply keyboard or to force a reply from the user. Not supported for messages sent on behalf of a business account
    reply_markup: Option(ReplyKeyboardMarkup),
  )
}

pub fn new_send_message_parameters(
  chat_id chat_id: IntOrString,
  text text: String,
) -> SendMessageParameters {
  SendMessageParameters(
    chat_id: chat_id,
    text: text,
    business_connection_id: None,
    message_thread_id: None,
    parse_mode: None,
    entities: None,
    link_preview_options: None,
    disable_notification: None,
    protect_content: None,
    reply_parameters: None,
    reply_markup: None,
  )
}

pub fn set_send_message_parameters_reply_markup(
  params: SendMessageParameters,
  reply_markup: ReplyKeyboardMarkup,
) -> SendMessageParameters {
  SendMessageParameters(..params, reply_markup: Some(reply_markup))
}

pub fn encode_send_message_parameters(
  send_message_parameters: SendMessageParameters,
) -> Json {
  let business_connection_id = #(
    "business_connection_id",
    json.nullable(send_message_parameters.business_connection_id, json.string),
  )
  let chat_id = #(
    "chat_id",
    encode_int_or_string(send_message_parameters.chat_id),
  )

  let message_thread_id = #(
    "message_thread_id",
    json.nullable(send_message_parameters.message_thread_id, json.int),
  )
  let text = #("text", json.string(send_message_parameters.text))
  let parse_mode = #(
    "parse_mode",
    json.nullable(send_message_parameters.parse_mode, json.string),
  )
  let entities = #(
    "entities",
    json.nullable(send_message_parameters.entities, json.array(
      _,
      encode_message_entity,
    )),
  )
  let link_preview_options = #(
    "link_preview_options",
    json.nullable(
      send_message_parameters.link_preview_options,
      encode_link_preview_options,
    ),
  )
  let disable_notification = #(
    "disable_notification",
    json.nullable(send_message_parameters.disable_notification, json.bool),
  )
  let protect_content = #(
    "protect_content",
    json.nullable(send_message_parameters.protect_content, json.bool),
  )
  let reply_parameters = #(
    "reply_parameters",
    json.nullable(
      send_message_parameters.reply_parameters,
      encode_reply_parameters,
    ),
  )
  let reply_markup = #(
    "reply_markup",
    json.nullable(
      send_message_parameters.reply_markup,
      encode_reply_keyboard_markup,
    ),
  )

  json_object_filter_nulls([
    business_connection_id,
    chat_id,
    message_thread_id,
    text,
    parse_mode,
    entities,
    link_preview_options,
    disable_notification,
    protect_content,
    reply_parameters,
    reply_markup,
  ])
}

// SetChatMenuButtonParameters ----------------------------------------------------------------------------------------

pub type SetChatMenuButtonParameters {
  SetChatMenuButtonParameters(
    /// Unique identifier for the target private chat. If not specified, default bot's menu button will be changed
    chat_id: Option(Int),
    /// A JSON-serialized object for the bot's new menu button. Defaults to MenuButtonDefault
    menu_button: Option(model.MenuButton),
  )
}

pub fn encode_set_chat_menu_button_parameters(
  params: SetChatMenuButtonParameters,
) -> Json {
  json_object_filter_nulls([
    #("chat_id", json.nullable(params.chat_id, json.int)),
    #("menu_button", json.nullable(params.menu_button, encode_menu_button)),
  ])
}

// MenuButton --------------------------------------------------------------------------------------------------------

pub fn encode_menu_button(menu_button: model.MenuButton) -> Json {
  case menu_button {
    model.MenuButtonCommandsMenuButton(model.MenuButtonCommands(..)) ->
      json_object_filter_nulls([#("type", json.string("commands"))])
    model.MenuButtonWebAppMenuButton(model.MenuButtonWebApp(
      web_app: web_app,
      ..,
    )) ->
      json_object_filter_nulls([
        #("type", json.string("web_app")),
        #("web_app", encode_web_app_info(web_app)),
      ])
    model.MenuButtonDefaultMenuButton(model.MenuButtonDefault(..)) ->
      json_object_filter_nulls([#("type", json.string("default"))])
  }
}

// InlineKeyboardMarkup ----------------------------------------------------------------------------------------------

pub fn encode_inline_keyboard_markup(
  inline_keyboard_markup: InlineKeyboardMarkup,
) -> Json {
  let inline_keyboard = #(
    "inline_keyboard",
    json.array(inline_keyboard_markup.inline_keyboard, json.array(
      _,
      encode_inline_keyboard_button,
    )),
  )

  json_object_filter_nulls([inline_keyboard])
}

// InlineKeyboardButton ----------------------------------------------------------------------------------------------

pub fn encode_inline_keyboard_button(
  inline_keyboard_button: InlineKeyboardButton,
) -> Json {
  let text = #("text", json.string(inline_keyboard_button.text))
  let url = #("url", json.nullable(inline_keyboard_button.url, json.string))
  let callback_data = #(
    "callback_data",
    json.nullable(inline_keyboard_button.callback_data, json.string),
  )
  let web_app = #(
    "web_app",
    json.nullable(inline_keyboard_button.web_app, encode_web_app_info),
  )
  let login_url = #(
    "login_url",
    json.nullable(inline_keyboard_button.login_url, encode_login_url),
  )
  let switch_inline_query = #(
    "switch_inline_query",
    json.nullable(inline_keyboard_button.switch_inline_query, json.string),
  )
  let switch_inline_query_current_chat = #(
    "switch_inline_query_current_chat",
    json.nullable(
      inline_keyboard_button.switch_inline_query_current_chat,
      json.string,
    ),
  )
  let switch_inline_query_chosen_chat = #(
    "switch_inline_query_chosen_chat",
    json.nullable(
      inline_keyboard_button.switch_inline_query_chosen_chat,
      encode_switch_inline_query_chosen_chat,
    ),
  )
  let pay = #("pay", json.nullable(inline_keyboard_button.pay, json.bool))

  json_object_filter_nulls([
    text,
    url,
    callback_data,
    web_app,
    login_url,
    switch_inline_query,
    switch_inline_query_current_chat,
    switch_inline_query_chosen_chat,
    pay,
  ])
}

// SwitchInlineQueryChosenChat --------------------------------------------------------------------------------------

pub fn encode_switch_inline_query_chosen_chat(
  switch_inline_query_chosen_chat: SwitchInlineQueryChosenChat,
) -> Json {
  let query = #(
    "query",
    json.nullable(switch_inline_query_chosen_chat.query, json.string),
  )
  let allow_user_chats = #(
    "allow_user_chats",
    json.nullable(switch_inline_query_chosen_chat.allow_user_chats, json.bool),
  )
  let allow_bot_chats = #(
    "allow_bot_chats",
    json.nullable(switch_inline_query_chosen_chat.allow_bot_chats, json.bool),
  )
  let allow_group_chats = #(
    "allow_group_chats",
    json.nullable(switch_inline_query_chosen_chat.allow_group_chats, json.bool),
  )
  let allow_channel_chats = #(
    "allow_channel_chats",
    json.nullable(
      switch_inline_query_chosen_chat.allow_channel_chats,
      json.bool,
    ),
  )

  json_object_filter_nulls([
    query,
    allow_user_chats,
    allow_bot_chats,
    allow_group_chats,
    allow_channel_chats,
  ])
}

// SetWebhookParameters ----------------------------------------------------------------------------------------------

/// https://core.telegram.org/bots/api#setwebhook
pub type SetWebhookParameters {
  SetWebhookParameters(
    /// HTTPS url to send updates to. Use an empty string to remove webhook integration
    url: String,
    // TODO: support certificate
    // certificate: Option(InputFile),
    /// Maximum allowed number of simultaneous HTTPS connections to the webhook for update delivery, 1-100. Defaults to 40. Use lower values to limit the load on your bot's server, and higher values to increase your bot's throughput.
    max_connections: Option(Int),
    /// The fixed IP address which will be used to send webhook requests instead of the IP address resolved through DNS
    ip_address: Option(String),
    /// A JSON-serialized list of the update types you want your bot to receive. For example, specify `["message", "edited_channel_post", "callback_query"]` to only receive updates of these types. See [Update](https://core.telegram.org/bots/api#update) for a complete list of available update types. Specify an empty list to receive all updates regardless of type (default). If not specified, the previous setting will be used.
    ///
    /// > Please note that this parameter doesn't affect updates created before the call to the setWebhook, so unwanted updates may be received for a short period of time.
    allowed_updates: Option(List(String)),
    /// Pass _True_ to drop all pending updates
    drop_pending_updates: Option(Bool),
    /// A secret token to be sent in a header "X-Telegram-Bot-Api-Secret-Token" in every webhook request, 1-256 characters. Only characters A-Z, a-z, 0-9, _ and - are allowed. The header is useful to ensure that the request comes from a webhook set by you.
    secret_token: Option(String),
  )
}

pub fn encode_set_webhook_parameters(params: SetWebhookParameters) -> Json {
  json_object_filter_nulls([
    #("url", json.string(params.url)),
    #("max_connections", json.nullable(params.max_connections, json.int)),
    #("ip_address", json.nullable(params.ip_address, json.string)),
    #(
      "allowed_updates",
      json.nullable(params.allowed_updates, json.array(_, json.string)),
    ),
    #(
      "drop_pending_updates",
      json.nullable(params.drop_pending_updates, json.bool),
    ),
    #("secret_token", json.nullable(params.secret_token, json.string)),
  ])
}

// WebAppInfo --------------------------------------------------------------------------------------------------------

pub fn encode_web_app_info(info: model.WebAppInfo) -> Json {
  json_object_filter_nulls([#("url", json.string(info.url))])
}

// ReplyParameters ----------------------------------------------------------------------------------------------------

pub fn encode_reply_parameters(reply_parameters: ReplyParameters) -> Json {
  let message_id = #("message_id", json.int(reply_parameters.message_id))
  let chat_id = #(
    "chat_id",
    json.nullable(reply_parameters.chat_id, encode_int_or_string),
  )
  let allow_sending_without_reply = #(
    "allow_sending_without_reply",
    json.nullable(reply_parameters.allow_sending_without_reply, json.bool),
  )
  let quote = #("quote", json.nullable(reply_parameters.quote, json.string))
  let quote_parse_mode = #(
    "quote_parse_mode",
    json.nullable(reply_parameters.quote_parse_mode, json.string),
  )
  let quote_entities = #(
    "quote_entities",
    json.nullable(reply_parameters.quote_entities, json.array(
      _,
      encode_message_entity,
    )),
  )
  let quote_position = #(
    "quote_position",
    json.nullable(reply_parameters.quote_position, json.int),
  )

  json_object_filter_nulls([
    message_id,
    chat_id,
    allow_sending_without_reply,
    quote,
    quote_parse_mode,
    quote_entities,
    quote_position,
  ])
}

// KeyboardButton ----------------------------------------------------------------------------------------------------

pub fn encode_keyboard_button(keyboard_button: KeyboardButton) -> Json {
  let text = #("text", json.string(keyboard_button.text))
  json_object_filter_nulls([text])
}

// ReplyKeyboardMarkup ------------------------------------------------------------------------------------------------

pub fn encode_reply_keyboard_button(
  reply_keyboard_button: List(KeyboardButton),
) -> Json {
  let text = #(
    "text",
    json.array(reply_keyboard_button, encode_keyboard_button),
  )
  json_object_filter_nulls([text])
}

pub fn encode_reply_keyboard_markup(
  reply_keyboard_markup: ReplyKeyboardMarkup,
) -> Json {
  let keyboard = #(
    "keyboard",
    json.array(reply_keyboard_markup.keyboard, encode_reply_keyboard_button),
  )
  let resize_keyboard = #(
    "resize_keyboard",
    json.nullable(reply_keyboard_markup.resize_keyboard, json.bool),
  )
  let one_time_keyboard = #(
    "one_time_keyboard",
    json.nullable(reply_keyboard_markup.one_time_keyboard, json.bool),
  )
  let selective = #(
    "selective",
    json.nullable(reply_keyboard_markup.selective, json.bool),
  )

  json_object_filter_nulls([
    keyboard,
    resize_keyboard,
    one_time_keyboard,
    selective,
  ])
}

// MessageEntity ------------------------------------------------------------------------------------------------------

pub fn encode_message_entity(message_entity: MessageEntity) -> Json {
  let entity_type = #("entity_type", json.string(message_entity.type_))
  let offset = #("offset", json.int(message_entity.offset))
  let length = #("length", json.int(message_entity.length))
  let url = #("url", json.nullable(message_entity.url, json.string))
  let user = #("user", json.nullable(message_entity.user, encode_user))
  let language = #(
    "language",
    json.nullable(message_entity.language, json.string),
  )
  let custom_emoji_id = #(
    "custom_emoji_id",
    json.nullable(message_entity.custom_emoji_id, json.string),
  )

  json_object_filter_nulls([
    entity_type,
    offset,
    length,
    url,
    user,
    language,
    custom_emoji_id,
  ])
}

// User --------------------------------------------------------------------------------------------------------------

pub fn encode_user(user: User) -> Json {
  let id = #("id", json.int(user.id))
  let is_bot = #("is_bot", json.bool(user.is_bot))
  let first_name = #("first_name", json.string(user.first_name))
  let last_name = #("last_name", json.nullable(user.last_name, json.string))
  let username = #("username", json.nullable(user.username, json.string))
  let language_code = #(
    "language_code",
    json.nullable(user.language_code, json.string),
  )
  let is_premium = #("is_premium", json.nullable(user.is_premium, json.bool))
  let added_to_attachment_menu = #(
    "added_to_attachment_menu",
    json.nullable(user.added_to_attachment_menu, json.bool),
  )

  json_object_filter_nulls([
    id,
    is_bot,
    first_name,
    last_name,
    username,
    language_code,
    is_premium,
    added_to_attachment_menu,
  ])
}

// LinkPreviewOptions ------------------------------------------------------------------------------------------------

pub fn encode_link_preview_options(
  link_preview_options: LinkPreviewOptions,
) -> Json {
  json_object_filter_nulls([
    #("is_disabled", json.nullable(link_preview_options.is_disabled, json.bool)),
    #("url", json.nullable(link_preview_options.url, json.string)),
    #(
      "prefer_small_media",
      json.nullable(link_preview_options.prefer_small_media, json.bool),
    ),
    #(
      "prefer_large_media",
      json.nullable(link_preview_options.prefer_large_media, json.bool),
    ),
    #(
      "show_above_text",
      json.nullable(link_preview_options.show_above_text, json.bool),
    ),
  ])
}

// LoginUrl ----------------------------------------------------------------------------------------------------------
pub fn encode_login_url(login_url: LoginUrl) -> Json {
  let url = #("url", json.string(login_url.url))
  let forward_text = #(
    "forward_text",
    json.nullable(login_url.forward_text, json.string),
  )
  let bot_username = #(
    "bot_username",
    json.nullable(login_url.bot_username, json.string),
  )
  let request_write_access = #(
    "request_write_access",
    json.nullable(login_url.request_write_access, json.bool),
  )

  json_object_filter_nulls([
    url,
    forward_text,
    bot_username,
    request_write_access,
  ])
}

// Common ------------------------------------------------------------------------------------------------------------

fn encode_int_or_string(value: model.IntOrString) -> Json {
  case value {
    model.Int(value) -> json.int(value)
    model.Str(value) -> json.string(value)
  }
}

fn json_object_filter_nulls(entries: List(#(String, Json))) -> Json {
  let null = json.null()

  entries
  |> list.filter(fn(entry) {
    let #(_, value) = entry
    case value == null {
      True -> False
      False -> True
    }
  })
  |> json.object
}
