//// M10 — the wire the API layer actually speaks.
////
//// A wrong method path or a raw `Response(String)` handed back instead of a
//// decoded result both look like success to the caller: the bot silently does
//// nothing and reports `Ok`.

import gleam/erlang/process
import gleam/http/response
import gleam/option.{None}
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
