#!/bin/sh


script_path=`dirname $0`
logfile=${script_path}/gen_root.log

# load setting
if [ -s ${script_path}/setting.sh ]; then
        . ${script_path}/setting.sh
else
        echo "Error: can not load gen root functions" | logger 
        exit 1
fi

# create arpa.zone root.zone module
gen_root_arpa_file() {

#        ns_file=$script_path/app_data/ns.sh
        rootzone_file=$script_path/app_data/root.zone
        arpazone_file=$script_path/app_data/arpa.zone
        if [ -s $ns_file  ];then
                . $ns_file
        else
                echo "$ns_file is not load"
        fi
        echo '$TTL 86400' > $rootzone_file
        echo ".        $soa_ttl   IN   SOA   $soa   $admin_mail      $serial    $refresh   $retry    $expire       $negative" >> $rootzone_file
        echo "arpa.    $soa_ttl   IN   SOA   $soa   $admin_mail      $serial    $refresh   $retry    $expire       $negative" > $arpazone_file

        ns_num=`grep "ns_servers" $ns_file |wc -l`

        for i in `seq 1 $ns_num`;do

        ns_name=`grep "ns_servers"  $ns_file  |sed -n "$i"p |awk -F "=" '{print $2}'| awk '{print $1}'`
        ns_addr=`grep "ns_servers"  $ns_file  |sed -n "$i"p |awk -F "=" '{print $2}'| awk '{print $2}'`

        echo ".            ${ns_ttl}                   IN         NS         $ns_name"    >>$rootzone_file
        echo "arpa.        ${root_arpa_ns_ttl}         IN         NS         $ns_name"    >>$arpazone_file
        echo "arpa.        ${root_arpa_ns_ttl}         IN         NS         $ns_name"    >>$rootzone_file
        echo "$ns_name        $aaaa_ttl                 IN         AAAA       $ns_addr"    >>$rootzone_file

        done

}

start_time=`date +%Y%m%d%H%M%S`

# download root, arpa files
zone_download () {
        rm -f $origin_data/root.zone
        dig @f.root-servers.net . axfr   >  $origin_data/root.zone
        if [ $? -ne 0 ]; then
                rm -f $origin_data/root.zone

                dig @f.root-servers.net . axfr   >  $origin_data/root.zone > /dev/null 2>&1
                if [ $? -ne 0 ]; then
                        rm -f $origin_data/root.zone
                        dig @f.root-servers.net . axfr > $origin_data/root.zone

                        if [ $? -ne 0 ];then
                                logger -p "local0.error"  "The PM download  root zonefile  failed"
                                echo "The PM download root zonefile  failed"  >> $logfile
                                echo "Error Error Error" |mail -s "The PM download root  zonefile  failed "  ggpang@biigroup.cn
                                exit 1

                        fi
                fi
        fi

        dig @f.root-servers.net arpa. axfr > $origin_data/arpa.zone
        if [ $? -ne 0 ]; then
                rm -f $origin_data/arpa.zone
                dig @f.root-servers.net arpa. axfr > $origin_data/arpa.zone
                if [ $? -ne 0 ]; then
                        rm -f $origin_data/arpa.zone
                        dig @f.root-servers.net arpa. axfr > $origin_data/arpa.zone

                        if [ $? -ne 0 ];then
                                logger -p "local0.error"  "The PM download  zonefile  failed"
                                echo "The PM download  zonefile  failed"  >> $logfile
                                echo "Error Error Error" |mail -s "The PM download  zonefile  failed "  ggpang@biigroup.cn
                                exit 2
                        fi
                fi
        fi

}


# update root zone
gen_root_zone () {
        root_soa_serial_tmp=`head -n 1 $app_data/root.zone |awk '{print $7}'`
        root_origin_soa_serial=`sed -n 5p $origin_data/root.zone |awk '{print $7}'`

        # zone apex
        cp $app_data/root.zone $zone_data/root.zone
        sed -i "s/${root_soa_serial_tmp}/${root_origin_soa_serial}/g" $zone_data/root.zone

        # zone cut
        egrep -v "NSEC|RRSIG|DNSKEY|SOA|^arpa.|;" $origin_data/root.zone    > $tmp_data/root.zone.no.dnssec
        egrep -v "[a-m].root-servers.net." $tmp_data/root.zone.no.dnssec  > $tmp_data/root.zone.cut

        sleep 2

        # append zone cut
        cat $tmp_data/root.zone.cut >> $zone_data/root.zone
}

# update arpa zone
gen_arpa_zone() {
        arpa_soa_serial_tmp=`head -n 1 $app_data/arpa.zone |awk '{print $7}'`
        arpa_origin_soa_serial=`sed -n 5p $origin_data/arpa.zone |awk '{print $7}'`

        # zone apex
        sed -i "s/${arpa_soa_serial_tmp}/${arpa_origin_soa_serial}/g"  $app_data/arpa.zone
        cp $app_data/arpa.zone  $zone_data/arpa.zone

        # zone cut
        egrep -v "NSEC|RRSIG|DNSKEY|SOA|;" $origin_data/arpa.zone > $tmp_data/arpa.zone.no.dnssec
        egrep -v  [a-m].root-servers.net $tmp_data/arpa.zone.no.dnssec  > $tmp_data/arpa.zone.cut
         
        # append zond cut
        cat $tmp_data/arpa.zone.cut >> $zone_data/arpa.zone
}


sign_arpa_zone () {

         /usr/local/sbin/dnssec-signzone  -K  $arpakeydir  -o arpa. -O full  -S -x  $zonedir/arpa.zone
          if [ $? -eq 0 ] 
             then
                 sed '/^;/d'  $zonedir/arpa.zone.signed > ${ROOT_ZONE_PATH}/arpa.zone.signed
                  /bin/cp -f $zonedir/arpa.zone ${ROOT_ZONE_PATH}
          else
                 logger -p "local0.error" "arpa zone signed failed" 
                 echo "arpa zone signed failed" >> $logfile
                 echo "Error Error Error" | mail -s "arpa zone signed failed" ${ADMIN_MAIL}
                exit 1
          fi 

}

#insert arpa_ds into root.zone
insert_arpa_ds() {
                 
                 cat ${script_path}/dsset-arpa.  >> $zonedir/root.zone
}

# sign root zone
sign_root_zone() {
        /usr/local/sbin/dnssec-signzone  -K $rootkeydir  -o . -O full -S -x $zonedir/root.zone
        if [ $? -eq 0 ]; then 
                sed '/^;/d'  $zonedir/root.zone.signed >  ${ROOT_ZONE_PATH}/root.zone.signed
                /bin/cp -f $zonedir/root.zone ${ROOT_ZONE_PATH}
        else 
                logger -p "local0.error" "root zone signed failed " 
                echo "root zone signed fail !!!" >> $logfile
                echo "Error Error Error" | mail -s "root zone signed fail"  ${ADMIN_MAIL}
                exit 1
        fi
}

# reload  bind
reload_bind() {
        /usr/local/sbin/rndc   reload
        if [  $? -eq  0 ]; then
                echo "PM named reload successful" >> $logfile
        else
                logger -p "local0.error" "PM named reload  failed " 
                echo "Error Error Error " |mail -s "PM named reload failed " ${ADMIN_MAIL}
                exit 1
        fi
         
}

# sync zone file to github
update_data()  {
        cd ${ROOT_ZONE_PATH} 
        sh github.sh
        cd 
}
