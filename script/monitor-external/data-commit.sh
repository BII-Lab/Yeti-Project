#!/bin/bash
 
SAVEDIR=$1
REMOTE=yeti@data.dnsv6lab.net
DATANAME=`ls -lh $SAVEDIR | tail -n 3 |awk '{print $NF}' |sed -n 1p` 

SSH_BIN=/usr/bin/ssh
NODENAME=`hostname`   
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

output=$(
    $SSH_BIN \
    -o PasswordAuthentication=no \
    -o StrictHostKeyChecking=no \
    -o PreferredAuthentications=publickey \
    $REMOTE \
    ditl $NODENAME $DATANAME \
    < ${SAVEDIR}/$DATANAME
)

if [ $? -eq 0 ]; then
        echo "$SSH_BIN completed successfully" 
        if [ "$output" = "$MY_MD5" ]; then
                echo "Remote and local MD5s match" #|$LOGGER
        else
                echo "Remote MD5 ($output) does not match local MD5 ($MY_MD5)" #|$LOGGER
        fi
fi
