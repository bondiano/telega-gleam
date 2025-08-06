import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import telega/format

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

pub fn complex_formatting_test() {
  format.build()
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
  |> format.to_html()
  |> should.equal(
    "<b>📊 Daily Report</b>\n\n<u>Statistics:</u>\n• Users: <code>1234</code>\n• Messages: <code>5678</code>\n\n<tg-spoiler>Secret data</tg-spoiler>",
  )
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
