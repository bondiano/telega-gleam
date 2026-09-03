//// The retry policy decides whether to replay a failed call from a table
//// generated out of `codegen/api.json`, so the guarantee worth testing is that
//// the table covers the spec and puts the dangerous methods on the right side.

import gleeunit/should

import telega/internal/method_info

pub fn creating_methods_are_not_idempotent_test() {
  [
    "sendMessage", "sendPhoto", "sendMediaGroup", "sendInvoice", "sendGift",
    "forwardMessage", "copyMessage", "createChatInviteLink", "createForumTopic",
    "createInvoiceLink", "uploadStickerFile", "addStickerToSet", "postStory",
    "refundStarPayment", "transferGift", "savePreparedInlineMessage",
    "exportChatInviteLink",
  ]
  |> should_all_be(method_info.is_idempotent, False)
}

pub fn reads_and_updates_are_idempotent_test() {
  [
    "getMe", "getUpdates", "getFile", "getChatMember", "deleteMessage",
    "editMessageText", "editMessageReplyMarkup", "setMessageReaction",
    "answerCallbackQuery", "answerInlineQuery", "setMyCommands", "banChatMember",
    "unpinChatMessage", "stopPoll", "leaveChat",
  ]
  |> should_all_be(method_info.is_idempotent, True)
}

/// Both are `send*`/`answer*` by name and classified against their prefix.
pub fn overrides_win_over_the_name_test() {
  // Repeating a "typing…" costs nothing, and long handlers repeat it on purpose.
  method_info.is_idempotent("sendChatAction") |> should.be_true
  // These answer a query by sending a message, so a replay is a second message.
  method_info.is_idempotent("answerWebAppQuery") |> should.be_false
  method_info.is_idempotent("answerGuestQuery") |> should.be_false
}

/// A method this Bot API version never had — a newer one, or a local API
/// server's own — is not replayed: creating something is the likelier guess.
pub fn unknown_methods_are_not_replayed_test() {
  method_info.lookup_idempotent("sendSomethingFromTheFuture")
  |> should.be_error
  method_info.is_idempotent("sendSomethingFromTheFuture") |> should.be_false
}

/// The whole point of generating the table is that it covers every method the
/// spec has, so a new API version cannot leave one unclassified.
pub fn the_table_covers_the_whole_spec_test() {
  method_info.method_count |> should.equal(185)
  method_info.bot_api_version |> should.equal("Bot API 10.3")
}

fn should_all_be(
  methods: List(String),
  classify: fn(String) -> Bool,
  expected: Bool,
) -> Nil {
  case methods {
    [] -> Nil
    [method, ..rest] -> {
      case classify(method) == expected {
        True -> Nil
        False -> panic as { "wrong idempotency verdict for " <> method }
      }
      should_all_be(rest, classify, expected)
    }
  }
}
