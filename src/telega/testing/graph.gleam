//// Graph export for dialogs and flows — see the whole navigation map before
//// running the bot.
////
//// ```gleam
//// import telega/testing/context
//// import telega/testing/graph
////
//// graph.of_dialog(dialog: booking_dialog(), ctx: context.context(session: Nil))
//// |> graph.to_dot
//// |> io.println
//// ```
////
//// Dialog graphs are **probed**, not guessed. A window's `render` is pure and
//// its handlers are pure functions of the state, so the exporter renders every
//// window, presses every button it finds (widget buttons included, routed the
//// way the engine routes them) and records where the returned `DialogAction`
//// points. Sub-dialogs are entered through the very `init`/`result` functions
//// the engine uses, so their windows are probed with real sub state.
////
//// Probing sees one state at a time: a `Goto` that only happens once the state
//// says so is invisible until you probe that state. The same goes for text
//// windows that validate their input — a rejected sample only ever draws the
//// re-render. Pass sample states and texts your handlers accept to
//// `of_dialog_probing` to widen the sweep.
////
//// Probing **runs your handlers**. Windows are pure by contract, but a handler
//// that writes to a database or calls the API on its way to a `Done` will do
//// exactly that while the graph is built — so hand it a test context (mock
//// client, test database), never a production one.
////
//// Flow graphs are **declarative**. A flow's transitions are returned by its
//// handlers (`Next`, `GoTo`, …), which are effectful and cannot be probed, so
//// only what the builder knows is drawn: steps, conditionals, parallel
//// fan-out/join, subflows, and the transitions the author declared with
//// `flow/builder.declare_next` / `declare_choice` / `declare_complete` /
//// `declare_cancel`. Steps left without any declared edge are marked
//// `OpaqueNode` (dashed) — the honest signal that their navigation is only
//// visible in the handler.
////
//// Both graphs are deterministic strings, so they snapshot well:
////
//// ```gleam
//// graph.of_dialog(dialog:, ctx:) |> graph.to_mermaid |> birdie.snap(title: "booking:graph")
//// ```

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order, Eq}
import gleam/string

import telega/bot.{type Context}
import telega/dialog.{type Dialog}
import telega/dialog/engine as dialog_engine
import telega/dialog/types as dialog_types
import telega/dialog/widget
import telega/flow/types as flow_types

// Graph model -----------------------------------------------------------------

/// A rendered-independent navigation graph. `nodes` and `edges` are sorted, so
/// two runs over the same dialog produce byte-identical output.
pub type Graph {
  Graph(name: String, nodes: List(Node), edges: List(Edge))
}

pub type Node {
  Node(id: String, label: String, kind: NodeKind, group: Option(String))
}

pub type NodeKind {
  /// Synthetic start marker.
  EntryNode
  /// A dialog window or a flow step.
  StepNode
  /// A dialog window that also accepts text input.
  InputNode
  /// A flow step whose transitions are decided inside the handler and cannot
  /// be extracted statically.
  OpaqueNode
  /// Synthetic end marker (`done`, `back`, subflow `return`).
  TerminalNode
  /// A URL or web-app target outside the bot.
  ExternalNode
}

pub type Edge {
  Edge(from: String, to: String, label: String, kind: EdgeKind)
}

pub type EdgeKind {
  /// Declared in the builder: guaranteed to exist regardless of state.
  Declared
  /// Found by probing pure handlers with sample states: real, but only as
  /// complete as the sampled states.
  Probed
  /// The edge exists, its target is computed at runtime (history-based `Back`).
  Unknown
}

const entry_id = "__entry"

const done_id = "__done"

const back_id = "__back"

const complete_id = "__complete"

const cancel_id = "__cancel"

const label_sep = ", "

const max_merged_labels = 4

// Dialogs ---------------------------------------------------------------------

/// Default sample text fed to `on_text` windows while probing.
pub fn default_texts() -> List(String) {
  ["sample"]
}

/// Build the navigation graph of a dialog, probing every window with its
/// initial state.
pub fn of_dialog(
  dialog dialog: Dialog(state, session, error, dependencies),
  ctx ctx: Context(session, error, dependencies),
) -> Graph {
  of_dialog_probing(dialog:, ctx:, states: [], texts: default_texts())
}

/// Build the navigation graph of a dialog, probing every window with the
/// initial state plus `states`, and every text window with `texts`.
///
/// Extra states uncover state-dependent navigation: a window that renders a
/// "continue" button only once a choice is made contributes its edge only when
/// probed with a state that has one.
pub fn of_dialog_probing(
  dialog dialog: Dialog(state, session, error, dependencies),
  ctx ctx: Context(session, error, dependencies),
  states states: List(state),
  texts texts: List(String),
) -> Graph {
  let compiled = dialog.compiled(dialog)
  let encode = dialog.state_encoder(dialog)
  let labels = compiled.labels(ctx)
  let parent_states =
    [compiled.initial_encoded(ctx), ..list.map(states, encode)]
    |> list.unique

  let windows =
    compiled.windows
    |> dict.to_list
    |> list.sort(fn(left, right) { string.compare(left.0, right.0) })

  let #(own_windows, sub_windows) =
    list.partition(windows, fn(entry) {
      case split_namespace(entry.0) {
        #(None, _) -> True
        #(Some(_), _) -> False
      }
    })

  // Phase 1: the parent's own windows, probed with the parent states.
  let own_transitions =
    list.flat_map(own_windows, fn(entry) {
      probe_window(ctx, labels, entry.1, parent_states, texts)
    })

  // Phase 2: sub-dialog windows, probed with states built by the sub's own
  // `init` from the `StartSub` calls discovered in phase 1.
  let sub_transitions =
    list.flat_map(sub_windows, fn(entry) {
      let states =
        sub_states(compiled, ctx, split_namespace(entry.0).0, own_transitions)
      probe_window(ctx, labels, entry.1, states, texts)
    })

  // Phase 3: what a window does with a returning sub-dialog's result.
  let result_transitions =
    probe_sub_results(compiled, ctx, own_windows, own_transitions)

  widget.clear_stash()

  let transitions =
    own_transitions
    |> list.append(sub_transitions)
    |> list.append(result_transitions)
  let starters = sub_starters(transitions)

  let widget_edges =
    list.flat_map(windows, fn(entry) {
      let window = entry.1
      list.flat_map(window.widgets, fn(item) {
        list.map(item.goto_targets, fn(target) {
          Edge(
            from: window.id,
            to: target,
            label: "widget:" <> item.id,
            kind: Declared,
          )
        })
      })
    })

  let edges =
    [Edge(from: entry_id, to: compiled.initial, label: "start", kind: Declared)]
    |> list.append(
      list.flat_map(transitions, edge_of_transition(_, compiled, starters)),
    )
    |> list.append(widget_edges)

  let nodes =
    [Node(id: entry_id, label: compiled.id, kind: EntryNode, group: None)]
    |> list.append(list.map(windows, fn(entry) { window_node(entry.1) }))

  finish(Graph(name: compiled.id, nodes:, edges:))
}

fn window_node(
  window: dialog_types.Window(String, session, error, dependencies),
) -> Node {
  let #(group, label) = split_namespace(window.id)
  let kind = case window.on_text {
    Some(_) -> InputNode
    None -> StepNode
  }
  Node(id: window.id, label:, kind:, group:)
}

/// What a window can do next, before it is turned into graph edges.
type Transition {
  ToWindow(from: String, to: String, label: String)
  SelfLoop(from: String, label: String)
  ToDone(from: String, label: String)
  ToBack(from: String, label: String)
  ToSub(
    from: String,
    sub_id: String,
    label: String,
    args: Dict(String, String),
    state: String,
  )
  ToExternal(from: String, url: String, label: String)
}

fn probe_window(
  ctx: Context(session, error, dependencies),
  labels: dialog_types.Labels,
  window: dialog_types.Window(String, session, error, dependencies),
  states: List(String),
  texts: List(String),
) -> List(Transition) {
  list.flat_map(states, fn(state) {
    // Widget stores start empty: a graph shows the dialog as a new user meets it.
    widget.stash_stores(dict.new())
    let rendered = window.render(state, ctx)
    let widget_rows =
      list.flat_map(window.widgets, fn(item) {
        item.render(dialog_types.WidgetCtx(
          state:,
          store: dialog_types.new_store(),
          labels:,
          ctx:,
        ))
      })
    let buttons = list.flatten(list.append(rendered.buttons, widget_rows))

    let from_buttons =
      list.flat_map(buttons, probe_button(ctx, labels, window, state, _))
    let from_text = case window.on_text {
      None -> []
      Some(on_text) ->
        list.flat_map(texts, fn(text) {
          case on_text(state, text, ctx) {
            Ok(action) -> transitions_of(window.id, "text", action)
            Error(_) -> []
          }
        })
    }
    list.append(from_buttons, from_text)
  })
}

fn probe_button(
  ctx: Context(session, error, dependencies),
  labels: dialog_types.Labels,
  window: dialog_types.Window(String, session, error, dependencies),
  state: String,
  button: dialog_types.DialogButton,
) -> List(Transition) {
  case button {
    dialog_types.ActionButton(action_id:, ..) ->
      press(ctx, labels, window, state, action_id, None)
    dialog_types.ActionArgButton(action_id:, arg:, ..) ->
      press(ctx, labels, window, state, action_id, Some(arg))
    dialog_types.UrlButton(text:, url:) -> [
      ToExternal(from: window.id, url:, label: text),
    ]
    dialog_types.WebAppButton(text:, url:) -> [
      ToExternal(from: window.id, url:, label: text),
    ]
    dialog_types.NoopButton(..) -> []
  }
}

/// Press one button the way the engine does: widget action ids go to the
/// widget's `on_event`, everything else to the window's `on_action`.
fn press(
  ctx: Context(session, error, dependencies),
  labels: dialog_types.Labels,
  window: dialog_types.Window(String, session, error, dependencies),
  state: String,
  action_id: String,
  arg: Option(String),
) -> List(Transition) {
  case parse_widget_action(action_id) {
    Ok(#(widget_id, cmd)) ->
      case list.find(window.widgets, fn(item) { item.id == widget_id }) {
        Error(Nil) -> []
        Ok(item) -> {
          let wctx =
            dialog_types.WidgetCtx(
              state:,
              store: dialog_types.new_store(),
              labels:,
              ctx:,
            )
          case item.on_event(wctx, cmd, arg) {
            Ok(dialog_types.StoreUpdated(_)) -> [
              SelfLoop(from: window.id, label: "widget:" <> widget_id),
            ]
            Ok(dialog_types.Emit(action)) ->
              transitions_of(window.id, widget_id <> ":" <> cmd, action)
            Error(_) -> []
          }
        }
      }
    Error(Nil) ->
      case
        window.on_action(state, dialog_types.ActionEvent(action_id:, arg:), ctx)
      {
        Ok(action) -> transitions_of(window.id, action_id, action)
        Error(_) -> []
      }
  }
}

/// `w:<widget_id>:<cmd>` — the action-id namespace reserved for widgets.
fn parse_widget_action(action_id: String) -> Result(#(String, String), Nil) {
  case string.split(action_id, ":") {
    ["w", widget_id, cmd] -> Ok(#(widget_id, cmd))
    _ -> Error(Nil)
  }
}

fn transitions_of(
  from: String,
  label: String,
  action: dialog_types.DialogAction(String),
) -> List(Transition) {
  case action {
    dialog_types.Stay(_) -> [SelfLoop(from:, label:)]
    dialog_types.Goto(window_id:, ..) -> [
      ToWindow(from:, to: window_id, label:),
    ]
    dialog_types.Back(_) -> [ToBack(from:, label:)]
    dialog_types.Done(_) -> [ToDone(from:, label:)]
    dialog_types.StartSub(sub_id:, args:, state:) -> [
      ToSub(from:, sub_id:, label:, args:, state:),
    ]
  }
}

/// The states a sub-dialog's windows are probed with: the sub's own `init`
/// applied to every `StartSub` found in the parent.
fn sub_states(
  compiled: dialog_engine.CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  sub_id: Option(String),
  transitions: List(Transition),
) -> List(String) {
  case sub_id {
    None -> []
    Some(sub_id) ->
      case dict.get(compiled.subs, sub_id) {
        Error(Nil) -> []
        Ok(sub) ->
          transitions
          |> list.filter_map(fn(transition) {
            case transition {
              ToSub(sub_id: found, args:, state:, ..) if found == sub_id ->
                Ok(sub.init(ctx, state, args))
              _ -> Error(Nil)
            }
          })
          |> fallback_states(sub, compiled, ctx)
          |> list.unique
      }
  }
}

fn fallback_states(
  states: List(String),
  sub: dialog_engine.CompiledSub(session, error, dependencies),
  compiled: dialog_engine.CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
) -> List(String) {
  case states {
    [] -> [sub.init(ctx, compiled.initial_encoded(ctx), dict.new())]
    states -> states
  }
}

/// Feed each `StartSub` back through the sub's `result` into the starting
/// window's `on_sub_result`, so the return path shows up in the graph too.
fn probe_sub_results(
  compiled: dialog_engine.CompiledDialog(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  windows: List(
    #(String, dialog_types.Window(String, session, error, dependencies)),
  ),
  transitions: List(Transition),
) -> List(Transition) {
  list.flat_map(transitions, fn(transition) {
    case transition {
      ToSub(from:, sub_id:, args:, state:, ..) ->
        case dict.get(compiled.subs, sub_id), list.key_find(windows, from) {
          Ok(sub), Ok(window) ->
            case window.on_sub_result {
              None -> []
              Some(handler) -> {
                let result = sub.result(ctx, sub.init(ctx, state, args))
                case handler(state, result, ctx) {
                  Ok(action) ->
                    transitions_of(from, sub_id <> " result", action)
                  Error(_) -> []
                }
              }
            }
          _, _ -> []
        }
      _ -> []
    }
  })
}

/// Which windows start which sub-dialog — a sub's `Done` returns to them.
fn sub_starters(transitions: List(Transition)) -> Dict(String, List(String)) {
  list.fold(transitions, dict.new(), fn(acc, transition) {
    case transition {
      ToSub(from:, sub_id:, ..) ->
        dict.upsert(acc, sub_id, fn(existing) {
          case existing {
            Some(starters) -> [from, ..starters]
            None -> [from]
          }
        })
      _ -> acc
    }
  })
}

fn edge_of_transition(
  transition: Transition,
  compiled: dialog_engine.CompiledDialog(session, error, dependencies),
  starters: Dict(String, List(String)),
) -> List(Edge) {
  case transition {
    ToWindow(from:, to:, label:) -> [Edge(from:, to:, label:, kind: Probed)]
    SelfLoop(from:, label:) -> [Edge(from:, to: from, label:, kind: Probed)]
    ToBack(from:, label:) -> [Edge(from:, to: back_id, label:, kind: Unknown)]
    ToExternal(from:, url:, label:) -> [
      Edge(from:, to: external_id(url), label:, kind: Declared),
    ]
    ToSub(from:, sub_id:, label:, ..) ->
      case dict.get(compiled.subs, sub_id) {
        Ok(sub) -> [
          Edge(
            from:,
            to: sub.initial,
            label: label <> " ▸ " <> sub_id,
            kind: Declared,
          ),
        ]
        Error(Nil) -> []
      }
    ToDone(from:, label:) -> done_edges(from, label, starters)
  }
}

/// A `Done` inside a sub-dialog is not the end of the dialog — it hands the
/// result back to the window that started the sub.
fn done_edges(
  from: String,
  label: String,
  starters: Dict(String, List(String)),
) -> List(Edge) {
  let returns = case split_namespace(from) {
    #(Some(sub_id), _) -> dict.get(starters, sub_id) |> result_unwrap_list
    #(None, _) -> []
  }
  case returns {
    [] -> [Edge(from:, to: done_id, label:, kind: Probed)]
    parents ->
      list.map(parents, fn(parent) {
        Edge(from:, to: parent, label: label <> " ▸ return", kind: Probed)
      })
  }
}

fn result_unwrap_list(result: Result(List(a), Nil)) -> List(a) {
  case result {
    Ok(value) -> value
    Error(Nil) -> []
  }
}

fn split_namespace(id: String) -> #(Option(String), String) {
  case string.split_once(id, dialog_engine.sub_separator) {
    Ok(#(prefix, rest)) -> #(Some(prefix), rest)
    Error(Nil) -> #(None, id)
  }
}

fn external_id(url: String) -> String {
  "__url:" <> url
}

// Flows -----------------------------------------------------------------------

/// A type-erased description of a flow: everything the builder knows
/// declaratively, with step types already rendered to strings.
type FlowDesc {
  FlowDesc(
    name: String,
    steps: List(String),
    initial: String,
    conditionals: List(#(String, List(String), String)),
    parallels: List(#(String, List(String), String)),
    subflows: List(#(String, FlowDesc, String)),
    declared: List(flow_types.DeclaredTransition),
  )
}

const max_subflow_depth = 3

/// Build the declarative skeleton of a flow: steps, conditional branches,
/// parallel fan-out/join and subflows.
///
/// Transitions returned by step handlers (`Next`, `GoTo`, `Complete`) are not
/// visible here — handlers are effectful and are never called. Steps with no
/// declared outgoing edge are marked `OpaqueNode`.
pub fn of_flow(
  flow flow: flow_types.Flow(step_type, session, error, dependencies),
) -> Graph {
  let desc = describe(flow)
  let #(nodes, edges) = desc_graph(desc, "")
  finish(
    Graph(
      name: desc.name,
      nodes: [
        Node(id: entry_id, label: desc.name, kind: EntryNode, group: None),
        ..nodes
      ],
      edges: [
        Edge(from: entry_id, to: desc.initial, label: "start", kind: Declared),
        ..edges
      ],
    ),
  )
}

fn describe(
  flow: flow_types.Flow(step_type, session, error, dependencies),
) -> FlowDesc {
  FlowDesc(
    name: flow.name,
    steps: dict.keys(flow.steps),
    initial: flow.step_to_string(flow.initial_step),
    conditionals: list.map(flow.conditionals, fn(conditional) {
      #(
        conditional.from,
        list.map(conditional.conditions, fn(condition) {
          flow.step_to_string(condition.1)
        }),
        flow.step_to_string(conditional.default),
      )
    }),
    parallels: list.map(flow.parallel_configs, fn(config) {
      #(
        config.trigger_step,
        list.map(config.parallel_steps, flow.step_to_string),
        flow.step_to_string(config.join_step),
      )
    }),
    subflows: list.map(flow.subflows, fn(subflow) {
      #(
        subflow.trigger_step,
        describe_dynamic(subflow.flow, max_subflow_depth),
        flow.step_to_string(subflow.return_step),
      )
    }),
    declared: flow.declared_transitions,
  )
}

/// The same description for an already type-erased subflow. Kept separate from
/// `describe` because a single function cannot recurse at two different step
/// types.
fn describe_dynamic(
  flow: flow_types.Flow(Dynamic, session, error, dependencies),
  depth: Int,
) -> FlowDesc {
  FlowDesc(
    name: flow.name,
    steps: dict.keys(flow.steps),
    initial: flow.step_to_string(flow.initial_step),
    conditionals: list.map(flow.conditionals, fn(conditional) {
      #(
        conditional.from,
        list.map(conditional.conditions, fn(condition) {
          flow.step_to_string(condition.1)
        }),
        flow.step_to_string(conditional.default),
      )
    }),
    parallels: list.map(flow.parallel_configs, fn(config) {
      #(
        config.trigger_step,
        list.map(config.parallel_steps, flow.step_to_string),
        flow.step_to_string(config.join_step),
      )
    }),
    subflows: case depth <= 0 {
      True -> []
      False ->
        list.map(flow.subflows, fn(subflow) {
          #(
            subflow.trigger_step,
            describe_dynamic(subflow.flow, depth - 1),
            flow.step_to_string(subflow.return_step),
          )
        })
    },
    declared: flow.declared_transitions,
  )
}

fn desc_graph(desc: FlowDesc, prefix: String) -> #(List(Node), List(Edge)) {
  let group = case prefix {
    "" -> None
    _ -> Some(desc.name)
  }
  let qualify = fn(step) { prefix <> step }

  let step_nodes =
    list.map(desc.steps, fn(step) {
      Node(id: qualify(step), label: step, kind: StepNode, group:)
    })

  let conditional_edges =
    list.flat_map(desc.conditionals, fn(conditional) {
      let #(from, targets, fallback) = conditional
      let branches =
        list.index_map(targets, fn(target, index) {
          Edge(
            from: qualify(from),
            to: qualify(target),
            label: "if #" <> int.to_string(index + 1),
            kind: Declared,
          )
        })
      [
        Edge(
          from: qualify(from),
          to: qualify(fallback),
          label: "else",
          kind: Declared,
        ),
        ..branches
      ]
    })

  let parallel_edges =
    list.flat_map(desc.parallels, fn(config) {
      let #(trigger, steps, join) = config
      list.flat_map(steps, fn(step) {
        [
          Edge(
            from: qualify(trigger),
            to: qualify(step),
            label: "parallel",
            kind: Declared,
          ),
          Edge(
            from: qualify(step),
            to: qualify(join),
            label: "join",
            kind: Declared,
          ),
        ]
      })
    })

  let #(sub_nodes, sub_edges) =
    list.fold(desc.subflows, #([], []), fn(acc, subflow) {
      let #(trigger, sub, return_step) = subflow
      let sub_prefix = sub.name <> "."
      let #(nodes, edges) = desc_graph(sub, sub_prefix)
      let return_node =
        Node(
          id: sub_prefix <> "__return",
          label: "return",
          kind: TerminalNode,
          group: Some(sub.name),
        )
      let wiring = [
        Edge(
          from: qualify(trigger),
          to: sub_prefix <> sub.initial,
          label: "subflow " <> sub.name,
          kind: Declared,
        ),
        Edge(
          from: sub_prefix <> "__return",
          to: qualify(return_step),
          label: "return",
          kind: Declared,
        ),
      ]
      #(
        list.append(acc.0, [return_node, ..nodes]),
        list.append(acc.1, list.append(edges, wiring)),
      )
    })

  let declared_edges =
    list.flat_map(desc.declared, fn(declared) {
      list.map(declared.targets, fn(target) {
        case target {
          flow_types.ToStep(step) ->
            Edge(
              from: qualify(declared.from),
              to: qualify(step),
              label: "next",
              kind: Declared,
            )
          flow_types.ToComplete ->
            Edge(
              from: qualify(declared.from),
              to: complete_id,
              label: "complete",
              kind: Declared,
            )
          flow_types.ToCancel ->
            Edge(
              from: qualify(declared.from),
              to: cancel_id,
              label: "cancel",
              kind: Declared,
            )
        }
      })
    })

  let edges =
    conditional_edges
    |> list.append(parallel_edges)
    |> list.append(declared_edges)
    |> list.append(sub_edges)
  let nodes = list.append(step_nodes, sub_nodes)

  #(mark_opaque(nodes, edges), edges)
}

/// A step with no declared outgoing edge navigates from inside its handler.
fn mark_opaque(nodes: List(Node), edges: List(Edge)) -> List(Node) {
  list.map(nodes, fn(node) {
    case node.kind {
      StepNode ->
        case list.any(edges, fn(edge) { edge.from == node.id }) {
          True -> node
          False -> Node(..node, kind: OpaqueNode)
        }
      _ -> node
    }
  })
}

// Normalization ---------------------------------------------------------------

/// Add the synthetic nodes the edges reference, drop duplicates, merge parallel
/// edges into one labelled edge and sort everything for stable output.
fn finish(graph: Graph) -> Graph {
  let edges = merge_edges(graph.edges) |> drop_covered_declarations
  let nodes =
    graph.nodes
    |> list.append(synthetic_nodes(edges))
    |> dedupe_nodes
    |> sort_nodes
  Graph(name: graph.name, nodes:, edges:)
}

/// A widget's declared `goto_targets` duplicate the edge its own event probe
/// already found (a `multiselect` "done" button is both). Keep the probed one:
/// it carries the button that triggers it. The declaration survives whenever
/// probing missed the target — e.g. a "done" button hidden until enough items
/// are selected.
fn drop_covered_declarations(edges: List(Edge)) -> List(Edge) {
  let probed =
    edges
    |> list.filter(fn(edge) { edge.kind == Probed })
    |> list.map(fn(edge) { edge.from <> "\u{0}" <> edge.to })
  list.filter(edges, fn(edge) {
    case edge.kind {
      Declared -> !list.contains(probed, edge.from <> "\u{0}" <> edge.to)
      _ -> True
    }
  })
}

fn synthetic_nodes(edges: List(Edge)) -> List(Node) {
  list.flat_map(edges, fn(edge) {
    case edge.to {
      to if to == done_id -> [
        Node(id: done_id, label: "done", kind: TerminalNode, group: None),
      ]
      to if to == back_id -> [
        Node(id: back_id, label: "back", kind: TerminalNode, group: None),
      ]
      to if to == complete_id -> [
        Node(
          id: complete_id,
          label: "complete",
          kind: TerminalNode,
          group: None,
        ),
      ]
      to if to == cancel_id -> [
        Node(id: cancel_id, label: "cancel", kind: TerminalNode, group: None),
      ]
      to ->
        case string.starts_with(to, "__url:") {
          True -> [
            Node(
              id: to,
              label: string.drop_start(to, 6),
              kind: ExternalNode,
              group: None,
            ),
          ]
          False -> []
        }
    }
  })
}

fn dedupe_nodes(nodes: List(Node)) -> List(Node) {
  list.fold(nodes, #(dict.new(), []), fn(acc, node) {
    let #(seen, kept) = acc
    case dict.has_key(seen, node.id) {
      True -> acc
      False -> #(dict.insert(seen, node.id, Nil), [node, ..kept])
    }
  }).1
  |> list.reverse
}

fn sort_nodes(nodes: List(Node)) -> List(Node) {
  list.sort(nodes, fn(left, right) {
    case int.compare(node_rank(left), node_rank(right)) {
      order if order == Eq -> compare_group_then_id(left, right)
      order -> order
    }
  })
}

fn compare_group_then_id(left: Node, right: Node) -> Order {
  case string.compare(group_key(left), group_key(right)) {
    Eq -> string.compare(left.id, right.id)
    order -> order
  }
}

fn group_key(node: Node) -> String {
  option.unwrap(node.group, "")
}

fn node_rank(node: Node) -> Int {
  case node.kind {
    EntryNode -> 0
    StepNode -> 1
    InputNode -> 1
    OpaqueNode -> 1
    TerminalNode -> 2
    ExternalNode -> 3
  }
}

fn merge_edges(edges: List(Edge)) -> List(Edge) {
  edges
  |> list.fold(dict.new(), fn(acc, edge) {
    let key = edge.from <> "\u{0}" <> edge.to <> "\u{0}" <> kind_key(edge.kind)
    dict.upsert(acc, key, fn(existing) {
      case existing {
        Some(#(kept, labels)) -> #(kept, [edge.label, ..labels])
        None -> #(edge, [edge.label])
      }
    })
  })
  |> dict.values
  |> list.map(fn(entry) {
    let #(edge, labels) = entry
    Edge(..edge, label: join_labels(labels))
  })
  |> list.sort(fn(left, right) {
    case string.compare(left.from, right.from) {
      Eq ->
        case string.compare(left.to, right.to) {
          Eq -> string.compare(left.label, right.label)
          order -> order
        }
      order -> order
    }
  })
}

fn kind_key(kind: EdgeKind) -> String {
  case kind {
    Declared -> "declared"
    Probed -> "probed"
    Unknown -> "unknown"
  }
}

fn join_labels(labels: List(String)) -> String {
  let unique =
    labels
    |> list.filter(fn(label) { label != "" })
    |> list.unique
    |> list.sort(string.compare)
  case list.length(unique) > max_merged_labels {
    True ->
      unique
      |> list.take(max_merged_labels)
      |> string.join(label_sep)
      |> string.append("…")
    False -> string.join(unique, label_sep)
  }
}

// Rendering -------------------------------------------------------------------

/// Render the graph as Graphviz DOT. Pipe it to `dot -Tsvg`.
pub fn to_dot(graph graph: Graph) -> String {
  let header =
    "digraph \""
    <> dot_escape(graph.name)
    <> "\" {\n"
    <> "  rankdir=LR;\n"
    <> "  node [shape=box, style=rounded, fontname=\"Helvetica\"];\n"
    <> "  edge [fontname=\"Helvetica\", fontsize=10];\n"

  let #(grouped, plain) =
    list.partition(graph.nodes, fn(node) { node.group != None })

  let plain_lines =
    plain
    |> list.map(fn(node) { "  " <> dot_node(node) })
    |> string.join("\n")

  let cluster_lines =
    grouped
    |> group_by_name
    |> list.map(fn(entry) {
      let #(name, nodes) = entry
      "  subgraph \"cluster_"
      <> dot_escape(name)
      <> "\" {\n    label=\""
      <> dot_escape(name)
      <> "\";\n    style=dashed;\n    color=\"#999999\";\n"
      <> {
        nodes
        |> list.map(fn(node) { "    " <> dot_node(node) })
        |> string.join("\n")
      }
      <> "\n  }"
    })
    |> string.join("\n")

  let edge_lines =
    graph.edges
    |> list.map(fn(edge) {
      "  \""
      <> dot_escape(edge.from)
      <> "\" -> \""
      <> dot_escape(edge.to)
      <> "\" [label=\""
      <> dot_escape(edge.label)
      <> "\""
      <> dot_edge_style(edge.kind)
      <> "];"
    })
    |> string.join("\n")

  [header, plain_lines, cluster_lines, "", edge_lines, "}\n"]
  |> list.filter(fn(part) { part != "" })
  |> string.join("\n")
}

fn dot_node(node: Node) -> String {
  "\""
  <> dot_escape(node.id)
  <> "\" [label=\""
  <> dot_escape(node.label)
  <> "\""
  <> dot_node_style(node.kind)
  <> "];"
}

fn dot_node_style(kind: NodeKind) -> String {
  case kind {
    EntryNode -> ", shape=circle, style=filled, fillcolor=\"#d9e8ff\""
    StepNode -> ""
    InputNode -> ", style=\"rounded,filled\", fillcolor=\"#eef6ec\""
    OpaqueNode -> ", style=\"rounded,dashed\", color=\"#999999\""
    TerminalNode -> ", shape=doublecircle, style=filled, fillcolor=\"#f2f2f2\""
    ExternalNode -> ", shape=note, color=\"#999999\""
  }
}

fn dot_edge_style(kind: EdgeKind) -> String {
  case kind {
    Declared -> ""
    Probed -> ", color=\"#555555\""
    Unknown -> ", style=dashed, color=\"#999999\""
  }
}

fn dot_escape(value: String) -> String {
  value
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
  |> string.replace("\n", "\\n")
}

/// Render the graph as a Mermaid `flowchart`. Renders inline in GitHub and in
/// the docs without a local Graphviz.
pub fn to_mermaid(graph graph: Graph) -> String {
  let ids =
    graph.nodes
    |> list.index_map(fn(node, index) {
      #(node.id, "n" <> int.to_string(index))
    })
    |> dict.from_list
  let short = fn(id) { dict.get(ids, id) |> unwrap_or(id) }

  let #(grouped, plain) =
    list.partition(graph.nodes, fn(node) { node.group != None })

  let plain_lines =
    plain
    |> list.map(fn(node) { "  " <> mermaid_node(node, short(node.id)) })
    |> string.join("\n")

  let cluster_lines =
    grouped
    |> group_by_name
    |> list.index_map(fn(entry, index) {
      let #(name, nodes) = entry
      "  subgraph g"
      <> int.to_string(index)
      <> "[\""
      <> mermaid_escape(name)
      <> "\"]\n"
      <> {
        nodes
        |> list.map(fn(node) { "    " <> mermaid_node(node, short(node.id)) })
        |> string.join("\n")
      }
      <> "\n  end"
    })
    |> string.join("\n")

  let edge_lines =
    graph.edges
    |> list.map(fn(edge) {
      let arrow = case edge.kind {
        Unknown -> " -.->"
        _ -> " -->"
      }
      "  "
      <> short(edge.from)
      <> arrow
      <> case edge.label {
        "" -> " "
        label -> "|\"" <> mermaid_escape(label) <> "\"| "
      }
      <> short(edge.to)
    })
    |> string.join("\n")

  ["flowchart LR", plain_lines, cluster_lines, edge_lines]
  |> list.filter(fn(part) { part != "" })
  |> string.join("\n")
  <> "\n"
}

fn mermaid_node(node: Node, id: String) -> String {
  let label = "\"" <> mermaid_escape(node.label) <> "\""
  case node.kind {
    EntryNode -> id <> "([" <> label <> "])"
    TerminalNode -> id <> "([" <> label <> "])"
    InputNode -> id <> "[/" <> label <> "/]"
    OpaqueNode -> id <> "[" <> label <> "]"
    ExternalNode -> id <> ">" <> label <> "]"
    StepNode -> id <> "[" <> label <> "]"
  }
}

fn mermaid_escape(value: String) -> String {
  value
  |> string.replace("\"", "#quot;")
  |> string.replace("\n", " ")
}

fn unwrap_or(result: Result(String, Nil), fallback: String) -> String {
  case result {
    Ok(value) -> value
    Error(Nil) -> fallback
  }
}

fn group_by_name(nodes: List(Node)) -> List(#(String, List(Node))) {
  nodes
  |> list.fold(dict.new(), fn(acc, node) {
    let name = group_key(node)
    dict.upsert(acc, name, fn(existing) {
      case existing {
        Some(kept) -> [node, ..kept]
        None -> [node]
      }
    })
  })
  |> dict.to_list
  |> list.map(fn(entry) { #(entry.0, list.reverse(entry.1)) })
  |> list.sort(fn(left, right) { string.compare(left.0, right.0) })
}
