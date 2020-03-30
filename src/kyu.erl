%% @doc This module provides helper functions
%% for amqp management.
-module(kyu).

-export([
    publish/2,
    declare/3
]).

-include("amqp.hrl").
-include("kyu.hrl").

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
-export_type([message/0]).

%% @equiv kyu_publisher:publish(Publisher, Message)
-spec publish(
    Publisher :: kyu_publisher:name(),
    Message :: message()
) -> ok | {error, binary()}.
publish(Publisher, Message) ->
    kyu_publisher:publish(Publisher, Message).

%% @doc Makes one or more declarations on the amqp channel.
-spec declare(
    Connection :: kyu_connection:name(),
    Channel :: pid(),
    Command :: list() | tuple()
) -> term().
declare(_, _, []) -> ok;
declare(Connection, Channel, [_|_] = Commands) ->
    lists:map(fun (Command) ->
        kyu:declare(Connection, Channel, Command)
    end, Commands);
declare(_, Channel, #'exchange.declare'{} = Command) ->
    #'exchange.declare_ok'{} = amqp_channel:call(Channel, Command);
declare(_, Channel, #'exchange.delete'{} = Command) ->
    #'exchange.delete_ok'{} = amqp_channel:call(Channel, Command);
declare(_, Channel, #'exchange.bind'{} = Command) ->
    #'exchange.bind_ok'{} = amqp_channel:call(Channel, Command);
declare(_, Channel, #'exchange.unbind'{} = Command) ->
    #'exchange.unbind_ok'{} = amqp_channel:call(Channel, Command);
declare(_, Channel, #'queue.declare'{} = Command) ->
    #'queue.declare_ok'{} = amqp_channel:call(Channel, Command);
declare(_, Channel, #'queue.bind'{} = Command) ->
    #'queue.bind_ok'{} = amqp_channel:call(Channel, Command);
declare(_, Channel, #'queue.purge'{} = Command) ->
    #'queue.purge_ok'{} = amqp_channel:call(Channel, Command);
declare(_, Channel, #'queue.delete'{} = Command) ->
    #'queue.delete_ok'{} = amqp_channel:call(Channel, Command);
declare(_, Channel, #'queue.unbind'{} = Command) ->
    #'queue.unbind_ok'{} = amqp_channel:call(Channel, Command);
declare(Connection, Channel, Command) ->
    kyu_management:declare(Connection, Channel, Command).
