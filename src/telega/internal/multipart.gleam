//// `multipart/form-data` body encoding for raw file uploads.
////
//// Telegram accepts a photo either as a plain string (a `file_id` or URL, sent
//// as JSON) or as attached bytes — and the bytes case is `multipart/form-data`,
//// which the JSON transport cannot express. This module builds that body as a
//// `BitArray` so it can ride the same client/queue path as every other call
//// (`client.fetch_multipart`); it does no IO of its own.

import gleam/bit_array
import gleam/list
import gleam/string

import telega/internal/utils

/// A single multipart part: a plain text field, or an attached file with its
/// own filename and content type.
pub type Part {
  FieldPart(name: String, value: String)
  FilePart(
    name: String,
    filename: String,
    content_type: String,
    content: BitArray,
  )
}

/// A fresh boundary for one body.
///
/// The boundary must not occur inside any part's bytes. A fixed one is a bet
/// that no uploaded file ever contains that exact string; a random one per
/// body makes the question moot.
pub fn new_boundary() -> String {
  "----telegaFormBoundary" <> utils.random_string(24)
}

/// The `Content-Type` header value that pairs with `encode` for `boundary`.
pub fn content_type_header(boundary: String) -> String {
  "multipart/form-data; boundary=" <> boundary
}

/// Encode `parts` into a `multipart/form-data` body delimited by `boundary`.
pub fn encode(boundary: String, parts: List(Part)) -> BitArray {
  let body =
    parts
    |> list.map(encode_part(boundary, _))
    |> bit_array.concat

  bit_array.concat([body, str("--" <> boundary <> "--\r\n")])
}

fn encode_part(boundary: String, part: Part) -> BitArray {
  case part {
    FieldPart(name:, value:) ->
      bit_array.concat([
        str("--" <> boundary <> "\r\n"),
        str(
          "Content-Disposition: form-data; name=\""
          <> header_safe(name)
          <> "\"\r\n\r\n",
        ),
        str(value),
        str("\r\n"),
      ])
    FilePart(name:, filename:, content_type:, content:) ->
      bit_array.concat([
        str("--" <> boundary <> "\r\n"),
        str(
          "Content-Disposition: form-data; name=\""
          <> header_safe(name)
          <> "\"; filename=\""
          <> header_safe(filename)
          <> "\"\r\n",
        ),
        str("Content-Type: " <> header_safe(content_type) <> "\r\n\r\n"),
        content,
        str("\r\n"),
      ])
  }
}

fn str(value: String) -> BitArray {
  bit_array.from_string(value)
}

/// Strip what would let a value break out of its quoted header: a `"` ends the
/// quoted string, and a CR or LF ends the header line — enough to append
/// headers, or a whole extra part, from a filename.
///
/// Filtered grapheme by grapheme rather than with `string.replace`: on Erlang
/// that matches whole grapheme clusters, and CRLF is *one* cluster, so
/// replacing `"\r"` alone leaves every `\r\n` untouched.
fn header_safe(value: String) -> String {
  value
  |> string.to_graphemes
  |> list.filter_map(fn(grapheme) {
    case grapheme {
      "\"" -> Ok("'")
      "\r" | "\n" | "\r\n" -> Error(Nil)
      _ -> Ok(grapheme)
    }
  })
  |> string.concat
}
