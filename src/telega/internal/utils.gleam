import gleam/string

pub fn normalize_url(url: String) {
  let url = string.trim(url)
  case string.ends_with(url, "/") {
    True -> string.drop_end(url, 1)
    _ -> url
  }
}

pub fn normalize_webhook_path(webhook_path: String) {
  let webhook_path = string.trim(webhook_path)
  let webhook_path = case string.ends_with(webhook_path, "/") {
    True -> string.drop_end(webhook_path, 1)
    _ -> webhook_path
  }

  case string.starts_with(webhook_path, "/") {
    True -> string.drop_start(webhook_path, 1)
    _ -> webhook_path
  }
}
