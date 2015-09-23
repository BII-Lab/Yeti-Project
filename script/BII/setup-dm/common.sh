
# get latest git repo
refresh_git_repository() {
	cd ${git_repository_dir} || (echo "`${datetime}` HM(${servername}):" \
                                    "${git_repository_dir} do not exist, please" \
					                "check setting.sh" >> ${logfile} && exit 1)

	try_git_num=3
	while [ ${try_git_num} -gt 0 ];do
		${git} pull
		if [ $? -eq 0 ];then
			#cd ${current_dir}
			cd -
			break;
				
		fi

		try_git_num=`expr ${try_git_num} - 1`
		if [ ${try_git_num} -eq 0 ];then
	        echo "`${datetime}` The HM(${servername}) server pull git repository  failed"  >> ${logfile}
            echo "`${datetime}` The HM(${servername}) server pull git repository  failed" | \
 				mail -s "The HM(${servername}) pull git repository  failed " -r ${sender}  ${admin_mail}
            exit 1
        fi
	done

}

# check git repo status
is_pending() {
    # get latest serial from git repo
    if [ -s ${git_repository_dir}/iana-start-serial.txt ]; then
        git_serial=`cat ${git_repository_dir}/iana-start-serial.txt`
    else
        git_serial=0
    fi

    # get current serial from DM
    current_serial=`dig @${serveraddr} . soa +short |awk '{print $3}'`
    if [ $? -ne 0 ]; then
       	echo "`${datetime}` ${FUNCNAME} dig can not get serial form ${serveraddr}" 
       	echo "`${datetime}` ${FUNCNAME} dig can not get serial form ${serveraddr}" | mail -s "`${datetime}` ${FUNCNAME} dig fail" \ 
					 -r ${sender} ${admin_mail}
        exit 1   
    fi

    # compare serial
    if [ "${current_serial}" -le "${git_serial}" ]; then
        # pending
       	echo "`${datetime}` ${FUNCNAME}: the status is pending, " \
             "please wait until the serial is bigger than ${git_serial}" 
        exit 1
    fi
}

