import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/erlang/atom.{type Atom}
import gleam/list
import gleam/result
import gleam/string
import logging.{Error, Info, Warning}

pub fn error_d(prefix: String, message: anything) {
  logging.log(Error, prefix <> ": " <> string.inspect(message))
}

pub fn error(message: String) {
  logging.log(Error, message)
}

pub fn info_d(prefix: String, message: anything) {
  logging.log(Info, prefix <> ": " <> string.inspect(message))
}

pub fn info(message: String) {
  logging.log(Info, message)
}

pub fn warning(message: String) {
  logging.log(Warning, message)
}

/// Structured metadata attached to every log line emitted by *this process*
/// for the duration of `run`.
///
/// Erlang's `logger` merges process metadata into every event, so a formatter
/// or handler (`logger_std_h` with a `template`, a JSON formatter, an OTLP
/// exporter) sees the fields without the message text having to carry them —
/// and so do log lines written by code that knows nothing about telega.
///
/// The previous metadata is restored afterwards, so nested contexts stack and
/// unwind. A process that dies inside `run` takes its metadata with it.
pub fn with_metadata(
  fields fields: List(#(String, String)),
  run run: fn() -> a,
) -> a {
  let previous = logger_get_process_metadata()
  let _ = logger_update_process_metadata(to_metadata(fields))
  let result = run()
  // `logger:get_process_metadata/0` answers `undefined` when the process has
  // none — restore a map, otherwise leave the process as we found it.
  let had_metadata =
    decode.run(previous, decode.dict(decode.dynamic, decode.dynamic))
    |> result.is_ok
  let _ = case had_metadata {
    True -> logger_set_process_metadata(previous)
    False -> logger_unset_process_metadata()
  }
  result
}

fn to_metadata(fields: List(#(String, String))) -> Dict(Atom, Dynamic) {
  fields
  |> list.map(fn(field) { #(atom.create(field.0), dynamic.string(field.1)) })
  |> dict.from_list
}

@external(erlang, "logger", "update_process_metadata")
fn logger_update_process_metadata(metadata: Dict(Atom, Dynamic)) -> Dynamic

@external(erlang, "logger", "set_process_metadata")
fn logger_set_process_metadata(metadata: Dynamic) -> Dynamic

@external(erlang, "logger", "unset_process_metadata")
fn logger_unset_process_metadata() -> Dynamic

@external(erlang, "logger", "get_process_metadata")
fn logger_get_process_metadata() -> Dynamic
