//// Phase 6a: state that is not the session — shared by a chat, followed by a
//// user, or global to the bot.

import gleam/dynamic/decode
import gleam/json
import gleam/option.{Some}
import gleeunit/should

import telega/storage/ets
import telega/store
import telega/testing/context
import telega/testing/factory

fn ctx_in(chat_id chat_id: Int, from_id from_id: Int) {
  context.context_with(
    session: Nil,
    update: factory.text_update_with(text: "hi", from_id:, chat_id:),
  )
}

fn counter(name: String) {
  let assert Ok(kv) = ets.new(name)
  #(
    kv,
    store.chat_data(
      storage: kv,
      encode: json.int,
      decode: decode.int,
      default: fn() { 0 },
    ),
  )
}

pub fn a_chat_store_starts_at_its_default_test() {
  let #(_kv, counters) = counter("store_default")
  store.get(ctx_in(chat_id: -100, from_id: 7), counters)
  |> should.equal(Ok(0))
}

pub fn every_member_of_a_chat_sees_the_same_value_test() {
  let #(_kv, counters) = counter("store_shared")
  let ada = ctx_in(chat_id: -100, from_id: 7)
  let grace = ctx_in(chat_id: -100, from_id: 8)

  store.update(ada, counters, fn(n) { n + 1 }) |> should.equal(Ok(1))
  store.update(grace, counters, fn(n) { n + 1 }) |> should.equal(Ok(2))

  // ...and a different chat has its own.
  store.get(ctx_in(chat_id: -200, from_id: 7), counters)
  |> should.equal(Ok(0))
}

pub fn a_chat_store_is_keyed_by_the_chat_test() {
  let #(kv, counters) = counter("store_key")
  let ctx = ctx_in(chat_id: -100, from_id: 7)

  store.key(ctx, counters) |> should.equal("chat:-100")
  let assert Ok(Nil) = store.set(ctx, counters, 41)
  kv.get("data:chat:-100") |> should.equal(Ok(Some("41")))
}

pub fn deleting_a_value_reads_back_the_default_test() {
  let #(_kv, counters) = counter("store_delete")
  let ctx = ctx_in(chat_id: -100, from_id: 7)

  let assert Ok(Nil) = store.set(ctx, counters, 5)
  let assert Ok(Nil) = store.delete(ctx, counters)
  store.get(ctx, counters) |> should.equal(Ok(0))
}

pub fn a_user_store_follows_the_user_between_chats_test() {
  let assert Ok(kv) = ets.new("store_user")
  let seen =
    store.user_data(
      storage: kv,
      encode: json.string,
      decode: decode.string,
      default: fn() { "" },
    )

  let assert Ok(Nil) = store.set(ctx_in(chat_id: -100, from_id: 7), seen, "ada")
  store.get(ctx_in(chat_id: -999, from_id: 7), seen)
  |> should.equal(Ok("ada"))
  store.get(ctx_in(chat_id: -100, from_id: 8), seen) |> should.equal(Ok(""))
}

pub fn a_global_store_is_the_same_everywhere_test() {
  let assert Ok(kv) = ets.new("store_global")
  let flag =
    store.global_data(
      name: "maintenance",
      storage: kv,
      encode: json.bool,
      decode: decode.bool,
      default: fn() { False },
    )

  let assert Ok(Nil) = store.set(ctx_in(chat_id: -100, from_id: 7), flag, True)
  store.get(ctx_in(chat_id: -200, from_id: 8), flag) |> should.equal(Ok(True))
  kv.get("data:global:maintenance") |> should.equal(Ok(Some("true")))
}

pub fn an_expired_value_reads_back_the_default_test() {
  let assert Ok(kv) = ets.new("store_ttl")
  let ephemeral =
    store.chat_data(
      storage: kv,
      encode: json.int,
      decode: decode.int,
      default: fn() { 0 },
    )
    |> store.with_ttl(1)

  let ctx = ctx_in(chat_id: -100, from_id: 7)
  let assert Ok(Nil) = store.set(ctx, ephemeral, 7)
  sleep(20)
  store.get(ctx, ephemeral) |> should.equal(Ok(0))
}

pub fn a_value_that_will_not_decode_reads_back_the_default_test() {
  let #(kv, counters) = counter("store_corrupt")
  let assert Ok(Nil) = kv.set("data:chat:-100", "\"not a number\"")

  store.get(ctx_in(chat_id: -100, from_id: 7), counters)
  |> should.equal(Ok(0))
}

pub fn an_explicit_key_reaches_data_no_update_points_at_test() {
  let #(_kv, counters) = counter("store_explicit_key")

  let assert Ok(1) = store.update_at(counters, "chat:-4242", fn(n) { n + 1 })
  store.get_at(counters, "chat:-4242") |> should.equal(Ok(1))
  let assert Ok(Nil) = store.delete_at(counters, "chat:-4242")
  store.get_at(counters, "chat:-4242") |> should.equal(Ok(0))
}

@external(erlang, "timer", "sleep")
fn sleep(milliseconds: Int) -> anything
