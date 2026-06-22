import gleam/bool
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import restaurant_booking/dependencies.{type Dependencies}
import restaurant_booking/i18n
import restaurant_booking/sql
import restaurant_booking/util
import sqlight
import telega/bot.{type Context}
import telega/flow/action
import telega/flow/builder
import telega/flow/instance
import telega/flow/types
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
  db: sqlight.Connection,
) -> types.Flow(RegistrationStep, Nil, String, Dependencies) {
  // The flow's *persistence backend* is built from `db` here, at init — it is
  // resolved before any update arrives, so it cannot come from `ctx.dependencies`. The
  // step handlers, in contrast, read their db for queries from `ctx.dependencies.db`.
  let storage = util.create_database_storage(db)

  builder.new("registration", storage, step_to_string, string_to_step)
  |> builder.add_step(Welcome, welcome_step)
  |> builder.add_step(CollectName, collect_name_step)
  |> builder.add_step(CollectPhone, collect_phone_step)
  |> builder.add_step(CollectEmail, collect_email_step)
  |> builder.add_step(ConfirmRegistration, confirm_registration_step)
  |> builder.on_complete(registration_complete)
  |> builder.on_error(registration_error)
  |> builder.build(initial: Welcome)
}

pub fn welcome_step(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  use user_in_db <- result.try(
    sql.get_user(
      ctx.dependencies.db,
      instance.instance_user_id(instance),
      instance.instance_chat_id(instance),
    )
    |> result.map_error(fn(err) {
      "Failed to get user: " <> string.inspect(err)
    }),
  )

  use <- bool.guard(user_in_db != [], action.cancel(ctx, instance))

  let message =
    i18n.t(ctx, "reg.welcome", [#("restaurant", util.get_restaurant_name())])

  case reply.with_text(ctx, message) {
    Ok(_) -> action.next(ctx, instance, CollectName)
    Error(_) -> action.cancel(ctx, instance)
  }
}

fn collect_name_step(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  case instance.get_step_data(instance, "user_input") {
    Some(name) -> {
      let instance = instance.clear_step_data_key(instance, "user_input")
      case validate_name(name) {
        Ok(valid_name) -> {
          let instance =
            instance.store_step_data(instance, "collected_name", valid_name)
          action.next(ctx, instance, CollectPhone)
        }
        Error(error_msg) -> {
          let _ =
            reply.with_text(
              ctx,
              "❌ "
                <> i18n.t(ctx, error_msg, [])
                <> "\n"
                <> i18n.t(ctx, "common.try_again", []),
            )
          action.wait(ctx, instance)
        }
      }
    }
    None -> ask_for_name(ctx, instance)
  }
}

fn ask_for_name(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  case reply.with_text(ctx, i18n.t(ctx, "reg.ask_name", [])) {
    Ok(_) -> action.wait(ctx, instance)
    Error(_) -> action.cancel(ctx, instance)
  }
}

fn collect_phone_step(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  case instance.get_step_data(instance, "user_input") {
    Some(phone) -> {
      let instance = instance.clear_step_data_key(instance, "user_input")
      case validate_phone(phone) {
        Ok(valid_phone) -> {
          let instance =
            instance.store_step_data(instance, "collected_phone", valid_phone)
          action.next(ctx, instance, CollectEmail)
        }
        Error(error_msg) -> {
          let _ =
            reply.with_text(
              ctx,
              "❌ "
                <> i18n.t(ctx, error_msg, [])
                <> "\n"
                <> i18n.t(ctx, "common.try_again", []),
            )
          action.wait(ctx, instance)
        }
      }
    }
    None -> ask_for_phone(ctx, instance)
  }
}

fn ask_for_phone(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  case reply.with_text(ctx, i18n.t(ctx, "reg.ask_phone", [])) {
    Ok(_) -> action.wait(ctx, instance)
    Error(_) -> action.cancel(ctx, instance)
  }
}

fn collect_email_step(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  case instance.get_step_data(instance, "user_input") {
    Some(email) -> {
      let instance = instance.clear_step_data_key(instance, "user_input")
      let trimmed = string.trim(email)
      let is_skip = string.lowercase(trimmed) == "skip"

      case is_skip {
        True -> {
          let instance =
            instance.store_step_data(instance, "collected_email", "")
          action.next(ctx, instance, ConfirmRegistration)
        }
        False -> {
          case validate_email(trimmed) {
            Ok(valid_email) -> {
              let instance =
                instance.store_step_data(
                  instance,
                  "collected_email",
                  valid_email,
                )
              action.next(ctx, instance, ConfirmRegistration)
            }
            Error(_) -> {
              let _ = reply.with_text(ctx, i18n.t(ctx, "reg.invalid_email", []))
              action.wait(ctx, instance)
            }
          }
        }
      }
    }
    None -> {
      case reply.with_text(ctx, i18n.t(ctx, "reg.ask_email", [])) {
        Ok(_) -> action.wait(ctx, instance)
        Error(_) -> action.cancel(ctx, instance)
      }
    }
  }
}

fn confirm_registration_step(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  case instance.get_wait_result(instance) {
    types.BoolCallback(value: True) ->
      save_and_complete(
        ctx,
        instance.clear_step_data_key(instance, "callback_data"),
      )
    types.BoolCallback(value: False) ->
      restart_registration(
        ctx,
        instance.clear_step_data_key(instance, "callback_data"),
      )
    types.Pending -> handle_text_response(ctx, instance)
    _ -> action.cancel(ctx, instance)
  }
}

fn save_and_complete(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  case extract_registration_data(instance) {
    Error(e) -> {
      let _ = reply.with_text(ctx, "❌ " <> i18n.t(ctx, e, []))
      action.cancel(ctx, instance)
    }
    Ok(reg_data) -> {
      case
        sql.create_or_update_user(
          ctx.dependencies.db,
          instance.instance_user_id(instance),
          instance.instance_chat_id(instance),
          reg_data.name,
          reg_data.phone,
          option.unwrap(reg_data.email, ""),
        )
      {
        Ok(_) -> action.complete(ctx, instance)
        Error(err) -> {
          let _ =
            reply.with_text(
              ctx,
              i18n.t(ctx, "reg.save_failed", [
                #("error", string.inspect(err)),
              ]),
            )
          action.cancel(ctx, instance)
        }
      }
    }
  }
}

fn restart_registration(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  let _ = reply.with_text(ctx, i18n.t(ctx, "reg.restart", []))
  action.goto(ctx, instance.clear_step_data(instance), CollectName)
}

fn handle_text_response(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  case instance.get_step_data(instance, "user_input") {
    None -> ask_for_confirmation(ctx, instance)
    Some(text) -> {
      let instance = instance.clear_step_data_key(instance, "user_input")
      case parse_edit_command(text) {
        Some(#(step, prompt_key)) -> {
          let _ = reply.with_text(ctx, i18n.t(ctx, prompt_key, []))
          action.goto(ctx, instance, step)
        }
        None -> ask_for_confirmation(ctx, instance)
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
        "name" -> Some(#(CollectName, "reg.edit_name"))
        "phone" -> Some(#(CollectPhone, "reg.edit_phone"))
        "email" -> Some(#(CollectEmail, "reg.edit_email"))
        _ -> None
      }
    }
  }
}

fn ask_for_confirmation(
  ctx: Context(Nil, String, Dependencies),
  instance: types.FlowInstance,
) -> types.StepResult(RegistrationStep, Nil, String, Dependencies) {
  case extract_registration_data(instance) {
    Ok(reg_data) -> {
      let email_display = case reg_data.email {
        Some(e) -> i18n.t(ctx, "reg.email_provided", [#("email", e)])
        None -> i18n.t(ctx, "reg.email_not_provided", [])
      }

      let message =
        i18n.t(ctx, "reg.confirm", [
          #("name", reg_data.name),
          #("phone", reg_data.phone),
          #("email", email_display),
        ])

      let keyboard = util.yes_no_keyboard("reg_confirm")

      case
        reply.with_markup(ctx, message, keyboard.to_inline_markup(keyboard))
      {
        Ok(_) -> action.wait_callback(ctx, instance)
        Error(_) -> action.cancel(ctx, instance)
      }
    }
    Error(error_msg) -> {
      let _ =
        reply.with_text(
          ctx,
          i18n.t(ctx, "reg.error_prefix", [
            #("error", i18n.t(ctx, error_msg, [])),
          ]),
        )
      action.cancel(ctx, instance)
    }
  }
}

fn registration_complete(
  ctx: Context(Nil, String, Dependencies),
  _instance: types.FlowInstance,
) -> Result(Context(Nil, String, Dependencies), String) {
  let message =
    i18n.t(ctx, "reg.success", [#("restaurant", util.get_restaurant_name())])

  case reply.with_text(ctx, message) {
    Ok(_) -> Ok(ctx)
    Error(_) -> Ok(ctx)
  }
}

fn registration_error(
  ctx: Context(Nil, String, Dependencies),
  _instance: types.FlowInstance,
  _error: option.Option(String),
) -> Result(Context(Nil, String, Dependencies), String) {
  case reply.with_text(ctx, i18n.t(ctx, "reg.error", [])) {
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
  instance: types.FlowInstance,
) -> Result(RegistrationData, String) {
  use name <- result.try(
    instance.get_step_data(instance, "collected_name")
    |> option.to_result("Missing name"),
  )

  use phone <- result.try(
    instance.get_step_data(instance, "collected_phone")
    |> option.to_result("Missing phone"),
  )

  let email = instance.get_step_data(instance, "collected_email")

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

/// Validators return i18n keys (e.g. `"error.invalid_phone"`) instead of raw
/// English; call sites translate them with `i18n.t`.
pub fn validate_name(name: String) -> Result(String, String) {
  let trimmed = string.trim(name)
  case string.length(trimmed) {
    n if n >= 2 && n <= 100 -> Ok(trimmed)
    n if n < 2 -> Error("error.name_too_short")
    _ -> Error("error.name_too_long")
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
    False -> Error("error.invalid_phone")
  }
}

pub fn validate_email(email: String) -> Result(String, String) {
  let trimmed = string.trim(email)
  case string.contains(trimmed, "@") && string.contains(trimmed, ".") {
    True -> Ok(trimmed)
    False -> Error("error.invalid_email")
  }
}
