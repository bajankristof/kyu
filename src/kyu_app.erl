%% @hidden
-module(kyu_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_, _) ->
    ets:new(kyu, [bag, public, named_table]),
    Connections = application:get_env(kyu, connections, []),
    kyu_sup:start_link(Connections).

stop(_) ->
    ok.
