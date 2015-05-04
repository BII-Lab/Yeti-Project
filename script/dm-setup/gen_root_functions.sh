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

start_time=`date +%Y%m%d%H%M%S`

# download root, arpa files
zone_download () {

	rm -f $origin_data/*              
	wget -i $app_data/wwwdownload.txt -P $origin_data  > /dev/null 2>&1 
          
	if [ $? -ne 0 ]; then 
		rm -f $origin_data/*

		wget -i $app_data/ftpdownload.txt  -P $origin_data  >/dev/null 2>&1
		if [ $? -ne 0 ]; then 
			rm -f $origin_data/*
			wget -i $app_data/wwwdownload.txt -P $origin_data  >/dev/null   2>&1
                                   
			if [ $? -ne 0 ]; then
				logger -p "local0.error"  "The PM download  zonefile  failed" 
				echo "The PM download  zonefile  failed"  >> $logfile
				echo "Error Error Error" |mail -s "The PM download  zonefile  failed "  ${ADMIN_MAIL} 
				exit 1
			fi
		fi
	fi
}


# md5sum check: arpa.zone, root.zone 
check_zone() {  

	arpa_current_md5=`md5sum $origin_data/arpa.zone.gz |awk '{print $1}'`
	arpa_origin_md5=`cat $origin_data/arpa.zone.gz.md5`

	if [ $arpa_current_md5 = $arpa_origin_md5 ]; then
		echo "arpa.zone is ok"
		[ -f $origin_data/arpa.zone.gz ] &&  gzip -d $origin_data/arpa.zone.gz
	else
		logger -p local0.error  "Warning: This arpa.zone file is incorrect Please check."
		echo "Warning: This arpa.zone file is incorrect Please check."  >> $logfile
		echo "Error Error Error" |mail -s "Warning: This arpa.zone file is incorrect Please check."  ${ADMIN_MAIL}
	fi   

	root_current_md5=`md5sum $origin_data/root.zone.gz |awk '{print $1}'`
	root_origin_md5=`cat $origin_data/root.zone.gz.md5`

	if [ "$root_current_md5" = "$root_origin_md5" ]; then
		echo "root.zone is ok"
		[ -f $origin_data/root.zone.gz   ] && gzip -d $origin_data/root.zone.gz

	else
		logger -p local0.error   "Warning: This root zone file is incorrect Please check."
		echo "Warning: This root.zone  file is incorrect Please check."  >> $logfile
		echo "Error Error Error" |mail -s "Warning: This root.zone  file is incorrect Please check."  ${ADMIN_MAIL}
		exit 1
	fi
}


# update root zone
gen_root_zone () {
	root_soa_serial_tmp=`head -n 1 $app_data/root.zone |awk '{print $7}'`

	# zone apex
	cp $app_data/root.zone $zone_data/root.zone
	sed -i "s/${root_soa_serial_tmp}/${root_origin_soa_serial}/g" $zone_data/root.zone

	# zone cut
	egrep -v "NSEC|RRSIG|DNSKEY|SOA" $origin_data/root.zone    > $tmp_data/root.zone.no.dnssec
	egrep -v "[a-m].root-servers.net." $tmp_data/root.zone.no.dnssec  > $tmp_data/root.zone.cut

	sleep 5

	# append zone cut
	cat $tmp_data/root.zone.cut >> $zone_data/root.zone
}

# update arpa zone
gen_arpa_zone() {
	arpa_soa_serial_tmp=`head -n 1 $app_data/arpa.zone |awk '{print $7}'`

	# zone apex
	sed -i "s/${arpa_soa_serial_tmp}/${arpa_origin_soa_serial}/g"  $app_data/arpa.zone
	cp $app_data/arpa.zone  $zone_data/arpa.zone

	# zone cut
	egrep -v "NSEC|RRSIG|DNSKEY|SOA" $origin_data/arpa.zone > $tmp_data/arpa.zone.no.dnssec
	egrep -v  [a-m].root-servers.net $tmp_data/arpa.zone.no.dnssec  > $tmp_data/arpa.zone.cut
         
	# append zond cut
	cat $tmp_data/arpa.zone.cut >> $zone_data/arpa.zone
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
