//// Tests for dialog sub-dialogs (`dialog.subdialog` + `StartSub`).
////
//// The parent "profile" dialog (String state = saved address summary) starts
//// the "address" sub-dialog (its own String state `"<city>|<street>"`) from
//// the menu window. The sub shares the live message; `Done` in the sub hands
//// the exported result to the menu's `on_sub_result`.

import birdie
import gleam/dict
import gleam/list
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
      initial_state: fn(_ctx) { "|" },
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

/// The sub's final state as the parent wants to show it. With the typed
/// hand-back this is the parent's own business — no exported dict in between.
fn address_summary(sub_state: String) -> String {
  case string.split(sub_state, "|") {
    [city, street] -> city <> ", " <> street
    _ -> "?, ?"
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
  let address = address_dialog(storage)
  let assert Ok(profile) =
    dialog.new(
      id: "profile",
      storage:,
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(id: "menu", render: render_menu, on_action: handle_menu)
    |> dialog.subdialog(sub: address, init: fn(_parent_state, args) {
      // The StartSub args pre-fill the city.
      option.unwrap(option.from_result(dict.get(args, "prefill")), "") <> "|"
    })
    // The handler is handed the sub's final state in the sub's own type.
    |> dialog.on_sub_result(
      window: "menu",
      sub: address,
      handler: fn(_state, sub_state, _ctx) {
        Ok(types.Stay(address_summary(sub_state)))
      },
    )
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
  dialog_engine.active_sub(inst) |> should.equal(Some("address"))
  dialog_engine.sub_depth(inst) |> should.equal(1)
  instance.get_data(inst, "__dialog_state")
  |> should.equal(Some("Springfield|"))

  send_text(flow, client, storage, chat_id, "profile", "Shelbyville")
  send_text(flow, client, storage, chat_id, "profile", "Evergreen Terrace 742")

  // Sub finished: back on the menu with the parent state updated by
  // on_sub_result, sub bookkeeping gone.
  let inst = profile_instance(storage, chat_id)
  inst.state.current_step |> should.equal("menu")
  dialog_engine.active_sub(inst) |> should.equal(None)
  dialog_engine.sub_depth(inst) |> should.equal(0)
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
  dialog_engine.active_sub(inst) |> should.equal(Some("address"))
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
  dialog_engine.active_sub(inst) |> should.equal(None)
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
  dialog_engine.active_sub(inst) |> should.equal(Some("address"))
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
  dialog_engine.active_sub(inst) |> should.equal(None)
}

pub fn sub_nested_two_levels_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let #(encode_state, decode_state) = dialog.string_codec()

  // Innermost: one window that finishes with a value.
  let assert Ok(inner) =
    dialog.new(
      id: "inner",
      storage:,
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "main",
      render: fn(_state, _ctx) {
        text_window("Inner", [[ActionButton("Pick", "pick")]])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "pick" -> Ok(types.Done("picked"))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.initial("main")
    |> dialog.build()

  // Middle: starts `inner`, and records what came back.
  let assert Ok(middle) =
    dialog.new(
      id: "middle",
      storage:,
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "main",
      render: fn(state, _ctx) {
        text_window("Middle(" <> state <> ")", [
          [ActionButton("Deeper", "deeper"), ActionButton("Done", "done")],
        ])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "deeper" -> Ok(types.StartSub("inner", dict.new(), state))
          "done" -> Ok(types.Done(state))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.subdialog(sub: inner, init: fn(_state, _args) { "" })
    |> dialog.on_sub_result(
      window: "main",
      sub: inner,
      handler: fn(_state, sub_state, _ctx) {
        Ok(types.Stay("got:" <> sub_state))
      },
    )
    |> dialog.initial("main")
    |> dialog.build()

  let assert Ok(outer) =
    dialog.new(
      id: "outer",
      storage:,
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "menu",
      render: fn(state, _ctx) {
        text_window("Outer(" <> state <> ")", [[ActionButton("Go", "go")]])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "go" -> Ok(types.StartSub("middle", dict.new(), state))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.subdialog(sub: middle, init: fn(_state, _args) { "" })
    |> dialog.on_sub_result(
      window: "menu",
      sub: middle,
      handler: fn(_state, sub_state, _ctx) { Ok(types.Stay(sub_state)) },
    )
    |> dialog.initial("menu")
    |> dialog.build()

  let flow = dialog_engine.compile(dialog.compiled(outer))
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 607

  driver.start_dialog(flow, client, chat_id, command: "/outer")
  press(flow, client, storage, chat_id, "outer", "dlg:outer:menu:go")

  let inst = load(storage, chat_id)
  inst.state.current_step |> should.equal("middle.main")
  dialog_engine.sub_depth(inst) |> should.equal(1)

  // Two levels deep: `middle` started `inner`.
  press(flow, client, storage, chat_id, "outer", "dlg:outer:middle.main:deeper")
  let inst = load(storage, chat_id)
  inst.state.current_step |> should.equal("middle.inner.main")
  dialog_engine.active_sub(inst) |> should.equal(Some("middle.inner"))
  dialog_engine.sub_depth(inst) |> should.equal(2)

  // Inner `Done` pops one level and hands its result to middle's window.
  press(
    flow,
    client,
    storage,
    chat_id,
    "outer",
    "dlg:outer:middle.inner.main:pick",
  )
  let inst = load(storage, chat_id)
  inst.state.current_step |> should.equal("middle.main")
  dialog_engine.active_sub(inst) |> should.equal(Some("middle"))
  dialog_engine.sub_depth(inst) |> should.equal(1)
  instance.get_data(inst, "__dialog_state") |> should.equal(Some("got:picked"))

  // Middle `Done` pops the last level back to the outer menu.
  press(flow, client, storage, chat_id, "outer", "dlg:outer:middle.main:done")
  let inst = load(storage, chat_id)
  inst.state.current_step |> should.equal("menu")
  dialog_engine.sub_depth(inst) |> should.equal(0)
  instance.get_data(inst, "__dialog_state") |> should.equal(Some("got:picked"))
}

pub fn sub_nested_back_cancels_one_level_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = nested_back_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 608

  driver.start_dialog(flow, client, chat_id, command: "/outer2")
  press(flow, client, storage, chat_id, "outer2", "dlg:outer2:menu:go")
  press(
    flow,
    client,
    storage,
    chat_id,
    "outer2",
    "dlg:outer2:middle2.main:deeper",
  )
  dialog_engine.sub_depth(load_from(storage, chat_id, "outer2"))
  |> should.equal(2)

  // Back on the inner dialog's first window cancels *that* level only.
  press(
    flow,
    client,
    storage,
    chat_id,
    "outer2",
    "dlg:outer2:middle2.inner2.main:back",
  )
  let inst = load_from(storage, chat_id, "outer2")
  inst.state.current_step |> should.equal("middle2.main")
  dialog_engine.active_sub(inst) |> should.equal(Some("middle2"))
  dialog_engine.sub_depth(inst) |> should.equal(1)

  // And again to leave the middle one.
  press(
    flow,
    client,
    storage,
    chat_id,
    "outer2",
    "dlg:outer2:middle2.main:back",
  )
  let inst = load_from(storage, chat_id, "outer2")
  inst.state.current_step |> should.equal("menu")
  dialog_engine.sub_depth(inst) |> should.equal(0)
}

fn load(
  storage: flow_types.FlowStorage(error.TelegaError),
  chat_id: Int,
) -> flow_types.FlowInstance {
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, "outer"))
  inst
}

fn load_from(
  storage: flow_types.FlowStorage(error.TelegaError),
  chat_id: Int,
  dialog_id: String,
) -> flow_types.FlowInstance {
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, dialog_id))
  inst
}

/// Outer → middle → inner, each level's first window offering only `Back`.
fn nested_back_flow(storage) {
  let #(encode_state, decode_state) = dialog.string_codec()

  let back_window = fn(label) {
    fn(_state: String, _ctx: Ctx) {
      text_window(label, [[ActionButton("‹ Back", "back")]])
    }
  }

  let assert Ok(inner) =
    dialog.new(
      id: "inner2",
      storage:,
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "main",
      render: back_window("Inner"),
      on_action: back_or_stay,
    )
    |> dialog.initial("main")
    |> dialog.build()

  let assert Ok(middle) =
    dialog.new(
      id: "middle2",
      storage:,
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "main",
      render: fn(_state, _ctx) {
        text_window("Middle", [
          [ActionButton("Deeper", "deeper"), ActionButton("‹ Back", "back")],
        ])
      },
      on_action: fn(state, event: ActionEvent, ctx) {
        case event.action_id {
          "deeper" -> Ok(types.StartSub("inner2", dict.new(), state))
          _ -> back_or_stay(state, event, ctx)
        }
      },
    )
    |> dialog.subdialog(sub: inner, init: fn(_state, _args) { "" })
    |> dialog.initial("main")
    |> dialog.build()

  let assert Ok(outer) =
    dialog.new(
      id: "outer2",
      storage:,
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "menu",
      render: fn(_state, _ctx) {
        text_window("Outer", [[ActionButton("Go", "go")]])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "go" -> Ok(types.StartSub("middle2", dict.new(), state))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.subdialog(sub: middle, init: fn(_state, _args) { "" })
    |> dialog.initial("menu")
    |> dialog.build()

  dialog_engine.compile(dialog.compiled(outer))
}

pub fn sub_widget_store_resets_on_reenter_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let #(encode_state, decode_state) = dialog.string_codec()

  let assert Ok(picker) =
    dialog.new(
      id: "picker",
      storage:,
      initial_state: fn(_ctx) { "" },
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
      initial_state: fn(_ctx) { "" },
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
    |> dialog.subdialog(sub: picker, init: fn(_state, _args) { "" })
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
    initial_state: fn(_ctx) { "" },
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
  |> dialog.subdialog(sub:, init: fn(_s, _a) { "" })
  |> dialog.subdialog(sub: sub2, init: fn(_s, _a) { "" })
  |> dialog.build()
  |> should.equal(Error(types.DuplicateSubDialogId(id: "addr")))
}

pub fn build_nests_sub_windows_transitively_test() {
  let assert Ok(inner) = minimal_string_dialog("inner") |> dialog.build()
  let assert Ok(middle) =
    minimal_string_dialog("middle")
    |> dialog.subdialog(sub: inner, init: fn(_s, _a) { "" })
    |> dialog.build()
  let assert Ok(outer) =
    minimal_string_dialog("outer")
    |> dialog.subdialog(sub: middle, init: fn(_s, _a) { "" })
    |> dialog.build()

  // Every level's windows are flattened into one namespace, so the innermost
  // window is addressable as a step of the outer dialog's flow.
  let compiled = dialog.compiled(outer)
  dict.keys(compiled.windows)
  |> list.sort(string.compare)
  |> should.equal(["main", "middle.inner.main", "middle.main"])

  // ...and so is its sub attachment, keyed by the same path `StartSub` uses.
  dict.keys(compiled.subs)
  |> list.sort(string.compare)
  |> should.equal(["middle", "middle.inner"])
}

pub fn build_dot_in_window_id_test() {
  let #(encode_state, decode_state) = dialog.string_codec()
  dialog.new(
    id: "ok",
    storage: flow_storage.create_noop_storage(),
    initial_state: fn(_ctx) { "" },
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
  let assert Ok(sub) = minimal_string_dialog("sub") |> dialog.build()
  minimal_string_dialog("ok")
  |> dialog.subdialog(sub:, init: fn(_s, _a) { "" })
  |> dialog.on_sub_result(
    window: "nope",
    sub:,
    handler: fn(state, _result, _ctx) { Ok(types.Stay(state)) },
  )
  |> dialog.build()
  |> should.equal(
    Error(types.UnknownWindowReference(from: "on_sub_result", to: "nope")),
  )
}

/// A handler for a sub that was never attached could only ever be dead code.
pub fn build_on_sub_result_unattached_sub_test() {
  let assert Ok(stranger) = minimal_string_dialog("stranger") |> dialog.build()
  minimal_string_dialog("ok")
  |> dialog.on_sub_result(
    window: "main",
    sub: stranger,
    handler: fn(state, _result, _ctx) { Ok(types.Stay(state)) },
  )
  |> dialog.build()
  |> should.equal(
    Error(types.UnattachedSubDialog(window: "main", sub: "stranger")),
  )
}

pub fn build_sub_window_budget_includes_namespace_test() {
  let long_id = string.repeat("w", 52)
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(sub) =
    dialog.new(
      id: "sub",
      storage: flow_storage.create_noop_storage(),
      initial_state: fn(_ctx) { "" },
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
    |> dialog.subdialog(sub:, init: fn(_s, _a) { "" })
    |> dialog.build()
  let assert Error(types.CallbackDataTooLong(window:, ..)) = result
  window |> should.equal("sub." <> long_id)
}

// M13 — an alert from `on_sub_result` must be the answer, not a second one ----

/// A sub whose window finishes on a **button press**, so `on_sub_result` runs
/// while a callback query is still unanswered.
fn button_sub(storage) {
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(built) =
    dialog.new(
      id: "confirm",
      storage:,
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "ask",
      render: fn(_state, _ctx) {
        text_window("Sure?", [[ActionButton("Yes", "yes")]])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "yes" -> Ok(types.Done("yes"))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.initial("ask")
    |> dialog.build()
  built
}

fn alerting_parent(storage) {
  let #(encode_state, decode_state) = dialog.string_codec()
  let confirm = button_sub(storage)
  let assert Ok(built) =
    dialog.new(
      id: "alerting",
      storage:,
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "menu",
      render: fn(_state, _ctx) {
        text_window("Menu", [[ActionButton("Confirm", "confirm")]])
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "confirm" -> Ok(types.StartSub("confirm", dict.new(), state))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.subdialog(sub: confirm, init: fn(_parent_state, _args) { "" })
    |> dialog.on_sub_result(
      window: "menu",
      sub: confirm,
      handler: fn(state, _sub_state, ctx) {
        let _ = dialog.toast(ctx, "Saved")
        Ok(types.Stay(state))
      },
    )
    |> dialog.initial("menu")
    |> dialog.build()
  dialog_engine.compile(dialog.compiled(built))
}

pub fn alert_from_on_sub_result_is_the_only_answer_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = alerting_parent(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 640

  driver.start_dialog(flow, client, chat_id, command: "/alerting")
  press(flow, client, storage, chat_id, "alerting", "dlg:alerting:menu:confirm")
  press(
    flow,
    client,
    storage,
    chat_id,
    "alerting",
    "dlg:alerting:confirm.ask:yes",
  )

  // The engine used to answer the press before `on_sub_result` ran, so the
  // toast was a *second* answer to the same query and never reached the user.
  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:sub:alert_from_on_sub_result")
}
