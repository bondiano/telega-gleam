import gleam/erlang/process
import gleam/option.{None}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleeunit
import gleeunit/should

import telega/bot.{Continue, Stop}
import telega/internal/registry
import telega/testing/context
import telega/testing/factory

pub fn main() {
  gleeunit.main()
}

type S {
  S
}

fn start_factory() {
  let assert Ok(started) =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.start
  started.data
}

/// Boots a bot with the given pre-router middleware, sends one text update, and
/// reports `#(acked, router_ran)` — whether the dispatch was acknowledged and
/// whether the update reached the router.
fn drive(
  registry_name registry_name: String,
  pre_handlers pre_handlers: List(bot.PreHandler(Nil)),
) -> #(Bool, Bool) {
  let assert Ok(reg) = registry.start(registry_name)
  let config = context.config()
  let bot_info = factory.bot_user()

  let router_reached = process.new_subject()
  let router_handler = fn(ctx: bot.Context(S, Nil, Nil), _update) {
    process.send(router_reached, Nil)
    Ok(ctx)
  }
  let session_settings =
    context.session_settings_with(default: fn() { S }, initial: S)

  let assert Ok(started) =
    bot.start(
      registry: reg,
      config:,
      bot_info:,
      router_handler:,
      pre_handlers:,
      session_settings:,
      catch_handler: context.catch_handler(),
      dependencies: Nil,
      chat_factory: start_factory(),
      name: None,
    )

  let acked = bot.handle_update(started.data, factory.text_update(text: "hi"))
  let router_ran = case process.receive(router_reached, 200) {
    Ok(_) -> True
    Error(_) -> False
  }
  let _ = registry.stop(reg)
  #(acked, router_ran)
}

pub fn continue_lets_update_reach_router_test() {
  let pass = fn(_pre: bot.PreContext(Nil)) { Continue }

  let #(acked, router_ran) =
    drive(registry_name: "pre_router_continue", pre_handlers: [pass])

  acked |> should.be_true
  router_ran |> should.be_true
}

pub fn stop_drops_update_before_router_test() {
  let block = fn(_pre: bot.PreContext(Nil)) { Stop }

  let #(acked, router_ran) =
    drive(registry_name: "pre_router_stop", pre_handlers: [block])

  // The update is acknowledged (Telegram won't retry) ...
  acked |> should.be_true
  // ... but it never reached the router.
  router_ran |> should.be_false
}

pub fn first_stop_short_circuits_the_chain_test() {
  let seen = process.new_subject()
  let record = fn(tag) {
    fn(_pre: bot.PreContext(Nil)) {
      process.send(seen, tag)
      Continue
    }
  }
  let block = fn(_pre: bot.PreContext(Nil)) { Stop }

  let #(_acked, router_ran) =
    drive(registry_name: "pre_router_chain", pre_handlers: [
      record("first"),
      block,
      record("after_stop"),
    ])

  router_ran |> should.be_false
  // The first middleware ran ...
  process.receive(seen, 100) |> should.equal(Ok("first"))
  // ... but nothing after the `Stop` did.
  process.receive(seen, 50) |> should.equal(Error(Nil))
}
