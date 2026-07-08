//// Tests for the built-in dialog widgets (`telega/dialog/widget`).
////
//// Level 1 snapshots render widget button rows purely (a `WidgetCtx` is
//// constructed by hand); level 2 drives widget events through the dialog
//// engine over a mock client, checking store persistence and the
//// `dialog.widget_store` stash.

import birdie
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot
import telega/dialog
import telega/dialog/engine as dialog_engine
import telega/dialog/types.{
  type ActionEvent, type RenderedWindow, ActionButton, ActionEvent,
  RenderedWindow,
}
import telega/dialog/widget.{type SelectItem, SelectItem}
import telega/dialog_driver as driver
import telega/error
import telega/flow/instance
import telega/flow/storage as flow_storage
import telega/flow/types as flow_types
import telega/format
import telega/testing/context
import telega/testing/mock
import telega/testing/render as testing_render

pub fn main() {
  gleeunit.main()
}

type Ctx =
  bot.Context(Nil, error.TelegaError, Nil)

// ============================================================================
// Level 1: pure widget render frames
// ============================================================================

fn widget_ctx(
  store: types.WidgetStore,
) -> types.WidgetCtx(String, Nil, error.TelegaError, Nil) {
  types.WidgetCtx(
    state: "",
    store:,
    labels: types.default_labels(),
    ctx: context.context(session: Nil),
  )
}

fn rows_frame(rows: List(List(types.DialogButton))) -> String {
  testing_render.window_frame(RenderedWindow(
    text: format.build() |> format.text("widget") |> format.to_formatted(),
    buttons: rows,
    media: None,
  ))
}

fn fruit_items(_state: String, _ctx: Ctx) -> List(SelectItem) {
  [
    SelectItem("apple", "Apple"),
    SelectItem("pear", "Pear"),
    SelectItem("plum", "Plum"),
    SelectItem("fig", "Fig"),
    SelectItem("kiwi", "Kiwi"),
  ]
}

pub fn pager_middle_page_frame_test() {
  let pager = widget.pager(id: "p", page_size: 2, total: fn(_, _) { 5 })
  let store = types.new_store() |> types.store_set("page", "1")
  pager.render(widget_ctx(store))
  |> rows_frame
  |> birdie.snap(title: "dialog:widget:pager_middle_page")
}

pub fn pager_single_page_renders_nothing_test() {
  let pager = widget.pager(id: "p", page_size: 10, total: fn(_, _) { 5 })
  pager.render(widget_ctx(types.new_store()))
  |> should.equal([])
}

pub fn radio_default_frame_test() {
  let radio = widget.radio(id: "z", items: fruit_items, default: Some("pear"))
  radio.render(widget_ctx(types.new_store()))
  |> list.take(3)
  |> rows_frame
  |> birdie.snap(title: "dialog:widget:radio_default_frame")
}

pub fn radio_picked_overrides_default_test() {
  let radio = widget.radio(id: "z", items: fruit_items, default: Some("pear"))
  let store = types.new_store() |> types.store_set("value", "plum")
  radio.render(widget_ctx(store))
  |> list.take(3)
  |> rows_frame
  |> birdie.snap(title: "dialog:widget:radio_picked_frame")
}

pub fn multiselect_below_min_hides_done_test() {
  let multi =
    widget.multiselect(id: "x", items: fruit_items, min: 1, max: 2, done: "ok")
  multi.render(widget_ctx(types.new_store()))
  |> rows_frame
  |> birdie.snap(title: "dialog:widget:multiselect_below_min_frame")
}

pub fn multiselect_valid_selection_shows_done_test() {
  let multi =
    widget.multiselect(id: "x", items: fruit_items, min: 1, max: 2, done: "ok")
  let store =
    types.new_store() |> types.store_set("values", "[\"pear\",\"fig\"]")
  multi.render(widget_ctx(store))
  |> rows_frame
  |> birdie.snap(title: "dialog:widget:multiselect_valid_frame")
}

pub fn paged_select_second_page_frame_test() {
  let paged =
    widget.paged_select(
      id: "s",
      items: fruit_items,
      page_size: 2,
      columns: 1,
      on_selected: fn(state, _id, _ctx) { Ok(types.Stay(state)) },
    )
  let store = types.new_store() |> types.store_set("page", "1")
  paged.render(widget_ctx(store))
  |> rows_frame
  |> birdie.snap(title: "dialog:widget:paged_select_page2_frame")
}

pub fn select_frame_test() {
  let select =
    widget.select(
      id: "s",
      items: fruit_items,
      columns: 2,
      on_selected: fn(state, _id, _ctx) { Ok(types.Stay(state)) },
    )
  select.render(widget_ctx(types.new_store()))
  |> rows_frame
  |> birdie.snap(title: "dialog:widget:select_frame")
}

// ============================================================================
// Test dialog: prefs (main: radio + multiselect → confirm)
// ============================================================================

fn zone_items(_state: String, _ctx: Ctx) -> List(SelectItem) {
  [SelectItem("hall", "Hall"), SelectItem("terrace", "Terrace")]
}

fn extra_items(_state: String, _ctx: Ctx) -> List(SelectItem) {
  [
    SelectItem("cake", "Cake"),
    SelectItem("flowers", "Flowers"),
    SelectItem("candles", "Candles"),
  ]
}

fn render_main(_state: String, _ctx: Ctx) -> RenderedWindow {
  RenderedWindow(
    text: format.build() |> format.text("Preferences") |> format.to_formatted(),
    buttons: [],
    media: None,
  )
}

/// The confirm render reads both widget stores via `dialog.widget_store` —
/// this is what proves the engine's stash works end to end.
fn render_confirm(_state: String, ctx: Ctx) -> RenderedWindow {
  let zone =
    dialog.widget_store(ctx, window_id: "main", widget_id: "z")
    |> widget.radio_value
    |> option.unwrap("hall")
  let extras =
    dialog.widget_store(ctx, window_id: "main", widget_id: "x")
    |> widget.multiselect_values
    |> string.join(",")
  RenderedWindow(
    text: format.build()
      |> format.text("zone=" <> zone <> " extras=" <> extras)
      |> format.to_formatted(),
    buttons: [[ActionButton("Save", "save")]],
    media: None,
  )
}

fn prefs_flow(
  storage: flow_types.FlowStorage(error.TelegaError),
) -> flow_types.Flow(String, Nil, error.TelegaError, Nil) {
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(prefs) =
    dialog.new(
      id: "prefs",
      storage:,
      initial_state: fn() { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window_with_widgets(
      id: "main",
      render: render_main,
      on_action: fn(state, _event, _ctx) { Ok(types.Stay(state)) },
      widgets: [
        widget.radio(id: "z", items: zone_items, default: Some("hall")),
        widget.multiselect(
          id: "x",
          items: extra_items,
          min: 1,
          max: 2,
          done: "confirm",
        ),
      ],
    )
    |> dialog.window(
      id: "confirm",
      render: render_confirm,
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "save" -> Ok(types.Done(state))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.initial("main")
    |> dialog.build()
  dialog_engine.compile(dialog.compiled(prefs))
}

// ============================================================================
// Driving helpers (thin wrappers over the shared driver)
// ============================================================================

fn flow_id(chat_id: Int, dialog_id: String) -> String {
  driver.flow_id(chat_id, dialog_id)
}

fn start_dialog(flow, client, chat_id: Int) -> Nil {
  driver.start_dialog(flow, client, chat_id, command: "/start")
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

fn dialog_mock_client() {
  driver.dialog_mock_client()
}

fn prefs_instance(
  storage: flow_types.FlowStorage(error.TelegaError),
  chat_id: Int,
) -> flow_types.FlowInstance {
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, "prefs"))
  inst
}

// ============================================================================
// Level 2: widget events through the engine
// ============================================================================

pub fn engine_radio_pick_persists_store_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = prefs_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 501

  start_dialog(flow, client, chat_id)
  press(
    flow,
    client,
    storage,
    chat_id,
    "prefs",
    "dlg:prefs:main:w:z:pick:terrace",
  )

  let inst = prefs_instance(storage, chat_id)
  inst.state.current_step |> should.equal("main")
  let assert Some(raw) = instance.get_data(inst, "__dialog_widget:main:z")
  let assert Ok(store) = types.decode_store(raw)
  widget.radio_value(store) |> should.equal(Some("terrace"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:widget:engine_radio_pick")
}

pub fn engine_multiselect_toggle_and_done_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = prefs_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 502

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "prefs", "dlg:prefs:main:w:x:tgl:cake")
  press(
    flow,
    client,
    storage,
    chat_id,
    "prefs",
    "dlg:prefs:main:w:x:tgl:flowers",
  )
  press(flow, client, storage, chat_id, "prefs", "dlg:prefs:main:w:x:done")

  // done → Goto("confirm"); the confirm render read both widget stores.
  let inst = prefs_instance(storage, chat_id)
  inst.state.current_step |> should.equal("confirm")

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:widget:engine_multiselect_done")
}

pub fn engine_multiselect_max_is_enforced_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = prefs_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 503

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "prefs", "dlg:prefs:main:w:x:tgl:cake")
  press(
    flow,
    client,
    storage,
    chat_id,
    "prefs",
    "dlg:prefs:main:w:x:tgl:flowers",
  )
  // Third toggle above max: ignored.
  press(
    flow,
    client,
    storage,
    chat_id,
    "prefs",
    "dlg:prefs:main:w:x:tgl:candles",
  )

  let inst = prefs_instance(storage, chat_id)
  let assert Some(raw) = instance.get_data(inst, "__dialog_widget:main:x")
  let assert Ok(store) = types.decode_store(raw)
  widget.multiselect_values(store) |> should.equal(["cake", "flowers"])
}

pub fn engine_multiselect_done_below_min_stays_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = prefs_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 504

  start_dialog(flow, client, chat_id)
  // A stale "done" press with nothing selected: no transition.
  press(flow, client, storage, chat_id, "prefs", "dlg:prefs:main:w:x:done")

  let inst = prefs_instance(storage, chat_id)
  inst.state.current_step |> should.equal("main")
}

pub fn engine_unknown_widget_is_ignored_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = prefs_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 505

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "prefs", "dlg:prefs:main:w:nope:pick:x")

  let inst = prefs_instance(storage, chat_id)
  inst.state.current_step |> should.equal("main")
  instance.get_data(inst, "__dialog_widget:main:nope") |> should.equal(None)
}

pub fn engine_widget_store_survives_json_roundtrip_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = prefs_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 506

  start_dialog(flow, client, chat_id)
  press(
    flow,
    client,
    storage,
    chat_id,
    "prefs",
    "dlg:prefs:main:w:z:pick:terrace",
  )

  // "Restart": the instance round-trips through JSON with the widget store.
  let inst = prefs_instance(storage, chat_id)
  let assert Ok(restored) =
    instance.from_json_string(instance.to_json_string(inst))
  let assert Ok(_) = storage.save(restored)

  press(flow, client, storage, chat_id, "prefs", "dlg:prefs:main:w:x:tgl:cake")
  let inst = prefs_instance(storage, chat_id)
  let assert Some(raw) = instance.get_data(inst, "__dialog_widget:main:z")
  let assert Ok(store) = types.decode_store(raw)
  widget.radio_value(store) |> should.equal(Some("terrace"))
}

// ============================================================================
// Test dialog: catalog (paged_select) — paging through the engine
// ============================================================================

fn catalog_flow(
  storage: flow_types.FlowStorage(error.TelegaError),
) -> flow_types.Flow(String, Nil, error.TelegaError, Nil) {
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(catalog) =
    dialog.new(
      id: "cat",
      storage:,
      initial_state: fn() { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window_with_widgets(
      id: "list",
      render: fn(_state, _ctx) {
        RenderedWindow(
          text: format.build() |> format.text("Pick") |> format.to_formatted(),
          buttons: [],
          media: None,
        )
      },
      on_action: fn(state, _event, _ctx) { Ok(types.Stay(state)) },
      widgets: [
        widget.paged_select(
          id: "s",
          items: fruit_items,
          page_size: 2,
          columns: 1,
          on_selected: fn(_state, item_id, _ctx) {
            Ok(types.Goto("picked", item_id))
          },
        ),
      ],
    )
    |> dialog.window(
      id: "picked",
      render: fn(state, _ctx) {
        RenderedWindow(
          text: format.build()
            |> format.text("picked: " <> state)
            |> format.to_formatted(),
          buttons: [],
          media: None,
        )
      },
      on_action: fn(state, _event, _ctx) { Ok(types.Done(state)) },
    )
    |> dialog.initial("list")
    |> dialog.build()
  dialog_engine.compile(dialog.compiled(catalog))
}

pub fn engine_paged_select_next_then_pick_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = catalog_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 507

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "cat", "dlg:cat:list:w:s:next")
  press(flow, client, storage, chat_id, "cat", "dlg:cat:list:w:s:pick:plum")

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, "cat"))
  inst.state.current_step |> should.equal("picked")
  instance.get_data(inst, "__dialog_state") |> should.equal(Some("plum"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:widget:engine_paged_select_next_and_pick")
}

pub fn engine_pager_prev_clamps_at_first_page_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = catalog_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 508

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "cat", "dlg:cat:list:w:s:prev")

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, "cat"))
  let assert Some(raw) = instance.get_data(inst, "__dialog_widget:list:s")
  let assert Ok(store) = types.decode_store(raw)
  widget.current_page(store) |> should.equal(0)
}

// ============================================================================
// Unit: build validation, widget event parsing
// ============================================================================

fn widget_builder(id: String) {
  let #(encode_state, decode_state) = dialog.string_codec()
  dialog.new(
    id:,
    storage: flow_storage.create_noop_storage(),
    initial_state: fn() { "" },
    encode_state:,
    decode_state:,
  )
}

fn widgets_window(builder, window_id: String, widgets) {
  dialog.window_with_widgets(
    builder,
    id: window_id,
    render: fn(_state: String, _ctx: Ctx) {
      RenderedWindow(
        text: format.build() |> format.text("x") |> format.to_formatted(),
        buttons: [],
        media: None,
      )
    },
    on_action: fn(state, _event, _ctx) { Ok(types.Stay(state)) },
    widgets:,
  )
}

pub fn build_duplicate_widget_id_test() {
  widget_builder("ok")
  |> widgets_window("menu", [
    widget.radio(id: "z", items: zone_items, default: None),
    widget.radio(id: "z", items: zone_items, default: None),
  ])
  |> dialog.initial("menu")
  |> dialog.build()
  |> should.equal(Error(types.DuplicateWidgetId(window: "menu", id: "z")))
}

pub fn build_reserved_character_in_widget_id_test() {
  widget_builder("ok")
  |> widgets_window("menu", [
    widget.radio(id: "z:1", items: zone_items, default: None),
  ])
  |> dialog.initial("menu")
  |> dialog.build()
  |> should.equal(Error(types.ReservedIdCharacter(kind: "widget", id: "z:1")))
}

pub fn build_unknown_multiselect_done_target_test() {
  widget_builder("ok")
  |> widgets_window("menu", [
    widget.multiselect(
      id: "x",
      items: extra_items,
      min: 0,
      max: 3,
      done: "nope",
    ),
  ])
  |> dialog.initial("menu")
  |> dialog.build()
  |> should.equal(Error(types.UnknownWindowReference(from: "menu", to: "nope")))
}

pub fn build_widget_action_too_long_test() {
  let long_id = string.repeat("w", 60)
  let result =
    widget_builder("ok")
    |> widgets_window("m", [
      widget.radio(id: long_id, items: zone_items, default: None),
    ])
    |> dialog.initial("m")
    |> dialog.build()
  let assert Error(types.CallbackDataTooLong(window: "m", ..)) = result
}

pub fn parse_widget_event_test() {
  dialog_engine.parse_widget_event(ActionEvent(
    action_id: "w",
    arg: Some("s:pick:19:30"),
  ))
  |> should.equal(Ok(#("s", "pick", Some("19:30"))))

  dialog_engine.parse_widget_event(ActionEvent(
    action_id: "w",
    arg: Some("p:next"),
  ))
  |> should.equal(Ok(#("p", "next", None)))

  dialog_engine.parse_widget_event(ActionEvent(action_id: "pick", arg: None))
  |> should.equal(Error(Nil))
}

pub fn widget_store_codec_roundtrip_test() {
  let store =
    types.new_store()
    |> types.store_set("page", "2")
    |> types.store_set("values", "[\"a\",\"b\"]")
  let assert Ok(decoded) = types.decode_store(types.encode_store(store))
  types.store_get(decoded, "page") |> should.equal(Some("2"))
  types.store_get(decoded, "values") |> should.equal(Some("[\"a\",\"b\"]"))
}
