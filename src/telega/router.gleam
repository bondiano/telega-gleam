//// # Telega Router
////
//// The router module provides a flexible and composable routing system for Telegram bot updates.
//// It allows you to define handlers for different types of messages and organize them into
//// logical groups with middleware support, error handling, and composition capabilities.
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
//// ## Middleware System
////
//// Middleware allows you to wrap handlers with additional functionality.
//// Middleware is applied in reverse order of addition (last added runs first):
////
//// ```gleam
//// router
//// |> router.use_middleware(router.with_logging)
//// |> router.use_middleware(auth_middleware)
//// |> router.use_middleware(rate_limit_middleware)
//// ```
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
//// ## Router Composition
////
//// Routers can be composed to build complex routing structures:
////
//// ### Merging Routers
////
//// `merge` combines two routers into one, with all routes unified.
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
//// ### Composing Routers
////
//// `compose` creates a router that tries each sub-router in sequence.
//// Each router maintains its own middleware and error handling:
////
//// ```gleam
//// let public_router =
////   router.new("public")
////   |> router.use_middleware(rate_limiting)
////   |> router.on_command("start", handle_start)
////
//// let private_router =
////   router.new("private")
////   |> router.use_middleware(auth_required)
////   |> router.on_command("admin", handle_admin)
////
//// let app = router.compose(private_router, public_router)
//// ```
////
//// ### Scoped Routing
////
//// `scope` creates a sub-router that only processes updates matching a predicate:
////
//// ```gleam
//// let admin_router =
////   router.new("admin")
////   |> router.on_command("ban", handle_ban)
////   |> router.scope(fn(update) {
////     // Only process updates from admin users
////     case update {
////       update.CommandUpdate(from_id: id, ..) -> is_admin(id)
////       _ -> False
////     }
////   })
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
////
//// // OR logic for multiple conditions
//// router
//// |> router.on_filtered(
////   router.or([
////     router.text_equals("help"),
////     router.text_equals("?"),
////     router.command_equals("help")
////   ]),
////   show_help
//// )
//// ```
////
//// ### Available Filters
////
//// **Message Type Filters:**
//// - `is_text()` - Text messages
//// - `is_command()` - Command messages
//// - `has_photo()` - Photo messages
//// - `has_video()` - Video messages
//// - `has_media()` - Any media (photo, video, audio, voice)
//// - `is_media_group()` - Media group/album messages
//// - `is_callback_query()` - Callback button presses
////
//// **Text Content Filters:**
//// - `text_equals(text)` - Exact text match
//// - `text_starts_with(prefix)` - Text starts with prefix
//// - `text_contains(substring)` - Text contains substring
//// - `command_equals(cmd)` - Specific command
////
//// **User/Chat Filters:**
//// - `from_user(user_id)` - From specific user
//// - `from_users(user_ids)` - From any of the users
//// - `in_chat(chat_id)` - In specific chat
//// - `is_private_chat()` - Private messages only
//// - `is_group_chat()` - Group/supergroup messages only
////
//// **Callback Query Filters:**
//// - `callback_data_starts_with(prefix)` - Callback data prefix
////
//// **Filter Composition:**
//// - `and(filters)` / `and2(f1, f2)` - All filters must match
//// - `or(filters)` / `or2(f1, f2)` - Any filter must match
//// - `not(filter)` - Negate a filter
//// - `filter(name, check_fn)` - Custom filter function
////
//// ## Advanced Features
////
//// ### Multiple Command Handlers
////
//// Register the same handler for multiple commands:
////
//// ```gleam
//// router
//// |> router.on_commands(["start", "help", "about"], show_info)
//// ```
////
//// ### Media Handling
////
//// Handle different media types with dedicated handlers:
////
//// ```gleam
//// router
//// |> router.on_photo(handle_photo)
//// |> router.on_video(handle_video)
//// |> router.on_voice(handle_voice_message)
//// |> router.on_audio(handle_audio_file)
//// |> router.on_media_group(handle_media_album)
//// ```
////
//// ### Handler Types
////
//// The router provides type-safe handlers for different update types:
//// - `CommandHandler` - Receives parsed command with arguments
//// - `TextHandler` - Receives text string
//// - `CallbackHandler` - Receives callback query ID and data
//// - `PhotoHandler` - Receives list of photo sizes
//// - `VideoHandler` - Receives video object
//// - `VoiceHandler` - Receives voice message
//// - `AudioHandler` - Receives audio file
//// - `MediaGroupHandler` - Receives media group ID and list of messages
//// - `Handler` - Generic handler for any update type
////

import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/bot.{type Context}

import telega/internal/log
import telega/internal/rate_limiter
import telega/model/types.{
  type Audio, type ChatJoinRequest, type ChatMemberUpdated,
  type ChosenInlineResult, type InlineQuery, type Message,
  type MessageReactionCountUpdated, type MessageReactionUpdated, type PhotoSize,
  type Poll, type PollAnswer, type PreCheckoutQuery, type ReactionType,
  type ShippingQuery, type Video, type Voice, ReactionTypeEmojiReactionType,
  ReactionTypePaidReactionType,
}
import telega/telemetry
import telega/update.{type Command, type Update}

/// Router with unified routes and middleware support
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
    name: String,
  )
  ComposedRouter(
    composes: List(Router(session, error, dependencies)),
    name: String,
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
  ChatJoinRequestRoute(
    handler: ChatJoinRequestHandler(session, error, dependencies),
  )
  CustomRoute(
    matcher: fn(Update) -> Bool,
    handler: Handler(session, error, dependencies),
  )
  FilteredRoute(filter: Filter, handler: Handler(session, error, dependencies))
}

/// Create a new router
pub fn new(name: String) -> Router(session, error, dependencies) {
  Router(
    commands: dict.new(),
    command_descriptions: dict.new(),
    callbacks: dict.new(),
    routes: [],
    fallback: None,
    middleware: [],
    catch_handler: None,
    name: name,
  )
}

/// Add a command handler
pub fn on_command(
  router: Router(session, error, dependencies),
  command: String,
  handler: CommandHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(commands:, ..) -> {
      // Remove leading slash if present for consistency
      let command_key = normalize_command(command)
      let wrapped_handler = fn(ctx, upd) {
        case upd {
          update.CommandUpdate(command: cmd, ..) -> handler(ctx, cmd)
          _ -> Ok(ctx)
        }
      }
      Router(
        ..router,
        commands: dict.insert(commands, command_key, wrapped_handler),
      )
    }
    ComposedRouter(..) as composed -> composed
  }
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
  let command_key = normalize_command(command)
  case on_command(router, command, handler) {
    Router(command_descriptions:, ..) as router ->
      Router(
        ..router,
        command_descriptions: dict.insert(
          command_descriptions,
          command_key,
          description,
        ),
      )
    ComposedRouter(..) as composed -> composed
  }
}

/// Strip a single leading slash so command keys are stored consistently.
fn normalize_command(command: String) -> String {
  case string.starts_with(command, "/") {
    True -> string.drop_start(command, 1)
    False -> command
  }
}

/// Add a text handler with pattern
pub fn on_text(
  router: Router(session, error, dependencies),
  pattern: Pattern,
  handler: TextHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [TextPatternRoute(pattern:, handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
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
  case router {
    Router(callbacks:, ..) -> {
      let key = case pattern {
        Exact(s) -> s
        Prefix(s) -> "prefix:" <> s
        Contains(s) -> "contains:" <> s
        Suffix(s) -> "suffix:" <> s
      }
      // Wrap the typed handler
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
      Router(..router, callbacks: dict.insert(callbacks, key, wrapped_handler))
    }
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handlers for media types
pub fn on_photo(
  router: Router(session, error, dependencies),
  handler: PhotoHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [PhotoRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

pub fn on_video(
  router: Router(session, error, dependencies),
  handler: VideoHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [VideoRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

pub fn on_voice(
  router: Router(session, error, dependencies),
  handler: VoiceHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [VoiceRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

pub fn on_audio(
  router: Router(session, error, dependencies),
  handler: AudioHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [AudioRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for media groups (albums of photos/videos)
pub fn on_media_group(
  router: Router(session, error, dependencies),
  handler: MediaGroupHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [MediaGroupRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for inline queries
pub fn on_inline_query(
  router: Router(session, error, dependencies),
  handler: InlineQueryHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [InlineQueryRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for chosen inline results
pub fn on_chosen_inline_result(
  router: Router(session, error, dependencies),
  handler: ChosenInlineResultHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [ChosenInlineResultRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for shipping queries (payments)
pub fn on_shipping_query(
  router: Router(session, error, dependencies),
  handler: ShippingQueryHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [ShippingQueryRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for pre-checkout queries (payments)
pub fn on_pre_checkout_query(
  router: Router(session, error, dependencies),
  handler: PreCheckoutQueryHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [PreCheckoutQueryRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for poll updates
pub fn on_poll(
  router: Router(session, error, dependencies),
  handler: PollHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [PollRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for poll answer updates
pub fn on_poll_answer(
  router: Router(session, error, dependencies),
  handler: PollAnswerHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [PollAnswerRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for message reactions
pub fn on_reaction(
  router: Router(session, error, dependencies),
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [MessageReactionRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for a specific emoji reaction
///
/// ## Example
/// ```gleam
/// router
/// |> router.on_reaction_emoji("👍", handle_like)
/// ```
pub fn on_reaction_emoji(
  router: Router(session, error, dependencies),
  emoji: String,
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [
        MessageReactionEmojiRoute(emojis: [emoji], handler:),
        ..routes
      ])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for multiple emoji reactions
///
/// ## Example
/// ```gleam
/// router
/// |> router.on_reaction_emojis(["👍", "❤", "🔥"], handle_positive_reactions)
/// ```
pub fn on_reaction_emojis(
  router: Router(session, error, dependencies),
  emojis: List(String),
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [
        MessageReactionEmojiRoute(emojis:, handler:),
        ..routes
      ])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for paid reactions (stars)
///
/// ## Example
/// ```gleam
/// router
/// |> router.on_paid_reaction(handle_star_reaction)
/// ```
pub fn on_paid_reaction(
  router: Router(session, error, dependencies),
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [MessageReactionPaidRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for added reactions only (filters out removed reactions)
///
/// ## Example
/// ```gleam
/// router
/// |> router.on_reaction_added(handle_new_reaction)
/// ```
pub fn on_reaction_added(
  router: Router(session, error, dependencies),
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [MessageReactionAddedRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for removed reactions only (filters out added reactions)
///
/// ## Example
/// ```gleam
/// router
/// |> router.on_reaction_removed(handle_removed_reaction)
/// ```
pub fn on_reaction_removed(
  router: Router(session, error, dependencies),
  handler: MessageReactionHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [MessageReactionRemovedRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for message reaction count updates (anonymous reactions in channels)
///
/// ## Example
/// ```gleam
/// router
/// |> router.on_reaction_count(handle_reaction_counts)
/// ```
pub fn on_reaction_count(
  router: Router(session, error, dependencies),
  handler: MessageReactionCountHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [MessageReactionCountRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for chat member updates
pub fn on_chat_member_updated(
  router: Router(session, error, dependencies),
  handler: ChatMemberUpdatedHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [ChatMemberUpdatedRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for chat join requests
pub fn on_chat_join_request(
  router: Router(session, error, dependencies),
  handler: ChatJoinRequestHandler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [ChatJoinRequestRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add a custom route with matcher function
pub fn on_custom(
  router: Router(session, error, dependencies),
  matcher: fn(Update) -> Bool,
  handler: Handler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [CustomRoute(matcher:, handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add a filtered route
pub fn on_filtered(
  router: Router(session, error, dependencies),
  filter: Filter,
  handler: Handler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [FilteredRoute(filter:, handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
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
    case update {
      update.TextUpdate(from_id:, ..) -> from_id == user_id
      update.CommandUpdate(from_id:, ..) -> from_id == user_id
      update.CallbackQueryUpdate(from_id:, ..) -> from_id == user_id
      update.PhotoUpdate(from_id:, ..) -> from_id == user_id
      update.VideoUpdate(from_id:, ..) -> from_id == user_id
      update.VoiceUpdate(from_id:, ..) -> from_id == user_id
      update.AudioUpdate(from_id:, ..) -> from_id == user_id
      _ -> False
    }
  })
}

/// Filter by multiple user IDs
pub fn from_users(user_ids: List(Int)) -> Filter {
  filter("from_users", fn(update) {
    case update {
      update.TextUpdate(from_id:, ..) -> list.contains(user_ids, from_id)
      update.CommandUpdate(from_id:, ..) -> list.contains(user_ids, from_id)
      update.CallbackQueryUpdate(from_id:, ..) ->
        list.contains(user_ids, from_id)
      update.PhotoUpdate(from_id:, ..) -> list.contains(user_ids, from_id)
      update.VideoUpdate(from_id:, ..) -> list.contains(user_ids, from_id)
      update.VoiceUpdate(from_id:, ..) -> list.contains(user_ids, from_id)
      update.AudioUpdate(from_id:, ..) -> list.contains(user_ids, from_id)
      _ -> False
    }
  })
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

/// Filter for private chats
/// https://core.telegram.org/api/bots%2Fids#user-ids
pub fn is_private_chat() -> Filter {
  filter("is_private_chat", fn(update) { update.chat_id > 0 })
}

/// Filter for group chats
/// https://core.telegram.org/api/bots%2Fids#supergroup-channel-ids
pub fn is_group_chat() -> Filter {
  filter("is_group_chat", fn(update) { update.chat_id < 0 })
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

/// Set fallback handler for unmatched updates
pub fn fallback(
  router: Router(session, error, dependencies),
  handler: Handler(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(..) -> Router(..router, fallback: Some(handler))
    ComposedRouter(..) as composed -> composed
  }
}

/// Add middleware to the router
pub fn use_middleware(
  router: Router(session, error, dependencies),
  middleware: Middleware(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(middleware: existing_middleware, ..) ->
      Router(..router, middleware: [middleware, ..existing_middleware])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add a catch handler to the router that handles errors from all routes
pub fn with_catch_handler(
  router: Router(session, error, dependencies),
  catch_handler: fn(error) ->
    Result(Context(session, error, dependencies), error),
) -> Router(session, error, dependencies) {
  case router {
    Router(..) -> Router(..router, catch_handler: Some(catch_handler))
    ComposedRouter(..) as composed -> composed
  }
}

/// Process an update through the router
pub fn handle(
  router: Router(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  update: Update,
) -> Result(Context(session, error, dependencies), error) {
  case router {
    Router(middleware:, catch_handler:, ..) -> {
      let handler = find_handler(router, update, ctx)

      let wrapped_handler = apply_middleware(handler, middleware)

      case catch_handler {
        Some(catch_fn) -> {
          case wrapped_handler(ctx, update) {
            Ok(result) -> Ok(result)
            Error(err) -> catch_fn(err)
          }
        }
        None -> wrapped_handler(ctx, update)
      }
    }
    ComposedRouter(composes:, ..) -> handle_composed(composes, ctx, update)
  }
}

/// Handle update through a list of composed routers
fn handle_composed(
  routers: List(Router(session, error, dependencies)),
  ctx: Context(session, error, dependencies),
  update: Update,
) -> Result(Context(session, error, dependencies), error) {
  case routers {
    [] -> Ok(ctx)
    // No router handled it
    [router, ..rest] -> {
      case can_handle_update(router, update) {
        True -> handle(router, ctx, update)
        False -> handle_composed(rest, ctx, update)
      }
    }
  }
}

/// Merge two routers into one. All routes are combined, with first router's routes
/// taking priority in case of conflicts. Middleware and catch handlers are shared.
pub fn merge(
  first: Router(session, error, dependencies),
  second: Router(session, error, dependencies),
) -> Router(session, error, dependencies) {
  // Convert both routers to flat representation for merging
  let first_flat = to_flat_router(first)
  let second_flat = to_flat_router(second)

  let assert Router(
    commands: first_commands,
    command_descriptions: first_descriptions,
    callbacks: first_callbacks,
    routes: first_routes,
    fallback: first_fallback,
    middleware: first_middleware,
    catch_handler: first_catch_handler,
    name: first_name,
  ) = first_flat

  let assert Router(
    commands: second_commands,
    command_descriptions: second_descriptions,
    callbacks: second_callbacks,
    routes: second_routes,
    fallback: second_fallback,
    middleware: second_middleware,
    catch_handler: second_catch_handler,
    name: second_name,
  ) = second_flat

  let merged_commands = merge_keeping_first(second_commands, first_commands)
  let merged_descriptions =
    merge_keeping_first(second_descriptions, first_descriptions)
  let merged_callbacks = merge_keeping_first(second_callbacks, first_callbacks)

  Router(
    commands: merged_commands,
    command_descriptions: merged_descriptions,
    callbacks: merged_callbacks,
    routes: list.append(first_routes, second_routes),
    fallback: option.or(first_fallback, second_fallback),
    middleware: list.append(first_middleware, second_middleware),
    catch_handler: option.or(first_catch_handler, second_catch_handler),
    name: first_name <> "+" <> second_name,
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

/// Compose two routers, where each router maintains its own middleware and catch handlers.
/// First router is tried first, if it doesn't handle the update, second router is tried.
pub fn compose(
  first: Router(session, error, dependencies),
  second: Router(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case first, second {
    ComposedRouter(composes: first_list, ..),
      ComposedRouter(composes: second_list, ..)
    ->
      ComposedRouter(
        composes: list.append(first_list, second_list),
        name: get_router_name(first) <> "+" <> get_router_name(second),
      )
    ComposedRouter(composes: routers, ..), Router(..) as second ->
      ComposedRouter(
        composes: list.append(routers, [second]),
        name: get_router_name(first) <> "+" <> get_router_name(second),
      )
    Router(..) as first, ComposedRouter(composes: routers, ..) ->
      ComposedRouter(
        composes: [first, ..routers],
        name: get_router_name(first) <> "+" <> get_router_name(second),
      )
    Router(..) as first, Router(..) as second ->
      ComposedRouter(
        composes: [first, second],
        name: get_router_name(first) <> "+" <> get_router_name(second),
      )
  }
}

/// Compose multiple routers into one. Routers are tried in order.
/// Each router maintains its own middleware and catch handlers.
pub fn compose_many(
  routers: List(Router(session, error, dependencies)),
) -> Router(session, error, dependencies) {
  case routers {
    [] -> new("empty")
    [router] -> router
    _ -> {
      let names = list.map(routers, get_router_name)
      let name = string.join(names, "+")
      ComposedRouter(composes: routers, name: name)
    }
  }
}

/// Get the name of a router
fn get_router_name(router: Router(session, error, dependencies)) -> String {
  case router {
    Router(name:, ..) -> name
    ComposedRouter(name:, ..) -> name
  }
}

/// Convert any router (including ComposedRouter) to a flat Router with all routes merged
fn to_flat_router(
  router: Router(session, error, dependencies),
) -> Router(session, error, dependencies) {
  case router {
    Router(..) -> router
    ComposedRouter(composes:, name:) -> {
      // Flatten all routers in the list
      let flattened = list.map(composes, to_flat_router)
      merge_routers(flattened, name)
    }
  }
}

/// Merge a list of routers into a single flat router
fn merge_routers(
  routers: List(Router(session, error, dependencies)),
  name: String,
) -> Router(session, error, dependencies) {
  case routers {
    [] ->
      Router(
        commands: dict.new(),
        command_descriptions: dict.new(),
        callbacks: dict.new(),
        routes: [],
        fallback: None,
        middleware: [],
        catch_handler: None,
        name: name,
      )
    [router] -> {
      case router {
        Router(..) as router -> Router(..router, name: name)
        ComposedRouter(..) -> router
        // Should not happen after flattening
      }
    }
    [first, ..rest] -> {
      let merged_rest = merge_routers(rest, name)

      let assert Router(
        commands: first_commands,
        command_descriptions: first_descriptions,
        callbacks: first_callbacks,
        routes: first_routes,
        fallback: first_fallback,
        middleware: first_middleware,
        catch_handler: first_catch_handler,
        ..,
      ) = first

      let assert Router(
        commands: rest_commands,
        command_descriptions: rest_descriptions,
        callbacks: rest_callbacks,
        routes: rest_routes,
        fallback: rest_fallback,
        middleware: rest_middleware,
        catch_handler: rest_catch_handler,
        ..,
      ) = merged_rest

      let merged_commands = merge_keeping_first(rest_commands, first_commands)
      let merged_descriptions =
        merge_keeping_first(rest_descriptions, first_descriptions)
      let merged_callbacks =
        merge_keeping_first(rest_callbacks, first_callbacks)

      Router(
        commands: merged_commands,
        command_descriptions: merged_descriptions,
        callbacks: merged_callbacks,
        routes: list.append(first_routes, rest_routes),
        fallback: option.or(first_fallback, rest_fallback),
        middleware: list.append(first_middleware, rest_middleware),
        catch_handler: option.or(first_catch_handler, rest_catch_handler),
        name: name,
      )
    }
  }
}

/// List every command registered with a description, as `#(command, description)`
/// pairs sorted by command name. Commands added with `on_command` (no
/// description) are omitted. Flattens composed routers, so a fully composed
/// router reports the union of its sub-routers' described commands.
///
/// This is what `telega.with_auto_commands` feeds into `setMyCommands`.
pub fn registered_commands(
  router: Router(session, error, dependencies),
) -> List(#(String, String)) {
  let assert Router(command_descriptions:, ..) = to_flat_router(router)

  command_descriptions
  |> dict.to_list
  |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
}

/// Derive the set of Telegram update types this router actually handles, as the
/// strings expected by `allowed_updates` (e.g. `"message"`, `"callback_query"`).
/// The result is deduplicated and sorted for stable output.
///
/// If the router has a fallback, custom, or filtered route, the handled set
/// cannot be determined statically (those routes can match anything), so an
/// empty list is returned to signal "do not restrict" — Telegram then sends its
/// default update set. Use a manual override when you need narrowing alongside
/// catch-all routes.
pub fn allowed_updates(
  router: Router(session, error, dependencies),
) -> List(String) {
  let assert Router(commands:, callbacks:, routes:, fallback:, ..) =
    to_flat_router(router)

  let has_wildcard =
    option.is_some(fallback)
    || list.any(routes, fn(route) {
      case route {
        CustomRoute(..) | FilteredRoute(..) -> True
        _ -> False
      }
    })

  case has_wildcard {
    True -> []
    False -> {
      let from_commands = case dict.is_empty(commands) {
        True -> []
        False -> ["message"]
      }
      let from_callbacks = case dict.is_empty(callbacks) {
        True -> []
        False -> ["callback_query"]
      }
      let from_routes = list.map(routes, route_update_type)

      [from_commands, from_callbacks, from_routes]
      |> list.flatten
      |> list.unique
      |> list.sort(string.compare)
    }
  }
}

/// Map a concrete route to the Telegram `allowed_updates` string it consumes.
fn route_update_type(route: Route(session, error, dependencies)) -> String {
  case route {
    TextPatternRoute(..)
    | PhotoRoute(..)
    | VideoRoute(..)
    | VoiceRoute(..)
    | AudioRoute(..)
    | MediaGroupRoute(..) -> "message"
    InlineQueryRoute(..) -> "inline_query"
    ChosenInlineResultRoute(..) -> "chosen_inline_result"
    ShippingQueryRoute(..) -> "shipping_query"
    PreCheckoutQueryRoute(..) -> "pre_checkout_query"
    PollRoute(..) -> "poll"
    PollAnswerRoute(..) -> "poll_answer"
    MessageReactionRoute(..)
    | MessageReactionEmojiRoute(..)
    | MessageReactionPaidRoute(..)
    | MessageReactionAddedRoute(..)
    | MessageReactionRemovedRoute(..) -> "message_reaction"
    MessageReactionCountRoute(..) -> "message_reaction_count"
    ChatMemberUpdatedRoute(..) -> "chat_member"
    ChatJoinRequestRoute(..) -> "chat_join_request"
    // Wildcards are handled before this function is reached.
    CustomRoute(..) | FilteredRoute(..) -> "message"
  }
}

/// Check if a router can handle a given update (has specific routes or fallback)
fn can_handle_update(
  router: Router(session, error, dependencies),
  update: Update,
) -> Bool {
  case router {
    Router(commands:, callbacks:, routes:, fallback:, ..) -> {
      let has_specific_route = case update {
        update.CommandUpdate(command: cmd, ..) ->
          dict.has_key(commands, cmd.command)

        update.TextUpdate(text:, ..) ->
          list.any(routes, fn(route) {
            case route {
              TextPatternRoute(pattern:, ..) -> matches_pattern(pattern, text)
              _ -> False
            }
          })

        update.CallbackQueryUpdate(query:, ..) ->
          case query.data {
            Some(data) -> {
              // Check exact match first
              dict.has_key(callbacks, data)
              // Check pattern matches
              || dict.to_list(callbacks)
              |> list.any(fn(entry) {
                let #(key, _) = entry
                case string.split(key, ":") {
                  ["prefix", prefix] -> string.starts_with(data, prefix)
                  ["contains", substr] -> string.contains(data, substr)
                  ["suffix", suffix] -> string.ends_with(data, suffix)
                  _ -> key == data
                }
              })
            }
            None -> False
          }

        update.PhotoUpdate(..) ->
          list.any(routes, fn(route) {
            case route {
              PhotoRoute(..) -> True
              _ -> False
            }
          })

        update.VideoUpdate(..) ->
          list.any(routes, fn(route) {
            case route {
              VideoRoute(..) -> True
              _ -> False
            }
          })

        update.VoiceUpdate(..) ->
          list.any(routes, fn(route) {
            case route {
              VoiceRoute(..) -> True
              _ -> False
            }
          })

        update.AudioUpdate(..) ->
          list.any(routes, fn(route) {
            case route {
              AudioRoute(..) -> True
              _ -> False
            }
          })
        update.MediaGroupUpdate(..) ->
          list.any(routes, fn(route) {
            case route {
              MediaGroupRoute(..) -> True
              _ -> False
            }
          })

        _ -> False
      }

      has_specific_route
      || list.any(routes, fn(route) {
        case route {
          CustomRoute(matcher:, ..) -> matcher(update)
          FilteredRoute(filter:, ..) -> evaluate_filter(filter, update)
          _ -> False
        }
      })
      || option.is_some(fallback)
    }
    ComposedRouter(composes:, ..) ->
      list.any(composes, fn(r) { can_handle_update(r, update) })
  }
}

/// Create a sub-router that processes updates within its own scope
pub fn scope(
  router: Router(session, error, dependencies),
  predicate: fn(Update) -> Bool,
) -> Router(session, error, dependencies) {
  case router {
    Router(
      commands:,
      command_descriptions:,
      callbacks:,
      routes:,
      fallback:,
      middleware:,
      catch_handler:,
      name:,
    ) -> {
      let scoped_handler = fn(handler) {
        fn(ctx, update) {
          case predicate(update) {
            True -> handler(ctx, update)
            False -> Ok(ctx)
          }
        }
      }

      let scope_route = fn(route) {
        case route {
          TextPatternRoute(pattern:, handler:) ->
            TextPatternRoute(pattern:, handler: fn(ctx, text) {
              case predicate(ctx.update) {
                True -> handler(ctx, text)
                False -> Ok(ctx)
              }
            })
          PhotoRoute(handler:) ->
            PhotoRoute(handler: fn(ctx, photos) {
              case predicate(ctx.update) {
                True -> handler(ctx, photos)
                False -> Ok(ctx)
              }
            })
          VideoRoute(handler:) ->
            VideoRoute(handler: fn(ctx, video) {
              case predicate(ctx.update) {
                True -> handler(ctx, video)
                False -> Ok(ctx)
              }
            })
          VoiceRoute(handler:) ->
            VoiceRoute(handler: fn(ctx, voice) {
              case predicate(ctx.update) {
                True -> handler(ctx, voice)
                False -> Ok(ctx)
              }
            })
          AudioRoute(handler:) ->
            AudioRoute(handler: fn(ctx, audio) {
              case predicate(ctx.update) {
                True -> handler(ctx, audio)
                False -> Ok(ctx)
              }
            })
          MediaGroupRoute(handler:) ->
            MediaGroupRoute(handler: fn(ctx, media_group_id, messages) {
              case predicate(ctx.update) {
                True -> handler(ctx, media_group_id, messages)
                False -> Ok(ctx)
              }
            })
          InlineQueryRoute(handler:) ->
            InlineQueryRoute(handler: fn(ctx, inline_query) {
              case predicate(ctx.update) {
                True -> handler(ctx, inline_query)
                False -> Ok(ctx)
              }
            })
          ChosenInlineResultRoute(handler:) ->
            ChosenInlineResultRoute(handler: fn(ctx, chosen_inline_result) {
              case predicate(ctx.update) {
                True -> handler(ctx, chosen_inline_result)
                False -> Ok(ctx)
              }
            })
          ShippingQueryRoute(handler:) ->
            ShippingQueryRoute(handler: fn(ctx, shipping_query) {
              case predicate(ctx.update) {
                True -> handler(ctx, shipping_query)
                False -> Ok(ctx)
              }
            })
          PreCheckoutQueryRoute(handler:) ->
            PreCheckoutQueryRoute(handler: fn(ctx, pre_checkout_query) {
              case predicate(ctx.update) {
                True -> handler(ctx, pre_checkout_query)
                False -> Ok(ctx)
              }
            })
          PollRoute(handler:) ->
            PollRoute(handler: fn(ctx, poll) {
              case predicate(ctx.update) {
                True -> handler(ctx, poll)
                False -> Ok(ctx)
              }
            })
          PollAnswerRoute(handler:) ->
            PollAnswerRoute(handler: fn(ctx, poll_answer) {
              case predicate(ctx.update) {
                True -> handler(ctx, poll_answer)
                False -> Ok(ctx)
              }
            })
          MessageReactionRoute(handler:) ->
            MessageReactionRoute(handler: fn(ctx, message_reaction) {
              case predicate(ctx.update) {
                True -> handler(ctx, message_reaction)
                False -> Ok(ctx)
              }
            })
          MessageReactionEmojiRoute(emojis:, handler:) ->
            MessageReactionEmojiRoute(
              emojis:,
              handler: fn(ctx, message_reaction) {
                case predicate(ctx.update) {
                  True -> handler(ctx, message_reaction)
                  False -> Ok(ctx)
                }
              },
            )
          MessageReactionPaidRoute(handler:) ->
            MessageReactionPaidRoute(handler: fn(ctx, message_reaction) {
              case predicate(ctx.update) {
                True -> handler(ctx, message_reaction)
                False -> Ok(ctx)
              }
            })
          MessageReactionAddedRoute(handler:) ->
            MessageReactionAddedRoute(handler: fn(ctx, message_reaction) {
              case predicate(ctx.update) {
                True -> handler(ctx, message_reaction)
                False -> Ok(ctx)
              }
            })
          MessageReactionRemovedRoute(handler:) ->
            MessageReactionRemovedRoute(handler: fn(ctx, message_reaction) {
              case predicate(ctx.update) {
                True -> handler(ctx, message_reaction)
                False -> Ok(ctx)
              }
            })
          MessageReactionCountRoute(handler:) ->
            MessageReactionCountRoute(handler: fn(ctx, message_reaction_count) {
              case predicate(ctx.update) {
                True -> handler(ctx, message_reaction_count)
                False -> Ok(ctx)
              }
            })
          ChatMemberUpdatedRoute(handler:) ->
            ChatMemberUpdatedRoute(handler: fn(ctx, chat_member_updated) {
              case predicate(ctx.update) {
                True -> handler(ctx, chat_member_updated)
                False -> Ok(ctx)
              }
            })
          ChatJoinRequestRoute(handler:) ->
            ChatJoinRequestRoute(handler: fn(ctx, chat_join_request) {
              case predicate(ctx.update) {
                True -> handler(ctx, chat_join_request)
                False -> Ok(ctx)
              }
            })
          CustomRoute(matcher:, handler:) ->
            CustomRoute(
              matcher: fn(update) { predicate(update) && matcher(update) },
              handler: handler,
            )
          FilteredRoute(filter: f, handler:) ->
            FilteredRoute(
              filter: and2(filter("scope", predicate), f),
              handler: handler,
            )
        }
      }

      Router(
        commands: dict.map_values(commands, fn(_, h) { scoped_handler(h) }),
        command_descriptions: command_descriptions,
        callbacks: dict.map_values(callbacks, fn(_, h) { scoped_handler(h) }),
        routes: list.map(routes, scope_route),
        fallback: option.map(fallback, scoped_handler),
        middleware: middleware,
        catch_handler: catch_handler,
        name: name <> "_scoped",
      )
    }
    ComposedRouter(..) as composed -> composed
  }
}

/// Find the appropriate handler for an update
fn find_handler(
  router: Router(session, error, dependencies),
  update: Update,
  context: Context(session, error, dependencies),
) -> Handler(session, error, dependencies) {
  case router {
    Router(..) -> find_handler_in_router(router, update, context)
    ComposedRouter(composes:, ..) ->
      find_handler_in_composed(composes, update, context)
  }
}

/// Find handler in composed routers
fn find_handler_in_composed(
  routers: List(Router(session, error, dependencies)),
  update: Update,
  context: Context(session, error, dependencies),
) -> Handler(session, error, dependencies) {
  case routers {
    [] -> fn(ctx, _) { Ok(ctx) }
    // No handler found
    [router, ..rest] -> {
      case can_handle_update(router, update) {
        True -> find_handler(router, update, context)
        False -> find_handler_in_composed(rest, update, context)
      }
    }
  }
}

/// Find handler in a regular router (not composed)
fn find_handler_in_router(
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

/// Find a command handler
fn find_command_handler(
  router: Router(session, error, dependencies),
  update: Update,
  context: Context(session, error, dependencies),
) -> Option(Handler(session, error, dependencies)) {
  case router, update {
    Router(commands:, ..), update.CommandUpdate(command:, ..) -> {
      //if command /help@yourbot has @ in the text,
      //try split suffix after @ and match with current bot's username
      let try_split = command.command |> string.split_once("@")
      let command_key = case context.bot_info.username, try_split {
        Some(bot_username), Ok(#(cmd_text, bot_suffix))
          if bot_username == bot_suffix && bot_username != ""
        -> cmd_text
        _, _ -> command.command
      }

      dict.get(commands, command_key)
      |> option.from_result
    }
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
  case dict.get(callbacks, data) {
    Ok(handler) -> Some(handler)
    Error(_) -> find_callback_by_pattern(callbacks, data)
  }
}

/// Find callback handler by pattern matching
fn find_callback_by_pattern(
  callbacks: Dict(String, Handler(session, error, dependencies)),
  data: String,
) -> Option(Handler(session, error, dependencies)) {
  dict.to_list(callbacks)
  |> list.find(fn(entry) {
    let #(key, _) = entry
    matches_callback_pattern(key, data)
  })
  |> result.map(fn(entry) {
    let #(_, handler) = entry
    handler
  })
  |> option.from_result
}

/// Check if a callback pattern key matches the data
fn matches_callback_pattern(key: String, data: String) -> Bool {
  case string.split(key, ":") {
    ["prefix", prefix] -> string.starts_with(data, prefix)
    ["contains", substr] -> string.contains(data, substr)
    ["suffix", suffix] -> string.ends_with(data, suffix)
    _ -> False
  }
}

/// Try routes, then fallback
fn find_route_or_fallback(
  router: Router(session, error, dependencies),
  update: Update,
) -> Handler(session, error, dependencies) {
  case router {
    Router(routes:, fallback:, ..) -> {
      case find_matching_route(routes, update) {
        Some(handler) -> handler
        None ->
          case fallback {
            Some(handler) -> handler
            None -> fn(ctx, _) { Ok(ctx) }
          }
      }
    }
    ComposedRouter(composes:, ..) ->
      find_route_or_fallback_in_composed(composes, update)
  }
}

/// Find route or fallback in composed routers
fn find_route_or_fallback_in_composed(
  routers: List(Router(session, error, dependencies)),
  update: Update,
) -> Handler(session, error, dependencies) {
  case routers {
    [] -> fn(ctx, _) { Ok(ctx) }
    [router, ..rest] -> {
      case can_handle_update(router, update) {
        True -> find_route_or_fallback(router, update)
        False -> find_route_or_fallback_in_composed(rest, update)
      }
    }
  }
}

/// Find matching route for an update
fn find_matching_route(
  routes: List(Route(session, error, dependencies)),
  update: Update,
) -> Option(Handler(session, error, dependencies)) {
  case routes {
    [] -> None
    [route, ..rest] ->
      case route_matches(route, update) {
        True -> {
          let handler = case route, update {
            TextPatternRoute(handler:, ..), update.TextUpdate(text:, ..) -> fn(
              ctx,
              _,
            ) {
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
            InlineQueryRoute(handler:),
              update.InlineQueryUpdate(inline_query:, ..)
            -> fn(ctx, _) { handler(ctx, inline_query) }
            ChosenInlineResultRoute(handler:),
              update.ChosenInlineResultUpdate(chosen_inline_result:, ..)
            -> fn(ctx, _) { handler(ctx, chosen_inline_result) }
            ShippingQueryRoute(handler:),
              update.ShippingQueryUpdate(shipping_query:, ..)
            -> fn(ctx, _) { handler(ctx, shipping_query) }
            PreCheckoutQueryRoute(handler:),
              update.PreCheckoutQueryUpdate(pre_checkout_query:, ..)
            -> fn(ctx, _) { handler(ctx, pre_checkout_query) }
            PollRoute(handler:), update.PollUpdate(poll:, ..) -> fn(ctx, _) {
              handler(ctx, poll)
            }
            PollAnswerRoute(handler:), update.PollAnswerUpdate(poll_answer:, ..)
            -> fn(ctx, _) { handler(ctx, poll_answer) }
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
              update.MessageReactionCountUpdate(
                message_reaction_count_updated:,
                ..,
              )
            -> fn(ctx, _) { handler(ctx, message_reaction_count_updated) }
            ChatMemberUpdatedRoute(handler:),
              update.ChatMemberUpdate(chat_member_updated:, ..)
            -> fn(ctx, _) { handler(ctx, chat_member_updated) }
            ChatJoinRequestRoute(handler:),
              update.ChatJoinRequestUpdate(chat_join_request:, ..)
            -> fn(ctx, _) { handler(ctx, chat_join_request) }
            CustomRoute(handler:, ..), _ -> handler
            FilteredRoute(handler:, ..), _ -> handler
            _, _ -> fn(ctx, _) { Ok(ctx) }
          }
          Some(handler)
        }
        False -> find_matching_route(rest, update)
      }
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
    InlineQueryRoute(..), update.InlineQueryUpdate(..) -> True
    ChosenInlineResultRoute(..), update.ChosenInlineResultUpdate(..) -> True
    ShippingQueryRoute(..), update.ShippingQueryUpdate(..) -> True
    PreCheckoutQueryRoute(..), update.PreCheckoutQueryUpdate(..) -> True
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
    ChatJoinRequestRoute(..), update.ChatJoinRequestUpdate(..) -> True
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
