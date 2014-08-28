#!/usr/bin/expect -f
# Zabbix IRC sender script
 
set force_conservative 0  ;# set to 1 to force conservative mode even if
                          ;# script wasnt run conservatively originally
                          
if {$force_conservative} {
        set send_slow {1 .1}
        proc send {ignore arg} {
                sleep .1
                exp_send -s -- $arg
        }
}
 
set timeout -1
spawn telnet localhost 1033 #eggdrop bot listening on 1033/TCP
match_max 100000
expect "Nickname.\r"
send -- "zabbix-sr\r"
expect "Enter your password.\r"
send -- "ubuntu\r"
expect -exact "*** zabbix-sr joined the party line.\r"
send -- ".msg #ob [lindex $argv]\r"
expect ".msg #ob [lindex $argv]\r"
send -- ".quit\r"
expect eof
 
-=-=-=-=-=-=-=-=-=-=-=-=-
 
#!/bin/bash
# IRC Caller for Zabbix Alert
DEBUG=0
 
usr=$1
msg=$2
 
/usr/lib/zabbix/alertscripts/irc_alert.sh $msg
