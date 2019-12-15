#!/bin/bash


# elasticsearch require swap memory
# setup: https://tecadmin.net/add-swap-partition-on-ec2-linux-instance/
#        https://linuxize.com/post/how-to-add-swap-space-on-ubuntu-18-04/
if free | awk '/^Swap:/ {exit !$2}'; then
    echo "Swap memory existed."
else
    echo "Allocate swap memory..."
	sudo dd if=/dev/zero of=/var/myswap bs=1M count=2048
	sudo mkswap /var/myswap
	sudo swapon /var/myswap

	# add to /etc/fstab for swap enabled if reboot
	sed -i "\$ a /var/myswap swap swap defaults 0 0" /etc/fstab
fi


# download and install the public signing key
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

apt-get install apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update && sudo apt-get install elasticsearch

sudo systemctl daemon-reload
sudo systemctl enable elasticsearch.service
sudo systemctl start elasticsearch.service
