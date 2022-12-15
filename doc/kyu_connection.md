

# Module kyu_connection #
* [Description](#description)
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

This module is responsible for creating
and maintaining AMQP connections.

__Behaviours:__ [`gen_server`](gen_server.md).

<a name="types"></a>

## Data Types ##




### <a name="type-opts">opts()</a> ###


<pre><code>
opts() = #{id =&gt; <a href="/Users/bajankristof/Projects/Erlang/stdlib/doc/supervisor.md#type-child_id">supervisor:child_id()</a>, name =&gt; <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, url =&gt; iodata(), host =&gt; iolist(), port =&gt; pos_integer(), username =&gt; binary(), password =&gt; binary(), heartbeat =&gt; pos_integer(), virtual_host =&gt; binary(), channel_max =&gt; pos_integer(), frame_max =&gt; pos_integer(), ssl_options =&gt; term(), client_properties =&gt; list(), retry_delay =&gt; pos_integer(), retry_attempts =&gt; infinity | pos_integer(), management_host =&gt; iodata(), management_port =&gt; pos_integer()}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#apply-2">apply/2</a></td><td>Equivalent to <a href="kyu_connection.md#apply-3"><tt>kyu_connection:apply(Ref, Function, [])</tt></a>.</td></tr><tr><td valign="top"><a href="#apply-3">apply/3</a></td><td>Calls a function on the underlying AMQP connection.</td></tr><tr><td valign="top"><a href="#call-2">call/2</a></td><td>Makes a gen_server:call/2 call to the connection.</td></tr><tr><td valign="top"><a href="#call-3">call/3</a></td><td>Makes a gen_server:call/3 call to the connection.</td></tr><tr><td valign="top"><a href="#cast-2">cast/2</a></td><td>Makes a gen_server:cast/2 call to the connection.</td></tr><tr><td valign="top"><a href="#child_spec-1">child_spec/1</a></td><td>Returns a connection child spec.</td></tr><tr><td valign="top"><a href="#network-1">network/1</a></td><td>Returns the connection's network params.</td></tr><tr><td valign="top"><a href="#option-2">option/2</a></td><td>Equivalent to <a href="kyu_connection.md#option-3"><tt>kyu_connection:option(Ref, Key, undefined)</tt></a>.</td></tr><tr><td valign="top"><a href="#option-3">option/3</a></td><td>Returns a value from the connection's options.</td></tr><tr><td valign="top"><a href="#options-1">options/1</a></td><td>Returns the connection's options.</td></tr><tr><td valign="top"><a href="#pid-1">pid/1</a></td><td>Returns the pid of the underlying AMQP connection.</td></tr><tr><td valign="top"><a href="#start_link-1">start_link/1</a></td><td>Starts a connection.</td></tr><tr><td valign="top"><a href="#stop-1">stop/1</a></td><td>Gracefully closes the connection.</td></tr><tr><td valign="top"><a href="#where-1">where/1</a></td><td>Returns the pid of the connection.</td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="apply-2"></a>

### apply/2 ###

<pre><code>
apply(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Function::atom()) -&gt; term()
</code></pre>
<br />

Equivalent to [`kyu_connection:apply(Ref, Function, [])`](kyu_connection.md#apply-3).

<a name="apply-3"></a>

### apply/3 ###

<pre><code>
apply(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Function::atom(), Args::list()) -&gt; term()
</code></pre>
<br />

Calls a function on the underlying AMQP connection.

<a name="call-2"></a>

### call/2 ###

<pre><code>
call(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term()) -&gt; term()
</code></pre>
<br />

Makes a gen_server:call/2 call to the connection.

<a name="call-3"></a>

### call/3 ###

<pre><code>
call(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term(), Timeout::timeout()) -&gt; term()
</code></pre>
<br />

Makes a gen_server:call/3 call to the connection.

<a name="cast-2"></a>

### cast/2 ###

<pre><code>
cast(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term()) -&gt; ok
</code></pre>
<br />

Makes a gen_server:cast/2 call to the connection.

<a name="child_spec-1"></a>

### child_spec/1 ###

<pre><code>
child_spec(Opts::<a href="#type-opts">opts()</a>) -&gt; <a href="/Users/bajankristof/Projects/Erlang/stdlib/doc/supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

Returns a connection child spec.

<a name="network-1"></a>

### network/1 ###

<pre><code>
network(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; #amqp_params_network{}
</code></pre>
<br />

Returns the connection's network params.

<a name="option-2"></a>

### option/2 ###

<pre><code>
option(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Key::atom()) -&gt; term()
</code></pre>
<br />

Equivalent to [`kyu_connection:option(Ref, Key, undefined)`](kyu_connection.md#option-3).

<a name="option-3"></a>

### option/3 ###

<pre><code>
option(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Key::atom(), Value::term()) -&gt; term()
</code></pre>
<br />

Returns a value from the connection's options.

<a name="options-1"></a>

### options/1 ###

<pre><code>
options(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; <a href="#type-opts">opts()</a>
</code></pre>
<br />

Returns the connection's options.

<a name="pid-1"></a>

### pid/1 ###

<pre><code>
pid(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; pid() | undefined
</code></pre>
<br />

Returns the pid of the underlying AMQP connection.

<a name="start_link-1"></a>

### start_link/1 ###

<pre><code>
start_link(Opts::<a href="#type-opts">opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

Starts a connection.

<a name="stop-1"></a>

### stop/1 ###

<pre><code>
stop(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; ok
</code></pre>
<br />

Gracefully closes the connection.

<a name="where-1"></a>

### where/1 ###

`where(Name) -> any()`

Returns the pid of the connection.
-spec where(Name :: kyu:name()) -> pid() | undefined.

