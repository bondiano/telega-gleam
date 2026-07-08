import birdie
import gleam/dynamic/decode
import gleam/http/response
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should

import telega/bot
import telega/dialog
import telega/dialog/engine as dialog_engine
import telega/dialog/render as dialog_render
import telega/dialog/types.{
  type ActionEvent, type RenderedWindow, ActionArgButton, ActionButton,
  ActionEvent, RenderedWindow,
}
import telega/dialog_driver as driver
import telega/error
import telega/flow/instance
import telega/flow/registry as flow_registry
import telega/flow/storage as flow_storage
import telega/flow/types as flow_types
import telega/format
import telega/reply
import telega/router
import telega/testing/context
import telega/testing/factory
import telega/testing/mock
import telega/testing/render as testing_render

pub fn main() {
  gleeunit.main()
}

// ============================================================================
// Test dialog: settings (menu → name → confirm)
// ============================================================================

pub type Settings {
  Settings(lang: String, name: String)
}

fn settings_codec() -> #(
  fn(Settings) -> String,
  fn(String) -> Result(Settings, Nil),
) {
  dialog.json_codec(
    encoder: fn(settings: Settings) {
      json.object([
        #("lang", json.string(settings.lang)),
        #("name", json.string(settings.name)),
      ])
    },
    decoder: {
      use lang <- decode.field("lang", decode.string)
      use name <- decode.field("name", decode.string)
      decode.success(Settings(lang:, name:))
    },
  )
}

fn render_menu(
  settings: Settings,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> RenderedWindow {
  let text =
    format.build()
    |> format.bold_text("Settings")
    |> format.line_break()
    |> format.text("lang: " <> settings.lang <> ", name: " <> settings.name)
    |> format.to_formatted()
  RenderedWindow(
    text:,
    buttons: [
      [ActionArgButton("EN", "lang", "en"), ActionArgButton("RU", "lang", "ru")],
      [ActionButton("Name", "name")],
      [ActionButton("Done", "done")],
    ],
    media: None,
  )
}

fn handle_menu(
  settings: Settings,
  event: ActionEvent,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> Result(types.DialogAction(Settings), error.TelegaError) {
  case event.action_id, event.arg {
    "lang", Some(lang) -> Ok(types.Stay(Settings(..settings, lang:)))
    "name", _ -> Ok(types.Goto("name", settings))
    "done", _ -> Ok(types.Goto("confirm", settings))
    _, _ -> Ok(types.Stay(settings))
  }
}

fn render_name(
  _settings: Settings,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> RenderedWindow {
  let text =
    format.build()
    |> format.text("What's your name?")
    |> format.to_formatted()
  RenderedWindow(
    text:,
    buttons: [[ActionButton("‹ Back", "back")]],
    media: None,
  )
}

fn handle_name_action(
  settings: Settings,
  event: ActionEvent,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> Result(types.DialogAction(Settings), error.TelegaError) {
  case event.action_id {
    "back" -> Ok(types.Back(settings))
    _ -> Ok(types.Stay(settings))
  }
}

fn handle_name_text(
  settings: Settings,
  text: String,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> Result(types.DialogAction(Settings), error.TelegaError) {
  Ok(types.Goto("confirm", Settings(..settings, name: text)))
}

fn render_confirm(
  settings: Settings,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> RenderedWindow {
  let text =
    format.build()
    |> format.bold_text("Save?")
    |> format.line_break()
    |> format.text(settings.name <> " / " <> settings.lang)
    |> format.to_formatted()
  RenderedWindow(
    text:,
    buttons: [[ActionButton("Yes", "yes"), ActionButton("No", "no")]],
    media: None,
  )
}

fn handle_confirm(
  settings: Settings,
  event: ActionEvent,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> Result(types.DialogAction(Settings), error.TelegaError) {
  case event.action_id {
    "yes" -> Ok(types.Done(settings))
    "no" -> Ok(types.Back(settings))
    _ -> Ok(types.Stay(settings))
  }
}

fn settings_dialog(
  storage: flow_types.FlowStorage(error.TelegaError),
) -> dialog.Dialog(Settings, Nil, error.TelegaError, Nil) {
  let #(encode_state, decode_state) = settings_codec()
  let assert Ok(built) =
    dialog.new(
      id: "settings",
      storage:,
      initial_state: fn() { Settings(lang: "en", name: "") },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(id: "menu", render: render_menu, on_action: handle_menu)
    |> dialog.window_with_input(
      id: "name",
      render: render_name,
      on_action: handle_name_action,
      on_text: handle_name_text,
    )
    |> dialog.window(
      id: "confirm",
      render: render_confirm,
      on_action: handle_confirm,
    )
    |> dialog.initial("menu")
    |> dialog.on_done(fn(settings: Settings, ctx) {
      reply.with_text(ctx, "saved: " <> settings.name <> "/" <> settings.lang)
      |> result.replace(ctx)
    })
    |> dialog.build()
  built
}

fn settings_flow(
  storage: flow_types.FlowStorage(error.TelegaError),
) -> flow_types.Flow(String, Nil, error.TelegaError, Nil) {
  dialog_engine.compile(dialog.compiled(settings_dialog(storage)))
}

// ============================================================================
// Test dialog: gallery (cover → photo) — media windows and text ↔ media
// ============================================================================

/// State is the current photo key ("a"/"b"); picking another photo keeps the
/// window but swaps the media (media → media edit).
fn render_cover(
  _state: String,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> RenderedWindow {
  RenderedWindow(
    text: format.build() |> format.text("Gallery") |> format.to_formatted(),
    buttons: [[ActionButton("Open", "open")]],
    media: None,
  )
}

fn handle_cover(
  state: String,
  event: ActionEvent,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> Result(types.DialogAction(String), error.TelegaError) {
  case event.action_id {
    "open" -> Ok(types.Goto("photo", state))
    _ -> Ok(types.Stay(state))
  }
}

fn render_gallery_photo(
  state: String,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> RenderedWindow {
  RenderedWindow(
    text: format.build()
      |> format.text("Photo " <> state)
      |> format.to_formatted(),
    buttons: [
      [ActionArgButton("A", "pick", "a"), ActionArgButton("B", "pick", "b")],
      [ActionButton("‹ Back", "back")],
    ],
    media: Some(types.PhotoMedia(
      media: "file_" <> state,
      has_spoiler: state == "b",
    )),
  )
}

fn handle_gallery_photo(
  state: String,
  event: ActionEvent,
  _ctx: bot.Context(Nil, error.TelegaError, Nil),
) -> Result(types.DialogAction(String), error.TelegaError) {
  case event.action_id, event.arg {
    "pick", Some(next) -> Ok(types.Stay(next))
    "back", _ -> Ok(types.Back(state))
    _, _ -> Ok(types.Stay(state))
  }
}

fn gallery_flow(
  storage: flow_types.FlowStorage(error.TelegaError),
) -> flow_types.Flow(String, Nil, error.TelegaError, Nil) {
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(gallery) =
    dialog.new(
      id: "gallery",
      storage:,
      initial_state: fn() { "a" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(id: "cover", render: render_cover, on_action: handle_cover)
    |> dialog.window(
      id: "photo",
      render: render_gallery_photo,
      on_action: handle_gallery_photo,
    )
    |> dialog.initial("cover")
    |> dialog.build()
  dialog_engine.compile(dialog.compiled(gallery))
}

fn start_gallery(flow, client, chat_id: Int) -> Nil {
  driver.start_dialog(flow, client, chat_id, command: "/gallery")
}

// ============================================================================
// Driving helpers (thin settings-dialog wrappers over the shared driver)
// ============================================================================

fn flow_id(chat_id: Int) -> String {
  driver.flow_id(chat_id, "settings")
}

fn start_dialog(flow, client, chat_id: Int) -> Nil {
  driver.start_dialog(flow, client, chat_id, command: "/settings")
}

fn press(flow, client, storage, chat_id: Int, data: String) -> Nil {
  driver.press(flow, client, storage, chat_id, "settings", data)
}

fn press_in(
  flow,
  client,
  storage,
  chat_id: Int,
  dialog_id: String,
  data: String,
) -> Nil {
  driver.press(flow, client, storage, chat_id, dialog_id, data)
}

fn send_text(flow, client, storage, chat_id: Int, text: String) -> Nil {
  driver.send_text(flow, client, storage, chat_id, "settings", text)
}

fn dialog_mock_client() {
  driver.dialog_mock_client()
}

// ============================================================================
// Level 1: pure window render snapshots
// ============================================================================

pub fn menu_window_frame_test() {
  render_menu(Settings(lang: "en", name: ""), context.context(session: Nil))
  |> testing_render.window_frame
  |> birdie.snap(title: "dialog:settings:menu_frame")
}

pub fn name_window_frame_test() {
  render_name(Settings(lang: "en", name: ""), context.context(session: Nil))
  |> testing_render.window_frame
  |> birdie.snap(title: "dialog:settings:name_frame")
}

pub fn confirm_window_frame_test() {
  render_confirm(
    Settings(lang: "ru", name: "Alice"),
    context.context(session: Nil),
  )
  |> testing_render.window_frame
  |> birdie.snap(title: "dialog:settings:confirm_frame")
}

pub fn gallery_photo_window_frame_test() {
  render_gallery_photo("b", context.context(session: Nil))
  |> testing_render.window_frame
  |> birdie.snap(title: "dialog:gallery:photo_frame")
}

// ============================================================================
// Level 2: engine scenario transcripts
// ============================================================================

pub fn engine_happy_path_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 201

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "dlg:settings:menu:name")
  send_text(flow, client, storage, chat_id, "Alice")
  press(flow, client, storage, chat_id, "dlg:settings:confirm:yes")

  // Completed: the instance is gone.
  let assert Ok(None) = storage.load(flow_id(chat_id))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:happy_path")
}

pub fn engine_back_returns_to_previous_window_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 202

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "dlg:settings:menu:name")
  press(flow, client, storage, chat_id, "dlg:settings:name:back")

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  inst.state.current_step |> should.equal("menu")

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:back")
}

pub fn engine_stay_rerenders_with_new_state_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 203

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "dlg:settings:menu:lang:ru")

  // Still on the menu, state updated and persisted.
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  inst.state.current_step |> should.equal("menu")
  instance.get_data(inst, "__dialog_state")
  |> should.equal(Some("{\"lang\":\"ru\",\"name\":\"\"}"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:stay_updates_lang")
}

pub fn engine_stale_button_answers_and_stays_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 204

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "dlg:settings:menu:name")
  // Press a button on the outdated "menu" message while "name" is current.
  press(flow, client, storage, chat_id, "dlg:settings:menu:done")

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  inst.state.current_step |> should.equal("name")

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:stale_button")
}

pub fn engine_foreign_callback_is_ignored_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 205

  start_dialog(flow, client, chat_id)
  // Not the dlg: scheme at all, and a different dialog's payload.
  press(flow, client, storage, chat_id, "menu:other:action")
  press(flow, client, storage, chat_id, "dlg:other_dialog:menu:x")

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  inst.state.current_step |> should.equal("menu")

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:foreign_callback")
}

pub fn engine_text_without_on_text_rerenders_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 206

  start_dialog(flow, client, chat_id)
  // The menu window has no on_text: the text is swallowed, window re-rendered.
  send_text(flow, client, storage, chat_id, "hello?")

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  inst.state.current_step |> should.equal("menu")
  // The swallowed text never touched the state: nothing was saved, so the
  // window still renders from the initial state.
  instance.get_data(inst, "__dialog_state") |> should.equal(None)

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:text_without_on_text")
}

pub fn engine_persistence_json_roundtrip_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 207

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "dlg:settings:menu:name")

  // "Restart": serialize the instance to JSON and back, then resume with a
  // fresh client — the dialog continues from the same window and edits the
  // same live message.
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  let assert Ok(restored) =
    instance.from_json_string(instance.to_json_string(inst))
  restored.state.current_step |> should.equal("name")
  let assert Ok(_) = storage.save(restored)

  let #(fresh_client, fresh_calls) = dialog_mock_client()
  send_text(flow, fresh_client, storage, chat_id, "Alice")

  let assert Ok(Some(after)) = storage.load(flow_id(chat_id))
  after.state.current_step |> should.equal("confirm")

  mock.get_calls(fresh_calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:persistence_resume")
}

pub fn engine_toast_skips_auto_answer_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(toasty) =
    dialog.new(
      id: "toasty",
      storage:,
      initial_state: fn() { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "main",
      render: fn(_state, _ctx) {
        RenderedWindow(
          text: format.build() |> format.text("Hi") |> format.to_formatted(),
          buttons: [[ActionButton("Ping", "ping")]],
          media: None,
        )
      },
      on_action: fn(state, _event, ctx) {
        let assert Ok(Nil) = dialog.toast(ctx, "pong!")
        Ok(types.Stay(state))
      },
    )
    |> dialog.initial("main")
    |> dialog.build()
  let flow = dialog_engine.compile(dialog.compiled(toasty))
  let #(client, calls) = dialog_mock_client()
  let chat_id = 208

  driver.start_dialog(flow, client, chat_id, command: "/toasty")
  driver.press(flow, client, storage, chat_id, "toasty", "dlg:toasty:main:ping")

  // Exactly one answerCallbackQuery — the toast; the engine's auto-answer
  // must be skipped.
  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:toast_skips_auto_answer")
}

pub fn engine_back_on_initial_window_re_renders_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(rooted) =
    dialog.new(
      id: "rooted",
      storage:,
      initial_state: fn() { "initial" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "home",
      render: fn(state, _ctx) {
        RenderedWindow(
          text: format.build()
            |> format.text("Home: " <> state)
            |> format.to_formatted(),
          buttons: [[ActionButton("‹ Back", "back")]],
          media: None,
        )
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "back" -> Ok(types.Back("carried-in-back"))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.initial("home")
    |> dialog.build()
  let flow = dialog_engine.compile(dialog.compiled(rooted))
  let #(client, calls) = dialog_mock_client()
  let chat_id = 209

  driver.start_dialog(flow, client, chat_id, command: "/rooted")
  // Back on the initial window with empty history: treated as Stay — the
  // state carried in Back(state) is persisted and the window re-renders,
  // instead of the press being silently dropped.
  driver.press(flow, client, storage, chat_id, "rooted", "dlg:rooted:home:back")

  let assert Ok(Some(inst)) = storage.load(driver.flow_id(chat_id, "rooted"))
  inst.state.current_step |> should.equal("home")
  instance.get_data(inst, "__dialog_state")
  |> should.equal(Some("carried-in-back"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:back_empty_history_stays")
}

pub fn engine_bool_leftover_button_is_answered_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 210

  start_dialog(flow, client, chat_id)
  // A leftover bool-format button ("<id>:true") from some non-dialog
  // keyboard: the spinner is removed and the window is untouched.
  press(flow, client, storage, chat_id, "some_id:true")

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  inst.state.current_step |> should.equal("menu")
  instance.get_data(inst, "__dialog_state") |> should.equal(None)

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:bool_leftover_answered")
}

pub fn engine_press_on_outdated_message_is_stale_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 211

  start_dialog(flow, client, chat_id)
  // The window id matches, but the press comes from a message that is not
  // the tracked live one (message 999 vs live 1): stale answer, on_action
  // never runs.
  driver.press_on_message(
    flow,
    client,
    storage,
    chat_id,
    "settings",
    "dlg:settings:menu:name",
    message_id: 999,
  )

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  inst.state.current_step |> should.equal("menu")

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:stale_message_guard")
}

// ============================================================================
// Registry routing: callback filters and orphan callbacks (dialog.attach)
// ============================================================================

fn two_window_dialog(
  id: String,
  storage: flow_types.FlowStorage(error.TelegaError),
) -> dialog.Dialog(String, Nil, error.TelegaError, Nil) {
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(built) =
    dialog.new(
      id:,
      storage:,
      initial_state: fn() { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window(
      id: "home",
      render: fn(_state, _ctx) {
        RenderedWindow(
          text: format.build()
            |> format.text(id <> " home")
            |> format.to_formatted(),
          buttons: [[ActionButton("Go", "go")]],
          media: None,
        )
      },
      on_action: fn(state, event: ActionEvent, _ctx) {
        case event.action_id {
          "go" -> Ok(types.Goto("second", state))
          _ -> Ok(types.Stay(state))
        }
      },
    )
    |> dialog.window(
      id: "second",
      render: fn(_state, _ctx) {
        RenderedWindow(
          text: format.build()
            |> format.text(id <> " second")
            |> format.to_formatted(),
          buttons: [],
          media: None,
        )
      },
      on_action: fn(state, _event, _ctx) { Ok(types.Stay(state)) },
    )
    |> dialog.initial("home")
    |> dialog.build()
  built
}

fn route_update(r, client, upd) -> Nil {
  let assert Ok(_) = router.handle(r, driver.ctx_for(client, upd), upd)
  Nil
}

pub fn callback_filter_routes_press_to_its_dialog_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let registry =
    flow_registry.new_registry()
    |> dialog.attach_on_command(
      command: "alpha",
      dialog: two_window_dialog("alpha", storage),
    )
    |> dialog.attach_on_command(
      command: "beta",
      dialog: two_window_dialog("beta", storage),
    )
  let r = flow_registry.apply_to_router(router.new("dialogs"), registry)
  let #(client, _calls) = dialog_mock_client()
  let chat_id = 212

  route_update(
    r,
    client,
    factory.command_update_with(
      command: "alpha",
      payload: None,
      from_id: driver.user_id,
      chat_id:,
    ),
  )
  route_update(
    r,
    client,
    factory.command_update_with(
      command: "beta",
      payload: None,
      from_id: driver.user_id,
      chat_id:,
    ),
  )

  // Both dialogs are waiting. Without the per-dialog callback filter the
  // first waiting flow would steal every press; with it, beta's payload
  // reaches beta.
  route_update(
    r,
    client,
    factory.callback_query_update_with(
      data: "dlg:beta:home:go",
      from_id: driver.user_id,
      chat_id:,
    ),
  )

  let assert Ok(Some(beta)) = storage.load(driver.flow_id(chat_id, "beta"))
  beta.state.current_step |> should.equal("second")
  let assert Ok(Some(alpha)) = storage.load(driver.flow_id(chat_id, "alpha"))
  alpha.state.current_step |> should.equal("home")

  // And alpha's own press still reaches alpha.
  route_update(
    r,
    client,
    factory.callback_query_update_with(
      data: "dlg:alpha:home:go",
      from_id: driver.user_id,
      chat_id:,
    ),
  )
  let assert Ok(Some(alpha)) = storage.load(driver.flow_id(chat_id, "alpha"))
  alpha.state.current_step |> should.equal("second")
}

pub fn orphan_dialog_callback_answered_stale_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let registry =
    flow_registry.new_registry()
    |> dialog.attach_on_command(
      command: "alpha",
      dialog: two_window_dialog("alpha", storage),
    )
  let r = flow_registry.apply_to_router(router.new("dialogs"), registry)
  let #(client, calls) = dialog_mock_client()
  let chat_id = 213

  // No live instance: a press on the message of an already finished dialog
  // is answered with the stale label by the orphan handler `attach` wires.
  route_update(
    r,
    client,
    factory.callback_query_update_with(
      data: "dlg:alpha:home:go",
      from_id: driver.user_id,
      chat_id:,
    ),
  )

  let assert Ok(None) = storage.load(driver.flow_id(chat_id, "alpha"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:orphan_stale_answer")
}

// ============================================================================
// Level 3: edit-error matrix
// ============================================================================

fn api_error_response(description: String) -> String {
  json.to_string(
    json.object([
      #("ok", json.bool(False)),
      #("error_code", json.int(400)),
      #("description", json.string(description)),
    ]),
  )
}

fn error_matrix_client(edit_error: String) {
  mock.stateful_client(handler: fn(req, _n) {
    let body = case
      string.contains(req.path, "editMessageText"),
      string.contains(req.path, "answerCallbackQuery")
    {
      True, _ -> api_error_response(edit_error)
      _, True -> mock.bool_response()
      _, _ -> mock.message_response()
    }
    Ok(response.new(200) |> response.set_body(body))
  })
}

pub fn render_not_modified_is_noop_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) =
    error_matrix_client("Bad Request: message is not modified")
  let chat_id = 301

  start_dialog(flow, client, chat_id)
  // Stay → edit fails with "not modified" → treated as success, no fallback.
  press(flow, client, storage, chat_id, "dlg:settings:menu:lang:ru")

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  instance.get_data(inst, "__dialog_message_id") |> should.equal(Some("1"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:render:not_modified_noop")
}

pub fn render_edit_not_found_falls_back_to_send_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) =
    error_matrix_client("Bad Request: message to edit not found")
  let chat_id = 302

  start_dialog(flow, client, chat_id)
  // Stay → edit fails with "not found" → a fresh sendMessage replaces it.
  press(flow, client, storage, chat_id, "dlg:settings:menu:lang:ru")

  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  inst.wait_token |> option.is_some() |> should.be_true()

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:render:edit_not_found_fallback")
}

pub fn render_unexpected_400_keeps_dialog_alive_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = settings_flow(storage)
  let #(client, calls) = error_matrix_client("Bad Request: chat not found")
  let chat_id = 303

  start_dialog(flow, client, chat_id)
  press(flow, client, storage, chat_id, "dlg:settings:menu:lang:ru")

  // The render failed, but the dialog is still waiting for input.
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id))
  inst.state.current_step |> should.equal("menu")
  inst.wait_token |> option.is_some() |> should.be_true()

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:render:unexpected_400_keeps_waiting")
}

// ============================================================================
// Media transitions (levels 2+3): the edit-or-send strategy matrix
// ============================================================================

fn media_mock_client() {
  driver.media_mock_client()
}

fn gallery_instance(
  storage: flow_types.FlowStorage(error.TelegaError),
  chat_id: Int,
) -> flow_types.FlowInstance {
  let assert Ok(Some(inst)) = storage.load(driver.flow_id(chat_id, "gallery"))
  inst
}

pub fn engine_text_to_media_recreates_message_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = gallery_flow(storage)
  let #(client, calls) = media_mock_client()
  let chat_id = 401

  start_gallery(flow, client, chat_id)
  // cover (text) → photo (media): delete + sendPhoto, kind flips to media.
  press_in(flow, client, storage, chat_id, "gallery", "dlg:gallery:cover:open")

  let inst = gallery_instance(storage, chat_id)
  inst.state.current_step |> should.equal("photo")
  instance.get_data(inst, "__dialog_message_kind")
  |> should.equal(Some("media"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:text_to_media")
}

pub fn engine_media_to_media_edits_in_place_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = gallery_flow(storage)
  let #(client, calls) = media_mock_client()
  let chat_id = 402

  start_gallery(flow, client, chat_id)
  press_in(flow, client, storage, chat_id, "gallery", "dlg:gallery:cover:open")
  // photo "a" → photo "b": one editMessageMedia swaps file, caption and
  // spoiler — no recreation.
  press_in(
    flow,
    client,
    storage,
    chat_id,
    "gallery",
    "dlg:gallery:photo:pick:b",
  )

  let inst = gallery_instance(storage, chat_id)
  inst.state.current_step |> should.equal("photo")
  instance.get_data(inst, "__dialog_message_kind")
  |> should.equal(Some("media"))
  instance.get_data(inst, "__dialog_state") |> should.equal(Some("b"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:media_to_media_edit")
}

pub fn engine_media_to_text_recreates_message_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = gallery_flow(storage)
  let #(client, calls) = media_mock_client()
  let chat_id = 403

  start_gallery(flow, client, chat_id)
  press_in(flow, client, storage, chat_id, "gallery", "dlg:gallery:cover:open")
  // photo (media) → cover (text): delete + sendMessage, kind flips back.
  press_in(flow, client, storage, chat_id, "gallery", "dlg:gallery:photo:back")

  let inst = gallery_instance(storage, chat_id)
  inst.state.current_step |> should.equal("cover")
  instance.get_data(inst, "__dialog_message_kind")
  |> should.equal(Some("text"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:engine:media_to_text")
}

pub fn render_media_delete_fail_still_sends_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = gallery_flow(storage)
  // A message older than 48 hours cannot be deleted: the failure is
  // swallowed and the photo is sent anyway.
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "answerCallbackQuery",
        response: mock.bool_response(),
      ),
      mock.route_with_response(
        path_contains: "deleteMessage",
        response: api_error_response("Bad Request: message can't be deleted"),
      ),
    ])
  let chat_id = 404

  start_gallery(flow, client, chat_id)
  press_in(flow, client, storage, chat_id, "gallery", "dlg:gallery:cover:open")

  let inst = gallery_instance(storage, chat_id)
  inst.state.current_step |> should.equal("photo")
  instance.get_data(inst, "__dialog_message_kind")
  |> should.equal(Some("media"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:render:media_delete_fail_still_sends")
}

pub fn render_media_edit_not_found_falls_back_to_send_test() {
  let assert Ok(storage) = flow_storage.create_ets_storage()
  let flow = gallery_flow(storage)
  let #(client, calls) =
    mock.routed_client(routes: [
      mock.route_with_response(
        path_contains: "answerCallbackQuery",
        response: mock.bool_response(),
      ),
      mock.route_with_response(
        path_contains: "deleteMessage",
        response: mock.bool_response(),
      ),
      mock.route_with_response(
        path_contains: "editMessageMedia",
        response: api_error_response("Bad Request: message to edit not found"),
      ),
    ])
  let chat_id = 405

  start_gallery(flow, client, chat_id)
  press_in(flow, client, storage, chat_id, "gallery", "dlg:gallery:cover:open")
  // The media edit fails because the message is gone: a fresh sendPhoto
  // replaces it.
  press_in(
    flow,
    client,
    storage,
    chat_id,
    "gallery",
    "dlg:gallery:photo:pick:b",
  )

  let inst = gallery_instance(storage, chat_id)
  inst.state.current_step |> should.equal("photo")
  instance.get_data(inst, "__dialog_message_kind")
  |> should.equal(Some("media"))

  mock.get_calls(calls)
  |> testing_render.calls_transcript
  |> birdie.snap(title: "dialog:render:media_edit_not_found_fallback")
}

// ============================================================================
// Unit: build validation, callback data scheme
// ============================================================================

fn minimal_window(builder, id: String) {
  dialog.window(
    builder,
    id:,
    render: fn(_state: String, _ctx: bot.Context(Nil, error.TelegaError, Nil)) {
      RenderedWindow(
        text: format.build() |> format.text("x") |> format.to_formatted(),
        buttons: [],
        media: None,
      )
    },
    on_action: fn(state, _event, _ctx) { Ok(types.Stay(state)) },
  )
}

fn string_builder(id: String) {
  let #(encode_state, decode_state) = dialog.string_codec()
  dialog.new(
    id:,
    storage: flow_storage.create_noop_storage(),
    initial_state: fn() { "" },
    encode_state:,
    decode_state:,
  )
}

pub fn build_no_windows_test() {
  string_builder("empty")
  |> dialog.initial("menu")
  |> dialog.build()
  |> should.equal(Error(types.NoWindows))
}

pub fn build_duplicate_window_id_test() {
  string_builder("dup")
  |> minimal_window("menu")
  |> minimal_window("menu")
  |> dialog.initial("menu")
  |> dialog.build()
  |> should.equal(Error(types.DuplicateWindowId(id: "menu")))
}

pub fn build_reserved_character_in_dialog_id_test() {
  string_builder("bad:id")
  |> minimal_window("menu")
  |> dialog.initial("menu")
  |> dialog.build()
  |> should.equal(
    Error(types.ReservedIdCharacter(kind: "dialog", id: "bad:id")),
  )
}

pub fn build_reserved_character_in_window_id_test() {
  string_builder("ok")
  |> minimal_window("me:nu")
  |> dialog.initial("me:nu")
  |> dialog.build()
  |> should.equal(Error(types.ReservedIdCharacter(kind: "window", id: "me:nu")))
}

pub fn build_unknown_initial_window_test() {
  string_builder("ok")
  |> minimal_window("menu")
  |> dialog.initial("nope")
  |> dialog.build()
  |> should.equal(Error(types.UnknownInitialWindow(id: "nope")))
}

pub fn build_missing_initial_window_test() {
  string_builder("ok")
  |> minimal_window("menu")
  |> dialog.build()
  |> should.equal(Error(types.UnknownInitialWindow(id: "")))
}

pub fn build_callback_prefix_too_long_test() {
  let long_window_id = string.repeat("w", 60)
  let result =
    string_builder("ok")
    |> minimal_window(long_window_id)
    |> dialog.initial(long_window_id)
    |> dialog.build()
  let assert Error(types.CallbackDataTooLong(window:, ..)) = result
  window |> should.equal(long_window_id)
}

pub fn parse_callback_data_test() {
  dialog_engine.parse_callback_data("dlg:settings:menu:done")
  |> should.equal(
    Ok(#("settings", "menu", ActionEvent(action_id: "done", arg: None))),
  )

  dialog_engine.parse_callback_data("dlg:settings:menu:pick:item:42")
  |> should.equal(
    Ok(#(
      "settings",
      "menu",
      ActionEvent(action_id: "pick", arg: Some("item:42")),
    )),
  )

  dialog_engine.parse_callback_data("menu:simple:action1")
  |> should.equal(Error(Nil))
}

pub fn pack_callback_data_limits_test() {
  dialog_render.pack_callback_data(
    dialog_id: "d",
    window_id: "w",
    action_id: "a",
    arg: None,
  )
  |> should.equal(Ok("dlg:d:w:a"))

  let assert Error(dialog_render.InvalidButton(action_id: "a:b", ..)) =
    dialog_render.pack_callback_data(
      dialog_id: "d",
      window_id: "w",
      action_id: "a:b",
      arg: None,
    )

  let assert Error(dialog_render.InvalidButton(..)) =
    dialog_render.pack_callback_data(
      dialog_id: "d",
      window_id: "w",
      action_id: "a",
      arg: Some(string.repeat("x", 60)),
    )
}

pub fn pack_callback_data_reserves_widget_namespace_test() {
  // The bare "w" action id is reserved: with a `:`-carrying arg it would be
  // indistinguishable from a widget event on parse.
  let assert Error(dialog_render.InvalidButton(action_id: "w", ..)) =
    dialog_render.pack_callback_data(
      dialog_id: "d",
      window_id: "m",
      action_id: "w",
      arg: None,
    )

  // The namespaced widget form is the one place `:` is allowed...
  dialog_render.pack_callback_data(
    dialog_id: "d",
    window_id: "m",
    action_id: "w:s:pick",
    arg: Some("plum"),
  )
  |> should.equal(Ok("dlg:d:m:w:s:pick:plum"))

  // ...and ordinary ids are unaffected (even ones starting with "w").
  dialog_render.pack_callback_data(
    dialog_id: "d",
    window_id: "m",
    action_id: "wide",
    arg: None,
  )
  |> should.equal(Ok("dlg:d:m:wide"))
}
