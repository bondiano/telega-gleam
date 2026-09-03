//// Driven against a mock client — no token, no network, no database file.

import gleam/dynamic/decode
import gleam/erlang/process
import gleam/json
import gleeunit

import telega/storage/ets
import telega/store
import telega/testing/conversation

import bot.{type Deps, Deps, Session}

pub fn main() {
  gleeunit.main()
}

fn dependencies(name: String) -> Deps {
  let assert Ok(kv) = ets.new(name)
  Deps(
    chat_total: store.chat_data(
      storage: kv,
      encode: json.int,
      decode: decode.int,
      default: fn() { 0 },
    ),
    grand_total: store.global_data(
      name: "messages",
      storage: kv,
      encode: json.int,
      decode: decode.int,
      default: fn() { 0 },
    ),
    scheduler: process.new_name("group_bot_test_jobs"),
  )
}

fn run(ct, name) {
  conversation.run_with_dependencies(
    ct,
    bot.build_router(),
    fn() { Session(sent: 0) },
    dependencies(name),
  )
}

pub fn stats_starts_at_zero_test() {
  conversation.conversation_test()
  |> conversation.send("/stats")
  |> conversation.expect_reply_containing("this chat: 0")
  |> run("group_bot_test_empty")
}

pub fn a_message_counts_towards_the_chat_test() {
  conversation.conversation_test()
  |> conversation.send("hello")
  |> conversation.send("/stats")
  |> conversation.expect_reply_containing("this chat: 1")
  |> run("group_bot_test_counting")
}

pub fn remind_explains_itself_when_misused_test() {
  conversation.conversation_test()
  |> conversation.send("/remind soon")
  |> conversation.expect_reply_containing("usage:")
  |> run("group_bot_test_usage")
}
