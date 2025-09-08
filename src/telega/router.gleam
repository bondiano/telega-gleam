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
////   reply.with_text(ctx, "Sorry, an error occurred")
//// })
//// ```
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

import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import telega/bot.{type Context}

import telega/internal/log
import telega/model/types.{
  type Audio, type Message, type PhotoSize, type Video, type Voice,
}
import telega/update.{type Command, type Update}

/// Router with unified routes and middleware support
pub opaque type Router(session, error) {
  Router(
    commands: Dict(String, Handler(session, error)),
    callbacks: Dict(String, Handler(session, error)),
    routes: List(Route(session, error)),
    fallback: Option(Handler(session, error)),
    middleware: List(Middleware(session, error)),
    catch_handler: Option(fn(error) -> Result(Context(session, error), error)),
    name: String,
  )
  ComposedRouter(composes: List(Router(session, error)), name: String)
}

/// Generic handler type for all updates
pub type Handler(session, error) =
  fn(Context(session, error), Update) -> Result(Context(session, error), error)

pub type CommandHandler(session, error) =
  fn(Context(session, error), Command) -> Result(Context(session, error), error)

pub type TextHandler(session, error) =
  fn(Context(session, error), String) -> Result(Context(session, error), error)

pub type CallbackHandler(session, error) =
  fn(Context(session, error), String, String) ->
    Result(Context(session, error), error)

pub type PhotoHandler(session, error) =
  fn(Context(session, error), List(PhotoSize)) ->
    Result(Context(session, error), error)

pub type VideoHandler(session, error) =
  fn(Context(session, error), Video) -> Result(Context(session, error), error)

pub type VoiceHandler(session, error) =
  fn(Context(session, error), Voice) -> Result(Context(session, error), error)

pub type AudioHandler(session, error) =
  fn(Context(session, error), Audio) -> Result(Context(session, error), error)

pub type MediaGroupHandler(session, error) =
  fn(Context(session, error), String, List(Message)) ->
    Result(Context(session, error), error)

pub type MessageHandler(session, error) =
  fn(Context(session, error), Message) -> Result(Context(session, error), error)

/// Middleware wraps a handler with additional functionality
pub type Middleware(session, error) =
  fn(Handler(session, error)) -> Handler(session, error)

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
pub type Route(session, error) {
  TextPatternRoute(pattern: Pattern, handler: TextHandler(session, error))
  PhotoRoute(handler: PhotoHandler(session, error))
  VideoRoute(handler: VideoHandler(session, error))
  VoiceRoute(handler: VoiceHandler(session, error))
  AudioRoute(handler: AudioHandler(session, error))
  MediaGroupRoute(handler: MediaGroupHandler(session, error))
  CustomRoute(matcher: fn(Update) -> Bool, handler: Handler(session, error))
  FilteredRoute(filter: Filter, handler: Handler(session, error))
}

/// Create a new router
pub fn new(name: String) -> Router(session, error) {
  Router(
    commands: dict.new(),
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
  router: Router(session, error),
  command: String,
  handler: CommandHandler(session, error),
) -> Router(session, error) {
  case router {
    Router(commands:, ..) -> {
      // Remove leading slash if present for consistency
      let command_key = case string.starts_with(command, "/") {
        True -> string.drop_start(command, 1)
        False -> command
      }
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
  router: Router(session, error),
  commands: List(String),
  handler: CommandHandler(session, error),
) -> Router(session, error) {
  list.fold(commands, router, fn(r, cmd) { on_command(r, cmd, handler) })
}

/// Add a text handler with pattern
pub fn on_text(
  router: Router(session, error),
  pattern: Pattern,
  handler: TextHandler(session, error),
) -> Router(session, error) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [TextPatternRoute(pattern:, handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add a handler for any text
pub fn on_any_text(
  router: Router(session, error),
  handler: TextHandler(session, error),
) -> Router(session, error) {
  on_text(router, Prefix(""), handler)
}

/// Add a callback query handler with pattern
pub fn on_callback(
  router: Router(session, error),
  pattern: Pattern,
  handler: CallbackHandler(session, error),
) -> Router(session, error) {
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
  router: Router(session, error),
  handler: PhotoHandler(session, error),
) -> Router(session, error) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [PhotoRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

pub fn on_video(
  router: Router(session, error),
  handler: VideoHandler(session, error),
) -> Router(session, error) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [VideoRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

pub fn on_voice(
  router: Router(session, error),
  handler: VoiceHandler(session, error),
) -> Router(session, error) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [VoiceRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

pub fn on_audio(
  router: Router(session, error),
  handler: AudioHandler(session, error),
) -> Router(session, error) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [AudioRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add handler for media groups (albums of photos/videos)
pub fn on_media_group(
  router: Router(session, error),
  handler: MediaGroupHandler(session, error),
) -> Router(session, error) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [MediaGroupRoute(handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add a custom route with matcher function
pub fn on_custom(
  router: Router(session, error),
  matcher: fn(Update) -> Bool,
  handler: Handler(session, error),
) -> Router(session, error) {
  case router {
    Router(routes:, ..) ->
      Router(..router, routes: [CustomRoute(matcher:, handler:), ..routes])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add a filtered route
pub fn on_filtered(
  router: Router(session, error),
  filter: Filter,
  handler: Handler(session, error),
) -> Router(session, error) {
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
    case update {
      update.TextUpdate(chat_id: cid, ..) -> cid == chat_id
      update.CommandUpdate(chat_id: cid, ..) -> cid == chat_id
      update.CallbackQueryUpdate(chat_id: cid, ..) -> cid == chat_id
      update.PhotoUpdate(chat_id: cid, ..) -> cid == chat_id
      update.VideoUpdate(chat_id: cid, ..) -> cid == chat_id
      update.VoiceUpdate(chat_id: cid, ..) -> cid == chat_id
      update.AudioUpdate(chat_id: cid, ..) -> cid == chat_id
      _ -> False
    }
  })
}

/// Filter for private chats
pub fn is_private_chat() -> Filter {
  filter("is_private_chat", fn(update) {
    case update {
      update.TextUpdate(message:, ..)
      | update.CommandUpdate(message:, ..)
      | update.PhotoUpdate(message:, ..)
      | update.VideoUpdate(message:, ..)
      | update.VoiceUpdate(message:, ..)
      | update.AudioUpdate(message:, ..) ->
        case message.chat.type_ {
          Some("private") -> True
          _ -> False
        }
      _ -> False
    }
  })
}

/// Filter for group chats
pub fn is_group_chat() -> Filter {
  filter("is_group_chat", fn(update) {
    case update {
      update.TextUpdate(message:, ..)
      | update.CommandUpdate(message:, ..)
      | update.PhotoUpdate(message:, ..)
      | update.VideoUpdate(message:, ..)
      | update.VoiceUpdate(message:, ..)
      | update.AudioUpdate(message:, ..) ->
        case message.chat.type_ {
          Some("group") | Some("supergroup") -> True
          _ -> False
        }
      _ -> False
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
  router: Router(session, error),
  handler: Handler(session, error),
) -> Router(session, error) {
  case router {
    Router(..) -> Router(..router, fallback: Some(handler))
    ComposedRouter(..) as composed -> composed
  }
}

/// Add middleware to the router
pub fn use_middleware(
  router: Router(session, error),
  middleware: Middleware(session, error),
) -> Router(session, error) {
  case router {
    Router(middleware: existing_middleware, ..) ->
      Router(..router, middleware: [middleware, ..existing_middleware])
    ComposedRouter(..) as composed -> composed
  }
}

/// Add a catch handler to the router that handles errors from all routes
pub fn with_catch_handler(
  router: Router(session, error),
  catch_handler: fn(error) -> Result(Context(session, error), error),
) -> Router(session, error) {
  case router {
    Router(..) -> Router(..router, catch_handler: Some(catch_handler))
    ComposedRouter(..) as composed -> composed
  }
}

/// Process an update through the router
pub fn handle(
  router: Router(session, error),
  ctx: Context(session, error),
  update: Update,
) -> Result(Context(session, error), error) {
  case router {
    Router(middleware:, catch_handler:, ..) -> {
      let handler = find_handler(router, update)

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
  routers: List(Router(session, error)),
  ctx: Context(session, error),
  update: Update,
) -> Result(Context(session, error), error) {
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
  first: Router(session, error),
  second: Router(session, error),
) -> Router(session, error) {
  // Convert both routers to flat representation for merging
  let first_flat = to_flat_router(first)
  let second_flat = to_flat_router(second)

  let assert Router(
    commands: first_commands,
    callbacks: first_callbacks,
    routes: first_routes,
    fallback: first_fallback,
    middleware: first_middleware,
    catch_handler: first_catch_handler,
    name: first_name,
  ) = first_flat

  let assert Router(
    commands: second_commands,
    callbacks: second_callbacks,
    routes: second_routes,
    fallback: second_fallback,
    middleware: second_middleware,
    catch_handler: second_catch_handler,
    name: second_name,
  ) = second_flat

  let merged_commands =
    dict.fold(second_commands, first_commands, fn(acc, key, value) {
      case dict.has_key(acc, key) {
        True -> acc
        False -> dict.insert(acc, key, value)
      }
    })

  let merged_callbacks =
    dict.fold(second_callbacks, first_callbacks, fn(acc, key, value) {
      case dict.has_key(acc, key) {
        True -> acc
        False -> dict.insert(acc, key, value)
      }
    })

  Router(
    commands: merged_commands,
    callbacks: merged_callbacks,
    routes: list.append(first_routes, second_routes),
    fallback: option.or(first_fallback, second_fallback),
    middleware: list.append(first_middleware, second_middleware),
    catch_handler: option.or(first_catch_handler, second_catch_handler),
    name: first_name <> "+" <> second_name,
  )
}

/// Compose two routers, where each router maintains its own middleware and catch handlers.
/// First router is tried first, if it doesn't handle the update, second router is tried.
pub fn compose(
  first: Router(session, error),
  second: Router(session, error),
) -> Router(session, error) {
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
  routers: List(Router(session, error)),
) -> Router(session, error) {
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
fn get_router_name(router: Router(session, error)) -> String {
  case router {
    Router(name:, ..) -> name
    ComposedRouter(name:, ..) -> name
  }
}

/// Convert any router (including ComposedRouter) to a flat Router with all routes merged
fn to_flat_router(router: Router(session, error)) -> Router(session, error) {
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
  routers: List(Router(session, error)),
  name: String,
) -> Router(session, error) {
  case routers {
    [] ->
      Router(
        commands: dict.new(),
        callbacks: dict.new(),
        routes: [],
        fallback: None,
        middleware: [],
        catch_handler: None,
        name: name,
      )
    [router] -> {
      case router {
        Router(
          commands:,
          callbacks:,
          routes:,
          fallback:,
          middleware:,
          catch_handler:,
          ..,
        ) ->
          Router(
            commands: commands,
            callbacks: callbacks,
            routes: routes,
            fallback: fallback,
            middleware: middleware,
            catch_handler: catch_handler,
            name: name,
          )
        ComposedRouter(..) -> router
        // Should not happen after flattening
      }
    }
    [first, ..rest] -> {
      let merged_rest = merge_routers(rest, name)

      let assert Router(
        commands: first_commands,
        callbacks: first_callbacks,
        routes: first_routes,
        fallback: first_fallback,
        middleware: first_middleware,
        catch_handler: first_catch_handler,
        ..,
      ) = first

      let assert Router(
        commands: rest_commands,
        callbacks: rest_callbacks,
        routes: rest_routes,
        fallback: rest_fallback,
        middleware: rest_middleware,
        catch_handler: rest_catch_handler,
        ..,
      ) = merged_rest

      let merged_commands =
        dict.fold(rest_commands, first_commands, fn(acc, key, value) {
          case dict.has_key(acc, key) {
            True -> acc
            False -> dict.insert(acc, key, value)
          }
        })

      let merged_callbacks =
        dict.fold(rest_callbacks, first_callbacks, fn(acc, key, value) {
          case dict.has_key(acc, key) {
            True -> acc
            False -> dict.insert(acc, key, value)
          }
        })

      Router(
        commands: merged_commands,
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

/// Check if a router can handle a given update (has specific routes or fallback)
fn can_handle_update(router: Router(session, error), update: Update) -> Bool {
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
  router: Router(session, error),
  predicate: fn(Update) -> Bool,
) -> Router(session, error) {
  case router {
    Router(
      commands:,
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
  router: Router(session, error),
  update: Update,
) -> Handler(session, error) {
  case router {
    Router(..) -> find_handler_in_router(router, update)
    ComposedRouter(composes:, ..) -> find_handler_in_composed(composes, update)
  }
}

/// Find handler in composed routers
fn find_handler_in_composed(
  routers: List(Router(session, error)),
  update: Update,
) -> Handler(session, error) {
  case routers {
    [] -> fn(ctx, _) { Ok(ctx) }
    // No handler found
    [router, ..rest] -> {
      case can_handle_update(router, update) {
        True -> find_handler(router, update)
        False -> find_handler_in_composed(rest, update)
      }
    }
  }
}

/// Find handler in a regular router (not composed)
fn find_handler_in_router(
  router: Router(session, error),
  update: Update,
) -> Handler(session, error) {
  case update {
    update.CommandUpdate(..) ->
      find_command_handler(router, update)
      |> option.unwrap(find_route_or_fallback(router, update))

    update.CallbackQueryUpdate(..) ->
      find_callback_handler(router, update)
      |> option.unwrap(find_route_or_fallback(router, update))

    _ -> find_route_or_fallback(router, update)
  }
}

/// Find a command handler
fn find_command_handler(
  router: Router(session, error),
  update: Update,
) -> Option(Handler(session, error)) {
  case router, update {
    Router(commands:, ..), update.CommandUpdate(command:, ..) ->
      dict.get(commands, command.command)
      |> option.from_result
    _, _ -> None
  }
}

/// Find a callback handler
fn find_callback_handler(
  router: Router(session, error),
  update: Update,
) -> Option(Handler(session, error)) {
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
  callbacks: Dict(String, Handler(session, error)),
  data: String,
) -> Option(Handler(session, error)) {
  // Try exact match first
  case dict.get(callbacks, data) {
    Ok(handler) -> Some(handler)
    Error(_) -> find_callback_by_pattern(callbacks, data)
  }
}

/// Find callback handler by pattern matching
fn find_callback_by_pattern(
  callbacks: Dict(String, Handler(session, error)),
  data: String,
) -> Option(Handler(session, error)) {
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
  router: Router(session, error),
  update: Update,
) -> Handler(session, error) {
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
  routers: List(Router(session, error)),
  update: Update,
) -> Handler(session, error) {
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
  routes: List(Route(session, error)),
  update: Update,
) -> Option(Handler(session, error)) {
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
fn route_matches(route: Route(session, error), update: Update) -> Bool {
  case route, update {
    TextPatternRoute(pattern:, ..), update.TextUpdate(text:, ..) ->
      matches_pattern(pattern, text)
    PhotoRoute(..), update.PhotoUpdate(..) -> True
    VideoRoute(..), update.VideoUpdate(..) -> True
    VoiceRoute(..), update.VoiceUpdate(..) -> True
    AudioRoute(..), update.AudioUpdate(..) -> True
    MediaGroupRoute(..), update.MediaGroupUpdate(..) -> True
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

/// Apply middleware to a handler
fn apply_middleware(
  handler: Handler(session, error),
  middleware: List(Middleware(session, error)),
) -> Handler(session, error) {
  list.fold(middleware, handler, fn(h, mw) { mw(h) })
}

/// Logging middleware - logs update processing
pub fn with_logging(handler: Handler(session, error)) -> Handler(session, error) {
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
  handler: Handler(session, error),
) -> Handler(session, error) {
  fn(ctx, update) {
    case predicate(update) {
      True -> handler(ctx, update)
      False -> Ok(ctx)
    }
  }
}

/// Error recovery middleware
pub fn with_recovery(
  recover: fn(error) -> Result(Context(session, error), error),
  handler: Handler(session, error),
) -> Handler(session, error) {
  fn(ctx, update) {
    case handler(ctx, update) {
      Ok(result) -> Ok(result)
      Error(err) -> recover(err)
    }
  }
}
