#!/bin/bash

#########################################################

# 1. Install Caddy Web Server
# 2. Install MariaDB
# 3. Install php7.3-fpm

#########################################################


# load config vars
source .env.sh


# Install php 7.3
add-apt-repository -y ppa:ondrej/php && apt-get update
apt-get -y install php7.3-fpm
apt-get -y install php-pear php7.3-curl php7.3-dev php7.3-gd php7.3-mbstring php7.3-zip php7.3-mysql php7.3-xml


# Install Caddy 2
wget https://github.com/caddyserver/caddy/releases/download/v2.0.0-beta12/caddy2_beta12_linux_amd64 -O caddy
sudo mv caddy /usr/bin
sudo chmod +x /usr/bin/caddy
sudo groupadd --system caddy
sudo useradd --system \
	--gid caddy \
	--create-home \
	--home-dir /var/lib/caddy \
	--shell /usr/sbin/nologin \
	--comment "Caddy web server" \
	caddy
# add user caddy to group www-data so that caddy can access php-fpm
usermod -a -G www-data caddy

mkdir -p /etc/caddy
mkdir -p /var/log/caddy
mkdir -p /var/www/html
chown -R caddy:root /etc/caddy /var/log/caddy
sudo cp ../../caddy/Caddyfile /etc/caddy/
sudo cp ../../caddy/caddy.service /etc/systemd/system/caddy.service
sudo systemctl daemon-reload
sudo systemctl enable caddy
sudo systemctl start caddy


# Install latest stable Mariadb (10.4)
apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
add-apt-repository 'deb [arch=amd64,arm64,ppc64el] https://mirrors.nxthost.com/mariadb/repo/10.4/ubuntu bionic main'
apt update
apt -y install mariadb-server mariadb-client
mysql_secure_installation

## Create database
mysql -uroot -p${DB_ROOT_PASSWD} -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 collate utf8mb4_general_ci;"
mysql -uroot -p${DB_ROOT_PASSWD} -e "CREATE USER $DB_USER@localhost IDENTIFIED BY '$DB_PASSWD';"
mysql -uroot -p${DB_ROOT_PASSWD} -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -uroot -p${DB_ROOT_PASSWD} -e "FLUSH PRIVILEGES;"




#
# Configure nginx
#

# Basic auth
sudo echo $BASIC_AUTH > /etc/nginx/.htpasswd

### Default vhost
mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
cp ./nginx/nginx.conf /etc/nginx/
# cp ./nginx/sites-available/default /etc/nginx/sites-available/
rm /etc/nginx/sites-enabled/default

### Setup default settings for all virtual hosts
mkdir -p /etc/nginx/conf.d/server/
cp ./nginx/conf.d/server/common.conf /etc/nginx/conf.d/server/
cp ./nginx/conf.d/server/security.conf /etc/nginx/conf.d/server/
cp ./nginx/conf.d/server/php.conf /etc/nginx/conf.d/server/

### Create dir structure & vhost
mkdir -p /var/www/$DOMAIN/web
chown -R www-data:www-data /var/www/$DOMAIN
chmod -R 775 /var/www/$DOMAIN
cp ./nginx/index.php /var/www/$DOMAIN/web/

cp ./nginx/sites-available/$DOMAIN /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN

systemctl restart nginx
systemctl status nginx
