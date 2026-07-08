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
pub opaque type FlowRegistry(session, error, dependencies) {
  FlowRegistry(
    flows: List(
      #(
        FlowTrigger,
        Flow(Dynamic, session, error, dependencies),
        Dict(String, String),
      ),
    ),
    flow_map: Dict(String, Flow(Dynamic, session, error, dependencies)),
    // Per-flow callback payload filters (by flow name). A waiting flow with a
    // filter only auto-resumes on callback payloads it accepts, so several
    // waiting flows can coexist without stealing each other's button presses.
    callback_filters: Dict(String, fn(String) -> Bool),
    // Fallbacks for callbacks no waiting flow consumed, matched on the raw
    // payload in registration order (see `with_orphan_callback_handler`).
    orphan_callback_handlers: List(
      #(
        fn(String) -> Bool,
        fn(Context(session, error, dependencies), String) ->
          Result(Context(session, error, dependencies), error),
      ),
    ),
    cancel_commands: List(
      #(
        String,
        fn(Context(session, error, dependencies), List(String)) ->
          Result(Context(session, error, dependencies), error),
      ),
    ),
  )
}

/// Create a new empty flow registry
pub fn new_registry() -> FlowRegistry(session, error, dependencies) {
  FlowRegistry(
    flows: [],
    flow_map: dict.new(),
    callback_filters: dict.new(),
    orphan_callback_handlers: [],
    cancel_commands: [],
  )
}

/// Add a flow to the registry with a trigger
pub fn register(
  registry: FlowRegistry(session, error, dependencies),
  trigger: FlowTrigger,
  flow: Flow(step_type, session, error, dependencies),
) -> FlowRegistry(session, error, dependencies) {
  register_with_data(registry, trigger, flow, dict.new())
}

/// Add a flow to the registry with a trigger and initial data
pub fn register_with_data(
  registry: FlowRegistry(session, error, dependencies),
  trigger: FlowTrigger,
  flow: Flow(step_type, session, error, dependencies),
  initial_data: Dict(String, String),
) -> FlowRegistry(session, error, dependencies) {
  let coerced_flow = unsafe_coerce(flow)
  FlowRegistry(
    ..registry,
    flows: list.append(registry.flows, [#(trigger, coerced_flow, initial_data)]),
    flow_map: dict.insert(registry.flow_map, flow.name, coerced_flow),
  )
}

/// Register a flow without a trigger (for calling from handlers)
pub fn register_callable(
  registry: FlowRegistry(session, error, dependencies),
  flow: Flow(step_type, session, error, dependencies),
) -> FlowRegistry(session, error, dependencies) {
  let coerced_flow = unsafe_coerce(flow)
  FlowRegistry(
    ..registry,
    flows: registry.flows,
    flow_map: dict.insert(registry.flow_map, flow.name, coerced_flow),
  )
}

/// Restrict a registered flow's callback auto-resume to payloads accepted by
/// `filter`. Auto-resume normally delivers a callback to the first waiting
/// flow regardless of payload; with a filter, a press that belongs to another
/// flow's keyboard skips this one and reaches its real target. Used by the
/// dialog engine, whose payloads are self-identifying (`dlg:<dialog_id>:...`).
pub fn with_callback_filter(
  registry: FlowRegistry(session, error, dependencies),
  flow_name flow_name: String,
  filter filter: fn(String) -> Bool,
) -> FlowRegistry(session, error, dependencies) {
  FlowRegistry(
    ..registry,
    callback_filters: dict.insert(registry.callback_filters, flow_name, filter),
  )
}

/// Handle callback payloads that no waiting flow consumed. Handlers are
/// tried in registration order; the first whose `matches` accepts the raw
/// payload runs. Used by dialogs to answer presses on messages of already
/// finished dialogs (otherwise the spinner hangs and the press is silently
/// swallowed by the registry's catch-all route).
pub fn with_orphan_callback_handler(
  registry: FlowRegistry(session, error, dependencies),
  matches matches: fn(String) -> Bool,
  handler handler: fn(Context(session, error, dependencies), String) ->
    Result(Context(session, error, dependencies), error),
) -> FlowRegistry(session, error, dependencies) {
  FlowRegistry(
    ..registry,
    orphan_callback_handlers: list.append(registry.orphan_callback_handlers, [
      #(matches, handler),
    ]),
  )
}

/// Register a cancel command that cancels all active flows for the user
pub fn register_cancel_command(
  registry: FlowRegistry(session, error, dependencies),
  command: String,
) -> FlowRegistry(session, error, dependencies) {
  register_cancel_command_with(registry, command, fn(ctx, _cancelled) {
    Ok(ctx)
  })
}

/// Register a cancel command with a custom callback
pub fn register_cancel_command_with(
  registry: FlowRegistry(session, error, dependencies),
  command: String,
  on_cancel: fn(Context(session, error, dependencies), List(String)) ->
    Result(Context(session, error, dependencies), error),
) -> FlowRegistry(session, error, dependencies) {
  FlowRegistry(
    ..registry,
    cancel_commands: list.append(registry.cancel_commands, [
      #(command, on_cancel),
    ]),
  )
}

/// Cancel all flows for a user in a chat
pub fn cancel_user_flows(
  registry: FlowRegistry(session, error, dependencies),
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
  registry: FlowRegistry(session, error, dependencies),
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
  ctx ctx: Context(session, error, dependencies),
  registry registry: FlowRegistry(session, error, dependencies),
  name flow_name: String,
  initial initial_data: Dict(String, String),
) -> Result(Context(session, error, dependencies), error) {
  case dict.get(registry.flow_map, flow_name) {
    Ok(found_flow) -> start(found_flow, initial_data, ctx)
    Error(_) -> Ok(ctx)
  }
}

/// Apply all registered flows to a router
pub fn apply_to_router(
  router: router.Router(session, error, dependencies),
  registry: FlowRegistry(session, error, dependencies),
) -> router.Router(session, error, dependencies) {
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
  flow flow: Flow(step_type, session, error, dependencies),
) -> fn(Context(session, error, dependencies), update.Command) ->
  Result(Context(session, error, dependencies), error) {
  fn(ctx, _command) { start(flow, dict.new(), ctx) }
}

fn start(
  flow flow: Flow(step_type, session, error, dependencies),
  initial initial_data: Dict(String, String),
  ctx ctx: Context(session, error, dependencies),
) -> Result(Context(session, error, dependencies), error) {
  let #(from_id, chat_id) = engine.extract_ids_from_context(ctx)
  engine.start_or_resume(flow, ctx, from_id, chat_id, initial_data)
}

fn to_handler_with_data(
  flow flow: Flow(step_type, session, error, dependencies),
  initial initial_data: Dict(String, String),
) -> fn(Context(session, error, dependencies), update.Command) ->
  Result(Context(session, error, dependencies), error) {
  fn(ctx, _update) { start(flow, initial_data, ctx) }
}

fn add_flow_route(
  router: router.Router(session, error, dependencies),
  trigger: FlowTrigger,
  flow: Flow(Dynamic, session, error, dependencies),
  initial_data initial_data: Dict(String, String),
) -> router.Router(session, error, dependencies) {
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
  flow: Flow(Dynamic, session, error, dependencies),
  ctx: Context(session, error, dependencies),
  inst: FlowInstance,
) -> #(Bool, Result(Context(session, error, dependencies), error)) {
  case instance.is_expired(inst, flow.ttl_ms) {
    True -> {
      engine.emit_flow_event("timeout", inst, [#("count", 1)])
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
  registry: FlowRegistry(session, error, dependencies),
) -> fn(Context(session, error, dependencies), String) ->
  Result(Context(session, error, dependencies), error) {
  fn(ctx: Context(session, error, dependencies), text: String) {
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
                        #(
                          instance.wait_result_key,
                          instance.encode_text_wait_result(text),
                        ),
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
  registry: FlowRegistry(session, error, dependencies),
) -> fn(Context(session, error, dependencies), String, String) ->
  Result(Context(session, error, dependencies), error) {
  fn(
    ctx: Context(session, error, dependencies),
    _callback_id: String,
    data: String,
  ) {
    let #(user_id, chat_id) = engine.extract_ids_from_context(ctx)
    let flows = dict.values(registry.flow_map)

    let result =
      list.fold(flows, None, fn(acc, flow) {
        case acc {
          Some(_) -> acc
          None -> {
            let accepts = case dict.get(registry.callback_filters, flow.name) {
              Ok(filter) -> filter(data)
              Error(_) -> True
            }
            case accepts {
              False -> None
              True -> {
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
                            #(instance.wait_result_key, wait_result_value),
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
          }
        }
      })

    case result {
      Some(res) -> res
      None ->
        case
          list.find(registry.orphan_callback_handlers, fn(entry) {
            entry.0(data)
          })
        {
          Ok(#(_matches, handler)) -> handler(ctx, data)
          Error(_) -> Ok(ctx)
        }
    }
  }
}

fn auto_resume_photo_handler(
  registry: FlowRegistry(session, error, dependencies),
) -> fn(Context(session, error, dependencies), List(model_types.PhotoSize)) ->
  Result(Context(session, error, dependencies), error) {
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
                        #(instance.wait_result_key, "photo:" <> file_ids_str),
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
  registry: FlowRegistry(session, error, dependencies),
) -> fn(Context(session, error, dependencies), model_types.Video) ->
  Result(Context(session, error, dependencies), error) {
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
                        #(instance.wait_result_key, "video:" <> video.file_id),
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
  registry: FlowRegistry(session, error, dependencies),
) -> fn(Context(session, error, dependencies), model_types.Voice) ->
  Result(Context(session, error, dependencies), error) {
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
                        #(instance.wait_result_key, "voice:" <> voice.file_id),
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
  registry: FlowRegistry(session, error, dependencies),
) -> fn(Context(session, error, dependencies), model_types.Audio) ->
  Result(Context(session, error, dependencies), error) {
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
                        #(instance.wait_result_key, "audio:" <> audio.file_id),
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
  registry: FlowRegistry(session, error, dependencies),
) -> fn(Context(session, error, dependencies), update.Update) ->
  Result(Context(session, error, dependencies), error) {
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
                                  instance.wait_result_key,
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
  registry: FlowRegistry(session, error, dependencies),
) -> fn(Context(session, error, dependencies), update.Update) ->
  Result(Context(session, error, dependencies), error) {
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
                              instance.wait_result_key,
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
