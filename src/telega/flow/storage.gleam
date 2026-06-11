//// Storage utilities for flow persistence.
////
//// `FlowStorage` is now derived from the unified `telega/storage`
//// `KeyValueStorage` contract. The ETS implementation lives in
//// `telega/storage/ets`; this module wires it into the flow contract.

import gleam/int
import gleam/option.{None}
import gleam/result
import telega/error.{type TelegaError}
import telega/flow/types.{type FlowStorage, FlowStorage}
import telega/storage
import telega/storage/ets

/// Generate a flow instance ID from user, chat, and flow name
pub fn generate_id(user_id: Int, chat_id: Int, flow_name: String) -> String {
  flow_name <> "_" <> int.to_string(chat_id) <> "_" <> int.to_string(user_id)
}

/// Create ETS-backed storage for flow instances.
///
/// Data persists in memory for the lifetime of the VM but does NOT survive VM
/// restarts. For persistence across restarts, build a `FlowStorage` from a
/// database-backed `KeyValueStorage` via `storage.flow_storage_from_storage`.
pub fn create_ets_storage() -> Result(FlowStorage(error), TelegaError) {
  use kv <- result.try(ets.new("telega_flow_storage"))
  Ok(storage.flow_storage_from_storage(kv))
}

/// Create no-op storage that discards all data.
/// Useful for testing or stateless flows that don't need persistence.
pub fn create_noop_storage() -> FlowStorage(error) {
  FlowStorage(
    save: fn(_instance) { Ok(Nil) },
    load: fn(_id) { Ok(None) },
    delete: fn(_id) { Ok(Nil) },
    list_by_user: fn(_user_id, _chat_id) { Ok([]) },
  )
}
