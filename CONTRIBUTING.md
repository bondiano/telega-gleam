# Contributing to Telega

Thanks for your interest in improving Telega — the Telegram Bot API library for
the BEAM. This guide covers how the repository is laid out, how to set up a dev
environment, the conventions we follow, and how changes get reviewed and
released.

By participating you agree to keep interactions respectful and constructive.

## Ways to contribute

- **Report bugs** — open an issue with a minimal reproduction (Gleam version, OS,
  and a small snippet or failing test).
- **Improve docs** — the module docstrings and `docs/*.md` are the canonical
  documentation (we publish to [hexdocs](https://hexdocs.pm/telega/), not a
  separate site). Typos and clarifications are very welcome.
- **Fix bugs / add features** — see the workflow below. For anything non-trivial,
  open an issue first so we can agree on the approach before you invest time.
- **Add an ecosystem package** — storage backends, HTTP clients, framework
  adapters. See [Adding an ecosystem package](#adding-an-ecosystem-package).

## Prerequisites

- **Gleam** `>= 1.12` (CI runs **1.16.0** — match it to avoid format/check drift).
- **Erlang/OTP** — a recent release (CI runs **28.0.1**). Telega targets the
  Erlang runtime only; there is no JavaScript target.
- **[Task](https://taskfile.dev/)** (`go-task`) — optional but recommended; every
  common workflow has a `task` shortcut. You can always fall back to raw `gleam`
  commands.

## Repository layout

This is a monorepo: the core library lives at the root, and each ecosystem
package is an independent Gleam project alongside it.

```
.
├── src/telega/            # core library
│   ├── model/             # Bot API types/decoder/encoder (GENERATED — see Codegen)
│   ├── flow/              # persistent state-machine engine
│   ├── internal/          # non-public helpers (registry, config, signal, …)
│   └── *.gleam            # router, bot, polling, api, reply, keyboard, …
├── test/                  # core tests
├── codegen/               # generator for the model layer
├── docs/                  # long-form guides (published to hexdocs)
├── examples/              # standalone example bots (00-echo-bot … 06-…)
├── telega_wisp/           # wisp webhook adapter
├── telega_mist/           # mist webhook adapter
├── telega_httpc/          # httpc HTTP client adapter
├── telega_hackney/        # hackney HTTP client adapter
├── telega_webapp/         # Telegram Mini Apps (initData validation)
├── telega_i18n/           # internationalization
├── telega_storage_postgres/   # session/flow storage backends
├── telega_storage_sqlite/
├── telega_storage_redis/
└── Taskfile.yml
```

New subsystems that are useful **outside** the core go into their own package
(following the pattern above). Things that belong to the bot runtime itself stay
in `src/telega/`.

## Development workflow

```sh
git clone https://github.com/bondiano/telega-gleam
cd telega-gleam

gleam deps download      # fetch dependencies for the core
gleam build              # type-check + compile
gleam test               # run the core test suite
gleam format             # format your changes
```

Before opening a PR, run the same checks CI runs (see [Pull requests](#pull-requests)):

```sh
gleam format --check src test
gleam check
gleam test
```

### Task shortcuts

| Command | What it does |
|---|---|
| `task format` | Format the root project |
| `task format:all` | Format the core, every ecosystem package, and every example |
| `task test` | Run the core test suite |
| `task test:all` | Run the core, every package, and every example test suite |
| `task codegen:fetch` | Download the latest Telegram Bot API spec into `codegen/` |
| `task codegen` | Regenerate the model layer, then `gleam format` + `gleam check` |
| `task codegen:diff` | Show what the last codegen run changed under `src/telega/model` |
| `task publish` | Publish the core + all ecosystem packages (maintainers — see below) |

The package and example lists live once in the `vars` block of `Taskfile.yml`.
Adding a new package or example there makes it part of `format:all`, `test:all`,
and `publish` automatically — keep that list in sync.

### Useful raw commands

```sh
gleam test -- --module=router_test   # run a single test module
GLEAM_LOG=trace gleam test           # tests with debug logging
gleam docs build                     # build the docs locally
```

### Working on a package or example

Each package/example is its own project — `cd` into it and use `gleam` as usual:

```sh
cd telega_wisp
gleam deps download
gleam test
```

Ecosystem packages depend on the **local** core via a path dependency
(`telega = { path = ".." }`), so your changes to `src/telega/` are picked up
immediately. See [Releasing](#releasing-maintainers) for how that interacts with
publishing.

## The model layer is generated

`src/telega/model/{types,decoder,encoder}.gleam` are **generated** from the
machine-readable Bot API spec — do not hand-edit the generated region.

Each file is split by a marker line:

```gleam
// === MANUAL — not regenerated below (codegen) ===
```

Everything **above** the marker is overwritten by the generator; everything from
the marker to EOF (method-parameter types, generics, hand-tuned helpers) is
preserved verbatim. To change generated output, edit the generator in
`codegen/`; to add things the spec can't express, put them in the manual suffix.

Bumping to a new Bot API version:

```sh
task codegen:fetch   # pull the latest api.json
task codegen         # regenerate + format + check
task codegen:diff    # review the diff
```

See `codegen/README.md` for details.

## Coding conventions

- **Format with `gleam format`.** CI fails on unformatted code.
- **Shorthand field syntax is required** in record construction, updates, and
  pattern matching:

  ```gleam
  // ✅
  Router(commands:, text_routes:, callback_routes:)
  // ❌
  Router(commands: commands, text_routes: text_routes)
  ```

- **Prefer functional, declarative, immutable** style — small focused functions,
  `use` for callback-heavy flows, descriptive names.
- **Handlers** follow the standard signature and always return the (possibly
  updated) context:

  ```gleam
  fn handler(ctx: Context(session, error), data: Type) -> Result(Context(session, error), error)
  ```

- **Builders** use the fluent `with_*` / `set_*` pattern (see `telega.gleam`).
- **Public API needs doc comments** (`///`). Module-level guides go in `////`
  docstrings or `docs/*.md` — that is where end-user documentation lives.

When in doubt, match the style of the surrounding code. `CLAUDE.md` captures the
project's architecture and conventions in more depth.

## Testing

We favor **integration tests that verify real behavior** over unit tests that
only assert something compiles. Priorities: message routing, error recovery and
edge cases, conversation/flow behavior, and middleware effects.

- Core tests live in `test/`; use the helpers in `telega/testing/*`
  (`context`, `factory`, `mock`, …) to build updates, contexts, and stub the API
  client. See `docs/testing.md`.
- Storage adapters with external services (Postgres, Redis) **skip** their
  integration tests gracefully when no service is reachable, so `task test:all`
  passes on a clean machine. If you add such tests, keep them skippable.
- Add or update tests for every behavioral change. A bug fix should come with a
  test that fails before the fix.

## Commit messages

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add per-user rate limit middleware
fix: correct decode of optional fields
docs: update conversation guide
refactor: extract chat instance lifecycle
test: cover drain timeout path
chore: bump dependencies
```

Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`,
`style`, `revert`. Keep the subject in the imperative mood and scoped to one
logical change.

## Pull requests

1. Branch off `master`.
2. Make your change with tests and docs.
3. Ensure the CI checks pass locally:

   ```sh
   gleam format --check src test
   gleam check
   gleam test
   ```

   If you touched a package or example, run its checks too (or `task test:all`).
4. Open a PR with a clear description of **what** and **why**. Link any related
   issue.

CI runs format check, `gleam check`, and the test suite for the core and — via
per-package workflows triggered on path changes — for each affected package.
Green CI is required before merge.

## Adding an ecosystem package

1. Create `telega_<name>/` as a standalone Gleam project (copy the structure of
   an existing one, e.g. `telega_storage_sqlite`).
2. Depend on the core with a **path dependency** so local development tracks your
   core changes:

   ```toml
   # telega_<name>/gleam.toml
   [dependencies]
   telega = { path = ".." }
   ```

3. Add the package name to the `PACKAGES` var in `Taskfile.yml` and add a
   `.github/workflows/check-telega-<name>.yml` (copy an existing one and adjust
   the path filter and working directory).
4. Include tests and a usage section in the module docstring / README.

## Releasing (maintainers)

Path dependencies cannot be published to Hex, but they are required for local
dev and CI (otherwise `gleam check` would resolve against the *published* core
and miss unreleased API). `task publish` reconciles this:

1. Bump the `version` in the `gleam.toml` of every package you changed
   (the core first if its public API changed). Hex rejects republishing an
   existing version.
2. Commit your changes (including the path-dependency `gleam.toml` files —
   the publish task restores them via `git checkout` afterwards).
3. Run the release:

   ```sh
   task publish        # publishes core, then every package
   # or, granularly:
   task publish:core
   task publish:packages
   ```

   For each package that uses `telega = { path = ".." }`, the task temporarily
   rewrites it to a version requirement derived from the core version, runs
   `gleam publish`, then restores the path dependency from git. Packages whose
   version was not bumped fail the "already published" check and are listed as
   skipped at the end — that is expected.

You need `HEXPM_API_KEY` set (or you'll be prompted to authenticate).

## License

By contributing, you agree that your contributions are licensed under the
project's Apache-2.0 license (declared in `gleam.toml`).
