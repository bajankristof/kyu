%% @hidden
-module(kyu_uuid).

-export ([new/0]).

-spec new() -> binary().
new() ->
    Binary = assemble(
        erlang:phash2(erlang:timestamp()),
        erlang:phash2({node(), self()}),
        rand:uniform(4095),
        rand:uniform(4294967295),
        rand:uniform(1073741823)
    ),
    Parts = split(Binary),
    erlang:list_to_binary(concat(Parts)).

-spec assemble(
    P1 :: integer(),
    P2 :: integer(),
    R1 :: integer(),
    R2 :: integer(),
    R3 :: integer()
) -> binary().
assemble(P1, P2, R1, R2, R3) ->
    <<P1:32, P2:16, 4:4, R1:12, 2:2, R2:32, R3:30>>.

-spec split(Id :: binary()) -> list().
split(<<P1:32, P2:16, P3:16, P4:8, P5:8, P6:48>>) ->
    [P1, P2, P3, P4, P5, P6].

-spec concat(Parts :: list()) -> list().
concat(Parts) ->
    io_lib:format("~8.16.0b-~4.16.0b-~4.16.0b-~2.16.0b~2.16.0b-~12.16.0b", Parts).
