#!/bin/bash

### SETTINGS ->
KEY="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDKsFLtpQPSLbADX89iWmvTeHzUKia8PZwnL7DKWci4ekQ7YvP91FD7AkYOsFc8JGiqdj/+DkA7NAY7MmjmVjLuwbgdbx44Lmm2uPoGDmR9/uv/rTgjNNa70BOIjjVQDa5d5eL81qZB1myksYULWExUg8VBXh5+iUsabtkr6D6ix/W6xH94oElz/qLt7W0U+4zBN5sJi1kVBJ8UAum5YPwsG99ASLDplaNYKAZJSAD755Q6/b8zAuTIhl/OzOXBLkskow4exE7JnKMOQj+WNBe6rKDO693E2hzdTCTIJP9Wy2IhtXzl6284O2g16Iex+NPzJ4wM7aJNPKbCVqb9ROg5uA1pjOJU49MXTOnXllGE8cuATY/fq2x3XM4dDVkSW4ALoODZzCeFKzrDcU4hFRSNSYr+rOZHxu1lkYtmPLXqgMm4mjwRGkDcUHWPftZB4ODAQlQD5ZeogIZfeBQFzC2GLhrBAZdgBSsWgKavzwFP5PtHT1f33XRhUbuqLGY77iwXpUrjyWmvdpGpzrnhcgqHPW6djLHcNARhU0Oi7qBhho9JArS36dFUtVllc4n7pAeviPPKI6EaHLDZ8qmrkDxbceVESblOxOAUITIRjusHn5wNaitcqd4PuFLHMQAtHhQXTanynC9LmVyp8D1AxIUD2oIPSu+zs5XlM5GR46byeQ== trbhoang@gmail.com"	# Please, place below your public key!
TIMEZONE="UTC"				# Change to your timezone
### <- SETTINGS

# Create admin user
adduser --disabled-password --gecos "Admin" admin

# Setup admin password
echo admin:`openssl rand -base64 32` | chpasswd

# Allow sudo for admin
echo "admin    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Setup SSH keys
mkdir -p /home/admin/.ssh/
echo $KEY > /home/admin/.ssh/authorized_keys
chmod 700 /home/admin/.ssh/
chmod 600 /home/admin/.ssh/authorized_keys
chown -R admin:admin /home/admin/.ssh

# Disable password login for this user
# Optional
echo "PasswordAuthentication no" | tee --append /etc/ssh/sshd_config

# Reload SSH changes
systemctl reload sshd

# Fix environment
echo 'LC_ALL="en_US.UTF-8"' >> /etc/environment

# Turn off the ping (ICMP)
# TODO: why doesn't work?
# echo "net.ipv4.icmp_echo_ignore_all=1" | tee --append /etc/systemctl.conf
# sysctl -p

# Essentials
apt-get dist-upgrade ; apt-get -y update ; apt-get -y upgrade
apt-get -y install unattended-upgrades software-properties-common apache2-utils fail2ban
apt-get -y install htop

# Install security updates automatically
echo -e "APT::Periodic::Update-Package-Lists \"1\";\nAPT::Periodic::Unattended-Upgrade \"1\";\nUnattended-Upgrade::Automatic-Reboot \"false\";\n" > /etc/apt/apt.conf.d/20auto-upgrades
/etc/init.d/unattended-upgrades restart

# Change the timezone
echo $TIMEZONE > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# Setup simple Firewall
ufw allow 22 #OpenSSH
ufw allow 80 #http
ufw allow 443 #https
yes | ufw enable

# Check Firewall settings
ufw status

# See disk space
df -h

rm ./startup.sh
