#!/bin/env sh

generate_crontab_time() {
    local keytype="$1"
    local keytag
    local keyname
    if [ "$keytype" = "zsk" ]; then
        KEYTAG=`/usr/local/bin/dig @${SERVER} . soa +dnssec +short | awk '/SOA/{print $7}'`
    elif [ "$keytype" = "ksk" ]; then
        KEYTAG=`/usr/local/bin/dig @${SERVER}  . dnskey +dnssec |awk '/RRSIG/{print $11}'`
    else
        echo "wrong dnskey type"
        exit 1
    fi

    KEYNAME=`ls ${ROOT_KEY} |grep "${KEYTAG}" |grep "key"`
    if [ -n "$KEYNAME" ]; then
        INACTIVE_TIME_STRING=`awk -F'[()]' '/Inactive:/ {print $2}' ${ROOT_KEY}/${KEYNAME}`
        INACTIVE_TIME=`date -d "$INACTIVE_TIME_STRING" +%Y%m%d%H%M%S`
        INACTIVE_MONTH=`echo ${INACTIVE_TIME} |awk '{print substr($0,5,2)}'`
        INACTIVE_DATE=`echo ${INACTIVE_TIME} |awk '{print substr($0,7,2)}'`
        INACTIVE_YMD=`echo ${INACTIVE_TIME} |awk '{print substr($0,1,8)}'`
        if [ "$KEYTYPE" = "zsk" ]; then
            KEY_GEN_TIME=`date -d "${INACTIVE_YMD} -4 days" +%F`
        elif [ "$KEYTYPE" = "ksk" ]; then
            KEY_GEN_TIME=`date -d "${INACTIVE_YMD} -30 days" +%F`
        else
            echo "wrong dnskey type" 
            exit 1
        fi

        HOUR=`echo ${INACTIVE_TIME} |awk '{print substr($0,9,2)}'`
        MINUTS=`echo ${INACTIVE_TIME} |awk '{print substr($0,11,2)}'`
        DAY=`echo ${KEY_GEN_TIME} |awk -F"-" '{print $3}'`
        MONTH=`echo ${KEY_GEN_TIME} |awk -F"-" '{print $2 }'`
    else
        echo "$NOW $keytype $KEYTAG is not exsit, add crontab is fail" | \
            mail -s "add crontable is fail" -r ${SENDER} ${ADMIN_MAIL}
        exit 1
    fi
}
