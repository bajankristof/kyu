%% @doc This module is responsible for creating
%% and maintaining amqp channels.
-module(kyu_channel).

-behaviour(gen_server).

-export([
    child_spec/2,
    start_link/2,
    call/2,
    call/3,
    cast/2,
    where/1,
    pid/1,
    status/1,
    connection/1,
    option/2,
    option/3,
    apply/3,
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
-type opts() :: #{id := supervisor:child_id(), name := name()}.
-export_types([name/0, opts/0]).

-record(state, {
    name :: name(),
    connection :: kyu_connection:name(),
    opts :: opts(),
    channel = undefined :: undefined | pid(),
    monitor = undefined :: undefined | reference()
}).

%% @doc Returns a channel child spec.
-spec child_spec(Connection :: kyu_connection:name(), Opts :: opts()) -> supervisor:child_spec().
child_spec(Connection, #{id := _} = Opts) ->
    #{id => maps:get(id, Opts), start => {?MODULE, start_link, [Connection, Opts]}};
child_spec(Connection, #{name := Name} = Opts) ->
    child_spec(Connection, Opts#{id => ?name(channel, Name)}).

%% @doc Starts a channel.
-spec start_link(Connection :: kyu_connection:name(), Opts :: opts()) -> {ok, pid()} | {error, term()}.
start_link(Connection, #{name := Name} = Opts) ->
    gen_server:start_link(?via(channel, Name), ?MODULE, {Connection, Opts}, []).

%% @doc Makes a gen_server:call/2 to the channel.
-spec call(Name :: name(), Request :: term()) -> term().
call(Name, Request) ->
    gen_server:call(?via(channel, Name), Request).

%% @doc Makes a gen_server:call/3 to the channel.
-spec call(Name :: name(), Request :: term(), Timeout :: timeout()) -> term().
call(Name, Request, Timeout) ->
    gen_server:call(?via(channel, Name), Request, Timeout).

%% @doc Makes a gen_server:cast/2 to the channel.
-spec cast(Name :: name(), Request :: term()) -> ok.
cast(Name, Request) ->
    gen_server:cast(?via(channel, Name), Request).

%% @doc Returns the pid of the channel.
%% -spec where(Name :: name()) -> pid() | undefined.
where(Name) ->
    gproc:where(?server(channel, Name)).

%% @doc Returns the pid of the underlying amqp channel.
-spec pid(Name :: name()) -> pid() | undefined.
pid(Name) ->
    call(Name, pid).

%% @doc Returns the up atom if the process is running and has an active channel.
-spec status(Name :: name()) -> up | down.
status(Name) ->
    case catch call(Name, status) of
        {'EXIT', {noproc, _}} -> down;
        Status -> Status
    end.

%% @doc Returns the name of the channel's connection.
-spec connection(Name :: name()) -> kyu_connection:name().
connection(Name) ->
    call(Name, connection).

%% @equiv kyu_channel:option(Name, Key, undefined)
-spec option(Name :: name(), Key :: atom()) -> term().
option(Name, Key) ->
    option(Name, Key, undefined).

%% @doc Returns a value from the channel's options.
-spec option(Name :: name(), Key :: atom(), Value :: term()) -> term().
option(Name, Key, Value) ->
    call(Name, {option, Key, Value}).

%% @doc Calls a function on the underlying amqp channel.
-spec apply(Name :: name(), Function :: atom(), Args :: list()) -> term().
apply(Name, Function, Args) ->
    Channel = pid(Name),
    erlang:apply(amqp_channel, Function, [Channel] ++ Args).

%% @equiv kyu_channel:await(Name, 60000)
-spec await(Name :: name()) -> ok.
await(Name) ->
    await(Name, ?DEFAULT_TIMEOUT).

%% @doc Waits for the channel to successfully setup.
-spec await(Name :: name(), Timeout :: timeout()) -> ok.
await(Name, Timeout) ->
    Server = ?server(channel, Name),
    Leftover = kyu_waitress:await(Server, Timeout),
    call(Name, await, Leftover).

%% @doc Subscribes the calling process to events from the channel.
-spec subscribe(Name :: name()) -> ok.
subscribe(Name) ->
    gproc:reg({p, l, ?event(channel, Name)}).

%% @doc Gracefully closes the channel.
-spec stop(Name :: name()) -> ok.
stop(Name) ->
    gen_server:stop(?via(channel, Name)).

%% @hidden
init({Connection, #{name := Name} = Opts}) ->
    lager:md([{channel, Name}]),
    % lager:debug("Kyu channel process started"),
    kyu_connection:subscribe(Connection),
    {ok, #state{
        name = Name,
        connection = Connection,
        opts = Opts
    }, {continue, init}}.

%% @hidden
handle_call(pid, _, #state{channel = Channel} = State) ->
    {reply, Channel, State};
handle_call(status, _, #state{channel = undefined} = State) ->
    {reply, down, State};
handle_call(status, _, #state{channel = _} = State) ->
    {reply, up, State};
handle_call(connection, _, #state{connection = Connection} = State) ->
    {reply, Connection, State};
handle_call({option, Key, Value}, _, #state{opts = Opts} = State) ->
    {reply, maps:get(Key, Opts, Value), State};
handle_call(await, Caller, #state{name = Name, channel = undefined} = State) ->
    kyu_waitress:register(?event(channel, Name), Caller),
    {noreply, State};
handle_call(await, _, #state{channel = _} = State) ->
    {reply, ok, State};
handle_call(_, _, State) ->
    {noreply, State}.

%% @hidden
handle_cast(_, State) ->
    {noreply, State}.

%% @hidden
handle_continue(init, #state{connection = Connection, channel = undefined} = State) ->
    case kyu_connection:status(Connection) of
        up ->
            {ok, Channel} = kyu_connection:apply(Connection, open_channel, []),
            Monitor = erlang:monitor(process, Channel),
            {noreply, State#state{
                channel = Channel,
                monitor = Monitor
            }, {continue, {init, fin}}};
        down -> {noreply, State}
    end;
handle_continue({init, fin}, #state{name = Name} = State) ->
    Callback = fun (Caller) -> gen_server:reply(Caller, ok) end,
    kyu_waitress:deliver(?event(channel, Name), Callback),
    gproc:send({p, l, ?event(channel, Name)}, ?message(channel, Name, up)),
    {noreply, State};
handle_continue(_, State) ->
    {noreply, State}.

%% @hidden
handle_info({'DOWN', Monitor, _, _, Shutdown}, #state{name = Name, monitor = Monitor} = State) ->
    gproc:send({p, l, ?event(channel, Name)}, ?message(channel, Name, down)),
    case Shutdown of
        {_, {_, connection_closing, _}} ->
            {noreply, State#state{channel = undefined, monitor = undefined}};
        normal -> {noreply, State#state{channel = undefined, monitor = undefined}};
        _ -> {noreply, State#state{channel = undefined, monitor = undefined}, {continue, init}}
    end;
handle_info(?message(connection, Connection, up), #state{connection = Connection} = State) ->
    {noreply, State, {continue, init}};
handle_info(?message(connection, Connection, down), #state{connection = Connection} = State) ->
    {noreply, State};
handle_info(Info, State) ->
    lager:warning("Kyu channel received unrecognizable info~n~p", [Info]),
    {noreply, State}.

%% @hidden
terminate(_, #state{channel = undefined}) -> ok;
terminate(_, #state{channel = Channel}) ->
    amqp_channel:close(Channel).
