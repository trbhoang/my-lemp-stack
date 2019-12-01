#!/bin/bash


# load config vars
source .env.sh


wget https://repo.zabbix.com/zabbix/4.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.4-1+bionic_all.deb
dpkg -i zabbix-release_4.4-1+bionic_all.deb
rm https://repo.zabbix.com/zabbix/4.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_4.4-1+bionic_all.deb
apt update

apt -y install zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-agent

mysql -uroot -p${ROOT_PASSWD} -e "CREATE DATABASE zabbix CHARACTER SET utf8 collate utf8_bin;"
mysql -uroot -p${ROOT_PASSWD} -e "CREATE USER zabbix@localhost IDENTIFIED BY 'zabbix';"
mysql -uroot -p${ROOT_PASSWD} -e "GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';"
mysql -uroot -p${ROOT_PASSWD} -e "FLUSH PRIVILEGES;"

# import initial schema and data
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p zabbix

sed -i 's/# DBPassword=/DBPassword=zabbix/g' /etc/zabbix/zabbix_server.conf

# nginx
cp ./nginx/sites-available/zabbix /etc/nginx/sites-available/zabbix
ln -s /etc/nginx/sites-available/zabbix /etc/nginx/sites-enabled/zabbix

# php-fpm pool
cp ./zabbix/zabbix-php-fpm.conf /etc/php/7.3/fpm/pool.d/

# start Zabbix server and agent processes
systemctl restart zabbix-server zabbix-agent
systemctl enable zabbix-server zabbix-agent


# defaut zabbix web login: Admin / zabbix
