#!/bin/sh

script_path=`dirname $0`

# load setting
if [ -s ${script_path}/setting.sh ]; then
	. ${script_path}/setting.sh
else
	echo "Error: can not load settings"  
	exit 1
fi
             
# update the serial number of the root zone
update_soa_serial () {
	serial=`$sed -n 2p $zone_data/root.zone|awk '{print $7}'`
	serial_update=`echo "${serial} + 1" |bc `

	$sed -i "s/${searial}/${serial_update}/g" $zone_data/root.zone
}

# sign root
sign_zone() {
	$dnssecsignzone -K $rootkeydir -o . -O full -S -x $zone_data/root.zone
}

# reload bind
reload_bind() {
	$sed '/^;/d'  $zone_data/root.zone.signed > ${ROOT_ZONE_PATH}/root.zone.signed

	cp -f $zone_data/root.zone ${ROOT_ZONE_PATH}

	$rndc reload
}

# sync zone to github 
update_data()  {
	cd ${ROOT_ZONE_PATH} 
	sh github.sh
	cd 
}


sleep 26
update_soa_serial
sign_zone
reload_bind
#update_data
