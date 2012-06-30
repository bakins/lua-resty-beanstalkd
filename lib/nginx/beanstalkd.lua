local _M = {}

_M._VERSION = '0.0.1'

local mt = {}

local tcp = ngx.socket.tcp
local match, concat = string.match, table.concat


-- the issue as currently implemented is if we get a keepalive connection
-- and we had specified a tube on it, but do not on this client, then we will
-- still be interacting with the tube that was set on the keepalive connection
-- so, don't use it as it is dangerous if you do not know this
local function use(self, tube)
    local sock = self.sock
    local cmd =  {"use ", tube, "\r\n" }
    local bytes, err = sock:send(cmd)
    if not bytes then
        return nil, err
    end
    local line, err = sock:receive()
    if not line then
        return nil, err
    end
    
    if ("USING " .. tube) ~= line then
        return nil, line
    end
    return true
end

function _M.new(host, port, options)
    options = options or {}
    host = host or "127.0.0.1"
    port = port or 11300
    local self = {
        keepalive_timeout = options.keepalive_timeout,
        keepalive_pool_size = options.keepalive_pool_size,
        timeout = options.timeout,
        tube = options.tube or "default",
        sock = tcp()
    }
    
    local ok, err = self.sock:connect(host, port)
    if not ok then
        return nil, err
    end
    if self.timeout then
        self.sock:settimeout(timeout)
    end

    if "default" ~= self.tube then
        local ok, err = use(self, self.tube)
        if not ok then
            return nil, ("error using tube: " .. err)
        end
    end

    setmetatable(self, { __index = mt })
    return self
end

-- really close in case you really want to close it
function mt.close(self, really_close)
    if really_close then
        return self.sock:close()
    else
        if self.keepalive_timeout or self.keepalive_pool_size then
            return self.sock:setkeepalive(self.keepalive_timeout, self.keepalive_pool_size)
        else
            return self.sock:setkeepalive()
        end
    end
end

-- interface is based on https://github.com/kr/beanstalk-client-ruby

function mt.put(self, body, pri, delay, ttr)
    pri = pri or 65536
    delay = delay or 0
    ttr = ttr or 120
    local sock = self.sock
    
    local cmd =  {"put ", pri, " ", delay, " ", ttr, " ", #body, "\r\n", body, "\r\n" }
    local bytes, err = sock:send(cmd)
    if not bytes then
        return nil, err
    end
    local line, err = sock:receive()
    if not line then
         return nil, err
    end
    
    local status, id = match(line, '(%u+)%s+(%d+)$')
    if not status then
        return nil, nil, line
    end
    if "INSERTED" == status then
        return true, id, status
    else
        return false, id, status
    end
end

function mt.delete(self, id)
    local sock = self.sock
    local cmd =  {"delete ", id, "\r\n" }
    local bytes, err = sock:send(cmd)
    if not bytes then
        return nil, err
    end
    local line, err = sock:receive()
    if not line then
         return nil, err
    end
    
    if "DELETED" == line then
        return true, line
    end
    return false, line
end

return _M
