import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/string

import telega/bot
import telega/error
import telega/file
import telega/format as fmt
import telega/media_group
import telega/model/types
import telega/reply

/// Extract URLs from text (supports newline and space separation)
pub fn extract_urls(text: String) -> List(String) {
  text
  |> string.split("\n")
  |> list.flat_map(fn(line) { string.split(line, " ") })
  |> list.map(string.trim)
  |> list.filter(fn(s) { string.length(s) > 0 })
  |> list.filter(is_url)
  |> list.map(clean_github_url)
}

/// Clean GitHub URLs - convert blob URLs to raw URLs
fn clean_github_url(url: String) -> String {
  case string.contains(url, "github.com") && string.contains(url, "/blob/") {
    True -> {
      url
      |> string.replace("/blob/", "/raw/")
      |> string.replace("?raw=true", "")
    }
    False -> url
  }
}

/// Check if string is a URL
pub fn is_url(text: String) -> Bool {
  string.starts_with(text, "http://") || string.starts_with(text, "https://")
}

/// Extract domain from URL
pub fn get_domain(url: String) -> String {
  url
  |> string.replace("https://", "")
  |> string.replace("http://", "")
  |> string.split("/")
  |> list.first()
  |> result.unwrap("unknown")
}

/// Handle case when no URLs found in message
pub fn handle_no_urls(ctx: bot.Context(session, error.TelegaError)) {
  let message =
    fmt.build()
    |> fmt.text("🤔 ")
    |> fmt.bold_text("No URLs found!")
    |> fmt.line_break()
    |> fmt.line_break()
    |> fmt.text("Send me image URLs and I'll upload them to Telegram.")
    |> fmt.line_break()
    |> fmt.text("Use ")
    |> fmt.code_text("/help")
    |> fmt.text(" for instructions.")
    |> fmt.to_formatted()

  reply.with_formatted(ctx, message)
  |> result.map(fn(_) { ctx })
}

/// Send a single photo from URL
pub fn send_single_photo(
  ctx: bot.Context(session, error.TelegaError),
  url: String,
) {
  let _ = reply.with_text(ctx, "📥 Processing image...")

  let caption = "🖼️ From: " <> get_domain(url)
  let photo = media_group.photo_with_caption(file.Url(url), caption)

  case reply.with_media_group(ctx, [photo]) {
    Ok(_) -> Ok(ctx)
    Error(_) -> {
      // Real error occurred
      let error_msg =
        fmt.build()
        |> fmt.text("❌ ")
        |> fmt.bold_text("Failed to send image")
        |> fmt.line_break()
        |> fmt.text("Check if the URL is valid and points to an image.")
        |> fmt.to_formatted()

      reply.with_formatted(ctx, error_msg)
      |> result.map(fn(_) { ctx })
    }
  }
}

pub fn send_media_group(
  ctx: bot.Context(session, error.TelegaError),
  urls: List(String),
) {
  let count = list.length(urls)

  let processing_msg =
    fmt.build()
    |> fmt.text("📥 Processing ")
    |> fmt.bold_text(int.to_string(count) <> " images")
    |> fmt.text("...")
    |> fmt.to_formatted()

  let _ = reply.with_formatted(ctx, processing_msg)

  // Log URLs for debugging
  io.println("📝 Processing URLs:")
  list.each(urls, fn(url) { io.println("  - " <> url) })

  let builder =
    urls
    |> list.index_fold(media_group.new(), fn(builder, url, index) {
      let caption = case index {
        0 -> "🖼️ [1/" <> int.to_string(count) <> "] " <> get_domain(url)
        _ ->
          "🖼️ ["
          <> int.to_string(index + 1)
          <> "/"
          <> int.to_string(count)
          <> "]"
      }

      media_group.add_photo_url_with_caption(builder, url, caption)
    })

  case media_group.validate_and_build(builder) {
    Error(media_group.InvalidMediaCount(n)) -> {
      let error_msg =
        fmt.build()
        |> fmt.text("❌ ")
        |> fmt.bold_text("Invalid media count")
        |> fmt.line_break()
        |> fmt.text("Media groups must contain 2-10 items (got ")
        |> fmt.bold_text(int.to_string(n))
        |> fmt.text(")")
        |> fmt.to_formatted()

      reply.with_formatted(ctx, error_msg)
      |> result.map(fn(_) { ctx })
    }
    Error(_) -> {
      let error_msg =
        fmt.build()
        |> fmt.text("❌ ")
        |> fmt.bold_text("Failed to create media group")
        |> fmt.line_break()
        |> fmt.text("Please check your URLs and try again.")
        |> fmt.to_formatted()

      reply.with_formatted(ctx, error_msg)
      |> result.map(fn(_) { ctx })
    }
    Ok(validated_media) -> {
      case reply.with_media_group(ctx, validated_media) {
        Ok(_messages) -> {
          // Successfully sent
          let success_msg =
            fmt.build()
            |> fmt.text("✅ Successfully sent ")
            |> fmt.bold_text(int.to_string(count) <> " images")
            |> fmt.text("!")
            |> fmt.to_formatted()

          reply.with_formatted(ctx, success_msg)
          |> result.map(fn(_) { ctx })
        }
        Error(_) -> {
          // Real error occurred
          let error_msg =
            fmt.build()
            |> fmt.text("❌ ")
            |> fmt.bold_text("Failed to send media group")
            |> fmt.line_break()
            |> fmt.text("Some URLs might be invalid or not point to images.")
            |> fmt.to_formatted()

          reply.with_formatted(ctx, error_msg)
          |> result.map(fn(_) { ctx })
        }
      }
    }
  }
}

pub fn download_largest_photo(
  ctx: bot.Context(session, error.TelegaError),
  photos: List(types.PhotoSize),
  index: Int,
) -> option.Option(String) {
  case list.last(photos) {
    Ok(photo) -> {
      let path = "/tmp/photo_" <> int.to_string(index + 1) <> ".jpg"
      io.println("📥 Attempting to download photo to: " <> path)
      io.println("   File ID: " <> photo.file_id)
      
      case file.download_to_file(ctx.config.api_client, photo.file_id, path) {
        Ok(_) -> {
          io.println("✅ Successfully downloaded to: " <> path)
          option.Some(path)
        }
        Error(err) -> {
          io.println("❌ Download failed: " <> err)
          option.None
        }
      }
    }
    Error(_) -> {
      io.println("❌ No photos in the list")
      option.None
    }
  }
}

pub fn download_media_group_photos(
  ctx: bot.Context(session, error.TelegaError),
  messages: List(types.Message),
) -> List(String) {
  messages
  |> list.index_map(fn(msg, index) {
    case msg.photo {
      option.Some(photos) -> download_largest_photo(ctx, photos, index)
      option.None -> option.None
    }
  })
  |> list.filter_map(fn(opt) {
    case opt {
      option.Some(path) -> Ok(path)
      option.None -> Error(Nil)
    }
  })
}
