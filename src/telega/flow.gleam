//// Type-safe, persistent flow system for building multi-step conversational interactions.
////
//// This module has been split into focused submodules for maintainability.
//// Import directly from the submodules:
////
//// ## Submodules
////
//// - `telega/flow/types` — All shared type definitions (FlowInstance, FlowAction, WaitResult, etc.)
//// - `telega/flow/instance` — Instance CRUD, accessors, data operations, serialization
//// - `telega/flow/action` — Navigation helpers (next, back, goto, complete, cancel, wait, etc.)
//// - `telega/flow/storage` — Storage utilities (ETS, noop, generate_id)
//// - `telega/flow/builder` — FlowBuilder and flow construction (new, add_step, build, etc.)
//// - `telega/flow/engine` — Core execution engine (internal)
//// - `telega/flow/handler` — Built-in step handlers (text_step, message_step, resume handlers)
//// - `telega/flow/registry` — FlowRegistry and router integration (new_registry, register, apply_to_router)
//// - `telega/flow/compose` — Flow composition (sequential, conditional, parallel, validation_middleware)
////
//// ## Quick Start
////
//// ```gleam
//// import telega/flow/types
//// import telega/flow/builder
//// import telega/flow/action
//// import telega/flow/registry
//// import telega/flow/storage
////
//// // 1. Build flow with handlers
//// let assert Ok(store) = storage.create_ets_storage()
//// let onboarding_flow =
////   builder.new("onboarding", store, step_to_string, string_to_step)
////   |> builder.add_step(Welcome, welcome_handler)
////   |> builder.add_step(CollectName, name_handler)
////   |> builder.build(initial: Welcome)
////
//// // 2. Register and apply to router
//// let flow_registry =
////   registry.new_registry()
////   |> registry.register(types.OnCommand("/start"), onboarding_flow)
////
//// router |> registry.apply_to_router(flow_registry)
//// ```

