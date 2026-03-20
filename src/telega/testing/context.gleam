//// Context and config builders for testing.
////
//// Provides functions to create `bot.Context`, `config.Config`,
//// and `bot.SessionSettings` with sensible test defaults.
////
//// ```gleam
//// import telega/testing/context
//// import telega/testing/factory
////
//// let ctx = context.context(session: MySession(count: 0))
//// let cfg = context.config()
//// ```

import gleam/erlang/process
import gleam/option.{None, Some}

import gleam/http/response

import telega/bot
import telega/client
import telega/error
import telega/internal/config
import telega/model/types
import telega/testing/factory
import telega/update

fn test_fetch_client(
  _req,
) -> Result(response.Response(String), error.TelegaError) {
  Ok(response.new(200) |> response.set_body("{\"ok\":true,\"result\":{}}"))
}

/// Creates a test `Config` with a test token and URL.
pub fn config() -> config.Config {
  config.new(
    api_client: client.new(token: "test_token", fetch_client: test_fetch_client),
    webhook_path: "test_webhook",
    secret_token: None,
    url: "https://test.example.com",
  )
}

/// Creates a test `Config` with the given Telegram client.
/// Use this with `mock.message_client()` to get a config that returns valid API responses.
pub fn config_with_client(client: client.TelegramClient) -> config.Config {
  let cfg = config()
  config.Config(..cfg, api_client: client)
}

/// Creates a `Context` with the given session and default update/config.
pub fn context(session session: session) -> bot.Context(session, error) {
  context_with(session:, update: factory.text_update(text: "Hello"))
}

/// Creates a `Context` with the given session and update.
pub fn context_with(
  session session: session,
  update update: update.Update,
) -> bot.Context(session, error) {
  context_with_all(
    session:,
    update:,
    key: "test_chat:123",
    bot_info: factory.bot_user(),
  )
}

/// Creates a `Context` with full customization.
pub fn context_with_all(
  session session: session,
  update update: update.Update,
  key key: String,
  bot_info bot_info: types.User,
) -> bot.Context(session, error) {
  let chat_subject = process.new_subject()
  bot.Context(
    key:,
    update:,
    config: config(),
    session:,
    chat_subject:,
    start_time: None,
    log_prefix: None,
    bot_info:,
  )
}

/// Creates `SessionSettings` with a no-op persist and get returning None.
pub fn session_settings(
  default default: fn() -> session,
) -> bot.SessionSettings(session, error) {
  bot.SessionSettings(
    persist_session: fn(_key, session) { Ok(session) },
    get_session: fn(_key) { Ok(None) },
    default_session: default,
  )
}

/// Creates `SessionSettings` where get returns `Some(initial)`.
pub fn session_settings_with(
  default default: fn() -> session,
  initial initial: session,
) -> bot.SessionSettings(session, error) {
  bot.SessionSettings(
    persist_session: fn(_key, session) { Ok(session) },
    get_session: fn(_key) { Ok(Some(initial)) },
    default_session: default,
  )
}

/// Creates a no-op catch handler.
pub fn catch_handler() -> bot.CatchHandler(session, error) {
  fn(_ctx, _error) { Ok(Nil) }
}
