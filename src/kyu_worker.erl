%% @doc This module is responsible for commication
%% with and between consumer workers.
-module(kyu_worker).

-behaviour(gen_server).
-behaviour(poolboy_worker).

-export([
    child_spec/2,
    start_link/2,
    call/2,
    call_each/2,
    call/3,
    call_each/3,
    cast/2,
    cast_each/2,
    send/2,
    send_each/2,
    get_all/1,
    message/2,
    transaction/2
]).

-export([start_link/1]).
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

-record(state, {
    connection :: kyu_connection:name(),
    name :: kyu_consumer:name(),
    opts :: kyu_consumer:opts(),
    module :: atom(),
    args :: term(),
    unacked = []
}).

-callback init(State :: term()) ->
    {ok, term()} | {stop, term()}.
-callback handle_message(Message :: kyu:message(), State :: term()) ->
    {ack, term()} | {reject, term()} | {remove, term()} | {stop, term(), term()}.
-callback handle_info(Info :: term(), State :: term()) ->
    {noreply, term()} | {stop, term(), term()}.
-optional_callbacks([init/1, handle_info/2]).

%% @hidden
-spec child_spec(
    Connection :: kyu_connection:name(),
    Opts :: kyu_consumer:opts()
) -> supervisor:child_spec().
child_spec(Connection, #{name := Name} = Opts) ->
    poolboy:child_spec(
        ?name(pool, Name),
        make_pool(Connection, Opts),
        {Connection, Opts}
    ).

%% @hidden
-spec start_link(
    Connection :: kyu_connection:name(),
    Opts :: kyu_consumer:opts()
) -> {ok, pid()} | {error, term()}.
start_link(Connection, Opts) ->
    poolboy:start_link(
        make_pool(Connection, Opts),
        {Connection, Opts}
    ).

%% @hidden
-spec call(Name :: kyu_consumer:name(), Request :: term()) -> term().
call(Name, Request) ->
    transaction(Name, fun (Worker) ->
        gen_server:call(Worker, Request)
    end).

%% @hidden
-spec call(Name :: kyu_consumer:name(), Request :: term(), Timeout :: timeout()) -> term().
call(Name, Request, Timeout) ->
    transaction(Name, fun (Worker) ->
        gen_server:call(Worker, Request, Timeout)
    end).

%% @hidden
-spec call_each(Name :: kyu_consumer:name(), Request :: term()) -> list().
call_each(Name, Request) ->
    lists:map(fun (Worker) ->
        gen_server:call(Worker, Request)
    end, get_all(Name)).

%% @hidden
-spec call_each(Name :: kyu_consumer:name(), Request :: term(), Timeout :: timeout()) -> list().
call_each(Name, Request, Timeout) ->
    lists:map(fun (Worker) ->
        gen_server:call(Worker, Request, Timeout)
    end, get_all(Name)).

%% @hidden
-spec cast(Name :: kyu_consumer:name(), Request :: term()) -> ok.
cast(Name, Request) ->
    transaction(Name, fun (Worker) ->
        gen_server:cast(Worker, Request)
    end).

%% @hidden
-spec cast_each(Name :: kyu_consumer:name(), Request :: term()) -> ok.
cast_each(Name, Request) ->
    lists:foldl(fun (Worker, ok) ->
        gen_server:cast(Worker, Request)
    end, ok, get_all(Name)).

%% @doc Sends info to one of the worker processes (in round-robin fashion).
-spec send(Name :: kyu_consumer:name(), Info :: term()) -> term().
send(Name, Info) ->
    transaction(Name, fun (Worker) -> Worker ! Info end).

%% @doc Sends info to all of the worker processes.
-spec send_each(Name :: kyu_consumer:name(), Info :: term()) -> list().
send_each(Name, Info) ->
    lists:map(fun (Worker) -> Worker ! Info end, get_all(Name)).

%% @doc Returns the worker pids.
-spec get_all(Name :: kyu_consumer:name()) -> [pid()].
get_all(Name) ->
    Children = gen_server:call(?via(worker, Name), get_all_workers),
    lists:foldl(fun
        ({_, Worker, _, _}, Workers) when erlang:is_pid(Worker) ->
            Workers ++ [Worker];
        (_, Workers) -> Workers
    end, [], Children).

%% @hidden
-spec message(Name :: kyu_consumer:name(), Command :: tuple()) -> ok.
message(Name, Command) ->
    Worker = poolboy:checkout(?via(worker, Name)),
    gen_server:cast(Worker, Command).

%% @hidden
-spec transaction(Name :: kyu_consumer:name(), Callback :: fun((pid()) -> term())) -> term().
transaction(Name, Callback) ->
    poolboy:transaction(?via(worker, Name), Callback).

%% CALLBACK FUNCTIONS

%% @hidden
start_link({Connection, Opts}) ->
    gen_server:start_link(?MODULE, {Connection, Opts}, []).

%% @hidden
init({Connection, #{name := Name} = Opts}) ->
    % lager:debug([{worker, Name}], "Kyu worker process started"),
    State = #state{connection = Connection, name = Name,
        opts = Opts, module = maps:get(worker_module, Opts),
        args = maps:get(worker_state, Opts)},
    case call_optional(State#state.module, {init, 1}, [State#state.args]) of
        {ok, Args} -> {ok, State#state{args = Args}};
        {stop, Stop} -> {stop, Stop};
        undefined -> {ok, State}
    end.

%% @hidden
handle_call(_, _, State) ->
    {noreply, State}.

%% @hidden
handle_cast({message, Tag, _, _} = Command, #state{unacked = Unacked} = State) ->
    {noreply, State#state{unacked = Unacked ++ [Tag]}, {continue, Command}};
handle_cast(_, State) ->
    {noreply, State}.

%% @hidden
handle_continue({message, Tag, Key, Content}, #state{module = Module, args = Args} = State) ->
    Message = maps:put(routing_key, Key, kyu_message:parse(Content)),
    case erlang:apply(Module, handle_message, [Message, Args]) of
        {ack, _} = Return -> {noreply, State, {continue, {reply, Tag, Return}}};
        {reject, _} = Return -> {noreply, State, {continue, {reply, Tag, Return}}};
        {remove, _} = Return -> {noreply, State, {continue, {reply, Tag, Return}}};
        {stop, _, _} = Return -> {noreply, State, {continue, {reply, Tag, Return}}}
    end;
handle_continue({reply, Tag, {Type, Args}}, #state{name = Name, unacked = Unacked} = State) ->
    ok = kyu_wrangler:cast(Name, {Type, Tag}),
    poolboy:checkin(?via(worker, Name), self()),
    {noreply, State#state{args = Args, unacked = lists:delete(Tag, Unacked)}};
handle_continue({noreply, {_, Args}}, #state{} = State) ->
    {noreply, State#state{args = Args}};
handle_continue({_, _, {stop, Stop, Args}}, #state{} = State) ->
    {stop, Stop, State#state{args = Args}};
handle_continue(_, State) ->
    {noreply, State}.

%% @hidden
handle_info(Info, #state{module = Module, args = Args} = State) ->
    case call_optional(Module, {handle_info, 2}, [Info, Args]) of
        {noreply, _} = Return -> {noreply, State, {continue, {noreply, Return}}};
        {stop, _, _} = Return -> {noreply, State, {continue, {noreply, Return}}};
        undefined -> {noreply, State}
    end.

%% @hidden
terminate(_, #state{name = Name, unacked = Unacked}) ->
    lists:foldl(fun (Tag, ok) ->
        kyu_wrangler:cast(Name, {reject, Tag})
    end, ok, Unacked).

%% PRIVATE FUNCTIONS

call_optional(Module, {Function, Arity}, Args) ->
    Functions = erlang:apply(Module, module_info, [exports]),
    case lists:member({Function, Arity}, Functions) of
        true -> erlang:apply(Module, Function, Args);
        false -> undefined
    end.

make_pool(_, #{name := Name} = Opts) ->
    Count = maps:get(worker_count, Opts, 1),
    Prefetch = maps:get(prefetch_count, Opts, 1),
    Overflow = Count * Prefetch - Count,
    [{size, Count}, {max_overflow, Overflow},
        {name, ?via(worker, Name)}, {worker_module, ?MODULE}].
