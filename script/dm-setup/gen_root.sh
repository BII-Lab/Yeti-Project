#!/bin/sh


script_path=`dirname $0`



# load functions
if [ -s ${script_path}/gen_root_functions.sh ]; then
	. ${script_path}/gen_root_functions.sh
else
	echo "Error: can not load gen root functions" | logger 
	exit 1
fi


# main flow
case $1 in
  autoupdate)
    echo "$start_time" >> $logfile
    zone_download
    check_zone

    root_current_soa_serial=`head -n 1 $zone_data/root.zone |awk '{print $7}'`
    root_origin_soa_serial=`head -n 1 $origin_data/root.zone|awk '{print $7}'`

    arpa_current_soa_serial=`head -n 1 $zone_data/arpa.zone |awk '{print $7}'`
    arpa_origin_soa_serial=`head -n 1 $origin_data/arpa.zone |awk '{print $7}'`

    if [ ${root_origin_soa_serial} -gt  ${root_current_soa_serial:=0}  ]; then
      gen_root_zone
      sign_root_zone
      reload_bind
    else
      echo "root zone file was not update!!!" >> $logfile
    fi

    if [ $arpa_origin_soa_serial -gt ${arpa_current_soa_serial:=0} ]; then
        gen_arpa_zone
        sign_arpa_zone
        reload_bind
    else
        echo "arpa zone file was not update !!!!"  >> $logfile
    fi

#   update_data
    ;;
  manual_update)
    sign_root_zone
    sign_arpa_zone
    reload_bind
#    update_data
    ;;
  *)
    echo "sh gen_root.sh  autoupdate | manual_update "
    ;;
esac
