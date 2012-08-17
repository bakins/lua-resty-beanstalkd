local _M = {}

_M._VERSION = '0.0.1'

local mt = {}

local tcp = ngx.socket.tcp
local match, concat = string.match, table.concat

function _M.new()
    local sock, err = tcp()
    if not sock then
        return nil, err
    end
    return setmetatable({ sock = sock }, { __index = mt })
end

function mt.set_timeout(self, timeout)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:settimeout(timeout)
end

function mt.connect(self, host, port, ...)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    host = host or "127.0.0.1"
    port = port or 11300
    return sock:connect(host, port, ...)
end

function mt.set_keepalive(self, ...)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:setkeepalive(...)
end


function mt.get_reused_times(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:getreusedtimes()
end

function mt.close(self)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end

    return sock:close()
end

-- interface is based on https://github.com/kr/beanstalk-client-ruby

function mt.put(self, body, pri, delay, ttr)
    local sock = self.sock
    if not sock then
        return nil, "not initialized"
    end
    
    pri = pri or 65536
    delay = delay or 0
    ttr = ttr or 120
    
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
    if not sock then
        return nil, "not initialized"
    end
    
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
