# Flows

Flows let you build multi-step conversations. Think of them as isolated rooms where users interact with your bot through a sequence of steps.

## Terminology

| Term | Description |
|------|-------------|
| **Flow** | A finite state machine representing a multi-step conversation |
| **Step** | A state in the flow where the bot waits for user input |
| **Instance** | A user's active session within a flow |
| **Transition** | Moving from one step to another |
| **Subflow** | A flow called from within another flow |

## Quick Start

### 1. Define Steps

Steps are defined as an algebraic data type:

```gleam
pub type RegistrationStep {
  AskName
  AskEmail
  Confirm
}

fn step_to_string(step: RegistrationStep) -> String {
  case step {
    AskName -> "ask_name"
    AskEmail -> "ask_email"
    Confirm -> "confirm"
  }
}

fn string_to_step(s: String) -> Result(RegistrationStep, Nil) {
  case s {
    "ask_name" -> Ok(AskName)
    "ask_email" -> Ok(AskEmail)
    "confirm" -> Ok(Confirm)
    _ -> Error(Nil)
  }
}
```

### 2. Build the Flow

```gleam
let registration_flow =
  flow.new("registration", storage, step_to_string, string_to_step)
  |> flow.add_step(AskName, ask_name_handler)
  |> flow.add_step(AskEmail, ask_email_handler)
  |> flow.add_step(Confirm, confirm_handler)
  |> flow.build(initial: AskName)
```

### 3. Write Step Handlers

Each step handler receives context and instance, returns an action:

```gleam
fn ask_name_handler(ctx, instance) {
  // Check if we already have input
  case flow.get_step_data(instance, "input") {
    Some(name) -> {
      // Store and move to next step
      let instance = flow.store_data(instance, "name", name)
      flow.next(ctx, instance, AskEmail)
    }
    None -> {
      // Ask user and wait
      let _ = reply.with_text(ctx, "What's your name?")
      flow.wait(ctx, instance, "name_input")
    }
  }
}
```

### 4. Register and Apply

```gleam
let registry =
  flow.new_registry()
  |> flow.register(flow.OnCommand("/register"), registration_flow)

let router =
  router.new("MyBot")
  |> flow.apply_to_router(registry)
```

## Navigation

### Basic Transitions

```gleam
// Move to next step
flow.next(ctx, instance, NextStep)

// Go back to previous step
flow.back(ctx, instance)

// Jump to any step
flow.goto(ctx, instance, TargetStep)

// Complete the flow
flow.complete(ctx, instance)

// Cancel the flow
flow.cancel(ctx, instance)
```

### Waiting for Input

```gleam
// Wait for text message
flow.wait(ctx, instance, "unique_token")

// Wait for callback button press
flow.wait_callback(ctx, instance, "callback_token")
```

## State Management

Flows have two types of data storage:

### Flow Data (Persistent)

Survives across all steps. Use for collected user data:

```gleam
// Store
let instance = flow.store_data(instance, "email", "user@example.com")

// Retrieve
case flow.get_data(instance, "email") {
  Some(email) -> // use email
  None -> // not set
}
```

### Step Data (Temporary)

Cleared on each step transition. Use for validation state:

```gleam
// Store temporary data
let instance = flow.store_step_data(instance, "attempts", "2")

// Retrieve
flow.get_step_data(instance, "attempts")

// Clear
flow.clear_step_data(instance)
```

## Callbacks and Buttons

Handle inline keyboard buttons using `wait_callback` and `is_callback_passed`:

```gleam
fn confirm_handler(ctx, instance) {
  case flow.is_callback_passed(instance, "input", "confirm") {
    Some(True) -> flow.complete(ctx, instance)
    Some(False) -> flow.cancel(ctx, instance)
    None -> {
      // Create callback data type
      let callback_data = keyboard.string_callback_data("confirm")

      // Build inline keyboard with callbacks
      let assert Ok(yes_btn) = keyboard.inline_button(
        "✅ Yes",
        keyboard.pack_callback(callback_data, "yes"),
      )
      let assert Ok(no_btn) = keyboard.inline_button(
        "❌ No",
        keyboard.pack_callback(callback_data, "no"),
      )
      let kb = keyboard.new_inline([[yes_btn, no_btn]])

      let _ = reply.with_markup(ctx, "Confirm?", kb)
      flow.wait_callback(ctx, instance, "input")
    }
  }
}
```

## Error Handling

```gleam
flow.new("checkout", storage, step_to_string, string_to_step)
|> flow.add_step(Payment, payment_handler)
|> flow.on_error(fn(ctx, instance, error) {
  let _ = reply.with_text(ctx, "Something went wrong. Please try again.")
  Ok(ctx)
})
|> flow.on_complete(fn(ctx, instance) {
  let _ = reply.with_text(ctx, "Thank you!")
  Ok(ctx)
})
|> flow.build(initial: Payment)
```

## Subflows

Subflows let you reuse flow logic. When a subflow completes, control returns to the parent.

### Defining a Reusable Subflow

```gleam
let address_flow =
  flow.new("address", storage, addr_to_string, string_to_addr)
  |> flow.add_step(Street, street_handler)
  |> flow.add_step(City, city_handler)
  |> flow.add_step(Done, fn(ctx, instance) {
    // Return collected data to parent
    let result = dict.from_list([
      #("street", flow.get_data(instance, "street") |> option.unwrap("")),
      #("city", flow.get_data(instance, "city") |> option.unwrap("")),
    ])
    flow.return_from_subflow(ctx, instance, result)
  })
  |> flow.build(initial: Street)
```

### Using a Subflow

```gleam
let checkout_flow =
  flow.new("checkout", storage, step_to_string, string_to_step)
  |> flow.add_step(Cart, cart_handler)
  |> flow.add_subflow(
      trigger: CollectAddress,
      subflow: address_flow,
      return_to: Payment,
      map_args: fn(instance) { dict.new() },
      map_result: fn(result, instance) {
        FlowInstance(..instance, state: FlowState(
          ..instance.state,
          data: dict.merge(instance.state.data, result)
        ))
      },
    )
  |> flow.add_step(Payment, payment_handler)
  |> flow.build(initial: Cart)
```

### Manual Subflow Entry

```gleam
fn some_handler(ctx, instance) {
  // Enter subflow with initial data
  flow.enter_subflow(ctx, instance, "address", dict.new())
}
```

## Lifecycle Hooks

### Flow Hooks

Called when entering, leaving (to subflow), or exiting a flow:

```gleam
flow.new("onboarding", storage, step_to_string, string_to_step)
|> flow.set_on_flow_enter(fn(ctx, instance) {
  let _ = reply.with_text(ctx, "Welcome!")
  Ok(#(ctx, instance))
})
|> flow.set_on_flow_exit(fn(ctx, instance) {
  let _ = reply.with_text(ctx, "Goodbye!")
  Ok(ctx)
})
```

### Step Hooks

Called before and after individual steps:

```gleam
flow.add_step_with_hooks(
  step: Payment,
  handler: payment_handler,
  on_enter: Some(fn(ctx, instance) {
    let _ = reply.with_text(ctx, "💳 Payment section")
    Ok(#(ctx, instance))
  }),
  on_leave: None,
)
```

## Storage

Flows require a storage backend for persistence. Use the built-in memory storage for development:

```gleam
let storage = flow.create_memory_storage()
```

For production, implement `FlowStorage`:

```gleam
pub type FlowStorage(error) {
  FlowStorage(
    save: fn(FlowInstance) -> Result(Nil, error),
    load: fn(String) -> Result(Option(FlowInstance), error),
    delete: fn(String) -> Result(Nil, error),
    list_by_user: fn(Int, Int) -> Result(List(FlowInstance), error),
  )
}
```

## Complete Example

A simple registration bot:

```gleam
import gleam/dict
import gleam/option.{None, Some}
import telega/flow
import telega/reply

pub type Step {
  Name
  Email
  Done
}

pub fn create_flow(storage) {
  flow.new("register", storage, step_to_string, string_to_step)
  |> flow.add_step(Name, name_step)
  |> flow.add_step(Email, email_step)
  |> flow.add_step(Done, done_step)
  |> flow.on_complete(fn(ctx, _) {
    let _ = reply.with_text(ctx, "✅ Registration complete!")
    Ok(ctx)
  })
  |> flow.build(initial: Name)
}

fn name_step(ctx, instance) {
  case flow.get_step_data(instance, "input") {
    Some(name) -> {
      let instance = flow.store_data(instance, "name", name)
      flow.next(ctx, instance, Email)
    }
    None -> {
      let _ = reply.with_text(ctx, "What's your name?")
      flow.wait(ctx, instance, "name")
    }
  }
}

fn email_step(ctx, instance) {
  case flow.get_step_data(instance, "input") {
    Some(email) -> {
      let instance = flow.store_data(instance, "email", email)
      flow.next(ctx, instance, Done)
    }
    None -> {
      let _ = reply.with_text(ctx, "What's your email?")
      flow.wait(ctx, instance, "email")
    }
  }
}

fn done_step(ctx, instance) {
  let name = flow.get_data(instance, "name") |> option.unwrap("Unknown")
  let email = flow.get_data(instance, "email") |> option.unwrap("Unknown")

  let _ = reply.with_text(ctx,
    "Name: " <> name <> "\nEmail: " <> email
  )
  flow.complete(ctx, instance)
}

fn step_to_string(step) {
  case step {
    Name -> "name"
    Email -> "email"
    Done -> "done"
  }
}

fn string_to_step(s) {
  case s {
    "name" -> Ok(Name)
    "email" -> Ok(Email)
    "done" -> Ok(Done)
    _ -> Error(Nil)
  }
}
```
