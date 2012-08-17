Name
====

lua-resty-beanstalkd - Lua beanstalkd client driver for the ngx_lua
based on the cosocket API

Based on the
[lua-resty-memcached](https://github.com/agentzh/lua-resty-memcached)
library.

Influenced by [beanstalk-client-ruby](https://github.com/kr/beanstalk-client-ruby)

Status
======

This library is currently very unstable. It is being written
primarily for the author's education of ngx_lua cosockets.

Only the "put" and "delete" commands are supported. Only the default beanstalkd
tube may be used. 

Description
===========

This Lua library is a beanstalkd client driver for the ngx_lua nginx module:

http://wiki.nginx.org/HttpLuaModule

This Lua library takes advantage of ngx\_lua's cosocket API, which ensures
100% nonblocking behavior.

Note that at least [ngx_lua 0.5.0rc29](https://github.com/chaoslawful/lua-nginx-module/tags) or [ngx_openresty 1.0.15.7](http://openresty.org/#Download) is required.

Synopsis
========

    lua_package_path "/path/to/lua-resty-beanstalkd/lib/?.lua;;";

    server {
        location /test {
            content_by_lua '
                local beanstalkd = require "resty.beanstalkd"
                local b = beanstalkd.new()
                local ok, err = b:connect()
                if not ok then
                    ngx.say("failed to connect: ", err)
                    return
                end
                local ok, id, err = b:put("foo")
                ngx.say(ok)
                ok, err = b:delete(id)
                ngx.say(ok)
                b:close()
            ';
        }
    }

Methods
=======


new
---
`syntax: b, err = beanstalkd:new()`

Creates a beanstalkd object. In case of failures, returns `nil` and a string describing the error.

connect
-------
`syntax: ok, err = b:connect(host, port)`

Attempts to connect to the remote host and port that the beanstalkd server is listening to or a local unix domain socket file listened by the beanstalkd server.

Before actually resolving the host name and connecting to the remote
backend, this method will always look up the connection pool for
matched idle connections created by previous calls of this method.

Host defaults to _127.0.0.1_ and port defaults to _11300_.

put
---
`syntax: ok, id, err = b:put(body, pri, delay, ttr)`

Inserts a job into the queue. 

 _body_ should be a string.

_pri_ is the priority and defaults to 65536

_delay_ defaults to 0

_ttr_  -- time to run -- defaults to 0

In case of success, returns `true` and the job id.  On error, it will
return `false`, `nil`, and an error message.

delete
-----
`syntax: ok, id, err = b:delete(id)`

Deletes a job from the queue.

In case of success, returns `true`.  On error, it will
return `false` and an error message.


set_timeout
----------
`syntax: b:set_timeout(time)`

Sets the timeout (in ms) protection for subsequent operations, including the `connect` method.

set_keepalive
------------
`syntax: ok, err = b:set_keepalive(max_idle_timeout, pool_size)`

Keeps the current beanstalkd connection alive and put it into the ngx_lua cosocket connection pool.

You can specify the max idle timeout (in ms) when the connection is in the pool and the maximal size of the pool every nginx worker process.

In case of success, returns `1`. In case of errors, returns `nil` with a string describing the error.

get_reused_times
----------------
`syntax: times, err = b:get_reused_times()`

This method returns the (successfully) reused times for the current connection. In case of error, it returns `nil` and a string describing the error.

If the current connection does not come from the built-in connection pool, then this method always returns `0`, that is, the connection has never been reused (yet). If the connection comes from the connection pool, then the return value is always non-zero. So this method can also be used to determine if the current connection comes from the pool.

close
-----
`syntax: ok, err = memc:close()`

Closes the current beanstalkd connection and returns the status.

In case of success, returns `1`. In case of errors, returns `nil` with a string describing the error.

Limitations
===========

* This library cannot be used in code contexts like set_by_lua*, log_by_lua*, and
header_filter_by_lua* where the ngx_lua cosocket API is not available.
* The `resty.beanstalkd` object instance cannot be stored in a Lua variable at the Lua module level,
because it will then be shared by all the concurrent requests handled by the same nginx
 worker process (see
http://wiki.nginx.org/HttpLuaModule#Data_Sharing_within_an_Nginx_Worker ) and
result in bad race conditions when concurrent requests are trying to use the same `resty.beanstalkd` instance.
You should always initiate `resty.beanstalkd` objects in function local
variables or in the `ngx.ctx` table. These places all have their own data copies for
each request.
* Only the default tube is used.

TODO
====

* Support the `use` command

Author
======

Brian Akins <brian@akins.org>

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2012, by Brian Akins <brian@akins.org>.

Portions of the code are from [lua-resty-memcached](https://github.com/agentzh/lua-resty-memcached) Copyright (C) 2012, by Zhang "agentzh" Yichun (章亦春) <agentzh@gmail.com>.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

See Also
========
* the ngx_lua module: http://wiki.nginx.org/HttpLuaModule
* the beanstalkd protocol specification: https://github.com/kr/beanstalkd/blob/master/doc/protocol.txt
* the [lua-resty-memcached](https://github.com/agentzh/lua-resty-memcached) library.
* the [lua-resty-redis](https://github.com/agentzh/lua-resty-redis) library.
* the [lua-resty-mysql](https://github.com/agentzh/lua-resty-mysql) library.

