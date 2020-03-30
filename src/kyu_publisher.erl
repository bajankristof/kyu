%% @doc This module is responsible for creating
%% and managing amqp publishers.
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
-type opts() :: #{id := supervisor:child_id(), name := name(), confirms := boolean()}.
-type execution() :: sync | async | supervised.
-export_type([name/0, opts/0, execution/0]).

-record(state, {
    name :: name(),
    connection :: kyu_connection:name(),
    opts :: opts(),
    confirms = true,
    commands = [] :: list(),
    channel = undefined :: pid() | undefined,
    monitor = undefined :: reference() | undefined,
    refs = #{}
}).

-record(publish, {
    command :: #'basic.publish'{},
    props :: #'P_basic'{},
    payload :: binary(),
    execution :: execution()
}).

%% API FUNCTIONS

%% @doc Returns a publisher child spec.
-spec child_spec(Connection :: kyu_connection:name(), Opts :: map()) -> supervisor:child_spec().
child_spec(Connection, #{id := _} = Opts) ->
    #{id => maps:get(id, Opts), start => {?MODULE, start_link, [Connection, Opts]}};
child_spec(Connection, #{name := Name} = Opts) ->
    child_spec(Connection, Opts#{id => ?name(publisher, Name)}).

%% @doc Starts a publisher.
-spec start_link(Connection :: kyu_connection:name(), Opts :: map()) -> {ok, pid()} | {error, term()}.
start_link(Connection, #{name := Name} = Opts) ->
    gen_server:start_link(?via(publisher, Name), ?MODULE, {Connection, Opts}, []).

%% @doc Makes a gen_server:call/2 to the publisher.
-spec call(Name :: name(), Request :: term()) -> term().
call(Name, Request) ->
    gen_server:call(?via(publisher, Name), Request).

%% @doc Makes a gen_server:call/3 to the publisher.
-spec call(Name :: name(), Request :: term(), Timeout :: timeout()) -> term().
call(Name, Request, Timeout) ->
    gen_server:call(?via(publisher, Name), Request, Timeout).

%% @doc Makes a gen_server:cast/2 to the publisher.
-spec cast(Name :: name(), Request :: term()) -> ok.
cast(Name, Request) ->
    gen_server:cast(?via(publisher, Name), Request).

%% @doc Returns the pid of the publisher.
%% -spec where(Name :: name()) -> pid() | undefined.
where(Name) ->
    gproc:where(?server(publisher, Name)).

%% @doc Returns the name of the consumer's connection server.
-spec connection(Name :: name()) -> kyu_connection:name().
connection(Name) ->
    call(Name, connection).

%% @doc Returns the underlying amqp channel.
-spec channel(Name :: name()) -> pid() | undefined.
channel(Name) ->
    call(Name, channel).

%% @doc Returns a value from the publisher's options.
-spec option(Name :: name(), Key :: atom(), Value :: term()) -> term().
option(Name, Key, Value) ->
    call(Name, {option, Key, Value}).

%% @doc Publishes a message on the channel.
-spec publish(Name :: name(), Message :: kyu:message()) -> ok | {error, binary()}.
publish(Name, Message) ->
    true = kyu_message:validate(Message),
    Timeout = maps:get(timeout, Message, ?DEFAULT_TIMEOUT),
    call(Name, make_command(Message), Timeout).

%% @equiv kyu_publisher:await(Name, 60000)
-spec await(Name :: name()) -> ok.
await(Name) ->
    await(Name, ?DEFAULT_TIMEOUT).

%% @doc Waits for the publisher to successfully setup.
-spec await(Name :: name(), Timeout :: timeout()) -> ok.
await(Name, Timeout) ->
    Server = ?server(publisher, Name),
    Leftover = kyu_waitress:await(Server, Timeout),
    call(Name, await, Leftover).

%% @doc Stops the publisher.
-spec stop(Name :: name()) -> ok.
stop(Name) ->
    gen_server:stop(?via(publisher, Name)).

%% @hidden
-spec ref() -> binary().
ref() -> base64:encode(erlang:term_to_binary(erlang:make_ref())).

%% CALLBACK FUNCTIONS

%% @hidden
init({Connection, #{name := Name} = Opts}) ->
    lager:md([{publisher, Name}]),
    % lager:debug("Kyu publisher process started"),
    kyu_connection:subscribe(Connection),
    Commands = maps:get(commands, Opts, []),
    {ok, #state{
        name = Name,
        connection = Connection,
        commands = Commands,
        opts = Opts
    }, {continue, init}}.

%% @hidden
handle_call(connection, _, #state{connection = Connection} = State) ->
    {reply, Connection, State};
handle_call(channel, _, #state{channel = Channel} = State) ->
    {reply, Channel, State};
handle_call({option, Key, Value}, _, #state{opts = Opts} = State) ->
    {reply, maps:get(Key, Opts, Value), State};
handle_call(#publish{}, _, #state{channel = undefined} = State) ->
    {reply, ?ERROR_NO_CHANNEL, State};
handle_call(#publish{} = Command, Caller, State) ->
    handle_publish(Command, Caller, State);
handle_call(await, Caller, #state{name = Name, channel = undefined} = State) ->
    kyu_waitress:register(?event(publisher, Name), Caller),
    {noreply, State};
handle_call(await, _, #state{channel = _} = State) ->
    {reply, ok, State};
handle_call(_, _, State) ->
    {noreply, State}.

%% @hidden
handle_cast(_, State) ->
    {noreply, State}.

%% @hidden
handle_continue(init, #state{channel = undefined, connection = Connection, commands = Commands} = State) ->
    case catch kyu_connection:channel(Connection) of
        {ok, Channel} ->
            kyu:declare(Connection, Channel, Commands),
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
handle_continue({reply, Ref, Return}, #state{refs = Refs} = State) ->
    case Refs of
        #{Ref := Caller} ->
            gen_server:reply(Caller, Return),
            {noreply, State#state{refs = maps:without([Ref], Refs)}};
        _ -> {noreply, State}
    end;
handle_continue(_, State) ->
    {noreply, State}.

%% @hidden
handle_info({'DOWN', Monitor, _, _, normal}, #state{monitor = Monitor} = State) ->
    {noreply, State#state{channel = undefined, monitor = undefined}};
handle_info({'DOWN', Monitor, _, _, {_, {connection_closing, _}}}, #state{monitor = Monitor} = State) ->
    {noreply, State#state{channel = undefined, monitor = undefined}};
handle_info({'DOWN', Monitor, _, _, _}, #state{monitor = Monitor} = State) ->
    {noreply, State#state{channel = undefined, monitor = undefined}, {continue, init}};
handle_info(?message(connection, Connection, up), #state{connection = Connection} = State) ->
    {noreply, State, {continue, init}};
handle_info({#'basic.return'{reply_text = Reason}, #amqp_msg{props = #'P_basic'{message_id = Ref}}}, State) ->
    {noreply, State, {continue, {reply, Ref, {error, Reason}}}};
handle_info(#'basic.nack'{delivery_tag = Seq}, State) ->
    {noreply, State, {continue, {reply, Seq, ?ERROR_NOT_CONFIRMED}}};
handle_info(#'basic.ack'{delivery_tag = Seq}, State) ->
    {noreply, State, {continue, {reply, Seq, ok}}};
handle_info(_, State) ->
    {noreply, State}.

%% @hidden
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
handle_publish(#publish{execution = sync} = Command, Caller, #state{channel = Channel} = State) ->
    Refs = State#state.refs,
    Seq = amqp_channel:next_publish_seqno(Channel),
    ok = erlang:apply(amqp_channel, call, make_args(Command, State)),
    {noreply, State#state{refs = Refs#{Seq => Caller}}};
handle_publish(#publish{execution = supervised} = Command, Caller, #state{channel = Channel} = State) ->
    Ref = ref(),
    Refs = State#state.refs,
    Supervised = make_supervised(Command, Ref),
    Seq = amqp_channel:next_publish_seqno(Channel),
    ok = erlang:apply(amqp_channel, call, make_args(Supervised, State)),
    {noreply, State#state{refs = Refs#{Ref => Caller, Seq => Caller}}}.

make_args(#publish{command = Command, props = Props, payload = Payload}, #state{channel = Channel}) ->
    [Channel, Command, #amqp_msg{props = Props, payload = Payload}].

make_supervised(#publish{props = Props} = Command, Key) ->
    Command#publish{props = Props#'P_basic'{message_id = Key}}.

make_command(Message) ->
    #publish{
        command = #'basic.publish'{
            routing_key = maps:get(routing_key, Message, <<>>),
            exchange = maps:get(exchange, Message, <<>>),
            mandatory = maps:get(mandatory, Message, false)
        },
        props = kyu_message:props(Message),
        payload = maps:get(payload, Message, <<>>),
        execution = maps:get(execution, Message, sync)
    }.
