//// File handling utilities for Telegram Bot API
//// Provides types and functions for working with files in media uploads

import gleam/http/request
import gleam/httpc
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile

import telega/api
import telega/client.{type TelegramClient}
import telega/model/types.{type File}

/// Represents different ways to specify media in Telegram Bot API
pub type MediaInput {
  /// HTTP or HTTPS URL to a file on the internet
  Url(url: String)

  /// File ID of a previously uploaded file (for reuse)
  FileId(file_id: String)

  /// Local file path for multipart upload
  /// The attach_name is used to reference the file in the multipart form
  LocalFile(path: String, attach_name: String)

  /// Raw bytes for direct upload
  Bytes(data: BitArray, filename: String, attach_name: String)
}

/// Creates a MediaInput from a string that could be URL or file ID
pub fn from_string(value: String) -> MediaInput {
  case
    string.starts_with(value, "http://"),
    string.starts_with(value, "https://")
  {
    True, _ | _, True -> Url(value)
    _, _ -> FileId(value)
  }
}

/// Creates a MediaInput from a local file path
pub fn from_file(path: String) -> MediaInput {
  let attach_name = "file_" <> string.replace(path, "/", "_")
  LocalFile(path, attach_name)
}

/// Creates a MediaInput from a local file path with custom attach name
pub fn from_file_with_name(path: String, attach_name: String) -> MediaInput {
  LocalFile(path, attach_name)
}

/// Creates a MediaInput from bytes
pub fn from_bytes(data: BitArray, filename: String) -> MediaInput {
  let attach_name = "bytes_" <> filename
  Bytes(data, filename, attach_name)
}

/// Reads a file and creates a MediaInput with its contents
pub fn read_file(path: String) -> Result(MediaInput, simplifile.FileError) {
  use data <- result.try(simplifile.read_bits(path))
  let filename = case string.split(path, "/") {
    [] -> "file"
    parts -> {
      case list.last(parts) {
        Ok(name) -> name
        Error(_) -> "file"
      }
    }
  }
  Ok(from_bytes(data, filename))
}

/// Gets the string representation for JSON encoding
/// For local files and bytes, returns the attach:// reference
pub fn to_json_value(input: MediaInput) -> String {
  case input {
    Url(url) -> url
    FileId(id) -> id
    LocalFile(_, attach_name) -> "attach://" <> attach_name
    Bytes(_, _, attach_name) -> "attach://" <> attach_name
  }
}

/// Checks if this MediaInput requires multipart upload
pub fn requires_multipart(input: MediaInput) -> Bool {
  case input {
    LocalFile(..) | Bytes(..) -> True
    Url(..) | FileId(..) -> False
  }
}

/// Gets the attach name if this is a local file or bytes
pub fn get_attach_name(input: MediaInput) -> Option(String) {
  case input {
    LocalFile(_, name) | Bytes(_, _, name) -> Some(name)
    _ -> None
  }
}

/// Information needed for multipart file upload
pub type MultipartFile {
  MultipartFile(
    /// Field name in the multipart form
    field_name: String,
    /// File name to send
    filename: String,
    /// File content
    content: BitArray,
    /// MIME type (optional)
    mime_type: Option(String),
  )
}

/// Converts MediaInput to MultipartFile for upload
pub fn to_multipart_file(
  input: MediaInput,
) -> Result(Option(MultipartFile), simplifile.FileError) {
  case input {
    Url(..) | FileId(..) -> Ok(None)

    LocalFile(path, attach_name) -> {
      use content <- result.try(simplifile.read_bits(path))
      let filename = case string.split(path, "/") {
        [] -> "file"
        parts -> {
          case list.last(parts) {
            Ok(name) -> name
            Error(_) -> "file"
          }
        }
      }
      Ok(
        Some(MultipartFile(
          field_name: attach_name,
          filename: filename,
          content: content,
          mime_type: detect_mime_type(filename),
        )),
      )
    }

    Bytes(data, filename, attach_name) -> {
      Ok(
        Some(MultipartFile(
          field_name: attach_name,
          filename: filename,
          content: data,
          mime_type: detect_mime_type(filename),
        )),
      )
    }
  }
}

/// Simple MIME type detection based on file extension
fn detect_mime_type(filename: String) -> Option(String) {
  let extension = case string.split(filename, ".") {
    [] -> ""
    parts -> {
      case list.last(parts) {
        Ok(ext) -> string.lowercase(ext)
        Error(_) -> ""
      }
    }
  }

  case extension {
    "jpg" | "jpeg" -> Some("image/jpeg")
    "png" -> Some("image/png")
    "gif" -> Some("image/gif")
    "webp" -> Some("image/webp")
    "mp4" -> Some("video/mp4")
    "avi" -> Some("video/x-msvideo")
    "mkv" -> Some("video/x-matroska")
    "webm" -> Some("video/webm")
    "mp3" -> Some("audio/mpeg")
    "ogg" -> Some("audio/ogg")
    "wav" -> Some("audio/wav")
    "pdf" -> Some("application/pdf")
    "zip" -> Some("application/zip")
    "json" -> Some("application/json")
    "xml" -> Some("application/xml")
    _ -> None
  }
}

/// Downloads a file from Telegram servers
/// First gets the file path using getFile API, then downloads the actual file
pub fn download_file(
  client: TelegramClient,
  file_id: String,
) -> Result(BitArray, String) {
  use file_info <- result.try(
    api.get_file(client, file_id)
    |> result.map_error(fn(e) {
      "Failed to get file info: " <> string.inspect(e)
    }),
  )

  case file_info.file_path {
    None -> Error("File path not available")
    Some(path) -> download_by_path(client, path)
  }
}

/// Downloads a file using its file_path from the File object
pub fn download_by_path(
  client: TelegramClient,
  file_path: String,
) -> Result(BitArray, String) {
  let url = build_file_url(client, file_path)

  use req <- result.try(
    request.to(url)
    |> result.map_error(fn(_) { "Failed to build request for: " <> url }),
  )

  // Convert to bits request with empty body for GET request
  let bits_req = request.set_body(req, <<>>)

  use resp <- result.try(
    httpc.send_bits(bits_req)
    |> result.map_error(fn(_) { "Failed to download file from: " <> url }),
  )

  case resp.status {
    200 -> Ok(resp.body)
    status -> Error("Download failed with status: " <> int.to_string(status))
  }
}

/// Downloads a file and saves it to disk
pub fn download_to_file(
  client: TelegramClient,
  file_id: String,
  save_path: String,
) -> Result(Nil, String) {
  use content <- result.try(download_file(client, file_id))

  simplifile.write_bits(save_path, content)
  |> result.map_error(fn(e) { "Failed to save file: " <> string.inspect(e) })
}

/// Gets file information without downloading
pub fn get_file_info(
  client: TelegramClient,
  file_id: String,
) -> Result(File, String) {
  api.get_file(client, file_id)
  |> result.map_error(fn(e) { "Failed to get file info: " <> string.inspect(e) })
}

/// Builds the full URL for downloading a file from Telegram
fn build_file_url(client: TelegramClient, file_path: String) -> String {
  let api_url = client.get_api_url(client:)
  let base_url = case api_url {
    "https://api.telegram.org/bot" -> "https://api.telegram.org/file"
    custom -> {
      // Remove /bot suffix if present
      case string.ends_with(custom, "/bot") {
        True -> string.drop_end(custom, 4) <> "/file"
        False -> custom <> "/file"
      }
    }
  }

  base_url <> "/bot" <> client.get_token(client) <> "/" <> file_path
}
