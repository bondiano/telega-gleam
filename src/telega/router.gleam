//// # Telega Router
////
//// The router module provides a flexible and composable routing system for Telegram bot updates.
//// It allows you to define handlers for different types of messages and organize them into
//// logical groups with middleware support, error handling, and composition capabilities.
////
//// ## Two types, two jobs
////
//// - [`Router`](#Router) is a **leaf**: routes, middleware, a catch handler,
////   an optional scope. Everything named `on_*` registers on a leaf.
//// - [`RouterTree`](#RouterTree) is a **composition**: an ordered list of
////   leaves, each optionally guarded by a [`Filter`](#Filter). It has no
////   routes of its own, so `on_command` on a tree does not compile — the
////   registration that a composed router used to swallow is now a type error.
////
//// `telega.with_router` takes a `Router`; `telega.with_router_tree` takes a
//// `RouterTree`. Both are converted to a [`Routable`](#Routable) internally.
////
//// ## Basic Usage
////
//// ```gleam
//// import telega/router
//// import telega/update
//// import telega/reply
////
//// let router =
////   router.new("my_bot")
////   |> router.on_command("start", handle_start)
////   |> router.on_command("help", handle_help)
////   |> router.on_any_text(handle_text)
////   |> router.on_photo(handle_photo)
////   |> router.fallback(handle_unknown)
//// ```
////
//// ## Routing Priority
////
//// Routes are matched in the following priority order:
//// 1. **Commands** - Exact command matches (e.g., "/start", "/help")
//// 2. **Callback Queries** - Callback data patterns
//// 3. **Custom Routes** - User-defined matchers
//// 4. **Media Routes** - Photo, video, voice, audio handlers
//// 5. **Text Routes** - Text pattern matching
//// 6. **Fallback** - Catch-all handler for unmatched updates
////
//// Within each category, routes are tried in the order they were added,
//// with the first matching route handling the update.
////
//// ## Pattern Matching
////
//// Text and callback queries support flexible pattern matching:
////
//// ```gleam
//// router
//// |> router.on_text(Exact("hello"), handle_hello)
//// |> router.on_text(Prefix("search:"), handle_search)
//// |> router.on_text(Contains("help"), handle_help_mention)
//// |> router.on_text(Suffix("?"), handle_question)
////
//// router
//// |> router.on_callback(Prefix("page:"), handle_pagination)
//// |> router.on_callback(Exact("cancel"), handle_cancel)
//// ```
////
//// ### Typed callback routes
////
//// A [`keyboard.KeyboardCallbackData`](telega/keyboard.html#KeyboardCallbackData)
//// factory already knows how to serialize and parse its own payloads.
//// `on_callback_data` registers a route for exactly that factory's payloads and
//// hands the handler the decoded value — no `unpack_callback` in the handler,
//// and a payload that fails to decode never reaches it:
////
//// ```gleam
//// let page = keyboard.int_callback_data("page")
////
//// router
//// |> router.on_callback_data(page, fn(ctx, query, page_number) {
////   // page_number: Int
////   reply.with_text(ctx, "Page " <> int.to_string(page_number))
//// })
//// ```
////
//// ## Middleware System
////
//// Middleware allows you to wrap handlers with additional functionality.
//// The first middleware added is the outermost one, so it runs first and sees
//// the handler's result last:
////
//// ```gleam
//// router
//// |> router.use_middleware(router.with_logging)     // outermost, runs first
//// |> router.use_middleware(auth_middleware)
//// |> router.use_middleware(rate_limit_middleware)   // innermost, closest to the handler
//// ```
////
//// On a `RouterTree`, `use_middleware_on_tree` pushes the middleware into every
//// branch (each branch keeps its own copy, applied around its own handlers).
////
//// Built-in middleware includes:
//// - `with_logging` - Logs all update processing
//// - `with_filter` - Conditionally processes updates
//// - `with_recovery` - Recovers from handler errors
////
//// ## Error Handling
////
//// Routers support catch handlers to gracefully handle errors from routes:
////
//// ```gleam
//// router
//// |> router.with_catch_handler(fn(error) {
////   log.error("Route error: " <> string.inspect(error))
////   Error(error)
//// })
//// ```
////
//// The catch handler receives only the `error` (no context) and must return
//// `Result(Context, error)` — log and re-raise with `Error(error)`, or recover
//// with a context already in scope.
////
//// Note: The router's catch handler only handles errors from route handlers.
//// System-level errors (like session persistence failures) are handled by
//// the bot's main catch handler configured via `telega.with_catch_handler`.
////
//// ## Composition
////
//// ### Merging leaves
////
//// `merge` combines two leaf routers into one, with all routes unified.
//// Routes from the first router take priority in case of conflicts:
////
//// ```gleam
//// let admin_router =
////   router.new("admin")
////   |> router.on_command("ban", handle_ban)
////   |> router.on_command("stats", handle_stats)
////
//// let user_router =
////   router.new("user")
////   |> router.on_command("start", handle_start)
////   |> router.on_command("help", handle_help)
////
//// let main_router = router.merge(admin_router, user_router)
//// ```
////
//// ### Building a tree
////
//// `append` adds a leaf that is tried in order; `branch` adds one that is only
//// consulted when a filter matches. Each leaf keeps its own middleware and
//// catch handler:
////
//// ```gleam
//// let tree =
////   router.tree()
////   |> router.branch(router.is_private_chat(), private_router)
////   |> router.branch(router.is_group_chat(), group_router)
////   |> router.append(shared_router)
////   |> router.tree_fallback(handle_unknown)
////
//// telega.new_for_polling(token:)
//// |> telega.with_router_tree(tree)
//// ```
////
//// `compose(a, b)` and `compose_many([a, b, c])` are shorthand for a tree of
//// unconditional branches.
////
//// ### Scoped leaves
////
//// `scope` restricts a whole leaf to updates matching a predicate. A scoped
//// leaf declines out-of-scope updates outright, so the next branch of the tree
//// gets its turn:
////
//// ```gleam
//// let admin_router =
////   router.new("admin")
////   |> router.on_command("ban", handle_ban)
////   |> router.scope(fn(update) { is_admin(update.from_id) })
//// ```
////
//// ## Custom Routes
////
//// For complex routing logic, use custom matchers:
////
//// ```gleam
//// router
//// |> router.on_custom(
////   matcher: fn(update) {
////     case update {
////       update.TextUpdate(text: t, ..) ->
////         string.starts_with(t, "http://") || string.starts_with(t, "https://")
////       _ -> False
////     }
////   },
////   handler: handle_link
//// )
//// ```
////
//// ## Magic Filters
////
//// The router includes a powerful filter system for creating complex routing conditions:
////
//// ```gleam
//// // Simple filters
//// router
//// |> router.on_filtered(router.is_private_chat(), handle_private)
//// |> router.on_filtered(router.from_user(admin_id), handle_admin)
////
//// // Combining filters with AND logic
//// router
//// |> router.on_filtered(
////   router.and2(
////     router.is_group_chat(),
////     router.text_starts_with("!")
////   ),
////   handle_group_command
//// )
////
//// // Combining multiple filters
//// router
//// |> router.on_filtered(
////   router.and([
////     router.is_text(),
////     router.from_users([admin1, admin2, admin3]),
////     router.not(router.text_starts_with("/"))
////   ]),
////   handle_admin_text
//// )
//// ```
////
//// ### Filter reference
////
//// Every filter is a predicate over the **whole update**, so one table covers
//// them all. "Reads" says where the answer comes from — an update that has no
//// such field never matches.
////
//// | Filter | Reads | True when |
//// |---|---|---|
//// | `is_text()` | update kind | the update is a plain text message |
//// | `text_equals(t)` | text | the text is exactly `t` |
//// | `text_starts_with(p)` | text | the text starts with `p` |
//// | `text_contains(s)` | text | the text contains `s` |
//// | `is_command()` | update kind | the update is a command |
//// | `command_equals(c)` | command | the command is `c` (leading `/` optional) |
//// | `from_user(id)` | `update.from_id` | the sender is `id` |
//// | `from_users(ids)` | `update.from_id` | the sender is one of `ids` |
//// | `in_chat(id)` | `update.chat_id` | the update happened in chat `id` |
//// | `from_chats(ids)` | `update.chat_id` | the chat is one of `ids` |
//// | `is_private_chat()` | `update.chat().type_` | the chat is `"private"` |
//// | `is_group_chat()` | `update.chat().type_` | the chat is `"group"` or `"supergroup"` |
//// | `chat_type(t)` | `update.chat().type_` | the chat type is exactly `t` |
//// | `has_photo()` | update kind | the message carries photos |
//// | `has_video()` | update kind | the message carries a video |
//// | `is_media_group()` | update kind | the update is a buffered album |
//// | `has_media()` | update kind | photo, video, voice, audio or album |
//// | `is_callback_query()` | update kind | the update is a button press |
//// | `callback_data_starts_with(p)` | `query.data` | the callback payload starts with `p` |
//// | `is_forwarded()` | `message.forward_origin` | the message was forwarded |
//// | `is_reply()` | `message.reply_to_message` | the message replies to another |
//// | `in_topic(id)` | `message.message_thread_id` | the message is in forum topic `id` |
//// | `has_entity(kind)` | `message.entities` + `caption_entities` | an entity of that type is present (e.g. `"url"`, `"mention"`) |
//// | `via_bot()` | `message.via_bot` | the message was sent through an inline bot |
//// | `via_bot_id(id)` | `message.via_bot.id` | it was sent through bot `id` |
//// | `is_automatic_forward()` | `message.is_automatic_forward` | a channel post auto-forwarded to its discussion group |
//// | `has_media_spoiler()` | `message.has_media_spoiler` | the media is spoiler-covered |
////
//// The message-reading filters use `update.message`, which answers `None` for
//// updates that are not about a message (callback queries, inline queries,
//// polls, member changes) — those match none of them.
////
//// ## Handler Types
////
//// Different route types receive different handler signatures:
////
//// - `CommandHandler` - Receives the parsed command
//// - `TextHandler` - Receives the message text
//// - `CallbackHandler` - Receives callback query id and data
//// - `CallbackDataHandler` - Receives the callback query and a decoded payload
//// - `PhotoHandler` - Receives list of photo sizes
//// - `VideoHandler` - Receives video info
//// - `VoiceHandler` - Receives voice message info
//// - `AudioHandler` - Receives audio file
//// - `MediaGroupHandler` - Receives media group ID and list of messages
//// - `MessageHandler` - Receives a whole message (edits, channel posts, business messages)
//// - `Handler` - Generic handler for any update type
////

import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order
import gleam/result
import gleam/string
import telega/bot.{type Context}

import telega/internal/log
import telega/internal/rate_limiter
import telega/keyboard.{type KeyboardCallbackData}
import telega/model/types.{
  type Audio, type CallbackQuery, type ChatBoostRemoved, type ChatBoostUpdated,
  type ChatJoinRequest, type ChatMemberUpdated, type ChosenInlineResult,
  type InlineQuery, type Message, type MessageEntity,
  type MessageReactionCountUpdated, type MessageReactionUpdated,
  type PaidMediaPurchased, type PhotoSize, type Poll, type PollAnswer,
  type PreCheckoutQuery, type ReactionType, type ShippingQuery, type Video,
  type Voice, type WebAppData, ReactionTypeEmojiReactionType,
  ReactionTypePaidReactionType,
}
import telega/telemetry
import telega/update.{type Command, type Update}

/// A leaf router: routes, middleware, a catch handler and an optional scope.
///
/// Every `on_*` function registers on one of these. Compositions live in
/// [`RouterTree`](#RouterTree) — a separate type, so a registration on a
/// composition is a compile error rather than a route that quietly goes
/// nowhere.
pub opaque type Router(session, error, dependencies) {
  Router(
    commands: Dict(String, Handler(session, error, dependencies)),
    /// Optional human-readable descriptions for registered commands, keyed by
    /// the same normalized command name as `commands`. Populated by
    /// `on_command_with_description` and consumed by the auto `setMyCommands`
    /// machinery in `telega`.
    command_descriptions: Dict(String, String),
    callbacks: Dict(String, Handler(session, error, dependencies)),
    routes: List(Route(session, error, dependencies)),
    fallback: Option(Handler(session, error, dependencies)),
    middleware: List(Middleware(session, error, dependencies)),
    catch_handler: Option(
      fn(error) -> Result(Context(session, error, dependencies), error),
    ),
    /// Set by `scope`: an update the predicate rejects is not this router's,
    /// so `handle` returns the context untouched and, inside a tree, the next
    /// branch gets its turn.
    scope_predicate: Option(fn(Update) -> Bool),
    name: String,
  )
}

/// An ordered composition of leaf routers.
///
/// A tree holds no routes of its own: `on_command` and friends are not defined
/// for it. Build one with [`tree`](#tree) and add leaves with
/// [`append`](#append) (always tried) or [`branch`](#branch) (tried only when a
/// filter matches). Branches are consulted in the order they were added, and
/// the first one that both passes its filter and has a route for the update
/// handles it.
pub opaque type RouterTree(session, error, dependencies) {
  RouterTree(
    branches: List(Branch(session, error, dependencies)),
    fallback: Option(Handler(session, error, dependencies)),
  )
}

/// One leaf of a tree, with the filter that guards it (if any).
type Branch(session, error, dependencies) {
  Branch(filter: Option(Filter), router: Router(session, error, dependencies))
}

/// What `telega` actually stores: a leaf and a tree reduced to the four things
/// the bot needs from a router. Build one with [`routable`](#routable) or
/// [`tree_routable`](#tree_routable).
pub type Routable(session, error, dependencies) {
  Routable(
    name: String,
    handle: fn(Context(session, error, dependencies), Update) ->
      Result(Context(session, error, dependencies), error),
    /// The derived `allowed_updates` set; `[]` means "do not restrict".
    allowed_updates: List(String),
    /// `#(command, description)` pairs for `setMyCommands`.
    registered_commands: List(#(String, String)),
  )
}

/// Generic handler type for all updates
pub type Handler(session, error, dependencies) =
  fn(Context(session, error, dependencies), Update) ->
    Result(Context(session, error, dependencies), error)

pub type CommandHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), Command) ->
    Result(Context(session, error, dependencies), error)

pub type TextHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), String) ->
    Result(Context(session, error, dependencies), error)

pub type CallbackHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), String, String) ->
    Result(Context(session, error, dependencies), error)

/// Handler for a typed callback route registered with `on_callback_data`:
/// the callback query itself plus the payload already decoded by the
/// `keyboard.KeyboardCallbackData` factory the route was registered with.
pub type CallbackDataHandler(session, error, dependencies, data) =
  fn(Context(session, error, dependencies), CallbackQuery, data) ->
    Result(Context(session, error, dependencies), error)

pub type PhotoHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), List(PhotoSize)) ->
    Result(Context(session, error, dependencies), error)

pub type VideoHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), Video) ->
    Result(Context(session, error, dependencies), error)

pub type VoiceHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), Voice) ->
    Result(Context(session, error, dependencies), error)

pub type AudioHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), Audio) ->
    Result(Context(session, error, dependencies), error)

pub type MediaGroupHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), String, List(Message)) ->
    Result(Context(session, error, dependencies), error)

pub type MessageHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), Message) ->
    Result(Context(session, error, dependencies), error)

pub type WebAppDataHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), WebAppData) ->
    Result(Context(session, error, dependencies), error)

pub type InlineQueryHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), InlineQuery) ->
    Result(Context(session, error, dependencies), error)

pub type ChosenInlineResultHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), ChosenInlineResult) ->
    Result(Context(session, error, dependencies), error)

pub type ShippingQueryHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), ShippingQuery) ->
    Result(Context(session, error, dependencies), error)

pub type PreCheckoutQueryHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), PreCheckoutQuery) ->
    Result(Context(session, error, dependencies), error)

pub type PaidMediaPurchaseHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), PaidMediaPurchased) ->
    Result(Context(session, error, dependencies), error)

pub type PollHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), Poll) ->
    Result(Context(session, error, dependencies), error)

pub type PollAnswerHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), PollAnswer) ->
    Result(Context(session, error, dependencies), error)

pub type MessageReactionHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), MessageReactionUpdated) ->
    Result(Context(session, error, dependencies), error)

pub type MessageReactionCountHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), MessageReactionCountUpdated) ->
    Result(Context(session, error, dependencies), error)

pub type ChatMemberUpdatedHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), ChatMemberUpdated) ->
    Result(Context(session, error, dependencies), error)

pub type ChatJoinRequestHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), ChatJoinRequest) ->
    Result(Context(session, error, dependencies), error)

pub type ChatBoostHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), ChatBoostUpdated) ->
    Result(Context(session, error, dependencies), error)

pub type RemovedChatBoostHandler(session, error, dependencies) =
  fn(Context(session, error, dependencies), ChatBoostRemoved) ->
    Result(Context(session, error, dependencies), error)

/// Middleware wraps a handler with additional functionality
pub type Middleware(session, error, dependencies) =
  fn(Handler(session, error, dependencies)) ->
    Handler(session, error, dependencies)

/// Pattern matching for text and callbacks
pub type Pattern {
  Exact(String)
  Prefix(String)
  Contains(String)
  Suffix(String)
}

/// Filter type for composable update filtering
pub opaque type Filter {
  Filter(check: fn(Update) -> Bool, name: String)
  And(left: Filter, right: Filter)
  Or(left: Filter, right: Filter)
  Not(filter: Filter)
}

/// Unified route type that encompasses all route types
pub type Route(session, error, dependencies) {
  TextPatternRoute(
    pattern: Pattern,
    handler: TextHandler(session, error, dependencies),
  )
  PhotoRoute(handler: PhotoHandler(session, error, dependencies))
  VideoRoute(handler: VideoHandler(session, error, dependencies))
  VoiceRoute(handler: VoiceHandler(session, error, dependencies))
  AudioRoute(handler: AudioHandler(session, error, dependencies))
  MediaGroupRoute(handler: MediaGroupHandler(session, error, dependencies))
  /// Data sent by a Mini App through `Telegram.WebApp.sendData`.
  WebAppDataRoute(handler: WebAppDataHandler(session, error, dependencies))
  /// A message the user edited.
  EditedMessageRoute(handler: MessageHandler(session, error, dependencies))
  /// A post in a channel the bot administers.
  ChannelPostRoute(handler: MessageHandler(session, error, dependencies))
  /// An edited channel post.
  EditedChannelPostRoute(handler: MessageHandler(session, error, dependencies))
  /// A message from a connected business account's chat.
  BusinessMessageRoute(handler: MessageHandler(session, error, dependencies))
  InlineQueryRoute(handler: InlineQueryHandler(session, error, dependencies))
  ChosenInlineResultRoute(
    handler: ChosenInlineResultHandler(session, error, dependencies),
  )
  ShippingQueryRoute(
    handler: ShippingQueryHandler(session, error, dependencies),
  )
  PreCheckoutQueryRoute(
    handler: PreCheckoutQueryHandler(session, error, dependencies),
  )
  /// A paid media purchase, for `sendPaidMedia` with a payload.
  PaidMediaPurchaseRoute(
    handler: PaidMediaPurchaseHandler(session, error, dependencies),
  )
  PollRoute(handler: PollHandler(session, error, dependencies))
  PollAnswerRoute(handler: PollAnswerHandler(session, error, dependencies))
  MessageReactionRoute(
    handler: MessageReactionHandler(session, error, dependencies),
  )
  MessageReactionEmojiRoute(
    emojis: List(String),
    handler: MessageReactionHandler(session, error, dependencies),
  )
  MessageReactionPaidRoute(
    handler: MessageReactionHandler(session, error, dependencies),
  )
  MessageReactionAddedRoute(
    handler: MessageReactionHandler(session, error, dependencies),
  )
  MessageReactionRemovedRoute(
    handler: MessageReactionHandler(session, error, dependencies),
  )
  MessageReactionCountRoute(
    handler: MessageReactionCountHandler(session, error, dependencies),
  )
  ChatMemberUpdatedRoute(
    handler: ChatMemberUpdatedHandler(session, error, dependencies),
  )
  /// The *bot's own* membership changed — it was blocked, unblocked, added to
  /// a group, or promoted. A different Telegram update kind from
  /// `chat_member`, and `allowed_updates` lists them separately.
  MyChatMemberUpdatedRoute(
    handler: ChatMemberUpdatedHandler(session, error, dependencies),
  )
  ChatJoinRequestRoute(
    handler: ChatJoinRequestHandler(session, error, dependencies),
  )
  /// A chat boost was added or changed.
  ChatBoostRoute(handler: ChatBoostHandler(session, error, dependencies))
  /// A chat boost was removed.
  RemovedChatBoostRoute(
    handler: RemovedChatBoostHandler(session, error, dependencies),
  )
  /// An update this version of the library cannot interpret. Registering one
  /// makes `allowed_updates` derivation give up on narrowing — an update kind
  /// the library does not know is, by definition, not in the derived set.
  UnknownUpdateRoute(handler: Handler(session, error, dependencies))
  CustomRoute(
    matcher: fn(Update) -> Bool,
    handler: Handler(session, error, dependencies),
  )
  FilteredRoute(filter: Filter, handler: Handler(session, error, dependencies))
}

/// Create a new leaf router
pub fn new(name: String) -> Router(session, error, dependencies) {
  Router(
    commands: dict.new(),
    command_descriptions: dict.new(),
    callbacks: dict.new(),
    routes: [],
    fallback: None,
    middleware: [],
    catch_handler: None,
    scope_predicate: None,
    name: name,
  )
}

/// The router's name, as given to `new` (with `_scoped`/`+` suffixes from
/// `scope` and `merge`).
pub fn name(router: Router(session, error, dependencies)) -> String {
  router.name
}

/// Routes are prepended, so the newest registration is tried first.
fn add_route(
  router: Router(session, error, dependencies),
  route: Route(session, error, dependencies),
) -> Router(session, error, dependencies) {
  Router(..router, routes: [route, ..router.routes])
}

/// Add a command handler
pub fn on_command(
  router: Router(session, error, dependencies),
  command: String,
  handler: CommandHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  let command_key = normalize_command(command)
  let wrapped_handler = fn(ctx, upd) {
    case upd {
      update.CommandUpdate(command: cmd, ..) -> handler(ctx, cmd)
      _ -> Ok(ctx)
    }
  }
  Router(
    ..router,
    commands: dict.insert(router.commands, command_key, wrapped_handler),
  )
}

/// Add multiple commands with same handler
pub fn on_commands(
  router: Router(session, error, dependencies),
  commands: List(String),
  handler: CommandHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  list.fold(commands, router, fn(r, cmd) { on_command(r, cmd, handler) })
}

/// Add a command handler together with a human-readable description.
///
/// The description is what shows up in the Telegram command menu. When the bot
/// is started with `telega.with_auto_commands`, all commands registered this way
/// are published via `setMyCommands` automatically, and `telega_i18n` can supply
/// per-language variants. The description is ignored for routing — it only feeds
/// command auto-synchronization.
///
/// ```gleam
/// router
/// |> router.on_command_with_description("start", "Start the bot", handle_start)
/// |> router.on_command_with_description("help", "Show help", handle_help)
/// ```
pub fn on_command_with_description(
  router: Router(session, error, dependencies),
  command: String,
  description: String,
  handler: CommandHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  let key = normalize_command(command)
  let router = on_command(router, command, handler)
  Router(
    ..router,
    command_descriptions: dict.insert(
      router.command_descriptions,
      key,
      description,
    ),
  )
}

/// Key a command for the lookup table: no leading slash, lower case.
///
/// BotFather only accepts lowercase command names, but a user (or a phone
/// keyboard's autocapitalise) can still send `/Start` — matching it
/// case-sensitively would drop the command on the floor.
fn normalize_command(command: String) -> String {
  case string.starts_with(command, "/") {
    True -> string.drop_start(command, 1)
    False -> command
  }
  |> string.lowercase
}

/// Add a text handler with pattern
pub fn on_text(
  router: Router(session, error, dependencies),
  pattern: Pattern,
  handler: TextHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, TextPatternRoute(pattern:, handler:))
}

/// Add a handler for any text
pub fn on_any_text(
  router: Router(session, error, dependencies),
  handler: TextHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  on_text(router, Prefix(""), handler)
}

/// Add a callback query handler with pattern
pub fn on_callback(
  router: Router(session, error, dependencies),
  pattern: Pattern,
  handler: CallbackHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  let key = callback_key(pattern)
  let wrapped_handler = fn(ctx, upd) {
    case upd {
      update.CallbackQueryUpdate(query:, ..) ->
        case query.data {
          Some(data) -> handler(ctx, query.id, data)
          None -> Ok(ctx)
        }
      _ -> Ok(ctx)
    }
  }
  Router(
    ..router,
    callbacks: dict.insert(router.callbacks, key, wrapped_handler),
  )
}

/// Add a callback route for one `keyboard.KeyboardCallbackData` factory.
///
/// The route matches exactly the payloads that factory builds
/// (`Prefix(id <> delimiter)`) and the handler receives the value already
/// decoded — no `unpack_callback` boilerplate, and a payload that belongs to
/// another factory or fails to deserialize never reaches the handler.
///
/// ```gleam
/// let page = keyboard.int_callback_data("page")
///
/// router.new("bot")
/// |> router.on_callback_data(page, fn(ctx, _query, page_number) {
///   reply.with_text(ctx, "Page " <> int.to_string(page_number))
/// })
/// ```
///
/// A payload the factory rejects leaves the context untouched, so a sibling
/// route or the fallback never sees it — register the factory routes you
/// expect and a `Prefix` route for anything else.
pub fn on_callback_data(
  router: Router(session, error, dependencies),
  factory: KeyboardCallbackData(data),
  handler: CallbackDataHandler(session, error, dependencies, data),
) -> Router(session, error, dependencies) {
  let key = callback_key(Prefix(keyboard.callback_data_prefix(factory)))
  let wrapped_handler = fn(ctx, upd) {
    case upd {
      update.CallbackQueryUpdate(query:, ..) ->
        case query.data {
          Some(payload) ->
            case keyboard.unpack_callback(payload:, callback_data: factory) {
              Ok(callback) -> handler(ctx, query, callback.data)
              Error(Nil) -> Ok(ctx)
            }
          None -> Ok(ctx)
        }
      _ -> Ok(ctx)
    }
  }
  Router(
    ..router,
    callbacks: dict.insert(router.callbacks, key, wrapped_handler),
  )
}

/// Add handlers for media types
pub fn on_photo(
  router: Router(session, error, dependencies),
  handler: PhotoHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, PhotoRoute(handler:))
}

pub fn on_video(
  router: Router(session, error, dependencies),
  handler: VideoHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, VideoRoute(handler:))
}

pub fn on_voice(
  router: Router(session, error, dependencies),
  handler: VoiceHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, VoiceRoute(handler:))
}

pub fn on_audio(
  router: Router(session, error, dependencies),
  handler: AudioHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, AudioRoute(handler:))
}

/// Handle a whole album as one update.
///
/// Only fires when incoming albums are buffered — see
/// `telega.with_media_group_timeout`. Without it every photo of an album
/// arrives on its own `on_photo`/`on_video`/`on_audio` route.
pub fn on_media_group(
  router: Router(session, error, dependencies),
  handler: MediaGroupHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, MediaGroupRoute(handler:))
}

/// Data a Mini App sent with `Telegram.WebApp.sendData`.
pub fn on_web_app_data(
  router: Router(session, error, dependencies),
  handler: WebAppDataHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, WebAppDataRoute(handler:))
}

/// A message the user edited. Telegram does not send these by default —
/// `allowed_updates` derivation adds `"edited_message"` for you.
pub fn on_edited_message(
  router: Router(session, error, dependencies),
  handler: MessageHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, EditedMessageRoute(handler:))
}

/// A post in a channel the bot administers.
pub fn on_channel_post(
  router: Router(session, error, dependencies),
  handler: MessageHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, ChannelPostRoute(handler:))
}

/// An edited channel post.
pub fn on_edited_channel_post(
  router: Router(session, error, dependencies),
  handler: MessageHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, EditedChannelPostRoute(handler:))
}

/// A message in a chat connected to the bot's business account.
pub fn on_business_message(
  router: Router(session, error, dependencies),
  handler: MessageHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, BusinessMessageRoute(handler:))
}

pub fn on_inline_query(
  router: Router(session, error, dependencies),
  handler: InlineQueryHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, InlineQueryRoute(handler:))
}

pub fn on_chosen_inline_result(
  router: Router(session, error, dependencies),
  handler: ChosenInlineResultHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, ChosenInlineResultRoute(handler:))
}

pub fn on_shipping_query(
  router: Router(session, error, dependencies),
  handler: ShippingQueryHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, ShippingQueryRoute(handler:))
}

pub fn on_pre_checkout_query(
  router: Router(session, error, dependencies),
  handler: PreCheckoutQueryHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, PreCheckoutQueryRoute(handler:))
}

/// A user bought paid media the bot sent with a payload.
pub fn on_paid_media_purchase(
  router: Router(session, error, dependencies),
  handler: PaidMediaPurchaseHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, PaidMediaPurchaseRoute(handler:))
}

pub fn on_poll(
  router: Router(session, error, dependencies),
  handler: PollHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, PollRoute(handler:))
}

pub fn on_poll_answer(
  router: Router(session, error, dependencies),
  handler: PollAnswerHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, PollAnswerRoute(handler:))
}

/// Handle any reaction change on a message.
pub fn on_reaction(
  router: Router(session, error, dependencies),
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, MessageReactionRoute(handler:))
}

/// Handle reactions with one specific emoji.
pub fn on_reaction_emoji(
  router: Router(session, error, dependencies),
  emoji: String,
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, MessageReactionEmojiRoute(emojis: [emoji], handler:))
}

/// Handle reactions with any of the given emojis.
pub fn on_reaction_emojis(
  router: Router(session, error, dependencies),
  emojis: List(String),
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, MessageReactionEmojiRoute(emojis:, handler:))
}

/// Handle paid (star) reactions.
pub fn on_paid_reaction(
  router: Router(session, error, dependencies),
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, MessageReactionPaidRoute(handler:))
}

/// Handle only reaction *additions*.
pub fn on_reaction_added(
  router: Router(session, error, dependencies),
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, MessageReactionAddedRoute(handler:))
}

/// Handle only reaction *removals*.
pub fn on_reaction_removed(
  router: Router(session, error, dependencies),
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, MessageReactionRemovedRoute(handler:))
}

/// Handle anonymous reaction counters in large chats.
pub fn on_reaction_count(
  router: Router(session, error, dependencies),
  handler: MessageReactionCountHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, MessageReactionCountRoute(handler:))
}

/// Another member's status in a chat changed.
pub fn on_chat_member_updated(
  router: Router(session, error, dependencies),
  handler: ChatMemberUpdatedHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, ChatMemberUpdatedRoute(handler:))
}

/// The bot's own status in a chat changed (blocked, added, promoted).
pub fn on_my_chat_member_updated(
  router: Router(session, error, dependencies),
  handler: ChatMemberUpdatedHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, MyChatMemberUpdatedRoute(handler:))
}

pub fn on_chat_join_request(
  router: Router(session, error, dependencies),
  handler: ChatJoinRequestHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, ChatJoinRequestRoute(handler:))
}

/// A chat boost was added or changed. The bot must be an administrator.
pub fn on_chat_boost(
  router: Router(session, error, dependencies),
  handler: ChatBoostHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, ChatBoostRoute(handler:))
}

/// A chat boost was removed.
pub fn on_removed_chat_boost(
  router: Router(session, error, dependencies),
  handler: RemovedChatBoostHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, RemovedChatBoostRoute(handler:))
}

/// An update this version of the library cannot interpret: a Bot API kind it
/// does not know yet, or one whose payload failed to decode. The handler gets
/// the `UnknownUpdate` and can read `update.raw`.
///
/// Registering this route turns off `allowed_updates` narrowing — an update
/// kind the library does not know can never be in a derived set.
pub fn on_unknown_update(
  router: Router(session, error, dependencies),
  handler: Handler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, UnknownUpdateRoute(handler:))
}

/// Route on a hand-written predicate over the whole update.
pub fn on_custom(
  router: Router(session, error, dependencies),
  matcher matcher: fn(Update) -> Bool,
  handler handler: Handler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, CustomRoute(matcher:, handler:))
}

/// Route on a composable `Filter`.
pub fn on_filtered(
  router: Router(session, error, dependencies),
  filter: Filter,
  handler: Handler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  add_route(router, FilteredRoute(filter:, handler:))
}

/// Create a filter from a custom function
pub fn filter(name: String, check: fn(Update) -> Bool) -> Filter {
  Filter(check:, name:)
}

/// Combine filters with AND logic
pub fn and(filters: List(Filter)) -> Filter {
  case filters {
    [] -> filter("always", fn(_) { True })
    [f] -> f
    [f1, f2] -> And(f1, f2)
    [f1, ..rest] -> And(f1, and(rest))
  }
}

/// Combine two filters with AND logic
pub fn and2(left: Filter, right: Filter) -> Filter {
  And(left, right)
}

/// Combine filters with OR logic
pub fn or(filters: List(Filter)) -> Filter {
  case filters {
    [] -> filter("never", fn(_) { False })
    [f] -> f
    [f1, f2] -> Or(f1, f2)
    [f1, ..rest] -> Or(f1, or(rest))
  }
}

/// Combine two filters with OR logic
pub fn or2(left: Filter, right: Filter) -> Filter {
  Or(left, right)
}

/// Negate a filter
pub fn not(f: Filter) -> Filter {
  Not(f)
}

/// Filter for text messages
pub fn is_text() -> Filter {
  filter("is_text", fn(update) {
    case update {
      update.TextUpdate(..) -> True
      _ -> False
    }
  })
}

/// Filter for text that equals a specific value
pub fn text_equals(text: String) -> Filter {
  filter("text_equals:" <> text, fn(update) {
    case update {
      update.TextUpdate(text: t, ..) -> t == text
      _ -> False
    }
  })
}

/// Filter for text that starts with a prefix
pub fn text_starts_with(prefix: String) -> Filter {
  filter("text_starts_with:" <> prefix, fn(update) {
    case update {
      update.TextUpdate(text: t, ..) -> string.starts_with(t, prefix)
      _ -> False
    }
  })
}

/// Filter for text that contains a substring
pub fn text_contains(substring: String) -> Filter {
  filter("text_contains:" <> substring, fn(update) {
    case update {
      update.TextUpdate(text: t, ..) -> string.contains(t, substring)
      _ -> False
    }
  })
}

/// Filter for commands
pub fn is_command() -> Filter {
  filter("is_command", fn(update) {
    case update {
      update.CommandUpdate(..) -> True
      _ -> False
    }
  })
}

/// Filter for specific command
pub fn command_equals(cmd: String) -> Filter {
  filter("command:" <> cmd, fn(update) {
    case update {
      update.CommandUpdate(command:, ..) -> command.command == cmd
      _ -> False
    }
  })
}

/// Filter by user ID
pub fn from_user(user_id: Int) -> Filter {
  filter("from_user:" <> string.inspect(user_id), fn(update) {
    update.from_id == user_id
  })
}

/// Filter by multiple user IDs
pub fn from_users(user_ids: List(Int)) -> Filter {
  filter("from_users", fn(update) { list.contains(user_ids, update.from_id) })
}

/// Filter by chat ID
pub fn in_chat(chat_id: Int) -> Filter {
  filter("in_chat:" <> string.inspect(chat_id), fn(update) {
    update.chat_id == chat_id
  })
}

/// Filter by multiple chat IDs. Matches when the update's chat is one of
/// `chat_ids` — a whitelist of chats. Combine with `not` for a blacklist:
///
/// ```gleam
/// // Only react in the support chats
/// router.on_filtered(router.from_chats([-100_1, -100_2]), handler)
///
/// // React everywhere except the banned chats
/// router.on_filtered(router.not(router.from_chats([-100_666])), handler)
/// ```
pub fn from_chats(chat_ids: List(Int)) -> Filter {
  filter("from_chats", fn(update) { list.contains(chat_ids, update.chat_id) })
}

/// Filter for private chats.
///
/// Reads the chat's own `type_`, not the sign of `chat_id`: an update that
/// happens in no chat at all (an inline query, a poll answer) is not a private
/// chat, however its stand-in `chat_id` is keyed.
pub fn is_private_chat() -> Filter {
  filter("is_private_chat", fn(upd) {
    case update.chat(upd) {
      Some(chat) -> chat.type_ == "private"
      None -> False
    }
  })
}

/// Filter for group and supergroup chats. Channels are neither — use
/// `chat_type` for those.
pub fn is_group_chat() -> Filter {
  filter("is_group_chat", fn(upd) {
    case update.chat(upd) {
      Some(chat) -> chat.type_ == "group" || chat.type_ == "supergroup"
      None -> False
    }
  })
}

/// Filter on the chat's `type_` verbatim: "private", "group", "supergroup" or
/// "channel". Updates that happen in no chat never match.
pub fn chat_type(type_: String) -> Filter {
  filter("chat_type:" <> type_, fn(upd) {
    case update.chat(upd) {
      Some(chat) -> chat.type_ == type_
      None -> False
    }
  })
}

/// Filter for photo messages
pub fn has_photo() -> Filter {
  filter("has_photo", fn(update) {
    case update {
      update.PhotoUpdate(..) -> True
      _ -> False
    }
  })
}

/// Filter for video messages
pub fn has_video() -> Filter {
  filter("has_video", fn(update) {
    case update {
      update.VideoUpdate(..) -> True
      _ -> False
    }
  })
}

/// Filter for media group messages
pub fn is_media_group() -> Filter {
  filter("is_media_group", fn(update) {
    case update {
      update.MediaGroupUpdate(..) -> True
      _ -> False
    }
  })
}

/// Filter for media (photo, video, audio, voice)
pub fn has_media() -> Filter {
  filter("has_media", fn(update) {
    case update {
      update.PhotoUpdate(..)
      | update.VideoUpdate(..)
      | update.AudioUpdate(..)
      | update.VoiceUpdate(..) -> True
      _ -> False
    }
  })
}

/// Filter for callback queries
pub fn is_callback_query() -> Filter {
  filter("is_callback_query", fn(update) {
    case update {
      update.CallbackQueryUpdate(..) -> True
      _ -> False
    }
  })
}

/// Filter for callback data that starts with prefix
pub fn callback_data_starts_with(prefix: String) -> Filter {
  filter("callback_data_starts_with:" <> prefix, fn(update) {
    case update {
      update.CallbackQueryUpdate(query:, ..) ->
        case query.data {
          Some(data) -> string.starts_with(data, prefix)
          None -> False
        }
      _ -> False
    }
  })
}

/// Evaluate a composable `Filter` against an update.
///
/// This is the bridge that lets the filter combinators (`and`/`or`/`not`,
/// `is_text`, `has_photo`, …) be reused outside the router — most notably to
/// drive `telega.wait_filtered` / `telega.wait_for` in conversations:
///
/// ```gleam
/// use ctx, upd <- telega.wait_for(
///   ctx,
///   filter: router.matches(router.or2(router.is_text(), router.has_photo()), _),
///   or: None,
///   timeout: None,
/// )
/// ```
pub fn matches(filter: Filter, update: Update) -> Bool {
  evaluate_filter(filter, update)
}

/// Evaluate a filter against an update
fn evaluate_filter(f: Filter, update: Update) -> Bool {
  case f {
    Filter(check:, ..) -> check(update)
    And(left, right) ->
      evaluate_filter(left, update) && evaluate_filter(right, update)
    Or(left, right) ->
      evaluate_filter(left, update) || evaluate_filter(right, update)
    Not(filter) -> !evaluate_filter(filter, update)
  }
}

// Content filters ---------------------------------------------------------------------
//
// These read the update's own `Message` through `update.message`, which is
// `None` for updates that are not about a message at all (callback queries,
// inline queries, polls, member changes) — those match none of them.

/// Build a filter over the update's message, `False` when there is none.
fn on_message(name: String, check: fn(Message) -> Bool) -> Filter {
  Filter(name:, check: fn(upd) {
    case update.message(upd) {
      Some(message) -> check(message)
      None -> False
    }
  })
}

/// The message was forwarded from somewhere else.
pub fn is_forwarded() -> Filter {
  use message <- on_message("is_forwarded")
  option.is_some(message.forward_origin)
}

/// The message is a reply to another message.
pub fn is_reply() -> Filter {
  use message <- on_message("is_reply")
  option.is_some(message.reply_to_message)
}

/// The message belongs to the given forum topic / message thread.
pub fn in_topic(thread_id: Int) -> Filter {
  use message <- on_message("in_topic:" <> int.to_string(thread_id))
  message.message_thread_id == Some(thread_id)
}

/// The message carries an entity of the given type — `"url"`, `"mention"`,
/// `"hashtag"`, `"bot_command"`, `"spoiler"`, … Both the text entities and the
/// caption entities are searched, so a captioned photo with a link matches
/// `has_entity("url")` the same way a text message does.
pub fn has_entity(kind: String) -> Filter {
  use message <- on_message("has_entity:" <> kind)
  let entities =
    list.append(
      option.unwrap(message.entities, []),
      option.unwrap(message.caption_entities, []),
    )
  list.any(entities, fn(entity: MessageEntity) { entity.type_ == kind })
}

/// The message was sent through an inline bot.
pub fn via_bot() -> Filter {
  use message <- on_message("via_bot")
  option.is_some(message.via_bot)
}

/// The message was sent through the inline bot with this id.
pub fn via_bot_id(bot_id: Int) -> Filter {
  use message <- on_message("via_bot_id:" <> int.to_string(bot_id))
  case message.via_bot {
    Some(bot) -> bot.id == bot_id
    None -> False
  }
}

/// A channel post automatically forwarded to the linked discussion group.
pub fn is_automatic_forward() -> Filter {
  use message <- on_message("is_automatic_forward")
  message.is_automatic_forward == Some(True)
}

/// The message's media is covered by a spoiler animation.
pub fn has_media_spoiler() -> Filter {
  use message <- on_message("has_media_spoiler")
  message.has_media_spoiler == Some(True)
}

/// Set fallback handler for unmatched updates
pub fn fallback(
  router: Router(session, error, dependencies),
  handler: Handler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  Router(..router, fallback: Some(handler))
}

/// Add middleware to the router. The first middleware added is the outermost
/// one: it runs first and sees the handler's result last.
pub fn use_middleware(
  router: Router(session, error, dependencies),
  middleware: Middleware(session, error, dependencies),
) -> Router(session, error, dependencies) {
  Router(..router, middleware: [middleware, ..router.middleware])
}

/// Add a catch handler to the router that handles errors from all routes
pub fn with_catch_handler(
  router: Router(session, error, dependencies),
  catch_handler: fn(error) ->
    Result(Context(session, error, dependencies), error),
) -> Router(session, error, dependencies) {
  Router(..router, catch_handler: Some(catch_handler))
}

/// Restrict a whole router to updates matching a predicate.
///
/// The predicate is also what `handle` and the tree consult before dispatching,
/// so an out-of-scope update is *declined* rather than swallowed: the next
/// branch of a tree gets its turn instead of the scoped router eating it.
pub fn scope(
  router: Router(session, error, dependencies),
  predicate: fn(Update) -> Bool,
) -> Router(session, error, dependencies) {
  Router(
    ..router,
    scope_predicate: Some(case router.scope_predicate {
      Some(existing) -> fn(update) { existing(update) && predicate(update) }
      None -> predicate
    }),
    name: router.name <> "_scoped",
  )
}

/// Whether this router's scope admits the update.
fn in_scope(
  router: Router(session, error, dependencies),
  update: Update,
) -> Bool {
  case router.scope_predicate {
    Some(predicate) -> predicate(update)
    None -> True
  }
}

/// Process an update through a leaf router.
pub fn handle(
  router: Router(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  update: Update,
) -> Result(Context(session, error, dependencies), error) {
  use <- bool.guard(when: !in_scope(router, update), return: Ok(ctx))

  let handler =
    find_handler(router, update, ctx)
    |> apply_middleware(router.middleware)

  case router.catch_handler {
    Some(catch_fn) ->
      case handler(ctx, update) {
        Ok(result) -> Ok(result)
        Error(err) -> catch_fn(err)
      }
    None -> handler(ctx, update)
  }
}

/// Merge two leaf routers into one. All routes are combined, with the first
/// router's routes taking priority in case of conflicts. Middleware and catch
/// handlers are shared.
pub fn merge(
  first: Router(session, error, dependencies),
  second: Router(session, error, dependencies),
) -> Router(session, error, dependencies) {
  Router(
    commands: merge_keeping_first(second.commands, first.commands),
    command_descriptions: merge_keeping_first(
      second.command_descriptions,
      first.command_descriptions,
    ),
    callbacks: merge_keeping_first(second.callbacks, first.callbacks),
    routes: list.append(first.routes, second.routes),
    fallback: option.or(first.fallback, second.fallback),
    middleware: list.append(first.middleware, second.middleware),
    catch_handler: option.or(first.catch_handler, second.catch_handler),
    scope_predicate: merge_scopes(first.scope_predicate, second.scope_predicate),
    // A merged router answers for both, so it carries both names.
    name: first.name <> "+" <> second.name,
  )
}

/// Merge `incoming` into `base`, keeping `base`'s value on key conflicts.
fn merge_keeping_first(incoming: Dict(k, v), base: Dict(k, v)) -> Dict(k, v) {
  dict.fold(incoming, base, fn(acc, key, value) {
    case dict.has_key(acc, key) {
      True -> acc
      False -> dict.insert(acc, key, value)
    }
  })
}

/// A merged router is in scope when either side is; unscoped stays unscoped.
fn merge_scopes(
  first: Option(fn(Update) -> Bool),
  second: Option(fn(Update) -> Bool),
) -> Option(fn(Update) -> Bool) {
  case first, second {
    None, other | other, None -> other
    Some(first), Some(second) -> Some(fn(u) { first(u) || second(u) })
  }
}

// Composition ------------------------------------------------------------------------

/// An empty tree. Add leaves with `append` and `branch`.
pub fn tree() -> RouterTree(session, error, dependencies) {
  RouterTree(branches: [], fallback: None)
}

/// Add a leaf that is tried for every update, after the branches already added.
pub fn append(
  tree: RouterTree(session, error, dependencies),
  router: Router(session, error, dependencies),
) -> RouterTree(session, error, dependencies) {
  RouterTree(
    ..tree,
    branches: list.append(tree.branches, [Branch(filter: None, router:)]),
  )
}

/// Add a leaf that is only consulted when `when` matches the update.
///
/// ```gleam
/// router.tree()
/// |> router.branch(router.is_private_chat(), private_router)
/// |> router.branch(router.is_group_chat(), group_router)
/// ```
pub fn branch(
  tree: RouterTree(session, error, dependencies),
  when filter: Filter,
  router router: Router(session, error, dependencies),
) -> RouterTree(session, error, dependencies) {
  RouterTree(
    ..tree,
    branches: list.append(tree.branches, [Branch(filter: Some(filter), router:)]),
  )
}

/// A handler for updates no branch claimed.
pub fn tree_fallback(
  tree: RouterTree(session, error, dependencies),
  handler: Handler(session, error, dependencies),
) -> RouterTree(session, error, dependencies) {
  RouterTree(..tree, fallback: Some(handler))
}

/// Push middleware into every branch. Each branch keeps its own copy, applied
/// around its own handlers, so a branch's catch handler still sees its errors.
pub fn use_middleware_on_tree(
  tree: RouterTree(session, error, dependencies),
  middleware: Middleware(session, error, dependencies),
) -> RouterTree(session, error, dependencies) {
  map_branches(tree, use_middleware(_, middleware))
}

/// Give every branch the same catch handler. A branch that already has one
/// keeps it.
pub fn with_catch_handler_on_tree(
  tree: RouterTree(session, error, dependencies),
  catch_handler: fn(error) ->
    Result(Context(session, error, dependencies), error),
) -> RouterTree(session, error, dependencies) {
  use router <- map_branches(tree)
  case router.catch_handler {
    Some(_) -> router
    None -> with_catch_handler(router, catch_handler)
  }
}

fn map_branches(
  tree: RouterTree(session, error, dependencies),
  apply: fn(Router(session, error, dependencies)) ->
    Router(session, error, dependencies),
) -> RouterTree(session, error, dependencies) {
  RouterTree(
    ..tree,
    branches: list.map(tree.branches, fn(b) {
      Branch(..b, router: apply(b.router))
    }),
  )
}

/// Compose two leaf routers into a tree. Both are tried in order.
pub fn compose(
  first: Router(session, error, dependencies),
  second: Router(session, error, dependencies),
) -> RouterTree(session, error, dependencies) {
  tree() |> append(first) |> append(second)
}

/// Compose many leaf routers into a tree, tried in order.
pub fn compose_many(
  routers: List(Router(session, error, dependencies)),
) -> RouterTree(session, error, dependencies) {
  list.fold(routers, tree(), append)
}

/// The tree's name: its branch names joined with `+`.
pub fn tree_name(tree: RouterTree(session, error, dependencies)) -> String {
  case tree.branches {
    [] -> "empty"
    branches ->
      branches
      |> list.map(fn(b) { b.router.name })
      |> string.join("+")
  }
}

/// Process an update through a tree: the first branch whose filter matches and
/// which has a route for the update handles it, otherwise the tree fallback.
pub fn handle_tree(
  tree: RouterTree(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  update: Update,
) -> Result(Context(session, error, dependencies), error) {
  do_handle_tree(tree.branches, tree.fallback, ctx, update)
}

fn do_handle_tree(
  branches: List(Branch(session, error, dependencies)),
  fallback: Option(Handler(session, error, dependencies)),
  ctx: Context(session, error, dependencies),
  update: Update,
) -> Result(Context(session, error, dependencies), error) {
  case branches {
    [] ->
      case fallback {
        Some(handler) -> handler(ctx, update)
        None -> Ok(ctx)
      }
    [Branch(filter:, router:), ..rest] -> {
      let selected = case filter {
        Some(f) -> matches(f, update)
        None -> True
      }
      case selected && can_handle_update(router, update, ctx) {
        True -> handle(router, ctx, update)
        False -> do_handle_tree(rest, fallback, ctx, update)
      }
    }
  }
}

/// Reduce a leaf router to what the bot needs from it.
pub fn routable(
  router: Router(session, error, dependencies),
) -> Routable(session, error, dependencies) {
  Routable(
    name: router.name,
    handle: fn(ctx, upd) { handle(router, ctx, upd) },
    allowed_updates: allowed_updates(router),
    registered_commands: registered_commands(router),
  )
}

/// Reduce a tree to what the bot needs from it.
pub fn tree_routable(
  tree: RouterTree(session, error, dependencies),
) -> Routable(session, error, dependencies) {
  Routable(
    name: tree_name(tree),
    handle: fn(ctx, upd) { handle_tree(tree, ctx, upd) },
    allowed_updates: tree_allowed_updates(tree),
    registered_commands: tree_registered_commands(tree),
  )
}

/// List every command registered with a description, as `#(command, description)`
/// pairs sorted by command name. Commands added with `on_command` (no
/// description) are omitted.
///
/// This is what `telega.with_auto_commands` feeds into `setMyCommands`.
pub fn registered_commands(
  router: Router(session, error, dependencies),
) -> List(#(String, String)) {
  router.command_descriptions
  |> dict.to_list
  |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
}

/// The union of every branch's described commands, sorted by command name.
/// Earlier branches win a duplicate.
pub fn tree_registered_commands(
  tree: RouterTree(session, error, dependencies),
) -> List(#(String, String)) {
  tree.branches
  |> list.fold(dict.new(), fn(acc, b) {
    merge_keeping_first(b.router.command_descriptions, acc)
  })
  |> dict.to_list
  |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
}

/// Derive the set of Telegram update types this router actually handles, as the
/// strings expected by `allowed_updates` (e.g. `"message"`, `"callback_query"`).
/// The result is deduplicated and sorted for stable output.
///
/// If the router has a fallback, custom, filtered, or `on_unknown_update`
/// route, the handled set cannot be determined statically (those routes can
/// match anything), so an empty list is returned to signal "do not restrict" —
/// Telegram then sends its default update set. Use a manual override when you
/// need narrowing alongside catch-all routes.
///
/// A non-empty result always contains `"callback_query"`, even for a router
/// with no callback route. Static derivation only sees the router: a handler
/// that parks on `bot.wait_callback` is invisible to it, and narrowing the set
/// without `callback_query` would leave that conversation waiting forever.
/// Allowing it costs nothing when unused — Telegram only sends callback queries
/// for keyboards the bot itself put on screen.
pub fn allowed_updates(
  router: Router(session, error, dependencies),
) -> List(String) {
  use <- bool.guard(when: narrowing_gives_up(router), return: [])

  let from_commands = case dict.is_empty(router.commands) {
    True -> []
    False -> ["message"]
  }
  let from_callbacks = case dict.is_empty(router.callbacks) {
    True -> []
    False -> ["callback_query"]
  }
  let from_routes = list.filter_map(router.routes, route_update_type)

  case from_commands, from_callbacks, from_routes {
    // Nothing is registered at all, so there is nothing to derive. Not the
    // same statement as "do not restrict" — see `tree_allowed_updates`.
    [], [], [] -> []
    _, _, _ ->
      ["callback_query", ..list.flatten([from_commands, from_routes])]
      |> list.unique
      |> list.sort(string.compare)
  }
}

/// Whether this router can match update kinds no static analysis can
/// enumerate, and so cannot be narrowed at all.
fn narrowing_gives_up(router: Router(session, error, dependencies)) -> Bool {
  option.is_some(router.fallback) || list.any(router.routes, is_wildcard_route)
}

/// The union of every branch's derived set. One branch that gives up on
/// narrowing gives up for the whole tree — as does a tree fallback.
pub fn tree_allowed_updates(
  tree: RouterTree(session, error, dependencies),
) -> List(String) {
  use <- bool.guard(when: option.is_some(tree.fallback), return: [])
  // A branch is asked whether it *gives up* on narrowing, not whether its
  // derived set is empty: a branch with nothing registered contributes
  // nothing, it does not force the whole tree to stop narrowing.
  use <- bool.guard(
    when: list.any(tree.branches, fn(b) { narrowing_gives_up(b.router) }),
    return: [],
  )

  tree.branches
  |> list.flat_map(fn(b) { allowed_updates(b.router) })
  |> list.unique
  |> list.sort(string.compare)
}

/// A route that can match update kinds no static analysis can enumerate.
fn is_wildcard_route(route: Route(session, error, dependencies)) -> Bool {
  case route {
    CustomRoute(..) | FilteredRoute(..) | UnknownUpdateRoute(..) -> True
    _ -> False
  }
}

/// Map a concrete route to the Telegram `allowed_updates` string it consumes.
/// Wildcard routes have no such string and are filtered out before this runs.
fn route_update_type(
  route: Route(session, error, dependencies),
) -> Result(String, Nil) {
  case route {
    TextPatternRoute(..)
    | PhotoRoute(..)
    | VideoRoute(..)
    | VoiceRoute(..)
    | AudioRoute(..)
    | MediaGroupRoute(..)
    | WebAppDataRoute(..) -> Ok("message")
    EditedMessageRoute(..) -> Ok("edited_message")
    ChannelPostRoute(..) -> Ok("channel_post")
    EditedChannelPostRoute(..) -> Ok("edited_channel_post")
    BusinessMessageRoute(..) -> Ok("business_message")
    InlineQueryRoute(..) -> Ok("inline_query")
    ChosenInlineResultRoute(..) -> Ok("chosen_inline_result")
    ShippingQueryRoute(..) -> Ok("shipping_query")
    PreCheckoutQueryRoute(..) -> Ok("pre_checkout_query")
    PaidMediaPurchaseRoute(..) -> Ok("purchased_paid_media")
    PollRoute(..) -> Ok("poll")
    PollAnswerRoute(..) -> Ok("poll_answer")
    MessageReactionRoute(..)
    | MessageReactionEmojiRoute(..)
    | MessageReactionPaidRoute(..)
    | MessageReactionAddedRoute(..)
    | MessageReactionRemovedRoute(..) -> Ok("message_reaction")
    MessageReactionCountRoute(..) -> Ok("message_reaction_count")
    ChatMemberUpdatedRoute(..) -> Ok("chat_member")
    MyChatMemberUpdatedRoute(..) -> Ok("my_chat_member")
    ChatJoinRequestRoute(..) -> Ok("chat_join_request")
    ChatBoostRoute(..) -> Ok("chat_boost")
    RemovedChatBoostRoute(..) -> Ok("removed_chat_boost")
    CustomRoute(..) | FilteredRoute(..) | UnknownUpdateRoute(..) -> Error(Nil)
  }
}

/// Whether a router has anything to say about an update.
///
/// Answered with the very matchers dispatch uses — `route_matches` for routes,
/// the command and callback lookups for the two dictionaries — so a branch can
/// never claim an update it would then decline to handle, or decline one it
/// has a route for.
fn can_handle_update(
  router: Router(session, error, dependencies),
  update: Update,
  context: Context(session, error, dependencies),
) -> Bool {
  use <- bool.guard(when: !in_scope(router, update), return: False)

  let keyed = case update {
    // Normalized exactly like `find_command_handler` does, or `/help@bot`
    // in a group would be claimed here and dropped there.
    update.CommandUpdate(command: cmd, ..) ->
      dict.has_key(
        router.commands,
        command_lookup_key(context.bot_info.username, cmd.command),
      )
    update.CallbackQueryUpdate(query:, ..) ->
      case query.data {
        Some(data) ->
          option.is_some(find_callback_by_data(router.callbacks, data))
        None -> False
      }
    _ -> False
  }

  keyed
  || list.any(router.routes, route_matches(_, update))
  || option.is_some(router.fallback)
}

/// Find the appropriate handler for an update
fn find_handler(
  router: Router(session, error, dependencies),
  update: Update,
  context: Context(session, error, dependencies),
) -> Handler(session, error, dependencies) {
  case update {
    update.CommandUpdate(..) ->
      find_command_handler(router, update, context)
      |> option.unwrap(find_route_or_fallback(router, update))

    update.CallbackQueryUpdate(..) ->
      find_callback_handler(router, update)
      |> option.unwrap(find_route_or_fallback(router, update))

    _ -> find_route_or_fallback(router, update)
  }
}

/// The key a command update is looked up under.
///
/// `/help@yourbot` in a group addresses this bot, so the `@suffix` is dropped
/// when it names us. Both the lookup and `can_handle_update` go through here —
/// a second copy is how the two drifted apart.
/// The key a received command is looked up by: `@botname` stripped when it
/// addresses this bot, then normalized the same way registration normalizes.
/// Telegram usernames are case-insensitive too, so the suffix is compared in
/// lower case.
fn command_lookup_key(bot_username: Option(String), command: String) -> String {
  case bot_username, string.split_once(command, "@") {
    Some(username), Ok(#(command_text, suffix)) ->
      case
        username != "" && string.lowercase(username) == string.lowercase(suffix)
      {
        True -> normalize_command(command_text)
        False -> normalize_command(command)
      }
    _, _ -> normalize_command(command)
  }
}

/// Find a command handler
fn find_command_handler(
  router: Router(session, error, dependencies),
  update: Update,
  context: Context(session, error, dependencies),
) -> Option(Handler(session, error, dependencies)) {
  case router, update {
    Router(commands:, ..), update.CommandUpdate(command:, ..) ->
      dict.get(
        commands,
        command_lookup_key(context.bot_info.username, command.command),
      )
      |> option.from_result
    _, _ -> None
  }
}

/// Find a callback handler
fn find_callback_handler(
  router: Router(session, error, dependencies),
  update: Update,
) -> Option(Handler(session, error, dependencies)) {
  case router, update {
    Router(callbacks:, ..), update.CallbackQueryUpdate(query:, ..) ->
      case query.data {
        Some(data) -> find_callback_by_data(callbacks, data)
        None -> None
      }
    _, _ -> None
  }
}

/// Find callback handler by data string
fn find_callback_by_data(
  callbacks: Dict(String, Handler(session, error, dependencies)),
  data: String,
) -> Option(Handler(session, error, dependencies)) {
  // Try exact match first
  case dict.get(callbacks, callback_key(Exact(data))) {
    Ok(handler) -> Some(handler)
    Error(_) -> find_callback_by_pattern(callbacks, data)
  }
}

/// Find callback handler by pattern matching. The MOST SPECIFIC matching
/// pattern wins, not whichever one the callback map happens to yield first:
/// routes live in a `Dict`, and its iteration order is sorted for a small
/// Erlang map but hash-derived past 32 keys — so "first match" is not a
/// property a bot can rely on. Specificity is the length of the pattern's
/// payload, which makes the catch-all `Prefix("")` a flow registry installs
/// for auto-resume (`flow/registry.apply_to_router`) the LAST resort it is
/// meant to be, behind every route the bot registered itself. Equal-length
/// patterns are broken by key order so the choice stays deterministic.
fn find_callback_by_pattern(
  callbacks: Dict(String, Handler(session, error, dependencies)),
  data: String,
) -> Option(Handler(session, error, dependencies)) {
  dict.to_list(callbacks)
  |> list.filter(fn(entry) {
    let #(key, _) = entry
    matches_callback_pattern(key, data)
  })
  |> list.sort(fn(a, b) {
    let #(key_a, _) = a
    let #(key_b, _) = b
    case int.compare(pattern_specificity(key_b), pattern_specificity(key_a)) {
      order.Eq -> string.compare(key_a, key_b)
      ordering -> ordering
    }
  })
  |> list.first
  |> result.map(fn(entry) {
    let #(_, handler) = entry
    handler
  })
  |> option.from_result
}

/// How specific a callback pattern key is: the length of its payload, so
/// `Prefix("raid_pick:")` outranks `Prefix("")`. A key with no recognised tag
/// cannot match anything, so its rank never gets consulted.
fn pattern_specificity(key: String) -> Int {
  case string.split_once(key, ":") {
    Ok(#("prefix", payload))
    | Ok(#("contains", payload))
    | Ok(#("suffix", payload)) -> string.length(payload)
    _ -> 0
  }
}

/// The `Dict` key a callback pattern is stored under. Every kind carries its
/// own tag, `Exact` included: stored under its raw payload instead, an exact
/// route whose payload happens to look like a tagged pattern would collide
/// with the real thing — `Exact("prefix:foo")` and `Prefix("foo")` shared a
/// key, one silently overwrote the other, and the survivor then answered
/// payloads it was never registered for. With a tag of its own the two
/// namespaces cannot meet, and a payload that repeats a tag
/// (`Exact("exact:foo")`) is still distinct from the route it imitates.
fn callback_key(pattern: Pattern) -> String {
  case pattern {
    Exact(value) -> "exact:" <> value
    Prefix(value) -> "prefix:" <> value
    Contains(value) -> "contains:" <> value
    Suffix(value) -> "suffix:" <> value
  }
}

/// Check if a callback pattern key matches the data. The pattern payload
/// may itself contain ":" (e.g. `Prefix("travel_to:")`), so split only on
/// the first delimiter. An `exact:` key never matches here — it is resolved
/// by the direct lookup in `find_callback_by_data` before patterns are tried.
fn matches_callback_pattern(key: String, data: String) -> Bool {
  case string.split_once(key, ":") {
    Ok(#("prefix", prefix)) -> string.starts_with(data, prefix)
    Ok(#("contains", substr)) -> string.contains(data, substr)
    Ok(#("suffix", suffix)) -> string.ends_with(data, suffix)
    _ -> False
  }
}

/// Try routes, then fallback
fn find_route_or_fallback(
  router: Router(session, error, dependencies),
  update: Update,
) -> Handler(session, error, dependencies) {
  case find_matching_route(router.routes, update) {
    Some(handler) -> handler
    None ->
      case router.fallback {
        Some(handler) -> handler
        None -> fn(ctx, _) { Ok(ctx) }
      }
  }
}

/// Find matching route for an update
fn find_matching_route(
  routes: List(Route(session, error, dependencies)),
  update: Update,
) -> Option(Handler(session, error, dependencies)) {
  case list.filter(routes, route_matches(_, update)) {
    [] -> None
    [first, ..rest] -> Some(handler_for_route(pick_route(first, rest), update))
  }
}

/// Which of the matching routes actually runs. Routes are PREPENDED, so the
/// list runs newest-first and the first match wins — with one exception: among
/// matching text PATTERNS the most specific one wins, so the `on_any_text`
/// catch-all a flow registry installs for auto-resume
/// (`flow/registry.apply_to_router`) cannot shadow the `on_text` routes a bot
/// registered before it. Every other route kind keeps its position, so a
/// filtered or custom route still outranks a text pattern the way it always
/// did.
fn pick_route(
  first: Route(session, error, dependencies),
  rest: List(Route(session, error, dependencies)),
) -> Route(session, error, dependencies) {
  case first {
    TextPatternRoute(..) ->
      list.fold(rest, first, fn(best, candidate) {
        case best, candidate {
          TextPatternRoute(pattern: chosen, ..),
            TextPatternRoute(pattern: offered, ..)
          ->
            case
              text_pattern_specificity(offered)
              > text_pattern_specificity(chosen)
            {
              True -> candidate
              False -> best
            }
          _, _ -> best
        }
      })
    _ -> first
  }
}

/// How specific a text pattern is — the same rule `pattern_specificity` applies
/// to encoded callback keys: the length of the payload it constrains, with an
/// exact match stricter than a prefix of equal length. `Prefix("")` scores 0,
/// which is what makes it a last resort.
fn text_pattern_specificity(pattern: Pattern) -> Int {
  case pattern {
    Exact(value) -> string.length(value) + 1
    Prefix(value) | Contains(value) | Suffix(value) -> string.length(value)
  }
}

fn handler_for_route(
  route: Route(session, error, dependencies),
  update: Update,
) -> Handler(session, error, dependencies) {
  case route, update {
    TextPatternRoute(handler:, ..), update.TextUpdate(text:, ..) -> fn(ctx, _) {
      handler(ctx, text)
    }
    PhotoRoute(handler:), update.PhotoUpdate(photos:, ..) -> fn(ctx, _) {
      handler(ctx, photos)
    }
    VideoRoute(handler:), update.VideoUpdate(video:, ..) -> fn(ctx, _) {
      handler(ctx, video)
    }
    VoiceRoute(handler:), update.VoiceUpdate(voice:, ..) -> fn(ctx, _) {
      handler(ctx, voice)
    }
    AudioRoute(handler:), update.AudioUpdate(audio:, ..) -> fn(ctx, _) {
      handler(ctx, audio)
    }
    MediaGroupRoute(handler:),
      update.MediaGroupUpdate(media_group_id:, messages:, ..)
    -> fn(ctx, _) { handler(ctx, media_group_id, messages) }
    WebAppDataRoute(handler:), update.WebAppUpdate(web_app_data:, ..) -> fn(
      ctx,
      _,
    ) {
      handler(ctx, web_app_data)
    }
    EditedMessageRoute(handler:), update.EditedMessageUpdate(message:, ..) -> fn(
      ctx,
      _,
    ) {
      handler(ctx, message)
    }
    ChannelPostRoute(handler:), update.ChannelPostUpdate(post:, ..) -> fn(
      ctx,
      _,
    ) {
      handler(ctx, post)
    }
    EditedChannelPostRoute(handler:), update.EditedChannelPostUpdate(post:, ..)
    -> fn(ctx, _) { handler(ctx, post) }
    BusinessMessageRoute(handler:), update.BusinessMessageUpdate(message:, ..)
    -> fn(ctx, _) { handler(ctx, message) }
    InlineQueryRoute(handler:), update.InlineQueryUpdate(inline_query:, ..) -> fn(
      ctx,
      _,
    ) {
      handler(ctx, inline_query)
    }
    ChosenInlineResultRoute(handler:),
      update.ChosenInlineResultUpdate(chosen_inline_result:, ..)
    -> fn(ctx, _) { handler(ctx, chosen_inline_result) }
    ShippingQueryRoute(handler:),
      update.ShippingQueryUpdate(shipping_query:, ..)
    -> fn(ctx, _) { handler(ctx, shipping_query) }
    PreCheckoutQueryRoute(handler:),
      update.PreCheckoutQueryUpdate(pre_checkout_query:, ..)
    -> fn(ctx, _) { handler(ctx, pre_checkout_query) }
    PaidMediaPurchaseRoute(handler:),
      update.PaidMediaPurchaseUpdate(paid_media_purchased:, ..)
    -> fn(ctx, _) { handler(ctx, paid_media_purchased) }
    PollRoute(handler:), update.PollUpdate(poll:, ..) -> fn(ctx, _) {
      handler(ctx, poll)
    }
    PollAnswerRoute(handler:), update.PollAnswerUpdate(poll_answer:, ..) -> fn(
      ctx,
      _,
    ) {
      handler(ctx, poll_answer)
    }
    MessageReactionRoute(handler:),
      update.MessageReactionUpdate(message_reaction_updated:, ..)
    -> fn(ctx, _) { handler(ctx, message_reaction_updated) }
    MessageReactionEmojiRoute(handler:, ..),
      update.MessageReactionUpdate(message_reaction_updated:, ..)
    -> fn(ctx, _) { handler(ctx, message_reaction_updated) }
    MessageReactionPaidRoute(handler:),
      update.MessageReactionUpdate(message_reaction_updated:, ..)
    -> fn(ctx, _) { handler(ctx, message_reaction_updated) }
    MessageReactionAddedRoute(handler:),
      update.MessageReactionUpdate(message_reaction_updated:, ..)
    -> fn(ctx, _) { handler(ctx, message_reaction_updated) }
    MessageReactionRemovedRoute(handler:),
      update.MessageReactionUpdate(message_reaction_updated:, ..)
    -> fn(ctx, _) { handler(ctx, message_reaction_updated) }
    MessageReactionCountRoute(handler:),
      update.MessageReactionCountUpdate(message_reaction_count_updated:, ..)
    -> fn(ctx, _) { handler(ctx, message_reaction_count_updated) }
    ChatMemberUpdatedRoute(handler:),
      update.ChatMemberUpdate(chat_member_updated:, ..)
    -> fn(ctx, _) { handler(ctx, chat_member_updated) }
    MyChatMemberUpdatedRoute(handler:),
      update.MyChatMemberUpdate(chat_member_updated:, ..)
    -> fn(ctx, _) { handler(ctx, chat_member_updated) }
    ChatJoinRequestRoute(handler:),
      update.ChatJoinRequestUpdate(chat_join_request:, ..)
    -> fn(ctx, _) { handler(ctx, chat_join_request) }
    ChatBoostRoute(handler:), update.ChatBoostUpdate(chat_boost:, ..) -> fn(
      ctx,
      _,
    ) {
      handler(ctx, chat_boost)
    }
    RemovedChatBoostRoute(handler:),
      update.RemovedChatBoost(removed_chat_boost:, ..)
    -> fn(ctx, _) { handler(ctx, removed_chat_boost) }
    UnknownUpdateRoute(handler:), _ -> handler
    CustomRoute(handler:, ..), _ -> handler
    FilteredRoute(handler:, ..), _ -> handler
    _, _ -> fn(ctx, _) { Ok(ctx) }
  }
}

/// Check if a route matches an update
fn route_matches(
  route: Route(session, error, dependencies),
  update: Update,
) -> Bool {
  case route, update {
    TextPatternRoute(pattern:, ..), update.TextUpdate(text:, ..) ->
      matches_pattern(pattern, text)
    PhotoRoute(..), update.PhotoUpdate(..) -> True
    VideoRoute(..), update.VideoUpdate(..) -> True
    VoiceRoute(..), update.VoiceUpdate(..) -> True
    AudioRoute(..), update.AudioUpdate(..) -> True
    MediaGroupRoute(..), update.MediaGroupUpdate(..) -> True
    WebAppDataRoute(..), update.WebAppUpdate(..) -> True
    EditedMessageRoute(..), update.EditedMessageUpdate(..) -> True
    ChannelPostRoute(..), update.ChannelPostUpdate(..) -> True
    EditedChannelPostRoute(..), update.EditedChannelPostUpdate(..) -> True
    BusinessMessageRoute(..), update.BusinessMessageUpdate(..) -> True
    InlineQueryRoute(..), update.InlineQueryUpdate(..) -> True
    ChosenInlineResultRoute(..), update.ChosenInlineResultUpdate(..) -> True
    ShippingQueryRoute(..), update.ShippingQueryUpdate(..) -> True
    PreCheckoutQueryRoute(..), update.PreCheckoutQueryUpdate(..) -> True
    PaidMediaPurchaseRoute(..), update.PaidMediaPurchaseUpdate(..) -> True
    PollRoute(..), update.PollUpdate(..) -> True
    PollAnswerRoute(..), update.PollAnswerUpdate(..) -> True
    MessageReactionRoute(..), update.MessageReactionUpdate(..) -> True
    MessageReactionEmojiRoute(emojis:, ..),
      update.MessageReactionUpdate(message_reaction_updated:, ..)
    -> matches_reaction_emojis(message_reaction_updated.new_reaction, emojis)
    MessageReactionPaidRoute(..),
      update.MessageReactionUpdate(message_reaction_updated:, ..)
    -> has_paid_reaction(message_reaction_updated.new_reaction)
    MessageReactionAddedRoute(..),
      update.MessageReactionUpdate(message_reaction_updated:, ..)
    -> has_added_reactions(message_reaction_updated)
    MessageReactionRemovedRoute(..),
      update.MessageReactionUpdate(message_reaction_updated:, ..)
    -> has_removed_reactions(message_reaction_updated)
    MessageReactionCountRoute(..), update.MessageReactionCountUpdate(..) -> True
    ChatMemberUpdatedRoute(..), update.ChatMemberUpdate(..) -> True
    MyChatMemberUpdatedRoute(..), update.MyChatMemberUpdate(..) -> True
    ChatJoinRequestRoute(..), update.ChatJoinRequestUpdate(..) -> True
    ChatBoostRoute(..), update.ChatBoostUpdate(..) -> True
    RemovedChatBoostRoute(..), update.RemovedChatBoost(..) -> True
    UnknownUpdateRoute(..), update.UnknownUpdate(..) -> True
    CustomRoute(matcher:, ..), _ -> matcher(update)
    FilteredRoute(filter:, ..), _ -> evaluate_filter(filter, update)
    _, _ -> False
  }
}

/// Check if text matches pattern
fn matches_pattern(pattern: Pattern, text: String) -> Bool {
  case pattern {
    Exact(p) -> text == p
    Prefix(p) -> string.starts_with(text, p)
    Contains(p) -> string.contains(text, p)
    Suffix(p) -> string.ends_with(text, p)
  }
}

/// Check if any reaction matches the specified emojis
fn matches_reaction_emojis(
  reactions: List(ReactionType),
  emojis: List(String),
) -> Bool {
  list.any(reactions, fn(reaction) {
    case reaction {
      ReactionTypeEmojiReactionType(inner) -> list.contains(emojis, inner.emoji)
      _ -> False
    }
  })
}

/// Check if any reaction is a paid reaction
fn has_paid_reaction(reactions: List(ReactionType)) -> Bool {
  list.any(reactions, fn(reaction) {
    case reaction {
      ReactionTypePaidReactionType(_) -> True
      _ -> False
    }
  })
}

/// Check if there are added reactions (new_reaction has items not in old_reaction)
fn has_added_reactions(update: MessageReactionUpdated) -> Bool {
  list.any(update.new_reaction, fn(new_r) {
    !list.any(update.old_reaction, fn(old_r) {
      reaction_type_equals(new_r, old_r)
    })
  })
}

/// Check if there are removed reactions (old_reaction has items not in new_reaction)
fn has_removed_reactions(update: MessageReactionUpdated) -> Bool {
  list.any(update.old_reaction, fn(old_r) {
    !list.any(update.new_reaction, fn(new_r) {
      reaction_type_equals(old_r, new_r)
    })
  })
}

/// Check if two reaction types are equal
fn reaction_type_equals(a: ReactionType, b: ReactionType) -> Bool {
  case a, b {
    ReactionTypeEmojiReactionType(a_inner),
      ReactionTypeEmojiReactionType(b_inner)
    -> a_inner.emoji == b_inner.emoji
    types.ReactionTypeCustomEmojiReactionType(a_inner),
      types.ReactionTypeCustomEmojiReactionType(b_inner)
    -> a_inner.custom_emoji_id == b_inner.custom_emoji_id
    ReactionTypePaidReactionType(_), ReactionTypePaidReactionType(_) -> True
    _, _ -> False
  }
}

/// Apply middleware to a handler
fn apply_middleware(
  handler: Handler(session, error, dependencies),
  middleware: List(Middleware(session, error, dependencies)),
) -> Handler(session, error, dependencies) {
  list.fold(middleware, handler, fn(h, mw) { mw(h) })
}

/// Logging middleware - logs update processing
pub fn with_logging(
  handler: Handler(session, error, dependencies),
) -> Handler(session, error, dependencies) {
  fn(ctx, update_param) {
    let update_type = update.to_string(update_param)
    log.info("Processing " <> update_type)

    case handler(ctx, update_param) {
      Ok(result) -> {
        log.info("Processed " <> update_type)
        Ok(result)
      }
      Error(err) -> {
        log.error(
          "Failed to process " <> update_type <> ": " <> string.inspect(err),
        )
        Error(err)
      }
    }
  }
}

/// Filter middleware - only process updates that match predicate
pub fn with_filter(
  predicate: fn(Update) -> Bool,
  handler: Handler(session, error, dependencies),
) -> Handler(session, error, dependencies) {
  fn(ctx, update) {
    case predicate(update) {
      True -> handler(ctx, update)
      False -> Ok(ctx)
    }
  }
}

/// Error recovery middleware
pub fn with_recovery(
  recover: fn(error) -> Result(Context(session, error, dependencies), error),
  handler: Handler(session, error, dependencies),
) -> Handler(session, error, dependencies) {
  fn(ctx, update) {
    case handler(ctx, update) {
      Ok(result) -> Ok(result)
      Error(err) -> recover(err)
    }
  }
}

/// Per-user flood control middleware: allows at most `limit` updates per
/// `window_ms` window for each `{chat_id}:{from_id}` pair. Counters live in
/// ETS, so the limit is shared across all routes of the bot.
///
/// `on_limit` is called instead of the handler when the limit is exceeded —
/// pass `fn(ctx) { Ok(ctx) }` to drop the update silently, or reply from it
/// to inform the user. Every rejected update emits a
/// `telega.rate_limit.hit` telemetry event.
///
/// Updates without user context (e.g. poll updates, `from_id` is `-1`) are
/// not limited.
///
/// ```gleam
/// router.new("bot")
/// |> router.use_middleware(router.with_rate_limit(
///   limit: 5,
///   window_ms: 3000,
///   on_limit: fn(ctx) { Ok(ctx) },
/// ))
/// ```
///
/// Call `with_rate_limit` once at bot setup: the limiter's ETS table is owned
/// by the calling process and is deleted when that process exits.
pub fn with_rate_limit(
  limit limit: Int,
  window_ms window_ms: Int,
  on_limit on_limit: fn(Context(session, error, dependencies)) ->
    Result(Context(session, error, dependencies), error),
) -> Middleware(session, error, dependencies) {
  let limiter = rate_limiter.new(limit:, window_ms:)

  fn(handler) {
    fn(ctx: Context(session, error, dependencies), update_param: Update) {
      use <- bool.lazy_guard(when: update_param.from_id < 0, return: fn() {
        handler(ctx, update_param)
      })

      let key =
        int.to_string(update_param.chat_id)
        <> ":"
        <> int.to_string(update_param.from_id)
      case rate_limiter.hit(limiter, key) {
        True -> handler(ctx, update_param)
        False -> {
          telemetry.execute(["telega", "rate_limit", "hit"], [#("count", 1)], [
            #("chat_id", telemetry.IntValue(update_param.chat_id)),
            #("from_id", telemetry.IntValue(update_param.from_id)),
            #(
              "update_type",
              telemetry.StringValue(update.to_string(update_param)),
            ),
          ])
          on_limit(ctx)
        }
      }
    }
  }
}
