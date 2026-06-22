//// Tests for the `dependencies` DI container slot on `Context`.
////
//// `dependencies` holds non-persisted services (db pool, http client, i18n catalog).
//// Unlike `session`, it is set once at bot init and never persisted. These
//// tests verify a handler can read services from `ctx.dependencies` and that mock
//// services can be substituted in tests via `context_with_dependencies`.

import gleam/option.{None}
import gleam/result
import gleeunit
import gleeunit/should

import telega
import telega/bot.{type Context, Context}
import telega/error.{type TelegaError}
import telega/reply
import telega/router
import telega/testing/context as test_context
import telega/testing/conversation
import telega/testing/mock

pub fn main() {
  gleeunit.main()
}

/// A mock "service" — stands in for something like a db pool or http client.
type Service {
  Service(greeting: String, calls: Int)
}

/// Handler reads its dependency straight from `ctx.dependencies`, not `session`.
fn greet_handler(
  ctx: Context(Nil, TelegaError, Service),
) -> Result(Context(Nil, TelegaError, Service), TelegaError) {
  let service = ctx.dependencies
  use _ <- result.map(reply.with_text(ctx, service.greeting))
  ctx
}

pub fn handler_reads_service_from_dependencies_test() {
  let #(client, _calls) = mock.message_client()
  let cfg = test_context.config_with_client(client)

  // Inject a mock service via dependencies.
  let ctx =
    Context(
      ..test_context.context_with_dependencies(
        session: Nil,
        dependencies: Service(greeting: "hello from dependencies", calls: 0),
      ),
      config: cfg,
    )

  ctx.dependencies.greeting
  |> should.equal("hello from dependencies")

  let assert Ok(out) = greet_handler(ctx)
  // dependencies is carried through unchanged (it is not persisted/mutated like session).
  out.dependencies.greeting
  |> should.equal("hello from dependencies")
}

pub fn dependencies_default_is_nil_test() {
  // The plain testing builders default dependencies to Nil so no-dependencies bots are simple.
  let ctx = test_context.context(session: "state")
  ctx.dependencies
  |> should.equal(Nil)
}

/// End-to-end: a `dependencies`-typed router driven through the actor-based
/// conversation runner. The handler reads its greeting from `ctx.dependencies`.
fn dependencies_router() -> router.Router(Nil, TelegaError, Service) {
  router.new("dependencies-bot")
  |> router.on_command(
    "hello",
    fn(ctx: Context(Nil, TelegaError, Service), _cmd) {
      use _ <- result.map(reply.with_text(ctx, ctx.dependencies.greeting))
      ctx
    },
  )
}

pub fn run_with_deps_drives_actor_handler_test() {
  conversation.conversation_test()
  |> conversation.send("/hello")
  |> conversation.expect_reply_containing("hi from injected dependencies")
  |> conversation.run_with_dependencies(
    dependencies_router(),
    fn() { Nil },
    Service(greeting: "hi from injected dependencies", calls: 0),
  )
}

pub fn dependencies_is_independent_of_session_test() {
  // session and dependencies are distinct slots: updating session leaves dependencies intact.
  let ctx =
    test_context.context_with_dependencies(
      session: 0,
      dependencies: Service(greeting: "svc", calls: 7),
    )
  let next = Context(..ctx, session: 99)

  next.session |> should.equal(99)
  next.dependencies.calls |> should.equal(7)
}

/// A conversation that suspends on `wait_text` and, on resume, reads `dependencies`.
/// The continuation runs in a *fresh* `Context` rebuilt by the chat actor from
/// its stored `dependencies` — so this is the real test that `dependencies` survives the
/// suspend/resume round-trip (not just a single synchronous handler call).
fn greet_after_name(ctx: Context(Nil, TelegaError, Service), _cmd) {
  use _ <- result.try(reply.with_text(ctx, "What's your name?"))
  use ctx: Context(Nil, TelegaError, Service), name <- telega.wait_text(
    ctx,
    or: None,
    timeout: None,
  )
  // `ctx` here is the resumed context; `ctx.dependencies` must still be the injected service.
  use _ <- result.map(reply.with_text(
    ctx,
    ctx.dependencies.greeting <> ", " <> name,
  ))
  ctx
}

fn wait_deps_router() -> router.Router(Nil, TelegaError, Service) {
  router.new("dependencies-wait-bot")
  |> router.on_command("start", greet_after_name)
}

pub fn deps_survive_wait_continuation_test() {
  conversation.conversation_test()
  |> conversation.send("/start")
  |> conversation.expect_reply_containing("What's your name?")
  |> conversation.send("Alice")
  |> conversation.expect_reply_containing("hi-from-dependencies, Alice")
  |> conversation.run_with_dependencies(
    wait_deps_router(),
    fn() { Nil },
    Service(greeting: "hi-from-dependencies", calls: 0),
  )
}
