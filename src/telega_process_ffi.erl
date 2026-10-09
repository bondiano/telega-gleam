%% The process dictionary, as far as `telega/scope` is concerned.
-module(telega_process_ffi).

-export([scope_entries/0, restore_scope_entries/1]).

%% `telega/scope` keeps an update's values under binary keys; everything
%% else in the dictionary (logger metadata, OTP ancestry) is the process's
%% own and stays put.
scope_entries() ->
    [{K, V} || {K, V} <- erlang:get(), is_binary(K)].

restore_scope_entries(Entries) ->
    lists:foreach(fun({K, V}) -> erlang:put(K, V) end, Entries),
    nil.
