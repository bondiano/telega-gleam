//// Shared driving harness for dialog engine tests.
////
//// Mimics the flow registry's auto-resume: loads the waiting instance from
//// storage and resumes it with the same `__wait_result` payloads the
//// registry's callback/text handlers would build. Used by `dialog_test`,
//// `dialog_sub_test` and `dialog_widget_test`.

import gleam/dict
import gleam/option.{None, Some}

import telega/bot
import telega/client.{type TelegramClient}
import telega/dialog/engine as dialog_engine
import telega/error
import telega/flow/engine as flow_engine
import telega/flow/instance
import telega/flow/storage as flow_storage
import telega/flow/types as flow_types
import telega/model/types as model_types
import telega/testing/context
import telega/testing/factory
import telega/testing/mock
import telega/update

pub const user_id = 10

pub type Ctx =
  bot.Context(Nil, error.TelegaError, Nil)

pub type DialogFlow =
  flow_types.Flow(String, Nil, error.TelegaError, Nil)

pub type DialogStorage =
  flow_types.FlowStorage(error.TelegaError)

pub fn ctx_for(client: TelegramClient, upd: update.Update) -> Ctx {
  let ctx = context.context_with(session: Nil, update: upd)
  bot.Context(..ctx, config: context.config_with_client(client))
}

/// Instance id of a dialog's flow (`__dialog:<dialog_id>`) for the shared
/// test user.
pub fn flow_id(chat_id: Int, dialog_id: String) -> String {
  flow_storage.generate_id(
    user_id,
    chat_id,
    dialog_engine.flow_name_prefix <> dialog_id,
  )
}

/// Start (or resume) a dialog flow the way its start command would.
pub fn start_dialog(
  flow: DialogFlow,
  client: TelegramClient,
  chat_id: Int,
  command command: String,
) -> Nil {
  let ctx =
    ctx_for(
      client,
      factory.text_update_with(text: command, from_id: user_id, chat_id:),
    )
  let assert Ok(_) =
    flow_engine.start_or_resume(
      flow,
      ctx,
      user_id:,
      chat_id:,
      initial_data: dict.new(),
    )
  Nil
}

/// Deliver a button press to the waiting dialog instance.
pub fn press(
  flow: DialogFlow,
  client: TelegramClient,
  storage: DialogStorage,
  chat_id: Int,
  dialog_id: String,
  data: String,
) -> Nil {
  let upd =
    factory.callback_query_update_with(data:, from_id: user_id, chat_id:)
  resume_with_callback(flow, client, storage, chat_id, dialog_id, data, upd)
}

/// Deliver a button press whose callback query carries a custom
/// `message_id` — a press on a message other than the tracked live one.
pub fn press_on_message(
  flow: DialogFlow,
  client: TelegramClient,
  storage: DialogStorage,
  chat_id: Int,
  dialog_id: String,
  data: String,
  message_id message_id: Int,
) -> Nil {
  let upd = callback_update_on_message(data:, chat_id:, message_id:)
  resume_with_callback(flow, client, storage, chat_id, dialog_id, data, upd)
}

fn resume_with_callback(
  flow: DialogFlow,
  client: TelegramClient,
  storage: DialogStorage,
  chat_id: Int,
  dialog_id: String,
  data: String,
  upd: update.Update,
) -> Nil {
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, dialog_id))
  let ctx = ctx_for(client, upd)
  let resume =
    dict.from_list([
      #("callback_data", data),
      #(instance.wait_result_key, instance.encode_callback_wait_result(data)),
    ])
  let assert Ok(_) =
    flow_engine.resume_with_instance(flow, ctx, inst, Some(resume))
  Nil
}

/// Deliver a text message to the waiting dialog instance.
pub fn send_text(
  flow: DialogFlow,
  client: TelegramClient,
  storage: DialogStorage,
  chat_id: Int,
  dialog_id: String,
  text: String,
) -> Nil {
  let assert Ok(Some(inst)) = storage.load(flow_id(chat_id, dialog_id))
  let ctx =
    ctx_for(client, factory.text_update_with(text:, from_id: user_id, chat_id:))
  let resume =
    dict.from_list([
      #("user_input", text),
      #(instance.wait_result_key, instance.encode_text_wait_result(text)),
    ])
  let assert Ok(_) =
    flow_engine.resume_with_instance(flow, ctx, inst, Some(resume))
  Nil
}

/// A `CallbackQueryUpdate` whose `query.message` has the given `message_id`
/// (the factory default is always `1`).
pub fn callback_update_on_message(
  data data: String,
  chat_id chat_id: Int,
  message_id message_id: Int,
) -> update.Update {
  let from = factory.user_with(id: user_id, first_name: "TestUser")
  let chat = factory.chat_with(id: chat_id, type_: "private")
  let msg =
    model_types.Message(
      ..factory.message_with(text: "", from:, chat:),
      message_id:,
    )
  let query =
    model_types.CallbackQuery(
      id: "test_callback_query",
      from:,
      message: Some(model_types.MessageMaybeInaccessibleMessage(msg)),
      inline_message_id: None,
      chat_instance: "test_chat_instance",
      data: Some(data),
      game_short_name: None,
    )
  let raw =
    model_types.Update(
      ..factory.raw_update(message: msg),
      message: None,
      callback_query: Some(query),
    )
  update.CallbackQueryUpdate(query:, from_id: user_id, chat_id:, raw:)
}

/// Mock client for text-only dialogs: `answerCallbackQuery` → `true`,
/// everything else → a valid `Message`.
pub fn dialog_mock_client() {
  mock.routed_client(routes: [
    mock.route_with_response(
      path_contains: "answerCallbackQuery",
      response: mock.bool_response(),
    ),
  ])
}

/// Mock client for dialogs that recreate the live message (media windows,
/// sub-dialogs): additionally answers `deleteMessage` with `true`.
pub fn media_mock_client() {
  mock.routed_client(routes: [
    mock.route_with_response(
      path_contains: "answerCallbackQuery",
      response: mock.bool_response(),
    ),
    mock.route_with_response(
      path_contains: "deleteMessage",
      response: mock.bool_response(),
    ),
  ])
}
