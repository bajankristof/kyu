

# Module kyu_consumer #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

__Behaviours:__ [`supervisor`](supervisor.md).

<a name="types"></a>

## Data Types ##




### <a name="type-name">name()</a> ###


<pre><code>
name() = term()
</code></pre>




### <a name="type-opts">opts()</a> ###


<pre><code>
opts() = #{name =&gt; <a href="#type-name">name()</a>, queue =&gt; binary(), worker_module =&gt; atom(), worker_state =&gt; map(), worker_count =&gt; integer(), prefetch_count =&gt; integer(), commands =&gt; list()}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#await-1">await/1</a></td><td></td></tr><tr><td valign="top"><a href="#await-2">await/2</a></td><td></td></tr><tr><td valign="top"><a href="#channel-1">channel/1</a></td><td></td></tr><tr><td valign="top"><a href="#check_opts-1">check_opts/1</a></td><td></td></tr><tr><td valign="top"><a href="#child_spec-2">child_spec/2</a></td><td></td></tr><tr><td valign="top"><a href="#connection-1">connection/1</a></td><td></td></tr><tr><td valign="top"><a href="#init-1">init/1</a></td><td></td></tr><tr><td valign="top"><a href="#queue-1">queue/1</a></td><td></td></tr><tr><td valign="top"><a href="#start_link-2">start_link/2</a></td><td></td></tr><tr><td valign="top"><a href="#where-1">where/1</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="await-1"></a>

### await/1 ###

<pre><code>
await(Name::<a href="#type-name">name()</a>) -&gt; ok
</code></pre>
<br />

<a name="await-2"></a>

### await/2 ###

<pre><code>
await(Name::<a href="#type-name">name()</a>, Timeout::timeout()) -&gt; ok
</code></pre>
<br />

<a name="channel-1"></a>

### channel/1 ###

<pre><code>
channel(Name::<a href="#type-name">name()</a>) -&gt; pid() | undefined
</code></pre>
<br />

<a name="check_opts-1"></a>

### check_opts/1 ###

<pre><code>
check_opts(Opts::<a href="#type-opts">opts()</a>) -&gt; ok
</code></pre>
<br />

<a name="child_spec-2"></a>

### child_spec/2 ###

<pre><code>
child_spec(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Opts::<a href="#type-opts">opts()</a>) -&gt; <a href="supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

<a name="connection-1"></a>

### connection/1 ###

<pre><code>
connection(Name::<a href="#type-name">name()</a>) -&gt; term()
</code></pre>
<br />

<a name="init-1"></a>

### init/1 ###

`init(X1) -> any()`

<a name="queue-1"></a>

### queue/1 ###

<pre><code>
queue(Name::<a href="#type-name">name()</a>) -&gt; binary()
</code></pre>
<br />

<a name="start_link-2"></a>

### start_link/2 ###

<pre><code>
start_link(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Opts::<a href="#type-opts">opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

<a name="where-1"></a>

### where/1 ###

`where(Name) -> any()`

