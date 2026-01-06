import gleam/bool
import gleam/dict
import gleam/int
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import pog
import restaurant_booking/sql
import restaurant_booking/util
import telega/bot.{type Context}
import telega/flow
import telega/keyboard
import telega/reply

/// Define strongly-typed steps for the registration flow
pub type RegistrationStep {
  Welcome
  CollectName
  CollectPhone
  CollectEmail
  ConfirmRegistration
}

fn step_to_string(step: RegistrationStep) -> String {
  case step {
    Welcome -> "welcome"
    CollectName -> "collect_name"
    CollectPhone -> "collect_phone"
    CollectEmail -> "collect_email"
    ConfirmRegistration -> "confirm_registration"
  }
}

fn string_to_step(name: String) -> Result(RegistrationStep, Nil) {
  case name {
    "welcome" -> Ok(Welcome)
    "collect_name" -> Ok(CollectName)
    "collect_phone" -> Ok(CollectPhone)
    "collect_email" -> Ok(CollectEmail)
    "confirm_registration" -> Ok(ConfirmRegistration)
    _ -> Error(Nil)
  }
}

pub fn create_registration_flow(
  db: pog.Connection,
) -> flow.Flow(RegistrationStep, Nil, String) {
  let storage = util.create_database_storage(db)

  flow.new("registration", storage, step_to_string, string_to_step)
  |> flow.add_step(Welcome, fn(ctx, instance) {
    welcome_step(ctx, instance, db)
  })
  |> flow.add_step(CollectName, collect_name_step)
  |> flow.add_step(CollectPhone, collect_phone_step)
  |> flow.add_step(CollectEmail, collect_email_step)
  |> flow.add_step(ConfirmRegistration, fn(ctx, instance) {
    confirm_registration_step(ctx, instance, db)
  })
  |> flow.on_complete(registration_complete)
  |> flow.on_error(registration_error)
  |> flow.build(initial: Welcome)
}

pub fn welcome_step(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
  db: pog.Connection,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  use user_in_db <- result.try(
    sql.get_user(db, instance.user_id, instance.chat_id)
    |> result.map_error(fn(err) {
      "Failed to get user: " <> string.inspect(err)
    }),
  )

  use <- bool.guard(user_in_db.count > 0, flow.cancel(ctx, instance))

  let message = "🍽️ Welcome to " <> util.get_restaurant_name() <> "!

To make a reservation, I need to collect some information about you.
This will only take a few minutes.

Let's start! 👋"

  case reply.with_text(ctx, message) {
    Ok(_) -> flow.next(ctx, instance, CollectName)
    Error(_) -> flow.cancel(ctx, instance)
  }
}

fn collect_name_step(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  case flow.get_step_data(instance, "name") {
    Some(name) -> {
      case validate_name(name) {
        Ok(valid_name) -> {
          let instance =
            flow.store_step_data(instance, "collected_name", valid_name)
          flow.next(ctx, instance, CollectPhone)
        }
        Error(error_msg) -> {
          let _ =
            reply.with_text(ctx, "❌ " <> error_msg <> "\nPlease try again.")
          flow.wait(ctx, instance, "name_input_" <> instance.id)
        }
      }
    }
    None -> ask_for_name(ctx, instance)
  }
}

fn ask_for_name(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  case reply.with_text(ctx, "Please enter your full name:") {
    Ok(_) -> flow.wait(ctx, instance, "name_input_" <> instance.id)
    Error(_) -> flow.cancel(ctx, instance)
  }
}

fn collect_phone_step(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  case flow.get_step_data(instance, "phone") {
    Some(phone) -> {
      case validate_phone(phone) {
        Ok(valid_phone) -> {
          let instance =
            flow.store_step_data(instance, "collected_phone", valid_phone)
          flow.next(ctx, instance, CollectEmail)
        }
        Error(error_msg) -> {
          let _ =
            reply.with_text(ctx, "❌ " <> error_msg <> "\nPlease try again.")
          flow.wait(ctx, instance, "phone_input_" <> instance.id)
        }
      }
    }
    None -> ask_for_phone(ctx, instance)
  }
}

fn ask_for_phone(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  let message =
    "
📱 Please provide your phone number:

This is required for booking confirmations and important updates.
Format: +1-555-123-4567 or (555) 123-4567
  "

  case reply.with_text(ctx, message) {
    Ok(_) -> flow.wait(ctx, instance, "phone_input_" <> instance.id)
    Error(_) -> flow.cancel(ctx, instance)
  }
}

fn collect_email_step(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  case flow.get_step_data(instance, "email") {
    Some(email) -> {
      let trimmed = string.trim(email)
      let is_skip = string.lowercase(trimmed) == "skip"

      case is_skip {
        True -> {
          let instance = flow.store_step_data(instance, "collected_email", "")
          flow.next(ctx, instance, ConfirmRegistration)
        }
        False -> {
          case validate_email(trimmed) {
            Ok(valid_email) -> {
              let instance =
                flow.store_step_data(instance, "collected_email", valid_email)
              flow.next(ctx, instance, ConfirmRegistration)
            }
            Error(_) -> {
              let _ =
                reply.with_text(
                  ctx,
                  "❌ Invalid email format. Please try again or type 'skip'.",
                )
              flow.wait(ctx, instance, "email_input_" <> instance.id)
            }
          }
        }
      }
    }
    None -> {
      let message =
        "
📧 Email address (optional):

We'll send you booking confirmations and special offers.
You can skip this step by typing 'skip'.
      "

      case reply.with_text(ctx, message) {
        Ok(_) -> flow.wait(ctx, instance, "email_input_" <> instance.id)
        Error(_) -> flow.cancel(ctx, instance)
      }
    }
  }
}

fn confirm_registration_step(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
  db: pog.Connection,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  case flow.is_callback_passed(instance, "confirmation", "reg_confirm") {
    Some(True) -> save_and_complete(ctx, instance, db)
    Some(False) -> restart_registration(ctx, instance)
    None -> handle_text_response(ctx, instance)
  }
}

fn save_and_complete(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
  db: pog.Connection,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  case extract_registration_data(instance) {
    Error(e) -> {
      let _ = reply.with_text(ctx, "❌ " <> e)
      flow.cancel(ctx, instance)
    }
    Ok(reg_data) -> {
      case
        sql.create_or_update_user(
          db,
          instance.user_id,
          instance.chat_id,
          reg_data.name,
          reg_data.phone,
          option.unwrap(reg_data.email, ""),
        )
      {
        Ok(_) -> flow.complete(ctx, instance)
        Error(err) -> {
          let _ =
            reply.with_text(ctx, "❌ Failed to save: " <> string.inspect(err))
          flow.cancel(ctx, instance)
        }
      }
    }
  }
}

fn restart_registration(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  let _ = reply.with_text(ctx, "Starting over. Please enter your full name:")
  flow.goto(ctx, flow.clear_step_data(instance), CollectName)
}

fn handle_text_response(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  case flow.get_step_data(instance, "confirmation") {
    None -> ask_for_confirmation(ctx, instance)
    Some(text) -> {
      case parse_edit_command(text) {
        Some(#(step, prompt)) -> {
          let _ = reply.with_text(ctx, prompt)
          let cleared =
            flow.FlowInstance(
              ..instance,
              step_data: dict.delete(instance.step_data, "confirmation"),
            )
          flow.goto(ctx, cleared, step)
        }
        None ->
          ask_for_confirmation(
            ctx,
            flow.FlowInstance(
              ..instance,
              step_data: dict.delete(instance.step_data, "confirmation"),
            ),
          )
      }
    }
  }
}

fn parse_edit_command(
  text: String,
) -> option.Option(#(RegistrationStep, String)) {
  case string.starts_with(string.lowercase(text), "edit ") {
    False -> None
    True -> {
      case string.drop_start(text, 5) |> string.trim |> string.lowercase {
        "name" -> Some(#(CollectName, "Please enter your new name:"))
        "phone" -> Some(#(CollectPhone, "Please enter your new phone number:"))
        "email" ->
          Some(#(
            CollectEmail,
            "Please enter your new email (or type 'skip' to leave it empty):",
          ))
        _ -> None
      }
    }
  }
}

fn ask_for_confirmation(
  ctx: Context(Nil, String),
  instance: flow.FlowInstance,
) -> flow.StepResult(RegistrationStep, Nil, String) {
  case extract_registration_data(instance) {
    Ok(reg_data) -> {
      let email_display = case reg_data.email {
        Some(e) -> "📧 " <> e
        None -> "📧 Not provided"
      }

      let message = "
✨ Please confirm your registration:

👤 Name: " <> reg_data.name <> "
📱 Phone: " <> reg_data.phone <> "
" <> email_display <> "

To edit any field, type 'edit name', 'edit phone', or 'edit email'
  "

      let keyboard = util.yes_no_keyboard("reg_confirm")

      case
        reply.with_markup(ctx, message, keyboard.to_inline_markup(keyboard))
      {
        Ok(_) -> flow.wait_callback(ctx, instance, "confirmation")
        Error(_) -> flow.cancel(ctx, instance)
      }
    }
    Error(error_msg) -> {
      let _ = reply.with_text(ctx, "❌ Registration error: " <> error_msg)
      flow.cancel(ctx, instance)
    }
  }
}

fn registration_complete(
  ctx: Context(Nil, String),
  _instance: flow.FlowInstance,
) -> Result(Context(Nil, String), String) {
  let message = "
🎉 Registration successful!

Welcome to " <> util.get_restaurant_name() <> "! You can now make reservations.

Use /book to make a new reservation
Use /my_bookings to see your current reservations
Use /help for more options
  "

  case reply.with_text(ctx, message) {
    Ok(_) -> Ok(ctx)
    Error(_) -> Ok(ctx)
  }
}

fn registration_error(
  ctx: Context(Nil, String),
  _instance: flow.FlowInstance,
  _error: option.Option(String),
) -> Result(Context(Nil, String), String) {
  let message =
    "❌ Sorry, there was an error with your registration.

Please try again with /register or contact support if the problem persists."

  case reply.with_text(ctx, message) {
    Ok(_) -> Ok(ctx)
    Error(_) -> Ok(ctx)
  }
}

/// Registration data extracted from flow instance
pub type RegistrationData {
  RegistrationData(name: String, phone: String, email: option.Option(String))
}

/// Extract and validate registration data from scene data
fn extract_registration_data(
  instance: flow.FlowInstance,
) -> Result(RegistrationData, String) {
  use name <- result.try(
    flow.get_step_data(instance, "collected_name")
    |> option.to_result("Missing name"),
  )

  use phone <- result.try(
    flow.get_step_data(instance, "collected_phone")
    |> option.to_result("Missing phone"),
  )

  let email = flow.get_step_data(instance, "collected_email")

  use validated_name <- result.try(validate_name(name))
  use validated_phone <- result.try(validate_phone(phone))

  let validated_email = case email {
    Some(email_str) -> {
      case email_str == "skip" || email_str == "" {
        True -> None
        False -> {
          case validate_email(email_str) {
            Ok(valid_email) -> Some(valid_email)
            Error(_) -> None
            // Invalid email becomes None
          }
        }
      }
    }
    None -> None
  }

  Ok(RegistrationData(
    name: validated_name,
    phone: validated_phone,
    email: validated_email,
  ))
}

pub fn validate_name(name: String) -> Result(String, String) {
  let trimmed = string.trim(name)
  case string.length(trimmed) {
    n if n >= 2 && n <= 100 -> Ok(trimmed)
    n if n < 2 -> Error("Name must be at least 2 characters")
    _ -> Error("Name is too long")
  }
}

pub fn validate_phone(phone: String) -> Result(String, String) {
  let cleaned =
    string.replace(phone, each: " ", with: "")
    |> string.replace(each: "-", with: "")
    |> string.replace(each: "(", with: "")
    |> string.replace(each: ")", with: "")

  let length = string.length(cleaned)
  case length >= 10 && length <= 15 {
    True -> Ok(cleaned)
    False ->
      Error(
        "Phone number must be between 10 and 15 digits (got "
        <> int.to_string(length)
        <> " digits)",
      )
  }
}

pub fn validate_email(email: String) -> Result(String, String) {
  let trimmed = string.trim(email)
  case string.contains(trimmed, "@") && string.contains(trimmed, ".") {
    True -> Ok(trimmed)
    False -> Error("Invalid email format")
  }
}
