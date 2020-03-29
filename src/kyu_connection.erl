%% @doc This module is responsible for creating
%% and maintaining amqp connections and channels.
-module(kyu_connection).

-behaviour(gen_server).

-export([
    child_spec/1,
    start_link/1,
    call/2,
    call/3,
    cast/2,
    where/1,
    connection/1,
    channel/1,
    network/1,
    option/3,
    await/1,
    await/2,
    subscribe/1,
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
-include("./_macros.hrl").
-include("./_defaults.hrl").
-include("./_errors.hrl").

-type name() :: term().
-type opts() :: #{
    name := name(),
    url := iodata(),
    host := iolist(),
    port := integer(),
    username := binary(),
    password := binary(),
    heartbeat := integer(),
    virtual_host := binary(),
    channel_max := integer(),
    frame_max := integer(),
    ssl_options := term(),
    client_properties := list(),
    retry_sleep := integer(),
    max_attempts := infinity | integer(),
    management := #{
        host := iodata(),
        port := integer()
    }
}.
-export_type([name/0, opts/0]).

-record(state, {
    name :: name(),
    opts :: opts(),
    network :: #amqp_params_network{},
    connection = undefined :: pid() | undefined,
    monitor = undefined :: reference() | undefined,
    timer = undefined :: reference() | undefined,
    attempts = 1
}).

%% API FUNCTIONS

%% @doc Returns a connection server child spec.
-spec child_spec(Opts :: opts()) -> supervisor:child_spec().
child_spec(#{name := Name} = Opts) ->
    #{id => ?name(connection, Name), start => {?MODULE, start_link, [Opts]}}.

%% @doc Starts a connection server.
-spec start_link(Opts :: opts()) -> {ok, pid()} | {error, term()}.
start_link(#{name := Name} = Opts) ->
    gen_server:start_link(?via(connection, Name), ?MODULE, Opts, []).

%% @doc Makes a gen_server:call/2 to the connection server.
-spec call(Name :: name(), Request :: term()) -> term().
call(Name, Request) ->
    gen_server:call(?via(connection, Name), Request).

%% @doc Makes a gen_server:call/3 to the connection server.
-spec call(Name :: name(), Request :: term(), Timeout :: timeout()) -> term().
call(Name, Request, Timeout) ->
    gen_server:call(?via(connection, Name), Request, Timeout).

%% @doc Makes a gen_server:cast/2 to the connection server.
-spec cast(Name :: name(), Request :: term()) -> ok.
cast(Name, Request) ->
    gen_server:cast(?via(connection, Name), Request).

%% @doc Returns the pid of the connection server.
%% -spec where(Name :: name()) -> pid() | undefined.
where(Name) ->
    gproc:where(?server(connection, Name)).

%% @doc Returns the underlying amqp connection.
-spec connection(Name :: name()) -> pid() | undefined.
connection(Name) ->
    call(Name, connection).

%% @doc Opens an amqp channel.
-spec channel(Name :: name()) -> {ok, pid()} | {error, term()}.
channel(Name) ->
    call(Name, channel).

%% @doc Returns the connection server's network params.
-spec network(Name :: name()) -> #amqp_params_network{}.
network(Name) ->
    call(Name, network).

%% @doc Returns a value from the connection server's options.
-spec option(Name :: name(), Key :: atom(), Value :: term()) -> term().
option(Name, Key, Value) ->
    call(Name, {option, Key, Value}).

%% @equiv kyu_connection:await(Name, 60000)
-spec await(Name :: name()) -> ok.
await(Name) ->
    await(Name, ?DEFAULT_TIMEOUT).

%% @doc Waits for the connection server to successfully connect.
-spec await(Name :: name(), Timeout :: timeout()) -> ok.
await(Name, Timeout) ->
    Server = ?server(connection, Name),
    Leftover = kyu_waitress:await(Server, Timeout),
    call(Name, await, Leftover).

%% @doc Subscribes the calling process to events from the connection server.
-spec subscribe(Name :: name()) -> ok.
subscribe(Name) ->
    gproc:reg({p, l, ?event(connection, Name)}).

%% @doc Stops the connection server.
-spec stop(Name :: name()) -> ok.
stop(Name) ->
    gen_server:stop(?via(connection, Name)).

%% CALLBACK FUNCTIONS

%% @hidden
init(#{name := Name} = Opts) ->
    lager:md([{connection, Name}]),
    lager:debug("Kyu connection server started"),
    {ok, #state{
        name = Name,
        opts = Opts,
        network = kyu_network:from(Opts)
    }, {continue, connect}}.

%% @hidden
handle_call(connection, _, #state{connection = Connection} = State) ->
    {reply, Connection, State};
handle_call(channel, _, #state{connection = undefined} = State) ->
    {reply, ?ERROR_NO_CONNECTION, State};
handle_call(channel, _, #state{connection = Connection} = State) ->
    {reply, amqp_connection:open_channel(Connection), State};
handle_call(network, _, #state{network = Network} = State) ->
    {reply, Network, State};
handle_call({option, Key, Value}, _, #state{opts = Opts} = State) ->
    {reply, maps:get(Key, Opts, Value), State};
handle_call(await, Caller, #state{name = Name, connection = undefined} = State) ->
    kyu_waitress:register(?event(connection, Name), Caller),
    {noreply, State};
handle_call(await, _, #state{connection = _} = State) ->
    {reply, ok, State};
handle_call(_, _, State) ->
    {noreply, State}.

%% @hidden
handle_cast(_, State) ->
    {noreply, State}.

%% @hidden
handle_continue(connect, #state{
    connection = undefined,
    name = Name,
    opts = Opts,
    network = Network,
    attempts = Attempts
} = State) ->
    lager:debug("Kyu connection server connecting"),
    Max = maps:get(max_attempts, Opts, ?DEFAULT_MAX_ATTEMPTS),
    case {amqp_connection:start(Network), Attempts} of
        {{ok, Connection}, _} ->
            lager:info("Kyu connection server connection up"),
            gproc:send({p, l, ?event(connection, Name)}, ?message(connection, Name, up)),
            Monitor = erlang:monitor(process, Connection),
            handle_connection(State#state{connection = Connection, monitor = Monitor, attempts = 1});
        {{error, Reason}, Max} ->
            Meta = [{reason, Reason}, {attempts, Attempts}],
            lager:info(Meta, "Kyu connection server reached max attempts"),
            {stop, Reason, State};
        {{error, Reason}, _} ->
            Meta = [{reason, Reason}, {attempts, Attempts}],
            lager:warning(Meta, "Kyu connection server connection failed"),
            handle_failure(State#state{attempts = Attempts + 1})
    end;
handle_continue(_, State) ->
    {noreply, State}.

%% @hidden
handle_info(connect, #state{connection = undefined} = State) ->
    {noreply, State, {continue, connect}};
handle_info({'DOWN', Monitor, _, _, Reason}, #state{name = Name, monitor = Monitor} = State) ->
    gproc:send({p, l, ?event(connection, Name)}, ?message(connection, Name, down)),
    lager:notice([{reason, Reason}], "Kyu connection server connection down"),
    {noreply, State#state{connection = undefined, monitor = undefined}, {continue, connect}};
handle_info(_, State) ->
    {noreply, State}.

%% @hidden
terminate(_, #state{connection = undefined}) -> ok;
terminate(_, #state{connection = Connection}) ->
    amqp_connection:close(Connection).

%% PRIVATE FUNCTIONS

handle_connection(#state{name = Name} = State) ->
    Callback = fun (Caller) -> gen_server:reply(Caller, ok) end,
    kyu_waitress:deliver(?event(connection, Name), Callback),
    {noreply, State}.

handle_failure(#state{opts = Opts} = State) ->
    Sleep = maps:get(retry_sleep, Opts, ?DEFAULT_RETRY_SLEEP),
    lager:debug("Kyu connection server retrying in ~ps", [Sleep div 1000]),
    erlang:send_after(Sleep, self(), connect),
    {noreply, State}.
