import gleam/int
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

const prefix_alphabet = "useandom-26T198340PX75pxJACKVERYMINDBUSHWOLF_GQZbfghjklqvwyzrict"

/// Generates random string of given length using the prefix alphabet.
pub fn random_string(length length) {
  do_random_string(length, "", string.length(prefix_alphabet))
}

fn do_random_string(n, acc, alphabet_length) {
  case n {
    0 -> acc
    _ -> {
      let index = int.random(alphabet_length)
      let char = string.slice(prefix_alphabet, index, 1)
      do_random_string(n - 1, acc <> char, alphabet_length)
    }
  }
}

pub fn seconds_to_milliseconds(time: Float) -> Float {
  time *. 1000.0
}

@external(erlang, "erlang", "system_time")
fn erlang_system_time_millisecond() -> Int

pub fn current_time_ms() -> Int {
  erlang_system_time_millisecond() / 1_000_000
}
