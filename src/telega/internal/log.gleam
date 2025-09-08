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
