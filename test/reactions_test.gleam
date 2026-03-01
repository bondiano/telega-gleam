import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import telega/model/types
import telega/reactions

pub fn main() {
  gleeunit.main()
}

// ============================================
// Reaction constructor tests
// ============================================

pub fn emoji_creates_correct_reaction_type_test() {
  let reaction = reactions.emoji("👍")

  case reaction {
    types.ReactionTypeEmojiReactionType(inner) -> {
      inner.emoji |> should.equal("👍")
      inner.type_ |> should.equal("emoji")
    }
    _ -> should.fail()
  }
}

pub fn custom_emoji_creates_correct_reaction_type_test() {
  let reaction = reactions.custom_emoji("123456789")

  case reaction {
    types.ReactionTypeCustomEmojiReactionType(inner) -> {
      inner.custom_emoji_id |> should.equal("123456789")
      inner.type_ |> should.equal("custom_emoji")
    }
    _ -> should.fail()
  }
}

pub fn paid_creates_correct_reaction_type_test() {
  let reaction = reactions.paid()

  case reaction {
    types.ReactionTypePaidReactionType(inner) -> {
      inner.type_ |> should.equal("paid")
    }
    _ -> should.fail()
  }
}

// ============================================
// Preset constants tests
// ============================================

pub fn thumbs_up_constant_is_correct_test() {
  case reactions.thumbs_up {
    types.ReactionTypeEmojiReactionType(inner) -> {
      inner.emoji |> should.equal("👍")
    }
    _ -> should.fail()
  }
}

pub fn heart_constant_is_correct_test() {
  case reactions.heart {
    types.ReactionTypeEmojiReactionType(inner) -> {
      inner.emoji |> should.equal("❤")
    }
    _ -> should.fail()
  }
}

pub fn fire_constant_is_correct_test() {
  case reactions.fire {
    types.ReactionTypeEmojiReactionType(inner) -> {
      inner.emoji |> should.equal("🔥")
    }
    _ -> should.fail()
  }
}

// ============================================
// Reaction type helper tests
// ============================================

pub fn get_emoji_returns_emoji_for_emoji_reaction_test() {
  let reaction = reactions.emoji("👍")
  reactions.get_emoji(reaction) |> should.equal(Some("👍"))
}

pub fn get_emoji_returns_none_for_custom_emoji_test() {
  let reaction = reactions.custom_emoji("12345")
  reactions.get_emoji(reaction) |> should.equal(None)
}

pub fn get_emoji_returns_none_for_paid_reaction_test() {
  let reaction = reactions.paid()
  reactions.get_emoji(reaction) |> should.equal(None)
}

pub fn get_custom_emoji_id_returns_id_for_custom_emoji_test() {
  let reaction = reactions.custom_emoji("12345")
  reactions.get_custom_emoji_id(reaction) |> should.equal(Some("12345"))
}

pub fn get_custom_emoji_id_returns_none_for_emoji_test() {
  let reaction = reactions.emoji("👍")
  reactions.get_custom_emoji_id(reaction) |> should.equal(None)
}

pub fn is_paid_returns_true_for_paid_reaction_test() {
  let reaction = reactions.paid()
  reactions.is_paid(reaction) |> should.be_true()
}

pub fn is_paid_returns_false_for_emoji_reaction_test() {
  let reaction = reactions.emoji("👍")
  reactions.is_paid(reaction) |> should.be_false()
}

pub fn is_emoji_returns_true_for_emoji_reaction_test() {
  let reaction = reactions.emoji("👍")
  reactions.is_emoji(reaction) |> should.be_true()
}

pub fn is_emoji_returns_false_for_paid_reaction_test() {
  let reaction = reactions.paid()
  reactions.is_emoji(reaction) |> should.be_false()
}

pub fn is_custom_emoji_returns_true_for_custom_emoji_test() {
  let reaction = reactions.custom_emoji("12345")
  reactions.is_custom_emoji(reaction) |> should.be_true()
}

pub fn is_custom_emoji_returns_false_for_emoji_test() {
  let reaction = reactions.emoji("👍")
  reactions.is_custom_emoji(reaction) |> should.be_false()
}

pub fn reaction_equals_returns_true_for_same_emoji_test() {
  let r1 = reactions.emoji("👍")
  let r2 = reactions.emoji("👍")
  reactions.reaction_equals(r1, r2) |> should.be_true()
}

pub fn reaction_equals_returns_false_for_different_emoji_test() {
  let r1 = reactions.emoji("👍")
  let r2 = reactions.emoji("❤")
  reactions.reaction_equals(r1, r2) |> should.be_false()
}

pub fn reaction_equals_returns_true_for_same_custom_emoji_test() {
  let r1 = reactions.custom_emoji("12345")
  let r2 = reactions.custom_emoji("12345")
  reactions.reaction_equals(r1, r2) |> should.be_true()
}

pub fn reaction_equals_returns_false_for_different_custom_emoji_test() {
  let r1 = reactions.custom_emoji("12345")
  let r2 = reactions.custom_emoji("67890")
  reactions.reaction_equals(r1, r2) |> should.be_false()
}

pub fn reaction_equals_returns_true_for_paid_reactions_test() {
  let r1 = reactions.paid()
  let r2 = reactions.paid()
  reactions.reaction_equals(r1, r2) |> should.be_true()
}

pub fn reaction_equals_returns_false_for_different_types_test() {
  let r1 = reactions.emoji("👍")
  let r2 = reactions.paid()
  reactions.reaction_equals(r1, r2) |> should.be_false()
}

pub fn matches_emoji_returns_true_for_matching_emoji_test() {
  let reaction = reactions.emoji("👍")
  reactions.matches_emoji(reaction, "👍") |> should.be_true()
}

pub fn matches_emoji_returns_false_for_non_matching_emoji_test() {
  let reaction = reactions.emoji("👍")
  reactions.matches_emoji(reaction, "❤") |> should.be_false()
}

pub fn matches_emoji_returns_false_for_non_emoji_reaction_test() {
  let reaction = reactions.paid()
  reactions.matches_emoji(reaction, "👍") |> should.be_false()
}

// ============================================
// Reaction changes tests
// ============================================

fn test_chat() -> types.Chat {
  types.Chat(
    id: 123,
    type_: "private",
    title: None,
    username: None,
    first_name: Some("Test"),
    last_name: None,
    is_forum: None,
    is_direct_messages: None,
  )
}

fn test_message_reaction_updated(
  old_reaction: List(types.ReactionType),
  new_reaction: List(types.ReactionType),
) -> types.MessageReactionUpdated {
  types.MessageReactionUpdated(
    chat: test_chat(),
    message_id: 1,
    user: None,
    actor_chat: None,
    date: 1_234_567_890,
    old_reaction:,
    new_reaction:,
  )
}

pub fn get_changes_detects_added_reactions_test() {
  let update = test_message_reaction_updated([], [reactions.thumbs_up])

  let changes = reactions.get_changes(update)

  changes.added |> should.equal([reactions.thumbs_up])
  changes.removed |> should.equal([])
  changes.kept |> should.equal([])
}

pub fn get_changes_detects_removed_reactions_test() {
  let update = test_message_reaction_updated([reactions.thumbs_up], [])

  let changes = reactions.get_changes(update)

  changes.added |> should.equal([])
  changes.removed |> should.equal([reactions.thumbs_up])
  changes.kept |> should.equal([])
}

pub fn get_changes_detects_kept_reactions_test() {
  let update =
    test_message_reaction_updated([reactions.thumbs_up], [reactions.thumbs_up])

  let changes = reactions.get_changes(update)

  changes.added |> should.equal([])
  changes.removed |> should.equal([])
  changes.kept |> should.equal([reactions.thumbs_up])
}

pub fn get_changes_handles_complex_scenario_test() {
  let update =
    test_message_reaction_updated([reactions.thumbs_up, reactions.heart], [
      reactions.heart,
      reactions.fire,
    ])

  let changes = reactions.get_changes(update)

  // fire was added
  changes.added |> should.equal([reactions.fire])
  // thumbs_up was removed
  changes.removed |> should.equal([reactions.thumbs_up])
  // heart was kept
  changes.kept |> should.equal([reactions.heart])
}

pub fn was_added_returns_true_when_emoji_was_added_test() {
  let update = test_message_reaction_updated([], [reactions.thumbs_up])

  reactions.was_added(update, "👍") |> should.be_true()
}

pub fn was_added_returns_false_when_emoji_was_not_added_test() {
  let update = test_message_reaction_updated([], [reactions.thumbs_up])

  reactions.was_added(update, "❤") |> should.be_false()
}

pub fn was_removed_returns_true_when_emoji_was_removed_test() {
  let update = test_message_reaction_updated([reactions.thumbs_up], [])

  reactions.was_removed(update, "👍") |> should.be_true()
}

pub fn was_removed_returns_false_when_emoji_was_not_removed_test() {
  let update = test_message_reaction_updated([reactions.thumbs_up], [])

  reactions.was_removed(update, "❤") |> should.be_false()
}

pub fn has_added_returns_true_when_reactions_were_added_test() {
  let update = test_message_reaction_updated([], [reactions.thumbs_up])

  reactions.has_added(update) |> should.be_true()
}

pub fn has_added_returns_false_when_no_reactions_were_added_test() {
  let update = test_message_reaction_updated([reactions.thumbs_up], [])

  reactions.has_added(update) |> should.be_false()
}

pub fn has_removed_returns_true_when_reactions_were_removed_test() {
  let update = test_message_reaction_updated([reactions.thumbs_up], [])

  reactions.has_removed(update) |> should.be_true()
}

pub fn has_removed_returns_false_when_no_reactions_were_removed_test() {
  let update = test_message_reaction_updated([], [reactions.thumbs_up])

  reactions.has_removed(update) |> should.be_false()
}

// ============================================
// Reaction count tests
// ============================================

fn test_message_reaction_count_updated(
  reaction_counts: List(types.ReactionCount),
) -> types.MessageReactionCountUpdated {
  types.MessageReactionCountUpdated(
    chat: test_chat(),
    message_id: 1,
    date: 1_234_567_890,
    reactions: reaction_counts,
  )
}

pub fn get_counts_returns_all_counts_test() {
  let update =
    test_message_reaction_count_updated([
      types.ReactionCount(type_: reactions.thumbs_up, total_count: 5),
      types.ReactionCount(type_: reactions.heart, total_count: 3),
    ])

  let counts = reactions.get_counts(update)

  counts
  |> should.equal([
    reactions.ReactionCountInfo(reaction: reactions.thumbs_up, count: 5),
    reactions.ReactionCountInfo(reaction: reactions.heart, count: 3),
  ])
}

pub fn get_total_count_sums_all_counts_test() {
  let update =
    test_message_reaction_count_updated([
      types.ReactionCount(type_: reactions.thumbs_up, total_count: 5),
      types.ReactionCount(type_: reactions.heart, total_count: 3),
    ])

  reactions.get_total_count(update) |> should.equal(8)
}

pub fn get_emoji_count_returns_correct_count_test() {
  let update =
    test_message_reaction_count_updated([
      types.ReactionCount(type_: reactions.thumbs_up, total_count: 5),
      types.ReactionCount(type_: reactions.heart, total_count: 3),
    ])

  reactions.get_emoji_count(update, "👍") |> should.equal(5)
  reactions.get_emoji_count(update, "❤") |> should.equal(3)
  reactions.get_emoji_count(update, "🔥") |> should.equal(0)
}

pub fn get_top_reactions_returns_sorted_by_count_test() {
  let update =
    test_message_reaction_count_updated([
      types.ReactionCount(type_: reactions.thumbs_up, total_count: 5),
      types.ReactionCount(type_: reactions.heart, total_count: 10),
      types.ReactionCount(type_: reactions.fire, total_count: 3),
    ])

  let top = reactions.get_top_reactions(update, 2)

  top
  |> should.equal([
    reactions.ReactionCountInfo(reaction: reactions.heart, count: 10),
    reactions.ReactionCountInfo(reaction: reactions.thumbs_up, count: 5),
  ])
}
