# ShadowShorten

- It's an URL shortener.
- It's a HTTP proxy for chinese users.
- It uses lua, nginx and redis (openresty)

[中文介绍](http://blog.blahgeek.com/ShadowShorten/)

[Demo](http://blaa.cf/4djtgp6c) (Visit it from chinese, otherwise it's just a shorten URL, nothing more)

## How it works

When it's going to shorten an URL, it checks if this website is blocked in china (via greatfire.org). If it is, it will provide a proxy to chinese user who visit it.

## How to run

- Install openresty with some extra module: `--with-http_spdy_module --with-http_sub_module --with-http_geoip_module`
- Install some extra lua lib (and set correct `lua_package_path` in your main `nginx.conf`):
  - [lua-resty-template](https://github.com/bungle/lua-resty-template)
  - [lua-resty-http](https://github.com/pintsized/lua-resty-http)
- Add `geoip_country GeoIP.dat;` to your main `nginx.conf` (download it from somewhere)
- (Optional) Get a wildcard SSL certification for you proxy domain and configure it in your main `nginx.conf`
- Link `ShadowShorten` directory to `/etc/nginx/apps/`
- Add `include /etc/nginx/apps/ShadowShorten/nginx.conf` to your main `nginx.conf`
- Copy `auth.htpasswd.sample` to `auth.htpasswd` and change the password
- Change `ShadowShorten/nginx.conf` as you need (domain names etc.)
- Run nginx (openresty)

## How to use

`http --form --auth user:passwd http://blaa.cf/new url="http://baidu.com"`(httpie)
