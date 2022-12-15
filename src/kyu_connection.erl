%% @doc This module is responsible for creating
%% and maintaining AMQP connections.
-module(kyu_connection).

-compile({no_auto_import, [apply/3]}).

-behaviour(gen_server).

-export([
    child_spec/1,
    start_link/1,
    call/2,
    call/3,
    cast/2,
    where/1,
    pid/1,
    network/1,
    options/1,
    option/2,
    option/3,
    apply/2,
    apply/3,
    stop/1
]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_continue/2,
    handle_info/2,
    terminate/2
]).

-include("amqp.hrl").
-include("./_defaults.hrl").
-include("./_errors.hrl").
-include("./_macros.hrl").

-type opts() :: #{
    id := supervisor:child_id(),
    name := kyu:name(),
    url := iodata(),
    host := iolist(),
    port := pos_integer(),
    username := binary(),
    password := binary(),
    heartbeat := pos_integer(),
    virtual_host := binary(),
    channel_max := pos_integer(),
    frame_max := pos_integer(),
    ssl_options := term(),
    client_properties := list(),
    retry_delay := pos_integer(),
    retry_attempts := infinity | pos_integer(),
    management_host := iodata(),
    management_port := pos_integer()
}.
-export_type([opts/0]).

-record(state, {
    opts :: opts(),
    network :: #amqp_params_network{},
    connection = undefined :: pid()
}).

%% API FUNCTIONS

%% @doc Returns a connection child spec.
-spec child_spec(Opts :: opts()) -> supervisor:child_spec().
child_spec(#{id := _} = Opts) ->
    #{id => maps:get(id, Opts), start => {?MODULE, start_link, [Opts]}};
child_spec(#{name := Name} = Opts) ->
    child_spec(Opts#{id => ?name(connection, Name)}).

%% @doc Starts a connection.
-spec start_link(Opts :: opts()) -> {ok, pid()} | {error, term()}.
start_link(#{name := Name} = Opts) ->
    gen_server:start_link(?via(connection, Name), ?MODULE, Opts, []);
start_link(Opts) ->
    gen_server:start_link(?MODULE, Opts, []).

%% @doc Makes a gen_server:call/2 call to the connection.
-spec call(Ref :: pid() | kyu:name(), Request :: term()) -> term().
call(Ref, Request) ->
    call(Ref, Request, ?DEFAULT_TIMEOUT).

%% @doc Makes a gen_server:call/3 call to the connection.
-spec call(Ref :: pid() | kyu:name(), Request :: term(), Timeout :: timeout()) -> term().
call(Ref, Request, Timeout) when erlang:is_pid(Ref) ->
    gen_server:call(Ref, Request, Timeout);
call(Ref, Request, Timeout) ->
    gen_server:call(?via(connection, Ref), Request, Timeout).

%% @doc Makes a gen_server:cast/2 call to the connection.
-spec cast(Ref :: pid() | kyu:name(), Request :: term()) -> ok.
cast(Ref, Request) when erlang:is_pid(Ref) ->
    gen_server:cast(Ref, Request);
cast(Ref, Request) ->
    gen_server:cast(?via(connection, Ref), Request).

%% @doc Returns the pid of the connection.
%% -spec where(Name :: kyu:name()) -> pid() | undefined.
where(Name) ->
    gproc:where(?key(connection, Name)).

%% @doc Returns the pid of the underlying AMQP connection.
-spec pid(Ref :: pid() | kyu:name()) -> pid() | undefined.
pid(Ref) ->
    call(Ref, pid).

%% @doc Returns the connection's network params.
-spec network(Ref :: pid() | kyu:name()) -> #amqp_params_network{}.
network(Ref) ->
    call(Ref, network).

%% @doc Returns the connection's options.
-spec options(Ref :: pid() | kyu:name()) -> opts().
options(Ref) ->
    call(Ref, options).

%% @equiv kyu_connection:option(Ref, Key, undefined)
-spec option(Ref :: pid() | kyu:name(), Key :: atom()) -> term().
option(Ref, Key) ->
    option(Ref, Key, undefined).

%% @doc Returns a value from the connection's options.
-spec option(Ref :: pid() | kyu:name(), Key :: atom(), Value :: term()) -> term().
option(Ref, Key, Value) ->
    call(Ref, {option, Key, Value}).

%% @equiv kyu_connection:apply(Ref, Function, [])
-spec apply(Ref :: pid() | kyu:name(), Function :: atom()) -> term().
apply(Ref, Function) ->
    apply(Ref, Function, []).

%% @doc Calls a function on the underlying AMQP connection.
-spec apply(Ref :: pid() | kyu:name(), Function :: atom(), Args :: list()) -> term().
apply(Ref, Function, Args) ->
    Connection = pid(Ref),
    erlang:apply(amqp_connection, Function, [Connection | Args]).

%% @doc Gracefully closes the connection.
-spec stop(Ref :: pid() | kyu:name()) -> ok.
stop(Ref) when erlang:is_pid(Ref) ->
    gen_server:stop(Ref);
stop(Ref) ->
    gen_server:stop(?via(connection, Ref)).

%% CALLBACK FUNCTIONS

%% @hidden
init(Opts) ->
    Network = kyu_network:new(Opts),
    State = #state{network = Network, opts = Opts},
    {ok, State, {continue, connect}}.

%% @hidden
handle_call(pid, _, #state{connection = Connection} = State) ->
    {reply, Connection, State};
handle_call(network, _, #state{network = Network} = State) ->
    {reply, Network, State};
handle_call(options, _, #state{opts = Opts} = State) ->
    {reply, Opts, State};
handle_call({option, Key, Value}, _, #state{opts = Opts} = State) ->
    {reply, maps:get(Key, Opts, Value), State};
handle_call(_, _, State) ->
    {noreply, State}.

%% @hidden
handle_cast(_, State) ->
    {noreply, State}.

%% @hidden
handle_continue(connect, #state{network = Network, opts = Opts} = State) ->
    case kyu_internal:attempt({amqp_connection, start, [Network]}, Opts) of
        {ok, Connection} ->
            erlang:monitor(process, Connection),
            {noreply, State#state{connection = Connection}};
        {error, Reason} ->
            {stop, Reason, State}
    end.

%% @hidden
handle_info({'DOWN', _, process, Connection, Reason}, #state{connection = Connection} = State) ->
    {stop, Reason, State};
handle_info(_, State) ->
    {noreply, State}.

%% @hidden
terminate(_, #state{connection = undefined}) -> ok;
terminate(_, #state{connection = Connection}) ->
    case erlang:is_process_alive(Connection) of
        true -> amqp_connection:close(Connection);
        false -> ok
    end.
