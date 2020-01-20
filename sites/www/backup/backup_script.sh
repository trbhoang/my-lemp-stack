#!/bin/bash

#####################################
#
# Backup db & files using Restic
# Ref: https://kalifi.org/2018/01/restic-php-database.html
#
#####################################


# load config vars
source ../.env.sh

export B2_ACCOUNT_ID=$B2_ACCOUNT_ID
export B2_ACCOUNT_KEY=$B2_ACCOUNT_KEY
export RESTIC_REPOSITORY=$RESTIC_REPOSITORY
export RESTIC_PASSWORD=$RESTIC_PASSWORD


# backup website's resources
restic backup /var/www/writerviet.com

# backup db
# mysqldump -u database_user -p --all-databases | restic backup --stdin --stdin-filename all_databases.sql
mysqldump -uroot -p$DB_ROOT_PASSWD $DB_NAME | restic backup --stdin --stdin-filename /db/$DB_NAME.sql

# prune old ones
restic forget --prune --keep-daily 30 --keep-weekly 52


# scheduling the backup task with Crontab
# 0 0 * * * /path/to/backup-script.sh > /path/to/backup-script.log 2>&1


# sample restores
# restic restore latest --target /tmp/restore-web --path="/var/www/writerviet.com"
# restic restore latest --target /tmp/restore-db --path="/db"
