#!/bin/env sh

usage() {
    echo "Usage: sh $0 <add> <ns_domain_name> <ipv6address> ['transfer_net'] ['notify_addr']"
    echo "Sample: sh $0 add yeti-ns.domain.com x:x:x::2" 
    echo "Sample: sh $0 add yeti-ns.domain.com x:x:x::2 'x:x:x::2 x:x:x::3'"  # add transfer list
    echo "Sample: sh $0 add yeti-ns.domain.com x:x:x::2 'x:x:x::2 x:x:x::3' 'x:x:x::2 x:x:x::3'" # add transfer list and notify list

    echo "Usage: sh $0 <del> <ns_domain_name>"
    echo "Usage: sh $0 <renumber> <ns_domain_name> <new_ipv6address>"
    echo "Usage: sh $0 <rename> <old_domain_name> <new_domain>"

    echo "Usage: sh $0 <addnotify> <domain_name> <notifyaddr>"
    echo "Usage: sh $0 <delnotify> <domain_name> <notifyaddr>"
    echo "Usage: sh $0 <updatenotify> <domain_name> <oldaddr> <newaddr>"

    echo "Usage: sh $0 <addtransfer> <domain_name> <addr|network>"
    echo "Usage: sh $0 <deltransfer> <domain_name> <addr|network>"
    echo "Usage: sh $0 <updatetransfer> <domain_name> <oldtransfer> <newtransfer>"
    exit 1
}

if [ $# -lt 2 ]; then
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

if [ -s ${workdir}/setting.sh ]; then
    . ${workdir}/setting.sh
else
    echo "setting.sh file is not exsit"
    exit 1
fi

if [ -s ${workdir}/common.sh ]; then
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
    if [ ! -s ${tmp_root_ns_list} ]; then
        /bin/cp -f ${current_root_list} ${tmp_root_ns_list}
    fi

    origin_root_ns_num=`cat ${tmp_root_ns_list} |wc -l `

    # check wether have add this domain or not
    if [ `grep "${ns_domain}" ${tmp_root_ns_list} | grep -v "grep" |wc -l ` -eq 0 ]; then
        # verify domain and IPv6 Address
        ${workdir}/bin/checkns -ns ${ns_domain} -addr ${ipv6address}
        if [ $? -ne 0 ]; then
            echo " Domain and IPv6 Address don't match"
            exit 1
        fi
        
        # update yeti-root-servers.yaml in git repo
        python ${workdir}/bin/genyaml.py addserver "${ns_domain}" "${ipv6address}" \
                                                            "${git_root_ns_list}"
        if [ $? -ne 0 ]; then
            echo "$LINENO: genyaml addserver fail" && exit 1
        fi

        echo ""${ns_domain}"  "${ipv6address}"" >> ${tmp_root_ns_list}
    else
        echo "${ns_domain} yeti root ns recode has been added"
        exit 1
    fi

    new_root_ns_num=`cat ${tmp_root_ns_list} |wc -l `
    if [ ${new_root_ns_num} -le ${origin_root_ns_num} ]; then
        echo "`$datetime` update root list fail"
        exit 1
    fi
}

del_root_ns() {
    if [ !  -s ${tmp_root_ns_list} ]; then
        /bin/cp -f ${current_root_list} ${tmp_root_ns_list}
    fi

    origin_root_ns_num=`cat ${tmp_root_ns_list} |wc -l `
    if [ `grep "${ns_domain}" ${tmp_root_ns_list} |grep -v "grep" |wc -l` -eq 1  ]; then
       # del server in yeti-root-servers.yaml git repo
       python ${workdir}/bin/genyaml.py delserver "${ns_domain}" "${git_root_ns_list}" 
       if [ $? -ne 0 ]; then
           echo "$LINENO: genyaml delserver fail" && exit 1
       fi
       $sed -i "/"${ns_domain}"/d" ${tmp_root_ns_list}
    else
        echo "${ns_domain} root server don't exsit"
        exit 1
    fi

    new_root_ns_num=`cat ${tmp_root_ns_list} |wc -l `
    if [ ${new_root_ns_num} -gt ${origin_root_ns_num} ]; then
        echo "`$datetime` update root list fail"
        exit 1
    fi
}

update_root_ns() {
    if [ !  -s ${tmp_root_ns_list} ]; then
        /bin/cp -f ${current_root_list} ${tmp_root_ns_list}
    fi
   
    # check domain exist or not
    if grep "${ns_domain}" ${tmp_root_ns_list}; then
        local ipv6addr=`grep "${ns_domain}" ${tmp_root_ns_list}|awk '{print $2}'`

        # check new domain andd ipv6 address match or not
        if ${workdir}/bin/checkns -ns ${new_domain} -addr ${ipv6addr}; then
            # update domain in yeti-root-servers.yaml git repo
            python ${workdir}/bin/genyaml.py rename "${ns_domain}" "${new_domain}" \
                                                            "${git_root_ns_list}"
            if [ $? -ne 0 ]; then
                echo "$LINENO: genyaml reanme fail" && exit 1
            fi
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

update_root_ip() {
    if [ !  -s ${tmp_root_ns_list} ]; then
        /bin/cp -f ${current_root_list} ${tmp_root_ns_list}
    fi
   
    # check domain exist or not
    if grep -q "${ns_domain}" ${tmp_root_ns_list}; then
        local ipv6addr=`grep "${ns_domain}" ${tmp_root_ns_list}|awk '{print $2}'`

        # check domain and new ipv6 address match or not
        if ${workdir}/bin/checkns -ns ${ns_domain} -addr ${new_ipv6addr}; then
            # update root server address in yeti-root-servers.yaml git repo
            python ${workdir}/bin/genyaml.py renumber "${ns_domain}" \
                "${ipv6addr}" "${new_ipv6addr}" "${git_root_ns_list}" 
            if [ $? -ne 0 ]; then
                echo "$LINENO: genyaml reanme fail" && exit 1
            fi
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

    cd ${git_repository_dir} || (echo "${git_repository_dir} don't exist, \
                                      please check your setting" && exit 1)
    for git_option in pull  add  commit  push ;do
        
        try_num=3
    
        while [ ${try_num} -gt 0 ]; do
            if [  ${git_option} = "add" ]; then
                ${git} ${git_option} ${git_root_ns_list} ${git_start_serial_file}   
            elif [ ${git_option} = "commit" ]; then
                ${git} ${git_option} -m "${comment}"
            else
                ${git}  ${git_option}
            fi

            if [ $? -eq 0 ]; then
                    break;
            fi

            try_num=`expr ${try_num} - 1`
            if [ ${try_num} -eq 0 ]; then
                echo "`${datetime}` git ${git_option} command fail" 
                echo "`${datetime}` git ${git_option} command fail" | mail \
                -s "`${datetime}` git ${git_option} command fail" -r ${sender} ${admin_mail}

                exit 1
            fi
        done
    done
}

check_transfer() {
    local addr=$1
    local length

    if echo $addr |grep -q '/'; then
        addr=`echo $addr|cut -d '/' -f 1`

        length=`echo $addr|cut -d '/' -f 2`
        if [ $length -lt 16 -a $length -gt 128 ]; then
            debug "$FUNCNAME" "$LINENO"  "$addr is wrong format" && exit 1 
        fi
   fi

    # check transfer addr
    ${workdir}/bin/checkns -addr $addr 
    if [ $? -ne 0 ]; then
        debug "$FUNCNAME" "$LINENO" "$addr is wrong format" && exit 1
    fi
}

add_root_transfer() {
    for addr in $transfers; do
        # check transfer addr
        check_transfer $addr

        # check addr in ACL or not
        grep -q $addr ${named_zonetransfer_acl} && continue
                      
        # update yaml
        python ${workdir}/bin/genyaml.py addtransfer "${ns_domain}" "${addr}" \
                                                        "${git_root_ns_list}" 
        if [ $? -ne 0 ]; then
            debug "$FUNCNAME" "$LINENO" "addtransfer $addr failed" && exit 1
        fi
    done
}

del_root_transfer() {
    for addr in $transfers; do
        # check transfer addr
        check_transfer $addr

        # check addr in ACL or not
        grep -q $addr ${named_zonetransfer_acl} 
        if [ $? -ne 0 ]; then
            debug "$FUNCNAME" "$LINENO"  "$addr is not in ACL" && exit 1
        fi

        # update yaml
        python ${workdir}/bin/genyaml.py deltransfer "${ns_domain}" "${addr}" \
                                                          "${git_root_ns_list}"
        if [ $? -ne 0 ]; then
            debug "$FUNCNAME" "$LINENO"  "genyaml deltransfer fail" && exit 1
        fi
    done

}

update_root_transfer() {
    # check transfer addr
    check_transfer $newtransfer

    # check newtransfer in ACL or not
    grep -q $newtransfer ${named_zonetransfer_acl} && debug "$FUNCNAME" "$LINENO" \
                                                  "$newtransfer is in ACL" && exit 1

    # update yaml
    python ${workdir}/bin/genyaml.py updatetransfer "${ns_domain}" "${oldtransfer}" \
                                             "${newtransfer}" "${git_root_ns_list}"
    if [ $? -ne 0 ]; then
        debug "$FUNCNAME" "$LINENO"  "genyaml updatetransfer fail" && exit 1
    fi

}

add_root_notifyaddr() {
    for addr in $notifyaddrs; do
        # check notify addr
        ${workdir}/bin/checkns -addr $addr
        if [ $? -ne 0 ]; then
            debug "$FUNCNAME" "$LINENO"  "$addr is wrong format" && exit 1
        fi

        # check addr in notify list or not
        grep -q $addr ${named_notify_list} && continue

        # update yaml
        python ${workdir}/bin/genyaml.py addnotify "${ns_domain}" "${addr}" \
                                                     "${git_root_ns_list}"
        if [ $? -ne 0 ]; then
            debug "$FUNCNAME" "$LINENO" "genyaml addnotify fail" && exit 1
        fi
    done
}

del_root_notifyaddr() {
    for addr in $notifyaddrs; do
        # check notify addr
        ${workdir}/bin/checkns -addr $addr
        if [ $? -ne 0 ]; then
            debug "$FUNCNAME" "$LINENO" "$addr is wrong format" && exit 1
        fi

        # check addr in notify list or not
        grep -q $addr ${named_notify_list}
        if [ $? -ne 0 ]; then
            debug "$FUNCNAME" "$LINENO" "$addr is not in notify list" && exit 1
        fi

        # update yaml
        python ${workdir}/bin/genyaml.py delnotify "${ns_domain}" "${addr}" \
                        "${git_root_ns_list}"
        if [ $? -ne 0 ]; then
            debug "$FUNCNAME" "$LINENO"  "genyaml delnotify fail" && exit 1
        fi
    done
}

update_root_notifyaddr() {
    # check notify addr
    ${workdir}/bin/checkns -addr $oldaddr
    if [ $? -ne 0 ]; then
        debug "$FUNCNAME" "$LINENO"  "$oldaddr is wrong format" && exit 1
    fi
    # check addr in notify list or not
    grep -q $newaddr ${named_notify_list} && debug "$FUNCNAME" "$LINENO" \
                                 "$addr is in notify list" && exit 1

    # update yaml
    python ${workdir}/bin/genyaml.py updatenotify "${ns_domain}" "${oldaddr}" \
                                           "${newaddr}" "${git_root_ns_list}"
    if [ $? -ne 0 ]; then
        debug "$FUNCNAME" "$LINENO" "genyaml updatenotify fail" && exit 1
    fi
}

refresh_git_repository
is_pending

case "$1" in 
    add )
        ns_domain=$2
        ipv6address=$3
        comment="add root ${ns_domain}"
        
        add_root_ns
        
        # handle zone transfer and notify addr
        if [ $# -eq 4 ]; then
            transfer=$4
            add_root_transfer
        elif [ $# -eq 5 ]; then
            transfers=$4
            notifyaddrs=$5

            add_root_transfer
            add_root_notifyaddr
        else
            :            
        fi
        ;;
    del )
        ns_domain=$2
        comment="del ${ns_domain}"

        del_root_ns
        ;;
    renumber)
        ns_domain=$2
        new_ipv6addr=$3
        comment="update ${ns_domain} ipv6 address to ${new_ipv6addr}"

        update_root_ip
        ;;
    rename)
        ns_domain=$2
        new_domain=$3
        comment="rename ${ns_domain} to ${new_domain}"

        update_root_ns
        ;;
    addtransfer)
        ns_domain=$2
        transfers=$3
        comment="addtransfer ${ns_domain}  ${transfers}"

        add_root_transfer
        ;;
    deltransfer)
        ns_domain=$2
        transfers=$3
        comment="deltransfer ${ns_domain}  ${transfers}"

        del_root_transfer
        ;;
    updatetransfer)
        ns_domain=$2
        oldtransfer=$3
        newtransfer=$4
        comment="updatetransfer ${ns_domain} to ${newtransfer}"

        update_root_transfer
        ;;
    addnotify)
        ns_domain=$2
        notifyaddrs=$3
        comment="addnotify ${ns_domain}  ${notifyaddrs}"

        add_root_notifyaddr
        ;;
    delnotify)
        ns_domain=$2
        notifyaddrs=$3
        comment="delnotify ${ns_domain}  ${notifyaddrs}"

        del_root_notifyaddr
        ;;
    updatenotify)
        ns_domain=$2
        oldaddr=$3
        newaddr=$4
        comment="updatenotify ${ns_domain} to ${newaddr}"

        update_root_notifyaddr
        ;;
    *)
        usage
        ;;
esac 

generate_start_serial
update_git "${comment}"
