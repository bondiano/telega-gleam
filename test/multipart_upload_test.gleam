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

const message_with_photo = "{\"ok\":true,\"result\":{\"message_id\":7,\"date\":0,\"chat\":{\"id\":123,\"type\":\"private\"},\"photo\":[{\"file_id\":\"MINTED_FILE_ID\",\"file_unique_id\":\"u1\",\"width\":90,\"height\":90}]}}"

pub fn multipart_encode_shape_test() {
  let body =
    multipart.encode([
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

  string.contains(text, multipart.boundary) |> should.be_true
  string.contains(text, "name=\"chat_id\"") |> should.be_true
  string.contains(text, "name=\"photo\"; filename=\"cat.png\"")
  |> should.be_true
  string.contains(text, "Content-Type: image/png") |> should.be_true
  // Closing delimiter is the boundary with a trailing "--".
  string.contains(text, "--" <> multipart.boundary <> "--") |> should.be_true
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
  request.get_header(req, "content-type")
  |> should.equal(Ok(multipart.content_type_header()))
}

fn json_should_not_be_used(
  _req: request.Request(String),
) -> Result(response.Response(String), error.TelegaError) {
  Error(error.FetchError("the bytes upload must not use the JSON client"))
}
