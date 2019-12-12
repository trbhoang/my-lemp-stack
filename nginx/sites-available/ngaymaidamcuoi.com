server {
    listen 80;
    listen [::]:80;

    server_name ngaymaidamcuoi.com;
    set $base /var/www/ngaymaidamcuoi.com;
    root $base/web;

    include /etc/nginx/conf.d/server/common.conf;
    include /etc/nginx/conf.d/server/security.conf;
    include /etc/nginx/conf.d/server/php.conf;
}

# subdomains redirect
server {
    server_name www.ngaymaidamcuoi.com;
    return 301 https://ngaymaidamcuoi.com$request_uri;
}
