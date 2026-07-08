import gleam/erlang/process
import gleam/list
import gleam/result
import gleam/string
import sqlight

import telega
import telega/dialog
import telega/flow/registry
import telega/flow/types
import telega/reply
import telega/router.{type Router}
import telega_httpc

import restaurant_booking/config
import restaurant_booking/constants
import restaurant_booking/database
import restaurant_booking/dependencies.{type Dependencies, Dependencies}
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

  let catalog = i18n.catalog()
  let client = telega_httpc.new(cfg.bot_token)

  let bot =
    telega.new_for_polling(api_client: client)
    // Inject services once. `with_dependencies` must come before `with_router`:
    // it changes the builder's `dependencies` type and resets `dependencies`-typed fields.
    |> telega.with_dependencies(Dependencies(db:, catalog:))
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
) -> Router(Nil, String, Dependencies) {
  // Handlers and flow steps read services from `ctx.dependencies`. `db` is still needed
  // here only to build each flow's *persistence backend* — that storage is
  // created at init, before any update arrives, so it can't come from `ctx`.
  let registration_flow = registration.create_registration_flow(db)
  let menu_flow = menu.create_menu_flow(db)
  // Booking is a declarative dialog (`telega/dialog`) compiled onto the same
  // flow machinery — registered without a trigger and started from the
  // `/book` handler after the registration check.
  let booking_dialog = booking.create_booking_dialog(db)

  let flow_registry =
    registry.new_registry()
    |> registry.register(types.OnCommand("/start"), registration_flow)
    |> registry.register(types.OnCommand("/menu"), menu_flow)
    |> dialog.attach(booking_dialog)
    |> registry.register_cancel_command_with("/cancel", fn(ctx, _cancelled) {
      let _ = reply.with_text(ctx, i18n.t(ctx, "common.cancelled", []))
      Ok(ctx)
    })

  let base =
    router.new(cfg.restaurant_name <> constants.bot_name_suffix)
    |> router.use_middleware(i18n.middleware())
    |> router.on_command("/help", handlers.help)
    |> router.on_command("/language", settings.language)
    |> router.on_command("/my_bookings", handlers.my_bookings)
    |> router.on_command("/book", booking.start_booking(flow_registry))

  // Register one exact callback per locale (`lang:en`, `lang:ru`). Exact matches
  // take priority over the flows' catch-all callback handler, which is a prefix.
  let with_language =
    list.fold(i18n.supported_locales, base, fn(r, locale) {
      router.on_callback(
        r,
        router.Exact("lang:" <> locale),
        settings.set_language,
      )
    })

  with_language
  |> registry.apply_to_router(flow_registry)
}
