import gleam/json
import gleam/option.{Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot.{type Context, Context}
import telega/error.{type TelegaError}
import telega/model/encoder
import telega/model/types
import telega/reply
import telega/testing/context as test_context
import telega/testing/factory
import telega/testing/mock

pub fn main() {
  gleeunit.main()
}

fn paid_photo(media media: String) -> types.InputPaidMedia {
  types.InputPaidMediaPhotoInputPaidMedia(types.InputPaidMediaPhoto(
    type_: "photo",
    media:,
  ))
}

fn ctx_with_client(client) -> Context(String, TelegaError, Nil) {
  let base: Context(String, TelegaError, Nil) =
    test_context.context_with(
      session: "initial",
      update: factory.text_update_with(text: "hi", from_id: 123, chat_id: 456),
    )
  Context(..base, config: test_context.config_with_client(client))
}

// Encoder ------------------------------------------------------------------------------------------------------------

pub fn encode_minimal_parameters_test() {
  types.new_send_paid_media_parameters(
    chat_id: types.Int(123),
    star_count: 10,
    media: [paid_photo(media: "https://example.com/photo.jpg")],
  )
  |> encoder.encode_send_paid_media_parameters
  |> json.to_string
  |> should.equal(
    "{\"chat_id\":123,\"star_count\":10,\"media\":[{\"type\":\"photo\",\"media\":\"https://example.com/photo.jpg\"}]}",
  )
}

pub fn encode_with_options_test() {
  let params =
    types.SendPaidMediaParameters(
      ..types.new_send_paid_media_parameters(
        chat_id: types.Str("@channel"),
        star_count: 50,
        media: [paid_photo(media: "file_id_1")],
      ),
      payload: Some("internal:1"),
      caption: Some("Unlock me"),
      parse_mode: Some("HTML"),
      show_caption_above_media: Some(True),
    )

  params
  |> encoder.encode_send_paid_media_parameters
  |> json.to_string
  |> should.equal(
    "{\"chat_id\":\"@channel\",\"star_count\":50,\"media\":[{\"type\":\"photo\",\"media\":\"file_id_1\"}],\"payload\":\"internal:1\",\"caption\":\"Unlock me\",\"parse_mode\":\"HTML\",\"show_caption_above_media\":true}",
  )
}

pub fn encode_media_array_test() {
  let video =
    types.InputPaidMediaVideoInputPaidMedia(types.InputPaidMediaVideo(
      type_: "video",
      media: "video_file_id",
      thumbnail: option.None,
      cover: option.None,
      start_timestamp: option.None,
      width: option.None,
      height: option.None,
      duration: option.None,
      supports_streaming: option.None,
    ))

  let encoded =
    types.new_send_paid_media_parameters(
      chat_id: types.Int(1),
      star_count: 1,
      media: [paid_photo(media: "photo_file_id"), video],
    )
    |> encoder.encode_send_paid_media_parameters
    |> json.to_string

  encoded
  |> string.contains(
    "\"media\":[{\"type\":\"photo\",\"media\":\"photo_file_id\"},{\"type\":\"video\",\"media\":\"video_file_id\"}]",
  )
  |> should.be_true()
}

// reply.with_paid_media ------------------------------------------------------------------------------------------------

pub fn with_paid_media_calls_send_paid_media_test() {
  let #(client, calls) = mock.message_client()
  let ctx = ctx_with_client(client)

  reply.with_paid_media(ctx, star_count: 10, media: [
    paid_photo(media: "https://example.com/photo.jpg"),
  ])
  |> should.be_ok()

  let _ =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendPaidMedia",
      body_contains: "\"star_count\":10",
    )
  Nil
}

pub fn with_paid_media_targets_context_chat_test() {
  let #(client, calls) = mock.message_client()
  let ctx = ctx_with_client(client)

  reply.with_paid_media(ctx, star_count: 5, media: [
    paid_photo(media: "file_id_1"),
  ])
  |> should.be_ok()

  let call =
    mock.assert_called_with_body(
      from: calls,
      path_contains: "sendPaidMedia",
      body_contains: "\"chat_id\":\"" <> ctx.key <> "\"",
    )

  call.request.body
  |> string.contains("business_connection_id")
  |> should.be_false()
}
