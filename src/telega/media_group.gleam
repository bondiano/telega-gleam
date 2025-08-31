//// Media Group Builder module for creating and sending groups of photos and videos.
//// This module provides a builder pattern, allowing you to easily construct media groups for sending via Telegram Bot API.

import gleam/list
import gleam/option.{type Option, None, Some}

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

/// Creates a new empty media group builder
pub fn new() -> MediaGroupBuilder {
  MediaGroupBuilder(media: [])
}

/// Adds a photo to the media group
///
/// ## Example
/// ```gleam
/// media_group.new()
/// |> media_group.add_photo("https://example.com/photo.jpg", None)
/// ```
pub fn add_photo(
  builder: MediaGroupBuilder,
  media: String,
  options: Option(PhotoOptions),
) -> MediaGroupBuilder {
  let photo = case options {
    None ->
      InputMediaPhoto(
        type_: "photo",
        media:,
        caption: None,
        parse_mode: None,
        caption_entities: None,
        show_caption_above_media: None,
        has_spoiler: None,
      )
    Some(opts) ->
      InputMediaPhoto(
        type_: "photo",
        media:,
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

/// Adds a video to the media group
///
/// ## Example
/// ```gleam
/// media_group.new()
/// |> media_group.add_video("/path/to/video.mp4", Some(VideoOptions(
///   caption: Some("My video"),
///   parse_mode: Some("Markdown"),
///   ..default_video_options()
/// )))
/// ```
pub fn add_video(
  builder: MediaGroupBuilder,
  media: String,
  options: Option(VideoOptions),
) -> MediaGroupBuilder {
  let video = case options {
    None ->
      InputMediaVideo(
        type_: "video",
        media:,
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
        media:,
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
  media: String,
  options: Option(AudioOptions),
) -> MediaGroupBuilder {
  let audio = case options {
    None ->
      InputMediaAudio(
        type_: "audio",
        media:,
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
        media:,
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
  media: String,
  options: Option(DocumentOptions),
) -> MediaGroupBuilder {
  let document = case options {
    None ->
      InputMediaDocument(
        type_: "document",
        media:,
        thumbnail: None,
        caption: None,
        parse_mode: None,
        caption_entities: None,
        disable_content_type_detection: None,
      )
    Some(opts) ->
      InputMediaDocument(
        type_: "document",
        media:,
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
  media: String,
  options: Option(AnimationOptions),
) -> MediaGroupBuilder {
  let animation = case options {
    None ->
      InputMediaAnimation(
        type_: "animation",
        media:,
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
        media:,
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

/// Creates a photo with caption
pub fn photo_with_caption(media: String, caption: String) -> InputMedia {
  InputMediaPhotoInputMedia(InputMediaPhoto(
    type_: "photo",
    media:,
    caption: Some(caption),
    parse_mode: None,
    caption_entities: None,
    show_caption_above_media: None,
    has_spoiler: None,
  ))
}

/// Creates a video with caption
pub fn video_with_caption(media: String, caption: String) -> InputMedia {
  InputMediaVideoInputMedia(InputMediaVideo(
    type_: "video",
    media:,
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
