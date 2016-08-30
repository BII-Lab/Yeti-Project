#/bin/bash

usage() {
    echo "sh add_crond.sh zsk|ksk "
    echo "sample: sh add_crond.sh zsk"
    echo "sample: sh add_crond.sh ksk"
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

# check keytype
if [ "$1" = "zsk" -o "$1" = "ksk" ]; then
    KEYTYPE="$1"
else
    usage
fi

# get absoulte path
get_workdir() {
    local path=`readlink -f $0`
    WORKDIR=`dirname $path`
}
get_workdir 

if [ -s ${WORKDIR}/setting.sh ];then
    . ${WORKDIR}/setting.sh
else
    echo "setting.sh file is not exsit"
    exit 1
fi

# 2 days
DELAY_TIME="2"
SCRIPTS_FILE_DIR="$WORKDIR"
CRONTAB_FILE=/etc/crontab

# bind9 shuold list on this IP address
SERVER="127.0.0.1"

# prepare time for crontab task
if [ -s ${WORKDIR}/generate_cron_time.sh ]; then
    . ${WORKDIR}/generate_cron_time.sh
    generate_crontab_time ${KEYTYPE}
else
    echo "`$DATETIME` ${WORKDIR}/generate_cron_time.sh  don't exsit" 
    exit 1
fi

# wether have add this task or not
if [ `grep "${MINUTS} ${HOUR} ${DAY} ${MONTH} \* root \
sh ${SCRIPTS_FILE_DIR}/generate_key.sh -k ${KEYTYPE} -t ${DELAY_TIME} >/dev/null 2>&1" \
${CRONTAB_FILE} |wc -l` -lt 1 ];then

    #add gen root key crontab
    echo "                                           " >>$CRONTAB_FILE
    echo "#create new ${KEYTYPE} for root " >> $CRONTAB_FILE
    echo "${MINUTS} ${HOUR} ${DAY} ${MONTH} * root sh ${SCRIPTS_FILE_DIR}/generate_key.sh\
 -k ${KEYTYPE} -t ${DELAY_TIME} >/dev/null 2>&1" >>$CRONTAB_FILE
    if [ $? -ne 0 ];then
        echo "`$NOW` generate root ${KEYTYPE} cron task fail" |\
            mail -s "$NOW add generate_key.sh ${KEYTYPE} into /etc/crontab" \
             -r ${SENDER} ${ADMIN_MAIL}
    fi
fi

