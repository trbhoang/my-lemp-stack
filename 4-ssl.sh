#!/bin/bash

#########################################################

# Setup Letsencrypt
# Ref: https://github.com/Neilpang/acme.sh

#########################################################


# load config vars
source .env.sh


# create a common ACME-challenge directory (for Let's Encrypt)
mkdir -p /var/www/_letsencrypt
chown www-data /var/www/_letsencrypt

# install acme script
curl https://get.acme.sh | sh
LE_WORKING_DIR="/root/.acme.sh"


# issue a cert
/root/.acme.sh/acme.sh  --issue --nginx -d $DOMAIN  -d "www.$DOMAIN" -w /var/www/_letsencrypt

# install the certs to Nginx
/root/.acme.sh/acme.sh --install-cert -d $DOMAIN \
	--key-file       /var/www/$DOMAIN/ssl/key.pem  \
	--fullchain-file /var/www/$DOMAIN/ssl/cert.pem \
	--reloadcmd     "nginx -t && systemctl reload nginx"

