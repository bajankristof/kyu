-define(name(Type, Name), {kyu, Type, Name}).
-define(server(Type, Name), {n, l, ?name(Type, Name)}).
-define(via(Type, Name), {via, gproc, ?server(Type, Name)}).
-define(event(Type, Name), {kyu, Type, Name}).
-define(message(Type, Name, Message), {kyu, Type, Name, Message}).
