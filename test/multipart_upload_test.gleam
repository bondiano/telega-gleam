//// Tests for the raw-bytes photo upload path (`multipart/form-data`): the
//// encoder shape, and that `api.send_photo_bytes` posts a multipart body via
//// the bits client and decodes the returned `file_id`.

import gleam/bit_array
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/option.{None, Some}
import gleam/string
import gleeunit/should

import telega/api
import telega/client
import telega/error
import telega/internal/multipart
import telega/model/types

const message_with_photo = "{\"ok\":true,\"result\":{\"message_id\":7,\"date\":0,\"chat\":{\"id\":123,\"type\":\"private\"},\"photo\":[{\"file_id\":\"MINTED_FILE_ID\",\"file_unique_id\":\"u1\",\"width\":90,\"height\":90}]}}"

pub fn multipart_encode_shape_test() {
  let boundary = multipart.new_boundary()
  let body =
    multipart.encode(boundary, [
      multipart.FieldPart(name: "chat_id", value: "123"),
      multipart.FieldPart(name: "caption", value: "hi"),
      multipart.FilePart(
        name: "photo",
        filename: "cat.png",
        content_type: "image/png",
        content: bit_array.from_string("PNGDATA"),
      ),
    ])
  let assert Ok(text) = bit_array.to_string(body)

  string.contains(text, boundary) |> should.be_true
  string.contains(text, "name=\"chat_id\"") |> should.be_true
  string.contains(text, "name=\"photo\"; filename=\"cat.png\"")
  |> should.be_true
  string.contains(text, "Content-Type: image/png") |> should.be_true
  // Closing delimiter is the boundary with a trailing "--".
  string.contains(text, "--" <> boundary <> "--") |> should.be_true
}

pub fn send_photo_bytes_uploads_and_decodes_file_id_test() {
  let captured = process.new_subject()
  let bits_client = fn(req: request.Request(BitArray)) {
    process.send(captured, req)
    Ok(response.Response(
      status: 200,
      headers: [],
      body: bit_array.from_string(message_with_photo),
    ))
  }
  let client =
    client.new(token: "T", fetch_client: json_should_not_be_used)
    |> client.set_fetch_bits_client(bits_client)

  let assert Ok(message) =
    api.send_photo_bytes(
      client,
      chat_id: "123",
      content: <<1, 2, 3, 4>>,
      filename: "cat.png",
      content_type: "image/png",
      caption: Some("hi"),
      parse_mode: None,
    )

  // The minted file_id round-trips out of the decoded response.
  let assert Some([photo, ..]) = message.photo
  photo.file_id |> should.equal("MINTED_FILE_ID")

  // The request went out as multipart to sendPhoto, carrying the bytes.
  let assert Ok(req) = process.receive(captured, 100)
  req.method |> should.equal(http.Post)
  string.ends_with(req.path, "/sendPhoto") |> should.be_true
  let assert Ok(content_type) = request.get_header(req, "content-type")
  string.starts_with(
    content_type,
    "multipart/form-data; boundary=----telegaFormBoundary",
  )
  |> should.be_true
}

/// Bot API 10.3: the byte-upload sibling of an ephemeral `sendPhoto` carries
/// the nested parameters as a JSON-serialized form field.
pub fn send_ephemeral_photo_bytes_carries_parameters_test() {
  let captured = process.new_subject()
  let bits_client = fn(req: request.Request(BitArray)) {
    process.send(captured, req)
    Ok(response.Response(
      status: 200,
      headers: [],
      body: bit_array.from_string(message_with_photo),
    ))
  }
  let client =
    client.new(token: "T", fetch_client: json_should_not_be_used)
    |> client.set_fetch_bits_client(bits_client)

  let assert Ok(_) =
    api.send_ephemeral_photo_bytes(
      client,
      chat_id: "-100500",
      content: <<1, 2, 3, 4>>,
      filename: "cat.png",
      content_type: "image/png",
      caption: None,
      parse_mode: None,
      ephemeral: types.EphemeralMessageParameters(
        ..types.new_ephemeral_message_parameters(receiver_user_id: 777),
        callback_query_id: Some("q1"),
      ),
    )

  let assert Ok(req) = process.receive(captured, 100)
  let assert Ok(text) = bit_array.to_string(req.body)
  string.ends_with(req.path, "/sendPhoto") |> should.be_true
  string.contains(text, "name=\"ephemeral_message_parameters\"")
  |> should.be_true
  string.contains(
    text,
    "{\"receiver_user_id\":777,\"callback_query_id\":\"q1\"}",
  )
  |> should.be_true
}

fn json_should_not_be_used(
  _req: request.Request(String),
) -> Result(response.Response(String), error.TelegaError) {
  Error(error.FetchError("the bytes upload must not use the JSON client"))
}

// M10 — the encoder must not let a filename write headers -------------------

pub fn filename_cannot_inject_headers_test() {
  let boundary = multipart.new_boundary()
  let body =
    multipart.encode(boundary, [
      multipart.FilePart(
        name: "photo",
        filename: "a\"\r\nContent-Type: text/html\r\n\r\n<script>.png",
        content_type: "image/png",
        content: bit_array.from_string("PNGDATA"),
      ),
    ])
  let assert Ok(text) = bit_array.to_string(body)

  // A CR/LF in the filename would end the Content-Disposition line and let
  // the caller append headers (or a whole extra part) of its own. Stripped,
  // the text survives only as part of the quoted filename.
  string.contains(text, "Content-Type: text/html\r\n") |> should.be_false
  string.contains(
    text,
    "name=\"photo\"; filename=\"a'Content-Type: text/html<script>.png\"",
  )
  |> should.be_true
}

pub fn field_name_cannot_inject_headers_test() {
  let boundary = multipart.new_boundary()
  let body =
    multipart.encode(boundary, [
      multipart.FieldPart(name: "chat_id\"\r\nX-Evil: 1", value: "123"),
    ])
  let assert Ok(text) = bit_array.to_string(body)

  string.contains(text, "X-Evil: 1\r\n") |> should.be_false
}

pub fn boundary_differs_per_body_test() {
  // A fixed boundary that happens to occur in an uploaded file corrupts the
  // body; a fresh one per upload makes that a non-issue.
  multipart.new_boundary()
  |> should.not_equal(multipart.new_boundary())
}

pub fn transformers_see_multipart_uploads_test() {
  let seen = process.new_subject()
  let bits_client = fn(_req: request.Request(BitArray)) {
    process.send(seen, "uploaded")
    Ok(response.Response(
      status: 200,
      headers: [],
      body: bit_array.from_string(message_with_photo),
    ))
  }
  let tg_client =
    client.new(token: "T", fetch_client: json_should_not_be_used)
    |> client.set_fetch_bits_client(bits_client)
    |> client.use_transformer(fn(req, next) {
      process.send(seen, "transformer:" <> client.request_method(req))
      next(req)
    })

  let assert Ok(_) =
    api.send_photo_bytes(
      tg_client,
      chat_id: "123",
      content: <<1, 2>>,
      filename: "cat.png",
      content_type: "image/png",
      caption: None,
      parse_mode: None,
    )

  // An upload is an API call like any other: a logging, auth or short-circuit
  // transformer must not be skipped just because the body is binary.
  process.receive(seen, 100) |> should.equal(Ok("transformer:sendPhoto"))
  process.receive(seen, 100) |> should.equal(Ok("uploaded"))
}

pub fn a_transformer_can_short_circuit_an_upload_test() {
  let calls = process.new_subject()
  let bits_client = fn(_req: request.Request(BitArray)) {
    process.send(calls, "uploaded")
    Ok(response.Response(
      status: 200,
      headers: [],
      body: bit_array.from_string(message_with_photo),
    ))
  }
  let tg_client =
    client.new(token: "T", fetch_client: json_should_not_be_used)
    |> client.set_fetch_bits_client(bits_client)
    |> client.use_transformer(fn(_req, _next) {
      Error(error.FetchError("blocked by transformer"))
    })

  api.send_photo_bytes(
    tg_client,
    chat_id: "123",
    content: <<1, 2>>,
    filename: "cat.png",
    content_type: "image/png",
    caption: None,
    parse_mode: None,
  )
  |> should.be_error()

  process.receive(calls, 100) |> should.equal(Error(Nil))
}
