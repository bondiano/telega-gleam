import gleam/dynamic
import gleam/dynamic/decode
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import justin
import simplifile

const scrapped_file = "./tg_api.generated.json"

const output_file = "../../src/telega/model.gleam"

pub type GenericType {
  GenericType(name: String, subtypes: List(String))
}

pub type Param {
  Param(name: String, type_: List(String), description: String, optional: Bool)
}

pub type Model {
  Model(name: String, params: List(Param), description: Option(String))
}

pub type Method {
  Method(
    name: String,
    params: List(Param),
    returns: List(String),
    description: Option(String),
  )
}

pub type ApiDefinition {
  ApiDefinition(
    generics: List(GenericType),
    models: List(Model),
    methods: List(Method),
  )
}

fn decode_generic_type() {
  use name <- decode.field("name", decode.string)
  use subtypes <- decode.field("subtypes", decode.list(decode.string))
  decode.success(GenericType(name: name, subtypes: subtypes))
}

fn decode_param() {
  use name <- decode.field("name", decode.string)
  use type_list <- decode.field(
    "type",
    decode.list(
      decode.one_of(decode.string, or: [
        // Decode ["array", ["str"]]
        decode.list(
          decode.one_of(decode.string, or: [
            decode.list(decode.string) |> decode.map(string.join(_, ",")),
          ]),
        )
        |> decode.map(fn(nested) {
          case nested {
            ["array", single] -> "List(" <> single <> ")"
            _ -> string.join(nested, ",")
          }
        }),
      ]),
    ),
  )

  use description <- decode.field("description", decode.string)
  use optional <- decode.field("optional", decode.bool)
  decode.success(Param(
    name: name,
    type_: type_list,
    description: description,
    optional: optional,
  ))
}

fn decode_model() {
  use name <- decode.field("name", decode.string)
  use params <- decode.field("params", decode.list(decode_param()))
  use description <- decode.field("description", decode.optional(decode.string))

  decode.success(Model(name: name, params: params, description: description))
}

fn decode_method() {
  use name <- decode.field("name", decode.string)
  use params <- decode.field("params", decode.list(decode_param()))
  use returns <- decode.field(
    "return",
    decode.one_of(decode.list(decode.string), or: [
      decode.string |> decode.map(fn(single) { [single] }),
      decode.list(decode.list(decode.string))
        |> decode.map(fn(nested) {
          case nested {
            [["array", single]] -> [single]
            [] -> ["List(String)"]
            _ -> []
          }
        }),
    ]),
  )

  use description <- decode.field("description", decode.optional(decode.string))

  decode.success(Method(
    name: name,
    params: params,
    returns: returns,
    description: description,
  ))
}

fn decode_api_definition() {
  use generics <- decode.field("generics", decode.list(decode_generic_type()))
  use models <- decode.field("models", decode.list(decode_model()))
  use methods <- decode.field("methods", decode.list(decode_method()))

  decode.success(ApiDefinition(
    generics: generics,
    models: models,
    methods: methods,
  ))
}

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
    [single] -> {
      case string.starts_with(single, "List(") {
        True -> single
        False -> single
      }
    }
    ["array", single] -> "List(" <> map_type(single) <> ")"
    _ -> {
      let types = list.map(type_, map_type)
      string.join(types, "Or")
    }
  }
}

fn add_doc_block_on_new_line(str: String) -> String {
  let lines = string.split(str, "\n")

  case lines {
    [first] -> first
    [first, ..rest] ->
      first
      <> "\n"
      <> list.map(rest, fn(line) { "/// " <> line }) |> string.join("\n")
    [] -> ""
  }
}

fn map_param_name(name: String) -> String {
  case name {
    "type" -> "type_"
    other -> other
  }
}

fn generate_model_type(model: Model) -> String {
  let type_doc = case model.description {
    Some(desc) ->
      "/// **Official reference:** " <> add_doc_block_on_new_line(desc) <> "\n"
    None -> ""
  }

  let params =
    list.map(model.params, fn(param) {
      let param_type = type_to_gleam(param.type_)
      let type_with_option = case param.optional {
        True -> "Option(" <> param_type <> ")"
        False -> param_type
      }

      let comment = "    /// " <> add_doc_block_on_new_line(param.description)
      let name = map_param_name(param.name)
      comment <> "\n    " <> name <> ": " <> type_with_option
    })

  case params {
    [] -> "pub type " <> model.name <> " {\n  " <> model.name <> "()\n}\n"
    _ -> {
      let params_str = string.join(params, ",\n")

      type_doc
      <> "pub type "
      <> model.name
      <> " {\n  "
      <> model.name
      <> "(\n"
      <> params_str
      <> ",\n  )\n}\n"
    }
  }
}

fn generate_model_decoder(model: Model) -> String {
  let fn_name = justin.snake_case(model.name) <> "_decoder"

  // Generate decoder function signature
  let signature =
    "pub fn " <> fn_name <> "() -> decode.Decoder(" <> model.name <> ") {\n"

  // Generate field decoders for each parameter
  let fields =
    list.map(model.params, fn(param) {
      let field_name = param.name

      // Choose the right decoder based on the parameter type
      let decoder = case param.type_ {
        ["int"] -> "decode.int"
        ["float"] -> "decode.float"
        ["double"] -> "decode.float"
        ["str"] -> "decode.string"
        ["boolean"] -> "decode.bool"
        ["bool"] -> "decode.bool"
        ["true"] -> "decode.bool"
        [type_name] -> justin.snake_case(type_name) <> "_decoder()"
        ["int", "str"] -> "int_or_string_decoder()"
        ["file", "str"] -> "file_or_string_decoder()"
        ["array", "int"] -> "decode.list(decode.int)"
        ["array", "float"] -> "decode.list(decode.float)"
        ["array", "string"] -> "decode.list(decode.string)"
        ["array", "bool"] -> "decode.list(decode.bool)"
        ["array", "true"] -> "decode.list(decode.bool)"
        ["array", "List(" <> type_name] ->
          "decode.list(decode.list("
          <> case type_name {
            "str" -> "decode.string"
            s -> s
          }
          |> justin.snake_case()
          |> string.replace("(", "")
          |> string.replace(")", "")
          <> "_decoder()))"
        ["array", type_name] ->
          "decode.list("
          <> case justin.snake_case(type_name) {
            "str" -> "decode.string"
            s -> s <> "_decoder()"
          }
          <> ")"
        unknown ->
          panic as { "Unknown type: " <> { unknown |> string.inspect } }
      }
      let decoder = case param.optional {
        True -> "decode.optional(" <> decoder <> ")"
        False -> decoder
      }

      "    use "
      <> map_param_name(field_name)
      <> " <- decode.field(\""
      <> map_param_name(field_name)
      <> "\", "
      <> decoder
      <> ")"
    })

  let fields_str = string.join(fields, "\n")

  let constructor =
    "    decode.success("
    <> model.name
    <> case model.params {
      [] -> ""
      _ -> "(\n"
    }

  let field_assignments = case model.params {
    [] -> ""
    _ ->
      list.map(model.params, fn(param) {
        "      "
        <> map_param_name(param.name)
        <> ": "
        <> map_param_name(param.name)
      })
      |> string.join(",\n")
  }

  // Close the constructor
  let closing = case model.params {
    [] -> ")\n}\n"
    _ -> "))\n}\n"
  }

  signature <> fields_str <> "\n" <> constructor <> field_assignments <> closing
}

fn generate_model_encoder(model: Model) -> String {
  let fn_name = "encode_" <> justin.snake_case(model.name)
  let param_name = justin.snake_case(model.name)

  let signature =
    "pub fn "
    <> fn_name
    <> "("
    <> case model.params {
      [] -> "_" <> param_name
      _ -> param_name
    }
    <> ": "
    <> model.name
    <> ") -> Json {\n"

  // Проверяем, есть ли параметры
  case model.params {
    // Если параметров нет, возвращаем пустой массив
    [] -> signature <> "  json_object_filter_nulls([])\n}\n"

    // Если параметры есть, генерируем их список
    _ -> {
      let fields =
        list.map(model.params, fn(param) {
          let field_name = param.name
          let field_access = param_name <> "." <> map_param_name(field_name)

          let encoder = case param.type_ {
            ["int"] ->
              case param.optional {
                True -> "json.nullable(" <> field_access <> ", json.int)"
                False -> "json.int(" <> field_access <> ")"
              }
            ["float"] ->
              case param.optional {
                True -> "json.nullable(" <> field_access <> ", json.float)"
                False -> "json.float(" <> field_access <> ")"
              }
            ["string"] | ["str"] ->
              case param.optional {
                True -> "json.nullable(" <> field_access <> ", json.string)"
                False -> "json.string(" <> field_access <> ")"
              }
            ["boolean"] | ["bool"] | ["true"] ->
              case param.optional {
                True -> "json.nullable(" <> field_access <> ", json.bool)"
                False -> "json.bool(" <> field_access <> ")"
              }
            ["array", type_name] -> {
              case type_name {
                "int" ->
                  case param.optional {
                    True ->
                      "json.nullable("
                      <> field_access
                      <> ", json.array(_, json.int))"
                    False -> "json.array(" <> field_access <> ", json.int)"
                  }
                "float" ->
                  case param.optional {
                    True ->
                      "json.nullable("
                      <> field_access
                      <> ", json.array(_, json.float))"
                    False -> "json.array(" <> field_access <> ", json.float)"
                  }
                "string" | "str" ->
                  case param.optional {
                    True ->
                      "json.nullable("
                      <> field_access
                      <> ", json.array(_, json.string))"
                    False -> "json.array(" <> field_access <> ", json.string)"
                  }
                "bool" | "boolean" ->
                  case param.optional {
                    True ->
                      "json.nullable("
                      <> field_access
                      <> ", json.array(_, json.bool))"
                    False -> "json.array(" <> field_access <> ", json.bool)"
                  }
                other ->
                  case string.starts_with(other, "List(") {
                    True -> {
                      let inner_type =
                        string.replace(other, "List(", "")
                        |> string.replace(")", "")
                      case param.optional {
                        True ->
                          "json.nullable("
                          <> field_access
                          <> ", fn(outer_list) { "
                          <> "json.array(outer_list, fn(inner_list) { "
                          <> "json.array(inner_list, encode_"
                          <> justin.snake_case(inner_type)
                          <> ")"
                          <> "})"
                          <> "})"
                        False ->
                          "json.array("
                          <> field_access
                          <> ", fn(inner_list) { "
                          <> "json.array(inner_list, encode_"
                          <> justin.snake_case(inner_type)
                          <> ")"
                          <> "})"
                      }
                    }
                    False -> {
                      case param.optional {
                        True ->
                          "json.nullable("
                          <> field_access
                          <> ", json.array(_, encode_"
                          <> justin.snake_case(other)
                          <> "))"
                        False ->
                          "json.array("
                          <> field_access
                          <> ", encode_"
                          <> justin.snake_case(other)
                          <> ")"
                      }
                    }
                  }
              }
            }
            ["int", "str"] ->
              case param.optional {
                True ->
                  "json.nullable(" <> field_access <> ", encode_int_or_string)"
                False -> "encode_int_or_string(" <> field_access <> ")"
              }
            ["file", "str"] ->
              case param.optional {
                True ->
                  "json.nullable(" <> field_access <> ", encode_file_or_string)"
                False -> "encode_file_or_string(" <> field_access <> ")"
              }
            [single] ->
              case param.optional {
                True ->
                  "json.nullable("
                  <> field_access
                  <> ", encode_"
                  <> justin.snake_case(single)
                  <> ")"
                False ->
                  "encode_"
                  <> justin.snake_case(single)
                  <> "("
                  <> field_access
                  <> ")"
              }
            _ ->
              panic as { "Unknown type: " <> { param.type_ |> string.inspect } }
          }

          "    #(\"" <> field_name <> "\", " <> encoder <> ")"
        })

      let fields_str = string.join(fields, ",\n")

      signature
      <> "  json_object_filter_nulls([\n"
      <> fields_str
      <> ",\n  ])\n}\n"
    }
  }
}

fn generate_generic_type(generic: GenericType) -> String {
  let subtypes =
    list.map(generic.subtypes, fn(subtype) {
      "  " <> subtype <> generic.name <> "(" <> subtype <> ")"
    })

  "pub type "
  <> generic.name
  <> " {\n"
  <> string.join(subtypes, "\n")
  <> "\n}\n"
}

fn generate_generic_decoder(generic: GenericType) -> String {
  let fn_name = justin.snake_case(generic.name) <> "_decoder"

  let signature =
    "pub fn " <> fn_name <> "() -> decode.Decoder(" <> generic.name <> ") {\n"

  let variant_field = "  use variant <- decode.field(\"type\", decode.string)\n"

  let cases =
    list.map(generic.subtypes, fn(subtype) {
      let variant_name = "\"" <> justin.snake_case(subtype) <> "\""
      let constructor_name = subtype <> generic.name
      let decoder_name = justin.snake_case(subtype) <> "_decoder()"

      "    "
      <> variant_name
      <> " -> {\n"
      <> "      use value <- decode.field(\"value\", "
      <> decoder_name
      <> ")\n"
      <> "      decode.success("
      <> constructor_name
      <> "(value))\n"
      <> "    }"
    })

  let cases_str = string.join(cases, "\n")

  let default_case =
    "\n    _ -> panic as \"Invalid variant for " <> generic.name <> "\"\n"

  signature
  <> variant_field
  <> "  case variant {\n"
  <> cases_str
  <> default_case
  <> "  }\n}\n"
}

fn generate_generic_encoder(generic: GenericType) -> String {
  let fn_name = "encode_" <> justin.snake_case(generic.name)

  let signature =
    "pub fn " <> fn_name <> "(value: " <> generic.name <> ") -> Json {\n"

  let cases =
    list.map(generic.subtypes, fn(subtype) {
      let constructor_name = subtype <> generic.name

      "    "
      <> constructor_name
      <> "(inner_value) -> {\n"
      <> "      json.object([\n"
      <> "        #(\"type\", json.string(\""
      <> justin.snake_case(subtype)
      <> "\")),\n"
      <> "        #(\"value\", encode_"
      <> justin.snake_case(subtype)
      <> "(inner_value)),\n"
      <> "      ])\n"
      <> "    }"
    })

  let cases_str = string.join(cases, "\n")

  signature <> "  case value {\n" <> cases_str <> "\n  }\n}\n"
}

const header = "import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/json.{type Json}
import gleam/list

// This file is auto-generated from the Telegram Bot API documentation.
// Do not edit it manually.\n"

const footer = "pub type FileOrString {
  FileV(value: File)
  StringV(string: String)
}

pub fn file_or_string_decoder() -> decode.Decoder(FileOrString) {
  use variant <- decode.field(\"type\", decode.string)
  case variant {
    \"file_v\" -> {
      use value <- decode.field(\"value\", file_decoder())
      decode.success(FileV(value:))
    }
    \"string\" -> {
      use string <- decode.field(\"string\", decode.string)
      decode.success(StringV(string:))
    }
    _ -> decode.failure(StringV(\"\"), \"FileOrString\")
  }
}

pub fn encode_file_or_string(value: FileOrString) -> Json {
  case value {
    FileV(value) -> encode_file(value)
    StringV(string) -> json.string(string)
  }
}

// Common ------------------------------------------------------------------------------------------------------------

pub type IntOrString {
  Int(value: Int)
  Str(value: String)
}

pub fn int_or_string_decoder() -> decode.Decoder(IntOrString) {
  use variant <- decode.field(\"type\", decode.string)
  case variant {
    \"int\" -> {
      use value <- decode.field(\"value\", decode.int)
      decode.success(Int(value:))
    }
    \"str\" -> {
      use value <- decode.field(\"value\", decode.string)
      decode.success(Str(value:))
    }
    _ -> decode.failure(Int(0), \"IntOrString\")
  }
}

pub fn encode_int_or_string(value: IntOrString) -> Json {
  case value {
    Int(value) -> json.int(value)
    Str(value) -> json.string(value)
  }
}

pub fn json_object_filter_nulls(entries: List(#(String, Json))) -> Json {
  let null = json.null()

  entries
  |> list.filter(fn(entry) {
    let #(_, value) = entry
    value != null
  })
  |> json.object
}"

fn generate_code(api: ApiDefinition) -> String {
  let model_types = list.map(api.models, generate_model_type)
  let model_decoders = list.map(api.models, generate_model_decoder)
  let model_encoders = list.map(api.models, generate_model_encoder)
  let generic_types = list.map(api.generics, generate_generic_type)
  let generic_decoders = list.map(api.generics, generate_generic_decoder)
  let generic_encoders = list.map(api.generics, generate_generic_encoder)

  header
  <> string.join(generic_types, "\n")
  <> "\n"
  <> string.join(model_types, "\n")
  <> "\n"
  <> string.join(model_decoders, "\n")
  <> "\n"
  <> string.join(model_encoders, "\n")
  <> "\n"
  <> string.join(generic_decoders, "\n")
  <> "\n"
  <> string.join(generic_encoders, "\n")
  <> "\n"
  <> footer
}

fn parse_api_definition(json) {
  decode.run(json, decode_api_definition())
  |> result.map_error(fn(errors) {
    list.map(errors, fn(error) {
      dynamic.DecodeError(
        expected: error.expected,
        found: error.found,
        path: error.path,
      )
    })
  })
}

pub fn main() {
  io.println("Starting API generator...")

  case simplifile.read(scrapped_file) {
    Ok(content) -> {
      io.println("Successfully read input file: " <> scrapped_file)

      case json.decode(from: content, using: parse_api_definition) {
        Ok(api_definition) -> {
          io.println("Successfully parsed JSON")

          io.println("Successfully decoded API definition")
          io.println(
            "Found "
            <> string.inspect(list.length(api_definition.models))
            <> " models",
          )

          let code = generate_code(api_definition)

          case simplifile.write(output_file, code) {
            Ok(_) ->
              io.println(
                "Successfully generated Gleam code at: " <> output_file,
              )
            Error(reason) -> {
              io.println(
                "Failed to write output file: " <> string.inspect(reason),
              )
            }
          }
        }
        Error(reason) -> {
          io.println("Failed to parse JSON:")
          io.println(string.inspect(reason))
        }
      }
    }
    Error(reason) -> {
      io.println("Failed to read input file: " <> string.inspect(reason))
    }
  }
}
