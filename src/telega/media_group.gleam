//// Media Group Builder module for creating and sending groups of photos, videos, documents, and audio files.
////
//// This module provides a fluent builder API for constructing media groups (albums) that can be sent
//// via the Telegram Bot API. Media groups allow you to send multiple media files as a single message,
//// appearing as an album in the Telegram client.
////
//// ## Features
////
//// - **Builder Pattern**: Chain method calls to construct complex media groups
//// - **Type Safety**: Validates media compatibility at compile time
//// - **Flexible Input**: Supports URLs, file IDs, local files, and raw bytes
//// - **Rich Formatting**: Add captions with HTML/Markdown formatting
//// - **Validation**: Ensures media groups meet Telegram's requirements
////
//// ## Telegram API Constraints
////
//// - Media groups must contain 2-10 items
//// - Documents and audio files can only be grouped with media of the same type
//// - Photos and videos can be mixed in the same group
//// - Only the first media item's caption is prominently displayed
////
//// ## Examples
////
//// ### Simple Photo Album
//// ```gleam
//// let album = media_group.new()
////   |> media_group.add_photo_url("https://example.com/photo1.jpg", None)
////   |> media_group.add_photo_url_with_caption(
////        "https://example.com/photo2.jpg",
////        "Beautiful sunset"
////      )
////   |> media_group.validate_and_build()
//// ```
////
//// ### Mixed Media (Photos + Videos)
//// ```gleam
//// let mixed = media_group.new()
////   |> media_group.add_photo_url("https://example.com/photo.jpg", None)
////   |> media_group.add_video_url_with_caption(
////        "https://example.com/video.mp4",
////        "Amazing video"
////      )
////   |> media_group.validate_and_build()
//// ```
////
//// ### Document Group
//// ```gleam
//// let docs = media_group.new()
////   |> media_group.add_document(file.Url("https://example.com/doc1.pdf"), None)
////   |> media_group.add_document_with_caption(
////        file.Url("https://example.com/doc2.pdf"),
////        "Important document"
////      )
////   |> media_group.validate_and_build()
//// ```
////
//// ## Error Handling
////
//// The `validate_and_build` function returns a `Result` with possible errors:
//// - `InvalidMediaCount`: Less than 2 or more than 10 items
//// - `IncompatibleMediaTypes`: Mixing incompatible media types
//// - `EmptyMediaGroup`: No media items added
////
//// ## See Also
////
//// - [Telegram Bot API - sendMediaGroup](https://core.telegram.org/bots/api#sendmediagroup)
//// - [InputMedia types](https://core.telegram.org/bots/api#inputmedia)

import gleam/list
import gleam/option.{type Option, None, Some}

import telega/file.{type MediaInput}
import telega/model/types.{
  type InputMedia, type MessageEntity, InputMediaAnimation,
  InputMediaAnimationInputMedia, InputMediaAudio, InputMediaAudioInputMedia,
  InputMediaDocument, InputMediaDocumentInputMedia, InputMediaPhoto,
  InputMediaPhotoInputMedia, InputMediaVideo, InputMediaVideoInputMedia,
}

/// A builder for creating media groups
pub type MediaGroupBuilder {
  MediaGroupBuilder(media: List(InputMedia))
}

/// Media group validation errors
pub type MediaGroupError {
  /// Media group must contain 2-10 items
  InvalidMediaCount(count: Int)
  /// Media types cannot be mixed (except photo and video)
  IncompatibleMediaTypes
  /// Media group is empty
  EmptyMediaGroup
}

/// Media options for photos
pub type PhotoOptions {
  PhotoOptions(
    caption: Option(String),
    parse_mode: Option(String),
    caption_entities: Option(List(MessageEntity)),
    show_caption_above_media: Option(Bool),
    has_spoiler: Option(Bool),
  )
}

/// Media options for videos
pub type VideoOptions {
  VideoOptions(
    caption: Option(String),
    parse_mode: Option(String),
    caption_entities: Option(List(MessageEntity)),
    show_caption_above_media: Option(Bool),
    has_spoiler: Option(Bool),
    thumbnail: Option(String),
    width: Option(Int),
    height: Option(Int),
    duration: Option(Int),
    supports_streaming: Option(Bool),
  )
}

/// Media options for audio files
pub type AudioOptions {
  AudioOptions(
    caption: Option(String),
    parse_mode: Option(String),
    caption_entities: Option(List(MessageEntity)),
    duration: Option(Int),
    performer: Option(String),
    title: Option(String),
    thumbnail: Option(String),
  )
}

/// Media options for documents
pub type DocumentOptions {
  DocumentOptions(
    caption: Option(String),
    parse_mode: Option(String),
    caption_entities: Option(List(MessageEntity)),
    disable_content_type_detection: Option(Bool),
    thumbnail: Option(String),
  )
}

/// Media options for animations
pub type AnimationOptions {
  AnimationOptions(
    caption: Option(String),
    parse_mode: Option(String),
    caption_entities: Option(List(MessageEntity)),
    show_caption_above_media: Option(Bool),
    has_spoiler: Option(Bool),
    thumbnail: Option(String),
    width: Option(Int),
    height: Option(Int),
    duration: Option(Int),
  )
}

/// Creates a new empty media group builder.
///
/// This is the starting point for building a media group. Chain other methods
/// to add media items, then call `validate_and_build()` to get the final result.
pub fn new() -> MediaGroupBuilder {
  MediaGroupBuilder(media: [])
}

/// Adds a photo to the media group with optional formatting options.
///
/// ## Parameters
/// - `media`: The photo to add (URL, file ID, local file, or bytes)
/// - `options`: Optional formatting settings (caption, parse mode, spoiler, etc.)
///
/// ## Example
/// ```gleam
/// media_group.new()
/// |> media_group.add_photo(
///      file.Url("https://example.com/photo.jpg"),
///      Some(PhotoOptions(
///        caption: Some("Beautiful landscape"),
///        parse_mode: Some("HTML"),
///        has_spoiler: Some(False),
///        ..default_photo_options()
///      ))
///    )
/// ```
pub fn add_photo(
  builder: MediaGroupBuilder,
  media: MediaInput,
  options: Option(PhotoOptions),
) -> MediaGroupBuilder {
  let photo = case options {
    None ->
      InputMediaPhoto(
        type_: "photo",
        media: file.to_json_value(media),
        caption: None,
        parse_mode: None,
        caption_entities: None,
        show_caption_above_media: None,
        has_spoiler: None,
      )
    Some(opts) ->
      InputMediaPhoto(
        type_: "photo",
        media: file.to_json_value(media),
        caption: opts.caption,
        parse_mode: opts.parse_mode,
        caption_entities: opts.caption_entities,
        show_caption_above_media: opts.show_caption_above_media,
        has_spoiler: opts.has_spoiler,
      )
  }

  MediaGroupBuilder(
    media: list.append(builder.media, [
      InputMediaPhotoInputMedia(photo),
    ]),
  )
}

/// Adds a video to the media group with optional formatting options.
///
/// Videos can be mixed with photos in the same media group.
///
/// ## Parameters
/// - `media`: The video to add (URL, file ID, local file, or bytes)
/// - `options`: Optional video settings (caption, dimensions, duration, etc.)
pub fn add_video(
  builder: MediaGroupBuilder,
  media: MediaInput,
  options: Option(VideoOptions),
) -> MediaGroupBuilder {
  let video = case options {
    None ->
      InputMediaVideo(
        type_: "video",
        media: file.to_json_value(media),
        thumbnail: None,
        caption: None,
        parse_mode: None,
        caption_entities: None,
        show_caption_above_media: None,
        width: None,
        height: None,
        duration: None,
        supports_streaming: None,
        has_spoiler: None,
        cover: None,
        start_timestamp: None,
      )
    Some(opts) ->
      InputMediaVideo(
        type_: "video",
        media: file.to_json_value(media),
        thumbnail: opts.thumbnail,
        caption: opts.caption,
        parse_mode: opts.parse_mode,
        caption_entities: opts.caption_entities,
        show_caption_above_media: opts.show_caption_above_media,
        width: opts.width,
        height: opts.height,
        duration: opts.duration,
        supports_streaming: opts.supports_streaming,
        has_spoiler: opts.has_spoiler,
        cover: None,
        start_timestamp: None,
      )
  }

  MediaGroupBuilder(
    media: list.append(builder.media, [
      InputMediaVideoInputMedia(video),
    ]),
  )
}

/// Adds an audio file to the media group
pub fn add_audio(
  builder: MediaGroupBuilder,
  media: MediaInput,
  options: Option(AudioOptions),
) -> MediaGroupBuilder {
  let audio = case options {
    None ->
      InputMediaAudio(
        type_: "audio",
        media: file.to_json_value(media),
        thumbnail: None,
        caption: None,
        parse_mode: None,
        caption_entities: None,
        duration: None,
        performer: None,
        title: None,
      )
    Some(opts) ->
      InputMediaAudio(
        type_: "audio",
        media: file.to_json_value(media),
        thumbnail: opts.thumbnail,
        caption: opts.caption,
        parse_mode: opts.parse_mode,
        caption_entities: opts.caption_entities,
        duration: opts.duration,
        performer: opts.performer,
        title: opts.title,
      )
  }

  MediaGroupBuilder(
    media: list.append(builder.media, [
      InputMediaAudioInputMedia(audio),
    ]),
  )
}

/// Adds a document to the media group
pub fn add_document(
  builder: MediaGroupBuilder,
  media: MediaInput,
  options: Option(DocumentOptions),
) -> MediaGroupBuilder {
  let document = case options {
    None ->
      InputMediaDocument(
        type_: "document",
        media: file.to_json_value(media),
        thumbnail: None,
        caption: None,
        parse_mode: None,
        caption_entities: None,
        disable_content_type_detection: None,
      )
    Some(opts) ->
      InputMediaDocument(
        type_: "document",
        media: file.to_json_value(media),
        thumbnail: opts.thumbnail,
        caption: opts.caption,
        parse_mode: opts.parse_mode,
        caption_entities: opts.caption_entities,
        disable_content_type_detection: opts.disable_content_type_detection,
      )
  }

  MediaGroupBuilder(
    media: list.append(builder.media, [
      InputMediaDocumentInputMedia(document),
    ]),
  )
}

/// Adds an animation to the media group
pub fn add_animation(
  builder: MediaGroupBuilder,
  media: MediaInput,
  options: Option(AnimationOptions),
) -> MediaGroupBuilder {
  let animation = case options {
    None ->
      InputMediaAnimation(
        type_: "animation",
        media: file.to_json_value(media),
        thumbnail: None,
        caption: None,
        parse_mode: None,
        caption_entities: None,
        show_caption_above_media: None,
        width: None,
        height: None,
        duration: None,
        has_spoiler: None,
      )
    Some(opts) ->
      InputMediaAnimation(
        type_: "animation",
        media: file.to_json_value(media),
        thumbnail: opts.thumbnail,
        caption: opts.caption,
        parse_mode: opts.parse_mode,
        caption_entities: opts.caption_entities,
        show_caption_above_media: opts.show_caption_above_media,
        width: opts.width,
        height: opts.height,
        duration: opts.duration,
        has_spoiler: opts.has_spoiler,
      )
  }

  MediaGroupBuilder(
    media: list.append(builder.media, [
      InputMediaAnimationInputMedia(animation),
    ]),
  )
}

/// Builds the media group and returns the list of InputMedia
pub fn build(builder: MediaGroupBuilder) -> List(InputMedia) {
  builder.media
}

/// Validates and builds the final media group.
///
/// This function checks that the media group meets Telegram's requirements:
/// - Contains 2-10 items
/// - Uses compatible media types
/// - Is not empty
pub fn validate_and_build(
  builder: MediaGroupBuilder,
) -> Result(List(InputMedia), MediaGroupError) {
  let count = list.length(builder.media)

  case count {
    0 -> Error(EmptyMediaGroup)
    1 -> Error(InvalidMediaCount(count))
    n if n > 10 -> Error(InvalidMediaCount(count))
    _ -> {
      // Check if media types are compatible
      case is_compatible_media_types(builder.media) {
        True -> Ok(builder.media)
        False -> Error(IncompatibleMediaTypes)
      }
    }
  }
}

/// Checks if media types in the group are compatible
/// Photos and videos can be mixed, but audio and documents must be grouped separately
fn is_compatible_media_types(media: List(InputMedia)) -> Bool {
  let types = list.map(media, get_media_type)
  let unique_types = list.unique(types)

  case unique_types {
    // Single type is always compatible
    [_] -> True
    // Photos and videos can be mixed
    ["photo", "video"] | ["video", "photo"] -> True
    // Any other combination is incompatible
    _ -> False
  }
}

/// Gets the type of an InputMedia item
fn get_media_type(media: InputMedia) -> String {
  case media {
    InputMediaPhotoInputMedia(_) -> "photo"
    InputMediaVideoInputMedia(_) -> "video"
    InputMediaAudioInputMedia(_) -> "audio"
    InputMediaDocumentInputMedia(_) -> "document"
    InputMediaAnimationInputMedia(_) -> "animation"
  }
}

/// Helper function to create default photo options
pub fn default_photo_options() -> PhotoOptions {
  PhotoOptions(
    caption: None,
    parse_mode: None,
    caption_entities: None,
    show_caption_above_media: None,
    has_spoiler: None,
  )
}

/// Helper function to create default video options
pub fn default_video_options() -> VideoOptions {
  VideoOptions(
    caption: None,
    parse_mode: None,
    caption_entities: None,
    show_caption_above_media: None,
    has_spoiler: None,
    thumbnail: None,
    width: None,
    height: None,
    duration: None,
    supports_streaming: None,
  )
}

/// Helper function to create default audio options
pub fn default_audio_options() -> AudioOptions {
  AudioOptions(
    caption: None,
    parse_mode: None,
    caption_entities: None,
    duration: None,
    performer: None,
    title: None,
    thumbnail: None,
  )
}

/// Helper function to create default document options
pub fn default_document_options() -> DocumentOptions {
  DocumentOptions(
    caption: None,
    parse_mode: None,
    caption_entities: None,
    disable_content_type_detection: None,
    thumbnail: None,
  )
}

/// Helper function to create default animation options
pub fn default_animation_options() -> AnimationOptions {
  AnimationOptions(
    caption: None,
    parse_mode: None,
    caption_entities: None,
    show_caption_above_media: None,
    has_spoiler: None,
    thumbnail: None,
    width: None,
    height: None,
    duration: None,
  )
}

/// Creates a standalone photo InputMedia with a caption.
///
/// Useful when you need to create a single photo for direct use
/// without the builder pattern.
pub fn photo_with_caption(media: MediaInput, caption: String) -> InputMedia {
  InputMediaPhotoInputMedia(InputMediaPhoto(
    type_: "photo",
    media: file.to_json_value(media),
    caption: Some(caption),
    parse_mode: None,
    caption_entities: None,
    show_caption_above_media: None,
    has_spoiler: None,
  ))
}

/// Creates a video with caption
pub fn video_with_caption(media: MediaInput, caption: String) -> InputMedia {
  InputMediaVideoInputMedia(InputMediaVideo(
    type_: "video",
    media: file.to_json_value(media),
    caption: Some(caption),
    parse_mode: None,
    caption_entities: None,
    thumbnail: None,
    show_caption_above_media: None,
    width: None,
    height: None,
    duration: None,
    supports_streaming: None,
    has_spoiler: None,
    cover: None,
    start_timestamp: None,
  ))
}

/// Add a photo from a file path
pub fn add_photo_file(
  builder: MediaGroupBuilder,
  path: String,
  options: Option(PhotoOptions),
) -> MediaGroupBuilder {
  add_photo(builder, file.from_file(path), options)
}

/// Convenience function to add a photo from a URL.
///
/// This is a shorthand for `add_photo(builder, file.Url(url), options)`.
pub fn add_photo_url(
  builder: MediaGroupBuilder,
  url: String,
  options: Option(PhotoOptions),
) -> MediaGroupBuilder {
  add_photo(builder, file.Url(url), options)
}

/// Convenience function to add a photo with just a caption.
///
/// Use this when you only need to set a caption without other formatting options.
pub fn add_photo_with_caption(
  builder: MediaGroupBuilder,
  media: MediaInput,
  caption: String,
) -> MediaGroupBuilder {
  add_photo(
    builder,
    media,
    Some(PhotoOptions(
      caption: Some(caption),
      parse_mode: None,
      caption_entities: None,
      show_caption_above_media: None,
      has_spoiler: None,
    )),
  )
}

/// Convenience function to add a photo from URL with a caption.
///
/// Combines URL input and caption setting in a single call.
pub fn add_photo_url_with_caption(
  builder: MediaGroupBuilder,
  url: String,
  caption: String,
) -> MediaGroupBuilder {
  add_photo_with_caption(builder, file.Url(url), caption)
}

/// Add a video from a file path
pub fn add_video_file(
  builder: MediaGroupBuilder,
  path: String,
  options: Option(VideoOptions),
) -> MediaGroupBuilder {
  add_video(builder, file.from_file(path), options)
}

/// Add a video from a URL
pub fn add_video_url(
  builder: MediaGroupBuilder,
  url: String,
  options: Option(VideoOptions),
) -> MediaGroupBuilder {
  add_video(builder, file.Url(url), options)
}

/// Add a video with caption (convenience function)
pub fn add_video_with_caption(
  builder: MediaGroupBuilder,
  media: MediaInput,
  caption: String,
) -> MediaGroupBuilder {
  add_video(
    builder,
    media,
    Some(VideoOptions(
      caption: Some(caption),
      parse_mode: None,
      caption_entities: None,
      show_caption_above_media: None,
      has_spoiler: None,
      thumbnail: None,
      width: None,
      height: None,
      duration: None,
      supports_streaming: None,
    )),
  )
}

/// Add a video URL with caption (convenience function)
pub fn add_video_url_with_caption(
  builder: MediaGroupBuilder,
  url: String,
  caption: String,
) -> MediaGroupBuilder {
  add_video_with_caption(builder, file.Url(url), caption)
}

/// Add a document from a file path
pub fn add_document_file(
  builder: MediaGroupBuilder,
  path: String,
  options: Option(DocumentOptions),
) -> MediaGroupBuilder {
  add_document(builder, file.from_file(path), options)
}

/// Add a document with caption (convenience function)
pub fn add_document_with_caption(
  builder: MediaGroupBuilder,
  media: MediaInput,
  caption: String,
) -> MediaGroupBuilder {
  add_document(
    builder,
    media,
    Some(DocumentOptions(
      caption: Some(caption),
      parse_mode: None,
      caption_entities: None,
      disable_content_type_detection: None,
      thumbnail: None,
    )),
  )
}

/// Add an audio file with caption (convenience function)
pub fn add_audio_with_caption(
  builder: MediaGroupBuilder,
  media: MediaInput,
  caption: String,
) -> MediaGroupBuilder {
  add_audio(
    builder,
    media,
    Some(AudioOptions(
      caption: Some(caption),
      parse_mode: None,
      caption_entities: None,
      duration: None,
      performer: None,
      title: None,
      thumbnail: None,
    )),
  )
}

/// Checks if any media in the group requires multipart upload
pub fn requires_multipart(builder: MediaGroupBuilder) -> Bool {
  list.any(builder.media, fn(media) {
    case media {
      InputMediaPhotoInputMedia(photo) ->
        file.requires_multipart(file.from_string(photo.media))
      InputMediaVideoInputMedia(video) ->
        file.requires_multipart(file.from_string(video.media))
      InputMediaAudioInputMedia(audio) ->
        file.requires_multipart(file.from_string(audio.media))
      InputMediaDocumentInputMedia(document) ->
        file.requires_multipart(file.from_string(document.media))
      InputMediaAnimationInputMedia(animation) ->
        file.requires_multipart(file.from_string(animation.media))
    }
  })
}

/// Creates a media group from a list of photo URLs.
///
/// Convenient helper for quickly creating a photo album from URLs.
pub fn from_photo_urls(urls: List(String)) -> MediaGroupBuilder {
  list.fold(urls, new(), fn(builder, url) { add_photo_url(builder, url, None) })
}

/// Creates a media group from a list of photo URLs with captions
pub fn from_photos_with_captions(
  photos: List(#(String, String)),
) -> MediaGroupBuilder {
  list.fold(photos, new(), fn(builder, photo) {
    let #(url, caption) = photo
    add_photo_url(
      builder,
      url,
      Some(PhotoOptions(
        caption: Some(caption),
        parse_mode: None,
        caption_entities: None,
        show_caption_above_media: None,
        has_spoiler: None,
      )),
    )
  })
}

/// Creates a media group from a list of video URLs
pub fn from_video_urls(urls: List(String)) -> MediaGroupBuilder {
  list.fold(urls, new(), fn(builder, url) { add_video_url(builder, url, None) })
}

/// Gets the count of media items in the builder.
///
/// Useful for checking if you're within the 2-10 item limit.
pub fn count(builder: MediaGroupBuilder) -> Int {
  list.length(builder.media)
}

/// Checks if the builder is empty
pub fn is_empty(builder: MediaGroupBuilder) -> Bool {
  list.is_empty(builder.media)
}

/// Gets the first media item if it exists
pub fn first(builder: MediaGroupBuilder) -> Option(InputMedia) {
  list.first(builder.media) |> option.from_result
}

/// Gets the last media item if it exists
pub fn last(builder: MediaGroupBuilder) -> Option(InputMedia) {
  list.last(builder.media) |> option.from_result
}
