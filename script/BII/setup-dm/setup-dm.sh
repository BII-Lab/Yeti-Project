#!/bin/sh

#
# setup Yeti Distribute Master
# generate Yeti root zone from IANA root zone file
# replace with Yeti root zone apex
# sign with Yeti ZSK and KSK
#

# load functions
WORKDIR=`dirname $0`
if [ -s $WORKDIR/setup-dm-functions.sh ]; then
     . $WORKDIR/setup-dm-functions.sh 
else
    echo "`$NOW` setup-dm-functions.sh isn't exsit" >> $LOG_FILE
    exit 1
fi

# check IANA serial number changed or not
is_new_zone || exit 0

# get the latest DM repository(Yeti NS list, ZSK and KSK)
refresh_git_repository

# first, generate Yeti root zone file
generate_yeti_zone

# second, sign Yeti root zone
sign_yeti_zone

# last, distribute Yeti root zone
distribute_yeti_zone
