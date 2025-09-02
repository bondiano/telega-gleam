# Media Group Bot Example

A Telegram bot that processes image URLs and sends them back as photos or media groups (albums).

## Features

- 🔗 **URL Processing**: Send image URLs and the bot uploads them to Telegram
- 🖼️ **Smart Grouping**:
  - 1 URL → Single photo
  - 2+ URLs → Media group (album)
- 💾 **File Downloads**: Downloads received photos to `/tmp/`
- 📝 **Flexible Input**: Supports URLs separated by spaces or newlines

## Usage

### Setup

```bash
export BOT_TOKEN="your_bot_token_here"
gleam run

# or
BOT_TOKEN="your_bot_token_here" gleam run
```

**Note:** The bot will fail to start if `BOT_TOKEN` is not set.

### Commands

- `/start` or `/help` - Show usage instructions

### Sending URLs

Send image URLs in any format:

```
# Single URL
https://example.com/photo.jpg

# Multiple URLs (space-separated)
https://example.com/photo1.jpg https://example.com/photo2.jpg

# Multiple URLs (newline-separated)
https://example.com/photo1.jpg
https://example.com/photo2.jpg
https://example.com/photo3.jpg
```

## Architecture

```
handle_text()
├── extract_urls() - Parse URLs from message
├── send_single_photo() - Send one photo
└── send_media_group() - Send multiple photos

handle_photo() - Download single photos
handle_media_group() - Download photo albums
```

## Key Functions

- **`extract_urls()`** - Parses text for HTTP/HTTPS URLs
- **`send_single_photo()`** - Uploads single image from URL
- **`send_media_group()`** - Creates and sends media album
- **`download_largest_photo()`** - Downloads highest resolution photo
- **`get_domain()`** - Extracts domain for captions

## Technical Details

### Media Input Types
- `file.Url()` - For HTTP/HTTPS URLs
- `file.FileId()` - For reusing uploaded files
- `file.LocalFile()` - For local file uploads

### File Downloads
```gleam
file.download_to_file(client, file_id, save_path)
```

## Dependencies

- `telega` - Telegram Bot API
- `envoy` - Environment variables

## Example Output

**Single URL:**
```
User: https://example.com/photo.jpg
Bot: 📥 Processing image...
Bot: [Photo with caption "🖼️ From: example.com"]
```

**Multiple URLs:**
```
User: https://example.com/photo1.jpg
      https://example.com/photo2.jpg
Bot: 📥 Processing 2 images...
Bot: [Media group with 2 photos]
Bot: ✅ Sent 2 images!
```