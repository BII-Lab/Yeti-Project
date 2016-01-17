#!/bin/env sh

generate_crontab_time() {
    local keytype="$1"
    local keytag
    local keyname

    if [ "$keytype" = "zsk" ]; then
        keytag=`/usr/local/bin/dig  @${server} . dnskey +all |grep "ZSK" |awk '{print $NF}'`
    elif [ "$keytype" = "ksk" ]; then
        keytag=`/usr/local/bin/dig @${server}  .  dnskey  +all | grep "KSK" |awk '{print $NF}'`
    else
        echo "wrong dnskey type"
        exit 1
    fi

    keyname=`ls ${rootkeydir} |grep "${keytag}" |grep "key"`

    inactive_time=` grep "Inactive:" ${rootkeydir}/${keyname} |awk  '{print $3}' |awk '{print substr($0,1,8)}'`
    inactive_month=`echo ${inactive_time} |awk '{print substr($0,5,2)}'`
    inactive_date=`echo ${inactive_time} |awk '{print substr($0,7,2)}'`

    if [ "$keytype" = "zsk" ]; then
        key_gen_time=`date -d "${inactive_time} -4 days" +%F`
    elif [ "$keytype" = "ksk" ]; then
        key_gen_time=`date -d "${inactive_time} -7 days" +%F`
    else
        echo "wrong dnskey type" 
        exit 1
    fi

    hour=`grep "Inactive:" ${rootkeydir}/${keyname} |awk  '{print $7}' |awk -F":" '{print $1}'`
    minuts=`grep "Inactive:" ${rootkeydir}/${keyname} |awk  '{print $7}' |awk -F":" '{print $2}'`
    day=`echo ${key_gen_time} |awk -F"-" '{print $3}'`
    month=`echo ${key_gen_time} |awk -F"-" '{print $2 }'`

}

