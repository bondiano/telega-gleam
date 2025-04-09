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
