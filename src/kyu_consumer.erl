%% @doc This module is responsible for creating
%% and managing queue consumers.
-module(kyu_consumer).

-behaviour(supervisor).

-export([
    child_spec/2,
    start_link/2,
    check_opts/1,
    where/1,
    connection/1,
    channel/1,
    queue/1,
    await/1,
    await/2
]).

-export([init/1]).

-include("./_macros.hrl").

-type name() :: term().
-type opts() :: #{
    name := name(),
    queue := binary(),
    worker_module := atom(),
    worker_state := map(),
    worker_count := integer(),
    prefetch_count := integer(),
    commands := list()
}.
-export_type([name/0, opts/0]).

%% API FUNCTIONS

%% @doc Returns a consumer child spec.
-spec child_spec(Connection :: kyu_connection:name(), Opts :: opts()) -> supervisor:child_spec().
child_spec(Connection, #{name := Name} = Opts) ->
    #{id => ?name(consumer, Name), start => {?MODULE, start_link, [Connection, Opts]}}.

%% @doc Starts a consumer.
-spec start_link(Connection :: kyu_connection:name(), Opts :: opts()) -> {ok, pid()} | {error, term()}.
start_link(Connection, #{name := Name} = Opts) ->
    supervisor:start_link(?via(consumer, Name), ?MODULE, {Connection, Opts}).

%% @doc Checks the validity of the provided consumer options.
%% @throws badmatch
-spec check_opts(Opts :: opts()) -> ok.
check_opts(#{name := _, queue := Queue, worker_module := Module, worker_state := _})
    when erlang:is_binary(Queue), erlang:is_atom(Module) -> ok.

%% @doc Returns the pid of the consumer.
%% -spec where(Name :: name()) -> pid() | undefined.
where(Name) ->
    gproc:where(?server(consumer, Name)).

%% @doc Returns the name of the consumer's connection server.
-spec connection(Name :: name()) -> term().
connection(Name) ->
    kyu_wrangler:connection(Name).

%% @doc Returns the underlying amqp channel.
-spec channel(Name :: name()) -> pid() | undefined.
channel(Name) ->
    kyu_wrangler:channel(Name).

%% @doc Returns the name of the consumer's queue.
-spec queue(Name :: name()) -> binary().
queue(Name) ->
    kyu_wrangler:queue(Name).

%% @equiv kyu_consumer:await(Name, 60000)
-spec await(Name :: name()) -> ok.
await(Name) ->
    kyu_wrangler:await(Name).

%% @doc Waits for the consumer to successfully consume it's queue.
-spec await(Name :: name(), Timeout :: timeout()) -> ok.
await(Name, Timeout) ->
    kyu_wrangler:await(Name, Timeout).

%% CALLBACK FUNCTIONS

%% @hidden
init({Connection, Opts}) ->
    ok = check_opts(Opts),
    Specs = lists:map(fun (Module) ->
        erlang:apply(Module, child_spec, [Connection, Opts])
    end, [kyu_worker, kyu_wrangler]),
    {ok, {{one_for_all, 5, 3600}, Specs}}.
