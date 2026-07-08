import birdie
import gleam/http/request
import gleam/json
import gleeunit
import gleeunit/should

import telega/keyboard
import telega/model/types.{SendMessageReplyInlineKeyboardMarkupParameters}
import telega/testing/mock
import telega/testing/render

pub fn main() {
  gleeunit.main()
}

// canonical_json --------------------------------------------------------------

pub fn canonical_json_sorts_keys_and_indents_test() {
  let input =
    json.to_string(
      json.object([
        #("zebra", json.int(1)),
        #(
          "alpha",
          json.object([
            #("nested_b", json.bool(True)),
            #("nested_a", json.null()),
          ]),
        ),
        #("list", json.array([1.5, 2.0], json.float)),
        #("text", json.string("line\n\"quoted\"")),
        #("empty_object", json.object([])),
        #("empty_list", json.array([], json.int)),
      ]),
    )

  let assert Ok(canonical) = render.canonical_json(input)
  birdie.snap(canonical, title: "render:canonical_json:all_value_kinds")
}

pub fn canonical_json_invalid_input_test() {
  render.canonical_json("not json")
  |> should.equal(Error(Nil))
}

pub fn canonical_json_is_stable_under_key_order_test() {
  let a = "{\"b\":1,\"a\":{\"y\":2,\"x\":3}}"
  let b = "{\"a\":{\"x\":3,\"y\":2},\"b\":1}"
  should.equal(render.canonical_json(a), render.canonical_json(b))
}

// calls_transcript -------------------------------------------------------------

pub fn calls_transcript_test() {
  let send_message =
    request.new()
    |> request.set_path("/bottest_token/sendMessage")
    |> request.set_body(
      "{\"text\":\"Hello\",\"chat_id\":123,\"reply_markup\":{\"inline_keyboard\":[[{\"text\":\"Ok\",\"callback_data\":\"ok\"}]]}}",
    )
  let answer_callback =
    request.new()
    |> request.set_path("/bottest_token/answerCallbackQuery")
    |> request.set_body("{\"callback_query_id\":\"42\"}")
  let get_me =
    request.new()
    |> request.set_path("/bottest_token/getMe")

  [
    mock.ApiCall(request: send_message),
    mock.ApiCall(request: answer_callback),
    mock.ApiCall(request: get_me),
  ]
  |> render.calls_transcript
  |> birdie.snap(title: "render:calls_transcript:mixed_calls")
}

// keyboard_grid ----------------------------------------------------------------

pub fn keyboard_grid_test() {
  let callback_data = keyboard.string_callback_data("lang")
  let assert Ok(en_button) =
    keyboard.inline_button(
      "○ English",
      keyboard.pack_callback(callback_data, "en"),
    )
  let assert Ok(ru_button) =
    keyboard.inline_button(
      "● Русский",
      keyboard.pack_callback(callback_data, "ru"),
    )

  let markup =
    keyboard.new_inline([
      [en_button, ru_button],
      [
        keyboard.inline_url_button("Docs", "https://example.com"),
        keyboard.inline_web_app_button("App", "https://app.example.com"),
      ],
      [
        keyboard.inline_copy_text_button("1/3", "1/3"),
        keyboard.inline_switch_query_button("Share", "query"),
        keyboard.inline_switch_query_current_chat_button("Here", "q2"),
      ],
    ])
    |> keyboard.to_inline_markup

  let assert SendMessageReplyInlineKeyboardMarkupParameters(markup) = markup
  render.keyboard_grid(markup)
  |> birdie.snap(title: "render:keyboard_grid:all_button_kinds")
}
