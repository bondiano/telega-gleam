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
////     initial_state: fn(_ctx) { MyState(name: "") },
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
    decode_or_initial: fn(Context(session, error, dependencies), String) ->
      state,
  )
}

/// A sub-dialog attachment collected by `subdialog`, already erased to the
/// parent's encoded-state form.
type SubAttachment(session, error, dependencies) {
  SubAttachment(
    id: String,
    windows: List(Window(String, session, error, dependencies)),
    initial: String,
    init: fn(
      Context(session, error, dependencies),
      String,
      dict.Dict(String, String),
    ) -> String,
    /// The sub's *own* sub-dialogs, already compiled. They are re-keyed under
    /// this sub's namespace so nesting is transitive.
    nested: List(#(String, engine.CompiledSub(session, error, dependencies))),
  )
}

pub opaque type DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(
    id: String,
    windows: List(Window(state, session, error, dependencies)),
    initial: Option(String),
    initial_state: fn(Context(session, error, dependencies)) -> state,
    encode_state: fn(state) -> String,
    decode_state: fn(String) -> Result(state, Nil),
    on_done: Option(
      fn(state, Context(session, error, dependencies)) ->
        Result(Context(session, error, dependencies), error),
    ),
    subs: List(SubAttachment(session, error, dependencies)),
    /// `#(window id, sub id, handler)`. The handler takes the sub's final
    /// state still encoded — `on_sub_result` closed over the sub's decoder
    /// when it was registered.
    sub_result_hooks: List(
      #(
        String,
        String,
        fn(state, String, Context(session, error, dependencies)) ->
          Result(DialogAction(state), error),
      ),
    ),
    message_hooks: List(
      #(
        String,
        fn(state, types.MessageInput, Context(session, error, dependencies)) ->
          Result(DialogAction(state), error),
      ),
    ),
    show_mode_overrides: List(#(String, types.ShowMode)),
    storage: flow_types.FlowStorage(error),
    ttl_ms: Option(Int),
    labels: fn(Context(session, error, dependencies)) -> Labels,
    show_mode: types.ShowMode,
  )
}

/// Start building a dialog. `encode_state`/`decode_state` serialize the
/// user state for persistence (precedent: session serialization); for simple
/// states see `string_codec` and `json_codec`.
///
/// `initial_state` receives the `Context`, so a dialog can open on state seeded
/// from the session, the injected dependencies or the sender — a form
/// pre-filled from the user's profile, say.
pub fn new(
  id id: String,
  storage storage: flow_types.FlowStorage(error),
  initial_state initial_state: fn(Context(session, error, dependencies)) ->
    state,
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
    message_hooks: [],
    show_mode_overrides: [],
    storage:,
    ttl_ms: None,
    labels: fn(_ctx) { types.default_labels() },
    show_mode: types.EditLive,
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
      on_message: None,
      widgets: [],
      on_sub_result: dict.new(),
      show_mode: None,
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
      on_message: None,
      widgets: [],
      on_sub_result: dict.new(),
      show_mode: None,
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
      on_message: None,
      widgets:,
      on_sub_result: dict.new(),
      show_mode: None,
    ),
  )
}

/// Add a window that renders from data it does not keep in state — the
/// getter pattern.
///
/// `load` is the half that reads the world (a booking row, the user's open
/// orders, a price from an injected service); `render` stays a pure function
/// of `(state, data)` and can be snapshot-tested by handing it data made up
/// on the spot. Together they are exactly the `render` of
/// [`window`](#window), so nothing else about the window changes.
///
/// `load` runs on **every** render of the window — the first one and each
/// re-render after a press — so keep it to one cheap read, and put anything
/// expensive in `state` or `dependencies` instead.
///
/// ```gleam
/// |> dialog.window_with_data(
///   id: "orders",
///   load: fn(_state, ctx) { db.open_orders(ctx.dependencies.db, ctx.update.from_id) },
///   render: fn(_state, orders, _ctx) { order_list(orders) },
///   on_action:,
/// )
/// ```
///
/// To give a window with text input or widgets the same treatment, pass
/// [`with_data`](#with_data) as their `render`.
pub fn window_with_data(
  builder builder: DialogBuilder(state, session, error, dependencies),
  id id: String,
  load load: fn(state, Context(session, error, dependencies)) -> data,
  render render: fn(state, data, Context(session, error, dependencies)) ->
    RenderedWindow,
  on_action on_action: fn(
    state,
    ActionEvent,
    Context(session, error, dependencies),
  ) -> Result(DialogAction(state), error),
) -> DialogBuilder(state, session, error, dependencies) {
  window(builder, id:, render: with_data(load:, render:), on_action:)
}

/// The getter pattern as a plain render function, for the window constructors
/// that take other handlers too:
///
/// ```gleam
/// |> dialog.window_with_input(
///   id: "search",
///   render: dialog.with_data(load: recent_queries, render: search_window),
///   on_action:,
///   on_text:,
/// )
/// ```
pub fn with_data(
  load load: fn(state, Context(session, error, dependencies)) -> data,
  render render: fn(state, data, Context(session, error, dependencies)) ->
    RenderedWindow,
) -> fn(state, Context(session, error, dependencies)) -> RenderedWindow {
  fn(state, ctx) { render(state, load(state, ctx), ctx) }
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
/// to the window that started it (see `on_sub_result`).
///
/// Nesting is **transitive**: a dialog that has sub-dialogs of its own can be
/// attached, and its whole tree is flattened into this dialog's namespace
/// (`<sub>.<inner>.<window>`). At runtime the entered dialogs form a stack —
/// each `Done` or boundary `Back` pops one level.
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
) -> DialogBuilder(state, session, error, dependencies) {
  let parent_decode = decode_or_initial(builder)
  let attachment =
    SubAttachment(
      id: sub.compiled.id,
      windows: dict.values(sub.compiled.windows),
      initial: sub.compiled.initial,
      init: fn(ctx, parent_raw, args) {
        sub.encode_state(init(parent_decode(ctx, parent_raw), args))
      },
      nested: dict.to_list(sub.compiled.subs),
    )
  DialogBuilder(..builder, subs: [attachment, ..builder.subs])
}

/// Handle what a sub-dialog started from `window` came back with.
///
/// The handler receives the window's state and `sub`'s **final state, in
/// `sub`'s own type** — passing the sub itself is what lets the decoding
/// happen here rather than in a hand-written codec. It returns the next
/// action, `Stay` re-rendering the window with whatever it learned:
///
/// ```gleam
/// |> dialog.on_sub_result(window: "confirm", sub: address_dialog, handler:
///   fn(state, address: Address, _ctx) {
///     Ok(types.Stay(State(..state, address: Some(address.line))))
///   })
/// ```
///
/// Registered per `#(window, sub)`: one window can start several sub-dialogs
/// and react to each in its own type. A sub with no handler for the window it
/// returned to simply re-renders that window. `build()` rejects a handler for
/// an unknown window or for a sub that is not attached — either way it could
/// never run.
pub fn on_sub_result(
  builder builder: DialogBuilder(state, session, error, dependencies),
  window window: String,
  sub sub: Dialog(sub_state, session, error, dependencies),
  handler handler: fn(state, sub_state, Context(session, error, dependencies)) ->
    Result(DialogAction(state), error),
) -> DialogBuilder(state, session, error, dependencies) {
  let decode_sub = sub.decode_or_initial
  DialogBuilder(..builder, sub_result_hooks: [
    #(window, sub.compiled.id, fn(state, sub_raw, ctx) {
      handler(state, decode_sub(ctx, sub_raw), ctx)
    }),
    ..builder.sub_result_hooks
  ])
}

/// Accept non-text messages (a photo, a location, a voice note) on `window`.
///
/// Without it the engine politely ignores them and re-renders. The classified
/// input is in `MessageInput`; the raw update stays on `ctx.update`.
///
/// ```gleam
/// |> dialog.on_message(window: "avatar", handler: fn(state, input, _ctx) {
///   case input {
///     types.PhotoMessage(file_ids: [best, ..]) -> Ok(types.Goto("confirm", best))
///     _ -> Ok(types.Stay(state))
///   }
/// })
/// ```
pub fn on_message(
  builder builder: DialogBuilder(state, session, error, dependencies),
  window window: String,
  handler handler: fn(
    state,
    types.MessageInput,
    Context(session, error, dependencies),
  ) -> Result(DialogAction(state), error),
) -> DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(..builder, message_hooks: [
    #(window, handler),
    ..builder.message_hooks
  ])
}

/// Choose when the dialog replaces its live message instead of editing it.
///
/// The default (`EditLive`) always edits, which is right for button presses.
/// A dialog with text-input windows wants `ResendOnUserMessage`: after the
/// user types, an edited window is scrolled *above* their message and easy to
/// miss, so the window is resent below it instead.
///
/// ```gleam
/// |> dialog.with_show_mode(types.ResendOnUserMessage)
/// ```
pub fn with_show_mode(
  builder builder: DialogBuilder(state, session, error, dependencies),
  mode mode: types.ShowMode,
) -> DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(..builder, show_mode: mode)
}

/// Override the dialog's show mode for one window.
///
/// A dialog that edits in place is usually right, but a single window that
/// asks the user to type wants its answer resent below what they typed:
///
/// ```gleam
/// |> dialog.with_window_show_mode(
///   window: "name",
///   mode: types.ResendOnUserMessage,
/// )
/// ```
///
/// `build()` rejects an unknown window id. For one render only, a handler can
/// override both with `types.Shown(mode, action)`.
pub fn with_window_show_mode(
  builder builder: DialogBuilder(state, session, error, dependencies),
  window window: String,
  mode mode: types.ShowMode,
) -> DialogBuilder(state, session, error, dependencies) {
  DialogBuilder(..builder, show_mode_overrides: [
    #(window, mode),
    ..builder.show_mode_overrides
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
    list.map(subs, fn(sub) { sub.id }),
  ))
  use windows <- result.try(attach_message_hooks(
    windows,
    list.reverse(builder.message_hooks),
  ))
  use windows <- result.try(attach_show_modes(
    windows,
    list.reverse(builder.show_mode_overrides),
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
      initial_encoded: fn(ctx) { encode(builder.initial_state(ctx)) },
      on_done: option.map(builder.on_done, fn(on_done) {
        fn(raw, ctx) { on_done(decode(ctx, raw), ctx) }
      }),
      subs: dict.from_list(list.flat_map(subs, namespaced_subs)),
      storage: builder.storage,
      ttl_ms: builder.ttl_ms,
      labels: builder.labels,
      show_mode: builder.show_mode,
    ),
    encode_state: encode,
    decode_or_initial: decode,
  ))
}

/// Decode with a logged fallback to the initial state — a codec mismatch
/// (e.g. a state shape change after a deploy) must not kill the dialog.
fn decode_or_initial(
  builder: DialogBuilder(state, session, error, dependencies),
) -> fn(Context(session, error, dependencies), String) -> state {
  let DialogBuilder(id:, decode_state:, initial_state:, ..) = builder
  fn(ctx, raw) {
    case decode_state(raw) {
      Ok(state) -> state
      Error(Nil) -> {
        logging.log(
          logging.Warning,
          "[dialog:"
            <> id
            <> "] failed to decode state, falling back to initial",
        )
        initial_state(ctx)
      }
    }
  }
}

fn attach_sub_result_hooks(
  windows: List(Window(state, session, error, dependencies)),
  hooks: List(
    #(
      String,
      String,
      fn(state, String, Context(session, error, dependencies)) ->
        Result(DialogAction(state), error),
    ),
  ),
  attached_subs: List(String),
) -> Result(List(Window(state, session, error, dependencies)), DialogBuildError) {
  list.try_fold(hooks, windows, fn(windows, hook) {
    let #(window_id, sub_id, handler) = hook
    use <- require(
      list.any(windows, fn(window) { window.id == window_id }),
      types.UnknownWindowReference(from: "on_sub_result", to: window_id),
    )
    use <- require(
      list.contains(attached_subs, sub_id),
      types.UnattachedSubDialog(window: window_id, sub: sub_id),
    )
    Ok(
      list.map(windows, fn(window) {
        case window.id == window_id {
          True ->
            Window(
              ..window,
              on_sub_result: dict.insert(window.on_sub_result, sub_id, handler),
            )
          False -> window
        }
      }),
    )
  })
}

fn attach_message_hooks(
  windows: List(Window(state, session, error, dependencies)),
  hooks: List(
    #(
      String,
      fn(state, types.MessageInput, Context(session, error, dependencies)) ->
        Result(DialogAction(state), error),
    ),
  ),
) -> Result(List(Window(state, session, error, dependencies)), DialogBuildError) {
  list.try_fold(hooks, windows, fn(windows, hook) {
    let #(window_id, handler) = hook
    use <- require(
      list.any(windows, fn(window) { window.id == window_id }),
      types.UnknownWindowReference(from: "on_message", to: window_id),
    )
    Ok(
      list.map(windows, fn(window) {
        case window.id == window_id {
          True -> Window(..window, on_message: Some(handler))
          False -> window
        }
      }),
    )
  })
}

fn attach_show_modes(
  windows: List(Window(state, session, error, dependencies)),
  overrides: List(#(String, types.ShowMode)),
) -> Result(List(Window(state, session, error, dependencies)), DialogBuildError) {
  list.try_fold(overrides, windows, fn(windows, override) {
    let #(window_id, mode) = override
    use <- require(
      list.any(windows, fn(window) { window.id == window_id }),
      types.UnknownWindowReference(from: "with_window_show_mode", to: window_id),
    )
    Ok(
      list.map(windows, fn(window) {
        case window.id == window_id {
          True -> Window(..window, show_mode: Some(mode))
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
  decode: fn(Context(session, error, dependencies), String) -> state,
) -> Window(String, session, error, dependencies) {
  Window(
    id: window.id,
    render: fn(raw, ctx) { window.render(decode(ctx, raw), ctx) },
    on_action: fn(raw, event, ctx) {
      window.on_action(decode(ctx, raw), event, ctx)
      |> result.map(erase_action(_, encode))
    },
    on_text: option.map(window.on_text, fn(on_text) {
      fn(raw, text, ctx) {
        on_text(decode(ctx, raw), text, ctx)
        |> result.map(erase_action(_, encode))
      }
    }),
    on_message: option.map(window.on_message, fn(on_message) {
      fn(raw, input, ctx) {
        on_message(decode(ctx, raw), input, ctx)
        |> result.map(erase_action(_, encode))
      }
    }),
    widgets: list.map(window.widgets, erase_widget(_, encode, decode)),
    on_sub_result: dict.map_values(window.on_sub_result, fn(_sub_id, handler) {
      fn(raw, sub_raw, ctx) {
        handler(decode(ctx, raw), sub_raw, ctx)
        |> result.map(erase_action(_, encode))
      }
    }),
    show_mode: window.show_mode,
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
    types.Shown(mode:, action:) ->
      types.Shown(mode:, action: erase_action(action, encode))
  }
}

fn erase_widget(
  widget_item: types.KeyboardWidget(state, session, error, dependencies),
  encode: fn(state) -> String,
  decode: fn(Context(session, error, dependencies), String) -> state,
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
  decode: fn(Context(session, error, dependencies), String) -> state,
) -> types.WidgetCtx(state, session, error, dependencies) {
  types.WidgetCtx(
    state: decode(wctx.ctx, wctx.state),
    store: wctx.store,
    labels: wctx.labels,
    ctx: wctx.ctx,
  )
}

/// One sub attachment contributes itself plus every sub it attaches, each
/// re-keyed under this sub's namespace: `<sub>.<inner>`. Ids stay unique
/// however deep the tree goes, and the engine keeps looking subs up by the
/// same path `StartSub` carries.
fn namespaced_subs(
  sub: SubAttachment(session, error, dependencies),
) -> List(#(String, engine.CompiledSub(session, error, dependencies))) {
  let own = #(
    sub.id,
    engine.CompiledSub(
      id: sub.id,
      initial: namespaced_id(sub.id, sub.initial),
      init: sub.init,
    ),
  )

  let inner =
    list.map(sub.nested, fn(entry) {
      let #(key, compiled) = entry
      let key = namespaced_id(sub.id, key)
      #(
        key,
        engine.CompiledSub(
          id: key,
          // Already namespaced inside the sub, so this only adds our level.
          initial: namespaced_id(sub.id, compiled.initial),
          init: compiled.init,
        ),
      )
    })

  [own, ..inner]
}

fn namespaced_id(sub_id: String, window_id: String) -> String {
  sub_id <> engine.sub_separator <> window_id
}

/// Re-key an (already erased) sub-dialog window under the sub namespace and
/// map its navigation targets into it.
fn namespace_action(
  namespace: String,
  action: DialogAction(String),
) -> DialogAction(String) {
  case action {
    types.Goto(window_id:, state:) ->
      types.Goto(window_id: namespaced_id(namespace, window_id), state:)
    // A sub of a sub is addressed by the same path the compiled `subs` map
    // is keyed with, so `StartSub` moves into the namespace as well.
    types.StartSub(sub_id:, args:, state:) ->
      types.StartSub(sub_id: namespaced_id(namespace, sub_id), args:, state:)
    types.Shown(mode:, action:) ->
      types.Shown(mode:, action: namespace_action(namespace, action))
    other -> other
  }
}

fn namespace_window(
  namespace: String,
  window: Window(String, session, error, dependencies),
) -> Window(String, session, error, dependencies) {
  let map_action = namespace_action(namespace, _)
  Window(
    id: namespaced_id(namespace, window.id),
    render: window.render,
    on_action: fn(raw, event, ctx) {
      window.on_action(raw, event, ctx) |> result.map(map_action)
    },
    on_text: option.map(window.on_text, fn(on_text) {
      fn(raw, text, ctx) { on_text(raw, text, ctx) |> result.map(map_action) }
    }),
    on_message: option.map(window.on_message, fn(on_message) {
      fn(raw, input, ctx) {
        on_message(raw, input, ctx) |> result.map(map_action)
      }
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
          namespace,
          _,
        )),
      )
    }),
    // A nested sub is addressed by the path the compiled `subs` map is keyed
    // with, so the handler for it moves into the namespace as well.
    on_sub_result: window.on_sub_result
      |> dict.to_list
      |> list.map(fn(entry) {
        let #(sub_id, handler) = entry
        #(namespaced_id(namespace, sub_id), fn(raw, sub_raw, ctx) {
          handler(raw, sub_raw, ctx) |> result.map(map_action)
        })
      })
      |> dict.from_list,
    show_mode: window.show_mode,
  )
}

/// The dialog's own state encoder. `telega/testing/graph` uses it to probe
/// windows with sample states written in the user's own state type.
@internal
pub fn state_encoder(
  dialog: Dialog(state, session, error, dependencies),
) -> fn(state) -> String {
  dialog.encode_state
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
///
/// Dialogs are independent: the one this is called from stays open on its own
/// message, and the new one gets a message of its own. What the two share is
/// a **way back** — when `start` is called from inside another dialog's
/// handler, the new dialog remembers which dialog opened it, so its `on_done`
/// can hand control back with [`return_to_caller`](#return_to_caller):
///
/// ```gleam
/// // in the menu dialog's on_action
/// "settings" -> {
///   let _ = dialog.start(ctx, registry, "settings")
///   Ok(types.Stay(state))
/// }
///
/// // in the settings dialog
/// |> dialog.on_done(fn(_state, ctx) {
///   use #(ctx, _returned) <- result.map(dialog.return_to_caller(ctx, registry))
///   ctx
/// })
/// ```
///
/// The caller is recorded when the dialog is *started*; a `start` that only
/// resumes an already-open dialog leaves the way back it already had.
pub fn start(
  ctx ctx: Context(session, error, dependencies),
  registry registry: flow_registry.FlowRegistry(session, error, dependencies),
  dialog_id dialog_id: String,
) -> Result(Context(session, error, dependencies), error) {
  flow_registry.call_flow(
    ctx,
    registry,
    name: engine.flow_name_prefix <> dialog_id,
    initial: case calling_dialog(ctx) {
      Some(caller) -> dict.from_list([#(engine.caller_key, caller)])
      None -> dict.new()
    },
  )
}

/// The dialog whose handler is running right now, if any — the one that is
/// about to become the caller of whatever `start` opens.
fn calling_dialog(
  ctx: Context(session, error, dependencies),
) -> Option(String) {
  use flow_name <- option.then(bot.current_flow_step(ctx))
  case string.starts_with(flow_name, engine.flow_name_prefix) {
    True ->
      Some(string.drop_start(flow_name, string.length(engine.flow_name_prefix)))
    False -> None
  }
}

/// Which dialog opened the one being handled, if it was opened from another
/// dialog rather than from a command or a plain handler.
///
/// Readable from a window's handlers and from `on_done` — the answer belongs
/// to the update, so it survives the instance being deleted on the way out.
pub fn caller(
  ctx ctx: Context(session, error, dependencies),
) -> Option(String) {
  engine.stashed_caller(ctx)
}

/// Re-render the dialog that opened this one, if there is one and it is still
/// open. `False` comes back when nothing opened this dialog, or the caller
/// has since finished — either way nothing is started.
///
/// Put it at the end of `on_done` to give the user back the screen they came
/// from.
pub fn return_to_caller(
  ctx ctx: Context(session, error, dependencies),
  registry registry: flow_registry.FlowRegistry(session, error, dependencies),
) -> Result(#(Context(session, error, dependencies), Bool), error) {
  case caller(ctx) {
    None -> Ok(#(ctx, False))
    Some(caller) -> refresh(ctx, registry, caller)
  }
}

/// Re-render a user's **open** dialog without advancing it.
///
/// Unlike `start`, a user who has no live instance of this dialog is left
/// alone (`False` comes back) — a background refresh must not open a dialog
/// nobody asked for. Pair it with `telega.background_context` to update what
/// someone is looking at from a job that finished elsewhere:
///
/// ```gleam
/// let assert Ok(ctx) = telega.background_context(bot, chat_id:, user_id:)
/// let _ = dialog.refresh(ctx, registry, dialog_id: "export")
/// ```
///
/// The window's `render` runs again with the current state, so whatever it
/// reads — the session, an injected service, your own database — is re-read.
pub fn refresh(
  ctx ctx: Context(session, error, dependencies),
  registry registry: flow_registry.FlowRegistry(session, error, dependencies),
  dialog_id dialog_id: String,
) -> Result(#(Context(session, error, dependencies), Bool), error) {
  flow_registry.refresh_flow(
    ctx,
    registry,
    name: engine.flow_name_prefix <> dialog_id,
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
  // The ctx-aware variant runs the flow's exit hook, which takes the old
  // message's keyboard down before the fresh one is sent.
  let ctx = case
    flow_registry.cancel_flow_instance_for(
      registry:,
      ctx:,
      flow_id: instance_id,
    )
  {
    Ok(#(ctx, _)) -> ctx
    Error(_) -> ctx
  }
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
