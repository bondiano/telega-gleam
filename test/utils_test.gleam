import gleam/string
import gleeunit/should

import telega/internal/utils

pub fn normalize_url_test() {
  let url = utils.normalize_url("https://example.com/")
  should.equal(url, "https://example.com")

  let url = utils.normalize_url("https://example.com")
  should.equal(url, "https://example.com")
}

pub fn normalize_webhook_path_test() {
  let path = utils.normalize_webhook_path("/webhook/")
  should.equal(path, "webhook")

  let path = utils.normalize_webhook_path("webhook")
  should.equal(path, "webhook")

  let path = utils.normalize_webhook_path("/webhook")
  should.equal(path, "webhook")

  let path = utils.normalize_webhook_path("webhook/")
  should.equal(path, "webhook")
}

pub fn random_string_test() {
  let prefix = utils.random_string(10)
  should.equal(string.length(prefix), 10)

  let prefix = utils.random_string(5)
  should.equal(string.length(prefix), 5)
}
