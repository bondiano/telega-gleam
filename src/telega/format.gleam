//// Provides utilities for text formatting in Telegram messages.
//// Supports HTML, Markdown, and MarkdownV2 parse modes.
////
//// ## Quick Start
//// ```gleam
//// import telega/format as fmt
////
//// // Simple formatting
//// let text = fmt.bold("Important!") <> " " <> fmt.italic("Read this")
////
//// // Complex formatting with builder
//// let message = fmt.build()
////   |> fmt.text("Hello ")
////   |> fmt.bold_text("World")
////   |> fmt.line_break()
////   |> fmt.link_text("Click here", "https://example.com")
////   |> fmt.to_html()
//// ```

import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

import telega/model/types.{type MessageEntity, MessageEntity}

/// Supported parse modes for Telegram
pub type ParseMode {
  HTML
  Markdown
  MarkdownV2
}

/// Convert ParseMode to string for API
pub fn parse_mode_to_string(mode: ParseMode) -> String {
  case mode {
    HTML -> "HTML"
    Markdown -> "Markdown"
    MarkdownV2 -> "MarkdownV2"
  }
}

/// Formatted text container
pub opaque type FormattedText {
  FormattedText(segments: List(Segment), parse_mode: ParseMode)
}

/// Text segments with formatting
type Segment {
  Plain(String)
  Bold(String)
  Italic(String)
  Underline(String)
  Strikethrough(String)
  Spoiler(String)
  Code(String)
  Pre(code: String, language: Option(String))
  Link(text: String, url: String)
  Mention(username: String)
  CustomEmoji(emoji: String, id: String)
  Nested(List(Segment))
}

/// Builder pattern for constructing formatted text
pub opaque type FormatBuilder {
  FormatBuilder(segments: List(Segment), parse_mode: ParseMode)
}

/// Create a new format builder with HTML as default
pub fn build() -> FormatBuilder {
  FormatBuilder(segments: [], parse_mode: HTML)
}

/// Set parse mode for builder
pub fn with_mode(builder: FormatBuilder, mode: ParseMode) -> FormatBuilder {
  FormatBuilder(..builder, parse_mode: mode)
}

/// Add plain text
pub fn text(builder: FormatBuilder, text: String) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Plain(text), ..builder.segments])
}

/// Add bold text using builder
pub fn bold_text(builder: FormatBuilder, text: String) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Bold(text), ..builder.segments])
}

/// Add italic text using builder
pub fn italic_text(builder: FormatBuilder, text: String) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Italic(text), ..builder.segments])
}

/// Add underlined text using builder
pub fn underline_text(builder: FormatBuilder, text: String) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Underline(text), ..builder.segments])
}

/// Add strikethrough text using builder
pub fn strikethrough_text(
  builder: FormatBuilder,
  text: String,
) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Strikethrough(text), ..builder.segments])
}

/// Add spoiler text using builder
pub fn spoiler_text(builder: FormatBuilder, text: String) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Spoiler(text), ..builder.segments])
}

/// Add inline code using builder
pub fn code_text(builder: FormatBuilder, text: String) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Code(text), ..builder.segments])
}

/// Add code block using builder
pub fn pre_text(
  builder: FormatBuilder,
  code: String,
  language: Option(String),
) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Pre(code, language), ..builder.segments])
}

/// Add hyperlink using builder
pub fn link_text(
  builder: FormatBuilder,
  text: String,
  url: String,
) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Link(text, url), ..builder.segments])
}

/// Add mention using builder
pub fn mention_text(builder: FormatBuilder, username: String) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Mention(username), ..builder.segments])
}

/// Add custom emoji using builder
pub fn custom_emoji_text(
  builder: FormatBuilder,
  emoji: String,
  id: String,
) -> FormatBuilder {
  FormatBuilder(..builder, segments: [
    CustomEmoji(emoji, id),
    ..builder.segments
  ])
}

/// Add line break
pub fn line_break(builder: FormatBuilder) -> FormatBuilder {
  FormatBuilder(..builder, segments: [Plain("\n"), ..builder.segments])
}

/// Build to HTML string
pub fn to_html(builder: FormatBuilder) -> String {
  builder.segments
  |> list.reverse
  |> list.map(segment_to_html)
  |> string.join("")
}

/// Build to Markdown string
pub fn to_markdown(builder: FormatBuilder) -> String {
  builder.segments
  |> list.reverse
  |> list.map(segment_to_markdown)
  |> string.join("")
}

/// Build to MarkdownV2 string
pub fn to_markdown_v2(builder: FormatBuilder) -> String {
  builder.segments
  |> list.reverse
  |> list.map(segment_to_markdown_v2)
  |> string.join("")
}

/// Convert to FormattedText for use with reply functions
pub fn to_formatted(builder: FormatBuilder) -> FormattedText {
  FormattedText(
    segments: list.reverse(builder.segments),
    parse_mode: builder.parse_mode,
  )
}

/// Render FormattedText to string with parse mode
pub fn render(formatted: FormattedText) -> #(String, ParseMode) {
  let text = case formatted.parse_mode {
    HTML ->
      formatted.segments
      |> list.map(segment_to_html)
      |> string.join("")
    Markdown ->
      formatted.segments
      |> list.map(segment_to_markdown)
      |> string.join("")
    MarkdownV2 ->
      formatted.segments
      |> list.map(segment_to_markdown_v2)
      |> string.join("")
  }
  #(text, formatted.parse_mode)
}

// Simple formatting functions (without builder)

/// Format text as bold (HTML)
pub fn bold(text: String) -> String {
  segment_to_html(Bold(text))
}

/// Format text as italic (HTML)
pub fn italic(text: String) -> String {
  segment_to_html(Italic(text))
}

/// Format text as underline (HTML)
pub fn underline(text: String) -> String {
  segment_to_html(Underline(text))
}

/// Format text as strikethrough (HTML)
pub fn strikethrough(text: String) -> String {
  segment_to_html(Strikethrough(text))
}

/// Format text as spoiler (HTML)
pub fn spoiler(text: String) -> String {
  segment_to_html(Spoiler(text))
}

/// Format text as inline code (HTML)
pub fn code(text: String) -> String {
  segment_to_html(Code(text))
}

/// Format text as code block (HTML)
pub fn pre(code: String, language: Option(String)) -> String {
  segment_to_html(Pre(code, language))
}

/// Format text as hyperlink (HTML)
pub fn link(text: String, url: String) -> String {
  segment_to_html(Link(text, url))
}

/// Format text as mention (HTML)
pub fn mention(username: String) -> String {
  segment_to_html(Mention(username))
}

// Escape functions for each parse mode

/// Escape special characters for HTML
pub fn escape_html(text: String) -> String {
  text
  |> string.replace("&", "&amp;")
  |> string.replace("<", "&lt;")
  |> string.replace(">", "&gt;")
  |> string.replace("\"", "&quot;")
}

/// Escape special characters for Markdown
pub fn escape_markdown(text: String) -> String {
  text
  |> string.replace("\\", "\\\\")
  |> string.replace("_", "\\_")
  |> string.replace("*", "\\*")
  |> string.replace("[", "\\[")
  |> string.replace("]", "\\]")
  |> string.replace("(", "\\(")
  |> string.replace(")", "\\)")
  |> string.replace("`", "\\`")
}

/// Escape the contents of a `code` or `pre` entity.
///
/// Telegram unescapes only `` ` `` and `\` inside those, so escaping the full
/// set would leave literal backslashes in the code; escaping nothing (what
/// this used to do) lets a backtick close the span and the rest of the
/// message be read as the *user's* formatting.
pub fn escape_markdown_code(text: String) -> String {
  text
  |> string.replace("\\", "\\\\")
  |> string.replace("`", "\\`")
}

/// Escape a URL for the `(...)` part of a MarkdownV2 link or custom emoji.
///
/// Only `)` and `\` are special there. Running the full escape over a URL
/// backslash-escaped `-`, `.`, `=` and friends, which Telegram then leaves in
/// the link verbatim.
pub fn escape_markdown_url(url: String) -> String {
  url
  |> string.replace("\\", "\\\\")
  |> string.replace(")", "\\)")
}

/// Escape special characters for MarkdownV2
pub fn escape_markdown_v2(text: String) -> String {
  text
  |> string.replace("\\", "\\\\")
  |> string.replace("_", "\\_")
  |> string.replace("*", "\\*")
  |> string.replace("[", "\\[")
  |> string.replace("]", "\\]")
  |> string.replace("(", "\\(")
  |> string.replace(")", "\\)")
  |> string.replace("~", "\\~")
  |> string.replace("`", "\\`")
  |> string.replace(">", "\\>")
  |> string.replace("#", "\\#")
  |> string.replace("+", "\\+")
  |> string.replace("-", "\\-")
  |> string.replace("=", "\\=")
  |> string.replace("|", "\\|")
  |> string.replace("{", "\\{")
  |> string.replace("}", "\\}")
  |> string.replace(".", "\\.")
  |> string.replace("!", "\\!")
}

// Internal converters

fn segment_to_html(segment: Segment) -> String {
  case segment {
    Plain(text) -> escape_html(text)
    Bold(text) -> "<b>" <> escape_html(text) <> "</b>"
    Italic(text) -> "<i>" <> escape_html(text) <> "</i>"
    Underline(text) -> "<u>" <> escape_html(text) <> "</u>"
    Strikethrough(text) -> "<s>" <> escape_html(text) <> "</s>"
    Spoiler(text) -> "<tg-spoiler>" <> escape_html(text) <> "</tg-spoiler>"
    Code(text) -> "<code>" <> escape_html(text) <> "</code>"
    Pre(code, None) -> "<pre>" <> escape_html(code) <> "</pre>"
    Pre(code, Some(lang)) ->
      "<pre><code class=\"language-"
      <> escape_html(lang)
      <> "\">"
      <> escape_html(code)
      <> "</code></pre>"
    Link(text, url) ->
      "<a href=\"" <> escape_html(url) <> "\">" <> escape_html(text) <> "</a>"
    Mention(username) -> "@" <> escape_html(username)
    CustomEmoji(emoji, id) ->
      "<tg-emoji emoji-id=\""
      <> escape_html(id)
      <> "\">"
      <> escape_html(emoji)
      <> "</tg-emoji>"
    Nested(segments) ->
      segments
      |> list.map(segment_to_html)
      |> string.join("")
  }
}

fn segment_to_markdown(segment: Segment) -> String {
  case segment {
    Plain(text) -> escape_markdown(text)
    Bold(text) -> "*" <> escape_markdown(text) <> "*"
    Italic(text) -> "_" <> escape_markdown(text) <> "_"
    Code(text) -> "`" <> escape_markdown_code(text) <> "`"
    Pre(code, _) -> "```\n" <> escape_markdown_code(code) <> "\n```"
    Link(text, url) ->
      "[" <> escape_markdown(text) <> "](" <> escape_markdown_url(url) <> ")"
    // Markdown doesn't support all formats
    Underline(text) | Strikethrough(text) | Spoiler(text) ->
      escape_markdown(text)
    Mention(username) -> "@" <> escape_markdown(username)
    CustomEmoji(emoji, _) -> emoji
    Nested(segments) ->
      segments
      |> list.map(segment_to_markdown)
      |> string.join("")
  }
}

fn segment_to_markdown_v2(segment: Segment) -> String {
  case segment {
    Plain(text) -> escape_markdown_v2(text)
    Bold(text) -> "*" <> escape_markdown_v2(text) <> "*"
    Italic(text) -> "_" <> escape_markdown_v2(text) <> "_"
    Underline(text) -> "__" <> escape_markdown_v2(text) <> "__"
    Strikethrough(text) -> "~" <> escape_markdown_v2(text) <> "~"
    Spoiler(text) -> "||" <> escape_markdown_v2(text) <> "||"
    Code(text) -> "`" <> escape_markdown_code(text) <> "`"
    Pre(code, None) -> "```\n" <> escape_markdown_code(code) <> "\n```"
    Pre(code, Some(lang)) ->
      "```" <> lang <> "\n" <> escape_markdown_code(code) <> "\n```"
    Link(text, url) ->
      "[" <> escape_markdown_v2(text) <> "](" <> escape_markdown_url(url) <> ")"
    Mention(username) -> "@" <> escape_markdown_v2(username)
    CustomEmoji(emoji, id) ->
      "![" <> escape_markdown_v2(emoji) <> "](tg://emoji?id=" <> id <> ")"
    Nested(segments) ->
      segments
      |> list.map(segment_to_markdown_v2)
      |> string.join("")
  }
}

// Entity rendering
//
// The alternative to a parse mode: send the text raw and describe the
// formatting positionally. Nothing has to be escaped, so a user-supplied
// string can never close a span it did not open, and a `*` the user typed
// stays a `*`.

/// Render `FormattedText` to a plain string plus the `MessageEntity` list that
/// describes its formatting.
///
/// This is the escape-free way to send formatted text: no parse mode is
/// involved, so no character in the text is special. Offsets and lengths are
/// in UTF-16 code units, as the Bot API requires — an emoji outside the BMP
/// counts as two.
///
/// ```gleam
/// let #(text, entities) =
///   format.build()
///   |> format.text("Result: ")
///   |> format.bold_text(user_supplied)
///   |> format.to_formatted
///   |> format.entities
/// ```
///
/// Zero-length segments produce no entity — Telegram rejects those. A
/// `Mention` renders as `@username` with a `mention` entity over it, and a
/// `Nested` group contributes its children's entities without one of its own.
pub fn entities(formatted: FormattedText) -> #(String, List(MessageEntity)) {
  let #(_, texts, entities) = collect_entities(formatted.segments, 0, [], [])
  #(texts |> list.reverse |> string.join(""), entities |> list.reverse)
}

fn collect_entities(
  segments: List(Segment),
  offset: Int,
  texts: List(String),
  entities: List(MessageEntity),
) -> #(Int, List(String), List(MessageEntity)) {
  case segments {
    [] -> #(offset, texts, entities)
    [Nested(inner), ..rest] -> {
      let #(offset, texts, entities) =
        collect_entities(inner, offset, texts, entities)
      collect_entities(rest, offset, texts, entities)
    }
    [segment, ..rest] -> {
      let #(text, entity) = segment_entity(segment, offset)
      let length = utf16_length(text)
      let entities = case entity, length {
        _, 0 -> entities
        None, _ -> entities
        Some(entity), _ -> [MessageEntity(..entity, length:), ..entities]
      }
      collect_entities(rest, offset + length, [text, ..texts], entities)
    }
  }
}

/// The plain text a segment contributes, and the entity covering it — with a
/// placeholder `length` the caller replaces once it has measured the text.
fn segment_entity(
  segment: Segment,
  offset: Int,
) -> #(String, Option(MessageEntity)) {
  case segment {
    Plain(text) -> #(text, None)
    Bold(text) -> #(text, Some(entity("bold", offset)))
    Italic(text) -> #(text, Some(entity("italic", offset)))
    Underline(text) -> #(text, Some(entity("underline", offset)))
    Strikethrough(text) -> #(text, Some(entity("strikethrough", offset)))
    Spoiler(text) -> #(text, Some(entity("spoiler", offset)))
    Code(text) -> #(text, Some(entity("code", offset)))
    Pre(code, language) -> #(
      code,
      Some(MessageEntity(..entity("pre", offset), language:)),
    )
    Link(text, url) -> #(
      text,
      Some(MessageEntity(..entity("text_link", offset), url: Some(url))),
    )
    Mention(username) -> #("@" <> username, Some(entity("mention", offset)))
    CustomEmoji(emoji, id) -> #(
      emoji,
      Some(
        MessageEntity(
          ..entity("custom_emoji", offset),
          custom_emoji_id: Some(id),
        ),
      ),
    )
    // Handled by `collect_entities`, which flattens the group instead.
    Nested(_) -> #("", None)
  }
}

fn entity(type_: String, offset: Int) -> MessageEntity {
  MessageEntity(
    type_:,
    offset:,
    length: 0,
    url: None,
    user: None,
    language: None,
    custom_emoji_id: None,
    unix_time: None,
    date_time_format: None,
  )
}

/// Telegram counts entity offsets in UTF-16 code units, not graphemes and not
/// bytes: every codepoint above the BMP (emoji, most of them) is a surrogate
/// pair and counts twice.
fn utf16_length(text: String) -> Int {
  text
  |> string.to_utf_codepoints
  |> list.fold(0, fn(length, codepoint) {
    case string.utf_codepoint_to_int(codepoint) > 0xFFFF {
      True -> length + 2
      False -> length + 1
    }
  })
}
