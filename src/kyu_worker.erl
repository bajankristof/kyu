%% @doc This module is responsible for commication
%% with and between consumer workers.
-module(kyu_worker).

-behaviour(gen_server).
-behaviour(poolboy_worker).

-export([
    child_spec/1,
    child_spec/2,
    start_link/1,
    start_link/2,
    is_pool/1,
    where/1,
    call/2,
    call/3,
    call_each/2,
    call_each/3,
    cast/2,
    cast_each/2,
    send/2,
    send_each/2,
    channel/0,
    channel/1,
    get_all/1,
    transaction/2
]).
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2
]).

-include("amqp.hrl").
-include("./_defaults.hrl").
-include("./_macros.hrl").

-type opts() :: #{
    name := kyu:name(),
    channel := pid() | kyu:name(),
    queue := binary(),
    module := module(),
    args := term(),
    commands := list()
}.
-type pool_opts() :: #{
    size := pos_integer(),
    max_overflow := pos_integer(),
    strategy := lifo | fifo
}.
-export_type([opts/0, pool_opts/0]).

-record('worker.callbacks', {
    init = false :: boolean(),
    handle_message = false :: boolean(),
    handle_call = false :: boolean(),
    handle_cast = false :: boolean(),
    handle_info = false :: boolean(),
    terminate = false :: boolean()
}).

-record(worker, {
    module :: module(),
    state :: term(),
    callbacks :: #'worker.callbacks'{}
}).

-record(state, {
    channel :: pid() | kyu:name(),
    opts :: opts(),
    tag :: term(),
    worker :: #worker{}
}).

-define(matchCallback(Callback, Expect), #worker{callbacks = #'worker.callbacks'{Callback = Expect}}).

-callback init(Args :: term()) ->
    {ok, NewState :: term()}
    | {stop, Reason :: term()}.
-callback handle_call(Request :: term(), Caller :: gen_server:from(), State :: term()) ->
    {reply, Reply :: term(), NewState :: term()}
    | {noreply, NewState :: term()}
    | {stop, Reason :: term(), NewState :: term()}.
-callback handle_cast(Request :: term(), State :: term()) ->
    {noreply, NewState :: term()}
    | {stop, Reason :: term(), NewState :: term()}.
-callback handle_info(Info :: term(), State :: term()) ->
    {noreply, NewState :: term()}
    | {stop, Reason :: term(), NewState :: term()}.
-callback handle_message(Message :: kyu:message(), State :: term()) ->
    {ack, NewState :: term()}
    | {reject, NewState :: term()}
    | {remove, NewState :: term()}
    | {stop, Reason :: term(), NewState :: term()}.
-callback terminate(Reason :: term(), State :: term()) -> term().
-optional_callbacks([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

%% @doc Returns a worker child spec.
-spec child_spec(Opts :: opts()) -> supervisor:child_spec().
child_spec(#{id := Id, name := _} = Opts) ->
    #{id => Id, start => {?MODULE, start_link, [Opts]}};
child_spec(#{name := Name} = Opts) ->
    child_spec(Opts#{id => ?name(worker, Name)}).

%% @doc Returns a worker pool child spec.
-spec child_spec(Opts :: opts(), PoolOpts :: pool_opts()) -> supervisor:child_spec().
child_spec(#{id := Id, name := _} = Opts, #{} = PoolOpts) ->
    poolboy:child_spec(Id, make_pool_args(Opts, PoolOpts), maps:remove(name, Opts));
child_spec(#{name := Name} = Opts, PoolOpts) ->
    child_spec(Opts#{id => ?name(worker, Name)}, PoolOpts).

%% @doc Starts a worker.
-spec start_link(Opts :: opts()) -> {ok, pid()} | {error, term()}.
start_link(#{name := Name} = Opts) ->
    gen_server:start_link(?via(worker, Name), ?MODULE, Opts, []);
start_link(Opts) ->
    gen_server:start_link(?MODULE, Opts, []).

%% @doc Starts a worker pool.
-spec start_link(Opts :: opts(), PoolOpts :: pool_opts()) -> {ok, pid()} | {error, term()}.
start_link(#{name := _} = Opts, #{} = PoolOpts) ->
    poolboy:start_link(make_pool_args(Opts, PoolOpts), maps:remove(name, Opts)).

%% @doc Returns whether the worker is pooled or not.
-spec is_pool(Worker :: pid()) -> boolean.
is_pool(Worker) when erlang:is_pid(Worker) ->
    {dictionary, Info} = erlang:process_info(Worker, dictionary),
    case proplists:get_value('$initial_call', Info) of
        {?MODULE, _, _} -> false;
        _ -> true
    end.

%% @doc Returns the pid of the worker or worker pool.
%% -spec where(Name :: kyu:name()) -> pid() | undefined.
where(Name) ->
    gproc:where(?key(worker, Name)).

%% @doc Makes a gen_server:call/2 to the worker or one of the workers.
-spec call(Ref :: pid() | kyu:name(), Request :: term()) -> term().
call(Ref, Request) ->
    call(Ref, Request, ?DEFAULT_TIMEOUT).

%% @doc Makes a gen_server:call/3 to the worker or one of the workers.
-spec call(Ref :: pid() | kyu:name(), Request :: term(), Timeout :: timeout()) -> term().
call(Ref, Request, Timeout) ->
    transaction(Ref, fun (Worker) ->
        gen_server:call(Worker, Request, Timeout)
    end).

%% @doc Makes a gen_server:call/2 to all workers.
-spec call_each(Ref :: pid() | kyu:name(), Request :: term()) -> list().
call_each(Ref, Request) ->
    call_each(Ref, Request, ?DEFAULT_TIMEOUT).

%% @doc Makes a gen_server:call/3 to all workers.
-spec call_each(Ref :: pid() | kyu:name(), Request :: term(), Timeout :: timeout()) -> list().
call_each(Ref, Request, Timeout) ->
    lists:map(fun (Worker) ->
        gen_server:call(Worker, Request, Timeout)
    end, get_all(Ref)).

%% @doc Makes a gen_server:cast/2 to the worker or one of the workers.
-spec cast(Ref :: pid() | kyu:name(), Request :: term()) -> ok.
cast(Ref, Request) ->
    transaction(Ref, fun (Worker) ->
        gen_server:cast(Worker, Request)
    end).

%% @doc Makes a gen_server:cast/2 to all workers.
-spec cast_each(Ref :: pid() | kyu:name(), Request :: term()) -> list().
cast_each(Ref, Request) ->
    lists:map(fun (Worker) ->
        gen_server:cast(Worker, Request)
    end, get_all(Ref)).

%% @doc Sends info to the worker or one of the workers.
-spec send(Ref :: pid() | kyu:name(), Info :: term()) -> term().
send(Ref, Info) ->
    transaction(Ref, fun (Worker) -> Worker ! Info end).

%% @doc Sends info to all workers.
-spec send_each(Ref :: pid() | kyu:name(), Info :: term()) -> list().
send_each(Ref, Info) ->
    lists:map(fun (Worker) -> Worker ! Info end, get_all(Ref)).

%% @doc Returns the pid of the current process' AMQP channel
%% (if the current process is a worker).
-spec channel() -> pid().
channel() -> erlang:get('$kyu_channel').

%% @doc Returns the pid of the worker's AMQP channel.
-spec channel(Ref :: pid() | kyu:name()) -> pid().
channel(Ref) when not erlang:is_pid(Ref) ->
    channel(where(Ref));
channel(Ref) ->
    {dictionary, Info} = erlang:process_info(Ref, dictionary),
    proplists:get_value('$kyu_channel', Info).

%% @hidden
-spec get_all(Ref :: pid() | kyu:name()) -> [pid()].
get_all(Ref) when not erlang:is_pid(Ref) ->
    get_all(where(Ref));
get_all(Ref) ->
    case is_pool(Ref) of
        true ->
            Workers = gen_server:call(Ref, get_all_workers),
            lists:foldl(fun
                ({_, Pid, _, _}, Acc) when erlang:is_pid(Pid) ->
                    [Pid | Acc];
                (_, Acc) -> Acc
            end, [], Workers);
        false -> [Ref]
    end.

%% @hidden
-spec transaction(Ref :: pid() | kyu:name(), Callback :: fun()) -> term().
transaction(Ref, Callback) when not erlang:is_pid(Ref) ->
    transaction(where(Ref), Callback);
transaction(Worker, Callback) ->
    case is_pool(Worker) of
        true -> poolboy:transaction(Worker, Callback);
        false -> Callback(Worker)
    end.

%% CALLBACK FUNCTIONS

%% @hidden
init(#{channel := Channel, queue := Queue} = Opts) ->
    erlang:put('$kyu_channel', Channel),
    #'basic.qos_ok'{} = kyu_channel:call(Channel, #'basic.qos'{prefetch_count = 1, global = false}),
    #'basic.consume_ok'{consumer_tag = Tag} = kyu_channel:call(Channel, #'basic.consume'{queue = Queue}),
    State = #state{channel = Channel, opts = Opts, tag = Tag, worker = compile(Opts)},
    do_init(State).

%% @hidden
handle_call(Request, Caller, State) ->
    do_handle_call(Request, Caller, State).

%% @hidden
handle_cast(Request, State) ->
    do_handle_cast(Request, State).

%% @hidden
handle_info(#'basic.consume_ok'{}, State) ->
    {noreply, State};
handle_info({#'basic.deliver'{delivery_tag = Tag, routing_key = Key}, #amqp_msg{} = Content}, State) ->
    Message = kyu_message:parse(Content, #{routing_key => Key}),
    do_handle_message(Message, Tag, State);
handle_info(Info, State) ->
    do_handle_info(Info, State).

%% @hidden
terminate(Reason, #state{channel = Channel, tag = Tag} = State) ->
    #'basic.cancel_ok'{} = kyu_channel:call(Channel, #'basic.cancel'{consumer_tag = Tag}),
    do_terminate(Reason, State).

%% PRIVATE FUNCTIONS

%% @hidden
compile(#{module := Module} = Opts) ->
    WState = maps:get(args, Opts, undefined),
    #worker{module = Module, state = WState, callbacks = lists:foldl(fun
        ({init, 1}, Acc) -> Acc#'worker.callbacks'{init = true};
        ({handle_call, 3}, Acc) -> Acc#'worker.callbacks'{handle_call = true};
        ({handle_cast, 2}, Acc) -> Acc#'worker.callbacks'{handle_cast = true};
        ({handle_info, 2}, Acc) -> Acc#'worker.callbacks'{handle_info = true};
        ({terminate, 2}, Acc) -> Acc#'worker.callbacks'{terminate = true};
        (_, Acc) -> Acc
    end, #'worker.callbacks'{}, Module:module_info(exports))}.

%% @hidden
update(WState, #state{worker = Worker} = State) ->
    State#state{worker = Worker#worker{state = WState}}.

%% @hidden
do_init(#state{worker = ?matchCallback(init, false)} = State) ->
    {ok, State};
do_init(#state{worker = #worker{module = Module, state = WState0}} = State) ->
    case Module:init(WState0) of
        {ok, WState} -> {ok, update(WState, State)};
        {stop, Reason} -> {stop, Reason}
    end.

%% @hidden
do_handle_call(_, _, #state{worker = ?matchCallback(handle_call, false)} = State) ->
    {noreply, State};
do_handle_call(Request, Caller, #state{worker = #worker{module = Module, state = WState0}} = State) ->
    case Module:handle_call(Request, Caller, WState0) of
        {noreply, WState} -> {noreply, update(WState, State)};
        {reply, Reply, WState} -> {reply, Reply, update(WState, State)};
        {stop, Reason, WState} -> {stop, Reason, update(WState, State)}
    end.

%% @hidden
do_handle_cast(_, #state{worker = ?matchCallback(handle_cast, false)} = State) ->
    {noreply, State};
do_handle_cast(Request, #state{worker = #worker{module = Module, state = WState0}} = State) ->
    case Module:handle_cast(Request, WState0) of
        {noreply, WState} -> {noreply, update(WState, State)};
        {stop, Reason, WState} -> {stop, Reason, update(WState, State)}
    end.

%% @hidden
do_handle_info(_, #state{worker = ?matchCallback(handle_info, false)} = State) ->
    {noreply, State};
do_handle_info(Info, #state{worker = #worker{module = Module, state = WState0}} = State) ->
    case Module:handle_info(Info, WState0) of
        {noreply, WState} -> {noreply, update(WState, State)};
        {stop, Reason, WState} -> {stop, Reason, update(WState, State)}
    end.

%% @hidden
do_handle_message(Message, Tag, #state{worker = #worker{module = Module, state = WState0}} = State) ->
    case Module:handle_message(Message, WState0) of
        {Type, WState} -> do_reply(Type, Tag, update(WState, State));
        {stop, Reason, WState} -> {stop, Reason, WState}
    end.

%% @hidden
do_reply(ack, Tag, #state{channel = Channel} = State) ->
    ok = kyu_channel:cast(Channel, #'basic.ack'{delivery_tag = Tag}),
    {noreply, State};
do_reply(reject, Tag, #state{channel = Channel} = State) ->
    ok = kyu_channel:cast(Channel, #'basic.reject'{delivery_tag = Tag, requeue = true}),
    {noreply, State};
do_reply(remove, Tag, #state{channel = Channel} = State) ->
    ok = kyu_channel:cast(Channel, #'basic.reject'{delivery_tag = Tag, requeue = false}),
    {noreply, State}.

%% @hidden
do_terminate(_, #state{worker = ?matchCallback(terminate, false)}) -> ok;
do_terminate(Reason, #state{worker = #worker{module = Module, state = WState}}) ->
    Module:terminate(Reason, WState).

%% @hidden
make_pool_args(#{name := Name}, #{} = PoolOpts0) ->
    PoolOpts = maps:without([name, worker_module], PoolOpts0),
    [{name, ?via(worker, Name)}, {worker_module, ?MODULE} | maps:to_list(PoolOpts)].
