

# Module kyu_worker #
* [Description](#description)
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

This module is responsible for commication
with and between consumer workers.

__Behaviours:__ [`gen_server`](gen_server.md), [`poolboy_worker`](poolboy_worker.md).

__This module defines the `kyu_worker` behaviour.__<br /> Required callback functions: `handle_message/2`.

<a name="types"></a>

## Data Types ##




### <a name="type-opts">opts()</a> ###


<pre><code>
opts() = #{name =&gt; <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, channel =&gt; pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, queue =&gt; binary(), module =&gt; module(), args =&gt; term(), commands =&gt; list()}
</code></pre>




### <a name="type-pool_opts">pool_opts()</a> ###


<pre><code>
pool_opts() = #{size =&gt; pos_integer(), max_overflow =&gt; pos_integer(), strategy =&gt; lifo | fifo}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#call-2">call/2</a></td><td>Makes a gen_server:call/2 to the worker or one of the workers.</td></tr><tr><td valign="top"><a href="#call-3">call/3</a></td><td>Makes a gen_server:call/3 to the worker or one of the workers.</td></tr><tr><td valign="top"><a href="#call_each-2">call_each/2</a></td><td>Makes a gen_server:call/2 to all workers.</td></tr><tr><td valign="top"><a href="#call_each-3">call_each/3</a></td><td>Makes a gen_server:call/3 to all workers.</td></tr><tr><td valign="top"><a href="#cast-2">cast/2</a></td><td>Makes a gen_server:cast/2 to the worker or one of the workers.</td></tr><tr><td valign="top"><a href="#cast_each-2">cast_each/2</a></td><td>Makes a gen_server:cast/2 to all workers.</td></tr><tr><td valign="top"><a href="#channel-0">channel/0</a></td><td>Returns the pid of the current process' AMQP channel
(if the current process is a worker).</td></tr><tr><td valign="top"><a href="#channel-1">channel/1</a></td><td>Returns the pid of the worker's AMQP channel.</td></tr><tr><td valign="top"><a href="#child_spec-1">child_spec/1</a></td><td>Returns a worker child spec.</td></tr><tr><td valign="top"><a href="#child_spec-2">child_spec/2</a></td><td>Returns a worker pool child spec.</td></tr><tr><td valign="top"><a href="#is_pool-1">is_pool/1</a></td><td>Returns whether the worker is pooled or not.</td></tr><tr><td valign="top"><a href="#send-2">send/2</a></td><td>Sends info to the worker or one of the workers.</td></tr><tr><td valign="top"><a href="#send_each-2">send_each/2</a></td><td>Sends info to all workers.</td></tr><tr><td valign="top"><a href="#start_link-1">start_link/1</a></td><td>Starts a worker.</td></tr><tr><td valign="top"><a href="#start_link-2">start_link/2</a></td><td>Starts a worker pool.</td></tr><tr><td valign="top"><a href="#where-1">where/1</a></td><td>Returns the pid of the worker or worker pool.</td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="call-2"></a>

### call/2 ###

<pre><code>
call(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term()) -&gt; term()
</code></pre>
<br />

Makes a gen_server:call/2 to the worker or one of the workers.

<a name="call-3"></a>

### call/3 ###

<pre><code>
call(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term(), Timeout::timeout()) -&gt; term()
</code></pre>
<br />

Makes a gen_server:call/3 to the worker or one of the workers.

<a name="call_each-2"></a>

### call_each/2 ###

<pre><code>
call_each(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term()) -&gt; list()
</code></pre>
<br />

Makes a gen_server:call/2 to all workers.

<a name="call_each-3"></a>

### call_each/3 ###

<pre><code>
call_each(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term(), Timeout::timeout()) -&gt; list()
</code></pre>
<br />

Makes a gen_server:call/3 to all workers.

<a name="cast-2"></a>

### cast/2 ###

<pre><code>
cast(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term()) -&gt; ok
</code></pre>
<br />

Makes a gen_server:cast/2 to the worker or one of the workers.

<a name="cast_each-2"></a>

### cast_each/2 ###

<pre><code>
cast_each(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Request::term()) -&gt; list()
</code></pre>
<br />

Makes a gen_server:cast/2 to all workers.

<a name="channel-0"></a>

### channel/0 ###

<pre><code>
channel() -&gt; pid()
</code></pre>
<br />

Returns the pid of the current process' AMQP channel
(if the current process is a worker).

<a name="channel-1"></a>

### channel/1 ###

<pre><code>
channel(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; pid()
</code></pre>
<br />

Returns the pid of the worker's AMQP channel.

<a name="child_spec-1"></a>

### child_spec/1 ###

<pre><code>
child_spec(Opts::<a href="#type-opts">opts()</a>) -&gt; <a href="/Users/bajankristof/Projects/Erlang/stdlib/doc/supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

Returns a worker child spec.

<a name="child_spec-2"></a>

### child_spec/2 ###

<pre><code>
child_spec(Opts::<a href="#type-opts">opts()</a>, PoolOpts::<a href="#type-pool_opts">pool_opts()</a>) -&gt; <a href="/Users/bajankristof/Projects/Erlang/stdlib/doc/supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

Returns a worker pool child spec.

<a name="is_pool-1"></a>

### is_pool/1 ###

<pre><code>
is_pool(Worker::pid()) -&gt; boolean
</code></pre>
<br />

Returns whether the worker is pooled or not.

<a name="send-2"></a>

### send/2 ###

<pre><code>
send(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Info::term()) -&gt; term()
</code></pre>
<br />

Sends info to the worker or one of the workers.

<a name="send_each-2"></a>

### send_each/2 ###

<pre><code>
send_each(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, Info::term()) -&gt; list()
</code></pre>
<br />

Sends info to all workers.

<a name="start_link-1"></a>

### start_link/1 ###

<pre><code>
start_link(Opts::<a href="#type-opts">opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

Starts a worker.

<a name="start_link-2"></a>

### start_link/2 ###

<pre><code>
start_link(Opts::<a href="#type-opts">opts()</a>, PoolOpts::<a href="#type-pool_opts">pool_opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

Starts a worker pool.

<a name="where-1"></a>

### where/1 ###

`where(Name) -> any()`

Returns the pid of the worker or worker pool.
-spec where(Name :: kyu:name()) -> pid() | undefined.

