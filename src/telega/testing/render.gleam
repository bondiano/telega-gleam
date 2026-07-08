//// Pure canonicalizers for snapshot testing.
////
//// Turns API-call recordings and keyboard markup into stable, human-readable
//// strings suitable for snapshot libraries like `birdie`. Nothing here depends
//// on a snapshot library — the functions just build strings, so bot authors
//// can use them with any testing setup.
////
//// ```gleam
//// import birdie
//// import telega/testing/mock
//// import telega/testing/render
////
//// let #(client, calls) = mock.message_client()
//// // ... drive your bot ...
//// mock.get_calls(calls)
//// |> render.calls_transcript
//// |> birdie.snap(title: "greeting:start_command")
//// ```

import gleam/dict
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/string

import telega/dialog/types as dialog_types
import telega/format
import telega/model/types.{
  type InlineKeyboardButton, type InlineKeyboardMarkup, InlineKeyboardButton,
}
import telega/testing/mock

/// Parse a JSON string and re-serialize it canonically: object keys sorted,
/// two-space indentation. Produces stable diffs regardless of encoder key
/// order. Returns `Error(Nil)` if the input is not valid JSON.
pub fn canonical_json(input: String) -> Result(String, Nil) {
  case json.parse(from: input, using: json_value_decoder()) {
    Ok(value) -> Ok(render_json(value, 0))
    Error(_) -> Error(Nil)
  }
}

/// Render a transcript of recorded API calls: one entry per call with the
/// method name and the canonical JSON body. The bot token never appears in
/// the output. Non-JSON bodies are included verbatim.
pub fn calls_transcript(calls calls: List(mock.ApiCall)) -> String {
  calls
  |> list.index_map(fn(call, index) {
    let method = method_from_path(call.request.path)
    let header = int.to_string(index + 1) <> ". " <> method
    case call.request.body {
      "" -> header
      body ->
        case canonical_json(body) {
          Ok(canonical) -> header <> "\n" <> canonical
          Error(_) -> header <> "\n" <> body
        }
    }
  })
  |> string.join("\n\n")
}

/// Render an inline keyboard as an ASCII grid, one row per line:
///
/// ```text
/// [ ○ English ](lang:en) | [ ● Русский ](lang:ru)
/// [ Docs ](url:https://example.com)
/// ```
pub fn keyboard_grid(markup markup: InlineKeyboardMarkup) -> String {
  grid(markup.inline_keyboard, button_cell)
}

/// Render formatted text as a "frame": the parse mode header followed by the
/// rendered text. Snapshot one frame per parse mode to pin down escaping.
pub fn formatted_frame(formatted formatted: format.FormattedText) -> String {
  let #(text, parse_mode) = format.render(formatted)
  "parse_mode: " <> format.parse_mode_to_string(parse_mode) <> "\n---\n" <> text
}

/// Render the full visible "frame" of a dialog window: parse mode, media,
/// text, and button grid. This is the level-1 dialog snapshot —
/// `window.render(state, ctx)` is pure, so no network or actors are involved.
pub fn window_frame(window window: dialog_types.RenderedWindow) -> String {
  let frame = case window.media {
    Some(media) -> {
      let #(text, parse_mode) = format.render(window.text)
      "parse_mode: "
      <> format.parse_mode_to_string(parse_mode)
      <> "\nmedia: "
      <> media_cell(media)
      <> "\n---\n"
      <> text
    }
    None -> formatted_frame(window.text)
  }
  case window.buttons {
    [] -> frame
    buttons -> frame <> "\n---\n" <> grid(buttons, dialog_button_cell)
  }
}

fn grid(rows: List(List(button)), cell: fn(button) -> String) -> String {
  rows
  |> list.map(fn(row) {
    row
    |> list.map(cell)
    |> string.join(" | ")
  })
  |> string.join("\n")
}

fn media_cell(media: dialog_types.DialogMedia) -> String {
  case media {
    dialog_types.PhotoMedia(media:, has_spoiler:) ->
      "photo " <> media <> spoiler_suffix(has_spoiler)
    dialog_types.VideoMedia(media:, has_spoiler:) ->
      "video " <> media <> spoiler_suffix(has_spoiler)
    dialog_types.AnimationMedia(media:) -> "animation " <> media
    dialog_types.DocumentMedia(media:) -> "document " <> media
  }
}

fn spoiler_suffix(has_spoiler: Bool) -> String {
  case has_spoiler {
    True -> " (spoiler)"
    False -> ""
  }
}

fn dialog_button_cell(button: dialog_types.DialogButton) -> String {
  let payload = case button {
    dialog_types.ActionButton(action_id:, ..) -> action_id
    dialog_types.ActionArgButton(action_id:, arg:, ..) ->
      action_id <> ":" <> arg
    dialog_types.UrlButton(url:, ..) -> "url:" <> url
    dialog_types.WebAppButton(url:, ..) -> "web_app:" <> url
    dialog_types.NoopButton(..) -> "noop"
  }
  "[ " <> button.text <> " ](" <> payload <> ")"
}

fn button_cell(button: InlineKeyboardButton) -> String {
  "[ " <> button.text <> " ](" <> button_payload(button) <> ")"
}

fn button_payload(button: InlineKeyboardButton) -> String {
  case button {
    InlineKeyboardButton(callback_data: Some(data), ..) -> data
    InlineKeyboardButton(url: Some(url), ..) -> "url:" <> url
    InlineKeyboardButton(web_app: Some(web_app), ..) ->
      "web_app:" <> web_app.url
    InlineKeyboardButton(copy_text: Some(copy_text), ..) ->
      "copy:" <> copy_text.text
    InlineKeyboardButton(switch_inline_query: Some(query), ..) ->
      "switch:" <> query
    InlineKeyboardButton(switch_inline_query_current_chat: Some(query), ..) ->
      "switch_current:" <> query
    InlineKeyboardButton(login_url: Some(login_url), ..) ->
      "login:" <> login_url.url
    InlineKeyboardButton(pay: Some(True), ..) -> "pay"
    InlineKeyboardButton(callback_game: Some(_), ..) -> "game"
    _ -> "-"
  }
}

fn method_from_path(path: String) -> String {
  path
  |> string.split("/")
  |> list.last
  |> option.from_result
  |> option.unwrap(path)
}

// Canonical JSON --------------------------------------------------------------

type JsonValue {
  JNull
  JBool(Bool)
  JInt(Int)
  JFloat(Float)
  JString(String)
  JArray(List(JsonValue))
  JObject(List(#(String, JsonValue)))
}

fn json_value_decoder() -> decode.Decoder(JsonValue) {
  use <- decode.recursive
  decode.one_of(decode.map(decode.bool, JBool), or: [
    decode.map(decode.int, JInt),
    decode.map(decode.float, JFloat),
    decode.map(decode.string, JString),
    decode.map(decode.list(json_value_decoder()), JArray),
    decode.map(decode.dict(decode.string, json_value_decoder()), fn(fields) {
      fields
      |> dict.to_list
      |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
      |> JObject
    }),
    decode.map(decode.optional(decode.bool), fn(_) { JNull }),
  ])
}

fn render_json(value: JsonValue, level: Int) -> String {
  case value {
    JNull -> "null"
    JBool(True) -> "true"
    JBool(False) -> "false"
    JInt(i) -> int.to_string(i)
    JFloat(f) -> float.to_string(f)
    JString(s) -> json.to_string(json.string(s))
    JArray([]) -> "[]"
    JArray(items) -> {
      let inner =
        items
        |> list.map(fn(item) { pad(level + 1) <> render_json(item, level + 1) })
        |> string.join(",\n")
      "[\n" <> inner <> "\n" <> pad(level) <> "]"
    }
    JObject([]) -> "{}"
    JObject(fields) -> {
      let inner =
        fields
        |> list.map(fn(field) {
          pad(level + 1)
          <> json.to_string(json.string(field.0))
          <> ": "
          <> render_json(field.1, level + 1)
        })
        |> string.join(",\n")
      "{\n" <> inner <> "\n" <> pad(level) <> "}"
    }
  }
}

fn pad(level: Int) -> String {
  string.repeat("  ", level)
}
