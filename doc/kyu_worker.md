

# Module kyu_worker #
* [Description](#description)
* [Function Index](#index)
* [Function Details](#functions)

This module is responsible for commication
with and between consumer workers.

__Behaviours:__ [`gen_server`](gen_server.md), [`poolboy_worker`](poolboy_worker.md).

__This module defines the `kyu_worker` behaviour.__<br /> Required callback functions: `handle_message/2`.

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#get_all-1">get_all/1</a></td><td>Returns the worker pids.</td></tr><tr><td valign="top"><a href="#send-2">send/2</a></td><td>Sends info to one of the worker processes (in round-robin fashion).</td></tr><tr><td valign="top"><a href="#send_each-2">send_each/2</a></td><td>Sends info to all of the worker processes.</td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="get_all-1"></a>

### get_all/1 ###

<pre><code>
get_all(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>) -&gt; [pid()]
</code></pre>
<br />

Returns the worker pids.

<a name="send-2"></a>

### send/2 ###

<pre><code>
send(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Info::term()) -&gt; term()
</code></pre>
<br />

Sends info to one of the worker processes (in round-robin fashion).

<a name="send_each-2"></a>

### send_each/2 ###

<pre><code>
send_each(Name::<a href="kyu_consumer.md#type-name">kyu_consumer:name()</a>, Info::term()) -&gt; list()
</code></pre>
<br />

Sends info to all of the worker processes.

