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
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
cp ./nginx/nginx.conf /etc/nginx/
cp ./nginx/sites-available/default /etc/nginx/sites-available/

### Setup default settings for all virtual hosts
mkdir -p /etc/nginx/conf.d/server/
cp ./nginx/conf.d/server/1-common.conf /etc/nginx/conf.d/server/

### Create dir structure & vhost for writerviet.com
mkdir -p /var/www/writerviet.com/{web,logs,ssl}
chown -R www-data:www-data /var/www/writerviet.com
chmod -R 775 /var/www/writerviet.com
cp ./nginx/index.php /var/www/writerviet.com/web/

cp ./nginx/sites-available/writerviet.com /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/writerviet.com /etc/nginx/sites-enabled/writerviet.com

systemctl restart nginx; systemctl status nginx
