#!/bin/bash

# Beats --> Logstash --> Elasticsearch



# load config vars
source ../.env.sh


# elasticsearch require swap memory
# setup: https://tecadmin.net/add-swap-partition-on-ec2-linux-instance/
#        https://linuxize.com/post/how-to-add-swap-space-on-ubuntu-18-04/
if free | awk '/^Swap:/ {exit !$2}'; then
    echo "Swap memory existed."
else
    echo "Allocate swap memory..."
    # or $ sudo fallocate -l 1G /swapfile
    sudo dd if=/dev/zero of=/var/myswap bs=1M count=2048
    sudo mkswap /var/myswap
    sudo swapon /var/myswap
    # add to /etc/fstab for swap enabled if reboot
    # or $ echo '/swapfile none swap swap 0 0' | sudo tee -a /etc/fstab
    sed -i "\$ a /var/myswap swap swap defaults 0 0" /etc/fstab
fi


# install java which logstash requires
# logstash requires java
sudo apt install -y openjdk-11-jre-headless


# Download and install the Public Signing Key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update


# install Elasticsearch
sudo apt-get install elasticsearch
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch


# install Logstash
#
# test logstash:
#  $ /usr/share/logstash/bin/logstash --path.settings /etc/logstash/ -f ./logstash-test.conf --config.test_and_exit
#
sudo apt-get install logstash
cp ./logstash.nginx.conf /etc/logstash/conf.d/
# correct permission for logstash data & log folder
sudo chown -R logstash:logstash /var/lib/logstash
sudo chown -R logstash:adm /var/log/logstash
sudo systemctl enable logstash
sudo systemctl start logstash


# install Filebeat
sudo apt-get install filebeat
mv /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.bk
cp ./filebeat.yml /etc/filebeat/filebeat.yml
sudo systemctl enable filebeat
sudo systemctl start filebeat


# install Kibana
sudo apt-get install kibana
sudo systemctl enable kibana
sudo systemctl start kibana


# install and configure Nginx
sudo add-apt-repository -y ppa:nginx/stable && apt-get update
sudo apt-get -y install nginx
sudo echo $BASIC_AUTH > /etc/nginx/.htpasswd
sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bk
sudo cp ./nginx.conf /etc/nginx/nginx.conf

