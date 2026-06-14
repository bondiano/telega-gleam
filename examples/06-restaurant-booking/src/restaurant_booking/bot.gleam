import gleam/erlang/process
import gleam/list
import gleam/result
import gleam/string
import sqlight

import telega
import telega/flow/registry
import telega/flow/types
import telega/router.{type Router}
import telega_httpc

import restaurant_booking/config
import restaurant_booking/constants
import restaurant_booking/database
import restaurant_booking/flows/booking
import restaurant_booking/flows/menu
import restaurant_booking/flows/registration
import restaurant_booking/handlers
import restaurant_booking/i18n
import restaurant_booking/observability
import restaurant_booking/settings
import restaurant_booking/util

pub fn start(cfg: config.Config) -> Result(Nil, String) {
  // Subscribe to telemetry events before the bot starts handling updates.
  observability.attach()

  use db <- result.try(database.connect(cfg.database))

  util.log("Connected to database")

  let client = telega_httpc.new(cfg.bot_token)

  let bot =
    telega.new_for_polling(api_client: client)
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
  db: sqlight.Connection,
) -> Router(Nil, String) {
  let registration_flow = registration.create_registration_flow(db)
  let booking_flow = booking.create_booking_flow(db)
  let menu_flow = menu.create_menu_flow(db)

  let flow_registry =
    registry.new_registry()
    |> registry.register(types.OnCommand("/start"), registration_flow)
    |> registry.register(types.OnCommand("/book"), booking_flow)
    |> registry.register(types.OnCommand("/menu"), menu_flow)

  let catalog = i18n.catalog()

  let base =
    router.new(cfg.restaurant_name <> constants.bot_name_suffix)
    |> router.use_middleware(i18n.middleware(catalog, db))
    |> router.on_command("/help", handlers.help)
    |> router.on_command("/language", settings.language)
    |> router.on_command("/my_bookings", fn(ctx, cmd) {
      handlers.my_bookings(db, ctx, cmd)
    })

  // Register one exact callback per locale (`lang:en`, `lang:ru`). Exact matches
  // take priority over the flows' catch-all callback handler, which is a prefix.
  let with_language =
    list.fold(i18n.supported_locales, base, fn(r, locale) {
      router.on_callback(
        r,
        router.Exact("lang:" <> locale),
        fn(ctx, query_id, data) {
          settings.set_language(catalog, db, ctx, query_id, data)
        },
      )
    })

  with_language
  |> registry.apply_to_router(flow_registry)
}
