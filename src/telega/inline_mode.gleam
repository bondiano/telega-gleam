//// Builder for answering inline queries, in the spirit of `keyboard`.
////
//// Covers the most common `InlineQueryResult` variants (article, photo,
//// video, document, location); anything else can be added with `result`
//// using the raw types from `telega/model/types`.
////
//// ```gleam
//// fn handle_inline_query(ctx, query: types.InlineQuery) {
////   let #(page, next_offset) = inline_mode.paginate(items, offset: query.offset, page_size: 10)
////
////   let assert Ok(_) =
////     list.index_fold(page, inline_mode.new(), fn(builder, item, index) {
////       inline_mode.article(builder, id: int.to_string(index), title: item, text: item)
////     })
////     |> inline_mode.with_cache_time(300)
////     |> inline_mode.maybe_next_offset(next_offset)
////     |> inline_mode.answer(ctx, query.id)
////
////   Ok(ctx)
//// }
//// ```

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}

import telega/api
import telega/bot.{type Context}
import telega/error
import telega/model/types.{
  type InlineQueryResult, type InlineQueryResultsButton,
  AnswerInlineQueryParameters, InlineQueryResultArticle,
  InlineQueryResultArticleInlineQueryResult, InlineQueryResultDocument,
  InlineQueryResultDocumentInlineQueryResult, InlineQueryResultLocation,
  InlineQueryResultLocationInlineQueryResult, InlineQueryResultPhoto,
  InlineQueryResultPhotoInlineQueryResult, InlineQueryResultVideo,
  InlineQueryResultVideoInlineQueryResult, InputTextMessageContent,
  InputTextMessageContentInputMessageContent,
}

/// Accumulates inline query results and answer options.
pub opaque type InlineQueryAnswer {
  InlineQueryAnswer(
    // Stored in reverse order, `answer`/`results` restore it.
    results: List(InlineQueryResult),
    cache_time: Option(Int),
    is_personal: Option(Bool),
    next_offset: Option(String),
    button: Option(InlineQueryResultsButton),
  )
}

/// Create an empty inline query answer.
pub fn new() -> InlineQueryAnswer {
  InlineQueryAnswer(
    results: [],
    cache_time: None,
    is_personal: None,
    next_offset: None,
    button: None,
  )
}

/// Add an article result: shows `title` in the result list, sends `text` when chosen.
pub fn article(
  builder builder: InlineQueryAnswer,
  id id: String,
  title title: String,
  text text: String,
) -> InlineQueryAnswer {
  article_described(builder, id:, title:, text:, description: None)
}

/// Same as `article` with a short description shown under the title.
pub fn article_described(
  builder builder: InlineQueryAnswer,
  id id: String,
  title title: String,
  text text: String,
  description description: Option(String),
) -> InlineQueryAnswer {
  InlineQueryResultArticle(
    type_: "article",
    id:,
    title:,
    input_message_content: InputTextMessageContentInputMessageContent(
      InputTextMessageContent(
        message_text: text,
        parse_mode: None,
        entities: None,
        link_preview_options: None,
      ),
    ),
    reply_markup: None,
    url: None,
    description:,
    thumbnail_url: None,
    thumbnail_width: None,
    thumbnail_height: None,
  )
  |> InlineQueryResultArticleInlineQueryResult
  |> result(builder, _)
}

/// Add a photo result. `url` must point to a JPEG up to 5MB.
pub fn photo(
  builder builder: InlineQueryAnswer,
  id id: String,
  url url: String,
  thumb thumbnail_url: String,
) -> InlineQueryAnswer {
  photo_captioned(builder, id:, url:, thumb: thumbnail_url, caption: None)
}

/// Same as `photo` with a caption sent along with the photo.
pub fn photo_captioned(
  builder builder: InlineQueryAnswer,
  id id: String,
  url url: String,
  thumb thumbnail_url: String,
  caption caption: Option(String),
) -> InlineQueryAnswer {
  InlineQueryResultPhoto(
    type_: "photo",
    id:,
    photo_url: url,
    thumbnail_url:,
    photo_width: None,
    photo_height: None,
    title: None,
    description: None,
    caption:,
    parse_mode: None,
    caption_entities: None,
    show_caption_above_media: None,
    reply_markup: None,
    input_message_content: None,
  )
  |> InlineQueryResultPhotoInlineQueryResult
  |> result(builder, _)
}

/// Add an MP4 video result. For embedded players (`text/html`) build
/// `InlineQueryResultVideo` manually and add it with `result` — Telegram
/// requires `input_message_content` for those.
pub fn video(
  builder builder: InlineQueryAnswer,
  id id: String,
  url url: String,
  thumb thumbnail_url: String,
  title title: String,
) -> InlineQueryAnswer {
  InlineQueryResultVideo(
    type_: "video",
    id:,
    video_url: url,
    mime_type: "video/mp4",
    thumbnail_url:,
    title:,
    caption: None,
    parse_mode: None,
    caption_entities: None,
    show_caption_above_media: None,
    video_width: None,
    video_height: None,
    video_duration: None,
    description: None,
    reply_markup: None,
    input_message_content: None,
  )
  |> InlineQueryResultVideoInlineQueryResult
  |> result(builder, _)
}

/// Add a document result. `mime_type` must be `"application/pdf"` or `"application/zip"`.
pub fn document(
  builder builder: InlineQueryAnswer,
  id id: String,
  title title: String,
  url url: String,
  mime_type mime_type: String,
) -> InlineQueryAnswer {
  InlineQueryResultDocument(
    type_: "document",
    id:,
    title:,
    caption: None,
    parse_mode: None,
    caption_entities: None,
    document_url: url,
    mime_type:,
    description: None,
    reply_markup: None,
    input_message_content: None,
    thumbnail_url: None,
    thumbnail_width: None,
    thumbnail_height: None,
  )
  |> InlineQueryResultDocumentInlineQueryResult
  |> result(builder, _)
}

/// Add a location result.
pub fn location(
  builder builder: InlineQueryAnswer,
  id id: String,
  latitude latitude: Float,
  longitude longitude: Float,
  title title: String,
) -> InlineQueryAnswer {
  InlineQueryResultLocation(
    type_: "location",
    id:,
    latitude:,
    longitude:,
    title:,
    horizontal_accuracy: None,
    live_period: None,
    heading: None,
    proximity_alert_radius: None,
    reply_markup: None,
    input_message_content: None,
    thumbnail_url: None,
    thumbnail_width: None,
    thumbnail_height: None,
  )
  |> InlineQueryResultLocationInlineQueryResult
  |> result(builder, _)
}

/// Escape hatch: add any `InlineQueryResult` built from `telega/model/types`.
pub fn result(
  builder builder: InlineQueryAnswer,
  result result: InlineQueryResult,
) -> InlineQueryAnswer {
  InlineQueryAnswer(..builder, results: [result, ..builder.results])
}

/// Maximum time in seconds the result may be cached on Telegram servers (default 300).
pub fn with_cache_time(
  builder builder: InlineQueryAnswer,
  seconds seconds: Int,
) -> InlineQueryAnswer {
  InlineQueryAnswer(..builder, cache_time: Some(seconds))
}

/// Cache results only for the user that sent the query.
pub fn personal(builder builder: InlineQueryAnswer) -> InlineQueryAnswer {
  InlineQueryAnswer(..builder, is_personal: Some(True))
}

/// Offset the client sends in the next query to fetch more results.
pub fn with_next_offset(
  builder builder: InlineQueryAnswer,
  offset offset: String,
) -> InlineQueryAnswer {
  InlineQueryAnswer(..builder, next_offset: Some(offset))
}

/// Set the next offset when there are more pages — pairs with `paginate`.
pub fn maybe_next_offset(
  builder builder: InlineQueryAnswer,
  offset offset: Option(String),
) -> InlineQueryAnswer {
  case offset {
    Some(offset) -> with_next_offset(builder, offset)
    None -> builder
  }
}

/// Button shown above the inline results.
pub fn with_button(
  builder builder: InlineQueryAnswer,
  button button: InlineQueryResultsButton,
) -> InlineQueryAnswer {
  InlineQueryAnswer(..builder, button: Some(button))
}

/// Added results in the order they were added.
pub fn results(builder builder: InlineQueryAnswer) -> List(InlineQueryResult) {
  list.reverse(builder.results)
}

/// Send the accumulated results as the answer to an inline query.
/// No more than 50 results per query are allowed.
pub fn answer(
  builder builder: InlineQueryAnswer,
  ctx ctx: Context(session, error, dependencies),
  query_id query_id: String,
) -> Result(Bool, error.TelegaError) {
  api.answer_inline_query(
    ctx.config.api_client,
    parameters: AnswerInlineQueryParameters(
      inline_query_id: query_id,
      results: results(builder),
      cache_time: builder.cache_time,
      is_personal: builder.is_personal,
      next_offset: builder.next_offset,
      button: builder.button,
    ),
  )
}

/// Slice `items` for the page requested by `offset` (the raw
/// `InlineQuery.offset` string, empty on the first query) and compute the
/// offset of the next page, `None` when this page is the last one.
pub fn paginate(
  items items: List(a),
  offset offset: String,
  page_size page_size: Int,
) -> #(List(a), Option(String)) {
  let start = case int.parse(offset) {
    Ok(parsed) if parsed >= 0 -> parsed
    _ -> 0
  }

  let rest = list.drop(items, start)
  let page = list.take(rest, page_size)
  let next_offset = case list.length(rest) > page_size {
    True -> Some(int.to_string(start + page_size))
    False -> None
  }

  #(page, next_offset)
}
