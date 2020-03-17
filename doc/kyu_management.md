

# Module kyu_management #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-method">method()</a> ###


<pre><code>
method() = get | post
</code></pre>




### <a name="type-response">response()</a> ###


<pre><code>
response() = {ok, map() | list()} | {error, integer(), binary()} | {error, term()}
</code></pre>




### <a name="type-route">route()</a> ###


<pre><code>
route() = string() | {string(), list()}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#declare-3">declare/3</a></td><td></td></tr><tr><td valign="top"><a href="#get_headers-1">get_headers/1</a></td><td></td></tr><tr><td valign="top"><a href="#get_queue-2">get_queue/2</a></td><td></td></tr><tr><td valign="top"><a href="#get_queue_bindings-2">get_queue_bindings/2</a></td><td></td></tr><tr><td valign="top"><a href="#get_queue_bindings-3">get_queue_bindings/3</a></td><td></td></tr><tr><td valign="top"><a href="#get_queues-1">get_queues/1</a></td><td></td></tr><tr><td valign="top"><a href="#get_url-1">get_url/1</a></td><td></td></tr><tr><td valign="top"><a href="#request-3">request/3</a></td><td></td></tr><tr><td valign="top"><a href="#request-4">request/4</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="declare-3"></a>

### declare/3 ###

<pre><code>
declare(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Channel::pid(), Command::tuple()) -&gt; ok
</code></pre>
<br />

<a name="get_headers-1"></a>

### get_headers/1 ###

<pre><code>
get_headers(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>) -&gt; list()
</code></pre>
<br />

<a name="get_queue-2"></a>

### get_queue/2 ###

<pre><code>
get_queue(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Queue::binary()) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

<a name="get_queue_bindings-2"></a>

### get_queue_bindings/2 ###

<pre><code>
get_queue_bindings(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Queue::binary()) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

<a name="get_queue_bindings-3"></a>

### get_queue_bindings/3 ###

<pre><code>
get_queue_bindings(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Queue::binary(), Exchange::binary()) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

<a name="get_queues-1"></a>

### get_queues/1 ###

<pre><code>
get_queues(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

<a name="get_url-1"></a>

### get_url/1 ###

<pre><code>
get_url(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>) -&gt; string()
</code></pre>
<br />

<a name="request-3"></a>

### request/3 ###

<pre><code>
request(Method::<a href="#type-method">method()</a>, Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Route::<a href="#type-route">route()</a>) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

<a name="request-4"></a>

### request/4 ###

<pre><code>
request(Method::<a href="#type-method">method()</a>, Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Route::<a href="#type-route">route()</a>, Body::map() | list() | binary()) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

