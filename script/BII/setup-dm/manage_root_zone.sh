#!/bin/env sh

usage() {
	echo 'Usage: sh manage_root_zone.sh  add  ns_domain_name  ipv6address  comments'
	echo 'Usage: sh manage_root_zone.sh  del  ns_domain_name  comments'
	echo 'Usage: sh manage_root_zone.sh  renumbering  ns_domain_name ipv6address comments'
	echo 'Usage: sh manage_root_zone.sh  updatens  old_domain_name new_domain comments'
	exit 1
}

if [ $# -lt 3 ];then
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

if [ -s ${workdir}/common.sh ];then
    . ${workdir}/common.sh
else
    echo "common.sh file is not exsit"
    exit 1
fi

#logfile="${workdir}/log/modfiy_yeti_ns_server.log"
git_start_serial_file="${git_repository_dir}/iana-start-serial.txt"

# check nameserver and IPv6 Address format
tmp_root_ns_list="${workdir}/tmp/yeti-root-servers.txt"

generate_start_serial () {
	current_root_soa_serial=` head -1 ${zone_data}/root.zone  |awk '{print $7}'`

	date_num=`echo ${current_root_soa_serial:0:8}`
	modify_num=`echo ${current_root_soa_serial:8:10}`

	newdate_num=`date -d "${date_num} +2 days" +%Y%m%d`
	reference_soa_num=`echo ${newdate_num}${modify_num}`

	echo ${reference_soa_num} > ${git_start_serial_file}
}

add_root_ns(){
	if [ ! -s ${tmp_root_ns_list} ];then
		/bin/cp -f ${current_root_list} ${tmp_root_ns_list}
	fi

	origin_root_ns_num=`cat ${tmp_root_ns_list} |wc -l `

    # check wether have add this domain or not
	if [ `grep "${ns_domain}" ${tmp_root_ns_list} | grep -v "grep" |wc -l ` -eq 0 ];then
        # verify domain and IPv6 Address
        ${workdir}/bin/checkns -ns ${ns_domain} -addr ${ipv6address}
        if [ $? -ne 0 ]; then
            echo " Domain and IPv6 Address don't match"
            exit 1
        fi

 		echo ""${ns_domain}"  "${ipv6address}"" >> ${tmp_root_ns_list}
	else
		echo "${ns_domain} yeti root ns recode has been added"
		exit 1
	fi

	new_root_ns_num=`cat ${tmp_root_ns_list} |wc -l `
	if [ ${new_root_ns_num} -le ${origin_root_ns_num} ];then
		echo "`$datetime` update root list fail"
		exit 1
	fi
}

del_root_ns() {
    if [ !  -s ${tmp_root_ns_list} ];then
        /bin/cp -f ${current_root_list} ${tmp_root_ns_list}
    fi

	origin_root_ns_num=`cat ${tmp_root_ns_list} |wc -l `
	if [ `grep "${ns_domain}" ${tmp_root_ns_list} |grep -v "grep" |wc -l` -eq 1  ];then
	   $sed -i "/"${ns_domain}"/d" ${tmp_root_ns_list}
	else
		echo "${ns_domain} root server don't exsit"
		exit 1
	fi

	new_root_ns_num=`cat ${tmp_root_ns_list} |wc -l `
	if [ ${new_root_ns_num} -gt ${origin_root_ns_num} ];then
    	echo "`$datetime` update root list fail"
    	exit 1
	fi
}

update_root_ns() {
    if [ !  -s ${tmp_root_ns_list} ];then
        /bin/cp -f ${current_root_list} ${tmp_root_ns_list}
    fi
   
    # check domain exist or not
	if grep "${ns_domain}" ${tmp_root_ns_list}; then
        local ipv6addr=`grep "${ns_domain}" ${tmp_root_ns_list}|awk '{print $2}'`

        # check new domain andd ipv6 address match or not
        if ${workdir}/bin/checkns -ns ${new_domain} -addr ${ipv6addr}; then
	        $sed -i s/${ns_domain}/${new_domain}/g ${tmp_root_ns_list}
        else
            echo "func: ${FUNCNAME} line: $LINENO wrong domain: ${new_domain}"
            exit 1
        fi
	else
		echo "${ns_domain} root server don't exsit"
		exit 1
	fi
}

update_git () {

	if [ -s ${tmp_root_ns_list} ]; then
	    /bin/cp ${tmp_root_ns_list} ${git_root_ns_list}
	fi

	cd ${git_repository_dir} || (echo "${git_repository_dir} don't exist, please check your setting" && exit 1)

	for git_option in pull  add  commit  push ;do
		
		try_num=3
	
       	while [ ${try_num} -gt 0 ];do
			if [  ${git_option} = "add" ];then
				${git} ${git_option} ${git_root_ns_list} ${git_start_serial_file}	
			elif [ ${git_option} = "commit" ];then
				${git} ${git_option} -m "${comment}"
			else
           		${git}  ${git_option}
			fi

            if [ $? -eq 0 ];then
    	            break;
       	    fi

           	try_num=`expr ${try_num} - 1`
           	if [ ${try_num} -eq 0 ];then
               	echo "`${datetime}` git ${git_option} command fail" 
               	echo "`${datetime}` git ${git_option} command fail" | mail -s "`${datetime}` git ${git_option} command fail" \ 
					 -r ${sender} ${admin_mail}

               	exit 1
      	    fi
        done
	done
}

refresh_git_repository
is_pending

case "$1" in 
	add )
	    ns_domain=$2
	    ipv6address=$3
	    comment=$4
        
		add_root_ns "${ns_domain}" "${ipv6address}"
	    ;;
	del )
	    ns_domain=$2
	    comment=$3

		del_root_ns "${ns_domain}"  
	    ;;
    renumbering)
	    ns_domain=$2
	    ipv6address=$3
	    comment=$4

		del_root_ns "${ns_domain}"  
		add_root_ns "${ns_domain}" "${ipv6address}"
        
        ;;
    updatens)
	    ns_domain=$2
	    new_domain=$3
	    comment=$4

        update_root_ns
        ;;
	*)
        usage
	    ;;
esac 

generate_start_serial
update_git "${comment}"
