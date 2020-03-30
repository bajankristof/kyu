

# Module kyu_management #
* [Description](#description)
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

This module provides an interface to communicate
with the RabbitMQ management HTTP API.

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


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#get_queue-2">get_queue/2</a></td><td>Returns details about the provided queue.</td></tr><tr><td valign="top"><a href="#get_queue_bindings-2">get_queue_bindings/2</a></td><td>Returns the bindings declared on the provided queue.</td></tr><tr><td valign="top"><a href="#get_queue_bindings-3">get_queue_bindings/3</a></td><td>Returns the bindings in an exchange declared on the provided queue.</td></tr><tr><td valign="top"><a href="#get_queues-1">get_queues/1</a></td><td>Returns the queues declared on the provided connection.</td></tr><tr><td valign="top"><a href="#request-3">request/3</a></td><td>Equivalent to <a href="kyu_management.md#request-4"><tt>kyu_management:request(Method, Connection, Route, &lt;&lt;&gt;&gt;)</tt></a>.</td></tr><tr><td valign="top"><a href="#request-4">request/4</a></td><td>Makes a request to the RabbitMQ management HTTP API.</td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="get_queue-2"></a>

### get_queue/2 ###

<pre><code>
get_queue(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Queue::binary()) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

Returns details about the provided queue.
__This function respects the virtual_host option of the connection__.

<a name="get_queue_bindings-2"></a>

### get_queue_bindings/2 ###

<pre><code>
get_queue_bindings(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Queue::binary()) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

Returns the bindings declared on the provided queue.
__This function respects the virtual_host option of the connection__.

<a name="get_queue_bindings-3"></a>

### get_queue_bindings/3 ###

<pre><code>
get_queue_bindings(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Queue::binary(), Exchange::binary()) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

Returns the bindings in an exchange declared on the provided queue.
__This function respects the virtual_host option of the connection__.

<a name="get_queues-1"></a>

### get_queues/1 ###

<pre><code>
get_queues(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

Returns the queues declared on the provided connection.
__This function respects the virtual_host option of the connection__.

<a name="request-3"></a>

### request/3 ###

<pre><code>
request(Method::<a href="#type-method">method()</a>, Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Route::<a href="#type-route">route()</a>) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

Equivalent to [`kyu_management:request(Method, Connection, Route, <<>>)`](kyu_management.md#request-4).

<a name="request-4"></a>

### request/4 ###

<pre><code>
request(Method::<a href="#type-method">method()</a>, Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Route::<a href="#type-route">route()</a>, Body::map() | list() | binary()) -&gt; <a href="#type-response">response()</a>
</code></pre>
<br />

Makes a request to the RabbitMQ management HTTP API.

