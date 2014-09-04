#!/usr/bin/python 

#
# Copyright 2014 Canonical Ltd.
#
# Authors:
#  Samuel Cozannet 
#
# Note: requires pyzabbix to be installed. 
#
from pyzabbix import ZabbixAPI
import argparse
import sys
import yaml
import json
import pprint

parser = argparse.ArgumentParser(description="delete a host of a certain hostID from Zabbix")
parser.add_argument('-c', action="store", dest="conffile", default='.zabbixapi.yaml')
parser.add_argument('hostid', type=int, help = 'ID of host to delete')
args = parser.parse_args()

with open(args.conffile, 'r') as f:
    conf = yaml.load(f)

zapi = ZabbixAPI(server=conf["zabbix-api"]["endpoint"])
zapi.login(conf["zabbix-api"]["login"], conf["zabbix-api"]["password"])
zapi.host.delete( { "hostid": args.hostid })

