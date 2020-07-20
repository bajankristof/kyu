-module(kyu_SUITE_worker).

-behaviour(kyu_worker).

-compile(export_all).

handle_message(Message, [Pid, Reply] = State) ->
    Pid ! Message,
    {Reply, State}.
