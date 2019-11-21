#!/bin/bash

#########################################################

# 1. Install latest Nginx
# 2. Install MariaDB
# 3. Install php7.3-fpm
# (4). Config virtual hosts for nginx

# Reference: https://github.com/lucien144/lemp-stack

#########################################################


# load config vars
source .env.sh


# Install Nginx (1.16)
add-apt-repository -y ppa:nginx/stable && apt-get update
apt-get -y install nginx


# Install latest stable Mariadb (10.4)
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mirrors.nxthost.com/mariadb/repo/10.4/ubuntu bionic main'
apt update
apt -y install mariadb-server mariadb-client
mysql_secure_installation


# Install php 7.3.
add-apt-repository -y ppa:ondrej/php && apt-get update
apt-get -y install php7.3-fpm
apt-get -y install php-pear php7.3-curl php7.3-dev php7.3-gd php7.3-mbstring php7.3-zip php7.3-mysql php7.3-xml


#
# Configure nginx
#

### Default vhost
mv /etc/nginx/nginx.conf /etc/nginx/ngin.conf.bak
mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
cp ./nginx/nginx.conf /etc/nginx/
cp ./nginx/sites-available/default /etc/nginx/sites-available/

### Setup default settings for all virtual hosts
mkdir -p /etc/nginx/conf.d/server/
cp ./nginx/conf.d/server/1-common.conf /etc/nginx/conf.d/server/

### Create dir structure for new website
mkdir -p /var/www/vhosts/$SITE_NAME/{web,logs,ssl}
chown -R www-data:www-data /var/www/vhosts/$SITE_NAME
chmod -R 775 /var/www/vhosts/$SITE_NAME
cp ./nginx/index.php /var/www/vhosts/$SITE_NAME/web/

### Create new vhost for website
touch /etc/nginx/sites-available/$SITE_NAME
echo "server {
	listen 80;
	server_name www.$SITE_NAME;
	location ~ ^/\.well-known/(.*) {}
	location / {
		return 302 http://$SITE_NAME$request_uri;
	}
}
server {
	listen 80;

	root /var/www/vhosts/$SITE_NAME/web;
	index index.php index.html index.htm;

	server_name $SITE_NAME;

	include /etc/nginx/conf.d/server/1-common.conf;

	access_log /var/www/vhosts/$SITE_NAME/logs/access.log;
	error_log /var/www/vhosts/$SITE_NAME/logs/error.log warn;

	location ~ \.php$ {
		try_files \$uri \$uri/ /index.php?$args;
		fastcgi_split_path_info ^(.+\.php)(/.+)$;
		fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
		fastcgi_index index.php;
		fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
		include fastcgi_params;
	}
}" > /etc/nginx/sites-available/$SITE_NAME

ln -s /etc/nginx/sites-available/$SITE_NAME /etc/nginx/sites-enabled/$SITE_NAME
systemctl restart nginx; systemctl status nginx
