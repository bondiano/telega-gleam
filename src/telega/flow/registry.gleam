//// FlowRegistry and router integration.

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/float
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import telega/bot.{type Context}
import telega/flow/engine
import telega/flow/instance
import telega/flow/storage
import telega/flow/types.{
  type Flow, type FlowInstance, type FlowTrigger, OnAnyText, OnAudio, OnCallback,
  OnCommand, OnFiltered, OnPhoto, OnText, OnVideo, OnVoice,
}
import telega/internal/coerce
import telega/model/types as model_types
import telega/router
import telega/update

/// Flow registry for centralized flow management
pub opaque type FlowRegistry(session, error) {
  FlowRegistry(
    flows: List(
      #(FlowTrigger, Flow(Dynamic, session, error), Dict(String, String)),
    ),
    flow_map: Dict(String, Flow(Dynamic, session, error)),
    cancel_commands: List(
      #(
        String,
        fn(Context(session, error), List(String)) ->
          Result(Context(session, error), error),
      ),
    ),
  )
}

/// Create a new empty flow registry
pub fn new_registry() -> FlowRegistry(session, error) {
  FlowRegistry(flows: [], flow_map: dict.new(), cancel_commands: [])
}

/// Add a flow to the registry with a trigger
pub fn register(
  registry: FlowRegistry(session, error),
  trigger: FlowTrigger,
  flow: Flow(step_type, session, error),
) -> FlowRegistry(session, error) {
  register_with_data(registry, trigger, flow, dict.new())
}

/// Add a flow to the registry with a trigger and initial data
pub fn register_with_data(
  registry: FlowRegistry(session, error),
  trigger: FlowTrigger,
  flow: Flow(step_type, session, error),
  initial_data: Dict(String, String),
) -> FlowRegistry(session, error) {
  let coerced_flow = unsafe_coerce(flow)
  FlowRegistry(
    ..registry,
    flows: list.append(registry.flows, [#(trigger, coerced_flow, initial_data)]),
    flow_map: dict.insert(registry.flow_map, flow.name, coerced_flow),
  )
}

/// Register a flow without a trigger (for calling from handlers)
pub fn register_callable(
  registry: FlowRegistry(session, error),
  flow: Flow(step_type, session, error),
) -> FlowRegistry(session, error) {
  let coerced_flow = unsafe_coerce(flow)
  FlowRegistry(
    ..registry,
    flows: registry.flows,
    flow_map: dict.insert(registry.flow_map, flow.name, coerced_flow),
  )
}

/// Register a cancel command that cancels all active flows for the user
pub fn register_cancel_command(
  registry: FlowRegistry(session, error),
  command: String,
) -> FlowRegistry(session, error) {
  register_cancel_command_with(registry, command, fn(ctx, _cancelled) {
    Ok(ctx)
  })
}

/// Register a cancel command with a custom callback
pub fn register_cancel_command_with(
  registry: FlowRegistry(session, error),
  command: String,
  on_cancel: fn(Context(session, error), List(String)) ->
    Result(Context(session, error), error),
) -> FlowRegistry(session, error) {
  FlowRegistry(
    ..registry,
    cancel_commands: list.append(registry.cancel_commands, [
      #(command, on_cancel),
    ]),
  )
}

/// Cancel all flows for a user in a chat
pub fn cancel_user_flows(
  registry: FlowRegistry(session, error),
  user_id user_id: Int,
  chat_id chat_id: Int,
) -> Result(List(String), error) {
  let flows = dict.values(registry.flow_map)
  list.try_fold(flows, [], fn(acc, flow) {
    let flow_id = storage.generate_id(user_id, chat_id, flow.name)
    case flow.storage.load(flow_id) {
      Ok(Some(_inst)) -> {
        case flow.storage.delete(flow_id) {
          Ok(_) -> Ok([flow_id, ..acc])
          Error(err) -> Error(err)
        }
      }
      Ok(None) -> Ok(acc)
      Error(err) -> Error(err)
    }
  })
}

/// Cancel a specific flow instance by ID
pub fn cancel_flow_instance(
  registry: FlowRegistry(session, error),
  flow_id flow_id: String,
) -> Result(Bool, error) {
  let flows = dict.values(registry.flow_map)
  let found =
    list.fold(flows, False, fn(acc, flow) {
      case acc {
        True -> True
        False ->
          case flow.storage.load(flow_id) {
            Ok(Some(_)) -> {
              let _ = flow.storage.delete(flow_id)
              True
            }
            _ -> False
          }
      }
    })
  Ok(found)
}

/// Call a registered flow from any handler
pub fn call_flow(
  ctx ctx: Context(session, error),
  registry registry: FlowRegistry(session, error),
  name flow_name: String,
  initial initial_data: Dict(String, String),
) -> Result(Context(session, error), error) {
  case dict.get(registry.flow_map, flow_name) {
    Ok(found_flow) -> start(found_flow, initial_data, ctx)
    Error(_) -> Ok(ctx)
  }
}

/// Apply all registered flows to a router
pub fn apply_to_router(
  router: router.Router(session, error),
  registry: FlowRegistry(session, error),
) -> router.Router(session, error) {
  let router_with_flows =
    list.fold(registry.flows, router, fn(router, flow_entry) {
      let #(trigger, flow, initial_data) = flow_entry
      add_flow_route(router, trigger, flow, initial_data)
    })

  let router_with_cancel =
    list.fold(registry.cancel_commands, router_with_flows, fn(r, cancel_entry) {
      let #(command, on_cancel) = cancel_entry
      router.on_command(r, command, fn(ctx, _cmd) {
        case
          cancel_user_flows(
            registry,
            user_id: ctx.update.from_id,
            chat_id: ctx.update.chat_id,
          )
        {
          Ok(cancelled) -> on_cancel(ctx, cancelled)
          Error(_) -> Ok(ctx)
        }
      })
    })

  case dict.size(registry.flow_map) {
    0 -> router_with_cancel
    _ ->
      router_with_cancel
      |> router.on_any_text(auto_resume_handler(registry))
      |> router.on_callback(
        router.Prefix(""),
        auto_resume_callback_handler(registry),
      )
      |> router.on_photo(auto_resume_photo_handler(registry))
      |> router.on_video(auto_resume_video_handler(registry))
      |> router.on_voice(auto_resume_voice_handler(registry))
      |> router.on_audio(auto_resume_audio_handler(registry))
      |> router.on_filtered(
        router.filter("has_location", fn(upd) {
          case upd {
            update.MessageUpdate(message:, ..) ->
              option.is_some(message.location)
            _ -> False
          }
        }),
        auto_resume_location_handler(registry),
      )
      |> router.on_filtered(
        router.filter("is_command", fn(upd) {
          case upd {
            update.CommandUpdate(..) -> True
            _ -> False
          }
        }),
        auto_resume_command_handler(registry),
      )
  }
}

/// Create a router handler that starts a flow
pub fn to_handler(
  flow flow: Flow(step_type, session, error),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _command) { start(flow, dict.new(), ctx) }
}

fn start(
  flow flow: Flow(step_type, session, error),
  initial initial_data: Dict(String, String),
  ctx ctx: Context(session, error),
) -> Result(Context(session, error), error) {
  let #(from_id, chat_id) = engine.extract_ids_from_context(ctx)
  engine.start_or_resume(flow, ctx, from_id, chat_id, initial_data)
}

fn to_handler_with_data(
  flow flow: Flow(step_type, session, error),
  initial initial_data: Dict(String, String),
) -> fn(Context(session, error), update.Command) ->
  Result(Context(session, error), error) {
  fn(ctx, _update) { start(flow, initial_data, ctx) }
}

fn add_flow_route(
  router: router.Router(session, error),
  trigger: FlowTrigger,
  flow: Flow(Dynamic, session, error),
  initial_data initial_data: Dict(String, String),
) -> router.Router(session, error) {
  case trigger {
    OnCommand(command) ->
      router.on_command(
        router,
        command,
        to_handler_with_data(flow, initial_data),
      )
    OnText(pattern) ->
      router.on_text(router, pattern, fn(ctx, _text) {
        start(flow, initial_data, ctx)
      })
    OnCallback(pattern) ->
      router.on_callback(router, pattern, fn(ctx, _id, _data) {
        start(flow, initial_data, ctx)
      })
    OnFiltered(filter) ->
      router.on_filtered(router, filter, fn(ctx, _update) {
        start(flow, initial_data, ctx)
      })
    OnPhoto ->
      router.on_photo(router, fn(ctx, _photos) {
        start(flow, initial_data, ctx)
      })
    OnVideo ->
      router.on_video(router, fn(ctx, _video) { start(flow, initial_data, ctx) })
    OnAudio ->
      router.on_audio(router, fn(ctx, _audio) { start(flow, initial_data, ctx) })
    OnVoice ->
      router.on_voice(router, fn(ctx, _voice) { start(flow, initial_data, ctx) })
    OnAnyText ->
      router.on_any_text(router, fn(ctx, _text) {
        start(flow, initial_data, ctx)
      })
  }
}

/// Check if instance is expired, run timeout/exit hooks if so, delete and return True.
/// Returns False if not expired.
fn run_timeout_and_cleanup(
  flow: Flow(Dynamic, session, error),
  ctx: Context(session, error),
  inst: FlowInstance,
) -> #(Bool, Result(Context(session, error), error)) {
  case instance.is_expired(inst, flow.ttl_ms) {
    True -> {
      let ctx_result = case flow.on_timeout {
        Some(timeout_fn) ->
          case timeout_fn(ctx, inst) {
            Ok(new_ctx) ->
              case flow.on_flow_exit {
                Some(exit_fn) -> exit_fn(new_ctx, inst)
                None -> Ok(new_ctx)
              }
            Error(err) -> Error(err)
          }
        None ->
          case flow.on_flow_exit {
            Some(exit_fn) -> exit_fn(ctx, inst)
            None -> Ok(ctx)
          }
      }
      let _ = flow.storage.delete(inst.id)
      #(True, ctx_result)
    }
    False -> #(False, Ok(ctx))
  }
}

fn auto_resume_handler(
  registry: FlowRegistry(session, error),
) -> fn(Context(session, error), String) ->
  Result(Context(session, error), error) {
  fn(ctx: Context(session, error), text: String) {
    let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
    let flows = dict.values(registry.flow_map)

    let result =
      list.fold(flows, None, fn(acc, flow) {
        case acc {
          Some(_) -> acc
          None -> {
            let flow_id = storage.generate_id(user_id, chat_id, flow.name)
            case flow.storage.load(flow_id) {
              Ok(Some(inst)) if inst.wait_token != None -> {
                case run_timeout_and_cleanup(flow, ctx, inst) {
                  #(True, _) -> None
                  #(False, _) -> {
                    let data =
                      dict.from_list([
                        #("user_input", text),
                        #("__wait_result", "text:" <> text),
                      ])

                    engine.resume_with_instance(flow, ctx, inst, Some(data))
                    |> Some
                  }
                }
              }
              _ -> None
            }
          }
        }
      })

    case result {
      Some(res) -> res
      None -> Ok(ctx)
    }
  }
}

fn auto_resume_callback_handler(
  registry: FlowRegistry(session, error),
) -> fn(Context(session, error), String, String) ->
  Result(Context(session, error), error) {
  fn(ctx: Context(session, error), _callback_id: String, data: String) {
    let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
    let flows = dict.values(registry.flow_map)

    let result =
      list.fold(flows, None, fn(acc, flow) {
        case acc {
          Some(_) -> acc
          None -> {
            let flow_id = storage.generate_id(user_id, chat_id, flow.name)
            case flow.storage.load(flow_id) {
              Ok(Some(inst)) if inst.wait_token != None -> {
                case run_timeout_and_cleanup(flow, ctx, inst) {
                  #(True, _) -> None
                  #(False, _) -> {
                    let wait_result_value =
                      instance.encode_callback_wait_result(data)
                    let callback_data =
                      dict.from_list([
                        #("callback_data", data),
                        #("__wait_result", wait_result_value),
                      ])
                    engine.resume_with_instance(
                      flow,
                      ctx,
                      inst,
                      Some(callback_data),
                    )
                    |> Some
                  }
                }
              }
              _ -> None
            }
          }
        }
      })

    case result {
      Some(res) -> res
      None -> Ok(ctx)
    }
  }
}

fn auto_resume_photo_handler(
  registry: FlowRegistry(session, error),
) -> fn(Context(session, error), List(model_types.PhotoSize)) ->
  Result(Context(session, error), error) {
  fn(ctx, photos: List(model_types.PhotoSize)) {
    let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
    let flows = dict.values(registry.flow_map)
    let file_ids = list.map(photos, fn(p: model_types.PhotoSize) { p.file_id })
    let file_ids_str = string.join(file_ids, ",")

    let result =
      list.fold(flows, None, fn(acc, flow) {
        case acc {
          Some(_) -> acc
          None -> {
            let flow_id = storage.generate_id(user_id, chat_id, flow.name)
            case flow.storage.load(flow_id) {
              Ok(Some(inst)) if inst.wait_token != None -> {
                case run_timeout_and_cleanup(flow, ctx, inst) {
                  #(True, _) -> None
                  #(False, _) -> {
                    let data =
                      dict.from_list([
                        #("__wait_result", "photo:" <> file_ids_str),
                        #("__photos", file_ids_str),
                      ])
                    engine.resume_with_instance(flow, ctx, inst, Some(data))
                    |> Some
                  }
                }
              }
              _ -> None
            }
          }
        }
      })

    case result {
      Some(res) -> res
      None -> Ok(ctx)
    }
  }
}

fn auto_resume_video_handler(
  registry: FlowRegistry(session, error),
) -> fn(Context(session, error), model_types.Video) ->
  Result(Context(session, error), error) {
  fn(ctx, video: model_types.Video) {
    let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
    let flows = dict.values(registry.flow_map)

    let result =
      list.fold(flows, None, fn(acc, flow) {
        case acc {
          Some(_) -> acc
          None -> {
            let flow_id = storage.generate_id(user_id, chat_id, flow.name)
            case flow.storage.load(flow_id) {
              Ok(Some(inst)) if inst.wait_token != None -> {
                case run_timeout_and_cleanup(flow, ctx, inst) {
                  #(True, _) -> None
                  #(False, _) -> {
                    let data =
                      dict.from_list([
                        #("__wait_result", "video:" <> video.file_id),
                        #("__video_file_id", video.file_id),
                      ])
                    engine.resume_with_instance(flow, ctx, inst, Some(data))
                    |> Some
                  }
                }
              }
              _ -> None
            }
          }
        }
      })

    case result {
      Some(res) -> res
      None -> Ok(ctx)
    }
  }
}

fn auto_resume_voice_handler(
  registry: FlowRegistry(session, error),
) -> fn(Context(session, error), model_types.Voice) ->
  Result(Context(session, error), error) {
  fn(ctx, voice: model_types.Voice) {
    let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
    let flows = dict.values(registry.flow_map)

    let result =
      list.fold(flows, None, fn(acc, flow) {
        case acc {
          Some(_) -> acc
          None -> {
            let flow_id = storage.generate_id(user_id, chat_id, flow.name)
            case flow.storage.load(flow_id) {
              Ok(Some(inst)) if inst.wait_token != None -> {
                case run_timeout_and_cleanup(flow, ctx, inst) {
                  #(True, _) -> None
                  #(False, _) -> {
                    let data =
                      dict.from_list([
                        #("__wait_result", "voice:" <> voice.file_id),
                        #("__voice_file_id", voice.file_id),
                      ])
                    engine.resume_with_instance(flow, ctx, inst, Some(data))
                    |> Some
                  }
                }
              }
              _ -> None
            }
          }
        }
      })

    case result {
      Some(res) -> res
      None -> Ok(ctx)
    }
  }
}

fn auto_resume_audio_handler(
  registry: FlowRegistry(session, error),
) -> fn(Context(session, error), model_types.Audio) ->
  Result(Context(session, error), error) {
  fn(ctx, audio: model_types.Audio) {
    let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
    let flows = dict.values(registry.flow_map)

    let result =
      list.fold(flows, None, fn(acc, flow) {
        case acc {
          Some(_) -> acc
          None -> {
            let flow_id = storage.generate_id(user_id, chat_id, flow.name)
            case flow.storage.load(flow_id) {
              Ok(Some(inst)) if inst.wait_token != None -> {
                case run_timeout_and_cleanup(flow, ctx, inst) {
                  #(True, _) -> None
                  #(False, _) -> {
                    let data =
                      dict.from_list([
                        #("__wait_result", "audio:" <> audio.file_id),
                        #("__audio_file_id", audio.file_id),
                      ])
                    engine.resume_with_instance(flow, ctx, inst, Some(data))
                    |> Some
                  }
                }
              }
              _ -> None
            }
          }
        }
      })

    case result {
      Some(res) -> res
      None -> Ok(ctx)
    }
  }
}

fn auto_resume_location_handler(
  registry: FlowRegistry(session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, upd) {
    case upd {
      update.MessageUpdate(message:, ..) ->
        case message.location {
          Some(location) -> {
            let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
            let flows = dict.values(registry.flow_map)
            let lat_str = float.to_string(location.latitude)
            let lng_str = float.to_string(location.longitude)

            let result =
              list.fold(flows, None, fn(acc, flow) {
                case acc {
                  Some(_) -> acc
                  None -> {
                    let flow_id =
                      storage.generate_id(user_id, chat_id, flow.name)
                    case flow.storage.load(flow_id) {
                      Ok(Some(inst)) if inst.wait_token != None -> {
                        case run_timeout_and_cleanup(flow, ctx, inst) {
                          #(True, _) -> None
                          #(False, _) -> {
                            let data =
                              dict.from_list([
                                #(
                                  "__wait_result",
                                  "location:" <> lat_str <> "," <> lng_str,
                                ),
                                #("__location_lat", lat_str),
                                #("__location_lng", lng_str),
                              ])
                            engine.resume_with_instance(
                              flow,
                              ctx,
                              inst,
                              Some(data),
                            )
                            |> Some
                          }
                        }
                      }
                      _ -> None
                    }
                  }
                }
              })

            case result {
              Some(res) -> res
              None -> Ok(ctx)
            }
          }
          None -> Ok(ctx)
        }
      _ -> Ok(ctx)
    }
  }
}

fn auto_resume_command_handler(
  registry: FlowRegistry(session, error),
) -> fn(Context(session, error), update.Update) ->
  Result(Context(session, error), error) {
  fn(ctx, upd) {
    case upd {
      update.CommandUpdate(command:, ..) -> {
        let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
        let flows = dict.values(registry.flow_map)
        let payload = option.unwrap(command.payload, "")

        let result =
          list.fold(flows, None, fn(acc, flow) {
            case acc {
              Some(_) -> acc
              None -> {
                let flow_id = storage.generate_id(user_id, chat_id, flow.name)
                case flow.storage.load(flow_id) {
                  Ok(Some(inst)) if inst.wait_token != None -> {
                    case run_timeout_and_cleanup(flow, ctx, inst) {
                      #(True, _) -> None
                      #(False, _) -> {
                        let data =
                          dict.from_list([
                            #(
                              "__wait_result",
                              "command:" <> command.command <> ":" <> payload,
                            ),
                            #("command", command.command),
                            #("command_payload", payload),
                          ])
                        engine.resume_with_instance(flow, ctx, inst, Some(data))
                        |> Some
                      }
                    }
                  }
                  _ -> None
                }
              }
            }
          })

        case result {
          Some(res) -> res
          None -> Ok(ctx)
        }
      }
      _ -> Ok(ctx)
    }
  }
}

fn unsafe_coerce(value: value_type) -> result_type {
  coerce.unsafe_coerce(value)
}
