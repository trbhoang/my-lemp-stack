#!/bin/bash

#########################################################

# 1. Install Xenforo

#########################################################


sudo su

# load config vars
source .env.sh


cp -rvf ./xenforo/upload/* /var/www/$DOMAIN/web/
chown -R www-data:www-data /var/www/$DOMAIN/web
chmod 0777 /var/www/$DOMAIN/web/data
chmod 0777 /var/www/$DOMAIN/web/internal_data

## -> Goto http://$DOMAIN/ to start installation
## -> cookies_required_to_use_this_site -> use Firefox instead of Chrome
## To reinstall / upgrade -> http://$DOMAIN/install


## Create database
mysql -uroot -p${DB_ROOT_PASSWD} -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 collate utf8mb4_general_ci;"
mysql -uroot -p${DB_ROOT_PASSWD} -e "CREATE USER $DB_USER@localhost IDENTIFIED BY '$DB_PASSWD';"
mysql -uroot -p${DB_ROOT_PASSWD} -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -uroot -p${DB_ROOT_PASSWD} -e "FLUSH PRIVILEGES;"


# mysql -uroot -p
# CREATE DATABASE $WRV_DB;
# CREATE USER '$WRV_USER'@'localhost' IDENTIFIED BY '$WRV_PASSWD';
# GRANT ALL PRIVILEGES ON $WRV_DB.* TO '$WRV_USER'@'localhost';
# FLUSH PRIVILEGES;


## Sync production source code to local

# tar -czvf forum_20191124.tar.gz forum/
# tar -xzvf /vagrant/xenforo/forum_20191124.tar.gz
# edit src/config.php


## Sync production db

# export: mysqldump --add-drop-table -u root -p dbname > dbname.sql
# import: mysql -u root -p dbname < dbname.sql


