%% Small ETS helpers Gleam cannot express directly.
-module(telega_ets_ffi).

-export([size/1, is_alive/1]).

%% `ets:info(Table, size)` answers `undefined` for a table that is gone; a
%% caller only wants a number.
size(Table) ->
    case ets:info(Table, size) of
        undefined -> 0;
        Size -> Size
    end.

is_alive(Table) ->
    ets:info(Table, size) =/= undefined.
