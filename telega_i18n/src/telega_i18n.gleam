//// Internationalization (i18n) for the [Telega](https://hexdocs.pm/telega)
//// Telegram Bot Library.
////
//// Translations live in a [`Catalog`](#Catalog) — one flat table of dotted
//// keys per locale. Load them from TOML or JSON, install the
//// [`middleware`](#middleware) to resolve the active locale per update, then
//// call [`t`](#t) inside handlers.
////
//// ## Quick start
////
//// `locales/en.toml`:
////
//// ```toml
//// greeting = "Hello, {name}!"
////
//// [cart]
//// title = "Your cart"
//// ```
////
//// `locales/ru.toml`:
////
//// ```toml
//// greeting = "Привет, {name}!"
////
//// [cart]
//// title = "Ваша корзина"
//// ```
////
//// ```gleam
//// import gleam/option.{None}
//// import telega/router
//// import telega_i18n
////
//// pub fn build_router(catalog) {
////   // `catalog` loaded once at startup, e.g. with `load_toml_dir`.
////   router.new("bot")
////   |> router.use_middleware(telega_i18n.middleware(
////     catalog:,
////     // Optional per-user override stored in the session. Return `None`
////     // to fall back to the user's Telegram `language_code`.
////     from: fn(_session) { None },
////   ))
////   |> router.on_command("start", greet)
//// }
////
//// fn greet(ctx, _command) {
////   let msg = telega_i18n.t(ctx, "greeting", [#("name", "Lucy")])
////   // -> "Hello, Lucy!" or "Привет, Lucy!" depending on the user's locale
////   reply.with_text(ctx, msg)
//// }
//// ```
////
//// ## Locale resolution
////
//// For every update the middleware picks the first available of:
////
//// 1. the session override returned by your `from` resolver,
//// 2. the sender's Telegram `language_code`,
//// 3. the catalog's default locale.
////
//// The resolved locale is stored in the process dictionary of the chat
//// instance handling the update, so [`t`](#t) needs only the key.
////
//// ## Fallback chains
////
//// Lookups walk a chain: the active locale, its base language (`"en-US"` →
//// `"en"`), any explicit [`with_fallback`](#with_fallback) entries, and finally
//// the default locale. A missing key returns the key itself, so nothing ever
//// crashes on a typo.
////
//// ## Pluralization
////
//// [`tn`](#tn) selects a CLDR plural category (`one`/`few`/`many`/`other`) and
//// looks up `"<key>.<category>"`. The `count` is injected as `{count}`
//// automatically. English and Russian rules are built in.
////
//// ```toml
//// [items]
//// one = "{count} item"
//// other = "{count} items"
//// ```
////
//// ```gleam
//// telega_i18n.tn(ctx, "items", 5, [])
//// // -> "5 items"
//// ```

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/atom.{type Atom}
import gleam/float
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import simplifile
import tom

import telega/bot.{type Context}
import telega/model/types.{type Update as ModelUpdate, type User}
import telega/router.{type Middleware}
import telega/update.{type Update}

// Types ----------------------------------------------------------------------

/// A collection of translations keyed by locale. Build it with [`new`](#new)
/// and one of the loaders, then hand it to [`middleware`](#middleware).
pub opaque type Catalog {
  Catalog(
    default: String,
    locales: Dict(String, Dict(String, String)),
    fallbacks: Dict(String, List(String)),
  )
}

/// Errors raised while loading translations.
pub type I18nError {
  /// The TOML/JSON content could not be parsed.
  ParseError(message: String)
  /// A file or directory could not be read.
  FileError(message: String)
}

// Catalog construction -------------------------------------------------------

/// Create an empty catalog with the given default locale. The default is the
/// last link of every fallback chain.
pub fn new(default_locale default_locale: String) -> Catalog {
  Catalog(default: default_locale, locales: dict.new(), fallbacks: dict.new())
}

/// Add (or merge into) a locale from an already-flattened map of dotted keys
/// to templates. Later entries win on conflict.
pub fn add_locale(
  catalog catalog: Catalog,
  locale locale: String,
  translations translations: Dict(String, String),
) -> Catalog {
  let existing =
    dict.get(catalog.locales, locale)
    |> result.unwrap(dict.new())
  let merged = dict.merge(existing, translations)
  Catalog(..catalog, locales: dict.insert(catalog.locales, locale, merged))
}

/// Register an explicit fallback chain for a locale. These locales are tried
/// (in order) after the active locale and its base language but before the
/// default locale.
pub fn with_fallback(
  catalog catalog: Catalog,
  locale locale: String,
  chain chain: List(String),
) -> Catalog {
  Catalog(..catalog, fallbacks: dict.insert(catalog.fallbacks, locale, chain))
}

/// The catalog's default locale.
pub fn default_locale(catalog: Catalog) -> String {
  catalog.default
}

/// The list of locales the catalog knows about.
pub fn locales(catalog: Catalog) -> List(String) {
  dict.keys(catalog.locales)
}

// Loaders --------------------------------------------------------------------

/// Parse a TOML document and merge it into the catalog under `locale`. Nested
/// tables become dotted keys (`[cart] title = "..."` → `cart.title`).
pub fn add_toml(
  catalog catalog: Catalog,
  locale locale: String,
  content content: String,
) -> Result(Catalog, I18nError) {
  case tom.parse(content) {
    Ok(parsed) -> {
      let flat = flatten_toml("", parsed, []) |> dict.from_list
      Ok(add_locale(catalog, locale, flat))
    }
    Error(error) -> Error(ParseError(string.inspect(error)))
  }
}

/// Parse a JSON document and merge it into the catalog under `locale`. Nested
/// objects become dotted keys.
pub fn add_json(
  catalog catalog: Catalog,
  locale locale: String,
  content content: String,
) -> Result(Catalog, I18nError) {
  case json.parse(content, decode.dynamic) {
    Ok(value) -> {
      let flat = flatten_dynamic("", value, []) |> dict.from_list
      Ok(add_locale(catalog, locale, flat))
    }
    Error(error) -> Error(ParseError(string.inspect(error)))
  }
}

/// Load every `*.toml` file in `dir` as a locale named after the file
/// (`en.toml` → `"en"`), merging them into `catalog`.
pub fn load_toml_dir(
  catalog catalog: Catalog,
  dir dir: String,
) -> Result(Catalog, I18nError) {
  use files <- result.try(
    simplifile.read_directory(dir)
    |> result.map_error(fn(e) { FileError(string.inspect(e)) }),
  )

  files
  |> list.filter(string.ends_with(_, ".toml"))
  |> list.fold(Ok(catalog), fn(acc, file) {
    use cat <- result.try(acc)
    use content <- result.try(
      simplifile.read(dir <> "/" <> file)
      |> result.map_error(fn(e) { FileError(string.inspect(e)) }),
    )
    let locale = string.replace(file, ".toml", "")
    add_toml(cat, locale, content)
  })
}

/// Load every `*.json` file in `dir` as a locale named after the file
/// (`en.json` → `"en"`), merging them into `catalog`.
pub fn load_json_dir(
  catalog catalog: Catalog,
  dir dir: String,
) -> Result(Catalog, I18nError) {
  use files <- result.try(
    simplifile.read_directory(dir)
    |> result.map_error(fn(e) { FileError(string.inspect(e)) }),
  )

  files
  |> list.filter(string.ends_with(_, ".json"))
  |> list.fold(Ok(catalog), fn(acc, file) {
    use cat <- result.try(acc)
    use content <- result.try(
      simplifile.read(dir <> "/" <> file)
      |> result.map_error(fn(e) { FileError(string.inspect(e)) }),
    )
    let locale = string.replace(file, ".json", "")
    add_json(cat, locale, content)
  })
}

// Translation (pure) ---------------------------------------------------------

/// Translate `key` in an explicit `locale`, interpolating `{placeholder}`
/// values from `args`. Missing keys return the key unchanged.
///
/// Prefer [`t`](#t) inside handlers; this is the pure building block, handy
/// for tests and locale-agnostic call sites.
pub fn translate(
  catalog catalog: Catalog,
  locale locale: String,
  key key: String,
  args args: List(#(String, String)),
) -> String {
  case lookup(catalog, locale, key) {
    Ok(template) -> interpolate(template, args)
    Error(_) -> key
  }
}

/// Pluralizing variant of [`translate`](#translate). Picks the CLDR category
/// for `count`, looks up `"<key>.<category>"` (falling back to `"<key>.other"`),
/// and injects `count` as `{count}`.
pub fn translate_count(
  catalog catalog: Catalog,
  locale locale: String,
  key key: String,
  count count: Int,
  args args: List(#(String, String)),
) -> String {
  let args = [#("count", int.to_string(count)), ..args]
  let category = plural_category(locale, count)
  case lookup(catalog, locale, key <> "." <> category) {
    Ok(template) -> interpolate(template, args)
    Error(_) ->
      case lookup(catalog, locale, key <> ".other") {
        Ok(template) -> interpolate(template, args)
        Error(_) -> interpolate(key, args)
      }
  }
}

fn lookup(
  catalog: Catalog,
  locale: String,
  key: String,
) -> Result(String, Nil) {
  locale_chain(catalog, locale)
  |> list.find_map(fn(loc) {
    case dict.get(catalog.locales, loc) {
      Ok(table) -> dict.get(table, key)
      Error(_) -> Error(Nil)
    }
  })
}

fn locale_chain(catalog: Catalog, locale: String) -> List(String) {
  let base = case string.split_once(locale, "-") {
    Ok(#(language, _region)) -> [language]
    Error(_) -> []
  }
  let extra =
    dict.get(catalog.fallbacks, locale)
    |> result.unwrap([])

  [locale]
  |> list.append(base)
  |> list.append(extra)
  |> list.append([catalog.default])
  |> list.unique
}

fn interpolate(template: String, args: List(#(String, String))) -> String {
  list.fold(args, template, fn(acc, pair) {
    string.replace(acc, "{" <> pair.0 <> "}", pair.1)
  })
}

// Pluralization (CLDR) -------------------------------------------------------

/// Return the CLDR plural category (`"one"`, `"few"`, `"many"`, `"other"`) for
/// `count` in `locale`. Russian and English have dedicated rules; every other
/// locale uses the English rule.
pub fn plural_category(locale: String, count: Int) -> String {
  case base_language(locale) {
    "ru" | "uk" | "be" -> east_slavic_category(count)
    _ -> english_category(count)
  }
}

fn base_language(locale: String) -> String {
  case string.split_once(locale, "-") {
    Ok(#(language, _)) -> language
    Error(_) -> locale
  }
}

fn english_category(count: Int) -> String {
  case count {
    1 -> "one"
    _ -> "other"
  }
}

fn east_slavic_category(count: Int) -> String {
  let n = int.absolute_value(count)
  let mod10 = n % 10
  let mod100 = n % 100
  case Nil {
    _ if mod10 == 1 && mod100 != 11 -> "one"
    _ if mod10 >= 2 && mod10 <= 4 && { mod100 < 12 || mod100 > 14 } -> "few"
    _ -> "many"
  }
}

// Locale resolution ----------------------------------------------------------

/// Resolve the active locale from a session override and the sender's Telegram
/// `language_code`, falling back to the catalog default.
pub fn resolve_locale(
  catalog catalog: Catalog,
  session session_locale: Option(String),
  update update_locale: Option(String),
) -> String {
  session_locale
  |> option.or(update_locale)
  |> option.unwrap(catalog.default)
}

/// Extract the sender's `language_code` from a raw update, if present.
pub fn user_language_code(raw: ModelUpdate) -> Option(String) {
  [
    option.then(raw.message, fn(m) { m.from }),
    option.then(raw.edited_message, fn(m) { m.from }),
    option.then(raw.business_message, fn(m) { m.from }),
    option.map(raw.callback_query, fn(c) { c.from }),
    option.map(raw.inline_query, fn(q) { q.from }),
    option.map(raw.chosen_inline_result, fn(r) { r.from }),
    option.map(raw.shipping_query, fn(q) { q.from }),
    option.map(raw.pre_checkout_query, fn(q) { q.from }),
    option.map(raw.my_chat_member, fn(m) { m.from }),
    option.map(raw.chat_member, fn(m) { m.from }),
    option.map(raw.chat_join_request, fn(r) { r.from }),
  ]
  |> first_user
  |> option.then(fn(user: User) { user.language_code })
}

fn first_user(candidates: List(Option(User))) -> Option(User) {
  candidates
  |> list.find_map(fn(candidate) { option.to_result(candidate, Nil) })
  |> option.from_result
}

// Process-dictionary state ---------------------------------------------------

type State {
  State(catalog: Catalog, locale: String)
}

/// Store the active catalog and locale for the current process. The
/// [`middleware`](#middleware) calls this before each handler; call it yourself
/// only if you resolve locales outside the router.
pub fn enter(catalog catalog: Catalog, locale locale: String) -> Nil {
  let _ = erlang_put(state_key(), to_dynamic(State(catalog:, locale:)))
  Nil
}

/// Clear the i18n state for the current process.
pub fn leave() -> Nil {
  let _ = erlang_erase(state_key())
  Nil
}

/// The locale active in the current process, if [`enter`](#enter) (or the
/// middleware) has run.
pub fn current_locale() -> Option(String) {
  case read_state() {
    Ok(State(locale:, ..)) -> Some(locale)
    Error(_) -> None
  }
}

fn read_state() -> Result(State, Nil) {
  let value = erlang_get(state_key())
  // `erlang:get/1` returns the atom `undefined` when the key is unset.
  case value == to_dynamic(atom.create("undefined")) {
    True -> Error(Nil)
    False -> Ok(from_dynamic(value))
  }
}

fn state_key() -> Atom {
  atom.create("telega_i18n_state")
}

// Handler-facing API ---------------------------------------------------------

/// Translate `key` for the locale active in the current handler, interpolating
/// `{placeholder}` values from `args`. Requires the [`middleware`](#middleware)
/// (or a manual [`enter`](#enter)); otherwise returns the key unchanged.
pub fn t(
  ctx _ctx: Context(session, error),
  key key: String,
  args args: List(#(String, String)),
) -> String {
  translate_current(key, args)
}

/// Pluralizing variant of [`t`](#t). See [`translate_count`](#translate_count).
pub fn tn(
  ctx _ctx: Context(session, error),
  key key: String,
  count count: Int,
  args args: List(#(String, String)),
) -> String {
  case read_state() {
    Ok(State(catalog:, locale:)) ->
      translate_count(catalog, locale, key, count, args)
    Error(_) -> key
  }
}

/// Translate using the active process locale without a context. [`t`](#t)
/// delegates here.
pub fn translate_current(
  key key: String,
  args args: List(#(String, String)),
) -> String {
  case read_state() {
    Ok(State(catalog:, locale:)) -> translate(catalog, locale, key, args)
    Error(_) -> key
  }
}

// Middleware -----------------------------------------------------------------

/// Router middleware that resolves the active locale for every update and makes
/// it available to [`t`](#t)/[`tn`](#tn).
///
/// `from` reads an optional per-user override out of the session (e.g. a
/// language the user chose in settings); return `None` to fall back to the
/// sender's Telegram `language_code` and then the catalog default.
pub fn middleware(
  catalog catalog: Catalog,
  from from: fn(session) -> Option(String),
) -> Middleware(session, error) {
  fn(handler) {
    fn(ctx: Context(session, error), update: Update) {
      let session_locale = from(ctx.session)
      let update_locale = user_language_code(update.raw(ctx.update))
      let locale = resolve_locale(catalog, session_locale, update_locale)
      enter(catalog:, locale:)
      handler(ctx, update)
    }
  }
}

// Flattening helpers ---------------------------------------------------------

fn flatten_toml(
  prefix: String,
  table: Dict(String, tom.Toml),
  acc: List(#(String, String)),
) -> List(#(String, String)) {
  dict.fold(table, acc, fn(acc, key, value) {
    let path = join_key(prefix, key)
    case tom.as_table(value) {
      Ok(sub) -> flatten_toml(path, sub, acc)
      Error(_) ->
        case toml_leaf(value) {
          Ok(text) -> [#(path, text), ..acc]
          Error(_) -> acc
        }
    }
  })
}

fn toml_leaf(value: tom.Toml) -> Result(String, Nil) {
  case tom.as_string(value) {
    Ok(text) -> Ok(text)
    Error(_) ->
      case tom.as_int(value) {
        Ok(i) -> Ok(int.to_string(i))
        Error(_) ->
          case tom.as_float(value) {
            Ok(f) -> Ok(float.to_string(f))
            Error(_) ->
              case tom.as_bool(value) {
                Ok(b) -> Ok(bool_to_string(b))
                Error(_) -> Error(Nil)
              }
          }
      }
  }
}

fn flatten_dynamic(
  prefix: String,
  value: Dynamic,
  acc: List(#(String, String)),
) -> List(#(String, String)) {
  case decode.run(value, decode.string) {
    Ok(text) -> [#(prefix, text), ..acc]
    Error(_) ->
      case decode.run(value, decode.dict(decode.string, decode.dynamic)) {
        Ok(sub) ->
          dict.fold(sub, acc, fn(acc, key, value) {
            flatten_dynamic(join_key(prefix, key), value, acc)
          })
        Error(_) ->
          case decode.run(value, decode.int) {
            Ok(i) -> [#(prefix, int.to_string(i)), ..acc]
            Error(_) ->
              case decode.run(value, decode.float) {
                Ok(f) -> [#(prefix, float.to_string(f)), ..acc]
                Error(_) ->
                  case decode.run(value, decode.bool) {
                    Ok(b) -> [#(prefix, bool_to_string(b)), ..acc]
                    Error(_) -> acc
                  }
              }
          }
      }
  }
}

fn join_key(prefix: String, key: String) -> String {
  case prefix {
    "" -> key
    _ -> prefix <> "." <> key
  }
}

fn bool_to_string(value: Bool) -> String {
  case value {
    True -> "true"
    False -> "false"
  }
}

// FFI ------------------------------------------------------------------------

@external(erlang, "erlang", "put")
fn erlang_put(key: Atom, value: Dynamic) -> Dynamic

@external(erlang, "erlang", "get")
fn erlang_get(key: Atom) -> Dynamic

@external(erlang, "erlang", "erase")
fn erlang_erase(key: Atom) -> Dynamic

@external(erlang, "gleam_stdlib", "identity")
fn to_dynamic(value: a) -> Dynamic

@external(erlang, "gleam_stdlib", "identity")
fn from_dynamic(value: Dynamic) -> a
