#!/bin/bash

SAVEDIR=$1
REMOTE=yeti@data.dnsv6lab.net
DATANAME=`ls -lh $SAVEDIR | tail -n 3 |awk '{print $NF}' |sed -n 1p` 

SSH_BIN=/usr/bin/ssh
NODENAME=`hostname`   
# Read local definitions if there is any
# You can use this file to set your own values without modifying this
# script
if [ -s settings.sh ]; then
    . ./settings.sh $SAVEDIR
fi

##----md5sum---md5-------
system=`uname -s`
if [ $system = "Linux" ]; then  
             MY_MD5=`/usr/bin/md5sum "${SAVEDIR}/${DATANAME}" | awk '{print $1}'`
elif [ $system = "OpenBSD" ]; then
            MY_MD5=`/bin/md5 "${SAVEDIR}/${DATANAME}" | awk '{print $NF}'`
elif [ $system = "FreeBSD" ]; then
            MY_MD5=`/sbin/md5 -q "${SAVEDIR}/${DATANAME}"`
elif [ $system = "NetD" ]; then
            MY_MD5=`/usr/bin/md5 "${SAVEDIR}/${DATANAME}" | awk '{print $4}'`
fi
if [ "$SYSLOG_UPLOAD" = "yes" ] || [ "$SYSLOG_UPLOAD" = "y" ]; then
    LOGGER="logger -i -t Yeti"
else
    LOGGER="echo"
fi

output=$(
    $SSH_BIN \
    -o PasswordAuthentication=no \
    -o StrictHostKeyChecking=no \
    -o PreferredAuthentications=publickey \
    -i ${SSH_ID} \
    $REMOTE \
    ditl $NODENAME $DATANAME \
    < ${SAVEDIR}/$DATANAME
)

if [ $? -eq 0 ]; then
        ${LOGGER} "$SSH_BIN upload of $DATANAME completed successfully" 
        if [ "$output" = "$MY_MD5" ]; then
                ${LOGGER} "Remote and local MD5s match" 
        else
                ${LOGGER} "Remote MD5 ($output) does not match local MD5 ($MY_MD5)" 
        fi
else
    ${LOGGER} "$SSH_BIN failed: $?"
fi
