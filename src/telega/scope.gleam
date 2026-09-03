//// Per-update scratch space carried by [`Context`](bot.html#Context).
////
//// Some things a handler does have to be visible to code that never receives
//// the handler's return value: the dialog engine has to know whether the
//// user's `on_action` already answered the callback query, an API transformer
//// deep inside the client has to know whether this particular call opted out
//// of the webhook-reply claim, an i18n middleware has to hand the resolved
//// locale to `t(ctx, ...)` calls nested anywhere below it.
////
//// A `Scope` is the explicit place for exactly that. It is created once per
//// update, travels in `ctx.scope` (so every copy of the context — including
//// `Context(..ctx, session:)` — shares it), and is dropped when the update is
//// handled. Slots live in the process dictionary of the chat instance under a
//// namespace unique to the scope, which is what makes a leftover flag from an
//// earlier update unreadable rather than merely unlikely.
////
//// A slot is named by a typed [`Key`](#Key), so a read and a write agree on
//// the value's type by construction:
////
//// ```gleam
//// const locale_key: scope.Key(String) = scope.Key("my_bot/locale")
////
//// pub fn set_locale(ctx: Context(s, e, d), locale: String) -> Nil {
////   scope.put(ctx.scope, locale_key, locale)
//// }
////
//// pub fn locale(ctx: Context(s, e, d)) -> String {
////   scope.get(ctx.scope, locale_key) |> result.unwrap("en")
//// }
//// ```
////
//// Name keys after the module that owns them (`"my_bot/locale"`, not
//// `"locale"`): a scope is one flat namespace shared by the library, your
//// bot, and any middleware, and one name used at two different types is the
//// single way to get a value back that is not the one you stored.
////
//// A scope is *not* a place for application state: the session is per-user
//// persisted state, `telega/store` is chat/user/global state, `dependencies`
//// are services. It holds only what is true of the update being handled, and
//// only for as long as that update is.
////
//// A scope belongs to the process handling the update. Reading it from a
//// process you spawned yourself finds nothing rather than what the spawning
//// handler put there.

import gleam/bool
import gleam/dynamic/decode
import gleam/int
import gleam/list
import gleam/result
import telega/internal/scope as pdict

/// A per-update key/value namespace. Opaque: the runtime builds one per
/// update, and [`put`](#put) / [`get`](#get) are how it is read and written.
pub opaque type Scope {
  Scope(prefix: String)
}

/// The name of one slot, together with the type of what it holds.
///
/// Build it as a constant next to the code that owns the slot, so nothing
/// else can name it at another type:
///
/// ```gleam
/// const answered_key: scope.Key(String) = scope.Key("dialog/answered")
/// ```
pub type Key(value) {
  Key(name: String)
}

/// A fresh scope, sharing slots with no other scope alive or dead.
///
/// The runtime creates one per update; call this yourself only when you build
/// a `Context` by hand.
pub fn new() -> Scope {
  Scope(prefix: "telega/scope:" <> int.to_string(pdict.unique_integer()) <> ":")
}

/// Store `value` in `key`'s slot, replacing whatever was there.
pub fn put(scope scope: Scope, key key: Key(value), value value: value) -> Nil {
  let slot = slot(scope, key)
  let _ = pdict.put(index_key(scope), [slot, ..slots(scope)] |> list.unique)
  let _ = pdict.put(slot, value)
  Nil
}

/// Read `key`'s slot back. `Error(Nil)` when this scope never filled it.
pub fn get(scope scope: Scope, key key: Key(value)) -> Result(value, Nil) {
  let slot = slot(scope, key)
  use <- bool.guard(!list.contains(slots(scope), slot), Error(Nil))
  Ok(coerce(pdict.get(slot)))
}

/// Whether this scope has filled `key`'s slot.
pub fn has(scope scope: Scope, key key: Key(value)) -> Bool {
  list.contains(slots(scope), slot(scope, key))
}

/// Empty one slot.
pub fn erase(scope scope: Scope, key key: Key(value)) -> Nil {
  let slot = slot(scope, key)
  let _ = pdict.erase(slot)
  let _ =
    pdict.put(
      index_key(scope),
      slots(scope) |> list.filter(fn(s) { s != slot }),
    )
  Nil
}

/// Empty the whole scope. The runtime calls this once the update is handled,
/// which is what keeps a long-lived chat instance's process dictionary from
/// growing one namespace per update. A cleared scope is still usable.
pub fn clear(scope scope: Scope) -> Nil {
  list.each(slots(scope), pdict.erase)
  let _ = pdict.erase(index_key(scope))
  Nil
}

fn slot(scope: Scope, key: Key(value)) -> String {
  scope.prefix <> key.name
}

fn index_key(scope: Scope) -> String {
  scope.prefix <> "__slots"
}

/// Which slots this scope has filled. Presence is settled by this index and
/// not by the stored term, so a slot holding `None` — or any other value that
/// looks like an empty one — is still a filled slot.
fn slots(scope: Scope) -> List(String) {
  pdict.get(index_key(scope))
  |> decode.run(decode.list(decode.string))
  |> result.unwrap([])
}

/// Safe only because a `Key(value)` is the only way to name a slot, and the
/// same key both filled it and is reading it back.
@external(erlang, "gleam_stdlib", "identity")
fn coerce(value: dynamic_value) -> value
