

# Module kyu_channel #
* [Description](#description)
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

This module is responsible for creating
and maintaining AMQP channels
with only high level control.

<a name="types"></a>

## Data Types ##




### <a name="type-opts">opts()</a> ###


<pre><code>
opts() = #{name =&gt; <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#apply-2">apply/2</a></td><td>Equivalent to <a href="kyu_channel.md#apply-3"><tt>kyu_channel:apply(Channel, Function, [])</tt></a>.</td></tr><tr><td valign="top"><a href="#apply-3">apply/3</a></td><td>Calls a function on the AMQP channel.</td></tr><tr><td valign="top"><a href="#call-2">call/2</a></td><td>Makes an amqp_channel:call/2 call to the AMQP channel.</td></tr><tr><td valign="top"><a href="#cast-2">cast/2</a></td><td>Makes an amqp_channel:cast/2 call to the AMQP channel.</td></tr><tr><td valign="top"><a href="#connection-1">connection/1</a></td><td>Returns the connection to which the AMQP channel belongs.</td></tr><tr><td valign="top"><a href="#start-1">start/1</a></td><td>Starts a new AMQP channel.</td></tr><tr><td valign="top"><a href="#start-2">start/2</a></td><td>Starts a new AMQP channel with the specified options (name).</td></tr><tr><td valign="top"><a href="#stop-1">stop/1</a></td><td>Closes the AMQP channel.</td></tr><tr><td valign="top"><a href="#where-1">where/1</a></td><td>Returns the pid of the AMQP channel.</td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="apply-2"></a>

### apply/2 ###

<pre><code>
apply(Channel::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Function::atom()) -&gt; term()
</code></pre>
<br />

Equivalent to [`kyu_channel:apply(Channel, Function, [])`](kyu_channel.md#apply-3).

<a name="apply-3"></a>

### apply/3 ###

<pre><code>
apply(Channel::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Function::atom(), Args::list()) -&gt; term()
</code></pre>
<br />

Calls a function on the AMQP channel.

<a name="call-2"></a>

### call/2 ###

<pre><code>
call(Channel::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term()) -&gt; term()
</code></pre>
<br />

Makes an amqp_channel:call/2 call to the AMQP channel.

<a name="cast-2"></a>

### cast/2 ###

<pre><code>
cast(Channel::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term()) -&gt; term()
</code></pre>
<br />

Makes an amqp_channel:cast/2 call to the AMQP channel.

<a name="connection-1"></a>

### connection/1 ###

<pre><code>
connection(Channel::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; term()
</code></pre>
<br />

Returns the connection to which the AMQP channel belongs.

<a name="start-1"></a>

### start/1 ###

<pre><code>
start(Connection::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

Starts a new AMQP channel.

<a name="start-2"></a>

### start/2 ###

<pre><code>
start(Connection::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Opts::<a href="#type-opts">opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

Starts a new AMQP channel with the specified options (name).

<a name="stop-1"></a>

### stop/1 ###

<pre><code>
stop(Channel::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; ok
</code></pre>
<br />

Closes the AMQP channel.

<a name="where-1"></a>

### where/1 ###

`where(Ref) -> any()`

Returns the pid of the AMQP channel.
-spec where(Name :: kyu:name()) -> pid() | undefined.

