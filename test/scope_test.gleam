//// The per-update scratch space behind `ctx.scope`: what one update writes
//// there must be invisible to the next one, and must not pile up in the chat
//// instance's process dictionary either.

import gleam/option.{type Option, None, Some}
import gleeunit/should

import telega/scope.{Key}

const locale: scope.Key(String) = Key("scope_test/locale")

const count: scope.Key(Int) = Key("scope_test/count")

const pending: scope.Key(Option(Int)) = Key("scope_test/pending")

pub fn put_and_get_roundtrips_test() {
  let s = scope.new()

  scope.get(s, locale) |> should.equal(Error(Nil))

  scope.put(s, locale, "ru")
  scope.get(s, locale) |> should.equal(Ok("ru"))

  // Whole Gleam values, not just strings.
  scope.put(s, pending, Some(7))
  scope.get(s, pending) |> should.equal(Ok(Some(7)))
}

pub fn erase_forgets_one_slot_test() {
  let s = scope.new()
  scope.put(s, locale, "ru")
  scope.put(s, count, 2)

  scope.erase(s, locale)

  scope.get(s, locale) |> should.equal(Error(Nil))
  scope.has(s, locale) |> should.be_false
  scope.get(s, count) |> should.equal(Ok(2))
}

/// Two scopes in one process are two namespaces: this is what keeps a flag
/// left by one update from answering for the next, since a chat instance
/// handles thousands of updates in the same process.
pub fn scopes_do_not_see_each_other_test() {
  let first = scope.new()
  let second = scope.new()

  scope.put(first, locale, "ru")

  scope.get(second, locale) |> should.equal(Error(Nil))
  scope.get(first, locale) |> should.equal(Ok("ru"))
}

/// `clear` is what the chat instance calls once an update is handled, so the
/// process dictionary does not grow one namespace per update.
pub fn clear_empties_the_whole_scope_test() {
  let s = scope.new()
  scope.put(s, locale, "ru")
  scope.put(s, count, 2)

  scope.clear(s)

  scope.get(s, locale) |> should.equal(Error(Nil))
  scope.get(s, count) |> should.equal(Error(Nil))

  // A cleared scope is still usable — clearing is not closing.
  scope.put(s, count, 3)
  scope.get(s, count) |> should.equal(Ok(3))
}

/// A slot holding `None` is a filled slot: `get` tells it apart from one that
/// was never written, so an optional value round-trips as itself.
pub fn a_stored_none_is_not_an_empty_slot_test() {
  let s = scope.new()
  scope.put(s, pending, None)

  scope.get(s, pending) |> should.equal(Ok(None))
  scope.has(s, pending) |> should.be_true
}
