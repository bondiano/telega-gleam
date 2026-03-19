import gleam/erlang/process
import gleam/result
import gleam/string
import pog

import telega
import telega/flow/registry
import telega/flow/types
import telega/router.{type Router}

import restaurant_booking/config
import restaurant_booking/constants
import restaurant_booking/database
import restaurant_booking/flows/booking
import restaurant_booking/flows/menu
import restaurant_booking/flows/registration
import restaurant_booking/handlers
import restaurant_booking/util

pub fn start(cfg: config.Config) -> Result(Nil, String) {
  use db <- result.try(database.connect(cfg.database))

  util.log("Connected to database")

  let bot =
    telega.new_for_polling(cfg.bot_token)
    |> telega.with_router(build_router(cfg, db))

  use _telega_instance <- result.try(
    telega.init_for_polling_nil_session(bot) |> result.map_error(string.inspect),
  )

  util.log("Bot started! Send /start to begin")

  // Bot is running with supervision tree (including polling)
  process.sleep_forever()
  Ok(Nil)
}

pub fn build_router(
  cfg: config.Config,
  db: pog.Connection,
) -> Router(Nil, String) {
  let registration_flow = registration.create_registration_flow(db)
  let booking_flow = booking.create_booking_flow(db)
  let menu_flow = menu.create_menu_flow(db)

  let flow_registry =
    registry.new_registry()
    |> registry.register(types.OnCommand("/start"), registration_flow)
    |> registry.register(types.OnCommand("/book"), booking_flow)
    |> registry.register(types.OnCommand("/menu"), menu_flow)

  router.new(cfg.restaurant_name <> constants.bot_name_suffix)
  |> router.on_command("/help", handlers.help)
  |> router.on_command("/my_bookings", fn(ctx, cmd) {
    handlers.my_bookings(db, ctx, cmd)
  })
  |> registry.apply_to_router(flow_registry)
}
