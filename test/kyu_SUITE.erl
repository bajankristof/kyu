-module(kyu_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").
-include("amqp.hrl").
-include("kyu.hrl").

-define(SUPERVISOR, kyu_sup).
-define(CONNECTION, localhost).

%% SETUP

suite() -> [{timetrap, 64000}].

all() -> [
    {group, connection},
    {group, channel},
    {group, command},
    {group, management},
    {group, workflow}
].

groups() -> [
    {connection, [sequence], [
        can_connection_survive,
        can_connection_recover
    ]},
    {channel, [sequence], [
        can_create_channel,
        can_channel_survive,
        can_channel_recover
    ]},
    {command, [parallel], [
        can_declare_exchange,
        can_declare_queue,
        can_bind_queue
    ]},
    {management, [parallel], [
        can_get_queues,
        can_get_queue,
        can_get_bindings
    ]},
    {workflow, [sequence], [
        can_bind_kyu,
        can_unbind_kyu,
        can_publisher_survive,
        can_publisher_recover,
        can_publish_sync,
        can_publish_supervised,
        can_consumer_survive,
        can_ack_message,
        can_reject_message,
        can_recover_badmatch,
        can_publish_duplex
    ]}
].

init_per_suite(Config) ->
    application:ensure_all_started(kyu),
    ok = kyu_connection:await(?CONNECTION),
    Config.

end_per_suite(_) ->
    application:stop(kyu).

init_per_group(Group, Config) when (Group =:= command) or (Group =:= management) ->
    Spec = kyu_channel:child_spec(?CONNECTION, #{id => Group, name => Group}),
    {ok, _} = supervisor:start_child(?SUPERVISOR, Spec#{restart => temporary}),
    ok = kyu_channel:await(Group),
    [{group, Group} | Config];
init_per_group(Group, Config) ->
    [{group, Group} | Config].

end_per_group(command = Group, _) ->
    ok = supervisor:terminate_child(?SUPERVISOR, Group);
end_per_group(_, _) -> ok.

init_per_testcase(Case, Config) ->
    [{'case', Case}, {'case.binary', erlang:atom_to_binary(Case, utf8)} | Config].

end_per_testcase(_, _Config) -> ok.

%% TESTS

%% === CONNECTION TESTS === %%

can_connection_survive(_) ->
    Old = kyu_connection:pid(?CONNECTION),
    true = erlang:exit(Old, kill),
    ok = kyu_connection:await(?CONNECTION),
    New = kyu_connection:pid(?CONNECTION),
    up = kyu_connection:status(?CONNECTION),
    ?assertNotEqual(Old, New).

can_connection_recover(_) ->
    Old = kyu_connection:where(?CONNECTION),
    true = erlang:exit(Old, kill),
    ok = kyu_connection:await(?CONNECTION),
    New = kyu_connection:where(?CONNECTION),
    up = kyu_connection:status(?CONNECTION),
    ?assertNotEqual(Old, New).

%% === CHANNEL TESTS === %%

can_create_channel(Config) ->
    Case = ?config('case', Config),
    {ok, _} = kyu_channel:start_link(?CONNECTION, #{name => Case}),
    ok = kyu_channel:await(Case),
    up = kyu_channel:status(Case),
    Pid = kyu_channel:pid(Case),
    ?assert(erlang:is_pid(Pid)),
    ok = kyu_channel:stop(Case),
    ?assertEqual(undefined, erlang:process_info(Pid)).

can_channel_survive(Config) ->
    Case = ?config('case', Config),
    {ok, _} = kyu_channel:start_link(?CONNECTION, #{name => Case}),
    ok = kyu_channel:await(Case),
    Old = kyu_channel:pid(Case),
    ok = kyu_connection:stop(?CONNECTION),
    ok = kyu_channel:await(Case),
    New = kyu_channel:pid(Case),
    up = kyu_channel:status(Case),
    ?assertNotEqual(Old, New).

can_channel_recover(Config) ->
    Case = ?config('case', Config),
    Spec = kyu_channel:child_spec(?CONNECTION, #{id => Case, name => Case}),
    {ok, _} = supervisor:start_child(?SUPERVISOR, Spec#{restart => transient}),
    ok = kyu_channel:await(Case),
    Old = kyu_channel:where(Case),
    true = erlang:exit(Old, kill),
    ok = kyu_channel:await(Case),
    New = kyu_channel:where(Case),
    up = kyu_channel:status(Case),
    ?assertNotEqual(Old, New),
    ok = supervisor:terminate_child(?SUPERVISOR, Case),
    ok = supervisor:delete_child(?SUPERVISOR, Case).

%% === COMMAND TESTS === %%

can_declare_exchange(Config) ->
    Group = ?config(group, Config),
    Case = ?config('case.binary', Config),
    ok = kyu:declare(Group, #'exchange.declare'{exchange = Case}),
    ok = kyu:declare(Group, #'exchange.delete'{exchange = Case}).

can_declare_queue(Config) ->
    Group = ?config(group, Config),
    Case = ?config('case.binary', Config),
    ok = kyu:declare(Group, #'queue.declare'{queue = Case}),
    ok = kyu:declare(Group, #'queue.delete'{queue = Case}).

can_bind_queue(Config) ->
    Group = ?config(group, Config),
    Case = ?config('case.binary', Config),
    ok = kyu:declare(Group, #'exchange.declare'{exchange = Case}),
    ok = kyu:declare(Group, #'queue.declare'{queue = Case}),
    ok = kyu:declare(Group, #'queue.bind'{exchange = Case, queue = Case, routing_key = Case}),
    ok = kyu:declare(Group, #'exchange.delete'{exchange = Case}),
    ok = kyu:declare(Group, #'queue.delete'{queue = Case}).

%% === MANAGEMENT TESTS === %%

can_get_queues(_) ->
    {ok, _} = kyu_management:get_queues(?CONNECTION).

can_get_queue(Config) ->
    Group = ?config(group, Config),
    Case = ?config('case.binary', Config),
    ok = kyu:declare(Group, #'queue.declare'{queue = Case}),
    {ok, #{}} = kyu_management:get_queue(?CONNECTION, Case),
    ok = kyu:declare(Group, #'queue.delete'{queue = Case}).

can_get_bindings(Config) ->
    Group = ?config(group, Config),
    Case = ?config('case.binary', Config),
    ok = kyu:declare(Group, #'exchange.declare'{exchange = Case}),
    ok = kyu:declare(Group, #'queue.declare'{queue = Case}),
    ok = kyu:declare(Group, #'queue.bind'{exchange = Case, queue = Case, routing_key = Case}),
    {ok, [#{}|_]} = kyu_management:get_queue_bindings(?CONNECTION, Case, Case),
    ok = kyu:declare(Group, #'exchange.delete'{exchange = Case}),
    ok = kyu:declare(Group, #'queue.delete'{queue = Case}).

%% === WORKFLOW TESTS === %%

can_bind_kyu(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_channel:start_link(?CONNECTION, #{name => Case}),
    ok = kyu_channel:await(Case),
    ok = kyu:declare(Case, #'exchange.declare'{exchange = Case}),
    ok = kyu:declare(Case, #'queue.declare'{queue = Case}),
    ok = kyu:declare(Case, #'queue.bind'{exchange = Case, queue = Case, routing_key = <<"one">>}),
    ok = kyu:declare(Case, #'queue.bind'{exchange = Case, queue = Case, routing_key = <<"two">>}),
    ok = kyu:declare(Case, #'kyu.queue.bind'{exclusive = true, exchange = Case, queue = Case, routing_key = Case}),
    {ok, [_]} = kyu_management:get_queue_bindings(?CONNECTION, Case, Case),
    ok = kyu:declare(Case, #'exchange.delete'{exchange = Case}),
    ok = kyu:declare(Case, #'queue.delete'{queue = Case}),
    ok = kyu_channel:stop(Case).

can_unbind_kyu(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_channel:start_link(?CONNECTION, #{name => Case}),
    ok = kyu_channel:await(Case),
    ok = kyu:declare(Case, #'exchange.declare'{exchange = Case}),
    ok = kyu:declare(Case, #'queue.declare'{queue = Case}),
    ok = kyu:declare(Case, #'queue.bind'{exchange = Case, queue = Case, routing_key = <<"one">>}),
    ok = kyu:declare(Case, #'queue.bind'{exchange = Case, queue = Case, routing_key = <<"two">>}),
    ok = kyu:declare(Case, #'queue.bind'{exchange = Case, queue = Case, routing_key = Case}),
    ok = kyu:declare(Case, #'kyu.queue.unbind'{except = Case, exchange = Case, queue = Case}),
    {ok, [_]} = kyu_management:get_queue_bindings(?CONNECTION, Case, Case),
    ok = kyu:declare(Case, #'exchange.delete'{exchange = Case}),
    ok = kyu:declare(Case, #'queue.delete'{queue = Case}),
    ok = kyu_channel:stop(Case).

can_publisher_survive(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_publisher:start_link(?CONNECTION, #{name => Case}),
    ok = kyu_publisher:await(Case),
    Old = kyu_channel:pid(kyu_publisher:channel(Case)),
    ok = kyu_connection:stop(?CONNECTION),
    ok = kyu_publisher:await(Case),
    New = kyu_channel:pid(kyu_publisher:channel(Case)),
    ?assertNotEqual(Old, New),
    ok = kyu_publisher:stop(Case).

can_publisher_recover(Config) ->
    Case = ?config('case.binary', Config),
    Spec = kyu_publisher:child_spec(?CONNECTION, #{id => Case, name => Case}),
    {ok, _} = supervisor:start_child(?SUPERVISOR, Spec#{restart => transient}),
    ok = kyu_publisher:await(Case),
    Old = kyu_channel:pid(kyu_publisher:channel(Case)),
    true = erlang:exit(kyu_publisher:where(Case), kill),
    ok = kyu_publisher:await(Case),
    New = kyu_channel:pid(kyu_publisher:channel(Case)),
    ?assertNotEqual(Old, New),
    ok = supervisor:terminate_child(?SUPERVISOR, Case),
    ok = supervisor:delete_child(?SUPERVISOR, Case).

can_publish_sync(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_publisher:start_link(?CONNECTION, #{name => Case}),
    ok = kyu_publisher:await(Case),
    ok = kyu:publish(Case, #{}),
    ok = kyu_publisher:stop(Case).

can_publish_supervised(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_publisher:start_link(?CONNECTION, #{name => Case}),
    ok = kyu_publisher:await(Case),
    {error, <<"NO_ROUTE">>} = kyu:publish(Case, #{execution => supervised, mandatory => true}),
    ok = kyu_publisher:stop(Case).

can_consumer_survive(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_consumer:start_link(?CONNECTION, #{
        name => Case,
        queue => Case,
        worker_module => kyu_SUITE_worker,
        worker_state => [self(), ack],
        commands => [#'queue.declare'{queue = Case}]
    }),
    ok = kyu_consumer:await(Case),
    Old = kyu_channel:pid(kyu_consumer:channel(Case)),
    ok = kyu_connection:stop(?CONNECTION),
    ok = kyu_consumer:await(Case),
    New = kyu_channel:pid(kyu_consumer:channel(Case)),
    ?assertNotEqual(Old, New),
    ok = kyu_consumer:stop(Case).

can_ack_message(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_consumer:start_link(?CONNECTION, #{
        name => Case,
        queue => Case,
        worker_module => kyu_SUITE_worker,
        worker_state => [self(), ack],
        commands => [#'queue.declare'{queue = Case}]
    }),
    {ok, _} = kyu_publisher:start_link(?CONNECTION, #{name => Case}),
    ok = kyu_consumer:await(Case),
    ok = kyu_publisher:await(Case),
    ok = kyu:publish(Case, #{routing_key => Case}),
    receive
        #{routing_key := Case} ->
            ok = kyu_consumer:stop(Case),
            ok = kyu_publisher:stop(Case)
    end.

can_reject_message(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_consumer:start_link(?CONNECTION, #{
        name => Case,
        queue => Case,
        worker_module => kyu_SUITE_worker,
        worker_state => [self(), reject],
        commands => [#'queue.declare'{queue = Case}]
    }),
    {ok, _} = kyu_publisher:start_link(?CONNECTION, #{name => Case}),
    ok = kyu_consumer:await(Case),
    ok = kyu_publisher:await(Case),
    ok = kyu:publish(Case, #{routing_key => Case}),
    receive
        #{routing_key := Case} ->
            receive
                #{routing_key := Case} ->
                    ok = kyu_consumer:stop(Case),
                    ok = kyu_publisher:stop(Case)
            end
    end.

can_recover_badmatch(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_consumer:start_link(?CONNECTION, #{
        name => Case,
        queue => Case,
        worker_module => kyu_SUITE_worker,
        worker_state => [self(), badmatch],
        commands => [#'queue.declare'{queue = Case}]
    }),
    {ok, _} = kyu_publisher:start_link(?CONNECTION, #{name => Case}),
    ok = kyu_consumer:await(Case),
    ok = kyu_publisher:await(Case),
    ok = kyu:publish(Case, #{routing_key => Case}),
    receive
        #{routing_key := Case} ->
            receive
                #{routing_key := Case} ->
                    ok = kyu_consumer:stop(Case),
                    ok = kyu_publisher:stop(Case)
            end
    end.

can_publish_duplex(Config) ->
    Case = ?config('case.binary', Config),
    {ok, _} = kyu_consumer:start_link(?CONNECTION, #{
        name => Case,
        queue => Case,
        worker_module => kyu_SUITE_worker,
        worker_state => [self(), reject],
        commands => [#'queue.declare'{queue = Case}],
        duplex => true
    }),
    ok = kyu_consumer:await(Case),
    ok = kyu:publish(Case, #{routing_key => Case}),
    receive
        #{routing_key := Case} ->
            ok = kyu_consumer:stop(Case)
    end.
