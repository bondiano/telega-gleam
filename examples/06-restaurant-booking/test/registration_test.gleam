import gleeunit
import gleeunit/should
import restaurant_booking/flows/registration

pub fn main() {
  gleeunit.main()
}

pub fn validate_name_test() {
  registration.validate_name("John Doe")
  |> should.be_ok()

  registration.validate_name("J")
  |> should.be_error()
}

pub fn validate_phone_test() {
  registration.validate_phone("1234567890")
  |> should.be_ok()

  registration.validate_phone("123")
  |> should.be_error()
}

pub fn validate_email_test() {
  registration.validate_email("test@example.com")
  |> should.be_ok()

  registration.validate_email("invalid-email")
  |> should.be_error()
}
