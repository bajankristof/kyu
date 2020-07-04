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
    id := supervisor:child_id(),
    name := name(),
    queue := binary(),
    worker_module := atom(),
    worker_state := map(),
    worker_count := integer(),
    prefetch_count := integer(),
    duplex := boolean(),
    commands := list(),
    channel := kyu_channel:name()
}.
-export_type([name/0, opts/0]).

%% API FUNCTIONS

%% @doc Returns a consumer child spec.
-spec child_spec(Connection :: kyu_connection:name(), Opts :: opts()) -> supervisor:child_spec().
child_spec(Connection, #{id := _} = Opts) ->
    #{id => maps:get(id, Opts), start => {?MODULE, start_link, [Connection, Opts]}};
child_spec(Connection, #{name := Name} = Opts) ->
    child_spec(Connection, Opts#{id => ?name(consumer, Name)}).

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

%% @doc Returns the name of the consumer's connection.
-spec connection(Name :: name()) -> kyu_connection:name().
connection(Name) ->
    kyu_wrangler:connection(Name).

%% @doc Returns the name of the consumer's channel.
-spec channel(Name :: name()) -> kyu_channel:name().
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

%% @doc Waits for the consumer to successfully consume its queue.
-spec await(Name :: name(), Timeout :: timeout()) -> ok.
await(Name, Timeout) ->
    kyu_wrangler:await(Name, Timeout).

%% CALLBACK FUNCTIONS

%% @hidden
init({Connection, #{duplex := true} = Opts}) ->
    Modules = [kyu_wrangler, kyu_worker, kyu_publisher],
    init(Connection, maps:without([id], Opts), Modules);
init({Connection, Opts}) ->
    Modules = [kyu_wrangler, kyu_worker],
    init(Connection, maps:without([id], Opts), Modules).

%% PRIVATE FUNCTIONS

%% @hidden
init(Connection, #{channel := Channel} = Opts, Modules) ->
    ok = check_opts(Opts),
    Specs = lists:map(fun (Module) ->
        Module:child_spec(Connection, Opts#{channel => Channel})
    end, Modules),
    {ok, flags(Specs)};
init(Connection, Opts, Modules) ->
    ok = check_opts(Opts),
    Channel = erlang:make_ref(),
    Specs = lists:foldl(fun (Module, Acc) ->
        Acc ++ [Module:child_spec(Connection, Opts#{channel => Channel})]
    end, [kyu_channel:child_spec(Connection, #{name => Channel})], Modules),
    {ok, flags(Specs)}.

%% @hidden
flags(Specs) -> {{one_for_one, 5, 3600}, Specs}.
