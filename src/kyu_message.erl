%% @hidden
-module(kyu_message).

-export([parse/1, parse/2, compile/1]).

-include("amqp.hrl").

%% API FUNCTIONS

-spec parse(Message :: #amqp_msg{}) -> kyu:message().
parse(#amqp_msg{} = Message) ->
    parse(Message, #{}).

-spec parse(Message :: #amqp_msg{}, Acc0 :: map()) -> kyu:message().
parse(#amqp_msg{payload = Payload, props = #'P_basic'{} = Props}, #{} = Acc0) ->
    Keys = record_info(fields, 'P_basic'),
    Indexes = lists:seq(2, record_info(size, 'P_basic')),
    lists:foldl(fun (Index, Acc) ->
        Key = lists:nth(Index - 1, Keys),
        Acc#{Key => erlang:element(Index, Props)}
    end, Acc0#{payload => Payload}, Indexes).

-spec compile(Message :: kyu:message()) -> #amqp_msg{}.
compile(#{} = Message) ->
    Payload = maps:get(payload, Message, <<>>),
    Keys = record_info(fields, 'P_basic'),
    Indexes = lists:seq(2, record_info(size, 'P_basic')),
    Props = lists:foldl(fun (Index, Acc) ->
        Key = lists:nth(Index - 1, Keys),
        Default = erlang:element(Index, Acc),
        Value = maps:get(Key, Message, Default),
        erlang:setelement(Index, Acc, Value)
    end, #'P_basic'{}, Indexes),
    #amqp_msg{payload = Payload, props = Props}.
