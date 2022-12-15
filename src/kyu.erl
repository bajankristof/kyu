%% @doc This module provides helper functions
%% for AMQP management.
-module(kyu).

-export([
    publish/2,
    declare/2
]).

-include("amqp.hrl").
-include("kyu.hrl").

-type name() :: term().
-type message() :: #{
    routing_key := binary(),
    exchange := binary(),
    payload := binary(),
    mandatory := boolean(),
    type := binary(),
    headers := list(),
    priority := integer(),
    expiration := integer(),
    timestamp := integer(),
    content_type := binary(),
    content_encoding := binary(),
    delivery_mode := integer(),
    correlation_id := binary(),
    cluster_id := binary(),
    message_id := binary(),
    user_id := binary(),
    app_id := binary(),
    reply_to := binary(),
    execution := kyu_publisher:execution(),
    timeout := infinity | integer()
}.
-export_type([name/0, message/0]).

%% @equiv kyu_publisher:publish(Publisher, Message)
-spec publish(
    Publisher :: name(),
    Message :: message()
) -> ok | {error, binary()}.
publish(Publisher, Message) ->
    kyu_publisher:publish(Publisher, Message).

%% @doc Makes one or more declarations on the AMQP channel.
-spec declare(Channel :: pid() | name(), Command :: list() | tuple()) -> ok.
declare(_, []) -> ok;
declare(Channel, [_|_] = Commands) ->
    lists:foldl(fun (Command, _) ->
        ok = declare(Channel, Command)
    end, ok, Commands);
declare(Channel, #'exchange.declare'{} = Command) ->
    #'exchange.declare_ok'{} = kyu_channel:call(Channel, Command), ok;
declare(Channel, #'exchange.delete'{} = Command) ->
    #'exchange.delete_ok'{} = kyu_channel:call(Channel, Command), ok;
declare(Channel, #'exchange.bind'{} = Command) ->
    #'exchange.bind_ok'{} = kyu_channel:call(Channel, Command), ok;
declare(Channel, #'exchange.unbind'{} = Command) ->
    #'exchange.unbind_ok'{} = kyu_channel:call(Channel, Command), ok;
declare(Channel, #'queue.declare'{} = Command) ->
    #'queue.declare_ok'{} = kyu_channel:call(Channel, Command), ok;
declare(Channel, #'queue.bind'{} = Command) ->
    #'queue.bind_ok'{} = kyu_channel:call(Channel, Command), ok;
declare(Channel, #'queue.purge'{} = Command) ->
    #'queue.purge_ok'{} = kyu_channel:call(Channel, Command), ok;
declare(Channel, #'queue.delete'{} = Command) ->
    #'queue.delete_ok'{} = kyu_channel:call(Channel, Command), ok;
declare(Channel, #'queue.unbind'{} = Command) ->
    #'queue.unbind_ok'{} = kyu_channel:call(Channel, Command), ok;
declare(Channel, Command) ->
    kyu_management:declare(Channel, Command), ok.
