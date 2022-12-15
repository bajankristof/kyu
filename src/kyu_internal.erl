%% @hidden
-module(kyu_internal).

-export([attempt/2]).

-include("./_defaults.hrl").

-spec attempt(Mfa :: mfa(), Opts :: #{}) -> {ok, term()} | {error, term()}.
attempt(Mfa, Opts) ->
    attempt(0, Mfa, Opts).

-spec attempt(LastAttemptNo :: pos_integer(), Mfa :: mfa(), Opts :: #{}) -> {ok, term()} | {error, term()}.
attempt(LastAttemptNo, {Module, Function, Args}, Opts) ->
    MaxAttempts = maps:get(retry_attempts, Opts, ?DEFAULT_RETRY_ATTEMPTS),
    case {erlang:apply(Module, Function, Args), LastAttemptNo + 1} of
        {{ok, Result}, _} ->
            {ok, Result};
        {{error, Reason}, MaxAttempts} ->
            logger:notice("kyu: ~ts:~ts failed due to ~p", [Module, Function, Reason]),
            logger:warning("kyu: ~ts:~ts exhausted retry attempts, shutting down", [Module, Function]),
            {error, Reason};
        {{error, Reason}, CurrentAttemptNo} ->
            logger:notice("kyu: ~ts:~ts failed due to ~p", [Module, Function, Reason]),
            RetryDelay = maps:get(retry_delay, Opts, ?DEFAULT_RETRY_DELAY),
            timer:sleep(erlang:round(RetryDelay * math:pow(2, CurrentAttemptNo))),
            attempt(CurrentAttemptNo, {Module, Function, Args}, Opts)
    end.
