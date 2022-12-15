%% @doc This module is responsible for creating
%% and maintaining AMQP channels
%% with only high level control.
-module(kyu_channel).

-compile({no_auto_import, [apply/3]}).

-export([
    start/1,
    start/2,
    where/1,
    apply/2,
    apply/3,
    call/2,
    cast/2,
    connection/1,
    stop/1
]).

-include("./_macros.hrl").

-type opts() :: #{name := kyu:name()}.
-export_type([opts/0]).

%% @doc Starts a new AMQP channel.
-spec start(Connection :: pid() | kyu:name()) -> {ok, pid()} | {error, term()}.
start(Connection) ->
    case kyu_connection:apply(Connection, open_channel) of
        {ok, Channel} ->
            gproc:reg_other(?key('$owner', Channel), Channel, Connection),
            {ok, Channel};
        {error, Reason} ->
            {error, Reason}
    end.

%% @doc Starts a new AMQP channel with the specified options (name).
-spec start(Connection :: pid() | kyu:name(), Opts :: opts()) -> {ok, pid()} | {error, term()}.
start(Connection, #{name := Name}) ->
    case start(Connection) of
        {ok, Channel} ->
            gproc:reg_other(?key(channel, Name), Channel, Channel),
            {ok, Channel};
        {error, Reason} ->
            {error, Reason}
    end.

%% @doc Returns the pid of the AMQP channel.
%% -spec where(Name :: kyu:name()) -> pid() | undefined.
where(Ref) when not erlang:is_pid(Ref) ->
    gproc:where(?key(channel, Ref));
where(Ref) -> Ref.

%% @equiv kyu_channel:apply(Channel, Function, [])
-spec apply(Channel :: pid() | kyu:name(), Function :: atom()) -> term().
apply(Channel, Function) ->
    apply(Channel, Function, []).

%% @doc Calls a function on the AMQP channel.
-spec apply(Channel :: pid() | kyu:name(), Function :: atom(), Args :: list()) -> term().
apply(Channel, Function, Args) when not erlang:is_pid(Channel) ->
    apply(where(Channel), Function, Args);
apply(Channel, Function, Args) ->
    erlang:apply(amqp_channel, Function, [Channel | Args]).

%% @doc Makes an amqp_channel:call/2 call to the AMQP channel.
-spec call(Channel :: pid() | kyu:name(), Request :: term()) -> term().
call(Channel, Request) ->
    apply(Channel, call, [Request]).

%% @doc Makes an amqp_channel:cast/2 call to the AMQP channel.
-spec cast(Channel :: pid() | kyu:name(), Request :: term()) -> term().
cast(Channel, Request) ->
    apply(Channel, cast, [Request]).

%% @doc Returns the connection to which the AMQP channel belongs.
-spec connection(Channel :: pid() | kyu:name()) -> term().
connection(Channel) when not erlang:is_pid(Channel) ->
    connection(where(Channel));
connection(Channel) ->
    gproc:get_value(?key('$owner', Channel), Channel).

%% @doc Closes the AMQP channel.
-spec stop(Channel :: pid() | kyu:name()) -> ok.
stop(Channel) when not erlang:is_pid(Channel) ->
    stop(where(Channel));
stop(Channel) ->
    amqp_channel:close(Channel).
