%% @doc This module provides an interface to communicate
%% with the RabbitMQ management HTTP API.
%% @todo Interface further functionality?
-module(kyu_management).

-export([
    get_queues/1,
    get_queue/2,
    get_queue_bindings/2,
    get_queue_bindings/3,
    get_url/1,
    get_headers/1,
    request/3,
    request/4,
    declare/3
]).

-include("amqp.hrl").
-include("kyu.hrl").

-type method() :: get | post.
-type route() :: string() | {string(), list()}.
-type response() :: {ok, map() | list()} | {error, integer(), binary()} | {error, term()}.
-export_type([method/0, route/0, response/0]).

%% API FUNCTIONS

%% @doc Returns the queues declared on the provided connection.
%% <b>This function respects the virtual_host option of the connection</b>.
-spec get_queues(Connection :: kyu_connection:name()) -> response().
get_queues(Connection) ->
    Network = kyu_connection:network(Connection),
    Vhost = kyu_network:get(virtual_host, Network),
    request(get, Connection, {"/queues/~s", [Vhost]}).

%% @doc Returns details about the provided queue.
%% <b>This function respects the virtual_host option of the connection</b>.
-spec get_queue(Connection :: kyu_connection:name(), Queue :: binary()) -> response().
get_queue(Connection, Queue) ->
    Network = kyu_connection:network(Connection),
    Vhost = kyu_network:get(virtual_host, Network),
    request(get, Connection, {"/queues/~s/~s", [Vhost, Queue]}).

%% @doc Returns the bindings declared on the provided queue.
%% <b>This function respects the virtual_host option of the connection</b>.
-spec get_queue_bindings(Connection :: kyu_connection:name(), Queue :: binary()) -> response().
get_queue_bindings(Connection, Queue) ->
    Network = kyu_connection:network(Connection),
    Vhost = kyu_network:get(virtual_host, Network),
    request(get, Connection, {"/queues/~s/~s/bindings", [Vhost, Queue]}).

%% @doc Returns the bindings in an exchange declared on the provided queue.
%% <b>This function respects the virtual_host option of the connection</b>.
-spec get_queue_bindings(Connection :: kyu_connection:name(), Queue :: binary(), Exchange :: binary()) -> response().
get_queue_bindings(Connection, Queue, Exchange) ->
    Network = kyu_connection:network(Connection),
    Vhost = kyu_network:get(virtual_host, Network),
    request(get, Connection, {"/bindings/~s/e/~s/q/~s", [Vhost, Exchange, Queue]}).

%% @hidden
-spec get_url(Connection :: kyu_connection:name()) -> string().
get_url(Connection) ->
    Network = kyu_connection:network(Connection),
    Opts = kyu_connection:option(Connection, management, #{}),
    Host = maps:get(host, Opts,  kyu_network:get(host, Network)),
    Port = maps:get(port, Opts, 15672),
    {Prot, Socket, Args} = case Port of
        80 -> {"http", "~s", [Host]};
        443 -> {"https", "~s", [Host]};
        _ -> {"http", "~s:~p", [Host, Port]}
    end,
    io_lib:format(Prot ++ "://" ++ Socket ++ "/api", Args).

%% @hidden
-spec get_headers(Connection :: kyu_connection:name()) -> list().
get_headers(Connection) ->
    Network = kyu_connection:network(Connection),
    Username = kyu_network:get(username, Network),
    Password = kyu_network:get(password, Network),
    Content = base64:encode(<<Username/binary, ":", Password/binary>>),
    [{"Authorization", io_lib:format("Basic ~s", [Content])}].

%% @equiv kyu_management:request(Method, Connection, Route, <<>>)
-spec request(Method :: method(), Connection :: kyu_connection:name(), Route :: route()) -> response().
request(Method, Connection, Route) ->
    request(Method, Connection, Route, <<>>).

%% @doc Makes a request to the RabbitMQ management HTTP API.
-spec request(
    Method :: method(),
    Connection :: kyu_connection:name(),
    Route :: route(),
    Body :: map() | list() | binary()
) -> response().
request(Method, Connection, {Format, Args}, Body) ->
    Route = io_lib:format(Format, lists:map(fun http_uri:encode/1, Args)),
    request(Method, Connection, Route, Body);
request(Method, Connection, Route, #{} = Body) ->
    request(Method, Connection, Route, jsx:encode(Body));
request(Method, Connection, Route, []) ->
    request(Method, Connection, Route, <<"[]">>);
request(Method, Connection, Route, [_|_] = Body) ->
    request(Method, Connection, Route, jsx:encode(Body));
request(Method, Connection, Route, Body) ->
    Url = get_url(Connection) ++ Route,
    Headers = get_headers(Connection),
    Request = case Method of
        post -> {Url, Headers, "application/json", Body};
        get -> {Url, Headers}
    end,
    case httpc:request(Method, Request, [], []) of
        {ok, {{_, 200, _}, _, Response}} ->
            Binary = erlang:list_to_binary(Response),
            {ok, jsx:decode(Binary, [return_maps])};
        {ok, {{_, Code, Reason}, _, _}} ->
            Binary = erlang:list_to_binary(Reason),
            {error, Code, Binary};
        {error, Reason} -> {error, Reason}
    end.

-spec declare(Connection :: kyu_connection:name(), Channel :: pid(), Command :: tuple()) -> ok.
declare(Connection, Channel, #'kyu.queue.bind'{exclusive = false} = Command) ->
    kyu:declare(Connection, Channel, #'queue.bind'{
        routing_key = Command#'kyu.queue.bind'.routing_key,
        exchange = Command#'kyu.queue.bind'.exchange,
        queue = Command#'kyu.queue.bind'.queue,
        arguments = Command#'kyu.queue.bind'.arguments
    });
declare(Connection, Channel, #'kyu.queue.bind'{exclusive = true} = Command) ->
    Key = Command#'kyu.queue.bind'.routing_key,
    declare(Connection, Channel, #'kyu.queue.unbind'{
        pattern = <<"^(?!", Key/binary, "$).*$">>,
        exchange = Command#'kyu.queue.bind'.exchange,
        queue = Command#'kyu.queue.bind'.queue,
        arguments = Command#'kyu.queue.bind'.arguments
    }),
    declare(Connection, Channel, Command#'kyu.queue.bind'{exclusive = false});
declare(Connection, Channel, #'kyu.queue.unbind'{} = Command) ->
    {ok, Bindings} = get_queue_bindings(
        Connection,
        Command#'kyu.queue.unbind'.queue,
        Command#'kyu.queue.unbind'.exchange
    ),
    lists:map(fun (#{<<"routing_key">> := Key}) ->
        case match(Key, Command#'kyu.queue.unbind'.pattern) of
            match ->
                kyu:declare(Connection, Channel, #'queue.unbind'{
                    routing_key = Key,
                    exchange = Command#'kyu.queue.unbind'.exchange,
                    queue = Command#'kyu.queue.unbind'.queue,
                    arguments = Command#'kyu.queue.unbind'.arguments
                });
            nomatch -> ok
        end
    end, Bindings).

%% PRIVATE FUNCTIONS

match(Subject, Pattern) ->
    re:run(Subject, Pattern, [global, {capture, none}]).
