server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	server_name ngaymaidamcuoi.com;
	set $base /var/www/ngaymaidamcuoi.com;
	root $base/web;

	# SSL
	ssl_certificate /etc/letsencrypt/live/ngaymaidamcuoi.com/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/ngaymaidamcuoi.com/privkey.pem;
	include /etc/letsencrypt/options-ssl-nginx.conf;
	ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

	# security
	include /etc/nginx/conf.d/server/common.conf;
	include /etc/nginx/conf.d/server/security.conf;
	include /etc/nginx/conf.d/server/php.conf;
}

# subdomains redirect
server {
	listen 443 ssl http2;
	listen [::]:443 ssl http2;

	server_name www.ngaymaidamcuoi.com;

	# SSL
	ssl_certificate /etc/letsencrypt/live/ngaymaidamcuoi.com/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/ngaymaidamcuoi.com/privkey.pem;
	include /etc/letsencrypt/options-ssl-nginx.conf;
	ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

	return 301 https://ngaymaidamcuoi.com$request_uri;
}

# HTTP redirect
server {
	listen 80;
	listen [::]:80;

	server_name .ngaymaidamcuoi.com;

	include /etc/nginx/conf.d/server/letsencrypt.conf;

	location / {
		return 301 https://ngaymaidamcuoi.com$request_uri;
	}
}
