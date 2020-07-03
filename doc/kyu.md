

# Module kyu #
* [Description](#description)
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

This module provides helper functions
for amqp management.

<a name="types"></a>

## Data Types ##




### <a name="type-message">message()</a> ###


<pre><code>
message() = #{routing_key =&gt; binary(), exchange =&gt; binary(), payload =&gt; binary(), mandatory =&gt; boolean(), type =&gt; binary(), headers =&gt; list(), priority =&gt; integer(), expiration =&gt; integer(), timestamp =&gt; integer(), content_type =&gt; binary(), content_encoding =&gt; binary(), delivery_mode =&gt; integer(), correlation_id =&gt; binary(), cluster_id =&gt; binary(), message_id =&gt; binary(), user_id =&gt; binary(), app_id =&gt; binary(), reply_to =&gt; binary(), execution =&gt; <a href="kyu_publisher.md#type-execution">kyu_publisher:execution()</a>, timeout =&gt; infinity | integer()}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#declare-2">declare/2</a></td><td>Makes one or more declarations on the amqp channel.</td></tr><tr><td valign="top"><a href="#publish-2">publish/2</a></td><td>Equivalent to <a href="kyu_publisher.md#publish-2"><tt>kyu_publisher:publish(Publisher, Message)</tt></a>.</td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="declare-2"></a>

### declare/2 ###

<pre><code>
declare(Channel::<a href="kyu_channel.md#type-name">kyu_channel:name()</a>, Command::list() | tuple()) -&gt; ok
</code></pre>
<br />

Makes one or more declarations on the amqp channel.

<a name="publish-2"></a>

### publish/2 ###

<pre><code>
publish(Publisher::<a href="kyu_publisher.md#type-name">kyu_publisher:name()</a>, Message::<a href="#type-message">message()</a>) -&gt; ok | {error, binary()}
</code></pre>
<br />

Equivalent to [`kyu_publisher:publish(Publisher, Message)`](kyu_publisher.md#publish-2).

