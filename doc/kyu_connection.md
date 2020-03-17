

# Module kyu_connection #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

__Behaviours:__ [`gen_server`](gen_server.md).

<a name="types"></a>

## Data Types ##




### <a name="type-name">name()</a> ###


<pre><code>
name() = term()
</code></pre>




### <a name="type-opts">opts()</a> ###


<pre><code>
opts() = #{name =&gt; <a href="#type-name">name()</a>, url =&gt; iodata(), host =&gt; iolist(), port =&gt; integer(), username =&gt; binary(), password =&gt; binary(), heartbeat =&gt; integer(), virtual_host =&gt; binary(), channel_max =&gt; integer(), frame_max =&gt; integer(), ssl_options =&gt; term(), client_properties =&gt; list(), retry_sleep =&gt; integer(), max_attempts =&gt; infinity | integer(), management =&gt; #{host =&gt; iodata(), port =&gt; integer()}}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#await-1">await/1</a></td><td></td></tr><tr><td valign="top"><a href="#await-2">await/2</a></td><td></td></tr><tr><td valign="top"><a href="#call-2">call/2</a></td><td></td></tr><tr><td valign="top"><a href="#call-3">call/3</a></td><td></td></tr><tr><td valign="top"><a href="#cast-2">cast/2</a></td><td></td></tr><tr><td valign="top"><a href="#channel-1">channel/1</a></td><td></td></tr><tr><td valign="top"><a href="#channel-2">channel/2</a></td><td></td></tr><tr><td valign="top"><a href="#child_spec-1">child_spec/1</a></td><td></td></tr><tr><td valign="top"><a href="#connection-1">connection/1</a></td><td></td></tr><tr><td valign="top"><a href="#handle_call-3">handle_call/3</a></td><td></td></tr><tr><td valign="top"><a href="#handle_cast-2">handle_cast/2</a></td><td></td></tr><tr><td valign="top"><a href="#handle_continue-2">handle_continue/2</a></td><td></td></tr><tr><td valign="top"><a href="#handle_info-2">handle_info/2</a></td><td></td></tr><tr><td valign="top"><a href="#init-1">init/1</a></td><td></td></tr><tr><td valign="top"><a href="#network-1">network/1</a></td><td></td></tr><tr><td valign="top"><a href="#option-3">option/3</a></td><td></td></tr><tr><td valign="top"><a href="#start_link-1">start_link/1</a></td><td></td></tr><tr><td valign="top"><a href="#stop-1">stop/1</a></td><td></td></tr><tr><td valign="top"><a href="#subscribe-1">subscribe/1</a></td><td></td></tr><tr><td valign="top"><a href="#terminate-2">terminate/2</a></td><td></td></tr><tr><td valign="top"><a href="#where-1">where/1</a></td><td>Returns the pid of the connection server process.</td></tr></table>


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
channel(Name::<a href="#type-name">name()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

<a name="channel-2"></a>

### channel/2 ###

<pre><code>
channel(Name::<a href="#type-name">name()</a>, Commands::list()) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

<a name="child_spec-1"></a>

### child_spec/1 ###

<pre><code>
child_spec(Opts::<a href="#type-opts">opts()</a>) -&gt; <a href="supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

<a name="connection-1"></a>

### connection/1 ###

<pre><code>
connection(Name::<a href="#type-name">name()</a>) -&gt; pid() | undefined
</code></pre>
<br />

<a name="handle_call-3"></a>

### handle_call/3 ###

`handle_call(X1, Caller, State) -> any()`

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

`init(Opts) -> any()`

<a name="network-1"></a>

### network/1 ###

<pre><code>
network(Name::<a href="#type-name">name()</a>) -&gt; #amqp_params_network{}
</code></pre>
<br />

<a name="option-3"></a>

### option/3 ###

<pre><code>
option(Name::<a href="#type-name">name()</a>, Key::atom(), Value::term()) -&gt; term()
</code></pre>
<br />

<a name="start_link-1"></a>

### start_link/1 ###

<pre><code>
start_link(Opts::<a href="#type-opts">opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

<a name="stop-1"></a>

### stop/1 ###

<pre><code>
stop(Name::<a href="#type-name">name()</a>) -&gt; ok
</code></pre>
<br />

<a name="subscribe-1"></a>

### subscribe/1 ###

<pre><code>
subscribe(Name::<a href="#type-name">name()</a>) -&gt; ok
</code></pre>
<br />

<a name="terminate-2"></a>

### terminate/2 ###

`terminate(X1, State) -> any()`

<a name="where-1"></a>

### where/1 ###

`where(Name) -> any()`

Returns the pid of the connection server process.

