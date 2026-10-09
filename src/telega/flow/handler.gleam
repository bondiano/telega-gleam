//// Built-in step handlers and the text resume handler.

import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import telega/bot.{type Context}
import telega/flow/engine
import telega/flow/instance
import telega/flow/types.{
  type Flow, type FlowInstance, type StepHandler, Cancel, Complete, Next,
  Pending, TextInput, Wait,
}
import telega/reply
import telega/update

/// Create a text input step
pub fn text_step(
  prompt: String,
  data_key: String,
  next_step: step_type,
) -> StepHandler(step_type, session, error, dependencies) {
  fn(ctx: Context(session, error, dependencies), instance_val: FlowInstance) {
    case instance.get_wait_result(instance_val) {
      TextInput(value:) -> {
        let instance_val = instance.store_data(instance_val, data_key, value)
        Ok(#(ctx, Next(next_step), instance_val))
      }
      Pending -> {
        case reply.with_text(ctx, prompt) {
          Ok(_) -> Ok(#(ctx, Wait, instance_val))
          Error(_) -> Ok(#(ctx, Cancel, instance_val))
        }
      }
      _ -> {
        case reply.with_text(ctx, prompt) {
          Ok(_) -> Ok(#(ctx, Wait, instance_val))
          Error(_) -> Ok(#(ctx, Cancel, instance_val))
        }
      }
    }
  }
}

/// Like `text_step`, but the prompt is computed per update from the `Context`
/// and the flow instance instead of being fixed when the flow is built.
///
/// Use this when the prompt depends on something only known at update time —
/// most commonly the active locale for internationalization. `text_step` bakes
/// its prompt in at flow-construction time (startup), which is too early to know
/// the user's language; `text_step_with` resolves it on every prompt instead.
///
/// ```gleam
/// builder.add_step(
///   Date,
///   handler.text_step_with(
///     fn(ctx, _instance) { i18n.t(ctx, "book.ask_date", []) },
///     "booking_date",
///     Time,
///   ),
/// )
/// ```
pub fn text_step_with(
  prompt prompt: fn(Context(session, error, dependencies), FlowInstance) ->
    String,
  data_key data_key: String,
  next_step next_step: step_type,
) -> StepHandler(step_type, session, error, dependencies) {
  fn(ctx: Context(session, error, dependencies), instance_val: FlowInstance) {
    case instance.get_wait_result(instance_val) {
      TextInput(value:) -> {
        let instance_val = instance.store_data(instance_val, data_key, value)
        Ok(#(ctx, Next(next_step), instance_val))
      }
      _ -> {
        case reply.with_text(ctx, prompt(ctx, instance_val)) {
          Ok(_) -> Ok(#(ctx, Wait, instance_val))
          Error(_) -> Ok(#(ctx, Cancel, instance_val))
        }
      }
    }
  }
}

/// Create a message display step
pub fn message_step(
  message_fn: fn(FlowInstance) -> String,
  next_step: Option(step_type),
) -> StepHandler(step_type, session, error, dependencies) {
  fn(ctx: Context(session, error, dependencies), instance_val: FlowInstance) {
    let message = message_fn(instance_val)
    case reply.with_text(ctx, message) {
      Ok(_) -> {
        case next_step {
          Some(step) -> Ok(#(ctx, Next(step), instance_val))
          None -> Ok(#(ctx, Complete(instance_val.state.data), instance_val))
        }
      }
      Error(_) -> Ok(#(ctx, Cancel, instance_val))
    }
  }
}

/// Like `message_step`, but the message is computed from the `Context` (in
/// addition to the flow instance), enabling localization.
///
/// ```gleam
/// builder.add_step(
///   Welcome,
///   handler.message_step_with(
///     fn(ctx, _instance) { i18n.t(ctx, "book.welcome", []) },
///     option.Some(Date),
///   ),
/// )
/// ```
pub fn message_step_with(
  message_fn message_fn: fn(Context(session, error, dependencies), FlowInstance) ->
    String,
  next_step next_step: Option(step_type),
) -> StepHandler(step_type, session, error, dependencies) {
  fn(ctx: Context(session, error, dependencies), instance_val: FlowInstance) {
    let message = message_fn(ctx, instance_val)
    case reply.with_text(ctx, message) {
      Ok(_) -> {
        case next_step {
          Some(step) -> Ok(#(ctx, Next(step), instance_val))
          None -> Ok(#(ctx, Complete(instance_val.state.data), instance_val))
        }
      }
      Error(_) -> Ok(#(ctx, Cancel, instance_val))
    }
  }
}

/// Create a text handler for resuming flows
pub fn create_text_handler(
  flow: Flow(step_type, session, error, dependencies),
) -> fn(Context(session, error, dependencies), update.Update) ->
  Result(Context(session, error, dependencies), error) {
  fn(ctx, upd) {
    case upd {
      update.TextUpdate(text:, from_id:, chat_id:, ..) -> {
        // The storage is shared between flows, so `list_by_user` also returns
        // other flows' instances — resuming the first one handed this flow's
        // text to whichever flow happened to come back first.
        let waiting =
          flow.storage.list_by_user(from_id, chat_id)
          |> result.unwrap([])
          |> list.find(fn(inst) {
            inst.flow_name == flow.name && inst.wait_token != None
          })

        case waiting {
          Ok(inst) -> {
            let data = dict.from_list([#("user_input", text)])
            engine.resume_with_token(
              flow,
              ctx,
              option.unwrap(inst.wait_token, ""),
              Some(data),
            )
          }
          Error(Nil) -> Ok(ctx)
        }
      }
      _ -> Ok(ctx)
    }
  }
}
