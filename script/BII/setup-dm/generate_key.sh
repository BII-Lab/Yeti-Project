#!/bin/env sh

if [ $# -ne 2 ];then
    echo "sh generate_key.sh zsk|ksk number(delay_timex:int))"
    exit 1
fi

get_workdir() {
    local path="$1"
    local absoulte_path=`pwd`

    # wirkdir do not start with /
    if echo $path|egrep -q '^\.'; then
        echo "start with ."
        workdir="${absoulte_path}"
    elif echo $path|egrep '/'; then
        echo "absoulte path ."
        # absoulte path
        :
    else
        # relative path
        echo "relative path ."
        workdir="${absoulte_path}/${workdir}"
    fi
}

workdir=`dirname $0`
get_workdir $workdir

#apply new key or ns list time
delay_time="$2"
key_type="$1"

#time in second
HOUR=3600
DAY=86400
WEEK=604800
MONTH=2592000
MAXTTL=518400
ZONE_SYNC_ALL=86400

#key parameter setting
ksk_publish_time="now"
ksk_activate_time="now"
ksk_retire_time="now+$((3*MONTH))"
ksk_delete_time="now+$((3*MONTH+MAXTTL+ZONE_SYNC_ALL+7*DAY))"

zsk_publish_time="now"
zsk_activate_time="now+4d"
zsk_retire_time="now+$((2*WEEK+4*DAY))"
zsk_delete_time="now+$((2*WEEK+MAXTTL+ZONE_SYNC_ALL+4*DAY))"

if [ -s ${workdir}/setting.sh ];then
    . ${workdir}/setting.sh
else
    echo "setting.sh file is not exsit"
    exit 1
fi

if [ -s ${workdir}/common.sh ];then
    . ${workdir}/common.sh
else
    echo "common.sh file is not exsit"
    exit 1
fi

logfile=$workdir/log/generate_key.log
root_ksk_name_file="$workdir/tmp/root_ksk_name"
root_zsk_name_file="$workdir/tmp/root_ksk_name"
new_root_ksk_dir="$workdir/keys/root/newkey/ksk"
new_root_zsk_dir="$workdir/keys/root/newkey/zsk"

[ ! -d ${new_root_ksk_dir} ] && mkdir -p ${new_root_ksk_dir}
[ ! -d ${new_root_zsk_dir} ] && mkdir -p ${new_root_zsk_dir}

#Create KSK or ZSK  directory
create_key_dir() {

    date_time=`date +%Y%m%d`
    #This function is dependent on the "ls" command the default collation.
    key_num=`ls -l ${git_repository_dir}/$key_type/ | grep "${date_time}" | wc -l `
    if [ "$key_num" -lt 10 ]; then
        generate_num="0${key_num}"
        key_dir="${date_time}${generate_num}"
        mkdir -p ${git_repository_dir}/$key_type/${key_dir}
    else
        generate_num="${key_num}"
        key_dir="${date_time}${generate_num}"
        mkdir -p ${git_repository_dir}/$key_type/${key_dir}
    fi
}

#generate reference soa 
generate_start_serial() {
    current_root_soa_serial=` head -1 $zone_data/root.zone  |awk '{print $7}'`
    date_num=`echo ${current_root_soa_serial:0:8}`
    modify_num=`echo ${current_root_soa_serial:8:10}`
    newdate_num=`date -d "$date_num +${2} days" +%Y%m%d`
    reference_soa_num=`echo ${newdate_num}${modify_num}`
    echo ${reference_soa_num} > ${git_repository_dir}/$key_type/${key_dir}/${key_start_serial_file}
}

#root  ksk
generate_ksk() {
           
    $dnsseckeygen -a 8 -b 2048 -K ${new_root_ksk_dir} -f KSK \
                  -P ${ksk_publish_time} \
                  -A ${ksk_activate_time} \
                  -I ${ksk_retire_time} \
                  -D ${ksk_delete_time} \
                  -r /dev/urandom . >${root_ksk_name_file}

    if [ $? -eq 0 ];then
         echo "`${datetime}` root ksk generate successful" >> ${logfile}
    else
         echo  "`${datetime}` Generate root ksk error on the pm(${servername}) server" >>${logfile}
         echo  "`${datetime}` Generate root ksk error on the pm($servername) server" | \
               mail -s "generate root ksk fail"  -r ${sender}   ${admin_mail}
         exit 1
    fi          
           
}

#rename ksk and cp ksk to git repository
update_ksk_git() {

    root_ksk_prefix=`cat ${root_ksk_name_file}`
    /bin/cp  ${new_root_ksk_dir}/${root_ksk_prefix}.key   ${ksk_git_repository_dir}/${key_dir}
    if [ $? -ne 0 ];then
        echo "`${datetime}` rename root_ksk public key fail" >> ${logfile}
        exit 1
    fi

    /bin/cp ${new_root_ksk_dir}/${root_ksk_prefix}.private   ${ksk_git_repository_dir}/${key_dir}
    if [ $? -ne 0 ];then
        echo "`${datetime}` rename root_ksk  private key fail" >> ${logfile}
        exit 1
    fi
}

# generate ZSK   
generate_zsk() {

    ${dnsseckeygen} -a 8 -b 1024 -K ${new_root_zsk_dir} \
                    -P ${zsk_publish_time} \
                    -A ${zsk_activate_time} \
                    -I ${zsk_retire_time} \
                    -D ${zsk_delete_time} \
                    -r /dev/urandom  .  > ${root_zsk_name_file}

    if [ $? -ne  0 ];then 
        echo "`${datetime}` Generate root ZSK errors on the pm(${servername}) server"  >> ${logfile}
        echo "`${datetime}` Generate root ZSK errors on the pm(${servername}) server " | mail \
            -s "Generate root ZSK errors"  -r  ${sender}  ${admin_mail} 
        exit
    else

        echo "`${datetime}` Generate root zsk ok !!!"  >> ${logfile}
    fi
}

#rename zsk and cp zsk to git repository
update_zsk_git() {

    root_zsk_prefix=`cat ${root_zsk_name_file}`
    /bin/cp ${new_root_zsk_dir}/${root_zsk_prefix}.key   ${zsk_git_repository_dir}/${key_dir}
    if [ $? -ne 0 ];then
         echo "`${datetime}` rename root_zsk public key fail" >> ${logfile}
         exit 1
    fi

    /bin/cp ${new_root_zsk_dir}/${root_zsk_prefix}.private   ${zsk_git_repository_dir}/${key_dir}
    if [ $? -ne 0 ];then
        echo "`${datetime}` rename root_zsk  private key fail" >> ${logfile}
        exit 1
    fi
}

#upload  ksk  for git
update_git() {
    cd ${git_repository_dir} || (echo "${git_repository_dir} don't exist" && exit 1)
    for git_option  in pull  add commit  push ;do

        try_num=3

        while [ ${try_num} -gt 0 ];do

            if [ ${git_option} = "add" ];then
                ${git} ${git_option} ${git_repository_dir}/$key_type/$key_dir/*.key \
                        ${git_repository_dir}/$key_type/$key_dir/*.private \
                        ${git_repository_dir}/$key_type/$key_dir/*.txt
            elif [ ${git_option} = "commit" ];then
                ${git} ${git_option} -m "update root $1"     
            else
                ${git}  ${git_option}
            fi

            if [ $? -eq 0 ];then
                break;
            fi

            try_num=`expr $try_num - 1`

            if [ $try_num -eq 0 ];then
                echo "`${datetime}` git ${git_option}  command fail" >> ${logfile}
                echo "`${datetime}` git ${git_option}  command fail" |   mail \
                -s "`${datetime}` git ${git_option} command fail" -r ${sender} ${admin_mail}
                exit 1
            fi
        done
    done

}

refresh_git_repository
case $1 in
    zsk)
    create_key_dir $key_type
    generate_start_serial $key_type  ${delay_time}
    generate_zsk
    update_zsk_git
    update_git zsk
    ;;
    ksk)
    create_key_dir $key_type
    generate_start_serial $key_type ${delay_time}
    generate_ksk
    update_ksk_git
    update_git ksk
    ;;
    *)
    echo "sh generate_key.sh  zsk|ksk number(delay_timex:int))" 
    ;;
esac

