-- @Author: BlahGeek
-- @Date:   2015-05-26
-- @Last Modified by:   BlahGeek
-- @Last Modified time: 2015-05-26

local common = require "ShadowShorten.scripts.include.common"

local key = ngx.var.key;
local red = common.new_redis()

local res, err = red:hmget("shorten:" .. key, "host", "uri", "blocked")
local host, uri, blocked = unpack(res)
if host == ngx.null then
    return common.exit(ngx.HTTP_NOT_FOUND)
end

red:set_keepalive(10000, 10)

if blocked == "false" then -- only forbidden if not blocked
    return common.exit(ngx.HTTP_FORBIDDEN)
else
    ngx.var.custom_proxy_host = host
    return
end
