%% @hidden
-module(kyu_wrangler).

-behaviour(gen_server).

-export([
    child_spec/2,
    start_link/2,
    call/2,
    call/3,
    cast/2,
    where/1,
    connection/1,
    channel/1,
    queue/1,
    await/1,
    await/2
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

-record(state, {
    name :: kyu_consumer:name(),
    connection :: kyu_connection:name(),
    opts :: kyu_consumer:opts(),
    commands :: list(),
    queue :: binary(),
    channel = undefined :: undefined | pid(),
    monitor = undefined :: undefined | reference(),
    tag = undefined
}).

%% API FUNCTIONS

-spec child_spec(
    Connection :: kyu_connection:name(),
    Opts :: kyu_consumer:opts()
) -> supervisor:child_spec().
child_spec(Connection, #{name := Name} = Opts) ->
    #{id => ?name(wrangler, Name), start => {?MODULE, start_link, [Connection, Opts]}}.

-spec start_link(
    Connection :: kyu_connection:name(),
    Opts :: kyu_consumer:opts()
) -> {ok, pid()} | {error, term()}.
start_link(Connection, #{name := Name} = Opts) ->
    gen_server:start_link(?via(wrangler, Name), ?MODULE, {Connection, Opts}, []).

-spec call(Name :: kyu_consumer:name(), Request :: term()) -> term().
call(Name, Request) ->
    gen_server:call(?via(wrangler, Name), Request).

-spec call(Name :: kyu_consumer:name(), Request :: term(), Timeout :: timeout()) -> term().
call(Name, Request, Timeout) ->
    gen_server:call(?via(wrangler, Name), Request, Timeout).

-spec cast(Name :: kyu_consumer:name(), Request :: term()) -> ok.
cast(Name, Request) ->
    gen_server:cast(?via(wrangler, Name), Request).

%% -spec where(Name :: kyu_consumer:name()) -> pid() | undefined.
where(Name) ->
    gproc:where(?server(wrangler, Name)).

-spec connection(Name :: kyu_consumer:name()) -> term().
connection(Name) ->
    call(Name, connection).

-spec channel(Name :: kyu_consumer:name()) -> pid() | undefined.
channel(Name) ->
    call(Name, channel).

-spec queue(Name :: kyu_consumer:name()) -> binary().
queue(Name) ->
    call(Name, queue).

-spec await(Name :: kyu_consumer:name()) -> ok.
await(Name) ->
    await(Name, ?DEFAULT_TIMEOUT).

-spec await(Name :: kyu_consumer:name(), Timeout :: timeout()) -> ok.
await(Name, Timeout) ->
    Server = ?server(wrangler, Name),
    Leftover = kyu_waitress:await(Server, Timeout),
    call(Name, await, Leftover).

%% CALLBACK FUNCTIONS

init({Connection, #{name := Name, queue := Queue} = Opts}) ->
    lager:md([{wrangler, Name}]),
    lager:debug("Kyu wrangler process started"),
    kyu_connection:subscribe(Connection),
    Commands = maps:get(commands, Opts, []),
    {ok, #state{
        name = Name,
        connection = Connection,
        opts = Opts,
        commands = Commands,
        queue = Queue
    }, {continue, init}}.

handle_call(connection, _, #state{connection = Connection} = State) ->
    {reply, Connection, State};
handle_call(channel, _, #state{channel = Channel} = State) ->
    {reply, Channel, State};
handle_call(queue, _, #state{queue = Queue} = State) ->
    {reply, Queue, State};
handle_call(await, Caller, #state{name = Name, channel = undefined} = State) ->
    kyu_waitress:register(?event(wrangler, Name), Caller),
    {noreply, State};
handle_call(await, _, #state{channel = _} = State) ->
    {reply, ok, State};
handle_call(_, _, #state{channel = undefined} = State) ->
    {reply, ?ERROR_NO_CHANNEL, State};
handle_call({ack, Tag}, _, #state{channel = Channel} = State) ->
    ok = amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
    {reply, ok, State};
handle_call({reject, Tag}, _, #state{channel = Channel} = State) ->
    ok = amqp_channel:cast(Channel, #'basic.reject'{delivery_tag = Tag}),
    {reply, ok, State};
handle_call({remove, Tag}, _, #state{channel = Channel} = State) ->
    ok = amqp_channel:cast(Channel, #'basic.reject'{delivery_tag = Tag, requeue = false}),
    {reply, ok, State};
handle_call(_, _, State) ->
    {noreply, State}.

handle_cast(_, #state{channel = undefined} = State) ->
    {noreply, State};
handle_cast({ack, Tag}, #state{channel = Channel} = State) ->
    ok = amqp_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
    {noreply, State};
handle_cast({reject, Tag}, #state{channel = Channel} = State) ->
    ok = amqp_channel:cast(Channel, #'basic.reject'{delivery_tag = Tag}),
    {noreply, State};
handle_cast({remove, Tag}, #state{channel = Channel} = State) ->
    ok = amqp_channel:cast(Channel, #'basic.reject'{delivery_tag = Tag, requeue = false}),
    {noreply, State};
handle_cast(_, State) ->
    {noreply, State}.

handle_continue(init, #state{channel = undefined, connection = Connection, commands = Commands} = State) ->
    case catch kyu_connection:channel(Connection) of
        {ok, Channel} ->
            kyu:declare(Connection, Channel, Commands),
            Monitor = erlang:monitor(process, Channel),
            Next = State#state{channel = Channel, monitor = Monitor},
            {noreply, Next, {continue, {init, prefetch}}};
        {'EXIT', {noproc, _}} -> {noreply, State};
        ?ERROR_NO_CONNECTION -> {noreply, State};
        Reason -> {stop, Reason, State}
    end;
handle_continue({init, prefetch}, #state{channel = Channel, opts = Opts} = State) ->
    Count = maps:get(worker_count, Opts, 1),
    Prefetch = maps:get(prefetch_count, Opts, 1),
    Command = #'basic.qos'{prefetch_count = Count * Prefetch},
    #'basic.qos_ok'{} = amqp_channel:call(Channel, Command),
    {noreply, State, {continue, {init, consume}}};
handle_continue({init, consume}, #state{channel = Channel, queue = Queue} = State) ->
    Command = #'basic.consume'{queue = Queue},
    #'basic.consume_ok'{consumer_tag = Tag} = amqp_channel:call(Channel, Command),
    {noreply, State#state{tag = Tag}, {init, fin}};
handle_continue({init, fin}, #state{name = Name} = State) ->
    Callback = fun (Caller) -> gen_server:reply(Caller, ok) end,
    kyu_waitress:deliver(?event(wrangler, Name), Callback),
    {noreply, State};
handle_continue(_, State) ->
    {noreply, State}.

handle_info({#'basic.deliver'{} = Command, Content}, State) ->
    Worker = maps:get(name, State#state.opts),
    #'basic.deliver'{delivery_tag = Tag, routing_key = Key} = Command,
    ok = kyu_worker:message(Worker, {message, Tag, Key, Content}),
    {noreply, State};
handle_info({'DOWN', Monitor, _, _, normal}, #state{monitor = Monitor} = State) ->
    {noreply, State#state{channel = undefined, monitor = undefined}};
handle_info({'DOWN', Monitor, _, _, {_, {connection_closing, _}}}, #state{monitor = Monitor} = State) ->
    {noreply, State#state{channel = undefined, monitor = undefined}};
handle_info({'DOWN', Monitor, _, _, _}, #state{monitor = Monitor} = State) ->
    {noreply, State#state{channel = undefined, monitor = undefined}, {continue, init}};
handle_info(?message(connection, Connection, up), #state{connection = Connection} = State) ->
    {noreply, State, {continue, init}};
handle_info(_, State) ->
    {noreply, State}.

terminate(_, #state{channel = undefined}) -> ok;
terminate(_, #state{channel = Channel, tag = undefined}) ->
    amqp_channel:close(Channel);
terminate(_, #state{channel = Channel, tag = Tag}) ->
    amqp_channel:call(Channel, #'basic.cancel'{consumer_tag = Tag}),
    amqp_channel:close(Channel).
