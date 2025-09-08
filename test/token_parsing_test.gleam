import gleam/string
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn token_parsing_test() {
  let token = "booking_date_334068983:334068983:booking"
  let flow_id = "334068983:334068983:booking"
  let suffix = "_" <> flow_id

  let data_key = case string.ends_with(token, suffix) {
    True -> {
      let key = string.drop_end(token, string.length(suffix))
      case key {
        "" -> "text"
        k -> k
      }
    }
    False -> {
      case string.split(token, "_") {
        [key, ..] -> key
        [] -> "text"
      }
    }
  }

  data_key |> should.equal("booking_date")
}

pub fn token_parsing_with_underscore_in_key_test() {
  let token = "user_full_name_123:456:flow"
  let flow_id = "123:456:flow"
  let suffix = "_" <> flow_id

  let data_key = case string.ends_with(token, suffix) {
    True -> {
      let key = string.drop_end(token, string.length(suffix))
      case key {
        "" -> "text"
        k -> k
      }
    }
    False -> {
      case string.split(token, "_") {
        [key, ..] -> key
        [] -> "text"
      }
    }
  }

  data_key |> should.equal("user_full_name")
}

pub fn token_parsing_simple_key_test() {
  let token = "name_789:012:registration"
  let flow_id = "789:012:registration"
  let suffix = "_" <> flow_id

  let data_key = case string.ends_with(token, suffix) {
    True -> {
      let key = string.drop_end(token, string.length(suffix))
      case key {
        "" -> "text"
        k -> k
      }
    }
    False -> {
      case string.split(token, "_") {
        [key, ..] -> key
        [] -> "text"
      }
    }
  }

  data_key |> should.equal("name")
}

pub fn token_parsing_fallback_test() {
  let token = "some_random_token"
  let flow_id = "123:456:flow"
  let suffix = "_" <> flow_id

  let data_key = case string.ends_with(token, suffix) {
    True -> {
      let key = string.drop_end(token, string.length(suffix))
      case key {
        "" -> "text"
        k -> k
      }
    }
    False -> {
      case string.split(token, "_") {
        [key, ..] -> key
        [] -> "text"
      }
    }
  }

  data_key |> should.equal("some")
}

pub fn token_parsing_empty_key_test() {
  let token = "_123:456:flow"
  let flow_id = "123:456:flow"
  let suffix = "_" <> flow_id

  let data_key = case string.ends_with(token, suffix) {
    True -> {
      let key = string.drop_end(token, string.length(suffix))
      case key {
        "" -> "text"
        k -> k
      }
    }
    False -> {
      case string.split(token, "_") {
        [key, ..] -> key
        [] -> "text"
      }
    }
  }

  data_key |> should.equal("text")
}
