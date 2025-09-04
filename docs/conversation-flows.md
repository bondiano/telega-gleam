# Conversation Flows

Structured conversation management with three specialized flow modules - from simple dialogs to complex persistent workflows.

## Flows vs Conversation API

This guide covers **conversation flow modules** that provide structured, high-level abstractions for building complex conversations:

| Concept | Description | Use Case |
|---------|-------------|----------|
| **[Conversation API](./conversation.md)** | Low-level `wait_*` functions (`wait_text`, `wait_command`, etc.) | Simple inline waiting within handlers |
| **Dialog Module** | Immediate Q&A interactions with validation | Simple forms, menus, confirmations |
| **Flow Module** | Multi-step stateful processes with navigation | Registration wizards, surveys |
| **Persistent Flow** | Long-running flows with storage and external integration | Approval workflows, payment processing |

The flow modules are built on top of the Conversation API but provide additional structure, state management, and navigation capabilities.

## Decision Tree

```
Does your conversation need to survive bot restarts?
├── Yes → Use persistent_flow
└── No
    ├── Is it a multi-step process?
    │   ├── Yes → Use flow
    │   └── No → Use dialog
    └── Do you need navigation (back/forward)?
        ├── Yes → Use flow
        └── No → Use dialog
```

## Module 1: Dialog (`telega/conversation/dialog`)

### Purpose

Simple, immediate interactions with users using continuation-passing style.

### Best For

- Quick questions ("What's your name?")
- Menu selections
- Input validation with retries
- Single-message exchanges

### Example Use Cases

- ✅ Asking for user's email
- ✅ Selecting from a list of options
- ❌ Multi-page registration form
- ❌ Shopping cart checkout flow

### Code Example

```gleam
import telega/conversation/dialog

fn handle_subscribe(ctx, _command) {
  use ctx, email <- dialog.ask_validated(
    ctx,
    "Enter your email to subscribe:",
    validate_email,
    retry_prompt: Some("Invalid email format. Please try again:"),
    max_attempts: Some(3),
    timeout: Some(60_000),
  )

  case email {
    Some(e) -> {
      // Save email to database
      reply.with_text(ctx, "Successfully subscribed: " <> e)
    }
    None -> {
      reply.with_text(ctx, "Subscription cancelled")
    }
  }
}
```

## Module 2: Flow (`telega/conversation/flow`)

### Purpose

Multi-step, stateful conversations with navigation capabilities within a single session.

### Best For

- Multi-step forms
- Wizards with multiple pages
- Processes with branching logic
- Data collection across steps
- Flows with back/forward navigation

### Example Use Cases

- ✅ User registration wizard
- ✅ Product configuration flow
- ✅ Survey with multiple questions
- ✅ Booking process with steps
- ❌ Order tracking (needs persistence)
- ❌ Application approval workflow (long-running)

### Code Example

```gleam
import telega/conversation/flow

// Define flow
let booking_flow =
  flow.new("booking", "select_service")
  |> flow.add_step("select_service", fn(ctx, state) {
    // Show service options
    Ok(#(ctx, flow.Next("select_date")))
  })
  |> flow.add_step("select_date", fn(ctx, state) {
    // Show calendar
    Ok(#(ctx, flow.Next("select_time")))
  })
  |> flow.add_step("select_time", fn(ctx, state) {
    // Show time slots
    Ok(#(ctx, flow.Next("confirm")))
  })
  |> flow.add_step("confirm", fn(ctx, state) {
    // Show summary and confirm
    Ok(#(ctx, flow.Complete(state.data)))
  })
  |> flow.on_complete(fn(ctx, data) {
    // Save booking
    Ok(ctx)
  })

// Start flow
use ctx <- flow.start(booking_flow, ctx)
```

## Module 3: Persistent Flow (`telega/conversation/persistent_flow`)

### Purpose

Long-running, persistent conversational flows that survive restarts and support complex business processes with advanced flow control.

### Best For

- Long-running processes (hours/days)
- Flows requiring approval stages
- Multi-user collaborative flows
- Processes with external integrations
- Flows needing audit trails
- Business-critical workflows
- External system integration
- Complex navigation patterns

### Example Use Cases

- ✅ Job application process
- ✅ Loan application workflow
- ✅ Document verification flow
- ✅ Multi-day tournament registration
- ✅ Customer support ticket flow
- ✅ Order fulfillment tracking
- ✅ External approval workflows
- ✅ Payment processing with callbacks

### Key Features

#### Persistence Without Timeouts

Persistent flows are designed to be truly persistent - they don't expire automatically and must be explicitly completed or cancelled. This ensures that important business processes aren't interrupted by arbitrary timeouts.

#### Flow Actions

- `StandardAction(flow.FlowAction)` - Standard navigation (Next, Back, Jump, Complete, Cancel)
- `Wait(token)` - Pause flow with resumption token for external processes
- `Goto(label)` - Jump directly to any step
- `Call(flow_name, args)` - Call another flow with arguments and return handling
- `Exit(result)` - Exit flow with optional result data

#### Scene Data
Isolated data storage per scene/step:
- `store_scene_data(instance, key, value)` - Store local data
- `get_scene_data(instance, key)` - Retrieve local data
- `clear_scene_data(instance)` - Clear all scene data

### Code Examples

#### Basic Persistent Flow

```gleam
import telega/conversation/persistent_flow as pflow

// Create flow with storage
let application_flow =
  pflow.new("job_application", "start", storage)
  |> pflow.add_step("start", collect_personal_info)
  |> pflow.add_step("experience", collect_experience)
  |> pflow.add_step("documents", upload_documents)
  |> pflow.add_step("review", review_application)
  |> pflow.on_complete(submit_to_hr)
  |> pflow.on_error(log_and_recover)

// Start or resume for user
use ctx <- pflow.start_or_resume(
  application_flow,
  ctx,
  user_id: ctx.update.from_id,
  chat_id: ctx.update.chat_id,
)
```

#### External Integration with Wait/Resume

```gleam
// Flow that integrates with external approval system
let approval_flow =
  pflow.new("approval", "submit", storage)
  |> pflow.add_step("submit", fn(ctx, instance) {
    // Collect data and submit
    let token = pflow.generate_wait_token(instance)
    send_to_external_system(token, instance.state.data)
    reply.with_text(ctx, "Your request has been submitted. You'll be notified when approved.")
    Ok(#(ctx, pflow.Wait(token), instance))
  })
  |> pflow.add_step("approved", fn(ctx, instance) {
    reply.with_text(ctx, "✅ Your request has been approved!")
    Ok(#(ctx, pflow.StandardAction(flow.Complete(instance.state.data)), instance))
  })
  |> pflow.add_step("rejected", fn(ctx, instance) {
    let reason = pflow.get_scene_data(instance, "rejection_reason")
    reply.with_text(ctx, "❌ Request rejected: " <> option.unwrap(reason, "No reason provided"))
    Ok(#(ctx, pflow.Exit(None), instance))
  })

// External system callback to resume flow
pub fn handle_external_callback(token: String, approved: Bool, reason: Option(String)) {
  use ctx <- pflow.resume_with_token(
    approval_flow,
    ctx,
    token,
    Some(dict.from_list([
      #("status", case approved { True -> "approved" False -> "rejected" }),
      #("rejection_reason", option.unwrap(reason, "")),
    ])),
  )
}
```

#### Using Scene Data

```gleam
fn multi_input_step(ctx, instance) {
  // Store temporary data in scene
  let instance = pflow.store_scene_data(instance, "draft_message", user_input)

  // Check if all required data collected
  case pflow.get_scene_data(instance, "draft_message") {
    Some(message) -> {
      // Process and move to next scene
      let instance = pflow.clear_scene_data(instance)
      Ok(#(ctx, pflow.Goto("review"), instance))
    }
    None -> {
      // Ask for input
      reply.with_text(ctx, "Please enter your message:")
      Ok(#(ctx, pflow.StandardAction(flow.Next("multi_input")), instance))
    }
  }
}
```

#### Complex Navigation with Goto and Call

```gleam
fn navigation_step(ctx, instance) {
  case user_choice {
    "skip" -> Ok(#(ctx, pflow.Goto("finish"), instance))
    "help" -> {
      // Call another flow and return here when done
      Ok(#(ctx, pflow.Call("help_flow", dict.from_list([#("context", "main_flow")])), instance))
    }
    "back" -> Ok(#(ctx, pflow.StandardAction(flow.Back), instance))
    _ -> Ok(#(ctx, pflow.StandardAction(flow.Next("process")), instance))
  }
}
```

#### Flow Registry and Call/Return Pattern

```gleam
// Register multiple flows
let registry = pflow.new_registry()
  |> pflow.register_flow("main_flow", main_flow)
  |> pflow.register_flow("help_flow", help_flow)
  |> pflow.register_flow("auth_flow", auth_flow)

// Main flow can call other registered flows
fn require_auth_step(ctx, instance) {
  case is_authenticated(instance) {
    True -> Ok(#(ctx, pflow.StandardAction(flow.Next("continue")), instance))
    False -> {
      // Call auth flow and return here after authentication
      Ok(#(ctx, pflow.Call("auth_flow", dict.new()), instance))
    }
  }
}

// Called flow can return to caller
fn auth_complete_step(ctx, instance) {
  // Return to the calling flow
  Ok(#(ctx, pflow.Exit(Some(dict.from_list([#("authenticated", "true")]))), instance))
}
```

## Migration Path

### From Dialog to Flow

When your dialog-based interaction grows beyond simple Q&A:

```gleam
// Before (dialog)
use ctx, name <- dialog.ask(ctx, "Name?", None)
use ctx, email <- dialog.ask(ctx, "Email?", None)
// Can't go back, no state

// After (flow)
flow.new("registration", "name")
|> flow.add_step("name", ask_name)
|> flow.add_step("email", ask_email)
// Can navigate back, maintains state
```

### From Flow to Persistent Flow

When your flow needs to survive restarts or handle long durations:

```gleam
// Before (flow)
flow.new("application", "start")
// Lost on restart

// After (persistent_flow)
pflow.new("application", "start", storage)
// Survives restarts, truly persistent
```

## Best Practices

### General Guidelines

1. **Start Simple**: Begin with dialog, upgrade as needed
2. **Consider User Experience**: Long flows need save points
3. **Handle Errors Gracefully**: Always provide fallback options
4. **Manage Flow Lifecycle**: Implement proper cleanup strategies
5. **Test Edge Cases**: Network failures, restarts, concurrent access

### Dialog Best Practices

- Keep interactions short (1-3 questions max)
- Provide clear validation messages
- Always offer a way to cancel
- Use appropriate timeouts

### Flow Best Practices

- Design clear step names
- Implement proper navigation
- Validate data before transitions
- Clean up on cancellation
- Keep flows under 10 steps

### Persistent Flow Best Practices

- Implement robust storage layer
- Use database transactions
- Design proper flow completion strategies
- Log all state transitions
- Implement manual cleanup when needed
- Handle concurrent updates
- Provide flow status to users
- Use wait tokens for external integrations
- Clear scene data when changing contexts
- Store only essential data in flow state
- Use flow registry for multi-flow applications
- Implement proper return handling for called flows

## Common Pitfalls

### Dialog Pitfalls

- ❌ Trying to build complex flows
- ❌ No state between messages
- ❌ Can't resume after errors

### Flow Pitfalls

- ❌ State lost on restart
- ❌ No built-in persistence
- ❌ No external integration support

### Persistent Flow Pitfalls

- ❌ Over-engineering simple interactions
- ❌ Not handling storage failures
- ❌ Forgetting manual cleanup strategies
- ❌ Not tracking abandoned flows
- ❌ Forgetting to handle Wait token validation
- ❌ Not clearing scene data between contexts
- ❌ Circular flow calls without exit conditions
- ❌ Not registering flows before calling them
- ❌ Missing return handlers for called flows

## Integration Examples

### Combining Modules

You can combine modules for different parts of your bot:

```gleam
// Use dialog for quick settings
fn handle_settings(ctx, _) {
  use ctx, choice <- dialog.select_menu(
    ctx,
    "Settings:",
    [#("Profile", "profile"), #("Notifications", "notif")],
    None,
  )
  // ...
}

// Use flow for profile setup
fn handle_profile_setup(ctx, _) {
  use ctx <- flow.start(profile_flow, ctx)
  // ...
}

// Use persistent_flow for applications
fn handle_application(ctx, _) {
  use ctx <- pflow.start_or_resume(
    application_flow,
    ctx,
    user_id,
    chat_id,
  )
  // ...
}
```

## Advanced Persistent Flow Features

### Wait/Resume Pattern

Perfect for integrating with external systems:
- Payment gateways
- Approval workflows
- Email verification
- SMS OTP validation

### Scene Data Pattern

Useful for:
- Temporary form data
- Draft messages
- Validation errors
- UI state

### Flow Composition with Call

The Call action enables powerful flow composition patterns:
- **Reusable sub-flows**: Authentication, payment, address collection
- **Help flows**: Context-aware help that returns to original flow
- **Error recovery flows**: Standardized error handling
- **Conditional flows**: Dynamic flow selection based on state

Key points:
- Called flows can return data via `Exit(result)`
- Calling flow automatically resumes after called flow completes
- Flow state is preserved across calls
- Flows must be registered in the same registry

## Performance Considerations

| Module | Memory Usage | Storage I/O | Latency |
|--------|-------------|-------------|---------|
| dialog | Low | None | Minimal |
| flow | Medium | None | Minimal |
| persistent_flow | Low-Medium | High | Higher |

## Conclusion

Choose your conversation module based on:

- **Complexity**: How many steps and branches?
- **Duration**: Seconds, minutes, hours, or days?
- **Persistence**: Must survive restarts?
- **Scale**: How many concurrent conversations?
- **User Experience**: Need navigation and resume?
- **Integration**: External systems involved?
- **Flow Control**: Need advanced navigation (Goto, Call, Exit)?

### Quick Decision Guide

| Requirement | Dialog | Flow | Persistent Flow |
|------------|--------|------|----------------|
| Simple Q&A | ✅ | ⚠️ | ❌ |
| Multi-step forms | ❌ | ✅ | ✅ |
| Navigation (Back/Forward) | ❌ | ✅ | ✅ |
| Survive restarts | ❌ | ❌ | ✅ |
| External integration | ❌ | ❌ | ✅ |
| Wait for callbacks | ❌ | ❌ | ✅ |
| Scene-local data | ❌ | ❌ | ✅ |
| Complex navigation | ❌ | ⚠️ | ✅ |
