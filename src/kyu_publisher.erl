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
    status/1,
    connection/1,
    channel/1,
    option/3,
    publish/2,
    await/1,
    await/2,
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
    id := supervisor:child_id(),
    name := name(),
    channel := kyu_channel:name(),
    confirms := boolean()
}.
-type execution() :: sync | async | supervised.
-export_type([name/0, opts/0, execution/0]).

-record(state, {
    name :: name(),
    connection :: kyu_connection:name(),
    opts :: opts(),
    channel :: kyu_channel:name(),
    monitor = undefined :: reference(),
    status = down :: up | down,
    tags = #{}
}).

-record(publish, {
    command :: #'basic.publish'{},
    props :: #'P_basic'{},
    payload :: binary(),
    execution :: execution()
}).

%% API FUNCTIONS

%% @doc Returns a publisher child spec.
-spec child_spec(Connection :: kyu_connection:name(), Opts :: opts()) -> supervisor:child_spec().
child_spec(Connection, #{id := _} = Opts) ->
    #{id => maps:get(id, Opts), start => {?MODULE, start_link, [Connection, Opts]}};
child_spec(Connection, #{name := Name} = Opts) ->
    child_spec(Connection, Opts#{id => ?name(publisher, Name)}).

%% @doc Starts a publisher.
-spec start_link(Connection :: kyu_connection:name(), Opts :: opts()) -> {ok, pid()} | {error, term()}.
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

%% @doc Returns the up atom if the publisher is running and has an active channel.
-spec status(Name :: name()) -> up | down.
status(Name) ->
    case catch call(Name, status) of
        {'EXIT', {noproc, _}} -> down;
        Status -> Status
    end.

%% @doc Returns the name of the publisher's connection.
-spec connection(Name :: name()) -> kyu_connection:name().
connection(Name) ->
    call(Name, connection).

%% @doc Returns the name of the publisher's channel.
-spec channel(Name :: name()) -> kyu_channel:name().
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

%% @doc Gracefully stops the publisher.
-spec stop(Name :: name()) -> ok.
stop(Name) ->
    gen_server:stop(?via(publisher, Name)).

%% CALLBACK FUNCTIONS

%% @hidden
init({Connection, #{name := Name} = Opts}) ->
    {ok, #state{
        name = Name,
        connection = Connection,
        opts = Opts,
        channel = maps:get(channel, Opts, erlang:make_ref())
    }, {continue, init}}.

%% @hidden
handle_call(status, _, #state{status = Status} = State) ->
    {reply, Status, State};
handle_call(connection, _, #state{connection = Connection} = State) ->
    {reply, Connection, State};
handle_call(channel, _, #state{channel = Channel} = State) ->
    {reply, Channel, State};
handle_call({option, Key, Value}, _, #state{opts = Opts} = State) ->
    {reply, maps:get(Key, Opts, Value), State};
handle_call(#publish{}, _, #state{status = down} = State) ->
    {reply, ?ERROR_NO_CHANNEL, State};
handle_call(#publish{} = Command, Caller, #state{} = State) ->
    handle_publish(Command, Caller, State);
handle_call(await, _, #state{status = up} = State) ->
    {reply, ok, State};
handle_call(await, Caller, #state{name = Name} = State) ->
    kyu_waitress:register(?event(publisher, Name), Caller),
    {noreply, State};
handle_call(_, _, State) ->
    {noreply, State}.

%% @hidden
handle_cast(_, State) ->
    {noreply, State}.

%% @hidden
handle_continue(init, #state{opts = #{channel := Channel}} = State) ->
    true = kyu_channel:subscribe(Channel),
    case kyu_channel:status(Channel) of
        up -> self() ! ?message(channel, Channel, up);
        down -> ok
    end,
    {noreply, State};
handle_continue(init, #state{connection = Connection, channel = Channel} = State) ->
    true = kyu_channel:subscribe(Channel),
    {ok, _} = kyu_channel:start_link(Connection, #{name => Channel}),
    {noreply, State};
handle_continue({init, _}, #state{status = down} = State) ->
    {noreply, State};
handle_continue({init, confirms}, #state{opts = #{confirms := false}} = State) ->
    {noreply, State, {continue, {init, fin}}};
handle_continue({init, confirms}, #state{channel = Channel} = State) ->
    #'confirm.select_ok'{} = kyu_channel:apply(Channel, call, [#'confirm.select'{}]),
    kyu_channel:apply(Channel, register_confirm_handler, [self()]),
    {noreply, State, {continue, {init, fin}}};
handle_continue({init, fin}, #state{name = Name} = State) ->
    Callback = fun (Caller) -> gen_server:reply(Caller, ok) end,
    kyu_waitress:deliver(?event(publisher, Name), Callback),
    {noreply, State};
handle_continue({reply, Tag, Return}, #state{tags = Tags} = State) ->
    case maps:get(Tag, Tags, undefined) of
        undefined -> {noreply, State};
        Caller ->
            gen_server:reply(Caller, Return),
            {noreply, State#state{tags = maps:without([Tag], Tags)}}
    end;
handle_continue(_, State) ->
    {noreply, State}.

%% @hidden
handle_info({#'basic.return'{reply_text = Text}, #amqp_msg{props = #'P_basic'{message_id = Tag}}}, State) ->
    {noreply, State, {continue, {reply, Tag, {error, Text}}}};
handle_info(#'basic.nack'{delivery_tag = Seq}, State) ->
    {noreply, State, {continue, {reply, Seq, ?ERROR_NOT_CONFIRMED}}};
handle_info(#'basic.ack'{delivery_tag = Seq}, State) ->
    {noreply, State, {continue, {reply, Seq, ok}}};
handle_info(?message(channel, Channel, up), #state{channel = Channel, status = up} = State) ->
    {noreply, State};
handle_info(?message(channel, Channel, up), #state{channel = Channel, opts = Opts} = State) ->
    Monitor = erlang:monitor(process, kyu_channel:pid(Channel)),
    ok = kyu:declare(Channel, maps:get(commands, Opts, [])),
    kyu_channel:apply(Channel, register_return_handler, [self()]),
    {noreply, State#state{monitor = Monitor, status = up}, {continue, {init, confirms}}};
handle_info(?message(channel, Channel, down), #state{channel = Channel} = State) ->
    {noreply, State#state{status = down}};
handle_info({'DOWN', Monitor, _, _, _}, #state{monitor = Monitor} = State) ->
    {noreply, State#state{status = down}};
handle_info(_, State) ->
    {noreply, State}.

%% @hidden
terminate(_, #state{channel = Channel, status = up}) ->
    kyu_channel:apply(Channel, unregister_return_handler, []),
    kyu_channel:apply(Channel, unregister_confirm_handler, []);
terminate(_, _) -> ok.

%% PRIVATE FUNCTIONS

%% @hidden
handle_publish(#publish{} = Command, _, #state{channel = Channel, opts = #{confirms := false}} = State) ->
    ok = kyu_channel:apply(Channel, cast, make_args(Command, State)),
    {reply, ok, State};
handle_publish(#publish{execution = async} = Command, _, #state{channel = Channel} = State) ->
    ok = kyu_channel:apply(Channel, cast, make_args(Command, State)),
    {reply, ok, State};
handle_publish(#publish{execution = sync} = Command, Caller, #state{channel = Channel, tags = Tags} = State) ->
    Seq = kyu_channel:apply(Channel, next_publish_seqno, []),
    ok = kyu_channel:apply(Channel, call, make_args(Command, State)),
    {noreply, State#state{tags = Tags#{Seq => Caller}}};
handle_publish(#publish{execution = supervised} = Command, Caller, #state{channel = Channel, tags = Tags} = State) ->
    Id = kyu_uuid:new(),
    Supervised = make_supervised(Command, Id),
    Seq = kyu_channel:apply(Channel, next_publish_seqno, []),
    ok = kyu_channel:apply(Channel, call, make_args(Supervised, State)),
    {noreply, State#state{tags = Tags#{Id => Caller, Seq => Caller}}}.

%% @hidden
make_args(#publish{command = Command, props = Props, payload = Payload}, _) ->
    [Command, #amqp_msg{props = Props, payload = Payload}].

%% @hidden
make_supervised(#publish{props = Props} = Command, Id) ->
    Command#publish{props = Props#'P_basic'{message_id = Id}}.

%% @hidden
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
