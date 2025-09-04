import logging
import restaurant_booking/bot
import restaurant_booking/config
import restaurant_booking/util

pub fn main() -> Nil {
  logging.configure()
  logging.set_level(logging.Info)

  case config.load() {
    Ok(cfg) -> {
      util.log("Starting Restaurant Booking Bot...")
      case bot.start(cfg) {
        Ok(_) -> Nil
        Error(err) -> {
          util.log_error("Bot error: " <> err)
        }
      }
    }
    Error(err) -> {
      util.log_error("Configuration error: " <> err)
    }
  }
}