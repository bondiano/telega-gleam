import carpenter/table
import gleam/option.{None, Some}

import telega

pub type NameBotSession {
  NameBotSession(name: String)
}

fn default_session() {
  NameBotSession(name: "Unknown")
}

pub fn attach(bot) {
  let assert Ok(session_table) =
    table.build("session")
    |> table.privacy(table.Public)
    |> table.set

  telega.with_session_settings(
    bot,
    get_session: fn(key) {
      case table.lookup(session_table, key) {
        [#(_, session), ..] -> session |> Some |> Ok
        _ -> Ok(None)
      }
    },
    persist_session: fn(key, session) {
      table.insert(session_table, [#(key, session)])
      Ok(session)
    },
    default_session:,
  )
}
