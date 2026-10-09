# Changelog

All notable changes to the core `telega` package are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

Ecosystem packages (`telega_wisp`, `telega_httpc`, `telega_storage_*`, …) are
versioned independently; entries that change their public API are noted here
under the release that shipped them.

## [Unreleased]

### Added

- **`update.message_thread_id`, `update.business_connection_id`,
  `update.direct_messages_topic_id`.** Where a reply to the update belongs:
  the forum topic the message was sent in (only a topic message, not the
  reply chain of a plain supergroup), the business connection it came
  through, and the direct-messages topic of a channel's direct messages chat.
  A callback query answers for the message under the pressed button.
- **`telega/webhook`**, the gate every webhook adapter runs a request through:
  `admit` (not ours / `401` / `503` / process) and `health_probe`, plus the
  `secret_header` and `default_health_path` constants. `telega_wisp` and
  `telega_mist` are rewritten on it and no longer carry a copy each.
- **`telega/testing/storage.check`**, the contract every `KeyValueStorage`
  backend must meet (get/set/delete, a literal `scan` prefix, TTL expiry), run
  by the ETS, SQLite, Postgres and Redis suites alike.
- **Telemetry event names as constants.** Every event `telega` emits is a
  `pub const` in `telega/telemetry` (`telemetry.update_stop`,
  `telemetry.flow_step`, …) and the module's event table now lists all of
  them, including the nine it was missing (`chat_instance.hibernate`,
  `session.load_error`, `storage.decode_error`, `flow.exit`, `flow.error`,
  `flow.wait_in_step`, `dialog.*`, `job.run`, `job.error`).
- **`error.FetchTimeoutError`.** `telega_httpc` and `telega_hackney` report a
  timed-out request as this variant instead of a `FetchError` whose text had
  to be searched for "Timeout"; the poller matches on it. `error.to_string` no
  longer wraps a `FetchError` reason in quotes.
- **One answer per button press, everywhere.** `reply.answer_callback_once`
  stops a button's spinner unless `reply.answer_toast` / `answer_alert` /
  `answer_quietly` already answered that press; `reply.callback_answered` reads
  the same per-update flag. The dialog engine, the flow registry's callback
  resume and `wait_choice` all call it, so a plain flow step or a `wait_choice`
  no longer leaves the spinner running for a minute. `dialog.alert` and
  `dialog.toast` are the `reply` shortcuts under their dialog names.
- **A command menu per scope.** `telega.with_command_scopes` publishes a
  different `setMyCommands` list per `CommandScope` (`PrivateChats`,
  `GroupChats`, `GroupAdministrators`, `ChatScope(chat_id:)`) — the personal
  loop in a DM, what a group plays together in the group. Each scope names
  commands the router already describes, in the order the menu should read, and
  is published in every locale `with_command_translations` configured. The
  default scope still carries the whole catalog, because it is what an
  unpublished scope falls back to. Guide:
  [`docs/router.md`](docs/router.md#a-different-menu-per-scope).

### Removed

- **`telega/menu_builder`**, deprecated in 3.0.0. A dialog window with
  `widget.select`, `widget.paged_select` or `widget.list_group` renders the
  same menu and keeps its state.
- `flow/handler.create_resume_handler` and `create_resume_handler_with_keyboard`:
  unused since the flow registry took over callback resumption.
- `bot.cancel_conversation(bot:, key:)`, which took the opaque `Bot` no caller
  can hold. `telega.cancel_conversation` and `bot.cancel_conversation_in` stay.
- `encoder.bot_command_scope_to_json`: use the generated
  `encoder.encode_bot_command_scope`.

### Changed

- **A reply lands where the update came from.** Every `reply.*` send, edit
  and chat action, `payments.send` / `create_link`, and a dialog window pass
  the update's `message_thread_id`, `business_connection_id` and
  `direct_messages_topic_id` on (see `update.message_thread_id` and friends).
  A bot answering in a forum topic no longer posts to General, and a handler
  of `on_business_message` can reply with `reply.text` instead of a hand-built
  `api.send_message`. **Breaking** only in effect: a bot that relied on its
  replies landing in General must send through `api.*` with
  `message_thread_id: None`. `reply.with_photo_bytes` still sends to the chat
  only.
- **Request parameter records match Bot API 10.3, and codegen keeps them so.**
  `task codegen` / CI now compares every hand-written `*Parameters` record's
  field names with the spec's method fields and fails on drift. Bringing the
  records up to date added `direct_messages_topic_id` and
  `suggested_post_parameters` to every `send*`, `forward*` and `copy*` record
  (plus `message_effect_id` / `video_start_timestamp` where the spec has them),
  `use_independent_chat_permissions` to `RestrictChatMemberParameters`,
  `can_manage_direct_messages` / `can_manage_tags` to
  `PromoteChatMemberParameters`, and `business_connection_id` / `rich_message`
  to `EditMessageTextParameters`, whose `text` is now `Option(String)`.
  `SendDiceParameters` gained the six fields it was missing and its
  `reply_parameters` is a `ReplyParameters` (it was typed as a reply keyboard).
  **Breaking** renames to match the spec: `SendLivePhotoParameters.media` →
  `live_photo`; `CreateChatSubscriptionInviteLinkParameters.period` / `amount`
  → `subscription_period` / `subscription_price`;
  `GetUserPersonalChatMessagesParameters.message_ids` → `limit`;
  `GetManagedBotAccessSettingsParameters.bot_id` → `user_id`;
  `SetManagedBotAccessSettingsParameters` is `user_id`, `is_access_restricted`,
  `added_user_ids`; `AnswerGuestQueryParameters` is `guest_query_id` plus
  `result: InlineQueryResult`; `GetBusinessAccountGiftsParameters.exclude_limited`
  split into `exclude_limited_upgradable` / `exclude_limited_non_upgradable`,
  with `exclude_from_blockchain` added. Every record constructed by hand needs
  the new fields (`None`).
- **`RouterTree` is gone; a `Router` composes.** `append` and `branch` add
  branches to any router, consulted in order after its own routes and before
  its `fallback`; `compose` / `compose_many` return a `Router`. **Breaking:**
  `router.tree`, `tree_fallback`, `use_middleware_on_tree`,
  `with_catch_handler_on_tree`, `tree_name`, `handle_tree`, `tree_routable`,
  `tree_registered_commands`, `tree_allowed_updates` and `telega.router_tree`
  are removed — the plain `fallback`, `use_middleware`, `with_catch_handler`,
  `name`, `handle`, `routable`, `registered_commands`, `allowed_updates` and
  `telega.router` now do the same for a composed router. Middleware and the
  catch handler of a composed router wrap whatever handled the update, so they
  now reach branches added after them and the fallback, which the `*_on_tree`
  forms never did.
- **One callback-data codec.** Dialog buttons (`dlg:…`), widget buttons
  (`w:…`), the yes/no payloads a flow step reads back and `wait_choice`'s
  buttons are all packed and unpacked with `telega/keyboard`'s
  `KeyboardCallbackData` (`render.callback_codec`, `widget.action_codec`,
  `keyboard.bool_callback_data`, `keyboard.int_callback_data("choice")`)
  instead of four hand-written parsers. Wire formats are unchanged except
  `wait_choice`, whose buttons now carry `choice:<index>` instead of a bare
  index and only accept their own presses; a `wait_choice` prompt does not
  survive a restart anyway.
- **`Context` lives in `telega/context`.** `bot.Context` is an alias for the same
  type, so imports keep working; what changed is the record. `chat_subject`
  (unused since `wait_*` stopped messaging the chat instance) and `start_time`
  (never read) are gone, and so is `annotations`. **Breaking:** a pre-handler
  now returns `bot.Continue(annotate: fn(Scope) -> Nil)` instead of
  `Continue(annotations: Dict)`, writes typed values into the update's scope,
  and handlers read them with `scope.get(ctx.scope, key)`. `bot.annotation` and
  `PreContext.annotations` are removed. Build a context by hand with
  `context.new`.

### Fixed

- **`telega_wisp` read and parsed the body before checking the secret**, so a
  request with a wrong token got `400`/`415` instead of `401` and cost a parse.
  Both adapters now check path, secret and health before touching the body.
- **Both webhook adapters panicked on an update that would not decode**, in a
  spawned process, losing the update with only a crash report. They answer
  `400` like `handle_bot_with_reply` always did.
- **The request queue retried on top of the client.** A call that failed after
  the client's own retry loop was re-queued up to three more times, each time
  running the whole loop again (up to 16 HTTP attempts), and the queue did not
  know which methods are idempotent, so a `sendMessage` lost to a transport
  error could be sent twice. The queue no longer retries; `RetryPolicy` is the
  only place retries happen. **Breaking:** `client.RequestQueueConfig` lost its
  `retry_delay` and `max_retries` fields.
- **`replay_dead_letters` dropped letters without running a handler** when
  `idempotency.deduplicate` was installed: the pre-handler had already seen the
  `update_id`, answered `Stop`, and the replay counted as handled. Replays now
  skip the pre-router middleware.
- The two update-kind matches in the chat instance that decide what a pending
  `wait_*` must not swallow and which messages are album parts no longer end in
  a wildcard, so a new Bot API update kind fails to compile until it is placed.
  Album parts arriving as business messages are now gathered like any other.
- **An update queued behind the handler that armed a `wait_*` skipped the
  wait.** The continuation was armed by a message to the chat instance's own
  mailbox, so an update already waiting there was routed first. This hit every
  quick double reply and the re-arming helpers (`wait_number`, `wait_email`,
  `wait_choice`). The wait is now bound as soon as the handler returns.
- **The default catch handler stopped the chat instance.** `bot.CatchHandler`
  documented a default of `Ok(Nil)`, but without `with_catch_handler` the bot
  used `Error(err)`: one failing handler killed that chat's instance and the
  conversation it was waiting on. The default now logs the error and keeps the
  instance.
- **Storage `scan` treated the prefix as a pattern.** `telega_storage_postgres`
  and `telega_storage_sqlite` passed it straight to `LIKE`, so `_` and `%` in a
  prefix (a flow named `my_flow`) matched other characters; `telega_storage_redis`
  passed it to `SCAN MATCH` unescaped. All three now match the prefix literally.
- **`telega_storage_redis.set_with_ttl` sent `SET` then `EXPIRE`** as two
  commands, leaving a key that never expires when the second failed. It sends
  one `SET ... PX`.
- **`setMyCommands` sent `scope` and `language_code` inside each command object**
  instead of beside `commands`, where the Bot API reads them. Telegram dropped
  both, so `with_command_translations` published every language to the DEFAULT
  scope in turn and the last locale won for everybody — a bot with two locales
  showed one of them to all its users. Localized menus now land in their own
  language, and a scope is honored at all.
- **`api.get_my_commands` returned `Result(BotCommand, _)`** and decoded the
  Bot API's array as a single command, so the call could only ever fail. It
  returns `Result(List(BotCommand), _)`. The signature changes, but no working
  call can exist to break.
- `set_my_commands`, `delete_my_commands` and `get_my_commands` no longer send
  `"scope": null` / `"language_code": null` for parameters that were not set.

## [3.0.0] - 2026-09-04

The builder, the router's composition type and the dialog sub-result API all
changed shape. Follow the [v3 migration guide](docs/migration-v3.md). Every
ecosystem package (`telega_wisp`, `telega_mist`, `telega_httpc`,
`telega_hackney`, `telega_webapp`, `telega_i18n`, `telega_storage_*`) is
released at `3.0.0` alongside the core and requires it.

### Added

- **Observability.** `telega.update.stop` / `.exception` now carry `route` (the
  route that claimed the update) and `router` (the leaf router or tree branch),
  plus `update_id` on every phase; readable from a handler via
  `router.matched_route` / `router.matched_router`. `telega.log_context` sets
  Erlang `logger` process metadata (`chat_id`, `from_id`, `update_id`,
  `session_key`) for the duration of a handler.
- **Health and overload.** `telega.health` / `health_within` / `is_healthy` /
  `health_status_code` / `health_to_json` ask the bot actor's own mailbox, so a
  wedged actor reports `Unavailable` instead of a stale snapshot.
  `telega.with_max_in_flight` makes `Overloaded` possible. Both webhook adapters
  gained `handle_health` (`GET /healthz` by default) and gate updates on
  `is_healthy`, so a draining or overloaded node answers `503` and Telegram
  redelivers. Ops guide: [`docs/deployment.md`](docs/deployment.md).
- **Dead-letter queue.** `telega.with_dead_letters` records the updates a
  crashed chat instance left unfinished (raw JSON + crash reason);
  `telega.dead_letters` / `replay_dead_letters` / `drop_dead_letter` read,
  re-dispatch and forget them.
- **Router v3.** `RouterTree` is a separate type for composition
  (`tree` / `append` / `branch` / `compose` / `compose_many`) with tree-level
  settings (`use_middleware_on_tree`, `with_catch_handler_on_tree`,
  `tree_fallback`, `tree_name`, `tree_allowed_updates`,
  `tree_registered_commands`). New dedicated routes: `on_edited_message`,
  `on_channel_post`, `on_edited_channel_post`, `on_business_message`,
  `on_web_app_data`, `on_chat_boost`, `on_removed_chat_boost`,
  `on_paid_media_purchase`, `on_unknown_update`, `on_my_chat_member_updated`,
  and the typed `on_callback_data(factory, handler)`.
- **Shared state and scheduled work.** `telega/store` gives chat-, user- and
  bot-wide values a home beside the session (`chat_data`, `user_data`,
  `global_data`, `custom`, `with_ttl`), read and written straight through.
  `telega/jobs` runs work later — in memory (`run_after`, `run_every`) or
  persisted across restarts (`persisted`, `persisted_every`), on a
  `telega.background_context`.
- **Per-update scratch space.** `telega/scope` — typed `Key(value)` slots
  carried in `Context.scope`, created per update and cleared when it is handled.
- **Errors.** `error.classify` turns a Telegram error into an `ApiErrorKind`
  (`BotBlocked`, `ChatMigrated(new_chat_id:)`, `TooManyRequests(retry_after:)`,
  …); `TelegramApiError` carries Telegram's own `parameters`
  (`error.retry_after`, `error.migrate_to_chat_id`).
- **Replies.** Shortcuts that return the context instead of a `Result` to
  `let assert` on: `reply.text`, `quote`, `remove_keyboard`,
  `edit_callback_message`, `edit_callback_markup`, `answer_toast`,
  `answer_alert`, `answer_quietly`. Escape-free formatting via
  `reply.with_entities` + `format.entities`. Streaming into one growing message
  with `reply.stream_text` / `stream_into`.
- **Client.** A configurable `RetryPolicy` (`RetryOn(Never | OnlyIdempotent |
  Always)`, `set_retry_policy`, `set_max_retry_attempts`,
  `set_max_retry_delay`), `client.trace_transformer` for call logging with the
  token stripped, and `client.cache_get_me`.
- **Bot API coverage.** Every method in the vendored spec now has a wrapper in
  `telega/api`, including multipart uploads for albums that contain local files.
- **Dialogs.** Sub-dialogs nest to any depth on a stack; per-window and
  per-action show modes (`with_show_mode`, `with_window_show_mode`,
  `types.Shown`); the getter pattern (`window_with_data`, `with_data`);
  `on_message` for photos/video/voice/audio/location; `initial_state` receives
  the `Context`; `dialog.refresh` re-renders an open dialog from a background
  context; `dialog.start` / `caller` / `return_to_caller` let one dialog hand
  the screen back to the one that opened it; new `counter`, `calendar` and
  `list_group` widgets.
- **Testing.** The dialog driver ships in the package
  (`telega/testing/dialog`), and `telega/testing/graph` exports a dialog or flow
  as Graphviz DOT / Mermaid.
- **Flows.** Persisted instances carry a `schema_version`;
  `storage.flow_storage_from_storage_with_retention` lets the backend reclaim
  abandoned instances.
- **Sessions.** `telega.with_session_key` (with `bot.default_session_key`,
  `chat_session_key`, `user_session_key`), versioned sessions via
  `storage.session_settings_from_storage_versioned`, and
  `telega.with_session_load_error` (`FailUpdate` / `ReadOnly` / `UseDefault`).
- **Media groups.** Incoming albums are buffered into one `MediaGroupUpdate`
  when `telega.with_media_group_timeout` is set.
- **`allowed_updates`.** `telega.with_extra_allowed_updates` adds kinds static
  derivation cannot see; unknown names are warned about against the generated
  update-kind table.
- **Codegen.** `src/telega/internal/update_info.gleam` and the `raw_to_update`
  dispatch chain are generated from the spec, and codegen fails if `api.gleam`
  does not wrap every spec method. New CI tasks: `task codegen:check`,
  `task api:check`, `task api:latest`, `task lint:totality`.
- **Docs.** `docs/deployment.md`, `docs/migration-v3.md`, `docs/replies.md`,
  and this changelog.
- **Examples.** `07-streaming-bot`, `08-group-bot`, `09-webhook-wisp`,
  `10-inline-and-payments`.

### Changed

- **BREAKING — builder.** One constructor `telega.new(api_client)`; the mode is
  a step (`telega.polling(...)`, the default, or
  `telega.webhook(url:, path:, secret_token:)`); one terminal `telega.start()`
  (`telega.supervised()` under someone else's tree). Bare verbs for the
  pipeline (`dependencies` / `session` / `router` / `router_tree` / `polling` /
  `webhook` / `start` / `supervised`) and `with_*` for every option — no more
  `set_*`. A fourth type parameter marks the builder `Fresh` or `Configured`,
  so calling `dependencies` or `session` after the router is a compile error
  rather than a silently reset router.
- **BREAKING — router composition.** `compose` no longer returns a `Router`:
  composition produces a `RouterTree`, and `on_command` on a tree does not
  compile. Registrations can no longer vanish into a composition.
- **BREAKING — scope.** Every update carries an explicit `Context.scope`;
  library state that used to live in the process dictionary moved there.
- **BREAKING — dialogs.** `on_sub_result` receives the sub-dialog's final state
  in the sub's own type, decoded by the sub's own codec — the untyped result
  dict is gone.
- Updates are dispatched fire-and-forget with in-flight backpressure, so a slow
  handler in one chat no longer blocks other chats or the next `getUpdates`.
- Chat instances are evictable and evicted by default (30-minute idle timeout,
  `telega.with_chat_idle_timeout` / `without_chat_idle_timeout`), and compact
  their heap after a minute of quiet (`telega.with_chat_hibernate_after`).
- A session no handler changed is not written back (`bot.PersistOnChange`);
  `telega.with_session_persistence(bot.PersistAlways)` restores the old
  behaviour.
- Queued requests run concurrently up to the overall limit and share the direct
  path's retry logic; `getUpdates` bypasses the queue entirely.
  `client.new_with_default_limits` configures Telegram's documented limits
  (30/s overall, 1/s per private chat, 20/min per group).
- Both HTTP adapters bound a call at 60 s by default, above the 30-second long
  poll.
- Commands are matched case-insensitively and end at any whitespace.
- Router filters read the sender and the chat's real `type_`, not the shape of
  the update or the sign of a stand-in `chat_id`.
- A non-empty derived `allowed_updates` set always contains `callback_query`.

### Deprecated

- `telega/menu_builder` — use a `telega/dialog` window with `widget.select` /
  `widget.paged_select`, which keeps its state and validates callback data.
  The warning sits on `new`, `new_stateful`, `confirmation` and `settings_menu`.

### Removed

- `flow.instance_to_row` / `instance_from_row` / `FlowInstanceRow` — the flat
  row dropped `history`, `flow_stack` and `parallel_state`.

### Fixed

- Every dispatched update is answered on all exit paths; the bot monitors each
  instance it dispatched to and answers for whatever a crashed one left
  unfinished, so a wedged handler can no longer hang the poller forever.
- Stopped chat instances are deregistered before they stop, so no update is
  delivered to an instance on its way out.
- The update decode path never panics: an unknown update kind or a malformed
  payload becomes `UnknownUpdate`, and `api.get_updates` decodes each update on
  its own so one bad update cannot drop the batch.
- Long polling survives outages — only `401` / `404` stop the worker; `409`,
  rate limits, 5xx and network failures retry with backoff.
- `wait_*` handler filters are enforced when the continuation runs, and a
  command the wait did not ask for falls through to the router (so `/cancel`
  works mid-conversation) instead of being swallowed.
- A **pre-checkout or shipping query** now falls through to the router the same
  way. In a private chat it keys to the same chat instance as the messages, so
  a handler parked on `payments.wait_successful_payment` used to swallow the
  very query Telegram fails the payment over if it goes unanswered for 10
  seconds. Register `router.on_pre_checkout_query` and the two work side by
  side; the wait stays armed through it.
- **`wait_*` timeouts are milliseconds**, as they were always documented — they
  used to be treated as seconds. A `timeout: Some(60)` written against the old
  behaviour now means 60 **ms**, not a minute: multiply every existing wait
  timeout by 1000.
- Flow: errors are reported instead of swallowed, `Back` works across
  conditional transitions, the wait kind is enforced, waiting flows resolve by
  recency, every exit runs the exit hook exactly once, a consumed wait result
  is dropped when a step parks again, and subflows can wait and hand control
  back.
- Dialog: a press is answered exactly once and after the handlers that may want
  to answer it; the callback id survives; handlers are scoped to their own flow;
  the widget stash is cleared when the step returns.
- Client: non-idempotent calls are no longer replayed, the 429 sleep is capped
  (`max_retry_after_ms`, 60 s), multipart headers are sanitised, and uploads run
  through the transformer chain.
- `reply` no longer leaks the webhook secret or the bot token into logs.
- `format` escapes code spans and link URLs per the MarkdownV2 rules.
- `keyboard.unpack_callback` rejects payloads belonging to another callback id
  or that fail to decode, and a grid width below 1 no longer loops forever.
- ETS tables (roles cache, chat registry) are owned by a process that outlives
  the caller, so lookups after a short-lived `main` exits no longer raise
  `badarg`.
- Secret tokens are compared in constant time, and `polling.get_status` /
  `is_running` ask the worker instead of reporting a construction-time snapshot.
- `api`: the `giftPremium` path is correct and `sendAudio` / approve responses
  decode.
- The request queue keeps a slice of the bot-wide rate for the top lane.

## [2.4.1] - 2026-08-28

### Added

- Graph visualization for dialogs and flows (`telega/testing/graph`).

### Fixed

- Callback and text routing picks the most specific matching pattern.

## [2.4.0] - 2026-08-27

### Added

- Bot API 10.3 support.

## [2.3.0] - 2026-07-23

### Added

- Multipart upload support.

### Fixed

- Types for deleting a message reaction ([#44](https://github.com/bondiano/telega-gleam/pull/44)).

## [2.2.1] - 2026-07-17

### Added

- Bot API 10.2 support.

### Fixed

- Callback `Prefix` patterns whose payload contains a colon.

## [2.2.0] - 2026-07-17

### Added

- `telega.supervised` — run the bot under your own supervision tree.

## [2.1.0] - 2026-07-08

### Added

- Declarative dialogs (`telega/dialog`).
- Broadcast (`telega/broadcast`).
- Webhook reply optimization (`telega/webhook_reply`).
- Deep link helpers (`telega/deep_link`).
- Chat actions kept alive during long handlers (`telega/chat_action`).
- `sendPaidMedia` support.
- A transformer extension point for the client (`client.use_transformer`).
- `wait_filtered`.

## [2.0.0] - 2026-06-29

### Added

- Unified storage layer with PostgreSQL, Redis and SQLite backends.
- Telemetry integration (`telega/telemetry`).
- Dependency injection via the `Context` `dependencies` slot.
- Pre-router middleware, webhook idempotency (`telega/idempotency`) and role
  filters (`telega/roles`).
- Graceful shutdown with SIGTERM handling and in-flight draining.
- Auto-published router commands and derived `allowed_updates`.
- Per-user rate limit middleware, inline mode result builders
  (`telega/inline_mode`) and payments helpers (`telega/payments`).
- Ecosystem packages: `telega_mist`, `telega_webapp`, `telega_i18n`.
- The Bot API model generator moved into the repository (`codegen/`).

## Earlier releases

`1.2.0` and older predate this changelog. See the
[commit history](https://github.com/bondiano/telega-gleam/commits/master) and
the [release tags](https://github.com/bondiano/telega-gleam/tags).

[Unreleased]: https://github.com/bondiano/telega-gleam/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/bondiano/telega-gleam/compare/v2.4.1...v3.0.0
[2.4.1]: https://github.com/bondiano/telega-gleam/compare/v2.4.0...v2.4.1
[2.4.0]: https://github.com/bondiano/telega-gleam/compare/v2.3.0...v2.4.0
[2.3.0]: https://github.com/bondiano/telega-gleam/compare/v2.2.1...v2.3.0
[2.2.1]: https://github.com/bondiano/telega-gleam/compare/v2.2.0...v2.2.1
[2.2.0]: https://github.com/bondiano/telega-gleam/compare/v2.1.0...v2.2.0
[2.1.0]: https://github.com/bondiano/telega-gleam/compare/v2.0.0...v2.1.0
[2.0.0]: https://github.com/bondiano/telega-gleam/compare/v1.2.0...v2.0.0
