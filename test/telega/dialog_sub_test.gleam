//// Tests for dialog sub-dialogs (`dialog.subdialog` + `StartSub`).
////
//// The parent "profile" dialog (String state = saved address summary) starts
//// the "address" sub-dialog (its own String state `"<city>|<street>"`) from
//// the menu window. The sub shares the live message; `Done` in the sub hands
//// the exported result to the menu's `on_sub_result`.

import birdie
import gleam/dict
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot
import telega/dialog
import telega/dialog/engine as dialog_engine
import telega/dialog/types.{
  type ActionEvent, type RenderedWindow, ActionButton, RenderedWindow,
}
import telega/dialog/widget.{SelectItem}
import telega/dialog_driver as driver
import telega/error
import telega/flow/instance
import telega/flow/storage as flow_storage
import telega/flow/types as flow_types
import telega/format
import telega/testing/mock
import telega/testing/render as testing_render

pub fn main() {
  gleeunit.main()
}

type Ctx =
  bot.Context(Nil, error.TelegaError, Nil)

// ============================================================================
// Sub-dialog: address (city → street), state "<city>|<street>"
// ============================================================================

fn text_window(text: String, buttons: List(List(types.DialogButton))) {
  RenderedWindow(
    text: format.build() |> format.text(text) |> format.to_formatted(),
    buttons:,
    media: None,
  )
}

fn back_or_stay(
  state: String,
  event: ActionEvent,
  _ctx: Ctx,
) -> Result(types.DialogAction(String), error.TelegaError) {
  case event.action_id {
    "back" -> Ok(types.Back(state))
    _ -> Ok(types.Stay(state))
  }
}

fn address_dialog(
  storage: flow_types.FlowStorage(error.TelegaError),
) -> dialog.Dialog(String, Nil, error.TelegaError, Nil) {
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(address) =
    dialog.new(
      id: "address",
      storage:,
      initial_state: fn() { "|" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window_with_input(
      id: "city",
      render: fn(state, _ctx) {
        text_window("City? (" <> state <> ")", [
          [ActionButton("‹ Back", "back")],
        ])
      },
      on_action: back_or_stay,
      on_text: fn(state, text, _ctx) {
        let street = case string.split(state, "|") {
          [_, street] -> street
          _ -> ""
        }
        Ok(types.Goto("street", text <> "|" <> street))
      },
    )
    |> dialog.window_with_input(
      id: "street",
      render: fn(state, _ctx) {
        text_window("Street? (" <> state <> ")", [
          [ActionButton("‹ Back", "back")],
        ])
      },
      on_action: back_or_stay,
      on_text: fn(state, text, _ctx) {
        let city = case string.split(state, "|") {
          [city, _] -> city
          _ -> ""
        }
        Ok(types.Done(city <> "|" <> text))
      },
    )
    |> dialog.initial("city")
    |> dialog.build()
  address
}

fn address_result(sub_state: String) -> dict.Dict(String, String) {
  case string.split(sub_state, "|") {
    [city, street] ->
      dict.from_list([#("address.city", city), #("address.street", street)])
    _ -> dict.new()
  }
}

// ============================================================================
// Parent dialog: profile (menu), state = saved address summary
// ============================================================================

fn render_menu(state: String, _ctx: Ctx) -> RenderedWindow {
  let address = case state {
    "" -> "none"
    saved -> saved
  }
  text_window("Profile. Address: " <> address, [
    [ActionButton("Address", "address")],
    [ActionButton("Finish", "finish")],
  ])
}

fn handle_menu(
  state: String,
  event: ActionEvent,
  _ctx: Ctx,
) -> Result(types.DialogAction(String), error.TelegaError) {
  case event.action_id {
    "address" ->
      Ok(types.StartSub(
        "address",
        dict.from_list([#("prefill", "Springfield")]),
        state,
      ))
    "ghost" -> Ok(types.StartSub("no_such_sub", dict.new(), state))
    "finish" -> Ok(types.Done(state))
    _ -> Ok(types.Stay(state))
  }
}

fn profile_dialog(
  storage: flow_types.FlowStorage(error.TelegaError),
) -> dialog.Dialog(String, Nil, error.TelegaError, Nil) {
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(profile) =
    dialog.new(
      id: "profile",
      storage:,
      initial_state: fn() { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(id: "menu", render: render_menu, on_action: handle_menu)
    |> dialog.subdialog(
      sub: address_dialog(storage),
      init: fn(_parent_state, args) {
        // The StartSub args pre-fill the city.
        option.unwrap(option.from_result(dict.get(args, "prefill")), "") <> "|"
      },
      result: address_result,
    )
    |> dialog.on_sub_result(window: "menu", handler: fn(_state, result, _ctx) {
      let city = option.from_result(dict.get(result, "address.city"))
      let street = option.from_result(dict.get(result, "address.street"))
      Ok(types.Stay(
        option.unwrap(city, "?") <> ", " <> option.unwrap(street, "?"),
      ))
    })
    |> dialog.initial("menu")
    |> dialog.build()
  profile
}

fn profile_flow(
  storage: flow_types.FlowStorage(error.TelegaError),
) -> flow_types.Flow(String, Nil, error.TelegaError, Nil) {
  dialog_engine.compile(dialog.compiled(profile_dialog(storage)))
}

// ============================================================================
// Driving helpers (thin wrappers over the shared driver)
// ============================================================================

fn flow_id(chat_id: Int, dialog_id: String) -> String {
  driver.flow_id(chat_id, dialog_id)
}

fn start_dialog(flow, client, chat_id: Int) -> Nil {
  driver.start_dialog(flow, client, chat_id, command: "/profile")
}

fn press(
  flow,
  client,
  storage,
  chat_id: Int,
  dialog_id: String,
  data: String,
) -> Nil {
  driver.press(flow, client, storage, chat_id, dialog_id, data)
}

fn send_text(
  flow,
  client,
  storage,
  chat_id: Int,
  dialog_id: String,
  text: String,
) -> Nil {
  driver.send_text(flow, client, storage, chat_id, dialog_id, text)
}

fn dialog_mock_client() {
  driver.media_mock_client()
}

fn profile_instance(
  storage: flow_types.FlowStorage(error.TelegaError),
  chat_id: Int,
) -> flow_types.FlowInstance {
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, "profile"))
  inst
}

// ============================================================================
// Level 2: engine scenarios
// ============================================================================

pub fn sub_happy_path_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = profile_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 601

  start_dialog(flow, client, chat_id)
  // Enter the sub: the same live message is edited into the city window,
  // pre-filled from the StartSub args.
  press(flow, client, storage, chat_id, "profile", "dlg:profile:menu:address")

  let inst = profile_instance(storage, chat_id)
  inst.state.current_step |> should.equal("address.city")
  instance.get_data(inst, "__dialog_sub") |> should.equal(Some("address"))
  instance.get_data(inst, "__dialog_return_window")
  |> should.equal(Some("menu"))
  instance.get_data(inst, "__dialog_state")
  |> should.equal(Some("Springfield|"))

  send_text(flow, client, storage, chat_id, "profile", "Shelbyville")
  send_text(flow, client, storage, chat_id, "profile", "Evergreen Terrace 742")

  // Sub finished: back on the menu with the parent state updated by
  // on_sub_result, sub bookkeeping gone.
  let inst = profile_instance(storage, chat_id)
  inst.state.current_step |> should.equal("menu")
  instance.get_data(inst, "__dialog_sub") |> should.equal(None)
  instance.get_data(inst, "__dialog_sub_saved") |> should.equal(None)
  instance.get_data(inst, "__dialog_state")
  |> should.equal(Some("Shelbyville, Evergreen Terrace 742"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:sub:happy_path")
}

pub fn sub_back_inside_sub_stays_in_sub_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = profile_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 602

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "profile", "dlg:profile:menu:address")
  send_text(flow, client, storage, chat_id, "profile", "Shelbyville")
  // street → Back → city: a history pop inside the sub.
  press(
    flow,
    client,
    storage,
    chat_id,
    "profile",
    "dlg:profile:address.street:back",
  )

  let inst = profile_instance(storage, chat_id)
  inst.state.current_step |> should.equal("address.city")
  instance.get_data(inst, "__dialog_sub") |> should.equal(Some("address"))
}

pub fn sub_back_on_first_window_cancels_sub_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = profile_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 603

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "profile", "dlg:profile:menu:address")
  // Back on the sub's first window crosses the boundary: the sub is
  // cancelled, on_sub_result is NOT called, parent state is untouched.
  press(
    flow,
    client,
    storage,
    chat_id,
    "profile",
    "dlg:profile:address.city:back",
  )

  let inst = profile_instance(storage, chat_id)
  inst.state.current_step |> should.equal("menu")
  instance.get_data(inst, "__dialog_sub") |> should.equal(None)
  instance.get_data(inst, "__dialog_state") |> should.equal(Some(""))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:sub:back_boundary_cancels")
}

pub fn sub_stale_parent_button_while_in_sub_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = profile_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 604

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "profile", "dlg:profile:menu:address")
  // A press on the outdated menu message while the sub is active: stale
  // answer, no transition, sub state untouched.
  press(flow, client, storage, chat_id, "profile", "dlg:profile:menu:finish")

  let inst = profile_instance(storage, chat_id)
  inst.state.current_step |> should.equal("address.city")
  instance.get_data(inst, "__dialog_sub") |> should.equal(Some("address"))
}

pub fn sub_persistence_roundtrip_mid_sub_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = profile_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 605

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "profile", "dlg:profile:menu:address")
  send_text(flow, client, storage, chat_id, "profile", "Shelbyville")

  // "Restart" in the middle of the sub: JSON roundtrip, fresh client.
  let inst = profile_instance(storage, chat_id)
  let assert Ok(restored) =
    instance.from_json_string(instance.to_json_string(inst))
  restored.state.current_step |> should.equal("address.street")
  let assert Ok(_) = storage.save(restored)

  let #(fresh_client, _fresh_calls) = dialog_mock_client()
  send_text(
    flow,
    fresh_client,
    storage,
    chat_id,
    "profile",
    "Evergreen Terrace 742",
  )

  let inst = profile_instance(storage, chat_id)
  inst.state.current_step |> should.equal("menu")
  instance.get_data(inst, "__dialog_state")
  |> should.equal(Some("Shelbyville, Evergreen Terrace 742"))
}

pub fn sub_unknown_sub_id_stays_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = profile_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 606

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "profile", "dlg:profile:menu:ghost")

  let inst = profile_instance(storage, chat_id)
  inst.state.current_step |> should.equal("menu")
  instance.get_data(inst, "__dialog_sub") |> should.equal(None)
}

pub fn sub_nested_start_sub_is_rejected_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let #(encode_state, decode_state) = dialog.string_codec()

  // A sub whose window tries to start another sub at runtime.
  let assert Ok(greedy) =
    dialog.new(
      id: "greedy",
      storage:,
      initial_state: fn() { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "main",
      render: fn(_state, _ctx) {
        text_window("Greedy", [[ActionButton("Deeper", "deeper")]])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "deeper" -> Ok(types.StartSub("greedy", dict.new(), state))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.initial("main")
    |> dialog.build()

  let assert Ok(parent) =
    dialog.new(
      id: "host",
      storage:,
      initial_state: fn() { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "menu",
      render: fn(_state, _ctx) {
        text_window("Host", [[ActionButton("Go", "go")]])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "go" -> Ok(types.StartSub("greedy", dict.new(), state))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.subdialog(
      sub: greedy,
      init: fn(_state, _args) { "" },
      result: fn(_state) { dict.new() },
    )
    |> dialog.initial("menu")
    |> dialog.build()

  let flow = dialog_engine.compile(dialog.compiled(parent))
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 607

  driver.start_dialog(flow, client, chat_id, command: "/host")
  press(flow, client, storage, chat_id, "host", "dlg:host:menu:go")
  // Nested StartSub from inside the sub: rejected, window re-rendered.
  press(flow, client, storage, chat_id, "host", "dlg:host:greedy.main:deeper")

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, "host"))
  inst.state.current_step |> should.equal("greedy.main")
  instance.get_data(inst, "__dialog_sub") |> should.equal(Some("greedy"))
}

pub fn sub_widget_store_resets_on_reenter_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let #(encode_state, decode_state) = dialog.string_codec()

  let assert Ok(picker) =
    dialog.new(
      id: "picker",
      storage:,
      initial_state: fn() { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window_with_widgets(
      id: "main",
      render: fn(_state, _ctx) {
        text_window("Pick", [[ActionButton("‹ Back", "back")]])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "ok" -> Ok(types.Done(state))
          "back" -> Ok(types.Back(state))
          _ -> Ok(types.Stay(state))
        }
      },
      widgets: [
        widget.radio(
          id: "r",
          items: fn(_state, _ctx) {
            [SelectItem("a", "A"), SelectItem("b", "B")]
          },
          default: None,
        ),
      ],
    )
    |> dialog.window(
      id: "done",
      render: fn(_state, _ctx) {
        text_window("Done", [[ActionButton("Ok", "ok")]])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "ok" -> Ok(types.Done(state))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.initial("main")
    |> dialog.build()

  let assert Ok(parent) =
    dialog.new(
      id: "host2",
      storage:,
      initial_state: fn() { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "menu",
      render: fn(_state, _ctx) {
        text_window("Host", [[ActionButton("Go", "go")]])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "go" -> Ok(types.StartSub("picker", dict.new(), state))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.subdialog(
      sub: picker,
      init: fn(_state, _args) { "" },
      result: fn(_state) { dict.new() },
    )
    |> dialog.initial("menu")
    |> dialog.build()

  let flow = dialog_engine.compile(dialog.compiled(parent))
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 608

  driver.start_dialog(flow, client, chat_id, command: "/host2")
  press(flow, client, storage, chat_id, "host2", "dlg:host2:menu:go")
  // Pick "b" in the sub's radio, then finish the sub.
  press(
    flow,
    client,
    storage,
    chat_id,
    "host2",
    "dlg:host2:picker.main:w:r:pick:b",
  )
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, "host2"))
  instance.get_data(inst, "__dialog_widget:picker.main:r")
  |> should.equal(Some("{\"value\":\"b\"}"))

  // Cancel the sub (boundary Back) and re-enter: the second StartSub must
  // reset the sub's widget stores so the radio starts unpicked.
  press(flow, client, storage, chat_id, "host2", "dlg:host2:picker.main:back")
  press(flow, client, storage, chat_id, "host2", "dlg:host2:menu:go")
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, "host2"))
  inst.state.current_step |> should.equal("picker.main")
  instance.get_data(inst, "__dialog_widget:picker.main:r") |> should.equal(None)
}

// ============================================================================
// Unit: build validation
// ============================================================================

fn minimal_string_dialog(id: String) {
  let #(encode_state, decode_state) = dialog.string_codec()
  dialog.new(
    id:,
    storage: flow_storage.create_noop_storage(),
    initial_state: fn() { "" },
    encode_state:,
    decode_state:,
  )
  |> dialog.window(
    id: "main",
    render: fn(_state: String, _ctx: Ctx) { text_window("x", []) },
    on_action: fn(state, _event, _ctx) { Ok(types.Stay(state)) },
  )
  |> dialog.initial("main")
}

pub fn build_duplicate_sub_id_test() {
  let assert Ok(sub) = minimal_string_dialog("addr") |> dialog.build()
  let assert Ok(sub2) = minimal_string_dialog("addr") |> dialog.build()
  minimal_string_dialog("parent")
  |> dialog.subdialog(sub:, init: fn(_s, _a) { "" }, result: fn(_s) {
    dict.new()
  })
  |> dialog.subdialog(sub: sub2, init: fn(_s, _a) { "" }, result: fn(_s) {
    dict.new()
  })
  |> dialog.build()
  |> should.equal(Error(types.DuplicateSubDialogId(id: "addr")))
}

pub fn build_nested_sub_is_rejected_test() {
  let assert Ok(inner) = minimal_string_dialog("inner") |> dialog.build()
  let assert Ok(middle) =
    minimal_string_dialog("middle")
    |> dialog.subdialog(sub: inner, init: fn(_s, _a) { "" }, result: fn(_s) {
      dict.new()
    })
    |> dialog.build()
  minimal_string_dialog("outer")
  |> dialog.subdialog(sub: middle, init: fn(_s, _a) { "" }, result: fn(_s) {
    dict.new()
  })
  |> dialog.build()
  |> should.equal(Error(types.NestedSubDialog(id: "middle")))
}

pub fn build_dot_in_window_id_test() {
  let #(encode_state, decode_state) = dialog.string_codec()
  dialog.new(
    id: "ok",
    storage: flow_storage.create_noop_storage(),
    initial_state: fn() { "" },
    encode_state:,
    decode_state:,
  )
  |> dialog.window(
    id: "me.nu",
    render: fn(_state: String, _ctx: Ctx) { text_window("x", []) },
    on_action: fn(state, _event, _ctx) { Ok(types.Stay(state)) },
  )
  |> dialog.initial("me.nu")
  |> dialog.build()
  |> should.equal(Error(types.ReservedIdCharacter(kind: "window", id: "me.nu")))
}

pub fn build_dot_in_dialog_id_test() {
  minimal_string_dialog("bad.id")
  |> dialog.build()
  |> should.equal(
    Error(types.ReservedIdCharacter(kind: "dialog", id: "bad.id")),
  )
}

pub fn build_on_sub_result_unknown_window_test() {
  minimal_string_dialog("ok")
  |> dialog.on_sub_result(window: "nope", handler: fn(state, _result, _ctx) {
    Ok(types.Stay(state))
  })
  |> dialog.build()
  |> should.equal(
    Error(types.UnknownWindowReference(from: "on_sub_result", to: "nope")),
  )
}

pub fn build_sub_window_budget_includes_namespace_test() {
  let long_id = string.repeat("w", 52)
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(sub) =
    dialog.new(
      id: "sub",
      storage: flow_storage.create_noop_storage(),
      initial_state: fn() { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: long_id,
      render: fn(_state: String, _ctx: Ctx) { text_window("x", []) },
      on_action: fn(state, _event, _ctx) { Ok(types.Stay(state)) },
    )
    |> dialog.initial(long_id)
    |> dialog.build()

  // Fits standalone ("dlg:sub:<52>:" + 1 = 61) but not under the parent
  // prefix ("dlg:parent:sub.<52>:" + 1 = 68).
  let result =
    minimal_string_dialog("parent")
    |> dialog.subdialog(sub:, init: fn(_s, _a) { "" }, result: fn(_s) {
      dict.new()
    })
    |> dialog.build()
  let assert Error(types.CallbackDataTooLong(window:, ..)) = result
  window |> should.equal("sub." <> long_id)
}
