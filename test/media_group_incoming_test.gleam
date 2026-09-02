//// Regression tests for H6: `MediaGroupUpdate` was declared and routable but
//// never constructed — an album arrived as N separate `PhotoUpdate`s and
//// `router.on_media_group` was dead code.

import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/factory_supervisor as fsup
import gleam/otp/supervision
import gleeunit/should

import telega/bot
import telega/internal/registry
import telega/model/types
import telega/testing/context
import telega/testing/factory
import telega/update as update_module

pub type Sess {
  Sess(counter: Int)
}

pub type Err {
  Err(message: String)
}

const album_chat = 77

fn start_test_factory() {
  let assert Ok(started) =
    fsup.worker_child(bot.start_chat_instance)
    |> fsup.restart_strategy(supervision.Transient)
    |> fsup.start
  started.data
}

fn start_bot(
  name name: String,
  media_group_timeout media_group_timeout: option.Option(Int),
  router router: fn(bot.Context(Sess, Err, Nil), update_module.Update) ->
    Result(bot.Context(Sess, Err, Nil), Err),
) -> bot.BotSubject {
  let assert Ok(reg) = registry.start(name)
  let assert Ok(started) =
    bot.start(
      registry: reg,
      config: context.config(),
      bot_info: factory.bot_user(),
      router_handler: router,
      pre_handlers: [],
      session_settings: context.session_settings_with(
        default: fn() { Sess(0) },
        initial: Sess(0),
      ),
      catch_handler: context.catch_handler(),
      dependencies: Nil,
      chat_factory: start_test_factory(),
      chat_idle_timeout: None,
      chat_init_timeout: 5000,
      media_group_timeout:,
      name: None,
    )
  started.data
}

/// One message of an album: a photo carrying the shared `media_group_id`.
fn album_photo(
  media_group_id: String,
  file_id: String,
) -> update_module.Update {
  let assert update_module.PhotoUpdate(
    photos:,
    message:,
    from_id:,
    chat_id:,
    ..,
  ) =
    factory.photo_update_with(
      photos: [factory.photo_size_with(file_id:)],
      from_id: album_chat,
      chat_id: album_chat,
    )
  let message = types.Message(..message, media_group_id: Some(media_group_id))
  update_module.PhotoUpdate(
    photos:,
    message:,
    from_id:,
    chat_id:,
    raw: factory.raw_update(message:),
  )
}

pub fn h6_album_arrives_as_one_media_group_update_test() {
  let seen = process.new_subject()
  let bot_subject =
    start_bot(
      name: "h6_album",
      media_group_timeout: Some(100),
      router: fn(ctx, update) {
        process.send(seen, update)
        Ok(ctx)
      },
    )

  // Every message is answered, so the poller's in-flight accounting stays
  // honest even though only one update reaches the router.
  ["a", "b", "c"]
  |> list.each(fn(file_id) {
    bot.handle_update(bot_subject, album_photo("album-1", file_id))
    |> should.be_true
  })

  let assert Ok(update_module.MediaGroupUpdate(
    media_group_id:,
    messages:,
    chat_id:,
    ..,
  )) = process.receive(seen, 2000)

  media_group_id |> should.equal("album-1")
  chat_id |> should.equal(album_chat)
  list.length(messages) |> should.equal(3)

  // Nothing else is routed: the individual photos were consumed by the album.
  process.receive(seen, 300) |> should.be_error
}

pub fn h6_aggregation_is_opt_in_test() {
  let seen = process.new_subject()
  let bot_subject =
    start_bot(
      name: "h6_optout",
      media_group_timeout: None,
      router: fn(ctx, update) {
        process.send(seen, update)
        Ok(ctx)
      },
    )

  bot.handle_update(bot_subject, album_photo("album-2", "a"))
  |> should.be_true

  let assert Ok(update_module.PhotoUpdate(..)) = process.receive(seen, 1000)
}
