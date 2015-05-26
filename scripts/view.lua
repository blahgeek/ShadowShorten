-- @Author: BlahGeek
-- @Date:   2015-05-26
-- @Last Modified by:   BlahGeek
-- @Last Modified time: 2015-05-26

local template = require "resty.template"
local http = require "resty.http"

local common = require "ShadowShorten.scripts.include.common"

local key = ngx.var[1]
local country = ngx.var.geoip_country_code

local red = common.new_redis()

local res, err = red:hmget("shorten:" .. key, "url", "blocked")
if res[1] == ngx.null then
    return common.exit(ngx.HTTP_NOT_FOUND)
end

red:set_keepalive(10000, 10)

if ngx.var[2] then
    -- in proxy
    if res[2] == "false" then -- only forbidden if not blocked
        return common.exit(ngx.HTTP_FORBIDDEN)
    else
        ngx.var.proxy_path = res[1]
        return
    end
else
    if country == "CN" and res[2] ~= "false" then
        local parsed = http:parse_uri(res[1])
        return template.render("proxy.html", {
                                domain = parsed[2],
                                url = res[1],
                                proxy = ngx.var.proxy_domain .. "/" .. key .. "/proxy"
                               })
    else
        return ngx.redirect(res[1])
    end
end

