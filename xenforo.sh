#!/bin/bash

#########################################################

# 1. Install Xenforo

#########################################################


# load config vars
source .env.sh


cp -rvf ./xenforo/upload/* /var/www/writerviet.com/web/
chown -R www-data:www-data /var/www/writerviet.com/web
chmod 0777 /var/www/writerviet.com/web/data
chmod 0777 /var/www/writerviet.com/web/internal_data

## -> Goto http://writerviet.com/ to start installation
## -> cookies_required_to_use_this_site -> use Firefox instead of Chrome
## To reinstall / upgrade -> http://writerviet.com/install


## Create database

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


