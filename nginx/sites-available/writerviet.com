server {
	listen 80;
	server_name www.writerviet.com;

	# location ~ ^/\.well-known/(.*) {}
	location / {
		return 302 http://writerviet.com$request_uri;
	}
}

server {
	listen 80;
	server_name writerviet.com;
	root /var/www/writerviet.com/web;

	include /etc/nginx/conf.d/server/common.conf;
	include /etc/nginx/conf.d/server/php.conf;

	# access_log /var/www/writerviet.com/logs/access.log;
	# error_log /var/www/writerviet.com/logs/error.log warn;
}
