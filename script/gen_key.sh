#!/bin/bash

#key roller
#
keydir="/root/scripts/key"


public_time=1
active_time=0
inactive_time=2
delete_time=3


#time in second
HOUR=3600
DAY=86400
WEEK=604800
MONTH=2592000
MAXTTL=518400
ZONE_SYNC_ALL=86400

#    root   ZSK
echo "--------------ZSK----------"
dnssec-keygen -a 8 -b 1024 -P now -A now -I now+2w -D now+$((2*WEEK+MAXTTL+ZONE_SYNC_ALL)) -r /dev/urandom -K $keydir/root/   .  
dnssec-keygen -a 8 -b 1024 -P now -A now+$((2*WEEK)) -I now+$((4*WEEK)) -D now+$((4*WEEK+MAXTTL+ZONE_SYNC_ALL)) -r /dev/urandom  -K $keydir/root  .
#dnssec-keygen -a 8 -b 1024 -P now+$(()) -A now+$(((4*WEEK)) -I now+$((6*WEEK)) -D now+$((6*WEEK+MAXTTL+ZONE_SYNC_ALL)) -r /dev/urandom  ${zone_name}

#   arpa  zsk 

dnssec-keygen -a 8 -b 1024 -P now -A now -I now+2w -D now+$((2*WEEK+MAXTTL+ZONE_SYNC_ALL)) -r /dev/urandom -K $keydir/root/   arpa.

dnssec-keygen -a 8 -b 1024 -P now -A now+$((2*WEEK)) -I now+$((4*WEEK)) -D now+$((4*WEEK+MAXTTL+ZONE_SYNC_ALL)) -r /dev/urandom  arpa.
#dnssec-keygen -a 8 -b 1024 -P now -A now+2min -I now+8min -D now+19min -r /dev/urandom ${zone_name}.

echo "--------------KSK----------"
# KSK
dnssec-keygen -a 8 -b 2048 -f KSK  -P now -A now -I now+3mo -D now+$((3*MONTH+MAXTTL+ZONE_SYNC_ALL)) -r /dev/urandom  arpa.

       
