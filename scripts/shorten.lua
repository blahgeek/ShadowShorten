-- @Author: BlahGeek
-- @Date:   2015-05-26
-- @Last Modified by:   BlahGeek
-- @Last Modified time: 2015-05-30

local random = require "resty.random"
local http = require "resty.http"

local common = require "ShadowShorten.scripts.include.common"

local gen_random = function(len)
    local DIGITS = "0123456789abcdefghijklmnopqrstuvwxyz"
    local DIGITS_LEN = 36  -- 10 + 26

    local random_raw_str = random.bytes(len)
    local random_str = ''
    for i = 1, len do
        local code = string.byte(random_raw_str, i)
        code = code % DIGITS_LEN + 1
        random_str = random_str .. string.sub(digits, code, code)
    end

    return random_str
end

local is_block = function(url)
    -- return: true for blocked, false for not blocked, nil for unknown
    -- url must start with "http://" or "https://"
    local httpc = http.new()
    local req_url = string.format("%s/?type=gf_this_site&language=en-us&v=3&location=%s",
                                  ngx.var.block_detect, ngx.escape_uri(url))
    local res, err = httpc:request_uri(req_url)
    if not res then return nil end

    if string.find(res.body, "is not blocked in China") then
        local blocked = false
    elseif string.find(res.body, "% blocked in China") then
        local blocked = true
    end
    return blocked -- maybe nil
end

-----------------------------------------
-- Main scripts starts here
-----------------------------------------

ngx.req.read_body()
local args, err = ngx.req.get_post_args()

local url = args and args["url"]
if not url then return common.exit(ngx.HTTP_BAD_REQUEST) end

local ttl = args and args["ttl"]

if not string.find(url, "http://") and not string.find(url, "https://") then
    url = "http://" .. url
end

local url_scheme, url_host, url_port, url_path = unpack(http:parse_uri(url))
local url_scheme_host = url_scheme .. "://" .. url_host .. ":" .. tostring(url_port)
if url_path == nil or url_path == "" then url_path = "/" end

local blocked = is_block(url_scheme_host)
local key = gen_random(tonumber(ngx.var.random_key_len))

----------------------------------------
-- Insert it into redis
----------------------------------------

local red = common.new_redis()
local ok, err = red:hmset("shorten:" .. key, {
                            host = url_scheme_host,
                            uri = url_path,
                            blocked = tostring(blocked)
                          })
if not ok then
    return common.exit(ngx.HTTP_INTERNAL_SERVER_ERROR, "Failed to insert into redis")
end

if ttl then red:expire("shorten" .. key, ttl) end

ngx.say(key)

red:set_keepalive(10000, 10)
