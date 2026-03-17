//// Built-in step handlers and resume handler factories.

import gleam/dict
import gleam/option.{type Option, None, Some}
import gleam/string
import telega/bot.{type Context}
import telega/flow/engine
import telega/flow/instance
import telega/flow/types.{
  type Flow, type FlowInstance, type StepHandler, Cancel, Complete, Next,
  Pending, TextInput, Wait,
}
import telega/keyboard
import telega/reply
import telega/update

/// Create a text input step
pub fn text_step(
  prompt: String,
  data_key: String,
  next_step: step_type,
) -> StepHandler(step_type, session, error) {
  fn(ctx: Context(session, error), instance_val: FlowInstance) {
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

/// Create a message display step
pub fn message_step(
  message_fn: fn(FlowInstance) -> String,
  next_step: Option(step_type),
) -> StepHandler(step_type, session, error) {
  fn(ctx: Context(session, error), instance_val: FlowInstance) {
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

/// Create a router handler for resuming flows from callback queries
pub fn create_resume_handler(
  flow: Flow(step_type, session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  resume_handler(flow)
}

/// Create a router handler for resuming flows from callback queries with keyboard parsing
pub fn create_resume_handler_with_keyboard(
  flow: Flow(step_type, session, error),
  callback_data: keyboard.KeyboardCallbackData(String),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  resume_handler_with_keyboard(flow, callback_data)
}

/// Create a text handler for resuming flows
pub fn create_text_handler(
  flow: Flow(step_type, session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, upd) {
    case upd {
      update.TextUpdate(text:, from_id:, chat_id:, ..) -> {
        case flow.storage.list_by_user(from_id, chat_id) {
          Ok([inst, ..]) if inst.wait_token != None -> {
            let data = dict.from_list([#("user_input", text)])
            engine.resume_with_token(
              flow,
              ctx,
              option.unwrap(inst.wait_token, ""),
              Some(data),
            )
          }
          _ -> Ok(ctx)
        }
      }
      _ -> Ok(ctx)
    }
  }
}

fn resume_handler(
  flow flow: Flow(step_type, session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, upd) {
    case upd {
      update.CallbackQueryUpdate(query:, ..) -> {
        let data = option.unwrap(query.data, "")
        let token = case string.split(data, ":") {
          [_prefix, token, ..] -> token
          _ -> data
        }
        let resume_data =
          dict.from_list([
            #("callback_data", data),
            #("__wait_result", instance.encode_callback_wait_result(data)),
          ])
        engine.resume_with_token(flow, ctx, token, Some(resume_data))
      }
      _ -> Ok(ctx)
    }
  }
}

fn resume_handler_with_keyboard(
  flow: Flow(step_type, session, error),
  callback_data: keyboard.KeyboardCallbackData(String),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, upd) {
    case upd {
      update.CallbackQueryUpdate(query:, ..) -> {
        let data = option.unwrap(query.data, "")
        let wait_result_value = instance.encode_callback_wait_result(data)
        let resume_data =
          dict.from_list([
            #("callback_data", data),
            #("__wait_result", wait_result_value),
          ])
        case keyboard.unpack_callback(data, callback_data) {
          Ok(callback) ->
            engine.resume_with_token(
              flow,
              ctx,
              callback.data,
              Some(resume_data),
            )
          Error(_) -> {
            let token = case string.split(data, ":") {
              [_prefix, token, ..] -> token
              _ -> data
            }
            engine.resume_with_token(flow, ctx, token, Some(resume_data))
          }
        }
      }
      _ -> Ok(ctx)
    }
  }
}
