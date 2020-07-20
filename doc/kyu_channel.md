

# Module kyu_channel #
* [Description](#description)
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

This module is responsible for creating
and maintaining amqp channels.

__Behaviours:__ [`gen_server`](gen_server.md).

<a name="types"></a>

## Data Types ##




### <a name="type-name">name()</a> ###


<pre><code>
name() = term()
</code></pre>




### <a name="type-opts">opts()</a> ###


<pre><code>
opts() = #{id =&gt; <a href="supervisor.md#type-child_id">supervisor:child_id()</a>, name =&gt; <a href="#type-name">name()</a>}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#apply-3">apply/3</a></td><td>Calls a function on the underlying amqp channel.</td></tr><tr><td valign="top"><a href="#await-1">await/1</a></td><td>Equivalent to <a href="kyu_channel.md#await-2"><tt>kyu_channel:await(Name, 60000)</tt></a>.</td></tr><tr><td valign="top"><a href="#await-2">await/2</a></td><td>Waits for the channel to successfully setup.</td></tr><tr><td valign="top"><a href="#call-2">call/2</a></td><td>Makes a gen_server:call/2 to the channel.</td></tr><tr><td valign="top"><a href="#call-3">call/3</a></td><td>Makes a gen_server:call/3 to the channel.</td></tr><tr><td valign="top"><a href="#cast-2">cast/2</a></td><td>Makes a gen_server:cast/2 to the channel.</td></tr><tr><td valign="top"><a href="#child_spec-2">child_spec/2</a></td><td>Returns a channel child spec.</td></tr><tr><td valign="top"><a href="#connection-1">connection/1</a></td><td>Returns the name of the channel's connection.</td></tr><tr><td valign="top"><a href="#option-2">option/2</a></td><td>Equivalent to <a href="kyu_channel.md#option-3"><tt>kyu_channel:option(Name, Key, undefined)</tt></a>.</td></tr><tr><td valign="top"><a href="#option-3">option/3</a></td><td>Returns a value from the channel's options.</td></tr><tr><td valign="top"><a href="#pid-1">pid/1</a></td><td>Returns the pid of the underlying amqp channel.</td></tr><tr><td valign="top"><a href="#start_link-2">start_link/2</a></td><td>Starts a channel.</td></tr><tr><td valign="top"><a href="#status-1">status/1</a></td><td>Returns the up atom if the process is running and has an active channel.</td></tr><tr><td valign="top"><a href="#stop-1">stop/1</a></td><td>Gracefully closes the channel.</td></tr><tr><td valign="top"><a href="#subscribe-1">subscribe/1</a></td><td>Subscribes the calling process to events from the channel.</td></tr><tr><td valign="top"><a href="#where-1">where/1</a></td><td>Returns the pid of the channel.</td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="apply-3"></a>

### apply/3 ###

<pre><code>
apply(Name::<a href="#type-name">name()</a>, Function::atom(), Args::list()) -&gt; term()
</code></pre>
<br />

Calls a function on the underlying amqp channel.

<a name="await-1"></a>

### await/1 ###

<pre><code>
await(Name::<a href="#type-name">name()</a>) -&gt; ok
</code></pre>
<br />

Equivalent to [`kyu_channel:await(Name, 60000)`](kyu_channel.md#await-2).

<a name="await-2"></a>

### await/2 ###

<pre><code>
await(Name::<a href="#type-name">name()</a>, Timeout::timeout()) -&gt; ok
</code></pre>
<br />

Waits for the channel to successfully setup.

<a name="call-2"></a>

### call/2 ###

<pre><code>
call(Name::<a href="#type-name">name()</a>, Request::term()) -&gt; term()
</code></pre>
<br />

Makes a gen_server:call/2 to the channel.

<a name="call-3"></a>

### call/3 ###

<pre><code>
call(Name::<a href="#type-name">name()</a>, Request::term(), Timeout::timeout()) -&gt; term()
</code></pre>
<br />

Makes a gen_server:call/3 to the channel.

<a name="cast-2"></a>

### cast/2 ###

<pre><code>
cast(Name::<a href="#type-name">name()</a>, Request::term()) -&gt; ok
</code></pre>
<br />

Makes a gen_server:cast/2 to the channel.

<a name="child_spec-2"></a>

### child_spec/2 ###

<pre><code>
child_spec(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Opts::<a href="#type-opts">opts()</a>) -&gt; <a href="supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

Returns a channel child spec.

<a name="connection-1"></a>

### connection/1 ###

<pre><code>
connection(Name::<a href="#type-name">name()</a>) -&gt; <a href="kyu_connection.md#type-name">kyu_connection:name()</a>
</code></pre>
<br />

Returns the name of the channel's connection.

<a name="option-2"></a>

### option/2 ###

<pre><code>
option(Name::<a href="#type-name">name()</a>, Key::atom()) -&gt; term()
</code></pre>
<br />

Equivalent to [`kyu_channel:option(Name, Key, undefined)`](kyu_channel.md#option-3).

<a name="option-3"></a>

### option/3 ###

<pre><code>
option(Name::<a href="#type-name">name()</a>, Key::atom(), Value::term()) -&gt; term()
</code></pre>
<br />

Returns a value from the channel's options.

<a name="pid-1"></a>

### pid/1 ###

<pre><code>
pid(Name::<a href="#type-name">name()</a>) -&gt; pid() | undefined
</code></pre>
<br />

Returns the pid of the underlying amqp channel.

<a name="start_link-2"></a>

### start_link/2 ###

<pre><code>
start_link(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Opts::<a href="#type-opts">opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

Starts a channel.

<a name="status-1"></a>

### status/1 ###

<pre><code>
status(Name::<a href="#type-name">name()</a>) -&gt; up | down
</code></pre>
<br />

Returns the up atom if the process is running and has an active channel.

<a name="stop-1"></a>

### stop/1 ###

<pre><code>
stop(Name::<a href="#type-name">name()</a>) -&gt; ok
</code></pre>
<br />

Gracefully closes the channel.

<a name="subscribe-1"></a>

### subscribe/1 ###

<pre><code>
subscribe(Name::<a href="#type-name">name()</a>) -&gt; ok
</code></pre>
<br />

Subscribes the calling process to events from the channel.

<a name="where-1"></a>

### where/1 ###

`where(Name) -> any()`

Returns the pid of the channel.
-spec where(Name :: name()) -> pid() | undefined.

