

# Module kyu_worker #
* [Function Index](#index)
* [Function Details](#functions)

__Behaviours:__ [`gen_server`](gen_server.md), [`poolboy_worker`](poolboy_worker.md).

__This module defines the `kyu_worker` behaviour.__<br /> Required callback functions: `handle_message/2`.

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#call-2">call/2</a></td><td></td></tr><tr><td valign="top"><a href="#call-3">call/3</a></td><td></td></tr><tr><td valign="top"><a href="#call_each-2">call_each/2</a></td><td></td></tr><tr><td valign="top"><a href="#call_each-3">call_each/3</a></td><td></td></tr><tr><td valign="top"><a href="#cast-2">cast/2</a></td><td></td></tr><tr><td valign="top"><a href="#cast_each-2">cast_each/2</a></td><td></td></tr><tr><td valign="top"><a href="#child_spec-2">child_spec/2</a></td><td></td></tr><tr><td valign="top"><a href="#get_all-1">get_all/1</a></td><td></td></tr><tr><td valign="top"><a href="#handle_call-3">handle_call/3</a></td><td></td></tr><tr><td valign="top"><a href="#handle_cast-2">handle_cast/2</a></td><td></td></tr><tr><td valign="top"><a href="#handle_info-2">handle_info/2</a></td><td></td></tr><tr><td valign="top"><a href="#init-1">init/1</a></td><td></td></tr><tr><td valign="top"><a href="#send-2">send/2</a></td><td></td></tr><tr><td valign="top"><a href="#send_each-2">send_each/2</a></td><td></td></tr><tr><td valign="top"><a href="#start_link-1">start_link/1</a></td><td></td></tr><tr><td valign="top"><a href="#start_link-2">start_link/2</a></td><td></td></tr><tr><td valign="top"><a href="#transaction-2">transaction/2</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="call-2"></a>

### call/2 ###

<pre><code>
call(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Request::term()) -&gt; term()
</code></pre>
<br />

<a name="call-3"></a>

### call/3 ###

<pre><code>
call(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Request::term(), Timeout::timeout()) -&gt; term()
</code></pre>
<br />

<a name="call_each-2"></a>

### call_each/2 ###

<pre><code>
call_each(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Request::term()) -&gt; list()
</code></pre>
<br />

<a name="call_each-3"></a>

### call_each/3 ###

<pre><code>
call_each(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Request::term(), Timeout::timeout()) -&gt; list()
</code></pre>
<br />

<a name="cast-2"></a>

### cast/2 ###

<pre><code>
cast(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Request::term()) -&gt; ok
</code></pre>
<br />

<a name="cast_each-2"></a>

### cast_each/2 ###

<pre><code>
cast_each(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Request::term()) -&gt; ok
</code></pre>
<br />

<a name="child_spec-2"></a>

### child_spec/2 ###

<pre><code>
child_spec(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Opts::<a href="kyu_consumer.md#type-opts">kyu_consumer:opts()</a>) -&gt; <a href="supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

<a name="get_all-1"></a>

### get_all/1 ###

<pre><code>
get_all(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>) -&gt; [pid()]
</code></pre>
<br />

<a name="handle_call-3"></a>

### handle_call/3 ###

`handle_call(X1, X2, State) -> any()`

<a name="handle_cast-2"></a>

### handle_cast/2 ###

`handle_cast(X1, State) -> any()`

<a name="handle_info-2"></a>

### handle_info/2 ###

`handle_info(Info, State) -> any()`

<a name="init-1"></a>

### init/1 ###

`init(X1) -> any()`

<a name="send-2"></a>

### send/2 ###

<pre><code>
send(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Info::term()) -&gt; term()
</code></pre>
<br />

<a name="send_each-2"></a>

### send_each/2 ###

<pre><code>
send_each(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Info::term()) -&gt; list()
</code></pre>
<br />

<a name="start_link-1"></a>

### start_link/1 ###

`start_link(X1) -> any()`

<a name="start_link-2"></a>

### start_link/2 ###

<pre><code>
start_link(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Opts::<a href="kyu_consumer.md#type-opts">kyu_consumer:opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

<a name="transaction-2"></a>

### transaction/2 ###

<pre><code>
transaction(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Callback::fun((pid()) -&gt; term())) -&gt; term()
</code></pre>
<br />

