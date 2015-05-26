-- @Author: BlahGeek
-- @Date:   2015-05-26
-- @Last Modified by:   BlahGeek
-- @Last Modified time: 2015-05-26

local redis = require "resty.redis"

local _M = {}


local exit = function(status, msg)
    ngx.status = status
    if msg then ngx.say(msg) end
    return ngx.exit(status)
end

_M.exit = exit

function _M.new_redis(host, port)
    if host == nil then host = "127.0.0.1" end
    if port == nil then port = 6379 end
    local red = redis:new()
    red:set_timeout(1000)
    local ok, err = red:connect(host, port)
    if not ok then
        return exit(ngx.HTTP_INTERNAL_SERVER_ERROR, "Failed to connect to redis")
    end
    return red
end

return _M
