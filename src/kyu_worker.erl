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
    transaction/2
]).

-export([start_link/1]).
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2
]).

-include("amqp.hrl").
-include("./_macros.hrl").

-record(state, {
    connection :: kyu_connection:name(),
    name :: kyu_consumer:name(),
    opts :: kyu_consumer:opts(),
    module :: atom(),
    state :: term()
}).

-callback handle_message(Message :: kyu:message(), State :: term()) ->
    {ack, term()} | {reject, term()} | {remove, term()} | {stop, term(), term()}.
%% @todo
-callback handle_info(Info :: term(), State :: term()) ->
    {noreply, term()} | {stop, term(), term()}.
-optional_callbacks([handle_info/2]).

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

-spec start_link(
    Connection :: kyu_connection:name(),
    Opts :: kyu_consumer:opts()
) -> {ok, pid()} | {error, term()}.
start_link(Connection, Opts) ->
    poolboy:start_link(
        make_pool(Connection, Opts),
        {Connection, Opts}
    ).

-spec call(Name :: kyu_consumer:name(), Request :: term()) -> term().
call(Name, Request) ->
    transaction(Name, fun (Worker) ->
        gen_server:call(Worker, Request)
    end).

-spec call(Name :: kyu_consumer:name(), Request :: term(), Timeout :: timeout()) -> term().
call(Name, Request, Timeout) ->
    transaction(Name, fun (Worker) ->
        gen_server:call(Worker, Request, Timeout)
    end).

-spec call_each(Name :: kyu_consumer:name(), Request :: term()) -> list().
call_each(Name, Request) ->
    lists:map(fun (Worker) ->
        gen_server:call(Worker, Request)
    end, get_all(Name)).

-spec call_each(Name :: kyu_consumer:name(), Request :: term(), Timeout :: timeout()) -> list().
call_each(Name, Request, Timeout) ->
    lists:map(fun (Worker) ->
        gen_server:call(Worker, Request, Timeout)
    end, get_all(Name)).

-spec cast(Name :: kyu_consumer:name(), Request :: term()) -> ok.
cast(Name, Request) ->
    transaction(Name, fun (Worker) ->
        gen_server:cast(Worker, Request)
    end).

-spec cast_each(Name :: kyu_consumer:name(), Request :: term()) -> ok.
cast_each(Name, Request) ->
    lists:foldl(fun (Worker, ok) ->
        gen_server:cast(Worker, Request)
    end, ok, get_all(Name)).

-spec send(Name :: kyu_consumer:name(), Info :: term()) -> term().
send(Name, Info) ->
    transaction(Name, fun (Worker) -> Worker ! Info end).

-spec send_each(Name :: kyu_consumer:name(), Info :: term()) -> list().
send_each(Name, Info) ->
    lists:map(fun (Worker) -> Worker ! Info end, get_all(Name)).

-spec get_all(Name :: kyu_consumer:name()) -> [pid()].
get_all(Name) ->
    Children = gen_server:call(?via(worker, Name), get_all_workers),
    lists:foldl(fun
        ({_, Worker, _, _}, Workers) when erlang:is_pid(Worker) ->
            Workers ++ [Worker];
        (_, Workers) -> Workers
    end, [], Children).

-spec transaction(Name :: kyu_consumer:name(), Callback :: fun((pid()) -> term())) -> term().
transaction(Name, Callback) ->
    poolboy:transaction(?via(worker, Name), Callback).

%% CALLBACK FUNCTIONS

start_link({Connection, Opts}) ->
    gen_server:start_link(?MODULE, {Connection, Opts}, []).

init({Connection, #{name := Name} = Opts}) ->
    lager:debug([{worker, Name}], "Kyu worker process started"),
    {ok, #state{
        connection = Connection,
        name = Name,
        opts = Opts,
        module = maps:get(worker_module, Opts),
        state = maps:get(worker_state, Opts)
    }}.

handle_call(_, _, State) ->
    {reply, ok, State}.

handle_cast({message, Tag, Key, Content}, #state{name = Name, module = Module, state = Current} = State) ->
    Message = update_message(#{routing_key => Key}, Content),
    case erlang:apply(Module, handle_message, [Message, Current]) of
        {ack, Next} ->
            ok = kyu_wrangler:cast(Name, {ack, Tag}),
            {noreply, State#state{state = Next}};
        {reject, Next} ->
            ok = kyu_wrangler:cast(Name, {reject, Tag}),
            {noreply, State#state{state = Next}};
        {remove, Next} ->
            ok = kyu_wrangler:cast(Name, {remove, Tag}),
            {noreply, State#state{state = Next}};
        {stop, Reason, Next} ->
            ok = kyu_wrangler:cast(Name, {reject, Tag}),
            {stop, Reason, State#state{state = Next}}
    end;
handle_cast(_, State) ->
    {noreply, State}.

handle_info(Info, #state{module = Module, state = Current} = State) ->
    Functions = erlang:apply(Module, module_info, [exports]),
    case lists:member({handle_info, 2}, Functions) of
        false -> {noreply, State};
        true ->
            {noreply, Next} = erlang:apply(Module, handle_info, [Info, Current]),
            {noreply, State#state{state = Next}}
    end.

%% PRIVATE FUNCTIONS

make_pool(_, #{name := Name} = Opts) ->
    Count = maps:get(worker_count, Opts, 1),
    Prefetch = maps:get(prefetch_count, Opts, 1),
    Overflow = Count * Prefetch - Count,
    [
        {size, Count},
        {max_overflow, Overflow},
        {name, ?via(worker, Name)},
        {worker_module, ?MODULE}
    ].

make_message(#amqp_msg{payload = Payload, props = Props}) ->
    Keys = [headers, priority, expiration, content_type,
        content_encoding, delivery_mode, correlation_id,
        message_id, user_id, app_id, reply_to],
    Values = lists:map(fun
        (headers) -> {headers, Props#'P_basic'.headers};
        (priority) -> {priority, Props#'P_basic'.priority};
        (expiration) -> {expiration, Props#'P_basic'.expiration};
        (content_type) -> {content_type, Props#'P_basic'.content_type};
        (content_encoding) -> {content_encoding, Props#'P_basic'.content_encoding};
        (delivery_mode) -> {delivery_mode, Props#'P_basic'.delivery_mode};
        (correlation_id) -> {correlation_id, Props#'P_basic'.correlation_id};
        (message_id) -> {message_id, Props#'P_basic'.message_id};
        (user_id) -> {user_id, Props#'P_basic'.user_id};
        (app_id) -> {app_id, Props#'P_basic'.app_id};
        (reply_to) -> {reply_to, Props#'P_basic'.reply_to}
    end, Keys),
    maps:from_list(Values ++ [{payload, Payload}]).

update_message(Message, #amqp_msg{} = Content) ->
    maps:merge(Message, make_message(Content)).
