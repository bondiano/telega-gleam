import logging
import restaurant_booking/bot
import restaurant_booking/config

pub fn main() -> Nil {
  logging.configure()
  logging.set_level(logging.Info)

  let assert Ok(cfg) = config.load()
  let assert Ok(_) = bot.start(cfg)

  Nil
}
