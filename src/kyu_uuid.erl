%% @hidden
-module(kyu_uuid).

-export ([new/0]).

-spec new() -> binary().
new() ->
    <<P1:32, P2:16, P3:16, P4:8, P5:8, P6:48>> = <<(erlang:phash2(erlang:timestamp())):32,
        (erlang:phash2({node(), self()})):16, 4:4, (rand:uniform(4095)):12, 2:2,
        (rand:uniform(4294967295)):32, (rand:uniform(1073741823)):30>>,
    Str = io_lib:format("~8.16.0b-~4.16.0b-~4.16.0b-~2.16.0b~2.16.0b-~12.16.0b", [P1, P2, P3, P4, P5, P6]),
    erlang:list_to_binary(Str).
