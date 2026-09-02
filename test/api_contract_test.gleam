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
