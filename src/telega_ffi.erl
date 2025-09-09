-module(telega_ffi).
-export([put_flows/1, get_flows/0, unsafe_coerce/1]).

-define(FLOWS_TABLE, telega_flows).

put_flows(Flows) ->
    case ets:info(?FLOWS_TABLE) of
        undefined ->
            ets:new(?FLOWS_TABLE, [named_table, public, set]);
        _ ->
            ok
    end,
    ets:insert(?FLOWS_TABLE, {flows, Flows}),
    nil.

get_flows() ->
    case ets:info(?FLOWS_TABLE) of
        undefined ->
            [];
        _ ->
            case ets:lookup(?FLOWS_TABLE, flows) of
                [{flows, Flows}] -> Flows;
                [] -> []
            end
    end.

unsafe_coerce(Value) ->
    Value.