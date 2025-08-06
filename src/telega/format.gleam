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
pub fn strikethrough_text(builder: FormatBuilder, text: String) -> FormatBuilder {
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
    Code(text) -> "`" <> text <> "`"
    Pre(code, _) -> "```\n" <> code <> "\n```"
    Link(text, url) -> "[" <> escape_markdown(text) <> "](" <> url <> ")"
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
    Code(text) -> "`" <> text <> "`"
    Pre(code, None) -> "```\n" <> code <> "\n```"
    Pre(code, Some(lang)) -> "```" <> lang <> "\n" <> code <> "\n```"
    Link(text, url) ->
      "[" <> escape_markdown_v2(text) <> "](" <> escape_markdown_v2(url) <> ")"
    Mention(username) -> "@" <> escape_markdown_v2(username)
    CustomEmoji(emoji, id) -> "![" <> emoji <> "](tg://emoji?id=" <> id <> ")"
    Nested(segments) ->
      segments
      |> list.map(segment_to_markdown_v2)
      |> string.join("")
  }
}
