# Migration: v4

v4 changes four contracts and a handful of names. There is no deprecation
period — the old forms are gone, so each is one mechanical pass — and the
builder pipeline, handlers, sessions, flows and dialogs are untouched.

1. **A storage backend implements two more things.** `KeyValueStorage` gained
   `compare_and_set` and a paged `scan`. Only code that *implements* the
   record is affected; code that *uses* a backend is not.
2. **A reply lands where the update came from.** Every `reply.*` call passes
   the forum topic, business connection and direct-messages topic of the
   update on, so a bot in a forum stops posting to General.
3. **A router composes; `RouterTree` is gone.** Everything the `*_on_tree`
   functions did, the plain ones do.
4. **A pre-handler annotates the update's scope** instead of returning a
   dictionary.

Plus request parameter records that now match Bot API 10.3 — new fields, a few
spec-driven renames — and the removals listed at the end.

## Storage backends

If you wrote your own `KeyValueStorage`, add the two fields:

```gleam
storage.KeyValueStorage(
  get:, set:, set_with_ttl:, delete:,
  // Write only if the key holds `expected` (`None`: absent or expired), as
  // one atomic step; answer whether it was written.
  compare_and_set: fn(key, expected, value, ttl_ms) {
    db_update_if(db, key, expected, value, ttl_ms)
  },
  // One page of live keys in key order, and the cursor of the next page.
  scan: fn(prefix, cursor, limit) {
    use page <- result.map(db_keys(db, prefix, after: cursor, limit:))
    #(page, storage.next_cursor(page, limit))
  },
)
```

`compare_and_set` has to be atomic on the backend — a guarded
`UPDATE … WHERE value = $2 … RETURNING key`, a Lua script — because
`store.update` and the job scheduler rely on it across processes and nodes.
Run `telega/testing/storage.check` from your test suite; it is the contract
as a test, and the one the shipped backends pass.

Callers of `scan` change too:

| v3 | v4 |
| --- | --- |
| `kv.scan(prefix)` | `storage.scan_all(kv, prefix)` — or page yourself with `kv.scan(prefix, cursor, limit)` |
| a hand-written record that only re-types errors | `storage.map_error(kv, fn(err) { … })` |

`telega_storage_sqlite`, `telega_storage_postgres` and `telega_storage_redis`
are released at 4.0.0 with both; `telega/storage/ets` has them.

## Replies land in the topic they were asked in

`reply.with_text` & co., `chat_action`, `payments.send` and a dialog window
now send with the update's `message_thread_id` (a forum topic),
`business_connection_id` and `direct_messages_topic_id`, read through the new
`update.message_thread_id` / `business_connection_id` /
`direct_messages_topic_id`. Nothing to change for a bot in private chats and
plain groups. In a forum, replies move from General into the topic the
message came from — which is what users expect, and a change in behaviour
all the same. A bot that wants General on purpose sends through `api.*` with
`message_thread_id: None`. A handler of `on_business_message` can drop its
hand-built `api.send_message` and `reply.text` like everyone else.

`reply.with_photo_bytes` still sends to the chat only.

## `store.update` is a compare-and-set

It reads, applies your function and writes with `compare_and_set`; if another
instance wrote in between, it reads again and reapplies. Two consequences:

- the function you pass must be **pure** — it can run more than once;
- the advice to key the session by chat for shared counters is withdrawn.
  Keep them in a `store`.

## Router composition

`RouterTree` is gone. `router.append` and `router.branch` add branches to any
`Router`; `compose` / `compose_many` return a `Router`; everything a tree had
of its own is the plain function now.

| v3 | v4 |
| --- | --- |
| `router.tree(name)` | `router.new(name)` |
| `router.tree_fallback(tree, h)` | `router.fallback(r, h)` |
| `router.use_middleware_on_tree(tree, mw)` | `router.use_middleware(r, mw)` |
| `router.with_catch_handler_on_tree(tree, h)` | `router.with_catch_handler(r, h)` |
| `router.tree_name` / `handle_tree` / `tree_routable` | `router.name` / `handle` / `routable` |
| `router.tree_registered_commands` / `tree_allowed_updates` | `router.registered_commands` / `allowed_updates` |
| `telega.router_tree(tree)` | `telega.router(r)` |

One behavioural difference: middleware and the catch handler of a composed
router now wrap whatever handled the update, including branches added after
them and the fallback — which the `*_on_tree` forms never reached.

## Pre-handlers annotate the scope

A pre-handler returns `bot.Continue(annotate: fn(Scope) -> Nil)` instead of
`Continue(annotations: Dict)`, writes typed values into the update's scope, and
handlers read them back with `scope.get`:

```gleam
// v3
bot.Continue(annotations: dict.from_list([#("locale", "de")]))
// ... bot.annotation(ctx, "locale")

// v4
const locale_key: scope.Key(String) = scope.Key("locale")

bot.Continue(annotate: fn(scope) { scope.put(scope, locale_key, "de") })
// ... scope.get(ctx.scope, locale_key)
```

`bot.annotation` and `PreContext.annotations` are gone.

## `Context`

`Context` lives in `telega/context`; `bot.Context` is an alias, so imports keep
working. The record lost `chat_subject`, `start_time` and `annotations`. Build
one by hand (tests, custom runners) with `context.new`, or the helpers in
`telega/testing/context`.

## Request parameter records

Every `*Parameters` record matches Bot API 10.3, and codegen now fails on
drift. Two kinds of change:

- **New fields**, which every record you construct by hand needs as `None`:
  `direct_messages_topic_id` and `suggested_post_parameters` on every `send*`,
  `forward*` and `copy*` record; `message_effect_id` / `video_start_timestamp`
  where the spec has them; `use_independent_chat_permissions` on
  `RestrictChatMemberParameters`; `can_manage_direct_messages` /
  `can_manage_tags` on `PromoteChatMemberParameters`; `business_connection_id`
  / `rich_message` on `EditMessageTextParameters`, whose `text` is now
  `Option(String)`; six fields on `SendDiceParameters`, whose
  `reply_parameters` is a `ReplyParameters`.
- **Renames** to the spec's names:

| v3 | v4 |
| --- | --- |
| `SendLivePhotoParameters.media` | `live_photo` |
| `CreateChatSubscriptionInviteLinkParameters.period` / `amount` | `subscription_period` / `subscription_price` |
| `GetUserPersonalChatMessagesParameters.message_ids` | `limit` |
| `GetManagedBotAccessSettingsParameters.bot_id` | `user_id` |
| `SetManagedBotAccessSettingsParameters` | `user_id`, `is_access_restricted`, `added_user_ids` |
| `AnswerGuestQueryParameters` | `guest_query_id`, `result: InlineQueryResult` |
| `GetBusinessAccountGiftsParameters.exclude_limited` | `exclude_limited_upgradable` / `exclude_limited_non_upgradable` (+ `exclude_from_blockchain`) |

The `reply.*` shortcuts fill all of this in, so most bots touch none of it.

## Smaller changes you may hit

- `client.RequestQueueConfig` lost `retry_delay` and `max_retries`: the queue
  no longer retries, the client's `RetryPolicy` is the only place retries
  happen. Delete the two fields.
- `wait_choice` buttons carry `choice:<index>` instead of a bare index and
  only accept their own presses. Only a test that pressed the raw payload
  notices.
- `api.get_my_commands` returns `Result(List(BotCommand), _)`; it could never
  succeed before.
- The default catch handler logs and keeps the chat instance instead of
  stopping it, as `bot.CatchHandler` always documented.
- A stored job record gained a `claimed` flag; v3 records are read fine.
- `telega_wisp` / `telega_mist` check path, secret and health before reading
  the body, so a wrong secret is `401` where it was `400`/`415`.

## Removed

| Gone | Instead |
| --- | --- |
| `telega/menu_builder` (deprecated in 3.0.0) | a dialog window with `widget.select`, `widget.paged_select` or `widget.list_group` |
| `flow/handler.create_resume_handler`, `create_resume_handler_with_keyboard` | the flow registry resumes callbacks itself |
| `bot.cancel_conversation(bot:, key:)` | `telega.cancel_conversation` / `bot.cancel_conversation_in` |
| `encoder.bot_command_scope_to_json` | `encoder.encode_bot_command_scope` |
| `bot.annotation`, `PreContext.annotations` | `scope.get` (above) |

## Worth adopting while you are here

- `router.with_timeout(ms:, on_timeout:)` on any bot whose handlers call out
  to the network: a hung handler no longer holds its chat for good.
- `reply.with_long_text` for text that may pass 4096 characters;
  `reply.stream_text` now rolls over into a new message by itself.
- `telega.with_command_scopes` for a different `/` menu in DMs and groups.
- Several nodes behind a webhook: see
  [`docs/deployment.md`](deployment.md#several-nodes). Persisted jobs now run
  once across the fleet.

## Checklist

1. Custom storage backend: add `compare_and_set` and the paged `scan`, run
   `testing/storage.check`. Callers: `kv.scan(p)` → `storage.scan_all(kv, p)`;
   error-mapping wrappers → `storage.map_error`.
2. `router.tree*` / `*_on_tree` / `telega.router_tree` → the plain names.
3. Pre-handlers: `Continue(annotations:)` → `Continue(annotate:)`;
   `bot.annotation` → `scope.get`.
4. Hand-built `*Parameters` records: add the new fields, apply the renames.
5. `RequestQueueConfig`: drop `retry_delay` and `max_retries`.
6. Pass a pure function to `store.update`.
7. Bump every `telega_*` package to 4.0.0 together with the core.
