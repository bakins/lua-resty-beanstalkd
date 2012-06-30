lua-nginx-beanstalkd
====================

lua-resty-beanstalkd - Lua beanstalkd client driver for the ngx_lua
based on the cosocket API

Originally based on the
[lua-resty-memcached](https://github.com/agentzh/lua-resty-memcached)
library.

Influence by [beanstalk-client-ruby](https://github.com/kr/beanstalk-client-ruby)

Status
======

This library is currently very unstable. It is being written
primarily for the author's education of ngx_lua cosockets.

Only the "put" and "delete" commands are supported. Only the default beanstalkd
tube may be used. I only need put for my purposes, but delete makes
testing much easier.

Description
===========

This Lua library is a beanstalkd client driver for the [ngx_lua nginx module](http://wiki.nginx.org/HttpLuaModule)

This Lua library takes advantage of ngx_lua's cosocket API, which ensures
100% nonblocking behavior.

Note that at least [ngx\_lua 0.5.0rc29](https://github.com/chaoslawful/lua-nginx-module/tags) or [ngx\_openresty 1.0.15.7](http://openresty.org/#Download) is required.

This library does not follow the general interface that other nginx
resty modules use.  The interface is simplified (in the author's
opinion) and influenced by the ruby client.  It also uses the author's
general Lua style rather.

Synopsis
========

    lua_package_path "/path/to/lua-resty-beanstalkd/lib/?.lua;;";
    location /t {
        content_by_lua '
            local beanstalkd = require "nginx.beanstalkd"
            local b = beanstalkd.new()
            local ok, id, err = b:put("foo")
            ngx.say(ok)
            ok, err = b:delete(id)
            ngx.say(ok)
            b:close()
        ';
    }

Methods
=======

new
---
`syntax: b = beanstalkd:new(host, port, options)`

Creates a beanstalkd object. Returns `nil` on error. Host defaults to
_127.0.0.1_. Port defaults to _11300_. Options should be a table with
these keys:

* keepalive_timeout - timeout argument to
  [setkeepalive](http://wiki.nginx.org/HttpLuaModule#tcpsock:setkeepalive)
* keepalive\_pool\_size    - size argument to
  [setkeepalive](http://wiki.nginx.org/HttpLuaModule#tcpsock:setkeepalive)
* timeout - time argument to [settimeout](http://wiki.nginx.org/HttpLuaModule#tcpsock:settimeout)  

put
---
`syntax: rc, id, err = b:put(body, pri, delay, ttr)`

Put _body_ into the tube.  Defaults are:

* pri - 65536
* delay - 0
* ttr - 120

Returns:

* rc - true id job was successfully queued. beanstalkd: INSERTED
* id - job id.  This will only be valid if the job was _inserted_ or
  _buried_
* err - error message.  If rc is _false_ and id id valid, this is
usually _BURIED_

delete
-----
`syntax: rc, err = b:delete(id)`

Delete a job.

Returns:

* rc - true is job was succeccfully deleted
* err - error message

Limitations
===========

* This library cannot be used in code contexts like set_by_lua*, log_by_lua*, and
header_filter_by_lua* where the ngx_lua cosocket API is not available.
* The `nginx.beanstalkd` object instance cannot be stored in a Lua variable at the Lua module level,
because it will then be shared by all the concurrent requests handled by the same nginx
 worker process (see
http://wiki.nginx.org/HttpLuaModule#Data_Sharing_within_an_Nginx_Worker ) and
result in bad race conditions when concurrent requests are trying to use the same `resty.memcached` instance.
You should always initiate `nginx.beanstalkd` objects in function local
variables or in the `ngx.ctx` table. These places all have their own data copies for
each request.


TODO
====
* implement "use" for tubes.  I'd rather avoid having to switch tubes
  during evey command, but the current implementation of ngx_lua
  cosockets only uses a pool per host:port pair, so we are unable to
  use tubes in a very simple way. I probably could do a tube per
  client, but we would have to send/receive the "use" command for
  every clinet creation, which seems very wasteful. Perhaps a "pool"
  of beanstalkd clients??
* implement other commands.  I generally am tetsing with putting from
  nginx and handling jobs with a simple Ruby script.  

Author
======

Brian Akins <brian@akins.org>

Heavily influenced by  Zhang "agentzh" Yichun (章亦春) <agentzh@gmail.com>.

Copyright and License
=====================

This module is licensed under the BSD license.

Copyright (C) 2012, by Brian Akins <brian@akins.org>.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

See Also
========
* the [ngx_lua module](http://wiki.nginx.org/HttpLuaModule)
* the [beanstalkd wired protocol specification](https://github.com/kr/beanstalkd/blob/master/doc/protocol.txt)
* the [lua-resty-memcached](https://github.com/agentzh/lua-resty-memcached) library.
*  [beanstalk-client-ruby](https://github.com/kr/beanstalk-client-ruby)
