import gleeunit
import gleeunit/should

import telega

pub fn main() {
  gleeunit.main()
}

// L1 — the webhook secret must not be compared byte-by-byte with early exit --

pub fn secret_token_comparison_is_length_independent_test() {
  // `constant_time_compare` is what `is_secret_token_valid` uses; a plain `==`
  // on binaries short-circuits at the first differing byte, which leaks the
  // shared prefix through timing.
  telega.constant_time_compare("s3cret", "s3cret") |> should.be_true
  telega.constant_time_compare("s3cret", "s3crew") |> should.be_false
  telega.constant_time_compare("s3cret", "s3cre") |> should.be_false
  telega.constant_time_compare("", "") |> should.be_true
  telega.constant_time_compare("", "x") |> should.be_false
}
