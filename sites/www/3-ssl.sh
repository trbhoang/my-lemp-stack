#!/bin/bash

#########################################################

# Setup Letsencrypt
# Ref: https://github.com/Neilpang/acme.sh

#########################################################


# load config vars
source .env.sh


# install certbot
add-apt-repository ppa:certbot/certbot
apt-get update
apt-get install certbot python-certbot-nginx


# issue certificate
# or just get certificate: certbot certonly --nginx
certbot --nginx


# renew: certbot renew
# test renew: certbot renew --dry-run
# renew cron: /etc/cron.d/certbot


