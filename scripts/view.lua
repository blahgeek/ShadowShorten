-- @Author: BlahGeek
-- @Date:   2015-05-26
-- @Last Modified by:   BlahGeek
-- @Last Modified time: 2015-05-26

local exit = function(msg, status)
    ngx.status = status
    ngx.say(msg)
    return ngx.exit(status)
end

local redis = require "resty.redis"
local template = require "resty.template"

local key = ngx.var[1]
local country = ngx.var.geoip_country_code

local red = redis:new()
red:set_timeout(1000)
local ok, err = red:connect("127.0.0.1", 6379)
if not ok then
    return exit("Failed to connect to redis", ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local res, err = red:hmget("shorten:" .. key, "url", "blocked")
if res[1] == ngx.null then
    return exit("Key not found", ngx.HTTP_NOT_FOUND)
end

red:set_keepalive(10000, 10)

if country == "CN" and res[2] ~= "false" then
    return template.render("proxy.html", {url = res[1]})
else
    return ngx.redirect(res[1])
end

