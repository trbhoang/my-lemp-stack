#!/bin/bash


# REF: https://www.kiloroot.com/mysql-database-backup-part-3-remote-backup-using-rsync/
#      https://www.freecodecamp.org/news/cronjob-ransomware-attack/
# Import db:
# 		mysql -uroot -p$DB_ROOT_PASSWD $DB_NAME < $DB_NAME-$DATE.sql


# load config vars
source ../.env.sh


DATE=`date +%Y%m%d_%H%M`

mkdir -p /opt/backup/db
cd /opt/backup/db

mysqldump -uroot -p$DB_ROOT_PASSWD $DB_NAME > $DB_NAME-$DATE.sql
tar -czvf $DB_NAME-$DATE.tar.gz $DB_NAME-$DATE.sql
rm $DB_NAME-$DATE.sql

find /opt/backup/db/* -type f -mtime +20 -delete



