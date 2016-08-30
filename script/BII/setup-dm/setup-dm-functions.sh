#!/bin/sh

# get absoulte path
get_workdir() {
    local path=`readlink -f $0`
    WORKDIR=`dirname $path`
}

get_workdir

if [ -s ${WORKDIR}/setting.sh ]; then
    . ${WORKDIR}/setting.sh
else
    echo "setting.sh file is not exsit"
    exit 1
fi

if [ -s ${WORKDIR}/common.sh ]; then
    . ${WORKDIR}/common.sh
else
    echo "common.sh file is not exsit"
    exit 1
fi

download_zone() {
    local method="$1"
    case "$method" in 
        axfr)
            ${DIG} +onesoa +nocmd +nocomments +nostats -6 @${F_SERVER} . axfr > ${ORIGIN_ZONE}/root.zone
            if [ $? -ne 0 ]; then
                ${DIG} +onesoa +nocmd +nocomments +nostats  @${F_SERVER} . axfr > ${ORIGIN_ZONE}/root.zone
            fi
            ;;
        ftp)
            root_zone_url="ftp://rs.internic.net/domain/root.zone"
            $WGET -O ${ORIGIN_ZONE}/root.zone ${root_zone_url}
            ;;
        *)
           echo "Usage: $0 axfr|ftp"
           return 1
           ;;
    esac
}

# download root zone fromm F-root or ftp
root_zone_download() {
    rm -f ${ORIGIN_ZONE}/root.zone

    tries=3
    while [ "${tries}" -gt 0 ]; do
        download_zone axfr && break
        download_zone ftp && break

        tries=`expr ${tries} - 1`
        if [ "${tries}" -eq 0 ]; then
            echo "`${NOW}` The HM(${SERVER_NAME}) server download root zonefile failed" >>\
                       ${LOG_FILE}
            echo "`${NOW}` The HM(${SERVER_NAME}) server download root zonefile failed" |\
                       mail -s "The HM download root zonefile failed " -r ${SENDER} ${ADMIN_MAIL}
            exit 1
        fi
    done
}

# check original root zone 
# depends on ldns-verify-zone :yum install ldns
check_root_zone() { 
    ${LDNS_VERIFY_ZONE} -k ${ICANN_KSK} ${ORIGIN_ZONE}/root.zone
    if [ $? -ne 0 ]; then
        echo "`${NOW}` root.zone verify fail" >> ${LOG_FILE}
        exit 1
    fi
} 

get_serial() {
    if [ -s ${DM_REPO}/ns/${START_SERIAL} ]; then
        /bin/cp ${DM_REPO}/ns/${START_SERIAL} ${IANA_START_SERIAL} 
        start_serial=`cat ${IANA_START_SERIAL}`
    else
        # git repo is empty, we shuold not get serial from git
        start_serial=9015092200
    fi

    # get latest SOA serial from root zone file
    latest_serial=`grep "SOA" ${ORIGIN_ZONE}/root.zone |\
        egrep -v "NSEC|RRSIG"| head -1 |awk '{print $7}'`     
}

generate_ns() {
    if [ -s ${ROOT_LIST} -a "${latest_serial}" -ge "${start_serial}" ]; then
        $PYTHON $WORKDIR/bin/parseyaml.py ns ${ROOT_LIST} >\
            $CURRENT_ROOT_LIST
        if [ $? -ne 0 ]; then
            echo "${ROOT_LIST} file not exist or format error" >> ${LOG_FILE}
            exit 1
        fi
    else
        echo "${ROOT_LIST} not exsit or serial number is not update" >> ${LOG_FILE}
    fi

    local root_count=`cat ${CURRENT_ROOT_LIST} | wc -l `
    for n in `seq 1 ${root_count}`; do
        root_name=`$SED -n "${n}p" ${CURRENT_ROOT_LIST} | awk '{print $1}'`
        root_ip=`$SED -n "${n}p" ${CURRENT_ROOT_LIST} | awk '{print $2}'`

        #${WORKDIR}/bin/checkns -ns ${root_name} -addr ${root_ip}
        #if [ $? -eq 0 ]; then
        printf "%-30s %-10s %-4s %-8s %-40s\n"  "."   "$ttl" "IN" "NS" "${root_name}" >> $f
        printf "%-30s %-10s %-4s %-8s %-40s\n"  "${root_name}"  "$ttl" "IN" "AAAA" "${root_ip}" >>$f
        #else
        #    echo "`${NOW}` ${root_name} or ${root_ip} is not Correct" >> ${LOG_FILE}
        #    echo "`${NOW}` ${root_name} or ${root_ip} is not Correct" |\ 
        #        mail  -s "check root ns list --fail ${root_name} -addr ${root_ip}" -r ${SENDER} ${ADMIN_MAIL}
        #    printf "%-30s %-10s %-4s %-8s %-40s\n"  "."   "$ttl" "IN" "NS" "${root_name}" >> $f
        #    printf "%-30s %-10s %-4s %-8s %-40s\n" "${root_name}" "$ttl" "IN" "AAAA" "${root_ip}" >> $f
        #fi
    done
}

# generate root zone apex part
generate_apex() {
    local f="${CONFIG}/root.zone.apex"
    local ttl="86400"

    get_serial

    # generate soa 
    echo ".    86400   IN    SOA    www.yeti-dns.org.  hostmaster.yeti-dns.org.\
        2015091000  1800  900  604800  86400" > $f
    
    # generate ns 
    generate_ns
}

generate_hint() {
    local f="$HINT"
    local ttl="3600000"
     
    get_serial

    # delete original hint file
    /bin/rm -f $HINT
    
    # generate hint file
    generate_ns

    /bin/cp -f $f  ${BIND_ZONE_PATH}
}

# generate acl_zone_transfer and notify_list
generate_acl() {
    local list_type="$1"

    get_serial

    if [ "$list_type" = "notify" ]; then
         local f="${NOTIFY_LIST}"
    elif [ "$list_type" = "acl" ]; then
         local f="${ZONETRANSFER_ACL}"
    else
        echo "Parameter $list_type does not exist"
        exit 1
    fi

    if [ -s ${ROOT_LIST} -a "${latest_serial}" -ge "${start_serial}" ]; then
        $PYTHON $WORKDIR/bin/parseyaml.py  $list_type ${ROOT_LIST} > $f
        if [ $? -ne 0 ]; then
            echo "${ROOT_LIST} file not exist or format error" >>\
                ${LOG_FILE}
            exit 1
        fi

    fi
}

generate_root_zone() {
    local tmp_serial=` head -1 ${CONFIG}/root.zone.apex |awk '{print $7}'`

    if [ -s ${ZONE_DATA}/root.zone ]; then
        local current_serial=`head -1 ${ZONE_DATA}/root.zone |awk '{print $7}'`
    else
        local current_serial=0
    fi

    local latest_serial=`grep "SOA" ${ORIGIN_ZONE}/root.zone |\
        egrep -v "NSEC|RRSIG"| head -1 |awk '{print $7}'`

    if [ ${latest_serial} -gt ${current_serial} ]; then
        # zone cut
        egrep -v "NSEC|RRSIG|DNSKEY|SOA|^;|^\." ${ORIGIN_ZONE}/root.zone >\
            ${TMP_ZONE}/root.zone.cut

        #update root zone serial number
        $SED -i "s/${tmp_serial}/${latest_serial}/"\
            ${CONFIG}/root.zone.apex

        # append zone cut
        /bin/cp ${CONFIG}/root.zone.apex  ${ZONE_DATA}/root.zone
        cat ${TMP_ZONE}/root.zone.cut >> ${ZONE_DATA}/root.zone
    fi
}

add_public_key() {
    local current_serial=`grep "SOA" ${ORIGIN_ZONE}/root.zone |\
                                 egrep -v "NSEC|RRSIG"| head -1 |awk '{print $7}'`
    local current_utc_time=`date -u +%Y%m%d%H%M%S`

    #import public zsk of bii tisf wide
    for dm_dir in bii tisf wide; do
        #import public key of zsk
        for zskdir in `ls  ${ZSK_DIR}/${dm_dir}`; do
            local zsk_serial=`cat ${ZSK_DIR}/$dm_dir/$zskdir/${START_SERIAL}`
            local zsk_delete_time=`$SED -n '/Delete/p' ${ZSK_DIR}/$dm_dir/$zskdir/*.key |\
                                       awk '{print $3}'`

            if [ "${current_serial}" -ge "${zsk_serial}" -a \
                 "${zsk_delete_time}" -gt "${current_utc_time}" ]; then 

                $SED -n '$'p ${ZSK_DIR}/$dm_dir/$zskdir/*.key |\
                    awk -F' IN' '{print $1,"86400  IN",$2}' >> ${ZONE_DATA}/root.zone
                
            fi
        done
    done

    #import public zsk of zsk dir 
    for zskdir in `find ${ZSK_DIR} -type d -name "20*"`; do
        #import public key of zsk
            local zsk_serial=`cat $zskdir/${START_SERIAL}`
            local zsk_delete_time=`$SED -n '/Delete/p' $zskdir/*.key | awk '{print $3}'`

            if [ "${current_serial}" -ge "${zsk_serial}" -a \
                 "${zsk_delete_time}" -gt "${current_utc_time}" ]; then 

                $SED -n '$'p $zskdir/*.key |\
                    awk -F' IN' '{print $1,"86400  IN",$2}' >> ${ZONE_DATA}/root.zone
                
            fi
    done
    
}

copy_zsk() {
    local key_dir="$1"
    key_serial=`cat $key_dir/${START_SERIAL}`
    key_activate_time=`$SED -n '/Activate/p' $key_dir/*.key | awk '{print $3}'`
    key_inactivite_time=`$SED -n '/Inactive/p' $key_dir/*.key | awk '{print $3}'`
    key_name=`ls $key_dir/*.key | awk -F'/' '{print $NF}' |\
                  awk -F'key' '{print $1}'`
    latest_serial=`grep "SOA" ${ORIGIN_ZONE}/root.zone | egrep -v "NSEC|RRSIG" |\
                      head -1 |awk '{print $7}'`
    # compare serial number
    if [ "${latest_serial}" -ge "${key_serial}" ]; then
        if [ "${current_utc_time}" -ge "${key_activate_time}" -a\
            "${key_inactivite_time}" -gt "${current_utc_time}" ]; then
            #apply zsk or ksk
            /bin/cp ${NEW_ZSK}/${key_name}* ${ROOT_KEY}/
            echo "ok" > $status_file
            echo "`${NOW}` ${type} $key_name is applied" >> ${LOG_FILE}
        fi
    fi
}

find_lastest_zsk() {
    local current_utc_time=`date -u +%Y%m%d%H%M%S`
    local status_file="$WORKDIR/tmp/status.txt"
    
    # delete old message of zsk of bii
    rm -f $status_file

    # delete old ksk and zsk 
    rm -f ${ROOT_KEY}/K.*
    
    # find zsk in bii dir
    for keydir in `ls ${ZSK_DIR}/${DM}`; do
        copy_zsk ${ZSK_DIR}/${DM}/$keydir
    done
    
    #find zsk in zsk dir
    if [ ! -f $status_file  ]; then
        for keydir in `find ${ZSK_DIR} -type d -name "20*"`; do
            copy_zsk $keydir
        done
    fi
}       

find_lastest_ksk() {
    local current_utc_time=`date -u +%Y%m%d%H%M%S`
    local dir
    local newkey_dir
    dir="${KSK_DIR}"
    newkey_dir="${NEW_KSK}"
    for keydir in `ls $dir`; do    
        local key_serial=`cat $dir/${keydir}/${START_SERIAL}`
        local key_delete_time=`$SED -n '/Delete/p' $dir/$keydir/*.key |\
                                 awk '{print $3}'`
        local key_publish_time=`$SED -n '/Publish/p' $dir/$keydir/*.key |\
                                   awk '{print $3}'`
        local key_name=`ls ${dir}/$keydir/*.key |\
                            awk -F'/' '{print $NF}' |awk -F'key' '{print $1}'`
        local latest_serial=`grep "SOA" ${ORIGIN_ZONE}/root.zone | egrep -v "NSEC|RRSIG" |\
                                 head -1 |awk '{print $7}'`

        # compare serial number
        if [ "${latest_serial}" -ge "${key_serial}" ]; then
            if [ "${current_utc_time}" -ge "${key_publish_time}" -a\
                 "${key_delete_time}" -gt "${current_utc_time}" ]; then
                #apply zsk or ksk
                /bin/cp ${KSK_DIR}/$keydir/${key_name}* ${ROOT_KEY}/
                echo "`${NOW}` ${type} $key_name is applied" >> ${LOG_FILE}
            fi
        fi
    done
}

# get serial number
_get_serial() {
  local server="$1"
  local result="$2"
  local status="$(dig -6 @$server . soa|tee $result|grep status|awk -F"[:,]" '{print $4}')"
  if [ "$status" = " NOERROR" ]; then
      # find SOA RR and get SOA serial number
      grep "^\..*SOA" $result|awk '{print $7}'  
  fi
  
  echo > "$result"
}

get_yeti_serial() {
    for server in '240c:F:1:22::4'; do
        YETI_SERIAL=$(_get_serial "$server" "/tmp/dig.log")
        if [ ! -z "$IANA_SERIAL" ]; then
            break
        fi
    done
}

get_iana_serial() {
    for server in f.root-servers.net l.root-servers.net; do
        IANA_SERIAL=$(_get_serial "$server" "/tmp/dig.log")
        if [ ! -z "$IANA_SERIAL" ]; then
            break
        fi
    done
}

is_new_zone() {
  get_yeti_serial
  get_iana_serial

  if [ -z "$IANA_SERIAL" -o -z "$YETI_SERIAL" ]; then
    # tiemout
    return 1
  else
    # contine
    :
  fi

  if [[ $IANA_SERIAL > $YETI_SERIAL ]]; then
      # need genereate new zone
      :
  else
      # return
      :
  fi
}
   
sign_root_zone() {
    ${DNSSECSIGNZONE} -K ${ROOT_KEY} -P -o . -O full -S  -x ${ZONE_DATA}/root.zone 
    if [ $? -eq 0 ]; then 
        $SED '/^;/d' ${ZONE_DATA}/root.zone.signed > ${BIND_ZONE_PATH}/root.zone.signed
    else 
        echo "`${NOW}` root zone resgined failed on pm(${SERVER_NAME}) server" >>\
                   ${LOG_FILE}
        echo "`${NOW}` root zone resgined failed on pm(${SERVER_NAME}) server" |\
                   mail -s "root zone signed fail"  -r ${SENDER} ${ADMIN_MAIL} 
        exit 1
    fi
}

#reload bind 
reload_name_server() {
    $RNDC reload .
    if [ $? -eq 0 ]; then
        echo "`${NOW}` pm(${SERVER_NAME}) named reload successful" >> ${LOG_FILE}
    else
        echo "`${NOW}` named process reload failed pm(${SERVER_NAME}) server" |\
                   mail -s "HM named reload failed " -r ${SENDER} ${ADMIN_MAIL}
        exit 1
    fi
}

update_github() {
    local current_path=`pwd`
    cd ${BIND_ZONE_PATH}
    sh github.sh 
    cd $current_path
}

generate_yeti_zone() {
    root_zone_download
    check_root_zone
    generate_apex 
    generate_hint 
    generate_acl notify
    generate_acl acl
    generate_root_zone
}

sign_yeti_zone() {
    add_public_key
    find_lastest_zsk 
    find_lastest_ksk 
    sign_root_zone
}

distribute_yeti_zone() {
    reload_name_server
    update_github
}

