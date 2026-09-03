//// Slots the router fills while dispatching, read back by the bot actor for
//// telemetry and by `router.matched_route` for user code.
////
//// They live here rather than in `telega/router` because `telega/bot` cannot
//// import the router (the router imports the bot), and one name used at two
//// different types is exactly the mistake a shared constant prevents.

import telega/scope

/// Label of the route that claimed the current update.
pub const route_slot: scope.Key(String) = scope.Key("telega/route")

/// Name of the leaf router that route belonged to.
pub const router_slot: scope.Key(String) = scope.Key("telega/router")
