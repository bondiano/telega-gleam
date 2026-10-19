%% Direct hackney call with the timeouts Telega needs.
%%
%% Explicit timeouts keep hackney's 5-second default from aborting long polls.
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
        {error, timeout} ->
            {error, timeout};
        {error, connect_timeout} ->
            {error, timeout};
        {error, checkout_timeout} ->
            {error, timeout};
        {error, Error} ->
            {error, {other, Error}}
    end.
