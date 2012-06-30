local _M = {}

_M._VERSION = '0.0.1'

local mt = {}

local tcp = ngx.socket.tcp
local find = string.find

function _M.new(host, port, options)
    options = options or {}
    host = host or "127.0.0.1"
    port = port or 11300
    local self = {
        keepalive_timeout = options.keepalive_timeout,
        keepalive_pool_size = options.keepalive_pool_size,
        timeout = options.timeout,
        sock = tcp()
    }
    
    local ok, err = self.sock:connect(host, port)
    if not ok then
        return nil, err
    end
    setmetatable(self, mt)
    if self.timeout then
        self.sock:settimeout(timeout)
    end
   
    return b
end

-- really close in case you really want to close it
function close(self, really_close)
    if really_close then
        return self.sock:close()
    else
        return self.sock:setkeepalive(self.keepalive_timeout, self.keepalive_pool_size)
    end
end

-- interface is based on https://github.com/kr/beanstalk-client-ruby

-- "private" helper
-- expects table of command and a table of expected 
-- returns (patterns)
-- format is expected format - mutli line, etc
local function interact(self, cmd, expect, format)
    format = format or "line"
    local sock = self.sock
    
    local bytes, err = sock:send(cmd)
    if not bytes then
        return nil, err
    end
    
    -- all responses have at least one line
    local line, err = sock:receive()
    if not line then
        return nil, err
    end
    
    if "line" == format then
        for _,pattern in ipairs(expect) do
            if find(line, pattern) then
                return true, line
            end
        end
        return false, line
    end
    
    return nil, "unknown format"
end

function mt.put(self, body, pri, delay, ttr)
    pri = pri or 65536
    delay = delay or 0
    ttr = ttr or 120

    local rc, line = 
        interact(self, 
                 {"put", pri, delay, ttr, #body, "\r\n", body, "\r\n" }, 
                 { "^INSERTED", "^BURIED"},
                 "line")
    
    if rc and line == "INSERTED" then
        return true
    else
        return rc, line
    end
end

return _M
