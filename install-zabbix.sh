#!/bin/bash
################################################################################
#  
# Script to install Zabbix Agent and Server on a Ubuntu 14.04 vanilla system
#
################################################################################

# Configuring default versions
VERSION="2.2"
DISTRIBUTION="ubuntu"
DIST="trusty"
APT_KEY="D13D58E479EA5ED4"
APT_SRV="keys.gnupg.net"
MYSQL_PASS="ubuntu"

### Pre requisite
# Using default repository for latest Zabbix binaries
echo "deb http://repo.zabbixzone.com/zabbix/${VERSION}/${DISTRIBUTION}/ ${DIST} main contrib non-free" | tee /etc/apt/sources.list.d/zabbix.list
apt-key adv --keyserver ${APT_SRV} --recv-keys ${APT_KEY}

# Updating local repos
apt-get update -qq

# Compilation (uncomment if you want to build from sources)
# apt-get install -y -qq gcc libmagic1 build-essential pkg-config
# OpenIPMI
apt-get install -y -qq openipmi libopenipmi-dev 
# CURL
apt-get install -y -qq libcurl4-openssl-dev 
# SNMP
apt-get install -y -qq libsnmp-dev snmp snmptt libsnmp-base libsnmp-perl libsnmp30 libsnmp-mib-compiler-perl snmp-mibs-downloader libsnmp-base libsnmp-dev snmpd
# Jabber
apt-get install -y -qq libiksemel-dev libiksemel3 libiksemel-utils
# MySQL
apt-get install -y -qq mysql-client libmysqlclient15-dev
# SSL & SSH
apt-get install -y -qq libssl-dev libssh2-1-dev 
# Networking & Stuff
apt-get install -y -qq  fping wakeonlan ntp bc
# AMT Terminal
apt-get install -y -qq  amtterm



sed -i.bak 's/^mibs\ \:/#\ mibs\ \:/' /etc/snmp/snmp.conf

# Stuff
apt-get install -y -qq htop openssl shellinabox eggdrop expect

# Install ncftp
apt-get install -y -qq ncftp

# Networking
apt-get install -y -qq tshark nmap
groupadd wireshark
usermod -a -G wireshark $USERNAME
chgrp wireshark /usr/bin/dumpcap
chmod 750 /usr/bin/dumpcap
setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap
# This line verifies the result. Uncomment if want to check
# getcap /usr/bin/dumpcap
# Note leaving the session is required. Will work after a reboot

# CVS Systems
apt-get install -y -qq git bzr

### Final touch
echo "We are now ready to install Zabbix.."
echo .

# Installing Zabbix
sed -i.bak "s/MYSQL_PASS/${MYSQL_PASS}/g" ./mysql_ob.preseed
debconf-set-selections ./mysql_ob.preseed
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --force-yes mysql-server-5.5

sed -i.bak "s/MYSQL_PASS/${MYSQL_PASS}/g" ./zabbix_ob.preseed
debconf-set-selections ./zabbix_ob.preseed
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --force-yes zabbix-server-mysql
apt-get install -y -qq zabbix-frontend-php zabbix-java-gateway zabbix-agent zabbix-get zabbix-sender php5-mysql

# Add the timezone to php.ini
sed -i.bak 's/^;date\.timezone\ =/date\.timezone\ = Europe\/Paris/' /etc/php5/apache2/php.ini
# Set default configuration
cp -f ./zabbix.conf_ob.php /etc/zabbix/web/zabbix.conf.php
service apache2 restart

# Import default DB
service zabbix-server stop
sleep 1
mysql -uroot -pubuntu zabbix < ./zabbix_ob.sql
sleep 1
service zabbix-server start

# Prepare for agent MySQL querying
# Reference: http://blog.themilkyway.org/2013/11/how-to-monitor-mysql-using-the-new-zabbix-template-app-mysql/
mysql -uroot -p${MYSQL_PASS} -e"GRANT USAGE ON *.* TO 'zabbix'@'127.0.0.1' IDENTIFIED BY 'zabbix'"
mysql -uroot -p${MYSQL_PASS} -e"GRANT USAGE ON *.* TO 'zabbix'@'localhost' IDENTIFIED BY 'zabbix'"
mysql -uroot -p${MYSQL_PASS} -e"GRANT USAGE ON *.* TO 'ubuntu'@'127.0.0.1'"
mysql -uroot -p${MYSQL_PASS} -e"GRANT USAGE ON *.* TO 'ubuntu'@'localhost'"
mysql -uroot -pubuntu -e"flush privileges"
cp ./my.cnf /etc/zabbix/.my.cnf
service zabbix-agent restart

# Now copy External scripts
cp ./usr/lib/zabbix/externalscripts/* /usr/lib/zabbix/externalscripts/
cp ./usr/lib/zabbix/alertscripts/* /usr/lib/zabbix/alertscripts/

