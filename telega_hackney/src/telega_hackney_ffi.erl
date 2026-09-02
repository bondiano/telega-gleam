%% Direct hackney call with the timeouts Telega needs.
%%
%% `gleam_hackney` passes only `{with_body, true}`, which leaves hackney's
%% 5-second `recv_timeout` in force — shorter than a 30-second long poll, so
%% every empty `getUpdates` ends in a timeout and the bot silently degrades to
%% 5-second polling.
-module(telega_hackney_ffi).

-export([send/6]).

send(Method, Url, Headers, Body, ConnectTimeout, RecvTimeout) ->
    Options = [
        {with_body, true},
        {connect_timeout, ConnectTimeout},
        {recv_timeout, RecvTimeout}
    ],
    case hackney:request(Method, Url, Headers, Body, Options) of
        {ok, Status, ResponseHeaders, ResponseBody} ->
            {ok, {response, Status, ResponseHeaders, ResponseBody}};
        {ok, Status, ResponseHeaders} ->
            {ok, {response, Status, ResponseHeaders, <<>>}};
        {error, Error} ->
            {error, Error}
    end.
