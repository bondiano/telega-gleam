//// M10 — the wire the API layer actually speaks.
////
//// A wrong method path or a raw `Response(String)` handed back instead of a
//// decoded result both look like success to the caller: the bot silently does
//// nothing and reports `Ok`.

import gleam/erlang/process
import gleam/http/response
import gleam/option.{None, Some}
import gleeunit/should

import telega/api
import telega/client
import telega/error
import telega/model/types

fn recording_client(body: String) -> #(client.TelegramClient, fn() -> String) {
  let calls = process.new_subject()
  let client =
    client.new(token: "test-token", fetch_client: fn(req) {
      process.send(calls, req.path)
      Ok(response.Response(status: 200, headers: [], body:))
    })
    |> client.set_max_retry_attempts(0)
  #(client, fn() {
    let assert Ok(path) = process.receive(calls, 100)
    path
  })
}

pub fn gift_premium_uses_the_documented_path_test() {
  let #(client, last_path) =
    recording_client("{\"ok\": true, \"result\": true}")

  let assert Ok(True) =
    api.gift_premium(
      client:,
      parameters: types.GiftPremiumSubscriptionParameters(
        user_id: 1,
        month_count: 3,
        star_count: 1000,
        text: None,
        text_parse_mode: None,
        text_entities: None,
      ),
    )

  last_path() |> should.equal("/bottest-token/giftPremiumSubscription")
}

pub fn send_audio_reports_an_api_error_test() {
  let #(client, _) =
    recording_client(
      "{\"ok\": false, \"error_code\": 400, \"description\": \"Bad Request: chat not found\"}",
    )

  // `ok: false` with a 200 status is how Telegram reports a failure. Handing
  // the raw response back made it indistinguishable from a sent message.
  api.send_audio(
    client:,
    parameters: types.SendAudioParameters(
      chat_id: types.Int(1),
      business_connection_id: None,
      message_thread_id: None,
      audio: types.StringV("audio-file-id"),
      caption: None,
      parse_mode: None,
      caption_entities: None,
      duration: None,
      performer: None,
      title: None,
      thumbnail: None,
      disable_notification: None,
      protect_content: None,
      allow_paid_broadcast: None,
      message_effect_id: None,
      reply_parameters: None,
      reply_markup: None,
      ephemeral_message_parameters: None,
      direct_messages_topic_id: None,
      suggested_post_parameters: None,
    ),
  )
  |> should.equal(
    Error(error.TelegramApiError(
      error_code: 400,
      description: "Bad Request: chat not found",
      parameters: None,
    )),
  )
}

pub fn approve_chat_join_request_reports_an_api_error_test() {
  let #(client, _) =
    recording_client(
      "{\"ok\": false, \"error_code\": 400, \"description\": \"Bad Request: user not found\"}",
    )

  api.approve_chat_join_request(
    client:,
    parameters: types.ApproveChatJoinRequestParameters(
      chat_id: types.Int(1),
      user_id: 2,
    ),
  )
  |> should.equal(
    Error(error.TelegramApiError(
      error_code: 400,
      description: "Bad Request: user not found",
      parameters: None,
    )),
  )
}

// The methods that were simply missing ---------------------------------------

pub fn newly_wired_methods_hit_their_paths_test() {
  let #(client, last_path) =
    recording_client("{\"ok\": true, \"result\": true}")

  let assert Ok(True) =
    api.set_user_emoji_status(
      client:,
      parameters: types.new_set_user_emoji_status_parameters(user_id: 1),
    )
  last_path() |> should.equal("/bottest-token/setUserEmojiStatus")

  let assert Ok(True) =
    api.set_passport_data_errors(
      client:,
      parameters: types.SetPassportDataErrorsParameters(user_id: 1, errors: []),
    )
  last_path() |> should.equal("/bottest-token/setPassportDataErrors")

  let assert Ok(True) =
    api.approve_suggested_post(
      client:,
      parameters: types.new_approve_suggested_post_parameters(
        chat_id: 1,
        message_id: 2,
      ),
    )
  last_path() |> should.equal("/bottest-token/approveSuggestedPost")

  let assert Ok(True) =
    api.decline_suggested_post(
      client:,
      parameters: types.new_decline_suggested_post_parameters(
        chat_id: 1,
        message_id: 2,
      ),
    )
  last_path() |> should.equal("/bottest-token/declineSuggestedPost")
}

pub fn get_my_star_balance_decodes_the_balance_test() {
  let #(client, last_path) =
    recording_client(
      "{\"ok\": true, \"result\": {\"amount\": 42, \"nanostar_amount\": 500000000}}",
    )

  api.get_my_star_balance(client)
  |> should.equal(
    Ok(types.StarAmount(amount: 42, nanostar_amount: Some(500_000_000))),
  )

  last_path() |> should.equal("/bottest-token/getMyStarBalance")
}

pub fn every_spec_method_reachable_test() {
  let #(client, last_path) =
    recording_client("{\"ok\": true, \"result\": true}")

  let assert Ok(True) =
    api.set_chat_member_tag(
      client:,
      parameters: types.new_set_chat_member_tag_parameters(
        chat_id: types.Int(-100),
        user_id: 5,
      ),
    )
  last_path() |> should.equal("/bottest-token/setChatMemberTag")
}

pub fn copy_message_decodes_a_message_id_test() {
  let #(client, last_path) =
    recording_client("{\"ok\": true, \"result\": {\"message_id\": 42}}")

  api.copy_message(
    client:,
    parameters: types.CopyMessageParameters(
      chat_id: types.Int(1),
      message_thread_id: None,
      from_chat_id: types.Int(2),
      message_id: 3,
      video_start_timestamp: None,
      caption: None,
      parse_mode: None,
      caption_entities: None,
      show_caption_above_media: None,
      disable_notification: None,
      protect_content: None,
      allow_paid_broadcast: None,
      reply_parameters: None,
      reply_markup: None,
      direct_messages_topic_id: None,
      message_effect_id: None,
      suggested_post_parameters: None,
    ),
  )
  |> should.equal(Ok(types.MessageId(message_id: 42)))

  last_path() |> should.equal("/bottest-token/copyMessage")
}

pub fn copy_messages_decodes_message_ids_test() {
  let #(client, last_path) =
    recording_client(
      "{\"ok\": true, \"result\": [{\"message_id\": 42}, {\"message_id\": 43}]}",
    )

  api.copy_messages(
    client:,
    parameters: types.CopyMessagesParameters(
      chat_id: types.Int(1),
      message_thread_id: None,
      from_chat_id: types.Int(2),
      message_ids: [3, 4],
      disable_notification: None,
      protect_content: None,
      remove_caption: None,
      direct_messages_topic_id: None,
    ),
  )
  |> should.equal(
    Ok([types.MessageId(message_id: 42), types.MessageId(message_id: 43)]),
  )

  last_path() |> should.equal("/bottest-token/copyMessages")
}

pub fn forward_messages_decodes_message_ids_test() {
  let #(client, last_path) =
    recording_client("{\"ok\": true, \"result\": [{\"message_id\": 42}]}")

  api.forward_messages(
    client:,
    parameters: types.ForwardMessagesParameters(
      chat_id: types.Int(1),
      message_thread_id: None,
      from_chat_id: types.Int(2),
      message_ids: [3],
      disable_notification: None,
      protect_content: None,
      direct_messages_topic_id: None,
    ),
  )
  |> should.equal(Ok([types.MessageId(message_id: 42)]))

  last_path() |> should.equal("/bottest-token/forwardMessages")
}

pub fn get_custom_emoji_stickers_decodes_an_array_test() {
  let #(client, last_path) =
    recording_client(
      "{\"ok\": true, \"result\": [{\"file_id\": \"file\", \"file_unique_id\": \"unique\", \"type\": \"custom_emoji\", \"width\": 1, \"height\": 1, \"is_animated\": false, \"is_video\": false}]}",
    )

  let assert Ok([sticker]) =
    api.get_custom_emoji_stickers(
      client:,
      parameters: types.GetCustomEmojiStickersParameters(custom_emoji_ids: [
        "emoji",
      ]),
    )

  sticker.file_id |> should.equal("file")
  last_path() |> should.equal("/bottest-token/getCustomEmojiStickers")
}

pub fn get_game_high_scores_decodes_an_array_test() {
  let #(client, last_path) =
    recording_client(
      "{\"ok\": true, \"result\": [{\"position\": 1, \"user\": {\"id\": 1, \"is_bot\": false, \"first_name\": \"U\"}, \"score\": 10}]}",
    )

  let assert Ok([score]) =
    api.get_game_high_scores(
      client:,
      parameters: types.GetGameHighScoresParameters(
        user_id: 1,
        chat_id: None,
        message_id: None,
        inline_message_id: None,
      ),
    )

  score.position |> should.equal(1)
  last_path() |> should.equal("/bottest-token/getGameHighScores")
}

pub fn send_message_draft_decodes_true_test() {
  let #(client, last_path) =
    recording_client("{\"ok\": true, \"result\": true}")

  api.send_message_draft(
    client:,
    parameters: types.SendMessageDraftParameters(
      chat_id: 1,
      draft_id: 2,
      text: "partial",
      message_thread_id: None,
      parse_mode: None,
      entities: None,
      can_stop: None,
      keep_on_stop: None,
    ),
  )
  |> should.equal(Ok(True))

  last_path() |> should.equal("/bottest-token/sendMessageDraft")
}

pub fn managed_bot_token_decodes_a_bare_string_test() {
  let #(client, last_path) =
    recording_client("{\"ok\": true, \"result\": \"123:ABC\"}")

  api.get_managed_bot_token(
    client:,
    parameters: types.ManagedBotTokenParameters(user_id: 5),
  )
  |> should.equal(Ok("123:ABC"))

  last_path() |> should.equal("/bottest-token/getManagedBotToken")
}
