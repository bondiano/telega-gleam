# Deployment and operations

Running a telega bot in production. Everything here is about the BEAM node
around the bot — how it starts, how it reports, how it stops, and how it gets
replaced — rather than about the bot's own logic.

- [Building a release](#building-a-release)
- [systemd](#systemd)
- [Docker](#docker)
- [fly.io](#flyio)
- [Health checks](#health-checks)
- [Overload protection](#overload-protection)
- [Graceful shutdown and zero-loss deploys](#graceful-shutdown-and-zero-loss-deploys)
- [Structured logs](#structured-logs)
- [Metrics and traces](#metrics-and-traces)
- [Dead letters](#dead-letters)
- [Hot code reload](#hot-code-reload)

## Building a release

Gleam compiles to Erlang, so a bot ships either as a Gleam project you run with
`gleam run`, or as an OTP release you run with no toolchain on the box. The
release is what you want in production: it bundles the ERTS, boots faster, and
gives you `bin/<app> remote_console` for a live shell.

```sh
gleam export erlang-shipment      # build/erlang-shipment/
./build/erlang-shipment/entrypoint.sh run
```

`erlang-shipment` needs the same OTP major version at build and run time. Build
it inside the image you deploy (see [Docker](#docker)) rather than on a laptop.

The token belongs in the environment, never in the repository:

```gleam
pub fn main() {
  let assert Ok(token) = envoy.get("BOT_TOKEN")
  let client = telega_httpc.new_client(token)
  // ...
}
```

## systemd

Long polling needs no inbound port, which makes it the simplest thing to run
under systemd.

```ini
# /etc/systemd/system/mybot.service
[Unit]
Description=mybot (telega)
After=network-online.target
Wants=network-online.target

[Service]
Type=exec
User=mybot
WorkingDirectory=/opt/mybot
Environment=BOT_TOKEN=...
ExecStart=/opt/mybot/entrypoint.sh run
Restart=always
RestartSec=2
# Give the bot time to drain in-flight updates before SIGKILL.
KillSignal=SIGTERM
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
```

`TimeoutStopSec` has to be comfortably longer than the bot's drain timeout, and
the bot has to be built with `telega.with_signal_handlers()` so SIGTERM runs
`telega.shutdown` instead of killing the VM outright:

```gleam
telega.new(api_client)
|> telega.router(router)
|> telega.with_drain_timeout(10_000)
|> telega.with_signal_handlers()
|> telega.start()
```

## Docker

Build in a Gleam image, run on a slim Erlang one — the runtime image needs no
compiler.

```dockerfile
FROM ghcr.io/gleam-lang/gleam:v1.12.0-erlang-alpine AS build
WORKDIR /app
COPY gleam.toml manifest.toml ./
RUN gleam deps download
COPY src ./src
RUN gleam export erlang-shipment

FROM erlang:27-alpine
RUN adduser -D bot
WORKDIR /app
COPY --from=build /app/build/erlang-shipment ./
USER bot
ENTRYPOINT ["./entrypoint.sh"]
CMD ["run"]
```

Two details that bite:

- **`STOPSIGNAL`** is `SIGTERM` by default, which is what you want — pair it
  with `docker stop --timeout` longer than the drain timeout.
- **Use `exec` form** for `ENTRYPOINT` (as above). The shell form puts `sh`
  between Docker and the VM, and `sh` does not forward signals.

## fly.io

Long polling on fly.io needs no HTTP service at all; a webhook bot does.

```toml
# fly.toml
app = "mybot"

[env]
  PORT = "8080"

[[services]]
  internal_port = 8080
  protocol = "tcp"

  [[services.http_checks]]
    path = "/healthz"
    interval = "10s"
    timeout = "2s"
    grace_period = "10s"

[deploy]
  strategy = "bluegreen"
```

`kill_signal`/`kill_timeout` (top level in `fly.toml`) default to `SIGINT` and
5 seconds; set `kill_signal = "SIGTERM"` and a `kill_timeout` above the drain
timeout so a deploy drains instead of dropping updates.

## Health checks

`telega.health` asks the bot actor how it is doing. The answer comes out of the
actor's own mailbox, so a bot whose actor has died or wedged reports
`Unavailable` rather than a stale snapshot — which is the point of a health
check.

```gleam
pub type Health {
  Healthy(in_flight: Int, chat_instances: Int)
  Draining(in_flight: Int, chat_instances: Int)
  Overloaded(in_flight: Int, chat_instances: Int, max_in_flight: Int)
  Unavailable
}
```

The webhook adapters ship the endpoint:

```gleam
fn handle_request(bot: Telega(s, e, d), req: Request) -> Response {
  use <- telega_wisp.handle_health(telega: bot, req:, path: "healthz")
  use <- telega_wisp.handle_bot(telega: bot, req:)
  wisp.not_found()
}
```

`GET /healthz` answers `200` with
`{"status":"healthy","in_flight":3,"chat_instances":41}` when the bot is
serving, and `503` with `draining`, `overloaded` or `unavailable` otherwise.
`telega_mist.handle_health` is the same function for mist.

A **polling** bot has no HTTP server, but it can still be probed: expose the
same endpoint from any small server, or check liveness from a cron job through
`telega.health`.

Use it as a *readiness* probe (take the instance out of rotation) rather than a
liveness one: `Draining` and `Overloaded` are healthy states of a working bot,
and restarting on them is exactly wrong.

## Overload protection

`telega.with_max_in_flight(n)` caps how many updates the bot admits to being
behind on. Past that, `health` reports `Overloaded` and the webhook adapters
answer `503` — Telegram backs off and redelivers instead of piling more work
onto a bot that is already behind.

```gleam
telega.new(api_client)
|> telega.router(router)
|> telega.webhook(url:, path:, secret_token:)
|> telega.with_max_in_flight(500)
|> telega.start()
```

Long polling needs no such cap: the worker already stops fetching while
`limit` updates are in flight and resumes as they settle.

Pick `n` from what the bot can actually keep up with. There is no default —
without this call overload is never reported, and the bot queues without bound.

## Graceful shutdown and zero-loss deploys

`telega.shutdown` stops the poller (or starts answering `503`), waits up to
`with_drain_timeout` for in-flight updates to finish, runs `with_on_shutdown`,
and stops the supervision tree. `with_signal_handlers()` wires SIGTERM to it.

The sequence a deploy wants:

1. SIGTERM arrives.
2. The bot stops accepting: the poller stops fetching, the webhook endpoints
   answer `503` (so Telegram retries the update after the deploy).
3. In-flight updates finish, up to the drain timeout.
4. `on_shutdown` releases what the bot owns (pools, files, registrations).
5. The VM exits.

Every timeout in the chain has to be ordered `drain_timeout <
TimeoutStopSec / kill_timeout / terminationGracePeriodSeconds`, or the
orchestrator kills the VM mid-drain.

Sessions survive a restart only as far as their storage does: the built-in ETS
backend lives and dies with the node, so a bot that must not forget needs one
of the `telega_storage_*` packages. Conversations (`wait_*`) never survive a
restart — a suspended continuation is a live process, not data. Flows and
dialogs do, because their state is persisted.

## Structured logs

`telega.log_context` attaches the update's identifiers to Erlang's `logger` as
**process metadata**, so every line written inside it — including lines written
by libraries that know nothing about telega — carries `chat_id`, `from_id`,
`update_id`, `session_key` and `telega_prefix`.

```gleam
fn handler(ctx, _cmd) {
  use ctx <- telega.log_context(ctx, "checkout")
  telega.log_info(ctx, "starting")
  reply.text(ctx, "One moment…")
}
```

Read the fields in a formatter template, or hand them to a JSON formatter:

```erlang
%% sys.config
[{kernel, [{logger_level, info},
           {logger, [{handler, default, logger_std_h,
             #{formatter => {logger_formatter,
                 #{template => [time," ",level,
                                " chat=",chat_id," upd=",update_id," ",
                                msg,"\n"],
                   single_line => true}}}}]}]}].
```

## Metrics and traces

Every stage of the update lifecycle emits a [`telemetry`](https://hexdocs.pm/telemetry/)
event; the full table is in the `telega/telemetry` module docs. The two you
want on a dashboard first:

- `telega.update.stop` — duration per update, with `route` (which route
  claimed it), `router` (which tree branch), `update_type`, `chat_id`,
  `from_id`, `update_id`.
- `telega.api_call.stop` / `.exception` — duration and status per Bot API
  method.

`route` is what turns a flat "p99 update latency" into "p99 for
`command:/report`", and it costs nothing to record: the router already knows.
Inside a handler the same value is available as `router.matched_route(ctx)`.

Attach a handler once at startup, before `telega.start()`:

```gleam
telemetry.attach_many(
  id: "prom",
  events: [["telega", "update", "stop"], ["telega", "api_call", "stop"]],
  handler: fn(_event, measurements, metadata) {
    // observe a histogram keyed by `route` / `method`
  },
)
```

Handlers run **synchronously in the emitting process** — keep them to an ETS
or counter update, and forward anything heavier to your own process (there is
a worked example in the `telega/telemetry` docs).

For traces, `opentelemetry_telemetry` bridges the `start`/`stop`/`exception`
spans directly.

## Dead letters

A handler that panics takes its chat instance down with it. The bot answers the
poller (or the webhook) for the update the instance never finished, so nothing
hangs — but the update is gone, and with it the evidence.

Give the bot a queue and it is kept instead:

```gleam
let assert Ok(kv) = ets.new("bot")   // or a telega_storage_* backend

telega.new(api_client)
|> telega.router(router)
|> telega.with_dead_letters(storage.dead_letters_from_storage(
  kv,
  retention_ms: Some(7 * 24 * 60 * 60 * 1000),
))
|> telega.start()
```

Entries live under the `dlq:` prefix, keyed by `update_id`, holding the raw
update JSON and the crash reason. Read them with `telega.dead_letters`, feed
them back through the bot with `telega.replay_dead_letters` once the bug is
fixed, and forget one with `telega.drop_dead_letter`.

Use a persistent backend for it: the ETS store dies with the node, which is
exactly the moment you wanted the evidence.

## Hot code reload

The BEAM can load a new version of a module into a running node, and telega
does nothing to prevent it — a bot is a supervision tree of ordinary actors.
Two things make it work in practice:

- **Handlers are values, not code paths.** A chat instance holds the router
  handler it was started with. A reloaded module reaches new chat instances
  immediately, and existing ones only when they are restarted — including by
  the 30-minute idle eviction, which is the cheapest way to roll a change
  through a live bot.
- **A suspended `wait_*` continuation is a closure over old code.** Reloading
  twice unloads the old version and kills processes still running it, which
  means every conversation in flight. Flows and dialogs are safe: their state
  is data, and the step that resumes it is looked up by name.

For anything larger than a hot fix, prefer a rolling restart with a drain
(above): it is one mechanism instead of two, and it is the one the deploy
already exercises.
