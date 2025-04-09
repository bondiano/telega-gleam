import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string

import telega/error
import telega/model.{
  type CallbackQuery, type Message, type MessageEntity,
  type Update as ModelUpdate,
}

/// Messages represent the data that the bot receives from the Telegram API.
pub type Update {
  TextUpdate(
    from_id: Int,
    chat_id: Int,
    text: String,
    message: Message,
    raw: ModelUpdate,
  )
  CommandUpdate(
    from_id: Int,
    chat_id: Int,
    command: Command,
    message: Message,
    raw: ModelUpdate,
  )
  CallbackQueryUpdate(
    from_id: Int,
    chat_id: Int,
    query: CallbackQuery,
    raw: ModelUpdate,
  )
}

pub type Command {
  /// Represents a command message.
  Command(
    /// Whole command message
    text: String,
    /// Command name without the leading slash
    command: String,
    /// The command arguments, if any.
    payload: Option(String),
  )
}

/// Decode a update from the Telegram API to `Update` instance.
pub fn decode(json: Dynamic) {
  use raw_update <- result.try(
    decode.run(json, model.update_decoder())
    |> result.map_error(fn(e) {
      error.DecodeUpdateError(
        "Cannot decode update: "
        <> string.inspect(json)
        <> " "
        <> string.inspect(e),
      )
    }),
  )
  use <- try_decode_to_callback_query(raw_update)
  use <- try_to_decode_message_or_command(raw_update)

  Error(error.UnknownUpdateError(raw_update))
}

fn try_decode_to_callback_query(raw: ModelUpdate, on_none) {
  case raw.callback_query {
    Some(callback_query) -> new_callback_query_update(raw, callback_query) |> Ok
    None -> on_none()
  }
}

fn try_to_decode_message_or_command(raw: ModelUpdate, on_none) {
  case raw.message {
    Some(message) ->
      case message.text {
        Some(text) ->
          case is_command_update(text, raw) {
            True -> new_command_update(raw, message, text) |> Ok
            False -> new_text_update(raw, message, text) |> Ok
          }
        None -> on_none()
      }
    None -> on_none()
  }
}

fn new_callback_query_update(raw: ModelUpdate, callback_query: CallbackQuery) {
  CallbackQueryUpdate(
    raw:,
    from_id: callback_query.from.id,
    chat_id: case callback_query.message {
      Some(message) ->
        case message {
          model.MessageMaybeInaccessibleMessage(message) -> message.chat.id
          model.InaccessibleMessageMaybeInaccessibleMessage(message) ->
            message.chat.id
        }
      None -> callback_query.from.id
    },
    query: callback_query,
  )
}

fn new_text_update(raw: ModelUpdate, message: Message, text: String) {
  TextUpdate(
    raw:,
    text:,
    message:,
    from_id: case message.from {
      Some(user) -> user.id
      None -> message.chat.id
    },
    chat_id: message.chat.id,
  )
}

fn new_command_update(raw: ModelUpdate, message: Message, text: String) {
  CommandUpdate(
    raw:,
    message:,
    from_id: case message.from {
      Some(user) -> user.id
      None -> message.chat.id
    },
    chat_id: message.chat.id,
    command: extract_command(text),
  )
}

fn is_command_entity(text, entity: MessageEntity) {
  entity.type_ == "bot_command"
  && entity.offset == 0
  && entity.length == string.length(text)
}

fn is_command_update(text: String, raw_update: ModelUpdate) -> Bool {
  use <- bool.guard(!string.starts_with(text, "/"), False)

  case raw_update.message {
    Some(message) ->
      case message.entities {
        Some(entities) -> list.any(entities, is_command_entity(text, _))
        None -> False
      }
    None -> False
  }
}

fn extract_command(text: String) -> Command {
  case string.split(text, " ") {
    [command, ..payload] ->
      Command(
        text:,
        command: string.drop_start(command, 1),
        payload: payload
          |> string.join(" ")
          |> Some,
      )
    [] -> Command(text:, command: "", payload: None)
  }
}
