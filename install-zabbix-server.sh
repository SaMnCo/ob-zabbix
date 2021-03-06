#!/bin/bash
################################################################################
#  
# Script to install Zabbix Agent and Server on a Ubuntu 14.04 vanilla system
# 
# Copyright Samuel Cozannet 2014
# Maintainer: Samuel Cozannet <samuel.cozannet@canonical.com>
#
################################################################################

set -x

# Configuring default versions
VERSION="2.2"
DISTRIBUTION="ubuntu"
DIST="trusty"
APT_KEY="D13D58E479EA5ED4"
APT_SRV="keys.gnupg.net"
# Warning this default pass is also hard-coded at the end cuz I've been lazy. 
MYSQL_PASS="ubuntu"
START_DB="zabbix_ob.sql"
# START_DB="zabbix_full.sql"

### Pre requisite
# Using default repository for latest Zabbix binaries
echo "deb http://repo.zabbixzone.com/zabbix/${VERSION}/${DISTRIBUTION}/ ${DIST} main contrib non-free" | tee /etc/apt/sources.list.d/zabbix.list
apt-key adv --keyserver ${APT_SRV} --recv-keys ${APT_KEY}

# Adding the multiverse repos
echo "deb http://us.archive.ubuntu.com/ubuntu/ ${DIST} multiverse" | tee -a /etc/apt/sources.list.d/multiverse.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ ${DIST}-updates multiverse" | tee -a /etc/apt/sources.list.d/multiverse.list

# Updating local repos
apt-get update -qq

# Compilation (uncomment if you want to build from sources)
# apt-get install -y -qq gcc libmagic1 build-essential pkg-config
# OpenIPMI
apt-get install -y -qq openipmi libopenipmi-dev 
# CURL
apt-get install -y -qq libcurl4-openssl-dev 
# SNMP
apt-get install -y -qq libsnmp-dev snmp snmptt snmpd libsnmp-base libsnmp-perl libsnmp30 libsnmp-mib-compiler-perl libsnmp-base libsnmp-dev 
# SNMP from multiverse (in case it fails will not remove other snmp packages)
apt-get install -y -qq snmp-mibs-downloader
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

# CVS & Code Systems
apt-get install -y -qq git bzr python-pip

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
mysql -uroot -pubuntu zabbix < ./${START_DB}
sleep 1
service zabbix-server start

# Prepare for agent MySQL querying
# Reference: http://blog.themilkyway.org/2013/11/how-to-monitor-mysql-using-the-new-zabbix-template-app-mysql/
# This needs a fix to implement the MYSQL_PASS above 
mysql -uroot -p${MYSQL_PASS} -e"GRANT USAGE ON *.* TO 'zabbix'@'127.0.0.1' IDENTIFIED BY 'ubuntu'"
mysql -uroot -p${MYSQL_PASS} -e"GRANT USAGE ON *.* TO 'zabbix'@'localhost' IDENTIFIED BY 'ubuntu'"
# I don't know if there is a bug here but the agent also requires the below
mysql -uroot -p${MYSQL_PASS} -e"GRANT USAGE ON *.* TO 'ubuntu'@'127.0.0.1'"
mysql -uroot -p${MYSQL_PASS} -e"GRANT USAGE ON *.* TO 'ubuntu'@'localhost'"
mysql -uroot -p${MYSQL_PASS} -e"GRANT USAGE ON *.* TO 'zabbix'@'127.0.0.1'"
mysql -uroot -p${MYSQL_PASS} -e"GRANT USAGE ON *.* TO 'zabbix'@'localhost'"
mysql -uroot -pubuntu -e"flush privileges"
cp ./my.cnf /etc/zabbix/.my.cnf
service zabbix-agent restart

# Now copy External scripts
cp ./usr/lib/zabbix/externalscripts/* /usr/lib/zabbix/externalscripts/
cp ./usr/lib/zabbix/alertscripts/* /usr/lib/zabbix/alertscripts/
mv /usr/lib/zabbix/externalscripts/jujuapi.yaml /usr/lib/zabbix/externalscripts/.jujuapi.yaml
mv /usr/lib/zabbix/externalscripts/zabbixapi.yaml /usr/lib/zabbix/externalscripts/.zabbixapi.yaml
chmod +x /usr/lib/zabbix/externalscripts/* 
chmod +x /usr/lib/zabbix/alertscripts/* 
chown zabbix:zabbix /usr/lib/zabbix/externalscripts/*
chown zabbix:zabbix /usr/lib/zabbix/alertscripts/* 

# Installing a local Zabbix API tool
pip install pyzabbix

