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

/// A fixed boundary. It only needs to not occur inside any part's bytes;
/// for the image/JSON payloads Telegram uploads that is not a real risk, and
/// a stable value keeps the encoding pure (no RNG).
pub const boundary = "----telegaFormBoundaryX3nK7pQ9wLmZ2vRb"

/// The `Content-Type` header value that pairs with `encode`.
pub fn content_type_header() -> String {
  "multipart/form-data; boundary=" <> boundary
}

/// Encode `parts` into a `multipart/form-data` body delimited by `boundary`.
pub fn encode(parts: List(Part)) -> BitArray {
  let body =
    parts
    |> list.map(encode_part)
    |> bit_array.concat

  bit_array.concat([body, str("--" <> boundary <> "--\r\n")])
}

fn encode_part(part: Part) -> BitArray {
  case part {
    FieldPart(name:, value:) ->
      bit_array.concat([
        str("--" <> boundary <> "\r\n"),
        str("Content-Disposition: form-data; name=\"" <> name <> "\"\r\n\r\n"),
        str(value),
        str("\r\n"),
      ])
    FilePart(name:, filename:, content_type:, content:) ->
      bit_array.concat([
        str("--" <> boundary <> "\r\n"),
        str(
          "Content-Disposition: form-data; name=\""
          <> name
          <> "\"; filename=\""
          <> escape(filename)
          <> "\"\r\n",
        ),
        str("Content-Type: " <> content_type <> "\r\n\r\n"),
        content,
        str("\r\n"),
      ])
  }
}

fn str(value: String) -> BitArray {
  bit_array.from_string(value)
}

/// Escape a `"` in a filename so it cannot break out of the quoted header.
fn escape(filename: String) -> String {
  string.replace(filename, "\"", "'")
}
