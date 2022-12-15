%% @doc This module is responsible for creating
%% and managing queue consumers.
-module(kyu_consumer).

-behaviour(supervisor).

-export([
    child_spec/1,
    start_link/1,
    check_opts/1,
    where/1,
    channel/1,
    stop/1
]).
-export([
    init/1
]).

-include("amqp.hrl").
-include("./_macros.hrl").

-define(FLAGS, {one_for_one, 10, 3600}).

-type opts() :: #{
    id := supervisor:child_id(),
    name := kyu:name(),
    connection := pid() | kyu:name(),
    module := module(),
    args := term(),
    prefetch_count := pos_integer(),
    commands := list(),
    duplex := boolean()
}.
-export_type([opts/0]).

%% @doc Returns a consumer child spec.
-spec child_spec(Opts :: opts()) -> supervisor:child_spec().
child_spec(#{id := Id, name := _} = Opts) ->
    ok = check_opts(Opts),
    #{id => Id, start => {?MODULE, start_link, Opts}};
child_spec(#{name := Name} = Opts) ->
    child_spec(Opts#{id => ?name(consumer, Name)}).

%% @doc Starts a consumer.
-spec start_link(Opts :: opts()) -> {ok, pid()} | {error, term()}.
start_link(#{name := Name} = Opts) ->
    ok = check_opts(Opts),
    supervisor:start_link(?via(consumer, Name), ?MODULE, Opts).

%% @doc Checks the validity of the provided consumer options.
%% @throws badmatch
-spec check_opts(Opts :: opts()) -> ok.
check_opts(#{name := _, connection := _, queue := Queue, module := Module, prefetch_count := PrefetchCount})
    when erlang:is_binary(Queue), erlang:is_atom(Module), erlang:is_integer(PrefetchCount), PrefetchCount > 0 -> ok.

%% @doc Returns the pid of the consumer.
%% -spec where(Name :: kyu:name()) -> pid() | undefined.
where(Name) ->
    gproc:where(?key(consumer, Name)).

%% @doc Returns the pid of the consumer's AMQP channel.
-spec channel(Ref :: pid() | kyu:name()) -> pid().
channel(Ref) when not erlang:is_pid(Ref) ->
    channel(where(Ref));
channel(Ref) ->
    {dictionary, Info} = erlang:process_info(Ref, dictionary),
    proplists:get_value('$kyu_channel', Info).

%% @hidden
-spec stop(Ref :: pid() | kyu:name()) -> ok.
stop(Ref) when not erlang:is_pid(Ref) ->
    stop(where(Ref));
stop(Ref) ->
    erlang:unlink(Ref),
    erlang:exit(Ref, shutdown).

%% CALLBACK FUNCTIONS

%% @hidden
init(#{connection := Connection} = Opts) ->
    case kyu_channel:start(Connection) of
        {ok, Channel} -> do_init(Channel, Opts);
        {error, Reason} -> {stop, Reason}
    end.

%% PRIVATE FUNCTIONS

%% @hidden
do_init(Channel, #{prefetch_count := PrefetchCount} = Opts) ->
    erlang:link(Channel),
    erlang:put('$kyu_channel', Channel),
    ok = kyu:declare(Channel, maps:get(commands, Opts, [])),
    #'basic.qos_ok'{} = kyu_channel:call(Channel, #'basic.qos'{prefetch_count = PrefetchCount, global = true}),
    {ok, {?FLAGS, make_child_specs(Channel, Opts)}}.

%% @hidden
make_child_specs(Channel, #{name := Name, duplex := true} = Opts) ->
    [kyu_publisher:child_spec(#{name => Name, channel => Channel, confirms => true})
     | make_child_specs(Channel, maps:remove(duplex, Opts))];
make_child_specs(Channel, #{prefetch_count := PrefetchCount} = Opts) ->
    [kyu_worker:child_spec(Opts#{channel => Channel}, #{size => PrefetchCount, max_overflow => 0})].
