//// Telegram Mini Apps (Web Apps) support for Telega.
////
//// A Mini App receives a signed `initData` string from the Telegram client.
//// Your backend must verify that string before trusting any of the user data
//// inside it. This module covers the full server-side flow:
////
//// - [`validate`](#validate) / [`validate_with_max_age`](#validate_with_max_age)
////   — verify the `HMAC-SHA256` signature produced with your bot token (the
////   standard first-party check) and parse the payload into typed values.
//// - [`validate_third_party`](#validate_third_party) — verify the `Ed25519`
////   `signature` field, for apps opened on behalf of *another* bot.
//// - [`parse`](#parse) — decode `initData` into [`WebAppInitData`](#WebAppInitData)
////   without checking any signature (use only on already-trusted input).
//// - [`answer_web_app_query`](#answer_web_app_query) — reply to an inline Mini
////   App query with a result.
////
//// ## Validation
////
//// The signing scheme (see the [official docs](https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app)):
//// `secret_key = HMAC_SHA256(bot_token, "WebAppData")`, then the expected hash
//// is `HMAC_SHA256(data_check_string, secret_key)` where `data_check_string`
//// is every field except `hash`/`signature`, sorted by key and joined with
//// newlines as `key=value`.
////
//// ```gleam
//// import telega_webapp
////
//// // `init_data` is the raw query string from `Telegram.WebApp.initData`,
//// // forwarded by your frontend (e.g. in an `Authorization` header).
//// case telega_webapp.validate_with_max_age(token, init_data, 86_400) {
////   Ok(data) -> {
////     // Trusted. `data.user` is who opened the app.
////     todo
////   }
////   Error(_) -> todo  // reject the request
//// }
//// ```

import gleam/bit_array
import gleam/bool
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/http/response.{type Response}
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import gleam/uri

import gleam/crypto
import gleam/erlang/atom.{type Atom}

import telega/client.{type TelegramClient, fetch, new_post_request}
import telega/error.{type TelegaError}
import telega/model/decoder
import telega/model/encoder
import telega/model/types.{type InlineQueryResult, type SentWebAppMessage}

// --- Types -----------------------------------------------------------------

/// A Telegram user as described inside a Mini App `initData` payload.
///
/// Mirrors the [`WebAppUser`](https://core.telegram.org/bots/webapps#webappuser)
/// object — note this is *not* the same shape as the Bot API `User`.
pub type WebAppUser {
  WebAppUser(
    id: Int,
    first_name: String,
    last_name: Option(String),
    username: Option(String),
    language_code: Option(String),
    is_bot: Option(Bool),
    is_premium: Option(Bool),
    added_to_attachment_menu: Option(Bool),
    allows_write_to_pm: Option(Bool),
    photo_url: Option(String),
  )
}

/// A chat the Mini App was launched from (attachment-menu apps only).
///
/// Mirrors the [`WebAppChat`](https://core.telegram.org/bots/webapps#webappchat)
/// object.
pub type WebAppChat {
  WebAppChat(
    id: Int,
    type_: String,
    title: String,
    username: Option(String),
    photo_url: Option(String),
  )
}

/// The decoded `initData` payload.
///
/// `hash` is the first-party `HMAC-SHA256` signature and is empty when the app
/// was opened with only a third-party `signature` present.
pub type WebAppInitData {
  WebAppInitData(
    query_id: Option(String),
    user: Option(WebAppUser),
    receiver: Option(WebAppUser),
    chat: Option(WebAppChat),
    chat_type: Option(String),
    chat_instance: Option(String),
    start_param: Option(String),
    can_send_after: Option(Int),
    auth_date: Int,
    hash: String,
    signature: Option(String),
  )
}

/// Reasons validation or parsing can fail.
pub type WebAppError {
  /// The `initData` string is not a valid URL-encoded query.
  MalformedInitData
  /// A required field (named) was missing or could not be decoded.
  InvalidField(String)
  /// No `hash` field — cannot run first-party validation.
  MissingHash
  /// No `signature` field — cannot run third-party validation.
  MissingSignature
  /// The computed signature did not match the provided one.
  SignatureMismatch
  /// `auth_date` is older than the allowed `max_age`.
  Outdated
}

/// Which Telegram environment a third-party `signature` was issued by. Selects
/// the public key used for `Ed25519` verification.
pub type Environment {
  Production
  Test
}

// --- Public API ------------------------------------------------------------

/// Validate `init_data` against your bot `token` using the first-party
/// `HMAC-SHA256` scheme and return the typed payload on success.
///
/// This does **not** check `auth_date` freshness — use
/// [`validate_with_max_age`](#validate_with_max_age) to also reject stale data,
/// which you almost always want in production.
pub fn validate(
  token token: String,
  init_data init_data: String,
) -> Result(WebAppInitData, WebAppError) {
  use pairs <- result.try(raw_pairs(init_data))
  use hash <- result.try(
    list.key_find(pairs, "hash") |> result.replace_error(MissingHash),
  )

  let expected = sign(token, data_check_string(pairs))
  case
    crypto.secure_compare(
      bit_array.from_string(expected),
      bit_array.from_string(hash),
    )
  {
    True -> parse_pairs(pairs)
    False -> Error(SignatureMismatch)
  }
}

/// Like [`validate`](#validate), but also rejects data whose `auth_date` is
/// older than `max_age_seconds` relative to the current system time.
///
/// A typical `max_age` is one day (`86_400`).
pub fn validate_with_max_age(
  token token: String,
  init_data init_data: String,
  max_age_seconds max_age_seconds: Int,
) -> Result(WebAppInitData, WebAppError) {
  use data <- result.try(validate(token, init_data))
  case is_fresh(data, max_age_seconds, now_seconds()) {
    True -> Ok(data)
    False -> Error(Outdated)
  }
}

/// Validate `init_data` issued for a *third-party* bot using the `Ed25519`
/// `signature` field. `bot_id` is the numeric id of the bot the Mini App was
/// opened for (the part before `:` in its token).
///
/// Use this when your service receives Mini App data for bots you don't hold
/// the token of; otherwise prefer [`validate`](#validate).
pub fn validate_third_party(
  bot_id bot_id: Int,
  init_data init_data: String,
  environment environment: Environment,
) -> Result(WebAppInitData, WebAppError) {
  use pairs <- result.try(raw_pairs(init_data))
  use signature <- result.try(
    list.key_find(pairs, "signature")
    |> result.replace_error(MissingSignature),
  )
  use signature_bytes <- result.try(
    bit_array.base64_url_decode(signature)
    |> result.replace_error(InvalidField("signature")),
  )
  // Ed25519 signatures are exactly 64 bytes; `crypto:verify` raises `badarg`
  // for anything else, so reject malformed input up front.
  use <- bool.guard(
    bit_array.byte_size(signature_bytes) != 64,
    Error(SignatureMismatch),
  )

  let message =
    int.to_string(bot_id) <> ":WebAppData\n" <> data_check_string(pairs)
  case
    verify_ed25519(
      bit_array.from_string(message),
      signature_bytes,
      public_key(environment),
    )
  {
    True -> parse_pairs(pairs)
    False -> Error(SignatureMismatch)
  }
}

/// Decode `init_data` into typed values **without** verifying any signature.
///
/// Only use on input you have already validated (or trust for another reason);
/// for request handling use [`validate`](#validate) instead.
pub fn parse(
  init_data init_data: String,
) -> Result(WebAppInitData, WebAppError) {
  use pairs <- result.try(raw_pairs(init_data))
  parse_pairs(pairs)
}

/// Whether `auth_date` is within `max_age_seconds` of `now_unix` (both in Unix
/// seconds). Exposed for callers that supply their own clock.
pub fn is_fresh(
  data data: WebAppInitData,
  max_age_seconds max_age_seconds: Int,
  now_unix now_unix: Int,
) -> Bool {
  data.auth_date + max_age_seconds >= now_unix
}

/// Reply to an inline Mini App query via
/// [answerWebAppQuery](https://core.telegram.org/bots/api#answerwebappquery).
///
/// `web_app_query_id` comes from the `web_app_data`/`WebAppData` query sent by
/// the app; build `result` with `telega/inline_mode` or the raw
/// `telega/model/types` constructors.
pub fn answer_web_app_query(
  client client: TelegramClient,
  web_app_query_id web_app_query_id: String,
  result result: InlineQueryResult,
) -> Result(SentWebAppMessage, TelegaError) {
  let body =
    json.object([
      #("web_app_query_id", json.string(web_app_query_id)),
      #("result", encoder.encode_inline_query_result(result)),
    ])

  new_post_request(
    client:,
    path: "answerWebAppQuery",
    body: json.to_string(body),
  )
  |> fetch(client)
  |> map_response(decoder.sent_web_app_message_decoder())
}

// --- Validation internals --------------------------------------------------

/// Telegram's `initData` HMAC: the secret key is itself an HMAC of the token
/// keyed by the literal `"WebAppData"`, then the data-check string is signed
/// with that secret. Returned lowercase-hex to match the wire `hash`.
fn sign(token: String, data_check_string: String) -> String {
  let secret_key =
    crypto.hmac(
      bit_array.from_string(token),
      crypto.Sha256,
      bit_array.from_string("WebAppData"),
    )

  crypto.hmac(
    bit_array.from_string(data_check_string),
    crypto.Sha256,
    secret_key,
  )
  |> bit_array.base16_encode
  |> string.lowercase
}

/// All fields except `hash`/`signature`, sorted by key, joined as
/// `key=value` with newlines.
fn data_check_string(pairs: List(#(String, String))) -> String {
  pairs
  |> list.filter(fn(pair) { pair.0 != "hash" && pair.0 != "signature" })
  |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
  |> list.map(fn(pair) { pair.0 <> "=" <> pair.1 })
  |> string.join("\n")
}

fn raw_pairs(
  init_data: String,
) -> Result(List(#(String, String)), WebAppError) {
  uri.parse_query(init_data)
  |> result.replace_error(MalformedInitData)
}

// --- Parsing ---------------------------------------------------------------

fn parse_pairs(
  pairs: List(#(String, String)),
) -> Result(WebAppInitData, WebAppError) {
  use auth_date <- result.try(parse_int_field(pairs, "auth_date"))
  use user <- result.try(parse_json_field(pairs, "user", web_app_user_decoder()))
  use receiver <- result.try(parse_json_field(
    pairs,
    "receiver",
    web_app_user_decoder(),
  ))
  use chat <- result.try(parse_json_field(pairs, "chat", web_app_chat_decoder()))
  use can_send_after <- result.try(parse_optional_int_field(
    pairs,
    "can_send_after",
  ))

  Ok(WebAppInitData(
    query_id: string_field(pairs, "query_id"),
    user:,
    receiver:,
    chat:,
    chat_type: string_field(pairs, "chat_type"),
    chat_instance: string_field(pairs, "chat_instance"),
    start_param: string_field(pairs, "start_param"),
    can_send_after:,
    auth_date:,
    hash: list.key_find(pairs, "hash") |> result.unwrap(""),
    signature: string_field(pairs, "signature"),
  ))
}

fn string_field(pairs: List(#(String, String)), key: String) -> Option(String) {
  list.key_find(pairs, key) |> option.from_result
}

fn parse_int_field(
  pairs: List(#(String, String)),
  key: String,
) -> Result(Int, WebAppError) {
  use raw <- result.try(
    list.key_find(pairs, key) |> result.replace_error(InvalidField(key)),
  )
  int.parse(raw) |> result.replace_error(InvalidField(key))
}

fn parse_optional_int_field(
  pairs: List(#(String, String)),
  key: String,
) -> Result(Option(Int), WebAppError) {
  case list.key_find(pairs, key) {
    Error(_) -> Ok(None)
    Ok(raw) ->
      int.parse(raw)
      |> result.replace_error(InvalidField(key))
      |> result.map(Some)
  }
}

fn parse_json_field(
  pairs: List(#(String, String)),
  key: String,
  decoder: decode.Decoder(a),
) -> Result(Option(a), WebAppError) {
  case list.key_find(pairs, key) {
    Error(_) -> Ok(None)
    Ok(raw) ->
      json.parse(raw, decoder)
      |> result.replace_error(InvalidField(key))
      |> result.map(Some)
  }
}

fn web_app_user_decoder() -> decode.Decoder(WebAppUser) {
  use id <- decode.field("id", decode.int)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.optional_field(
    "last_name",
    None,
    decode.optional(decode.string),
  )
  use username <- decode.optional_field(
    "username",
    None,
    decode.optional(decode.string),
  )
  use language_code <- decode.optional_field(
    "language_code",
    None,
    decode.optional(decode.string),
  )
  use is_bot <- decode.optional_field(
    "is_bot",
    None,
    decode.optional(decode.bool),
  )
  use is_premium <- decode.optional_field(
    "is_premium",
    None,
    decode.optional(decode.bool),
  )
  use added_to_attachment_menu <- decode.optional_field(
    "added_to_attachment_menu",
    None,
    decode.optional(decode.bool),
  )
  use allows_write_to_pm <- decode.optional_field(
    "allows_write_to_pm",
    None,
    decode.optional(decode.bool),
  )
  use photo_url <- decode.optional_field(
    "photo_url",
    None,
    decode.optional(decode.string),
  )
  decode.success(WebAppUser(
    id:,
    first_name:,
    last_name:,
    username:,
    language_code:,
    is_bot:,
    is_premium:,
    added_to_attachment_menu:,
    allows_write_to_pm:,
    photo_url:,
  ))
}

fn web_app_chat_decoder() -> decode.Decoder(WebAppChat) {
  use id <- decode.field("id", decode.int)
  use type_ <- decode.field("type", decode.string)
  use title <- decode.field("title", decode.string)
  use username <- decode.optional_field(
    "username",
    None,
    decode.optional(decode.string),
  )
  use photo_url <- decode.optional_field(
    "photo_url",
    None,
    decode.optional(decode.string),
  )
  decode.success(WebAppChat(id:, type_:, title:, username:, photo_url:))
}

// --- API response handling -------------------------------------------------

type ApiResponse(result) {
  ApiSuccess(result: result)
  ApiFailure(error_code: Int, description: String)
}

fn map_response(
  response: Result(Response(String), TelegaError),
  result_decoder: decode.Decoder(a),
) -> Result(a, TelegaError) {
  use response <- result.try(response)

  json.parse(response.body, api_response_decoder(result_decoder))
  |> result.map_error(error.JsonDecodeError)
  |> result.try(fn(parsed) {
    case parsed {
      ApiSuccess(result:) -> Ok(result)
      ApiFailure(error_code:, description:) ->
        Error(error.TelegramApiError(error_code, description))
    }
  })
}

fn api_response_decoder(
  result_decoder: decode.Decoder(a),
) -> decode.Decoder(ApiResponse(a)) {
  use ok <- decode.field("ok", decode.bool)
  case ok {
    True -> {
      use result <- decode.field("result", result_decoder)
      decode.success(ApiSuccess(result:))
    }
    False -> {
      use error_code <- decode.optional_field("error_code", 0, decode.int)
      use description <- decode.optional_field("description", "", decode.string)
      decode.success(ApiFailure(error_code:, description:))
    }
  }
}

// --- Ed25519 ---------------------------------------------------------------

/// Verify an `Ed25519` signature via the Erlang `crypto` module. The `eddsa`
/// algorithm expects the public key as a `[PublicKey, ed25519]` term, which we
/// build with `gleam/dynamic` rather than an FFI shim.
fn verify_ed25519(
  message: BitArray,
  signature: BitArray,
  public_key: BitArray,
) -> Bool {
  let key =
    dynamic.list([
      dynamic.bit_array(public_key),
      atom.to_dynamic(atom.create("ed25519")),
    ])
  crypto_verify(
    atom.create("eddsa"),
    atom.create("none"),
    message,
    signature,
    key,
  )
}

@external(erlang, "crypto", "verify")
fn crypto_verify(
  algorithm: Atom,
  digest_type: Atom,
  message: BitArray,
  signature: BitArray,
  key: Dynamic,
) -> Bool

/// Telegram's public keys for verifying third-party `signature`s, as published
/// in the [docs](https://core.telegram.org/bots/webapps#validating-data-for-third-party-use).
fn public_key(environment: Environment) -> BitArray {
  let hex = case environment {
    Production ->
      "e7bf03a2fa4602af4580703d88dda5bb59f32ed8b02a56c187fe7d34caed242d"
    Test -> "40055058a4ee38156a06562e52eece92a771bcb8346deeb3d33aff7f55cea4be"
  }
  // Keys are compile-time constants, so decoding never fails in practice.
  bit_array.base16_decode(hex) |> result.unwrap(<<>>)
}

// --- Time ------------------------------------------------------------------

fn now_seconds() -> Int {
  os_system_time(atom.create("second"))
}

@external(erlang, "os", "system_time")
fn os_system_time(unit: Atom) -> Int
