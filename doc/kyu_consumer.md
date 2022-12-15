

# Module kyu_consumer #
* [Description](#description)
* [Data Types](#types)
* [Function Index](#index)
* [Function Details](#functions)

This module is responsible for creating
and managing queue consumers.

__Behaviours:__ [`supervisor`](supervisor.md).

<a name="types"></a>

## Data Types ##




### <a name="type-opts">opts()</a> ###


<pre><code>
opts() = #{id =&gt; <a href="/Users/bajankristof/Projects/Erlang/stdlib/doc/supervisor.md#type-child_id">supervisor:child_id()</a>, name =&gt; <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, connection =&gt; pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>, module =&gt; module(), args =&gt; term(), prefetch_count =&gt; pos_integer(), commands =&gt; list(), duplex =&gt; boolean()}
</code></pre>

<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#channel-1">channel/1</a></td><td>Returns the pid of the consumer's AMQP channel.</td></tr><tr><td valign="top"><a href="#check_opts-1">check_opts/1</a></td><td>Checks the validity of the provided consumer options.</td></tr><tr><td valign="top"><a href="#child_spec-1">child_spec/1</a></td><td>Returns a consumer child spec.</td></tr><tr><td valign="top"><a href="#start_link-1">start_link/1</a></td><td>Starts a consumer.</td></tr><tr><td valign="top"><a href="#where-1">where/1</a></td><td>Returns the pid of the consumer.</td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="channel-1"></a>

### channel/1 ###

<pre><code>
channel(Ref::pid() | <a href="/Users/bajankristof/Projects/Erlang/kyu/doc/kyu.md#type-name">kyu:name()</a>) -&gt; pid()
</code></pre>
<br />

Returns the pid of the consumer's AMQP channel.

<a name="check_opts-1"></a>

### check_opts/1 ###

<pre><code>
check_opts(Opts::<a href="#type-opts">opts()</a>) -&gt; ok
</code></pre>
<br />

throws `badmatch`

Checks the validity of the provided consumer options.

<a name="child_spec-1"></a>

### child_spec/1 ###

<pre><code>
child_spec(Opts::<a href="#type-opts">opts()</a>) -&gt; <a href="/Users/bajankristof/Projects/Erlang/stdlib/doc/supervisor.md#type-child_spec">supervisor:child_spec()</a>
</code></pre>
<br />

Returns a consumer child spec.

<a name="start_link-1"></a>

### start_link/1 ###

<pre><code>
start_link(Opts::<a href="#type-opts">opts()</a>) -&gt; {ok, pid()} | {error, term()}
</code></pre>
<br />

Starts a consumer.

<a name="where-1"></a>

### where/1 ###

`where(Name) -> any()`

Returns the pid of the consumer.
-spec where(Name :: kyu:name()) -> pid() | undefined.

