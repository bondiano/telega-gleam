import telega

import bot/storage

pub type Language {
  English
  Russian
}

pub type LanguageBotSession {
  LanguageBotSession(lang: Language)
}

fn default_session() {
  LanguageBotSession(lang: English)
}

pub fn attach(bot) {
  let assert Ok(session_storage) = storage.start()

  telega.with_session_settings(
    bot,
    get_session: fn(key) { storage.get(session_storage, key) |> Ok },
    persist_session: fn(key, session) {
      storage.set(session_storage, key, session)

      Ok(session)
    },
    default_session:,
  )
}
