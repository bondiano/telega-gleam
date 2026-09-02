import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

import birdie

import telega/bot
import telega/dialog
import telega/dialog/types as dialog_types
import telega/dialog/widget
import telega/error
import telega/flow/action
import telega/flow/builder
import telega/flow/instance
import telega/flow/storage as flow_storage
import telega/flow/types as flow_types
import telega/format
import telega/testing/context
import telega/testing/graph

pub fn main() {
  gleeunit.main()
}

type Ctx =
  bot.Context(Nil, error.TelegaError, Nil)

type Action =
  Result(dialog_types.DialogAction(String), error.TelegaError)

// ============================================================================
// Fixture: booking dialog with a widget, a sub-dialog and a text window
// ============================================================================

fn text(value: String) -> format.FormattedText {
  format.build() |> format.text(value) |> format.to_formatted()
}

fn render_menu(_state: String, _ctx: Ctx) -> dialog_types.RenderedWindow {
  dialog_types.RenderedWindow(
    text: text("Book a table"),
    buttons: [
      [dialog_types.ActionButton("Address", "addr")],
      [dialog_types.ActionButton("Next", "next")],
    ],
    media: None,
  )
}

fn handle_menu(
  state: String,
  event: dialog_types.ActionEvent,
  _ctx: Ctx,
) -> Action {
  case event.action_id {
    "addr" -> Ok(dialog_types.StartSub("address", dict.new(), state))
    "next" -> Ok(dialog_types.Goto("confirm", state))
    _ -> Ok(dialog_types.Stay(state))
  }
}

fn guests_widget() -> dialog_types.KeyboardWidget(
  String,
  Nil,
  error.TelegaError,
  Nil,
) {
  widget.radio(
    id: "guests",
    items: fn(_state, _ctx) {
      [widget.SelectItem("1", "One"), widget.SelectItem("2", "Two")]
    },
    default: Some("1"),
  )
}

fn render_confirm(state: String, _ctx: Ctx) -> dialog_types.RenderedWindow {
  dialog_types.RenderedWindow(
    text: text("Confirm: " <> state),
    buttons: [
      [dialog_types.ActionButton("Book", "book")],
      [dialog_types.UrlButton("Terms", "https://example.com/terms")],
    ],
    media: None,
  )
}

fn handle_confirm(
  state: String,
  event: dialog_types.ActionEvent,
  _ctx: Ctx,
) -> Action {
  case event.action_id {
    "book" -> Ok(dialog_types.Done(state))
    _ -> Ok(dialog_types.Stay(state))
  }
}

fn render_city(_state: String, _ctx: Ctx) -> dialog_types.RenderedWindow {
  dialog_types.RenderedWindow(
    text: text("Which city?"),
    buttons: [
      [dialog_types.ActionArgButton("Berlin", "pick", "berlin")],
      [dialog_types.ActionButton("‹ Back", "back")],
    ],
    media: None,
  )
}

fn handle_city(
  state: String,
  event: dialog_types.ActionEvent,
  _ctx: Ctx,
) -> Action {
  case event.action_id, event.arg {
    "pick", Some(city) -> Ok(dialog_types.Goto("check", city))
    "back", _ -> Ok(dialog_types.Back(state))
    _, _ -> Ok(dialog_types.Stay(state))
  }
}

fn handle_city_text(state: String, value: String, _ctx: Ctx) -> Action {
  case value {
    "" -> Ok(dialog_types.Stay(state))
    city -> Ok(dialog_types.Goto("check", city))
  }
}

fn render_check(state: String, _ctx: Ctx) -> dialog_types.RenderedWindow {
  dialog_types.RenderedWindow(
    text: text("City: " <> state),
    buttons: [
      [dialog_types.ActionButton("OK", "ok")],
      [dialog_types.ActionButton("‹ Back", "back")],
    ],
    media: None,
  )
}

fn handle_check(
  state: String,
  event: dialog_types.ActionEvent,
  _ctx: Ctx,
) -> Action {
  case event.action_id {
    "ok" -> Ok(dialog_types.Done(state))
    "back" -> Ok(dialog_types.Back(state))
    _ -> Ok(dialog_types.Stay(state))
  }
}

fn address_dialog() -> dialog.Dialog(String, Nil, error.TelegaError, Nil) {
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(built) =
    dialog.new(
      id: "address",
      storage: flow_storage.create_noop_storage(),
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window_with_input(
      id: "city",
      render: render_city,
      on_action: handle_city,
      on_text: handle_city_text,
    )
    |> dialog.window(id: "check", render: render_check, on_action: handle_check)
    |> dialog.initial("city")
    |> dialog.build()
  built
}

fn booking_dialog() -> dialog.Dialog(String, Nil, error.TelegaError, Nil) {
  let #(encode_state, decode_state) = dialog.string_codec()
  let assert Ok(built) =
    dialog.new(
      id: "booking",
      storage: flow_storage.create_noop_storage(),
      initial_state: fn(_ctx) { "" },
      encode_state:,
      decode_state:,
    )
    |> dialog.window_with_widgets(
      id: "menu",
      render: render_menu,
      on_action: handle_menu,
      widgets: [guests_widget()],
    )
    |> dialog.window(
      id: "confirm",
      render: render_confirm,
      on_action: handle_confirm,
    )
    |> dialog.initial("menu")
    |> dialog.subdialog(
      sub: address_dialog(),
      init: fn(_state, _args) { "" },
      result: fn(city) { dict.from_list([#("address.city", city)]) },
    )
    |> dialog.on_sub_result(window: "menu", handler: fn(_state, result, _ctx) {
      let city =
        dict.get(result, "address.city")
        |> option.from_result
        |> option.unwrap("")
      Ok(dialog_types.Goto("confirm", city))
    })
    |> dialog.build()
  built
}

fn booking_graph() -> graph.Graph {
  graph.of_dialog(dialog: booking_dialog(), ctx: context.context(session: Nil))
}

fn has_edge(
  graph_value: graph.Graph,
  from: String,
  to: String,
  kind: graph.EdgeKind,
) -> Bool {
  list.any(graph_value.edges, fn(edge) {
    edge.from == from && edge.to == to && edge.kind == kind
  })
}

// ============================================================================
// Dialog graph
// ============================================================================

pub fn dialog_graph_entry_and_windows_test() {
  let value = booking_graph()

  value.name |> should.equal("booking")
  has_edge(value, "__entry", "menu", graph.Declared) |> should.be_true

  list.map(value.nodes, fn(node) { node.id })
  |> should.equal([
    "__entry", "confirm", "menu", "address.check", "address.city", "__back",
    "__done", "__url:https://example.com/terms",
  ])
}

pub fn dialog_graph_probes_button_navigation_test() {
  let value = booking_graph()

  // "Next" → Goto("confirm")
  has_edge(value, "menu", "confirm", graph.Probed) |> should.be_true
  // "Book" → Done
  has_edge(value, "confirm", "__done", graph.Probed) |> should.be_true
  // A url button leaves the bot.
  has_edge(value, "confirm", "__url:https://example.com/terms", graph.Declared)
  |> should.be_true
}

pub fn dialog_graph_probes_text_input_test() {
  let value = booking_graph()

  // on_text of the sub-dialog's city window navigates to `check`.
  has_edge(value, "address.city", "address.check", graph.Probed)
  |> should.be_true
}

pub fn dialog_graph_walks_into_sub_dialog_test() {
  let value = booking_graph()

  // StartSub enters the sub's initial window...
  has_edge(value, "menu", "address.city", graph.Declared) |> should.be_true
  // ...and the sub's `Done` returns to the window that started it.
  has_edge(value, "address.check", "menu", graph.Probed) |> should.be_true
  // The sub's windows are grouped under the sub id.
  list.filter(value.nodes, fn(node) { node.group == Some("address") })
  |> list.length
  |> should.equal(2)
}

pub fn dialog_graph_probes_sub_result_test() {
  let value = booking_graph()

  // `on_sub_result` on `menu` routes the returning result to `confirm`.
  list.any(value.edges, fn(edge) { edge.from == "menu" && edge.to == "confirm" })
  |> should.be_true
}

pub fn dialog_graph_marks_text_windows_test() {
  let value = booking_graph()

  let assert Ok(city) =
    list.find(value.nodes, fn(node) { node.id == "address.city" })
  city.kind |> should.equal(graph.InputNode)

  let assert Ok(menu) = list.find(value.nodes, fn(node) { node.id == "menu" })
  menu.kind |> should.equal(graph.StepNode)
}

pub fn dialog_graph_widget_store_updates_are_self_loops_test() {
  let value = booking_graph()

  has_edge(value, "menu", "menu", graph.Probed) |> should.be_true
}

pub fn dialog_graph_dot_snapshot_test() {
  booking_graph()
  |> graph.to_dot
  |> birdie.snap(title: "graph:booking_dialog:dot")
}

pub fn dialog_graph_mermaid_snapshot_test() {
  booking_graph()
  |> graph.to_mermaid
  |> birdie.snap(title: "graph:booking_dialog:mermaid")
}

// ============================================================================
// Fixture: flow skeleton
// ============================================================================

type Step {
  Start
  Check
  Fast
  Slow
  Fan
  BranchA
  BranchB
  Join
  Notify
  Finish
}

fn step_to_string(step: Step) -> String {
  case step {
    Start -> "start"
    Check -> "check"
    Fast -> "fast"
    Slow -> "slow"
    Fan -> "fan"
    BranchA -> "branch_a"
    BranchB -> "branch_b"
    Join -> "join"
    Notify -> "notify"
    Finish -> "finish"
  }
}

fn string_to_step(value: String) -> Result(Step, Nil) {
  case value {
    "start" -> Ok(Start)
    "check" -> Ok(Check)
    "fast" -> Ok(Fast)
    "slow" -> Ok(Slow)
    "fan" -> Ok(Fan)
    "branch_a" -> Ok(BranchA)
    "branch_b" -> Ok(BranchB)
    "join" -> Ok(Join)
    "notify" -> Ok(Notify)
    "finish" -> Ok(Finish)
    _ -> Error(Nil)
  }
}

fn noop_step(
  ctx: bot.Context(Nil, error.TelegaError, Nil),
  inst: flow_types.FlowInstance,
  next: Step,
) {
  action.next(ctx, inst, step: next)
}

fn demo_flow() -> flow_types.Flow(Step, Nil, error.TelegaError, Nil) {
  builder.new(
    "checkout",
    flow_storage.create_noop_storage(),
    step_to_string,
    string_to_step,
  )
  |> builder.add_step(Start, fn(ctx, inst) { noop_step(ctx, inst, Check) })
  |> builder.add_step(Check, fn(ctx, inst) { noop_step(ctx, inst, Fast) })
  |> builder.add_step(Fast, fn(ctx, inst) { noop_step(ctx, inst, Fan) })
  |> builder.add_step(Slow, fn(ctx, inst) { noop_step(ctx, inst, Fan) })
  |> builder.add_step(Fan, fn(ctx, inst) { noop_step(ctx, inst, Join) })
  |> builder.add_step(BranchA, fn(ctx, inst) { noop_step(ctx, inst, Join) })
  |> builder.add_step(BranchB, fn(ctx, inst) { noop_step(ctx, inst, Join) })
  |> builder.add_step(Join, fn(ctx, inst) { noop_step(ctx, inst, Finish) })
  |> builder.add_step(Notify, fn(ctx, inst) { noop_step(ctx, inst, Finish) })
  |> builder.add_step(Finish, fn(ctx, inst) { noop_step(ctx, inst, Finish) })
  |> builder.add_conditional(
    Check,
    fn(inst) { instance.get_data(inst, "express") == Some("1") },
    true: Fast,
    false: Slow,
  )
  |> builder.parallel(from: Fan, steps: [BranchA, BranchB], join: Join)
  // Handler-driven transitions, declared so the graph can draw them.
  |> builder.declare_next(from: Start, to: Check)
  |> builder.declare_next(from: Fast, to: Fan)
  |> builder.declare_next(from: Slow, to: Fan)
  |> builder.declare_choice(from: Join, to: [Finish, Notify])
  |> builder.declare_complete(from: Finish)
  |> builder.declare_cancel(from: Finish)
  |> builder.build(initial: Start)
}

// ============================================================================
// Flow graph
// ============================================================================

pub fn flow_graph_declared_edges_test() {
  let value = graph.of_flow(flow: demo_flow())

  value.name |> should.equal("checkout")
  has_edge(value, "__entry", "start", graph.Declared) |> should.be_true
  has_edge(value, "check", "fast", graph.Declared) |> should.be_true
  has_edge(value, "check", "slow", graph.Declared) |> should.be_true
  has_edge(value, "fan", "branch_a", graph.Declared) |> should.be_true
  has_edge(value, "branch_b", "join", graph.Declared) |> should.be_true
}

pub fn flow_graph_draws_declared_transitions_test() {
  let value = graph.of_flow(flow: demo_flow())

  has_edge(value, "start", "check", graph.Declared) |> should.be_true
  has_edge(value, "join", "finish", graph.Declared) |> should.be_true
  has_edge(value, "finish", "__complete", graph.Declared) |> should.be_true
  has_edge(value, "finish", "__cancel", graph.Declared) |> should.be_true
}

pub fn flow_graph_marks_handler_driven_steps_test() {
  let value = graph.of_flow(flow: demo_flow())

  // A declaration takes the step out of the opaque set...
  let assert Ok(start) = list.find(value.nodes, fn(node) { node.id == "start" })
  start.kind |> should.equal(graph.StepNode)

  // ...`notify` declares nothing of its own, so it stays dashed: only its
  // handler knows where it goes.
  let assert Ok(notify) =
    list.find(value.nodes, fn(node) { node.id == "notify" })
  notify.kind |> should.equal(graph.OpaqueNode)
}

/// Declarations are checked against the registered steps, so a rename cannot
/// leave the graph lying.
pub fn flow_declaration_errors_test() {
  builder.declaration_errors(demo_flow()) |> should.equal([])

  let broken =
    builder.new(
      "broken",
      flow_storage.create_noop_storage(),
      step_to_string,
      string_to_step,
    )
    |> builder.add_step(Start, fn(ctx, inst) { noop_step(ctx, inst, Check) })
    |> builder.declare_next(from: Start, to: Check)
    |> builder.build(initial: Start)

  builder.declaration_errors(broken)
  |> should.equal(["declared transition 'start' -> unknown step 'check'"])
}

pub fn flow_graph_dot_snapshot_test() {
  graph.of_flow(flow: demo_flow())
  |> graph.to_dot
  |> birdie.snap(title: "graph:checkout_flow:dot")
}
