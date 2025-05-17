import gleam/option.{None}
import telega/client

import telega
import telega/bot
import telega/feature

// lib API POC
// fn admin_feature(ctx) {
//   use <- feature.chat_type("private")
//   use <- bool.guard(is_admin(ctx), feature.Next(ctx))
//   use <- bool.guard(has_media_right(ctx), feature.Break(ctx, NoRightFeature))
//   // between features you can jump
//   use <- chat_actions.start_typing
//   use <- feature.handle_command("/media", handle_set_media)
//   use <- feature.handle_text("Remove all", handle_remove_all)
//   feature.Next(ctx)
// }

fn handle_hello(ctx) {
  ctx
}

fn simple_feature(ctx) {
  use _ <- feature.chat_type("private")
  use ctx <- feature.handle_text("Hello", handle_hello)
  todo
  // bot.Next(ctx)
}

pub fn init_feature_test() {
  let bot =
    telega.new("", "", "", None)
    |> telega.feature(simple_feature)
    |> telega.set_api_client(
      client.new("") |> client.set_fetch_client(fn(req) { todo }),
    )
}
