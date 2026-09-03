# Telega Group Bot — chat data and persisted jobs

A bot for group chats that keeps three different kinds of state, and a reminder
that survives a restart.

## Setup

1. Get a bot token from [@BotFather](https://t.me/BotFather).
2. `export BOT_TOKEN="your_bot_token_here"`
3. Add the bot to a group (and turn off privacy mode in BotFather if you want it
   to see every message).

```sh
gleam run   # start the bot; state lands in ./group_bot.db
```

## What it shows

### Three scopes, one storage backend

| What | Where | Key |
|---|---|---|
| messages *you* sent in *this* chat | session | `session:{chat_id}:{from_id}` |
| messages *everyone* sent in this chat | `store.chat_data` | `data:chat:{chat_id}` |
| messages across every chat | `store.global_data` | `data:global:messages` |

The chat counter cannot live in a session: each member has their own, and a
member's chat instance would happily overwrite what another member's wrote.
`telega/store` reads and writes the backend directly for exactly that reason —
nothing is cached, so every member sees the same number.

`/stats` prints all three.

### Versioned sessions

`storage.session_settings_from_storage_versioned` wraps the stored session in
`{"v": 1, "d": ...}`. When `Session` grows a field, bump the version and read
the old shape in `migrate` instead of resetting everyone to zero.

### Reminders that survive a restart

`/remind 2 water the plants` schedules a **persisted job**: the handler name,
the chat, the payload and the due time go into SQLite. Stop the bot, start it
again, and the scheduler reads it back and fires it — on a
`telega.background_context`, so replying works exactly as it does in a handler.

```sh
gleam run          # /remind 2 test
# ^C before it fires
gleam run          # the reminder still arrives
```

### A database that is briefly unreadable

`telega.with_session_load_error(bot.ReadOnly)` keeps the bot answering when the
session cannot be read: handlers run on the default session and every write is
skipped, so nothing overwrites the session that is still on disk. The default —
`bot.FailUpdate` — would instead report the update unhandled.
