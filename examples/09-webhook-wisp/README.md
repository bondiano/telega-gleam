# Telega Webhook Bot — health, idempotency, graceful drain

The same echo bot as `00-echo-bot`, but reachable over a **webhook** and wired
for a real deployment. Long polling needs none of this; a webhook needs all of
it.

## Setup

1. Get a bot token from [@BotFather](https://t.me/BotFather).
2. Expose the server publicly over **HTTPS** — Telegram will not POST to plain
   HTTP. In development, [ngrok](https://ngrok.com/) or
   [cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
   gives you a URL in one command.

```sh
export BOT_TOKEN="123456:your-token-here"
export SERVER_URL="https://your-tunnel.example.com"   # public base URL
export WEBHOOK_PATH="webhook"                          # optional, default "webhook"
export BOT_SECRET_TOKEN="$(openssl rand -hex 32)"      # optional, generated if unset
export PORT=8000                                       # optional

gleam run
```

`telega.start()` calls `setWebhook` for you, so Telegram starts POSTing to
`$SERVER_URL/$WEBHOOK_PATH` as soon as the bot is up.

## What it shows

### The health endpoint

```sh
$ curl -s localhost:8000/healthz
{"status":"healthy","in_flight":0,"chat_instances":0}
```

`telega_wisp.handle_health` answers `200` while the bot actor is alive,
accepting updates and below the in-flight cap, and `503` with the same shape
(`draining`, `overloaded`, `unavailable`) otherwise. Point your load balancer
or Kubernetes readiness probe at it: a node that is draining or wedged leaves
rotation instead of black-holing updates.

It is registered **before** `handle_bot` so the probe is answered even while
the bot refuses updates — that is the whole point of a probe.

### Idempotency

Telegram redelivers an update when it does not get a `200` in time — on a slow
handler, a redeploy, or a network blip. Without deduplication that means the
command runs twice, which matters the moment a handler does something
non-idempotent (sends an invoice, grants a reward, charges Stars).

```gleam
|> telega.use_pre_handler(idempotency.deduplicate(storage: store, ttl_ms: 3_600_000))
```

Pre-router middleware runs sequentially inside the single bot actor, so the
read-then-write is race-free even when two copies of an update arrive at once.
The store here is in-memory ETS — per node, gone on restart. Run more than one
instance and you want a shared backend (`telega_storage_redis`,
`telega_storage_postgres`) so a redelivery landing on another node is still
recognised.

### Overload

```gleam
|> telega.with_max_in_flight(500)
```

Above 500 updates being handled at once, the health endpoint reports
`overloaded` and the webhook endpoint answers `503`. Telegram backs off and
redelivers later instead of adding to the pile. Without this call overload is
never reported — there is no useful default, pick it from what your bot can
keep up with.

### Graceful drain

```gleam
|> telega.with_drain_timeout(10_000)
|> telega.with_signal_handlers()
```

On SIGTERM — what fly.io and Kubernetes send when they replace a container —
the bot stops accepting updates, finishes what is in flight (up to 10 s), runs
the shutdown hook and exits. In the meantime `/healthz` says `draining` and the
webhook answers `503`, so the updates that arrive during the deploy are
redelivered to the new instance rather than lost.

### Dead letters

```gleam
|> telega.with_dead_letters(storage.dead_letters_from_storage(
  storage: store,
  retention_ms: Some(604_800_000),
))
```

When a chat instance crashes, the update it was handling is written to storage
with the crash reason instead of vanishing. Read them with
`telega.dead_letters`, feed them back in with `telega.replay_dead_letters`, and
forget one with `telega.drop_dead_letter`.

## Tests

```sh
gleam test
```

The handlers are tested through the conversation DSL, with no server and no
network — the webhook wiring is deployment configuration, not behaviour.

## See also

- [Deployment guide](../../docs/deployment.md) — TLS, platforms, drain, probes
- [`telega/idempotency`](../../src/telega/idempotency.gleam)
- [`telega/webhook_reply`](../../src/telega/webhook_reply.gleam) — answer an
  update inside the webhook response body and save a round-trip
