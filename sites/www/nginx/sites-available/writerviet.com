server {
    listen 80;
    server_name writerviet.com;
    set $base /var/www/writerviet.com;
    root $base/web;

    include /etc/nginx/conf.d/server/common.conf;
    include /etc/nginx/conf.d/server/security.conf;
    include /etc/nginx/conf.d/server/php.conf;
}

# subdomains redirect
server {
    server_name www.writerviet.com;
    return 301 https://writerviet.com$request_uri;
}
