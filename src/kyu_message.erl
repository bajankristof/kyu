%% @hidden
-module(kyu_message).

-export([validate/1, parse/1, props/1]).

-include("amqp.hrl").

%% API FUNCTIONS

-spec validate(Message :: map()) -> true | false.
validate(#{} = Message) ->
    maps:fold(fun
        (_, _, false) -> false;
        (routing_key, Value, _) -> erlang:is_binary(Value);
        (exchange, Value, _) -> erlang:is_binary(Value);
        (payload, Value, _) -> erlang:is_binary(Value);
        (mandatory, Value, _) -> erlang:is_boolean(Value);
        (type, Value, _) -> erlang:is_binary(Value);
        (headers, Value, _) -> erlang:is_list(Value);
        (priority, Value, _) -> erlang:is_integer(Value);
        (expiration, Value, _) -> erlang:is_integer(Value);
        (timestamp, Value, _) -> erlang:is_integer(Value);
        (content_type, Value, _) -> erlang:is_binary(Value);
        (content_encoding, Value, _) -> erlang:is_binary(Value);
        (delivery_mode, Value, _) -> erlang:is_integer(Value);
        (correlation_id, Value, _) -> erlang:is_binary(Value);
        (cluster_id, Value, _) -> erlang:is_binary(Value);
        (message_id, Value, _) -> erlang:is_binary(Value);
        (user_id, Value, _) -> erlang:is_binary(Value);
        (app_id, Value, _) -> erlang:is_binary(Value);
        (reply_to, Value, _) -> erlang:is_binary(Value);
        (_, _, _) -> true
    end, true, Message).

-spec parse(Content :: #amqp_msg{}) -> kyu:message().
parse(#amqp_msg{payload = Payload, props = Props}) ->
    Info = record_info(fields, 'P_basic'),
    Seq = lists:seq(2, erlang:length(Info) + 1),
    Temp = lists:map(fun ({Index, Key}) ->
        {Key, erlang:element(Index, Props)}
    end, lists:zip(Seq, Info)),
    maps:from_list([{payload, Payload} | Temp]).

-spec props(Message :: kyu:message()) -> tuple().
props(#{} = Message) ->
    Info = record_info(fields, 'P_basic'),
    Temp = lists:map(fun (Key) ->
        maps:get(Key, Message, undefined)
    end, Info),
    erlang:list_to_tuple(['P_basic' | Temp]).
