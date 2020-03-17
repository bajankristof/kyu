

# Module kyu #
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

<a name="types"></a>

## Data Types ##




### <a name="type-message">message()</a> ###


<pre><code>
message() = #{routing_key =&gt; binary(), exchange =&gt; binary(), payload =&gt; binary(), timeout =&gt; integer(), mandatory =&gt; boolean(), headers =&gt; list(), priority =&gt; integer(), expiration =&gt; integer(), content_type =&gt; binary(), content_encoding =&gt; binary(), delivery_mode =&gt; integer(), correlation_id =&gt; binary(), message_id =&gt; binary(), user_id =&gt; binary(), app_id =&gt; binary(), reply_to =&gt; binary(), execution =&gt; <a href="kyu_publisher.md#type-execution">kyu_publisher:execution()</a>}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#declare-3">declare/3</a></td><td></td></tr><tr><td valign="top"><a href="#publish-2">publish/2</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="declare-3"></a>

### declare/3 ###

<pre><code>
declare(Connection::<a href="kyu_connection.md#type-name">kyu_connection:name()</a>, Channel::pid(), Command::list() | tuple()) -&gt; term()
</code></pre>
<br />

<a name="publish-2"></a>

### publish/2 ###

<pre><code>
publish(Publisher::<a href="kyu_publisher.md#type-name">kyu_publisher:name()</a>, Message::<a href="#type-message">message()</a>) -&gt; ok | {error, binary()}
</code></pre>
<br />

