-module(kyu_ct_worker).

-behaviour(kyu_worker).

-compile(export_all).

init(#{source := Source} = Opts) ->
    logger:info("    callback: kyu_ct_worker:init/1~n    args: ~p", [Opts]),
    Source ! {init, Opts},
    {ok, Opts}.

handle_call(Request, Caller, #{source := Source} = State) ->
    logger:info("    callback: kyu_ct_worker:handle_call/3~n    request: ~p~n    caller: ~p~n    state: ~p~n", [Request, Caller, State]),
    Source ! {call, Request, Caller, State},
    case maps:get(handle_call, State, noreply) of
        noreply -> {noreply, State};
        {reply, Reply} -> {reply, Reply, State}
    end.

handle_cast(Request, #{source := Source} = State) ->
    logger:info("    callback: kyu_ct_worker:handle_cast/2~n    request: ~p~n    state: ~p~n", [Request, State]),
    Source ! {cast, Request, State},
    {noreply, State}.

handle_info(Info, #{source := Source} = State) ->
    logger:info("    callback: kyu_ct_worker:handle_info/2~n    info: ~p~n    state: ~p~n", [Info, State]),
    Source ! {info, Info, State},
    {noreply, State}.

handle_message(Message, #{source := Source} = State) ->
    logger:info("    callback: kyu_ct_worker:handle_message/2~n    message: ~p~n    state: ~p~n", [Message, State]),
    Source ! {message, Message, State},
    case maps:get(reply, State, ack) of
        [Type | Rem] -> {Type, State#{reply => Rem}};
        Type -> {Type, State}
    end.

terminate(Reason, #{source := Source} = State) ->
    logger:info("    callback: kyu_ct_worker:terminate/2~n    reason: ~p~n    state: ~p~n", [Reason, State]),
    Source ! {terminate, Reason, State}.
