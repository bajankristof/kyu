-module(kyu_SUITE).

-export([
    suite/0,
    all/0,
    groups/0,
    init_per_group/2,
    end_per_group/2,
    init_per_testcase/2,
    end_per_testcase/2
]).

%% COMMANDS
-export([
    can_declare_exchange/1,
    can_declare_queue/1,
    can_bind_queue/1
]).

%% LIFECYCLE
-export([
    can_connection_survive/1,
    can_publisher_survive/1,
    can_consumer_survive/1
]).

%% FEATURES
-export([
    can_publish_supervised/1,
    can_ack_message/1,
    can_reject_message/1,
    can_recover_badmatch/1
]).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").
-include("amqp.hrl").
-include("kyu.hrl").

-define(CTEXG, <<"kyu">>).
-define(CTEXGT, <<"topic">>).
-define(CTRK, <<"kyu.routing.key">>).
-define(CTWM, kyu_ctwm).
-define(CTWS, #{}).

suite() -> [
    {timetrap, 10000}
].

all() -> [
    {group, commands},
    {group, lifecycle},
    {group, features}
].

groups() -> [
    {commands, [], [
        can_declare_exchange,
        can_declare_queue,
        can_bind_queue
    ]},
    {lifecycle, [], [
        can_connection_survive,
        can_publisher_survive,
        can_consumer_survive
    ]},
    {features, [], [
        can_publish_supervised,
        can_ack_message,
        can_reject_message,
        can_recover_badmatch
    ]}
].

init_per_group(_, Config) ->
    application:ensure_all_started(kyu),
    Connection = <<"localhost">>,
    ok = kyu_connection:await(Connection),
    [{connection, Connection}] ++ Config.

end_per_group(_, _) ->
    application:stop(kyu).

init_per_testcase(Case, Config) ->
    dbg:tracer(),
    % dbg:p(all, c),
    % dbg:tpl(kyu_worker, init, '_', cx),
    % dbg:tpl(kyu_worker, cast, '_', cx),
    % dbg:tpl(kyu_worker, handle_cast, '_', cx),
    % dbg:tpl(kyu_worker, handle_continue, '_', cx),
    % dbg:tpl(kyu_wrangler, handle_info, '_', cx),
    % dbg:tpl(poolboy, checkout, '_', cx),
    Binary = erlang:atom_to_binary(Case, utf8),
    Connection = ?config(connection, Config),
    {ok, Channel} = kyu_connection:channel(Connection),
    [{name, Binary}, {channel, Channel}, {queue, Binary}] ++ Config.

end_per_testcase(_, Config) ->
    dbg:stop_clear(),
    Channel = ?config(channel, Config),
    case erlang:process_info(Channel) of
        undefined -> ok;
        _ -> amqp_channel:close(Channel)
    end.

can_declare_exchange(Config) ->
    Connection = ?config(connection, Config),
    Channel = ?config(channel, Config),
    kyu:declare(Connection, Channel, #'exchange.declare'{exchange = ?CTEXG, type = ?CTEXGT}),
    kyu:declare(Connection, Channel, #'exchange.delete'{exchange = ?CTEXG}).

can_declare_queue(Config) ->
    Connection = ?config(connection, Config),
    Channel = ?config(channel, Config),
    Queue = ?config(queue, Config),
    kyu:declare(Connection, Channel, #'queue.declare'{queue = Queue}),
    {ok, #{}} = kyu_management:get_queue(Connection, Queue),
    kyu:declare(Connection, Channel, #'queue.delete'{queue = Queue}).

can_bind_queue(Config) ->
    Connection = ?config(connection, Config),
    Channel = ?config(channel, Config),
    Queue = ?config(queue, Config),
    kyu:declare(Connection, Channel, [
        #'queue.declare'{queue = Queue},
        #'queue.bind'{
            routing_key = <<"kyu.binding.normal">>,
            queue = Queue,
            exchange = <<"amq.topic">>
        }
    ]),
    kyu:declare(Connection, Channel, #'kyu.queue.bind'{
        routing_key = <<"kyu.binding.survivor">>,
        queue = Queue,
        exchange = <<"amq.topic">>,
        exclusive = true
    }),
    ?assertMatch(
        {ok, [#{<<"routing_key">> := <<"kyu.binding.survivor">>}]},
        kyu_management:get_queue_bindings(Connection, Queue, <<"amq.topic">>)
    ),
    kyu:declare(Connection, Channel, #'kyu.queue.unbind'{
        pattern = <<"^.*$">>,
        queue = Queue,
        exchange = <<"amq.topic">>
    }),
    {ok, []} = kyu_management:get_queue_bindings(Connection, Queue, <<"amq.topic">>),
    kyu:declare(Connection, Channel, #'queue.delete'{queue = Queue}).

can_connection_survive(Config) ->
    Connection = ?config(connection, Config),
    Pid = kyu_connection:connection(Connection),
    erlang:exit(Pid, kill),
    ok = kyu_connection:await(Connection),
    ?assertNotEqual(Pid, kyu_connection:connection(Connection)).

can_publisher_survive(Config) ->
    Name = ?config(name, Config),
    Connection = ?config(connection, Config),
    {ok, _} = kyu_publisher:start_link(Connection, #{name => Name}),
    ok = kyu_publisher:await(Name),
    Old = kyu_publisher:channel(Name),
    ?assertEqual(true, erlang:is_pid(Old)),
    ok = kyu_connection:stop(Connection),
    ok = kyu_connection:await(Connection),
    ok = kyu_publisher:await(Name),
    Channel = kyu_publisher:channel(Name),
    ?assertNotEqual(Old, Channel),
    ok = kyu_publisher:stop(Name).

can_consumer_survive(Config) ->
    Name = ?config(name, Config),
    Connection = ?config(connection, Config),
    Queue = ?config(queue, Config),
    {ok, _} = kyu_consumer:start_link(Connection, #{
        name => Name,
        queue => Queue,
        worker_module => ?MODULE,
        worker_state => #{},
        commands => [#'queue.declare'{queue = Queue}]
    }),
    ok = kyu_consumer:await(Name),
    Old = kyu_consumer:channel(Name),
    ?assertEqual(true, erlang:is_pid(Old)),
    ok = kyu_connection:stop(Connection),
    ok = kyu_connection:await(Connection),
    ok = kyu_consumer:await(Name),
    Channel = kyu_consumer:channel(Name),
    ?assertNotEqual(Old, Channel),
    kyu:declare(Connection, Channel, #'queue.delete'{queue = Queue}),
    erlang:exit(kyu_consumer:where(Name), normal).

can_publish_supervised(Config) ->
    Name = ?config(name, Config),
    Connection = ?config(connection, Config),
    {ok, _} = kyu_publisher:start_link(Connection, #{name => Name}),
    ok = kyu_publisher:await(Name),
    Message = #{mandatory => true, execution => supervised},
    ?assertMatch({error, <<"NO_ROUTE">>}, kyu_publisher:publish(Name, Message)),
    ok = kyu_publisher:stop(Name).

can_ack_message(Config) ->
    Self = self(),
    Name = ?config(name, Config),
    ok = start_features(Config, fun
        (Message, State) ->
            Self ! Message,
            {ack, State}
    end),
    ok = kyu_publisher:publish(Name, #{
        routing_key => ?CTRK,
        exchange => ?CTEXG,
        mandatory => true,
        execution => async,
        payload => Name
    }),
    receive #{payload := Name} -> stop_features(Config) end.

can_reject_message(Config) ->
    Self = self(),
    Name = ?config(name, Config),
    ok = start_features(Config, fun
        (Message, State) -> Self ! Message, {reject, State}
    end),
    ok = kyu_publisher:publish(Name, #{
        routing_key => ?CTRK,
        exchange => ?CTEXG,
        mandatory => true,
        execution => async,
        payload => Name
    }),
    receive
        #{payload := Name} ->
            receive #{payload := Name} -> stop_features(Config) end
    end.

can_recover_badmatch(Config) ->
    Self = self(),
    Name = ?config(name, Config),
    ok = start_features(Config, fun
        (Message, _) -> Self ! Message, badmatch
    end),
    ok = kyu_publisher:publish(Name, #{
        routing_key => ?CTRK,
        exchange => ?CTEXG,
        mandatory => true,
        execution => async,
        payload => Name
    }),
    receive
        #{payload := Name} ->
            receive #{payload := Name} -> stop_features(Config) end
    end.

start_features(Config, Callback) ->
    ok = meck:new(?CTWM, [non_strict]),
    ok = meck:expect(?CTWM, handle_message, Callback),
    % dbg:tpl(?CTWM, handle_message, '_', cx),
    Name = ?config(name, Config),
    Connection = ?config(connection, Config),
    Queue = ?config(queue, Config),
    {ok, _} = kyu_publisher:start_link(Connection, #{
        name => Name,
        commands => [
            #'exchange.declare'{
                exchange = ?CTEXG,
                type = ?CTEXGT
            }
        ]
    }),
    {ok, _} = kyu_consumer:start_link(Connection, #{
        name => Name,
        queue => Queue,
        worker_module => ?CTWM,
        worker_state => ?CTWS,
        commands => [
            #'exchange.declare'{
                exchange = ?CTEXG,
                type = ?CTEXGT
            },
            #'queue.declare'{queue = Queue},
            #'queue.bind'{
                routing_key = ?CTRK,
                queue = Queue,
                exchange = ?CTEXG
            }
        ]
    }),
    ok = kyu_publisher:await(Name),
    kyu_consumer:await(Name).

stop_features(Config) ->
    Name = ?config(name, Config),
    Connection = ?config(connection, Config),
    Channel = kyu_consumer:channel(Name),
    Queue = ?config(queue, Config),
    kyu:declare(Connection, Channel, [
        #'exchange.delete'{exchange = ?CTEXG},
        #'queue.delete'{queue = Queue}
    ]),
    erlang:exit(kyu_consumer:where(Name), normal),
    kyu_publisher:stop(Name),
    meck:unload(?CTWM).
