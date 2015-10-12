#!/bin/sh

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

download_zone() {
    local method="$1"

    case "$method" in 
        axfr)
            ${dig} -6 @f.root-servers.net . axfr   >  ${origin_data}/root.zone
            if [ $? -ne 0 ]; then
                ${dig} -4 @f.root-servers.net . axfr   >  ${origin_data}/root.zone
            fi
            ;;
        ftp)
            root_zone_url="ftp://rs.internic.net/domain/root.zone"
            $wget -O ${origin_data}/root.zone ${root_zone_url}
            ;;
        *)
           echo "Usage: $0 axfr|ftp"
           return 1
           ;;
    esac
}

# download root zone fromm F-root or ftp
root_zone_download () {
    rm -f ${origin_data}/root.zone

    zone_download_num=3
    while [ ${zone_download_num} -gt 0 ]; do
        download_zone ftp && break
        download_zone axfr && break

        zone_download_num=`expr ${zone_download_num} - 1`
        if [ ${zone_download_num} -eq 0 ]; then
            echo "`${datetime}` The HM(${servername}) server download root zonefile  failed"  >> ${logfile}
            echo "`${datetime}` The HM(${servername}) server download root zonefile  failed"  | \
                 mail -s "The HM download root  zonefile  failed " -r ${sender}  ${admin_mail}
            exit 1
        fi
    done
}

# check original root zone 
# depends on ldns-verify-zone :yum install ldns
check_root_zone() { 
    ${ldns_verify_zone} -k ${icann_ksk_file} ${origin_data}/root.zone
    if [ $? -ne 0 ]; then
        echo "`${datetime}` root.zone verify fail" >> ${logfile}
        exit 1
    fi

} 

# generate root zone apex part
generate_root_ns_file () {
    local start_serial

    if [ -s ${git_repository_dir}/iana-start-serial.txt ]; then
        /bin/cp ${git_repository_dir}/iana-start-serial.txt  ${iana_start_serial} 
        start_serial=`cat ${iana_start_serial}`
    else
        # git repo is empty, we shuold not get serial from git
        start_serial=9015092200
    fi

    # get latest SOA serial from root zone file
    latest_root_soa_serial=`grep "SOA" ${origin_data}/root.zone | egrep -v "NSEC|RRSIG"| head -1 |awk '{print $7}'`     
    if [ -s ${git_root_ns_list} -a ${latest_root_soa_serial} -ge ${start_serial} ]; then
        $python $workdir/bin/parseyaml.py ns  ${git_root_ns_list}  > $current_root_list
        if [ $? -ne 0 ]; then
            echo "${git_root_ns_list} file not exist or format error" >> ${logfilea}
            exit 1
        fi
    fi

    # build root zone apex
    yeti_root_num=`cat ${current_root_list} | wc -l `
    echo ".    86400   IN    SOA    bii.dns-lab.net.  yeti.biigroup.cn.  \
        2015091000  1800  900  604800  86400" > ${config}/root.zone.apex
    for num in `seq 1 ${yeti_root_num}`; do
        root_name=`$sed -n "${num}p" ${current_root_list}  | awk '{print  $1}'`
        root_ip=`$sed -n "${num}p" ${current_root_list}  | awk '{print  $2}'`
        ${workdir}/bin/checkns -ns ${root_name} -addr ${root_ip}
        if [ $? -eq 0 ]; then
            printf "%-30s %-10s %-4s %-8s %-40s\n"  "."   "518400" "IN" "NS" "${root_name}" >>${config}/root.zone.apex
            printf "%-30s %-10s %-4s %-8s %-40s\n"  "${root_name}"  "172800" "IN" "AAAA" "${root_ip}"\
                 >>${config}/root.zone.apex
        else
            echo "`${datetime}` ${root_name} or ${root_ip} is not Correct" >> ${logfile}
            echo "`${datetime}` ${root_name} or ${root_ip} is not Correct" |mail \
                 -s "check root ns list --fail" -r ${sender}  ${admin_mail}
        fi
    done
}


# generate acl_zone_transfer and notify_list
generate_notify_zonetransfer_list () {
    local start_serial

    if [ -s ${git_repository_dir}/iana-start-serial.txt ]; then
        /bin/cp ${git_repository_dir}/iana-start-serial.txt  ${iana_start_serial}
        start_serial=`cat ${iana_start_serial}`
    else
        # git repo is empty, we shuold not get serial from git
        start_serial=9015092200
    fi

    # get latest SOA serial from root zone file
    latest_root_soa_serial=`grep "SOA" ${origin_data}/root.zone | egrep -v "NSEC|RRSIG"| head -1 |awk '{print $7}'`
    if [ -s ${git_root_ns_list} -a ${latest_root_soa_serial} -ge ${start_serial} ];then
        $python $workdir/bin/parseyaml.py  notify ${git_root_ns_list}  > ${named_notify_file}
        if [ $? -ne 0 ]; then
            echo "${git_root_ns_list} file not exist or format error" >> ${logfilea}
            exit 1
        fi

        $python $workdir/bin/parseyaml.py  acl    ${git_root_ns_list}  > ${named_zonetransfer_file}
        if [ $? -ne 0 ]; then
            echo "${git_root_ns_list} file not exist or format error" >> ${logfilea}
            exit 1
        fi
    fi

}

generate_root_zone () {
    tmp_root_soa_serial=` head -1 ${config}/root.zone.apex |awk '{print $7}'`
    
    if [ -s ${zone_data}/root.zone ]; then
        current_root_soa_serial=` head -1 ${zone_data}/root.zone  |awk '{print $7}'`
    else
        current_root_soa_serial=0
    fi

    latest_root_soa_serial=`grep "SOA" ${origin_data}/root.zone | egrep -v "NSEC|RRSIG"| head -1 |awk '{print $7}'`
    if [ ${latest_root_soa_serial} -gt ${current_root_soa_serial} ]; then
        # zone cut
        egrep -v "NSEC|RRSIG|DNSKEY|SOA|^;|^\." ${origin_data}/root.zone > ${tmp_data}/root.zone.cut

        #update root zone serial number
        $sed -i "s/${tmp_root_soa_serial}/${latest_root_soa_serial}/" ${config}/root.zone.apex

        # append zone cut
        /bin/cp ${config}/root.zone.apex  ${zone_data}/root.zone
        cat ${tmp_data}/root.zone.cut >> ${zone_data}/root.zone
    fi
}

# get latest ZSK/KSK from git repo
get_latest_dnskey () {
    local start_serial    

    if [ -s ${iana_start_serial} ]; then
        start_serial=`cat ${iana_start_serial}`
    else
        # git repo is empty, we shuold not get serial from git
        start_serial=9015092200
    fi

    # compare serial number
    latest_root_soa_serial=`grep "SOA" ${origin_data}/root.zone | egrep -v "NSEC|RRSIG"| head -1 |awk '{print $7}'`
    if [ ${latest_root_soa_serial} -ge ${start_serial} ]; then
        if [ -s ${git_repository_dir}/yeti-root-zsk.key ]; then
            new_root_zsk_name=`${parsednskey_command} -f ${git_repository_dir}/yeti-root-zsk.key`
            if [ ! -f ${rootkeydir}/${new_root_zsk_name}.key ]; then
                /bin/cp  ${git_repository_dir}/yeti-root-zsk.key  ${rootkeydir}/${new_root_zsk_name}.key
                /bin/cp  ${git_repository_dir}/yeti-root-zsk.private  $rootkeydir/${new_root_zsk_name}.private
            fi
        fi
        
        if [ -s ${git_repository_dir}/yeti-root-ksk.key  ]; then
            new_root_ksk_name=`${parsednskey_command} -f ${git_repository_dir}/yeti-root-ksk.key`
            if [ ! -f ${rootkeydir}/${new_root_ksk_name}.key ]; then
        
                /bin/cp  ${git_repository_dir}/yeti-root-ksk.key  ${rootkeydir}/${new_root_ksk_name}.key
                /bin/cp  ${git_repository_dir}/yeti-root-ksk.private  ${rootkeydir}/${new_root_ksk_name}.private
            fi  
        fi
    fi
}
    
sign_root_zone() {
    ${dnssecsignzone} -K ${rootkeydir} -o . -O full -S -x ${zone_data}/root.zone 
    if [ $? -eq 0 ]; then 
        $sed '/^;/d'  ${zone_data}/root.zone.signed >  ${root_zone_path}/root.zone.signed
        /bin/cp -f ${zone_data}/root.zone ${root_zone_path}
    else 
        echo "`${datetime}` root zone resgined failed on pm(${servername}) server" >> ${logfile}
        echo "`${datetime}` root zone resgined failed on pm(${servername}) server" | \
               mail -s "root zone signed fail"  -r ${sender} ${admin_mail} 
        exit 1
    fi
}

reload_root_zone() {
    $rndc reload .
    if [  $? -eq  0 ]; then
        echo "`${datetime}` pm(${servername}) named reload successful" >> ${logfile}
    else
        echo "`${datetime}` named process reload failed on the pm(${servername}) server" | \
               mail -s "HM named reload failed " -r ${sender}  ${admin_mail}
        exit 1
    fi
}
