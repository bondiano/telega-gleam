import carpenter/table
import gleam/option.{None, Some}
import telega

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
  let assert Ok(session_table) =
    table.build("session")
    |> table.privacy(table.Public)
    |> table.set

  telega.with_session_settings(
    bot,
    default_session:,
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
  )
}
