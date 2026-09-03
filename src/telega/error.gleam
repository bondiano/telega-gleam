import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/actor
import gleam/string

import telega/model/types.{type ResponseParameters, type Update}

pub type TelegaError {
  /// Returned by Bot API if server returns `ok: false`, indicating that your API request was invalid and failed.
  ///
  /// `parameters` is Telegram's own `ResponseParameters` when it sent one —
  /// `retry_after` on a flood wait, `migrate_to_chat_id` when a group became a
  /// supergroup. Read them with `retry_after` / `migrate_to_chat_id`.
  TelegramApiError(
    error_code: Int,
    description: String,
    parameters: Option(ResponseParameters),
  )
  /// Returned if the Bot API server could not be reached or the request failed
  FetchError(error: String)
  /// Returned if the JSON response from the Bot API could not be decoded
  JsonDecodeError(error: json.DecodeError)

  /// Returned if the bot failed to call `handle_update`
  BotHandleUpdateError(reason: String)

  /// Returned if the bot failed to convert API request to HTTP request
  ApiToRequestConvertError
  SetWebhookError

  // Start errors
  RegistryStartError(reason: String)
  BotStartError(reason: actor.StartError)
  ChatInstanceStartError(reason: actor.StartError)

  FileNotFoundError

  DecodeUpdateError(reason: String)

  /// Occurs when the update is not handled by any handler
  UnknownUpdateError(update: Update)

  /// General actor error (e.g., from polling)
  ActorError(reason: String)

  RouterError(reason: String)

  // Supervision errors
  SupervisorStartError(reason: actor.StartError)
  ShutdownError(reason: String)
}

pub fn to_string(error: TelegaError) -> String {
  case error {
    TelegramApiError(error_code:, description:, ..) ->
      "Telegram API error: " <> int.to_string(error_code) <> " " <> description
    JsonDecodeError(error) -> "Decode JSON error: " <> string.inspect(error)
    ApiToRequestConvertError -> "Failed to convert API request to HTTP request"
    FetchError(error) -> "Failed to send request: " <> string.inspect(error)
    SetWebhookError -> "Failed to set webhook"
    RegistryStartError(reason) -> "Failed to start registry: " <> reason
    BotStartError(reason) -> "Failed to start bot: " <> string.inspect(reason)
    ChatInstanceStartError(reason) ->
      "Failed to start chat instance: " <> string.inspect(reason)
    FileNotFoundError -> "File not found"
    DecodeUpdateError(reason) -> "Failed to decode update: " <> reason
    BotHandleUpdateError(reason) -> "Failed to handle update: " <> reason
    UnknownUpdateError(update) -> "Unknown update: " <> string.inspect(update)
    ActorError(reason) -> "Actor error: " <> reason
    RouterError(reason) -> "Router error: " <> reason
    SupervisorStartError(reason) ->
      "Failed to start supervisor: " <> string.inspect(reason)
    ShutdownError(reason) -> "Shutdown error: " <> reason
  }
}

/// What a Bot API failure actually was, in a form you can `case` on.
///
/// The Bot API has no structured error codes: everything but the HTTP status
/// arrives as English prose in `description`. `classify` does that reading
/// once, so call sites match on a constructor instead of spelling substrings
/// of their own. Every `is_*` predicate in this module is a one-line wrapper
/// over it.
///
/// ```gleam
/// case error.classify(err) {
///   error.BotBlocked | error.UserDeactivated -> forget_user(chat_id)
///   error.TooManyRequests(retry_after:) -> sleep(retry_after * 1000)
///   error.ChatMigrated(new_chat_id:) -> resend_to(new_chat_id)
///   _ -> log(err)
/// }
/// ```
pub type ApiErrorKind {
  /// The user blocked the bot (403). They can unblock it later, so the chat id
  /// stays valid.
  BotBlocked
  /// The bot was removed from the chat (403 "bot was kicked" / "bot is not a
  /// member").
  BotKicked
  /// The account is gone for good (403 "user is deactivated").
  UserDeactivated
  /// Telegram does not know this chat (400 "chat not found") — a wrong id, or
  /// a user who never started the bot.
  ChatNotFound
  /// The bot is in the chat but may not post there: restricted by an admin, a
  /// channel it is not an admin of, or a bot-to-bot chat.
  ChatWriteForbidden
  /// The edit was a no-op: new content equals the current one. Safe to treat
  /// as success.
  MessageNotModified
  /// The message to edit no longer exists (deleted by the user or too old).
  MessageNotFound
  /// The message exists but cannot be edited (e.g. not sent by the bot).
  MessageCantBeEdited
  /// The text or caption exceeded Telegram's length limit. Split it and resend.
  MessageTooLong
  /// Flood control (429). `retry_after` is what Telegram asked for, in
  /// seconds, or `0` when it sent no `parameters`.
  TooManyRequests(retry_after: Int)
  /// The group became a supergroup and got a new id. Resend to `new_chat_id`.
  ChatMigrated(new_chat_id: Int)
  /// The token is wrong or revoked (401).
  Unauthorized
  /// A 403 this module does not recognize more precisely.
  Forbidden
  /// A 400 this module does not recognize more precisely.
  BadRequest
  /// Telegram's own failure (5xx). Worth retrying.
  ServerError
  /// Anything else, including every non-API `TelegaError` (a transport
  /// failure, a decode error, an actor that would not start).
  Other
}

/// Read a Bot API failure into an `ApiErrorKind`.
///
/// Non-API errors — transport, decoding, startup — classify as `Other`: they
/// carry no Telegram status to read.
pub fn classify(error error: TelegaError) -> ApiErrorKind {
  case error {
    TelegramApiError(error_code:, description:, parameters:) ->
      classify_api(error_code, string.lowercase(description), parameters)
    _ -> Other
  }
}

fn classify_api(
  code: Int,
  description: String,
  parameters: Option(ResponseParameters),
) -> ApiErrorKind {
  case migrate_to(parameters), code {
    Some(new_chat_id), _ -> ChatMigrated(new_chat_id:)
    None, 429 -> TooManyRequests(retry_after: retry_after_of(parameters))
    None, _ -> classify_description(code, description)
  }
}

fn migrate_to(parameters: Option(ResponseParameters)) -> Option(Int) {
  case parameters {
    Some(parameters) -> parameters.migrate_to_chat_id
    None -> None
  }
}

fn retry_after_of(parameters: Option(ResponseParameters)) -> Int {
  case parameters {
    Some(parameters) -> option.unwrap(parameters.retry_after, 0)
    None -> 0
  }
}

/// Telegram describes the reason in prose; the status alone cannot tell a
/// blocked user from a bot that was kicked. Both halves have to agree, so a
/// 400 that merely mentions "blocked" is not read as a 403.
fn classify_description(code: Int, description: String) -> ApiErrorKind {
  case code {
    401 -> Unauthorized
    403 ->
      first_kind(
        [
          #(contains(description, "bot was blocked by the user"), BotBlocked),
          #(contains(description, "user is deactivated"), UserDeactivated),
          #(contains(description, "bot was kicked"), BotKicked),
          #(contains(description, "bot is not a member"), BotKicked),
          #(write_forbidden(description), ChatWriteForbidden),
        ],
        otherwise: Forbidden,
      )
    400 ->
      first_kind(
        [
          #(contains(description, "chat not found"), ChatNotFound),
          #(
            contains(description, "message is not modified"),
            MessageNotModified,
          ),
          #(contains(description, "message to edit not found"), MessageNotFound),
          #(
            contains(description, "message can't be edited"),
            MessageCantBeEdited,
          ),
          #(contains(description, "message is too long"), MessageTooLong),
          #(write_forbidden(description), ChatWriteForbidden),
        ],
        otherwise: BadRequest,
      )
    _ if code >= 500 -> ServerError
    _ -> Other
  }
}

fn first_kind(
  candidates: List(#(Bool, ApiErrorKind)),
  otherwise otherwise: ApiErrorKind,
) -> ApiErrorKind {
  case list.find(candidates, fn(candidate) { candidate.0 }) {
    Ok(#(_, kind)) -> kind
    Error(Nil) -> otherwise
  }
}

fn write_forbidden(description: String) -> Bool {
  contains(description, "chat_write_forbidden")
  || contains(description, "have no rights to send a message")
  || contains(description, "not enough rights to send")
  || contains(description, "can't send messages to bots")
}

fn contains(description: String, needle: String) -> Bool {
  string.contains(description, needle)
}

/// The edit was a no-op: new content equals the current one. Safe to treat
/// as success.
pub fn is_message_not_modified(error error: TelegaError) -> Bool {
  classify(error) == MessageNotModified
}

/// The message to edit no longer exists (deleted by the user or too old).
pub fn is_message_not_found(error error: TelegaError) -> Bool {
  classify(error) == MessageNotFound
}

/// The message exists but cannot be edited (e.g. not sent by the bot).
pub fn is_message_cant_be_edited(error error: TelegaError) -> Bool {
  classify(error) == MessageCantBeEdited
}

/// The text or caption was longer than Telegram accepts (400 "message is too
/// long").
pub fn is_message_too_long(error error: TelegaError) -> Bool {
  classify(error) == MessageTooLong
}

/// Seconds to wait before repeating the request, as Telegram reported them in
/// `parameters.retry_after` (flood control). `None` for every other error.
pub fn retry_after(error error: TelegaError) -> Option(Int) {
  case error {
    TelegramApiError(parameters: Some(parameters), ..) -> parameters.retry_after
    _ -> None
  }
}

/// The supergroup id this chat was migrated to, as Telegram reported it in
/// `parameters.migrate_to_chat_id`. Resend to this id instead.
pub fn migrate_to_chat_id(error error: TelegaError) -> Option(Int) {
  case error {
    TelegramApiError(parameters: Some(parameters), ..) ->
      parameters.migrate_to_chat_id
    _ -> None
  }
}

/// The user blocked the bot (403). They can unblock it later, so the chat id
/// stays valid.
pub fn is_bot_blocked(error error: TelegaError) -> Bool {
  classify(error) == BotBlocked
}

/// The account is gone for good (403 "user is deactivated").
pub fn is_user_deactivated(error error: TelegaError) -> Bool {
  classify(error) == UserDeactivated
}

/// Telegram does not know this chat (400 "chat not found") — a wrong id, or a
/// user who never started the bot.
pub fn is_chat_not_found(error error: TelegaError) -> Bool {
  classify(error) == ChatNotFound
}

/// The bot was removed from the chat (403 "bot was kicked" / "bot is not a
/// member").
pub fn is_bot_kicked(error error: TelegaError) -> Bool {
  classify(error) == BotKicked
}

/// This chat cannot be delivered to right now: blocked, deactivated, kicked,
/// unknown to Telegram, or one the bot may not write in. Retrying the same
/// call will not help, which is what separates it from a flood wait or a 5xx.
pub fn is_chat_unreachable(error error: TelegaError) -> Bool {
  case classify(error) {
    BotBlocked
    | BotKicked
    | UserDeactivated
    | ChatNotFound
    | ChatWriteForbidden -> True
    _ -> False
  }
}

/// Helper to replace `result.try` for api call and error mapping.
pub fn try(
  result: Result(a, TelegaError),
  to to_error: fn(TelegaError) -> e,
  fun fun: fn(a) -> Result(b, e),
) -> Result(b, e) {
  case result {
    Ok(x) -> fun(x)
    Error(e) -> Error(to_error(e))
  }
}
