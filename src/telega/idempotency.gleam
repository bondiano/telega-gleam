//// Webhook/update idempotency: drop updates Telegram re-delivers.
////
//// Telegram retries an update (same `update_id`) when it does not receive a
//// `200` in time — on a slow response, a redeploy, or a network blip. Without
//// deduplication that means a command runs twice, which is a real problem for
//// non-idempotent actions (sending an invoice, charging Stars, granting a
//// reward).
////
//// `deduplicate` builds a [pre-router middleware](telega.html#use_pre_handler)
//// that remembers each `update_id` in a [`KeyValueStorage`](telega/storage.html)
//// for a TTL window and stops any update whose id was already seen. Because
//// pre-router middleware runs sequentially inside the single bot actor, the
//// read-then-write below is race-free even under concurrent re-delivery.
////
//// ```gleam
//// import telega
//// import telega/idempotency
//// import telega/storage/ets
////
//// let assert Ok(store) = ets.new(name: "telega_dedup")
////
//// telega.new(token:, url:, webhook_path:, secret_token:)
//// |> telega.use_pre_handler(idempotency.deduplicate(
////   storage: store,
////   // Keep ids for an hour — comfortably longer than Telegram's retry window.
////   ttl_ms: 3600_000,
//// ))
//// |> telega.with_router(router)
//// |> telega.init()
//// ```
////
//// Use a persistent backend (Postgres/SQLite/Redis) when you run more than one
//// bot node or want dedup to survive a restart — the in-memory `ets` store is
//// per-node and cleared on VM restart.

import gleam/int
import gleam/option.{None, Some}

import telega/bot.{type PreContext, type PreHandler, Continue, Stop}
import telega/storage.{type KeyValueStorage}
import telega/update

const key_prefix = "dedup:"

/// Build a pre-router middleware that drops updates whose `update_id` was
/// already processed within the last `ttl_ms` milliseconds.
///
/// On a storage error the update is let through (fail-open): processing an
/// update twice is recoverable, silently dropping a legitimate one is not.
pub fn deduplicate(
  storage storage: KeyValueStorage(storage_error),
  ttl_ms ttl_ms: Int,
) -> PreHandler(dependencies) {
  fn(pre_ctx: PreContext(dependencies)) {
    let update_id = update.raw(pre_ctx.update).update_id
    let key = key_prefix <> int.to_string(update_id)

    case storage.get(key) {
      // Already seen within the TTL window — drop the duplicate.
      Ok(Some(_)) -> Stop
      // First time we see this id — remember it and let it through.
      Ok(None) -> {
        let _ = storage.set_with_ttl(key, "1", ttl_ms)
        Continue
      }
      // Fail-open: never drop a real update because the store hiccuped.
      Error(_) -> Continue
    }
  }
}
