#!/bin/sh

script_path=`dirname $0`
servername=`hostname`
logfile=${script_path}/gen_root.log

# load setting
if [ -s ${script_path}/setting.sh ]; then
        . ${script_path}/setting.sh
else
        echo "Error: can not load gen root functions" 
        exit 1
fi
# create  root.zone module
gen_root_file() {

        rootzone_file=$script_path/app_data/root.zone
	namedcache_file=$script_path/zone_data/named.cache
        if [ -s $ns_file  ];then
                . $ns_file
        else
                echo "$ns_file is not exist on pm ($servername) server" |mail -s "The PM download root  zonefile  failed " -r $sender  ${ADMIN_MAIL}
		
        fi
        echo '$TTL 86400' > $rootzone_file
        echo ".			$soa_ttl	IN	SOA	$soa  $soa_mail  $serial  $refresh  $retry  $expire  $negative" >> $rootzone_file
        echo "" >$namedcache_file
        ns_num=`grep "^ns_servers" $ns_file | wc -l`

        for i in `seq 1 $ns_num`;do
        	ns="\$ns_servers_$i"
		ns_name=`eval echo $ns | awk '{print $1}'`
		ns_addr=`eval echo $ns | awk '{print $2}'`

        	echo ".			${ns_ttl}	IN	NS	$ns_name"    >>$rootzone_file
          	echo "$ns_name	$aaaa_ttl	IN	AAAA	$ns_addr"    >>$rootzone_file
          	echo ".			${named_cache_ttl}	IN	NS	$ns_name"    >>$namedcache_file
        	echo "$ns_name	${named_cache_ttl}	IN	AAAA	$ns_addr"    >>$namedcache_file
        done
	 
	grep -v "^$"  $namedcache_file  >${ROOT_ZONE_PATH}/named.cache
}

start_time=`date +%Y%m%d%H%M%S`

# download root files

zone_download () {
	rm -f $origin_data/root.zone
	$dig @f.root-servers.net . axfr   >  $origin_data/root.zone
        if [ $? -ne 0 ]; then
                rm -f $origin_data/root.zone

                $dig @f.root-servers.net . axfr   >  $origin_data/root.zone > /dev/null 2>&1
                if [ $? -ne 0 ]; then
                        rm -f $origin_data/root.zone
                        $dig @f.root-servers.net . axfr > $origin_data/root.zone

                        if [ $? -ne 0 ];then
                                echo "The PM($servername) server download root zonefile  failed"  >> $logfile
                                echo "The PM($servername) server download root zonefile  failed" |mail -s "The PM download root  zonefile  failed " -r $sender  ${ADMIN_MAIL} 
                                exit 1

                        fi
                fi
        fi

}

# update root zone
gen_root_zone () {
        root_soa_serial_tmp=`$sed -n 2p $app_data/root.zone |awk '{print $7}'`
        root_origin_soa_serial=`$sed -n 5p $origin_data/root.zone |awk '{print $7}'`
        # zone apex
        $sed -i "s/${root_soa_serial_tmp}/${root_origin_soa_serial}/g" $app_data/root.zone
        # zone cut
	egrep -v "NSEC|RRSIG|DNSKEY|SOA|^;|^\." $origin_data/root.zone    > $tmp_data/root.zone.cut
        # append zone cut
        cat $tmp_data/root.zone.cut >> $app_data/root.zone
        cp $app_data/root.zone $zone_data/root.zone
}

# sign root zone
sign_root_zone() {
        $dnssecsignzone -K $rootkeydir -o . -O full -S -x $zonedir/root.zone
        if [ $? -eq 0 ]; then 
                $sed '/^;/d'  $zonedir/root.zone.signed >  ${ROOT_ZONE_PATH}/root.zone.signed
                /bin/cp -f $zonedir/root.zone ${ROOT_ZONE_PATH}
        else 
                echo "root zone resgined failed,please check root.zone file and keys on pm($servername) server" >> $logfile
                echo "root zone resgined failed,please check root.zone file and keys on pm($servername) server" | mail -s "root zone signed fail"  -r $sender  ${ADMIN_MAIL}
                exit 1
        fi
}

# reload  bind
reload_bind() {
        $rndc reload
        if [  $? -eq  0 ]; then
                echo "PM named reload successful" >> $logfile
        else
                echo "named process reload failed on the pm($servername) server" |mail -s "PM named reload failed " -r $sender  ${ADMIN_MAIL}
                exit 1
        fi
}

# sync zone file to github
update_data()  {
        cd ${ROOT_ZONE_PATH} 
        sh github.sh   "$1"
        cd 
}

