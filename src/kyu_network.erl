%% @hidden
-module(kyu_network).

-export([
    new/1,
    patch/2,
    get/2
]).

-include("amqp.hrl").

-spec new(Opts :: kyu_connection:opts()) -> #amqp_params_network{}.
new(#{url := Url} = Opts) ->
    {ok, Network} = amqp_uri:parse(Url),
    patch(Network, maps:without([url, Opts]));
new(Opts) ->
    Network = #amqp_params_network{},
    patch(Network, Opts).

-spec patch(Network :: #amqp_params_network{}, Opts :: kyu_connection:opts()) -> #amqp_params_network{}.
patch(Network, Opts) ->
    #amqp_params_network{
        host = maps:get(host, Opts, get(host, Network)),
        port = maps:get(port, Opts, get(port, Network)),
        username = maps:get(username, Opts, get(username, Network)),
        password = maps:get(password, Opts, get(password, Network)),
        heartbeat = maps:get(heartbeat, Opts, get(heartbeat, Network)),
        virtual_host = maps:get(virtual_host, Opts, get(virtual_host, Network)),
        channel_max = maps:get(channel_max, Opts, get(channel_max, Network)),
        frame_max = maps:get(frame_max, Opts, get(frame_max, Network)),
        ssl_options = maps:get(ssl_options, Opts, get(ssl_options, Network)),
        client_properties = maps:get(client_properties, Opts, get(client_properties, Network))
    }.

-spec get(Key :: atom(), Network :: #amqp_params_network{}) -> term().
get(host, #amqp_params_network{host = Value}) -> Value;
get(port, #amqp_params_network{port = Value}) -> Value;
get(username, #amqp_params_network{username = Value}) -> Value;
get(password, #amqp_params_network{password = Value}) -> Value;
get(heartbeat, #amqp_params_network{heartbeat = Value}) -> Value;
get(virtual_host, #amqp_params_network{virtual_host = Value}) -> Value;
get(channel_max, #amqp_params_network{channel_max = Value}) -> Value;
get(frame_max, #amqp_params_network{frame_max = Value}) -> Value;
get(ssl_options, #amqp_params_network{ssl_options = Value}) -> Value;
get(client_properties, #amqp_params_network{client_properties = Value}) -> Value;
get(url, #amqp_params_network{host = Host, port = Port, virtual_host = Vhost}) ->
    io_lib:format("amqp(s)://~ts:~p/~ts", [Host, Port, Vhost]).
