//// Drive a compiled dialog in tests, without a bot or a network.
////
//// This is the "level 2" harness from `docs/dialogs.md`: it stands in for the
//// flow registry's auto-resume, loading the waiting instance from storage and
//// resuming it with the same payloads the registry's callback/text/photo
//// handlers would build. Pair it with `telega/testing/mock` and
//// `telega/testing/render.calls_transcript` to snapshot everything the user
//// would see.
////
//// ```gleam
//// let assert Ok(storage) = flow_storage.create_ets_storage()
//// let assert Ok(built) = my_dialog(storage)
//// let flow = dialog_engine.compile(dialog.compiled(built))
//// let #(client, calls) = testing_dialog.text_client()
////
//// let driver =
////   testing_dialog.driver(flow:, client:, dialog_id: "settings")
////   |> testing_dialog.with_chat(chat_id: 42)
////
//// testing_dialog.start(driver, command: "/settings")
//// testing_dialog.press(driver, data: "dlg:settings:menu:lang:ru")
//// testing_dialog.send_text(driver, text: "Alice")
////
//// mock.get_calls(calls)
//// |> render.calls_transcript
//// |> birdie.snap(title: "settings:happy_path")
//// ```

import gleam/dict
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

import telega/bot.{type Context}
import telega/client.{type TelegramClient}
import telega/dialog/engine as dialog_engine
import telega/flow/engine as flow_engine
import telega/flow/instance
import telega/flow/storage as flow_storage
import telega/flow/types as flow_types
import telega/model/types as model_types
import telega/testing/context
import telega/testing/factory
import telega/testing/mock
import telega/update

/// Everything a dialog needs to be driven: the compiled flow (which carries
/// its own storage), the mock client its renders talk to, and who is talking.
pub opaque type Driver(session, error, dependencies) {
  Driver(
    flow: flow_types.Flow(String, session, error, dependencies),
    client: TelegramClient,
    dialog_id: String,
    chat_id: Int,
    user_id: Int,
    session: session,
    dependencies: dependencies,
  )
}

/// A driver for a `Nil`-session, `Nil`-dependencies dialog — the common case.
/// Chat 1 and user 1 unless `with_chat`/`with_user` say otherwise.
pub fn driver(
  flow flow: flow_types.Flow(String, Nil, error, Nil),
  client client: TelegramClient,
  dialog_id dialog_id: String,
) -> Driver(Nil, error, Nil) {
  Driver(
    flow:,
    client:,
    dialog_id:,
    chat_id: 1,
    user_id: 1,
    session: Nil,
    dependencies: Nil,
  )
}

/// `driver` for a dialog with its own session and injected dependencies.
pub fn driver_with(
  flow flow: flow_types.Flow(String, session, error, dependencies),
  client client: TelegramClient,
  dialog_id dialog_id: String,
  session session: session,
  dependencies dependencies: dependencies,
) -> Driver(session, error, dependencies) {
  Driver(
    flow:,
    client:,
    dialog_id:,
    chat_id: 1,
    user_id: 1,
    session:,
    dependencies:,
  )
}

/// Drive the dialog in a different chat — one driver per chat keeps
/// concurrent-dialog tests apart.
pub fn with_chat(
  driver: Driver(session, error, dependencies),
  chat_id chat_id: Int,
) -> Driver(session, error, dependencies) {
  Driver(..driver, chat_id:)
}

/// Drive the dialog as a different user.
pub fn with_user(
  driver: Driver(session, error, dependencies),
  user_id user_id: Int,
) -> Driver(session, error, dependencies) {
  Driver(..driver, user_id:)
}

/// The flow instance id this driver reads and writes — useful for asserting
/// on the persisted state directly.
pub fn instance_id(driver: Driver(session, error, dependencies)) -> String {
  instance_id_for(
    dialog_id: driver.dialog_id,
    chat_id: driver.chat_id,
    user_id: driver.user_id,
  )
}

/// The flow instance id a dialog persists under, without a driver.
pub fn instance_id_for(
  dialog_id dialog_id: String,
  chat_id chat_id: Int,
  user_id user_id: Int,
) -> String {
  flow_storage.generate_id(
    user_id,
    chat_id,
    dialog_engine.flow_name_prefix <> dialog_id,
  )
}

/// The persisted instance, or `None` once the dialog has finished.
pub fn instance(
  driver: Driver(session, error, dependencies),
) -> Option(flow_types.FlowInstance) {
  case driver.flow.storage.load(instance_id(driver)) {
    Ok(found) -> found
    Error(_) -> None
  }
}

/// Start (or resume) the dialog the way its start command would.
pub fn start(
  driver: Driver(session, error, dependencies),
  command command: String,
) -> Nil {
  let ctx =
    context_for(
      driver,
      factory.text_update_with(
        text: command,
        from_id: driver.user_id,
        chat_id: driver.chat_id,
      ),
    )
  let assert Ok(_) =
    flow_engine.start_or_resume(
      driver.flow,
      ctx,
      user_id: driver.user_id,
      chat_id: driver.chat_id,
      initial_data: dict.new(),
    )
  Nil
}

/// Deliver a button press to the waiting dialog.
pub fn press(
  driver: Driver(session, error, dependencies),
  data data: String,
) -> Nil {
  factory.callback_query_update_with(
    data:,
    from_id: driver.user_id,
    chat_id: driver.chat_id,
  )
  |> resume_with_callback(driver, data, _)
}

/// Deliver a press coming from a message other than the live one — a button
/// on an outdated copy of the dialog.
pub fn press_on_message(
  driver: Driver(session, error, dependencies),
  data data: String,
  message_id message_id: Int,
) -> Nil {
  callback_update_on_message(
    data:,
    user_id: driver.user_id,
    chat_id: driver.chat_id,
    message_id:,
  )
  |> resume_with_callback(driver, data, _)
}

/// Deliver a text message to the waiting dialog.
pub fn send_text(
  driver: Driver(session, error, dependencies),
  text text: String,
) -> Nil {
  let ctx =
    context_for(
      driver,
      factory.text_update_with(
        text:,
        from_id: driver.user_id,
        chat_id: driver.chat_id,
      ),
    )
  resume(driver, ctx, [
    #("user_input", text),
    #(instance.wait_result_key, instance.encode_text_wait_result(text)),
  ])
}

/// Deliver a photo to the waiting dialog, the way the flow registry's photo
/// auto-resume does.
pub fn send_photo(
  driver: Driver(session, error, dependencies),
  file_ids file_ids: List(String),
) -> Nil {
  let joined = string.join(file_ids, ",")
  let ctx =
    context_for(
      driver,
      factory.photo_update_with(
        photos: list.map(file_ids, fn(id) {
          factory.photo_size_with(file_id: id)
        }),
        from_id: driver.user_id,
        chat_id: driver.chat_id,
      ),
    )
  resume(driver, ctx, [
    #("__photo_file_ids", joined),
    #(instance.wait_result_key, "photo:" <> joined),
  ])
}

/// Mock client for text-only dialogs: `answerCallbackQuery` → `true`,
/// everything else → a valid `Message`.
pub fn text_client() -> #(TelegramClient, Subject(mock.ApiCall)) {
  mock.routed_client(routes: [
    mock.route_with_response(
      path_contains: "answerCallbackQuery",
      response: mock.bool_response(),
    ),
  ])
}

/// Mock client for dialogs that recreate the live message (media windows,
/// sub-dialogs): additionally answers `deleteMessage` with `true`.
pub fn media_client() -> #(TelegramClient, Subject(mock.ApiCall)) {
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

fn context_for(
  driver: Driver(session, error, dependencies),
  upd: update.Update,
) -> Context(session, error, dependencies) {
  let ctx =
    context.context_with_all(
      session: driver.session,
      update: upd,
      key: int_key(driver),
      bot_info: factory.bot_user(),
      dependencies: driver.dependencies,
    )
  bot.Context(..ctx, config: context.config_with_client(driver.client))
}

fn int_key(driver: Driver(session, error, dependencies)) -> String {
  string.inspect(driver.chat_id) <> ":" <> string.inspect(driver.user_id)
}

fn resume_with_callback(
  driver: Driver(session, error, dependencies),
  data: String,
  upd: update.Update,
) -> Nil {
  // Every press here reuses one query id, which Telegram never does. Each
  // press gets its own `Context` — and so its own `Scope` — so the previous
  // press's "already answered" mark is out of reach, exactly as it would be
  // between two real updates.
  resume(driver, context_for(driver, upd), [
    #("callback_data", data),
    #(instance.wait_result_key, instance.encode_callback_wait_result(data)),
  ])
}

fn resume(
  driver: Driver(session, error, dependencies),
  ctx: Context(session, error, dependencies),
  data: List(#(String, String)),
) -> Nil {
  let assert Ok(Some(inst)) = driver.flow.storage.load(instance_id(driver))
  let assert Ok(_) =
    flow_engine.resume_with_instance(
      driver.flow,
      ctx,
      inst,
      Some(dict.from_list(data)),
    )
  Nil
}

fn callback_update_on_message(
  data data: String,
  user_id user_id: Int,
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
