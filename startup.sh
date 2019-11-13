#!/bin/bash

# load config vars
source .env.sh


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
apt-get -y install unattended-upgrades software-properties-common apache2-utils
apt-get -y install htop


# Install security updates automatically
echo -e "APT::Periodic::Update-Package-Lists \"1\";\nAPT::Periodic::Unattended-Upgrade \"1\";\nUnattended-Upgrade::Automatic-Reboot \"false\";\n" > /etc/apt/apt.conf.d/20auto-upgrades
/etc/init.d/unattended-upgrades restart

# Change the timezone
echo $TIMEZONE > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata

# Install & configure sendmail
apt-get -y install sendmail
sed -i "/MAILER_DEFINITIONS/ a FEATURE(\`authinfo', \`hash -o /etc/mail/authinfo/smtp-auth.db\')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ a define(\`confAUTH_MECHANISMS', \`EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN\')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ a TRUST_AUTH_MECH(\`EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ a define(\`confAUTH_OPTIONS', \`A p')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ a define(\`ESMTP_MAILER_ARGS', \`TCP \$h 587')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ a define(\`RELAY_MAILER_ARGS', \`TCP \$h 587')dnl" /etc/mail/sendmail.mc
sed -i "/MAILER_DEFINITIONS/ a define(\`SMART_HOST', \`[email-smtp.us-east-1.amazonaws.com]')dnl" /etc/mail/sendmail.mc

mkdir /etc/mail/authinfo
chmod 750 /etc/mail/authinfo
cd /etc/mail/authinfo
echo "AuthInfo: \"U:root\" \"I:$SMTP_USER\" \"P:$SMTP_PASS\"" > smtp-auth
chmod 600 smtp-auth
makemap hash smtp-auth < smtp-auth

make -C /etc/mail
systemctl restart sendmail
echo "Subject: sendmail test" | sendmail -v $SYSADMIN_EMAIL


### Security

# Install & configure CSF (https://www.configserver.com/cp/csf.html)
apt-get -y install libwww-perl unzip
cd /usr/src/
wget https://download.configserver.com/csf.tgz
tar -xzf csf.tgz
cd csf
sh install.sh

cd /usr/local/csf/bin/
perl csftest.pl

sed -i 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf
sed -i 's/LF_ALERT_TO = ""/LF_ALERT_TO = "'$SYSADMIN_EMAIL'"/g' /etc/csf/csf.conf
systemctl start csf
systemctl start lfd
systemctl enable csf
systemctl enable lfd

# List csf firewall rules
csf -l



# Setup simple Firewall
# ufw allow 22 #OpenSSH
# ufw allow 80 #http
# ufw allow 443 #https
# yes | ufw enable

# # Check Firewall settings
# ufw status

# See disk space
df -h

