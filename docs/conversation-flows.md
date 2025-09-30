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

## Parallel Steps (Advanced)

Parallel steps allow users to complete independent tasks in any order. When a flow reaches a parallel step trigger, it spawns multiple concurrent steps that can be completed independently. The flow automatically transitions to the join step when all parallel steps are completed.

### Use Cases

- **Multi-factor verification**: Email, phone, and document verification in any order
- **KYC onboarding**: Collect multiple documents independently
- **Survey sections**: Users can fill sections in preferred order
- **Multi-step authentication**: Complete authentication factors independently

### Basic Usage

```gleam
pub type VerificationStep {
  Start
  EmailVerify
  PhoneVerify
  DocumentVerify
  AllComplete
}

let kyc_flow =
  flow.new("kyc_verification", storage, step_to_string, string_to_step)
  |> flow.add_step(Start, start_handler)
  |> flow.add_step(EmailVerify, email_verify_handler)
  |> flow.add_step(PhoneVerify, phone_verify_handler)
  |> flow.add_step(DocumentVerify, document_verify_handler)
  |> flow.parallel(
      from: Start,
      steps: [EmailVerify, PhoneVerify, DocumentVerify],
      join: AllComplete,
    )
  |> flow.add_step(AllComplete, complete_handler)
  |> flow.build(initial: Start)
```

### How It Works

1. User reaches `Start` step
2. Flow automatically creates parallel state with 3 pending steps
3. User can complete EmailVerify, PhoneVerify, DocumentVerify in ANY order
4. Bot tracks progress automatically
5. When ALL steps complete → automatically transition to AllComplete

### Step Handlers

Each parallel step handler should complete its task and return normally:

```gleam
fn email_verify_handler(ctx, instance) {
  use ctx <- reply.with_text(ctx, "Enter your email:")

  use ctx, email <- wait_email(
    ctx,
    or: Some(bot.HandleText(fn(ctx, _) {
      reply.with_text(ctx, "Invalid email")
    })),
    timeout: None,
  )

  // Store result in flow data
  let updated_data = dict.insert(instance.state.data, "email", email)
  let updated_instance = flow.update_data(instance, updated_data)

  // Mark this step as complete and continue
  use ctx <- reply.with_text(ctx, "✅ Email verified!")
  Ok(#(ctx, flow.Next(PhoneVerify), updated_instance))
}
```

### Progress Tracking

Users can check their progress at any time:

```gleam
fn show_progress_handler(ctx, instance) {
  case instance.state.parallel_state {
    Some(parallel) -> {
      let total = list.length(parallel.pending_steps) + list.length(parallel.completed_steps)
      let completed = list.length(parallel.completed_steps)

      let message =
        "Verification progress: "
        <> int.to_string(completed)
        <> "/"
        <> int.to_string(total)
        <> "\n\nCompleted: "
        <> string.join(parallel.completed_steps, ", ")
        <> "\n\nPending: "
        <> string.join(parallel.pending_steps, ", ")

      reply.with_text(ctx, message)
    }
    None -> reply.with_text(ctx, "No active verification")
  }
}
```

### Best Practices

1. **Independence**: Ensure parallel steps don't depend on each other's results
2. **Clear feedback**: Show users which steps are complete and which remain
3. **Progress indicators**: Provide visual progress (e.g., "2/3 complete")
4. **Allow any order**: Don't assume completion order
5. **Idempotency**: Allow users to redo completed steps if needed
6. **Timeout handling**: Consider timeouts for abandoned parallel flows

### Deprecated API

The old API `add_parallel_steps()` is deprecated. Use `parallel()` instead:

```gleam
// ❌ Old (deprecated)
|> flow.add_parallel_steps(
    trigger_step: Start,
    parallel_steps: [EmailVerify, PhoneVerify],
    join_at: Complete,
  )

// ✅ New (recommended)
|> flow.parallel(
    from: Start,
    steps: [EmailVerify, PhoneVerify],
    join: Complete,
  )
```

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
