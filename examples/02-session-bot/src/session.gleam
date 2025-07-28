import telega

import bot/storage

pub type NameBotState {
  SetName
  WaitName
}

pub type NameBotSession {
  NameBotSession(name: String, state: NameBotState)
}

fn default_session() {
  NameBotSession(name: "Unknown", state: WaitName)
}

pub fn attach(bot) {
  let assert Ok(session_storage) = storage.start()

  telega.with_session_settings(
    bot,
    default_session:,
    get_session: fn(key) { storage.get(session_storage, key) |> Ok },
    persist_session: fn(key, session) {
      storage.set(session_storage, key, session)

      Ok(session)
    },
  )
}
