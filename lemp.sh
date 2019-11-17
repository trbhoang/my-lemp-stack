#!/bin/bash


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


