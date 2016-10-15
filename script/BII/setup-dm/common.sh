#debug
debug() {
    # debug, record time, func, line, error msg
    # log $FUNCNAME $LINENO "test failed" "please check"
    # if it's not called in function, please run 'debug main $LINENO  mesg
    if [ $# -lt 3 ]; then
        echo "Usage: debug \$FUNCNAME \$LINENO  \"msg\""
        echo "called in function: debug \$FUNCNAME \$LINENO \"msg\""
        echo "called out of function: debug main \$LINENO \"msg\""
        exit 1
    fi

    local func=$1; shift
    local line=$1; shift
    local msg="$@"

    echo "[$(date +'%Y-%m-%d %H:%M:%S')]:" "file: $0" \
                "func: $func line: $line msg: $msg"
}

# get latest git repo
refresh_git_repository() {
    cd ${DM_REPO} || (echo "`${NOW}` HM(${SERVER_NAME}):" \
                                    "${DM_REPO} do not exist, please" \
                                    "check setting.sh" >> ${LOGFILE} && exit 1)

    try_git_num=3
    while [ ${try_git_num} -gt 0 ];do
        ${GIT} pull
        if [ $? -eq 0 ];then
            #cd ${current_dir}
            cd -
            break;
                
        fi

        try_git_num=`expr ${try_git_num} - 1`
        if [ ${try_git_num} -eq 0 ];then
            echo "`${NOW}` The HM(${SERVER_NAME}) server pull git repository  failed"  >> ${LOGFILE}
            echo "`${NOW}` The HM(${SERVER_NAME}) server pull git repository  failed" | \
                mail -s "The HM(${SERVER_NAME}) pull git repository  failed " -r ${SENDER}  ${ADMIN_MAIL}
            exit 1
        fi
    done

}

# check git repo status
is_pending() {
    # get latest serial from git repo
    if [ -s ${DM_REPO}/${START_SERIAL} ]; then
        git_serial=`cat ${DM_REPO}/${START_SERIAL}`
    else
        git_serial=0
    fi

    # get current serial from DM
    current_serial=`dig @${SERVER_ADDR} . soa +short |awk '{print $3}'`
    if [ $? -ne 0 ]; then
        echo "`${NOW}` ${FUNCNAME} dig can not get serial form ${SERVER_ADDR}" 
        echo "`${NOW}` ${FUNCNAME} dig can not get serial form ${SERVER_ADDR}" | \
         mail -s "`${NOW}` ${FUNCNAME} dig fail"  -r ${SENDER} ${ADMIN_MAIL}
        exit 1   
    fi

    # compare serial
    if [ "${current_serial}" -le "${git_serial}" ]; then
        # pending
        echo "`${NOW}` ${FUNCNAME}: the status is pending, " \
             "please wait until the serial is bigger than ${git_serial}" 
        exit 1
    fi
}

