import gleam/option.{None, Some}
import gleam/result
import gleam/string
import pog
import restaurant_booking/util
import telega/bot.{type Context}
import telega/conversation/flow
import telega/conversation/persistent_flow as pflow
import telega/reply

pub fn create_registration_flow(
  db: pog.Connection,
) -> pflow.PersistentFlow(Nil, String) {
  let storage = util.create_database_storage(db)

  pflow.new("registration", "welcome", storage)
  |> pflow.add_step("welcome", welcome_step)
  |> pflow.add_step("collect_name", collect_name_step)
  |> pflow.add_step("collect_phone", collect_phone_step)
  |> pflow.add_step("collect_email", collect_email_step)
  |> pflow.add_step("confirm_registration", confirm_registration_step)
  |> pflow.on_complete(registration_complete)
  |> pflow.on_error(registration_error)
}

pub fn welcome_step(
  ctx: Context(Nil, String),
  instance: pflow.FlowInstance,
) -> Result(
  #(Context(Nil, String), pflow.PersistentFlowAction, pflow.FlowInstance),
  String,
) {
  let message = "
🍽️ Welcome to " <> util.get_restaurant_name() <> "!

To make a reservation, I need to collect some information about you.
This will only take a few minutes.

Let's start! 👋
  "

  case reply.with_text(ctx, message) {
    Ok(_) ->
      Ok(#(ctx, pflow.StandardAction(flow.Next("collect_name")), instance))
    Error(_) -> Ok(#(ctx, pflow.StandardAction(flow.Cancel), instance))
  }
}

fn collect_name_step(
  ctx: Context(Nil, String),
  instance: pflow.FlowInstance,
) -> Result(
  #(Context(Nil, String), pflow.PersistentFlowAction, pflow.FlowInstance),
  String,
) {
  case pflow.get_scene_data(instance, "name") {
    Some(name) -> {
      case string.length(name) >= 2 {
        True -> {
          let instance =
            pflow.store_scene_data(instance, "collected_name", name)
          Ok(#(ctx, pflow.StandardAction(flow.Next("collect_phone")), instance))
        }
        False -> ask_for_name(ctx, instance)
      }
    }
    None -> ask_for_name(ctx, instance)
  }
}

fn ask_for_name(
  ctx: Context(Nil, String),
  instance: pflow.FlowInstance,
) -> Result(
  #(Context(Nil, String), pflow.PersistentFlowAction, pflow.FlowInstance),
  String,
) {
  case reply.with_text(ctx, "Please enter your full name:") {
    Ok(_) -> Ok(#(ctx, pflow.Wait("name_input_" <> instance.id), instance))
    Error(_) -> Ok(#(ctx, pflow.StandardAction(flow.Cancel), instance))
  }
}

fn collect_phone_step(
  ctx: Context(Nil, String),
  instance: pflow.FlowInstance,
) -> Result(
  #(Context(Nil, String), pflow.PersistentFlowAction, pflow.FlowInstance),
  String,
) {
  case pflow.get_scene_data(instance, "phone") {
    Some(phone) -> {
      case is_valid_phone(phone) {
        True -> {
          let instance =
            pflow.store_scene_data(instance, "collected_phone", phone)
          Ok(#(ctx, pflow.StandardAction(flow.Next("collect_email")), instance))
        }
        False -> ask_for_phone(ctx, instance)
      }
    }
    None -> ask_for_phone(ctx, instance)
  }
}

fn ask_for_phone(
  ctx: Context(Nil, String),
  instance: pflow.FlowInstance,
) -> Result(
  #(Context(Nil, String), pflow.PersistentFlowAction, pflow.FlowInstance),
  String,
) {
  let message =
    "
📱 Please provide your phone number:

This is required for booking confirmations and important updates.
Format: +1-555-123-4567 or (555) 123-4567
  "

  case reply.with_text(ctx, message) {
    Ok(_) -> Ok(#(ctx, pflow.Wait("phone_input_" <> instance.id), instance))
    Error(_) -> Ok(#(ctx, pflow.StandardAction(flow.Cancel), instance))
  }
}

fn collect_email_step(
  ctx: Context(Nil, String),
  instance: pflow.FlowInstance,
) -> Result(
  #(Context(Nil, String), pflow.PersistentFlowAction, pflow.FlowInstance),
  String,
) {
  case pflow.get_scene_data(instance, "email") {
    Some(email) -> {
      let instance = pflow.store_scene_data(instance, "collected_email", email)
      Ok(#(
        ctx,
        pflow.StandardAction(flow.Next("confirm_registration")),
        instance,
      ))
    }
    _ -> {
      let message =
        "
📧 Email address (optional):

We'll send you booking confirmations and special offers.
You can skip this step by typing 'skip'.
      "

      case reply.with_text(ctx, message) {
        Ok(_) -> Ok(#(ctx, pflow.Wait("email_input_" <> instance.id), instance))
        Error(_) -> Ok(#(ctx, pflow.StandardAction(flow.Cancel), instance))
      }
    }
  }
}

fn confirm_registration_step(
  ctx: Context(Nil, String),
  instance: pflow.FlowInstance,
) -> Result(
  #(Context(Nil, String), pflow.PersistentFlowAction, pflow.FlowInstance),
  String,
) {
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

Is this information correct?
- Type 'yes' to confirm
- Type 'no' to start over
- Type 'edit name/phone/email' to change specific field
  "

      case reply.with_text(ctx, message) {
        Ok(_) ->
          Ok(#(ctx, pflow.Wait("confirmation_" <> instance.id), instance))
        Error(_) -> Ok(#(ctx, pflow.StandardAction(flow.Cancel), instance))
      }
    }
    Error(error_msg) -> {
      case reply.with_text(ctx, "❌ Registration error: " <> error_msg) {
        Ok(_) -> Ok(#(ctx, pflow.StandardAction(flow.Cancel), instance))
        Error(_) -> Ok(#(ctx, pflow.StandardAction(flow.Cancel), instance))
      }
    }
  }
}

fn registration_complete(
  ctx: Context(Nil, String),
  _instance: pflow.FlowInstance,
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
  _instance: pflow.FlowInstance,
  _error: String,
) -> Result(Context(Nil, String), String) {
  let message =
    "
❌ Sorry, there was an error with your registration.

Please try again with /register or contact support if the problem persists.
  "

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
  instance: pflow.FlowInstance,
) -> Result(RegistrationData, String) {
  use name <- result.try(
    pflow.get_scene_data(instance, "collected_name")
    |> option_to_result("Missing name"),
  )

  use phone <- result.try(
    pflow.get_scene_data(instance, "collected_phone")
    |> option_to_result("Missing phone"),
  )

  let email = pflow.get_scene_data(instance, "collected_email")

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

  case is_valid_phone(cleaned) {
    True -> Ok(cleaned)
    False -> Error("Invalid phone number format")
  }
}

fn is_valid_phone(phone: String) -> Bool {
  // Simple phone validation - just check length
  let length = string.length(phone)
  length >= 10 && length <= 15
}

pub fn validate_email(email: String) -> Result(String, String) {
  let trimmed = string.trim(email)
  case string.contains(trimmed, "@") && string.contains(trimmed, ".") {
    True -> Ok(trimmed)
    False -> Error("Invalid email format")
  }
}

fn option_to_result(
  opt: option.Option(a),
  error_msg: String,
) -> Result(a, String) {
  case opt {
    Some(value) -> Ok(value)
    None -> Error(error_msg)
  }
}
