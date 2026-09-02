//// Thin wrapper over the **shipped** driver (`telega/testing/dialog`), kept
//// so the existing dialog tests read the way they always did — and so the
//// harness users get is the one this suite exercises.

import telega/bot
import telega/client.{type TelegramClient}
import telega/error
import telega/flow/types as flow_types
import telega/testing/context
import telega/testing/dialog as testing_dialog
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

fn driver_for(
  flow: DialogFlow,
  client: TelegramClient,
  chat_id: Int,
  dialog_id: String,
) -> testing_dialog.Driver(Nil, error.TelegaError, Nil) {
  testing_dialog.driver(flow:, client:, dialog_id:)
  |> testing_dialog.with_chat(chat_id:)
  |> testing_dialog.with_user(user_id:)
}

/// Instance id of a dialog's flow (`__dialog:<dialog_id>`) for the shared
/// test user.
pub fn flow_id(chat_id: Int, dialog_id: String) -> String {
  testing_dialog.instance_id_for(dialog_id:, chat_id:, user_id:)
}

/// Start (or resume) a dialog flow the way its start command would.
pub fn start_dialog(
  flow: DialogFlow,
  client: TelegramClient,
  chat_id: Int,
  command command: String,
) -> Nil {
  testing_dialog.start(driver_for(flow, client, chat_id, ""), command:)
}

/// Deliver a button press to the waiting dialog instance.
pub fn press(
  flow: DialogFlow,
  client: TelegramClient,
  _storage: DialogStorage,
  chat_id: Int,
  dialog_id: String,
  data: String,
) -> Nil {
  testing_dialog.press(driver_for(flow, client, chat_id, dialog_id), data:)
}

/// Deliver a button press whose callback query carries a custom
/// `message_id` — a press on a message other than the tracked live one.
pub fn press_on_message(
  flow: DialogFlow,
  client: TelegramClient,
  _storage: DialogStorage,
  chat_id: Int,
  dialog_id: String,
  data: String,
  message_id message_id: Int,
) -> Nil {
  testing_dialog.press_on_message(
    driver_for(flow, client, chat_id, dialog_id),
    data:,
    message_id:,
  )
}

/// Deliver a text message to the waiting dialog instance.
pub fn send_text(
  flow: DialogFlow,
  client: TelegramClient,
  _storage: DialogStorage,
  chat_id: Int,
  dialog_id: String,
  text: String,
) -> Nil {
  testing_dialog.send_text(driver_for(flow, client, chat_id, dialog_id), text:)
}

/// Deliver a photo message to the waiting dialog instance.
pub fn send_photo(
  flow: DialogFlow,
  client: TelegramClient,
  _storage: DialogStorage,
  chat_id: Int,
  dialog_id: String,
  file_ids: List(String),
) -> Nil {
  testing_dialog.send_photo(
    driver_for(flow, client, chat_id, dialog_id),
    file_ids:,
  )
}

pub fn dialog_mock_client() {
  testing_dialog.text_client()
}

pub fn media_mock_client() {
  testing_dialog.media_client()
}
