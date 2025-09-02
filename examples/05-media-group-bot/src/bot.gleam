import envoy
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result

import telega
import telega/error
import telega/format as fmt
import telega/model/types
import telega/polling
import telega/reply
import telega/router
import telega/update

import utils

fn handle_help(ctx, _command: update.Command) {
  use ctx <- telega.log_context(ctx, "help_command")

  let message =
    fmt.build()
    |> fmt.text("🖼️ ")
    |> fmt.bold_text("Image URL Bot")
    |> fmt.line_break()
    |> fmt.line_break()
    |> fmt.text("Send me image URLs and I'll upload them to Telegram!")
    |> fmt.line_break()
    |> fmt.line_break()
    |> fmt.bold_text("How it works:")
    |> fmt.line_break()
    |> fmt.text("• 1 URL → Single photo")
    |> fmt.line_break()
    |> fmt.text("• 2+ URLs → Media group (album)")
    |> fmt.line_break()
    |> fmt.line_break()
    |> fmt.bold_text("Examples:")
    |> fmt.line_break()
    |> fmt.code_text("https://example.com/photo.jpg")
    |> fmt.line_break()
    |> fmt.text("or multiple URLs:")
    |> fmt.line_break()
    |> fmt.pre_text(
      "https://example.com/photo1.jpg\nhttps://example.com/photo2.jpg",
      None,
    )
    |> fmt.line_break()
    |> fmt.line_break()
    |> fmt.text("💡 URLs can be space or newline separated")
    |> fmt.to_formatted()

  reply.with_formatted(ctx, message)
  |> result.map(fn(_) { ctx })
}

fn handle_text(ctx, text) {
  use ctx <- telega.log_context(ctx, "text_message")

  let urls = utils.extract_urls(text)

  case urls {
    [] -> utils.handle_no_urls(ctx)
    [single_url] -> utils.send_single_photo(ctx, single_url)
    multiple_urls -> utils.send_media_group(ctx, multiple_urls)
  }
}

fn handle_media_group(ctx, _media_group_id, messages: List(types.Message)) {
  use ctx <- telega.log_context(ctx, "media_group_received")

  let count = list.length(messages)
  let downloaded = utils.download_media_group_photos(ctx, messages)

  let message = case downloaded {
    [] -> "📸 Received " <> int.to_string(count) <> " items"
    files -> {
      "📸 Received "
      <> int.to_string(count)
      <> " items\n"
      <> "💾 Downloaded: "
      <> int.to_string(list.length(files))
      <> " photos"
    }
  }

  reply.with_text(ctx, message)
  |> result.map(fn(_) { ctx })
  |> result.map_error(fn(_) { error.FetchError("Failed to send message") })
}

fn handle_photo(ctx, photo_sizes: List(types.PhotoSize)) {
  use ctx <- telega.log_context(ctx, "photo_received")

  case utils.download_largest_photo(ctx, photo_sizes, 0) {
    Some(path) -> {
      let msg =
        fmt.build()
        |> fmt.text("📸 Photo saved to: ")
        |> fmt.code_text(path)
        |> fmt.line_break()
        |> fmt.line_break()
        |> fmt.text("💡 ")
        |> fmt.italic_text("Send me URLs to upload images to Telegram!")
        |> fmt.to_formatted()

      reply.with_formatted(ctx, msg)
      |> result.map(fn(_) { ctx })
      |> result.map_error(fn(_) { error.FetchError("Failed to send message") })
    }
    None -> {
      reply.with_text(ctx, "❌ Failed to save photo")
      |> result.map(fn(_) { ctx })
      |> result.map_error(fn(_) { error.FetchError("Failed to send message") })
    }
  }
}

pub fn main() {
  let assert Ok(token) = envoy.get("BOT_TOKEN")

  let router =
    router.new("image_url_bot")
    |> router.on_commands(["help", "start"], handle_help)
    |> router.on_media_group(handle_media_group)
    |> router.on_photo(handle_photo)
    |> router.on_any_text(handle_text)

  let assert Ok(bot) =
    telega.new_for_polling(token:)
    |> telega.with_router(router)
    |> telega.init_for_polling_nil_session()

  io.println("✨ Image URL Bot started!")
  io.println("📷 Send me image URLs to upload them to Telegram")
  io.println("💡 Use /help for instructions")

  let assert Ok(poller) = polling.start_polling_default(bot)
  polling.wait_finish(poller)
}
