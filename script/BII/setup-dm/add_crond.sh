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
    keytype="$1"
else
    usage
fi

# get absoulte path
get_workdir() {
    local path="$1"
    local absoulte_path=`pwd`

    # wirkdir do not start with /
    if echo $path|egrep -q '^\.'; then
        #echo "start with ."
        workdir="${absoulte_path}"
    elif echo $path|egrep -q '/'; then
        # absoulte path
        :
    else
        # relative path
        #echo "relative path ."
        workdir="${absoulte_path}/${workdir}"
    fi
}

workdir=`dirname $0`
get_workdir $workdir

if [ -s ${workdir}/setting.sh ];then
	. ${workdir}/setting.sh
else
	echo "setting.sh file is not exsit"
    exit 1
fi

# 2 days
delay_time="2"

scripts_file_dir="$workdir"
crontab_file=/etc/crontab

# bind9 shuold list on this IP address
server=127.0.0.1

# prepare time for crontab task
if [ -s ${workdir}/generate_cron_time.sh ]; then
    . ${workdir}/generate_cron_time.sh
    generate_crontab_time ${keytype}
else
	echo "`$datetime` ${workdir}/generate_cron_time.sh  don't exsit" 
    exit 1
fi

# wether have add this task or not
if [ `grep "${minuts} ${hour} ${day} ${month} \* root \
sh ${scripts_file_dir}/generate_key.sh ${keytype} ${delay_time}  >/dev/null 2>&1" \
${crontab_file} |wc -l ` -lt 1 ];then

    #add gen root key crontab
	echo "                                           " >>$crontab_file
	echo "#create new ${keytype} for root or arpa " >> $crontab_file
	echo "${minuts} ${hour} ${day} ${month} * root ${scripts_file_dir}/generate_key.sh ${keytype} ${delay_time}" >>$crontab_file

	if [ $? -ne 0 ];then
		echo "`$datetime` generate root ${keytype} cron task fail" | mail -s "add generate_key.sh ${keytype} into /etc/crontab" \
			 -r ${sender} ${admin_mail}
	fi
fi

