-record('kyu.queue.bind', {
    routing_key :: binary(),
    exchange :: binary(),
    queue :: binary(),
    arguments = [] :: list(),
    exclusive = false :: boolean()
}).

-record('kyu.queue.unbind', {
    pattern :: binary(),
    exchange :: binary(),
    queue :: binary(),
    arguments = [] :: list()
}).
