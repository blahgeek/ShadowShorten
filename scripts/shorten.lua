-- @Author: BlahGeek
-- @Date:   2015-05-26
-- @Last Modified by:   BlahGeek
-- @Last Modified time: 2015-05-26

local random = require "resty.random"
local http = require "resty.http"

local common = require "ShadowShorten.scripts.include.common"

local gen_random = function(len)
    local digits = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local digits_len = 62  -- 10 + 26 * 2

    random_raw_str = random.bytes(len)
    random_str = ''
    for i = 1, len do
        code = string.byte(random_raw_str, i)
        code = code % digits_len + 1
        random_str = random_str .. string.sub(digits, code, code)
    end

    return random_str
end

local is_block = function(url)
    -- return: true for blocked, false for not blocked, nil for unknown
    -- url must start with "http://" or "https://"
    local httpc = http.new()
    local res, err = httpc:request_uri(ngx.var.block_detect .. "/?" ..
                                       "type=gf_this_site&language=en-us&v=3&location=" .. 
                                       ngx.escape_uri(url))
    if not res then
        return nil
    end

    blocked = nil
    if string.find(res.body, "is not blocked in China") then
        blocked = false
    elseif string.find(res.body, "% blocked in China") then
        blocked = true
    end
    return blocked
end

-----------------------------------------
-- Main scripts starts here
-----------------------------------------

ngx.req.read_body()
local args, err = ngx.req.get_post_args()

url = nil
if args then url = args["url"] end

if not url then
    return common.exit(ngx.HTTP_BAD_REQUEST)
end

if not string.find(url, "http://") and not string.find(url, "https://") then
    url = "http://" .. url
end

uri_path = http:parse_uri(url)[4]
if uri_path == nil or uri_path == "" then
    url = url .. "/"  -- so that nginx would not pass uri of the original request
end

blocked = is_block(url)
key = gen_random(5)

----------------------------------------
-- Insert it into redis
----------------------------------------

local red = common.new_redis()
local ok, err = red:hmset("shorten:" .. key, {
                              url = url,
                              blocked = tostring(blocked)
                          })
if not ok then
    return common.exit(ngx.HTTP_INTERNAL_SERVER_ERROR, "Failed to insert into redis")
end

ngx.say(url)
ngx.say(key)

red:set_keepalive(10000, 10)
