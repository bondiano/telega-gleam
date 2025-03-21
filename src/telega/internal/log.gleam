import gleam/string
import logging.{Debug, Error, Info, Warning}

pub fn error_d(message: anything) {
  logging.log(Error, string.inspect(message))
}

pub fn error(message: String) {
  logging.log(Error, message)
}

pub fn debug_d(message: anything) {
  logging.log(Debug, string.inspect(message))
}

pub fn debug(message: anything) {
  logging.log(Debug, string.inspect(message))
}

pub fn info_d(message: anything) {
  logging.log(Info, string.inspect(message))
}

pub fn info(message: String) {
  logging.log(Info, message)
}

pub fn warn_d(message: anything) {
  logging.log(Warning, string.inspect(message))
}

pub fn warn(message: String) {
  logging.log(Warning, message)
}
