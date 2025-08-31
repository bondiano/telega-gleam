import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import telega/media_group.{DocumentOptions, PhotoOptions, VideoOptions}
import telega/model/types.{
  InputMediaDocumentInputMedia, InputMediaPhotoInputMedia,
  InputMediaVideoInputMedia,
}

pub fn main() {
  gleeunit.main()
}

pub fn new_builder_test() {
  let builder = media_group.new()
  let media = media_group.build(builder)

  media
  |> list.length()
  |> should.equal(0)
}

pub fn add_photo_test() {
  let builder =
    media_group.new()
    |> media_group.add_photo("photo.jpg", None)
    |> media_group.add_photo(
      "photo2.jpg",
      Some(PhotoOptions(
        caption: Some("Test caption"),
        parse_mode: Some("Markdown"),
        caption_entities: None,
        show_caption_above_media: None,
        has_spoiler: None,
      )),
    )

  let media = media_group.build(builder)

  media
  |> list.length()
  |> should.equal(2)

  // Check first photo
  case list.first(media) {
    Ok(InputMediaPhotoInputMedia(photo)) -> {
      photo.media |> should.equal("photo.jpg")
      photo.caption |> should.equal(None)
    }
    _ -> panic as "Expected InputMediaPhotoInputMedia"
  }

  // Check second photo
  case list.drop(media, 1) |> list.first() {
    Ok(InputMediaPhotoInputMedia(photo)) -> {
      photo.media |> should.equal("photo2.jpg")
      photo.caption |> should.equal(Some("Test caption"))
      photo.parse_mode |> should.equal(Some("Markdown"))
    }
    _ -> panic as "Expected InputMediaPhotoInputMedia"
  }
}

pub fn add_video_test() {
  let builder =
    media_group.new()
    |> media_group.add_video("video.mp4", None)
    |> media_group.add_video(
      "video2.mp4",
      Some(VideoOptions(
        caption: Some("Video caption"),
        parse_mode: Some("HTML"),
        caption_entities: None,
        show_caption_above_media: Some(True),
        has_spoiler: None,
        thumbnail: None,
        width: Some(1920),
        height: Some(1080),
        duration: Some(60),
        supports_streaming: Some(True),
      )),
    )

  let media = media_group.build(builder)

  media
  |> list.length()
  |> should.equal(2)

  // Check second video
  case list.drop(media, 1) |> list.first() {
    Ok(InputMediaVideoInputMedia(video)) -> {
      video.media |> should.equal("video2.mp4")
      video.caption |> should.equal(Some("Video caption"))
      video.width |> should.equal(Some(1920))
      video.height |> should.equal(Some(1080))
      video.duration |> should.equal(Some(60))
      video.supports_streaming |> should.equal(Some(True))
    }
    _ -> panic as "Expected InputMediaVideoInputMedia"
  }
}

pub fn mixed_media_test() {
  let builder =
    media_group.new()
    |> media_group.add_photo("photo.jpg", None)
    |> media_group.add_video("video.mp4", None)
    |> media_group.add_photo(
      "photo2.jpg",
      Some(PhotoOptions(
        caption: Some("Last photo"),
        parse_mode: None,
        caption_entities: None,
        show_caption_above_media: None,
        has_spoiler: Some(True),
      )),
    )

  let media = media_group.build(builder)

  media
  |> list.length()
  |> should.equal(3)

  // Verify order and types
  case media {
    [
      InputMediaPhotoInputMedia(_),
      InputMediaVideoInputMedia(_),
      InputMediaPhotoInputMedia(last_photo),
    ] -> {
      last_photo.has_spoiler |> should.equal(Some(True))
    }
    _ -> panic as "Unexpected media order or types"
  }
}

pub fn add_document_test() {
  let builder =
    media_group.new()
    |> media_group.add_document("document.pdf", None)
    |> media_group.add_document(
      "document2.pdf",
      Some(DocumentOptions(
        caption: Some("Important document"),
        parse_mode: None,
        caption_entities: None,
        disable_content_type_detection: Some(True),
        thumbnail: Some("thumb.jpg"),
      )),
    )

  let media = media_group.build(builder)

  media
  |> list.length()
  |> should.equal(2)

  case list.drop(media, 1) |> list.first() {
    Ok(InputMediaDocumentInputMedia(doc)) -> {
      doc.caption |> should.equal(Some("Important document"))
      doc.disable_content_type_detection |> should.equal(Some(True))
      doc.thumbnail |> should.equal(Some("thumb.jpg"))
    }
    _ -> panic as "Expected InputMediaDocumentInputMedia"
  }
}

pub fn helper_functions_test() {
  // Test photo with caption helper
  let photo = media_group.photo_with_caption("photo.jpg", "Caption")
  case photo {
    InputMediaPhotoInputMedia(p) -> {
      p.media |> should.equal("photo.jpg")
      p.caption |> should.equal(Some("Caption"))
    }
    _ -> panic as "Expected InputMediaPhotoInputMedia"
  }

  // Test video with caption helper
  let video = media_group.video_with_caption("video.mp4", "Video caption")
  case video {
    InputMediaVideoInputMedia(v) -> {
      v.media |> should.equal("video.mp4")
      v.caption |> should.equal(Some("Video caption"))
    }
    _ -> panic as "Expected InputMediaVideoInputMedia"
  }
}

pub fn default_options_test() {
  // Test default photo options
  let photo_opts = media_group.default_photo_options()
  photo_opts.caption |> should.equal(None)
  photo_opts.parse_mode |> should.equal(None)
  photo_opts.has_spoiler |> should.equal(None)

  // Test default video options
  let video_opts = media_group.default_video_options()
  video_opts.width |> should.equal(None)
  video_opts.height |> should.equal(None)
  video_opts.duration |> should.equal(None)

  // Test default audio options
  let audio_opts = media_group.default_audio_options()
  audio_opts.performer |> should.equal(None)
  audio_opts.title |> should.equal(None)

  // Test default document options
  let doc_opts = media_group.default_document_options()
  doc_opts.disable_content_type_detection |> should.equal(None)
}
