# Conversational Flows in Telega

Telega provides two complementary systems for building conversational bot interactions:

## Dialog vs Flow: Quick Comparison

| Feature | Dialog | Flow |
|---------|--------|------|
| **Complexity** | Simple Q&A | Multi-step workflows |
| **Persistence** | Memory only | External storage |
| **Restarts** | Lost on restart | Survives restarts |
| **Multi-user** | Single session | Isolated instances |
| **Duration** | Minutes | Hours/days |
| **Use Case** | Quick interactions | Complex processes |

## Decision Tree

```
Does your conversation need to survive bot restarts?
├── Yes → Use Flow Module
└── No
    ├── Is it a multi-step process?
    │   ├── Yes → Use Flow Module
    │   └── No → Use Dialog Module
    └── Do you need navigation (back/forward)?
        ├── Yes → Use Flow Module
        └── No → Use Dialog Module
```

## Dialog Module

**Best for**: Simple, immediate conversations within a single handler.

```gleam
import telega/conversation/dialog
import telega/reply

fn name_handler(ctx, _) {
  use ctx, name <- dialog.ask(ctx, "What's your name?", None)
  use ctx, age <- dialog.ask(ctx, "How old are you?", None)

  let message = "Hello " <> name <> ", you are " <> age <> " years old!"
  reply.with_text(ctx, message)
}
```

**Features:**

- Continuation-passing style for sequential questions
- Built-in validation with retry logic
- Menu selections with inline keyboards
- Automatic timeout handling
- Simple and lightweight

## Flow Module

**Best for**: Complex, persistent workflows that span multiple sessions.

```gleam
import telega/flow
import telega/reply
import gleam/string

fn create_registration_flow(storage) {
  flow.new("registration", "welcome", storage)
  |> flow.add_step("welcome", welcome_step)
  |> flow.add_step("collect_name", collect_name_step)
  |> flow.add_step("collect_email", collect_email_step)
  |> flow.add_step("confirm", confirm_step)
  |> flow.on_complete(registration_complete)
  |> flow.on_error(handle_error)
}

fn collect_name_step(ctx, instance) {
  case flow.get_scene_data(instance, "name") {
    Some(name) ->
      case string.length(name) >= 2 {
        True -> flow.next(ctx, instance, "collect_email")
        False -> ask_for_name(ctx, instance)
      }
    None -> ask_for_name(ctx, instance)
  }
}

fn ask_for_name(ctx, instance) {
  case reply.with_text(ctx, "Enter your name:") {
    Ok(_) -> flow.wait(ctx, instance, "name_input_" <> instance.id)
    Error(_) -> flow.cancel(ctx, instance)
  }
}
```

**Features:**

- **Persistent state**: Survives bot restarts
- **Multi-user**: Each user gets isolated flow instances
- **Scene data**: Temporary storage per step
- **Flexible navigation**: Jump, wait, complete, cancel
- **Helper functions**: Reduce boilerplate by ~10x
- **Storage agnostic**: Database, memory, or custom backends

## Key Concepts in Flows

### Flow Actions

- `flow.next(ctx, instance, "step")` - Move to next step
- `flow.complete(ctx, instance)` - Finish with success
- `flow.cancel(ctx, instance)` - Cancel the flow
- `flow.wait(ctx, instance, token)` - Wait for user input
- `flow.goto(ctx, instance, "step")` - Jump to any step

### Scene Data vs Flow Data

```gleam
// Scene data - temporary, cleared when moving between steps
let instance = flow.store_scene_data(instance, "temp_input", value)
let temp_value = flow.get_scene_data(instance, "temp_input")

// Flow data - persistent throughout the entire flow
let updated_instance = flow.FlowInstance(
  ..instance,
  state: flow.FlowState(
    ..instance.state,
    data: dict.insert(instance.state.data, "user_name", name),
  ),
)
```

### Helper Functions

The flow module includes helper functions that dramatically reduce boilerplate:

```gleam
// Instead of manually constructing results:
Ok(#(ctx, flow.StandardAction(flow.Jump("next_step")), instance))

// Use helpers:
flow.next(ctx, instance, "next_step")

// Other helpers:
flow.complete(ctx, instance)
flow.cancel(ctx, instance)
flow.wait(ctx, instance, token)
flow.next_with_data(ctx, instance, "step", "key", "value")
```

## Storage Backends

Flows require persistent storage. Common implementations:

### Database Storage
```gleam
import pog

pub fn create_database_storage(db: pog.Connection) -> flow.FlowStorage {
  flow.FlowStorage(
    load: fn(flow_id) { sql.load_flow_instance(db, flow_id) },
    save: fn(instance) { sql.save_flow_instance(db, instance) },
    delete: fn(flow_id) { sql.delete_flow_instance(db, flow_id) },
    cleanup: fn(max_age) { sql.cleanup_expired_instances(db, max_age) },
  )
}
```

### Memory Storage (Development)
```gleam
import telega/flow

let memory_storage = flow.create_memory_storage()
```

## Flow Registration and Routing

```gleam
import telega/flow
import telega/router
import gleam/dict

// Register flows in your bot setup
let flows = [
  registration_flow,
  booking_flow,
  support_flow,
]

// In your router
router.command("register", fn(ctx, _) {
  // Start the registration flow for this user
  flow.start_or_resume(
    registration_flow,
    ctx,
    ctx.update.from_id,
    ctx.update.chat_id,
  )
})

// Handle text input for active flows
router.text(router.Any, fn(ctx, data) {
  // Continue any active flow for this user
  flow.handle_text_input(ctx, data.text)
})
```

## Best Practices

### When to Use Dialog

- ✅ Simple form inputs (name, email, age)
- ✅ Quick surveys or feedback
- ✅ Menu selections
- ✅ Single-session interactions
- ✅ Prototype conversations

### When to Use Flow

- ✅ Multi-step registration processes
- ✅ Shopping cart workflows
- ✅ Customer support tickets
- ✅ Long-running wizards
- ✅ Processes that span multiple days
- ✅ Complex state management

### Flow Design Tips

1. **Keep steps focused**: Each step should have a single responsibility
2. **Use scene data**: For temporary validation or processing data
3. **Implement proper validation**: Check inputs before proceeding
4. **Handle errors gracefully**: Always provide error handlers
5. **Use descriptive step names**: Makes debugging easier
6. **Plan your navigation**: Consider all possible user paths

## Example: Restaurant Booking Flow

See the complete example in `examples/06-restaurant-booking/` which demonstrates:

- User registration flow with validation
- Booking flow with date/time selection
- Database persistence
- Error handling
- Multi-step navigation
- Scene data usage

This example shows how flows can handle complex, real-world scenarios with multiple validation steps, database integration, and robust error handling.
