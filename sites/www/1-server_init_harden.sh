#!/bin/bash

#########################################################

#  1. [Optionally] Change root password
#  2. Remove amazon ssm agent and other non-used services
#  3. Create non-root user and give it "sudo" privilege
#  4. Alter to secure SSH
#  5. Set timezone to UTC, fix environment
#  6. Make swap memory (VPS provided OS doesnt creat it by defaut)
#  7. [Optionally] Reset the url for apt repo from VPS provided CDN to OS provided ones
#  8. Update + Upgrade + Install & Config softwares (sendmail, CSF, LFD)


#########################################################



# load config vars
source .env.sh


# Change root password
echo root:$ROOT_PASSWD | chpasswd


# remove amazon-ssm-agent
snap remove amazon-ssm-agent
# remove never-used services: snapd, lxcfs
# ref: https://peteris.rocks/blog/htop/
sudo apt remove lvm2 -y --purge
sudo apt remove snapd -y --purge
sudo apt remove lxcfs -y --purge
sudo apt remove mdadm -y --purge
sudo apt remove policykit-1 -y --purge
sudo apt remove open-iscsi -y --purge
sudo systemctl stop getty@tty1


# Create non-root user
adduser --disabled-password --gecos "Admin" $SYSADMIN_USER
# Setup admin password
echo $SYSADMIN_USER:$SYSADMIN_PASSWD | chpasswd
# Allow sudo for sys admin user
echo "$SYSADMIN_USER    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
# Setup SSH keys
mkdir -p /home/$SYSADMIN_USER/.ssh/
echo $KEY > /home/$SYSADMIN_USER/.ssh/authorized_keys
chmod 700 /home/$SYSADMIN_USER/.ssh/
chmod 600 /home/$SYSADMIN_USER/.ssh/authorized_keys
chown -R $SYSADMIN_USER:$SYSADMIN_USER /home/$SYSADMIN_USER/.ssh


# Alter to secure ssh
echo "PasswordAuthentication no" | tee --append /etc/ssh/sshd_config
echo "PermitEmptyPasswords no" | tee --append /etc/ssh/sshd_config
echo "PermitRootLogin no" | tee --append /etc/ssh/sshd_config
echo "Protocol 2" | tee --append /etc/ssh/sshd_config
# configure idle timeout interval
echo "ClientAliveInterval 360" | tee --append /etc/ssh/sshd_config
echo "ClientAliveCountMax 0" | tee --append /etc/ssh/sshd_config
# disable port forwarding (yes: to support connecting from localhost)
echo "AllowTcpForwarding yes" | tee --append /etc/ssh/sshd_config
echo "X11Forwarding no" | tee --append /etc/ssh/sshd_config
echo "UseDNS no" | tee --append /etc/ssh/sshd_config
echo "MaxAuthTries 5" | tee --append /etc/ssh/sshd_config
echo "MaxSessions 3" | tee --append /etc/ssh/sshd_config
# Reload SSH changes
systemctl reload sshd


# Fix environment
echo 'LC_ALL="en_US.UTF-8"' >> /etc/environment
echo 'LC_CTYPE="en_US.UTF-8"' >> /etc/environment
# Change the timezone
echo $TIMEZONE > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
# Change hostname
hostnamectl set-hostname $HOST_NAME
sed -i "1i 127.0.1.1 $HOST_DNS $HOST_NAME" /etc/hosts


# Install essential packages
apt-get dist-upgrade ; apt-get -y update ; apt-get -y upgrade
apt-get -y install unattended-upgrades software-properties-common apache2-utils dnsutils apt-transport-https
apt-get -y install htop
# Install security updates automatically
echo -e "APT::Periodic::Update-Package-Lists \"1\";\nAPT::Periodic::Unattended-Upgrade \"1\";\nUnattended-Upgrade::Automatic-Reboot \"false\";\n" > /etc/apt/apt.conf.d/20auto-upgrades
/etc/init.d/unattended-upgrades restart


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


# Should have space for swap memory
if free | awk '/^Swap:/ {exit !$2}'; then
    echo "Swap memory existed."
else
    echo "Allocate swap memory..."
    # or $ sudo fallocate -l 1G /swapfile
    sudo dd if=/dev/zero of=/var/myswap bs=1M count=2048
    sudo mkswap /var/myswap
		sudo chmod 600 /var/myswap
    sudo swapon /var/myswap
    # add to /etc/fstab for swap enabled if reboot
    # or $ echo '/swapfile none swap swap 0 0' | sudo tee -a /etc/fstab
    sed -i "\$ a /var/myswap swap swap defaults 0 0" /etc/fstab
fi


### Firewall & login monitoring (csf, lfd)

# Install & configure CSF (https://www.configserver.com/cp/csf.html)
apt-get -y install libwww-perl unzip
cd /usr/src/
wget https://download.configserver.com/csf.tgz
tar -xzf csf.tgz
cd csf
sh install.sh
cd /usr/local/csf/bin/
perl csftest.pl
cp /etc/csf/csf.conf /etc/csf/csf.conf.bak
# Custom some csf settings
sed -i 's/TESTING = "1"/TESTING = "0"/g' /etc/csf/csf.conf
sed -i 's/SMTP_BLOCK = "0"/SMTP_BLOCK = "1"/g' /etc/csf/csf.conf
sed -i 's/PT_SKIP_HTTP = "0"/PT_SKIP_HTTP = "1"/g' /etc/csf/csf.conf
sed -i 's/PT_USERPROC = "10"/PT_USERPROC = "15"/g' /etc/csf/csf.conf
sed -i 's/IGNORE_ALLOW = "0"/IGNORE_ALLOW = "1"/g' /etc/csf/csf.conf
# Disallow incomming PING
sed -i 's/ICMP_IN = "1"/ICMP_IN = "0"/g' /etc/csf/csf.conf
sed -i 's/LF_ALERT_TO = ""/LF_ALERT_TO = "'$SYSADMIN_EMAIL'"/g' /etc/csf/csf.conf
sed -i 's/TCP_IN = "20,21,22,25,53,80,110,143,443,465,587,993,995"/TCP_IN = "22,80,443"/g' /etc/csf/csf.conf
sed -i 's/TCP_OUT = "20,21,22,25,53,80,110,113,443,587,993,995"/TCP_OUT = "22,80,443"/g' /etc/csf/csf.conf
sed -i 's/UDP_IN = "20,21,53"/UDP_IN = "53"/g' /etc/csf/csf.conf
sed -i 's/UDP_OUT = "20,21,53,113,123"/UDP_OUT = "53,67"/g' /etc/csf/csf.conf
sed -i 's/TCP6_IN = "20,21,22,25,53,80,110,143,443,465,587,993,995"/TCP6_IN = ""/g' /etc/csf/csf.conf
sed -i 's/TCP6_OUT = "20,21,22,25,53,80,110,113,443,587,993,995"/TCP6_OUT = ""/g' /etc/csf/csf.conf
sed -i 's/UDP6_OUT = "20,21,53,113,123"/UDP6_OUT = ""/g' /etc/csf/csf.conf
# to allow web server to send email through smtp
sed -i 's/SMTP_ALLOWUSER = ""/SMTP_ALLOWUSER = "www-data"/g' /etc/csf/csf.conf

# disable LFD excessive resource usage alert
# ref: https://www.interserver.net/tips/kb/disable-lfd-excessive-resource-usage-alert/
sed -i 's/PT_USERMEM = "512"/PT_USERMEM = "0"/g' /etc/csf/csf.conf
sed -i 's/PT_USERTIME = "1800"/PT_USERTIME = "0"/g' /etc/csf/csf.conf
# Ignore alert if following process use exeeded resource
echo "exe:/usr/sbin/rsyslogd" | tee --append /etc/csf/csf.pignore
echo "exe:/lib/systemd/systemd-networkd" | tee --append /etc/csf/csf.pignore
echo "exe:/usr/sbin/atd" | tee --append /etc/csf/csf.pignore
echo "exe:/lib/systemd/systemd" | tee --append /etc/csf/csf.pignore
echo "exe:/lib/systemd/systemd-resolved" | tee --append /etc/csf/csf.pignore

systemctl enable csf
systemctl enable lfd
systemctl start csf
systemctl start lfd

# List csf firewall rules
csf -l

