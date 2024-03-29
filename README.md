# kyu - Simplified Erlang AMQP client

`kyu` is an AMQP client application that provides a simplified abstraction layer above the official [amqp_client](https://github.com/rabbitmq/rabbitmq-erlang-client). This of course also means that the module isn't suited to handle every possible use case (check out the features section below). 

`kyu` is heavily inspired by the great [turtle](https://github.com/shopgun/turtle) application. In some areas it provides more functionality over turtle, in others it lacks. The one feature that it definitely lacks is _built in rpc support_. If you don't want to implement that yourself I suggest taking a look at turtle.

## Features
`kyu`...
 - Can setup multiple AMQP connections and also maintains them (if a connection is lost it will try to reconnect based on the connection's configuration). If the connection is down you will receive errors when making AMQP dependent calls.
 - Uses names for connections, publishers, and consumers, this way you can access them from anywhere in your application. _The name can be any Erlang term (except `pid()`s), but has to be unique per handler type (a connection can have the same name as a publisher but two connections with the same name will conflict)_.
 - Provides an easy way to setup publishers or publisher pools that can be used to send messages from anywhere in your application. 
 - Supports a special publish execution mode that handles returned messages from the AMQP channel and replies with an error to the caller _(can be used to make sure the published message was successfully routed to at least one queue)_.
 - Provides an easy way to setup consumers. Messages are handled by a stateful callback module defined in the consumer's configuration.
 - Provides an interface to communicate with the RabbitMQ management HTTP API. 
 - Adds special declaration commands using the RabbitMQ management HTTP API, that can be used to setup publishers and consumers.

## Build
`kyu` can be built using [rebar3](https://www.rebar3.org/):
```sh
rebar3 compile
```

## Installation
Simply add `kyu` to your [rebar3](https://www.rebar3.org/) dependecies and to the applications list (for example in \<yourapp\>.app.src).
```erlang
%% rebar.config
{deps, [
    kyu,
    %% or
    {kyu, "~> 2.0"},
    %% or
    {kyu, {git, "git://github.com/bajankristof/kyu.git"}}
]}
```
```erlang
%% <yourapp>.app.src
{application, yourapp, [
    {mod, {yourapp_app, []}},
    {applications, [
        kernel,
        stdlib,
        kyu
    ]}
]}.
```

## Usage
One way to use the application is by providing connection configurations in environment variables (for example in your `sys.config` or `sys.config.src` file). This will use `kyu`'s supervisor to start the connections. 

Another way is to start your application and then attach connections to your supervision tree using `kyu_connection:child_spec/1` ([check out the docs](https://github.com/bajankristof/kyu/blob/main/doc/kyu_connection.md#child_spec-1)).

```erlang
%% example sys.config
[
    {kyu, [
        {connections, [#{
            name => <<"rabbitmq_cluster">>, %% required
            url => "amqp://user:password@rabbitmq.cluster", %% optional
            host => "rabbitmq.cluster", %% optional - default: "localhost"
            port => 5672, %% optional - default: 5672
            username => <<"user">>, %% optional - default: <<"guest">>
            password => <<"password">>, %% optional - default: <<"guest">>
            retry_delay => 5000, %% (ms) optional - default: 1000
            retry_attempts => 99, %% optional - default: infinity
            management_host => "rabbitmq.management", %% optional - default: connection host
            management_port => 443 %% optional - default: 15672
        }]}
    ]}
].
```

If the `retry_attempts` option is `0` or below the server will try to connect infinitely.

For the full set of configuration options [check out the docs](https://github.com/bajankristof/kyu/blob/main/doc/kyu_connection.md#types).

## Publishers
```erlang
-include_lib("kyu/include/amqp.hrl"). %% amqp commands

kyu_publisher:child_spec(#{
    connection => <<"rabbitmq_cluster">>, %% required
    name => <<"my_publisher">>, %% required
    confirms => true, %% optional - default: true
    commands => [ %% optional
        #'exchange.declare'{
            exchange = <<"my_exchange">>,
            type = <<"topic">>,
            durable = false
        }
    ]
}).
```
After introducing the returned child spec to your supervision tree, you can start publishing messages. 
```erlang
Publisher = <<"my_publisher">>,
Message = #{
    routing_key => <<"my.routing.key">>,
    exchange => <<"my_exchange">>,
    payload => <<"hello world">>,
    execution => async %% check out the explanation below
},
kyu:publish(Publisher, Message).
```
This will try to publish the provided message.

For a full set of possible message properties, [check out the docs](https://github.com/bajankristof/kyu/blob/main/doc/kyu.md#types).

### Execution
This setting will tell the publisher how to act on messages:

 - `sync` (default): If the publisher is in confirm mode, it will make the caller wait for the AMQP server to confirm the publication. **This is only synchronous from the perspective of the caller!** Other messages can still be published at the same time.
 - `async`: The publisher will ignore confirmation or returned messages.
 - `supervised`: The publisher will make the caller wait for either the AMQP server to confirm or return the message and reply with a value based on what was sent back by the server (for example `{error, <<"NO_ROUTE">>}`. For this to work **the publisher must be in confirm mode and the mandatory flag has to be set to `true`** on the message. To be able to identify a returned message, **the publisher overrides the `message_id` property** with a custom value! **This is only synchronous from the perspective of the caller!** Other messages can still be published at the same time.

## Consumers
```erlang
-include_lib("amqp.hrl").
-include_lib("kyu.hrl").

kyu_consumer:child_spec(#{
    connection => <<"rabbitmq_cluster">>, %% required
    name => <<"my_consumer">>, %% required
    queue => <<"queue_to_consume">>, %% required
    module => my_worker, %% required
    args => #{}, %% optional - default: undefined
    prefetch_count => 2, %% required - will start a channel with global prefetch count of 2, and 2 workers with local prefetch count of 1
    commands => [ %% optional
        #'queue.declare'{queue = <<"queue_to_consume">>},
        #'kyu.queue.bind'{ %% this is one of the special commands introduced by kyu
            routing_key = <<"my.routing.key">>,
            exchange = <<"my_exchange">>,
            queue = <<"queue_to_consume">>,
            exclusive = true
        }
    ]
}).
```
After introducing the consumer to your supervision tree, it will start to consume messages from the provided queue and make calls to the specified worker module.
```erlang
-module(my_worker).

-behaviour(kyu_worker).

-exports([
    init/1,
    handle_message/2,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2
]).

%% this callback is optional and works much like gen_server:init/1
-spec init(Args :: term()) -> {ok, State :: term()} | {stop, Reason :: term()}.
init(Args) ->
    %% initialization
    {ok, Args}.

-spec handle_message(Message :: kyu:message(), State :: term()) ->
    {ack, NewState :: term()}
    | {reject, NewState :: term()}
    | {remove, NewState :: term()}
    | {stop, Reason :: term(), NewState :: term()}.
handle_message(Message, State) ->
    %% consumption
    {ack, State}.

%% this callback is optional and works like gen_server:handle_call/3
-spec handle_call(Request :: term(), From :: gen_server:from(), State :: term()) ->
    {reply, Reply :: term(), NewState :: term()}
    | {noreply, NewState :: term()}
    | {stop, Reason :: term(), NewState :: term()}.
handle_call(_Request, _From, State) ->
    {noreply, State}.

%% this callback is optional and works like gen_server:handle_cast/2
-spec handle_cast(Request :: term(), State :: term()) ->
    {noreply, NewState :: term()}
    | {stop, Reason :: term(), NewState :: term()}.
handle_cast(_Request, State) ->
    {noreply, State}.

%% this callback is optional and works like gen_server:handle_info/2
-spec handle_info(Info :: term(), State :: term()) ->
    {noreply, NewState :: term()}
    | {stop, Reason :: term(), NewState :: term()}.
handle_info(_Info, State) ->
    {noreply, State}.

%% this callback is optional and works like gen_server:terminate/2
-spec terminate(Reason :: term(), State :: term()) -> term().
terminate(_Reason, _State) -> ok.
```

 - `ack` - (as you would expect) acks the message
 - `reject` - rejects and requeues the message
 - `remove` - rejects and removes the message from the queue
 - `stop` - crashes the worker process

## Commands
`kyu` supports commands in publisher and consumer configurations. This allows you to declare exchanges, queues and bindings before publishing or consuming. 

### AMQP commands
The out of the box supported AMQP commands are:
- `exchange.declare`
- `exchange.delete`
- `exchange.bind`
- `exchange.unbind`
- `queue.declare`
- `queue.bind`
- `queue.purge`
- `queue.delete`
- `queue.unbind`

Use these in a module:
```erlang
-include_lib("kyu/include/amqp.hrl").
```

### Kyu commands
There are two custom commands at the moment:

```erlang
%% extends the standard 'queue.bind' command
#'kyu.queue.bind'{
    routing_key :: binary(),
    exchange :: binary(),
    queue :: binary(),
    arguments :: list(),

    exclusive :: boolean()
    %% when set to false the command is equivalent to 
    %% a standard 'queue.bind' command

    %% when set to true it will unbind any other routing key
    %% with the same arguments (above)
}
```

```erlang
%% provides an alternative to the standard 'queue.unbind' command
#'kyu.queue.unbind'{
    except = <<>> :: binary(), %% an exception routing key
    pattern = <<>> :: binary(), %% a regex pattern
    %% if a routing key bound to the queue
    %% matches the pattern and the arguments (below)
    %% it will be unbound
    %% (except and pattern may not be used together)

    exchange :: binary(),
    queue :: binary(),
    arguments :: list()
}
```

Use these in a module:
```erlang
-include_lib("kyu/include/kyu.hrl").
```

## Documentation
Read the full documentation [here](https://github.com/bajankristof/kyu/blob/main/doc/README.md).
