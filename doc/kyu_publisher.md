

# Module kyu_publisher #
* [Description](#description)
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

This module is responsible for creating
and managing AMQP publishers.

__Behaviours:__ [`gen_server`](gen_server.md), [`poolboy_worker`](poolboy_worker.md).

<a name="types"></a>

## Data Types ##




### <a name="type-execution">execution()</a> ###


<pre><code>
execution() = sync | async | supervised
</code></pre>




### <a name="type-opts">opts()</a> ###


<pre><code>
opts() = #{id =&gt; <a href="/Users/bajankristof/Projects/Erlang/stdlib/doc/supervisor.md#type-child_id">supervisor:child_id()</a>, name =&gt; <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, connection =&gt; pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, channel =&gt; pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, confirms =&gt; boolean(), commands =&gt; list()}
</code></pre>




### <a name="type-pool_opts">pool_opts()</a> ###


<pre><code>
pool_opts() = #{size =&gt; pos_integer(), max_overflow =&gt; pos_integer(), strategy =&gt; lifo | fifo}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#call-2">call/2</a></td><td>Makes a gen_server:call/2 to the publisher.</td></tr><tr><td valign="top"><a href="#call-3">call/3</a></td><td>Makes a gen_server:call/3 to the publisher.</td></tr><tr><td valign="top"><a href="#cast-2">cast/2</a></td><td>Makes a gen_server:cast/2 to the publisher.</td></tr><tr><td valign="top"><a href="#channel-1">channel/1</a></td><td>Returns the pid of the publisher's channel.</td></tr><tr><td valign="top"><a href="#child_spec-1">child_spec/1</a></td><td>Returns a publisher child spec.</td></tr><tr><td valign="top"><a href="#child_spec-2">child_spec/2</a></td><td>Returns a publisher pool child spec.</td></tr><tr><td valign="top"><a href="#connection-1">connection/1</a></td><td>Returns the name of the publisher's connection.</td></tr><tr><td valign="top"><a href="#is_pool-1">is_pool/1</a></td><td>Returns whether the publisher is pooled or not.</td></tr><tr><td valign="top"><a href="#option-2">option/2</a></td><td>Equivalent to <a href="kyu_connection.md#option-3"><tt>kyu_connection:option(Ref, Key, undefined)</tt></a>.</td></tr><tr><td valign="top"><a href="#option-3">option/3</a></td><td>Returns a value from the publisher's options.</td></tr><tr><td valign="top"><a href="#publish-2">publish/2</a></td><td>Publishes a message on the channel.</td></tr><tr><td valign="top"><a href="#start_link-1">start_link/1</a></td><td>Starts a publisher.</td></tr><tr><td valign="top"><a href="#start_link-2">start_link/2</a></td><td>Starts a publisher pool.</td></tr><tr><td valign="top"><a href="#stop-1">stop/1</a></td><td>Gracefully stops the publisher.</td></tr><tr><td valign="top"><a href="#where-1">where/1</a></td><td>Returns the pid of the publisher.</td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="call-2"></a>

### call/2 ###

<pre><code>
call(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term()) -&gt; term()
</code></pre>
<br />

Makes a gen_server:call/2 to the publisher.

<a name="call-3"></a>

### call/3 ###

<pre><code>
call(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term(), Timeout::timeout()) -&gt; term()
</code></pre>
<br />

Makes a gen_server:call/3 to the publisher.

<a name="cast-2"></a>

### cast/2 ###

<pre><code>
cast(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term()) -&gt; ok
</code></pre>
<br />

Makes a gen_server:cast/2 to the publisher.

<a name="channel-1"></a>

### channel/1 ###

<pre><code>
channel(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; pid()
</code></pre>
<br />

Returns the pid of the publisher's channel.

<a name="child_spec-1"></a>

### child_spec/1 ###

<pre><code>
child_spec(Opts::<a href="#type-opts">opts()</a>) -&gt; <a href="/Users/bajankristof/Projects/Erlang/stdlib/doc/supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

Returns a publisher child spec.

<a name="child_spec-2"></a>

### child_spec/2 ###

<pre><code>
child_spec(Opts::<a href="#type-opts">opts()</a>, PoolOpts::<a href="#type-pool_opts">pool_opts()</a>) -&gt; <a href="/Users/bajankristof/Projects/Erlang/stdlib/doc/supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

Returns a publisher pool child spec.

<a name="connection-1"></a>

### connection/1 ###

<pre><code>
connection(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>
</code></pre>
<br />

Returns the name of the publisher's connection.

<a name="is_pool-1"></a>

### is_pool/1 ###

<pre><code>
is_pool(Publisher::pid()) -&gt; boolean
</code></pre>
<br />

Returns whether the publisher is pooled or not.

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

Returns a value from the publisher's options.

<a name="publish-2"></a>

### publish/2 ###

<pre><code>
publish(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Message::<a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-message">kyu:message()</a>) -&gt; ok | {error, binary()}
</code></pre>
<br />

Publishes a message on the channel.

<a name="start_link-1"></a>

### start_link/1 ###

<pre><code>
start_link(Opts::<a href="#type-opts">opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

Starts a publisher.

<a name="start_link-2"></a>

### start_link/2 ###

<pre><code>
start_link(Opts::<a href="#type-opts">opts()</a>, PoolOpts::<a href="#type-pool_opts">pool_opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

Starts a publisher pool.

<a name="stop-1"></a>

### stop/1 ###

<pre><code>
stop(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; ok
</code></pre>
<br />

Gracefully stops the publisher.

<a name="where-1"></a>

### where/1 ###

`where(Name) -> any()`

Returns the pid of the publisher.
-spec where(Name :: kyu:name()) -> pid() | undefined.

