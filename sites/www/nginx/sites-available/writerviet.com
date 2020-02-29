server {
    listen 80;
    server_name writerviet.com;
    set $base /var/www/writerviet.com;
    root $base/web/forum;

    location /wordcounter {
        root $base/web;
    }

    location ~ ^/wordcounter/client/ {
        root    $base/web;
        access_log off;
        log_not_found off;
        add_header Cache-Control "public, no-transform, max-age=2628000";
    }

    include /etc/nginx/conf.d/server/common.conf;
    include /etc/nginx/conf.d/server/security.conf;
    include /etc/nginx/conf.d/server/php.conf;
}

# subdomains redirect
server {
    server_name www.writerviet.com;
    return 301 https://writerviet.com$request_uri;
}
