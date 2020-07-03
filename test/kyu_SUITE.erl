-module(kyu_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("stdlib/include/assert.hrl").
-include("amqp.hrl").
-include("kyu.hrl").

suite() -> [{timetrap, 64000}].

all() -> [
].

groups() -> [
].

init_per_group(_, Config) -> Config.

end_per_group(_, _) -> ok.

init_per_testcase(_Case, Config) -> Config.

end_per_testcase(_, _Config) -> ok.
