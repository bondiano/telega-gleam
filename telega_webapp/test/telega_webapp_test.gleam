import gleam/bit_array
import gleam/crypto
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should

import telega_webapp

pub fn main() {
  gleeunit.main()
}

// Independent test vector: the `hash` below was computed with OpenSSL
// (a separate HMAC-SHA256 implementation), not this library, so a passing
// `validate` proves interop rather than self-consistency.
//
//   secret = HMAC-SHA256(key="WebAppData", msg=token)
//   hash   = HMAC-SHA256(key=secret, msg=data_check_string)
const token = "123456:test-token"

const init_data = "auth_date=1700000000&query_id=abc123&user={\"id\":42,\"first_name\":\"Ada\"}&hash=67d6dab32066b404ee1be485bd816a0dc07345a836d006fe4765e0c899d6557c"

pub fn validate_ok_test() {
  let assert Ok(data) = telega_webapp.validate(token, init_data)

  data.auth_date |> should.equal(1_700_000_000)
  data.query_id |> should.equal(Some("abc123"))

  let assert Some(user) = data.user
  user.id |> should.equal(42)
  user.first_name |> should.equal("Ada")
  user.last_name |> should.equal(None)
}

pub fn validate_wrong_token_test() {
  telega_webapp.validate("0000000000:wrong-token", init_data)
  |> should.equal(Error(telega_webapp.SignatureMismatch))
}

pub fn validate_tampered_data_test() {
  // Change the first name; the hash no longer matches.
  let tampered = string.replace(init_data, "Ada", "Bob")
  telega_webapp.validate(token, tampered)
  |> should.equal(Error(telega_webapp.SignatureMismatch))
}

pub fn validate_missing_hash_test() {
  telega_webapp.validate(token, "auth_date=1700000000&query_id=abc")
  |> should.equal(Error(telega_webapp.MissingHash))
}

pub fn validate_with_max_age_fresh_test() {
  // With a huge max_age the 2023 `auth_date` is still "fresh".
  let assert Ok(_) =
    telega_webapp.validate_with_max_age(token, init_data, 100_000_000_000)
}

pub fn validate_with_max_age_outdated_test() {
  telega_webapp.validate_with_max_age(token, init_data, 60)
  |> should.equal(Error(telega_webapp.Outdated))
}

pub fn is_fresh_test() {
  let assert Ok(data) = telega_webapp.validate(token, init_data)
  telega_webapp.is_fresh(data, 100, 1_700_000_050) |> should.equal(True)
  telega_webapp.is_fresh(data, 10, 1_700_000_050) |> should.equal(False)
}

pub fn parse_without_validation_test() {
  let assert Ok(data) = telega_webapp.parse(init_data)
  let assert Some(user) = data.user
  user.first_name |> should.equal("Ada")
}

pub fn parse_missing_auth_date_test() {
  telega_webapp.parse("query_id=abc&hash=deadbeef")
  |> should.equal(Error(telega_webapp.InvalidField("auth_date")))
}

// Round-trip: sign an arbitrary payload with the documented scheme and
// confirm `validate` accepts it, exercising fields beyond the fixed vector.
pub fn round_trip_test() {
  let my_token = "987654:another-token"
  let fields = [
    #("auth_date", "1700000000"),
    #("query_id", "test-query"),
    #("user", "{\"id\":7,\"first_name\":\"Grace\",\"username\":\"ghopper\"}"),
  ]
  let signed = sign_init_data(my_token, fields)

  let assert Ok(data) = telega_webapp.validate(my_token, signed)
  let assert Some(user) = data.user
  user.id |> should.equal(7)
  user.username |> should.equal(Some("ghopper"))
}

// Third-party Ed25519 path: an all-zero (valid-length) signature must verify
// false rather than crash, proving the `crypto:verify` FFI is wired up.
pub fn validate_third_party_rejects_bad_signature_test() {
  let signature = string.repeat("A", 86)
  let data =
    "auth_date=1700000000&query_id=abc123&signature=" <> signature <> "&hash=x"
  telega_webapp.validate_third_party(123_456, data, telega_webapp.Production)
  |> should.equal(Error(telega_webapp.SignatureMismatch))
}

pub fn validate_third_party_rejects_wrong_length_signature_test() {
  let data = "auth_date=1700000000&signature=YWJj&hash=x"
  telega_webapp.validate_third_party(123_456, data, telega_webapp.Test)
  |> should.equal(Error(telega_webapp.SignatureMismatch))
}

pub fn validate_third_party_missing_signature_test() {
  telega_webapp.validate_third_party(
    123_456,
    "auth_date=1700000000&hash=x",
    telega_webapp.Production,
  )
  |> should.equal(Error(telega_webapp.MissingSignature))
}

/// Build a valid `initData` query string for `fields` using the Telegram
/// signing scheme. Values must not contain `&`, `=`, `%` or `+` so they
/// survive `uri.parse_query` unchanged.
fn sign_init_data(token: String, fields: List(#(String, String))) -> String {
  let data_check_string =
    fields
    |> list.sort(fn(a, b) { string.compare(a.0, b.0) })
    |> list.map(fn(p) { p.0 <> "=" <> p.1 })
    |> string.join("\n")

  let secret =
    crypto.hmac(
      bit_array.from_string(token),
      crypto.Sha256,
      bit_array.from_string("WebAppData"),
    )
  let hash =
    crypto.hmac(bit_array.from_string(data_check_string), crypto.Sha256, secret)
    |> bit_array.base16_encode
    |> string.lowercase

  list.map(fields, fn(p) { p.0 <> "=" <> p.1 })
  |> list.append(["hash=" <> hash])
  |> string.join("&")
}
