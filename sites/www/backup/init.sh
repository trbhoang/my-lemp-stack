#!/bin/bash


# load config vars
source ../.env.sh

export B2_ACCOUNT_ID=$B2_ACCOUNT_ID
export B2_ACCOUNT_KEY=$B2_ACCOUNT_KEY
export RESTIC_REPOSITORY=$RESTIC_REPOSITORY
export RESTIC_PASSWORD=$RESTIC_PASSWORD


# install restic
wget https://github.com/restic/restic/releases/download/v0.9.6/restic_0.9.6_linux_amd64.bz2
bunzip2 restic_0.9.6_linux_amd64.bz2
mv restic_0.9.6_linux_amd64 /usr/bin/restic
chmod +x /usr/bin/restic


# initialize backup repository on B2
restic -r $RESTIC_REPOSITORY init

