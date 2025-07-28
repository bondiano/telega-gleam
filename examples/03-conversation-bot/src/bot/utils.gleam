import envoy
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type DotEnvError {
  ErrorReadingEnvFile(simplifile.FileError)
}

pub fn env_config() {
  use env_file <- result.map(
    simplifile.read(".env")
    |> result.map_error(ErrorReadingEnvFile),
  )

  let lines =
    string.split(env_file, "\n")
    |> list.filter(fn(line) { line != "" })

  use line <- list.each(lines)
  let splited_line = string.split(line, "=")
  let key =
    list.first(splited_line)
    |> result.unwrap("")
    |> string.trim()

  let value =
    list.drop(splited_line, 1)
    |> string.join("=")
    |> string.trim()

  envoy.set(key, value)
}
