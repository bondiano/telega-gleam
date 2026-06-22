//// Shared services injected into every handler via `telega.with_dependencies`.
////
//// `dependencies` is the non-persisted dependency-injection slot on `Context`: unlike
//// `session` (per-user state that is persisted), `dependencies` holds services that
//// live for the whole bot and are set once at init — here the SQLite
//// connection and the i18n catalog. Handlers, flow steps, and middleware read
//// them via `ctx.dependencies.db` / `ctx.dependencies.catalog`. See `docs/dependency-injection.md`.

import sqlight
import telega_i18n.{type Catalog}

pub type Dependencies {
  Dependencies(db: sqlight.Connection, catalog: Catalog)
}
