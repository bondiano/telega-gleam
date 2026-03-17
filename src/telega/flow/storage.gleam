//// Storage utilities for flow persistence.

import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import telega/error.{type TelegaError}
import telega/flow/types.{type FlowInstance, type FlowStorage, FlowStorage}
import telega/internal/flow_storage

/// Generate a flow instance ID from user, chat, and flow name
pub fn generate_id(user_id: Int, chat_id: Int, flow_name: String) -> String {
  flow_name <> "_" <> int.to_string(chat_id) <> "_" <> int.to_string(user_id)
}

fn user_index_key(user_id: Int, chat_id: Int) -> String {
  "_idx:" <> int.to_string(chat_id) <> ":" <> int.to_string(user_id)
}

/// Create ETS-backed storage for flow instances.
///
/// Data persists in memory for the lifetime of the VM but does NOT survive VM restarts.
/// For persistent storage across restarts, implement a custom `FlowStorage` with a database backend.
pub fn create_ets_storage() -> Result(FlowStorage(error), TelegaError) {
  use storage <- result.try(flow_storage.start())
  Ok(
    FlowStorage(
      save: fn(instance) {
        flow_storage.save(storage, instance.id, instance)
        let index_key = user_index_key(instance.user_id, instance.chat_id)
        flow_storage.add_to_index(storage, index_key, instance.id)
        Ok(Nil)
      },
      load: fn(id) { Ok(flow_storage.load(storage, id)) },
      delete: fn(id) {
        let instance: Option(FlowInstance) = flow_storage.load(storage, id)
        flow_storage.delete(storage, id)
        case instance {
          Some(inst) -> {
            let index_key = user_index_key(inst.user_id, inst.chat_id)
            flow_storage.remove_from_index(storage, index_key, id)
          }
          None -> Nil
        }
        Ok(Nil)
      },
      list_by_user: fn(user_id, chat_id) {
        let index_key = user_index_key(user_id, chat_id)
        let instance_ids = flow_storage.lookup_index(storage, index_key)
        Ok(
          list.filter_map(instance_ids, fn(id) {
            case flow_storage.load(storage, id) {
              Some(instance) -> Ok(instance)
              None -> Error(Nil)
            }
          }),
        )
      },
    ),
  )
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
