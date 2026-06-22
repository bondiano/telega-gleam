//// Role-based access control: gate handlers on a user's chat role.
////
//// Telegram exposes a user's role in a chat through `getChatMember`. This
//// module wraps that call with a small TTL cache (one API round-trip is too
//// slow to repeat on every message) and exposes it three ways:
////
//// - **Booleans** — [`is_admin`](#is_admin) / [`is_owner`](#is_owner) for ad-hoc
////   checks inside a handler.
//// - **`use` guards** — [`ensure_admin`](#ensure_admin) / [`ensure_owner`](#ensure_owner)
////   wrap a handler body and run an `on_denied` branch otherwise.
//// - **Router middleware** — [`require_admin`](#require_admin) /
////   [`require_owner`](#require_owner) gate every route of a (sub-)router.
////
//// "Admin" means administrator *or* owner; "owner" means the chat creator only.
////
//// ## Caching
////
//// [`new_cache`](#new_cache) returns a cache backed by an ETS table owned by the
//// calling process — create it once at bot setup, not inside a handler. Entries
//// expire after `ttl_ms`; pass `ttl_ms: 0` to disable caching and always hit the
//// API. The cache is keyed by `{chat_id}:{user_id}`, so a role change (promote /
//// demote) is picked up after at most `ttl_ms`.
////
//// ```gleam
//// import telega/roles
//// import telega/router
////
//// // Cache roles for 60s.
//// let cache = roles.new_cache(ttl_ms: 60_000)
////
//// // Admin-only /ban command:
//// router.new("admin")
//// |> router.on_command("ban", fn(ctx, _cmd) {
////   use ctx <- roles.ensure_admin(ctx, cache, on_denied: fn(ctx) {
////     reply.with_text(ctx, "Admins only.")
////   })
////   // ... ban logic, only reached for admins ...
////   Ok(ctx)
//// })
//// ```
////
//// On an API error the check fails closed (access denied) and the result is not
//// cached, so the next update retries.

import gleam/erlang/atom
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/result

import telega/api
import telega/bot.{type Context}
import telega/client.{type TelegramClient}
import telega/error
import telega/internal/utils
import telega/model/types
import telega/router.{type Middleware}
import telega/update.{type Update}

type EtsTable

/// A TTL cache of resolved chat roles. Create once with [`new_cache`](#new_cache).
pub opaque type RoleCache {
  RoleCache(table: EtsTable, ttl_ms: Int)
}

// Cached role status strings.
const status_owner = "owner"

const status_admin = "admin"

const status_member = "member"

/// Create a role cache. Entries expire after `ttl_ms` milliseconds; `ttl_ms: 0`
/// disables caching (every check hits the API).
///
/// The ETS table is owned by the calling process — create the cache from a
/// long-lived process (bot setup), not from a handler.
pub fn new_cache(ttl_ms ttl_ms: Int) -> RoleCache {
  let table =
    ets_new(atom.create("telega_role_cache"), [
      atom.create("set"),
      atom.create("public"),
    ])
  RoleCache(table:, ttl_ms:)
}

/// `True` if the user is an administrator or the owner of the chat.
pub fn is_admin(
  cache cache: RoleCache,
  client client: TelegramClient,
  chat_id chat_id: Int,
  user_id user_id: Int,
) -> Bool {
  let status = status_of(cache, client, chat_id, user_id)
  status == status_owner || status == status_admin
}

/// `True` if the user is the owner (creator) of the chat.
pub fn is_owner(
  cache cache: RoleCache,
  client client: TelegramClient,
  chat_id chat_id: Int,
  user_id user_id: Int,
) -> Bool {
  status_of(cache, client, chat_id, user_id) == status_owner
}

/// `use`-friendly guard: run `next` only if the user is an admin/owner of the
/// current chat, otherwise run `on_denied`.
///
/// ```gleam
/// use ctx <- roles.ensure_admin(ctx, cache, on_denied: deny)
/// // admin-only body
/// ```
pub fn ensure_admin(
  ctx ctx: Context(session, error, dependencies),
  cache cache: RoleCache,
  on_denied on_denied: fn(Context(session, error, dependencies)) ->
    Result(Context(session, error, dependencies), error),
  next next: fn(Context(session, error, dependencies)) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
  case
    is_admin(
      cache,
      ctx.config.api_client,
      ctx.update.chat_id,
      ctx.update.from_id,
    )
  {
    True -> next(ctx)
    False -> on_denied(ctx)
  }
}

/// `use`-friendly guard: run `next` only if the user owns the current chat,
/// otherwise run `on_denied`.
pub fn ensure_owner(
  ctx ctx: Context(session, error, dependencies),
  cache cache: RoleCache,
  on_denied on_denied: fn(Context(session, error, dependencies)) ->
    Result(Context(session, error, dependencies), error),
  next next: fn(Context(session, error, dependencies)) ->
    Result(Context(session, error, dependencies), error),
) -> Result(Context(session, error, dependencies), error) {
  case
    is_owner(
      cache,
      ctx.config.api_client,
      ctx.update.chat_id,
      ctx.update.from_id,
    )
  {
    True -> next(ctx)
    False -> on_denied(ctx)
  }
}

/// Router middleware that gates every route on admin/owner status. Non-admins
/// are handed to `on_denied` instead of the matched handler.
///
/// Apply it to a dedicated admin sub-router and compose it with your main
/// router so only those routes are gated:
///
/// ```gleam
/// let admin =
///   router.new("admin")
///   |> router.use_middleware(roles.require_admin(cache:, on_denied: deny))
///   |> router.on_command("ban", ban_handler)
///
/// router.compose(main_router, admin)
/// ```
pub fn require_admin(
  cache cache: RoleCache,
  on_denied on_denied: fn(Context(session, error, dependencies)) ->
    Result(Context(session, error, dependencies), error),
) -> Middleware(session, error, dependencies) {
  fn(handler) {
    fn(ctx: Context(session, error, dependencies), upd: Update) {
      case is_admin(cache, ctx.config.api_client, upd.chat_id, upd.from_id) {
        True -> handler(ctx, upd)
        False -> on_denied(ctx)
      }
    }
  }
}

/// Router middleware that gates every route on owner (creator) status.
pub fn require_owner(
  cache cache: RoleCache,
  on_denied on_denied: fn(Context(session, error, dependencies)) ->
    Result(Context(session, error, dependencies), error),
) -> Middleware(session, error, dependencies) {
  fn(handler) {
    fn(ctx: Context(session, error, dependencies), upd: Update) {
      case is_owner(cache, ctx.config.api_client, upd.chat_id, upd.from_id) {
        True -> handler(ctx, upd)
        False -> on_denied(ctx)
      }
    }
  }
}

// --- Internal: cache + API resolution ---------------------------------------

fn status_of(
  cache: RoleCache,
  client: TelegramClient,
  chat_id: Int,
  user_id: Int,
) -> String {
  let key = int.to_string(chat_id) <> ":" <> int.to_string(user_id)

  case cache_get(cache, key) {
    Some(status) -> status
    None ->
      case query_status(client, chat_id, user_id) {
        // Cache only successful lookups so transient API errors aren't sticky.
        Ok(status) -> {
          cache_put(cache, key, status)
          status
        }
        // Fail closed: deny on API error, and don't cache the denial.
        Error(_) -> status_member
      }
  }
}

fn query_status(
  client: TelegramClient,
  chat_id: Int,
  user_id: Int,
) -> Result(String, error.TelegaError) {
  api.get_chat_member(
    client,
    types.GetChatMemberParameters(chat_id: types.Int(value: chat_id), user_id:),
  )
  |> result.map(classify)
}

fn classify(member: types.ChatMember) -> String {
  case member {
    types.ChatMemberOwnerChatMember(_) -> status_owner
    types.ChatMemberAdministratorChatMember(_) -> status_admin
    _ -> status_member
  }
}

fn cache_get(cache: RoleCache, key: String) -> Option(String) {
  case cache.ttl_ms <= 0 {
    True -> None
    False ->
      case ets_lookup(cache.table, key) {
        [#(_, status, expires_at), ..] ->
          case utils.current_time_ms() < expires_at {
            True -> Some(status)
            False -> {
              ets_delete(cache.table, key)
              None
            }
          }
        _ -> None
      }
  }
}

fn cache_put(cache: RoleCache, key: String, status: String) -> Nil {
  case cache.ttl_ms <= 0 {
    True -> Nil
    False -> {
      ets_insert(cache.table, #(
        key,
        status,
        utils.current_time_ms() + cache.ttl_ms,
      ))
      Nil
    }
  }
}

@external(erlang, "ets", "new")
fn ets_new(name: atom.Atom, options: List(atom.Atom)) -> EtsTable

@external(erlang, "ets", "insert")
fn ets_insert(table: EtsTable, tuple: #(String, String, Int)) -> Bool

@external(erlang, "ets", "lookup")
fn ets_lookup(table: EtsTable, key: String) -> List(#(String, String, Int))

@external(erlang, "ets", "delete")
fn ets_delete(table: EtsTable, key: String) -> Bool
