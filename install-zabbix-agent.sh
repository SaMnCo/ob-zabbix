#!/bin/bash
################################################################################
#  
# Script to install Zabbix Agent on a Ubuntu 14.04 vanilla system
#
################################################################################

# Configuring default versions
VERSION="2.2"
DISTRIBUTION="ubuntu"
# This should be automated. 
DIST="precise"
APT_KEY="D13D58E479EA5ED4"
APT_SRV="keys.gnupg.net"
MYSQL_PASS="ubuntu"
ZABBIX_SERVER="ec2-54-68-41-89.us-west-2.compute.amazonaws.com"

### Pre requisite
# Using default repository for latest Zabbix binaries
echo "deb http://repo.zabbixzone.com/zabbix/${VERSION}/${DISTRIBUTION}/ ${DIST} main contrib non-free" | tee /etc/apt/sources.list.d/zabbix.list
apt-key adv --keyserver ${APT_SRV} --recv-keys ${APT_KEY}

# Adding the multiverse repos
echo "deb http://us.archive.ubuntu.com/ubuntu/ ${DIST} multiverse" | tee -a /etc/apt/sources.list
echo "deb http://us.archive.ubuntu.com/ubuntu/ ${DIST}-updates multiverse" | tee -a /etc/apt/sources.list

# Updating local repos
apt-get update -qq

# CVS Systems
apt-get install -y -qq git bzr
# OpenIPMI
apt-get install -y -qq openipmi 
# CURL
apt-get install -y -qq curl 
# SNMP
apt-get install -y -qq snmp snmptt snmpd
apt-get install -y -qq snmp-mibs-downloader 
# Networking & Stuff
apt-get install -y -qq  fping wakeonlan ntp bc nmap
# AMT Terminal
apt-get install -y -qq  amtterm
# Stuff
apt-get install -y -qq expect
# Networking
apt-get install -y -qq tshark 
groupadd wireshark
usermod -a -G wireshark $USERNAME
chgrp wireshark /usr/bin/dumpcap
chmod 750 /usr/bin/dumpcap
setcap cap_net_raw,cap_net_admin=eip /usr/bin/dumpcap
# This line verifies the result. Uncomment if want to check
# getcap /usr/bin/dumpcap
# Note leaving the session is required. Will work after a reboot

### Final touch
echo "We are now ready to install Zabbix.."
echo .

### Installing Zabbix
apt-get install -y -qq zabbix-agent

sed -i.bak -e 's/^#\ EnableRemoteCommands=0/EnableRemoteCommands=1/g' \
    -e 's/^#\ LogRemoteCommands=0/LogRemoteCommands=1/g' \
    -e "s/Server=127\.0\.0\.1/Server="${ZABBIX_SERVER}"/g" \
    -e "s/ServerActive=127\.0\.0\.1/ServerActive="${ZABBIX_SERVER}"/g" \
    -e '/Hostname=Zabbix\ server/d' \
    -e 's/^#\ AllowRoot=0/AllowRoot=1/g' \
    /etc/zabbix/zabbix_agentd.conf

service zabbix-agent restart



