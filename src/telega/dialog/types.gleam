//// Shared type definitions for the declarative dialog system.
////
//// A dialog is a set of windows; a window is a pure render function plus
//// event handlers. See `telega/dialog` for the builder API and the full
//// guide.

import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result

import telega/bot.{type Context}
import telega/format.{type FormattedText}

/// The visible result of rendering a window: message text, an inline
/// keyboard, and an optional media attachment. The engine turns it into the
/// right `send*`/`edit*` calls (see `telega/dialog/render`) and builds
/// callback data for the buttons itself. For media windows the text becomes
/// the caption.
pub type RenderedWindow {
  RenderedWindow(
    text: FormattedText,
    buttons: List(List(DialogButton)),
    media: Option(DialogMedia),
  )
}

/// Media attached to a window. `media` is a **file_id or URL** — uploading
/// local files via `attach://` is not supported in dialogs yet (the string
/// will widen to `FileOrString` without breakage when it is).
pub type DialogMedia {
  PhotoMedia(media: String, has_spoiler: Bool)
  VideoMedia(media: String, has_spoiler: Bool)
  AnimationMedia(media: String)
  DocumentMedia(media: String)
}

pub type DialogButton {
  /// Action button: the engine builds callback data (`dlg:<dialog>:<window>:<action>`).
  ActionButton(text: String, action_id: String)
  /// Action with an argument (e.g. the id of a list item):
  /// `dlg:<dialog>:<window>:<action>:<arg>`.
  ActionArgButton(text: String, action_id: String, arg: String)
  UrlButton(text: String, url: String)
  WebAppButton(text: String, url: String)
  /// Non-clickable button (header/counter): rendered as a copy-text button
  /// that copies its own label.
  NoopButton(text: String)
}

/// What a window handler decides to do next. `state` is always explicit:
/// handlers are pure functions from the old state to an action carrying the
/// new state.
pub type DialogAction(state) {
  /// Re-render the current window with the new state.
  Stay(state)
  /// Go to another window (pushed to history — `Back` returns here).
  Goto(window_id: String, state: state)
  /// One step back in the navigation stack.
  Back(state)
  /// Finish the dialog (runs `on_done`, removes the keyboard).
  Done(state)
  /// Start a sub-dialog attached with `dialog.subdialog`. The sub takes over
  /// the live message; its `Done` returns control to the current window's
  /// `on_sub_result` (see `telega/dialog` § sub-dialogs). `args` are handed
  /// to the sub-dialog's `init`. One level of nesting only: `StartSub` from
  /// inside a sub-dialog is rejected at runtime (logged, window re-rendered).
  StartSub(sub_id: String, args: Dict(String, String), state: state)
}

/// A parsed button press delivered to `on_action`.
pub type ActionEvent {
  ActionEvent(action_id: String, arg: Option(String))
}

/// A single dialog window: a pure render function plus event handlers.
///
/// - `render` must be pure — its only "effect" is reading `ctx` (e.g. for
///   i18n). This is what makes windows snapshot-testable without a network.
/// - `on_action` receives an already-parsed `ActionEvent`, not a raw string.
/// - `on_text: None` means text sent to this window is politely ignored:
///   the engine just re-renders the window.
/// - `widgets` are managed keyboard widgets (see `telega/dialog/widget`):
///   the engine appends their button rows after `render`'s own buttons and
///   routes their events to `KeyboardWidget.on_event`, bypassing `on_action`.
/// - `on_sub_result` runs when a sub-dialog started from this window (via
///   `StartSub`) finishes: it receives the window's state and the result
///   dict exported by the `subdialog` attachment, and decides where to go
///   next (`Stay` re-renders this window). `None` just re-renders.
pub type Window(state, session, error, dependencies) {
  Window(
    id: String,
    render: fn(state, Context(session, error, dependencies)) -> RenderedWindow,
    on_action: fn(state, ActionEvent, Context(session, error, dependencies)) ->
      Result(DialogAction(state), error),
    on_text: Option(
      fn(state, String, Context(session, error, dependencies)) ->
        Result(DialogAction(state), error),
    ),
    widgets: List(KeyboardWidget(state, session, error, dependencies)),
    on_sub_result: Option(
      fn(state, Dict(String, String), Context(session, error, dependencies)) ->
        Result(DialogAction(state), error),
    ),
  )
}

// Widgets ------------------------------------------------------------------------

/// A managed keyboard widget: renders extra button rows for a window and
/// handles their events itself. Widget buttons use action ids of the form
/// `w:<widget_id>:<cmd>` (the `w:` action-id namespace is reserved for
/// widgets), so the engine can route presses to `on_event` without touching
/// the window's `on_action`.
///
/// Built-in widgets live in `telega/dialog/widget` (pager, select, radio,
/// multiselect, paged_select). Custom widgets construct this record directly:
///
/// - `goto_targets` — window ids the widget may `Emit(Goto(...))` to;
///   validated by `dialog.build()`.
/// - `static_actions` — the widget's full static action ids
///   (`w:<widget_id>:<cmd>`) for the build-time callback-data byte budget;
///   argument-carrying buttons are additionally validated on every render.
pub type KeyboardWidget(state, session, error, dependencies) {
  KeyboardWidget(
    id: String,
    render: fn(WidgetCtx(state, session, error, dependencies)) ->
      List(List(DialogButton)),
    on_event: fn(
      WidgetCtx(state, session, error, dependencies),
      String,
      Option(String),
    ) -> Result(WidgetResult(state), error),
    goto_targets: List(String),
    static_actions: List(String),
  )
}

/// Everything a widget sees when rendering or handling an event: the window's
/// user state, the widget's own persistent store, the dialog labels, and the
/// update context.
pub type WidgetCtx(state, session, error, dependencies) {
  WidgetCtx(
    state: state,
    store: WidgetStore,
    labels: Labels,
    ctx: Context(session, error, dependencies),
  )
}

/// What a widget decides after handling one of its events.
pub type WidgetResult(state) {
  /// Update the widget store; the window is re-rendered in place.
  StoreUpdated(WidgetStore)
  /// Delegate a dialog action outward — e.g. `Goto` on a "done" press. To
  /// update the store and the state together, emit `Stay(new_state)` after a
  /// `StoreUpdated` round-trip or fold the value into the state itself.
  Emit(DialogAction(state))
}

/// A widget's private key-value store. Persisted with the dialog instance
/// under `__dialog_widget:<window_id>:<widget_id>`, so widget state survives
/// restarts together with the rest of the dialog.
pub opaque type WidgetStore {
  WidgetStore(entries: Dict(String, String))
}

pub fn new_store() -> WidgetStore {
  WidgetStore(entries: dict.new())
}

pub fn store_get(store store: WidgetStore, key key: String) -> Option(String) {
  dict.get(store.entries, key) |> option.from_result
}

pub fn store_set(
  store store: WidgetStore,
  key key: String,
  value value: String,
) -> WidgetStore {
  WidgetStore(entries: dict.insert(store.entries, key, value))
}

/// Serialize a store for persistence in `FlowInstance.state.data` (a JSON
/// object of strings).
@internal
pub fn encode_store(store: WidgetStore) -> String {
  store.entries
  |> dict.to_list
  |> list.map(fn(entry) { #(entry.0, json.string(entry.1)) })
  |> json.object
  |> json.to_string
}

@internal
pub fn decode_store(raw: String) -> Result(WidgetStore, Nil) {
  json.parse(raw, decode.dict(decode.string, decode.string))
  |> result.map(WidgetStore)
  |> result.replace_error(Nil)
}

/// User-facing labels for engine-generated UI. All strings are resolved via
/// a `fn(Context) -> Labels` factory so `telega_i18n` works out of the box.
/// Defaults are wordless unicode symbols to stay locale-neutral.
pub type Labels {
  Labels(
    prev: String,
    next: String,
    page_info: String,
    checked: String,
    unchecked: String,
    checkbox_on: String,
    checkbox_off: String,
    done: String,
    /// `answer_callback_query` text shown when the user presses a button on
    /// an outdated dialog message.
    stale: String,
  )
}

pub fn default_labels() -> Labels {
  Labels(
    prev: "‹",
    next: "›",
    page_info: "{current}/{total}",
    checked: "● ",
    unchecked: "○ ",
    checkbox_on: "☑ ",
    checkbox_off: "☐ ",
    done: "✓",
    stale: "⏳",
  )
}

/// Validation errors returned by `dialog.build()`.
pub type DialogBuildError {
  DuplicateWindowId(id: String)
  /// A `Goto`/widget `done`/`on_sub_result` target references a window that
  /// doesn't exist.
  UnknownWindowReference(from: String, to: String)
  /// The static part of a button's callback data exceeds Telegram's 64-byte
  /// limit. Use shorter dialog/window/action ids. For sub-dialog windows the
  /// budget includes the `<sub_id>.` step prefix.
  CallbackDataTooLong(window: String, action: String, bytes: Int)
  NoWindows
  UnknownInitialWindow(id: String)
  DuplicateWidgetId(window: String, id: String)
  /// `:` is the callback-data separator and is forbidden in dialog, window,
  /// action, and widget ids; `.` namespaces sub-dialog windows and is
  /// additionally forbidden in dialog and window ids.
  ReservedIdCharacter(kind: String, id: String)
  DuplicateSubDialogId(id: String)
  /// The attached sub-dialog has sub-dialogs of its own — nesting is one
  /// level deep.
  NestedSubDialog(id: String)
}
