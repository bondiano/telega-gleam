%% Small ETS helpers Gleam cannot express directly.
-module(telega_ets_ffi).

-export([size/1, is_alive/1, compare_and_set/6]).

%% `ets:info(Table, size)` answers `undefined` for a table that is gone; a
%% caller only wants a number.
size(Table) ->
    case ets:info(Table, size) of
        undefined -> 0;
        Size -> Size
    end.

is_alive(Table) ->
    ets:info(Table, size) =/= undefined.

%% Write {Key, Value, ExpiresAt} only if the table currently holds Expected
%% for Key: `none` is "absent, or present but expired at Now", `{some, V}` is
%% "live and equal to V". One `insert_new` / `select_replace` each, so the
%% check and the write cannot interleave with another process's. An
%% ExpiresAt of 0 never expires.
compare_and_set(Table, Key, none, Value, ExpiresAt, Now) ->
    case ets:insert_new(Table, {Key, Value, ExpiresAt}) of
        true ->
            true;
        false ->
            Expired = [{'andalso', {'=/=', '$1', 0}, {'=<', '$1', Now}}],
            Spec = [{{Key, '_', '$1'}, Expired, [{const, {Key, Value, ExpiresAt}}]}],
            ets:select_replace(Table, Spec) =:= 1
    end;
compare_and_set(Table, Key, {some, Expected}, Value, ExpiresAt, Now) ->
    Live = [{'orelse', {'==', '$1', 0}, {'>', '$1', Now}}],
    Spec = [{{Key, Expected, '$1'}, Live, [{const, {Key, Value, ExpiresAt}}]}],
    ets:select_replace(Table, Spec) =:= 1.
