%% @hidden
-module(kyu_waitress).
%% for the record this module is named waitress because that sounds better then waiter
%% no sexism intended

-export([await/2, register/2, deliver/2]).

-spec await(Gproc :: tuple(), Timeout :: timeout()) -> infinity | integer().
await(Gproc, infinity) ->
    gproc:await(Gproc, infinity),
    infinity;
await(Gproc, Timeout) ->
    Start = erlang:system_time(millisecond),
    gproc:await(Gproc, Timeout),
    Timeout - (erlang:system_time(millisecond) - Start).

-spec register(Event :: term(), Caller :: tuple()) -> true.
register(Event, Caller) ->
    ets:insert(kyu, {Event, Caller}).

-spec deliver(Event :: term(), Callback :: fun()) -> true.
deliver(Event, Callback) ->
    Callers = lists:flatten(ets:match(kyu, {Event, '$1'})),
    lists:map(Callback, Callers),
    ets:delete(kyu, Event).
