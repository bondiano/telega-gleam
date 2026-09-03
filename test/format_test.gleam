import birdie
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import telega/format
import telega/testing/render

pub fn main() {
  gleeunit.main()
}

// Test simple formatting functions
pub fn bold_test() {
  format.bold("Hello")
  |> should.equal("<b>Hello</b>")
}

pub fn italic_test() {
  format.italic("World")
  |> should.equal("<i>World</i>")
}

pub fn underline_test() {
  format.underline("Text")
  |> should.equal("<u>Text</u>")
}

pub fn strikethrough_test() {
  format.strikethrough("Old")
  |> should.equal("<s>Old</s>")
}

pub fn spoiler_test() {
  format.spoiler("Secret")
  |> should.equal("<tg-spoiler>Secret</tg-spoiler>")
}

pub fn code_test() {
  format.code("let x = 1")
  |> should.equal("<code>let x = 1</code>")
}

pub fn pre_test() {
  format.pre("fn main() {\n  println!(\"Hello\");\n}", None)
  |> should.equal("<pre>fn main() {\n  println!(&quot;Hello&quot;);\n}</pre>")
}

pub fn pre_with_language_test() {
  format.pre("print('Hello')", Some("python"))
  |> should.equal(
    "<pre><code class=\"language-python\">print('Hello')</code></pre>",
  )
}

pub fn link_test() {
  format.link("Click here", "https://example.com")
  |> should.equal("<a href=\"https://example.com\">Click here</a>")
}

pub fn mention_test() {
  format.mention("username")
  |> should.equal("@username")
}

pub fn escape_html_test() {
  format.escape_html("<b>Test & \"quotes\"</b>")
  |> should.equal("&lt;b&gt;Test &amp; &quot;quotes&quot;&lt;/b&gt;")
}

pub fn escape_markdown_test() {
  format.escape_markdown("*bold* _italic_ [link](url) `code`")
  |> should.equal("\\*bold\\* \\_italic\\_ \\[link\\]\\(url\\) \\`code\\`")
}

pub fn escape_markdown_v2_test() {
  format.escape_markdown_v2("*_~`>#+-=|{}.![]()\\")
  |> should.equal("\\*\\_\\~\\`\\>\\#\\+\\-\\=\\|\\{\\}\\.\\!\\[\\]\\(\\)\\\\")
}

pub fn builder_simple_test() {
  format.build()
  |> format.text("Hello ")
  |> format.bold_text("World")
  |> format.to_html()
  |> should.equal("Hello <b>World</b>")
}

pub fn builder_complex_test() {
  format.build()
  |> format.bold_text("Title")
  |> format.line_break()
  |> format.text("Normal text with ")
  |> format.code_text("inline code")
  |> format.line_break()
  |> format.link_text("Link", "https://example.com")
  |> format.to_html()
  |> should.equal(
    "<b>Title</b>\nNormal text with <code>inline code</code>\n<a href=\"https://example.com\">Link</a>",
  )
}

pub fn builder_with_mode_markdown_test() {
  format.build()
  |> format.with_mode(format.Markdown)
  |> format.bold_text("Bold")
  |> format.text(" and ")
  |> format.italic_text("italic")
  |> format.to_markdown()
  |> should.equal("*Bold* and _italic_")
}

pub fn builder_with_mode_markdown_v2_test() {
  format.build()
  |> format.with_mode(format.MarkdownV2)
  |> format.bold_text("Bold")
  |> format.text(" ")
  |> format.italic_text("italic")
  |> format.text(" ")
  |> format.underline_text("underline")
  |> format.to_markdown_v2()
  |> should.equal("*Bold* _italic_ __underline__")
}

pub fn builder_spoiler_and_strikethrough_test() {
  format.build()
  |> format.with_mode(format.MarkdownV2)
  |> format.spoiler_text("Hidden")
  |> format.text(" ")
  |> format.strikethrough_text("Crossed")
  |> format.to_markdown_v2()
  |> should.equal("||Hidden|| ~Crossed~")
}

pub fn builder_code_block_test() {
  format.build()
  |> format.text("Code example:")
  |> format.line_break()
  |> format.pre_text("let x = 42\nlet y = x + 1", Some("gleam"))
  |> format.to_html()
  |> should.equal(
    "Code example:\n<pre><code class=\"language-gleam\">let x = 42\nlet y = x + 1</code></pre>",
  )
}

pub fn builder_mention_and_custom_emoji_test() {
  format.build()
  |> format.mention_text("user123")
  |> format.text(" sent ")
  |> format.custom_emoji_text("🎉", "emoji_id_123")
  |> format.to_html()
  |> should.equal(
    "@user123 sent <tg-emoji emoji-id=\"emoji_id_123\">🎉</tg-emoji>",
  )
}

pub fn escape_in_bold_test() {
  format.bold("<script>alert('xss')</script>")
  |> should.equal("<b>&lt;script&gt;alert('xss')&lt;/script&gt;</b>")
}

pub fn escape_in_link_test() {
  format.link("Click & \"read\"", "https://example.com?a=1&b=2")
  |> should.equal(
    "<a href=\"https://example.com?a=1&amp;b=2\">Click &amp; &quot;read&quot;</a>",
  )
}

pub fn parse_mode_to_string_test() {
  format.parse_mode_to_string(format.HTML)
  |> should.equal("HTML")

  format.parse_mode_to_string(format.Markdown)
  |> should.equal("Markdown")

  format.parse_mode_to_string(format.MarkdownV2)
  |> should.equal("MarkdownV2")
}

pub fn formatted_text_render_html_test() {
  let formatted =
    format.build()
    |> format.with_mode(format.HTML)
    |> format.bold_text("Test")
    |> format.to_formatted()

  let #(text, mode) = format.render(formatted)
  text
  |> should.equal("<b>Test</b>")
  mode
  |> should.equal(format.HTML)
}

pub fn formatted_text_render_markdown_v2_test() {
  let formatted =
    format.build()
    |> format.with_mode(format.MarkdownV2)
    |> format.bold_text("Bold")
    |> format.text(" ")
    |> format.italic_text("Italic")
    |> format.to_formatted()

  let #(text, mode) = format.render(formatted)
  text
  |> should.equal("*Bold* _Italic_")
  mode
  |> should.equal(format.MarkdownV2)
}

fn daily_report(mode: format.ParseMode) -> format.FormatBuilder {
  format.build()
  |> format.with_mode(mode)
  |> format.bold_text("📊 Daily Report")
  |> format.line_break()
  |> format.line_break()
  |> format.underline_text("Statistics:")
  |> format.line_break()
  |> format.text("• Users: ")
  |> format.code_text("1234")
  |> format.line_break()
  |> format.text("• Messages: ")
  |> format.code_text("5678")
  |> format.line_break()
  |> format.line_break()
  |> format.spoiler_text("Secret data")
  |> format.line_break()
  |> format.link_text("Details & more", "https://example.com?a=1&b=2")
  |> format.line_break()
  |> format.pre_text("let x = 42", Some("gleam"))
}

pub fn complex_formatting_html_test() {
  daily_report(format.HTML)
  |> format.to_formatted()
  |> render.formatted_frame
  |> birdie.snap(title: "format:daily_report:html")
}

pub fn complex_formatting_markdown_test() {
  daily_report(format.Markdown)
  |> format.to_formatted()
  |> render.formatted_frame
  |> birdie.snap(title: "format:daily_report:markdown")
}

pub fn complex_formatting_markdown_v2_test() {
  daily_report(format.MarkdownV2)
  |> format.to_formatted()
  |> render.formatted_frame
  |> birdie.snap(title: "format:daily_report:markdown_v2")
}

pub fn empty_text_test() {
  format.build()
  |> format.to_html()
  |> should.equal("")
}

pub fn only_line_breaks_test() {
  format.build()
  |> format.line_break()
  |> format.line_break()
  |> format.to_html()
  |> should.equal("\n\n")
}

pub fn special_characters_in_code_test() {
  format.code("< > & \"")
  |> should.equal("<code>&lt; &gt; &amp; &quot;</code>")
}

pub fn markdown_limitations_test() {
  format.build()
  |> format.with_mode(format.Markdown)
  |> format.underline_text("underline")
  |> format.text(" ")
  |> format.strikethrough_text("strike")
  |> format.text(" ")
  |> format.spoiler_text("spoiler")
  |> format.to_markdown()
  |> should.equal("underline strike spoiler")
}

pub fn mixed_formats_html_test() {
  let result =
    format.bold("Bold")
    <> " "
    <> format.italic("Italic")
    <> " "
    <> format.code("Code")
  result
  |> should.equal("<b>Bold</b> <i>Italic</i> <code>Code</code>")
}

// M12 — MarkdownV2 escaping inside code spans and link URLs -----------------

pub fn markdown_v2_escapes_code_spans_test() {
  // A backtick in the code text closes the span; a backslash escapes the next
  // character. Both must be escaped, or Telegram answers 400 — or worse,
  // renders the rest of the message as the user's formatting.
  format.build()
  |> format.with_mode(format.MarkdownV2)
  |> format.code_text("a ` b \\ c")
  |> format.to_markdown_v2()
  |> should.equal("`a \\` b \\\\ c`")
}

pub fn markdown_v2_escapes_pre_blocks_test() {
  format.build()
  |> format.with_mode(format.MarkdownV2)
  |> format.pre_text("let s = \"``` \\\"", None)
  |> format.to_markdown_v2()
  |> should.equal("```\nlet s = \"\\`\\`\\` \\\\\"\n```")
}

pub fn markdown_v2_escapes_only_paren_and_backslash_in_urls_test() {
  // Inside the `(...)` of a link Telegram unescapes only `)` and `\`. Escaping
  // the full set left literal backslashes in the URL.
  format.build()
  |> format.with_mode(format.MarkdownV2)
  |> format.link_text("docs", "https://example.com/a_b-c.d?x=1&y=(2)")
  |> format.to_markdown_v2()
  |> should.equal("[docs](https://example.com/a_b-c.d?x=1&y=(2\\))")
}

pub fn markdown_escapes_code_spans_test() {
  format.build()
  |> format.with_mode(format.Markdown)
  |> format.code_text("a ` b \\ c")
  |> format.to_markdown()
  |> should.equal("`a \\` b \\\\ c`")
}

// Entity rendering
//
// The escape-free path: the text goes out verbatim and the formatting travels
// beside it, positionally. Offsets are UTF-16 code units, which is where this
// is easy to get wrong.

pub fn entities_of_plain_text_test() {
  let #(text, entities) =
    format.build()
    |> format.text("*not bold* <b>not html</b>")
    |> format.to_formatted()
    |> format.entities

  // Nothing is escaped, because with entities nothing is special.
  text |> should.equal("*not bold* <b>not html</b>")
  entities |> should.equal([])
}

pub fn entities_offsets_are_utf16_code_units_test() {
  // "🤖" is one grapheme, one codepoint — and two UTF-16 code units, which is
  // the only unit Telegram counts in.
  let #(text, entities) =
    format.build()
    |> format.text("🤖 ")
    |> format.bold_text("bot")
    |> format.to_formatted()
    |> format.entities

  text |> should.equal("🤖 bot")

  let assert [entity] = entities
  entity.type_ |> should.equal("bold")
  entity.offset |> should.equal(3)
  entity.length |> should.equal(3)
}

pub fn entities_skip_empty_segments_test() {
  let #(_, entities) =
    format.build()
    |> format.bold_text("")
    |> format.italic_text("real")
    |> format.to_formatted()
    |> format.entities

  // Telegram rejects a zero-length entity, so an empty segment contributes
  // text (none) and nothing else.
  let assert [entity] = entities
  entity.type_ |> should.equal("italic")
}

pub fn entities_carry_link_and_language_test() {
  let #(_, entities) =
    format.build()
    |> format.link_text("docs", "https://gleam.run")
    |> format.pre_text("let x = 1", Some("gleam"))
    |> format.to_formatted()
    |> format.entities

  let assert [link, pre] = entities
  link.type_ |> should.equal("text_link")
  link.url |> should.equal(Some("https://gleam.run"))
  pre.type_ |> should.equal("pre")
  pre.language |> should.equal(Some("gleam"))
}

pub fn entities_daily_report_test() {
  daily_report(format.HTML)
  |> format.to_formatted()
  |> render.entities_frame
  |> birdie.snap(title: "format:daily_report:entities")
}

pub fn entities_with_user_input_test() {
  format.build()
  |> format.text("Search: ")
  |> format.bold_text("*_[]()~`>#+-=|{}.!<b>&")
  |> format.to_formatted()
  |> render.entities_frame
  |> birdie.snap(title: "format:user_input:entities")
}
