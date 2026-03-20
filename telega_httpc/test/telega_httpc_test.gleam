import gleeunit
import gleeunit/should
import telega/client
import telega_httpc

pub fn main() {
  gleeunit.main()
}

pub fn new_creates_client_test() {
  let client = telega_httpc.new("test-token")
  client.get_api_url(client)
  |> should.equal("https://api.telegram.org/bot")
}
