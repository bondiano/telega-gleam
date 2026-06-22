import gleam/erlang/process
import gleeunit
import gleeunit/should

import telega/bot
import telega/idempotency
import telega/storage/ets
import telega/testing/context as test_context
import telega/testing/factory
import telega/update

pub fn main() {
  gleeunit.main()
}

/// A text update carrying a specific `update_id` in its raw payload.
fn update_with_id(id: Int) -> update.Update {
  let upd = factory.text_update(text: "hi")
  case upd {
    update.TextUpdate(message:, ..) ->
      update.TextUpdate(
        ..upd,
        raw: factory.raw_update_with(message:, update_id: id),
      )
    _ -> upd
  }
}

fn pre_context_for(id: Int) -> bot.PreContext(Nil) {
  bot.PreContext(
    update: update_with_id(id),
    config: test_context.config(),
    dependencies: Nil,
    bot_info: factory.bot_user(),
  )
}

pub fn first_delivery_passes_duplicate_stops_test() {
  let assert Ok(store) = ets.new(name: "dedup_test_basic")
  let dedup = idempotency.deduplicate(storage: store, ttl_ms: 60_000)

  // First time we see update 5 — let it through.
  dedup(pre_context_for(5)) |> should.equal(bot.Continue)
  // Telegram re-delivers the same update — drop it.
  dedup(pre_context_for(5)) |> should.equal(bot.Stop)
  // A different update id is unaffected.
  dedup(pre_context_for(6)) |> should.equal(bot.Continue)
}

pub fn entry_expires_after_ttl_test() {
  let assert Ok(store) = ets.new(name: "dedup_test_ttl")
  let dedup = idempotency.deduplicate(storage: store, ttl_ms: 40)

  dedup(pre_context_for(1)) |> should.equal(bot.Continue)
  dedup(pre_context_for(1)) |> should.equal(bot.Stop)

  // After the TTL window the id is forgotten and the update passes again.
  process.sleep(70)
  dedup(pre_context_for(1)) |> should.equal(bot.Continue)
}
