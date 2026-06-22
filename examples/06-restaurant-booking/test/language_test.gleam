//// Tests for the `/language` command and its callback.
////
//// The bot wires its SQLite connection and i18n catalog through `dependencies` (the
//// non-persisted dependency-injection slot on `Context`). These tests drive the
//// handlers directly with a `dependencies`-injected context built by
//// `context.context_with_dependencies` — the simplest way to unit-test handlers that
//// read `ctx.dependencies`. (For end-to-end actor-level tests, `telega/testing`'s
//// `conversation.run_with_dependencies` / `handler.with_test_bot_with_dependencies` take a
//// `dependencies` value.) End-to-end locale resolution is covered in `i18n_test`.

import gleam/option.{type Option, None, Some}
import sqlight

import telega/testing/context
import telega/testing/factory

import restaurant_booking/dependencies.{Dependencies}
import restaurant_booking/i18n
import restaurant_booking/settings

import test_db

fn run_with_dependencies(test_fn: fn(dependencies.Dependencies) -> Nil) -> Nil {
  case test_db.try_connect_and_setup() {
    None -> Nil
    Some(db) -> {
      let d = Dependencies(db:, catalog: i18n.catalog())
      test_fn(d)
      test_db.cleanup(db)
    }
  }
}

fn dependencies_db(d: dependencies.Dependencies) -> sqlight.Connection {
  d.db
}

/// `set_language` persists the chosen locale (the callback handler reads the db
/// and catalog from `ctx.dependencies`).
pub fn set_language_persists_choice_test() {
  use d <- run_with_dependencies

  let ctx = context.context_with_dependencies(session: Nil, dependencies: d)

  // No override stored yet for this chat/user.
  i18n.get_user_language(
    dependencies_db(d),
    ctx.update.chat_id,
    ctx.update.from_id,
  )
  |> expect_none

  let _ = settings.set_language(ctx, "query-id", "lang:ru")

  i18n.get_user_language(
    dependencies_db(d),
    ctx.update.chat_id,
    ctx.update.from_id,
  )
  |> expect_some("ru")
}

/// The `/language` command handler runs against a `dependencies`-injected context.
pub fn language_command_runs_test() {
  use d <- run_with_dependencies

  let ctx = context.context_with_dependencies(session: Nil, dependencies: d)

  // The handler resolves text via the i18n catalog from `ctx.dependencies`; we only
  // assert it doesn't crash building the picker keyboard.
  let _ = settings.language(ctx, factory.command(command: "language"))
  Nil
}

/// Storing then reading an override round-trips through the db in `dependencies`.
pub fn language_override_roundtrip_test() {
  use d <- run_with_dependencies

  let db = dependencies_db(d)
  i18n.get_user_language(db, 100, 200) |> expect_none

  let assert Ok(_) = i18n.set_user_language(db, 100, 200, "ru")
  i18n.get_user_language(db, 100, 200) |> expect_some("ru")

  // Overrides are per chat+user.
  i18n.get_user_language(db, 100, 999) |> expect_none

  let assert Ok(_) = i18n.set_user_language(db, 100, 200, "en")
  i18n.get_user_language(db, 100, 200) |> expect_some("en")
}

fn expect_none(value: Option(String)) -> Nil {
  let assert None = value
  Nil
}

fn expect_some(value: Option(String), expected: String) -> Nil {
  let assert Some(v) = value
  let assert True = v == expected
  Nil
}
