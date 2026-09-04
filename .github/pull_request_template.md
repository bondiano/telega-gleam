## What and why

<!-- What does this change do, and what problem does it solve? Link the issue. -->

## Checklist

- [ ] `gleam format --check src test` passes
- [ ] `gleam check` passes
- [ ] `gleam test` passes (plus the affected package/example, or `task test:all`)
- [ ] **Behaviour changed → docs updated.** The docstring of every public
      function I touched, plus the relevant guide in `docs/*.md` and the section
      in `README.md` / `CLAUDE.md` that describes it. A behavioural change with
      no doc change is a bug report waiting to happen.
- [ ] **Behaviour changed → `CHANGELOG.md` updated** under `## [Unreleased]`,
      in the right Keep a Changelog section (`Added` / `Changed` / `Deprecated`
      / `Removed` / `Fixed`). Mark breaking changes **BREAKING** and say what
      to do instead.
- [ ] A bug fix comes with a test that fails without it
- [ ] Touched the model layer or the API spec? `task codegen:check` and
      `task api:check` pass
- [ ] Conventional Commit subject (`feat:`, `fix:`, `docs:`, …)

<!--
Reviewers: see CONTRIBUTING.md for the repository layout, what is generated
from the API spec, and the release process.
-->
