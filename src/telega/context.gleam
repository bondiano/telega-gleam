//// The per-update context every handler receives.
////
//// A `Context` is built by the chat instance for each update and dropped once
//// the update is handled. It carries the update, the session loaded for this
//// chat, the injected `dependencies`, the API configuration and a
//// [`Scope`](scope.html) for per-update scratch state. Handlers return a
//// (possibly updated) `Context`; `bot.next_session` is how a handler changes
//// the session it will hand back.
////
//// `bot.Context` is the same type under its historical name.

import gleam/option.{type Option, None}

import telega/internal/config.{type Config}
import telega/model/types.{type User}
import telega/scope.{type Scope}
import telega/update.{type Update}

pub type Context(session, error, dependencies) {
  Context(
    /// The session key this update was routed under (`telega.with_session_key`).
    key: String,
    update: Update,
    config: Config,
    session: session,
    /// Non-persisted services injected at bot init (a db pool, an http client,
    /// an i18n catalog). Unlike `session`, never persisted. See
    /// `telega.with_dependencies`.
    dependencies: dependencies,
    /// Prefix `telega.log_info` / `log_error` put in front of their messages;
    /// set by `telega.log_context`.
    log_prefix: Option(String),
    bot_info: User,
    /// Scratch space for *this* update, shared by every copy of the context
    /// and dropped once the update is handled. Where the dialog engine keeps
    /// its "callback already answered" flag and its widget stash, where a
    /// pre-handler's annotations land, and where a middleware can hand a
    /// resolved locale to handlers nested below it. See
    /// [`telega/scope`](scope.html).
    scope: Scope,
  )
}

/// A fresh context for one update, with an empty scope.
pub fn new(
  key key: String,
  update update: Update,
  config config: Config,
  session session: session,
  dependencies dependencies: dependencies,
  bot_info bot_info: User,
) -> Context(session, error, dependencies) {
  Context(
    key:,
    update:,
    config:,
    session:,
    dependencies:,
    log_prefix: None,
    bot_info:,
    scope: scope.new(),
  )
}
