import gleam/bit_array
import gleam/int
import gleam/json.{type Json}
import gleam/list
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

pub fn json_object_filter_nulls(entries: List(#(String, Json))) -> Json {
  let null = json.null()

  entries
  |> list.filter(fn(entry) {
    let #(_, value) = entry
    value != null
  })
  |> json.object
}

/// Compare two secrets without giving away where they first differ.
///
/// `==` on binaries stops at the first differing byte, so the response time
/// reveals how long a shared prefix is and a token can be guessed one byte at
/// a time. This walks both to the end whatever it finds. Lengths are compared
/// up front — the length is not the secret.
pub fn constant_time_compare(left: String, right: String) -> Bool {
  let left = bit_array.from_string(left)
  let right = bit_array.from_string(right)

  case bit_array.byte_size(left) == bit_array.byte_size(right) {
    False -> False
    True -> accumulate_difference(left, right, 0) == 0
  }
}

fn accumulate_difference(left: BitArray, right: BitArray, acc: Int) -> Int {
  case left, right {
    <<l:8, left_rest:bits>>, <<r:8, right_rest:bits>> ->
      accumulate_difference(
        left_rest,
        right_rest,
        int.bitwise_or(acc, int.bitwise_exclusive_or(l, r)),
      )
    _, _ -> acc
  }
}
