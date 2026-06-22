import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot.{type Context, Context}
import telega/error.{type TelegaError}
import telega/inline_mode
import telega/model/types
import telega/testing/context as test_context
import telega/testing/factory
import telega/testing/mock

pub fn main() {
  gleeunit.main()
}

pub fn builder_keeps_result_order_test() {
  let results =
    inline_mode.new()
    |> inline_mode.article(id: "1", title: "First", text: "first text")
    |> inline_mode.photo(
      id: "2",
      url: "https://example.com/photo.jpg",
      thumb: "https://example.com/thumb.jpg",
    )
    |> inline_mode.location(
      id: "3",
      latitude: 52.52,
      longitude: 13.405,
      title: "Berlin",
    )
    |> inline_mode.results()

  let assert [
    types.InlineQueryResultArticleInlineQueryResult(article),
    types.InlineQueryResultPhotoInlineQueryResult(photo),
    types.InlineQueryResultLocationInlineQueryResult(location),
  ] = results

  article.id |> should.equal("1")
  article.title |> should.equal("First")
  let assert types.InputTextMessageContentInputMessageContent(content) =
    article.input_message_content
  content.message_text |> should.equal("first text")

  photo.photo_url |> should.equal("https://example.com/photo.jpg")
  photo.thumbnail_url |> should.equal("https://example.com/thumb.jpg")

  location.title |> should.equal("Berlin")
}

pub fn video_and_document_builders_test() {
  let results =
    inline_mode.new()
    |> inline_mode.video(
      id: "v1",
      url: "https://example.com/video.mp4",
      thumb: "https://example.com/thumb.jpg",
      title: "Video",
    )
    |> inline_mode.document(
      id: "d1",
      title: "Manual",
      url: "https://example.com/manual.pdf",
      mime_type: "application/pdf",
    )
    |> inline_mode.results()

  let assert [
    types.InlineQueryResultVideoInlineQueryResult(video),
    types.InlineQueryResultDocumentInlineQueryResult(document),
  ] = results

  video.mime_type |> should.equal("video/mp4")
  video.title |> should.equal("Video")
  document.mime_type |> should.equal("application/pdf")
  document.document_url |> should.equal("https://example.com/manual.pdf")
}

pub fn answer_sends_results_and_options_test() {
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "answerInlineQuery",
        response: mock.bool_response(),
      ),
    ])

  let base: Context(String, TelegaError, Nil) =
    test_context.context_with(
      session: "initial",
      update: factory.text_update(text: "hi"),
    )
  let ctx = Context(..base, config: test_context.config_with_client(client))

  inline_mode.new()
  |> inline_mode.article(id: "1", title: "Result", text: "text")
  |> inline_mode.with_cache_time(300)
  |> inline_mode.personal()
  |> inline_mode.with_next_offset("10")
  |> inline_mode.answer(ctx, query_id: "query_1")
  |> should.be_ok()
  |> should.equal(True)

  let assert [call] = mock.get_calls(from: calls)
  call.request.path |> string.contains("answerInlineQuery") |> should.be_true()
  call.request.body
  |> string.contains("\"inline_query_id\":\"query_1\"")
  |> should.be_true()
  call.request.body
  |> string.contains("\"next_offset\":\"10\"")
  |> should.be_true()
  call.request.body
  |> string.contains("\"is_personal\":true")
  |> should.be_true()
  call.request.body
  |> string.contains("\"cache_time\":300")
  |> should.be_true()
}

pub fn paginate_first_page_test() {
  let items = ["a", "b", "c", "d", "e"]

  inline_mode.paginate(items:, offset: "", page_size: 2)
  |> should.equal(#(["a", "b"], Some("2")))
}

pub fn paginate_middle_and_last_page_test() {
  let items = ["a", "b", "c", "d", "e"]

  inline_mode.paginate(items:, offset: "2", page_size: 2)
  |> should.equal(#(["c", "d"], Some("4")))

  inline_mode.paginate(items:, offset: "4", page_size: 2)
  |> should.equal(#(["e"], None))
}

pub fn paginate_exact_boundary_test() {
  let items = ["a", "b", "c", "d"]

  // Last full page: no next offset
  inline_mode.paginate(items:, offset: "2", page_size: 2)
  |> should.equal(#(["c", "d"], None))
}

pub fn paginate_invalid_offset_falls_back_to_start_test() {
  let items = ["a", "b", "c"]

  inline_mode.paginate(items:, offset: "garbage", page_size: 2)
  |> should.equal(#(["a", "b"], Some("2")))

  inline_mode.paginate(items:, offset: "-5", page_size: 2)
  |> should.equal(#(["a", "b"], Some("2")))
}
