//// `reactions` provides convenient helpers for working with Telegram reactions.
////
//// ## Sending reactions
////
//// ```gleam
//// import telega/reactions
////
//// // React to current message with emoji
//// reactions.react(ctx, reactions.thumbs_up)
////
//// // React with custom emoji string
//// reactions.react_emoji(ctx, "👍")
////
//// // React with big animation
//// reactions.react_big(ctx, reactions.heart)
//// ```
////
//// ## Handling reaction updates
////
//// ```gleam
//// import telega/router
//// import telega/reactions
////
//// router.new()
//// |> router.on_reaction(fn(ctx, update) {
////   let changes = reactions.get_changes(update)
////   // Process added/removed reactions
////   Ok(ctx)
//// })
//// ```

import gleam/list
import gleam/option.{type Option, None, Some}

import telega/api
import telega/bot.{type Context}
import telega/error
import telega/model/types.{
  type MessageReactionCountUpdated, type MessageReactionUpdated,
  type ReactionCount, type ReactionType, Int as IntValue,
  ReactionTypeCustomEmoji, ReactionTypeCustomEmojiReactionType,
  ReactionTypeEmoji, ReactionTypeEmojiReactionType, ReactionTypePaid,
  ReactionTypePaidReactionType, SetMessageReactionParameters,
}
import telega/update.{type Update}

// ============================================
// Reaction constructors
// ============================================

/// Create an emoji reaction
pub fn emoji(emoji_str: String) -> ReactionType {
  ReactionTypeEmojiReactionType(ReactionTypeEmoji(
    type_: "emoji",
    emoji: emoji_str,
  ))
}

/// Create a custom emoji reaction
pub fn custom_emoji(custom_emoji_id: String) -> ReactionType {
  ReactionTypeCustomEmojiReactionType(ReactionTypeCustomEmoji(
    type_: "custom_emoji",
    custom_emoji_id:,
  ))
}

/// Create a paid reaction (stars)
pub fn paid() -> ReactionType {
  ReactionTypePaidReactionType(ReactionTypePaid(type_: "paid"))
}

// ============================================
// Emoji presets
// ============================================

pub const thumbs_up: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "👍"),
)

pub const thumbs_down: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "👎"),
)

pub const heart: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "❤"),
)

pub const fire: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "🔥"),
)

pub const clap: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "👏"),
)

pub const party: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "🎉"),
)

pub const laugh: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "😂"),
)

pub const wow: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "😮"),
)

pub const sad: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "😢"),
)

pub const angry: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "😡"),
)

pub const poop: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "💩"),
)

pub const hundred: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "💯"),
)

pub const eyes: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "👀"),
)

pub const thinking: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "🤔"),
)

pub const ok: ReactionType = ReactionTypeEmojiReactionType(
  ReactionTypeEmoji(type_: "emoji", emoji: "👌"),
)

// ============================================
// Reaction actions
// ============================================

/// React to the current message with a reaction
///
/// ## Example
/// ```gleam
/// reactions.react(ctx, reactions.thumbs_up)
/// ```
pub fn react(
  ctx ctx: Context(session, error),
  reaction reaction: ReactionType,
) -> Result(Bool, error.TelegaError) {
  case get_message_id(ctx.update) {
    Some(message_id) ->
      set_reaction(ctx, ctx.update.chat_id, message_id, Some([reaction]), None)
    None ->
      Error(error.RouterError("No message_id available in current update"))
  }
}

/// React to the current message with an emoji string
///
/// ## Example
/// ```gleam
/// reactions.react_emoji(ctx, "👍")
/// ```
pub fn react_emoji(
  ctx ctx: Context(session, error),
  emoji_str emoji_str: String,
) -> Result(Bool, error.TelegaError) {
  react(ctx, emoji(emoji_str))
}

/// React to the current message with multiple reactions
///
/// ## Example
/// ```gleam
/// reactions.react_many(ctx, [reactions.thumbs_up, reactions.heart])
/// ```
pub fn react_many(
  ctx ctx: Context(session, error),
  reactions reactions: List(ReactionType),
) -> Result(Bool, error.TelegaError) {
  case get_message_id(ctx.update) {
    Some(message_id) ->
      set_reaction(ctx, ctx.update.chat_id, message_id, Some(reactions), None)
    None ->
      Error(error.RouterError("No message_id available in current update"))
  }
}

/// React to the current message with a big animation
///
/// ## Example
/// ```gleam
/// reactions.react_big(ctx, reactions.party)
/// ```
pub fn react_big(
  ctx ctx: Context(session, error),
  reaction reaction: ReactionType,
) -> Result(Bool, error.TelegaError) {
  case get_message_id(ctx.update) {
    Some(message_id) ->
      set_reaction(
        ctx,
        ctx.update.chat_id,
        message_id,
        Some([reaction]),
        Some(True),
      )
    None ->
      Error(error.RouterError("No message_id available in current update"))
  }
}

/// Clear all bot's reactions from the current message
///
/// ## Example
/// ```gleam
/// reactions.clear_reaction(ctx)
/// ```
pub fn clear_reaction(
  ctx ctx: Context(session, error),
) -> Result(Bool, error.TelegaError) {
  case get_message_id(ctx.update) {
    Some(message_id) ->
      set_reaction(ctx, ctx.update.chat_id, message_id, Some([]), None)
    None ->
      Error(error.RouterError("No message_id available in current update"))
  }
}

/// React to a specific message by ID
///
/// ## Example
/// ```gleam
/// reactions.react_to_message(ctx, message_id: 123, reaction: reactions.heart)
/// ```
pub fn react_to_message(
  ctx ctx: Context(session, error),
  message_id message_id: Int,
  reaction reaction: ReactionType,
) -> Result(Bool, error.TelegaError) {
  set_reaction(ctx, ctx.update.chat_id, message_id, Some([reaction]), None)
}

/// React to a specific message in a specific chat
///
/// ## Example
/// ```gleam
/// reactions.react_to_chat_message(ctx, chat_id: -100123, message_id: 456, reaction: reactions.fire)
/// ```
pub fn react_to_chat_message(
  ctx ctx: Context(session, error),
  chat_id chat_id: Int,
  message_id message_id: Int,
  reaction reaction: ReactionType,
) -> Result(Bool, error.TelegaError) {
  set_reaction(ctx, chat_id, message_id, Some([reaction]), None)
}

// ============================================
// Reaction changes analysis
// ============================================

/// Information about reaction changes
pub type ReactionChanges {
  ReactionChanges(
    /// Reactions that were added
    added: List(ReactionType),
    /// Reactions that were removed
    removed: List(ReactionType),
    /// Reactions that remained unchanged
    kept: List(ReactionType),
  )
}

/// Get detailed information about reaction changes
///
/// ## Example
/// ```gleam
/// let changes = reactions.get_changes(update)
/// list.each(changes.added, fn(r) {
///   case reactions.get_emoji(r) {
///     Some(e) -> io.println("Added: " <> e)
///     None -> Nil
///   }
/// })
/// ```
pub fn get_changes(update: MessageReactionUpdated) -> ReactionChanges {
  let old = update.old_reaction
  let new = update.new_reaction

  let added =
    list.filter(new, fn(r) { !list.any(old, fn(o) { reaction_equals(r, o) }) })

  let removed =
    list.filter(old, fn(r) { !list.any(new, fn(n) { reaction_equals(r, n) }) })

  let kept =
    list.filter(new, fn(r) { list.any(old, fn(o) { reaction_equals(r, o) }) })

  ReactionChanges(added:, removed:, kept:)
}

/// Check if a specific emoji was added
///
/// ## Example
/// ```gleam
/// if reactions.was_added(update, "👍") {
///   // Handle like
/// }
/// ```
pub fn was_added(update: MessageReactionUpdated, emoji_str: String) -> Bool {
  let changes = get_changes(update)
  list.any(changes.added, fn(r) {
    case get_emoji(r) {
      Some(e) -> e == emoji_str
      None -> False
    }
  })
}

/// Check if a specific emoji was removed
///
/// ## Example
/// ```gleam
/// if reactions.was_removed(update, "👍") {
///   // Handle unlike
/// }
/// ```
pub fn was_removed(update: MessageReactionUpdated, emoji_str: String) -> Bool {
  let changes = get_changes(update)
  list.any(changes.removed, fn(r) {
    case get_emoji(r) {
      Some(e) -> e == emoji_str
      None -> False
    }
  })
}

/// Check if there are any added reactions
pub fn has_added(update: MessageReactionUpdated) -> Bool {
  let changes = get_changes(update)
  !list.is_empty(changes.added)
}

/// Check if there are any removed reactions
pub fn has_removed(update: MessageReactionUpdated) -> Bool {
  let changes = get_changes(update)
  !list.is_empty(changes.removed)
}

// ============================================
// Reaction count helpers (for channels)
// ============================================

/// Reaction count information
pub type ReactionCountInfo {
  ReactionCountInfo(reaction: ReactionType, count: Int)
}

/// Get all reaction counts from a MessageReactionCountUpdated
pub fn get_counts(
  update: MessageReactionCountUpdated,
) -> List(ReactionCountInfo) {
  list.map(update.reactions, fn(rc: ReactionCount) {
    ReactionCountInfo(reaction: rc.type_, count: rc.total_count)
  })
}

/// Get total count across all reactions
pub fn get_total_count(update: MessageReactionCountUpdated) -> Int {
  list.fold(update.reactions, 0, fn(acc, rc: ReactionCount) {
    acc + rc.total_count
  })
}

/// Get count for a specific emoji
pub fn get_emoji_count(
  update: MessageReactionCountUpdated,
  emoji_str: String,
) -> Int {
  list.fold(update.reactions, 0, fn(acc, rc: ReactionCount) {
    case get_emoji(rc.type_) {
      Some(e) if e == emoji_str -> acc + rc.total_count
      _ -> acc
    }
  })
}

/// Get top reactions sorted by count
pub fn get_top_reactions(
  update: MessageReactionCountUpdated,
  limit: Int,
) -> List(ReactionCountInfo) {
  update.reactions
  |> list.map(fn(rc: ReactionCount) {
    ReactionCountInfo(reaction: rc.type_, count: rc.total_count)
  })
  |> list.sort(fn(a, b) { int.compare(b.count, a.count) })
  |> list.take(limit)
}

// ============================================
// Reaction type helpers
// ============================================

/// Get emoji string from a ReactionType (if it's an emoji reaction)
///
/// ## Example
/// ```gleam
/// case reactions.get_emoji(reaction) {
///   Some(emoji) -> io.println("Emoji: " <> emoji)
///   None -> io.println("Not an emoji reaction")
/// }
/// ```
pub fn get_emoji(reaction: ReactionType) -> Option(String) {
  case reaction {
    ReactionTypeEmojiReactionType(inner) -> Some(inner.emoji)
    _ -> None
  }
}

/// Get custom emoji ID from a ReactionType (if it's a custom emoji reaction)
pub fn get_custom_emoji_id(reaction: ReactionType) -> Option(String) {
  case reaction {
    ReactionTypeCustomEmojiReactionType(inner) -> Some(inner.custom_emoji_id)
    _ -> None
  }
}

/// Check if a reaction is a paid reaction (stars)
pub fn is_paid(reaction: ReactionType) -> Bool {
  case reaction {
    ReactionTypePaidReactionType(_) -> True
    _ -> False
  }
}

/// Check if a reaction is an emoji reaction
pub fn is_emoji(reaction: ReactionType) -> Bool {
  case reaction {
    ReactionTypeEmojiReactionType(_) -> True
    _ -> False
  }
}

/// Check if a reaction is a custom emoji reaction
pub fn is_custom_emoji(reaction: ReactionType) -> Bool {
  case reaction {
    ReactionTypeCustomEmojiReactionType(_) -> True
    _ -> False
  }
}

/// Check if two reactions are equal
pub fn reaction_equals(a: ReactionType, b: ReactionType) -> Bool {
  case a, b {
    ReactionTypeEmojiReactionType(a_inner),
      ReactionTypeEmojiReactionType(b_inner)
    -> a_inner.emoji == b_inner.emoji
    ReactionTypeCustomEmojiReactionType(a_inner),
      ReactionTypeCustomEmojiReactionType(b_inner)
    -> a_inner.custom_emoji_id == b_inner.custom_emoji_id
    ReactionTypePaidReactionType(_), ReactionTypePaidReactionType(_) -> True
    _, _ -> False
  }
}

/// Check if a reaction matches a specific emoji
pub fn matches_emoji(reaction: ReactionType, emoji_str: String) -> Bool {
  case get_emoji(reaction) {
    Some(e) -> e == emoji_str
    None -> False
  }
}

// ============================================
// Internal helpers
// ============================================

fn set_reaction(
  ctx: Context(session, error),
  chat_id: Int,
  message_id: Int,
  reaction: Option(List(ReactionType)),
  is_big: Option(Bool),
) -> Result(Bool, error.TelegaError) {
  api.set_message_reaction(
    ctx.config.api_client,
    parameters: SetMessageReactionParameters(
      chat_id: IntValue(chat_id),
      message_id:,
      reaction:,
      is_big:,
    ),
  )
}

fn get_message_id(update: Update) -> Option(Int) {
  case update {
    update.TextUpdate(message:, ..) -> Some(message.message_id)
    update.CommandUpdate(message:, ..) -> Some(message.message_id)
    update.PhotoUpdate(message:, ..) -> Some(message.message_id)
    update.VideoUpdate(message:, ..) -> Some(message.message_id)
    update.AudioUpdate(message:, ..) -> Some(message.message_id)
    update.VoiceUpdate(message:, ..) -> Some(message.message_id)
    update.MediaGroupUpdate(..) -> None
    update.WebAppUpdate(message:, ..) -> Some(message.message_id)
    update.MessageUpdate(message:, ..) -> Some(message.message_id)
    update.ChannelPostUpdate(post:, ..) -> Some(post.message_id)
    update.EditedMessageUpdate(message:, ..) -> Some(message.message_id)
    update.EditedChannelPostUpdate(post:, ..) -> Some(post.message_id)
    update.BusinessMessageUpdate(message:, ..) -> Some(message.message_id)
    update.EditedBusinessMessageUpdate(message:, ..) -> Some(message.message_id)
    update.MessageReactionUpdate(message_reaction_updated:, ..) ->
      Some(message_reaction_updated.message_id)
    update.MessageReactionCountUpdate(message_reaction_count_updated:, ..) ->
      Some(message_reaction_count_updated.message_id)
    update.CallbackQueryUpdate(query:, ..) ->
      case query.message {
        Some(types.MessageMaybeInaccessibleMessage(msg)) -> Some(msg.message_id)
        Some(types.InaccessibleMessageMaybeInaccessibleMessage(msg)) ->
          Some(msg.message_id)
        None -> None
      }
    // These update types don't have a message_id
    update.BusinessConnectionUpdate(..) -> None
    update.DeletedBusinessMessageUpdate(..) -> None
    update.InlineQueryUpdate(..) -> None
    update.ChosenInlineResultUpdate(..) -> None
    update.ShippingQueryUpdate(..) -> None
    update.PreCheckoutQueryUpdate(..) -> None
    update.PaidMediaPurchaseUpdate(..) -> None
    update.PollUpdate(..) -> None
    update.PollAnswerUpdate(..) -> None
    update.MyChatMemberUpdate(..) -> None
    update.ChatMemberUpdate(..) -> None
    update.ChatJoinRequestUpdate(..) -> None
    update.RemovedChatBoost(..) -> None
  }
}

import gleam/int
