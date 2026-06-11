//// Telega model-layer code generator.
////
//// Reads the machine-readable Telegram Bot API spec
//// (github.com/PaulSonOfLars/telegram-bot-api-spec, `api.json`) and regenerates
//// the *generated prefix* of the three model modules:
////
////   - ../src/telega/model/types.gleam   — type definitions
////   - ../src/telega/model/decoder.gleam — JSON decoders
////   - ../src/telega/model/encoder.gleam — JSON encoders
////
//// Each target file keeps a hand-written *manual suffix* below the
//// `manual_marker` line; the generator preserves everything from that marker to
//// EOF verbatim. Run via `task codegen` from the repo root.

import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regexp
import gleam/result
import gleam/set.{type Set}
import gleam/string
import justin
import simplifile

const spec_file = "./api.json"

const types_file = "../src/telega/model/types.gleam"

const decoder_file = "../src/telega/model/decoder.gleam"

const encoder_file = "../src/telega/model/encoder.gleam"

/// Everything from this line to EOF in each target file is hand-written and
/// preserved across regenerations.
const manual_marker = "// === MANUAL — not regenerated below (codegen) ==="

// --- Spec types not represented as a real Gleam struct ----------------------

/// Telegram types that must not be generated as records.
const skip_types = ["InputFile"]

/// Unions the library intentionally maintains by hand (kept in the manual
/// suffix) because the repo's variant set diverges from the canonical spec.
/// `InputMedia` carries Location/Sticker/Venue variants the library relies on,
/// which the spec assigns to InputPollMedia / InputPollOptionMedia instead.
const manual_unions = ["InputMedia"]

// --- Internal model ---------------------------------------------------------

pub type Field {
  Field(name: String, type_: List(String), description: String, optional: Bool)
}

pub type Model {
  Model(name: String, fields: List(Field), description: String)
}

/// A discriminated union variant: the wrapped type and the discriminator value
/// Telegram sends for it (e.g. `ChatMemberOwner` / `"creator"`).
pub type Variant {
  Variant(type_name: String, value: String)
}

pub type Union {
  Union(name: String, subtypes: List(String), description: String)
}

/// A union for which a discriminated decoder can be generated.
pub type DecodableUnion {
  DecodableUnion(name: String, discriminator: String, variants: List(Variant))
}

// --- Raw spec decoding (PaulSonOfLars schema) -------------------------------

type RawField {
  RawField(
    name: String,
    types: List(String),
    required: Bool,
    description: String,
  )
}

type RawType {
  RawType(
    name: String,
    description: String,
    fields: Option(List(RawField)),
    subtypes: Option(List(String)),
  )
}

fn raw_field_decoder() -> decode.Decoder(RawField) {
  use name <- decode.field("name", decode.string)
  use types <- decode.field("types", decode.list(decode.string))
  use required <- decode.field("required", decode.bool)
  use description <- decode.optional_field("description", "", decode.string)
  decode.success(RawField(name:, types:, required:, description:))
}

fn raw_type_decoder() -> decode.Decoder(RawType) {
  use name <- decode.field("name", decode.string)
  use description <- decode.optional_field(
    "description",
    [],
    decode.list(decode.string),
  )
  use fields <- decode.optional_field(
    "fields",
    None,
    decode.optional(decode.list(raw_field_decoder())),
  )
  use subtypes <- decode.optional_field(
    "subtypes",
    None,
    decode.optional(decode.list(decode.string)),
  )
  decode.success(RawType(
    name:,
    description: string.join(description, " "),
    fields:,
    subtypes:,
  ))
}

type Spec {
  Spec(version: String, types: Dict(String, RawType))
}

fn spec_decoder() -> decode.Decoder(Spec) {
  use version <- decode.field("version", decode.string)
  use types <- decode.field(
    "types",
    decode.dict(decode.string, raw_type_decoder()),
  )
  decode.success(Spec(version:, types:))
}

// --- Transform raw spec -> internal model -----------------------------------

/// Normalize a single Telegram type string into the intermediate token list the
/// code generators understand (e.g. "Integer" -> ["int"],
/// "Array of PhotoSize" -> ["array", "PhotoSize"]).
fn normalize_single(s: String) -> List(String) {
  case s {
    "Integer" -> ["int"]
    "String" -> ["str"]
    "Boolean" -> ["bool"]
    "Float" -> ["float"]
    "Float number" -> ["float"]
    "True" -> ["true"]
    "Array of " <> rest ->
      case rest {
        "Array of " <> inner -> ["array", "List(" <> inner <> ")"]
        _ -> ["array", array_inner(rest)]
      }
    other -> [other]
  }
}

fn array_inner(s: String) -> String {
  case s {
    "Integer" -> "int"
    "String" -> "string"
    "Boolean" -> "bool"
    "Float" -> "float"
    "True" -> "true"
    other -> other
  }
}

fn normalize_types(types: List(String)) -> List(String) {
  case types {
    [single] -> normalize_single(single)
    multiple ->
      case set.from_list(multiple) == set.from_list(["Integer", "String"]) {
        True -> ["int", "str"]
        // Fallback: collapse to the first type. Only Integer|String occurs in
        // generated models today; anything else is a manual method parameter.
        False ->
          case multiple {
            [first, ..] -> normalize_single(first)
            [] -> ["str"]
          }
      }
  }
}

fn raw_field_to_field(rf: RawField) -> Field {
  Field(
    name: rf.name,
    type_: normalize_types(rf.types),
    description: rf.description,
    optional: !rf.required,
  )
}

fn raw_to_model(rt: RawType) -> Model {
  let fields =
    rt.fields
    |> option.unwrap([])
    |> list.map(raw_field_to_field)
  Model(name: rt.name, fields:, description: rt.description)
}

/// Extract the discriminator constant Telegram embeds in a subtype field
/// description, e.g. `... always "creator"` -> `#("status", "creator")`.
fn extract_discriminator(
  rt: RawType,
  re: regexp.Regexp,
) -> Option(#(String, String)) {
  rt.fields
  |> option.unwrap([])
  |> list.filter_map(fn(f) {
    case regexp.scan(re, f.description) {
      [regexp.Match(submatches: [Some(value), ..], ..), ..] ->
        Ok(#(f.name, value))
      _ -> Error(Nil)
    }
  })
  |> list.first
  |> option.from_result
}

/// A union is decodable if every subtype yields the same discriminator field
/// with a unique, non-empty value.
fn try_decodable_union(
  union: Union,
  types: Dict(String, RawType),
  re: regexp.Regexp,
) -> Option(DecodableUnion) {
  let extracted =
    list.map(union.subtypes, fn(sub) {
      case dict.get(types, sub) {
        Ok(rt) -> #(sub, extract_discriminator(rt, re))
        Error(_) -> #(sub, None)
      }
    })

  let all_present = list.all(extracted, fn(e) { e.1 != None })
  let fields =
    extracted
    |> list.filter_map(fn(e) {
      case e.1 {
        Some(#(field, _)) -> Ok(field)
        None -> Error(Nil)
      }
    })
    |> set.from_list
  let values =
    extracted
    |> list.filter_map(fn(e) {
      case e.1 {
        Some(#(_, value)) -> Ok(value)
        None -> Error(Nil)
      }
    })
  let unique_values = set.size(set.from_list(values)) == list.length(values)

  case all_present && set.size(fields) == 1 && unique_values {
    True -> {
      let assert [discriminator] = set.to_list(fields)
      let variants =
        list.filter_map(extracted, fn(e) {
          case e.1 {
            Some(#(_, value)) -> Ok(Variant(type_name: e.0, value:))
            None -> Error(Nil)
          }
        })
      Some(DecodableUnion(name: union.name, discriminator:, variants:))
    }
    False -> None
  }
}

// --- Shared name/type helpers -----------------------------------------------

fn map_type(type_: String) -> String {
  case type_ {
    "int" -> "Int"
    "float" -> "Float"
    "string" -> "String"
    "str" -> "String"
    "boolean" -> "Bool"
    "bool" -> "Bool"
    "true" -> "Bool"
    "file" -> "File"
    other -> other
  }
}

fn type_to_gleam(type_: List(String)) -> String {
  case type_ {
    ["int"] -> "Int"
    ["float"] -> "Float"
    ["string"] -> "String"
    ["str"] -> "String"
    ["boolean"] -> "Bool"
    ["bool"] -> "Bool"
    ["true"] -> "Bool"
    [single] -> single
    ["array", single] -> "List(" <> map_type(single) <> ")"
    multiple -> list.map(multiple, map_type) |> string.join("Or")
  }
}

fn map_field_name(name: String) -> String {
  case name {
    "type" -> "type_"
    other -> other
  }
}

fn add_doc_block_on_new_line(str: String) -> String {
  case string.split(str, "\n") {
    [first] -> first
    [first, ..rest] ->
      first
      <> "\n"
      <> { list.map(rest, fn(line) { "/// " <> line }) |> string.join("\n") }
    [] -> ""
  }
}

// --- Type generation --------------------------------------------------------

fn generate_model_type(model: Model) -> String {
  let type_doc = case model.description {
    "" -> ""
    desc ->
      "/// **Official reference:** " <> add_doc_block_on_new_line(desc) <> "\n"
  }

  case model.fields {
    [] ->
      type_doc <> "pub type " <> model.name <> " {\n  " <> model.name <> "\n}\n"
    fields -> {
      let params =
        list.map(fields, fn(field) {
          let base = type_to_gleam(field.type_)
          let typed = case field.optional {
            True -> "Option(" <> base <> ")"
            False -> base
          }
          let comment = "/// " <> add_doc_block_on_new_line(field.description)
          comment <> "\n" <> map_field_name(field.name) <> ": " <> typed
        })
      type_doc
      <> "pub type "
      <> model.name
      <> " {\n  "
      <> model.name
      <> "(\n"
      <> string.join(params, ",\n")
      <> ",\n  )\n}\n"
    }
  }
}

fn generate_union_type(union: Union) -> String {
  let subtypes =
    list.map(union.subtypes, fn(sub) {
      "  " <> sub <> union.name <> "(" <> sub <> ")"
    })
  "pub type " <> union.name <> " {\n" <> string.join(subtypes, "\n") <> "\n}\n"
}

// --- Decoder generation -----------------------------------------------------

fn base_decoder(type_: List(String)) -> String {
  case type_ {
    ["int"] -> "decode.int"
    ["float"] -> "decode.float"
    ["str"] -> "decode.string"
    ["string"] -> "decode.string"
    ["boolean"] -> "decode.bool"
    ["bool"] -> "decode.bool"
    ["true"] -> "decode.bool"
    ["int", "str"] -> "int_or_string_decoder()"
    ["file", "str"] -> "file_or_string_decoder()"
    [type_name] -> justin.snake_case(type_name) <> "_decoder()"
    ["array", "int"] -> "decode.list(decode.int)"
    ["array", "float"] -> "decode.list(decode.float)"
    ["array", "string"] -> "decode.list(decode.string)"
    ["array", "bool"] -> "decode.list(decode.bool)"
    ["array", "true"] -> "decode.list(decode.bool)"
    ["array", "List(" <> inner] -> {
      let decoder =
        inner
        |> justin.snake_case
        |> string.replace("(", "")
        |> string.replace(")", "")
      "decode.list(decode.list(" <> decoder <> "_decoder()))"
    }
    ["array", type_name] ->
      "decode.list(" <> justin.snake_case(type_name) <> "_decoder())"
    unknown -> panic as { "Unknown decoder type: " <> string.inspect(unknown) }
  }
}

fn generate_model_decoder(model: Model) -> String {
  let fn_name = justin.snake_case(model.name) <> "_decoder"
  let signature =
    "pub fn " <> fn_name <> "() -> decode.Decoder(" <> model.name <> ") {\n"

  case model.fields {
    [] -> signature <> "  decode.success(" <> model.name <> ")\n}\n"
    fields -> {
      let lines =
        list.map(fields, fn(field) {
          let var = map_field_name(field.name)
          let dec = base_decoder(field.type_)
          case field.optional {
            False ->
              "  use "
              <> var
              <> " <- decode.field(\""
              <> field.name
              <> "\", "
              <> dec
              <> ")"
            True ->
              "  use "
              <> var
              <> " <- decode.optional_field(\""
              <> field.name
              <> "\", None, decode.optional("
              <> dec
              <> "))"
          }
        })
      let assigns =
        list.map(fields, fn(field) {
          let var = map_field_name(field.name)
          "    " <> var <> ": " <> var
        })
      signature
      <> string.join(lines, "\n")
      <> "\n  decode.success("
      <> model.name
      <> "(\n"
      <> string.join(assigns, ",\n")
      <> ",\n  ))\n}\n"
    }
  }
}

fn generate_union_decoder(union: DecodableUnion) -> String {
  let fn_name = justin.snake_case(union.name) <> "_decoder"
  let signature =
    "pub fn " <> fn_name <> "() -> decode.Decoder(" <> union.name <> ") {\n"
  let variant_field =
    "  use variant <- decode.field(\""
    <> union.discriminator
    <> "\", decode.string)\n"

  let cases =
    list.map(union.variants, fn(variant) {
      "    \""
      <> variant.value
      <> "\" -> {\n      use value <- decode.then("
      <> justin.snake_case(variant.type_name)
      <> "_decoder())\n      decode.success("
      <> variant.type_name
      <> union.name
      <> "(value))\n    }"
    })

  signature
  <> variant_field
  <> "  case variant {\n"
  <> string.join(cases, "\n")
  <> "\n    _ -> panic as \"Invalid variant for "
  <> union.name
  <> "\"\n  }\n}\n"
}

// --- Encoder generation -----------------------------------------------------

fn base_encoder(type_: List(String)) -> String {
  case type_ {
    ["int"] -> "json.int"
    ["float"] -> "json.float"
    ["string"] -> "json.string"
    ["str"] -> "json.string"
    ["boolean"] -> "json.bool"
    ["bool"] -> "json.bool"
    ["true"] -> "json.bool"
    ["int", "str"] -> "encode_int_or_string"
    ["file", "str"] -> "encode_file_or_string"
    ["array", inner] ->
      case inner {
        "int" -> "json.array(_, json.int)"
        "float" -> "json.array(_, json.float)"
        "string" -> "json.array(_, json.string)"
        "str" -> "json.array(_, json.string)"
        "bool" -> "json.array(_, json.bool)"
        "boolean" -> "json.array(_, json.bool)"
        "true" -> "json.array(_, json.bool)"
        "List(" <> rest -> {
          let inner_type = rest |> string.replace(")", "") |> justin.snake_case
          "fn(rows) { json.array(rows, fn(row) { json.array(row, encode_"
          <> inner_type
          <> ") }) }"
        }
        other -> "json.array(_, encode_" <> justin.snake_case(other) <> ")"
      }
    [single] -> "encode_" <> justin.snake_case(single)
    multiple ->
      "encode_"
      <> { list.map(multiple, justin.snake_case) |> string.join("_or_") }
  }
}

fn generate_model_encoder(model: Model) -> String {
  let fn_name = "encode_" <> justin.snake_case(model.name)
  let param_name = justin.snake_case(model.name)
  let signature =
    "pub fn "
    <> fn_name
    <> "("
    <> case model.fields {
      [] -> "_" <> param_name
      _ -> param_name
    }
    <> ": "
    <> model.name
    <> ") -> Json {\n"

  case model.fields {
    [] -> signature <> "  json_object_filter_nulls([])\n}\n"
    fields -> {
      let entries =
        list.map(fields, fn(field) {
          let access = param_name <> "." <> map_field_name(field.name)
          let enc = base_encoder(field.type_)
          let value = case field.optional {
            True -> "json.nullable(" <> access <> ", " <> enc <> ")"
            False -> enc <> "(" <> access <> ")"
          }
          "    #(\"" <> field.name <> "\", " <> value <> ")"
        })
      signature
      <> "  json_object_filter_nulls([\n"
      <> string.join(entries, ",\n")
      <> ",\n  ])\n}\n"
    }
  }
}

fn generate_union_encoder(union: Union) -> String {
  let fn_name = "encode_" <> justin.snake_case(union.name)
  let signature =
    "pub fn " <> fn_name <> "(value: " <> union.name <> ") -> Json {\n"
  let cases =
    list.map(union.subtypes, fn(sub) {
      "    "
      <> sub
      <> union.name
      <> "(inner_value) -> encode_"
      <> justin.snake_case(sub)
      <> "(inner_value)"
    })
  signature <> "  case value {\n" <> string.join(cases, "\n") <> "\n  }\n}\n"
}

// --- Import-list computation ------------------------------------------------

/// Whole-word identifiers occurring in `body`.
fn word_set(body: String) -> Set(String) {
  let assert Ok(re) = regexp.from_string("[A-Za-z_][A-Za-z0-9_]*")
  regexp.scan(re, body)
  |> list.map(fn(m) { m.content })
  |> set.from_list
}

fn captures(body: String, pattern: String) -> Set(String) {
  let assert Ok(re) = regexp.from_string(pattern)
  regexp.scan(re, body)
  |> list.filter_map(fn(m) {
    case m.submatches {
      [Some(name), ..] -> Ok(name)
      _ -> Error(Nil)
    }
  })
  |> set.from_list
}

/// Capitalised identifiers applied as `Name(` in `body` — i.e. constructor
/// applications and patterns for types that carry fields.
fn applied_ctor_set(body: String) -> Set(String) {
  captures(body, "([A-Z][A-Za-z0-9_]*)\\(")
}

/// No-arg constructor usages: `(Name)` (e.g. `decode.success(CallbackGame)`)
/// and case-pattern arms `Name ->`. Avoids matching bare type annotations.
fn noarg_use_set(body: String) -> Set(String) {
  set.union(
    captures(body, "\\(([A-Z][A-Za-z0-9_]*)\\)"),
    captures(body, "([A-Z][A-Za-z0-9_]*) ->"),
  )
}

/// Names of every `pub type X` declared in the given source text. Used to learn
/// the hand-written types defined in the manual suffixes.
fn declared_type_names(text: String) -> List(String) {
  let assert Ok(re) = regexp.from_string("pub type ([A-Z][A-Za-z0-9_]*)")
  regexp.scan(re, text)
  |> list.filter_map(fn(m) {
    case m.submatches {
      [Some(name), ..] -> Ok(name)
      _ -> Error(Nil)
    }
  })
}

/// Constructors declared inside `pub type X { ... }` blocks, tagged with
/// whether they carry fields. No-arg constructors (`Typing`) must be matched as
/// bare words; field constructors (`Int(value: Int)`) as `Name(`.
fn declared_constructors(text: String) -> List(#(String, Bool)) {
  text
  |> string.split("\n")
  |> list.fold(#(False, []), fn(state, line) {
    let #(in_type, acc) = state
    let trimmed = string.trim(line)
    case in_type {
      False ->
        case
          string.starts_with(line, "pub type ")
          && string.ends_with(trimmed, "{")
        {
          True -> #(True, acc)
          False -> #(False, acc)
        }
      True ->
        case trimmed == "}" {
          True -> #(False, acc)
          False ->
            case leading_constructor(trimmed) {
              Some(name) -> #(True, [
                #(name, string.contains(trimmed, "(")),
                ..acc
              ])
              None -> #(True, acc)
            }
        }
    }
  })
  |> fn(state) { state.1 }
}

/// The leading constructor name on a type-body line, if it starts with an
/// uppercase identifier.
fn leading_constructor(trimmed: String) -> Option(String) {
  case regexp.from_string("^([A-Z][A-Za-z0-9_]*)") {
    Ok(re) ->
      case regexp.scan(re, trimmed) {
        [regexp.Match(submatches: [Some(name), ..], ..), ..] -> Some(name)
        _ -> None
      }
    Error(_) -> None
  }
}

fn module_import(type_names: List(String), ctor_names: List(String)) -> String {
  let entries =
    list.append(list.map(type_names, fn(n) { "type " <> n }), ctor_names)
  case entries {
    [] -> ""
    _ ->
      "import telega/model/types.{\n"
      <> { list.map(entries, fn(e) { "  " <> e }) |> string.join(",\n") }
      <> ",\n}\n"
  }
}

/// Build the `telega/model/types` import for a generated module by scanning its
/// full body (generated + manual suffix) for referenced types and constructors.
fn types_import_for(
  body: String,
  all_types: Set(String),
  arg_ctors: Set(String),
  noarg_ctors: Set(String),
) -> String {
  let words = word_set(body)
  let apps = applied_ctor_set(body)
  let noarg_uses = noarg_use_set(body)
  let used_types =
    set.intersection(words, all_types)
    |> set.to_list
    |> list.sort(string.compare)
  let used_ctors =
    set.union(
      set.intersection(apps, arg_ctors),
      set.intersection(noarg_uses, noarg_ctors),
    )
    |> set.to_list
    |> list.sort(string.compare)
  module_import(used_types, used_ctors)
}

// --- Manual suffix ----------------------------------------------------------

fn read_manual_suffix(path: String) -> Result(String, String) {
  use content <- result.try(
    simplifile.read(path)
    |> result.replace_error("cannot read " <> path),
  )
  case string.split_once(content, manual_marker) {
    Ok(#(_, suffix)) -> Ok(manual_marker <> suffix)
    Error(_) ->
      Error(
        "manual marker not found in "
        <> path
        <> " — add the line `"
        <> manual_marker
        <> "` before the hand-written section.",
      )
  }
}

// --- File assembly ----------------------------------------------------------

const types_header = "//// This module contains all types from [Telegram Bot API](https://core.telegram.org/bots/api).
////
//// Most of types named in the same way as in the official documentation.
//// But some types are renamed to more verbose names for using from Gleam code (ex. `type` -> `type_`).

import gleam/option.{type Option, None}

"

const decoder_header = "//// This module contains all decoders for types [Telegram Bot API](https://core.telegram.org/bots/api).

import gleam/dynamic/decode
import gleam/option.{None}

"

const encoder_header = "//// This module contains all encoders for types [Telegram Bot API](https://core.telegram.org/bots/api).

import gleam/int
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None, Some}
import telega/internal/utils.{json_object_filter_nulls}

"

fn banner(version: String) -> String {
  "// This file is auto-generated for "
  <> version
  <> " from the Telegram Bot API spec.\n"
  <> "// Do not edit above the MANUAL marker — run `task codegen` to regenerate.\n\n"
}

fn write_file(path: String, content: String) -> Result(Nil, String) {
  simplifile.write(path, content)
  |> result.replace_error("failed to write " <> path)
}

// --- Main -------------------------------------------------------------------

pub fn main() {
  case run() {
    Ok(msg) -> io.println(msg)
    Error(err) -> {
      io.println_error("codegen failed: " <> err)
      panic as err
    }
  }
}

fn run() -> Result(String, String) {
  use content <- result.try(
    simplifile.read(spec_file)
    |> result.replace_error("cannot read " <> spec_file),
  )
  use spec <- result.try(
    json.parse(content, spec_decoder())
    |> result.replace_error("failed to parse " <> spec_file),
  )

  let skip = set.from_list(skip_types)
  let raw_types =
    spec.types
    |> dict.values
    |> list.filter(fn(rt) { !set.contains(skip, rt.name) })
    |> list.sort(fn(a, b) { string.compare(a.name, b.name) })

  let manual_union_set = set.from_list(manual_unions)
  let unions =
    list.filter_map(raw_types, fn(rt) {
      case rt.subtypes {
        Some(subs) ->
          case set.contains(manual_union_set, rt.name) {
            True -> Error(Nil)
            False ->
              Ok(Union(
                name: rt.name,
                subtypes: subs,
                description: rt.description,
              ))
          }
        None -> Error(Nil)
      }
    })
  let models =
    raw_types
    |> list.filter(fn(rt) { rt.subtypes == None })
    |> list.map(raw_to_model)

  let assert Ok(disc_re) =
    regexp.from_string("(?:always|must be)\\s+[\"“]?([a-z0-9_]+)")
  let decodable_unions =
    list.filter_map(unions, fn(u) {
      case try_decodable_union(u, spec.types, disc_re) {
        Some(du) -> Ok(du)
        None -> Error(Nil)
      }
    })

  // Read all manual suffixes up front so a missing marker aborts before any
  // file is overwritten.
  use types_suffix <- result.try(read_manual_suffix(types_file))
  use decoder_suffix <- result.try(read_manual_suffix(decoder_file))
  use encoder_suffix <- result.try(read_manual_suffix(encoder_file))

  // All type names that can appear in decoder/encoder import lists: every spec
  // type plus the hand-written types declared in the manual suffixes (method
  // parameter types, IntOrString/FileOrString, ...).
  let manual_type_names =
    [types_suffix, decoder_suffix, encoder_suffix]
    |> string.join("\n")
    |> declared_type_names
  let all_names =
    raw_types
    |> list.map(fn(rt) { rt.name })
    |> list.append(manual_type_names)
    |> set.from_list

  // Value constructors that decoder/encoder may reference, classified by
  // whether they carry fields (matched as `Name(`) or are no-arg (bare word).
  let union_variant_ctors =
    list.flat_map(unions, fn(u) {
      list.map(u.subtypes, fn(sub) { sub <> u.name })
    })
  let #(empty_model_names, field_model_names) =
    list.partition(models, fn(m) { m.fields == [] })
  let suffix_ctors =
    [types_suffix, decoder_suffix, encoder_suffix]
    |> string.join("\n")
    |> declared_constructors
  let #(suffix_arg, suffix_noarg) = list.partition(suffix_ctors, fn(c) { c.1 })
  let arg_ctors =
    union_variant_ctors
    |> list.append(list.map(field_model_names, fn(m) { m.name }))
    |> list.append(list.map(suffix_arg, fn(c) { c.0 }))
    |> set.from_list
  let noarg_ctors =
    empty_model_names
    |> list.map(fn(m) { m.name })
    |> list.append(list.map(suffix_noarg, fn(c) { c.0 }))
    |> set.from_list

  // --- types.gleam: generated unions + models, then manual suffix ---
  let union_types = list.map(unions, generate_union_type)
  let model_types = list.map(models, generate_model_type)
  let types_body =
    string.join(union_types, "\n")
    <> "\n"
    <> string.join(model_types, "\n")
    <> "\n"
    <> types_suffix
  let types_content = types_header <> banner(spec.version) <> types_body
  use _ <- result.try(write_file(types_file, types_content))

  // --- decoder.gleam: model + clean-union decoders, then manual suffix ---
  let model_decoders = list.map(models, generate_model_decoder)
  let union_decoders = list.map(decodable_unions, generate_union_decoder)
  let decoder_body =
    string.join(model_decoders, "\n")
    <> "\n"
    <> string.join(union_decoders, "\n")
    <> "\n"
    <> decoder_suffix
  let decoder_imports =
    types_import_for(decoder_body, all_names, arg_ctors, noarg_ctors)
  let decoder_content =
    decoder_header <> decoder_imports <> banner(spec.version) <> decoder_body
  use _ <- result.try(write_file(decoder_file, decoder_content))

  // --- encoder.gleam: model + all-union encoders, then manual suffix ---
  let model_encoders = list.map(models, generate_model_encoder)
  let union_encoders = list.map(unions, generate_union_encoder)
  let encoder_body =
    string.join(model_encoders, "\n")
    <> "\n"
    <> string.join(union_encoders, "\n")
    <> "\n"
    <> encoder_suffix
  let encoder_imports =
    types_import_for(encoder_body, all_names, arg_ctors, noarg_ctors)
  let encoder_content =
    encoder_header <> encoder_imports <> banner(spec.version) <> encoder_body
  use _ <- result.try(write_file(encoder_file, encoder_content))

  Ok(
    "Generated model layer for "
    <> spec.version
    <> ": "
    <> int_to_string(list.length(models))
    <> " models, "
    <> int_to_string(list.length(unions))
    <> " unions ("
    <> int_to_string(list.length(decodable_unions))
    <> " decodable).",
  )
}

fn int_to_string(n: Int) -> String {
  string.inspect(n)
}
