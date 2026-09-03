# codegen

Regenerates everything Telega can derive from the machine-readable Telegram Bot
API spec ([PaulSonOfLars/telegram-bot-api-spec](https://github.com/PaulSonOfLars/telegram-bot-api-spec)):

| Output | Shape |
| --- | --- |
| `src/telega/model/{types,decoder,encoder}.gleam` | generated prefix + manual suffix |
| `src/telega/internal/method_info.gleam` | whole file — the method list and per-method idempotency |
| `src/telega/internal/update_info.gleam` | whole file — the update kinds, i.e. the `allowed_updates` names |
| `src/telega/update.gleam` | one generated block: the `raw_to_update` dispatch chain |
| `src/telega/api.gleam` | **checked, not generated**: one wrapper per spec method, no more, no less |

## Usage

From the repository root:

```bash
task codegen:fetch   # download the latest api.json into codegen/
task codegen         # regenerate + gleam format + gleam check
task codegen:diff    # review what changed in src/telega/model
task codegen:check   # CI: fail if the checked-in generated code has drifted
task api:check       # CI: the Bot API version agrees in spec, tables and README
task api:latest      # is a newer spec published upstream?
```

## How it works

Each target module is split into a **generated prefix** and a hand-written
**manual suffix**, divided by the marker line:

```gleam
// === MANUAL — not regenerated below (codegen) ===
```

The generator overwrites everything above the marker and preserves everything
from the marker to EOF verbatim. The manual suffixes hold things that cannot be
derived from the spec:

- method-parameter types (`*Parameters`) and their `new_*` / `default_*`
  constructors, plus their encoders (parameters are only ever encoded);
- the generic `IntOrString` / `FileOrString` types and codecs;
- decoders for unions whose discriminator is not mechanically derivable
  (`InlineQueryResult`, `InputMessageContent`, `MaybeInaccessibleMessage`);
- the `InputMedia` union, which the library keeps broader than the spec
  (it accepts Location/Sticker/Venue media);
- small helpers such as `messages_array_decoder`.

Generated decoders use `decode.optional_field(name, None, decode.optional(...))`
for optional fields so a missing key decodes to `None` instead of failing.

Import lists for `decoder.gleam` / `encoder.gleam` are computed by scanning the
full file body (generated + manual suffix), so they stay correct across the
manual boundary.

## Fully generated tables

`internal/method_info.gleam` has no manual suffix — it is generated whole. It
lists every method of this Bot API version (`methods()` / `is_method`) and
answers one question about each: whether replaying it after a transport error
or a 5xx is safe, which is what `telega/client`'s `RetryPolicy` reads. The spec
does not carry that fact, so the generator derives it from two name-prefix
tables in `codegen.gleam` (`idempotent_prefixes` / `non_idempotent_prefixes`)
plus a short override list for the ones the name gets wrong (`sendChatAction`
is safe; `answerWebAppQuery` and `answerGuestQuery` are not). A method matching
neither table **fails the generation** with its name, so a new API version
cannot quietly land a new `send`-alike on the retryable side.

`internal/update_info.gleam` is generated whole from the fields of the spec's
`Update` type, which are exactly the names Telegram accepts in
`allowed_updates`. `telega.with_allowed_updates` / `with_extra_allowed_updates`
warn about a name that is not in it, and `router`'s route → update-kind mapping
is tested against it.

## The generated block in `update.gleam`

`update.gleam` is hand-written apart from `raw_to_update`, which lives between

```gleam
// === GENERATED — do not edit (codegen) ===
// === END GENERATED (codegen) ===
```

and is emitted as one `on_field` line per `Update` field — `message` last,
because it dispatches further on the message's own content. The builder each
field goes to is `new_<field>_update`, with the four exceptions listed in
`update_builder_overrides` in `codegen.gleam`. A new update kind in the spec
therefore becomes a call to a function that does not exist yet: `gleam check`
fails, instead of the kind being silently decoded as `UnknownUpdate`.

## Checked, not generated: `api.gleam`

The method wrappers are hand-written (each has its own parameter record and
result type), but *which* methods exist is a spec fact. The generator scans
`api.gleam` for `path: "<method>"` and fails when the spec has a method with no
wrapper, or `api.gleam` has a wrapper for a method the spec no longer has.

## Bumping the Bot API version

1. `task codegen:fetch`
2. `task codegen`
3. `task codegen:diff` and review — the diff should be the new/changed types,
   decoders and encoders only; the manual suffixes must be untouched.
4. Fix any manual blocks that reference renamed/removed types, add wrappers for
   new methods and builders for new update kinds until `gleam check` passes,
   then `gleam test` and `task test:all`.
5. Update the `**Bot API version:**` line in `README.md` (and `CLAUDE.md`), and
   confirm with `task api:check`.
