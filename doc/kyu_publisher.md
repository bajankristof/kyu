

# Module kyu_publisher #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

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
opts() = #{name =&gt; <a href="#type-name">name()</a>, confirms =&gt; boolean()}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#await-1">await/1</a></td><td></td></tr><tr><td valign="top"><a href="#await-2">await/2</a></td><td></td></tr><tr><td valign="top"><a href="#call-2">call/2</a></td><td></td></tr><tr><td valign="top"><a href="#call-3">call/3</a></td><td></td></tr><tr><td valign="top"><a href="#cast-2">cast/2</a></td><td></td></tr><tr><td valign="top"><a href="#channel-1">channel/1</a></td><td></td></tr><tr><td valign="top"><a href="#child_spec-2">child_spec/2</a></td><td></td></tr><tr><td valign="top"><a href="#connection-1">connection/1</a></td><td></td></tr><tr><td valign="top"><a href="#handle_call-3">handle_call/3</a></td><td></td></tr><tr><td valign="top"><a href="#handle_cast-2">handle_cast/2</a></td><td></td></tr><tr><td valign="top"><a href="#handle_continue-2">handle_continue/2</a></td><td></td></tr><tr><td valign="top"><a href="#handle_info-2">handle_info/2</a></td><td></td></tr><tr><td valign="top"><a href="#init-1">init/1</a></td><td></td></tr><tr><td valign="top"><a href="#option-3">option/3</a></td><td></td></tr><tr><td valign="top"><a href="#publish-2">publish/2</a></td><td></td></tr><tr><td valign="top"><a href="#ref-0">ref/0</a></td><td></td></tr><tr><td valign="top"><a href="#start_link-2">start_link/2</a></td><td></td></tr><tr><td valign="top"><a href="#stop-1">stop/1</a></td><td></td></tr><tr><td valign="top"><a href="#terminate-2">terminate/2</a></td><td></td></tr><tr><td valign="top"><a href="#where-1">where/1</a></td><td></td></tr></table>


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

<a name="call-2"></a>

### call/2 ###

<pre><code>
call(Name::<a href="#type-name">name()</a>, Request::term()) -&gt; term()
</code></pre>
<br />

<a name="call-3"></a>

### call/3 ###

<pre><code>
call(Name::<a href="#type-name">name()</a>, Request::term(), Timeout::timeout()) -&gt; term()
</code></pre>
<br />

<a name="cast-2"></a>

### cast/2 ###

<pre><code>
cast(Name::<a href="#type-name">name()</a>, Request::term()) -&gt; ok
</code></pre>
<br />

<a name="channel-1"></a>

### channel/1 ###

<pre><code>
channel(Name::<a href="#type-name">name()</a>) -&gt; pid() | undefined
</code></pre>
<br />

<a name="child_spec-2"></a>

### child_spec/2 ###

<pre><code>
child_spec(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Opts::map()) -&gt; <a href="supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

<a name="connection-1"></a>

### connection/1 ###

<pre><code>
connection(Name::<a href="#type-name">name()</a>) -&gt; <a href="kyu_connection.md#type-name">kyu_connection:name()</a>
</code></pre>
<br />

<a name="handle_call-3"></a>

### handle_call/3 ###

`handle_call(Publish, Caller, State) -> any()`

<a name="handle_cast-2"></a>

### handle_cast/2 ###

`handle_cast(X1, State) -> any()`

<a name="handle_continue-2"></a>

### handle_continue/2 ###

`handle_continue(X1, State) -> any()`

<a name="handle_info-2"></a>

### handle_info/2 ###

`handle_info(X1, State) -> any()`

<a name="init-1"></a>

### init/1 ###

`init(X1) -> any()`

<a name="option-3"></a>

### option/3 ###

<pre><code>
option(Name::<a href="#type-name">name()</a>, Key::atom(), Value::term()) -&gt; term()
</code></pre>
<br />

<a name="publish-2"></a>

### publish/2 ###

<pre><code>
publish(Name::<a href="#type-name">name()</a>, Message::<a href="kyu.md#type-message">kyu:message()</a>) -&gt; ok | {error, binary()}
</code></pre>
<br />

<a name="ref-0"></a>

### ref/0 ###

<pre><code>
ref() -&gt; binary()
</code></pre>
<br />

<a name="start_link-2"></a>

### start_link/2 ###

<pre><code>
start_link(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Opts::map()) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

<a name="stop-1"></a>

### stop/1 ###

<pre><code>
stop(Name::<a href="#type-name">name()</a>) -&gt; ok
</code></pre>
<br />

<a name="terminate-2"></a>

### terminate/2 ###

`terminate(X1, State) -> any()`

<a name="where-1"></a>

### where/1 ###

`where(Name) -> any()`

