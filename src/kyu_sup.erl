%% @hidden
-module(kyu_sup).

-behaviour(supervisor).

-export([start_link/1]).

-export([init/1]).

-define(SERVER, ?MODULE).
-define(FLAGS, {one_for_one, 10, 3600}).

start_link(Connections) ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, Connections).

init(Connections) ->
    Specs = lists:map(fun kyu_connection:child_spec/1, Connections),
    {ok, {{one_for_one, 10, 3600}, Specs}}.
