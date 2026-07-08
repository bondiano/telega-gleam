# Dialogs

Dialogs are declarative, single-message UIs for multi-step interactions (an
[aiogram-dialog](https://github.com/Tishka17/aiogram_dialog) analog). A dialog
is a set of **windows**; a window is a pure render function plus event
handlers. The engine keeps **one live message** and edits it on every
transition, builds and parses button callback data itself, provides `Back`
navigation, managed keyboard widgets, sub-dialogs, and persistence through any
flow storage backend.

```
┌─────────────────────────────┐
│ Settings                    │   one Telegram message,
│ lang: en, name: Alice       │   edited in place on every
├─────────────────────────────┤   button press / text input
│ [ EN ] [ RU ]               │
│ [ Name ]                    │
│ [ Done ]                    │
└─────────────────────────────┘
```

## When to Use Dialogs

Use a dialog when the interaction is **one message with buttons that morphs
in place**: settings panels, booking wizards, browsable catalogs,
confirmation screens.

### Dialogs vs Conversations vs Flows vs Menu Builder

Dialogs compile to [flows](./conversation-flows.md), so they inherit
persistence, TTL, and `/cancel` — the difference is the level of abstraction:

| | [Conversations](./conversation.md) | [Flows](./conversation-flows.md) | Menu Builder | Dialogs |
|---|---|---|---|---|
| **UI model** | bot sends messages | you send/edit manually | one menu message | one live message, auto edit-or-send |
| **Persistence** | in-memory | storage backend | in-memory | storage backend (via flow) |
| **Callback data** | manual | manual | generated | generated + validated (64 bytes) |
| **Back navigation** | no | manual (`Back` action) | built-in | built-in |
| **Media** | manual | manual | no | text ↔ media transitions handled |
| **Reusable selects/pagination** | no | no | pagination | widgets (pager, radio, multiselect, …) |
| **Composition** | nested calls | subflows | nested menus | sub-dialogs |
| **Best for** | quick Q&A forms | branchy processes with custom messages | standalone menus outside a process | screen-like UIs: settings, wizards, catalogs |

Menu builder remains a good fit for a single menu that is not part of a
persistent process. If you are hand-writing `editMessageText` calls and
parsing callback payloads inside a flow — that is the sign to switch to a
dialog.

## Terminology

| Term | Description |
|------|-------------|
| **Dialog** | A set of windows compiled into one flow; one live instance per `(dialog, chat, user)` |
| **Window** | A screen: pure `render(state, ctx) -> RenderedWindow` + event handlers |
| **State** | Your own type, serialized with a codec you provide; persisted with the instance |
| **Action** | What a handler returns: `Stay`, `Goto`, `Back`, `Done`, `StartSub` |
| **Widget** | A managed keyboard fragment (pager, radio, …) with its own persisted store |
| **Sub-dialog** | A reusable dialog started from a window, sharing the live message |

## Quick Start

```gleam
import gleam/option.{None, Some}
import telega/dialog
import telega/dialog/types.{ActionButton, RenderedWindow}
import telega/flow/registry as flow_registry
import telega/flow/storage as flow_storage
import telega/format

pub type Settings {
  Settings(lang: String, name: String)
}

fn render_menu(settings: Settings, _ctx) -> RenderedWindow {
  RenderedWindow(
    text: format.build()
      |> format.bold_text("Settings")
      |> format.line_break()
      |> format.text("lang: " <> settings.lang <> ", name: " <> settings.name)
      |> format.to_formatted(),
    buttons: [
      [ActionButton("Name", "name")],
      [ActionButton("Done", "done")],
    ],
    media: None,
  )
}

fn handle_menu(settings, event: types.ActionEvent, _ctx) {
  case event.action_id {
    "name" -> Ok(types.Goto("name", settings))
    "done" -> Ok(types.Done(settings))
    _ -> Ok(types.Stay(settings))
  }
}

fn render_name(_settings, _ctx) -> RenderedWindow {
  RenderedWindow(
    text: format.build()
      |> format.text("What's your name?")
      |> format.to_formatted(),
    buttons: [[ActionButton("‹ Back", "back")]],
    media: None,
  )
}

pub fn create_settings_dialog(storage) {
  let assert Ok(settings) =
    dialog.new(
      id: "settings",
      storage:,
      initial_state: fn() { Settings(lang: "en", name: "") },
      encode_state: encode_settings,
      decode_state: decode_settings,
    )
    |> dialog.window(id: "menu", render: render_menu, on_action: handle_menu)
    |> dialog.window_with_input(
      id: "name",
      render: render_name,
      on_action: fn(settings, event, _ctx) {
        case event.action_id {
          "back" -> Ok(types.Back(settings))
          _ -> Ok(types.Stay(settings))
        }
      },
      on_text: fn(settings, text, _ctx) {
        Ok(types.Goto("menu", Settings(..settings, name: text)))
      },
    )
    |> dialog.initial("menu")
    |> dialog.on_done(fn(settings, ctx) { save_settings(settings, ctx) })
    |> dialog.build()
  settings
}
```

Wire it up through a flow registry:

```gleam
let registry =
  flow_registry.new_registry()
  |> dialog.attach_on_command("settings", settings_dialog)
  |> flow_registry.register_cancel_command("cancel")

let router = flow_registry.apply_to_router(router, registry)
```

That is the whole loop: `/settings` sends the menu; every press edits the
same message; `Done` runs `on_done` and removes the keyboard. `build()`
returns `Result` — window ids are validated up front (duplicates, unknown
`initial`, reserved characters, callback-data budget).

## State and Codecs

The dialog state is your own type. It is persisted (as a string) in the flow
instance, so provide a codec at `dialog.new`:

- `dialog.string_codec()` — for a plain `String` state.
- `dialog.json_codec(encoder, decoder)` — for records, via `gleam/json` +
  `gleam/dynamic/decode` (same pattern as
  [session serialization](./session-serialization.md)).

Handlers are pure functions from the old state to an action carrying the new
state — there is no hidden mutation:

```gleam
"lang" -> Ok(types.Stay(Settings(..settings, lang: "ru")))
```

If a persisted state fails to decode after a deploy that changed its shape,
the dialog logs a warning and falls back to `initial_state()` instead of
crashing.

## Windows and Actions

`render` must be pure — its only "effect" is reading `ctx` (e.g. for i18n).
This is what makes windows snapshot-testable without a network (§ Testing).

A handler returns a `DialogAction`:

| Action | Effect |
|---|---|
| `Stay(state)` | save state, re-render the current window (edit in place) |
| `Goto(window_id, state)` | save state, go to the window; pushed to history |
| `Back(state)` | save state, one step back in the history |
| `Done(state)` | save state, run `on_done`, remove the keyboard, delete the instance |
| `StartSub(sub_id, args, state)` | start a sub-dialog (§ Sub-dialogs) |

Buttons in `RenderedWindow.buttons`:

- `ActionButton(text, action_id)` → callback data `dlg:<dialog>:<window>:<action>`
- `ActionArgButton(text, action_id, arg)` → `…:<action>:<arg>` (e.g. a list item id)
- `UrlButton`, `WebAppButton` — pass-through
- `NoopButton(text)` — non-clickable (header/counter), rendered as a
  copy-text button

`on_action` receives an already-parsed `ActionEvent(action_id, arg)`, never a
raw payload string.

### Text input

A window added with `window_with_input` also accepts text (`on_text`).
Windows without `on_text` swallow text politely: the message is consumed and
the window re-rendered, so the user always sees the current screen. The
dialog is **modal to text but not to commands** — commands still reach the
router, so always register a cancel command
(`flow_registry.register_cancel_command`).

Validation errors belong in the state, not in ad-hoc extra messages:

```gleam
fn handle_date_text(state, text, _ctx) {
  case validate_date(text) {
    Ok(Nil) -> Ok(types.Goto("time", State(..state, date: text, error: None)))
    Error(key) -> Ok(types.Stay(State(..state, error: Some(key))))
  }
}
```

## Media Windows

Set `RenderedWindow.media` to attach a photo/video/animation/document; the
window text becomes the caption. `media` is a **file_id or URL** (no
`attach://` uploads yet).

The Bot API cannot edit a text message into a media one (or back), so the
engine tracks the live message kind and picks a strategy:

| was \ becomes | text | media |
|---|---|---|
| — (no message) | `sendMessage` | `sendPhoto`/`sendVideo`/… |
| text | `editMessageText` | delete (best effort) + send |
| media (any kind) | delete (best effort) + send | `editMessageMedia` |

`deleteMessage` is best effort (messages older than 48 hours cannot be
deleted): the failure is swallowed and the fresh message is sent anyway.
Media → media of a different kind is a single `editMessageMedia` — it swaps
the file, the media type, and the caption at once.

## Widgets

Widgets are managed keyboard fragments from `telega/dialog/widget`: the
engine renders their button rows after the window's own buttons, handles
their callbacks itself (bypassing `on_action`), and persists their state with
the dialog instance — selections and page positions survive restarts.

```gleam
import telega/dialog/widget.{SelectItem}

|> dialog.window_with_widgets(
  id: "prefs",
  render: render_prefs,             // just the prompt + your own buttons
  on_action: handle_prefs,
  widgets: [
    widget.radio(id: "zone", items: zone_items, default: Some("hall")),
    widget.multiselect(id: "extras", items: extra_items,
      min: 0, max: 3, done: "confirm"),
  ],
)
```

Built-ins:

| Widget | Behavior | Read the value with |
|---|---|---|
| `pager(id:, page_size:, total:)` | `‹ 2/5 ›` row; hidden when one page | `widget.current_page` |
| `select(id:, items:, columns:, on_selected:)` | one-shot choice grid; a press calls `on_selected` | — (nothing stored) |
| `radio(id:, items:, default:)` | single choice, `●`/`○` marks | `widget.radio_value` |
| `multiselect(id:, items:, min:, max:, done:)` | checkboxes; the done button shows only within `min`/`max` and emits `Goto(done, state)` | `widget.multiselect_values` |
| `paged_select(id:, items:, page_size:, columns:, on_selected:)` | select + pager in one | `widget.current_page` |

`SelectItem(id:, label:)` ids travel in callback data — keep them short (the
64-byte limit is validated on every render).

Widget state lives in a per-widget store, persisted under the dialog
instance. Read it from any render or handler:

```gleam
let zone =
  dialog.widget_store(ctx, window_id: "prefs", widget_id: "zone")
  |> widget.radio_value
  |> option.unwrap("hall")
```

Note that `radio`'s `default` is only a visual pre-selection — `radio_value`
stays `None` until the user actually picks, so apply the same default when
reading.

Custom widgets construct `types.KeyboardWidget` directly: `render` returns
button rows, `on_event` handles `w:<widget_id>:<cmd>` presses and returns
`StoreUpdated` (re-render in place) or `Emit(action)` (delegate outward).
Declare `goto_targets` and `static_actions` so `build()` can validate window
references and the callback-data budget.

## Sub-dialogs

A sub-dialog is a **reusable dialog attached to a parent** — its state type
may differ. It takes over the same live message; when it finishes, the
parent window that started it receives the result.

```gleam
// A reusable address dialog with its own state.
pub type AddressState {
  AddressState(city: String, street: String)
}

pub fn create_address_dialog(storage) -> dialog.Dialog(AddressState, s, e, d) {
  // ...windows "city" and "street"; the last one returns Done(state)
}

// Attach to the parent and handle the result:
|> dialog.subdialog(
  sub: create_address_dialog(storage),
  init: fn(_parent_state, _args) { AddressState(city: "", street: "") },
  result: fn(address) {
    dict.from_list([
      #("address.city", address.city),
      #("address.street", address.street),
    ])
  },
)
|> dialog.on_sub_result(window: "confirm", handler: fn(state, result, _ctx) {
  let address = case dict.get(result, "address.city"), dict.get(result, "address.street") {
    Ok(city), Ok(street) -> Some(city <> ", " <> street)
    _, _ -> None
  }
  Ok(types.Stay(BookingState(..state, address:)))
})
```

Start it from any window handler:

```gleam
"address" -> Ok(types.StartSub("delivery_address", dict.new(), state))
```

Semantics:

- `init(parent_state, args)` builds the sub's starting state (`args` come
  from `StartSub` — use them to pass parameters).
- The sub edits the **same live message**; message id/kind, waits, TTL and
  persistence are shared with the parent. A half-entered sub survives
  restarts like everything else.
- The sub's `Done(sub_state)` → `result(sub_state)` dict → the starting
  window's `on_sub_result` (default: just re-render that window). Prefix the
  result keys with the sub id by convention (`"address.city"`) to keep them
  collision-free.
- `Back` on the sub's **first** window cancels the sub: the parent window is
  re-rendered, `on_sub_result` is **not** called.
- A sub cannot `Goto` parent windows (its navigation is namespaced), and the
  sub's own `storage`/`ttl`/`labels`/`on_done` are ignored while attached.
- Nesting is **one level**: attaching a dialog that itself has sub-dialogs
  fails at `build()` (`NestedSubDialog`); a `StartSub` from inside a sub is
  rejected at runtime (logged, window re-rendered). Chaining is fine:
  `on_sub_result` may return another `StartSub`.

## i18n

`render` receives the update's `Context`, so
[`telega_i18n`](../telega_i18n) works out of the box — translate inside the
render exactly like in any handler:

```gleam
fn render_confirm(state, ctx) {
  RenderedWindow(
    text: format.build()
      |> format.text(i18n.t(ctx, "book.confirm", [#("date", state.date)]))
      |> format.to_formatted(),
    ...
  )
}
```

Engine-generated texts — the multiselect **Done** button, pager arrows,
check marks, and the "this menu is outdated" callback answer — come from
`Labels`. Localize them with `with_labels`; the factory receives the
`Context`, so the i18n middleware's per-update locale applies:

```gleam
fn dialog_labels(ctx) -> types.Labels {
  let defaults = types.default_labels()
  types.Labels(
    ..defaults,
    done: i18n.t(ctx, "book.prefs_done", []),   // "✅ Done" / "✅ Готово"
    stale: i18n.t(ctx, "common.stale", []),     // "⏳ This menu is outdated"
  )
}

|> dialog.with_labels(dialog_labels)
```

The defaults are wordless unicode symbols (`‹`, `›`, `●`, `☑`, `✓`, `⏳`), so
an unlocalized dialog never shows English words to non-English users.

## Callback Data, Limits, Reserved Characters

Callback data follows the `dlg:<dialog>:<window>:<action>[:<arg>]` scheme
(widget events use the `w:<widget_id>:<cmd>` action namespace). Telegram
limits callback data to **64 bytes**:

- `build()` validates every static prefix and widget action, including the
  `<sub_id>.<window_id>` namespace of sub-dialog windows;
- dynamic parts (`ActionArgButton` args, select item ids) are validated on
  every render — a violation is logged as a render error and the dialog
  keeps waiting (a misconfiguration must be visible, not silently degraded).

Keep dialog/window/action ids short; use short keys or indices for list
items, not raw titles. Two characters are reserved: `:` (the scheme
separator, forbidden in all ids) and `.` (the sub-dialog namespace,
forbidden in dialog and window ids).

### Stale buttons

Presses on outdated messages are guarded twice: the `window_id` in the
payload catches presses on old windows, and the pressed message's id is
compared against the tracked live message — a press on an old *copy* of the
live window (left behind by a recreate fallback or `restart`) is caught too.
Both answer the callback with `labels.stale` and do nothing.

Presses on messages of an already **finished** dialog are handled by a
fallback that `attach`/`attach_on_command` register automatically: the
callback is answered with `labels.stale` instead of hanging. No hand-written
router fallback is needed.

### Several flows waiting at once

`attach` also restricts the dialog's auto-resume to its own `dlg:<id>:`
payloads, so a dialog and another waiting flow (or two dialogs) can coexist:
a press on the other flow's keyboard is not swallowed by the dialog. Plain
hand-written flows can opt into the same behavior with
`flow_registry.with_callback_filter`.

## Errors and Robustness

- **User handler errors** (an `Error(e)` from `on_action`/`on_text`/…) are
  logged, emit `["telega", "dialog", "error"]` telemetry, and re-render the
  current window — the dialog never dies silently.
- **Render/API errors** (network, over-budget buttons) are logged loudly and
  the instance keeps waiting, so the user can retry.
- **Edit fallbacks**: "message is not modified" is treated as success;
  "message to edit not found" / "message can't be edited" fall back to a
  fresh send. The classifiers live in `telega/error`
  (`error.is_message_not_modified` & co, aliased in `telega/dialog/render`)
  and are useful outside dialogs.
- **Webhook reply**: under `handle_bot_with_reply` the dialog's own sends opt
  out of webhook-reply claiming (`webhook_reply.without_claim`) — the engine
  needs the real message id to edit the live message later, and a claimed
  `sendMessage` would yield a fake stub id.
- `alert(ctx, text)` / `toast(ctx, text)` show a modal alert or a toast from
  inside `on_action`; the engine then skips its automatic spinner-removing
  callback answer for that event.

## Lifecycle

- **One live instance** per `(dialog, chat, user)`: a repeated start command
  *resumes* (re-renders) the current dialog. `dialog.restart(ctx, registry,
  id)` is the hard reset (delete + start).
- `dialog.attach(registry, dialog)` registers without a trigger — start
  programmatically with `dialog.start(ctx, registry, dialog_id)` (e.g. after
  a permissions check). `dialog.attach_on_command("book", dialog)` binds a
  command.
- `dialog.with_ttl(ms:)` expires an abandoned dialog (lazy check on the next
  event), inherited from the flow engine.
- `/cancel` is the flow registry's cancel command — register it; the dialog
  is modal to text, so it is the user's escape hatch.

## Testing

Dialogs are designed for snapshot testing with the pure canonicalizers from
`telega/testing/render` (see [testing.md](./testing.md) § Snapshot Testing).
Three levels:

**Level 1 — pure window frames.** `render(state, ctx)` has no effects, so
frame every meaningful state without a network:

```gleam
render_confirm(filled_state(), ctx)
|> testing_render.window_frame
|> birdie.snap(title: "booking:confirm:frame_en")
```

For windows that read widget stores, seed them first with
`widget.seed_store(window_id:, widget_id:, store:)`.

**Per-locale frames**: pin the same frame once per locale — with
`telega_i18n` set the locale around the render:

```gleam
telega_i18n.enter(catalog:, locale: "ru")
render.window_frame(booking.render_confirm(state, ctx))
|> birdie.snap(title: "booking:confirm:frame_ru")
telega_i18n.leave()
```

**Level 2 — engine transcripts.** Drive the compiled flow with a mock client
and snapshot the full visible API-call sequence (`sendMessage`,
`editMessageText`, `answerCallbackQuery`, …):

```gleam
let flow = dialog_engine.compile(dialog.compiled(my_dialog))
// start, press buttons, send texts against a mock client...
mock.get_calls(calls)
|> testing_render.calls_transcript
|> birdie.snap(title: "dialog:engine:happy_path")
```

**Level 3 — error-path regressions.** Script Telegram's answers with
`mock.stateful_client`/`mock.routed_client` (400 "message is not modified",
"message to edit not found", …) and snapshot the recovery.

`test/telega/dialog_test.gleam`, `dialog_widget_test.gleam`,
`dialog_sub_test.gleam` in the repository and
`examples/06-restaurant-booking/test/booking_dialog_test.gleam` are working
references for all of the above.

## Telemetry

Dialogs emit `["telega", "dialog", <event>]` with `dialog_id`/`window_id`
metadata: `render` (with `duration`), `action` (with `action_id`),
`render_error`, `error`, `sub_start`, `sub_done`, `sub_cancel` — on top of
the flow-level `["telega", "flow", ...]` events (`flow_name` is
`"__dialog:" <> id`). See `telega/telemetry` for the handler API.

## Example

[`examples/06-restaurant-booking`](../examples/06-restaurant-booking) uses
every feature on this page: text-input windows with in-state validation, a
`paged_select`/`select`/`radio`/`multiselect` keyboard, a media window
(text ↔ photo transitions), a reusable address sub-dialog, localized labels
via `telega_i18n`, SQLite persistence, and per-locale snapshot tests.
