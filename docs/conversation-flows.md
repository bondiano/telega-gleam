# Conversation Flows

A comprehensive guide to Telega's type-safe, persistent flow system for building multi-step bot interactions.

## Overview

Flows represent structured, multi-step conversations between users and your bot. Unlike simple command-response interactions, flows maintain state across messages, guide users through complex processes, and handle interruptions gracefully.

## Core Concepts

### Flow as State Machine

Each flow is a finite state machine where:

- **Steps** are states in the machine
- **Handlers** define behavior at each state
- **Transitions** move between states based on user input or logic
- **State** persists automatically between messages
- **Typesafe** - each step is a variant in your ADT

### Persistence and Isolation

- **Per-User Isolation**: Each user has their own flow instance
- **Automatic Persistence**: State saves after each step
- **Resilient to Restarts**: Flows resume exactly where they left off
- **Concurrent Execution**: Multiple users can be in the same flow simultaneously

## Architecture

### Flow Registry Pattern

```text
FlowRegistry
├── Triggered Flows
│   ├── Command Triggers (/start, /help)
│   ├── Callback Triggers (button presses)
│   └── Pattern Triggers (text matching)
└── Callable Flows
    └── Registered flows callable via call_flow(ctx, registry, name, data)
```

**Note**: There are no global flows. All flow calls require passing the registry explicitly.

### Integration Pipeline

1. **Registration Phase**: Flows register with triggers in FlowRegistry
2. **Router Integration**: Registry applies all flows to the router
3. **Auto-Resume Setup**: Registry-aware handlers automatically resume interrupted flows
4. **Runtime Execution**: Messages route to active flows or trigger new ones

```gleam
// Example of registry-based integration
let flow_registry =
  flow.new_registry()
  |> flow.register(flow.OnCommand("/start"), registration_flow)
  |> flow.register_callable(helper_flow)

let router =
  router.new("MyBot")
  |> flow.apply_to_router(flow_registry)
```

## Flow Lifecycle

### Creation

Flows start when triggered by:

- Commands (`/start`, `/checkout`)
- Callbacks (inline keyboard buttons)
- Text patterns
- Programmatic calls from handlers (requires registry)

```gleam
// Calling a flow from a handler
fn my_handler(ctx, registry, data) {
  let initial_data = dict.from_list([
    #("user_id", "123"),
    #("action", "checkout")
  ])
  flow.call_flow(ctx, registry, "checkout_flow", initial_data)
}
```

### Execution

1. User triggers flow
2. System creates isolated instance
3. Initial step handler executes
4. Flow waits for user input
5. Input resumes flow at next step
6. Process repeats until completion or cancellation

### Termination

Flows end through:

- **Completion**: Reaching a terminal step
- **Cancellation**: User cancels or timeout occurs
- **Error**: Unrecoverable error in handler

## State Management

### Flow State Types

#### Persistent State (`state.data`)

- Survives across all steps
- Stores collected user data
- Persists to storage backend

#### Scene Data (`scene_data`)

- Temporary per-step storage
- Cleared on step transition
- Useful for validation state

#### Instance Metadata

- User and chat IDs
- Current step
- Creation timestamp
- Wait tokens for resumption

### Storage Abstraction

The storage layer is pluggable via the `FlowStorage` type:

- **Database**: PostgreSQL, MySQL, SQLite
- **Memory**: For development/testing
- **Redis**: For distributed systems
- **Custom**: Implement your own backend

## Navigation Patterns

### Linear Progression

```gleam
flow.next(ctx, instance, NextStep)
```

### Conditional Branching

```gleam
case user_input {
  "yes" -> flow.next(ctx, instance, Confirmed)
  "no" -> flow.next(ctx, instance, Cancelled)
  _ -> flow.repeat(ctx, instance)
}
```

Branch based on user input or business logic.

### Backward Navigation

```gleam
flow.back(ctx, instance)
```

Returns to previous step, useful for corrections.

### Dynamic Navigation

```gleam
flow.goto(ctx, instance, TargetStep)
```

Jump to any step, enabling complex workflows.

## Wait Mechanisms

### Text Input

```gleam
flow.wait(ctx, instance, "unique_token")
```

Pauses flow until user sends any text message.

### Callback Input

```gleam
flow.wait_callback(ctx, instance, "callback_token")
```

Waits for inline keyboard interaction.

### Auto-Resume

When a flow is waiting, any matching input automatically resumes it without explicit commands. The auto-resume handlers are created by the registry during router integration and have access to all registered flows for resumption.

## Error Handling

### Step-Level Errors

Each handler returns `Result` - errors bubble up to flow error handler.

### Flow-Level Error Handler

```gleam
|> flow.on_error(fn(ctx, instance, error) {
  // Log error, notify user, clean up
  Ok(ctx)
})
```

### Recovery Strategies

- **Retry**: Repeat current step
- **Fallback**: Move to error recovery step
- **Cancel**: Terminate flow gracefully
- **Escalate**: Transfer to human operator

## Best Practices

### Design Principles

1. **Single Responsibility**: Each flow handles one business process
2. **Idempotency**: Steps should be safe to repeat
3. **Validation Early**: Validate input before state changes
4. **Clear Navigation**: Users should understand their position
5. **Graceful Degradation**: Handle errors without data loss
6. **Explicit Dependencies**: Pass registry where needed, avoid hidden state

### Implementation Guidelines

- Use ADTs for type-safe step definitions
- Keep handlers focused and testable
- Store minimal state - only what's needed
- Provide clear user feedback at each step
- Implement timeouts for abandoned flows
- Clean up completed flow instances
- Pass registry explicitly to handlers that need to call flows
- Use `register_callable` for flows that are only called programmatically
