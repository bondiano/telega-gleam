import gleam/result
import gleam/string
import pog
import telega/polling

import telega
import telega/flow
import telega/router.{type Router}

import restaurant_booking/config
import restaurant_booking/constants
import restaurant_booking/database
import restaurant_booking/flows/booking
import restaurant_booking/flows/registration
import restaurant_booking/handlers
import restaurant_booking/util

pub fn start(cfg: config.Config) -> Result(Nil, String) {
  use db <- result.try(database.connect(cfg.database))

  util.log("Connected to database")

  let bot =
    telega.new_for_polling(cfg.bot_token)
    |> telega.with_router(create_router(cfg, db))

  use telega_instance <- result.try(
    telega.init_for_polling_nil_session(bot) |> result.map_error(string.inspect),
  )

  util.log("Bot started! Send /start to begin")

  use poller <- result.try(
    polling.start_polling_default(telega_instance)
    |> result.map_error(string.inspect),
  )

  polling.wait_finish(poller)
  Ok(Nil)
}

fn create_router(cfg: config.Config, db: pog.Connection) -> Router(Nil, String) {
  let registration_flow = registration.create_registration_flow(db)
  let booking_flow = booking.create_booking_flow(db)

  router.new(cfg.restaurant_name <> constants.bot_name_suffix)
  |> flow.register_flows([
    #(flow.OnCommand("/start"), registration_flow),
    #(flow.OnCommand("/book"), booking_flow),
  ])
  |> router.on_command("/help", handlers.help)
  |> router.on_command("/my_bookings", fn(ctx, cmd) {
    handlers.my_bookings(db, ctx, cmd)
  })
}
