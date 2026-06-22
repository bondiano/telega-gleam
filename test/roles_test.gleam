import gleam/erlang/process.{type Subject}
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option.{None}
import gleeunit
import gleeunit/should

import telega/bot.{type Context, Context}
import telega/client
import telega/error.{type TelegaError}
import telega/model/encoder
import telega/model/types
import telega/roles
import telega/testing/context as test_context
import telega/testing/factory

pub fn main() {
  gleeunit.main()
}

const chat_id = -100

const user_id = 7

/// A client that always answers `getChatMember` with `body`, recording each
/// call on the returned subject so tests can assert how often the API was hit.
fn member_client(body: String) -> #(client.TelegramClient, Subject(Nil)) {
  let calls = process.new_subject()
  let fetch = fn(_req) {
    process.send(calls, Nil)
    Ok(response.new(200) |> response.set_body(body))
  }
  #(client.new(token: "test", fetch_client: fetch), calls)
}

/// A client whose `getChatMember` always fails.
fn failing_client() -> client.TelegramClient {
  client.new(token: "test", fetch_client: fn(_req) {
    Error(error.FetchError("boom"))
  })
}

fn ok(result: json.Json) -> String {
  json.to_string(json.object([#("ok", json.bool(True)), #("result", result)]))
}

fn owner_body() -> String {
  ok(
    encoder.encode_chat_member(
      types.ChatMemberOwnerChatMember(types.ChatMemberOwner(
        status: "creator",
        user: factory.user_with(id: user_id, first_name: "Owner"),
        is_anonymous: False,
        custom_title: None,
      )),
    ),
  )
}

fn member_body() -> String {
  ok(
    encoder.encode_chat_member(
      types.ChatMemberMemberChatMember(types.ChatMemberMember(
        status: "member",
        tag: None,
        user: factory.user_with(id: user_id, first_name: "Member"),
        until_date: None,
      )),
    ),
  )
}

/// `administrator` has a large required-field set; build it as raw JSON with
/// every privilege denied — `classify` only inspects the `status`.
fn admin_body() -> String {
  let bools = [
    "can_be_edited", "is_anonymous", "can_manage_chat", "can_delete_messages",
    "can_manage_video_chats", "can_restrict_members", "can_promote_members",
    "can_change_info", "can_invite_users", "can_post_stories",
    "can_edit_stories", "can_delete_stories",
  ]
  let fields = [
    #("status", json.string("administrator")),
    #(
      "user",
      encoder.encode_user(factory.user_with(id: user_id, first_name: "Admin")),
    ),
    ..list.map(bools, fn(k) { #(k, json.bool(False)) })
  ]
  ok(json.object(fields))
}

pub fn owner_is_admin_and_owner_test() {
  let #(client, _calls) = member_client(owner_body())
  let cache = roles.new_cache(ttl_ms: 60_000)

  roles.is_owner(cache:, client:, chat_id:, user_id:) |> should.be_true
  roles.is_admin(cache:, client:, chat_id:, user_id:) |> should.be_true
}

pub fn administrator_is_admin_but_not_owner_test() {
  let #(client, _calls) = member_client(admin_body())
  let cache = roles.new_cache(ttl_ms: 60_000)

  roles.is_admin(cache:, client:, chat_id:, user_id:) |> should.be_true
  roles.is_owner(cache:, client:, chat_id:, user_id:) |> should.be_false
}

pub fn plain_member_is_neither_test() {
  let #(client, _calls) = member_client(member_body())
  let cache = roles.new_cache(ttl_ms: 60_000)

  roles.is_admin(cache:, client:, chat_id:, user_id:) |> should.be_false
  roles.is_owner(cache:, client:, chat_id:, user_id:) |> should.be_false
}

pub fn api_error_fails_closed_test() {
  let cache = roles.new_cache(ttl_ms: 60_000)

  roles.is_admin(cache:, client: failing_client(), chat_id:, user_id:)
  |> should.be_false
}

pub fn caches_within_ttl_test() {
  let #(client, calls) = member_client(owner_body())
  let cache = roles.new_cache(ttl_ms: 60_000)

  roles.is_admin(cache:, client:, chat_id:, user_id:) |> should.be_true
  roles.is_owner(cache:, client:, chat_id:, user_id:) |> should.be_true

  // Two checks for the same {chat,user} hit the API only once.
  process.receive(calls, 50) |> should.equal(Ok(Nil))
  process.receive(calls, 50) |> should.equal(Error(Nil))
}

pub fn ttl_zero_disables_cache_test() {
  let #(client, calls) = member_client(owner_body())
  let cache = roles.new_cache(ttl_ms: 0)

  roles.is_admin(cache:, client:, chat_id:, user_id:) |> should.be_true
  roles.is_admin(cache:, client:, chat_id:, user_id:) |> should.be_true

  // Caching disabled — each check hits the API.
  process.receive(calls, 50) |> should.equal(Ok(Nil))
  process.receive(calls, 50) |> should.equal(Ok(Nil))
}

fn ctx_for(client: client.TelegramClient) -> Context(String, TelegaError, Nil) {
  let upd = factory.text_update_with(text: "hi", from_id: user_id, chat_id:)
  let ctx = test_context.context_with(session: "initial", update: upd)
  Context(..ctx, config: test_context.config_with_client(client))
}

pub fn ensure_admin_runs_body_for_admin_test() {
  let #(client, _calls) = member_client(owner_body())
  let cache = roles.new_cache(ttl_ms: 60_000)

  let result = {
    use ctx <- roles.ensure_admin(ctx_for(client), cache, on_denied: fn(ctx) {
      Ok(Context(..ctx, session: "denied"))
    })
    Ok(Context(..ctx, session: "allowed"))
  }

  result
  |> should.be_ok()
  |> fn(ctx: Context(String, TelegaError, Nil)) { ctx.session }
  |> should.equal("allowed")
}

pub fn ensure_admin_denies_plain_member_test() {
  let #(client, _calls) = member_client(member_body())
  let cache = roles.new_cache(ttl_ms: 60_000)

  let result = {
    use ctx <- roles.ensure_admin(ctx_for(client), cache, on_denied: fn(ctx) {
      Ok(Context(..ctx, session: "denied"))
    })
    Ok(Context(..ctx, session: "allowed"))
  }

  result
  |> should.be_ok()
  |> fn(ctx: Context(String, TelegaError, Nil)) { ctx.session }
  |> should.equal("denied")
}
