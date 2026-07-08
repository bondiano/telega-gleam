//// Compiles a `Dialog` into a `Flow(String, ...)` and dispatches events.
////
//// Each window becomes a flow step (step type = the window id). The step
//// handler runs the render → wait → dispatch cycle:
////
//// - `Pending` — render the window (edit-or-send) and park on `Wait`
//// - `DataCallback` — parse the `dlg:` scheme, guard against stale/foreign
////   messages, run `window.on_action`, auto-answer the callback query
//// - `TextInput` — run `window.on_text` if set, otherwise re-render
////
//// The engine is **type-erased**: `telega/dialog.build()` wraps every
//// user-typed window into a `Window(String, ...)` whose closures carry the
//// dialog's own state codec, so the engine only ever moves the encoded state
//// string around. This is what lets a sub-dialog with a different state type
//// live inside its parent's flow.
////
//// ## Sub-dialogs
////
//// Sub-dialogs deliberately do NOT use the flow engine's
//// `EnterSubflow`/`FlowStackFrame` machinery: that path never re-executes
//// the parent step after the sub-flow returns (and sets no wait token, so
//// auto-resume cannot wake it), resumes sub-flow steps against the parent's
//// step registry, and loses the parent's history. Instead the sub-dialog's
//// windows are compiled into the parent flow as `<sub_id>.<window_id>` steps
//// and the engine keeps its own return bookkeeping in instance data:
////
//// | key | content |
//// |---|---|
//// | `__dialog_sub` | active sub-dialog id (absent at top level) |
//// | `__dialog_return_window` | parent window that emitted `StartSub` |
//// | `__dialog_sub_saved` | parent's encoded state while the sub runs |
////
//// The live message, its kind, waits, TTL and persistence are shared with
//// the parent for free (same instance). A `Back` that would cross the sub
//// boundary cancels the sub and returns to the parent window without calling
//// `on_sub_result`.
////
//// Navigation deliberately never uses the flow `GoTo` action — it erases
//// history, which would break `Back`. Only `Next`/`NextString`/`Back` are
//// emitted, plus the history-preserving `Jump` for sub-dialog enter/return
//// (which must not push sub steps onto the parent history).

import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

import logging

import telega/bot.{type Context}
import telega/dialog/render
import telega/dialog/types.{
  type ActionEvent, type DialogAction, type Labels, type Window, ActionEvent,
}
import telega/dialog/widget
import telega/flow/builder as flow_builder
import telega/flow/instance
import telega/flow/types as flow_types
import telega/model/types as model_types
import telega/telemetry
import telega/update

/// Flow names are prefixed so dialogs never collide with hand-written flows
/// in the same registry.
pub const flow_name_prefix = "__dialog:"

/// Separator between a sub-dialog id and its window ids in step names and
/// callback data (`address.city`). Forbidden in dialog/window/sub ids.
pub const sub_separator = "."

const state_key = "__dialog_state"

const message_id_key = "__dialog_message_id"

const message_kind_key = "__dialog_message_kind"

const sub_key = "__dialog_sub"

const return_window_key = "__dialog_return_window"

const sub_saved_key = "__dialog_sub_saved"

/// Everything the engine needs to know about a dialog, with all window
/// handlers erased to the encoded-state form. Built by
/// `telega/dialog.build()`; not constructed by hand.
pub type CompiledDialog(session, error, dependencies) {
  CompiledDialog(
    id: String,
    /// Parent windows plus every attached sub-dialog's windows under
    /// namespaced ids (`<sub_id>.<window_id>`).
    windows: Dict(String, Window(String, session, error, dependencies)),
    initial: String,
    initial_encoded: fn() -> String,
    on_done: Option(
      fn(String, Context(session, error, dependencies)) ->
        Result(Context(session, error, dependencies), error),
    ),
    subs: Dict(String, CompiledSub),
    storage: flow_types.FlowStorage(error),
    ttl_ms: Option(Int),
    labels: fn(Context(session, error, dependencies)) -> Labels,
  )
}

/// A sub-dialog attachment: how to build its starting state and how to turn
/// its final state into the result dict for `on_sub_result`.
pub type CompiledSub {
  CompiledSub(
    id: String,
    /// Namespaced id of the sub-dialog's initial window.
    initial: String,
    /// `fn(parent_encoded_state, args) -> sub_encoded_state`
    init: fn(String, Dict(String, String)) -> String,
    /// `fn(sub_encoded_state) -> result dict`
    result: fn(String) -> Dict(String, String),
  )
}

/// Compile a dialog into a flow. Window id = step name (identity
/// converters), `on_error` is always set (the flow engine silently swallows
/// errors otherwise): it logs, emits telemetry, and re-renders the current
/// window best-effort.
pub fn compile(
  dialog: CompiledDialog(session, error, dependencies),
) -> flow_types.Flow(String, session, error, dependencies) {
  let flow_name = flow_name_prefix <> dialog.id

  let builder =
    flow_builder.new(flow_name, dialog.storage, fn(step) { step }, fn(step) {
      Ok(step)
    })

  let builder =
    dict.fold(dialog.windows, builder, fn(builder, window_id, window) {
      flow_builder.add_step(builder, window_id, window_step(dialog, window))
    })

  let builder =
    flow_builder.on_complete(builder, fn(ctx, inst) {
      // `on_done` may still read widget selections; clear the stash after so
      // later non-dialog handlers don't see the finished dialog's stores.
      widget.stash_stores(inst.state.data)
      let result = case dialog.on_done {
        Some(on_done) -> on_done(load_state(dialog, inst), ctx)
        None -> Ok(ctx)
      }
      widget.clear_stash()
      result
    })

  let builder =
    flow_builder.on_error(builder, fn(ctx, inst, maybe_error) {
      log_dialog_error(dialog, inst, maybe_error)
      let _ = try_render_current(dialog, ctx, inst)
      Ok(ctx)
    })

  let builder = case dialog.ttl_ms {
    Some(ms) -> flow_builder.with_ttl(builder, ms:)
    None -> builder
  }

  flow_builder.build(builder, initial: dialog.initial)
}

// Step handler ------------------------------------------------------------------

fn window_step(
  dialog: CompiledDialog(session, error, dependencies),
  window: Window(String, session, error, dependencies),
) -> flow_types.StepHandler(String, session, error, dependencies) {
  fn(ctx, inst: flow_types.FlowInstance) {
    // Make widget stores readable from user renders/handlers via
    // `dialog.widget_store` — the chat instance is a single process.
    widget.stash_stores(inst.state.data)
    case instance.get_wait_result(inst) {
      flow_types.Pending -> render_and_wait(dialog, window, ctx, inst)
      flow_types.DataCallback(value:) ->
        handle_callback(dialog, window, ctx, inst, value)
      flow_types.TextInput(value:) ->
        handle_text(dialog, window, ctx, inst, value)
      // A leftover bool-format button (`<id>:true`) still arrives as a
      // callback query: remove the client spinner before ignoring it.
      flow_types.BoolCallback(..) -> {
        render.answer_quietly(ctx, None)
        wait(ctx, inst)
      }
      // Commands, media and everything else are not dialog events: keep
      // waiting. Cancel commands are handled by the flow registry before the
      // instance is resumed.
      _ -> wait(ctx, inst)
    }
  }
}

fn render_and_wait(
  dialog: CompiledDialog(session, error, dependencies),
  window: Window(String, session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
) -> flow_types.StepResult(String, session, error, dependencies) {
  render_and_park(dialog, window, ctx, inst, load_state(dialog, inst))
}

fn handle_callback(
  dialog: CompiledDialog(session, error, dependencies),
  window: Window(String, session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  data: String,
) -> flow_types.StepResult(String, session, error, dependencies) {
  case parse_callback_data(data) {
    // Foreign or malformed payload: silently remove the spinner and keep
    // waiting — some other route owns this button.
    Error(Nil) -> {
      render.answer_quietly(ctx, None)
      wait(ctx, inst)
    }
    Ok(#(dialog_id, window_id, event)) ->
      case dialog_id == dialog.id, window_id == window.id {
        False, _ -> {
          render.answer_quietly(ctx, None)
          wait(ctx, inst)
        }
        // A press on an outdated message of this dialog (the dialog has
        // moved on): soft notice, no transition.
        True, False -> answer_stale(dialog, ctx, inst)
        True, True ->
          // The window id matches, but the press may still come from an
          // outdated copy of the live message (left behind by a recreate
          // fallback or `restart`): acting on it would mutate the fresh
          // instance's state from a stale keyboard.
          case pressed_outdated_message(ctx, inst) {
            True -> answer_stale(dialog, ctx, inst)
            False -> {
              let state = load_state(dialog, inst)
              emit_action_event(dialog, window.id, event)
              case parse_widget_event(event) {
                Ok(#(widget_id, cmd, arg)) ->
                  handle_widget_event(
                    dialog,
                    window,
                    ctx,
                    inst,
                    state,
                    widget_id,
                    cmd,
                    arg,
                  )
                Error(Nil) -> {
                  let handled = window.on_action(state, event, ctx)
                  render.auto_answer(ctx)
                  case handled {
                    Ok(action) -> apply_action(dialog, ctx, inst, action)
                    Error(error) -> Error(error)
                  }
                }
              }
            }
          }
      }
  }
}

fn answer_stale(
  dialog: CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
) -> flow_types.StepResult(String, session, error, dependencies) {
  let labels = dialog.labels(ctx)
  render.answer_quietly(ctx, Some(labels.stale))
  wait(ctx, inst)
}

/// Whether the pressed message is not the tracked live dialog message.
/// `False` when either id is unknown — an unverifiable press is processed
/// normally.
fn pressed_outdated_message(
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
) -> Bool {
  case pressed_message_id(ctx), message_id(inst) {
    Some(pressed), Some(live) -> pressed != live
    _, _ -> False
  }
}

fn pressed_message_id(
  ctx: Context(session, error, dependencies),
) -> Option(Int) {
  case ctx.update {
    update.CallbackQueryUpdate(query:, ..) ->
      case query.message {
        Some(model_types.MessageMaybeInaccessibleMessage(message)) ->
          Some(message.message_id)
        Some(model_types.InaccessibleMessageMaybeInaccessibleMessage(message)) ->
          Some(message.message_id)
        None -> None
      }
    _ -> None
  }
}

fn handle_widget_event(
  dialog: CompiledDialog(session, error, dependencies),
  window: Window(String, session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  state: String,
  widget_id: String,
  cmd: String,
  arg: Option(String),
) -> flow_types.StepResult(String, session, error, dependencies) {
  case list.find(window.widgets, fn(candidate) { candidate.id == widget_id }) {
    // A widget button of a window that no longer declares this widget: the
    // message is effectively stale — remove the spinner and keep waiting.
    Error(Nil) -> {
      render.answer_quietly(ctx, None)
      wait(ctx, inst)
    }
    Ok(found) -> {
      let store = load_widget_store(inst, window.id, widget_id)
      let widget_ctx =
        types.WidgetCtx(state:, store:, labels: dialog.labels(ctx), ctx:)
      let handled = found.on_event(widget_ctx, cmd, arg)
      render.auto_answer(ctx)
      case handled {
        Ok(types.StoreUpdated(store)) -> {
          let inst = save_widget_store(inst, window.id, widget_id, store)
          apply_action(dialog, ctx, inst, types.Stay(state))
        }
        Ok(types.Emit(action)) -> apply_action(dialog, ctx, inst, action)
        Error(error) -> Error(error)
      }
    }
  }
}

fn handle_text(
  dialog: CompiledDialog(session, error, dependencies),
  window: Window(String, session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  text: String,
) -> flow_types.StepResult(String, session, error, dependencies) {
  case window.on_text {
    Some(on_text) -> {
      let state = load_state(dialog, inst)
      case on_text(state, text, ctx) {
        Ok(action) -> apply_action(dialog, ctx, inst, action)
        Error(error) -> Error(error)
      }
    }
    // The window doesn't accept text: swallow it and re-render so the user
    // sees the current window state.
    None -> render_and_wait(dialog, window, ctx, inst)
  }
}

// DialogAction → FlowAction ------------------------------------------------------

fn apply_action(
  dialog: CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  action: DialogAction(String),
) -> flow_types.StepResult(String, session, error, dependencies) {
  case action {
    types.Stay(state) -> {
      let inst = save_state(inst, state)
      case current_window(dialog, inst) {
        Ok(window) -> render_and_park(dialog, window, ctx, inst, state)
        Error(Nil) -> wait(ctx, inst)
      }
    }

    types.Goto(window_id:, state:) -> {
      let inst = save_state(inst, state)
      case dict.has_key(dialog.windows, window_id) {
        True -> Ok(#(ctx, flow_types.NextString(window_id), inst))
        // A typo in a window id must not tear the dialog down: log and stay.
        False -> {
          log_unknown_window(dialog, inst.state.current_step, window_id)
          wait(ctx, inst)
        }
      }
    }

    types.Back(state) -> {
      let inst = save_state(inst, state)
      case instance.get_data(inst, sub_key) {
        // The flow engine's `Back` on an empty history silently drops the
        // instance update (nothing is saved or re-rendered), which would
        // lose the state carried in `Back(state)` — treat it as `Stay`.
        None ->
          case inst.state.history {
            [] -> apply_action(dialog, ctx, inst, types.Stay(state))
            _ -> Ok(#(ctx, flow_types.Back, inst))
          }
        Some(sub_id) -> {
          let prefix = sub_id <> sub_separator
          case inst.state.history {
            // Still inside the sub-dialog: normal history pop.
            [head, ..] ->
              case string.starts_with(head, prefix) {
                True -> Ok(#(ctx, flow_types.Back, inst))
                False -> cancel_sub(dialog, ctx, inst, sub_id)
              }
            // Back on the sub's first window: cancel the sub, return to the
            // parent window without calling `on_sub_result`.
            [] -> cancel_sub(dialog, ctx, inst, sub_id)
          }
        }
      }
    }

    types.Done(state) ->
      case instance.get_data(inst, sub_key) {
        Some(sub_id) -> finish_sub(dialog, ctx, inst, sub_id, state)
        None -> finish_dialog(dialog, ctx, inst, state)
      }

    types.StartSub(sub_id:, args:, state:) ->
      case instance.get_data(inst, sub_key) {
        // One level of nesting only (documented): reject and re-render.
        Some(active) -> {
          logging.log(
            logging.Error,
            "[dialog:"
              <> dialog.id
              <> "] StartSub('"
              <> sub_id
              <> "') rejected: sub-dialog '"
              <> active
              <> "' is already active (nesting is one level deep)",
          )
          apply_action(dialog, ctx, inst, types.Stay(state))
        }
        None ->
          start_sub(dialog, ctx, inst, sub_id, args, state, when_unknown: fn() {
            apply_action(dialog, ctx, inst, types.Stay(state))
          })
      }
  }
}

fn finish_dialog(
  _dialog: CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  state: String,
) -> flow_types.StepResult(String, session, error, dependencies) {
  let inst = save_state(inst, state)
  case message_id(inst) {
    Some(message_id) -> {
      let _ =
        render.remove_keyboard(ctx, chat_id: ctx.update.chat_id, message_id:)
      Nil
    }
    None -> Nil
  }
  Ok(#(ctx, flow_types.Complete(inst.state.data), inst))
}

// Sub-dialog lifecycle -------------------------------------------------------------

/// Enter a sub-dialog: park the parent state, swap in the sub's initial
/// state, reset the sub's widget stores (a re-entered sub starts clean), and
/// jump-render its initial window. The jump must not push the sub step onto
/// the parent history — `Back` boundary detection relies on it (see the
/// module doc).
fn start_sub(
  dialog: CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  sub_id: String,
  args: Dict(String, String),
  parent_state: String,
  when_unknown when_unknown: fn() ->
    flow_types.StepResult(String, session, error, dependencies),
) -> flow_types.StepResult(String, session, error, dependencies) {
  case dict.get(dialog.subs, sub_id) {
    Error(Nil) -> {
      logging.log(
        logging.Error,
        "[dialog:"
          <> dialog.id
          <> "] StartSub to unknown sub-dialog '"
          <> sub_id
          <> "' from '"
          <> inst.state.current_step
          <> "'",
      )
      when_unknown()
    }
    Ok(sub) -> {
      emit_dialog_event(dialog, "sub_start", inst.state.current_step, [
        #("count", 1),
      ])
      let inst =
        inst
        |> reset_sub_widget_stores(sub_id)
        |> instance.store_data(sub_key, sub_id)
        |> instance.store_data(return_window_key, inst.state.current_step)
        |> instance.store_data(sub_saved_key, parent_state)
        |> save_state(sub.init(parent_state, args))
      jump_and_render(dialog, ctx, inst, sub.initial)
    }
  }
}

/// The sub-dialog finished with `Done`: export its result, restore the
/// parent state and history, and hand the result to the return window's
/// `on_sub_result` (default: just re-render the return window).
fn finish_sub(
  dialog: CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  sub_id: String,
  sub_state: String,
) -> flow_types.StepResult(String, session, error, dependencies) {
  emit_dialog_event(dialog, "sub_done", inst.state.current_step, [
    #("count", 1),
  ])
  let result = case dict.get(dialog.subs, sub_id) {
    Ok(sub) -> sub.result(sub_state)
    Error(Nil) -> dict.new()
  }
  let return_window = return_window_of(dialog, inst)
  let inst = leave_sub(dialog, inst, sub_id)
  let parent_state = load_state(dialog, inst)

  let on_sub_result =
    dict.get(dialog.windows, return_window)
    |> option.from_result
    |> option.then(fn(window) { window.on_sub_result })

  case on_sub_result {
    None -> jump_and_render(dialog, ctx, inst, return_window)
    Some(handler) -> {
      // Parent widget stores are visible again in the handler.
      widget.stash_stores(inst.state.data)
      case handler(parent_state, result, ctx) {
        Error(error) -> Error(error)
        Ok(action) ->
          apply_sub_return_action(dialog, ctx, inst, return_window, action)
      }
    }
  }
}

/// Map the action returned by `on_sub_result`. The current step is still the
/// sub's last window, so plain `apply_action` semantics ("re-render the
/// current window") would render the wrong window — every branch navigates
/// relative to the return window instead.
fn apply_sub_return_action(
  dialog: CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  return_window: String,
  action: DialogAction(String),
) -> flow_types.StepResult(String, session, error, dependencies) {
  case action {
    types.Stay(state) ->
      jump_and_render(dialog, ctx, save_state(inst, state), return_window)

    types.Goto(window_id:, state:) -> {
      let inst = save_state(inst, state)
      case dict.has_key(dialog.windows, window_id) {
        // Behave like a Goto from the return window: it goes onto the
        // history so Back returns there.
        True -> {
          let inst = push_history(inst, return_window)
          jump_and_render(dialog, ctx, inst, window_id)
        }
        False -> {
          log_unknown_window(dialog, return_window, window_id)
          jump_and_render(dialog, ctx, inst, return_window)
        }
      }
    }

    // Back relative to the return window: pop the (already restored) parent
    // history.
    types.Back(state) -> {
      let inst = save_state(inst, state)
      case inst.state.history {
        [previous, ..rest] ->
          jump_and_render(dialog, ctx, set_history(inst, rest), previous)
        [] -> jump_and_render(dialog, ctx, inst, return_window)
      }
    }

    types.Done(state) -> finish_dialog(dialog, ctx, inst, state)

    // Chain into the next sub-dialog, keeping the original return window.
    types.StartSub(sub_id:, args:, state:) -> {
      let inst = set_current_step(inst, return_window)
      start_sub(dialog, ctx, inst, sub_id, args, state, when_unknown: fn() {
        jump_and_render(dialog, ctx, save_state(inst, state), return_window)
      })
    }
  }
}

/// Back crossed the sub boundary: drop the sub without a result.
fn cancel_sub(
  dialog: CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  sub_id: String,
) -> flow_types.StepResult(String, session, error, dependencies) {
  emit_dialog_event(dialog, "sub_cancel", inst.state.current_step, [
    #("count", 1),
  ])
  let return_window = return_window_of(dialog, inst)
  let inst = leave_sub(dialog, inst, sub_id)
  jump_and_render(dialog, ctx, inst, return_window)
}

/// Restore the parent context: parent state back into `__dialog_state`, sub
/// bookkeeping keys cleared, sub steps stripped from the history top.
fn leave_sub(
  dialog: CompiledDialog(session, error, dependencies),
  inst: flow_types.FlowInstance,
  sub_id: String,
) -> flow_types.FlowInstance {
  let parent_state =
    instance.get_data(inst, sub_saved_key)
    |> option.unwrap(dialog.initial_encoded())
  let prefix = sub_id <> sub_separator
  let history =
    list.drop_while(inst.state.history, string.starts_with(_, prefix))
  inst
  |> save_state(parent_state)
  |> remove_data(sub_key)
  |> remove_data(return_window_key)
  |> remove_data(sub_saved_key)
  |> set_history(history)
}

fn return_window_of(
  dialog: CompiledDialog(session, error, dependencies),
  inst: flow_types.FlowInstance,
) -> String {
  instance.get_data(inst, return_window_key)
  |> option.unwrap(dialog.initial)
}

/// A re-entered sub-dialog must not see widget selections from a previous
/// run: drop all of its windows' widget stores.
fn reset_sub_widget_stores(
  inst: flow_types.FlowInstance,
  sub_id: String,
) -> flow_types.FlowInstance {
  let prefix = "__dialog_widget:" <> sub_id <> sub_separator
  let data =
    dict.filter(inst.state.data, fn(key, _) { !string.starts_with(key, prefix) })
  set_data(inst, data)
}

// Rendering helpers --------------------------------------------------------------

/// Switch to `target` without touching the history — the navigation
/// primitive for sub-dialog enter/return. Emits the flow `Jump` action, so
/// the transition goes through the flow engine (persistence, telemetry) and
/// the target step renders via its own `Pending` handling.
fn jump_and_render(
  dialog: CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  target: String,
) -> flow_types.StepResult(String, session, error, dependencies) {
  case dict.has_key(dialog.windows, target) {
    True -> Ok(#(ctx, flow_types.Jump(target), inst))
    False -> {
      log_unknown_window(dialog, inst.state.current_step, target)
      wait(ctx, inst)
    }
  }
}

/// Render a window and park on `Wait`, keeping the dialog alive if the
/// render fails.
fn render_and_park(
  dialog: CompiledDialog(session, error, dependencies),
  window: Window(String, session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  state: String,
) -> flow_types.StepResult(String, session, error, dependencies) {
  case render_window(dialog, window, ctx, inst, state) {
    Ok(inst) -> wait(ctx, inst)
    Error(render_error) -> {
      log_render_error(dialog, window.id, render_error)
      wait(ctx, inst)
    }
  }
}

fn render_window(
  dialog: CompiledDialog(session, error, dependencies),
  window: Window(String, session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  state: String,
) -> Result(flow_types.FlowInstance, render.RenderError) {
  // Re-stash so a render following a widget-store update sees fresh values.
  widget.stash_stores(inst.state.data)
  let rendered = window.render(state, ctx)
  let rendered = append_widget_rows(dialog, window, ctx, inst, state, rendered)
  let started_at = telemetry.monotonic_time()
  case
    render.render_window(
      ctx,
      chat_id: ctx.update.chat_id,
      message: live_message(inst),
      dialog_id: dialog.id,
      window_id: window.id,
      window: rendered,
    )
  {
    Ok(#(message_id, kind)) -> {
      emit_dialog_event(dialog, "render", window.id, [
        #("duration", telemetry.monotonic_time() - started_at),
      ])
      inst
      |> instance.store_data(message_id_key, int.to_string(message_id))
      |> instance.store_data(message_kind_key, kind_to_string(kind))
      |> Ok
    }
    Error(render_error) -> Error(render_error)
  }
}

/// Widget rows come after the window's own buttons, widgets in declaration
/// order.
fn append_widget_rows(
  dialog: CompiledDialog(session, error, dependencies),
  window: Window(String, session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
  state: String,
  rendered: types.RenderedWindow,
) -> types.RenderedWindow {
  case window.widgets {
    [] -> rendered
    widgets -> {
      let labels = dialog.labels(ctx)
      let rows =
        list.flat_map(widgets, fn(item) {
          let store = load_widget_store(inst, window.id, item.id)
          item.render(types.WidgetCtx(state:, store:, labels:, ctx:))
        })
      types.RenderedWindow(
        ..rendered,
        buttons: list.append(rendered.buttons, rows),
      )
    }
  }
}

fn load_widget_store(
  inst: flow_types.FlowInstance,
  window_id: String,
  widget_id: String,
) -> types.WidgetStore {
  instance.get_data(inst, widget.store_data_key(window_id, widget_id))
  |> option.map(types.decode_store)
  |> option.map(option.from_result)
  |> option.flatten
  |> option.unwrap(types.new_store())
}

fn save_widget_store(
  inst: flow_types.FlowInstance,
  window_id: String,
  widget_id: String,
  store: types.WidgetStore,
) -> flow_types.FlowInstance {
  instance.store_data(
    inst,
    widget.store_data_key(window_id, widget_id),
    types.encode_store(store),
  )
}

/// Best-effort re-render for the `on_error` hook. Skipped entirely when the
/// instance is no longer stored (e.g. the error came from `on_done` after
/// completion): a finished dialog must not be re-rendered or resurrected.
/// A successful render is persisted — the edit may have fallen back to a
/// fresh send, and losing its message id would strand the old message with a
/// live keyboard. The stored wait token is kept as-is: the in-memory
/// instance's token was already consumed by this update.
fn try_render_current(
  dialog: CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
) -> Result(Nil, Nil) {
  case dialog.storage.load(inst.id) {
    Ok(Some(stored)) ->
      case current_window(dialog, inst) {
        Ok(window) ->
          case
            render_window(dialog, window, ctx, inst, load_state(dialog, inst))
          {
            Ok(updated) -> {
              let _ =
                dialog.storage.save(
                  flow_types.FlowInstance(
                    ..updated,
                    wait_token: stored.wait_token,
                    wait_timeout_at: stored.wait_timeout_at,
                  ),
                )
              Ok(Nil)
            }
            Error(_) -> Error(Nil)
          }
        Error(Nil) -> Error(Nil)
      }
    _ -> Error(Nil)
  }
}

fn current_window(
  dialog: CompiledDialog(session, error, dependencies),
  inst: flow_types.FlowInstance,
) -> Result(Window(String, session, error, dependencies), Nil) {
  dict.get(dialog.windows, inst.state.current_step)
}

// State and instance helpers ------------------------------------------------------

/// The encoded state string. Decoding (and the fallback to the initial
/// state on codec mismatch) happens inside the erased window closures built
/// by `dialog.build()`.
fn load_state(
  dialog: CompiledDialog(session, error, dependencies),
  inst: flow_types.FlowInstance,
) -> String {
  case instance.get_data(inst, state_key) {
    Some(raw) -> raw
    None -> dialog.initial_encoded()
  }
}

fn save_state(
  inst: flow_types.FlowInstance,
  state: String,
) -> flow_types.FlowInstance {
  instance.store_data(inst, state_key, state)
}

fn message_id(inst: flow_types.FlowInstance) -> Option(Int) {
  case instance.get_data(inst, message_id_key) {
    Some(raw) -> option.from_result(int.parse(raw))
    None -> None
  }
}

/// The live message with its kind — what the edit-or-send matrix in
/// `dialog/render` branches on. A missing/unknown kind means `text`: dialogs
/// persisted before media support only ever sent text messages.
fn live_message(
  inst: flow_types.FlowInstance,
) -> Option(#(Int, render.MessageKind)) {
  use message_id <- option.map(message_id(inst))
  let kind = case instance.get_data(inst, message_kind_key) {
    Some("media") -> render.MediaMessage
    _ -> render.TextMessage
  }
  #(message_id, kind)
}

fn kind_to_string(kind: render.MessageKind) -> String {
  case kind {
    render.TextMessage -> "text"
    render.MediaMessage -> "media"
  }
}

fn set_current_step(
  inst: flow_types.FlowInstance,
  step: String,
) -> flow_types.FlowInstance {
  flow_types.FlowInstance(
    ..inst,
    state: flow_types.FlowState(..inst.state, current_step: step),
  )
}

fn set_history(
  inst: flow_types.FlowInstance,
  history: List(String),
) -> flow_types.FlowInstance {
  flow_types.FlowInstance(
    ..inst,
    state: flow_types.FlowState(..inst.state, history:),
  )
}

fn push_history(
  inst: flow_types.FlowInstance,
  step: String,
) -> flow_types.FlowInstance {
  set_history(inst, [step, ..inst.state.history])
}

fn set_data(
  inst: flow_types.FlowInstance,
  data: Dict(String, String),
) -> flow_types.FlowInstance {
  flow_types.FlowInstance(
    ..inst,
    state: flow_types.FlowState(..inst.state, data:),
  )
}

fn remove_data(
  inst: flow_types.FlowInstance,
  key: String,
) -> flow_types.FlowInstance {
  set_data(inst, dict.delete(inst.state.data, key))
}

/// Park the step waiting for the next event, clearing the consumed wait
/// result so a later direct `execute_step` (e.g. a repeated start command)
/// sees `Pending` and re-renders instead of re-processing a stale event.
fn wait(
  ctx: Context(session, error, dependencies),
  inst: flow_types.FlowInstance,
) -> flow_types.StepResult(String, session, error, dependencies) {
  let inst = instance.clear_wait_result(inst)
  Ok(#(ctx, flow_types.Wait, inst))
}

// Callback data parsing -----------------------------------------------------------

/// Parse `dlg:<dialog_id>:<window_id>:<action_id>[:<arg>]`. Extra segments
/// are joined back into the arg, so args may contain `:`.
pub fn parse_callback_data(
  data: String,
) -> Result(#(String, String, ActionEvent), Nil) {
  case string.split(data, ":") {
    ["dlg", dialog_id, window_id, action_id] ->
      Ok(#(dialog_id, window_id, ActionEvent(action_id:, arg: None)))
    ["dlg", dialog_id, window_id, action_id, ..arg_parts] ->
      Ok(#(
        dialog_id,
        window_id,
        ActionEvent(action_id:, arg: Some(string.join(arg_parts, ":"))),
      ))
    _ -> Error(Nil)
  }
}

/// A widget event arrives as `ActionEvent("w", Some("<widget_id>:<cmd>[:<arg>]"))`
/// after the generic parse (`dlg:<d>:<w>:w:<widget_id>:<cmd>[:<arg>]`). Extra
/// segments are re-joined into the arg, mirroring `parse_callback_data`.
@internal
pub fn parse_widget_event(
  event: ActionEvent,
) -> Result(#(String, String, Option(String)), Nil) {
  case event.action_id, event.arg {
    "w", Some(rest) ->
      case string.split(rest, ":") {
        [widget_id, cmd] -> Ok(#(widget_id, cmd, None))
        [widget_id, cmd, ..arg_parts] ->
          Ok(#(widget_id, cmd, Some(string.join(arg_parts, ":"))))
        _ -> Error(Nil)
      }
    _, _ -> Error(Nil)
  }
}

// Telemetry and logging -------------------------------------------------------------

fn emit_action_event(
  dialog: CompiledDialog(session, error, dependencies),
  window_id: String,
  event: ActionEvent,
) -> Nil {
  telemetry.execute(["telega", "dialog", "action"], [#("count", 1)], [
    #("dialog_id", telemetry.StringValue(dialog.id)),
    #("window_id", telemetry.StringValue(window_id)),
    #("action_id", telemetry.StringValue(event.action_id)),
  ])
}

fn emit_dialog_event(
  dialog: CompiledDialog(session, error, dependencies),
  event: String,
  window_id: String,
  measurements: List(#(String, Int)),
) -> Nil {
  telemetry.execute(["telega", "dialog", event], measurements, [
    #("dialog_id", telemetry.StringValue(dialog.id)),
    #("window_id", telemetry.StringValue(window_id)),
  ])
}

fn log_unknown_window(
  dialog: CompiledDialog(session, error, dependencies),
  from: String,
  to: String,
) -> Nil {
  logging.log(
    logging.Error,
    "[dialog:"
      <> dialog.id
      <> "] Goto to unknown window '"
      <> to
      <> "' from '"
      <> from
      <> "'",
  )
}

fn log_render_error(
  dialog: CompiledDialog(session, error, dependencies),
  window_id: String,
  render_error: render.RenderError,
) -> Nil {
  emit_dialog_event(dialog, "render_error", window_id, [#("count", 1)])
  logging.log(
    logging.Error,
    "[dialog:"
      <> dialog.id
      <> "] failed to render window '"
      <> window_id
      <> "': "
      <> render.describe_error(render_error),
  )
}

fn log_dialog_error(
  dialog: CompiledDialog(session, error, dependencies),
  inst: flow_types.FlowInstance,
  maybe_error: Option(error),
) -> Nil {
  emit_dialog_event(dialog, "error", inst.state.current_step, [#("count", 1)])
  let details = case maybe_error {
    Some(error) -> string.inspect(error)
    None -> "unknown step '" <> inst.state.current_step <> "'"
  }
  logging.log(
    logging.Error,
    "[dialog:"
      <> dialog.id
      <> "] handler error in window '"
      <> inst.state.current_step
      <> "': "
      <> details,
  )
}
