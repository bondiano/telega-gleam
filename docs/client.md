# Client: transformers, default parse mode, retries

`telega/client` is the HTTP layer every API call goes through. This guide
covers the three knobs it exposes beyond picking a `fetch_client` adapter:
request transformers (middleware around every call), a default parse mode
for reply helpers, and the retry behavior on rate limits.

## Request transformers

A transformer is middleware around a single outgoing API call — the same idea
as `api.config.use()` in grammY. It receives the request and a `next`
continuation, and can:

- modify the request before passing it on,
- short-circuit the chain and return a result without calling `next`,
- inspect or transform the result after `next` returns.

```gleam
pub type ApiRequestTransformer =
  fn(
    TelegramApiRequest,
    fn(TelegramApiRequest) -> Result(Response(String), TelegaError),
  ) ->
    Result(Response(String), TelegaError)
```

Register transformers with `client.use_transformer`. The first added is the
outermost: it sees the request first and the result last.

```gleam
import gleam/io
import telega/client

let log_calls = fn(request, next) {
  io.println("→ " <> client.request_method(request))
  let result = next(request)
  io.println("← " <> client.request_method(request))
  result
}

let api_client =
  client.new(token:, fetch_client:)
  |> client.use_transformer(log_calls)
```

### Inspecting and rewriting requests

`TelegramApiRequest` is opaque; use the accessors:

- `client.request_method(request)` — the API method name (`"sendMessage"`);
- `client.request_body(request)` — the JSON body as `Option(String)`
  (`None` for GET requests);
- `client.map_request_body(request, mapper)` — rewrite the JSON body of a
  POST request (GET requests pass through unchanged).

```gleam
let tag_messages = fn(request, next) {
  case client.request_method(request) {
    "sendMessage" ->
      next(client.map_request_body(request, add_tracking_field))
    _ -> next(request)
  }
}
```

Short-circuiting is useful in tests and for client-side guards:

```gleam
let block_all = fn(_request, _next) {
  Error(error.FetchError("blocked in tests"))
}
```

### Where transformers run

Transformers run *inside* the `telega.api_call` telemetry span, so their
latency counts toward the span duration. `next` leads into the request queue
(if configured) or the plain retry loop, and finally into your `fetch_client`.

Raw file uploads (`multipart/form-data`) go through the same chain. Their body
is binary, so `request_body` returns `None` and `map_request_body` leaves them
unchanged; everything else — reading the method, short-circuiting, inspecting
the result — works exactly as for a JSON call.

## Default parse mode

Setting `parse_mode` on every call gets old fast. Configure it once on the
client:

```gleam
import telega/client
import telega/format

let api_client =
  client.new(token:, fetch_client:)
  |> client.set_default_parse_mode(format.HTML)
```

The `telega/reply` helpers that previously sent no parse mode — `with_text`,
`with_markup`, and `edit_text` (when `parameters.parse_mode` is `None`) — now
use the client's default. Helpers with an explicit format (`with_html`,
`with_markdown`, `with_markdown_v2`, `with_formatted`, ...) and parameters
that already set a parse mode are unaffected.

Calls made directly through `telega/api` with hand-built parameters are also
unaffected — the default lives in the client but is applied by the reply
helpers, not by rewriting request bodies.

## Retries

Every call is repeated according to the client's `RetryPolicy`, whether or not
a request queue is configured:

```gleam
pub type RetryPolicy {
  RetryPolicy(
    max_attempts: Int,               // 4 — the first attempt counts
    base_delay_ms: Int,              // 1000, doubling each further attempt
    max_delay_ms: Int,               // 30_000 — cap on the doubling
    jitter: Bool,                    // True
    retry_on_server_errors: RetryOn, // OnlyIdempotent
    retry_on_transport_errors: RetryOn, // OnlyIdempotent
    max_retry_after_ms: Int,         // 60_000 — cap on honouring a 429
  )
}

pub type RetryOn {
  Never
  OnlyIdempotent
  Always
}
```

```gleam
client.new(token:, fetch_client:)
|> client.set_retry_policy(
  client.RetryPolicy(
    ..client.default_retry_policy(),
    max_attempts: 6,
    base_delay_ms: 250,
    // this caller deduplicates its own sends, so replaying one is safe
    retry_on_transport_errors: client.Always,
  ),
)
```

- **429 Too Many Requests** — the client reads `parameters.retry_after`
  (seconds) from the response body and sleeps exactly that long before
  retrying; if the field is missing it falls back to `base_delay_ms`. Telegram
  answers a 429 *instead of* doing the work, so this retry is safe for every
  method whatever `retry_on_*` says. A `retry_after` longer than
  `max_retry_after_ms` is **not** slept off — blocking the calling chat
  instance for minutes is worse than the failure, so the 429 response is
  returned to the caller.
- **Transport errors and 5xx** — repeated according to `retry_on_transport_errors`
  and `retry_on_server_errors`. The default, `OnlyIdempotent`, repeats a call
  only when replaying it cannot duplicate anything: a lost response to
  `sendMessage` says nothing about whether the message was posted. Which
  methods those are is not guessed from the name at runtime — it is a table
  generated from the Bot API spec (`telega/internal/method_info`), so every one
  of the API's 185 methods is classified and a new API version cannot add an
  unclassified one.
- **Backoff** — `base_delay_ms`, doubling, capped at `max_delay_ms`. With
  `jitter` (the default) each delay is spread over the upper half of its
  window, so a fleet of bots coming back from the same outage does not hit the
  API in lockstep.

`set_max_retry_attempts` and `set_max_retry_delay` are shorthands for
`max_attempts` (which counts the first attempt: `set_max_retry_attempts(0)` is
`max_attempts: 1`) and `max_retry_after_ms`.

Each retry emits a `telega.api_call.retry` telemetry event carrying the actual
delay in `retry_after` (milliseconds).

## Rate limits: the request queue

For proactive rate limiting — staying under the limits rather than reacting to
429s — start the client with a queue:

```gleam
let assert Ok(api_client) =
  client.new_with_default_limits(token:, fetch_client:)
```

That configures Telegram's documented limits: 30 requests per second overall,
**1 per second to any one private chat**, and **20 per minute to any one
group, supergroup or channel**. The per-chat rules are created as chats appear
and dropped again after a minute of quiet, so a bot answering many chats does
not carry a rule for every chat it has ever replied to. Which chat a call is
addressed to is read off the outgoing request; a `@username` chat and a raw
upload (whose body is binary, not JSON) have no numeric `chat_id` there and are
paced by the global rules only.

`client.set_request_queue` takes the whole configuration if you want different
numbers; `per_chat: None` turns per-chat pacing off and leaves only the global
rules.

The queue decides *when* a call may run; the call itself runs in its own
process, so queued calls are concurrent up to `overall_limit` and a slow call
never stalls the others. A call that still fails after the client's own retries
is re-queued up to `max_retries` times with an exponential backoff
(`retry_delay`, doubling each attempt, capped at 30 seconds).

**`getUpdates` never goes through the queue.** A long poll holds its slot for
the whole polling timeout (30 s by default) while Telegram rate-limits nothing
about it, so queueing it would spend a concurrency slot the bot needs for its
replies. Only the polling worker calls it, one call at a time.

## Keeping a chat action alive (`telega/chat_action`)

Telegram clears a chat action indicator ("typing…", "sending photo…") about
5 seconds after `sendChatAction`, so a single call is not enough for a
long-running handler. `chat_action.with_action` sends the action immediately
and re-sends it every ~4 seconds until the wrapped function returns:

```gleam
import telega/chat_action

fn handler(ctx, _) {
  use <- chat_action.with_action(ctx, chat_action.Typing)
  // long-running work: LLM call, file processing, etc.
  reply.with_text(ctx, "Done!")
}
```

`with_action_every` accepts a custom interval in milliseconds — useful for
tests and long uploads.

The repeating sender runs in an unlinked worker process that monitors the
caller. It stops when the wrapped function returns or when the calling
process dies, so no processes leak even if the handler crashes — and a
worker failure never takes the handler down.
