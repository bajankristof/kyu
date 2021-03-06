

# Module kyu_publisher #
* [Description](#description)
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

This module is responsible for creating
and managing amqp publishers.

__Behaviours:__ [`gen_server`](gen_server.md).

<a name="types"></a>

## Data Types ##




### <a name="type-execution">execution()</a> ###


<pre><code>
execution() = sync | async | supervised
</code></pre>




### <a name="type-name">name()</a> ###


<pre><code>
name() = term()
</code></pre>




### <a name="type-opts">opts()</a> ###


<pre><code>
opts() = #{id =&gt; <a href="supervisor.md#type-child_id">supervisor:child_id()</a>, name =&gt; <a href="#type-name">name()</a>, channel =&gt; <a href="kyu_channel.md#type-name">kyu_channel:name()</a>, confirms =&gt; boolean()}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#await-1">await/1</a></td><td>Equivalent to <a href="kyu_publisher.md#await-2"><tt>kyu_publisher:await(Name, 60000)</tt></a>.</td></tr><tr><td valign="top"><a href="#await-2">await/2</a></td><td>Waits for the publisher to successfully setup.</td></tr><tr><td valign="top"><a href="#call-2">call/2</a></td><td>Makes a gen_server:call/2 to the publisher.</td></tr><tr><td valign="top"><a href="#call-3">call/3</a></td><td>Makes a gen_server:call/3 to the publisher.</td></tr><tr><td valign="top"><a href="#cast-2">cast/2</a></td><td>Makes a gen_server:cast/2 to the publisher.</td></tr><tr><td valign="top"><a href="#channel-1">channel/1</a></td><td>Returns the name of the publisher's channel.</td></tr><tr><td valign="top"><a href="#child_spec-2">child_spec/2</a></td><td>Returns a publisher child spec.</td></tr><tr><td valign="top"><a href="#connection-1">connection/1</a></td><td>Returns the name of the publisher's connection.</td></tr><tr><td valign="top"><a href="#option-3">option/3</a></td><td>Returns a value from the publisher's options.</td></tr><tr><td valign="top"><a href="#publish-2">publish/2</a></td><td>Publishes a message on the channel.</td></tr><tr><td valign="top"><a href="#start_link-2">start_link/2</a></td><td>Starts a publisher.</td></tr><tr><td valign="top"><a href="#status-1">status/1</a></td><td>Returns the up atom if the publisher is running and has an active channel.</td></tr><tr><td valign="top"><a href="#stop-1">stop/1</a></td><td>Gracefully stops the publisher.</td></tr><tr><td valign="top"><a href="#where-1">where/1</a></td><td>Returns the pid of the publisher.</td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="await-1"></a>

### await/1 ###

<pre><code>
await(Name::<a href="#type-name">name()</a>) -&gt; ok
</code></pre>
<br />

Equivalent to [`kyu_publisher:await(Name, 60000)`](kyu_publisher.md#await-2).

<a name="await-2"></a>

### await/2 ###

<pre><code>
await(Name::<a href="#type-name">name()</a>, Timeout::timeout()) -&gt; ok
</code></pre>
<br />

Waits for the publisher to successfully setup.

<a name="call-2"></a>

### call/2 ###

<pre><code>
call(Name::<a href="#type-name">name()</a>, Request::term()) -&gt; term()
</code></pre>
<br />

Makes a gen_server:call/2 to the publisher.

<a name="call-3"></a>

### call/3 ###

<pre><code>
call(Name::<a href="#type-name">name()</a>, Request::term(), Timeout::timeout()) -&gt; term()
</code></pre>
<br />

Makes a gen_server:call/3 to the publisher.

<a name="cast-2"></a>

### cast/2 ###

<pre><code>
cast(Name::<a href="#type-name">name()</a>, Request::term()) -&gt; ok
</code></pre>
<br />

Makes a gen_server:cast/2 to the publisher.

<a name="channel-1"></a>

### channel/1 ###

<pre><code>
channel(Name::<a href="#type-name">name()</a>) -&gt; <a href="kyu_channel.md#type-name">kyu_channel:name()</a>
</code></pre>
<br />

Returns the name of the publisher's channel.

<a name="child_spec-2"></a>

### child_spec/2 ###

<pre><code>
child_spec(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Opts::<a href="#type-opts">opts()</a>) -&gt; <a href="supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

Returns a publisher child spec.

<a name="connection-1"></a>

### connection/1 ###

<pre><code>
connection(Name::<a href="#type-name">name()</a>) -&gt; <a href="kyu_connection.md#type-name">kyu_connection:name()</a>
</code></pre>
<br />

Returns the name of the publisher's connection.

<a name="option-3"></a>

### option/3 ###

<pre><code>
option(Name::<a href="#type-name">name()</a>, Key::atom(), Value::term()) -&gt; term()
</code></pre>
<br />

Returns a value from the publisher's options.

<a name="publish-2"></a>

### publish/2 ###

<pre><code>
publish(Name::<a href="#type-name">name()</a>, Message::<a href="kyu.md#type-message">kyu:message()</a>) -&gt; ok | {error, binary()}
</code></pre>
<br />

Publishes a message on the channel.

<a name="start_link-2"></a>

### start_link/2 ###

<pre><code>
start_link(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Opts::<a href="#type-opts">opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

Starts a publisher.

<a name="status-1"></a>

### status/1 ###

<pre><code>
status(Name::<a href="#type-name">name()</a>) -&gt; up | down
</code></pre>
<br />

Returns the up atom if the publisher is running and has an active channel.

<a name="stop-1"></a>

### stop/1 ###

<pre><code>
stop(Name::<a href="#type-name">name()</a>) -&gt; ok
</code></pre>
<br />

Gracefully stops the publisher.

<a name="where-1"></a>

### where/1 ###

`where(Name) -> any()`

Returns the pid of the publisher.
-spec where(Name :: name()) -> pid() | undefined.

