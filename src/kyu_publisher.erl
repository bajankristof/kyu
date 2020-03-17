-module(kyu_publisher).

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
    option/3,
    publish/2,
    await/1,
    await/2,
    stop/1,
    ref/0
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
-type opts() :: #{name := name(), confirms := boolean()}.
-type execution() :: sync | async | supervised.
-export_type([name/0, opts/0, execution/0]).

-record(state, {
    name :: name(),
    connection :: kyu_connection:name(),
    opts :: opts(),
    confirms = true,
    commands = [] :: list(),
    channel = undefined :: pid() | undefined,
    monitor = undefined :: reference() | undefined
}).

-record(publish, {
    command :: #'basic.publish'{},
    props :: #'P_basic'{},
    payload :: binary(),
    execution :: execution(),
    timeout :: integer()
}).

%% API FUNCTIONS

-spec child_spec(Connection :: kyu_connection:name(), Opts :: map()) -> supervisor:child_spec().
child_spec(Connection, #{name := Name} = Opts) ->
    #{id => ?name(publisher, Name), start => {?MODULE, start_link, [Connection, Opts]}}.

-spec start_link(Connection :: kyu_connection:name(), Opts :: map()) -> {ok, pid()} | {error, term()}.
start_link(Connection, #{name := Name} = Opts) ->
    gen_server:start_link(?via(publisher, Name), ?MODULE, {Connection, Opts}, []).

-spec call(Name :: name(), Request :: term()) -> term().
call(Name, Request) ->
    gen_server:call(?via(publisher, Name), Request).

-spec call(Name :: name(), Request :: term(), Timeout :: timeout()) -> term().
call(Name, Request, Timeout) ->
    gen_server:call(?via(publisher, Name), Request, Timeout).

-spec cast(Name :: name(), Request :: term()) -> ok.
cast(Name, Request) ->
    gen_server:cast(?via(publisher, Name), Request).

%% -spec where(Name :: name()) -> pid() | undefined.
where(Name) ->
    gproc:where(?server(publisher, Name)).

-spec connection(Name :: name()) -> kyu_connection:name().
connection(Name) ->
    call(Name, connection).

-spec channel(Name :: name()) -> pid() | undefined.
channel(Name) ->
    call(Name, channel).

-spec option(Name :: name(), Key :: atom(), Value :: term()) -> term().
option(Name, Key, Value) ->
    call(Name, {option, Key, Value}).

-spec publish(Name :: name(), Message :: kyu:message()) -> ok | {error, binary()}.
publish(Name, Message) ->
    call(Name, make_command(Message)).

-spec await(Name :: name()) -> ok.
await(Name) ->
    await(Name, ?DEFAULT_TIMEOUT).

-spec await(Name :: name(), Timeout :: timeout()) -> ok.
await(Name, Timeout) ->
    Server = ?server(publisher, Name),
    Leftover = kyu_waitress:await(Server, Timeout),
    call(Name, await, Leftover).

-spec stop(Name :: name()) -> ok.
stop(Name) ->
    gen_server:stop(?via(publisher, Name)).

-spec ref() -> binary().
ref() -> base64:encode(erlang:term_to_binary(erlang:make_ref())).

%% CALLBACK FUNCTIONS

init({Connection, #{name := Name} = Opts}) ->
    lager:md([{publisher, Name}]),
    lager:debug("Kyu publisher process started"),
    kyu_connection:subscribe(Connection),
    Commands = maps:get(commands, Opts, []),
    {ok, #state{
        name = Name,
        connection = Connection,
        commands = Commands,
        opts = Opts
    }, {continue, init}}.

handle_call(connection, _, #state{connection = Connection} = State) ->
    {reply, Connection, State};
handle_call(channel, _, #state{channel = Channel} = State) ->
    {reply, Channel, State};
handle_call({option, Key, Value}, _, #state{opts = Opts} = State) ->
    {reply, maps:get(Key, Opts, Value), State};
handle_call(#publish{}, _, #state{channel = undefined} = State) ->
    {reply, ?ERROR_NO_CHANNEL, State};
handle_call(#publish{} = Command, {Caller, _}, State) ->
    handle_publish(Command, Caller, State);
handle_call(await, Caller, #state{name = Name, channel = undefined} = State) ->
    kyu_waitress:register(?event(publisher, Name), Caller),
    {noreply, State};
handle_call(await, _, #state{channel = _} = State) ->
    {reply, ok, State};
handle_call(_, _, State) ->
    {noreply, State}.

handle_cast(_, State) ->
    {noreply, State}.

handle_continue(init, #state{channel = undefined, connection = Connection, commands = Commands} = State) ->
    case catch kyu_connection:channel(Connection, Commands) of
        {ok, Channel} ->
            amqp_channel:register_return_handler(Channel, self()),
            Monitor = erlang:monitor(process, Channel),
            Next = State#state{channel = Channel, monitor = Monitor},
            {noreply, Next, {continue, {init, confirms}}};
        {'EXIT', {noproc, _}} -> {noreply, State};
        ?ERROR_NO_CONNECTION -> {noreply, State};
        Reason -> {stop, Reason, State}
    end;
handle_continue({init, confirms}, #state{channel = Channel, confirms = true} = State) ->
    #'confirm.select_ok'{} = amqp_channel:call(Channel, #'confirm.select'{}),
    amqp_channel:register_confirm_handler(Channel, self()),
    {noreply, State, {continue, {init, fin}}};
handle_continue({init, confirms}, #state{confirms = false} = State) ->
    {noreply, State, {continue, {init, fin}}};
handle_continue({init, fin}, #state{name = Name} = State) ->
    Callback = fun (Caller) -> gen_server:reply(Caller, ok) end,
    kyu_waitress:deliver(?event(publisher, Name), Callback),
    {noreply, State};
handle_continue(_, State) ->
    {noreply, State}.

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
terminate(_, #state{channel = Channel}) ->
    amqp_channel:close(Channel).

%% PRIVATE FUNCTIONS

handle_publish(#publish{} = Command, _, #state{confirms = false} = State) ->
    ok = erlang:apply(amqp_channel, cast, make_args(Command, State)),
    {reply, ok, State};
handle_publish(#publish{execution = async} = Command, _, #state{} = State) ->
    ok = erlang:apply(amqp_channel, cast, make_args(Command, State)),
    {reply, ok, State};
handle_publish(#publish{execution = sync} = Command, _, #state{channel = Channel} = State) ->
    Timeout = Command#publish.timeout,
    ok = erlang:apply(amqp_channel, call, make_args(Command, State)),
    case amqp_channel:wait_for_confirms(Channel, Timeout) of
        timeout -> {reply, ?ERROR_TIMEOUT, State};
        true -> {reply, ok, State}
    end;
handle_publish(#publish{execution = supervised} = Command, _, #state{channel = Channel} = State) ->
    Ref = ref(),
    Supervised = make_supervised(Command, Ref),
    Seq = amqp_channel:next_publish_seqno(Channel),
    ok = erlang:apply(amqp_channel, call, make_args(Supervised, State)),
    erlang:send_after(Command#publish.timeout, self(), {timeout, Ref}),
    receive
        {#'basic.return'{reply_text = Reason},
            #amqp_msg{props = #'P_basic'{message_id = Ref}}} ->
            {reply, {error, Reason}, State};
        #'basic.nack'{delivery_tag = Seq} ->
            {reply, ?ERROR_NOT_CONFIRMED, State};
        #'basic.ack'{delivery_tag = Seq} ->
            {reply, ok, State};
        {timeout, Ref} ->
            ?ERROR_TIMEOUT
    end.

make_args(#publish{command = Command, props = Props, payload = Payload}, #state{channel = Channel}) ->
    [Channel, Command, #amqp_msg{props = Props, payload = Payload}].

make_supervised(#publish{props = Props} = Command, Key) ->
    Command#publish{props = update_props(Props, #{message_id => Key})}.

make_command(Message) ->
    #publish{
        command = #'basic.publish'{
            mandatory = maps:get(mandatory, Message, false),
            exchange = maps:get(exchange, Message, <<>>),
            routing_key = maps:get(routing_key, Message, <<>>)
        },
        props = make_props(Message),
        payload = maps:get(payload, Message, <<>>),
        execution = maps:get(execution, Message, sync),
        timeout = maps:get(timeout, Message, ?DEFAULT_TIMEOUT)
    }.

make_props(Message) ->
    update_props(#'P_basic'{}, Message).

update_props(#'P_basic'{} = Props, Message) ->
    maps:fold(fun
        (headers, Value, Acc) -> Acc#'P_basic'{headers = Value};
        (priority, Value, Acc) -> Acc#'P_basic'{priority = Value};
        (expiration, Value, Acc) -> Acc#'P_basic'{expiration = Value};
        (content_type, Value, Acc) -> Acc#'P_basic'{content_type = Value};
        (content_encoding, Value, Acc) -> Acc#'P_basic'{content_encoding = Value};
        (delivery_mode, Value, Acc) -> Acc#'P_basic'{delivery_mode = Value};
        (correlation_id, Id, Acc) -> Acc#'P_basic'{correlation_id = Id};
        (message_id, Id, Acc) -> Acc#'P_basic'{message_id = Id};
        (user_id, Id, Acc) -> Acc#'P_basic'{user_id = Id};
        (app_id, Id, Acc) -> Acc#'P_basic'{app_id = Id};
        (reply_to, Value, Acc) -> Acc#'P_basic'{reply_to = Value};
        (_, _, Acc) -> Acc
    end, Props, Message).
