# Flows

Flows are type-safe, persistent state machines for building multi-step conversations. They give your bot structured navigation, persistent state that survives restarts, composable logic, and middleware.

## When to Use Flows

Use flows when you need:

- **Persistent state** — flow progress is saved to storage and survives VM restarts
- **Complex branching** — conditional transitions, parallel execution, subflows
- **Type-safe navigation** — steps are algebraic data types, not strings
- **Reusable logic** — compose flows sequentially, conditionally, or in parallel

For simple multi-message interactions that don't need persistence, the [Conversation API](./conversation.md) may be a better fit.

### Flows vs Conversations

| | Conversations | Flows |
|---|---|---|
| **Persistence** | In-memory (BEAM actor) | Storage backend (ETS, DB, custom) |
| **Survives restart** | No | Yes |
| **Step definition** | Implicit (`wait_*` calls) | Explicit (algebraic data types) |
| **Navigation** | Linear (sequential waits) | Flexible (next, back, goto, conditional) |
| **Composition** | Nested function calls | Sequential, conditional, parallel |
| **Middleware** | No | Yes (per-step and global) |
| **Timeouts** | Per-wait (`timeout:` param) | Per-wait + flow-level TTL |
| **Cancellation** | Not built-in | `/cancel` command, programmatic API |
| **Best for** | Simple forms, quick dialogs | Registration wizards, booking flows, multi-stage processes |

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

> **Why string conversion?** Flows persist state to storage. The `step_to_string` / `string_to_step` functions serialize step types for storage and restore them on resume.

### 2. Build the Flow

```gleam
import telega/flow/builder
import telega/flow/storage

let assert Ok(store) = storage.create_ets_storage()

let registration_flow =
  builder.new("registration", store, step_to_string, string_to_step)
  |> builder.add_step(AskName, ask_name_handler)
  |> builder.add_step(AskEmail, ask_email_handler)
  |> builder.add_step(Confirm, confirm_handler)
  |> builder.build(initial: AskName)
```

### 3. Write Step Handlers

Each step handler receives context and instance, returns an action:

```gleam
import telega/flow/action
import telega/flow/instance

fn ask_name_handler(ctx, inst) {
  // Check if we already have input
  case instance.get_step_data(inst, "user_input") {
    Some(name) -> {
      // Store and move to next step
      let inst = instance.store_data(inst, "name", name)
      action.next(ctx, inst, AskEmail)
    }
    None -> {
      // Ask user and wait
      let _ = reply.with_text(ctx, "What's your name?")
      action.wait(ctx, inst)
    }
  }
}
```

> **The handler pattern:** Every step handler is called twice — first with no input (`None`) to send the prompt, then again with user input (`Some(value)`) when the user responds. This is because flows are persisted: the handler must be re-entrant.

### 4. Register and Apply

```gleam
import telega/flow/registry
import telega/flow/types

let reg =
  registry.new_registry()
  |> registry.register(types.OnCommand("/register"), registration_flow)

let router =
  router.new("MyBot")
  |> registry.apply_to_router(reg)
```

`apply_to_router` automatically sets up resume handlers for all input types (text, callbacks, photos, video, voice, audio, location, commands) — you don't need to wire them manually.

## Navigation

### Basic Transitions

```gleam
import telega/flow/action

// Move to next step
action.next(ctx, instance, NextStep)

// Go back to previous step
action.back(ctx, instance)

// Jump to any step
action.goto(ctx, instance, TargetStep)

// Complete the flow
action.complete(ctx, instance)

// Cancel the flow
action.cancel(ctx, instance)
```

### Conditional Transitions

Define transitions that depend on flow state:

```gleam
builder.new("checkout", storage, step_to_string, string_to_step)
|> builder.add_step(SelectPlan, select_plan_handler)
|> builder.add_step(FreeSetup, free_setup_handler)
|> builder.add_step(Payment, payment_handler)
|> builder.add_step(Done, done_handler)
|> builder.add_conditional(
    from: SelectPlan,
    condition: fn(inst) {
      instance.get_data(inst, "plan") == Some("premium")
    },
    true: Payment,
    false: FreeSetup,
  )
|> builder.build(initial: SelectPlan)
```

For more than two branches, use `add_multi_conditional`:

```gleam
builder.add_multi_conditional(
  from: SelectPlan,
  conditions: [
    #(fn(inst) { instance.get_data(inst, "plan") == Some("free") }, FreeSetup),
    #(fn(inst) { instance.get_data(inst, "plan") == Some("premium") }, Payment),
  ],
  default: FreeSetup,
)
```

### Waiting for Input

```gleam
// Wait for text message (no timeout — waits forever)
action.wait(ctx, instance)

// Wait for callback button press (no timeout)
action.wait_callback(ctx, instance)

// Wait with timeout (expires after given ms)
action.wait_with_timeout(ctx, instance, timeout_ms: 60_000)
action.wait_callback_with_timeout(ctx, instance, timeout_ms: 60_000)
```

See [Timeouts and Cleanup](#timeouts-and-cleanup) for details on expiration behavior.

## State Management

Flows have two types of data storage:

### Flow Data (Persistent)

Survives across all steps. Use for collected user data:

```gleam
import telega/flow/instance

// Store
let inst = instance.store_data(inst, "email", "user@example.com")

// Retrieve
case instance.get_data(inst, "email") {
  Some(email) -> // use email
  None -> // not set
}
```

### Step Data (Temporary)

Cleared on each step transition. Use for validation state:

```gleam
// Store temporary data
let inst = instance.store_step_data(inst, "attempts", "2")

// Retrieve
instance.get_step_data(inst, "attempts")

// Clear
instance.clear_step_data(inst)
```

## Validation

### Input Validation in Steps

Validate user input and retry on failure:

```gleam
fn email_step(ctx, inst) {
  case instance.get_step_data(inst, "user_input") {
    Some(email) -> {
      // Validate the input
      case is_valid_email(email) {
        True -> {
          let inst = instance.store_data(inst, "email", email)
          action.next(ctx, inst, NextStep)
        }
        False -> {
          // Show error and stay on the same step (wait again)
          let _ = reply.with_text(ctx, "Invalid email format. Please try again:")
          action.wait(ctx, inst)
        }
      }
    }
    None -> {
      let _ = reply.with_text(ctx, "What's your email?")
      action.wait(ctx, inst)
    }
  }
}
```

### Retry with Attempt Tracking

```gleam
fn age_step(ctx, inst) {
  case instance.get_step_data(inst, "user_input") {
    Some(input) -> {
      case int.parse(input) {
        Ok(age) if age >= 13 && age <= 120 -> {
          let inst = instance.store_data(inst, "age", input)
          action.next(ctx, inst, NextStep)
        }
        _ -> {
          let attempts =
            instance.get_step_data(inst, "attempts")
            |> option.then(int.parse)
            |> option.unwrap(0)

          case attempts >= 3 {
            True -> {
              let _ = reply.with_text(ctx, "Too many attempts. Cancelling.")
              action.cancel(ctx, inst)
            }
            False -> {
              let inst = instance.store_step_data(inst, "attempts", int.to_string(attempts + 1))
              let _ = reply.with_text(ctx, "Please enter a valid age (13-120):")
              action.wait(ctx, inst)
            }
          }
        }
      }
    }
    None -> {
      let _ = reply.with_text(ctx, "How old are you?")
      action.wait(ctx, inst)
    }
  }
}
```

### Validation Middleware

Apply validation to any step without modifying the handler:

```gleam
import telega/flow/compose

let email_validator = compose.validation_middleware(fn(inst) {
  case instance.get_step_data(inst, "user_input") {
    Some(email) if is_valid_email(email) -> Ok(Nil)
    Some(_) -> Error("Invalid email format")
    None -> Ok(Nil)  // No input yet, let handler prompt
  }
})

builder.add_step_with_middleware(
  builder,
  AskEmail,
  [email_validator],
  ask_email_handler,
)
```

## Callbacks and Buttons

Handle inline keyboard buttons using `wait_callback` and `get_wait_result`:

```gleam
import telega/flow/action
import telega/flow/instance
import telega/flow/types

fn confirm_handler(ctx, inst) {
  case instance.get_wait_result(inst) {
    types.BoolCallback(value: True) -> action.complete(ctx, inst)
    types.BoolCallback(value: False) -> action.cancel(ctx, inst)
    types.Pending -> {
      // Create callback data type
      let callback_data = keyboard.bool_callback_data("confirm")

      // Build inline keyboard with callbacks
      let assert Ok(yes_btn) = keyboard.inline_button(
        "Yes",
        keyboard.pack_callback(callback_data, True),
      )
      let assert Ok(no_btn) = keyboard.inline_button(
        "No",
        keyboard.pack_callback(callback_data, False),
      )
      let kb = keyboard.new_inline([[yes_btn, no_btn]])

      let _ = reply.with_markup(ctx, "Confirm?", keyboard.to_inline_markup(kb))
      action.wait_callback(ctx, inst)
    }
    _ -> action.cancel(ctx, inst)
  }
}
```

The `WaitResult` type provides structured access to what the user sent:

```gleam
pub type WaitResult {
  TextInput(value: String)                       // Text message
  BoolCallback(value: Bool)                      // Yes/No button press
  DataCallback(value: String)                    // Other callback data
  PhotoInput(file_ids: List(String))             // Photo (multiple sizes)
  VideoInput(file_id: String)                    // Video message
  VoiceInput(file_id: String)                    // Voice message
  AudioInput(file_id: String)                    // Audio file
  LocationInput(latitude: Float, longitude: Float) // Location
  CommandInput(command: String, payload: String)  // Bot command
  Pending                                        // No input yet
}
```

All these input types are automatically handled by `registry.apply_to_router` — when a flow is waiting (after `action.wait` or `action.wait_callback`), any matching update will resume it with the appropriate `WaitResult`.

## Built-in Step Handlers

The `telega/flow/handler` module provides ready-made handlers for common patterns.

### `text_step` — Prompt, Wait, Store

Handles the "ask a question → wait for text → store and move on" pattern in one line:

```gleam
import telega/flow/handler

builder.new("booking", storage, step_to_string, string_to_step)
|> builder.add_step(
    Date,
    handler.text_step("Enter date (YYYY-MM-DD):", "booking_date", Time),
  )
|> builder.add_step(
    Time,
    handler.text_step("Enter time (HH:MM):", "booking_time", Guests),
  )
|> builder.add_step(
    Guests,
    handler.text_step("How many guests? (1-12)", "guest_count", Confirm),
  )
```

Parameters: `prompt` (message text), `data_key` (key to store input under), `next_step` (where to go after input).

### `message_step` — Display and Continue

Show a message and optionally transition to the next step:

```gleam
builder.add_step(
  Welcome,
  handler.message_step(
    fn(inst) {
      let name = instance.get_data(inst, "name") |> option.unwrap("there")
      "Welcome, " <> name <> "! Let's get started."
    },
    Some(NextStep),  // or None to complete the flow
  ),
)
```

## Error Handling

### Flow-Level Error Handler

```gleam
builder.new("checkout", storage, step_to_string, string_to_step)
|> builder.add_step(Payment, payment_handler)
|> builder.on_error(fn(ctx, instance, error) {
  let _ = reply.with_text(ctx, "Something went wrong. Please try again.")
  Ok(ctx)
})
|> builder.on_complete(fn(ctx, instance) {
  let _ = reply.with_text(ctx, "Thank you!")
  Ok(ctx)
})
|> builder.build(initial: Payment)
```

### Returning Errors from Steps

Step handlers can return errors directly — they will be caught by `on_error`:

```gleam
fn payment_step(ctx, inst) {
  case process_payment(inst) {
    Ok(receipt) -> action.complete(ctx, inst)
    Error(reason) -> Error("Payment failed: " <> reason)
  }
}
```

## Lifecycle Hooks

### Flow Hooks

Called when entering, leaving (to subflow), or exiting a flow:

```gleam
builder.new("onboarding", storage, step_to_string, string_to_step)
|> builder.set_on_flow_enter(fn(ctx, inst) {
  let _ = reply.with_text(ctx, "Welcome!")
  Ok(#(ctx, inst))
})
|> builder.set_on_flow_exit(fn(ctx, inst) {
  let _ = reply.with_text(ctx, "Goodbye!")
  Ok(ctx)
})
```

### Step Hooks

Called before and after individual steps:

```gleam
builder.add_step_with_hooks(
  step: Payment,
  handler: payment_handler,
  on_enter: Some(fn(ctx, inst) {
    let _ = reply.with_text(ctx, "Payment section")
    Ok(#(ctx, inst))
  }),
  on_leave: None,
)
```

## Middleware

### Per-Step Middleware

Middleware runs before the step handler. It can modify the instance, skip the step, or cancel the flow:

```gleam
builder.add_step_with_middleware(
  builder,
  Payment,
  [auth_middleware, logging_middleware],
  payment_handler,
)
```

### Global Middleware

Applies to every step in the flow:

```gleam
builder.new("checkout", storage, step_to_string, string_to_step)
|> builder.add_global_middleware(fn(ctx, instance, next) {
  // Log every step transition
  logging.log(logging.Info, "Step: " <> instance.state.current_step)
  next()
})
```

## Subflows

Subflows let you reuse flow logic. When a subflow completes, control returns to the parent.

### Defining a Reusable Subflow

```gleam
let address_flow =
  builder.new("address", storage, addr_to_string, string_to_addr)
  |> builder.add_step(Street, street_handler)
  |> builder.add_step(City, city_handler)
  |> builder.add_step(Done, fn(ctx, inst) {
    // Return collected data to parent
    let result = dict.from_list([
      #("street", instance.get_data(inst, "street") |> option.unwrap("")),
      #("city", instance.get_data(inst, "city") |> option.unwrap("")),
    ])
    action.return_from_subflow(ctx, inst, result)
  })
  |> builder.build(initial: Street)
```

### Using a Subflow

```gleam
let checkout_flow =
  builder.new("checkout", storage, step_to_string, string_to_step)
  |> builder.add_step(Cart, cart_handler)
  |> builder.add_subflow(
      trigger_step: CollectAddress,
      subflow: address_flow,
      return_to: Payment,
      map_args: fn(inst) { dict.new() },
      map_result: fn(result, inst) {
        dict.fold(result, inst, fn(i, key, value) {
          instance.store_data(i, key, value)
        })
      },
    )
  |> builder.add_step(Payment, payment_handler)
  |> builder.build(initial: Cart)
```

### Inline Subflows

For subflows that don't need their own step type, use inline subflows:

```gleam
builder.with_inline_subflow(
  name: "address",
  trigger: CollectAddress,
  return_to: Payment,
  initial: "street",
  steps: [
    #("street", fn(ctx, inst) {
      case instance.get_step_data(inst, "user_input") {
        Some(street) -> {
          let inst = instance.store_data(inst, "street", street)
          builder.inline_next(ctx, inst, step_name: "city")
        }
        None -> {
          let _ = reply.with_text(ctx, "Enter your street:")
          Ok(#(ctx, types.Wait, inst))
        }
      }
    }),
    #("city", fn(ctx, inst) {
      case instance.get_step_data(inst, "user_input") {
        Some(city) -> {
          let inst = instance.store_data(inst, "city", city)
          Ok(#(ctx, types.Complete(inst.state.data), inst))
        }
        None -> {
          let _ = reply.with_text(ctx, "Enter your city:")
          Ok(#(ctx, types.Wait, inst))
        }
      }
    }),
  ],
)
```

### Manual Subflow Entry

```gleam
fn some_handler(ctx, inst) {
  // Enter subflow with initial data
  action.enter_subflow(ctx, inst, "address", dict.new())
}
```

## Flow Composition

The `telega/flow/compose` module lets you combine multiple flows into larger workflows.

### Sequential Composition

Run flows one after another. Data from each flow carries over to the next:

```gleam
import gleam/dynamic
import telega/flow/compose

let full_onboarding = compose.compose_sequential(
  "full_onboarding",
  [profile_flow, preferences_flow, tutorial_flow],
  storage,
)
```

### Conditional Composition

Select which flow to run based on instance state:

```gleam
let support_flow = compose.compose_conditional(
  "support",
  fn(inst) {
    case instance.get_data(inst, "issue_type") {
      Some("billing") -> "billing"
      Some("technical") -> "technical"
      _ -> "general"
    }
  },
  dict.from_list([
    #("billing", billing_flow),
    #("technical", technical_flow),
    #("general", general_flow),
  ]),
  storage,
)
```

### Parallel Composition

Run multiple flows concurrently and merge their results:

```gleam
let survey_flow = compose.compose_parallel(
  "full_survey",
  [demographics_flow, preferences_flow, feedback_flow],
  fn(results) {
    // Merge all results into one dict
    list.fold(results, dict.new(), fn(acc, result) {
      dict.merge(acc, result)
    })
  },
  storage,
)
```

## Registry

The flow registry manages flow lifecycle and router integration.

### Triggers

Flows can be triggered by different update types:

```gleam
import telega/flow/types

// Start on command
registry.register(types.OnCommand("/register"), registration_flow)

// Start on text pattern
registry.register(types.OnText(router.Exact("register")), registration_flow)

// Start on callback
registry.register(types.OnCallback(router.Prefix("reg:")), registration_flow)

// Start on photo/video/voice/audio
registry.register(types.OnPhoto, photo_flow)

// Start on any text
registry.register(types.OnAnyText, catchall_flow)

// Start on custom filter
registry.register(types.OnFiltered(router.filter("custom", my_filter_fn)), custom_flow)
```

### Callable Flows

Register flows without triggers to call them programmatically from handlers:

```gleam
let reg =
  registry.new_registry()
  |> registry.register(types.OnCommand("/start"), main_flow)
  |> registry.register_callable(address_flow)

// Later, from any handler:
registry.call_flow(ctx: ctx, registry: reg, name: "address", initial: dict.new())
```

### Initial Data

Pass data when starting a flow:

```gleam
registry.register_with_data(
  types.OnCommand("/book"),
  booking_flow,
  dict.from_list([#("source", "command")]),
)
```

## Storage

Flows require a storage backend for persistence.

### ETS Storage (In-Memory)

Good for development and single-node deployments. Data is lost on VM restart:

```gleam
import telega/flow/storage

let assert Ok(store) = storage.create_ets_storage()
```

### No-Op Storage

For testing or stateless flows. Discards all data:

```gleam
let store = storage.create_noop_storage()
```

### Custom Storage (Database)

For production with persistence across restarts, implement `FlowStorage`:

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

Use `instance_to_row` and `instance_from_row` for serialization:

```gleam
import telega/flow/instance
import telega/flow/types

// Saving: convert to flat row for DB
let row = instance.instance_to_row(inst)
// Access row.id, row.flow_name, row.current_step, row.data, etc.

// Loading: reconstruct from DB row
let inst = instance.instance_from_row(types.FlowInstanceRow(
  id: db_row.id,
  flow_name: db_row.flow_name,
  user_id: db_row.user_id,
  chat_id: db_row.chat_id,
  current_step: db_row.current_step,
  data: parsed_data_dict,
  step_data: parsed_step_data_dict,
  wait_token: db_row.wait_token,
  wait_timeout_at: db_row.wait_timeout_at,
  created_at: db_row.created_at,
  updated_at: db_row.updated_at,
))
```

#### PostgreSQL Example

A complete database storage implementation from the [restaurant-booking example](../examples/06-restaurant-booking/):

```gleam
import gleam/json
import gleam/dict
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import pog
import telega/flow/instance
import telega/flow/types

pub fn create_database_storage(db: pog.Connection) -> types.FlowStorage(String) {
  types.FlowStorage(
    save: fn(inst) {
      let row = instance.instance_to_row(inst)

      let state_data_json =
        json.object(
          row.data
          |> dict.to_list
          |> list.map(fn(pair) { #(pair.0, json.string(pair.1)) }),
        )

      let step_data_json = case dict.size(row.step_data) {
        0 -> json.null()
        _ ->
          json.object(
            row.step_data
            |> dict.to_list
            |> list.map(fn(pair) { #(pair.0, json.string(pair.1)) }),
          )
      }

      case
        sql.save_flow_instance(
          db, row.id, row.flow_name, row.user_id, row.chat_id,
          row.current_step, state_data_json, step_data_json,
          option.unwrap(row.wait_token, ""),
        )
      {
        Ok(_) -> Ok(Nil)
        Error(err) ->
          Error("Failed to save flow instance: " <> string.inspect(err))
      }
    },
    load: fn(id) {
      case sql.load_flow_instance(db, id) {
        Ok(pog.Returned(count: _, rows: [row])) ->
          Ok(Some(db_row_to_flow_instance(row)))
        Ok(pog.Returned(count: _, rows: [])) -> Ok(None)
        _ -> Error("Failed to load flow instance")
      }
    },
    delete: fn(id) {
      case sql.delete_flow_instance(db, id) {
        Ok(_) -> Ok(Nil)
        Error(err) ->
          Error("Failed to delete flow instance: " <> string.inspect(err))
      }
    },
    list_by_user: fn(user_id, chat_id) {
      case sql.list_user_instances(db, user_id, chat_id) {
        Ok(pog.Returned(count: _, rows:)) ->
          Ok(list.map(rows, db_row_to_flow_instance))
        Error(err) ->
          Error("Failed to list instances: " <> string.inspect(err))
      }
    },
  )
}
```

## Testing

Use `noop_storage` to test flow logic without side effects:

```gleam
import telega/flow/instance
import telega/flow/storage

pub fn step_data_operations_test() {
  let inst =
    instance.new_instance(
      id: "test_123_456",
      flow_name: "test_flow",
      user_id: 123,
      chat_id: 456,
      current_step: "step1",
    )

  // Test data operations
  let inst = instance.store_data(inst, "name", "Alice")
  instance.get_data(inst, "name")
  |> should.equal(Some("Alice"))

  // Test step data (cleared on transition)
  let inst = instance.store_step_data(inst, "attempts", "1")
  instance.get_step_data(inst, "attempts")
  |> should.equal(Some("1"))

  let inst = instance.clear_step_data(inst)
  instance.get_step_data(inst, "attempts")
  |> should.equal(None)
}
```

### Testing Step Handlers

Test handlers by creating instances with pre-set step data:

```gleam
pub fn email_validation_test() {
  let store = storage.create_noop_storage()

  // Simulate user input by setting step data
  let inst =
    instance.new_instance(
      id: "test_1_1",
      flow_name: "registration",
      user_id: 1,
      chat_id: 1,
      current_step: "email",
    )
    |> instance.store_step_data("user_input", "invalid-email")

  // Call handler directly and assert the result action
  // ...
}
```

### Testing Serialization

Verify that your step types survive round-trip serialization:

```gleam
pub fn serialization_round_trip_test() {
  let inst =
    instance.new_instance(
      id: "test_1_1",
      flow_name: "test",
      user_id: 1,
      chat_id: 1,
      current_step: "ask_name",
    )
    |> instance.store_data("key", "value")

  let row = instance.instance_to_row(inst)
  let restored = instance.instance_from_row(types.FlowInstanceRow(
    id: row.id,
    flow_name: row.flow_name,
    user_id: row.user_id,
    chat_id: row.chat_id,
    current_step: row.current_step,
    data: row.data,
    step_data: row.step_data,
    wait_token: row.wait_token,
    wait_timeout_at: row.wait_timeout_at,
    created_at: row.created_at,
    updated_at: row.updated_at,
  ))

  instance.get_data(restored, "key")
  |> should.equal(Some("value"))
}
```

## Timeouts and Cleanup

By default, flow instances live forever — a flow in `Wait` state will stay in storage indefinitely until the user responds or the flow is explicitly canceled. This is the safe default for simple bots, but production bots should configure timeouts and cleanup.

### Flow-Level TTL

Set a maximum lifetime for the entire flow instance:

```gleam
builder.new("booking", store, step_to_string, string_to_step)
|> builder.with_ttl(ms: 600_000)  // 10 minutes for the whole flow
|> builder.add_step(Date, date_handler)
|> builder.add_step(Time, time_handler)
|> builder.build(initial: Date)
```

When a flow exceeds its TTL:
- On the next user message (lazy check), the expired instance is deleted and a new flow starts fresh
- The `on_timeout` hook is called before deletion (if configured)

### Per-Wait Timeout

Set a timeout on individual wait points:

```gleam
fn date_handler(ctx, inst) {
  case instance.get_wait_result(inst) {
    types.TextInput(value:) -> {
      let inst = instance.store_data(inst, "date", value)
      action.next(ctx, inst, Time)
    }
    types.Pending -> {
      let _ = reply.with_text(ctx, "Enter date (you have 2 minutes):")
      action.wait_with_timeout(ctx, inst, timeout_ms: 120_000)
    }
    _ -> action.cancel(ctx, inst)
  }
}
```

Per-wait timeout takes precedence over flow TTL for the current wait. If neither is set, the wait lasts forever.

### Timeout Hook

React to expired flows — notify the user, log metrics, etc.:

```gleam
builder.new("booking", store, step_to_string, string_to_step)
|> builder.with_ttl(ms: 600_000)
|> builder.on_timeout(fn(ctx, instance) {
  let _ = reply.with_text(ctx, "Your booking session expired. Start again with /book")
  Ok(ctx)
})
|> builder.build(initial: Date)
```

The `on_timeout` hook is called with the user's context when the expiration is detected via lazy check (i.e., when the user sends the next message). It is **not** called by the background sweeper.

### Cancel Command

Register a command that cancels all active flows for the user:

```gleam
let reg =
  registry.new_registry()
  |> registry.register(types.OnCommand("/book"), booking_flow)
  |> registry.register_cancel_command("/cancel")
```

When the user sends `/cancel`, all their active flow instances are deleted and `on_flow_exit` hooks are called.

For a custom cancel message:

```gleam
registry.register_cancel_command_with(reg, "/cancel", fn(ctx, cancelled_flows) {
  let count = list.length(cancelled_flows)
  let _ = reply.with_text(ctx, int.to_string(count) <> " flow(s) cancelled.")
  Ok(ctx)
})
```

### Programmatic Cancellation

Cancel flows from outside the bot (webhooks, admin panels, cron jobs):

```gleam
// Cancel all flows for a user in a chat
let assert Ok(cancelled_ids) =
  registry.cancel_user_flows(reg, user_id: 123, chat_id: 456)

// Cancel a specific flow instance by ID
let assert Ok(True) =
  registry.cancel_flow_instance(reg, flow_id: "booking_456_123")
```

These functions work directly with storage and don't require a `Context`. Useful for:
- Admin webhook: `POST /admin/cancel-flow?user_id=123&chat_id=456`
- Batch cleanup cron jobs
- Graceful shutdown (cancel all active flows before stopping)

### How Expiration Works

Flows are checked for expiration at two points:

1. **Lazy check (on resume)** — when a user sends a message and an auto-resume handler loads the instance. If expired: calls `on_timeout` + `on_flow_exit` hooks, deletes instance, message is not consumed as flow input.

2. **Lazy check (on start)** — when `start_or_resume` finds an existing instance. If expired: deletes old instance, starts a fresh flow.

An instance is expired if:
- Flow has TTL and `current_time - created_at > ttl_ms`, OR
- Instance has `wait_timeout_at` and `current_time > wait_timeout_at`

## Best Practices

1. **One question per step.** Keep steps focused — each step should ask for one piece of information. This makes navigation (back/goto) predictable.

2. **Always handle cancel.** Use `registry.register_cancel_command("/cancel")` to give users a way to exit any active flow. For flows where cancellation needs special handling, check for `CommandInput(command: "/cancel", ..)` in your step handlers.

3. **Use flow data for results, step data for temp state.** Flow data persists across steps; step data is cleared on transition. Use step data for retry counters, validation flags, etc.

4. **Design for restart.** Don't rely on in-memory state outside the flow instance. Everything needed to resume should be in flow data or retrievable from your database.

5. **Validate early, fail clearly.** Validate user input in the step handler and show a clear error message before calling `action.wait` again. Consider tracking attempt counts to prevent infinite loops.

6. **Use built-in handlers for simple steps.** `handler.text_step` and `handler.message_step` eliminate boilerplate for the most common patterns.

7. **Prefer `on_error` over manual error handling.** The flow-level error handler catches all errors from step handlers, providing a single place for error recovery logic.

8. **Use subflows for reusable sequences.** If the same sequence of steps appears in multiple flows (e.g., address collection), extract it into a subflow.

9. **Set TTL for production flows.** Flows without TTL accumulate in storage forever. Use `builder.with_ttl` to set a reasonable lifetime (e.g., 10–30 minutes for form-like flows). For long-running workflows, use per-wait timeouts instead.

10. **Use programmatic cancellation for admin tools.** `registry.cancel_user_flows` and `registry.cancel_flow_instance` work without `Context` — ideal for admin webhooks, cron jobs, and graceful shutdown.

## Complete Example

A simple registration bot:

```gleam
import gleam/dict
import gleam/option.{None, Some}
import telega/flow/action
import telega/flow/builder
import telega/flow/instance
import telega/reply

pub type Step {
  Name
  Email
  Done
}

pub fn create_flow(storage) {
  builder.new("register", storage, step_to_string, string_to_step)
  |> builder.add_step(Name, name_step)
  |> builder.add_step(Email, email_step)
  |> builder.add_step(Done, done_step)
  |> builder.on_complete(fn(ctx, _) {
    let _ = reply.with_text(ctx, "Registration complete!")
    Ok(ctx)
  })
  |> builder.build(initial: Name)
}

fn name_step(ctx, inst) {
  case instance.get_step_data(inst, "user_input") {
    Some(name) -> {
      let inst = instance.store_data(inst, "name", name)
      action.next(ctx, inst, Email)
    }
    None -> {
      let _ = reply.with_text(ctx, "What's your name?")
      action.wait(ctx, inst)
    }
  }
}

fn email_step(ctx, inst) {
  case instance.get_step_data(inst, "user_input") {
    Some(email) -> {
      let inst = instance.store_data(inst, "email", email)
      action.next(ctx, inst, Done)
    }
    None -> {
      let _ = reply.with_text(ctx, "What's your email?")
      action.wait(ctx, inst)
    }
  }
}

fn done_step(ctx, inst) {
  let name = instance.get_data(inst, "name") |> option.unwrap("Unknown")
  let email = instance.get_data(inst, "email") |> option.unwrap("Unknown")

  let _ = reply.with_text(ctx,
    "Name: " <> name <> "\nEmail: " <> email
  )
  action.complete(ctx, inst)
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

## Module Reference

| Module | Purpose |
|---|---|
| `telega/flow/types` | All shared type definitions (`FlowInstance`, `FlowAction`, `WaitResult`, etc.) |
| `telega/flow/instance` | Instance CRUD, accessors, data operations, serialization |
| `telega/flow/action` | Navigation helpers (`next`, `back`, `goto`, `complete`, `cancel`, `wait`, `wait_with_timeout`) |
| `telega/flow/storage` | Storage utilities (ETS, noop, `generate_id`) |
| `telega/flow/builder` | Flow construction (`new`, `add_step`, `build`, hooks, middleware, conditionals) |
| `telega/flow/engine` | Core execution engine (internal) |
| `telega/flow/handler` | Built-in step handlers (`text_step`, `message_step`, resume handlers) |
| `telega/flow/registry` | Flow registry and router integration (`new_registry`, `register`, `apply_to_router`) |
| `telega/flow/compose` | Flow composition (`compose_sequential`, `compose_conditional`, `compose_parallel`, `validation_middleware`) |
