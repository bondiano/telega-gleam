//// # Declarative dialogs
////
//// A dialog is a set of windows; a window is a pure render function plus
//// event handlers. The engine renders everything into **one live message**
//// (edit-or-send, including text ↔ media transitions — see
//// `telega/dialog/render`), parses button callback data itself, keeps a
//// navigation stack with `Back`, and persists all state in a `FlowStorage` —
//// the dialog survives restarts with any persistent backend
//// (Postgres/SQLite/Redis).
////
//// Dialogs compile to `telega/flow` state machines: a window is a step,
//// navigation is a flow action, delivery of callbacks/text into the active
//// window is the flow registry's wait-token auto-resume. Nothing here needs
//// a dedicated router route.
////
//// Full guide (positioning vs conversations/flows/menu builder, widgets,
//// sub-dialogs, i18n, testing):
//// [docs/dialogs.md](https://hexdocs.pm/telega/docs/dialogs.html).
////
//// ## Quick start
////
//// ```gleam
//// import telega/dialog
//// import telega/dialog/types.{ActionButton, RenderedWindow}
//// import telega/flow/registry as flow_registry
//// import telega/flow/storage as flow_storage
//// import telega/format
////
//// fn render_menu(state: MyState, _ctx) -> RenderedWindow {
////   RenderedWindow(
////     text: format.build() |> format.bold_text("Settings") |> format.to_formatted(),
////     buttons: [[ActionButton("Name", "name")], [ActionButton("Done", "done")]],
////     media: None,
////   )
//// }
////
//// fn handle_menu(state, event: types.ActionEvent, _ctx) {
////   case event.action_id {
////     "name" -> Ok(types.Goto("name", state))
////     "done" -> Ok(types.Done(state))
////     _ -> Ok(types.Stay(state))
////   }
//// }
////
//// let assert Ok(settings) =
////   dialog.new(
////     id: "settings",
////     storage: flow_storage,
////     initial_state: fn() { MyState(name: "") },
////     encode_state: encode_my_state,
////     decode_state: decode_my_state,
////   )
////   |> dialog.window(id: "menu", render: render_menu, on_action: handle_menu)
////   |> dialog.window_with_input(id: "name", render:, on_action:, on_text:)
////   |> dialog.initial("menu")
////   |> dialog.on_done(save_settings)
////   |> dialog.build()
////
//// let registry =
////   flow_registry.new_registry()
////   |> dialog.attach_on_command("settings", settings)
////   |> flow_registry.register_cancel_command("cancel")
////
//// let router = flow_registry.apply_to_router(router, registry)
//// ```
////
//// ## Behavior notes
////
//// - **One live instance** per `(dialog, chat, user)`: a repeated start
////   command resumes (re-renders) the current dialog instead of opening a
////   second one. Use `restart` for a hard reset.
//// - **The dialog is modal**: while it waits for a callback, plain text
////   messages are swallowed (the window is re-rendered). Commands still
////   reach the router — register a `/cancel` via
////   `flow_registry.register_cancel_command`.
//// - **Widgets**: `window_with_widgets` attaches managed keyboards from
////   `telega/dialog/widget` (pager, select, radio, multiselect,
////   paged_select) — the engine renders their rows, handles their callbacks
////   and persists their state; read selections with `widget_store`.
//// - **Sub-dialogs**: `subdialog` attaches another built dialog (its state
////   type may differ); any window starts it with `StartSub(sub_id, args,
////   state)` and receives its exported result in `on_sub_result`. The sub
////   shares the live message and the parent's storage/TTL/labels; `Back` on
////   its first window cancels it; nesting is one level deep.
//// - **Stale buttons**: a press on an outdated dialog message (an old
////   window, or an old copy of the live message) answers with `labels.stale`
////   and does nothing. Presses on messages of an already **finished** dialog
////   are answered the same way by a fallback that `attach` registers
////   automatically.
//// - **Errors**: user handler errors are logged, emit
////   `["telega", "dialog", "error"]` telemetry and re-render the current
////   window; failed renders (API errors, over-64-byte callback data) are
////   logged loudly and keep the dialog alive.

import gleam/bool
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set
import gleam/string

import logging

import telega/bot.{type Context}
import telega/dialog/engine.{type CompiledDialog, CompiledDialog}
import telega/dialog/render
import telega/dialog/types.{
  type ActionEvent, type DialogAction, type DialogBuildError, type Labels,
  type RenderedWindow, type Window, Window,
}
import telega/dialog/widget
import telega/error.{type TelegaError}
import telega/flow/engine as flow_engine
import telega/flow/registry as flow_registry
import telega/flow/storage as flow_storage
import telega/flow/types as flow_types

/// A validated dialog, ready to be attached to a flow registry. Internally
/// the windows are type-erased (they carry the state codec in closures); the
/// typed codec is kept alongside so the dialog can be attached as a
/// sub-dialog with `subdialog`.
pub opaque type Dialog(state, session, error, dependencies) {
  Dialog(
    compiled: CompiledDialog(session, error, dependencies),
    encode_state: fn(state) -> String,
    decode_or_initial: fn(String) -> state,
  )
}

/// A sub-dialog attachment collected by `subdialog`, already erased to the
/// parent's encoded-state form.
type SubAttachment(session, error, dependencies) {
  SubAttachment(
    id: String,
    windows: List(Window(String, session, error, dependencies)),
    initial: String,
    init: fn(String, dict.Dict(String, String)) -> String,
    result: fn(String) -> dict.Dict(String, String),
    has_own_subs: Bool,
  )
}

pub opaque type DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(
    id: String,
    windows: List(Window(state, session, error, dependencies)),
    initial: Option(String),
    initial_state: fn() -> state,
    encode_state: fn(state) -> String,
    decode_state: fn(String) -> Result(state, Nil),
    on_done: Option(
      fn(state, Context(session, error, dependencies)) ->
        Result(Context(session, error, dependencies), error),
    ),
    subs: List(SubAttachment(session, error, dependencies)),
    sub_result_hooks: List(
      #(
        String,
        fn(
          state,
          dict.Dict(String, String),
          Context(session, error, dependencies),
        ) -> Result(DialogAction(state), error),
      ),
    ),
    storage: flow_types.FlowStorage(error),
    ttl_ms: Option(Int),
    labels: fn(Context(session, error, dependencies)) -> Labels,
  )
}

/// Start building a dialog. `encode_state`/`decode_state` serialize the
/// user state for persistence (precedent: session serialization); for simple
/// states see `string_codec` and `json_codec`.
pub fn new(
  id id: String,
  storage storage: flow_types.FlowStorage(error),
  initial_state initial_state: fn() -> state,
  encode_state encode_state: fn(state) -> String,
  decode_state decode_state: fn(String) -> Result(state, Nil),
) -> DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(
    id:,
    windows: [],
    initial: None,
    initial_state:,
    encode_state:,
    decode_state:,
    on_done: None,
    subs: [],
    sub_result_hooks: [],
    storage:,
    ttl_ms: None,
    labels: fn(_ctx) { types.default_labels() },
  )
}

/// Codec pair for a plain `String` state:
/// `let #(encode, decode) = dialog.string_codec()`.
pub fn string_codec() -> #(
  fn(String) -> String,
  fn(String) -> Result(String, Nil),
) {
  #(fn(state) { state }, fn(raw) { Ok(raw) })
}

/// Codec pair from a JSON encoder + decoder:
/// `let #(encode, decode) = dialog.json_codec(encode_settings, settings_decoder())`.
pub fn json_codec(
  encoder encoder: fn(state) -> json.Json,
  decoder decoder: decode.Decoder(state),
) -> #(fn(state) -> String, fn(String) -> Result(state, Nil)) {
  #(fn(state) { json.to_string(encoder(state)) }, fn(raw) {
    json.parse(raw, decoder) |> result.replace_error(Nil)
  })
}

/// Add a window that only reacts to button presses. Text sent to it is
/// swallowed with a re-render.
pub fn window(
  builder builder: DialogBuilder(state, session, error, dependencies),
  id id: String,
  render render: fn(state, Context(session, error, dependencies)) ->
    RenderedWindow,
  on_action on_action: fn(
    state,
    ActionEvent,
    Context(session, error, dependencies),
  ) -> Result(DialogAction(state), error),
) -> DialogBuilder(state, session, error, dependencies) {
  add_window(
    builder,
    Window(
      id:,
      render:,
      on_action:,
      on_text: None,
      widgets: [],
      on_sub_result: None,
    ),
  )
}

/// Add a window that also accepts text input (e.g. "enter your name").
pub fn window_with_input(
  builder builder: DialogBuilder(state, session, error, dependencies),
  id id: String,
  render render: fn(state, Context(session, error, dependencies)) ->
    RenderedWindow,
  on_action on_action: fn(
    state,
    ActionEvent,
    Context(session, error, dependencies),
  ) -> Result(DialogAction(state), error),
  on_text on_text: fn(state, String, Context(session, error, dependencies)) ->
    Result(DialogAction(state), error),
) -> DialogBuilder(state, session, error, dependencies) {
  add_window(
    builder,
    Window(
      id:,
      render:,
      on_action:,
      on_text: Some(on_text),
      widgets: [],
      on_sub_result: None,
    ),
  )
}

/// Add a window with managed keyboard widgets (see `telega/dialog/widget`).
/// Widget button rows are appended after the window's own buttons and their
/// events are handled by the widgets themselves, bypassing `on_action`.
///
/// ```gleam
/// |> dialog.window_with_widgets(id: "fruits", render:, on_action:, widgets: [
///   widget.multiselect(id: "f", items: fruit_items, min: 1, max: 3,
///     done: "confirm"),
/// ])
/// ```
pub fn window_with_widgets(
  builder builder: DialogBuilder(state, session, error, dependencies),
  id id: String,
  render render: fn(state, Context(session, error, dependencies)) ->
    RenderedWindow,
  on_action on_action: fn(
    state,
    ActionEvent,
    Context(session, error, dependencies),
  ) -> Result(DialogAction(state), error),
  widgets widgets: List(
    types.KeyboardWidget(state, session, error, dependencies),
  ),
) -> DialogBuilder(state, session, error, dependencies) {
  add_window(
    builder,
    Window(
      id:,
      render:,
      on_action:,
      on_text: None,
      widgets:,
      on_sub_result: None,
    ),
  )
}

fn add_window(
  builder: DialogBuilder(state, session, error, dependencies),
  window: Window(state, session, error, dependencies),
) -> DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(..builder, windows: [window, ..builder.windows])
}

/// Attach a built dialog as a **sub-dialog**, startable from any window via
/// `StartSub(sub_id, args, state)` (the sub id is the attached dialog's id).
/// The sub takes over the live dialog message; its `Done` hands control back
/// to the window that started it (see `on_sub_result`). Nesting is one level
/// deep: a dialog with sub-dialogs of its own cannot be attached
/// (`NestedSubDialog`).
///
/// - `init` builds the sub's starting state from the parent state and the
///   `StartSub` args.
/// - `result` exports the sub's final state as the dict handed to the parent
///   window's `on_sub_result`; prefix the keys with the sub id by convention
///   (`"address.city"`) to keep them collision-free.
///
/// The attached dialog's own `storage`, `ttl`, `labels` and `on_done` are
/// ignored while it runs as a sub — the parent's apply. A `Back` on the
/// sub's first window cancels the sub (returns without a result).
pub fn subdialog(
  builder builder: DialogBuilder(state, session, error, dependencies),
  sub sub: Dialog(sub_state, session, error, dependencies),
  init init: fn(state, dict.Dict(String, String)) -> sub_state,
  result result: fn(sub_state) -> dict.Dict(String, String),
) -> DialogBuilder(state, session, error, dependencies) {
  let parent_decode = decode_or_initial(builder)
  let attachment =
    SubAttachment(
      id: sub.compiled.id,
      windows: dict.values(sub.compiled.windows),
      initial: sub.compiled.initial,
      init: fn(parent_raw, args) {
        sub.encode_state(init(parent_decode(parent_raw), args))
      },
      result: fn(sub_raw) { result(sub.decode_or_initial(sub_raw)) },
      has_own_subs: dict.size(sub.compiled.subs) > 0,
    )
  DialogBuilder(..builder, subs: [attachment, ..builder.subs])
}

/// Handle the result of a sub-dialog started from `window`: the handler
/// receives the window's state and the result dict exported by the
/// `subdialog` attachment, and returns the next action (`Stay` re-renders
/// the window with the updated state). Without a handler the window is
/// simply re-rendered.
pub fn on_sub_result(
  builder builder: DialogBuilder(state, session, error, dependencies),
  window window: String,
  handler handler: fn(
    state,
    dict.Dict(String, String),
    Context(session, error, dependencies),
  ) -> Result(DialogAction(state), error),
) -> DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(..builder, sub_result_hooks: [
    #(window, handler),
    ..builder.sub_result_hooks
  ])
}

/// Set the window the dialog opens with.
pub fn initial(
  builder builder: DialogBuilder(state, session, error, dependencies),
  window_id window_id: String,
) -> DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(..builder, initial: Some(window_id))
}

/// Called when a window returns `Done`: receives the final state. The live
/// message keeps its text but loses the keyboard.
pub fn on_done(
  builder builder: DialogBuilder(state, session, error, dependencies),
  handler handler: fn(state, Context(session, error, dependencies)) ->
    Result(Context(session, error, dependencies), error),
) -> DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(..builder, on_done: Some(handler))
}

/// Expire the dialog after `ms` milliseconds (lazy check on next event).
pub fn with_ttl(
  builder builder: DialogBuilder(state, session, error, dependencies),
  ms ms: Int,
) -> DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(..builder, ttl_ms: Some(ms))
}

/// Localize engine-generated texts (stale-button notice, widget labels).
/// The factory receives the update's `Context`, so `telega_i18n.t` works:
/// `dialog.with_labels(builder, fn(ctx) { labels_from_i18n(ctx) })`.
pub fn with_labels(
  builder builder: DialogBuilder(state, session, error, dependencies),
  labels labels: fn(Context(session, error, dependencies)) -> Labels,
) -> DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(..builder, labels:)
}

/// Validate and build the dialog. Checks window ids for duplicates and the
/// reserved `:`/`.` characters, the initial window, `on_sub_result` and
/// widget window references, sub-dialog attachments, and that all
/// callback-data prefixes (including the `<sub_id>.` namespace of sub
/// windows) leave room within Telegram's 64-byte limit.
///
/// Building also **erases** the state type: every window is wrapped so its
/// closures decode/encode the state with this dialog's codec, which is what
/// lets sub-dialogs with different state types share one flow.
pub fn build(
  builder builder: DialogBuilder(state, session, error, dependencies),
) -> Result(Dialog(state, session, error, dependencies), DialogBuildError) {
  let windows = list.reverse(builder.windows)
  let subs = list.reverse(builder.subs)

  use <- require(windows != [], types.NoWindows)
  use <- require(
    !string.contains(builder.id, ":") && !string.contains(builder.id, "."),
    types.ReservedIdCharacter(kind: "dialog", id: builder.id),
  )
  use windows <- result.try(attach_sub_result_hooks(
    windows,
    list.reverse(builder.sub_result_hooks),
  ))
  use Nil <- result.try(validate_windows(builder.id, windows))
  use Nil <- result.try(validate_widget_targets(windows))
  use Nil <- result.try(validate_subs(builder.id, subs))
  use initial <- result.try(option.to_result(
    builder.initial,
    types.UnknownInitialWindow(id: ""),
  ))
  use <- require(
    list.any(windows, fn(window) { window.id == initial }),
    types.UnknownInitialWindow(id: initial),
  )

  let encode = builder.encode_state
  let decode = decode_or_initial(builder)
  let erased_own =
    list.map(windows, fn(window) {
      #(window.id, erase_window(window, encode, decode))
    })
  let erased_subs =
    list.flat_map(subs, fn(sub) {
      list.map(sub.windows, fn(window) {
        let namespaced = namespace_window(sub.id, window)
        #(namespaced.id, namespaced)
      })
    })

  Ok(Dialog(
    compiled: CompiledDialog(
      id: builder.id,
      windows: dict.from_list(list.append(erased_own, erased_subs)),
      initial:,
      initial_encoded: fn() { encode(builder.initial_state()) },
      on_done: option.map(builder.on_done, fn(on_done) {
        fn(raw, ctx) { on_done(decode(raw), ctx) }
      }),
      subs: dict.from_list(
        list.map(subs, fn(sub) {
          #(
            sub.id,
            engine.CompiledSub(
              id: sub.id,
              initial: namespaced_id(sub.id, sub.initial),
              init: sub.init,
              result: sub.result,
            ),
          )
        }),
      ),
      storage: builder.storage,
      ttl_ms: builder.ttl_ms,
      labels: builder.labels,
    ),
    encode_state: encode,
    decode_or_initial: decode,
  ))
}

/// Decode with a logged fallback to the initial state — a codec mismatch
/// (e.g. a state shape change after a deploy) must not kill the dialog.
fn decode_or_initial(
  builder: DialogBuilder(state, session, error, dependencies),
) -> fn(String) -> state {
  let DialogBuilder(id:, decode_state:, initial_state:, ..) = builder
  fn(raw) {
    case decode_state(raw) {
      Ok(state) -> state
      Error(Nil) -> {
        logging.log(
          logging.Warning,
          "[dialog:"
            <> id
            <> "] failed to decode state, falling back to initial",
        )
        initial_state()
      }
    }
  }
}

fn attach_sub_result_hooks(
  windows: List(Window(state, session, error, dependencies)),
  hooks: List(
    #(
      String,
      fn(
        state,
        dict.Dict(String, String),
        Context(session, error, dependencies),
      ) -> Result(DialogAction(state), error),
    ),
  ),
) -> Result(List(Window(state, session, error, dependencies)), DialogBuildError) {
  list.try_fold(hooks, windows, fn(windows, hook) {
    let #(window_id, handler) = hook
    use <- require(
      list.any(windows, fn(window) { window.id == window_id }),
      types.UnknownWindowReference(from: "on_sub_result", to: window_id),
    )
    Ok(
      list.map(windows, fn(window) {
        case window.id == window_id {
          True -> Window(..window, on_sub_result: Some(handler))
          False -> window
        }
      }),
    )
  })
}

/// Measure the callback-data budget through the very function that packs it
/// at render time (`render.callback_data`), so build-time validation and
/// runtime packing can never diverge.
fn validate_budget(
  dialog_id: String,
  window_id: String,
  action_id: String,
) -> Result(Nil, DialogBuildError) {
  let bytes =
    string.byte_size(render.callback_data(
      dialog_id:,
      window_id:,
      action_id:,
      arg: None,
    ))
  use <- require(
    bytes <= render.max_callback_data_bytes,
    types.CallbackDataTooLong(window: window_id, action: action_id, bytes:),
  )
  Ok(Nil)
}

fn validate_windows(
  dialog_id: String,
  windows: List(Window(state, session, error, dependencies)),
) -> Result(Nil, DialogBuildError) {
  use _seen <- result.try(
    list.try_fold(windows, set.new(), fn(seen, window) {
      use <- require(
        !string.contains(window.id, ":") && !string.contains(window.id, "."),
        types.ReservedIdCharacter(kind: "window", id: window.id),
      )
      use <- require(
        !set.contains(seen, window.id),
        types.DuplicateWindowId(id: window.id),
      )
      // The static prefix `dlg:<dialog>:<window>:` must leave room for at
      // least a one-character action id; per-button lengths (dynamic action
      // ids and args) are validated on every render.
      use Nil <- result.try(validate_budget(dialog_id, window.id, "x"))
      use Nil <- result.try(validate_widgets(dialog_id, window.id, window))
      Ok(set.insert(seen, window.id))
    }),
  )
  Ok(Nil)
}

fn validate_widgets(
  dialog_id: String,
  window_id: String,
  window: Window(state, session, error, dependencies),
) -> Result(Nil, DialogBuildError) {
  use _seen <- result.try(
    list.try_fold(window.widgets, set.new(), fn(seen, widget) {
      use <- require(
        !string.contains(widget.id, ":"),
        types.ReservedIdCharacter(kind: "widget", id: widget.id),
      )
      use <- require(
        !set.contains(seen, widget.id),
        types.DuplicateWidgetId(window: window.id, id: widget.id),
      )
      use Nil <- result.try(
        list.try_each(widget.static_actions, validate_budget(
          dialog_id,
          window_id,
          _,
        )),
      )
      Ok(set.insert(seen, widget.id))
    }),
  )
  Ok(Nil)
}

/// Widget `Goto` targets (e.g. a multiselect's `done` window) must reference
/// existing windows; checked once all windows are known.
fn validate_widget_targets(
  windows: List(Window(state, session, error, dependencies)),
) -> Result(Nil, DialogBuildError) {
  let window_ids = set.from_list(list.map(windows, fn(window) { window.id }))
  list.try_each(windows, fn(window) {
    list.try_each(window.widgets, fn(widget) {
      list.try_each(widget.goto_targets, fn(target) {
        use <- require(
          set.contains(window_ids, target),
          types.UnknownWindowReference(from: window.id, to: target),
        )
        Ok(Nil)
      })
    })
  })
}

/// Sub-dialog attachments: unique ids, one nesting level, and the re-checked
/// 64-byte budget — the sub was validated against its own dialog id, but at
/// runtime its buttons carry the parent id plus the `<sub_id>.` prefix.
fn validate_subs(
  dialog_id: String,
  subs: List(SubAttachment(session, error, dependencies)),
) -> Result(Nil, DialogBuildError) {
  use _seen <- result.try(
    list.try_fold(subs, set.new(), fn(seen, sub) {
      use <- require(
        !set.contains(seen, sub.id),
        types.DuplicateSubDialogId(id: sub.id),
      )
      use <- require(!sub.has_own_subs, types.NestedSubDialog(id: sub.id))
      use Nil <- result.try(
        list.try_each(sub.windows, fn(window) {
          let namespaced = namespaced_id(sub.id, window.id)
          use Nil <- result.try(validate_budget(dialog_id, namespaced, "x"))
          list.try_each(window.widgets, fn(widget) {
            list.try_each(widget.static_actions, validate_budget(
              dialog_id,
              namespaced,
              _,
            ))
          })
        }),
      )
      Ok(set.insert(seen, sub.id))
    }),
  )
  Ok(Nil)
}

fn require(
  condition: Bool,
  build_error: DialogBuildError,
  continue: fn() -> Result(a, DialogBuildError),
) -> Result(a, DialogBuildError) {
  bool.guard(when: !condition, return: Error(build_error), otherwise: continue)
}

// Type erasure -----------------------------------------------------------------
//
// The engine only moves the encoded state string around; these wrappers bind
// a window's typed handlers to the dialog's codec. A sub-dialog's windows
// are additionally re-keyed under `<sub_id>.<window_id>` with their `Goto`
// targets mapped into the same namespace, so a sub can never navigate into
// parent windows.

fn erase_window(
  window: Window(state, session, error, dependencies),
  encode: fn(state) -> String,
  decode: fn(String) -> state,
) -> Window(String, session, error, dependencies) {
  Window(
    id: window.id,
    render: fn(raw, ctx) { window.render(decode(raw), ctx) },
    on_action: fn(raw, event, ctx) {
      window.on_action(decode(raw), event, ctx)
      |> result.map(erase_action(_, encode))
    },
    on_text: option.map(window.on_text, fn(on_text) {
      fn(raw, text, ctx) {
        on_text(decode(raw), text, ctx) |> result.map(erase_action(_, encode))
      }
    }),
    widgets: list.map(window.widgets, erase_widget(_, encode, decode)),
    on_sub_result: option.map(window.on_sub_result, fn(handler) {
      fn(raw, sub_result, ctx) {
        handler(decode(raw), sub_result, ctx)
        |> result.map(erase_action(_, encode))
      }
    }),
  )
}

fn erase_action(
  action: DialogAction(state),
  encode: fn(state) -> String,
) -> DialogAction(String) {
  case action {
    types.Stay(state) -> types.Stay(encode(state))
    types.Goto(window_id:, state:) ->
      types.Goto(window_id:, state: encode(state))
    types.Back(state) -> types.Back(encode(state))
    types.Done(state) -> types.Done(encode(state))
    types.StartSub(sub_id:, args:, state:) ->
      types.StartSub(sub_id:, args:, state: encode(state))
  }
}

fn erase_widget(
  widget_item: types.KeyboardWidget(state, session, error, dependencies),
  encode: fn(state) -> String,
  decode: fn(String) -> state,
) -> types.KeyboardWidget(String, session, error, dependencies) {
  types.KeyboardWidget(
    id: widget_item.id,
    render: fn(wctx: types.WidgetCtx(String, session, error, dependencies)) {
      widget_item.render(typed_widget_ctx(wctx, decode))
    },
    on_event: fn(wctx, cmd, arg) {
      widget_item.on_event(typed_widget_ctx(wctx, decode), cmd, arg)
      |> result.map(fn(widget_result) {
        case widget_result {
          types.StoreUpdated(store) -> types.StoreUpdated(store)
          types.Emit(action) -> types.Emit(erase_action(action, encode))
        }
      })
    },
    goto_targets: widget_item.goto_targets,
    static_actions: widget_item.static_actions,
  )
}

fn typed_widget_ctx(
  wctx: types.WidgetCtx(String, session, error, dependencies),
  decode: fn(String) -> state,
) -> types.WidgetCtx(state, session, error, dependencies) {
  types.WidgetCtx(
    state: decode(wctx.state),
    store: wctx.store,
    labels: wctx.labels,
    ctx: wctx.ctx,
  )
}

fn namespaced_id(sub_id: String, window_id: String) -> String {
  sub_id <> engine.sub_separator <> window_id
}

/// Re-key an (already erased) sub-dialog window under the sub namespace and
/// map its navigation targets into it.
fn namespace_window(
  sub_id: String,
  window: Window(String, session, error, dependencies),
) -> Window(String, session, error, dependencies) {
  let map_action = fn(action: DialogAction(String)) {
    case action {
      types.Goto(window_id:, state:) ->
        types.Goto(window_id: namespaced_id(sub_id, window_id), state:)
      other -> other
    }
  }
  Window(
    id: namespaced_id(sub_id, window.id),
    render: window.render,
    on_action: fn(raw, event, ctx) {
      window.on_action(raw, event, ctx) |> result.map(map_action)
    },
    on_text: option.map(window.on_text, fn(on_text) {
      fn(raw, text, ctx) { on_text(raw, text, ctx) |> result.map(map_action) }
    }),
    widgets: list.map(window.widgets, fn(widget_item) {
      types.KeyboardWidget(
        ..widget_item,
        on_event: fn(wctx, cmd, arg) {
          widget_item.on_event(wctx, cmd, arg)
          |> result.map(fn(widget_result) {
            case widget_result {
              types.Emit(action) -> types.Emit(map_action(action))
              other -> other
            }
          })
        },
        goto_targets: list.map(widget_item.goto_targets, namespaced_id(
          sub_id,
          _,
        )),
      )
    }),
    on_sub_result: option.map(window.on_sub_result, fn(handler) {
      fn(raw, sub_result, ctx) {
        handler(raw, sub_result, ctx) |> result.map(map_action)
      }
    }),
  )
}

/// Access the compiled form of a dialog for engine-level tests.
@internal
pub fn compiled(
  dialog: Dialog(state, session, error, dependencies),
) -> CompiledDialog(session, error, dependencies) {
  dialog.compiled
}

// Attaching and starting ---------------------------------------------------------

/// Register the dialog in a flow registry without a trigger — start it
/// programmatically with `start`. Event delivery into the active window is
/// the registry's standard auto-resume, so remember to finish with
/// `flow_registry.apply_to_router`.
///
/// Attaching also wires two routing guards for free: the dialog only
/// auto-resumes on its own `dlg:<id>:` callbacks (so several waiting
/// flows/dialogs can coexist), and presses on messages of an already
/// finished dialog are answered with `labels.stale` instead of hanging.
pub fn attach(
  registry registry: flow_registry.FlowRegistry(session, error, dependencies),
  dialog dialog: Dialog(state, session, error, dependencies),
) -> flow_registry.FlowRegistry(session, error, dependencies) {
  flow_registry.register_callable(registry, engine.compile(dialog.compiled))
  |> with_dialog_routing(dialog)
}

/// Register the dialog and start it on a command (e.g. `"settings"` for
/// `/settings`). A repeated command while the dialog is active resumes it.
/// Wires the same routing guards as `attach`.
pub fn attach_on_command(
  registry registry: flow_registry.FlowRegistry(session, error, dependencies),
  command command: String,
  dialog dialog: Dialog(state, session, error, dependencies),
) -> flow_registry.FlowRegistry(session, error, dependencies) {
  flow_registry.register(
    registry,
    flow_types.OnCommand(command),
    engine.compile(dialog.compiled),
  )
  |> with_dialog_routing(dialog)
}

fn with_dialog_routing(
  registry: flow_registry.FlowRegistry(session, error, dependencies),
  dialog: Dialog(state, session, error, dependencies),
) -> flow_registry.FlowRegistry(session, error, dependencies) {
  let flow_name = engine.flow_name_prefix <> dialog.compiled.id
  let prefix = "dlg:" <> dialog.compiled.id <> ":"
  let labels = dialog.compiled.labels
  registry
  |> flow_registry.with_callback_filter(flow_name:, filter: string.starts_with(
    _,
    prefix,
  ))
  |> flow_registry.with_orphan_callback_handler(
    matches: string.starts_with(_, prefix),
    handler: fn(ctx, _data) {
      render.answer_quietly(ctx, Some(labels(ctx).stale))
      Ok(ctx)
    },
  )
}

/// Start (or resume) an attached dialog from any handler.
pub fn start(
  ctx ctx: Context(session, error, dependencies),
  registry registry: flow_registry.FlowRegistry(session, error, dependencies),
  dialog_id dialog_id: String,
) -> Result(Context(session, error, dependencies), error) {
  flow_registry.call_flow(
    ctx,
    registry,
    name: engine.flow_name_prefix <> dialog_id,
    initial: dict.new(),
  )
}

/// Delete the current instance and start the dialog from scratch (a
/// repeated start command only resumes — this is the hard reset).
pub fn restart(
  ctx ctx: Context(session, error, dependencies),
  registry registry: flow_registry.FlowRegistry(session, error, dependencies),
  dialog_id dialog_id: String,
) -> Result(Context(session, error, dependencies), error) {
  let #(user_id, chat_id) = flow_engine.extract_ids_from_context(ctx)
  let instance_id =
    flow_storage.generate_id(
      user_id,
      chat_id,
      engine.flow_name_prefix <> dialog_id,
    )
  let _ = flow_registry.cancel_flow_instance(registry, flow_id: instance_id)
  start(ctx, registry, dialog_id)
}

/// Read a widget's persistent store from inside a window render or handler
/// (`on_action`, `on_text`, `on_done`). Combine with the typed readers from
/// `telega/dialog/widget`:
///
/// ```gleam
/// let zone =
///   dialog.widget_store(ctx, window_id: "prefs", widget_id: "zone")
///   |> widget.radio_value
///   |> option.unwrap("hall")
/// ```
///
/// Returns an empty store when the widget has no state yet. In pure render
/// tests seed the store first with `widget.seed_store`.
pub fn widget_store(
  ctx ctx: Context(session, error, dependencies),
  window_id window_id: String,
  widget_id widget_id: String,
) -> types.WidgetStore {
  widget.widget_store(ctx, window_id:, widget_id:)
}

// Callback answers ----------------------------------------------------------------

/// Show a modal alert to the user who pressed the button. Call inside
/// `on_action` before returning an action; the engine will skip its
/// automatic spinner-removing answer for this event.
pub fn alert(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Nil, TelegaError) {
  render.alert(ctx, text)
}

/// Show a toast notification at the top of the chat. Same contract as
/// `alert`.
pub fn toast(
  ctx ctx: Context(session, error, dependencies),
  text text: String,
) -> Result(Nil, TelegaError) {
  render.toast(ctx, text)
}
