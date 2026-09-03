# codegen

Regenerates Telega's model layer (`src/telega/model/{types,decoder,encoder}.gleam`)
and the per-method fact table (`src/telega/internal/method_info.gleam`)
from the machine-readable Telegram Bot API spec
([PaulSonOfLars/telegram-bot-api-spec](https://github.com/PaulSonOfLars/telegram-bot-api-spec)).

## Usage

From the repository root:

```bash
task codegen:fetch   # download the latest api.json into codegen/
task codegen         # regenerate + gleam format + gleam check
task codegen:diff    # review what changed in src/telega/model
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

`internal/method_info.gleam` has no manual suffix — it is generated whole. It
answers one question per method: whether replaying it after a transport error
or a 5xx is safe, which is what `telega/client`'s `RetryPolicy` reads. The spec
does not carry that fact, so the generator derives it from two name-prefix
tables in `codegen.gleam` (`idempotent_prefixes` / `non_idempotent_prefixes`)
plus a short override list for the ones the name gets wrong (`sendChatAction`
is safe; `answerWebAppQuery` and `answerGuestQuery` are not). A method matching
neither table **fails the generation** with its name, so a new API version
cannot quietly land a new `send`-alike on the retryable side.

## Bumping the Bot API version

1. `task codegen:fetch`
2. `task codegen`
3. `task codegen:diff` and review — the diff should be the new/changed types,
   decoders and encoders only; the manual suffixes must be untouched.
4. Fix any manual blocks that reference renamed/removed types, then
   `gleam test` and `task test:all`.
