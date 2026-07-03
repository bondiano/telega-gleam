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

## Retries and rate limits

Without a request queue, the client retries failed calls up to
`set_max_retry_attempts` times (default 3):

- **429 Too Many Requests** — the client reads `parameters.retry_after`
  (seconds) from the response body and sleeps exactly that long before
  retrying; if the field is missing it falls back to 1 second.
- **Transport errors** — retried after a fixed 1 second delay.

Each retry emits a `telega.api_call.retry` telemetry event carrying the
actual delay in `retry_after` (milliseconds).

For proactive rate limiting (staying under the limits instead of reacting to
429s), enable the request queue with `client.set_request_queue` — see the
docs in `telega/client`.
