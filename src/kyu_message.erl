%% @hidden
-module(kyu_message).

-export([validate/1, parse/1, props/1]).

-include("amqp.hrl").

-define(VALIDATORS, #{
    routing_key => fun erlang:is_binary/1,
    exchange => fun erlang:is_binary/1,
    payload => fun erlang:is_binary/1,
    mandatory => fun erlang:is_boolean/1,
    type => fun erlang:is_binary/1,
    headers => fun erlang:is_list/1,
    priority => fun erlang:is_integer/1,
    expiration => fun erlang:is_integer/1,
    timestamp => fun erlang:is_integer/1,
    content_type => fun erlang:is_binary/1,
    content_encoding => fun erlang:is_binary/1,
    delivery_mode => fun erlang:is_integer/1,
    correlation_id => fun erlang:is_binary/1,
    cluster_id => fun erlang:is_binary/1,
    message_id => fun erlang:is_binary/1,
    user_id => fun erlang:is_binary/1,
    app_id => fun erlang:is_binary/1,
    reply_to => fun erlang:is_binary/1
}).

%% API FUNCTIONS

-spec validate(Message :: map()) -> true | false.
validate(#{} = Message) ->
    maps:fold(fun
        (_, _, false) -> false;
        (Key, Value, true) ->
            Fun = maps:get(Key, ?VALIDATORS, fun true/1),
            erlang:apply(Fun, [Value])
    end, true, Message).

-spec parse(Content :: #amqp_msg{}) -> kyu:message().
parse(#amqp_msg{payload = Payload, props = Props}) ->
    Info = record_info(fields, 'P_basic'),
    Seq = lists:seq(1, erlang:length(Info)),
    Temp = lists:map(fun ({Index, Key}) ->
        {Key, erlang:element(Index + 1, Props)}
    end, lists:zip(Seq, Info)),
    maps:from_list(Temp ++ [{payload, Payload}]).

-spec props(Message :: kyu:message()) -> tuple().
props(#{} = Message) ->
    Info = record_info(fields, 'P_basic'),
    Temp = lists:map(fun (Key) ->
        maps:get(Key, Message, undefined)
    end, Info),
    erlang:list_to_tuple(['P_basic'] ++ Temp).

%% PRIVATE FUNCTIONS

true(_) -> true.
