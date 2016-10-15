#!/bin/env sh

#
# generate ZSK/KSK and push to DM Repo
#

if [ $# -eq 4 ];then
    while getopts :k:t: opt; do
        case $opt in 
            k)
                KEY_TYPE=$OPTARG
                ;;
            t)
                DELAY_TIME=$OPTARG
                ;;
            *)
                echo "Invalid parameter"
                echo "sh generate_key.sh -k zsk|ksk -t number(delay_timex:int)"
                exit 1
                ;;
        esac
    done
else
    echo "sh generate_key.sh -k zsk|ksk -t number(delay_timex:int)"
    exit 1
fi

get_workdir() {
    local path=`readlink -f $0`
    WORKDIR=`dirname $path`
}

get_workdir

#time in second
HOUR=3600
DAY=86400
WEEK=604800
MONTH=2592000
MAXTTL=86400
ZONE_SYNC_ALL=86400

#key parameter setting
KSK_PUBLISH_TIME="now"
KSK_ACTIVATE_TIME="now+$((1*MONTH))"
KSK_RETIRE_TIME="now+$((4*MONTH))"
KSK_DELETE_TIME="now+$((5*MONTH+MAXTTL+ZONE_SYNC_ALL+7*DAY))"

ZSK_PUBLISH_TIME="now"
ZSK_ACTIVATE_TIME="now+4d"
ZSK_RETIRE_TIME="now+$((2*WEEK+4*DAY))"
ZSK_DELETE_TIME="now+$((2*WEEK+MAXTTL+ZONE_SYNC_ALL+4*DAY))"

LOGFILE=$WORKDIR/log/generate_key.log
KSK_NAME="$WORKDIR/tmp/root_ksk_name"
ZSK_NAME="$WORKDIR/tmp/root_zsk_name"

if [ -s ${WORKDIR}/setting.sh ];then
    . ${WORKDIR}/setting.sh
else
    echo "setting.sh file is not exsit"
    exit 1
fi

if [ -s ${WORKDIR}/common.sh ];then
    . ${WORKDIR}/common.sh
else
    echo "common.sh file is not exsit"
    exit 1
fi

create_dir(){
    local dir=$1
    local current_date=`date +%Y%m%d`
    local key_count=`ls $1 | grep -c "$current_date"`

    if [ "$key_count" -lt 10 ]; then
        local generate_num="0${key_count}"
        newkey_dir="${current_date}${generate_num}"
    else
        newkey_dir="${current_date}${key_count}"
    fi

    mkdir -p $dir/${newkey_dir}
}

create_newkey_dir() {
    local key_type="$1"
    local zsk_dir="${DM_REPO}/$KEY_TYPE/$DM"
    local ksk_dir="${DM_REPO}/$KEY_TYPE"

    if [ "$key_type" = "zsk" ]; then
        create_dir $zsk_dir
    elif [ "$key_type" = "ksk" ]; then
        create_dir $ksk_dir
    else
        echo "`$NOW`@${SERVER_NAME} key type is error" >>$LOGFILE
        exit 1
    fi
}

# generate start serial
generate_start_serial() {
    local key_type=$1
    local delay_time="$2"
    local current_serial=`head -1 $ZONE_DATA/root.zone  |awk '{print $7}'`
    local date_num=`echo ${current_serial}| awk '{print substr($0,0,8)}'`
    local modify_num=`echo ${current_serial} | awk '{print substr($0,9,10)}'`
    local new_date=`date -d "$date_num +${delay_time} days" +%Y%m%d`
    local new_serial=`echo ${new_date}${modify_num}`

    if [ "$1" = "zsk" ]; then
        echo ${new_serial} > ${DM_REPO}/$key_type/${DM}/${newkey_dir}/${START_SERIAL}
    elif [ "$1" = "ksk" ]; then
        echo ${new_serial} > ${DM_REPO}/$key_type/${newkey_dir}/${START_SERIAL}
    else
        echo "key type is error" >>$LOGFILE
        exit 1
    fi
}

generate_key() {
    local key_type=$1

    while true; do
        if [ "$key_type" = "zsk" ]; then
            local keyname="${ZSK_NAME}"

            ${DNSSECKEYGEN} -a 8 -b 2048 -K ${NEW_ZSK} \
                            -P ${ZSK_PUBLISH_TIME} \
                            -A ${ZSK_ACTIVATE_TIME} \
                            -I ${ZSK_RETIRE_TIME} \
                            -D ${ZSK_DELETE_TIME} \
                            -r /dev/urandom . > ${ZSK_NAME}
        elif [ "$key_type" = "ksk" ]; then 
            local keyname="${KSK_NAME}"

            ${DNSSECKEYGEN} -a 8 -b 2048 -K ${NEW_KSK} -f KSK \
                            -P ${KSK_PUBLISH_TIME} \
                            -A ${KSK_ACTIVATE_TIME} \
                            -I ${KSK_RETIRE_TIME} \
                            -D ${KSK_DELETE_TIME} \
                            -r /dev/urandom . > ${KSK_NAME}
        else
            echo "Parameter does not exist"
            exit 1
        fi

        local newkey=`cat $keyname`
        local key_count=`find ${DM_REPO} -name "${newkey}.key" | wc -l`

        if [ "$key_count" -eq 0 ]; then
            break
        else
            continue
        fi 
    done    
    
    if [ $? -ne  0 ]; then 
        echo "`${NOW}` Generate root $key_type errors on the HM(${SERVER_NAME}) server"  >> ${LOGFILE}
        echo "`${NOW}` Generate root $key_type errors on the HM(${SERVER_NAME}) server " | mail \
            -s "Generate root $key_type errors"  -r  ${SENDER} ${ADMIN_MAIL} 
        exit 1
    else
        echo "`${NOW}` Generate root $key_type ok !!!" >> ${LOGFILE}
    fi
}

# copy ksk or zsk to DM repository
copy_key() {
    local zsk_prefix=`cat ${ZSK_NAME}`
    local ksk_prefix=`cat ${KSK_NAME}`
    local key_type="$1"

    if [ "$key_type" = "zsk" ]; then
        /bin/cp ${NEW_ZSK}/${zsk_prefix}.key ${ZSK_DIR}/${DM}/${newkey_dir}
    elif [ "$key_type" = "ksk" ]; then
        /bin/cp ${NEW_KSK}/${ksk_prefix}.private ${KSK_DIR}/${newkey_dir}
        /bin/cp ${NEW_KSK}/${ksk_prefix}.key ${KSK_DIR}/${newkey_dir}/
    else
        echo "key type is error" >>$LOGFILE
        exit 1
    fi

    if [ $? -ne 0 ];then
        echo "`${NOW}` copy root $key_type to git  fail" >> ${LOGFILE}
            exit 1
    fi
}


# Add change log
change_log() {
    local key_type="$1"
    local current_time=`date +%Y-%m-%d`

    [ ! -f "$CHANAGE" ] && touch $CHANGE 
    local row=`wc -l $CHANGE | awk '{print $1}'`

    if [ "$key_type" = "zsk" ]; then
        if [ "$row" -eq 0 ]; then
            echo "1. $current_time $ADMIN [add new zsk]" > $CHANGE
        else
            next_row=`echo "$row + 1" | bc`
            $SED -i "1i $next_row. $current_time $ADMIN [add new zsk]" $CHANGE
        fi
    elif [ "$key_type" = "ksk" ]; then
        if [ "$row" -eq 0 ]; then
            echo "1. $current_time $ADMIN [add new ksk]" > $CHANGE
        else
            next_row=`echo "$row + 1" | bc`
            $SED -i "1i $next_row. $current_time $ADMIN [add new ksk]" $CHANGE
        fi         
    else
        echo "key type is error" >>$LOGFILE
        exit 1
    fi
}     

# upload zsk or ksk DM Repo
update_key() {
    local key_type=$1
    cd ${DM_REPO} || (echo "${DM_REPO} don't exist" && exit 1)

    for option in add commit push; do
        if [ ${option} = "add" ]; then
            if [ "$key_type" = "zsk" ]; then
                ${GIT} ${option} ${ZSK_DIR}/${DM}/$newkey_dir/*.key \
                       ${ZSK_DIR}/${DM}/$newkey_dir/*.txt \
                       ${CHANGE}
            else
                ${GIT} ${option} ${KSK_DIR}/$newkey_dir/K* \
                       ${KSK_DIR}/$newkey_dir/*.txt \
                       ${CHANGE}
            fi 

            if [ $? -ne 0 ]; then
                echo "${NOW} git $option $key_type command is fail" >> ${LOGFILE}
                exit 1
            fi
        elif [ ${option} = "commit" ]; then
            ${GIT} ${option} -m "update root $key_type"     
            if [ $? -ne 0 ]; then
                echo "${NOW} git $option $key_type command is fail" >> ${LOGFILE}
                exit 1
            fi
        else
            # running git push 
            tries=3

            while [ ${tries} -gt 0 ]; do
                ${GIT} ${option}
                if [ $? -eq 0 ];then
                    break;
                fi
                tries=`expr $tries - 1`
            done

            if [ $tries -eq 0 ];then
                echo "`${NOW}` git ${option} $key_type command fail" >> ${LOGFILE}
                echo "`${NOW}` git ${option} $key_type command fail" | mail \
                    -s "`${NOW}` git ${option} $key_type command fail(${SERVER_NAME})"\
                    -r ${SENDER} ${ADMIN_MAIL}
                exit 1
           fi
        fi
    done
}

# sync DM repository
refresh_git_repository

# generate key dir and key
create_newkey_dir $KEY_TYPE
generate_start_serial $KEY_TYPE  ${DELAY_TIME}
generate_key $KEY_TYPE
copy_key $KEY_TYPE

# add log and push to DM Repo
change_log $KEY_TYPE
update_key $KEY_TYPE
