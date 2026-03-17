import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import telega/bot.{type Context, Context}
import telega/error.{type TelegaError}
import telega/model/types
import telega/router
import telega/testing/context as test_context
import telega/testing/factory
import telega/update.{type Update}

pub fn main() {
  gleeunit.main()
}

fn make_ctx(session: String) -> Context(String, TelegaError) {
  test_context.context(session:)
}

pub fn command_routing_integration_test() {
  let start_handler = fn(ctx: Context(String, TelegaError), cmd: update.Command) {
    case cmd.command {
      "start" -> Ok(Context(..ctx, session: "start_called"))
      _ -> Ok(ctx)
    }
  }

  let help_handler = fn(ctx: Context(String, TelegaError), cmd: update.Command) {
    case cmd.command {
      "help" -> Ok(Context(..ctx, session: "help_called"))
      _ -> Ok(ctx)
    }
  }

  let r =
    router.new("test")
    |> router.on_command("start", start_handler)
    |> router.on_command("help", help_handler)

  let start_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "start", payload: None, text: "/start"),
      message: factory.message(text: "/start"),
      raw: factory.raw_update(message: factory.message(text: "/start")),
    )

  let ctx = make_ctx("initial")
  let result = router.handle(r, ctx, start_update)

  result
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("start_called")

  let help_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "help", payload: None, text: "/help"),
      message: factory.message(text: "/help"),
      raw: factory.raw_update(message: factory.message(text: "/help")),
    )

  let ctx2 = make_ctx("initial")
  let result2 = router.handle(r, ctx2, help_update)

  result2
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("help_called")

  let unknown_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(
        command: "unknown",
        payload: None,
        text: "/unknown",
      ),
      message: factory.message(text: "/unknown"),
      raw: factory.raw_update(message: factory.message(text: "/unknown")),
    )

  let ctx3 = make_ctx("initial")
  let result3 = router.handle(r, ctx3, unknown_update)

  result3
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial")
}

pub fn decode_command_with_args_test() {
  let base = factory.message(text: "/start")
  let text = "/help foo bar"
  let entity =
    types.MessageEntity(
      type_: "bot_command",
      offset: 0,
      length: 5,
      url: None,
      user: None,
      language: None,
      custom_emoji_id: None,
      unix_time: None,
      date_time_format: None,
    )

  let message =
    types.Message(..base, text: Some(text), entities: Some([entity]))

  let raw = factory.raw_update(message:)

  let upd = update.raw_to_update(raw)

  case upd {
    update.CommandUpdate(command: cmd, ..) -> {
      cmd.command |> should.equal("help")
      cmd.payload |> should.equal(Some("foo bar"))
    }
    _ -> should.fail()
  }
}

pub fn router_command_with_args_test() {
  let handler = fn(ctx: Context(String, TelegaError), cmd: update.Command) {
    Ok(Context(..ctx, session: option.unwrap(cmd.payload, "no_payload")))
  }

  let r =
    router.new("test")
    |> router.on_command("help", handler)

  let base = factory.message(text: "/start")
  let text = "/help payload here"
  let entity =
    types.MessageEntity(
      type_: "bot_command",
      offset: 0,
      length: 5,
      url: None,
      user: None,
      language: None,
      custom_emoji_id: None,
      unix_time: None,
      date_time_format: None,
    )

  let message =
    types.Message(..base, text: Some(text), entities: Some([entity]))

  let raw = factory.raw_update(message:)

  let upd = update.raw_to_update(raw)
  let c = make_ctx("initial")
  let result = router.handle(r, c, upd)

  result
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("payload here")
}

pub fn router_command_with_matching_suffix_test() {
  router_command_with_suffix_test("/help@testbot", "help@testbot")
  router_command_with_suffix_test("/start@testbot", "start@testbot")
}

pub fn router_command_with_non_matching_suffix_test() {
  router_command_with_suffix_test("/help@someotherbot", "initial")
  router_command_with_suffix_test("/start@", "initial")
}

fn router_command_with_suffix_test(text: String, session_val: String) {
  let handler = fn(ctx: Context(String, TelegaError), cmd: update.Command) {
    Ok(Context(..ctx, session: cmd.command))
  }

  let r =
    router.new("test")
    |> router.on_commands(["help", "start"], handler)

  let base = factory.message(text: "/start")
  let entity =
    types.MessageEntity(
      type_: "bot_command",
      offset: 0,
      length: text |> string.length,
      url: None,
      user: None,
      language: None,
      custom_emoji_id: None,
      unix_time: None,
      date_time_format: None,
    )

  let message =
    types.Message(..base, text: Some(text), entities: Some([entity]))

  let raw = factory.raw_update(message:)

  let upd = update.raw_to_update(raw)
  let c = make_ctx("initial")
  let result = router.handle(r, c, upd)

  result
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal(session_val)
}

pub fn text_pattern_matching_integration_test() {
  let exact_handler = fn(ctx: Context(String, TelegaError), _text: String) {
    Ok(Context(..ctx, session: "exact_matched"))
  }

  let prefix_handler = fn(ctx: Context(String, TelegaError), _text: String) {
    Ok(Context(..ctx, session: "prefix_matched"))
  }

  let r =
    router.new("test")
    |> router.on_text(router.Exact("hello"), exact_handler)
    |> router.on_text(router.Prefix("search:"), prefix_handler)

  let exact_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "hello",
      message: factory.message(text: "hello"),
      raw: factory.raw_update(message: factory.message(text: "hello")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, exact_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("exact_matched")

  let prefix_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "search:gleam tutorials",
      message: factory.message(text: "search:gleam tutorials"),
      raw: factory.raw_update(message: factory.message(
        text: "search:gleam tutorials",
      )),
    )

  let ctx2 = make_ctx("initial")
  router.handle(r, ctx2, prefix_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("prefix_matched")
}

pub fn middleware_integration_test() {
  let handler = fn(ctx: Context(String, TelegaError), _cmd: update.Command) {
    Ok(Context(..ctx, session: ctx.session <> "_handler"))
  }

  let counting_middleware = fn(handler) {
    fn(ctx: Context(String, TelegaError), update: Update) {
      let modified_ctx = Context(..ctx, session: ctx.session <> "_pre")
      case handler(modified_ctx, update) {
        Ok(result_ctx) ->
          Ok(Context(..result_ctx, session: result_ctx.session <> "_post"))
        Error(err) -> Error(err)
      }
    }
  }

  let r =
    router.new("test")
    |> router.use_middleware(counting_middleware)
    |> router.on_command("test", handler)

  let cmd_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "test", payload: None, text: "/test"),
      message: factory.message(text: "/test"),
      raw: factory.raw_update(message: factory.message(text: "/test")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, cmd_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial_pre_handler_post")
}

pub fn fallback_integration_test() {
  let command_handler = fn(
    ctx: Context(String, TelegaError),
    _cmd: update.Command,
  ) {
    Ok(Context(..ctx, session: "command_handled"))
  }

  let fallback_handler = fn(ctx: Context(String, TelegaError), _update: Update) {
    Ok(Context(..ctx, session: "fallback_handled"))
  }

  let r =
    router.new("test")
    |> router.on_command("start", command_handler)
    |> router.fallback(fallback_handler)

  let command_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "start", payload: None, text: "/start"),
      message: factory.message(text: "/start"),
      raw: factory.raw_update(message: factory.message(text: "/start")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, command_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("command_handled")

  let text_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "random text",
      message: factory.message(text: "random text"),
      raw: factory.raw_update(message: factory.message(text: "random text")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(r, ctx2, text_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("fallback_handled")
}

pub fn filter_middleware_integration_test() {
  let handler = fn(ctx: Context(String, TelegaError), _update: Update) {
    Ok(Context(..ctx, session: "handler_called"))
  }

  let user_filter = fn(update: Update) -> Bool {
    case update {
      update.TextUpdate(from_id: id, ..) -> id == 123
      update.CommandUpdate(from_id: id, ..) -> id == 123
      _ -> False
    }
  }

  let r =
    router.new("test")
    |> router.on_custom(
      fn(update) {
        case update {
          update.TextUpdate(..) -> user_filter(update)
          _ -> False
        }
      },
      handler,
    )

  let allowed_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "hello",
      message: factory.message(text: "hello"),
      raw: factory.raw_update(message: factory.message(text: "hello")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, allowed_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("handler_called")

  let blocked_update =
    update.TextUpdate(
      from_id: 999,
      chat_id: 456,
      text: "hello",
      message: factory.message(text: "hello"),
      raw: factory.raw_update(message: factory.message(text: "hello")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(r, ctx2, blocked_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial")
}

pub fn custom_matcher_integration_test() {
  let custom_handler = fn(ctx: Context(String, TelegaError), _update: Update) {
    Ok(Context(..ctx, session: "custom_matched"))
  }

  let contains_number = fn(update: Update) -> Bool {
    case update {
      update.TextUpdate(text: text, ..) -> {
        text
        |> string.to_graphemes
        |> list.any(fn(char) {
          char == "0"
          || char == "1"
          || char == "2"
          || char == "3"
          || char == "4"
          || char == "5"
          || char == "6"
          || char == "7"
          || char == "8"
          || char == "9"
        })
      }
      _ -> False
    }
  }

  let r =
    router.new("test")
    |> router.on_custom(contains_number, custom_handler)

  let with_number =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "I have 5 apples",
      message: factory.message(text: "I have 5 apples"),
      raw: factory.raw_update(message: factory.message(text: "I have 5 apples")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, with_number)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("custom_matched")

  let without_number =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "No numbers here",
      message: factory.message(text: "No numbers here"),
      raw: factory.raw_update(message: factory.message(text: "No numbers here")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(r, ctx2, without_number)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial")
}

pub fn router_composition_integration_test() {
  let handler1 = fn(ctx: Context(String, TelegaError), _cmd: update.Command) {
    Ok(Context(..ctx, session: "router1"))
  }

  let handler2 = fn(ctx: Context(String, TelegaError), _cmd: update.Command) {
    Ok(Context(..ctx, session: "router2"))
  }

  let router1 =
    router.new("r1")
    |> router.on_command("start", handler1)

  let router2 =
    router.new("r2")
    |> router.on_command("help", handler2)

  let composed = router.compose(router1, router2)

  let start_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "start", payload: None, text: "/start"),
      message: factory.message(text: "/start"),
      raw: factory.raw_update(message: factory.message(text: "/start")),
    )

  let c = make_ctx("initial")
  composed
  |> router.handle(c, start_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router1")

  let help_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "help", payload: None, text: "/help"),
      message: factory.message(text: "/help"),
      raw: factory.raw_update(message: factory.message(text: "/help")),
    )

  let ctx2 = make_ctx("initial")
  composed
  |> router.handle(ctx2, help_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router2")
}

pub fn media_handlers_integration_test() {
  let photo_handler = fn(
    ctx: Context(String, TelegaError),
    _photos: List(types.PhotoSize),
  ) {
    Ok(Context(..ctx, session: "photo"))
  }

  let video_handler = fn(ctx: Context(String, TelegaError), _video: types.Video) {
    Ok(Context(..ctx, session: "video"))
  }

  let r =
    router.new("test")
    |> router.on_photo(photo_handler)
    |> router.on_video(video_handler)

  let photo_update =
    update.PhotoUpdate(
      from_id: 123,
      chat_id: 456,
      photos: [],
      message: factory.message(text: ""),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, photo_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("photo")

  let video_update =
    update.VideoUpdate(
      from_id: 123,
      chat_id: 456,
      video: types.Video(
        file_id: "test_video",
        file_unique_id: "unique_video",
        width: 1920,
        height: 1080,
        duration: 60,
        thumbnail: None,
        cover: None,
        file_name: None,
        mime_type: None,
        file_size: None,
        start_timestamp: None,
        qualities: None,
      ),
      message: factory.message(text: ""),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(r, ctx2, video_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("video")
}

pub fn recovery_middleware_integration_test() {
  let failing_handler = fn(
    _ctx: Context(String, TelegaError),
    _cmd: update.Command,
  ) {
    Error(error.ActorError("expected error"))
  }

  let recover = fn(err) {
    case err {
      error.ActorError("expected error") -> Ok(make_ctx("recovered"))
      _ -> Error(err)
    }
  }

  let r =
    router.new("test")
    |> router.on_command("fail", fn(c, cmd) {
      let _ = failing_handler(c, cmd)
      recover(error.ActorError("expected error"))
    })

  let cmd_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "fail", payload: None, text: "/fail"),
      message: factory.message(text: "/fail"),
      raw: factory.raw_update(message: factory.message(text: "/fail")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, cmd_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("recovered")
}

pub fn compose_basic_test() {
  let router1 =
    router.new("router1")
    |> router.on_command("start", fn(c, _cmd) {
      Ok(Context(..c, session: "router1_start"))
    })
    |> router.on_text(router.Prefix("hello"), fn(c, _text) {
      Ok(Context(..c, session: "router1_hello"))
    })

  let router2 =
    router.new("router2")
    |> router.on_command("help", fn(c, _cmd) {
      Ok(Context(..c, session: "router2_help"))
    })
    |> router.on_text(router.Prefix("world"), fn(c, _text) {
      Ok(Context(..c, session: "router2_world"))
    })

  let combined = router.compose(router1, router2)

  let start_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "start", payload: None, text: "/start"),
      message: factory.message(text: "/start"),
      raw: factory.raw_update(message: factory.message(text: "/start")),
    )

  let c = make_ctx("initial")
  router.handle(combined, c, start_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router1_start")

  let help_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "help", payload: None, text: "/help"),
      message: factory.message(text: "/help"),
      raw: factory.raw_update(message: factory.message(text: "/help")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(combined, ctx2, help_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router2_help")
}

pub fn compose_priority_test() {
  let router1 =
    router.new("router1")
    |> router.on_command("test", fn(c, _cmd) {
      Ok(Context(..c, session: "router1_wins"))
    })

  let router2 =
    router.new("router2")
    |> router.on_command("test", fn(c, _cmd) {
      Ok(Context(..c, session: "router2_should_not_run"))
    })

  let combined = router.compose(router1, router2)

  let test_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "test", payload: None, text: "/test"),
      message: factory.message(text: "/test"),
      raw: factory.raw_update(message: factory.message(text: "/test")),
    )

  let c = make_ctx("initial")
  router.handle(combined, c, test_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router1_wins")
}

pub fn compose_fallback_test() {
  let router1 =
    router.new("router1")
    |> router.on_command("start", fn(c, _cmd) {
      Ok(Context(..c, session: "router1_start"))
    })

  let router2 =
    router.new("router2")
    |> router.fallback(fn(c, _) {
      Ok(Context(..c, session: "router2_fallback"))
    })

  let combined = router.compose(router1, router2)

  let msg = factory.message(text: "random text")
  let text_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "random text",
      message: types.Message(..msg, text: Some("random text")),
      raw: factory.raw_update(message: msg),
    )

  let c = make_ctx("initial")
  router.handle(combined, c, text_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router2_fallback")
}

pub fn compose_catch_handler_test() {
  let router1 =
    router.new("router1")
    |> router.on_command("fail1", fn(_c, _cmd) {
      Error(error.ActorError("error1"))
    })
    |> router.with_catch_handler(fn(err) {
      case err {
        error.ActorError("error1") -> Ok(make_ctx("caught_by_router1"))
        _ -> Error(err)
      }
    })

  let router2 =
    router.new("router2")
    |> router.on_command("fail2", fn(_c, _cmd) {
      Error(error.ActorError("error2"))
    })
    |> router.with_catch_handler(fn(err) {
      case err {
        error.ActorError("error2") -> Ok(make_ctx("caught_by_router2"))
        _ -> Error(err)
      }
    })

  let combined = router.compose(router1, router2)

  let fail1_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "fail1", payload: None, text: "/fail1"),
      message: factory.message(text: "/fail1"),
      raw: factory.raw_update(message: factory.message(text: "/fail1")),
    )

  let ctx1 = make_ctx("initial")
  router.handle(combined, ctx1, fail1_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("caught_by_router1")

  let fail2_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "fail2", payload: None, text: "/fail2"),
      message: factory.message(text: "/fail2"),
      raw: factory.raw_update(message: factory.message(text: "/fail2")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(combined, ctx2, fail2_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("caught_by_router2")
}

pub fn nested_compose_test() {
  let router1 =
    router.new("router1")
    |> router.on_command("cmd1", fn(_c, _cmd) {
      Ok(make_ctx("handled_by_router1"))
    })

  let router2 =
    router.new("router2")
    |> router.on_command("cmd2", fn(_c, _cmd) {
      Ok(make_ctx("handled_by_router2"))
    })

  let router3 =
    router.new("router3")
    |> router.on_command("cmd3", fn(_c, _cmd) {
      Ok(make_ctx("handled_by_router3"))
    })

  let composed_1_2 = router.compose(router1, router2)
  let nested_composed = router.compose(composed_1_2, router3)

  let cmd3_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd3", payload: None, text: "/cmd3"),
      message: factory.message(text: "/cmd3"),
      raw: factory.raw_update(message: factory.message(text: "/cmd3")),
    )

  let ctx3 = make_ctx("initial")
  router.handle(nested_composed, ctx3, cmd3_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("handled_by_router3")
}

pub fn deeply_nested_compose_test() {
  let router1 =
    router.new("router1")
    |> router.use_middleware(fn(handler) {
      fn(c: bot.Context(String, error.TelegaError), update) {
        handler(make_ctx(c.session <> "_mw1"), update)
      }
    })
    |> router.on_command("cmd1", fn(c, _) { Ok(make_ctx(c.session <> "_r1")) })

  let router2 =
    router.new("router2")
    |> router.use_middleware(fn(handler) {
      fn(c: bot.Context(String, error.TelegaError), update) {
        handler(make_ctx(c.session <> "_mw2"), update)
      }
    })
    |> router.on_command("cmd2", fn(c, _) { Ok(make_ctx(c.session <> "_r2")) })

  let router3 =
    router.new("router3")
    |> router.use_middleware(fn(handler) {
      fn(c: bot.Context(String, error.TelegaError), update) {
        handler(make_ctx(c.session <> "_mw3"), update)
      }
    })
    |> router.on_command("cmd3", fn(c, _) { Ok(make_ctx(c.session <> "_r3")) })

  let router4 =
    router.new("router4")
    |> router.use_middleware(fn(handler) {
      fn(c: bot.Context(String, error.TelegaError), update) {
        handler(make_ctx(c.session <> "_mw4"), update)
      }
    })
    |> router.on_command("cmd4", fn(c, _) { Ok(make_ctx(c.session <> "_r4")) })

  let composed_1_2 = router.compose(router1, router2)
  let composed_3_4 = router.compose(router3, router4)
  let final_composed = router.compose(composed_1_2, composed_3_4)

  let cmd1_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd1", payload: None, text: "/cmd1"),
      message: factory.message(text: "/cmd1"),
      raw: factory.raw_update(message: factory.message(text: "/cmd1")),
    )

  let ctx1 = make_ctx("init")
  router.handle(final_composed, ctx1, cmd1_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("init_mw1_r1")

  let cmd3_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd3", payload: None, text: "/cmd3"),
      message: factory.message(text: "/cmd3"),
      raw: factory.raw_update(message: factory.message(text: "/cmd3")),
    )

  let ctx3 = make_ctx("init")
  router.handle(final_composed, ctx3, cmd3_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("init_mw3_r3")
}

pub fn nested_compose_with_fallback_test() {
  let router1 =
    router.new("router1")
    |> router.on_command("cmd1", fn(_c, _cmd) {
      Ok(make_ctx("handled_by_router1"))
    })

  let router2 =
    router.new("router2")
    |> router.on_command("cmd2", fn(_c, _cmd) {
      Ok(make_ctx("handled_by_router2"))
    })
    |> router.fallback(fn(_c, _) { Ok(make_ctx("fallback_router2")) })

  let router3 =
    router.new("router3")
    |> router.on_command("cmd3", fn(_c, _cmd) {
      Ok(make_ctx("handled_by_router3"))
    })
    |> router.fallback(fn(_c, _) { Ok(make_ctx("fallback_router3")) })

  let composed_1_2 = router.compose(router1, router2)
  let nested_composed = router.compose(composed_1_2, router3)

  let unknown_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(
        command: "unknown",
        payload: None,
        text: "/unknown",
      ),
      message: factory.message(text: "/unknown"),
      raw: factory.raw_update(message: factory.message(text: "/unknown")),
    )

  let c = make_ctx("initial")
  router.handle(nested_composed, c, unknown_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("fallback_router2")
}

pub fn merge_with_composed_router_test() {
  let router1 =
    router.new("router1")
    |> router.on_command("cmd1", fn(_c, _cmd) { Ok(make_ctx("router1_cmd1")) })

  let router2 =
    router.new("router2")
    |> router.on_command("cmd2", fn(_c, _cmd) { Ok(make_ctx("router2_cmd2")) })

  let router3 =
    router.new("router3")
    |> router.on_command("cmd3", fn(_c, _cmd) { Ok(make_ctx("router3_cmd3")) })

  let composed_1_2 = router.compose(router1, router2)
  let merged = router.merge(composed_1_2, router3)

  let cmd1_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd1", payload: None, text: "/cmd1"),
      message: factory.message(text: "/cmd1"),
      raw: factory.raw_update(message: factory.message(text: "/cmd1")),
    )

  let ctx1 = make_ctx("initial")
  router.handle(merged, ctx1, cmd1_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router1_cmd1")

  let cmd2_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd2", payload: None, text: "/cmd2"),
      message: factory.message(text: "/cmd2"),
      raw: factory.raw_update(message: factory.message(text: "/cmd2")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(merged, ctx2, cmd2_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router2_cmd2")

  let cmd3_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd3", payload: None, text: "/cmd3"),
      message: factory.message(text: "/cmd3"),
      raw: factory.raw_update(message: factory.message(text: "/cmd3")),
    )

  let ctx3 = make_ctx("initial")
  router.handle(merged, ctx3, cmd3_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router3_cmd3")
}

pub fn merge_composed_with_composed_test() {
  let router1 =
    router.new("router1")
    |> router.on_command("cmd1", fn(_c, _cmd) { Ok(make_ctx("router1_cmd1")) })

  let router2 =
    router.new("router2")
    |> router.on_command("cmd2", fn(_c, _cmd) { Ok(make_ctx("router2_cmd2")) })

  let router3 =
    router.new("router3")
    |> router.on_command("cmd3", fn(_c, _cmd) { Ok(make_ctx("router3_cmd3")) })

  let router4 =
    router.new("router4")
    |> router.on_command("cmd4", fn(_c, _cmd) { Ok(make_ctx("router4_cmd4")) })

  let composed_1_2 = router.compose(router1, router2)
  let composed_3_4 = router.compose(router3, router4)
  let merged = router.merge(composed_1_2, composed_3_4)

  let cmd1_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd1", payload: None, text: "/cmd1"),
      message: factory.message(text: "/cmd1"),
      raw: factory.raw_update(message: factory.message(text: "/cmd1")),
    )

  let ctx1 = make_ctx("initial")
  router.handle(merged, ctx1, cmd1_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router1_cmd1")

  let cmd4_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "cmd4", payload: None, text: "/cmd4"),
      message: factory.message(text: "/cmd4"),
      raw: factory.raw_update(message: factory.message(text: "/cmd4")),
    )

  let ctx4 = make_ctx("initial")
  router.handle(merged, ctx4, cmd4_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("router4_cmd4")
}

pub fn simple_filter_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(router.is_text(), fn(_c, _) {
      Ok(make_ctx("text_matched"))
    })
    |> router.on_filtered(router.is_command(), fn(_c, _) {
      Ok(make_ctx("command_matched"))
    })

  let text_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hello",
      message: factory.message(text: "Hello"),
      raw: factory.raw_update(message: factory.message(text: "Hello")),
    )

  let ctx1 = make_ctx("initial")
  router.handle(test_router, ctx1, text_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("text_matched")

  let cmd_update =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "start", payload: None, text: "/start"),
      message: factory.message(text: "/start"),
      raw: factory.raw_update(message: factory.message(text: "/start")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(test_router, ctx2, cmd_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("command_matched")
}

pub fn filter_composition_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(router.is_text(), fn(_c, _) {
      Ok(make_ctx("any_text"))
    })
    |> router.on_filtered(
      router.and2(router.is_text(), router.text_starts_with("Hello")),
      fn(_c, _) { Ok(make_ctx("hello_matched")) },
    )

  let hello_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hello World",
      message: factory.message(text: "Hello World"),
      raw: factory.raw_update(message: factory.message(text: "Hello World")),
    )

  let ctx1 = make_ctx("initial")
  router.handle(test_router, ctx1, hello_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("hello_matched")

  let other_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Goodbye",
      message: factory.message(text: "Goodbye"),
      raw: factory.raw_update(message: factory.message(text: "Goodbye")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(test_router, ctx2, other_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("any_text")
}

pub fn filter_or_logic_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(
      router.or2(router.text_equals("help"), router.command_equals("help")),
      fn(_c, _) { Ok(make_ctx("help_matched")) },
    )

  let text_help =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "help",
      message: factory.message(text: "help"),
      raw: factory.raw_update(message: factory.message(text: "help")),
    )

  let ctx1 = make_ctx("initial")
  router.handle(test_router, ctx1, text_help)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("help_matched")

  let cmd_help =
    update.CommandUpdate(
      from_id: 123,
      chat_id: 456,
      command: update.Command(command: "help", payload: None, text: "/help"),
      message: factory.message(text: "/help"),
      raw: factory.raw_update(message: factory.message(text: "/help")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(test_router, ctx2, cmd_help)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("help_matched")
}

pub fn filter_not_logic_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(
      router.and2(router.is_text(), router.not(router.text_starts_with("/"))),
      fn(_c, _) { Ok(make_ctx("not_command")) },
    )

  let text_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hello",
      message: factory.message(text: "Hello"),
      raw: factory.raw_update(message: factory.message(text: "Hello")),
    )

  let ctx1 = make_ctx("initial")
  router.handle(test_router, ctx1, text_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("not_command")

  let cmd_like =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "/start",
      message: factory.message(text: "/start"),
      raw: factory.raw_update(message: factory.message(text: "/start")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(test_router, ctx2, cmd_like)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial")
}

pub fn filter_user_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(router.from_user(123), fn(_c, _) {
      Ok(make_ctx("user_123"))
    })
    |> router.on_filtered(router.from_users([456, 789]), fn(_c, _) {
      Ok(make_ctx("special_users"))
    })

  let user123_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hello",
      message: factory.message(text: "Hello"),
      raw: factory.raw_update(message: factory.message(text: "Hello")),
    )

  let ctx1 = make_ctx("initial")
  router.handle(test_router, ctx1, user123_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("user_123")

  let user456_update =
    update.TextUpdate(
      from_id: 456,
      chat_id: 999,
      text: "Hello",
      message: factory.message(text: "Hello"),
      raw: factory.raw_update(message: factory.message(text: "Hello")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(test_router, ctx2, user456_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("special_users")
}

pub fn filter_chat_type_test() {
  let test_router =
    router.new("filter_test")
    |> router.on_filtered(router.is_private_chat(), fn(_c, _) {
      Ok(make_ctx("private_chat"))
    })
    |> router.on_filtered(router.is_group_chat(), fn(_c, _) {
      Ok(make_ctx("group_chat"))
    })

  let private_msg =
    types.Message(
      ..factory.message(text: "Hello"),
      chat: types.Chat(
        id: 456,
        type_: "private",
        title: None,
        username: None,
        first_name: Some("Test"),
        last_name: Some("User"),
        is_forum: None,
        is_direct_messages: None,
      ),
    )

  let private_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hello",
      message: private_msg,
      raw: factory.raw_update(message: private_msg),
    )

  let ctx1 = make_ctx("initial")
  router.handle(test_router, ctx1, private_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("private_chat")

  let group_msg =
    types.Message(
      ..factory.message(text: "Hello"),
      chat: types.Chat(
        id: -789,
        type_: "group",
        title: Some("Test Group"),
        username: None,
        first_name: None,
        last_name: None,
        is_forum: None,
        is_direct_messages: None,
      ),
    )

  let group_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: -789,
      text: "Hello",
      message: group_msg,
      raw: factory.raw_update(message: group_msg),
    )

  let ctx2 = make_ctx("initial")
  router.handle(test_router, ctx2, group_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("group_chat")
}

pub fn custom_filter_test() {
  let is_long_text =
    router.filter("long_text", fn(upd) {
      case upd {
        update.TextUpdate(text:, ..) -> string.length(text) > 10
        _ -> False
      }
    })

  let test_router =
    router.new("filter_test")
    |> router.on_filtered(router.is_text(), fn(_c, _) {
      Ok(make_ctx("short_text"))
    })
    |> router.on_filtered(is_long_text, fn(_c, _) { Ok(make_ctx("long_text")) })

  let long_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "This is a very long text message",
      message: factory.message(text: "This is a very long text message"),
      raw: factory.raw_update(message: factory.message(
        text: "This is a very long text message",
      )),
    )

  let ctx1 = make_ctx("initial")
  router.handle(test_router, ctx1, long_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("long_text")

  let short_update =
    update.TextUpdate(
      from_id: 123,
      chat_id: 456,
      text: "Hi",
      message: factory.message(text: "Hi"),
      raw: factory.raw_update(message: factory.message(text: "Hi")),
    )

  let ctx2 = make_ctx("initial")
  router.handle(test_router, ctx2, short_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("short_text")
}

pub fn complex_filter_composition_test() {
  let admin_ids = [100, 200, 300]

  let test_router =
    router.new("filter_test")
    |> router.on_filtered(
      router.and([
        router.is_text(),
        router.from_users(admin_ids),
        router.text_starts_with("!"),
        router.is_group_chat(),
      ]),
      fn(_c, _) { Ok(make_ctx("admin_group_command")) },
    )

  let group_msg =
    types.Message(
      ..factory.message(text: "!ban user123"),
      chat: types.Chat(
        id: -789,
        type_: "group",
        title: Some("Test Group"),
        username: None,
        first_name: None,
        last_name: None,
        is_forum: None,
        is_direct_messages: None,
      ),
    )

  let admin_update =
    update.TextUpdate(
      from_id: 200,
      chat_id: -789,
      text: "!ban user123",
      message: group_msg,
      raw: factory.raw_update(message: group_msg),
    )

  let ctx1 = make_ctx("initial")
  router.handle(test_router, ctx1, admin_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("admin_group_command")

  let non_admin_update =
    update.TextUpdate(
      from_id: 999,
      chat_id: 789,
      text: "!ban user123",
      message: group_msg,
      raw: factory.raw_update(message: group_msg),
    )

  let ctx2 = make_ctx("initial")
  router.handle(test_router, ctx2, non_admin_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("initial")
}

pub fn inline_query_handler_test() {
  let handler = fn(ctx: Context(String, TelegaError), query: types.InlineQuery) {
    Ok(Context(..ctx, session: "inline_query:" <> query.query))
  }

  let r =
    router.new("test")
    |> router.on_inline_query(handler)

  let inline_query_update =
    update.InlineQueryUpdate(
      from_id: 123,
      chat_id: 123,
      inline_query: types.InlineQuery(
        id: "query123",
        from: factory.user_with(id: 123, first_name: "Test"),
        query: "search text",
        offset: "0",
        chat_type: None,
        location: None,
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, inline_query_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("inline_query:search text")
}

pub fn chosen_inline_result_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    result: types.ChosenInlineResult,
  ) {
    Ok(Context(..ctx, session: "chosen:" <> result.result_id))
  }

  let r =
    router.new("test")
    |> router.on_chosen_inline_result(handler)

  let chosen_result_update =
    update.ChosenInlineResultUpdate(
      from_id: 123,
      chat_id: 123,
      chosen_inline_result: types.ChosenInlineResult(
        result_id: "result456",
        from: factory.user_with(id: 123, first_name: "Test"),
        location: None,
        inline_message_id: None,
        query: "test query",
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, chosen_result_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("chosen:result456")
}

pub fn poll_handler_test() {
  let handler = fn(ctx: Context(String, TelegaError), poll: types.Poll) {
    Ok(Context(..ctx, session: "poll:" <> poll.question))
  }

  let r =
    router.new("test")
    |> router.on_poll(handler)

  let poll_update =
    update.PollUpdate(
      from_id: -1,
      chat_id: -1,
      poll: types.Poll(
        id: "poll123",
        question: "Do you like Gleam?",
        question_entities: None,
        options: [
          types.PollOption(text: "Yes", text_entities: None, voter_count: 10),
          types.PollOption(text: "No", text_entities: None, voter_count: 2),
        ],
        total_voter_count: 12,
        is_closed: False,
        is_anonymous: True,
        type_: "regular",
        allows_multiple_answers: False,
        correct_option_id: None,
        explanation: None,
        explanation_entities: None,
        open_period: None,
        close_date: None,
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, poll_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("poll:Do you like Gleam?")
}

pub fn poll_answer_handler_test() {
  let handler = fn(ctx: Context(String, TelegaError), answer: types.PollAnswer) {
    Ok(Context(..ctx, session: "poll_answer:" <> answer.poll_id))
  }

  let r =
    router.new("test")
    |> router.on_poll_answer(handler)

  let poll_answer_update =
    update.PollAnswerUpdate(
      from_id: 123,
      chat_id: 123,
      poll_answer: types.PollAnswer(
        poll_id: "poll123",
        voter_chat: None,
        user: Some(factory.user_with(id: 123, first_name: "Test")),
        option_ids: [0],
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, poll_answer_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("poll_answer:poll123")
}

pub fn shipping_query_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    query: types.ShippingQuery,
  ) {
    Ok(Context(..ctx, session: "shipping:" <> query.id))
  }

  let r =
    router.new("test")
    |> router.on_shipping_query(handler)

  let shipping_query_update =
    update.ShippingQueryUpdate(
      from_id: 123,
      chat_id: 123,
      shipping_query: types.ShippingQuery(
        id: "shipping123",
        from: factory.user_with(id: 123, first_name: "Test"),
        invoice_payload: "test_payload",
        shipping_address: types.ShippingAddress(
          country_code: "US",
          state: "CA",
          city: "San Francisco",
          street_line1: "123 Main St",
          street_line2: "",
          post_code: "94102",
        ),
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, shipping_query_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("shipping:shipping123")
}

pub fn pre_checkout_query_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    query: types.PreCheckoutQuery,
  ) {
    Ok(Context(..ctx, session: "checkout:" <> query.id))
  }

  let r =
    router.new("test")
    |> router.on_pre_checkout_query(handler)

  let pre_checkout_query_update =
    update.PreCheckoutQueryUpdate(
      from_id: 123,
      chat_id: 123,
      pre_checkout_query: types.PreCheckoutQuery(
        id: "checkout123",
        from: factory.user_with(id: 123, first_name: "Test"),
        currency: "USD",
        total_amount: 1000,
        invoice_payload: "test_payload",
        shipping_option_id: None,
        order_info: None,
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, pre_checkout_query_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("checkout:checkout123")
}

pub fn message_reaction_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    reaction: types.MessageReactionUpdated,
  ) {
    Ok(Context(..ctx, session: "reaction:" <> string.inspect(reaction.chat.id)))
  }

  let r =
    router.new("test")
    |> router.on_reaction(handler)

  let reaction_update =
    update.MessageReactionUpdate(
      from_id: 123,
      chat_id: 456,
      message_reaction_updated: types.MessageReactionUpdated(
        chat: factory.chat_with(id: 456, type_: "private"),
        message_id: 789,
        user: Some(factory.user_with(id: 123, first_name: "Test")),
        actor_chat: None,
        date: 1_234_567_890,
        old_reaction: [],
        new_reaction: [],
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, reaction_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("reaction:456")
}

pub fn chat_member_updated_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    member: types.ChatMemberUpdated,
  ) {
    Ok(
      Context(
        ..ctx,
        session: "member_updated:" <> string.inspect(member.chat.id),
      ),
    )
  }

  let r =
    router.new("test")
    |> router.on_chat_member_updated(handler)

  let member_user = factory.user_with(id: 789, first_name: "Member")

  let member_updated_update =
    update.ChatMemberUpdate(
      from_id: 123,
      chat_id: 456,
      chat_member_updated: types.ChatMemberUpdated(
        chat: factory.chat_with(id: 456, type_: "group"),
        from: factory.user_with(id: 123, first_name: "Admin"),
        date: 1_234_567_890,
        old_chat_member: types.ChatMemberMemberChatMember(
          types.ChatMemberMember(
            status: "member",
            tag: None,
            user: member_user,
            until_date: None,
          ),
        ),
        new_chat_member: types.ChatMemberMemberChatMember(
          types.ChatMemberMember(
            status: "member",
            tag: None,
            user: member_user,
            until_date: None,
          ),
        ),
        invite_link: None,
        via_join_request: None,
        via_chat_folder_invite_link: None,
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, member_updated_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("member_updated:456")
}

pub fn chat_join_request_handler_test() {
  let handler = fn(
    ctx: Context(String, TelegaError),
    request: types.ChatJoinRequest,
  ) {
    Ok(Context(..ctx, session: "join_request:" <> request.from.first_name))
  }

  let r =
    router.new("test")
    |> router.on_chat_join_request(handler)

  let join_request_update =
    update.ChatJoinRequestUpdate(
      from_id: 123,
      chat_id: 456,
      chat_join_request: types.ChatJoinRequest(
        chat: factory.chat_with(id: 456, type_: "group"),
        from: types.User(
          ..factory.user_with(id: 123, first_name: "NewUser"),
          username: Some("newuser"),
        ),
        user_chat_id: 123,
        date: 1_234_567_890,
        bio: None,
        invite_link: None,
      ),
      raw: factory.raw_update(message: factory.message(text: "")),
    )

  let c = make_ctx("initial")
  router.handle(r, c, join_request_update)
  |> should.be_ok()
  |> fn(ctx) { ctx.session }
  |> should.equal("join_request:NewUser")
}

fn test_sender_chat() {
  types.Chat(
    id: -69_420,
    type_: "channel",
    title: Some("testchat"),
    username: None,
    first_name: None,
    last_name: None,
    is_forum: None,
    is_direct_messages: None,
  )
}

pub fn user_id_and_chat_id_parsing_test() {
  let base_msg = factory.message(text: "/start")
  let msg_from_user = types.Message(..base_msg, sender_chat: None)
  let msg_from_chat =
    types.Message(..base_msg, sender_chat: Some(test_sender_chat()))

  let raw_from_user = factory.raw_update(message: msg_from_user)
  let raw_from_chat = factory.raw_update(message: msg_from_chat)

  let upd_from_user = update.raw_to_update(raw_from_user)
  let upd_from_chat = update.raw_to_update(raw_from_chat)

  should.equal(upd_from_user.from_id, 987_654_321)
  should.equal(upd_from_user.chat_id, 123_456_789)
  should.equal(upd_from_chat.from_id, -69_420)
  should.equal(upd_from_user.chat_id, 123_456_789)
}
