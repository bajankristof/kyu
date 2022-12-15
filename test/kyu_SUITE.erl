-module(kyu_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").
-include("amqp.hrl").
-include("kyu.hrl").
-include("../src/_macros.hrl").

-define(SUPERVISOR, kyu_sup).
-define(CONNECTION, localhost).

%% SETUP

suite() -> [{timetrap, 1000}].

all() -> [
    {group, connection},
    {group, management},
    {group, command},
    {group, publisher},
    {group, consumer}
].

groups() -> [
    {connection, [sequence], [
        can_connection_recover,
        can_create_channel
    ]},
    {management, [parallel], [
        can_get_queues,
        can_get_queue,
        can_get_bindings
    ]},
    {command, [parallel], [
        can_declare_exchange,
        can_declare_queue,
        can_bind_queue,
        can_bind_queue_exclusive,
        can_unbind_queue_except
    ]},
    {publisher, [parallel], [
        can_publish_sync,
        can_publish_supervised
    ]},
    {consumer, [parallel], [
        can_ack_message,
        can_reject_message,
        can_send_each
    ]}
].

init_per_suite(Config) ->
    application:ensure_all_started(kyu),
    Config.

end_per_suite(_) ->
    application:stop(kyu).

init_per_group(Group, Config)
        when Group =:= management orelse Group =:= command ->
    {ok, Channel} = kyu_channel:start(?CONNECTION),
    [{group, Group}, {channel, Channel} | Config];
init_per_group(Group, Config) ->
    [{group, Group} | Config].

end_per_group(command, Config) ->
    kyu_channel:stop(?config(channel, Config));
end_per_group(_, _) ->
    ok.

init_per_testcase(Case, Config) ->
    [{'case', Case}, {'case.binary', erlang:atom_to_binary(Case, utf8)} | Config].

end_per_testcase(_, _Config) ->
    ok.

%% TESTS

%% === CONNECTION TESTS === %%

can_connection_recover(_) ->
    Pid0 = kyu_connection:pid(?CONNECTION),
    true = erlang:exit(Pid0, kill),
    % HACK: We need to wait a little for the supervisor to restart the connection.
    timer:sleep(100),
    gproc:await(?key(connection, ?CONNECTION)),
    Pid = kyu_connection:pid(?CONNECTION),
    ?assertNotEqual(Pid0, Pid).

can_create_channel(Config) ->
    {ok, Pid} = kyu_channel:start(?CONNECTION),
    ?assertEqual(kyu_channel:connection(Pid), ?CONNECTION),
    ok = kyu_channel:stop(Pid),
    Case = ?config('case', Config),
    {ok, _} = kyu_channel:start(?CONNECTION, #{name => Case}),
    ?assertEqual(kyu_channel:connection(Case), ?CONNECTION),
    ok = kyu_channel:stop(Case).

%% === MANAGEMENT TESTS === %%

can_get_queues(Config) ->
    Channel = ?config(channel, Config),
    Case = ?config('case.binary', Config),
    amqp_channel:call(Channel, #'queue.declare'{queue = Case}),
    ?assertMatch({ok, _}, kyu_management:get_queues(?CONNECTION)),
    {ok, Queues} = kyu_management:get_queues(?CONNECTION),
    ?assertMatch([_ | _], lists:reverse(Queues)),
    amqp_channel:call(Channel, #'queue.delete'{queue = Case}).

can_get_queue(Config) ->
    Channel = ?config(channel, Config),
    Case = ?config('case.binary', Config),
    amqp_channel:call(Channel, #'queue.declare'{queue = Case, durable = true}),
    ?assertMatch({ok, #{<<"durable">> := true}}, kyu_management:get_queue(?CONNECTION, Case)),
    amqp_channel:call(Channel, #'queue.delete'{queue = Case}).

can_get_bindings(Config) ->
    Channel = ?config(channel, Config),
    Case = ?config('case.binary', Config),
    amqp_channel:call(Channel, #'exchange.declare'{exchange = Case}),
    amqp_channel:call(Channel, #'queue.declare'{queue = Case}),
    amqp_channel:call(Channel, #'queue.bind'{exchange = Case, queue = Case, routing_key = Case}),
    ?assertMatch({ok, [#{<<"routing_key">> := Case}]}, kyu_management:get_queue_bindings(?CONNECTION, Case, Case)),
    amqp_channel:call(Channel, #'exchange.delete'{exchange = Case}),
    amqp_channel:call(Channel, #'queue.delete'{queue = Case}).

%% === COMMAND TESTS === %%

can_declare_exchange(Config) ->
    Channel = ?config(channel, Config),
    Case = ?config('case.binary', Config),
    ?assertMatch(ok, kyu:declare(Channel, #'exchange.declare'{exchange = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'exchange.delete'{exchange = Case})).

can_declare_queue(Config) ->
    Channel = ?config(channel, Config),
    Case = ?config('case.binary', Config),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.declare'{queue = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.delete'{queue = Case})).

can_bind_queue(Config) ->
    Channel = ?config(channel, Config),
    Case = ?config('case.binary', Config),
    ?assertMatch(ok, kyu:declare(Channel, #'exchange.declare'{exchange = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.declare'{queue = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.bind'{exchange = Case, queue = Case, routing_key = Case})),
    ?assertMatch({ok, [#{<<"routing_key">> := Case}]}, kyu_management:get_queue_bindings(?CONNECTION, Case, Case)),
    ?assertMatch(ok, kyu:declare(Channel, #'exchange.delete'{exchange = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.delete'{queue = Case})).

can_bind_queue_exclusive(Config) ->
    Channel = ?config(channel, Config),
    Case = ?config('case.binary', Config),
    ?assertMatch(ok, kyu:declare(Channel, #'exchange.declare'{exchange = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.declare'{queue = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.bind'{exchange = Case, queue = Case, routing_key = <<"foo">>})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.bind'{exchange = Case, queue = Case, routing_key = <<"bar">>})),
    ?assertMatch(ok, kyu:declare(Channel, #'kyu.queue.bind'{exclusive = true, exchange = Case, queue = Case, routing_key = Case})),
    ?assertMatch({ok, [#{<<"routing_key">> := Case}]}, kyu_management:get_queue_bindings(?CONNECTION, Case, Case)),
    ?assertMatch(ok, kyu:declare(Channel, #'exchange.delete'{exchange = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.delete'{queue = Case})).

can_unbind_queue_except(Config) ->
    Channel = ?config(channel, Config),
    Case = ?config('case.binary', Config),
    ?assertMatch(ok, kyu:declare(Channel, #'exchange.declare'{exchange = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.declare'{queue = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.bind'{exchange = Case, queue = Case, routing_key = <<"foo">>})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.bind'{exchange = Case, queue = Case, routing_key = <<"bar">>})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.bind'{exchange = Case, queue = Case, routing_key = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'kyu.queue.unbind'{except = Case, exchange = Case, queue = Case})),
    {ok, [_]} = kyu_management:get_queue_bindings(?CONNECTION, Case, Case),
    ?assertMatch(ok, kyu:declare(Channel, #'exchange.delete'{exchange = Case})),
    ?assertMatch(ok, kyu:declare(Channel, #'queue.delete'{queue = Case})).

%% === PUBLISHER TESTS === %%

can_publish_sync(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_publisher:start_link(#{connection => ?CONNECTION, name => Case, confirms => false}),
    Message = #{exchange => <<"amq.direct">>, routing_key => <<"foo">>},
    ?assertMatch(ok, kyu:publish(Case, Message)),
    ok = kyu_publisher:stop(Case).

can_publish_supervised(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_publisher:start_link(#{connection => ?CONNECTION, name => Case}),
    Message = #{exchange => <<"amq.direct">>, routing_key => <<"foo">>, execution => supervised},
    ?assertMatch({error, <<"NO_ROUTE">>}, kyu:publish(Case, Message)),
    ok = kyu_publisher:stop(Case).

%% === CONSUMER TESTS === %%

can_ack_message(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_consumer:start_link(#{
        name => Case,
        connection => ?CONNECTION,
        module => kyu_ct_worker,
        args => #{name => Case, source => self()},
        queue => Case,
        prefetch_count => 1,
        commands => [#'queue.declare'{queue = Case}],
        duplex => true
    }),
    receive {init, #{name := Case}} -> ok end,
    ?assertMatch(ok, kyu:publish(Case, #{routing_key => Case, payload => Case})),
    receive {message, #{routing_key := Case, payload := Case}, #{name := Case}} -> ok end,
    kyu_consumer:stop(Case).

can_reject_message(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_consumer:start_link(#{
        name => Case,
        connection => ?CONNECTION,
        module => kyu_ct_worker,
        args => #{name => Case, source => self(), reply => [reject, ack]},
        queue => Case,
        prefetch_count => 1,
        commands => [#'queue.declare'{queue = Case}],
        duplex => true
    }),
    ?assertMatch(ok, kyu:publish(Case, #{routing_key => Case, payload => Case})),
    receive {message, #{routing_key := Case, payload := Case}, #{name := Case}} -> ok end,
    receive {message, #{routing_key := Case, payload := Case}, #{name := Case}} -> ok end,
    kyu_consumer:stop(Case).

can_send_each(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_consumer:start_link(#{
        name => Case,
        connection => ?CONNECTION,
        module => kyu_ct_worker,
        args => #{name => Case, source => self()},
        queue => Case,
        prefetch_count => 3,
        commands => [#'queue.declare'{queue = Case}],
        duplex => true
    }),
    Info = erlang:make_ref(),
    ?assertMatch([Info, Info, Info], kyu_worker:send_each(Case, Info)),
    receive {info, Info, #{name := Case}} -> ok end,
    receive {info, Info, #{name := Case}} -> ok end,
    receive {info, Info, #{name := Case}} -> ok end,
    kyu_consumer:stop(Case).
