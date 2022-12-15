%% @doc This module is responsible for creating
%% and managing AMQP publishers.
-module(kyu_publisher).

-behaviour(gen_server).
-behaviour(poolboy_worker).

-export([
    child_spec/2,
    child_spec/1,
    start_link/2,
    start_link/1,
    is_pool/1,
    where/1,
    call/2,
    call/3,
    cast/2,
    connection/1,
    channel/1,
    option/2,
    option/3,
    publish/2,
    stop/1,
    transaction/2
]).

-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    handle_continue/2,
    terminate/2
]).

-include("amqp.hrl").
-include("./_defaults.hrl").
-include("./_errors.hrl").
-include("./_macros.hrl").

-type opts() :: #{
    id := supervisor:child_id(),
    name := kyu:name(),
    connection := pid() | kyu:name(),
    channel := pid() | kyu:name(),
    confirms := boolean(),
    commands := list()
}.
-type pool_opts() :: #{
    size := pos_integer(),
    max_overflow := pos_integer(),
    strategy := lifo | fifo
}.
-type execution() :: sync | async | supervised.
-export_type([opts/0, pool_opts/0, execution/0]).

-record(state, {
    channel = undefined :: pid(),
    confirms = true :: boolean(),
    buffer = gb_trees:empty() :: gb_trees:tree(),
    opts = undefined :: map()
}).

%% API FUNCTIONS

%% @doc Returns a publisher child spec.
-spec child_spec(Opts :: opts()) -> supervisor:child_spec().
child_spec(#{id := Id, name := _} = Opts) ->
    #{id => Id, start => {?MODULE, start_link, [Opts]}};
child_spec(#{name := Name} = Opts) ->
    child_spec(Opts#{id => ?name(publisher, Name)}).

%% @doc Returns a publisher pool child spec.
-spec child_spec(Opts :: opts(), PoolOpts :: pool_opts()) -> supervisor:child_spec().
child_spec(#{name := Name} = Opts, #{} = PoolOpts) ->
    poolboy:child_spec(?name(publisher, Name), make_pool_args(Opts, PoolOpts), maps:remove(name, Opts)).

%% @doc Starts a publisher.
-spec start_link(Opts :: opts()) -> {ok, pid()} | {error, term()}.
start_link(#{name := Name} = Opts) ->
    gen_server:start_link(?via(publisher, Name), ?MODULE, Opts, []);
start_link(Opts) ->
    gen_server:start_link(?MODULE, Opts, []).

%% @doc Starts a publisher pool.
-spec start_link(Opts :: opts(), PoolOpts :: pool_opts()) -> {ok, pid()} | {error, term()}.
start_link(#{name := _} = Opts, #{} = PoolOpts) ->
    poolboy:start_link(make_pool_args(Opts, PoolOpts), maps:remove(name, Opts)).

%% @doc Returns whether the publisher is pooled or not.
-spec is_pool(Publisher :: pid()) -> boolean.
is_pool(Publisher) when erlang:is_pid(Publisher) ->
    {dictionary, Info} = erlang:process_info(Publisher, dictionary),
    case proplists:get_value('$initial_call', Info) of
        {?MODULE, _, _} -> false;
        _ -> true
    end.

%% @doc Returns the pid of the publisher.
%% -spec where(Name :: kyu:name()) -> pid() | undefined.
where(Name) ->
    gproc:where(?key(publisher, Name)).

%% @doc Makes a gen_server:call/2 to the publisher.
-spec call(Ref :: pid() | kyu:name(), Request :: term()) -> term().
call(Ref, Request) ->
    call(Ref, Request, ?DEFAULT_TIMEOUT).

%% @doc Makes a gen_server:call/3 to the publisher.
-spec call(Ref :: pid() | kyu:name(), Request :: term(), Timeout :: timeout()) -> term().
call(Ref, Request, Timeout) ->
    transaction(Ref, fun (Publisher) ->
        gen_server:call(Publisher, Request, Timeout)
    end).

%% @doc Makes a gen_server:cast/2 to the publisher.
-spec cast(Ref :: pid() | kyu:name(), Request :: term()) -> ok.
cast(Ref, Request) ->
    transaction(Ref, fun (Publisher) ->
        gen_server:cast(Publisher, Request)
    end).

%% @doc Returns the name of the publisher's connection.
-spec connection(Ref :: pid() | kyu:name()) -> kyu:name().
connection(Ref) ->
    call(Ref, connection).

%% @doc Returns the pid of the publisher's channel.
-spec channel(Ref :: pid() | kyu:name()) -> pid().
channel(Ref) ->
    call(Ref, channel).

%% @equiv kyu_connection:option(Ref, Key, undefined)
-spec option(Ref :: pid() | kyu:name(), Key :: atom()) -> term().
option(Ref, Key) ->
    option(Ref, Key, undefined).

%% @doc Returns a value from the publisher's options.
-spec option(Ref :: pid() | kyu:name(), Key :: atom(), Value :: term()) -> term().
option(Ref, Key, Value) ->
    call(Ref, {option, Key, Value}).

%% @doc Publishes a message on the channel.
-spec publish(Ref :: pid() | kyu:name(), Message :: kyu:message()) -> ok | {error, binary()}.
publish(Ref, #{} = Message) ->
    Timeout = maps:get(timeout, Message, ?DEFAULT_TIMEOUT),
    call(Ref, {publish, Message}, Timeout).

%% @doc Gracefully stops the publisher.
-spec stop(Ref :: pid() | kyu:name()) -> ok.
stop(Ref) when not erlang:is_pid(Ref) ->
    stop(where(Ref));
stop(Publisher) ->
    case is_pool(Publisher) of
        true -> poolboy:stop(Publisher);
        false -> gen_server:stop(Publisher)
    end.

%% @hidden
-spec transaction(Ref :: pid() | kyu:name(), Callback :: fun()) -> term().
transaction(Ref, Callback) when not erlang:is_pid(Ref) ->
    transaction(where(Ref), Callback);
transaction(Publisher, Callback) ->
    case is_pool(Publisher) of
        true -> poolboy:transaction(Publisher, Callback);
        false -> Callback(Publisher)
    end.

%% CALLBACK FUNCTIONS

%% @hidden
init(#{channel := Channel} = Opts) ->
    do_init(Channel, Opts);
init(#{connection := Connection} = Opts) ->
    case kyu_channel:start(Connection) of
        {ok, Channel} -> do_init(Channel, Opts);
        {error, Reason} -> {stop, Reason}
    end.

%% @hidden
handle_call(connection, _, #state{channel = Channel} = State) ->
    {reply, kyu_channel:connection(Channel), State};
handle_call(channel, _, #state{channel = Channel} = State) ->
    {reply, Channel, State};
handle_call({option, Key, Value}, _, #state{opts = Opts} = State) ->
    {reply, maps:get(Key, Opts, Value), State};
handle_call({publish, #{execution := supervised}}, _, #state{confirms = false} = State) ->
    {reply, {error, ?ERROR_NOT_SUPPORTED}, State};
handle_call({publish, #{execution := supervised} = Message}, Caller, State) ->
    do_publish(Message#{message_id => kyu_uuid:new(), mandatory => true}, Caller, State);
handle_call({publish, Message}, Caller, State) ->
    do_publish(Message, Caller, State);
handle_call(_, _, State) ->
    {noreply, State}.

%% @hidden
handle_cast(_, State) ->
    {noreply, State}.

%% @hidden
handle_info({'DOWN', _, process, Channel, Reason}, #state{channel = Channel} = State) ->
    {stop, Reason, State};
handle_info({#'basic.return'{reply_text = Reason}, #amqp_msg{props = #'P_basic'{message_id = MessageId}}}, State0) ->
    do_reply(MessageId, {error, Reason}, State0);
handle_info(#'basic.nack'{delivery_tag = Seqno}, State0) ->
    do_reply(Seqno, {error, ?ERROR_NACK}, State0);
handle_info(#'basic.ack'{delivery_tag = Seqno}, State0) ->
    do_reply(Seqno, ok, State0);
handle_info(_, State) ->
    {noreply, State}.

%% @hidden
handle_continue(setup, #state{channel = Channel} = State) ->
    do_register_channel(Channel, State).

%% @hidden
terminate(_, #state{channel = Channel} = State) ->
    do_deregister_channel(Channel, State),
    do_close_channel(Channel, State).

%% PRIVATE FUNCTIONS

%% @hidden
do_init(Channel, Opts) ->
    erlang:monitor(process, kyu_channel:where(Channel)),
    ok = kyu:declare(maps:get(commands, Opts, [])),
    Confirms = maps:get(confirms, Opts, true),
    State = #state{channel = Channel, confirms = Confirms, opts = Opts},
    {ok, State, {continue, setup}}.

%% @hidden
do_register_channel(Channel, #state{confirms = true} = State) ->
    #'confirm.select_ok'{} = kyu_channel:call(Channel, #'confirm.select'{}),
    ok = kyu_channel:apply(Channel, register_confirm_handler, [self()]),
    ok = kyu_channel:apply(Channel, register_return_handler, [self()]),
    {noreply, State};
do_register_channel(_, State) ->
    {noreply, State}.

%% @hidden
do_deregister_channel(_, #state{confirms = false}) -> ok;
do_deregister_channel(Channel, _) ->
    ok = kyu_channel:apply(Channel, unregister_confirm_handler),
    ok = kyu_channel:apply(Channel, unregister_return_handler).

%% @hidden
do_close_channel(_, #state{opts = #{channel := _}}) -> ok;
do_close_channel(Channel, _) ->
    kyu_channel:stop(Channel).

%% @hidden
do_publish(#{} = Message, _, #state{channel = Channel, opts = #{confirms := false}} = State) ->
    ok = kyu_channel:apply(Channel, cast, make_publish_args(Message, State)),
    {reply, ok, State};
do_publish(#{execution := async} = Message, _, #state{channel = Channel} = State) ->
    ok = kyu_channel:apply(Channel, cast, make_publish_args(Message, State)),
    {reply, ok, State};
do_publish(#{execution := supervised} = Message, Caller, #state{channel = Channel} = State) ->
    MessageId = maps:get(message_id, Message),
    Seqno = kyu_channel:apply(Channel, next_publish_seqno),
    ok = kyu_channel:apply(Channel, call, make_publish_args(Message, State)),
    {noreply, store_refs([MessageId, Seqno], Caller, State)};
do_publish(#{} = Message, Caller, #state{channel = Channel} = State) ->
    Seqno = kyu_channel:apply(Channel, next_publish_seqno),
    ok = kyu_channel:apply(Channel, call, make_publish_args(Message, State)),
    {noreply, store_refs([Seqno], Caller, State)}.

%% @hidden
do_reply(Key, Reply, #state{buffer = Buffer0} = State0) ->
    case gb_trees:take_any(Key, Buffer0) of
        {Caller, Buffer} ->
            gen_server:reply(Caller, Reply),
            State = State0#state{buffer = Buffer},
            {noreply, delete_refs(Caller, State)};
        _ -> {noreply, State0}
    end.

%% @hidden
store_refs(Keys, Caller, #state{buffer = Buffer0} = State) ->
    Buffer = lists:foldl(fun (Key, Acc) ->
        gb_trees:insert(Key, Caller, Acc)
    end, gb_trees:insert(Caller, Keys, Buffer0), Keys),
    State#state{buffer = Buffer}.

%% @hidden
delete_refs(Caller, #state{buffer = Buffer0} = State) ->
    case gb_trees:lookup(Caller, Buffer0) of
        {value, Keys} ->
            Buffer = lists:foldl(fun gb_trees:delete_any/2, Buffer0, [Caller | Keys]),
            State#state{buffer = Buffer};
        _ -> State
    end.

%% @hidden
make_publish_args(#{} = Message, _) ->
    [#'basic.publish'{
        routing_key = maps:get(routing_key, Message, <<>>),
        exchange = maps:get(exchange, Message, <<>>),
        mandatory = maps:get(mandatory, Message, false)
    }, kyu_message:compile(Message)].

%% @hidden
make_pool_args(#{name := Name}, #{} = PoolOpts0) ->
    PoolOpts = maps:without([name, worker_module], PoolOpts0),
    [{name, ?via(publisher, Name)}, {worker_module, ?MODULE} | maps:to_list(PoolOpts)].
