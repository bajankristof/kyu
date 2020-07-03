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
    channel :: kyu_channel:name(),
    queue :: binary(),
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

-spec connection(Name :: kyu_consumer:name()) -> kyu_connection:name().
connection(Name) ->
    call(Name, connection).

-spec channel(Name :: kyu_consumer:name()) -> kyu_channel:name().
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

init({Connection, #{name := Name} = Opts}) ->
    lager:md([{wrangler, Name}]),
    % lager:debug("Kyu wrangler process started"),
    {ok, #state{
        name = Name,
        connection = Connection,
        opts = Opts,
        channel = maps:get(channel, Opts, {self(), Name}),
        queue = maps:get(queue, Opts)
    }, {continue, init}}.

handle_call(connection, _, #state{connection = Connection} = State) ->
    {reply, Connection, State};
handle_call(channel, _, #state{channel = Channel} = State) ->
    {reply, Channel, State};
handle_call(queue, _, #state{queue = Queue} = State) ->
    {reply, Queue, State};
handle_call(await, Caller, #state{name = Name, channel = Channel} = State) ->
    case kyu_channel:pid(Channel) of
        undefined ->
            kyu_waitress:register(?event(wrangler, Name), Caller),
            {noreply, State};
        _ -> {reply, ok, State}
    end;
handle_call({ack, Tag}, _, #state{channel = Channel} = State) ->
    ok = kyu_channel:apply(Channel, cast, [#'basic.ack'{delivery_tag = Tag}]),
    {reply, ok, State};
handle_call({reject, Tag}, _, #state{channel = Channel} = State) ->
    ok = kyu_channel:apply(Channel, cast, [#'basic.reject'{delivery_tag = Tag}]),
    {reply, ok, State};
handle_call({remove, Tag}, _, #state{channel = Channel} = State) ->
    ok = kyu_channel:apply(Channel, cast, [#'basic.reject'{delivery_tag = Tag, requeue = false}]),
    {reply, ok, State};
handle_call(_, _, State) ->
    {noreply, State}.

handle_cast({ack, Tag}, #state{channel = Channel} = State) ->
    ok = kyu_channel:apply(Channel, cast, [#'basic.ack'{delivery_tag = Tag}]),
    {noreply, State};
handle_cast({reject, Tag}, #state{channel = Channel} = State) ->
    ok = kyu_channel:apply(Channel, cast, [#'basic.reject'{delivery_tag = Tag}]),
    {noreply, State};
handle_cast({remove, Tag}, #state{channel = Channel} = State) ->
    ok = kyu_channel:apply(Channel, cast, [#'basic.reject'{delivery_tag = Tag, requeue = false}]),
    {noreply, State};
handle_cast(_, State) ->
    {noreply, State}.

handle_continue(init, #state{opts = #{channel := Channel}} = State) ->
    kyu_channel:subscribe(Channel),
    {noreply, State};
handle_continue(init, #state{connection = Connection, channel = Channel, opts = Opts} = State) ->
    true = kyu_channel:subscribe(Channel),
    {ok, _} = kyu_channel:start_link(Connection, Opts#{name => Channel}),
    {noreply, State};
handle_continue({init, prefetch}, #state{channel = Channel, opts = Opts} = State) ->
    Count = maps:get(worker_count, Opts, 1),
    Prefetch = maps:get(prefetch_count, Opts, 1),
    Command = #'basic.qos'{prefetch_count = Count * Prefetch},
    #'basic.qos_ok'{} = kyu_channel:apply(Channel, call, [Command]),
    {noreply, State, {continue, {init, consume}}};
handle_continue({init, consume}, #state{channel = Channel, queue = Queue} = State) ->
    Command = #'basic.consume'{queue = Queue},
    #'basic.consume_ok'{consumer_tag = Tag} = kyu_channel:apply(Channel, call, [Command]),
    {noreply, State#state{tag = Tag}, {init, fin}};
handle_continue({init, fin}, #state{name = Name} = State) ->
    Callback = fun (Caller) -> gen_server:reply(Caller, ok) end,
    kyu_waitress:deliver(?event(wrangler, Name), Callback),
    {noreply, State};
handle_continue(_, State) ->
    {noreply, State}.

handle_info({#'basic.deliver'{} = Command, Content}, #state{name = Name} = State) ->
    #'basic.deliver'{delivery_tag = Tag, routing_key = Key} = Command,
    ok = kyu_worker:message(Name, {message, Tag, Key, Content}),
    {noreply, State};
handle_info(?message(channel, Channel, up), #state{channel = Channel, opts = Opts} = State) ->
    ok = kyu:declare(Channel, maps:get(commands, Opts, [])),
    {noreply, State, {continue, {init, prefetch}}};
handle_info(?message(channel, Channel, down), #state{channel = Channel} = State) ->
    {noreply, State};
handle_info(Info, State) ->
    lager:warning("Kyu wrangler received unrecognizable info~n~p", [Info]),
    {noreply, State}.

terminate(_, #state{channel = Channel, tag = Tag}) ->
    Command = #'basic.cancel'{consumer_tag = Tag},
    #'basic.cancel_ok'{} = kyu_channel:apply(Channel, call, [Command]),
    ok.
