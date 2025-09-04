import gleam/erlang/process
import gleam/result
import gleam/string
import pog

import telega
import telega/conversation/persistent_flow as pflow
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

  util.log("Bot started! Send /start to begin")

  case telega.init_for_polling(bot) {
    Ok(_) -> {
      util.log("Bot is running...")
      process.sleep_forever()
      Ok(Nil)
    }
    Error(err) -> {
      util.log_error("Failed to start bot: " <> string.inspect(err))
      Error("Failed to start bot")
    }
  }
}

fn create_router(cfg: config.Config, db: pog.Connection) -> Router(Nil, String) {
  let registration_flow = registration.create_registration_flow(db)
  let booking_flow = booking.create_booking_flow(db)

  router.new(cfg.restaurant_name <> constants.bot_name_suffix)
  |> router.on_command("/start", pflow.to_handler(registration_flow))
  |> router.on_command("/book", pflow.to_handler(booking_flow))
  |> router.on_command("/help", handlers.help)
  |> router.on_command("/mybookings", fn(ctx, cmd) {
    handlers.my_bookings(db, ctx, cmd)
  })
}
